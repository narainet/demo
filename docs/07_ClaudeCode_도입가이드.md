# 07. Claude Code 도입 가이드

이 프로젝트를 **Claude Code** 로 이어서 개발·운영하기 위한 안내입니다.
이 패키지에는 Claude Code 가 바로 쓸 수 있도록 개발 지침이 이미 들어 있습니다.

---

## 1. Claude Code 가 무엇을 읽는가

Claude Code 는 작업 폴더와 그 **상위 폴더들의 `CLAUDE.md`** 를 자동으로 읽습니다.
이 패키지는 2단으로 구성했습니다.

```
RESULT/
├─ CLAUDE.md          ← 3제품 공통 규약 (항상 읽힙니다)
├─ RLMS/CLAUDE.md     ← RLMS 안에서 작업할 때 추가로 읽힙니다
├─ RegNex/CLAUDE.md
└─ LexPortal/CLAUDE.md
```

따라서 **어느 폴더에서 시작하든** 공통 규약이 적용되고, 제품 폴더에서 시작하면
그 제품 고유 사항이 더해집니다.

### 권장 작업 위치

| 상황 | `cd` 할 위치 |
|---|---|
| 한 제품만 개발 | `RESULT/RLMS` (또는 해당 제품) |
| 공통 기반을 3제품에 동시 반영 | `RESULT` |
| 문서·DB 스크립트 작업 | `RESULT` |

---

## 2. 설치와 시작

