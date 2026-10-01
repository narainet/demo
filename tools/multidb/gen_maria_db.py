# -*- coding: utf-8 -*-
"""제품 newdb(Oracle) → MariaDB 설치 세트 전량 생성 (2026-08-03)

핵심: MariaDB 는 COMMENT ON 문이 없어 컬럼 코멘트를 별도로 못 붙인다.
      → 12_comments.sql 을 파싱해 CREATE TABLE 컬럼 정의에 인라인 COMMENT 로 주입.
      (DDL 코멘트 필수 규약 유지)
"""
import io, os, re, sys
import os as _os
# 워크스페이스 루트. 다른 경로에 설치했으면 환경변수 RLMS_WS 로 지정한다.
_WS = _os.environ.get("RLMS_WS", "C:/eGovFrameDev-4.3.1-64bit/workspace")

WS = _WS

def rd(p):
    with io.open(p, encoding="utf-8-sig") as f:
        return f.read().replace("\r\n", "\n")

def wr(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with io.open(p, "w", encoding="utf-8", newline="") as f:
        f.write(s)

def split_stmts(text):
    out, cur, inq = [], "", False
    for ch in text:
        cur += ch
        if ch == "'":
            inq = not inq
        elif ch == ";" and not inq:
            out.append(cur); cur = ""
    if cur.strip():
        out.append(cur)
    return out

def esc(s):
    return s.replace("\\", "\\\\").replace("'", "''")

# ── 1) 코멘트 파싱 ──────────────────────────────────────────
def parse_comments(path):
    tbl, col = {}, {}
    for m in re.finditer(r"COMMENT ON TABLE\s+(\S+)\s+IS\s+'((?:[^']|'')*)'", rd(path), re.I):
        tbl[m.group(1).upper()] = m.group(2)
    for m in re.finditer(r"COMMENT ON COLUMN\s+(\S+?)\.(\S+)\s+IS\s+'((?:[^']|'')*)'", rd(path), re.I):
        col.setdefault(m.group(1).upper(), {})[m.group(2).upper()] = m.group(3)
    return tbl, col

# ── 2) 타입/공통 변환 ───────────────────────────────────────
def conv_types(s):
    s = re.sub(r'VARCHAR2\s*\(\s*(\d+)\s*(?:CHAR|BYTE)?\s*\)', r'VARCHAR(\1)', s, flags=re.I)
    s = re.sub(r'NVARCHAR2\s*\(\s*(\d+)\s*\)', r'VARCHAR(\1)', s, flags=re.I)
    # CHAR(4 CHAR) / CHAR(30 BYTE) — Oracle 길이 의미자 제거 (\b 라 VARCHAR(n) 은 안 걸린다)
    s = re.sub(r'\bCHAR\s*\(\s*(\d+)\s*(?:CHAR|BYTE)\s*\)', r'CHAR(\1)', s, flags=re.I)
    s = re.sub(r'\bNUMBER\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)', r'DECIMAL(\1,\2)', s, flags=re.I)
    def num1(m):
        p = int(m.group(1))
        return 'SMALLINT' if p <= 4 else 'INT' if p <= 9 else 'BIGINT' if p <= 18 else 'DECIMAL(%d)' % p
    s = re.sub(r'\bNUMBER\s*\(\s*(\d+)\s*\)', num1, s, flags=re.I)
    s = re.sub(r'\bNUMBER\b(?!\s*\()', 'DECIMAL(38,10)', s, flags=re.I)
    s = re.sub(r'\b(?:NCLOB|CLOB)\b', 'LONGTEXT', s, flags=re.I)
    s = re.sub(r'\bBLOB\b', 'LONGBLOB', s, flags=re.I)
    s = re.sub(r'\bRAW\s*\(\s*(\d+)\s*\)', r'VARBINARY(\1)', s, flags=re.I)
    s = re.sub(r'\bTIMESTAMP\s*\(\s*\d+\s*\)', 'DATETIME(6)', s, flags=re.I)
    s = re.sub(r'\bDATE\b(?=\s*(?:,|\)|NOT|NULL|DEFAULT|$))', 'DATETIME', s, flags=re.I)
    return s

def conv_common(s):
    s = re.sub(r'\bSYSTIMESTAMP\b', 'NOW(6)', s, flags=re.I)
    s = re.sub(r'\bSYSDATE\b', 'NOW()', s, flags=re.I)
    s = s.replace('"', '')
    s = re.sub(r'\s+ENABLE\b', '', s, flags=re.I)
    s = re.sub(r'\s+USING\s+INDEX(\s+[A-Z_0-9]+)?\s*', ' ', s, flags=re.I)
    s = re.sub(r'\b(?:PCTFREE|PCTUSED|INITRANS|MAXTRANS|TABLESPACE|STORAGE|LOGGING|NOCOMPRESS|NOCACHE|NOPARALLEL)\b[^,;\n]*', '', s, flags=re.I)
    return s

# Oracle 날짜포맷 → MySQL/MariaDB 포맷. 긴 토큰부터 매칭해야 HH24 가 HH 로 잘리지 않는다.
_FMT = [('YYYY', '%Y'), ('RRRR', '%Y'), ('HH24', '%H'), ('HH12', '%h'),
        ('MON', '%b'), ('DAY', '%W'),
        ('MM', '%m'), ('DD', '%d'), ('HH', '%h'), ('MI', '%i'), ('SS', '%s'), ('YY', '%y')]

def ora_fmt(f):
    out, i, F = '', 0, f.upper()
    while i < len(F):
        for k, v in _FMT:
            if F.startswith(k, i):
                out += v
                i += len(k)
                break
        else:
            out += f[i]
            i += 1
    return out

def conv_seed(s):
    """시드 INSERT 의 Oracle 함수 변환"""
    s = re.sub(r'\bSYSTIMESTAMP\b', 'NOW(6)', s, flags=re.I)
    s = re.sub(r'\bSYSDATE\b', 'NOW()', s, flags=re.I)
    # TO_DATE('2026-07-11 10:09:49','YYYY-MM-DD HH24:MI:SS') → STR_TO_DATE(...)
    s = re.sub(r"TO_DATE\(\s*'([^']*)'\s*,\s*'([^']*)'\s*\)",
               lambda m: "STR_TO_DATE('%s','%s')" % (m.group(1), ora_fmt(m.group(2))), s, flags=re.I)
    # TO_CHAR(expr,'fmt') → DATE_FORMAT(expr,'fmt')  (숫자 포맷은 대상 아님 — 시드엔 날짜만)
    s = re.sub(r"TO_CHAR\(\s*([^,()]*(?:\([^()]*\))?[^,()]*)\s*,\s*'([^']*)'\s*\)",
               lambda m: "DATE_FORMAT(%s,'%s')" % (m.group(1).strip(), ora_fmt(m.group(2))), s, flags=re.I)
    # CAST(NULL AS VARCHAR2(n)) → MariaDB CAST 는 CHAR 만 받는다
    s = re.sub(r'\bAS\s+(?:VARCHAR2|NVARCHAR2|VARCHAR)\s*\(\s*(\d+)\s*\)', r'AS CHAR(\1)', s, flags=re.I)
    s = re.sub(r'\bAS\s+NUMBER\s*\(\s*\d+\s*(?:,\s*\d+\s*)?\)', 'AS DECIMAL', s, flags=re.I)
    # SELECT ROWNUM (순번 생성 용도) → 윈도 함수
    s = re.sub(r'(?i)(\bSELECT\s+)ROWNUM\b(?=\s*,)', r'\1ROW_NUMBER() OVER ()', s)
    s = re.sub(r'\bNVL\s*\(', 'IFNULL(', s, flags=re.I)
    return s

# ── 3) CREATE TABLE 에 코멘트 주입 ──────────────────────────
def inject_comments(stmt, tbl_c, col_c):
    m = re.search(r'CREATE TABLE\s+([A-Z_0-9]+)', stmt, re.I)
    if not m:
        return stmt
    name = m.group(1).upper()
    cols = col_c.get(name, {})
    lines = stmt.split('\n')
    out = []
    for ln in lines:
        # "  COL_NAME TYPE ...," 형태의 컬럼 정의 줄만 대상 (제약 줄 제외)
        cm = re.match(r'^(\s*)([A-Z_0-9]+)(\s+(?:VARCHAR|CHAR|INT|SMALLINT|BIGINT|DECIMAL|LONGTEXT|LONGBLOB|DATETIME|VARBINARY|FLOAT|DOUBLE)\b.*?)(,?)\s*$', ln, re.I)
        if cm and cm.group(2).upper() not in ('CONSTRAINT', 'PRIMARY', 'UNIQUE', 'FOREIGN', 'KEY', 'CHECK'):
            col = cm.group(2).upper()
            c = cols.get(col)
            if c and 'COMMENT' not in cm.group(3).upper():
                ln = "%s%s%s COMMENT '%s'%s" % (cm.group(1), cm.group(2), cm.group(3).rstrip(), esc(c), cm.group(4))
        out.append(ln)
    stmt = '\n'.join(out)
    tc = tbl_c.get(name)
    return stmt, tc

def build_tables(src, dst, tbl_c, col_c, product, schema):
    text = rd(src)
    stmts = split_stmts(text)
    out, header_done, ntbl, nview, ncmt = [], False, 0, 0, 0
    for st in stmts:
        u = st.upper()
        if re.search(r'\bCREATE TABLE\b', u):
            if not header_done:
                cut = st.find('-- TABLE')
                if cut < 0:
                    cut = u.find('CREATE ')
                h = st[:cut]
                for a, b in (('신규 스키마 RLMS 클린 설치 세트', '%s(MariaDB) 클린 설치 세트' % product),
                             ('LexPortal(송무 단독) 클린 설치 세트', 'LexPortal(송무 단독, MariaDB) 클린 설치 세트'),
                             ('RegNex(규정 단독) 클린 설치 세트', 'RegNex(규정 단독, MariaDB) 클린 설치 세트'),
                             ('실행 계정: RLMS', '실행 계정: %s' % schema),
                             ('실행 계정: lexportal', '실행 계정: %s' % schema),
                             ('실행 계정: regnex', '실행 계정: %s' % schema),
                             ('원천: DBMS_METADATA.GET_DDL (스키마 한정자/스토리지 절 제거).',
                              '원천: Oracle DDL 자동변환 — VARCHAR2→VARCHAR, NUMBER→INT/DECIMAL, CLOB→LONGTEXT, DATE→DATETIME.\n-- ※ MariaDB 는 COMMENT ON 문이 없어 컬럼 코멘트를 컬럼 정의에 인라인으로 넣었다(코멘트 필수 규약 유지).')):
                    h = h.replace(a, b)
                out.append(h)
                st = st[cut:]
                header_done = True
            st = conv_common(conv_types(st))
            st, tc = inject_comments(st, tbl_c, col_c)
            ncmt += st.count("COMMENT '")
            st = re.sub(r'[ \t]+\n', '\n', st)
            st = re.sub(r'\n{3,}', '\n\n', st).rstrip().rstrip(';')
            tail = "\n  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci"
            if tc:
                tail += " COMMENT='%s'" % esc(tc)
                ncmt += 1
            out.append(st + tail + ";\n")
            ntbl += 1
        elif re.search(r'\bCREATE\b', u) and re.search(r'\bVIEW\b', u):
            v = conv_common(st)
            v = re.sub(r'\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:FORCE\s+|NONEDITIONABLE\s+)*VIEW\b', 'CREATE OR REPLACE VIEW', v, flags=re.I)
            out.append(v)
            nview += 1
        elif st.strip():
            out.append(conv_common(st))
    wr(dst, "".join(out))
    return ntbl, nview, ncmt

def build_plain(src, dst, product, schema, seed=False):
    """인덱스/FK/시드 — 문장 단위 변환"""
    text = rd(src)
    for a, b in (('신규 스키마 RLMS 클린 설치 세트', '%s(MariaDB) 클린 설치 세트' % product),
                 ('LexPortal(송무 단독) 클린 설치 세트', 'LexPortal(송무 단독, MariaDB) 클린 설치 세트'),
                 ('RegNex(규정 단독) 클린 설치 세트', 'RegNex(규정 단독, MariaDB) 클린 설치 세트'),
                 ('LexPortal 클린 설치 세트', 'LexPortal(MariaDB) 클린 설치 세트'),
                 ('RegNex 클린 설치 세트', 'RegNex(MariaDB) 클린 설치 세트'),
                 ('실행 계정: RLMS', '실행 계정: %s' % schema),
                 ('실행 계정: lexportal', '실행 계정: %s' % schema),
                 ('실행 계정: regnex', '실행 계정: %s' % schema)):
        text = text.replace(a, b)
    text = re.sub(r'(?im)^[ \t]*SET[ \t]+DEFINE[ \t]+\w+[ \t]*;?[ \t]*$\n?', '', text)   # sqlplus 지시어(MariaDB 문법 아님)
    out = []
    for st in split_stmts(text):
        if re.match(r'\s*SET\s+DEFINE', st, re.I):   # sqlplus 지시어 — MariaDB 문법 아님
            continue
        u = st.upper()
        if seed:
            st = conv_seed(st)
        else:
            st = conv_common(st)
        # FROM DUAL 은 MariaDB 도 지원 — 그대로 둔다
        out.append(st)
    wr(dst, "".join(out))
    n = sum(1 for s in out if s.strip() and not s.strip().startswith('--'))
    return n

def build_mixed(src, dst, product, schema):
    """DDL + 코멘트 + 시드가 한 파일에 섞인 설치본(15_law_install) 전용.
       COMMENT ON 은 MariaDB 에 없으므로 파일 자체에서 파싱해 CREATE TABLE 에 인라인 주입."""
    text = rd(src)
    for a, b in (('실행 계정: RLMS', '실행 계정: %s' % schema),
                 ('실행 계정: lexportal', '실행 계정: %s' % schema)):
        text = text.replace(a, b)
    text = re.sub(r'(?im)^[ \t]*SET[ \t]+DEFINE[ \t]+\w+[ \t]*;?[ \t]*$\n?', '', text)
    # 파일 내 COMMENT ON 파싱
    tbl_c, col_c = {}, {}
    for m in re.finditer(r"COMMENT ON TABLE\s+(\S+)\s+IS\s+'((?:[^']|'')*)'", text, re.I):
        tbl_c[m.group(1).upper()] = m.group(2)
    for m in re.finditer(r"COMMENT ON COLUMN\s+(\S+?)\.(\S+)\s+IS\s+'((?:[^']|'')*)'", text, re.I):
        col_c.setdefault(m.group(1).upper(), {})[m.group(2).upper()] = m.group(3)

    out, ntbl, ncmt, nins = [], 0, 0, 0
    for st in split_stmts(text):
        u = st.upper()
        if re.search(r'\bCOMMENT\s+ON\b', u):
            # 주석 헤더만 남기고 COMMENT ON 문 자체는 버린다(인라인으로 옮겨감)
            continue
        if re.search(r'\bCREATE TABLE\b', u):
            st = conv_common(conv_types(st))
            st, tc = inject_comments(st, tbl_c, col_c)
            ncmt += st.count("COMMENT '")
            st = re.sub(r'[ \t]+\n', '\n', st).rstrip().rstrip(';')
            tail = "\n  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci"
            if tc:
                tail += " COMMENT='%s'" % esc(tc)
                ncmt += 1
            out.append(st + tail + ";\n")
            ntbl += 1
        elif re.search(r'\bCREATE\s+(?:UNIQUE\s+)?INDEX\b', u) or re.search(r'\bALTER\s+TABLE\b', u):
            out.append(conv_common(st))
        else:
            if st.strip():
                out.append(conv_seed(st))
                if 'INSERT' in u:
                    nins += 1
    # 헤더에 변환 사실 명시
    body = "".join(out)
    body = body.replace('-- ============================================================================',
                        '-- ============================================================================', 1)
    wr(dst, body)
    return ntbl, ncmt, nins

if __name__ == '__main__':
    for product, schema in (('LexPortal', 'lexportal'), ('RegNex', 'regnex'), ('RLMS', 'rlms')):
        src = os.path.join(WS, product, 'database', 'newdb')
        dst = os.path.join(WS, product, 'database', 'maria')
        tbl_c, col_c = parse_comments(os.path.join(src, '12_comments.sql'))
        nt, nv, nc = build_tables(os.path.join(src, '10_tables.sql'),
                                  os.path.join(dst, '10_tables.sql'), tbl_c, col_c, product, schema)
        print('%s: 테이블 %d · 뷰 %d · 코멘트 %d 주입' % (product, nt, nv, nc))
        for f, is_seed in (('11_indexes.sql', False), ('30_fks.sql', False),
                           ('20_seed_ccm.sql', True), ('21_seed_menu.sql', True),
                           ('22_seed_auth.sql', True), ('23_seed_org_accounts.sql', True),
                           ('24_seed_bbs.sql', True), ('26_seed_idgn.sql', True),
                           ('25_seed_brand.sql', True), ('25_seed_domain.sql', True)):
            sp = os.path.join(src, f)
            if os.path.exists(sp):
                n = build_plain(sp, os.path.join(dst, f), product, schema, is_seed)
                print('   %-26s %d stmts' % (f, n))
        law = os.path.join(src, '15_law_install.sql')
        if os.path.exists(law):
            nt2, nc2, ni2 = build_mixed(law, os.path.join(dst, '15_law_install.sql'), product, schema)
            print('   %-26s 테이블 %d · 코멘트 %d · INSERT %d' % ('15_law_install.sql', nt2, nc2, ni2))
