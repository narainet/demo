import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

/**
 * 라이브 Oracle → newdb 시드 INSERT 생성기 (2026-08-06).
 *
 * newdb/2x_seed_*.sql 은 손으로 관리하다 라이브와 벌어진다(메뉴 69 vs 라이브 101 실측).
 * 정본은 라이브 DB 이므로 시드를 라이브에서 다시 뽑는다. maria/postgres 가 "DDL + 라이브 복사"인 것과 같은 원리.
 *
 * usage: SeedGen <jdbcUrl> <user> <pw> <spec...>
 *   spec = TABLE|WHERE|ORDERBY|OVERRIDE
 *     WHERE/ORDERBY 는 비워도 된다. OVERRIDE = "COL=리터럴" (예: NEXT_ID=1 — 클린설치는 채번 초기값).
 *
 * 출력은 표준출력(UTF-8). 값 포맷: NULL / 숫자 원본 / 문자열 작은따옴표(내부 ' 은 '' 로) /
 * DATE·TIMESTAMP 는 TO_DATE(...). `&` 는 호출측 스크립트의 SET DEFINE OFF 가 담당한다.
 */
public class SeedGen {

    public static void main(String[] args) throws Exception {
        PrintStream out = new PrintStream(System.out, true, "UTF-8");
        String url = args[0], user = args[1], pw = args[2];

        try (Connection con = DriverManager.getConnection(url, user, pw)) {
            for (int i = 3; i < args.length; i++) {
                String[] p = (args[i] + "|||").split("\\|", -1);
                String table = p[0].trim();
                String where = p[1].trim();
                String order = p[2].trim();
                String override = p[3].trim();

                String ovCol = null, ovVal = null;
                if (!override.isEmpty()) {
                    int eq = override.indexOf('=');
                    if (eq < 0) {
                        throw new IllegalArgumentException(
                                "spec 4번째 칸은 OVERRIDE(\"COL=값\") 다. ORDER BY 를 넣으려면 3번째 칸에: " + args[i]);
                    }
                    ovCol = override.substring(0, eq).trim().toUpperCase();
                    ovVal = override.substring(eq + 1).trim();
                }

                String sql = "SELECT * FROM " + table
                        + (where.isEmpty() ? "" : " WHERE " + where)
                        + (order.isEmpty() ? "" : " ORDER BY " + order);

                int rows = 0;
                StringBuilder body = new StringBuilder();
                try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
                    ResultSetMetaData md = rs.getMetaData();
                    int n = md.getColumnCount();
                    List<String> cols = new ArrayList<String>();
                    for (int c = 1; c <= n; c++) cols.add(md.getColumnName(c).toUpperCase());

                    while (rs.next()) {
                        StringBuilder vals = new StringBuilder();
                        for (int c = 1; c <= n; c++) {
                            if (c > 1) vals.append(", ");
                            String col = cols.get(c - 1);
                            if (col.equals(ovCol)) {
                                vals.append(ovVal);
                            } else {
                                vals.append(literal(rs, md, c));
                            }
                        }
                        body.append("INSERT INTO ").append(table).append(" (")
                            .append(join(cols)).append(")\n  VALUES (").append(vals).append(");\n");
                        rows++;
                    }
                }
                out.print(body);
                out.println("-- " + table + ": " + rows + " rows");
                out.println();
            }
        }
    }

    static String join(List<String> cols) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < cols.size(); i++) {
            if (i > 0) sb.append(", ");
            sb.append(cols.get(i));
        }
        return sb.toString();
    }

    /** 컬럼 1개를 Oracle 리터럴로. */
    static String literal(ResultSet rs, ResultSetMetaData md, int c) throws SQLException {
        int type = md.getColumnType(c);
        switch (type) {
            case Types.NUMERIC: case Types.DECIMAL: case Types.INTEGER:
            case Types.BIGINT: case Types.SMALLINT: case Types.TINYINT:
            case Types.FLOAT: case Types.DOUBLE: case Types.REAL: {
                String v = rs.getString(c);
                return rs.wasNull() ? "NULL" : v;
            }
            case Types.DATE: case Types.TIMESTAMP: {
                Timestamp ts = rs.getTimestamp(c);
                if (rs.wasNull() || ts == null) return "NULL";
                String s = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(ts);
                return "TO_DATE('" + s + "', 'YYYY-MM-DD HH24:MI:SS')";
            }
            default: {
                String v = rs.getString(c);
                if (rs.wasNull() || v == null) return "NULL";
                return "'" + v.replace("'", "''") + "'";
            }
        }
    }
}
