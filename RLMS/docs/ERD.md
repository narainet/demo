# RLMS — 핵심 기능 ERD

> 자동 생성물(`database/newdb` DDL 기준). 관계 라벨의 **★FK** 는 DB 에 FK 제약이 실제로 걸린 관계, 나머지는 **애플리케이션이 보장하는 논리 관계**다.  
> 전체 컬럼은 [테이블 명세서](테이블_명세서.md) 참고.

> ⚠️ 이 스키마는 FK 제약이 26건뿐이다(레거시 이관분은 FK 없음). 따라서 **DB 가 참조무결성을 지켜주지 않는다** — 삭제·이동 로직은 반드시 서비스 계층에서 연쇄 처리를 확인할 것.

---

## 1. 규정·조문 코어

분류(TB_CATE) 아래에 규정 회차(TB_PROM)가 달리고, 회차 1건이 조문·별표·이력을 소유한다. 같은 규정의 여러 회차는 `ILAW_ID` 로 묶이며(회차 그룹), 현행 회차는 시행일(`SSTART_DT`)·폐지일(`SNULL_DT`)로 판정한다.

```mermaid
erDiagram
    TB_CATE {
        NUMBER ICATE_NO
        NUMBER IREF
        VARCHAR2 SGUBUN_ID
        VARCHAR2 SNAME
        VARCHAR2 SDISP_YN
        VARCHAR2 SDEL_YN
    }
    TB_PROM {
        NUMBER IPROM_NO
        NUMBER ICATE_NO
        NUMBER IGAEJUNG_NO
        VARCHAR2 SGUBUN_ID
        NUMBER ILAW_ID
        VARCHAR2 STITLE
    }
    TB_CATE_OWNER {
        NUMBER ICATE_NO PK
        VARCHAR2 OWNER_TY PK
        VARCHAR2 OWNER_ID PK
    }
    TB_CATE_READER {
        NUMBER ICATE_NO PK
        VARCHAR2 READER_TY PK
        VARCHAR2 READER_ID PK
    }
    TB_GAEJUNG {
        NUMBER IGAEJUNG_NO
        VARCHAR2 SNAME
        VARCHAR2 SDEL_YN
    }
    TB_PROV_VRSN {
        NUMBER IPVRSN_NO
        NUMBER IPROM_NO
        VARCHAR2 SFULL_ITEM
        VARCHAR2 SITEM
        VARCHAR2 STITLE
        VARCHAR2 SDISP_YN
    }
    TB_PROV_HTML {
        NUMBER IPHTML_NO
        NUMBER IPROM_NO
        VARCHAR2 SITEM
        VARCHAR2 STITLE
        VARCHAR2 SDISP_YN
        VARCHAR2 SSTART_DT
    }
    TB_PROV_TEXT_HST {
        NUMBER IPTHST_NO
        NUMBER IPROM_NO
    }
    TB_DOCU {
        NUMBER IDOCU_NO
        NUMBER IPROM_NO
        VARCHAR2 SITEM
        VARCHAR2 STITLE
        VARCHAR2 SDISP_YN
        VARCHAR2 SSTART_DT
    }
    TB_PROM_WRK {
        NUMBER IPWRK_NO
        NUMBER IPROM_NO
        VARCHAR2 SSTATUS
    }
    TB_GAEJUNG_LOG {
        NUMBER IPROM_NO
    }
    TB_PROM_STSFDG {
        NUMBER IPROM_NO PK
        VARCHAR2 SINS_ID PK
    }
    TB_READ_DUTY {
        NUMBER IDUTY_NO PK
        NUMBER IPROM_NO
        NUMBER ILAW_ID
    }
    TB_PROM_MAP {
        NUMBER IPMAP_NO
        NUMBER IPROM_NO
        VARCHAR2 SNAME
        VARCHAR2 SDISP_YN
    }
    TB_CATE ||--o{ TB_CATE : "IREF · 자기참조 트리"
    TB_CATE ||--o{ TB_PROM : "ICATE_NO"
    TB_CATE ||--o{ TB_CATE_OWNER : "ICATE_NO ★FK"
    TB_CATE ||--o{ TB_CATE_READER : "ICATE_NO ★FK"
    TB_GAEJUNG ||--o{ TB_PROM : "IGAEJUNG_NO · 개정구분"
    TB_PROM ||--o{ TB_PROV_VRSN : "IPROM_NO · 조/항/호 분해"
    TB_PROM ||--o{ TB_PROV_HTML : "IPROM_NO · 조 단위 HTML"
    TB_PROM ||--o{ TB_PROV_TEXT_HST : "IPROM_NO · 일괄편집 스냅샷"
    TB_PROM ||--o{ TB_DOCU : "IPROM_NO · 별표/서식"
    TB_PROM ||--o{ TB_PROM_WRK : "IPROM_NO · 승인 워크플로"
    TB_PROM ||--o{ TB_GAEJUNG_LOG : "IPROM_NO · 작업로그"
    TB_PROM ||--o| TB_PROM_STSFDG : "IPROM_NO ★FK · 만족도"
    TB_PROM ||--o{ TB_READ_DUTY : "IPROM_NO ★FK · 필수열람"
    TB_PROM ||--o{ TB_PROM_MAP : "IPROM_NO · 규정맵 leaf"
```

