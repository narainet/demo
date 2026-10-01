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
  // PC 버전 보기(2026-08-06) — mgr.jsp 와 동일 방식. 사용자 화면엔 드로어가 없어 켜기 버튼도 헤더에 둔다.
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
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/rlms-compat.css'/>?v=20260806-calc"/>
  <%-- 인쇄 시 사용자화면 크롬(상단 헤더·GNB 메뉴)은 숨김 — 본문만 출력 --%>
  <style>
    @media print {
      .rlms-header, .rlms-front-gnb, #displaySettingsModal { display: none !important; }
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
    <a class="rlms-header-brand" href="<c:url value='/main.do'/>">
      <c:choose>
        <c:when test="${brandIsImage}"><img class="rlms-brand-img" src="<c:url value='/cmm/brand/logo.do'/>?v=${brandVer}" alt="<c:out value='${brandText}'/>"<c:if test="${not empty brandRawText}"> title="<c:out value='${brandRawText}'/>"</c:if>/></c:when>
        <c:otherwise><c:out value="${brandText}"/></c:otherwise>
      </c:choose>
    </a>
    <div class="rlms-header-actions">
      <c:choose>
        <c:when test="${rlmsAuthenticated}">
          <span class="rlms-user-name"><c:out value="${rlmsLoginUser.name}"/> 님</span>
          <%-- 승인 워크플로 배지는 규정관리 도메인 — 송무 단독(LexPortal)엔 없음 --%>
          <button type="button" class="rlms-link rlms-ds-trigger" data-ds-open><span class="rlms-ds-ico" aria-hidden="true">가</span>글자 크기</button>
          <c:if test="${rlmsHasAdmin}">
            <a href="<c:url value='/main.do'/>" class="rlms-link">관리자모드</a>
          </c:if>
          <a href="<c:url value='/uat/uia/actionLogout.do'/>" class="rlms-link">로그아웃</a>
        </c:when>
        <c:otherwise>
          <a href="<c:url value='/uat/uia/egovLoginUsr.do'/>" class="rlms-link">로그인</a>
        </c:otherwise>
      </c:choose>
      <%-- PC 버전 보기 — 모바일(≤1024)에서만 노출. 복귀=[모바일 버전](PC 강제 중일 때만 JS 로 노출) --%>
      <button type="button" class="rlms-link rlms-pcview-btn" onclick="rlmsSetPcView(true)">PC 버전</button>
      <button type="button" class="rlms-link" id="rlmsMobileViewBtn" style="display:none;" onclick="rlmsSetPcView(false)" title="모바일 화면으로 돌아가기">모바일 버전</button>
    </div>
  </header>

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
        <a href="<c:url value='/main.do'/>">홈</a>
      </c:otherwise>
    </c:choose>
  </nav>

  <%-- 메인 --%>
  <main class="rlms-front-main">
    <jsp:doBody/>
  </main>

  <%-- KRDS JS — krds.min.js 가 ui-script 를 번들 포함하므로 별도 로드 X
       (중복 로드 시 'windowSize already declared' SyntaxError → 레이아웃 깜빡임). mgr.jsp 와 동일. --%>
  <script src="<c:url value='/resources/krds/cdn/krds.min.js'/>"></script>
  <%-- 모바일(≤900) 검색영역 접기 — mgr.jsp 와 동일 컴포넌트(도움말·게시판열람·내계정 검색바 대상) --%>
  <script src="<c:url value='/resources/js/rlms-search-fold.js'/>?v=20260806"></script>
  <%-- 모바일(≤768) 상세 표 → 카드 (소송·의뢰 상세의 5~8열 표) --%>
  <script src="<c:url value='/resources/js/rlms-table-stack.js'/>?v=20260806"></script>
  <script>
  // PC 버전 보기 토글 — mgr.jsp 와 동일(viewport 메타 교체 = 미디어쿼리 즉시 재평가, 리로드 불요).
  function rlmsSetPcView(on) {
    try { if (on) { localStorage.setItem('rlmsPcView', 'Y'); } else { localStorage.removeItem('rlmsPcView'); } } catch (e) {}
    var m = document.querySelector('meta[name="viewport"]');
    if (m) { m.setAttribute('content', on ? 'width=1280' : 'width=device-width, initial-scale=1'); }
    var b = document.getElementById('rlmsMobileViewBtn');
    if (b) { b.style.display = on ? '' : 'none'; }
    var p = document.querySelector('.rlms-pcview-btn');
    if (p) { p.style.display = on ? 'none' : ''; }
    // 폭 변화를 폭에 반응하는 스크립트(검색영역 접기)에 알린다 — mgr.jsp 와 동일.
    try { window.dispatchEvent(new Event('resize')); } catch (e) {}
  }
  (function () {
    try {
      if (localStorage.getItem('rlmsPcView') === 'Y') {
        var b = document.getElementById('rlmsMobileViewBtn');
        if (b) { b.style.display = ''; }
        var p = document.querySelector('.rlms-pcview-btn');
        if (p) { p.style.display = 'none'; }
      }
    } catch (e) {}
  })();
  </script>
</body>
</html>
