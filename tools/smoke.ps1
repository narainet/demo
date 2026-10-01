# RLMS 스모크 테스트 — 로그인 + 핵심 화면/팝업/JSON 회귀 점검 (2026-07-28 신설)
#
# 사용:  .\tools\smoke.ps1                          # 기본 http://localhost:7070, sysmen
#        .\tools\smoke.ps1 -BaseUrl http://... -User sysmen -Pass '...'
#
# ⚠️ 중복로그인 방지 정책 때문에, 여기서 로그인하면 같은 계정의 브라우저 세션이 끊긴다.
# ⚠️ PS 5.1 은 한글 리터럴 때문에 이 파일이 UTF-8(BOM) 이어야 한다 — 다른 인코딩으로 저장 금지.
param(
    [string]$BaseUrl = 'http://localhost:7070',
    [string]$User = 'sysmen',
    [string]$Pass = 'asdqwe123!'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$sw = [Diagnostics.Stopwatch]::StartNew()
$results = New-Object System.Collections.ArrayList

function Add-Result([string]$state, [string]$name, [string]$detail) {
    [void]$results.Add([pscustomobject]@{ state = $state; name = $name; detail = $detail })
    $mark = if ($state -eq 'PASS') { '[PASS]' } else { '[FAIL]' }
    Write-Host ("{0} {1}{2}" -f $mark, $name, $(if ($detail) { " - $detail" } else { "" }))
}

# ── 1) 로그인 ─────────────────────────────────────────────
Write-Host "== RLMS smoke: $BaseUrl ($User) — 같은 계정 브라우저 세션은 끊깁니다 =="
try {
    $login = Invoke-WebRequest -Uri "$BaseUrl/uat/uia/actionLogin.do" -Method Post `
        -Body @{ id = $User; password = $Pass; userSe = '' } `
        -SessionVariable S -UseBasicParsing -TimeoutSec 15
    if ($login.Content -match 'id="loginForm"') { throw "로그인 실패(로그인 화면으로 회귀) — 계정/비밀번호 확인" }
    Add-Result 'PASS' '로그인' $null
} catch {
    Add-Result 'FAIL' '로그인' $_.Exception.Message
    Write-Host "`n== 로그인 실패 — 이후 점검 중단 =="; exit 1
}

# ── 2) 점검 목록 ──────────────────────────────────────────
#  kind: html(기본) | popup(헤더리스 셸 검증) | json(파싱+건수)
#  expect: 본문에 있어야 하는 문자열(정규식) — 확실한 것만 지정
$checks = @(
    @{ n = 'mgr 대시보드';        u = '/rlms/mgr/dashboard.do';                 expect = '대시보드' }
    @{ n = 'mgr 규정목록';        u = '/rlms/prom/selectPromList.do' }
    @{ n = 'mgr 승인관리';        u = '/rlms/promwork/selectPromWorkList.do' }
    @{ n = 'mgr 조회수통계';      u = '/rlms/stats/viewStats.do' }
    @{ n = 'mgr 권한관리';        u = '/sec/ram/EgovAuthorList.do' }
    @{ n = 'mgr 역할관리';        u = '/sec/rmt/EgovRoleList.do' }
    @{ n = 'mgr 부서권한관리';    u = '/sec/drm/EgovDeptAuthorList.do';         expect = '부서권한관리' }
    @{ n = 'mgr 사용자관리';      u = '/uss/umt/EgovUserManage.do' }
    @{ n = 'front 홈';            u = '/rlms/index.do' }
    @{ n = 'front 규정검색';      u = '/rlms/fulltext/historyList.do';          expect = '규정검색' }
    @{ n = 'front 전문뷰어';      u = '/rlms/fulltext/provisionList.do' }
    @{ n = 'front 통합검색';      u = '/rlms/fulltext/searchAll.do' }
    @{ n = 'front 폐지검색';      u = '/rlms/fulltext/nullifyList.do' }
    @{ n = 'front 최근개정';      u = '/rlms/fulltext/latestList.do' }
    @{ n = 'front 신구대조';      u = '/rlms/fulltext/comparisonList.do' }
    @{ n = 'front 도움말FAQ';     u = '/uss/olh/faq/selectFaqUserList.do' }
    @{ n = 'law 송무홈';          u = '/law/home/main.do';                      expect = '송무 홈' }
    @{ n = 'law 소송조회';        u = '/law/suit/list.do';                      expect = '소송조회' }
    @{ n = 'law 일정관리';        u = '/law/schedule/main.do' }
    @{ n = 'law 소송의뢰관리';    u = '/law/req/list.do';                       expect = '소송의뢰관리' }
    @{ n = 'law 소송통계';        u = '/law/stat/summary.do';                   expect = '소송통계' }
    @{ n = 'law 요율설정';        u = '/law/calcset/list.do' }
    @{ n = 'popup 부서조회';      u = '/sec/drm/EgovDeptSearchList.do';         kind = 'popup' }
    @{ n = 'popup 프로그램검색';  u = '/sym/prm/EgovProgramListSearch.do';      kind = 'popup' }
    @{ n = 'popup ID중복확인';    u = '/uss/umt/EgovIdDplctCnfirmView.do';      kind = 'popup' }
    @{ n = 'popup 개인정보로그';  u = '/sym/log/plg/SelectPrivacyLogDetail.do'; kind = 'popup' }
    @{ n = 'popup 사이트맵선택';  u = '/sym/mnu/mcm/EgovMenuCreatSiteMapSelect.do?authorCode=ROLE_ADMIN'; kind = 'popup' }
    @{ n = 'json 뷰어트리';       u = '/rlms/prom/treeJson.do';                 kind = 'json' }
    @{ n = 'json 분류필터트리';   u = '/rlms/cate/selectCateTreeJson.do';       kind = 'json' }
    @{ n = 'mgr 필수열람현황';    u = '/rlms/readduty/dutyStatus.do';           expect = '필수열람 현황' }
    @{ n = 'mgr 접속세션현황';    u = '/sym/log/wlg/SelectWebLogSessionList.do'; expect = '접속 세션 현황' }
)

# 렌더된 오류 페이지/스택 흔적(egovError 포함) (JS 문자열 리터럴 오탐을 피하려고 좁게 잡음)
$errMark = 'HTTP Status |java\.lang\.|org\.springframework\.|JasperException|알 수 없는 오류가 발생했습니다'

foreach ($c in $checks) {
    $name = $c.n
    try {
        $t0 = $sw.Elapsed.TotalSeconds
        $r = Invoke-WebRequest -Uri ($BaseUrl + $c.u) -WebSession $S -UseBasicParsing -TimeoutSec 20
        $dt = [math]::Round($sw.Elapsed.TotalSeconds - $t0, 2)
        $body = $r.Content
        if ($r.StatusCode -ne 200)            { Add-Result 'FAIL' $name "HTTP $($r.StatusCode)"; continue }
        if ($body -match 'id="loginForm"')    { Add-Result 'FAIL' $name '로그인 화면으로 리다이렉트(세션 상실)'; continue }
        if ($body -match $errMark)            { Add-Result 'FAIL' $name '오류 페이지/스택 흔적(egovError 포함)'; continue }
        switch ($c.kind) {
            'popup' {
                if ($body -notmatch 'rlms-popup-body') { Add-Result 'FAIL' $name '팝업 셸 아님(데코 매핑 확인)'; continue }
                if ($body -match '송무관리')           { Add-Result 'FAIL' $name '관리자 GNB 혼입(이중 레이아웃)'; continue }
            }
            'json' {
                $j = $body | ConvertFrom-Json
                $cnt = if ($j -is [array]) { $j.Count }
                       elseif ($null -ne $j.resultList) { @($j.resultList).Count }
                       else { -1 }
                if ($cnt -le 0) { Add-Result 'FAIL' $name "JSON 비었음/형태 이상(cnt=$cnt)"; continue }
            }
            default {
                if ($c.expect -and $body -notmatch $c.expect) { Add-Result 'FAIL' $name "기대 문자열 없음: $($c.expect)"; continue }
            }
        }
        Add-Result 'PASS' $name ("{0}s" -f $dt)
    } catch {
        Add-Result 'FAIL' $name $_.Exception.Message
    }
}

# ── 3) 요약 ───────────────────────────────────────────────
$fail = @($results | Where-Object { $_.state -eq 'FAIL' })
$total = $results.Count
Write-Host ("`n== 결과: {0}/{1} PASS, {2} FAIL ({3}s) ==" -f ($total - $fail.Count), $total, $fail.Count, [math]::Round($sw.Elapsed.TotalSeconds, 1))
if ($fail.Count) { $fail | ForEach-Object { Write-Host ("  FAIL: {0} - {1}" -f $_.name, $_.detail) } ; exit 1 }
exit 0
