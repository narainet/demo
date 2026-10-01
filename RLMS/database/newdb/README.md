# RLMS 신규 DB 클린 설치 세트 (database/newdb/)

DDL 은 레거시 운영 DB(2026-07-09 기준)에서 **코드 감사 기반으로 추출·정리**한 신규 스키마
`RLMS` 클린 설치 스크립트. 규정/연혁 운영 데이터는 **이관하지 않는다**(클린 시작, 사용자 확정
2026-07-10). 시드는 시스템 구동에 필요한 최소 완전 집합 + 예시 데이터.

## ★시드(20~26)는 라이브에서 생성한다 — 손편집 금지 (2026-08-06)

손으로 관리하던 시드가 라이브와 벌어져 있었다(**메뉴 69 vs 라이브 101** — 송무·필수열람·브랜드설정이
통째로 빠져 있었다). 정본은 라이브 DB 이므로 시드도 라이브에서 다시 뽑는다.
maria/postgres 세트가 "DDL + 라이브 복사"인 것과 같은 원리다.

```
python tools/multidb/genseed.py      # SeedGen.java(JDBC) 를 호출해 20~26 을 통째로 다시 씀
python tools/multidb/checkseed.py    # 자기완결성 22항목 검증(참조 끊김·송무 포함·채번 선점)
```

★**송무(law)는 코어다** — RLMS 는 통합본(규정+송무)이므로 2026-08-06 부터 클린 설치에 포함한다.
메뉴 26·프로그램 21·코드그룹 15·채번키 17·`ROLE_LAW_MGR`·`lawmgr` 계정·법원 22·요율 41 이 모두 들어간다.
(⚠️`LAWQUEST_*` 는 법령질의라 **송무가 아니다** — 원래부터 포함)
송무를 쓰지 않는 고객사는 설치 후 `../rlms_law_menu_remove.sql` 로 메뉴만 내린다(데이터·테이블 보존).

시드에서 **의도적으로 빼는 것**(자기완결성 검증이 지킨다):
- **데모 게시판** — 라이브의 갤러리·자료실·탭분류형·테스트·웹진. 공지사항 1보드만 싣는다.
  '테스트' 게시판 메뉴(35020000)도 함께 뺀다(게시판과 메뉴는 반드시 같이 움직인다).
- **채번 값** — 키 목록은 라이브 전수, `NEXT_ID`=`1`. ⛔단 **시드가 ID 를 선점하는 2키는 예외**:
  `LAW_COURT_ID`=200(법원 시드 최대 194)·`LAW_CALC_RATE_ID`=100(요율 41행). 안 올리면 첫 등록에서 PK 충돌.

## 설치 대상 요약

| 구분 | 내용 |
|---|---|
| 테이블 | **95종** = 공통·규정 77(`10_tables.sql`) + 송무 `LAW_*` 18(`15_law_install.sql`). 2026-08-06 라이브 실측과 일치. 최초 71 = 라이브 추출 70 + 합성 1(COMTHEMPLYRINFOCHANGEDTLS — 사용자수정 저장이 무조건 INSERT 하는데 라이브에도 부재했던 결함 보정) |
| 뷰 | COMVNUSERMASTER (로그인 정본 — GNR+USR 2-way UNION 최신판) |
| 트리거 | 7종 수정 이식 (규정 삭제 cascade 체인 — 앱이 명시 의존). 13종 폐기 |
| 함수 | GET_FULL_NAME_BY_CATE_NO 1종 재작성 이식 (TB_CODE→ccm SGUBUN). 13종 폐기 |
| Oracle Text | TB_PROV_VRSN.SCONTENTS CONTEXT 인덱스 + 한글 lexer |
| 미생성(폐기) | TB_CODE·TB_BUSEO·TB_NOTICE·TB_REL_REF·TB_REL_HB_TML·TB_CATE_POL_ITM·TB_FT_CACHE_QUEUE·TB_QUEUE_TABLE·SQ_* 시퀀스 전부·레거시 정책엔진(TB_ACT*/TB_*_POL*/TB_USER*)·그룹웨어 연동(TB_EXT_*/TB_GW_*) + ★죽은 흐름 방어 8종 제외 확정(2026-07-10 사용자): COMTHEMAILDSPTCHMANAGE(비번찾기 폐지)·COMTNSTPLATINFO(가입약관 폐지)·COMTNBBSUSE(표준 잔재 — 게시판상세 매퍼의 AUTH_FLAG 서브쿼리를 NULL 리터럴로 치환, EgovBBSMaster_SQL_oracle.xml)·COMTHPROGRMCHANGEDTLS·COMTNBKMKMENUMANAGERESULT·COMTNBLOG·COMTNBLOGUSER·COMTNRESTDE(4종은 라이브에도 부재 — 해당 URL 직타 시 에러는 라이브와 동등) |

