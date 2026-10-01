# tools/multidb — 멀티DB(Oracle→MariaDB/PostgreSQL) 이식·검증 도구함

LexPortal(송무 단독)·RegNex(규정 단독)의 3DB 지원(Oracle/MariaDB/PostgreSQL) 작업에서
만들어 실전 검증한 도구 일체. (2026-08-03 maria 세션 + 2026-08-05 postgres 세션 산출물의 상설화)

- 위치 관행: `tools/` 는 SVN 제외(git 만). dbq 처럼 RLMS tools 가 제품 공용 도구함.
- 접속 정보는 환경변수로 주입한다: `RLMS_DB_URL` / `RLMS_DB_USER` / `RLMS_DB_PASS`
  (기본 포트 — Oracle 1521 · MariaDB 3306 · PostgreSQL 5432).
- 자바 도구 컴파일: `%RLMS_JDK%/bin/javac -encoding UTF-8 <파일>.java`
  드라이버 jar(m2): postgresql-42.7.3 · mariadb-java-client-2.2.5 · ojdbc11-21.11.0.0

## 신규 DB 이식 표준 절차 (maria/pg 에서 검증된 순서)
1. **DDL/시드 생성** — `gen_maria_db.py` / `gen_pg_db.py` (newdb Oracle 정본 → database/maria|postgres)
2. **적재** — `JdbcRun`(maria, 2플래그 세션) / `JdbcRunPg`(pg, `$$` 달러 인용 인식).
   순서: 10→11→(12 pg)→(13 트리거)→20~26 시드→**15_law_install 은 시드 뒤**→30_fks
3. **매퍼 변환** — `map_ora2maria.py`(oracle→maria) / `map_maria2pg.py`(★maria 판을 원본으로 — 구조 수작업 재사용)
4. **린트** — `SqlLint`(maria, EXPLAIN) / `SqlLintPg`(pg, EXPLAIN·autocommit) — 잔여는 노이즈 분류로 판정
5. **실행 스윕** — `SqlRunPg`(SELECT 전건 실제 실행 — EXPLAIN 이 못 잡는 런타임 오류)
6. **표본 복사+채번 동기** — `OraToMaria` / `OraToPg`(채번 동기 내장, PG 는 superuser 접속 필수)
7. **시드 무결 대조** — `digest_*.sql` 을 원본/대상 DB 양쪽에 실행해 diff.
   ⛔행수만 비교하면 값 훼손(백슬래시 소실 등)을 못 잡는다 — **ROLE_PTTRN_LEN(길이합)** 이 정본 검증
8. **실기동 스모크** — DbType 전환→`mvn -o package`→스크래치 톰캣(`tomcat/server-*.xml`)→`smoke_*.ps1`

## 파일별 요약
| 파일 | 용도 |
|---|---|
| `gen_maria_db.py` | Oracle newdb → MariaDB DDL/시드(코멘트 인라인 주입, MariaDB 는 COMMENT ON 없음) |
| `gen_pg_db.py` | Oracle newdb → PostgreSQL DDL/시드(따옴표 전면 제거=소문자 폴딩 정합, PK 동명 선행 인덱스 생략, DATE→TIMESTAMP, COMMENT ON 통과) |
| `gen_product_db.py` | 라이브 RLMS 덤프 → 제품별 newdb 시드 필터(8/3 분리 때 사용) |
| `map_ora2maria.py` | 매퍼 oracle→maria 변환기(NVL/TO_CHAR 는 maria 네이티브라 보존) |
| `map_maria2pg.py` | 매퍼 maria→postgres 변환기(어휘 치환 — 구조는 maria 판이 이미 보유) |
| `JdbcRun.java` | 범용 JDBC 러너. ⛔maria 는 `PIPES_AS_CONCAT,NO_BACKSLASH_ESCAPES` 세션 자동 적용(빼면 시드 훼손) |
| `JdbcRunPg.java` | PG 로더 — plpgsql `$$` 달러 인용 안 쪼갬. 트리거/함수 파일 적재용 |
| `SqlLint.java` | maria EXPLAIN 린터(include 다중패스 전개) |
| `SqlLintPg.java` | PG EXPLAIN 린터 — autocommit(오류시 tx abort 회피)·CDATA 플레이스홀더 보호·selectKey 제거·날짜 파라미터 '2026-01-01'·`${별칭}.` 한정자 제거 |
| `SqlRunPg.java` | PG SELECT 실행 스윕(린트 통과 후 런타임 검증) |
| `OraToMaria.java` / `OraToPg.java` | 표본 데이터 복사기(대상 0행 & 원본 유행만·컬럼 교집합). OraToPg 는 COMTECOPSEQ 라이브 동기 내장, **PG 접속=superuser**(session_replication_role=replica) |
| `DecPw.java` / `DbDump.java` | ARIA 복호 / 스키마 덤프 보조 |
| `digest_regnex.sql` / `digest_lexportal.sql` | 시드 무결 digest(행수+ROLE_PTTRN 길이합) — Oracle/maria/pg 3사 공용 문법 |
| `smoke_regnex.ps1`(7072) / `smoke_lexportal.ps1`(7071) | 로그인+전 URL 스윕+심층. 오류 판정=HTTP·오류마커·**한글 오류페이지**('데이터처리/시스템 에러'는 200 으로 위장)·login-redirect |
| `smoke_urls_*.txt` | 스윕 URL 목록(원천=COMTNPROGRMLIST, `SELECT URL FROM COMTNPROGRMLIST WHERE URL != 'folder'` 로 재생성 가능) |
| `tomcat/server-*-707N.xml` | 스크래치 CATALINA_BASE 용 server.xml(HTTP 7071/7072·shutdown 8008/8007·Context docBase=target 전개본). 기동 레시피는 메모리 reference_wtp_tomcat_headless_launch |
| `fixups/` | 일회성 수리·스캐너 모음(rownum 페이징 해체 3종·별칭/OSET 수리·손상 스캐너·`mapsel_report.py`=맵 별칭 소문자 폴딩 취약점 스캐너·prune_pom 등) |

## ⛔이식 함정 요약 (상세는 메모리 project_multidb_maria_20260803 / project_multidb_postgres_20260805)
- **maria**: `||`=OR(PIPES 필수)·백슬래시 이스케이프(NO_BACKSLASH 필수)·날짜 산술=숫자 뺄셈·KEEP/INSERT ALL/FULL OUTER 미지원·파생테이블 별칭 필수·DESC NULLS LAST 등가라 절 제거됨(PG 이식 때 복원 필요)
- **pg**: pgjdbc CLOB=대형객체 OID(`jdbcType=CLOB` 금지)·미지정 바인드 `IS NULL` 추론 불가(CAST 필요)·무따옴표 별칭 소문자 폴딩(맵 반환 select 만 취약)·블록 주석 중첩 해석(주석 속 `/*` 금지)·FROM DUAL 부재(호환 테이블)·DESC 기본 NULLS FIRST·LPAD(numeric) 불가·재귀 CTE 양변 타입 일치·TO_DATE 토큰 그리디·FOR UPDATE WAIT 미지원·URL `stringtype=unspecified` 필수
