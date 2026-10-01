# CLAUDE.md — RegNex (규정관리 전용)

> 공통 지침은 상위 폴더의 `../CLAUDE.md` 를 먼저 보세요. 여기에는 이 제품 고유 사항만 적습니다.

## 이 제품의 범위

**규정관리 전용**입니다. 송무(`/law/**`, `narainet.law.*`, `LAW_*` 테이블)가
**들어 있지 않습니다.** 테이블 77종.

| 도메인 | URL | 패키지 | 매퍼 |
|---|---|---|---|
| 규정관리 | `/rlms/**` | `narainet.rlms.*` | `mapper/rlms/**` |
| 공통 | 그 외 | `egovframework.com.*` | `mapper/com/**` |

> RLMS(통합본)와 규정관리 코드는 **거의 동일**합니다. `narainet.rlms.*` 나
> 공통 기반을 고칠 때는 **RLMS 에도 같이 반영**하세요.

## 모듈 지도

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
| `lawquest` | `/rlms/lawquest` | 법령질의 (**송무와 무관한 별개 모듈**) |
| `favor` / `memo` | `/rlms/favor`, `/rlms/memo` | 즐겨찾기 / 메모 |
| `search` | `/rlms/prom/searchAll` | 통합검색 4축 |
| `stats` / `stsfdg` | `/rlms/stats` | 통계 / 만족도 |
| `docu` | — | 별표·별지서식 |
| `attach` | — | 도메인 첨부 (`TB_ATTACH`) |

> ⚠️ `TB_LAWQUEST`(법령질의)는 이름이 비슷하지만 **송무가 아닙니다.**
> 송무 테이블을 찾을 때 `LAW\_%` 로 정확히 매칭하세요 — `LAWQUEST` 가 딸려 옵니다.

## 이 제품 고유 주의사항

### 1. 송무 관련 코드를 추가하지 마세요

이 제품은 규정관리만 도입하는 고객용입니다. 송무 기능이 필요하면
RLMS(통합본)를 쓰는 것이 맞습니다.

### 2. DB 접속정보 암호화 화면 메뉴는 별도 스크립트입니다

시드(`21_seed_menu.sql`)에 포함되어 있지 않으므로, 설치 후
`database/db_crypto_menu.sql` 을 실행해야 관리자 화면에 나옵니다.

### 3. 첨부 정책

| 도메인 | 첨부 저장소 |
|---|---|
| 규정 | `TB_ATTACH` |
| 게시판 · 표준 모듈 | `COMTNFILE` / `COMTNFILEDETAIL` |

### 4. 시드 구성이 통합본과 다릅니다

송무 메뉴 축(ADMIN `55*`, USER `15*`)·`LAW_*` 프로그램·`ROLE_LAW_MGR` 가 빠져 있습니다.
예시 계정도 3종(`sysmen` / `approver` / `user`)입니다 — `lawmgr` 없음.

## 문서

- 테이블 전체: `docs/테이블_명세서.md` (77종, 자동 생성)
- 관계도: `docs/ERD.md` (5개 영역, 자동 생성)
- 재생성: `python ../tools/dbdoc/gen_dbdocs.py`

## 기본 포트

`http://localhost:7072` (참고 설정: `../tools/multidb/tomcat/server-regnex-7072.xml`)
