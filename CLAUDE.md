# CLAUDE.md — 공통 개발 지침

이 파일은 Claude Code 가 이 폴더 아래에서 작업할 때 자동으로 읽습니다.
제품별 추가 지침은 각 제품 폴더의 `CLAUDE.md` 에 있습니다.

---

## 이 저장소가 무엇인가

전자정부 표준프레임워크 4.3.0 기반 **규정·송무 관리시스템 3종**입니다.

| 폴더 | 제품 | 범위 |
|---|---|---|
| `RLMS/` | 통합본 | 규정관리 + 송무 |
| `RegNex/` | 규정관리 전용 | 규정관리 |
| `LexPortal/` | 송무 전용 | 송무 |

셋은 **같은 코드베이스에서 갈라진 형제**입니다. 공통 기반(`egovframework.com.*`)은
거의 동일합니다.

### ★ 3제품 동기화 규칙

공통 영역(`egovframework.com.*`, 공통 JSP/CSS/JS, 표준 매퍼)을 고칠 때는
**그 파일을 가진 모든 제품에 같이 반영**해야 합니다. 한 곳만 고치면 제품 간에
조용히 벌어집니다.

수정 전에 확인:

```bash
# 같은 파일이 다른 제품에도 있는지
ls RLMS/<경로> RegNex/<경로> LexPortal/<경로> 2>/dev/null
```

도메인 코드는 제품별로 다릅니다 — `narainet.rlms.*` 는 RLMS·RegNex 에만,
`narainet.law.*` 는 RLMS·LexPortal 에만 있습니다.

---

## 먼저 읽을 문서

작업 성격에 따라 **해당 문서를 먼저 읽고** 시작하세요.

| 하려는 일 | 읽을 문서 |
|---|---|
| 무엇이든 (처음) | `docs/01_시스템_개요.md` |
| 코드 수정 | **`docs/04_개발규약_아키텍처.md`** ← 함정 모음이 여기 있습니다 |
| DB·스키마 | `docs/03_데이터베이스_가이드.md`, `<제품>/docs/테이블_명세서.md` |
| 도메인 로직 이해 | `docs/05_핵심기능_설명서.md` |
| 빌드·기동 | `docs/02_설치_가이드.md` |
| 검증 | `docs/06_도구_사용설명서.md` |
| **"이건 왜 안 되나" 판단** | **`docs/08_현재_한계와_향후과제.md`** |

### 알려진 한계 — 여기서 막히면 파고들지 말고 08 문서를 볼 것

- **WAS 는 Tomcat 9 가 정본**입니다. **10.0 · 11.0 도 배포 시 `migrate.bat` 1회로 동작**합니다
  (소스 무수정, Tomcat 11 은 JDK 17 필요). 10.1 은 실측하지 않았습니다.
  ※ 2026-08-06 까지는 10.1 이상이 막혀 있었고, **SiteMesh 제거(2026-08-07)로 해소**됐습니다.
- **레이아웃은 JSP 태그파일**입니다. 화면 JSP 가 `<lay:layout>` 으로 자기 셸을 감싸고,
  어느 셸을 쓸지는 `WEB-INF/layouts.xml` 의 **URL 매핑**이 정합니다(페이지에 셸 이름을 박지 말 것).
  **⛔ 태그 본문은 `scriptless`** — 안에서 `<% %>`/`<%= %>` 사용 불가. 자세한 건 `docs/04` §8.1.
- **소스 문법만 Java 8 고정**이고, 빌드/구동 JDK 는 8·17·21 모두 됩니다.
- **DB 가 참조무결성을 지켜주지 않습니다**(FK 26건, `TB_*` 는 PK 제약 없음).
- **오류 화면이 HTTP 200 으로 나옵니다.** 상태 코드만으로 성공 판정 금지.

---

## 절대 규칙

### 1. JDK 1.8 문법만 씁니다
`var`, `record`, 텍스트 블록, `List.of(...)` 등 Java 9+ 문법은 **컴파일되지 않습니다.**

### 2. 매퍼는 항상 3벌을 함께 고칩니다
```
<기능>_SQL_oracle.xml
<기능>_SQL_maria.xml       ← 하나만 고치면 다른 DBMS 에서 조용히 깨집니다
<기능>_SQL_postgres.xml
```
고친 뒤에는 `tools/multidb/SqlLint*` 로 검사하세요.

### 3. 새 URL 은 DB 등록이 필요합니다
컨트롤러만 만들면 **403** 입니다. `COMTNPROGRMLIST` → `COMTNMENUINFO` →
`COMTNMENUCREATDTLS` 3곳에 등록하고 **재기동**해야 열립니다.
(`docs/04` §6)

### 4. 채번은 `COMTECOPSEQ` + `EgovIdGnrService`
시퀀스(`SQ_*.NEXTVAL`)를 쓰지 않습니다. 새 테이블을 만들면 **채번 행과 idgn 빈을
함께 추가**하세요 — 없으면 그 기능의 첫 저장이 실패합니다.

### 5. `SSYS_ID` 를 조회 조건으로 쓰지 않습니다
단일 시스템 고정값입니다. `WHERE SSYS_ID = ...` 를 넣으면 데이터가 사라져 보입니다.

