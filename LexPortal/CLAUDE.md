# CLAUDE.md — LexPortal (송무 전용)

> 공통 지침은 상위 폴더의 `../CLAUDE.md` 를 먼저 보세요. 여기에는 이 제품 고유 사항만 적습니다.

## 이 제품의 범위

**송무 전용**입니다. 규정관리(`/rlms/prom` 등, `TB_PROM`·`TB_CATE` 계열)가
**들어 있지 않습니다.** 테이블 59종 (공통 41 + 송무 `LAW_*` 18).

| 도메인 | URL | 패키지 | 매퍼 |
|---|---|---|---|
| 송무 | `/law/**` | `narainet.law.*` | `mapper/law/**` |
| 공통 | 그 외 | `egovframework.com.*` | `mapper/com/**` |

`narainet.rlms.*` 아래에는 공통으로 재사용하는 최소 코드(메뉴·통계·공통 web)만
남아 있습니다.

> RLMS(통합본)와 송무 코드는 **거의 동일**합니다. `narainet.law.*` 나 공통 기반을
> 고칠 때는 **RLMS 에도 같이 반영**하세요.

## 모듈 지도

| 패키지 | URL | 하는 일 |
|---|---|---|
| `home` | `/law/home` | 송무 대시보드 — 진행 사건, 임박 기일 |
| `suit` | `/law/suit` | 사건(심급 1건=1행), 당사자·수행자·토지·진행상황 |
| `req` / `requser` | `/law/req`, `/law/reqUser` | 소송의뢰 — 관리자 심사 / 사용자 신청 |
| `doc` | `/law/doc` | 소송문서 + 승인 워크플로 |
| `cost` | `/law/cost` | 소송비용 |
| `calcset` | `/law/calcset` | 소송비용 계산 요율표 (시점별 세트) |
| `lawyer` | `/law/lawyer` | 변호사 명부 |
| `assign` | `/law/assign` | 선임(사건×변호사) + 법무법인 만족도 |
| `schedule` | `/law/schedule` | 기일 달력 (`LAW_SUIT_PROG` 를 진행상황과 공유) |
| `seize` | `/law/seize` | 압류관리(가압류·가처분) |
| `receipt` | `/law/receipt` | 법원서류접수 |
| `stat` | `/law/stat` | 송무 통계 4축 |

## 이 제품 고유 주의사항

### 1. 첨부는 전자정부 표준을 씁니다

송무 첨부는 `COMTNFILE` / `COMTNFILEDETAIL`(`ATCH_FILE_ID`)입니다.
규정 모듈의 `TB_ATTACH` 는 이 제품에 **없습니다**.

업로드 물리 경로는 기능별 하위 폴더로 나뉩니다:
`Globals.fileStorePath.Law` → `req` / `doc` / `assign` / `seize` / `receipt`

### 2. 송무 DDL 은 시드 **뒤에** 실행합니다

`15_law_install.sql` 안에 `NOT EXISTS` 가드가 걸린 시드(공통코드 `LAW_*` 그룹·채번·
법원·요율)가 들어 있습니다. 그래서 실행 순서가 `… → 20~26 → 15 → 30` 입니다.
**먼저 돌리면 20/26 시드에서 중복 키 위반이 납니다.** (RLMS 는 반대입니다)

### 3. 주민등록번호 암호화 키

`Globals.law.cryptoKey` / `…KeyHash`(= `Base64(SHA-256(키))`).
**고객사 전용 값으로 교체**해야 하며, 운영 데이터가 쌓인 뒤에 바꾸면
기존 암호문을 복호할 수 없습니다.

### 4. 지도 표시는 선택 사항

`Globals.law.kakaoMapAppKey` 가 비어 있으면 지번 목록으로 자동 대체됩니다.
키가 없어도 기능은 정상 동작합니다.

### 5. DB 접속정보 암호화 화면 메뉴는 별도 스크립트입니다

시드(`21_seed_menu.sql`)에 포함되어 있지 않으므로, 설치 후
`database/db_crypto_menu.sql` 을 실행해야 관리자 화면에 나옵니다.

### 6. 첫 화면 경로가 다릅니다

`Globals.MainPage = /index.do` 입니다 (RLMS·RegNex 는 `/rlms/index.do`).

## 문서

- 테이블 전체: `docs/테이블_명세서.md` (59종, 자동 생성)
- 관계도: `docs/ERD.md` (3개 영역 — 사용자·권한·메뉴 / 게시판·첨부 / 송무, 자동 생성)
- 재생성: `python ../tools/dbdoc/gen_dbdocs.py`

## 기본 포트

`http://localhost:7071` (참고 설정: `../tools/multidb/tomcat/server-lexportal-7071.xml`)
