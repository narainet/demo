# LexPortal(송무관리 단독) 신규 DB 클린 설치 세트 (database/newdb/)

통합본 RLMS 스키마(2026-08-03 라이브)에서 **제품 필터링**으로 생성한 클린 설치 세트.
구성 = 공통 관리자 베이스(표준 `COMTN*` 41종 + 로그인 뷰) + 송무 `LAW_*` 18종.
규정관리(`TB_*`) 축은 공통 인프라 2종(`TB_ACT_LOG` 활동로그, `TB_STATS_BBS_VIEW` 게시판 조회통계)만 포함.

## 실행 순서 (러너: RLMS `tools/dbq/dbr.ps1 lexportal <pw> <file>`)

| # | 파일 | 내용 |
|---|---|---|
| 0 | `00_create_user.sql` | **SYS/SYSTEM** 로 1회 — lexportal 계정 생성(이미 있으면 생략) |
| 1 | `10_tables.sql` | 공통 테이블 41 + 뷰 COMVNUSERMASTER |
| 2 | `11_indexes.sql` | 비제약 인덱스(공통분) |
| 3 | `12_comments.sql` | 테이블/컬럼 코멘트(공통분) |
| 4 | `20_seed_ccm.sql` | 공통코드 그룹 29·상세 361 (규정 전용 5그룹 제외, LAW_* 15그룹 포함) |
| 5 | `21_seed_menu.sql` | 프로그램 59·메뉴 71·메뉴별권한 134 (=URL 인가 원천, 2026-08-04 GNB 재편 반영) |
| 6 | `22_seed_auth.sql` | 권한 9·권한그룹 1·역할 37·매핑 71·계층 8 |
| 7 | `23_seed_org_accounts.sql` | 예시 부서 + 계정 4종(sysmen/approver/lawmgr/user — sysmen=`asdqwe123!`, 나머지 `rlms1234!`) |
| 8 | `24_seed_bbs.sql` | 공지사항 게시판 |
| 9 | `25_seed_brand.sql` | COM_BRAND 기본 행('LexPortal 송무관리시스템') |
| 10 | `26_seed_idgn.sql` | COMTECOPSEQ 채번 66행(라이브 전량 — 잉여 행 무해, 누락=첫 저장 실패) |
| 11 | `15_law_install.sql` | 송무 LAW_* 18테이블 + 채번 17 + ccm 코드(중복가드) + 법원 22·요율 시드 |
| 12 | `30_fks.sql` | FK(공통분) — **맨 마지막**(시드 정합 검증 겸용) |

> ⚠️ 26(채번)을 15(law) **앞에** 실행할 것 — 15 의 채번 INSERT 는 NOT EXISTS 가드가 있지만
>   26 은 단순 INSERT 라 15 를 먼저 돌리면 중복(ORA-00001)이 난다.

## 메뉴 구성 (2026-08-04 관리자 GNB 재편)

- ADMIN GNB 7분할: 소송관리(1) / 일정관리(2) / 소송의뢰관리(3) / 선임관리(4) / 소송통계(5) / 게시판관리(6) / 관리자(7)
  - 소송관리 하위 7: 소송조회·소송문서조회·문서 승인·법원서류접수·압류관리·소송비용조회·소송비용 요율설정
  - 선임관리 하위 2: 선임관리·변호사관리 / 소송통계 하위 7종 유지
  - 게시판관리 하위: 게시판속성관리·템플릿관리·FAQ 관리·Q&A 관리(구 도움말관리 폴더 흡수·해체) + 사용 게시판 자동 연결
  - 관리자 하위 6그룹: 사용자관리/권한관리/메뉴관리/로그관리/운영관리/통계(사용자 활동 로그·게시판 조회통계·접속통계)
  - 대시보드(55010000, 구 송무 홈) = MENU_SE 'HIDDEN' — GNB 미노출. /law/index.do URL 인가(L6) 파생 원천이라 행·권한(ADMIN/LAW_MGR) 유지, 삭제 금지. 진입 = CI 클릭(/main.do)·모바일 드로어.
  - 관리자 축 메뉴는 ROLE_ADMIN 단독(EDITOR/APPROVER 부여 정리 — 부모 없는 GNB 고아 방지)
- USER GNB: 게시판 / 소송의뢰 / 도움말 / 마이페이지 (변경 없음)

## 통합본과의 차이

- 규정(`TB_*`) 테이블·트리거·Oracle Text·개정구분 시드 없음 (13/14/25_seed_domain 미포함).
- `TB_STATS_FT_VIEW`/`TB_STATS_KWD` 없음 — 대응 화면(규정별 조회통계 등)은 소스에서도 제거됨.
- 역할: ROLE_MGR_LAWQUEST/ROLE_USR_LAWQUEST(법령질의 표기용) 제외. EDITOR/APPROVER 는
  공통 게시판 권한 어휘가 참조하므로 유지.
- 시드 재실행 비멱등(단순 INSERT). 실패 시 truncate 후 재실행. UTF-8(AL32UTF8) 필수.