### 6. 논리 삭제
`SDEL_YN='N'` / `SDISP_YN='N'` 은 tombstone 입니다. 물리 삭제 로직을 넣지 마세요.

### 7. 프로퍼티 변경은 재기동해야 반영됩니다
`globals.properties` 는 기동 시 1회 로드입니다.

---

## 코드 규약 요약

| 대상 | 규칙 |
|---|---|
| 도메인 패키지 | `narainet.rlms.<기능>` / `narainet.law.<기능>` |
| **재사용 컴포넌트** | `egovframework.com.*` **원위치**에 둡니다 |
| 클래스 | `<기능>Controller/Service/ServiceImpl/Mapper/VO` |
| 매퍼 XML | `resources/egovframework/mapper/<도메인>/<기능>/<기능>_SQL_<db>.xml` |
| JSP | `WEB-INF/jsp/<도메인>/<기능>/` |
| URL | `/<도메인>/<기능>/<동작>.do` |
| 컬럼 | 헝가리안 — `I`=숫자, `S`=문자 |
| 스타일 | **KRDS 우선**. 폼은 `krds-form` + `tbl-detail` |
| Lombok | 적극 사용 (`@Getter`/`@Setter`/`@Builder`) |
| 트랜잭션 | `@Transactional` |
| SQL | 자바에 두지 않고 전부 MyBatis XML |

**DDL 을 추가할 때는 테이블·전 컬럼에 한국어 코멘트를 반드시 답니다.**
(문서 자동 생성이 이 코멘트를 원천으로 씁니다)

---

## 자주 밟는 함정

| 함정 | 결과 |
|---|---|
| MyBatis `<if test="x == 'Y'">` | 작은따옴표는 char — **큰따옴표**로 `test='x == "Y"'` |
| XML 주석 안에 `--` | 매퍼 로딩 실패 |
| JSP 주석(`//`) 안에 커스텀 태그 | 태그가 실행되어 500 |
| `<c:choose>` 직접 자식에 HTML 주석 | 오류 |
| `jsp:include` 로 변수 전달 | 안 됩니다 — `<c:set scope="request">` |
| `redirect:` 앞에서 모델에 담은 한글 | 사라집니다 — flash attribute |
| `.jspf` 에 `pageEncoding` 누락 | 한글 깨짐 |
| CSS grid `1fr` | 좁은 화면 넘침 — `minmax(0,1fr)` + `min-width:0` |
| `zoom` 을 body 에 적용 | 가로 스크롤 깨짐 — 래퍼에. `vh/vw` 는 `calc(N/var(--rlms-zoom,1))` |
| FK 믿고 연쇄 삭제 생략 | FK 가 26건뿐 — 서비스 계층에서 직접 연쇄 처리 |
| 메뉴 self-FK CASCADE | 자식 메뉴 대량 삭제 — 자식을 먼저 재배치 |
| `atchFileId` 재복호 | 바인딩 시 이미 복호됩니다 (no-op) |

---

## 빌드 · 검증

```bash
mvn -o -f RLMS/pom.xml compile        # ⛔ clean 금지 (WTP 배포본이 날아갑니다)
```

```bash
powershell -ExecutionPolicy Bypass -File tools\smoke.ps1
powershell -ExecutionPolicy Bypass -File tools\authcheck.ps1 -DbPass '<pw>'
```

⚠️ **오류 화면이 HTTP 200 으로 위장됩니다.** 전역 예외 처리기가 예외를 잡아
"시스템 에러" 화면을 200 으로 돌려주기 때문에, 상태 코드만으로 성공을 판정하면 안 됩니다.
본문의 한글 오류 문구까지 확인하세요.

---

## 문서·스키마를 바꿨을 때 해야 하는 일

```bash
# 1) Oracle 정본(database/newdb)을 먼저 고친다
# 2) 다른 DBMS 판 재생성
python tools/multidb/gen_maria_db.py
python tools/multidb/gen_pg_db.py
# 3) 문서 재생성 (손으로 고치지 말 것)
python tools/dbdoc/gen_dbdocs.py
# 4) 매퍼 3벌 확인
```

`<제품>/docs/테이블_명세서.md` 와 `ERD.md` 는 **자동 생성물**입니다.
직접 편집하면 다음 생성에서 사라집니다.

---

## 하지 말아야 할 것

- **`mvn clean`** — WTP 배포본이 날아가 재배포가 필요해집니다
- **자동 생성 문서 직접 편집** — `tools/dbdoc/gen_dbdocs.py` 로 다시 뽑으세요
- **매퍼 1벌만 수정** — 다른 DBMS 에서 조용히 깨집니다
- **규정 편집기 본문의 raw 렌더링을 XSS 로 오인해 이스케이프 추가** — 의도된 설계입니다
- **테스트/표본 데이터 임의 삭제** — 시연·검증용으로 남겨 둔 것입니다
- **`database/` 의 시드 파일 손편집** — 운영 DB 를 정본으로 삼는다면
  `tools/multidb/genseed.py` 로 다시 뽑으세요