## 실행 순서

| # | 파일 | 실행 계정 | 내용 |
|---|---|---|---|
| 0 | `00_create_user.sql` | **SYS/SYSTEM** | RLMS 계정 생성 + 권한(CTXAPP 포함). 비밀번호 수정 후 실행 |
| 1 | `10_tables.sql` | RLMS | 공통·규정 테이블 77 + 뷰 |
| 2 | `11_indexes.sql` | RLMS | 비제약 인덱스 |
| 3 | `12_comments.sql` | RLMS | 테이블/컬럼 코멘트 |
| 4 | `13_triggers_functions.sql` | RLMS | 트리거 7 + 함수 1 (`/` 구분 — sqlplus/SQL Developer) |
| 5 | `14_oracle_text.sql` | RLMS | 한글 lexer + 전문검색 인덱스 |
| 6 | `15_law_install.sql` | RLMS | **송무 `LAW_*` 18테이블 DDL**(코멘트 249·인덱스 23). PK 18 / FK 0 |
| 7 | `20_seed_ccm.sql` | RLMS | 공통코드 34그룹·상세 384 (송무 코드 15그룹 포함) |
| 8 | `21_seed_menu.sql` | RLMS | 프로그램 85·메뉴 100·메뉴별권한 231 (=URL 보안 원천, 송무 메뉴 26 포함) |
| 9 | `22_seed_auth.sql` | RLMS | 권한 3-tier + `ROLE_LAW_MGR` (권한 9·롤 39·매핑 76·계층 8) |
| 10 | `23_seed_org_accounts.sql` | RLMS | 예시 부서 7 + 예시 계정 4(관리자·승인자·사용자·송무담당자) + 로그인정책 |
| 11 | `24_seed_bbs.sql` | RLMS | 공지사항 게시판 (BBS_ID 하드코딩 — ID 불변) + 템플릿 12 |
| 12 | `25_seed_domain.sql` | RLMS | 개정구분 9 + 브랜드 + 법령질의 담당자 + **송무 기준데이터**(법원 22·요율 41) |
| 13 | `26_seed_idgn.sql` | RLMS | COMTECOPSEQ 채번행 66종 (누락 = 해당 기능 첫 저장 실패) |
| 14 | `30_fks.sql` | RLMS | FK 26건 — **맨 마지막**(시드 정합 검증 겸용) |

> ★스키마 동기화 확인(2026-08-06): `10_tables.sql` 77 + `15_law_install.sql` 18 = **95** = 실DB 95(DR$ 제외).
> 스키마를 바꿀 때는 실DB DDL 과 이 스크립트를 **같은 커밋에서** 함께 고칠 것.
> 시드는 스키마와 달리 손대지 말고 `genseed.py` 로 다시 뽑는다.

- 클라이언트 인코딩 **UTF-8(AL32UTF8)** 필수. 시드 파일(20~26)은 첫 줄에 `SET DEFINE OFF`
  내장(메뉴명 'Q&A' 등 `&` 리터럴 보호) — sqlplus/SQL Developer 로 실행할 것.
- 모든 시드 스크립트는 재실행 비멱등(단순 INSERT). 실패 시 truncate 후 재실행.

