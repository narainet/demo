import java.sql.*;
import java.util.*;

/**
 * Oracle → MariaDB 표본 데이터 복사기 (2026-08-05).
 * 규칙: 양쪽에 존재하는 테이블 중 "maria 0행 & oracle 1행 이상"만 복사(시드 적재분 보호).
 * 컬럼은 이름 교집합만(제품별 컬럼 드리프트 안전). FK 검사는 세션에서 끔.
 * usage: OraToMaria <oraUrl> <oraUser> <oraPw> <mariaUrl> <mariaUser> <mariaPw>
 */
public class OraToMaria {

    public static void main(String[] args) throws Exception {
        try (Connection ora = DriverManager.getConnection(args[0], args[1], args[2]);
             Connection ma = DriverManager.getConnection(args[3], args[4], args[5])) {
            ma.setAutoCommit(false);
            try (Statement s = ma.createStatement()) {
                s.execute("SET FOREIGN_KEY_CHECKS=0");
                s.execute("SET SESSION sql_mode=CONCAT(@@sql_mode,',PIPES_AS_CONCAT')");
            }

            List<String> tables = new ArrayList<>();
            try (Statement s = ma.createStatement();
                 ResultSet rs = s.executeQuery(
                     "SELECT table_name FROM information_schema.tables " +
                     "WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE' ORDER BY table_name")) {
                while (rs.next()) tables.add(rs.getString(1));
            }

            int copied = 0;
            for (String t : tables) {
                long mCnt = count(ma, t);
                if (mCnt > 0) continue;
                long oCnt;
                try {
                    oCnt = count(ora, t);
                } catch (SQLException e) {
                    continue;   // oracle 에 없는 테이블
                }
                if (oCnt == 0) continue;

                Set<String> mCols = cols(ma, t), oCols = cols(ora, t);
                List<String> use = new ArrayList<>();
                for (String c : oCols) if (mCols.contains(c)) use.add(c);
                if (use.isEmpty()) continue;

                StringBuilder sel = new StringBuilder("SELECT ");
                StringBuilder ins = new StringBuilder("INSERT INTO " + t + " (");
                StringBuilder qs = new StringBuilder();
                for (int i = 0; i < use.size(); i++) {
                    if (i > 0) { sel.append(", "); ins.append(", "); qs.append(", "); }
                    sel.append(use.get(i)); ins.append(use.get(i)); qs.append("?");
                }
                sel.append(" FROM ").append(t);
                ins.append(") VALUES (").append(qs).append(")");

                long rows = 0;
                try (Statement so = ora.createStatement();
                     ResultSet rs = so.executeQuery(sel.toString());
                     PreparedStatement ps = ma.prepareStatement(ins.toString())) {
                    ResultSetMetaData md = rs.getMetaData();
                    int n = md.getColumnCount();
                    int batch = 0;
                    while (rs.next()) {
                        for (int i = 1; i <= n; i++) {
                            int ct = md.getColumnType(i);
                            if (ct == Types.CLOB || ct == Types.NCLOB
                                    || ct == Types.LONGVARCHAR || ct == Types.LONGNVARCHAR) {
                                ps.setString(i, rs.getString(i));
                            } else if (ct == Types.BLOB || ct == Types.VARBINARY || ct == Types.LONGVARBINARY) {
                                ps.setBytes(i, rs.getBytes(i));
                            } else if (ct == Types.TIMESTAMP || ct == Types.DATE) {
                                ps.setTimestamp(i, rs.getTimestamp(i));
                            } else {
                                ps.setObject(i, rs.getObject(i));
                            }
                        }
                        ps.addBatch();
                        rows++;
                        if (++batch >= 500) { ps.executeBatch(); batch = 0; }
                    }
                    if (batch > 0) ps.executeBatch();
                }
                ma.commit();
                copied++;
                System.out.println(String.format("%-30s %6d rows", t, rows));
            }
            try (Statement s = ma.createStatement()) {
                s.execute("SET FOREIGN_KEY_CHECKS=1");
            }
            ma.commit();
            System.out.println("copied tables: " + copied);
        }
    }

    static long count(Connection c, String t) throws SQLException {
        try (Statement s = c.createStatement(); ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM " + t)) {
            rs.next();
            return rs.getLong(1);
        }
    }

    static Set<String> cols(Connection c, String t) throws SQLException {
        Set<String> out = new LinkedHashSet<>();
        try (Statement s = c.createStatement(); ResultSet rs = s.executeQuery("SELECT * FROM " + t + " WHERE 1=0")) {
            ResultSetMetaData md = rs.getMetaData();
            for (int i = 1; i <= md.getColumnCount(); i++) out.add(md.getColumnName(i).toUpperCase());
        }
        return out;
    }
}
