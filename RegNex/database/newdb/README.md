# RegNex(규정관리 단독) 신규 DB 클린 설치 세트 (database/newdb/)

통합본 RLMS 스키마(2026-08-03 라이브)에서 **송무(law) 축만 걷어낸** 클린 설치 세트.
구조 스크립트(10~14, 30)는 통합본 newdb 와 동일(테이블 77 + 뷰 + 트리거 7 + 함수 1 + Oracle Text).
송무 `LAW_*` 18테이블·송무 메뉴/코드/역할만 빠진다.

## 실행 순서 (러너: RLMS `tools/dbq/dbr.ps1 regnex <pw> <file>`)

| # | 파일 | 내용 |
|---|---|---|
| 0 | `00_create_user.sql` | **SYS/SYSTEM** 로 1회 — regnex 계정 생성(이미 있으면 생략). CTXAPP 필수 |
| 1 | `10_tables.sql` | 테이블 77 + 뷰 COMVNUSERMASTER |
| 2 | `11_indexes.sql` | 비제약 인덱스 |
| 3 | `12_comments.sql` | 테이블/컬럼 코멘트 |
| 4 | `13_triggers_functions.sql` | 트리거 7 + 함수 1 (규정 삭제 cascade 체인) |
| 5 | `14_oracle_text.sql` | 한글 lexer + 전문검색 인덱스(TB_PROV_VRSN) |
| 6 | `20_seed_ccm.sql` | 공통코드 그룹 19·상세 86 (LAW_* 15그룹 제외) |
| 7 | `21_seed_menu.sql` | 프로그램 63·메뉴 73·메뉴별권한 169 (송무 55*/15* 메뉴·테스트보드 제외) |
| 8 | `22_seed_auth.sql` | 권한 8(ROLE_LAW_MGR 제외)·권한그룹 1·역할 39·매핑 76·계층 6 |
| 9 | `23_seed_org_accounts.sql` | 예시 부서 + 계정 3종(admin/approver/user, 초기 pw `rlms1234!`) |
| 10 | `24_seed_bbs.sql` | 공지사항 게시판 |
| 11 | `25_seed_domain.sql` | 개정구분 8종 + 법령질의 관리자 + COM_BRAND('RegNex 규정관리시스템') |
| 12 | `26_seed_idgn.sql` | COMTECOPSEQ 채번 66행(라이브 전량 — LAW_* 잉여 행 무해) |
| 13 | `30_fks.sql` | FK — **맨 마지막**(시드 정합 검증 겸용) |

## 통합본과의 차이

- 송무 메뉴 축(ADMIN 55*, USER 15*) 23+3개 메뉴·LAW_* 프로그램·ROLE_LAW_MGR 제외.
- 테스트 게시판 메뉴(35020000)는 클린 DB 에 해당 보드가 없어 제외 — 게시판 생성 시 자동 연결.
- 시드 재실행 비멱등(단순 INSERT). 실패 시 truncate 후 재실행. UTF-8(AL32UTF8) 필수.
