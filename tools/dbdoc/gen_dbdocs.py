# -*- coding: utf-8 -*-
"""제품별 테이블 명세서 / ERD 문서 생성 — database/newdb 의 DDL·COMMENT 를 원천으로 한다.
   스키마를 고치면 이 스크립트를 다시 돌려 문서를 재생성할 것(손편집 금지)."""
import io, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dbmeta

RESULT = dbmeta.RESULT
PRODUCTS = ["RLMS", "RegNex", "LexPortal"]
PRODUCT_NM = {"RLMS": "RLMS (통합본 — 규정관리 + 송무)",
              "RegNex": "RegNex (규정관리 전용)",
              "LexPortal": "LexPortal (송무 전용)"}

# ────────────────────────────────────────────────────────────── 도메인 분류
DOMAINS = [
    ("A. 공통 — 사용자·권한·조직", [
        "COMVNUSERMASTER", "COMTNGNRLMBER", "COMTNEMPLYRINFO", "COMTHEMPLYRINFOCHANGEDTLS",
        "COMTNEMPLYRSCRTYESTBS", "COMTNORGNZTINFO", "COMTNAUTHORINFO", "COMTNAUTHORGROUPINFO",
        "COMTNAUTHORROLERELATE", "COMTNROLEINFO", "COMTNROLES_HIERARCHY", "COMTNLOGINPOLICY"]),
    ("B. 공통 — 메뉴·프로그램(URL 인가 원천)", [
        "COMTNMENUINFO", "COMTNPROGRMLIST", "COMTNMENUCREATDTLS", "COMTNSITEMAP"]),
    ("C. 공통 — 공통코드·채번", [
        "COMTCCMMNCODE", "COMTCCMMNDETAILCODE", "COMTECOPSEQ"]),
    ("D. 공통 — 게시판·댓글·만족도·템플릿", [
        "COMTNBBSMASTER", "COMTNBBSMASTEROPTN", "COMTNBBS", "COMTNBBSWRITEAUTHOR",
        "COMTNCOMMENT", "COMTNSTSFDG", "COMTNTMPLATINFO"]),
    ("E. 공통 — 첨부파일(표준)", ["COMTNFILE", "COMTNFILEDETAIL"]),
    ("F. 공통 — 로그·통계", [
        "COMTNLOGINLOG", "COMTNSYSLOG", "COMTNUSERLOG", "COMTNWEBLOG",
        "COMTSSYSLOGSUMMARY", "COMTSWEBLOGSUMMARY", "COMTNPRIVACYLOG"]),
    ("G. 공통 — 콘텐츠·운영", [
        "COMTNBANNER", "COMTNPOPUPMANAGE", "COMTNFAQINFO", "COMTNQAINFO", "COM_BRAND"]),
    ("H. 규정 — 분류·규정·조문(코어)", [
        "TB_CATE", "TB_CATE_OWNER", "TB_CATE_READER", "TB_GUBUN_READER",
        "TB_GAEJUNG", "TB_PROM", "TB_PROV_VRSN", "TB_PROV_HTML", "TB_PROV_TEXT_HST",
        "TB_DOCU", "TB_SRC_STORED", "TB_GAEJUNG_LOG"]),
    ("I. 규정 — 승인 워크플로·부가", [
        "TB_PROM_WRK", "TB_PROM_ACT_LOG", "TB_PROM_STSFDG", "TB_PROM_MAP",
        "TB_ATTACH", "TB_FAVOR", "TB_MEMO"]),
    ("J. 규정 — 필수 열람(의무 숙지)", [
        "TB_READ_DUTY", "TB_READ_DUTY_TGT", "TB_READ_DUTY_CHK"]),
    ("K. 규정 — 관련자료(8액션)", [
        "TB_REL_VRSN_CATE", "TB_REL_VRSN", "TB_REL_FILE", "TB_REL_WORD", "TB_REL_IMG",
        "TB_REL_ORGN", "TB_REL_HTML", "TB_REL_LNK", "TB_REL_DMN_LNK", "TB_REL_EXCL_LNK"]),
    ("L. 법령질의", ["TB_LAWQUEST", "TB_LAWQUEST_ADMIN"]),
    ("M. 통계·활동로그(도메인 확장)", [
        "TB_ACT_LOG", "TB_STATS_FT_VIEW", "TB_STATS_BBS_VIEW", "TB_STATS_KWD"]),
    ("N. 송무 — 사건·당사자·진행", [
        "LAW_SUIT", "LAW_SUIT_PARTY", "LAW_SUIT_STAFF", "LAW_SUIT_LAND",
        "LAW_SUIT_PROG", "LAW_SUIT_RSLT_HIST"]),
    ("O. 송무 — 문서·비용·변호사", [
        "LAW_SUIT_DOC", "LAW_SUIT_COST", "LAW_LAWYER", "LAW_SUIT_LAWYER", "LAW_LAWYER_SATIS"]),
    ("P. 송무 — 의뢰·압류·접수·기준데이터", [
        "LAW_SUIT_REQ", "LAW_SUIT_REQ_HIST", "LAW_SUIT_REQ_HELPER",
        "LAW_SEIZE", "LAW_COURT_RECEIPT", "LAW_COURT", "LAW_CALC_RATE"]),
]

