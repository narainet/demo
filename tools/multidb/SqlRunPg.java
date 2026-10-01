import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.util.*;
import java.util.regex.*;

/**
 * MyBatis 매퍼 SQL 문법 린터.
 *
 * 각 &lt;select/insert/update/delete&gt; 본문에서 MyBatis 동적 태그를 벗겨 순수 SQL 을 만들고
 * 대상 DB 에 PREPARE(=서버측 파싱)만 시켜 문법 오류를 잡는다. 실행하지 않으므로 데이터는 무변.
 *
 * 한계(의도적): 동적 태그를 "모두 참"으로 펼치므로 실제 런타임 조합과 100% 같지는 않다.
 *   → 문법 오류 탐지용이지 의미 검증용이 아니다. 의미는 앱 기동 후 화면으로 확인한다.
 *
 * usage: SqlRunPg <jdbcUrl> <user> <pw> <mapperDir> <suffix>
 */
public class SqlRunPg {

    public static void main(String[] args) throws Exception {
        String url = args[0], user = args[1], pw = args[2];
        Path dir = Paths.get(args[3]);
        String suffix = args[4];

        List<Path> files = new ArrayList<>();
        Files.walk(dir).filter(p -> p.toString().endsWith(suffix)).sorted().forEach(files::add);

        int total = 0, ok = 0;
        Map<String, List<String>> failures = new LinkedHashMap<>();

        // ★PREPARE 는 이 드라이버가 서버로 보내지 않아(깨진 SQL 도 통과) 검증이 무효다.
        //   EXPLAIN 으로 서버에 파싱+컬럼해석까지 시킨다. 실행 계획만 만들 뿐 데이터는 바뀌지 않지만,
        //   DML 도 대상이므로 트랜잭션을 열고 마지막에 롤백해 이중으로 막는다.
        try (Connection con = DriverManager.getConnection(url, user, pw)) {
            // PG: EXPLAIN 은 실행 없이 파싱+계획만 만들므로 autocommit 그대로 둔다.
            //     (트랜잭션을 열면 첫 오류 후 "transaction is aborted"로 이후 검사가 전부 무효가 된다)
            for (Path f : files) {
                String xml = new String(Files.readAllBytes(f), StandardCharsets.UTF_8);
                Map<String, String> frags = collectFragments(xml);
                for (Stmt st : collectStatements(xml)) {
                    total++;
                    String sql;
                    try {
                        sql = toPlainSql(st.body, frags);
                    } catch (Exception e) {
                        continue;   // 추출 실패는 린트 대상 외
                    }
                    if (sql.trim().isEmpty()) {
                        ok++;
                        continue;
                    }
                    try (java.sql.Statement s = con.createStatement()) {
                        if (!sql.trim().toUpperCase().startsWith("SELECT") && !sql.trim().toUpperCase().startsWith("WITH")) { ok++; continue; }
                        java.sql.ResultSet rr = s.executeQuery(sql);
                        int rn = 0; while (rr.next()) rn++;
                        System.out.println("  RUN-OK  " + st.id + "  rows=" + rn);
                        ok++;
                    } catch (Exception e) {
                        String msg = e.getMessage();
                        if (msg != null && msg.length() > 400) {
                            msg = msg.substring(0, 400) + "...";
                        }
                        failures.computeIfAbsent(dir.relativize(f).toString().replace('\\', '/'),
                                k -> new ArrayList<>()).add(st.id + "  ::  " + msg);
                    }
                }
            }
        }

        System.out.println("검사 " + total + "건 / 통과 " + ok + " / 실패 " + (total - ok));
        for (Map.Entry<String, List<String>> e : failures.entrySet()) {
            System.out.println("── " + e.getKey());
            for (String s : e.getValue()) {
                System.out.println("    " + s);
            }
        }
    }

    static class Stmt {
        String id, body;
        Stmt(String id, String body) { this.id = id; this.body = body; }
    }

