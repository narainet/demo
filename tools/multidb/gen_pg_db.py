# -*- coding: utf-8 -*-
"""제품 newdb(Oracle) → PostgreSQL 설치 세트 전량 생성 (2026-08-05)

MariaDB 판(gen_maria_db.py, 8/3)과 달리 PG 는 COMMENT ON 이 네이티브라
12_comments.sql 을 그대로 통과시킨다(인라인 주입 불요). 대신 PG 고유 처리:
  · 식별자 큰따옴표 전면 제거 — PG 는 따옴표 없으면 소문자 폴딩. 매퍼 SQL 이
    전부 비따옴표라, DDL 도 비따옴표로 만들어야 카탈로그가 일치한다.
  · CREATE UNIQUE INDEX PK_X + ALTER..ADD CONSTRAINT PK_X PRIMARY KEY 쌍은
    PG 에서 이름 충돌(제약이 동명 인덱스를 자체 생성) → 선행 인덱스 문을 생략.
  · DATE → TIMESTAMP (PG DATE 는 시각 소실), TO_DATE(시각포맷) → TO_TIMESTAMP.
  · SYSDATE→LOCALTIMESTAMP, SYSTIMESTAMP→CURRENT_TIMESTAMP, FROM DUAL 제거.
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

# ── 타입 변환 ───────────────────────────────────────────────
def conv_types(s):
    s = re.sub(r'VARCHAR2\s*\(\s*(\d+)\s*(?:CHAR|BYTE)?\s*\)', r'VARCHAR(\1)', s, flags=re.I)
    s = re.sub(r'NVARCHAR2\s*\(\s*(\d+)\s*\)', r'VARCHAR(\1)', s, flags=re.I)
    s = re.sub(r'\bCHAR\s*\(\s*(\d+)\s*(?:CHAR|BYTE)\s*\)', r'CHAR(\1)', s, flags=re.I)
    s = re.sub(r'\bNUMBER\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)', r'NUMERIC(\1,\2)', s, flags=re.I)
    def num1(m):
        p = int(m.group(1))
        return 'SMALLINT' if p <= 4 else 'INT' if p <= 9 else 'BIGINT' if p <= 18 else 'NUMERIC(%d)' % p
    s = re.sub(r'\bNUMBER\s*\(\s*(\d+)\s*\)', num1, s, flags=re.I)
    s = re.sub(r'\bNUMBER\b(?!\s*\()', 'NUMERIC', s, flags=re.I)
    s = re.sub(r'\b(?:NCLOB|CLOB)\b', 'TEXT', s, flags=re.I)
    s = re.sub(r'\bBLOB\b', 'BYTEA', s, flags=re.I)
    s = re.sub(r'\bRAW\s*\(\s*\d+\s*\)', 'BYTEA', s, flags=re.I)
    # Oracle DATE 는 시각 보유 → PG DATE 는 시각 소실이라 TIMESTAMP 로
    s = re.sub(r'\bDATE\b(?=\s*(?:,|\)|NOT|NULL|DEFAULT|$))', 'TIMESTAMP', s, flags=re.I)
    return s

# ── 공통(DDL) 변환 ──────────────────────────────────────────
def conv_common(s):
    s = re.sub(r'\bSYSTIMESTAMP\b', 'CURRENT_TIMESTAMP', s, flags=re.I)
    s = re.sub(r'\bSYSDATE\b', 'LOCALTIMESTAMP', s, flags=re.I)
    s = s.replace('"', '')
    s = re.sub(r'\s+ENABLE\b', '', s, flags=re.I)
    s = re.sub(r'\s+USING\s+INDEX(\s+[A-Z_0-9]+)?\s*', ' ', s, flags=re.I)
    s = re.sub(r'\b(?:PCTFREE|PCTUSED|INITRANS|MAXTRANS|TABLESPACE|STORAGE|LOGGING|NOCOMPRESS|NOCACHE|NOPARALLEL)\b[^,;\n]*', '', s, flags=re.I)
    s = re.sub(r'\bNVL\s*\(', 'COALESCE(', s, flags=re.I)
    s = re.sub(r'\s+FROM\s+DUAL\b', '', s, flags=re.I)
    return s

# ── 시드 변환 ───────────────────────────────────────────────
def conv_seed(s):
    s = re.sub(r'\bSYSTIMESTAMP\b', 'CURRENT_TIMESTAMP', s, flags=re.I)
    s = re.sub(r'\bSYSDATE\b', 'LOCALTIMESTAMP', s, flags=re.I)
    # PG TO_DATE 는 시각을 버린다 — 포맷에 시각 토큰이 있으면 TO_TIMESTAMP 로
    def todate(m):
        val, fmt = m.group(1), m.group(2)
        fn = 'TO_TIMESTAMP' if re.search(r'HH|MI|SS', fmt, re.I) else 'TO_DATE'
        return "%s('%s','%s')" % (fn, val, fmt)
    s = re.sub(r"TO_DATE\(\s*'([^']*)'\s*,\s*'([^']*)'\s*\)", todate, s, flags=re.I)
    # CAST(NULL AS VARCHAR2(n)) 등 시드 내 타입 표기
    s = re.sub(r'\bVARCHAR2\s*\(\s*(\d+)\s*\)', r'VARCHAR(\1)', s, flags=re.I)
    s = re.sub(r'\bAS\s+NUMBER\s*\(\s*\d+\s*(?:,\s*\d+\s*)?\)', 'AS NUMERIC', s, flags=re.I)
    # SELECT ROWNUM (순번 생성 용도) → 윈도 함수
    s = re.sub(r'(?i)(\bSELECT\s+)ROWNUM\b(?=\s*,)', r'\1ROW_NUMBER() OVER ()', s)
    s = re.sub(r'\bNVL\s*\(', 'COALESCE(', s, flags=re.I)
    s = re.sub(r'\s+FROM\s+DUAL\b', '', s, flags=re.I)
    s = s.replace('"', '')
    return s

HDR_MAP = lambda product, schema: (
    ('신규 스키마 RLMS 클린 설치 세트', '%s(PostgreSQL) 클린 설치 세트' % product),
    ('LexPortal(송무 단독) 클린 설치 세트', 'LexPortal(송무 단독, PostgreSQL) 클린 설치 세트'),
    ('RegNex(규정 단독) 클린 설치 세트', 'RegNex(규정 단독, PostgreSQL) 클린 설치 세트'),
    ('LexPortal 클린 설치 세트', 'LexPortal(PostgreSQL) 클린 설치 세트'),
    ('RegNex 클린 설치 세트', 'RegNex(PostgreSQL) 클린 설치 세트'),
    ('실행 계정: RLMS', '실행 계정: %s' % schema),
    ('실행 계정: lexportal', '실행 계정: %s' % schema),
    ('실행 계정: regnex', '실행 계정: %s' % schema),
)

def apply_hdr(text, product, schema):
    for a, b in HDR_MAP(product, schema):
        text = text.replace(a, b)
    return text

def strip_sqlplus(text):
    return re.sub(r'(?im)^[ \t]*SET[ \t]+DEFINE[ \t]+\w+[ \t]*;?[ \t]*$\n?', '', text)

def pk_constraint_names(text):
    """ALTER TABLE .. ADD CONSTRAINT X PRIMARY KEY 로 만들어질 제약 이름 집합 —
       같은 이름의 선행 CREATE UNIQUE INDEX 는 PG 에서 충돌하므로 생략 대상."""
    return set(m.group(1).upper() for m in re.finditer(
        r'ADD\s+CONSTRAINT\s+"?([A-Z_0-9]+)"?\s+PRIMARY\s+KEY', text, re.I))

def build_tables(src, dst, product, schema):
    text = apply_hdr(rd(src), product, schema)
    pknames = pk_constraint_names(text)
    stmts = split_stmts(text)
    out, header_done, ntbl, nview, nskip = [], False, 0, 0, 0
    for st in stmts:
        u = st.upper()
        if re.search(r'\bCREATE TABLE\b', u):
            if not header_done:
                cut = st.find('-- TABLE')
                if cut < 0:
                    cut = u.find('CREATE ')
                h = st[:cut]
                h = h.replace('원천: DBMS_METADATA.GET_DDL (스키마 한정자/스토리지 절 제거).',
                              '원천: Oracle DDL 자동변환 — VARCHAR2→VARCHAR, NUMBER→INT/NUMERIC, CLOB→TEXT, DATE→TIMESTAMP.\n'
                              '-- ※ 식별자 큰따옴표 전면 제거(PG 소문자 폴딩 ← 매퍼 SQL 비따옴표와 일치).\n'
                              '-- ※ 컬럼/테이블 코멘트는 12_comments.sql(COMMENT ON — PG 네이티브)이 담당.')
                out.append(h)
                st = st[cut:]
                header_done = True
            m = re.search(r'CREATE UNIQUE INDEX\s+"?([A-Z_0-9]+)"?', st, re.I)
            # CREATE TABLE 문 청크 안에 뒤따르는 인덱스가 섞여 있지는 않다(문장 단위 분리라 무관)
            st = conv_common(conv_types(st))
            st = re.sub(r'[ \t]+\n', '\n', st)
            st = re.sub(r'\n{3,}', '\n\n', st)
            out.append(st)
            ntbl += 1
        elif re.search(r'\bCREATE\s+UNIQUE\s+INDEX\b', u):
            m = re.search(r'CREATE\s+UNIQUE\s+INDEX\s+"?([A-Z_0-9]+)"?', st, re.I)
            if m and m.group(1).upper() in pknames:
                # PK 제약이 동명 인덱스를 자체 생성 — 선행 인덱스는 이름 충돌이라 생략
                nskip += 1
                lead = st[:st.upper().find('CREATE')]
                if lead.strip():
                    out.append(lead.rstrip() + '\n')
                continue
            out.append(conv_common(conv_types(st)))
        elif re.search(r'\bCREATE\b', u) and re.search(r'\bVIEW\b', u):
            v = conv_common(st)
            v = re.sub(r'\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:FORCE\s+|NONEDITIONABLE\s+)*VIEW\b',
                       'CREATE OR REPLACE VIEW', v, flags=re.I)
            out.append(v)
            nview += 1
        elif st.strip():
            out.append(conv_common(conv_types(st)))
    out.append(DUAL_BLOCK)          # ★필수 — 아래 상수 주석 참고
    wr(dst, "".join(out))
    return ntbl, nview, nskip

# ⛔PostgreSQL 에는 DUAL 이 없다. 그런데 URL 인가에 쓰이는 공유 SQL
#   (context-security.xml 안에 인라인으로 박혀 있어 매퍼 변환 대상이 아니다)이
#   FROM DUAL 을 대량으로 쓴다. 이 테이블을 빼면 **로그인 후 모든 화면이 403** 이 된다.
#   2026-08-06: 생성기가 이 블록을 빠뜨려 실제로 유실된 적이 있어 상수로 고정한다.
DUAL_BLOCK = """
--------------------------------------------------------------------------------
-- Oracle 호환 DUAL (1행) — 공유 인가 SQL(context-security.xml 쌍둥이)이
-- FROM DUAL 을 대량 사용하므로 PG 에도 동명 테이블을 둔다(고전 이식 심).
-- 매퍼(*_SQL_postgres.xml)는 FROM DUAL 을 이미 제거했으므로 이 테이블 미의존.
--------------------------------------------------------------------------------
CREATE TABLE DUAL (DUMMY VARCHAR(1));
INSERT INTO DUAL VALUES ('X');
COMMENT ON TABLE DUAL IS 'Oracle 호환 DUAL(1행) — 공유 인가 SQL(context-security)의 FROM DUAL 지원용';
COMMENT ON COLUMN DUAL.DUMMY IS '더미(X 1행 고정)';
"""


def build_plain(src, dst, product, schema, seed=False):
    text = strip_sqlplus(apply_hdr(rd(src), product, schema))
    out = []
    for st in split_stmts(text):
        if re.match(r'\s*SET\s+DEFINE', st, re.I):
            continue
        st = conv_seed(st) if seed else conv_common(conv_types(st))
        out.append(st)
    wr(dst, "".join(out))
    return sum(1 for s in out if s.strip() and not s.strip().startswith('--'))

def build_comments(src, dst, product, schema):
    """PG 는 COMMENT ON 네이티브 — 헤더만 바꾸고 통과(따옴표 제거만)."""
    text = strip_sqlplus(apply_hdr(rd(src), product, schema))
    text = text.replace('-- 12_comments.sql — 테이블/컬럼 코멘트',
                        '-- 12_comments.sql — 테이블/컬럼 코멘트 (PostgreSQL — COMMENT ON 네이티브, Oracle 판 그대로)')
    text = text.replace('"', '')
    wr(dst, text)
    return len(re.findall(r'(?i)\bCOMMENT\s+ON\b', text))

def build_mixed(src, dst, product, schema):
    """15_law_install(DDL+코멘트+시드 혼합) — PG 는 COMMENT ON 을 그대로 두는 점이 maria 와 다르다."""
    text = strip_sqlplus(apply_hdr(rd(src), product, schema))
    pknames = pk_constraint_names(text)
    out, ntbl, ncmt, nins, nskip = [], 0, 0, 0, 0
    for st in split_stmts(text):
        u = st.upper()
        if re.search(r'\bCREATE TABLE\b', u):
            out.append(conv_common(conv_types(st)))
            ntbl += 1
        elif re.search(r'\bCOMMENT\s+ON\b', u):
            out.append(st.replace('"', ''))
            ncmt += 1
        elif re.search(r'\bCREATE\s+UNIQUE\s+INDEX\b', u):
            m = re.search(r'CREATE\s+UNIQUE\s+INDEX\s+"?([A-Z_0-9]+)"?', st, re.I)
            if m and m.group(1).upper() in pknames:
                nskip += 1
                continue
            out.append(conv_common(conv_types(st)))
        elif re.search(r'\bCREATE\s+INDEX\b', u) or re.search(r'\bALTER\s+TABLE\b', u):
            out.append(conv_common(conv_types(st)))
        else:
            if st.strip():
                out.append(conv_seed(st))
                if 'INSERT' in u:
                    nins += 1
    wr(dst, "".join(out))
    return ntbl, ncmt, nins, nskip

if __name__ == '__main__':
    for product, schema in (('LexPortal', 'lexportal'), ('RegNex', 'regnex'), ('RLMS', 'rlms')):
        src = os.path.join(WS, product, 'database', 'newdb')
        dst = os.path.join(WS, product, 'database', 'postgres')
        nt, nv, nskip = build_tables(os.path.join(src, '10_tables.sql'),
                                     os.path.join(dst, '10_tables.sql'), product, schema)
        print('%s: 테이블 %d · 뷰 %d · PK동명인덱스 생략 %d' % (product, nt, nv, nskip))
        nc = build_comments(os.path.join(src, '12_comments.sql'),
                            os.path.join(dst, '12_comments.sql'), product, schema)
        print('   %-26s COMMENT %d' % ('12_comments.sql', nc))
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
            nt2, nc2, ni2, ns2 = build_mixed(law, os.path.join(dst, '15_law_install.sql'), product, schema)
            print('   %-26s 테이블 %d · COMMENT %d · INSERT %d · PK동명인덱스 생략 %d' % ('15_law_install.sql', nt2, nc2, ni2, ns2))
