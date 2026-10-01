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
 * usage: SqlLint <jdbcUrl> <user> <pw> <mapperDir> <suffix>
 */
public class SqlLint {

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
            con.setAutoCommit(false);
            try (java.sql.Statement st = con.createStatement()) {
                st.execute("SET SESSION sql_mode=CONCAT(@@sql_mode,',PIPES_AS_CONCAT,NO_BACKSLASH_ESCAPES')");
            }
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
                        s.execute("EXPLAIN " + sql);
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
            con.rollback();
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

        s = s.replaceAll("(?s)<!\\[CDATA\\[(.*?)\\]\\]>", "$1");
        s = s.replaceAll("(?s)<!--.*?-->", " ");
        // 구조 태그 → 키워드
        s = s.replaceAll("(?i)<where\\b[^>]*>", " WHERE 1=1 AND ");
        s = s.replaceAll("(?i)</where>", " ");
        s = s.replaceAll("(?i)<set\\b[^>]*>", " SET ");
        s = s.replaceAll("(?i)</set>", " ");
        // foreach → 단일 항목으로 근사
        s = s.replaceAll("(?i)<foreach\\b[^>]*>", " ( ");
        s = s.replaceAll("(?i)</foreach>", " ) ");
        // 나머지 태그(if/choose/when/otherwise/trim/bind 등) 제거 — 내용은 남긴다(모두 참으로 펼침)
        s = s.replaceAll("(?s)<bind\\b[^>]*/>", " ");
        s = s.replaceAll("(?s)<[^>]+>", " ");
        // 엔티티 복원
        s = s.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
             .replace("&quot;", "\"").replace("&apos;", "'");
        // 파라미터 — EXPLAIN 은 ? 를 못 받으므로 리터럴로. MariaDB 는 타입에 관대해 1 로 충분하다.
        s = s.replaceAll("#\\{[^}]*\\}", "1");
        s = s.replaceAll("\\$\\{[^}]*\\}", "1");
        // 태그 제거로 생긴 잔재 정리
        s = s.replaceAll("(?i)WHERE\\s+1=1\\s+AND\\s+(AND|OR)\\b", " WHERE 1=1 AND ");
        s = s.replaceAll("(?i)WHERE\\s+1=1\\s+AND\\s*(?=(ORDER|GROUP|HAVING|LIMIT|\\)|$))", " ");
        s = s.replaceAll("(?i)\\bSET\\s+,", " SET ");
        s = s.replaceAll(",\\s*(?=(FROM|WHERE|ORDER|GROUP)\\b)", " ");
        s = s.replaceAll("\\s+", " ").trim();
        return s;
    }
}
