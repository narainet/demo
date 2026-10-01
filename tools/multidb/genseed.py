# -*- coding: utf-8 -*-
"""라이브 Oracle -> newdb 시드 파일 재생성.

정책
  · 정본 = 라이브 RLMS. 손으로 관리하던 시드가 벌어졌다(메뉴 69 vs 라이브 101).
  · ★송무(law) 포함 — RLMS 는 통합본(규정+송무)이라 송무가 코어다(2026-08-06 사용자 확정).
    DDL 은 newdb/15_law_install.sql, 시드(코드·메뉴·권한·채번·법원·요율)는 여기서 라이브를 따른다.
  · 데모/시연용 게시판과 그 메뉴는 제외 — 클린 설치본에 남기지 않는다.
  · 채번(COMTECOPSEQ)은 키 목록만 라이브에서 가져오고 값은 1 로 초기화(클린 설치).
  · 운영 데이터(규정·조문·소송·로그)는 애초에 시드 대상이 아니다.
"""
import io, os, re, subprocess, sys, datetime
import os as _os
# 워크스페이스 루트. 다른 경로에 설치했으면 환경변수 RLMS_WS 로 지정한다.
_WS = _os.environ.get("RLMS_WS", "C:/eGovFrameDev-4.3.1-64bit/workspace")

SCRATCH = os.path.dirname(os.path.abspath(__file__))
NEWDB = _WS + "/RLMS/database/newdb"
LIB = _WS + "/RLMS/target/RLMS-1.0.0/WEB-INF/lib"
JAVA = _os.environ.get("RLMS_JDK", "C:/java/jdk-21.0.10") + "/bin/java"
CLASSES = os.environ.get("SEEDGEN_CLASSES", os.path.join(SCRATCH, "classes"))
CP = CLASSES + ";" + LIB + "/*"   # SeedGen.class 위치(기본: 이 폴더의 classes/)
# 시드를 뽑아올 "정본" DB 접속정보 — 반드시 환경변수로 주입한다(자격증명 하드코딩 금지).
#   set RLMS_DB_URL=jdbc:oracle:thin:@<host>:1521:<sid>
#   set RLMS_DB_USER=<계정>   /   set RLMS_DB_PASS=<비밀번호>
ORA = [_os.environ.get("RLMS_DB_URL", ""),
       _os.environ.get("RLMS_DB_USER", ""),
       _os.environ.get("RLMS_DB_PASS", "")]
if not all(ORA):
    raise SystemExit("RLMS_DB_URL / RLMS_DB_USER / RLMS_DB_PASS 환경변수를 먼저 설정할 것")

TODAY = "2026-08-06"

# 송무 제외 조건 (LAWQUEST 는 별개 모듈이라 LAW_ 접두사로 정밀 필터)
LAW_PROG = "(PROGRM_FILE_NM LIKE 'LAW\\_%' ESCAPE '\\' OR URL LIKE '/law/%')"
LAW_MENU_RANGE = "(MENU_NO BETWEEN 55000000 AND 55999999 OR MENU_NO BETWEEN 15000000 AND 15999999)"
# 데모 게시판(공지사항만 남긴다) + 그 메뉴
KEEP_BBS = "'BBSMSTR_000000000001BEeMsIjLSK'"
DEMO_MENU = "35020000"          # '테스트' 게시판 메뉴
DEMO_PROG = "'RLMS_USR_BBS_35020000'"


def gen(*specs):
    cmd = [JAVA, "-Dstdout.encoding=UTF-8", "-cp", CP, "SeedGen"] + ORA + list(specs)
    r = subprocess.run(cmd, capture_output=True)
    out = r.stdout.decode("utf-8", errors="replace")
    err = r.stderr.decode("utf-8", errors="replace")
    if r.returncode != 0:
        sys.stderr.write(out + "\n----- stderr -----\n" + err + "\n")
        raise SystemExit("SeedGen 실패: " + " ".join(specs))
    return out