## 예시 데이터 (전부 교체/추가 전제)

- **계정 4종** (★운영 전 즉시 변경. `sysmen` 만 `asdqwe123!`, 나머지 `rlms1234!`):
  - `sysmen`/관리자 → ROLE_ADMIN (관리자 대시보드)
  - `lawmgr`/송무담당자 → ROLE_LAW_MGR (송무관리)
  - `approver`/승인자 → ROLE_APPROVER (승인/반려)
  - `user`/사용자 → ROLE_USER (사용자 홈)
  - 해시 재생성: `java -cp tools/encpw;target/classes;… EncPw <평문> <로그인ID>` (솔트=로그인ID)
- **구분(SGUBUN)**: 법령·사규 2종만 예시 시드. 추가 구분·하위 분류(TB_CATE)는
  분류관리 화면에서 신규 사용자가 직접 생성 (TB_CATE 는 의도적으로 빈 상태로 시작).
- **부서 7종**(경영지원부·법무팀·본사·지사1·업무부·관리팀·관리1파트), **공지사항 보드 1개**.

## 앱 DataSource 전환 (신규 DB 준비 후)

`src/main/resources/egovframework/egovProps/globals.properties` 2개 키만 변경:

```properties
Globals.oracle.UserName = RLMS
Globals.oracle.Password = <ARIA 암호문>
```

- URL(`Globals.oracle.Url`)은 같은 인스턴스(CDB루트 방식)면 변경 불요.
- ARIA 암호문 생성: `.\tools\dbq\dbx.ps1 encdb "<새 평문 비밀번호>"`
- 매퍼는 전부 무한정자(스키마 접두 없음) — Java/XML 수정 불요 (2026-06-30 grep 검증).
- 변경 후 Tomcat 재기동. 첫 검증 동선: 로그인 3계정 → 홈/대시보드 렌더 → 분류관리(구분
  법령·사규 확인) → 규정 등록 → 조문 저장 → 승인 워크플로 → 통합검색.

## 알려진 특성 (설계 결정 사항)

1. ~~읽기전용 통계 2화면은 영구 빈 목록~~ → **해소(2026-07-30 확인)**: 시스템로그(TB_ACT_LOG —
   `StatsServiceImpl.recordAction`)·규정별 조회통계(TB_STATS_FT_VIEW — `insertViewStat`) 모두
   적재기가 붙어 자연 축적된다. 검색어 통계(TB_STATS_KWD)·게시판 조회통계(TB_STATS_BBS_VIEW) 도 동일.
   신규 설치 직후에는 당연히 비어 있고, 사용하면서 쌓인다.
2. **TB_SRC_STORED·TB_REL_ORGN·TB_DOCU 는 빈 시작**: 레거시 규정 데이터 자체를 이관하지
   않으므로 커버리지 공백 없음. 향후 레거시 이관 결정 시 함께 이관.
3. **SSYS_ID='레거시' 저장 규약**: 코드가 기본값으로 전면 하드코딩 — 분류/규정 데이터
   생성 시 앱이 자동으로 넣는 값이며 WHERE 필터로는 쓰지 않음(단일 시스템 원칙).
4. **죽은 표준모듈의 URL 직타**(휴일관리/블로그보드/바로가기/프로그램변경요청/비번찾기/
   가입약관)는 테이블 미생성으로 에러가 나지만, 4종은 라이브에도 테이블이 없어 현행과
   동등. 메뉴에 없는 화면들이라 정상 동선에선 도달 불가 — 컨트롤러 정리는 별도 과제.
5. **트리거 폐기 13종** 중 TRG_UPD_*(전문검색 캐시큐)·TRG_DEL_CATE(분류→규정 위험
   cascade)는 의도적 제거 — 앱 동작과 무관하거나 위험(상세: 13번 파일 헤더).
6. 첨부 저장 경로(`Globals.rlms.AttachPath`/`LegacyAttachPath`)는 신규 서버 기준으로
   globals.properties 에서 별도 확인 필요 (DB 무관).
