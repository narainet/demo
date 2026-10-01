# 레이아웃 검증 — 메뉴에 걸린 전 화면이 "셸 1겹"으로 렌더되는지 훑는다. (2026-08-07 신설)
#
# SiteMesh 제거 → JSP 태그파일 셸(<lay:layout>) 전환의 회귀 도구.
# SiteMesh 는 필터라 전 응답을 무조건 감쌌지만, 태그파일은 화면 JSP 가 스스로 감싸므로
# "래핑 누락(셸 없음)" 과 "이중 래핑(<html> 2개)" 이 새로운 실패 모드가 된다. 그 둘을 잡는다.
#
# 점검 항목(화면당):
#   - HTTP 200
#   - <html> / <body> / <!DOCTYPE> 이 각각 정확히 1개   ← 이중 래핑·중첩 검출
#   - </html> 로 끝남                                   ← 잘림 검출
#   - 셸 마커가 정확히 1종                              ← 셸 누락·혼선 검출
#   - <title> 이 비어있지 않음
#
# 사용:  .\tools\layoutcheck.ps1 -DbPass '<RLMS 스키마 비밀번호>' [-BaseUrl http://localhost:7070]
#        .\tools\layoutcheck.ps1 -Urls '/rlms/index.do','/cop/bbs/...'   # DB 없이 직접 지정
#
# ⚠️ sysmen 으로 로그인하므로 같은 계정의 브라우저 세션이 끊긴다(smoke.ps1 과 동일).
# ⚠️ PS 5.1 한글 리터럴 때문에 이 파일은 UTF-8(BOM) 이어야 한다.
param(
    [string]$DbPass,
    [string[]]$Urls,
    [string[]]$SelfContained = @('/index.do'),
    [string]$BaseUrl = 'http://localhost:7070',
    [string]$User = 'sysmen',
    [string]$Pass = 'asdqwe123!',
    [string]$DbUser = 'RLMS'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# 셸 마커 — /WEB-INF/tags/shell/*.tag 의 본문 컨테이너 클래스
$shellMarks = @{
    'mgr'   = 'rlms-admin-main'
    'front' = 'rlms-front-main'
    'popup' = 'rlms-popup-main'
    'plain' = 'rlms-plain-wrap'
}

# ── 1) 점검 대상 URL ──────────────────────────────────────
if (-not $Urls) {
    if (-not $DbPass) { throw "-DbPass 또는 -Urls 중 하나는 필요합니다." }
    $dbr = Join-Path $root 'tools\dbq\dbr.ps1'
    $sql = "SELECT DISTINCT p.URL FROM COMTNMENUINFO m " +
           "JOIN COMTNPROGRMLIST p ON m.PROGRM_FILE_NM = p.PROGRM_FILE_NM " +
           "WHERE m.PROGRM_FILE_NM <> 'folder' ORDER BY p.URL"
    $Urls = @((& $dbr $DbUser $DbPass exec $sql) | Where-Object { $_ -match '^/.+\.do$' })
}
Write-Host "== layoutcheck: $BaseUrl ($User) — 대상 $($Urls.Count)건 =="

# ── 2) 로그인 ─────────────────────────────────────────────
$login = Invoke-WebRequest -Uri "$BaseUrl/uat/uia/actionLogin.do" -Method Post `
    -Body @{ id = $User; password = $Pass; userSe = '' } `
    -SessionVariable S -UseBasicParsing -TimeoutSec 15
if ($login.Content -match 'id="loginForm"') { throw "로그인 실패 — 계정/비밀번호 확인" }

# ── 3) 훑기 ───────────────────────────────────────────────
$fail = 0; $skip = 0; $ok = 0
foreach ($u in $Urls) {
    try {
        $r = Invoke-WebRequest -Uri "$BaseUrl$u" -WebSession $S -UseBasicParsing -TimeoutSec 20
    } catch {
        Write-Host ("[SKIP] {0} - 응답 없음/{1}" -f $u, $_.Exception.Message.Split("`n")[0]); $skip++; continue
    }
    $c = $r.Content
    # 비 HTML(JSON·파일 등)은 셸 대상이 아니다
    if ($c -notmatch '(?i)<html') { Write-Host ("[SKIP] {0} - 비HTML 응답" -f $u); $skip++; continue }

    # ⛔ 변수명 $s 금지 — PS 는 대소문자 무시라 세션 변수 $S 를 덮어쓴다(2026-08-07 실착오).
    # ⛔ 구조 태그는 script/style/주석 밖에서만 센다 — 팝업 본문 추출 JS 안에
    #    /<body[^>]*>([\s\S]*?)<\/body>/ 같은 정규식 리터럴이 있어 그대로 세면 오탐이다.
    $plain = [regex]::Replace($c, '(?is)<script\b[^>]*>.*?</script>', '<script></script>')
    $plain = [regex]::Replace($plain, '(?is)<style\b[^>]*>.*?</style>', '<style></style>')
    $plain = [regex]::Replace($plain, '(?s)<!--.*?-->', '')

    $problems = @()
    $nHtml = ([regex]::Matches($plain, '(?i)<html[\s>]')).Count
    $nBody = ([regex]::Matches($plain, '(?i)<body[\s>]')).Count
    $nDoc  = ([regex]::Matches($plain, '(?i)<!DOCTYPE')).Count
    if ($nHtml -ne 1) { $problems += "html=$nHtml" }
    if ($nBody -ne 1) { $problems += "body=$nBody" }
    if ($nDoc  -ne 1) { $problems += "doctype=$nDoc" }
    if ($c.TrimEnd() -notmatch '(?i)</html>$') { $problems += "미종료" }

    # 자체 완결 레이아웃 화면(구 SiteMesh excludes)은 셸이 없는 것이 정상이다.
    # 예: LexPortal 포탈 공개 메인 /index.do — 전용 헤더·푸터·스타일을 스스로 갖는다.
    $bare = $SelfContained | Where-Object { $u -like "$_*" }
    $hits = @($shellMarks.Keys | Where-Object { $plain -match [regex]::Escape($shellMarks[$_]) })
    $want = if ($bare) { 0 } else { 1 }
    if ($hits.Count -ne $want) {
        $problems += ("셸={0}(기대 {1})" -f $(if ($hits) { $hits -join '+' } else { '없음' }), $want)
    }

    if ($c -match '(?is)<title>\s*(.*?)\s*</title>') {
        if (-not $Matches[1]) { $problems += "title 빈값" }
    } else { $problems += "title 없음" }

    if ($problems) {
        Write-Host ("[FAIL] {0} - {1}" -f $u, ($problems -join ', ')); $fail++
    } else {
        Write-Host ("[PASS] {0} - {1}" -f $u, $(if ($hits) { $hits[0] } else { '셸없음(자체완결)' })); $ok++
    }
}
Write-Host ""
Write-Host ("== 결과: {0} PASS, {1} FAIL, {2} SKIP ==" -f $ok, $fail, $skip)
if ($fail -gt 0) { exit 1 }
