# LexPortal(7071) 전화면 스모크 — DB 모드 무관(HTTP 스윕). 로그인 스윕 + law 축 심층
$ErrorActionPreference = 'Continue'
$base = "http://localhost:7071"
$sp = Split-Path $MyInvocation.MyCommand.Path
$jarCookie = Join-Path $sp "smoke_cookies_lex.txt"
Remove-Item $jarCookie -ErrorAction SilentlyContinue

# 1) 로그인 (sysmen/USR)
curl.exe -s -c $jarCookie -o NUL "$base/uat/uia/egovLoginUsr.do"
$login = curl.exe -s -b $jarCookie -c $jarCookie -o NUL -w "%{http_code} %{redirect_url}" --data-urlencode "id=sysmen" --data-urlencode "password=asdqwe123!" --data-urlencode "userSe=USR" "$base/uat/uia/actionLogin.do"
Write-Output "LOGIN: $login"

# 2) URL 스윕 (PROGRMLIST 전수 + law 심층)
$urls = Get-Content (Join-Path $sp "smoke_urls_lexportal.txt") | Where-Object { $_.Trim() -ne '' }
$extra = @(
    "/main.do",
    # 2026-08-06: 옛 URL 3건이 404 였다 — /law/home/main.do 는 8/4 에 /law/index.do 로 개명됐고,
    #             selectSuitList 는 URL 이 아니라 매퍼 메서드명이었다(실 URL = /law/suit/list.do).
    "/law/index.do",
    "/law/suit/list.do",
    "/law/suit/list.do?searchKeyword=%ED%85%8C%EC%8A%A4%ED%8A%B8",
    "/rlms/mgr/dashboard.do"
)
$koErr1 = "$([char]0xB370)$([char]0xC774)$([char]0xD130)$([char]0xCC98)$([char]0xB9AC) $([char]0xC5D0)$([char]0xB7EC)"   # 데이터처리 에러
$koErr2 = "$([char]0xC2DC)$([char]0xC2A4)$([char]0xD15C) $([char]0xC5D0)$([char]0xB7EC)"                                 # 시스템 에러
$fails = @(); $n = 0
foreach ($u in ($urls + $extra)) {
    $u = $u.Trim(); if ($u -eq '') { continue }
    $tmp = Join-Path $sp "smoke_body_lex.tmp"
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
