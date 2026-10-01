# RLMS(통합본) MariaDB 클린 설치 세트

Oracle 정본(`../newdb`)에서 자동 변환한 MariaDB 판. **파일만으로 클린 설치가 됩니다**
(Oracle 인스턴스 불필요).

> MariaDB 에는 `COMMENT ON` 문이 없어, 컬럼 코멘트를 `CREATE TABLE` 안에 인라인으로
> 주입했습니다. 그래서 `12_comments.sql` 이 없습니다.

## 0. DB·계정 준비 (관리자 계정으로 1회)

```sql
CREATE DATABASE rlms CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'rlms'@'%' IDENTIFIED BY '<비밀번호>';
GRANT ALL PRIVILEGES ON rlms.* TO 'rlms'@'%';
FLUSH PRIVILEGES;
```

서버 설정은 `lower_case_table_names=1` 을 전제로 합니다.

## 1. 실행 순서

| # | 파일 | 내용 |
|---|---|---|
| 1 | `10_tables.sql` | 공통·규정 테이블 77 + 뷰 `COMVNUSERMASTER` (코멘트 인라인) |
| 2 | `11_indexes.sql` | 비PK 인덱스 |
| 3 | `13_triggers_functions.sql` | 트리거 7 + 함수 1 (재귀 CTE 판) |
| 4 | **`15_law_install.sql`** | 송무 `LAW_*` 18테이블 DDL — **시드보다 먼저** (아래 ⚠️) |
| 5 | `20_seed_ccm.sql` | 공통코드 |
| 6 | `21_seed_menu.sql` | 프로그램·메뉴·메뉴별권한 (= URL 인가 원천) |
| 7 | `22_seed_auth.sql` | 권한·롤·매핑·계층 |
| 8 | `23_seed_org_accounts.sql` | 예시 부서·계정 4종·로그인정책 |
| 9 | `24_seed_bbs.sql` | 공지사항 게시판 + 템플릿 |
| 10 | `25_seed_domain.sql` | 개정구분·브랜드·**송무 기준데이터(법원·요율)** |
| 11 | `26_seed_idgn.sql` | 채번 행 (`COMTECOPSEQ`) |
| 12 | `30_fks.sql` | FK 제약 — **맨 마지막**(시드 정합 검증 겸용) |

> ⚠️ **RLMS 는 `15_law_install.sql` 을 시드보다 먼저** 돌립니다. 이 파일이 DDL 전용이고,
> 송무 기준데이터(법원 22·요율 41)는 `25_seed_domain.sql` 이 넣기 때문입니다.
> (LexPortal 은 반대로 15 안에 시드가 들어 있어 20~26 **뒤**에 돌립니다 — 제품마다 다릅니다.)

## 2. 적재 방법

```bash
# 동봉 러너 (세션 플래그를 자동으로 걸어 줍니다)
java -cp <mariadb-java-client.jar>;tools/multidb JdbcRun \
     "jdbc:mariadb://<host>:3306/rlms" rlms <pw> database/maria/10_tables.sql
```

⛔ **`mysql` CLI 로 직접 넣을 때는 세션 모드 2종을 반드시 켜세요.**

```sql
SET SESSION sql_mode = CONCAT(@@sql_mode, ',PIPES_AS_CONCAT,NO_BACKSLASH_ESCAPES');
```

빼면 시드 문자열의 백슬래시가 소실되고 `||` 연결이 논리 OR 로 해석되어 **데이터가 조용히
훼손**됩니다. 운영 DataSource 는 `context-datasource.xml` 의 maria 프로파일에 있는
`connectionInitSqls` 가 같은 일을 합니다.

## 3. Oracle 판과의 차이 (변환 규칙)

- 타입: `VARCHAR2(n)`→`VARCHAR(n)`, `NUMBER(p,s)`→`DECIMAL(p,s)`,
  `NUMBER(p)`→`SMALLINT/INT/BIGINT`, `CLOB`→`LONGTEXT`
- `SYSDATE`→`NOW()`, `FROM DUAL` 제거
- **물리 `DUAL` 테이블 없음** — MariaDB 는 `SELECT ... FROM DUAL` 을 문법으로 지원합니다
  (PostgreSQL 판에는 호환 테이블이 별도로 있습니다)
- `NVL` / `TO_CHAR(날짜)` 는 MariaDB 네이티브라 **변환하지 않습니다**

## 4. 재생성

스키마(`../newdb`)를 고쳤다면 이 폴더를 손으로 고치지 말고 다시 뽑으세요.

```bash
set RLMS_WS=<제품들이 들어있는 폴더>
python tools/multidb/gen_maria_db.py
```

`13_triggers_functions.sql` 만 생성기 대상이 아니라 수작업 이식본입니다 — 덮어쓰이지 않습니다.

## 5. 검증 상태

- DDL(10/11/13/15/30): 라이브 MariaDB 적재 + 스모크 98/98 통과 (2026-08-06)
- 시드(20~26): Oracle 정본에서 **자동 변환한 생성물**. 같은 생성기로 만든 RegNex·LexPortal
  세트는 라이브 검증을 마쳤으나, **RLMS 통합본 시드는 라이브 적재 검증 전**입니다.
  최초 설치 시 각 파일의 실행 오류 유무를 확인하고, `30_fks.sql` 이 오류 없이 끝나면
  참조 정합은 통과한 것입니다.