# ────────────────────────────────────────────────────────────── ERD 정의
# (제목, 설명, [(좌, 관계, 우, 라벨)])  — 관계: ||--o{ 1:N, ||--o| 1:0..1, }o--|| N:1
ERDS = [
 ("규정·조문 코어",
  "분류(TB_CATE) 아래에 규정 회차(TB_PROM)가 달리고, 회차 1건이 조문·별표·이력을 소유한다. "
  "같은 규정의 여러 회차는 `ILAW_ID` 로 묶이며(회차 그룹), 현행 회차는 시행일(`SSTART_DT`)·폐지일(`SNULL_DT`)로 판정한다.",
  [("TB_CATE", "||--o{", "TB_CATE", "IREF · 자기참조 트리"),
   ("TB_CATE", "||--o{", "TB_PROM", "ICATE_NO"),
   ("TB_CATE", "||--o{", "TB_CATE_OWNER", "ICATE_NO ★FK"),
   ("TB_CATE", "||--o{", "TB_CATE_READER", "ICATE_NO ★FK"),
   ("TB_GAEJUNG", "||--o{", "TB_PROM", "IGAEJUNG_NO · 개정구분"),
   ("TB_PROM", "||--o{", "TB_PROV_VRSN", "IPROM_NO · 조/항/호 분해"),
   ("TB_PROM", "||--o{", "TB_PROV_HTML", "IPROM_NO · 조 단위 HTML"),
   ("TB_PROM", "||--o{", "TB_PROV_TEXT_HST", "IPROM_NO · 일괄편집 스냅샷"),
   ("TB_PROM", "||--o{", "TB_DOCU", "IPROM_NO · 별표/서식"),
   ("TB_PROM", "||--o{", "TB_PROM_WRK", "IPROM_NO · 승인 워크플로"),
   ("TB_PROM", "||--o{", "TB_GAEJUNG_LOG", "IPROM_NO · 작업로그"),
   ("TB_PROM", "||--o|", "TB_PROM_STSFDG", "IPROM_NO ★FK · 만족도"),
   ("TB_PROM", "||--o{", "TB_READ_DUTY", "IPROM_NO ★FK · 필수열람"),
   ("TB_PROM", "||--o{", "TB_PROM_MAP", "IPROM_NO · 규정맵 leaf")]),

 ("관련자료(8액션) 허브-상세 구조",
  "`TB_REL_VRSN` 이 허브다. 자료 1건 = 허브 1행이고, `STABLE` 값이 실제 상세 테이블을 가리킨다"
  "(FILE/WORD/IMG/ORGN/HTML/LNK/DMN_LNK). 파일 실체는 `TB_ATTACH` 가 보관한다.",
  [("TB_PROM", "||--o{", "TB_REL_VRSN", "IPROM_NO"),
   ("TB_REL_VRSN_CATE", "||--o{", "TB_REL_VRSN", "IRVCATE_NO · 본문/붙임/양식"),
   ("TB_REL_VRSN", "||--o|", "TB_REL_FILE", "IRVRSN_NO (STABLE=FILE)"),
   ("TB_REL_VRSN", "||--o|", "TB_REL_WORD", "IRVRSN_NO (STABLE=WORD)"),
   ("TB_REL_VRSN", "||--o|", "TB_REL_IMG", "IRVRSN_NO (STABLE=IMG)"),
   ("TB_REL_VRSN", "||--o|", "TB_REL_ORGN", "IRVRSN_NO (STABLE=ORGN)"),
   ("TB_REL_VRSN", "||--o|", "TB_REL_HTML", "IRVRSN_NO (STABLE=HTML)"),
   ("TB_REL_VRSN", "||--o|", "TB_REL_LNK", "IRVRSN_NO (STABLE=LNK)"),
   ("TB_REL_VRSN", "||--o|", "TB_REL_DMN_LNK", "IRVRSN_NO (STABLE=DMN_LNK)"),
   ("TB_ATTACH", "||--o{", "TB_REL_FILE", "IATT_NO · 파일 실체"),
   ("TB_ATTACH", "||--o{", "TB_REL_WORD", "IATT_NO"),
   ("TB_ATTACH", "||--o{", "TB_REL_IMG", "IATT_NO"),
   ("TB_ATTACH", "||--o{", "TB_REL_ORGN", "IATT_NO")]),

 ("사용자·권한·메뉴 (URL 인가 원천)",
  "로그인 정본은 뷰 `COMVNUSERMASTER`(일반회원 + 업무사용자 UNION). URL 접근제어의 단일 원천은 "
  "**메뉴(COMTNMENUINFO) ↔ 프로그램(COMTNPROGRMLIST) ↔ 메뉴별 권한(COMTNMENUCREATDTLS)** 이다. "
  "신규 화면을 추가하면 프로그램·메뉴·메뉴별권한을 반드시 함께 등록해야 접근이 열린다.",
  [("COMTNORGNZTINFO", "||--o{", "COMTNORGNZTINFO", "UPPER_ORGNZT_ID ★FK · 부서 트리"),
   ("COMTNORGNZTINFO", "||--o{", "COMTNEMPLYRINFO", "ORGNZT_ID ★FK"),
   ("COMTNAUTHORGROUPINFO", "||--o{", "COMTNEMPLYRINFO", "GROUP_ID ★FK"),
   ("COMTNAUTHORGROUPINFO", "||--o{", "COMTNGNRLMBER", "GROUP_ID ★FK"),
   ("COMTNAUTHORINFO", "||--o{", "COMTNAUTHORROLERELATE", "AUTHOR_CODE ★FK"),
   ("COMTNROLEINFO", "||--o{", "COMTNAUTHORROLERELATE", "ROLE_CODE ★FK"),
   ("COMTNAUTHORINFO", "||--o{", "COMTNROLES_HIERARCHY", "PARNTS/CHLDRN ★FK"),
   ("COMTNAUTHORINFO", "||--o{", "COMTNMENUCREATDTLS", "AUTHOR_CODE ★FK"),
   ("COMTNMENUINFO", "||--o{", "COMTNMENUCREATDTLS", "MENU_NO ★FK"),
   ("COMTNMENUINFO", "||--o{", "COMTNMENUINFO", "UPPER_MENU_NO ★FK · 메뉴 트리"),
   ("COMTNPROGRMLIST", "||--o{", "COMTNMENUINFO", "PROGRM_FILE_NM ★FK"),
   ("COMTNSITEMAP", "||--o{", "COMTNMENUCREATDTLS", "MAPNG_CREAT_ID ★FK")]),

 ("게시판·첨부(표준 모듈)",
  "게시판은 eGov 표준을 그대로 쓴다. 첨부는 `COMTNFILE`(묶음) + `COMTNFILEDETAIL`(개별 파일) 2단 구조이며, "
  "게시글은 `ATCH_FILE_ID` 로 묶음을 참조한다. 규정 도메인 첨부만 `TB_ATTACH` 를 쓴다.",
  [("COMTNTMPLATINFO", "||--o{", "COMTNBBSMASTER", "TMPLAT_ID · 스킨"),
   ("COMTNBBSMASTER", "||--o{", "COMTNBBS", "BBS_ID ★FK"),
   ("COMTNBBSMASTER", "||--o|", "COMTNBBSMASTEROPTN", "BBS_ID · 옵션"),
   ("COMTNBBSMASTER", "||--o{", "COMTNBBSWRITEAUTHOR", "BBS_ID ★FK · 작성권한"),
   ("COMTNAUTHORINFO", "||--o{", "COMTNBBSWRITEAUTHOR", "AUTHOR_CODE ★FK"),
   ("COMTNBBS", "||--o{", "COMTNCOMMENT", "NTT_ID+BBS_ID ★FK"),
   ("COMTNBBS", "||--o{", "COMTNSTSFDG", "NTT_ID · 만족도"),
   ("COMTNFILE", "||--o{", "COMTNFILEDETAIL", "ATCH_FILE_ID ★FK"),
   ("COMTNBBS", "}o--o|", "COMTNFILE", "ATCH_FILE_ID"),
   ("COMTNFAQINFO", "}o--o|", "COMTNFILE", "ATCH_FILE_ID ★FK")]),

 ("송무 — 사건 중심 구조",
  "`LAW_SUIT` 이 **심급 1건 = 1행**이다. 1심·2심·3심은 별도 행이며 `FIRST_SUIT_ID` 로 사건군을 묶는다. "
  "사용자가 올린 소송의뢰(`LAW_SUIT_REQ`)는 승인 후 `SUIT_ID` 로 사건에 연결된다. "
  "첨부는 표준 `COMTNFILE`(ATCH_FILE_ID)을 쓴다.",
  [("LAW_SUIT", "||--o{", "LAW_SUIT", "FIRST_SUIT_ID · 심급 그룹"),
   ("LAW_COURT", "||--o{", "LAW_SUIT", "COURT_ID"),
   ("LAW_COURT", "||--o{", "LAW_COURT", "UPPER_COURT_ID · 법원 계층"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_PARTY", "SUIT_ID · 원고/피고"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_STAFF", "SUIT_ID · 수행자"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_LAND", "SUIT_ID · 사건토지"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_PROG", "SUIT_ID · 진행/기일"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_RSLT_HIST", "SUIT_ID · 결과이력"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_DOC", "SUIT_ID · 소송문서"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_COST", "SUIT_ID · 소송비용"),
   ("LAW_SUIT", "||--o{", "LAW_SUIT_LAWYER", "SUIT_ID · 선임"),
   ("LAW_LAWYER", "||--o{", "LAW_SUIT_LAWYER", "LAWYER_ID"),
   ("LAW_SUIT_LAWYER", "||--o{", "LAW_LAWYER_SATIS", "ASSIGN_ID · 만족도"),
   ("LAW_SUIT_REQ", "}o--o|", "LAW_SUIT", "SUIT_ID · 승인 후 연계"),
   ("LAW_SUIT_REQ", "||--o{", "LAW_SUIT_REQ_HIST", "REQ_ID · 사건경과"),
   ("LAW_SUIT_REQ", "||--o{", "LAW_SUIT_REQ_HELPER", "REQ_ID · 보조자"),
   ("COMTNORGNZTINFO", "||--o{", "LAW_SUIT_STAFF", "ORGNZT_ID · 표준 부서")]),

 ("필수 열람(의무 숙지)",
  "승인된 회차에 열람 의무를 지정하고(전사/부서/개인), 2단계(열람 자동기록 → 숙지 확인 버튼)로 증빙을 남긴다.",
  [("TB_PROM", "||--o|", "TB_READ_DUTY", "IPROM_NO ★FK · 회차당 1건"),
   ("TB_READ_DUTY", "||--o{", "TB_READ_DUTY_TGT", "IDUTY_NO ★FK · 대상 지정"),
   ("TB_READ_DUTY", "||--o{", "TB_READ_DUTY_CHK", "IDUTY_NO ★FK · 확인 증빙")]),
]


def clean(s):
    """문서용 코멘트 정리 — 레거시 계보 꼬리표 제거, 표 깨짐 방지."""
    if not s:
        return ""
    s = re.sub(r"\s*←\s*(tbetia\w*|tc_\w+|TB_\w+\.\w+)?[^,;.]*", "", s)
    s = re.sub(r"\s*\(?\s*←[^)]*\)?", "", s)
    s = s.replace("|", "\\|").replace("\n", " ")
    return re.sub(r"\s{2,}", " ", s).strip()


def anchor(t):
    return "#" + t.lower().replace("_", "-")


def gen_spec(product, M):
    T, tcm, ccm, fks, idx = M["tables"], M["tcm"], M["ccm"], M["fks"], M["idx"]
    fk_by_t, idx_by_t = {}, {}
    for f in fks:
        fk_by_t.setdefault(f["table"], []).append(f)
    for i in idx:
        idx_by_t.setdefault(i["table"], []).append(i)

    assigned, groups = set(), []
    for title, names in DOMAINS:
        present = [n for n in names if n in T]
        if present:
            groups.append((title, present))
            assigned.update(present)
    rest = [t for t in T if t not in assigned]
    if rest:
        groups.append(("Z. 기타(미분류)", rest))

    L = []
    L.append("# %s — 테이블 명세서\n" % product)
    L.append("> 생성 원천: `database/newdb/*.sql` (Oracle 클린 설치 세트)의 DDL·COMMENT.  ")
    L.append("> **이 문서는 자동 생성물이다.** 스키마를 고치면 손으로 고치지 말고 재생성할 것 — "
             "`python tools/dbdoc/gen_dbdocs.py`\n")
    L.append("| 항목 | 값 |")
    L.append("|---|---|")
    L.append("| 제품 | %s |" % PRODUCT_NM[product])
    L.append("| 테이블 수 | **%d** |" % len(T))
    L.append("| 컬럼 수 | %d |" % sum(len(v["cols"]) for v in T.values()))
    L.append("| FK 제약 | %d |" % len(fks))
    L.append("| 인덱스(비제약) | %d |\n" % len(idx))

    L.append("## 읽는 법\n")
    L.append("- **PK**: DDL 의 PRIMARY KEY 제약. 레거시에서 이관된 `TB_*` 테이블은 "
             "**PK 제약이 없다** — 논리 키는 애플리케이션이 보장한다(아래 각 표의 첫 컬럼이 논리 키).")
    L.append("- **NN**: NOT NULL. ")
    L.append("- 날짜/시각 컬럼은 대부분 `VARCHAR2` 문자열이다(레거시 관행). "
             "`SINS_DT`=등록시각(`YYYYMMDDHH24MISS`), `S*_DT`=일자(`YYYYMMDD`).")
    L.append("- `SDEL_YN`/`SDISP_YN`='N' 은 **논리 삭제(tombstone)** 다. 물리 삭제하지 않는다.")
    L.append("- `SSYS_ID` 는 단일 시스템 고정값이며 **조회 조건으로 쓰지 않는다**.\n")

    L.append("## 도메인별 목록\n")
    for title, names in groups:
        L.append("### %s\n" % title)
        L.append("| 테이블 | 한글명 | 컬럼 |")
        L.append("|---|---|---:|")
        for n in names:
            L.append("| [`%s`](%s) | %s | %d |" % (n, anchor(n), clean(tcm.get(n, "")) or "—",
                                                   len(T[n]["cols"])))
        L.append("")

    L.append("\n---\n")
    L.append("## 테이블 상세\n")
    for title, names in groups:
        L.append("### %s\n" % title.split(". ", 1)[-1])
        for n in names:
            v = T[n]
            L.append("#### %s\n" % n)
            d = clean(tcm.get(n, ""))
            if d:
                L.append("%s\n" % d)
            pk = set(v["pk"])
            fkcols = {}
            for f in fk_by_t.get(n, []):
                for c in f["cols"]:
                    fkcols[c] = "%s.%s" % (f["ref"], f["refcols"][0] if f["refcols"] else "")
            L.append("| # | 컬럼 | 타입 | NN | 키 | 설명 |")
            L.append("|---:|---|---|:-:|:-:|---|")
            for i, c in enumerate(v["cols"], 1):
                key = "PK" if c["name"] in pk else ("FK" if c["name"] in fkcols else "")
                desc = clean(ccm.get((n, c["name"]), ""))
                if c["name"] in fkcols:
                    desc = (desc + " → `%s`" % fkcols[c["name"]]).strip()
                if c["default"]:
                    desc = (desc + " (기본값 `%s`)" % c["default"].replace("|", "\\|")).strip()
                L.append("| %d | `%s` | %s | %s | %s | %s |"
                         % (i, c["name"], c["type"], "●" if c["notnull"] else "", key, desc or "—"))
            ix = idx_by_t.get(n, [])
            if ix:
                L.append("")
                for i2 in ix:
                    L.append("- 인덱스 %s`%s` (%s)" % ("**UNIQUE** " if i2["uniq"] else "",
                                                       i2["name"], ", ".join(i2["cols"])))
            ref_in = [f for f in fks if f["ref"] == n]
            if ref_in:
                L.append("")
                for f in ref_in:
                    L.append("- 참조됨 ← `%s(%s)`%s" % (f["table"], ", ".join(f["cols"]),
                                                        " *ON DELETE CASCADE*" if f["cascade"] else ""))
            L.append("")
    return "\n".join(L) + "\n"


def gen_erd(product, M):
    T, tcm = M["tables"], M["tcm"]
    L = []
    L.append("# %s — 핵심 기능 ERD\n" % product)
    L.append("> 자동 생성물(`database/newdb` DDL 기준). 관계 라벨의 **★FK** 는 DB 에 FK 제약이 "
             "실제로 걸린 관계, 나머지는 **애플리케이션이 보장하는 논리 관계**다.  ")
    L.append("> 전체 컬럼은 [테이블 명세서](테이블_명세서.md) 참고.\n")
    L.append("> ⚠️ 이 스키마는 FK 제약이 26건뿐이다(레거시 이관분은 FK 없음). "
             "따라서 **DB 가 참조무결성을 지켜주지 않는다** — 삭제·이동 로직은 반드시 서비스 계층에서 "
             "연쇄 처리를 확인할 것.\n")

    emitted = 0
    for title, desc, rels in ERDS:
        use = [r for r in rels if r[0] in T and r[2] in T]
        if not use:
            continue
        emitted += 1
        L.append("---\n")
        L.append("## %d. %s\n" % (emitted, title))
        L.append("%s\n" % desc)
        ents = []
        for a, _, b, _ in use:
            for e in (a, b):
                if e not in ents:
                    ents.append(e)
        keycols = {}
        for a, _, b, lab in use:
            m = re.match(r"([A-Z_0-9+]+)", lab)
            if m:
                for c in m.group(1).split("+"):
                    keycols.setdefault(a, set()).add(c)
                    keycols.setdefault(b, set()).add(c)
        L.append("```mermaid")
        L.append("erDiagram")
        DESC_RE = re.compile(
            r"^(S?TITLE|SNAME|S?NAME|GROUP_NM|CODE_NM|CODE_ID_NM|MENU_NM|ROLE_NM|ORGNZT_NM|"
            r"NTT_SJ|BBS_NM|COURT_NM|CASE_NO|CASE_NM|PARTY_NM|LAWYER_NM|REQ_TITL|DOC_TITL|"
            r"SSTATUS|STATUS_CD|APP_STS_CD|SSTART_DT|SNULL_DT|SDISP_YN|SDEL_YN|USE_YN|DEL_YN|"
            r"ILAW_ID|SGUBUN_ID|STABLE|SFLAG|SFULL_ITEM|SITEM|PROGRM_FILE_NM|URL)$")
        for e in ents:
            cols = T[e]["cols"]
            names = [c["name"] for c in cols]
            pk = T[e]["pk"]
            show = list(pk)
            if not pk and names:
                show.append(names[0])                       # 레거시 TB_* = 논리키(첫 컬럼)
            for c in sorted(keycols.get(e, [])):            # 관계에 쓰인 키
                if c in names and c not in show:
                    show.append(c)
            for c in names:                                 # 식별에 도움되는 컬럼 보충
                if len(show) >= 6:
                    break
                if c not in show and DESC_RE.match(c):
                    show.append(c)
            L.append("    %s {" % e)
            for c in show[:6]:
                col = next((x for x in cols if x["name"] == c), None)
                if not col:
                    continue
                typ = re.sub(r"\(.*\)$", "", col["type"])   # mermaid 는 괄호 불가
                L.append("        %s %s%s" % (typ, c, " PK" if c in pk else ""))
            L.append("    }")
        for a, rel, b, lab in use:
            L.append('    %s %s %s : "%s"' % (a, rel, b, lab.replace('"', "'")))
        L.append("```\n")
        L.append("| 테이블 | 설명 |")
        L.append("|---|---|")
        for e in ents:
            L.append("| [`%s`](테이블_명세서.md%s) | %s |" % (e, anchor(e),
                                                                 clean(tcm.get(e, "")) or "—"))
        L.append("")
    return "\n".join(L) + "\n"


if __name__ == "__main__":
    for p in PRODUCTS:
        M = dbmeta.load(p)
        d = os.path.join(RESULT, p, "docs")
        if not os.path.isdir(d):
            os.makedirs(d)
        for fn, txt in (("테이블_명세서.md", gen_spec(p, M)),
                        ("ERD.md", gen_erd(p, M))):
            with io.open(os.path.join(d, fn), "w", encoding="utf-8", newline="\n") as f:
                f.write(txt)
            print("  %-10s %-22s %6d bytes" % (p, fn, len(txt.encode("utf-8"))))
