import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 신규 DB 설치 스크립트 러너 — 지정 계정으로 접속해 .sql 파일을 문장 단위로 실행.
 * SET 지시어 무시, PL/SQL 블록(CREATE TRIGGER/FUNCTION/BEGIN~END; 후 단독 '/')과
 * 일반 문장(따옴표 밖 행끝 ';')을 구분 파싱. 첫 오류에서 중단(설치 순서 보장).
 *
 * usage: DbRun <user> <password> <scriptFile.sql | -e SQL한줄>
 */
public class DbRun {
    /** 접속 URL 은 -Ddb.url=... 또는 환경변수 RLMS_DB_URL 로 주입한다(하드코딩 금지). */
    private static final String JDBC_URL = resolveUrl();

    private static String resolveUrl() {
        String u = System.getProperty("db.url");
        if (u == null || u.isEmpty()) u = System.getenv("RLMS_DB_URL");
        if (u == null || u.isEmpty()) {
            System.err.println("[DbRun] DB 접속 URL 이 지정되지 않았다.");
            System.err.println("  -Ddb.url=jdbc:oracle:thin:@<host>:1521:<sid>  또는  환경변수 RLMS_DB_URL");
            System.exit(2);
        }
        return u;
    }

    public static void main(String[] args) throws Exception {
        System.setOut(new PrintStream(System.out, true, "UTF-8"));
        if (args.length < 3) {
            System.err.println("usage: DbRun <user> <password> <script.sql | exec SQL>");
            System.exit(2);
        }
        String user = args[0], pw = args[1];
        List<String> stmts;
        String label;
        if ("exec".equals(args[2])) {
            stmts = new ArrayList<>();
            stmts.add(args[3]);
            label = "(inline)";
        } else {
            String text = new String(Files.readAllBytes(Paths.get(args[2])), StandardCharsets.UTF_8);
            stmts = parse(text);
            label = args[2];
        }
        try (Connection con = DriverManager.getConnection(JDBC_URL, user, pw);
             Statement st = con.createStatement()) {
            int ok = 0;
            for (String sql : stmts) {
                try {
                    boolean isRs = st.execute(sql);
                    if (isRs) {
                        try (ResultSet rs = st.getResultSet()) {
                            int cols = rs.getMetaData().getColumnCount();
                            int rows = 0;
                            StringBuilder first = new StringBuilder();
                            while (rs.next()) {
                                if (rows < 2000) {
                                    StringBuilder b = new StringBuilder();
                                    for (int i = 1; i <= cols; i++) {
                                        if (i > 1) b.append(" | ");
                                        b.append(rs.getString(i));
                                    }
                                    first.append(b).append('\n');
                                }
                                rows++;
                            }
                            System.out.print(first);
                            System.out.println("(" + rows + " rows)");
                        }
                    }
                    ok++;
                } catch (Exception e) {
                    System.out.println("FAILED at statement #" + (ok + 1) + " of " + stmts.size() + " in " + label);
                    System.out.println("--- statement head ---");
                    System.out.println(sql.length() > 500 ? sql.substring(0, 500) + "..." : sql);
                    System.out.println("--- error ---");
                    System.out.println(e.getMessage());
                    System.exit(1);
                }
            }
            System.out.println("OK: " + ok + "/" + stmts.size() + " statements — " + label);
        }
    }

    /** 스크립트 → 문장 목록. */
    static List<String> parse(String text) {
        List<String> out = new ArrayList<>();
        String[] lines = text.replace("\r", "").replace("﻿", "").split("\n", -1);
        StringBuilder cur = new StringBuilder();
        boolean inPlsql = false;
        boolean inQuote = false;
        for (String line : lines) {
            String trimmed = line.trim();
            if (!inPlsql && cur.length() == 0) {
                // 문장 시작 전
                if (trimmed.isEmpty() || trimmed.startsWith("--")) continue;
                String u = trimmed.toUpperCase();
                if (u.startsWith("SET ")) continue; // sqlplus 지시어
                if (u.equals("/")) continue;
                if (u.startsWith("CREATE OR REPLACE TRIGGER") || u.startsWith("CREATE OR REPLACE FUNCTION")
                        || u.startsWith("CREATE OR REPLACE PROCEDURE") || u.startsWith("CREATE TRIGGER")
                        || u.startsWith("CREATE FUNCTION") || u.startsWith("BEGIN") || u.startsWith("DECLARE")) {
                    inPlsql = true;
                }
            }
            if (inPlsql) {
                if (trimmed.equals("/")) {
                    String s = cur.toString().trim();
                    if (!s.isEmpty()) out.add(s);
                    cur.setLength(0);
                    inPlsql = false;
                } else {
                    cur.append(line).append('\n');
                }
                continue;
            }
            // 일반 문장 누적 — 따옴표 상태 추적
            if (cur.length() == 0 && (trimmed.isEmpty() || trimmed.startsWith("--"))) continue;
            cur.append(line).append('\n');
            for (int i = 0; i < line.length(); i++) {
                if (line.charAt(i) == '\'') inQuote = !inQuote;
            }
            if (!inQuote) {
                String s = cur.toString().trim();
                if (s.endsWith(";")) {
                    out.add(s.substring(0, s.length() - 1).trim());
                    cur.setLength(0);
                }
            }
        }
        String rest = cur.toString().trim();
        if (!rest.isEmpty()) {
            if (rest.endsWith(";")) rest = rest.substring(0, rest.length() - 1);
            out.add(rest);
        }
        return out;
    }
}