def write(fname, header_lines, body, note=None):
    path = os.path.join(NEWDB, fname)
    txt = "--------------------------------------------------------------------------------\n"
    for l in header_lines:
        txt += "-- " + l + "\n"
    txt += "--------------------------------------------------------------------------------\n\n"
    txt += "SET DEFINE OFF\n\n"
    txt += body
    if note:
        txt += note + "\n"
    txt += "COMMIT;\n"
    io.open(path, "w", encoding="utf-8", newline="\n").write(txt)
    n = sum(1 for l in txt.split("\n") if l.startswith("INSERT INTO"))
    print("  %-26s INSERT %3d  (%d bytes)" % (fname, n, len(txt.encode("utf-8"))))
    return n


COMMON = [
    "신규 스키마 RLMS 클린 설치 세트 — ★라이브 RLMS(%s 상태)에서 재생성." % TODAY,
    "실행 계정: RLMS. 클라이언트 인코딩 UTF-8(AL32UTF8) 필수.",
    "생성기: tools/multidb/SeedGen.java (정본=라이브 DB. 손편집 금지 — 다시 뽑을 것)",
]

total = 0

# ── 20 공통코드 ────────────────────────────────────────────────────────────────
body = gen(
    "COMTCCMMNCODE||CODE_ID|",
    "COMTCCMMNDETAILCODE||CODE_ID, CODE|",
)
total += write("20_seed_ccm.sql", [
    "20_seed_ccm.sql — 공통코드(ccm) 시드",
] + COMMON + [
    "송무(law) 코드그룹 15종·상세 298 포함 — RLMS 통합본의 코어.",
    "구분(SGUBUN) 상세는 라이브 상태 그대로. 신규 고객사는 분류관리에서 직접 편집한다.",
], body)

# ── 21 프로그램/메뉴/메뉴별권한 ────────────────────────────────────────────────
body = gen(
    "COMTNPROGRMLIST|PROGRM_FILE_NM <> %s|PROGRM_FILE_NM|" % DEMO_PROG,
    "COMTNMENUINFO|MENU_NO <> %s|MENU_NO|" % DEMO_MENU,
    "COMTNMENUCREATDTLS|MENU_NO <> %s|MENU_NO, AUTHOR_CODE|" % DEMO_MENU,
)
total += write("21_seed_menu.sql", [
    "21_seed_menu.sql — 프로그램/메뉴/메뉴별권한 시드",
] + COMMON + [
    "★이 시드가 곧 URL 접근제어(L6 메뉴파생)의 원천. SET DEFINE OFF 필수(& 포함 값 대비).",
    "송무(law) 메뉴 26·프로그램 21 포함 — DDL 은 15_law_install.sql.",
    "제외 = 데모 게시판 '테스트'(메뉴 35020000 / 프로그램 RLMS_USR_BBS_35020000)",
    "        — 24_seed_bbs.sql 이 공지사항 1보드만 싣기 때문. 둘은 반드시 함께 움직인다.",
], body)

# ── 22 권한 ────────────────────────────────────────────────────────────────────
body = gen(
    "COMTNAUTHORINFO||AUTHOR_CODE|",
    "COMTNAUTHORGROUPINFO||GROUP_ID|",
    "COMTNROLEINFO||ROLE_CODE|",
    "COMTNAUTHORROLERELATE||AUTHOR_CODE, ROLE_CODE|",
    "COMTNROLES_HIERARCHY||PARNTS_ROLE, CHLDRN_ROLE|",
)
total += write("22_seed_auth.sql", [
    "22_seed_auth.sql — 권한 3-tier 시드",
] + COMMON + [
    "계층 의미론: CHLDRN_ROLE ⊇ PARNTS_ROLE (ADMIN⊇APPROVER⊇EDITOR⊇USER). ⛔방향 반전 금지.",
    "송무담당자(ROLE_LAW_MGR)와 그 계층 2행 포함 — RLMS 는 통합본이라 송무가 코어다.",
], body)

