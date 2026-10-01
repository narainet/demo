# RLMS(통합본) PostgreSQL 클린 설치 세트

Oracle 정본(`../newdb`)에서 자동 변환한 PostgreSQL 판. **파일만으로 클린 설치가 됩니다**
(Oracle 인스턴스 불필요).

## 0. 롤·DB 준비

`00_create_user.sql` 을 **관리자(postgres) 계정**으로 실행합니다.
`CREATE DATABASE` 는 트랜잭션 밖에서 실행되어야 합니다.

## 1. 실행 순서

| # | 파일 | 실행 계정 | 내용 |
|---|---|---|---|
| 0 | `00_create_user.sql` | postgres(관리자) | 롤 + DB 생성 |
| 1 | `10_tables.sql` | rlms | 공통·규정 테이블 77 + 뷰 + **DUAL 호환 테이블** |
| 2 | `11_indexes.sql` | rlms | 비PK 인덱스 |
| 3 | `12_comments.sql` | rlms | `COMMENT ON` (PG 네이티브) |
| 4 | `13_triggers_functions.sql` | rlms | 트리거 7 + `GET_FULL_NAME_BY_CATE_NO` (plpgsql) |
| 5 | **`15_law_install.sql`** | rlms | 송무 `LAW_*` 18테이블 DDL — **시드보다 먼저** (아래 ⚠️) |
| 6 | `20_seed_ccm.sql` | rlms | 공통코드 |
| 7 | `21_seed_menu.sql` | rlms | 프로그램·메뉴·메뉴별권한 (= URL 인가 원천) |
| 8 | `22_seed_auth.sql` | rlms | 권한·롤·매핑·계층 |
| 9 | `23_seed_org_accounts.sql` | rlms | 예시 부서·계정 4종·로그인정책 |
| 10 | `24_seed_bbs.sql` | rlms | 공지사항 게시판 + 템플릿 |
| 11 | `25_seed_domain.sql` | rlms | 개정구분·브랜드·**송무 기준데이터(법원·요율)** |
| 12 | `26_seed_idgn.sql` | rlms | 채번 행 (`COMTECOPSEQ`) |
| 13 | `30_fks.sql` | rlms | FK 제약 — **맨 마지막**(시드 정합 검증 겸용) |

> ⚠️ **RLMS 는 `15_law_install.sql` 을 시드보다 먼저** 돌립니다. 이 파일이 DDL 전용이고,
> 송무 기준데이터는 `25_seed_domain.sql` 이 넣기 때문입니다.
> (LexPortal 은 15 안에 시드가 들어 있어 20~26 **뒤**에 돌립니다 — 제품마다 다릅니다.)

## 2. 적재 방법

`psql` 로 번호 순서대로 실행하거나, 동봉 러너를 씁니다.

```bash
java -cp <postgresql.jar>;tools/multidb JdbcRunPg \
     "jdbc:postgresql://<host>:5432/rlms" rlms <pw> database/postgres/10_tables.sql
```

`JdbcRunPg` 는 plpgsql 의 `$$` 달러 인용을 문장 구분자로 오인하지 않으므로
**트리거·함수 파일(13)** 적재에 특히 필요합니다.

## 3. ⛔ PostgreSQL 특유의 함정

| 함정 | 내용 |
|---|---|
| **`DUAL` 테이블** | URL 인가에 쓰이는 공유 SQL(`context-security.xml` 인라인)이 `FROM DUAL` 을 대량 사용합니다. `10_tables.sql` 끝의 DUAL 생성 블록을 **절대 지우지 마세요** — 지우면 로그인 후 전 화면이 403 이 됩니다 |
| **`stringtype=unspecified`** | JDBC URL 에 필수. eGov VO 는 숫자·날짜도 String 으로 바인딩하므로, 이 옵션이 없으면 PG 강타입과 충돌해 오류가 납니다 |
| 식별자 대소문자 | DDL·매퍼 모두 **비따옴표**(소문자 폴딩)로 통일되어 있습니다. 따옴표를 붙이면 카탈로그가 어긋납니다 |
| `DATE` → `TIMESTAMP` | PG 의 `DATE` 는 시각을 버립니다. 변환기가 `TIMESTAMP` 로 바꿉니다 |
| CLOB 바인딩 | pgjdbc 에서 CLOB 은 OID 로 취급됩니다. 매퍼(`*_SQL_postgres.xml`)가 이미 대응되어 있습니다 |
| 전문검색 | `14_oracle_text`(Oracle Text)는 PG 에 이식하지 않았습니다. 통합검색은 `STRPOS` 부분일치로 동작합니다 |

## 4. Oracle 판과의 차이 (변환 규칙)

- 타입: `VARCHAR2(n)`→`VARCHAR(n)`, `NUMBER(p[,s])`→`SMALLINT/INT/BIGINT/NUMERIC`,
  `CLOB`→`TEXT`, `BLOB/RAW`→`BYTEA`, `DATE`→`TIMESTAMP`
- 함수: `SYSDATE`→`LOCALTIMESTAMP`, `SYSTIMESTAMP`→`CURRENT_TIMESTAMP`,
  시드의 `TO_DATE(…HH24MISS)`→`TO_TIMESTAMP(…)`, `SELECT ROWNUM`→`ROW_NUMBER() OVER ()`
- **PK 동명 선행 인덱스 생략** — Oracle 의 `CREATE UNIQUE INDEX PK_X` + `ADD CONSTRAINT PK_X`
  쌍은 PG 에서 이름 충돌이 나므로 선행 인덱스를 생략합니다

## 5. 재생성

```bash
set RLMS_WS=<제품들이 들어있는 폴더>
python tools/multidb/gen_pg_db.py
```

`13_triggers_functions.sql` 과 `00_create_user.sql` 은 생성기 대상이 아닌 수작업 이식본입니다
— 덮어쓰이지 않습니다.

## 6. 검증 상태

- DDL(10/11/12/13/15/30): 라이브 PostgreSQL 적재 + 스모크 98/98 통과 (2026-08-06)
- 시드(20~26): Oracle 정본에서 **자동 변환한 생성물**. 같은 생성기로 만든 RegNex·LexPortal
  세트는 라이브 검증을 마쳤으나, **RLMS 통합본 시드는 라이브 적재 검증 전**입니다.
  `30_fks.sql` 이 오류 없이 끝나면 참조 정합은 통과한 것입니다.
