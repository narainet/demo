# RLMS 화면명 정합 검사 — 메뉴명(COMTNMENUINFO.MENU_NM)이 화면 제목의 정본이다. (2026-07-29 신설)
#
# 규칙: 메뉴로 진입하는 화면의 <title> 과 <h1> 은 그 메뉴의 이름과 글자 그대로 같아야 한다.
#       (h1 이 없는 화면 — 규정 편집 IDE 처럼 자체 헤더를 쓰는 3-pane 화면 — 은 title 만 본다)
#
# 사용:  .\tools\namecheck.ps1 -DbPass '<RLMS 스키마 비밀번호>'
#        .\tools\namecheck.ps1 -DbPass '...' -BaseUrl http://localhost:7070
#
# ⚠️ 로그인 때문에 같은 계정(sysmen/user)의 브라우저 세션이 끊긴다 — smoke.ps1 과 같은 주의.
# ⚠️ PS 5.1 한글 리터럴 때문에 이 파일은 UTF-8(BOM) 이어야 한다.
param(
    [Parameter(Mandatory = $true)][string]$DbPass,
    [string]$BaseUrl = 'http://localhost:7070',
    [string]$DbUser = 'RLMS'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# ── 1) 메뉴명 정본 읽기 ───────────────────────────────────
$sql = "SELECT m.MENU_NO || '|' || m.MENU_NM || '|' || p.URL FROM COMTNMENUINFO m " +
       "JOIN COMTNPROGRMLIST p ON m.PROGRM_FILE_NM = p.PROGRM_FILE_NM " +
       "WHERE m.PROGRM_FILE_NM <> 'folder' ORDER BY m.MENU_NO"
$raw = & (Join-Path $root 'tools\dbq\dbr.ps1') $DbUser $DbPass exec $sql
$menus = @($raw | Where-Object { $_ -match '^\d{8}\|' })
if ($menus.Count -eq 0) { Write-Host '메뉴를 읽지 못했습니다 — DB 접속/비밀번호 확인'; exit 1 }
Write-Host ("== 화면명 정합 검사: 메뉴 {0}건 ({1}) ==" -f $menus.Count, $BaseUrl)

# ── 2) 계정별 세션 (권한이 갈리므로 관리자·일반 둘 다 준비) ──
$accounts = @(
    @{ id = 'sysmen'; pw = 'asdqwe123!' },
    @{ id = 'user';   pw = 'rlms1234!' }
)
$sessions = @{}
foreach ($a in $accounts) {
    $r = Invoke-WebRequest -Uri "$BaseUrl/uat/uia/actionLogin.do" -Method Post `
        -Body @{ id = $a.id; password = $a.pw; userSe = '' } -SessionVariable S -UseBasicParsing -TimeoutSec 20
    if ($r.Content -match 'id="loginForm"') { Write-Host ("로그인 실패: {0}" -f $a.id); exit 1 }
    $sessions[$a.id] = $S
}

# ── 3) 대조 ───────────────────────────────────────────────
$bad = New-Object System.Collections.ArrayList
foreach ($line in $menus) {
    $p = $line.Split('|'); $no = $p[0]; $nm = $p[1]; $u = $p[2]
    $title = ''; $h1 = ''; $reached = $false
    foreach ($a in $accounts) {
        try {
            $r = Invoke-WebRequest -Uri ($BaseUrl + $u) -WebSession $sessions[$a.id] -UseBasicParsing -TimeoutSec 25
            $b = $r.Content
            $m = [regex]::Match($b, '(?s)<title>(.*?)</title>')
            if ($m.Success) { $title = [System.Net.WebUtility]::HtmlDecode(($m.Groups[1].Value -replace '\s+', ' ').Trim()) }
            $m2 = [regex]::Match($b, '(?s)<h1[^>]*>(.*?)</h1>')
            if ($m2.Success) { $h1 = [System.Net.WebUtility]::HtmlDecode(((($m2.Groups[1].Value -replace '<[^>]+>', '') -replace '\s+', ' ')).Trim()) }
            $reached = $true
            break
        } catch { }
    }
    if (-not $reached) { [void]$bad.Add(("{0} [{1}] — 어느 계정으로도 열리지 않음 ({2})" -f $no, $nm, $u)); continue }
    if ($title -ne $nm -or ($h1 -ne '' -and $h1 -ne $nm)) {
        [void]$bad.Add(("{0} [{1}] — title='{2}' h1='{3}' ({4})" -f $no, $nm, $title, $h1, $u))
    }
}

if ($bad.Count -eq 0) {
    Write-Host ("`n== 결과: {0}/{0} 일치 ==" -f $menus.Count)
    exit 0
}
Write-Host ("`n== 결과: {0}/{1} 일치, {2} 불일치 ==" -f ($menus.Count - $bad.Count), $menus.Count, $bad.Count)
$bad | ForEach-Object { Write-Host ("  ! " + $_) }
exit 1
