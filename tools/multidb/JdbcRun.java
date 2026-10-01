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
 * 범용 JDBC 러너 (MariaDB / PostgreSQL 겸용).
 * 사용: JdbcRun <jdbcUrl> <user> <pw> (exec "SQL" | <scriptFile>)
 */
public class JdbcRun {

    public static void main(String[] args) throws Exception {
        if (args.length < 4) {
            System.err.println("usage: JdbcRun <url> <user> <pw> (exec \"SQL\" | <file>)");
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
            // Oracle 리터럴 파리티: || 연결 + 백슬래시 무해석(\A 등 정규식 시드 보존) — maria 전용, PG 는 무시
            if (url.startsWith("jdbc:mariadb")) {
                st.execute("SET SESSION sql_mode=CONCAT(@@sql_mode,',PIPES_AS_CONCAT,NO_BACKSLASH_ESCAPES')");
            }
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

    /**
     * 스크립트 → 문장 목록. 따옴표 밖 ';' 로 분할, 주석/빈 줄 무시.
     * 저장 프로그램(CREATE TRIGGER/FUNCTION/PROCEDURE)은 BEGIN~END 안의 ';' 가 문장 구분자가
     * 아니므로, 블록 모드로 들어가 컬럼 0 의 `END;`(또는 `END`)를 만날 때까지 한 문장으로 묶는다.
     * — MariaDB 는 sqlplus 의 '/' 종결자가 없고, JDBC 는 DELIMITER 지시어를 모른다.
     */
    static List<String> parse(String text) throws IOException {
        List<String> out = new ArrayList<>();
        String[] lines = text.replace("\r", "").replace("﻿", "").split("\n", -1);
        StringBuilder cur = new StringBuilder();
        boolean inQuote = false;
        boolean inBlock = false;
        for (String line : lines) {
            String trimmed = line.trim();
            if (cur.length() == 0 && (trimmed.isEmpty() || trimmed.startsWith("--")
                    || trimmed.toUpperCase().startsWith("SET DEFINE"))) {   // sqlplus 지시어
                continue;
            }
            if (cur.length() == 0) {
                String u = trimmed.toUpperCase();
                // DROP ... 은 일반 문장. CREATE 계열 저장 프로그램만 블록 모드.
                inBlock = u.startsWith("CREATE ")
                        && (u.contains(" TRIGGER ") || u.contains(" FUNCTION ") || u.contains(" PROCEDURE "));
            }
            for (int i = 0; i < line.length(); i++) {
                if (line.charAt(i) == '\'') {
                    inQuote = !inQuote;
                }
            }
            cur.append(line).append('\n');
            boolean end;
            if (inBlock) {
                // 들여쓰기 없는 END; / END 만 블록 종료로 인정 (본문 내부 END 는 들여쓰기됨)
                end = !inQuote && (line.equals("END;") || line.equals("END"));
            } else {
                end = !inQuote && trimmed.endsWith(";");
            }
            if (end) {
                String s = cur.toString().trim();
                if (s.endsWith(";")) {
                    s = s.substring(0, s.length() - 1);
                }
                out.add(s);
                cur.setLength(0);
                inBlock = false;
            }
        }
        if (cur.toString().trim().length() > 0) {
            out.add(cur.toString().trim());
        }
        return out;
    }
}
