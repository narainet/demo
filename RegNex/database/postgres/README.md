# RegNex PostgreSQL 설치 세트

Oracle 정본(`../newdb`)에서 자동변환+수작업 이식으로 생성한 PostgreSQL 판. (2026-08-05)

## 실행 순서
| 순서 | 파일 | 실행 계정 | 비고 |
|---|---|---|---|
| 0 | `00_create_user.sql` | postgres(관리자) | 롤+DB 생성. CREATE DATABASE 는 트랜잭션 밖 |
| 1 | `10_tables.sql` | regnex | 테이블 77 + 뷰 COMVNUSERMASTER |
| 2 | `11_indexes.sql` | regnex | 비PK 인덱스 |
| 3 | `12_comments.sql` | regnex | COMMENT ON — PG 네이티브(Oracle 판 그대로) |
| 4 | `13_triggers_functions.sql` | regnex | 트리거 7종(*_FN 함수쌍) + GET_FULL_NAME_BY_CATE_NO |
| 5 | `20~26_seed_*.sql` | regnex | 시드(번호순) |
| 6 | `30_fks.sql` | regnex | FK 제약 |

## Oracle 판과의 차이 (변환 규칙)
- **식별자 큰따옴표 전면 제거** — PG 는 비따옴표 식별자를 소문자로 폴딩한다.
  매퍼 SQL(`*_SQL_postgres.xml`)이 전부 비따옴표라 DDL 도 비따옴표여야 카탈로그가 일치.
- 타입: `VARCHAR2(n)`→`VARCHAR(n)`, `NUMBER(p[,s])`→`SMALLINT/INT/BIGINT/NUMERIC`,
  `CLOB`→`TEXT`, `BLOB/RAW`→`BYTEA`, **`DATE`→`TIMESTAMP`**(PG DATE 는 시각 소실).
- 함수: `SYSDATE`→`LOCALTIMESTAMP`, `SYSTIMESTAMP`→`CURRENT_TIMESTAMP`,
  시드의 `TO_DATE('…','…HH24MISS')`→`TO_TIMESTAMP(…)`(PG TO_DATE 는 시각을 버림), `FROM DUAL` 제거.
- **PK 동명 선행 인덱스 생략**: Oracle 의 `CREATE UNIQUE INDEX PK_X` + `ADD CONSTRAINT PK_X PRIMARY KEY`
  쌍은 PG 에서 이름 충돌(PK 제약이 동명 인덱스를 자체 생성) → 선행 인덱스 문 29건 생략.
- `14_oracle_text.sql`(Oracle Text) 은 PG 미이식 — 전문/통합검색 매퍼가 `STRPOS` 부분일치로 동작
  (MariaDB 판의 INSTR 대체와 동일 설계, 소량 데이터 전제).

## 접속 정보(개발)
- `jdbc:postgresql://<DB서버>:5432/regnex?stringtype=unspecified` / regnex
- `stringtype=unspecified` 필수 — eGov VO 가 숫자/날짜도 String 으로 바인딩하므로
  PG 강타입과의 충돌을 드라이버가 서버 추론으로 흡수하게 한다.

## 적재 도구
- sqlplus 불요. JDBC 러너(예: 개발도구 JdbcRunPg — `$$` 달러 인용 인식) 또는 psql 로 순서대로 실행.
- 콜레이션 'C' 근거는 00_create_user.sql 헤더 참조.
