# RLMS 권한 검증 — 인가 규칙 정본이 말하는 '기대'와 라이브 응답의 '실제'를 대조. (2026-07-29 신설)
#
# 두 가지를 본다.
#   1) 인가 매트릭스 : 계정 × 전 메뉴. 기대(requestMap 규칙) vs 실제(HTTP). 어긋나면 누수 또는 오차단.
#   2) 메뉴 노출     : 화면에 링크로 그려진 메뉴인데 누르면 막히는 항목(시연 최악의 경우).
#
# 기대값의 출처는 DB 권한표가 아니라 **context-security.xml 의 sqlRolesAndUrl** 이다.
# 실제 인가는 이 SQL 이 만드는 requestMap 이 결정하고, 경로 단위 L6 파생 때문에
# 메뉴 권한표만 보면 틀린 기대값이 나오기 때문이다.
#
# 사용:  .\tools\authcheck.ps1 -DbPass '<RLMS 스키마 비밀번호>'
#
# ⚠️ 계정 4종으로 로그인하므로 같은 계정의 브라우저 세션이 끊긴다(smoke.ps1 과 동일).
# ⚠️ PS 5.1 한글 리터럴 때문에 이 파일은 UTF-8(BOM) 이어야 한다.
param(
    [Parameter(Mandatory = $true)][string]$DbPass,
    [string]$BaseUrl = 'http://localhost:7070',
    [string]$DbUser = 'RLMS'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dbr = Join-Path $root 'tools\dbq\dbr.ps1'
$tmp = [IO.Path]::GetTempPath()

# ── 1) 메뉴 정본 ──────────────────────────────────────────
$sqlMenu = "SELECT m.MENU_NO || '|' || m.MENU_NM || '|' || p.URL FROM COMTNMENUINFO m " +
           "JOIN COMTNPROGRMLIST p ON m.PROGRM_FILE_NM = p.PROGRM_FILE_NM " +
           "WHERE m.PROGRM_FILE_NM <> 'folder' ORDER BY m.MENU_NO"
$menuRows = @((& $dbr $DbUser $DbPass exec $sqlMenu) | Where-Object { $_ -match '^\d{8}\|' })
if ($menuRows.Count -eq 0) { Write-Host '메뉴를 읽지 못했습니다 — DB 접속/비밀번호 확인'; exit 1 }

# ── 2) 인가 규칙 정본 (context-security.xml → 실행 → 순서 그대로) ──
$secXml = Join-Path $root 'src\main\resources\egovframework\spring\com\context-security.xml'
$x = [xml](Get-Content $secXml -Raw -Encoding UTF8)
$node = $x.SelectSingleNode("//*[local-name()='secured-object-config']")
$sqlRules = $node.GetAttribute('sqlRolesAndUrl')
$rulesFile = Join-Path $tmp 'rlms_authcheck_rules.sql'
Set-Content -Path $rulesFile -Value $sqlRules -Encoding UTF8
$ruleRows = @((& $dbr $DbUser $DbPass $rulesFile) | Where-Object { $_ -match '^\\A.* \| ' })
Remove-Item $rulesFile -Force -ErrorAction SilentlyContinue
if ($ruleRows.Count -eq 0) { Write-Host '인가 규칙을 읽지 못했습니다'; exit 1 }

# 같은 패턴의 여러 행은 하나의 권한 집합으로 누적(스프링 requestMap 과 동일)
$patterns = New-Object System.Collections.ArrayList
$auths = @{}
foreach ($line in $ruleRows) {
    $p = $line -split '\s\|\s', 2
    if ($p.Count -ne 2) { continue }
    $pat = $p[0].Trim(); $auth = $p[1].Trim()
    if (-not $auths.ContainsKey($pat)) { [void]$patterns.Add($pat); $auths[$pat] = New-Object System.Collections.Generic.HashSet[string] }
    [void]$auths[$pat].Add($auth)
}
Write-Host ("== 권한 검증: 메뉴 {0}건 · 인가 규칙 {1}패턴 ({2}) ==" -f $menuRows.Count, $patterns.Count, $BaseUrl)

# ── 3) 계정 (역할 계층 COMTNROLES_HIERARCHY 까지 펼친 보유 권한) ──
$accounts = @(
    @{ id = 'sysmen';   pw = 'asdqwe123!'; label = '관리자';     roles = @('ROLE_ADMIN','ROLE_APPROVER','ROLE_LAW_MGR','ROLE_EDITOR','ROLE_USER') },
    @{ id = 'approver'; pw = 'rlms1234!';  label = '승인자';     roles = @('ROLE_APPROVER','ROLE_EDITOR','ROLE_USER') },
    @{ id = 'lawmgr';   pw = 'rlms1234!';  label = '송무담당자'; roles = @('ROLE_LAW_MGR','ROLE_USER') },
    @{ id = 'user';     pw = 'rlms1234!';  label = '일반회원';   roles = @('ROLE_USER') }
)
foreach ($a in $accounts) { $a.roles += 'IS_AUTHENTICATED_FULLY' }

function Expect-Allow($url, $roles) {
    $path = ($url -split '\?')[0]
    foreach ($pat in $patterns) {
        if ([regex]::IsMatch($path, $pat)) {
            foreach ($r in $roles) { if ($auths[$pat].Contains($r)) { return @($true, $pat) } }
            return @($false, $pat)
        }
    }
    return @($false, '(매칭 규칙 없음)')
}

$menuName = @{}
$menuUrls = New-Object System.Collections.ArrayList
foreach ($line in $menuRows) {
    $p = $line.Split('|'); $menuName[$p[2]] = ($p[0] + ' ' + $p[1]); [void]$menuUrls.Add($p[2])
}

$bad = New-Object System.Collections.ArrayList
foreach ($a in $accounts) {
    $r = Invoke-WebRequest -Uri "$BaseUrl/uat/uia/actionLogin.do" -Method Post `
        -Body @{ id = $a.id; password = $a.pw; userSe = '' } -SessionVariable S -UseBasicParsing -TimeoutSec 20
    if ($r.Content -match 'id="loginForm"') { [void]$bad.Add(("로그인 실패: " + $a.id)); continue }

    $bodies = @{}
    $allow = 0
    foreach ($u in $menuUrls) {
        $exp = Expect-Allow $u $a.roles
        $st = 0
        try {
            $resp = Invoke-WebRequest -Uri ($BaseUrl + $u) -WebSession $S -UseBasicParsing -TimeoutSec 30
            $st = [int]$resp.StatusCode
            if ($st -eq 200) { $bodies[$u] = $resp.Content }
        } catch { $st = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { -1 } }
        $actual = ($st -eq 200)
        if ($actual) { $allow++ }
        if ($actual -ne $exp[0]) {
            $kind = if ($actual) { '누수(막혀야 하는데 열림)' } else { '오차단(열려야 하는데 막힘)' }
            [void]$bad.Add(("{0} — {1} [{2}] HTTP {3} / 규칙 {4}" -f $kind, $menuName[$u], $a.label, $st, $exp[1]))
        }
    }

    # 화면에 그려진 메뉴 링크 ↔ 접근 가능 여부
    #   style="display:none" 앵커는 제외 — 승인대기/반려 배지처럼 JS 가 조건부로 켜는 링크는
    #   권한 없는 계정에선 폴링(badgeCountsJson)이 403 이라 끝까지 숨겨진 채로 남는다.
    $ghost = New-Object System.Collections.Generic.HashSet[string]
    foreach ($body in $bodies.Values) {
        foreach ($m in [regex]::Matches($body, '<a\b[^>]*href="([^"]*\.do[^"]*)"[^>]*>')) {
            if ($m.Value -match 'display\s*:\s*none') { continue }
            $h = ($m.Groups[1].Value -replace '^https?://[^/]+', '')
            if ($h -notmatch '^/') { continue }
            $bare = ($h -split '\?')[0]
            foreach ($k in $menuUrls) {
                if ((($k -split '\?')[0]) -eq $bare -and -not $bodies.ContainsKey($k)) { [void]$ghost.Add($k) }
            }
        }
    }
    Write-Host ("  {0,-10}({1,-6}) 접근가능 {2,3} / 차단 {3,3}" -f $a.id, $a.label, $allow, ($menuUrls.Count - $allow))
    foreach ($g in $ghost) {
        [void]$bad.Add(("메뉴에 보이는데 막힘 — {0} [{1}]" -f $menuName[$g], $a.label))
    }
}

if ($bad.Count -eq 0) {
    Write-Host "`n== 불일치 0 — 인가 규칙·실제 응답·메뉴 노출이 전부 일치 =="
    exit 0
}
Write-Host ("`n== 불일치 {0}건 ==" -f $bad.Count)
$bad | ForEach-Object { Write-Host ("  ! " + $_) }
exit 1
