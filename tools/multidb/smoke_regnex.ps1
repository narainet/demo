# RegNex(7072) 전화면 스모크 — DB 모드 무관(HTTP 스윕). 로그인 스윕 + front 열람 축 심층
$ErrorActionPreference = 'Continue'
$base = "http://localhost:7072"
$sp = Split-Path $MyInvocation.MyCommand.Path
$jarCookie = Join-Path $sp "smoke_cookies_regnex.txt"
Remove-Item $jarCookie -ErrorAction SilentlyContinue

# 1) 로그인 (sysmen/USR)
curl.exe -s -c $jarCookie -o NUL "$base/uat/uia/egovLoginUsr.do"
$login = curl.exe -s -b $jarCookie -c $jarCookie -o NUL -w "%{http_code} %{redirect_url}" --data-urlencode "id=sysmen" --data-urlencode "password=asdqwe123!" --data-urlencode "userSe=USR" "$base/uat/uia/actionLogin.do"
Write-Output "LOGIN: $login"

# 2) URL 스윕
$urls = Get-Content (Join-Path $sp "smoke_urls_regnex.txt") | Where-Object { $_.Trim() -ne '' }
# front 열람 축 심층(변환 핵심 경로) 추가
$extra = @(
    "/rlms/index.do",
    "/rlms/fulltext/searchAll.do?searchKeyword=%EA%B7%9C%EC%A0%95",
    "/rlms/fulltext/provisionList.do",
    "/rlms/fulltext/historyList.do",
    "/rlms/fulltext/comparisonList.do",
    "/rlms/fulltext/nullifyList.do",
    "/rlms/fulltext/latestList.do",
    "/rlms/fulltext/quickSearchJson.do?q=%EC%A0%9C",
    "/rlms/prommap/view.do",
    "/rlms/prommap/treeJson.do",
    "/rlms/cate/selectCateTreeJson.do",
    "/rlms/prom/buseoListJson.do",
    "/uss/ion/pwm/listMainPopup.do"
)
$koErr1 = "$([char]0xB370)$([char]0xC774)$([char]0xD130)$([char]0xCC98)$([char]0xB9AC) $([char]0xC5D0)$([char]0xB7EC)"   # 데이터처리 에러
$koErr2 = "$([char]0xC2DC)$([char]0xC2A4)$([char]0xD15C) $([char]0xC5D0)$([char]0xB7EC)"                                 # 시스템 에러
$fails = @(); $n = 0
foreach ($u in ($urls + $extra)) {
    $u = $u.Trim(); if ($u -eq '') { continue }
    $tmp = Join-Path $sp "smoke_body_regnex.tmp"
    $code = curl.exe -s -b $jarCookie -c $jarCookie -L -o $tmp -w "%{http_code}" "$base$u"
    $n++
    $body = ""
    if (Test-Path $tmp) { $body = [IO.File]::ReadAllText($tmp, [Text.Encoding]::UTF8) }
    $bad = $null
    if ($code -ne "200") { $bad = "HTTP $code" }
    elseif ($body -match 'egovError|SQLSyntaxErrorException|MyBatisSystemException|BadSqlGrammarException|SQLIntegrityConstraint|CannotGetJdbcConnection') { $bad = "error-marker" }
    elseif ($body -match $koErr1 -or $body -match $koErr2 -or $body -match '404 Error') { $bad = "error-page-ko" }
    elseif ($u -notmatch 'Login|login' -and $body -match 'id="loginForm"' -and $u -notmatch 'egovLoginUsr') { $bad = "login-redirect" }
    if ($bad) { $fails += "{0,-70} {1}" -f $u, $bad }
}
Write-Output ("sweep: {0} urls, fail {1}" -f $n, $fails.Count)
$fails | ForEach-Object { Write-Output $_ }
