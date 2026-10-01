<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/tags/shell/front.tag

  사용자 화면 레이아웃 셸(JSP 태그파일).
   - KRDS + 상단 GNB (5구분 검색) + 본문 + 메모/즐겨찾기 플로팅 버튼
   - 레거시 /lims/front/layout.html 모방하되 KRDS 컴포넌트 사용
--%>
<%@ tag pageEncoding="UTF-8" body-content="scriptless"
        description="사용자 화면 셸 — 상단 헤더 + GNB + 빠른검색 + 본문" %>
<%@ attribute name="title"      required="false" description="브라우저 탭 제목. 비면 브랜드 문구." %>
<%@ attribute name="head"       required="false" description="페이지 고유 head 조각(link/script/style)을 담은 문자열." %>
<%@ attribute name="bodyOnload" required="false" description="페이지의 body onload 값." %>
<%@ tag import="java.util.List" %>
<%@ tag import="egovframework.com.cmm.LoginVO" %>
<%@ tag import="egovframework.com.cmm.util.EgovUserDetailsHelper" %>
<%@ tag import="narainet.rlms.menu.MenuHelper" %>
<%@ tag import="narainet.rlms.menu.service.MenuVO" %>
<%@ tag import="egovframework.com.uss.ion.brd.service.Brand" %>
<%@ tag import="egovframework.com.uss.ion.brd.service.BrandInfo" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    Boolean isAuth = EgovUserDetailsHelper.isAuthenticated();
    LoginVO loginUser = null;
    if (Boolean.TRUE.equals(isAuth)) {
        Object au = EgovUserDetailsHelper.getAuthenticatedUser();
        if (au instanceof LoginVO) loginUser = (LoginVO) au;
    }
    jspContext.setAttribute("rlmsAuthenticated", isAuth);
    jspContext.setAttribute("rlmsLoginUser", loginUser);

    // 공개열람 모드(Globals.rlms.publicFront=Y) — 익명에도 규정 열람 UI(분류 드로어 등)를 연다.
    // 개인화(즐겨찾기·메모·필수열람 등)는 각 화면이 로그인 여부로 따로 가린다.
    jspContext.setAttribute("rlmsPublicFront",
        Boolean.valueOf(narainet.rlms.common.service.PublicFront.enabled()));


    // 브랜드(로고·파비콘) — 관리자 > 브랜드설정. 기동 시 적재된 캐시라 페이지마다 DB 를 치지 않는다.
    Brand _brand = BrandInfo.get();
    String _brandText = _brand.getLogoText();
    jspContext.setAttribute("brandIsImage", Boolean.valueOf(_brand.isImageLogo()));
    jspContext.setAttribute("brandHasIcon", Boolean.valueOf(_brand.hasFavicon()));
    jspContext.setAttribute("brandVer",     BrandInfo.getVersion());
    jspContext.setAttribute("brandText", BrandInfo.getText());
    // 이미지 로고여도 문구가 입력돼 있으면 툴팁(title)으로 노출한다 — 로고만으로 시스템명이 안 보이는 것 보완.
    // 폴백 기본문구가 아니라 "실제 입력값"일 때만 붙이려고 원문을 따로 담는다.
    jspContext.setAttribute("brandRawText", _brandText == null ? "" : _brandText.trim());

    // 데이터기반 사용자 GNB — 표준 메뉴서비스(COMTNMENUINFO MENU_SE='USER' + 권한필터). 하드코딩 제거.
    List<MenuVO> rlmsMenuUser = MenuHelper.getMenuTree(request, "USER");
    jspContext.setAttribute("rlmsMenuUser", rlmsMenuUser);

    // 자체 검색 콘솔이 있는 화면(홈, 통합검색)에는 상단 빠른검색 바 숨김 — 검색창 이중 노출 방지.
    String rlmsReqUri = egovframework.com.cmm.util.EgovLayoutResolver.requestPath(request);
    jspContext.setAttribute("rlmsHasOwnSearch",
        rlmsReqUri != null && (rlmsReqUri.endsWith("/rlms/index.do")
            || rlmsReqUri.endsWith("/rlms/fulltext/searchAll.do")));

    // 관리자 메뉴 권한이 1개라도 있으면 "관리자모드" 진입 버튼 노출. getMenuTree 는 권한필터+60초 캐시.
    List<MenuVO> rlmsMenuAdmin = MenuHelper.getMenuTree(request, "ADMIN");
    jspContext.setAttribute("rlmsHasAdmin", rlmsMenuAdmin != null && !rlmsMenuAdmin.isEmpty());
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <script>
  // PC 버전 보기(2026-08-04) — 모바일에서 데스크톱 레이아웃 강제. viewport 메타를 1280 으로
  // 바꾸면 미디어쿼리가 데스크톱 규칙으로 평가된다(모바일 브라우저 전용 — 데스크톱은 메타 무시라 무해).
  // 켜기=전체메뉴 드로어 [PC 버전 보기], 끄기=헤더 [모바일 버전]. localStorage 유지.
  // head 인라인(메타 직후) 실행 = 첫 페인트 전에 적용돼 레이아웃 깜빡임 없음.
  (function(){
    try{
      if(localStorage.getItem('rlmsPcView')==='Y'){
        var m=document.querySelector('meta[name="viewport"]');
        if(m) m.setAttribute('content','width=1280');
      }
    }catch(e){}
  })();
  </script>
  <title>${empty title ? brandText : title}</title>

  <%-- 브라우저 탭 아이콘. 이게 없어 모든 화면이 /favicon.ico 404 를 냈다(2026-07-29 액세스 로그 최다 404)
       브랜드설정에 파비콘을 올렸으면 그것으로 대체된다. --%>
  <c:choose>
    <c:when test="${brandHasIcon}"><link rel="icon" href="<c:url value='/cmm/brand/favicon.do'/>?v=${brandVer}"/></c:when>
    <c:otherwise><link rel="icon" type="image/svg+xml" href="<c:url value='/resources/img/favicon.svg'/>"/></c:otherwise>
  </c:choose>

  <link rel="stylesheet" href="<c:url value='/resources/krds/cdn/krds.min.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/token/krds_tokens.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/common/common.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/component/component.css'/>?v=20260728a"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/rlms-compat.css'/>?v=20260804-fresp5"/>
  <%-- 인쇄 시 사용자화면 크롬(상단 헤더·GNB 메뉴·빠른검색)·드로어는 숨김 — 본문만 출력 --%>
  <style>
    @media print {
      .rlms-header, .rlms-front-gnb, .rlms-front-quicksch,
      [class*="rlms-prom-nav"], #displaySettingsModal { display: none !important; }
      .rlms-front-main { margin: 0 !important; padding: 0 !important; }
      body { background: #fff !important; }
    }
  </style>
  <script>
    // 세션 만료 감지(fetch 경로) — 만료 시 .do 호출이 로그인 페이지로 리다이렉트되면 로그인 화면으로 보냄(#12).
    (function(){
      if(!window.fetch || window.__rlmsFetchWrapped) return;
      window.__rlmsFetchWrapped = true;
      var RLMS_LOGIN_URL = '<c:url value="/uat/uia/egovLoginUsr.do"/>';
      var _redir = false, _f = window.fetch;
      window.fetch = function(){
        return _f.apply(this, arguments).then(function(res){
          try{
            if(!_redir && res && ((res.redirected && res.url && res.url.indexOf('/uat/uia/egovLoginUsr.do') >= 0)
                 || res.status === 401 || (res.headers && res.headers.get('X-RLMS-Auth') === 'login'))){
              _redir = true; location.href = RLMS_LOGIN_URL;
            }
          }catch(e){}
          return res;
        });
      };
    })();
  </script>

  ${head}

  <%-- 레이아웃 CSS 는 rlms-compat.css 에서 통일 관리 --%>
</head>
<%-- 페이지의 <body onload> 왕복 — 상세 설명은 mgr.jsp 동일 위치 주석 참조.
     casing 이 보존되므로 body.onload / body.onLoad 두 키를 모두 요청한다. --%>
<body<c:if test="${not empty bodyOnload}"> onload="${bodyOnload}"</c:if>>

  <%-- 글자 크기 설정(접근성) 모달+로직 공용 include (동적) --%>
  <jsp:include page="/WEB-INF/inc/display-settings.jsp" />

  <%-- 상단 헤더 (단순) --%>
  <header class="rlms-header">
    <a class="rlms-header-brand" href="<c:url value='/rlms/index.do'/>">
      <c:choose>
        <c:when test="${brandIsImage}"><img class="rlms-brand-img" src="<c:url value='/cmm/brand/logo.do'/>?v=${brandVer}" alt="<c:out value='${brandText}'/>"<c:if test="${not empty brandRawText}"> title="<c:out value='${brandRawText}'/>"</c:if>/></c:when>
        <c:otherwise><c:out value="${brandText}"/></c:otherwise>
      </c:choose>
    </a>
    <div class="rlms-header-actions">
      <c:choose>
        <c:when test="${rlmsAuthenticated}">
          <span class="rlms-user-name"><c:out value="${rlmsLoginUser.name}"/> 님</span>
          <%-- 승인 워크플로 알림(편집계 전용) — 편집자 로그인 랜딩이 front 홈이라 여기에도
               mgr 헤더와 동일한 배지를 노출(반려 인지 갭 교정, 2026-07-09). 폴링은 하단 스크립트. --%>
          <c:if test="${rlmsHasAdmin}">
            <c:url var="rlmsFrontPendingUrl" value="/rlms/promwork/selectPromWorkList.do"><c:param name="st" value="PENDING"/></c:url>
            <c:url var="rlmsFrontRejectUrl"  value="/rlms/promwork/selectPromWorkList.do"><c:param name="st" value="MYREJ"/></c:url>
            <a href="${rlmsFrontPendingUrl}" class="rlms-notif" id="rlmsNotifApprove" style="display:none;" title="처리 대기 중인 승인요청">
              <span class="rlms-notif-ico" aria-hidden="true">🔔</span>승인대기 <span class="rlms-notif-badge" id="rlmsNotifApproveCnt">0</span>
            </a>
            <a href="${rlmsFrontRejectUrl}" class="rlms-notif rlms-notif-deny" id="rlmsNotifReject" style="display:none;" title="내가 신청했다가 반려된 건 — 확인 후 재신청">
              반려 <span class="rlms-notif-badge" id="rlmsNotifRejectCnt">0</span>
            </a>
          </c:if>
          <button type="button" class="rlms-link rlms-ds-trigger" data-ds-open><span class="rlms-ds-ico" aria-hidden="true">가</span>글자 크기</button>
          <c:if test="${rlmsHasAdmin}">
            <%-- 관리자 화면은 반응형 대상이 아니므로 모바일(≤768)에선 숨김(rlms-compat.css).
                 [PC 버전 보기]로 데스크톱 레이아웃 강제 시엔 다시 노출된다. --%>
            <a href="<c:url value='/rlms/mgr/dashboard.do'/>" class="rlms-link rlms-admin-link">관리자모드</a>
          </c:if>
          <a href="<c:url value='/uat/uia/actionLogout.do'/>" class="rlms-link">로그아웃</a>
        </c:when>
        <c:otherwise>
          <a href="<c:url value='/uat/uia/egovLoginUsr.do'/>" class="rlms-link">로그인</a>
        </c:otherwise>
      </c:choose>
      <%-- PC 버전 강제 중일 때만 노출(JS) — 반응형(모바일 레이아웃)으로 복귀 --%>
      <button type="button" class="rlms-link" id="rlmsMobileViewBtn" style="display:none;" onclick="rlmsSetPcView(false)" title="모바일 화면으로 돌아가기">모바일 버전</button>
      <%-- 전체메뉴(모바일/태블릿 ≤1024) — 데스크톱에선 CSS 로 숨김. LexPortal mgr 와 동일 패턴 --%>
      <button type="button" class="rlms-burger" id="rlmsBurger" aria-label="전체 메뉴 열기" aria-controls="rlmsMnav" aria-expanded="false">
        <span></span><span></span><span></span>
      </button>
    </div>
  </header>

  <%-- ── 모바일 전체메뉴 드로어 (≤1024 햄버거로 오픈, LexPortal 대칭 룩) ─────────────
       GNB(.rlms-front-gnb)가 ≤1024 에서 숨으므로 동일 메뉴(rlmsMenuUser)를 드로어로 제공.
       폴더는 details/summary 아코디언(JS 불요), 최상단 '사용자 홈' = LexPortal '대시보드' 대응.
       익명(공개열람)은 GNB 폴백과 같은 열람 축 링크만 노출. --%>
  <div class="rlms-mnav" id="rlmsMnav" hidden>
    <button type="button" class="rlms-mnav-backdrop" data-mnav-close tabindex="-1" aria-hidden="true"></button>
    <aside class="rlms-mnav-panel" role="dialog" aria-modal="true" aria-label="전체 메뉴">
      <div class="rlms-mnav-head">
        <span class="rlms-mnav-tit">전체 메뉴</span>
        <button type="button" class="rlms-mnav-close" data-mnav-close aria-label="닫기">&times;</button>
      </div>
      <nav class="rlms-mnav-body">
        <a class="rlms-mnav-home" href="<c:url value='/rlms/index.do'/>">사용자 홈</a>
        <c:choose>
          <c:when test="${not empty rlmsMenuUser}">
            <c:forEach var="m1" items="${rlmsMenuUser}">
              <c:choose>
                <c:when test="${not empty m1.children}">
                  <details class="rlms-mnav-grp">
                    <summary><c:out value="${m1.menuNm}"/></summary>
                    <ul>
                      <c:forEach var="m2" items="${m1.children}">
                        <li>
                          <c:choose>
                            <c:when test="${not empty m2.children}">
                              <p class="rlms-mnav-sub-tit"><c:out value="${m2.menuNm}"/></p>
                              <ul>
                                <c:forEach var="m3" items="${m2.children}">
                                  <li><a href="<c:url value='${m3.href}'/>"<c:if test="${m3.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m3.menuNm}"/></a></li>
                                </c:forEach>
                              </ul>
                            </c:when>
                            <c:otherwise>
                              <a href="<c:url value='${m2.href}'/>"<c:if test="${m2.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m2.menuNm}"/></a>
                            </c:otherwise>
                          </c:choose>
                        </li>
                      </c:forEach>
                    </ul>
                  </details>
                </c:when>
                <c:otherwise>
                  <a class="rlms-mnav-link" href="<c:url value='${m1.href}'/>"<c:if test="${m1.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m1.menuNm}"/></a>
                </c:otherwise>
              </c:choose>
            </c:forEach>
          </c:when>
          <c:otherwise>
            <a class="rlms-mnav-link" href="<c:url value='/rlms/fulltext/searchAll.do'/>">통합검색</a>
            <c:if test="${rlmsPublicFront and not rlmsAuthenticated}">
              <a class="rlms-mnav-link" href="<c:url value='/rlms/fulltext/historyList.do'/>">규정검색</a>
              <a class="rlms-mnav-link" href="<c:url value='/rlms/fulltext/latestList.do'/>">최근개정내용</a>
              <a class="rlms-mnav-link" href="<c:url value='/rlms/fulltext/comparisonList.do'/>">신구대조</a>
              <a class="rlms-mnav-link" href="<c:url value='/rlms/fulltext/nullifyList.do'/>">폐지 사규/규정</a>
              <a class="rlms-mnav-link" href="<c:url value='/rlms/prommap/view.do'/>">규정맵</a>
            </c:if>
          </c:otherwise>
        </c:choose>
        <%-- PC 버전 보기 — 모바일에서 데스크톱 레이아웃 강제(viewport 1280). 복귀=헤더 [모바일 버전] --%>
        <button type="button" class="rlms-mnav-pcview" onclick="rlmsSetPcView(true)">PC 버전 보기</button>
      </nav>
    </aside>
  </div>
  <script>
  (function () {
    var mnav = document.getElementById('rlmsMnav');
    var burger = document.getElementById('rlmsBurger');
    if (!mnav || !burger) { return; }
    function openNav() { mnav.hidden = false; document.body.classList.add('rlms-mnav-open'); burger.setAttribute('aria-expanded', 'true'); }
    function closeNav() { mnav.hidden = true; document.body.classList.remove('rlms-mnav-open'); burger.setAttribute('aria-expanded', 'false'); }
    burger.addEventListener('click', openNav);
    mnav.addEventListener('click', function (e) {
      if (e.target.closest('[data-mnav-close]')) { closeNav(); }
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !mnav.hidden) { closeNav(); }
    });
  })();

  // PC 버전 보기 토글 — viewport 메타 교체 즉시 미디어쿼리 재평가(리로드 불요). localStorage 유지,
  // 초기 적용은 head 인라인 스크립트(첫 페인트 전). 데스크톱 브라우저는 viewport 메타를 무시하므로 무해.
  function rlmsSetPcView(on) {
    try { if (on) localStorage.setItem('rlmsPcView', 'Y'); else localStorage.removeItem('rlmsPcView'); } catch (e) {}
    var m = document.querySelector('meta[name="viewport"]');
    if (m) m.setAttribute('content', on ? 'width=1280' : 'width=device-width, initial-scale=1');
    var b = document.getElementById('rlmsMobileViewBtn');
    if (b) b.style.display = on ? '' : 'none';
    var mnav = document.getElementById('rlmsMnav');
    if (on && mnav && !mnav.hidden) {
      mnav.hidden = true;
      document.body.classList.remove('rlms-mnav-open');
      var bg = document.getElementById('rlmsBurger');
      if (bg) bg.setAttribute('aria-expanded', 'false');
    }
  }
  (function () {
    try {
      if (localStorage.getItem('rlmsPcView') === 'Y') {
        var b = document.getElementById('rlmsMobileViewBtn');
        if (b) b.style.display = '';
      }
    } catch (e) {}
  })();
  </script>

  <%-- 승인 워크플로 알림 폴링(편집계 전용) — mgr.jsp 와 동일(45초). USER 는 요청 자체를 안 보냄. --%>
  <c:if test="${rlmsAuthenticated and rlmsHasAdmin}">
  <script>
  (function(){
    var URL = '<c:url value="/rlms/promwork/badgeCountsJson.do"/>';
    function paint(linkId, cntId, n){
      var link = document.getElementById(linkId), cnt = document.getElementById(cntId);
      if (!link || !cnt) return;
      if (n > 0){ cnt.textContent = (n > 99 ? '99+' : n); link.style.display = ''; }
      else { link.style.display = 'none'; }
    }
    function poll(){
      fetch(URL, { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } })
        .then(function(r){ return r.ok ? r.json() : null; })
        .then(function(d){
          if (!d) return;
          paint('rlmsNotifApprove', 'rlmsNotifApproveCnt', d.pendingApproval || 0);
          paint('rlmsNotifReject',  'rlmsNotifRejectCnt',  d.myRejected || 0);
        })
        .catch(function(){ /* 폴링 실패 무시 — 다음 주기 재시도 */ });
    }
    poll();
    setInterval(poll, 120000);   <%-- 45s→120s (2026-07-24) — 유휴 탭의 배지 COUNT 쿼리 다이어트 --%>
  })();
  </script>
  </c:if>

  <%-- 상단 GNB — 데이터기반(COMTNMENUINFO MENU_SE='USER' + 권한필터). 표준 메뉴서비스 렌더.
       하드코딩 제거. 메뉴/외부링크는 표준 메뉴관리(/sym/mnu/mpm) 화면에서 수정.
       폴더는 하위 리프를 평면으로 펼쳐 현행 단일바 룩 유지. 외부링크는 새 탭.
       예외: RELATE_IMAGE_NM='drop' 인 폴더(마이페이지·게시판)는 그룹 라벨 + 드롭다운. --%>
  <nav class="rlms-front-gnb">
    <c:choose>
      <c:when test="${not empty rlmsMenuUser}">
        <c:forEach var="m1" items="${rlmsMenuUser}">
          <c:choose>
            <%-- 드롭다운 폴더: 하위를 메뉴판으로 묶음(호버/포커스 오픈, JS 불요). 판정은 DB 값(메뉴 개명에 안 깨짐) --%>
            <c:when test="${m1.dropdown}">
              <div class="rlms-gnb-drop">
                <button type="button" class="rlms-gnb-drop-btn" aria-haspopup="true"><c:out value="${m1.menuNm}"/> <span class="rlms-gnb-caret" aria-hidden="true">▾</span></button>
                <div class="rlms-gnb-drop-menu">
                  <c:forEach var="m2" items="${m1.children}">
                    <c:if test="${not m2.folder}">
                      <a href="<c:url value='${m2.href}'/>"<c:if test="${m2.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m2.menuNm}"/></a>
                    </c:if>
                  </c:forEach>
                </div>
              </div>
            </c:when>
            <%-- 폴더(그룹): 하위 리프를 평면으로 --%>
            <c:when test="${not empty m1.children}">
              <c:forEach var="m2" items="${m1.children}">
                <c:if test="${not m2.folder}">
                  <a href="<c:url value='${m2.href}'/>"<c:if test="${m2.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m2.menuNm}"/></a>
                </c:if>
              </c:forEach>
            </c:when>
            <%-- 최상위 직속 링크(폴더 아님) --%>
            <c:when test="${not m1.folder}">
              <a href="<c:url value='${m1.href}'/>"<c:if test="${m1.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m1.menuNm}"/></a>
            </c:when>
          </c:choose>
        </c:forEach>
      </c:when>
      <c:otherwise>
        <a href="<c:url value='/rlms/fulltext/searchAll.do'/>">통합검색</a>
        <%-- 공개열람(익명) — 표준 메뉴는 권한 기반이라 비어 폴백으로 온다.
             익명 개방된 열람 축 링크만 노출(개인화·게시판·FAQ 는 로그인 후 메뉴로) --%>
        <c:if test="${rlmsPublicFront and not rlmsAuthenticated}">
          <a href="<c:url value='/rlms/fulltext/historyList.do'/>">규정검색</a>
          <a href="<c:url value='/rlms/fulltext/latestList.do'/>">최근개정내용</a>
          <a href="<c:url value='/rlms/fulltext/comparisonList.do'/>">신구대조</a>
          <a href="<c:url value='/rlms/fulltext/nullifyList.do'/>">폐지 사규/규정</a>
          <a href="<c:url value='/rlms/prommap/view.do'/>">규정맵</a>
        </c:if>
      </c:otherwise>
    </c:choose>
  </nav>

  <%-- 빠른검색 바 — 자체 콘솔 있는 화면(홈·통합검색)에선 숨김, 그 외 서브페이지에서만 노출.
       제출 = 통합검색 전용 페이지(searchAll.do). 구분 hidden 은 미지정=전체 공개 원칙이라 제거
       (전부 TRUE 로 보내면 SGUBUN_ID 가 5종 외/NULL 인 규정이 빠지는 부작용도 있었음). --%>
  <c:if test="${not rlmsHasOwnSearch}">
  <form class="rlms-front-quicksch" action="<c:url value='/rlms/fulltext/searchAll.do'/>" method="get">
    <input type="text" name="searchKeyword" placeholder="통합검색 — 규정·조문·별표서식·자료·게시판·FAQ"/>
    <button type="submit" class="krds-btn primary medium">검색</button>
  </form>
  </c:if>

  <%-- 메인 --%>
  <main class="rlms-front-main">
    <jsp:doBody/>
  </main>

  <%-- KRDS JS — krds.min.js 가 ui-script 를 번들 포함하므로 별도 로드 X
       (중복 로드 시 'windowSize already declared' SyntaxError → 레이아웃 깜빡임). mgr.jsp 와 동일. --%>
  <script src="<c:url value='/resources/krds/cdn/krds.min.js'/>"></script>

  <%-- GNB 드롭다운 터치 대응 — hover 없는 단말(≥1025 터치 태블릿)은 버튼 탭으로 .open 토글, 바깥 탭=닫힘.
       ≤1024 는 GNB 자체가 숨고 전체메뉴 드로어가 대체하므로 이 토글은 데스크톱 폭 전용 보강이다. --%>
  <script>
  (function(){
    var drops = document.querySelectorAll('.rlms-front-gnb .rlms-gnb-drop');
    if (!drops.length) return;
    function closeAll(){ drops.forEach(function(d){ d.classList.remove('open'); }); }
    drops.forEach(function(d){
      var btn = d.querySelector('.rlms-gnb-drop-btn');
      if (!btn) return;
      btn.addEventListener('click', function(e){
        var was = d.classList.contains('open');
        closeAll();
        if (!was) d.classList.add('open');
        e.stopPropagation();
      });
    });
    document.addEventListener('click', closeAll);
  })();
  </script>

  <%-- 좌측 규정분류 펼침 드로어 — 모든 사용자 페이지 (분류>규정 leaf → 본문 바로열기).
       전문뷰어(provisionList.do?promNo)는 자체 좌측 트리라 컴포넌트가 자동 스킵.
       공개열람 모드면 익명에도 활성(트리 JSON 은 익명 개방 + 열람제한 가지치기 동일 적용). --%>
  <script src="<c:url value='/resources/js/rlms-prom-nav.js'/>?v=20260804-fresp"></script>
  <c:if test="${rlmsAuthenticated or rlmsPublicFront}">
  <script>
    if (window.RlmsPromNav) {
      RlmsPromNav.init({
        ctx:       '<c:url value="/"/>'.replace(/\/$/, ''),
        jeonUrl:   '<c:url value="/rlms/prom/treeJson.do"/>',
        deptUrl:   '<c:url value="/rlms/prom/treeJsonDept.do"/>',
        funcUrl:   '<c:url value="/rlms/prommap/treeJson.do"/>',
        viewerUrl: '<c:url value="/rlms/fulltext/provisionList.do"/>'
      });
    }
  </script>
  </c:if>
</body>
</html>
