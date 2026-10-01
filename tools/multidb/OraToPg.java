import java.sql.*;
import java.util.*;

/**
 * Oracle → PostgreSQL 표본 데이터 복사기 (2026-08-05, OraToMaria 포크).
 * 규칙: 양쪽에 존재하는 테이블 중 "PG 0행 & oracle 1행 이상"만 복사(시드 적재분 보호).
 * 컬럼은 이름 교집합만(제품별 컬럼 드리프트 안전).
 * FK 는 session_replication_role=replica 로 우회 — ★PG 접속은 superuser(postgres) 필수.
 * 마지막에 COMTECOPSEQ 채번을 Oracle 라이브 값으로 동기(시드 0행 아님 → 복사 규칙 밖이라 별도 단계.
 * 시드 채번이 복사된 로그 ID 와 충돌한 WEBLOG dup PK 실사고 재발 방지).
 * usage: OraToPg <oraUrl> <oraUser> <oraPw> <pgUrl> <pgSuperUser> <pgSuperPw>
 */
public class OraToPg {

    public static void main(String[] args) throws Exception {
        try (Connection ora = DriverManager.getConnection(args[0], args[1], args[2]);
             Connection pg = DriverManager.getConnection(args[3], args[4], args[5])) {
            pg.setAutoCommit(false);
            try (Statement s = pg.createStatement()) {
                s.execute("SET session_replication_role = replica");
            }

            List<String> tables = new ArrayList<>();
            try (Statement s = pg.createStatement();
                 ResultSet rs = s.executeQuery(
                     "SELECT table_name FROM information_schema.tables " +
                     "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name")) {
                while (rs.next()) tables.add(rs.getString(1));
            }

            int copied = 0;
            for (String t : tables) {
                if (t.equalsIgnoreCase("dual")) continue;   // 호환 심 — 복사 대상 아님
                long pCnt = count(pg, t);
                if (pCnt > 0) continue;
                long oCnt;
                try {
                    oCnt = count(ora, t);
                } catch (SQLException e) {
                    continue;   // oracle 에 없는 테이블
                }
                if (oCnt == 0) continue;

                Set<String> pCols = cols(pg, t), oCols = cols(ora, t);
                List<String> use = new ArrayList<>();
                for (String c : oCols) if (pCols.contains(c)) use.add(c);
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
                     PreparedStatement ps = pg.prepareStatement(ins.toString())) {
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
                pg.commit();
                copied++;
                System.out.println(String.format("%-30s %6d rows", t, rows));
            }
            System.out.println("copied tables: " + copied);

            // ── COMTECOPSEQ 채번 동기(라이브 값 우선 — 있으면 UPDATE, 없으면 INSERT) ──
            int upd = 0, insd = 0;
            try (Statement so = ora.createStatement();
                 ResultSet rs = so.executeQuery("SELECT TABLE_NAME, NEXT_ID FROM COMTECOPSEQ");
                 PreparedStatement pu = pg.prepareStatement(
                         "UPDATE COMTECOPSEQ SET NEXT_ID = ? WHERE TABLE_NAME = ?");
                 PreparedStatement pi = pg.prepareStatement(
                         "INSERT INTO COMTECOPSEQ (TABLE_NAME, NEXT_ID) VALUES (?, ?)")) {
                while (rs.next()) {
                    String name = rs.getString(1);
                    java.math.BigDecimal next = rs.getBigDecimal(2);
                    pu.setBigDecimal(1, next);
                    pu.setString(2, name);
                    if (pu.executeUpdate() == 0) {
                        pi.setString(1, name);
                        pi.setBigDecimal(2, next);
                        pi.executeUpdate();
                        insd++;
                    } else {
                        upd++;
                    }
                }
            }
            pg.commit();
            System.out.println("COMTECOPSEQ sync: update " + upd + ", insert " + insd);

            try (Statement s = pg.createStatement()) {
                s.execute("SET session_replication_role = DEFAULT");
            }
            pg.commit();
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
