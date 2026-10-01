# CLAUDE.md — RLMS (통합본)

> 공통 지침은 상위 폴더의 `../CLAUDE.md` 를 먼저 보세요. 여기에는 이 제품 고유 사항만 적습니다.

## 이 제품의 범위

**규정관리 + 송무를 모두 포함한 통합본**입니다. 테이블 95종
(공통·규정 77 + 송무 `LAW_*` 18).

| 도메인 | URL | 패키지 | 매퍼 |
|---|---|---|---|
| 규정관리 | `/rlms/**` | `narainet.rlms.*` | `mapper/rlms/**` |
| 송무 | `/law/**` | `narainet.law.*` | `mapper/law/**` |
| 공통 | 그 외 | `egovframework.com.*` | `mapper/com/**` |

**두 도메인은 완전히 독립**입니다. 서로의 테이블·패키지를 직접 참조하지 마세요
(공통 기반을 통해서만 만납니다).

## 모듈 지도

### 규정관리 (`narainet.rlms.*`)

| 패키지 | URL | 하는 일 |
|---|---|---|
| `cate` | `/rlms/cate` | 구분·분류 트리, 열람제한 |
| `prom` | `/rlms/prom`, `/rlms/fulltext` | 규정 회차, 조문 편집 IDE, 전문 뷰어, 내보내기 |
| `gaejung` | `/rlms/gaejung` | 개정구분 |
| `promwork` | `/rlms/promwork` | 승인 워크플로 |
| `related` | `/rlms/related` | 관련자료 8액션 (허브 `TB_REL_VRSN`) |
| `relexcl` | — | 자동링크 제외 범위 |
| `readduty` | `/rlms/readduty` | 필수 열람(의무 숙지) |
| `prommap` | `/rlms/prommap` | 규정맵(기능별 분류) |
| `lawquest` | `/rlms/lawquest` | 법령질의 |
| `favor` / `memo` | `/rlms/favor`, `/rlms/memo` | 즐겨찾기 / 메모 |
| `search` | `/rlms/prom/searchAll` | 통합검색 4축 |
| `stats` / `stsfdg` | `/rlms/stats` | 통계 / 만족도 |
| `docu` | — | 별표·별지서식 |
| `attach` | — | 도메인 첨부 (`TB_ATTACH`) |

### 송무 (`narainet.law.*`)

| 패키지 | URL | 하는 일 |
|---|---|---|
| `home` | `/law/home` | 송무 대시보드 |
| `suit` | `/law/suit` | 사건(심급 1건=1행), 당사자·수행자·토지·진행 |
| `req` / `requser` | `/law/req`, `/law/reqUser` | 소송의뢰 (관리자 / 사용자) |
| `doc` | `/law/doc` | 소송문서 + 승인 |
| `cost` / `calcset` | `/law/cost`, `/law/calcset` | 소송비용 / 요율표 |
| `lawyer` / `assign` | `/law/lawyer`, `/law/assign` | 변호사 명부 / 선임·만족도 |
| `schedule` | `/law/schedule` | 기일 달력 (`LAW_SUIT_PROG` 공유) |
| `seize` | `/law/seize` | 압류관리 |
| `receipt` | `/law/receipt` | 법원서류접수 |
| `stat` | `/law/stat` | 송무 통계 |

## 이 제품 고유 주의사항

### 1. 첨부 정책이 도메인마다 다릅니다

| 도메인 | 첨부 저장소 |
|---|---|
| 규정 | `TB_ATTACH` |
| 송무 · 게시판 · 표준 모듈 | `COMTNFILE` / `COMTNFILEDETAIL` (`ATCH_FILE_ID`) |

의도된 차이입니다. 통일하지 마세요.

### 2. 송무 DDL 은 시드보다 먼저 실행합니다

`15_law_install.sql` 은 **DDL 전용**이고, 송무 기준데이터(법원·요율)는
`25_seed_domain.sql` 이 넣습니다. 그래서 실행 순서가
`… → 15 → 20~26 → 30` 입니다. (LexPortal 은 반대입니다)

### 3. 주민등록번호 암호화 키

`Globals.law.cryptoKey` / `…KeyHash`(= `Base64(SHA-256(키))`).
**고객사 전용 값으로 교체**해야 하며, 운영 데이터가 쌓인 뒤에 바꾸면
기존 암호문을 복호할 수 없습니다.

### 4. 송무를 쓰지 않는 배포

메뉴만 내립니다(데이터·테이블 보존): `database/rlms_law_menu_remove.sql`

### 5. MariaDB / PostgreSQL 시드는 자동 변환 생성물입니다

DDL 은 라이브 검증을 마쳤지만, **RLMS 통합본의 시드(20~26)는 Oracle 정본에서
자동 변환한 뒤 라이브 적재 검증을 아직 하지 않았습니다.**
최초 설치 시 각 파일의 오류 유무를 확인하고, `30_fks.sql` 이 통과하면
참조 정합은 확인된 것입니다. (`database/maria/README.md` §5)

## 문서

- 테이블 전체: `docs/테이블_명세서.md` (95종, 자동 생성)
- 관계도: `docs/ERD.md` (6개 영역, 자동 생성)
- 재생성: `python ../tools/dbdoc/gen_dbdocs.py`

## 기본 포트

`http://localhost:7070`
