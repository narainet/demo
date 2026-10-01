# -*- coding: utf-8 -*-
"""제품 분리 DDL 세트 생성기 — RLMS newdb + 라이브 설정 덤프 → LexPortal/RegNex database/newdb"""
import io, os, re, sys
import os as _os
# 워크스페이스 루트. 다른 경로에 설치했으면 환경변수 RLMS_WS 로 지정한다.
_WS = _os.environ.get("RLMS_WS", "C:/eGovFrameDev-4.3.1-64bit/workspace")

RLMS = _WS + "/RLMS"
NEWDB = RLMS + "/database/newdb"
DUMP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dump")
LEX = _WS + "/LexPortal/database/newdb"
REG = _WS + "/RegNex/database/newdb"

def rd(p):
    with io.open(p, encoding="utf-8-sig") as f:
        return f.read().replace("\r\n", "\n")

def wr(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with io.open(p, "w", encoding="utf-8", newline="") as f:
        f.write(s)

# ── INSERT 문 파서: (콜럼리스트, 값리스트, 원문) ──────────────────────────
def parse_inserts(text):
    """DbDump 형식 INSERT 문 목록 → [(cols, vals, stmt_text)]"""
    out = []
    i = 0
    n = len(text)
    while True:
        j = text.find("INSERT INTO", i)
        if j < 0:
            break
        # 문장 끝 = 따옴표 밖의 ');' — 값 안의 세미콜론 보호
        k = j
        inq = False
        end = -1
        while k < n:
            c = text[k]
            if c == "'":
                inq = not inq
            elif c == ";" and not inq:
                end = k
                break
            k += 1
        assert end > 0, "INSERT 끝 못 찾음"
        stmt = text[j:end + 1]
        m = re.match(r"INSERT INTO (\S+) \(([^)]*)\)\s*VALUES \(", stmt, re.S)
        assert m, stmt[:100]
        cols = [c.strip() for c in m.group(2).split(",")]
        body = stmt[m.end():-2]  # ');' 제거
        vals, cur, inq, depth = [], "", False, 0
        p = 0
        while p < len(body):
            c = body[p]
            if c == "'":
                inq = not inq
                cur += c
            elif not inq and c == "(":
                depth += 1
                cur += c
            elif not inq and c == ")":
                depth -= 1
                cur += c
            elif c == "," and not inq and depth == 0:
                vals.append(cur.strip())
                cur = ""
            else:
                cur += c
            p += 1
        vals.append(cur.strip())
        assert len(vals) == len(cols), (cols, vals[:3], stmt[:120])
        out.append((cols, vals, stmt))
        i = end + 1
    return out

def val(cols, vals, name):
    v = vals[cols.index(name)]
    return v.strip("'")

def filter_dump(fname, keep):
    """dump/<fname> 의 INSERT 중 keep(cols,vals)=True 만 남긴 SQL 텍스트"""
    txt = rd(os.path.join(DUMP, fname))
    stmts = parse_inserts(txt)
    kept = [s for (c, v, s) in stmts if keep(c, v)]
    return kept, len(stmts)

HEADER = """--------------------------------------------------------------------------------
-- {fn} — {title}
-- {product} 클린 설치 세트 — 통합본(RLMS 스키마, 2026-08-03 라이브)에서 추출·제품 필터링.
-- 실행 계정: {schema}. 클라이언트 인코딩 UTF-8(AL32UTF8) 필수. 재실행 비멱등(단순 INSERT).
--------------------------------------------------------------------------------

SET DEFINE OFF

"""

def emit_seed(product, schema, outdir, fn, title, parts):
    body = HEADER.format(fn=fn, title=title, product=product, schema=schema)
    for label, stmts in parts:
        body += "-- ── %s (%d행) ──\n" % (label, len(stmts))
        body += "\n".join(stmts) + "\n\n"
    body += "COMMIT;\n"
    wr(os.path.join(outdir, fn), body)
    print("%s/%s: %s" % (product, fn, ", ".join("%s=%d" % (l, len(s)) for l, s in parts)))

# ════════════════════════════════════════════════════════════════════════
# 1) 메뉴/프로그램/메뉴권한
# ════════════════════════════════════════════════════════════════════════
menu_stmts = parse_inserts(rd(os.path.join(DUMP, "COMTNMENUINFO.sql")))

def menu_no(c, v):
    return val(c, v, "MENU_NO")

def menu_prog(c, v):
    return val(c, v, "PROGRM_FILE_NM")

ALL_MENUS = {menu_no(c, v): (c, v, s) for (c, v, s) in menu_stmts}

def lex_menu_keep(no):
    if no in ("0", "60030000"):
        return True
    if no.startswith("55"):
        return True                                   # 송무관리 전체
    if no in ("45000000", "45030000", "45060000", "45070000"):
        return True                                   # 통계(공통 3종)
    if no in ("70000000", "70010000", "70020000"):
        return True                                   # 도움말관리
    if no.startswith("80") or no.startswith("90"):
        return True                                   # 게시판관리·관리자
    if no.startswith("15") or no.startswith("25") or no.startswith("30"):
        return True                                   # USER: 소송의뢰·마이페이지·도움말
    if no in ("35000000", "35010000"):
        return True                                   # USER: 게시판(공지) — 테스트 보드 제외
    return False

def reg_menu_keep(no):
    if no.startswith("55") or no.startswith("15"):
        return False                                  # 송무 축 제거
    if no == "35020000":
        return False                                  # 테스트 보드 메뉴 제외(클린 DB 에 보드 없음)
    return True

lex_menus = sorted(no for no in ALL_MENUS if lex_menu_keep(no))
reg_menus = sorted(no for no in ALL_MENUS if reg_menu_keep(no))

prog_stmts = parse_inserts(rd(os.path.join(DUMP, "COMTNPROGRMLIST.sql")))
ALL_PROGS = {val(c, v, "PROGRM_FILE_NM"): (c, v, s) for (c, v, s) in prog_stmts}

def progs_for(menu_nos):
    names = set()
    for no in menu_nos:
        c, v, _ = ALL_MENUS[no]
        names.add(menu_prog(c, v))
    return names

lex_prog_names = progs_for(lex_menus)
reg_prog_names = progs_for(reg_menus)
unref = set(ALL_PROGS) - progs_for(ALL_MENUS.keys())
print("미참조 프로그램(전체 메뉴 기준):", sorted(unref))
# 미참조 프로그램은 URL 인가 파생에 쓰일 수 있어 도메인 명백(RLMS_/LAW_ 접두) 외엔 양쪽 유지
for nm in unref:
    if nm.startswith("LAW_"):
        lex_prog_names.add(nm)
    elif nm.startswith("RLMS_"):
        reg_prog_names.add(nm)
    else:
        lex_prog_names.add(nm)
        reg_prog_names.add(nm)

dtl_stmts = parse_inserts(rd(os.path.join(DUMP, "COMTNMENUCREATDTLS.sql")))

def build_menu_seed(product, schema, outdir, keep_menus, keep_prog_names, extra=""):
    progs = [s for (c, v, s) in prog_stmts if val(c, v, "PROGRM_FILE_NM") in keep_prog_names]
    menus = [s for (c, v, s) in menu_stmts if menu_no(c, v) in keep_menus]
    dtls = [s for (c, v, s) in dtl_stmts if val(c, v, "MENU_NO") in keep_menus]
    body = HEADER.format(fn="21_seed_menu.sql", title="프로그램·메뉴·메뉴별권한(=URL 인가 원천)",
                         product=product, schema=schema)
    body += "-- ── 프로그램 (%d행) ──\n" % len(progs) + "\n".join(progs) + "\n\n"
    body += "-- ── 메뉴 (%d행) ──\n" % len(menus) + "\n".join(menus) + "\n\n"
    body += "-- ── 메뉴별권한 (%d행) ──\n" % len(dtls) + "\n".join(dtls) + "\n\n"
    if extra:
        body += extra + "\n"
    body += "COMMIT;\n"
    wr(os.path.join(outdir, "21_seed_menu.sql"), body)
    print("%s/21_seed_menu.sql: prog=%d menu=%d auth=%d" % (product, len(progs), len(menus), len(dtls)))

LEX_MENU_EXTRA = """-- ── 제품 재배치: 규정관리 GNB 소멸에 따른 상위/순서 조정 ──
-- 통계(45000000)는 규정관리(48000000) 하위였음 → 관리자(90000000) 하위로 이동
UPDATE COMTNMENUINFO SET UPPER_MENU_NO = 90000000, MENU_ORDR = 6 WHERE MENU_NO = 45000000;
-- 도움말관리(70000000)도 규정관리 하위였음 → 최상위로
UPDATE COMTNMENUINFO SET UPPER_MENU_NO = 0, MENU_ORDR = 3 WHERE MENU_NO = 70000000;
-- ADMIN GNB 순서: 송무관리 1 / 게시판관리 2 / 도움말관리 3(위) / 관리자 4(기존값)
UPDATE COMTNMENUINFO SET MENU_ORDR = 1 WHERE MENU_NO = 55000000;
UPDATE COMTNMENUINFO SET MENU_ORDR = 2 WHERE MENU_NO = 80000000;
"""

build_menu_seed("LexPortal", "lexportal", LEX, set(lex_menus), lex_prog_names, LEX_MENU_EXTRA)
build_menu_seed("RegNex", "regnex", REG, set(reg_menus), reg_prog_names)

# ════════════════════════════════════════════════════════════════════════
# 2) 권한/역할 (22_seed_auth)
# ════════════════════════════════════════════════════════════════════════
LEX_DROP_ROLES = {"ROLE_MGR_LAWQUEST", "ROLE_USR_LAWQUEST"}   # rlms 법령질의 표기용
for product, schema, outdir, dropA, dropR in (
        ("LexPortal", "lexportal", LEX, set(), LEX_DROP_ROLES),
        ("RegNex", "regnex", REG, {"ROLE_LAW_MGR"}, set())):
    a, at = filter_dump("COMTNAUTHORINFO.sql", lambda c, v: val(c, v, "AUTHOR_CODE") not in dropA)
    r, rt = filter_dump("COMTNROLEINFO.sql", lambda c, v: val(c, v, "ROLE_CODE") not in dropR)
    rel, relt = filter_dump("COMTNAUTHORROLERELATE.sql",
                            lambda c, v: val(c, v, "AUTHOR_CODE") not in dropA
                            and val(c, v, "ROLE_CODE") not in dropR)
    h, ht = filter_dump("COMTNROLES_HIERARCHY.sql",
                        lambda c, v: dropA.isdisjoint({val(c, v, c2) for c2 in c}))
    g2, _ = filter_dump("COMTNAUTHORGROUPINFO.sql", lambda c, v: True)
    emit_seed(product, schema, outdir, "22_seed_auth.sql", "권한·권한그룹·역할·매핑·역할계층",
              [("권한", a), ("권한그룹", g2), ("역할", r), ("권한-역할 매핑", rel), ("역할계층", h)])

# ════════════════════════════════════════════════════════════════════════
# 3) 공통코드 ccm (20_seed_ccm)
# ════════════════════════════════════════════════════════════════════════
RLMS_ONLY_GROUPS = {"SGUBUN", "FT_STATUS", "REL_FILE", "REL_LINK", "COUNSEL_TYPE"}
for product, schema, outdir, drop in (
        ("LexPortal", "lexportal", LEX, RLMS_ONLY_GROUPS),
        ("RegNex", "regnex", REG, None)):   # None → LAW_% 제거
    def keep(c, v, drop=drop):
        cid = val(c, v, "CODE_ID")
        if drop is None:
            return not cid.startswith("LAW_")
        return cid not in drop
    g, _ = filter_dump("COMTCCMMNCODE.sql", keep)
    d, _ = filter_dump("COMTCCMMNDETAILCODE.sql", keep)
    emit_seed(product, schema, outdir, "20_seed_ccm.sql", "공통코드(그룹+상세)",
              [("코드그룹", g), ("상세코드", d)])

# ════════════════════════════════════════════════════════════════════════
# 4) 채번 (26_seed_idgn) — 라이브 COMTECOPSEQ 전량(잉여 행 무해, 누락=첫 저장 실패)
# ════════════════════════════════════════════════════════════════════════
for product, schema, outdir in (("LexPortal", "lexportal", LEX), ("RegNex", "regnex", REG)):
    s, _ = filter_dump("COMTECOPSEQ.sql", lambda c, v: True)
    emit_seed(product, schema, outdir, "26_seed_idgn.sql",
              "COMTECOPSEQ 채번(라이브 전량 — 잉여 행 무해)", [("채번", s)])

# ════════════════════════════════════════════════════════════════════════
# 5) 테이블/인덱스/코멘트/FK — LexPortal 은 공통 부분집합, RegNex 는 원본 그대로
# ════════════════════════════════════════════════════════════════════════
tables_txt = rd(os.path.join(NEWDB, "10_tables.sql"))
# 문장 단위 분할(따옴표 밖 ';') — 각 문장의 CREATE TABLE/VIEW 대상명으로 분류.
# 문장 사이 주석은 다음 문장에 붙인다.
stmts10 = []
cur, inq = "", False
for ch in tables_txt:
    cur += ch
    if ch == "'":
        inq = not inq
    elif ch == ";" and not inq:
        stmts10.append(cur)
        cur = ""
tail10 = cur  # 마지막 세미콜론 뒤 잔여(주석 등)
blocks = []   # (name, text)
head10 = None
for st in stmts10:
    m = (re.search(r'CREATE TABLE "?([A-Z_0-9]+)"?', st)
         or re.search(r'CREATE (?:UNIQUE )?INDEX \S+ ON "?([A-Z_0-9]+)"?', st)   # 부속 인덱스
         or re.search(r'VIEW "?([A-Z_0-9]+)"?', st)                               # 뷰(FORCE/NONEDITIONABLE 허용)
         or re.search(r'ALTER TABLE "?([A-Z_0-9]+)"?', st))                       # 분리형 PK 등
    assert m, st[:120]
    name = m.group(1)
    if head10 is None:
        # 첫 문장 앞부분 = 파일 헤더 주석
        cut = st.find("-- TABLE")
        if cut < 0:
            cut = st.upper().find("CREATE ")
        head10 = st[:cut]
        st = st[cut:]
    blocks.append((name, st.rstrip() + "\n"))
names10 = {n for n, _ in blocks}
print("10_tables 문장 %d / 대상 %d" % (len(blocks), len(names10)))
assert len(names10) == 78, len(names10)   # 테이블 77 + 뷰 1

def lex_table_keep(name):
    return (name.startswith("COMT") or name == "COM_BRAND"
            or name in ("TB_ACT_LOG", "TB_STATS_BBS_VIEW") or name == "COMVNUSERMASTER")

lex_tbls = [b for b in blocks if lex_table_keep(b[0])]
lex_names = {b[0] for b in lex_tbls}
body = head10.replace("테이블 76종 + 로그인 뷰", "공통 테이블 %d종 + 로그인 뷰" % (len(lex_tbls) - 1)) \
             .replace("신규 스키마 RLMS 클린 설치 세트", "LexPortal(송무 단독) 클린 설치 세트") \
             .replace("실행 계정: RLMS", "실행 계정: lexportal")
body += "".join("\n" + b[1] for b in lex_tbls)
wr(os.path.join(LEX, "10_tables.sql"), body)
print("LexPortal/10_tables.sql: blocks=%d" % len(lex_tbls))

def filter_lines(src, keep_names, patt):
    """한 줄=한 문장 스크립트에서 대상 테이블이 keep_names 인 줄만"""
    out = []
    for line in rd(src).split("\n"):
        m = re.search(patt, line)
        if m and m.group(1) not in keep_names:
            continue
        out.append(line)
    return "\n".join(out)

wr(os.path.join(LEX, "11_indexes.sql"),
   filter_lines(os.path.join(NEWDB, "11_indexes.sql"), lex_names, r"ON (\S+) \(")
   .replace("신규 스키마 RLMS 클린 설치 세트", "LexPortal(송무 단독) 클린 설치 세트")
   .replace("실행 계정: RLMS", "실행 계정: lexportal"))
wr(os.path.join(LEX, "12_comments.sql"),
   filter_lines(os.path.join(NEWDB, "12_comments.sql"), lex_names,
                r"COMMENT ON (?:TABLE|COLUMN) ([A-Z_0-9]+)")
   .replace("신규 스키마 RLMS 클린 설치 세트", "LexPortal(송무 단독) 클린 설치 세트")
   .replace("실행 계정: RLMS", "실행 계정: lexportal"))
wr(os.path.join(LEX, "30_fks.sql"),
   filter_lines(os.path.join(NEWDB, "30_fks.sql"), lex_names,
                r"ALTER TABLE (\S+) ADD")
   .replace("신규 스키마 RLMS 클린 설치 세트", "LexPortal(송무 단독) 클린 설치 세트")
   .replace("실행 계정: RLMS", "실행 계정: lexportal"))
# FK 참조 대상도 kept 인지 검증
for line in rd(os.path.join(LEX, "30_fks.sql")).split("\n"):
    m = re.search(r"REFERENCES (\S+) \(", line)
    if m and m.group(1) not in lex_names:
        print("경고: FK 참조 대상 미포함:", line)

# RegNex — 구조 파일 원본 복사(주석의 계정 표기만 교체)
import shutil
for fn in ("10_tables.sql", "11_indexes.sql", "12_comments.sql",
           "13_triggers_functions.sql", "14_oracle_text.sql", "30_fks.sql"):
    t = rd(os.path.join(NEWDB, fn)) \
        .replace("신규 스키마 RLMS 클린 설치 세트", "RegNex(규정 단독) 클린 설치 세트") \
        .replace("실행 계정: RLMS", "실행 계정: regnex")
    wr(os.path.join(REG, fn), t)
print("RegNex 구조 파일 6종 복사")

# ════════════════════════════════════════════════════════════════════════
# 6) 계정/게시판/도메인/브랜드
# ════════════════════════════════════════════════════════════════════════
for outdir, product, schema in ((LEX, "LexPortal", "lexportal"), (REG, "RegNex", "regnex")):
    for fn in ("23_seed_org_accounts.sql", "24_seed_bbs.sql"):
        t = rd(os.path.join(NEWDB, fn)) \
            .replace("신규 스키마 RLMS 클린 설치 세트", "%s 클린 설치 세트" % product) \
            .replace("실행 계정: RLMS", "실행 계정: " + schema)
        wr(os.path.join(outdir, fn), t)

# RegNex: 25_seed_domain 그대로(브랜드 문구만 제품명으로)
t = rd(os.path.join(NEWDB, "25_seed_domain.sql")) \
    .replace("신규 스키마 RLMS 클린 설치 세트", "RegNex(규정 단독) 클린 설치 세트") \
    .replace("실행 계정: RLMS", "실행 계정: regnex") \
    .replace("'LegalNex 법률규정통합관리시스템'", "'RegNex 규정관리시스템'")
wr(os.path.join(REG, "25_seed_domain.sql"), t)

# LexPortal: 도메인 시드는 브랜드 행만
wr(os.path.join(LEX, "25_seed_brand.sql"), HEADER.format(
    fn="25_seed_brand.sql", title="브랜드설정 기본 행(로고=텍스트, 화면에서 수정)",
    product="LexPortal", schema="lexportal")
   + "INSERT INTO COM_BRAND (BRAND_ID, LOGO_TY_CODE, LOGO_TEXT) VALUES ('S', 'TEXT', 'LexPortal 송무관리시스템');\n\nCOMMIT;\n")
print("계정/게시판/도메인/브랜드 시드 완료")

# 00_create_user 참고본
cu = rd(os.path.join(NEWDB, "00_create_user.sql"))
for outdir, schema, pw in ((LEX, "LEXPORTAL", "www_codea_kr_12"), (REG, "REGNEX", "www_codea_kr_12")):
    t = cu.replace("RLMS", schema).replace("rlms_CHANGE_ME_2026", pw)
    wr(os.path.join(outdir, "00_create_user.sql"), t)
print("00_create_user 2종")
print("생성 완료")