    static final Pattern STMT = Pattern.compile(
            "<(select|insert|update|delete)\\b([^>]*)>(.*?)</\\1>", Pattern.DOTALL | Pattern.CASE_INSENSITIVE);
    static final Pattern SQLFRAG = Pattern.compile(
            "<sql\\b([^>]*)>(.*?)</sql>", Pattern.DOTALL | Pattern.CASE_INSENSITIVE);
    static final Pattern IDATTR = Pattern.compile("id\\s*=\\s*\"([^\"]*)\"");

    static Map<String, String> collectFragments(String xml) {
        Map<String, String> m = new HashMap<>();
        Matcher mt = SQLFRAG.matcher(xml);
        while (mt.find()) {
            Matcher im = IDATTR.matcher(mt.group(1));
            if (im.find()) {
                m.put(im.group(1), mt.group(2));
            }
        }
        return m;
    }

    static List<Stmt> collectStatements(String xml) {
        List<Stmt> out = new ArrayList<>();
        Matcher mt = STMT.matcher(xml);
        while (mt.find()) {
            Matcher im = IDATTR.matcher(mt.group(2));
            out.add(new Stmt(im.find() ? im.group(1) : "?", mt.group(3)));
        }
        return out;
    }

    /** MyBatis 동적 태그를 벗기고 파라미터를 ? 로 바꾼 순수 SQL */
    static String toPlainSql(String body, Map<String, String> frags) {
        String s = body;
        // <include refid="x"/> 및 <include refid="x">...</include>(property 포함형) → 조각 삽입.
        // 조각 속 조각(중첩 include)이 있어 고정점까지 반복 전개(무한루프 방지 상한 8).
        Pattern incP = Pattern.compile(
                "<include\\s+refid\\s*=\\s*\"([^\"]*)\"\\s*(?:/>|>.*?</include>)",
                Pattern.CASE_INSENSITIVE | Pattern.DOTALL);
        for (int round = 0; round < 8; round++) {
            Matcher inc = incP.matcher(s);
            if (!inc.find()) {
                break;
            }
            inc.reset();
            StringBuffer sb = new StringBuffer();
            while (inc.find()) {
                String frag = frags.getOrDefault(inc.group(1), "");
                inc.appendReplacement(sb, Matcher.quoteReplacement(frag));
            }
            inc.appendTail(sb);
            s = sb.toString();
        }

        // selectKey 는 별도 문장 — insert 본문에 섞이면 가짜 문법오류가 되므로 제거
        s = s.replaceAll("(?is)<selectKey\\b.*?</selectKey>", " ");
        s = s.replaceAll("(?s)<!--.*?-->", " ");
        // ★CDATA 내용을 플레이스홀더로 보호 — 안의 <=, <, <> 가 아래 일반 태그 제거
        //   정규식(<[^>]+>)에 먹혀 문장이 통째로 잘리는 것을 막는다(8/5 maria 린트의 최대 노이즈 클래스).
        java.util.List<String> cdatas = new ArrayList<>();
        Matcher cd = Pattern.compile("(?s)<!\\[CDATA\\[(.*?)\\]\\]>").matcher(s);
        StringBuffer cb = new StringBuffer();
        while (cd.find()) {
            cdatas.add(cd.group(1));
            cd.appendReplacement(cb, Matcher.quoteReplacement("" + (cdatas.size() - 1) + ""));
        }
        cd.appendTail(cb);
        s = cb.toString();
        // 태그 속성 안의 > (예: test="n > 0") 가 태그 경계를 끊지 않도록 따옴표 인지 본문 클래스
        String A = "(?:[^>\"']|\"[^\"]*\"|'[^']*')*";
        // 구조 태그 → 키워드
        s = s.replaceAll("(?i)<where" + A + ">", " WHERE 1=1 AND ");
        s = s.replaceAll("(?i)</where>", " ");
        s = s.replaceAll("(?i)<set\\b" + A + ">", " SET ");
        s = s.replaceAll("(?i)</set>", " ");
        // foreach → 단일 항목으로 근사
        s = s.replaceAll("(?i)<foreach\\b" + A + ">", " ( ");
        s = s.replaceAll("(?i)</foreach>", " ) ");
        // 나머지 태그(if/choose/when/otherwise/trim/bind 등) 제거 — 내용은 남긴다(모두 참으로 펼침)
        s = s.replaceAll("(?s)<bind\\b" + A + "/>", " ");
        s = s.replaceAll("(?s)<" + A + ">", " ");
        // CDATA 내용 복원
        for (int i = 0; i < cdatas.size(); i++) {
            s = s.replace("" + i + "", cdatas.get(i));
        }
        // 엔티티 복원
        s = s.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
             .replace("&quot;", "\"").replace("&apos;", "'");
        // 파라미터 — EXPLAIN 은 ? 를 못 받으므로 리터럴로. MariaDB 는 타입에 관대해 1 로 충분하다.
        // PG 는 강타입이라 숫자 1 은 varchar 비교에서 가짜 실패를 만든다 → 미지정 리터럴 '1' 로
        // (서버가 문맥 타입으로 추론 — 운영 datasource 의 stringtype=unspecified 와 같은 경로).
        // 날짜성 파라미터(De/Dt/date/day/pnttm)는 TO_DATE/TO_TIMESTAMP 상수 접힘이 EXPLAIN 때
        // 즉시 평가되므로 실제 날짜꼴('2026-01-01')로 넣어 가짜 범위오류를 막는다.
        Matcher pm = Pattern.compile("#\\{([^}]*)\\}").matcher(s);
        StringBuffer pb = new StringBuffer();
        while (pm.find()) {
            String nm = pm.group(1);
            // 카멜 토큰 경계(대문자 De/Dt 로 끝나거나 Date/Pnttm/Day 토큰 보유)만 날짜로 —
            // firstIndex 의 소문자 'de' 같은 우연 매칭이 OFFSET 에 날짜를 넣는 사고 방지.
            // '2026-01-01' — TO_DATE/TO_TIMESTAMP('YYYY-MM-DD…') 와 호환.
            // ⛔'20260101' 은 불가: PG 토큰은 그리디라 구분자 없는 입력이면 YYYY 가 8자리를 다 먹는다.
            // (트레이드오프: varchar(8) 날짜 컬럼 INSERT 2건이 길이 초과 노이즈로 남는다 — 분류 문서화)
            String lit = nm.matches(".*(De|Dt)$|.*(Date|Pnttm|Day)([A-Z].*)?$|(?i)^(from|to|bgn|end)(de|dt)$")
                    ? "'2026-01-01'" : "'1'";
            pm.appendReplacement(pb, Matcher.quoteReplacement(lit));
        }
        pm.appendTail(pb);
        s = pb.toString();
        // ${별칭}.COL 꼴은 한정자만 제거(1.COL 가짜오류 방지) — 나머지 ${} 는 '1'
        // (컬럼/정렬식 치환이 대부분이라 문자열 리터럴이 숫자보다 호환 넓다: REPLACE('1',..) 등)
        s = s.replaceAll("\\$\\{[^}]*\\}\\s*\\.", "");
        s = s.replaceAll("\\$\\{[^}]*\\}", "'1'");
        // 태그 제거로 생긴 잔재 정리
        s = s.replaceAll("(?i)WHERE\\s+1=1\\s+AND\\s+(AND|OR)\\b", " WHERE 1=1 AND ");
        // GROUP/ORDER 는 반드시 BY 동반 — GROUP_ID 같은 컬럼명 오매칭 방지
        s = s.replaceAll("(?i)WHERE\\s+1=1\\s+AND\\s*(?=(ORDER\\s+BY|GROUP\\s+BY|HAVING\\b|LIMIT\\b|\\)|$))", " ");
        s = s.replaceAll("(?i)\\bSET\\s+,", " SET ");
        s = s.replaceAll(",\\s*(?=(FROM|WHERE|ORDER|GROUP)\\b)", " ");
        s = s.replaceAll("\\s+", " ").trim();
        return s;
    }
}
