import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * PostgreSQL 전용 JDBC 러너 — JdbcRun 포크(2026-08-05).
 * 차이: plpgsql 의 달러 인용($$ ... $$)을 인식해 본문 속 ';' 로 문장을 쪼개지 않는다.
 * 문장 종결 = 줄 끝 ';' AND 작은따옴표 짝수 AND '$$' 짝수.
 * 사용: JdbcRunPg <jdbcUrl> <user> <pw> (exec "SQL" | <scriptFile>)
 */
public class JdbcRunPg {

    public static void main(String[] args) throws Exception {
        if (args.length < 4) {
            System.err.println("usage: JdbcRunPg <url> <user> <pw> (exec \"SQL\" | <file>)");
            System.exit(2);
        }
        String url = args[0], user = args[1], pw = args[2];
        String label;
        List<String> stmts;
        if ("exec".equals(args[3])) {
            label = "(inline)";
            stmts = parse(args[4]);
        } else {
            label = args[3];
            stmts = parse(new String(Files.readAllBytes(Paths.get(args[3])), StandardCharsets.UTF_8));
        }

        int ok = 0;
        try (Connection con = DriverManager.getConnection(url, user, pw);
             Statement st = con.createStatement()) {
            for (String sql : stmts) {
                try {
                    boolean isRs = st.execute(sql);
                    if (isRs) {
                        try (ResultSet rs = st.getResultSet()) {
                            ResultSetMetaData md = rs.getMetaData();
                            int cols = md.getColumnCount();
                            int rows = 0;
                            StringBuilder out = new StringBuilder();
                            while (rs.next()) {
                                if (rows < 2000) {
                                    for (int i = 1; i <= cols; i++) {
                                        if (i > 1) out.append(" | ");
                                        out.append(rs.getString(i));
                                    }
                                    out.append('\n');
                                }
                                rows++;
                            }
                            System.out.print(out);
                            System.out.println("(" + rows + " rows)");
                        }
                    }
                    ok++;
                } catch (Exception e) {
                    System.out.println("FAILED at statement #" + (ok + 1) + " of " + stmts.size() + " in " + label);
                    System.out.println("--- statement head ---");
                    System.out.println(sql.length() > 400 ? sql.substring(0, 400) + "..." : sql);
                    System.out.println("--- error ---");
                    System.out.println(e.getMessage());
                    System.exit(1);
                }
            }
        }
        System.out.println("OK: " + ok + "/" + stmts.size() + " statements — " + label);
    }

    static int countToken(String s, String tok) {
        int n = 0, i = 0;
        while ((i = s.indexOf(tok, i)) >= 0) { n++; i += tok.length(); }
        return n;
    }

    /**
     * 스크립트 → 문장 목록. 빈 줄/주석 줄 무시(문장 누적 전).
     * 종결 판정: 줄 끝 ';' AND 누적 텍스트의 작은따옴표 짝수 AND '$$' 짝수.
     * (달러 인용 본문 속 ';' 와 '...' 문자열 속 ';' 모두 보존.
     *  ⚠️전제: 주석에 홀수 개 작은따옴표를 쓰지 않는다 — 본 설치 세트 파일 규약.)
     */
    static List<String> parse(String text) throws IOException {
        List<String> out = new ArrayList<>();
        String[] lines = text.replace("\r", "").replace("﻿", "").split("\n", -1);
        StringBuilder cur = new StringBuilder();
        for (String line : lines) {
            String trimmed = line.trim();
            if (cur.length() == 0 && (trimmed.isEmpty() || trimmed.startsWith("--")
                    || trimmed.toUpperCase().startsWith("SET DEFINE"))) {
                continue;
            }
            cur.append(line).append('\n');
            String acc = cur.toString();
            boolean quoteEven = countToken(acc, "'") % 2 == 0;
            boolean dollarEven = countToken(acc, "$$") % 2 == 0;
            if (trimmed.endsWith(";") && quoteEven && dollarEven) {
                String s = acc.trim();
                if (s.endsWith(";")) {
                    s = s.substring(0, s.length() - 1);
                }
                out.add(s);
                cur.setLength(0);
            }
        }
        if (cur.toString().trim().length() > 0) {
            out.add(cur.toString().trim());
        }
        return out;
    }
}