1. [claude.com/claude-code](https://claude.com/claude-code) 에서 Claude Code 를 설치합니다.
2. 터미널에서 프로젝트 폴더로 이동한 뒤 실행합니다.

```bash
cd C:\eGovFrameDev-4.3.1-64bit\workspace\RLMS
claude
```

> 이 패키지를 Eclipse 워크스페이스로 복사해서 쓴다면, `CLAUDE.md` 와 `docs/`,
> `tools/` 도 **함께 복사**해야 Claude Code 가 지침을 읽습니다.
> 제품 폴더만 옮기면 상위 `CLAUDE.md` 가 사라집니다.

### 처음 한 번 — 프로젝트를 파악시키기

```
docs/01_시스템_개요.md 와 docs/04_개발규약_아키텍처.md 를 읽고,
이 프로젝트의 구조와 지켜야 할 규약을 정리해줘.
```

---

## 3. 형상관리를 먼저 붙이세요

이 패키지는 형상관리 이력 없이 전달됩니다. **작업을 시작하기 전에** Git 이나 SVN
저장소를 만들어 초기 상태를 커밋해 두세요. 그래야 Claude Code 가 무엇을 바꿨는지
`git diff` 로 확인하고 되돌릴 수 있습니다.

```bash
cd C:\eGovFrameDev-4.3.1-64bit\workspace\RLMS
git init
git add .
git commit -m "인수 초기 상태"
```

각 제품 폴더에 `.gitignore` 가 이미 들어 있습니다
(`target/`, `.settings/`, `*.class`, 로그 등 제외).

> ⚠️ **`globals.properties` 에는 DB 접속 암호문이 들어갑니다.** 공개 저장소에
> 올리지 마세요. 사내 저장소를 쓰거나, 이 파일을 `.gitignore` 에 추가하고
> 배포 시 별도 관리하는 방식을 권합니다.

---

## 4. 잘 되는 요청 / 잘 안 되는 요청

### 잘 됩니다

```
규정 목록 화면에 '담당부서' 컬럼을 추가해줘.
매퍼는 oracle/maria/postgres 3벌 다 고치고, 화면 제목은 건드리지 마.
```
```
TB_PROM 에 컬럼 하나 추가하려고 해. DDL·매퍼·VO·화면까지 필요한 변경 목록을 먼저 뽑아줘.
```
```
tools/smoke.ps1 을 돌리고 실패한 항목의 원인을 찾아줘.
```
```
소송의뢰 승인 로직이 어디에 있는지 찾아서 흐름을 설명해줘.
```

### 요령

| 요령 | 이유 |
|---|---|
| **변경 범위를 명시** ("매퍼 3벌 다", "화면은 그대로") | 이 프로젝트는 한 변경이 여러 파일에 걸칩니다 |
| **큰 작업은 계획부터** ("먼저 변경 목록을 뽑아줘") | 리뷰 후 실행하면 되돌릴 일이 줄어듭니다 |
| **검증까지 시킨다** ("고치고 스모크 돌려줘") | 오류 화면이 HTTP 200 으로 위장하므로 자동 검증이 중요합니다 |
| **문서를 가리킨다** ("docs/05 의 관련자료 구조대로") | 근거가 문서에 있으면 결과가 정확해집니다 |

### 주의할 요청

| 요청 | 왜 위험한가 |
|---|---|
| "전체를 리팩터링해줘" | 변경 범위가 커서 검증이 불가능해집니다. 모듈 단위로 나누세요 |
| "테스트 데이터 정리해줘" | 시연·검증용으로 일부러 남긴 데이터가 있습니다 |
| "DB 를 최신 문법으로 바꿔줘" | JDK 1.8 · Oracle 11g 호환을 유지해야 합니다 |
| "자동 생성 문서를 예쁘게 고쳐줘" | `docs/테이블_명세서.md`·`ERD.md` 는 재생성 시 사라집니다 |

---

## 5. Claude Code 가 이미 알고 있는 것

`CLAUDE.md` 에 적어 두었으므로 매번 설명할 필요가 없습니다.

- JDK 1.8 문법만 쓸 것
- 매퍼는 oracle/maria/postgres **3벌**을 함께 고칠 것
- 새 URL 은 `COMTNPROGRMLIST` → `COMTNMENUINFO` → `COMTNMENUCREATDTLS` 등록이 필요
- 채번은 `COMTECOPSEQ` + `EgovIdGnrService` (시퀀스 금지)
- `SSYS_ID` 를 조회 조건으로 쓰지 않을 것
- 논리 삭제(`SDEL_YN='N'`)를 물리 삭제로 바꾸지 않을 것
- `mvn clean` 을 쓰지 않을 것
- MyBatis `<if test>` 의 문자열은 큰따옴표
- 자동 생성 문서를 직접 편집하지 않을 것

새로운 규약이 생기면 `CLAUDE.md` 에 **직접 추가**하세요. 그 뒤로는 계속 지켜집니다.

---

## 6. 권한 설정 — 무엇을 자동 허용할까

Claude Code 는 파일 수정·명령 실행 전에 확인을 받습니다. 자주 쓰는 읽기 전용 명령은
프로젝트 설정에 허용해 두면 편합니다.

`.claude/settings.json` (프로젝트 루트에 만들면 팀이 공유합니다):

```json
{
  "permissions": {
    "allow": [
      "Bash(mvn -o compile*)",
      "Bash(git status*)",
      "Bash(git diff*)",
      "Bash(git log*)"
    ]
  }
}
```

**허용하지 말아야 할 것** — 운영 DB 에 쓰는 명령, 배포 명령, `mvn clean`.
이런 것은 매번 사람이 확인하는 편이 안전합니다.

---

## 7. 안전 수칙

| 수칙 | 이유 |
|---|---|
| **운영 DB 접속정보를 대화에 붙여넣지 마세요** | 필요하면 환경변수(`RLMS_DB_*`)로 넘기세요 |
| **개발/테스트 DB에서 먼저 확인** | 이 스키마는 FK 가 26건뿐이라 잘못된 DELETE 가 조용히 고아 데이터를 만듭니다 |
| **스키마 변경은 3DBMS + 문서까지 한 세트** | 하나만 고치면 다른 DBMS 에서 나중에 터집니다 |
| **변경 후 스모크 필수** | 오류 화면이 HTTP 200 으로 위장합니다 |
| **커밋 전 `git diff` 확인** | 의도하지 않은 파일이 섞이지 않았는지 |

---

## 8. 자주 쓰는 명령 모음

작업 폴더에서:

```bash
mvn -o compile                                                    # 빌드 (clean 금지)
powershell -ExecutionPolicy Bypass -File tools\smoke.ps1          # 스모크
powershell -ExecutionPolicy Bypass -File tools\authcheck.ps1 -DbPass '<pw>'   # 인가 검증
python tools/dbdoc/gen_dbdocs.py                                  # 문서 재생성
python tools/multidb/gen_maria_db.py                              # MariaDB 세트 재생성
python tools/multidb/gen_pg_db.py                                 # PostgreSQL 세트 재생성
```

---

## 9. 막혔을 때 물어볼 것들

```
이 오류의 원인을 찾아줘: <오류 메시지 붙여넣기>
관련 코드와 최근 변경 이력도 같이 봐줘.
```
```
/rlms/foo/bar.do 가 403 이 나. docs/04 §6 의 URL 인가 규칙에 따라 원인을 찾고
필요한 DB 등록 SQL 을 만들어줘.
```
```
TB_PROM 을 참조하는 모든 코드를 찾아서, 컬럼 하나를 지웠을 때 깨지는 곳을 알려줘.
```