| 테이블 | 설명 |
|---|---|
| [`TB_CATE`](테이블_명세서.md#tb-cate) | 규정 분류 트리 — 자기참조(IREF) + 비정규화 조상경로(IREF_LV_1~10) |
| [`TB_PROM`](테이블_명세서.md#tb-prom) | 규정 회차(공포) 마스터 — 법령/사규 등 규정의 제·개정 회차 단위 행 |
| [`TB_CATE_OWNER`](테이블_명세서.md#tb-cate-owner) | 분류별 작성자(소유) 매핑 — 부서/개인 N명 |
| [`TB_CATE_READER`](테이블_명세서.md#tb-cate-reader) | 분류별 열람제한 매핑 - 지정 시 해당 부서/개인만 열람, 미지정=전체 공개 |
| [`TB_GAEJUNG`](테이블_명세서.md#tb-gaejung) | 개정구분 마스터 (제정/일부개정/폐지 등) |
| [`TB_PROV_VRSN`](테이블_명세서.md#tb-prov-vrsn) | 조문 버전(단위 행) — 본문을 조/항/호 단위로 분해 저장, SFULL_ITEM 으로 회차간 비교 |
| [`TB_PROV_HTML`](테이블_명세서.md#tb-prov-html) | 조문 HTML 본문 — 회차별 조 단위 본문 1행 (저장 시 TB_PROV_VRSN 으로 분해) |
| [`TB_PROV_TEXT_HST`](테이블_명세서.md#tb-prov-text-hst) | 회차 본문 일괄편집 이력 — 일괄저장 직전 본문 텍스트 스냅샷 |
| [`TB_DOCU`](테이블_명세서.md#tb-docu) | 별표/별지서식 — 회차(IPROM_NO) 단위 누적(변경분만 저장) 모델 |
| [`TB_PROM_WRK`](테이블_명세서.md#tb-prom-wrk) | 규정 승인 워크플로 — 회차별 상태(편집중/승인요청/승인완료 등) 이력 행 |
| [`TB_GAEJUNG_LOG`](테이블_명세서.md#tb-gaejung-log) | 규정 등록·수정 작업 로그 — 회차 저장 시점에 자동 1행 기록 |
| [`TB_PROM_STSFDG`](테이블_명세서.md#tb-prom-stsfdg) | — |
| [`TB_READ_DUTY`](테이블_명세서.md#tb-read-duty) | 필수 열람 지정 — 승인 회차에 열람 의무 대상(전사/부서/개인) 지정, 회차당 1건 |
| [`TB_PROM_MAP`](테이블_명세서.md#tb-prom-map) | 규정맵(기능별분류) 트리 — 폴더(SPROM_YN=N)와 규정 leaf(SPROM_YN=Y), IREF 자기참조 |

---

## 2. 관련자료(8액션) 허브-상세 구조

`TB_REL_VRSN` 이 허브다. 자료 1건 = 허브 1행이고, `STABLE` 값이 실제 상세 테이블을 가리킨다(FILE/WORD/IMG/ORGN/HTML/LNK/DMN_LNK). 파일 실체는 `TB_ATTACH` 가 보관한다.

```mermaid
erDiagram
    TB_PROM {
        NUMBER IPROM_NO
        VARCHAR2 SGUBUN_ID
        NUMBER ILAW_ID
        VARCHAR2 STITLE
        VARCHAR2 SSTART_DT
        VARCHAR2 SNULL_DT
    }
    TB_REL_VRSN {
        NUMBER IRVRSN_NO
        NUMBER IPROM_NO
        NUMBER IRVCATE_NO
        VARCHAR2 STABLE
        VARCHAR2 SFLAG
        VARCHAR2 SFULL_ITEM
    }
    TB_REL_VRSN_CATE {
        NUMBER IRVCATE_NO
        VARCHAR2 STITLE
        NUMBER ILAW_ID
    }
    TB_REL_FILE {
        NUMBER IRFILE_NO
        NUMBER IATT_NO
        NUMBER IRVRSN_NO
        VARCHAR2 STITLE
        VARCHAR2 SDEL_YN
    }
    TB_REL_WORD {
        NUMBER IRWORD_NO
        NUMBER IATT_NO
        NUMBER IRVRSN_NO
        VARCHAR2 STITLE
        VARCHAR2 SDEL_YN
    }
    TB_REL_IMG {
        NUMBER IRIMG_NO
        NUMBER IATT_NO
        NUMBER IRVRSN_NO
        VARCHAR2 STITLE
        VARCHAR2 SDEL_YN
    }
    TB_REL_ORGN {
        NUMBER IRORGN_NO
        NUMBER IATT_NO
        NUMBER IRVRSN_NO
        VARCHAR2 STITLE
        VARCHAR2 SDEL_YN
    }
    TB_REL_HTML {
        NUMBER IRHTML_NO
        NUMBER IRVRSN_NO
        VARCHAR2 STITLE
        VARCHAR2 SDEL_YN
    }
    TB_REL_LNK {
        NUMBER IRLINK_NO
        NUMBER IRVRSN_NO
        VARCHAR2 STITLE
    }
    TB_REL_DMN_LNK {
        NUMBER IRDLNK_NO
        VARCHAR2 IRVRSN_NO
        VARCHAR2 SFLAG
        NUMBER ILAW_ID
        VARCHAR2 SFULL_ITEM
        VARCHAR2 STITLE
    }
    TB_ATTACH {
        NUMBER IATT_NO
        VARCHAR2 SNAME
        VARCHAR2 STITLE
    }
    TB_PROM ||--o{ TB_REL_VRSN : "IPROM_NO"
    TB_REL_VRSN_CATE ||--o{ TB_REL_VRSN : "IRVCATE_NO · 본문/붙임/양식"
    TB_REL_VRSN ||--o| TB_REL_FILE : "IRVRSN_NO (STABLE=FILE)"
    TB_REL_VRSN ||--o| TB_REL_WORD : "IRVRSN_NO (STABLE=WORD)"
    TB_REL_VRSN ||--o| TB_REL_IMG : "IRVRSN_NO (STABLE=IMG)"
    TB_REL_VRSN ||--o| TB_REL_ORGN : "IRVRSN_NO (STABLE=ORGN)"
    TB_REL_VRSN ||--o| TB_REL_HTML : "IRVRSN_NO (STABLE=HTML)"
    TB_REL_VRSN ||--o| TB_REL_LNK : "IRVRSN_NO (STABLE=LNK)"
    TB_REL_VRSN ||--o| TB_REL_DMN_LNK : "IRVRSN_NO (STABLE=DMN_LNK)"
    TB_ATTACH ||--o{ TB_REL_FILE : "IATT_NO · 파일 실체"
    TB_ATTACH ||--o{ TB_REL_WORD : "IATT_NO"
    TB_ATTACH ||--o{ TB_REL_IMG : "IATT_NO"
    TB_ATTACH ||--o{ TB_REL_ORGN : "IATT_NO"
```

| 테이블 | 설명 |
|---|---|
| [`TB_PROM`](테이블_명세서.md#tb-prom) | 규정 회차(공포) 마스터 — 법령/사규 등 규정의 제·개정 회차 단위 행 |
| [`TB_REL_VRSN`](테이블_명세서.md#tb-rel-vrsn) | 관련자료 마스터(허브) — 회차/조문에 붙은 자료 1건=1행, STABLE 이 실제 상세 테이블 |
| [`TB_REL_VRSN_CATE`](테이블_명세서.md#tb-rel-vrsn-cate) | 관련자료 카테고리(본문/붙임/양식 등) — 회차+법령 단위 그룹 헤더 |
| [`TB_REL_FILE`](테이블_명세서.md#tb-rel-file) | 관련자료 — 일반 파일 상세 |
| [`TB_REL_WORD`](테이블_명세서.md#tb-rel-word) | 관련자료 — 워드/HWP 문서 상세 (HTML 변환본 보관) |
| [`TB_REL_IMG`](테이블_명세서.md#tb-rel-img) | 관련자료 — 이미지 첨부 상세 |
| [`TB_REL_ORGN`](테이블_명세서.md#tb-rel-orgn) | 관련자료 — 원본(정본) 파일 상세, 다운로드 허용은 카테고리 SORGNDOWN_YN 정책으로 통제 |
| [`TB_REL_HTML`](테이블_명세서.md#tb-rel-html) | 관련자료 — 직접작성 HTML 표/본문 상세 |
| [`TB_REL_LNK`](테이블_명세서.md#tb-rel-lnk) | 관련자료 — 외부 URL 링크 상세 |
| [`TB_REL_DMN_LNK`](테이블_명세서.md#tb-rel-dmn-lnk) | 관련자료 — 규정/조문 연계(DOMAIN_LINK) 상세 |
| [`TB_ATTACH`](테이블_명세서.md#tb-attach) | 도메인 첨부파일 — SREF_TABLE+IREF_NO 다형 참조 (BBS/팝업 등 표준모듈은 COMTNFILE 사용) |

---

## 3. 사용자·권한·메뉴 (URL 인가 원천)

로그인 정본은 뷰 `COMVNUSERMASTER`(일반회원 + 업무사용자 UNION). URL 접근제어의 단일 원천은 **메뉴(COMTNMENUINFO) ↔ 프로그램(COMTNPROGRMLIST) ↔ 메뉴별 권한(COMTNMENUCREATDTLS)** 이다. 신규 화면을 추가하면 프로그램·메뉴·메뉴별권한을 반드시 함께 등록해야 접근이 열린다.

```mermaid
erDiagram
    COMTNORGNZTINFO {
        CHAR ORGNZT_ID PK
        CHAR UPPER_ORGNZT_ID
        VARCHAR2 ORGNZT_NM
    }
    COMTNEMPLYRINFO {
        VARCHAR2 EMPLYR_ID PK
        CHAR GROUP_ID
        CHAR ORGNZT_ID
    }
    COMTNAUTHORGROUPINFO {
        CHAR GROUP_ID PK
        VARCHAR2 GROUP_NM
    }
    COMTNGNRLMBER {
        VARCHAR2 MBER_ID PK
        CHAR GROUP_ID
    }
    COMTNAUTHORINFO {
        VARCHAR2 AUTHOR_CODE PK
    }
    COMTNAUTHORROLERELATE {
        VARCHAR2 AUTHOR_CODE PK
        VARCHAR2 ROLE_CODE PK
    }
    COMTNROLEINFO {
        VARCHAR2 ROLE_CODE PK
        VARCHAR2 ROLE_NM
    }
    COMTNROLES_HIERARCHY {
        VARCHAR2 PARNTS_ROLE PK
        VARCHAR2 CHLDRN_ROLE PK
    }
    COMTNMENUCREATDTLS {
        NUMBER MENU_NO PK
        VARCHAR2 AUTHOR_CODE PK
        VARCHAR2 MAPNG_CREAT_ID
    }
    COMTNMENUINFO {
        NUMBER MENU_NO PK
        VARCHAR2 PROGRM_FILE_NM
        NUMBER UPPER_MENU_NO
        VARCHAR2 MENU_NM
    }
    COMTNPROGRMLIST {
        VARCHAR2 PROGRM_FILE_NM PK
        VARCHAR2 URL
    }
    COMTNSITEMAP {
        VARCHAR2 MAPNG_CREAT_ID PK
    }
    COMTNORGNZTINFO ||--o{ COMTNORGNZTINFO : "UPPER_ORGNZT_ID ★FK · 부서 트리"
    COMTNORGNZTINFO ||--o{ COMTNEMPLYRINFO : "ORGNZT_ID ★FK"
    COMTNAUTHORGROUPINFO ||--o{ COMTNEMPLYRINFO : "GROUP_ID ★FK"
    COMTNAUTHORGROUPINFO ||--o{ COMTNGNRLMBER : "GROUP_ID ★FK"
    COMTNAUTHORINFO ||--o{ COMTNAUTHORROLERELATE : "AUTHOR_CODE ★FK"
    COMTNROLEINFO ||--o{ COMTNAUTHORROLERELATE : "ROLE_CODE ★FK"
    COMTNAUTHORINFO ||--o{ COMTNROLES_HIERARCHY : "PARNTS/CHLDRN ★FK"
    COMTNAUTHORINFO ||--o{ COMTNMENUCREATDTLS : "AUTHOR_CODE ★FK"
    COMTNMENUINFO ||--o{ COMTNMENUCREATDTLS : "MENU_NO ★FK"
    COMTNMENUINFO ||--o{ COMTNMENUINFO : "UPPER_MENU_NO ★FK · 메뉴 트리"
    COMTNPROGRMLIST ||--o{ COMTNMENUINFO : "PROGRM_FILE_NM ★FK"
    COMTNSITEMAP ||--o{ COMTNMENUCREATDTLS : "MAPNG_CREAT_ID ★FK"
```

| 테이블 | 설명 |
|---|---|
| [`COMTNORGNZTINFO`](테이블_명세서.md#comtnorgnztinfo) | 조직정보 |
| [`COMTNEMPLYRINFO`](테이블_명세서.md#comtnemplyrinfo) | 업무사용자정보 |
| [`COMTNAUTHORGROUPINFO`](테이블_명세서.md#comtnauthorgroupinfo) | 권한그룹정보 |
| [`COMTNGNRLMBER`](테이블_명세서.md#comtngnrlmber) | 일반회원 |
| [`COMTNAUTHORINFO`](테이블_명세서.md#comtnauthorinfo) | 권한정보 |
| [`COMTNAUTHORROLERELATE`](테이블_명세서.md#comtnauthorrolerelate) | 권한롤관계 |
| [`COMTNROLEINFO`](테이블_명세서.md#comtnroleinfo) | 롤정보 |
| [`COMTNROLES_HIERARCHY`](테이블_명세서.md#comtnroles-hierarchy) | 롤 계층구조 |
| [`COMTNMENUCREATDTLS`](테이블_명세서.md#comtnmenucreatdtls) | 메뉴생성내역 |
| [`COMTNMENUINFO`](테이블_명세서.md#comtnmenuinfo) | 메뉴정보 |
| [`COMTNPROGRMLIST`](테이블_명세서.md#comtnprogrmlist) | 프로그램목록 |
| [`COMTNSITEMAP`](테이블_명세서.md#comtnsitemap) | 사이트맵 |

---

## 4. 게시판·첨부(표준 모듈)

게시판은 eGov 표준을 그대로 쓴다. 첨부는 `COMTNFILE`(묶음) + `COMTNFILEDETAIL`(개별 파일) 2단 구조이며, 게시글은 `ATCH_FILE_ID` 로 묶음을 참조한다. 규정 도메인 첨부만 `TB_ATTACH` 를 쓴다.

```mermaid
erDiagram
    COMTNTMPLATINFO {
        CHAR TMPLAT_ID PK
    }
    COMTNBBSMASTER {
        CHAR BBS_ID PK
        CHAR TMPLAT_ID
        VARCHAR2 BBS_NM
    }
    COMTNBBS {
        NUMBER NTT_ID PK
        CHAR BBS_ID PK
        CHAR ATCH_FILE_ID
        VARCHAR2 NTT_SJ
    }
    COMTNBBSMASTEROPTN {
        CHAR BBS_ID PK
    }
    COMTNBBSWRITEAUTHOR {
        CHAR BBS_ID PK
        VARCHAR2 AUTHOR_CODE PK
    }
    COMTNAUTHORINFO {
        VARCHAR2 AUTHOR_CODE PK
    }
    COMTNCOMMENT {
        NUMBER NTT_ID PK
        CHAR BBS_ID PK
        NUMBER ANSWER_NO PK
    }
    COMTNSTSFDG {
        NUMBER STSFDG_NO PK
        NUMBER NTT_ID
    }
    COMTNFILE {
        CHAR ATCH_FILE_ID PK
    }
    COMTNFILEDETAIL {
        CHAR ATCH_FILE_ID PK
        NUMBER FILE_SN PK
    }
    COMTNFAQINFO {
        CHAR FAQ_ID PK
        CHAR ATCH_FILE_ID
    }
    COMTNTMPLATINFO ||--o{ COMTNBBSMASTER : "TMPLAT_ID · 스킨"
    COMTNBBSMASTER ||--o{ COMTNBBS : "BBS_ID ★FK"
    COMTNBBSMASTER ||--o| COMTNBBSMASTEROPTN : "BBS_ID · 옵션"
    COMTNBBSMASTER ||--o{ COMTNBBSWRITEAUTHOR : "BBS_ID ★FK · 작성권한"
    COMTNAUTHORINFO ||--o{ COMTNBBSWRITEAUTHOR : "AUTHOR_CODE ★FK"
    COMTNBBS ||--o{ COMTNCOMMENT : "NTT_ID+BBS_ID ★FK"
    COMTNBBS ||--o{ COMTNSTSFDG : "NTT_ID · 만족도"
    COMTNFILE ||--o{ COMTNFILEDETAIL : "ATCH_FILE_ID ★FK"
    COMTNBBS }o--o| COMTNFILE : "ATCH_FILE_ID"
    COMTNFAQINFO }o--o| COMTNFILE : "ATCH_FILE_ID ★FK"
```

| 테이블 | 설명 |
|---|---|
| [`COMTNTMPLATINFO`](테이블_명세서.md#comtntmplatinfo) | 템플릿 |
| [`COMTNBBSMASTER`](테이블_명세서.md#comtnbbsmaster) | 게시판마스터 |
| [`COMTNBBS`](테이블_명세서.md#comtnbbs) | 게시판 |
| [`COMTNBBSMASTEROPTN`](테이블_명세서.md#comtnbbsmasteroptn) | 게시판마스터옵션 |
| [`COMTNBBSWRITEAUTHOR`](테이블_명세서.md#comtnbbswriteauthor) | 게시판작성권한 |
| [`COMTNAUTHORINFO`](테이블_명세서.md#comtnauthorinfo) | 권한정보 |
| [`COMTNCOMMENT`](테이블_명세서.md#comtncomment) | 댓글 |
| [`COMTNSTSFDG`](테이블_명세서.md#comtnstsfdg) | 만족도 |
| [`COMTNFILE`](테이블_명세서.md#comtnfile) | 파일속성 |
| [`COMTNFILEDETAIL`](테이블_명세서.md#comtnfiledetail) | 파일상세정보 |
| [`COMTNFAQINFO`](테이블_명세서.md#comtnfaqinfo) | FAQ정보 |

---

## 5. 송무 — 사건 중심 구조

`LAW_SUIT` 이 **심급 1건 = 1행**이다. 1심·2심·3심은 별도 행이며 `FIRST_SUIT_ID` 로 사건군을 묶는다. 사용자가 올린 소송의뢰(`LAW_SUIT_REQ`)는 승인 후 `SUIT_ID` 로 사건에 연결된다. 첨부는 표준 `COMTNFILE`(ATCH_FILE_ID)을 쓴다.

```mermaid
erDiagram
    LAW_SUIT {
        NUMBER SUIT_ID PK
        NUMBER COURT_ID
        NUMBER FIRST_SUIT_ID
        VARCHAR2 COURT_NM
        VARCHAR2 CASE_NO
        VARCHAR2 CASE_NM
    }
    LAW_COURT {
        NUMBER COURT_ID PK
        NUMBER UPPER_COURT_ID
        VARCHAR2 COURT_NM
        CHAR USE_YN
    }
    LAW_SUIT_PARTY {
        NUMBER PARTY_ID PK
        NUMBER SUIT_ID
        VARCHAR2 PARTY_NM
    }
    LAW_SUIT_STAFF {
        NUMBER STAFF_ID PK
        CHAR ORGNZT_ID
        NUMBER SUIT_ID
    }
    LAW_SUIT_LAND {
        NUMBER LAND_ID PK
        NUMBER SUIT_ID
    }
    LAW_SUIT_PROG {
        NUMBER PROG_ID PK
        NUMBER SUIT_ID
    }
    LAW_SUIT_RSLT_HIST {
        NUMBER HIST_ID PK
        NUMBER SUIT_ID
    }
    LAW_SUIT_DOC {
        NUMBER DOC_ID PK
        NUMBER SUIT_ID
        VARCHAR2 DOC_TITL
        VARCHAR2 APP_STS_CD
    }
    LAW_SUIT_COST {
        NUMBER COST_ID PK
        NUMBER SUIT_ID
    }
    LAW_SUIT_LAWYER {
        NUMBER ASSIGN_ID PK
        NUMBER LAWYER_ID
        NUMBER SUIT_ID
    }
    LAW_LAWYER {
        NUMBER LAWYER_ID PK
        VARCHAR2 LAWYER_NM
        CHAR DEL_YN
    }
    LAW_LAWYER_SATIS {
        NUMBER ASSIGN_ID PK
        VARCHAR2 EMPLYR_ID PK
    }
    LAW_SUIT_REQ {
        NUMBER REQ_ID PK
        NUMBER SUIT_ID
        VARCHAR2 REQ_TITL
        VARCHAR2 STATUS_CD
    }
    LAW_SUIT_REQ_HIST {
        NUMBER HIST_ID PK
        NUMBER REQ_ID
    }
    LAW_SUIT_REQ_HELPER {
        NUMBER HELPER_ID PK
        NUMBER REQ_ID
    }
    COMTNORGNZTINFO {
        CHAR ORGNZT_ID PK
        VARCHAR2 ORGNZT_NM
    }
    LAW_SUIT ||--o{ LAW_SUIT : "FIRST_SUIT_ID · 심급 그룹"
    LAW_COURT ||--o{ LAW_SUIT : "COURT_ID"
    LAW_COURT ||--o{ LAW_COURT : "UPPER_COURT_ID · 법원 계층"
    LAW_SUIT ||--o{ LAW_SUIT_PARTY : "SUIT_ID · 원고/피고"
    LAW_SUIT ||--o{ LAW_SUIT_STAFF : "SUIT_ID · 수행자"
    LAW_SUIT ||--o{ LAW_SUIT_LAND : "SUIT_ID · 사건토지"
    LAW_SUIT ||--o{ LAW_SUIT_PROG : "SUIT_ID · 진행/기일"
    LAW_SUIT ||--o{ LAW_SUIT_RSLT_HIST : "SUIT_ID · 결과이력"
    LAW_SUIT ||--o{ LAW_SUIT_DOC : "SUIT_ID · 소송문서"
    LAW_SUIT ||--o{ LAW_SUIT_COST : "SUIT_ID · 소송비용"
    LAW_SUIT ||--o{ LAW_SUIT_LAWYER : "SUIT_ID · 선임"
    LAW_LAWYER ||--o{ LAW_SUIT_LAWYER : "LAWYER_ID"
    LAW_SUIT_LAWYER ||--o{ LAW_LAWYER_SATIS : "ASSIGN_ID · 만족도"
    LAW_SUIT_REQ }o--o| LAW_SUIT : "SUIT_ID · 승인 후 연계"
    LAW_SUIT_REQ ||--o{ LAW_SUIT_REQ_HIST : "REQ_ID · 사건경과"
    LAW_SUIT_REQ ||--o{ LAW_SUIT_REQ_HELPER : "REQ_ID · 보조자"
    COMTNORGNZTINFO ||--o{ LAW_SUIT_STAFF : "ORGNZT_ID · 표준 부서"
```

| 테이블 | 설명 |
|---|---|
| [`LAW_SUIT`](테이블_명세서.md#law-suit) | 송무 사건 마스터 — 심급 단위 1행, 사건군 그룹핑은 FIRST_SUIT_ID(§4.5) |
| [`LAW_COURT`](테이블_명세서.md#law-court) | 송무 법원 마스터 (계층 — 루트 COURT_ID=0). 대표 시드 22행, 부족분은 운영 등록 |
| [`LAW_SUIT_PARTY`](테이블_명세서.md#law-suit-party) | 송무 사건 당사자 (원고/피고/보조참가인) |
| [`LAW_SUIT_STAFF`](테이블_명세서.md#law-suit-staff) | 송무 사건 소송수행자 (부서=표준 COMTNORGNZTINFO 연동 — 레거시 김해 부서코드 A33 폐기) |
| [`LAW_SUIT_LAND`](테이블_명세서.md#law-suit-land) | 송무 사건토지 (행 단위 정규화 — 사건지번표시도(Kakao Geocoder) 원천).CASE_LAND_* |
| [`LAW_SUIT_PROG`](테이블_명세서.md#law-suit-prog) | 송무 진행상황·기일 겸용 — 소송등록 진행상황 그리드와 일정관리(달력)가 같은 테이블(§7.5) |
| [`LAW_SUIT_RSLT_HIST`](테이블_명세서.md#law-suit-rslt-hist) | 송무 결과변경 이력 — 결과 필드만 이력화(레거시 전체 스냅샷 폐지) |
| [`LAW_SUIT_DOC`](테이블_명세서.md#law-suit-doc) | 송무 소송문서 — 첨부=표준 COMTNFILE/COMTNFILEDETAIL(다중), 등록=승인대기·수정 시 대기 리셋(§7.2) |
| [`LAW_SUIT_COST`](테이블_명세서.md#law-suit-cost) | 송무 소송비용 (단일행 — 레거시 신청/지급 2테이블 통합) |
| [`LAW_SUIT_LAWYER`](테이블_명세서.md#law-suit-lawyer) | 송무 선임 (사건×변호사) — 만족도 평가 대상 단위(§4.3) |
| [`LAW_LAWYER`](테이블_명세서.md#law-lawyer) | 송무 변호사 명부 — 법무법인은 텍스트(마스터 비범위 §1.2) |
| [`LAW_LAWYER_SATIS`](테이블_명세서.md#law-lawyer-satis) | 송무 법무법인 만족도(간이 별점+의견) — 평가 대상=선임(사건×변호사) 단위, 1인 1회 MERGE(TB_PROM_STSFDG 패턴).2) |
| [`LAW_SUIT_REQ`](테이블_명세서.md#law-suit-req) | 송무 소송의뢰 — 사용자(front) 신청, 법무팀 승인/반려, 승인 후 소송등록 연계(§7.8·7.9) |
| [`LAW_SUIT_REQ_HIST`](테이블_명세서.md#law-suit-req-hist) | 송무 소송의뢰 사건경과 내역 (행별 첨부 1건) |
| [`LAW_SUIT_REQ_HELPER`](테이블_명세서.md#law-suit-req-helper) | 송무 소송의뢰 수행 보조자 (부서명은 자유 텍스트 — 외부 인원 허용) |
| [`COMTNORGNZTINFO`](테이블_명세서.md#comtnorgnztinfo) | 조직정보 |

---

## 6. 필수 열람(의무 숙지)

승인된 회차에 열람 의무를 지정하고(전사/부서/개인), 2단계(열람 자동기록 → 숙지 확인 버튼)로 증빙을 남긴다.

```mermaid
erDiagram
    TB_PROM {
        NUMBER IPROM_NO
        VARCHAR2 SGUBUN_ID
        NUMBER ILAW_ID
        VARCHAR2 STITLE
        VARCHAR2 SSTART_DT
        VARCHAR2 SNULL_DT
    }
    TB_READ_DUTY {
        NUMBER IDUTY_NO PK
        NUMBER IPROM_NO
        NUMBER ILAW_ID
    }
    TB_READ_DUTY_TGT {
        NUMBER IDUTY_NO PK
        VARCHAR2 STGT_TY PK
        VARCHAR2 STGT_ID PK
    }
    TB_READ_DUTY_CHK {
        NUMBER IDUTY_NO PK
        VARCHAR2 SUSER_ID PK
    }
    TB_PROM ||--o| TB_READ_DUTY : "IPROM_NO ★FK · 회차당 1건"
    TB_READ_DUTY ||--o{ TB_READ_DUTY_TGT : "IDUTY_NO ★FK · 대상 지정"
    TB_READ_DUTY ||--o{ TB_READ_DUTY_CHK : "IDUTY_NO ★FK · 확인 증빙"
```

| 테이블 | 설명 |
|---|---|
| [`TB_PROM`](테이블_명세서.md#tb-prom) | 규정 회차(공포) 마스터 — 법령/사규 등 규정의 제·개정 회차 단위 행 |
| [`TB_READ_DUTY`](테이블_명세서.md#tb-read-duty) | 필수 열람 지정 — 승인 회차에 열람 의무 대상(전사/부서/개인) 지정, 회차당 1건 |
| [`TB_READ_DUTY_TGT`](테이블_명세서.md#tb-read-duty-tgt) | 필수 열람 대상 행 — DEPT(부서)/USER(개인) 혼합 지정 (TB_CATE_READER 패턴) |
| [`TB_READ_DUTY_CHK`](테이블_명세서.md#tb-read-duty-chk) | 필수 열람 확인 — 2단계(열람 자동/숙지 버튼), 증빙 영구 보존 |