# ── 23 조직/계정 ───────────────────────────────────────────────────────────────
body = gen(
    "COMTNORGNZTINFO||ORGNZT_ID|",
    "COMTNEMPLYRINFO||EMPLYR_ID|",
    "COMTNGNRLMBER||MBER_ID|",
    "COMTNEMPLYRSCRTYESTBS||SCRTY_DTRMN_TRGET_ID, AUTHOR_CODE|",
    "COMTNLOGINPOLICY||EMPLYR_ID|",
)
total += write("23_seed_org_accounts.sql", [
    "23_seed_org_accounts.sql — 예시 부서 + 예시 계정",
] + COMMON + [
    "★전부 예시 데이터 — 운영 전 반드시 비밀번호를 변경할 것.",
    "초기 비밀번호: sysmen=asdqwe123! (관리자) / approver·user=rlms1234!",
    "송무담당자(lawmgr) 예시 계정 포함 — 초기 비밀번호 rlms1234! (운영 전 변경).",
], body)

# ── 24 게시판 ──────────────────────────────────────────────────────────────────
body = gen(
    "COMTNBBSMASTER|BBS_ID = %s|BBS_ID|" % KEEP_BBS,
    "COMTNBBSMASTEROPTN|BBS_ID = %s|BBS_ID|" % KEEP_BBS,
    "COMTNTMPLATINFO||TMPLAT_ID|",
)
total += write("24_seed_bbs.sql", [
    "24_seed_bbs.sql — 게시판 시드 (공지사항 1보드 + 템플릿 카탈로그)",
] + COMMON + [
    "BBS_ID 'BBSMSTR_000000000001BEeMsIjLSK' 는 21_seed_menu.sql 의 프로그램 URL 에 박혀 있다 — ID 불변 필수.",
    "라이브의 데모 게시판(갤러리·자료실·탭분류형·테스트·웹진)은 싣지 않는다(클린 설치).",
], body)

# ── 25 도메인 ──────────────────────────────────────────────────────────────────
body = gen(
    "TB_GAEJUNG||IGAEJUNG_NO|",
    "COM_BRAND||1|",
    "TB_LAWQUEST_ADMIN||1|",
    "LAW_COURT||COURT_ID|",
    "LAW_CALC_RATE||RATE_ID|",
)
total += write("25_seed_domain.sql", [
    "25_seed_domain.sql — 도메인 기본 시드",
] + COMMON + [
    "개정구분·브랜드·법령질의 담당자 + 송무 기준데이터(법원 22·소송비용 요율 41).",
    "분류(TB_CATE)는 의도적으로 비운다 — 트리 최상위는 ccm SGUBUN 이 렌더하고 하위는 사용자가 만든다.",
    "브랜드는 관리자 > 운영관리 > 브랜드설정 에서 고객사에 맞게 교체하는 것이 정상 절차.",
], body)

# ── 26 채번 ────────────────────────────────────────────────────────────────────
body = gen(
    "COMTECOPSEQ||TABLE_NAME|NEXT_ID=1",
)
# ⛔시드가 ID 를 선점하는 테이블은 채번 시작점을 올려야 한다 — 안 그러면 첫 등록에서 PK 충돌.
#   LAW_COURT(라이브 최대 194)·LAW_CALC_RATE(41 행)가 해당. 원본 rlms_law_install.sql 의 관례를 따른다.
for key, start in (("LAW_COURT_ID", 200), ("LAW_CALC_RATE_ID", 100)):
    body = re.sub(r"(VALUES \('%s', )1\)" % key, r"\g<1>%d)" % start, body)
total += write("26_seed_idgn.sql", [
    "26_seed_idgn.sql — COMTECOPSEQ 채번 시드 (EgovIdGnrService 전략 테이블)",
] + COMMON + [
    "★값은 라이브가 아니라 1 로 초기화한다(클린 설치라 데이터가 없다).",
    "행이 없으면 해당 기능의 첫 INSERT 가 실패한다 — 키 목록은 라이브 전수를 따른다.",
    "★LAW_COURT_ID=200 / LAW_CALC_RATE_ID=100 — 25 시드가 ID 를 선점하므로 시작점을 올린다(PK 충돌 방지).",
], body)

print("\n총 INSERT 문: %d" % total)
