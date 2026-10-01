<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/tags/shell/mgr.tag

  업무 관리자 화면 레이아웃 셸(JSP 태그파일).
   - KRDS 디자인 시스템 적용 (krds.min.css/js + PretendardGOV 폰트)
   - 레이아웃: 상단 헤더 + 좌측 LNB + 본문
   - 본문은 페이지의 <body> 내용을 <jsp:doBody/> 로 삽입
   - 페이지의 <head> 안 추가 link/script 는 ${head} 로 삽입
   - 페이지 제목은 title 속성 (페이지 <title> 우선)

   ※ GNB/LNB 계산 로직은 narainet.rlms.menu.MenuHelper.resolveAdminLayout() 로 이관(2026-06-09).
     활성 LNB 판정은 DB 메뉴트리에서 파생(하드코딩 URL 사다리 제거). 스크립틀릿은 모델 주입만.
   파일명 admin → mgr 변경 사유: 보안 점검에서 'admin' 명명 노출 회피.
--%>
<%@ tag pageEncoding="UTF-8" body-content="scriptless"
        description="업무관리자 화면 셸 — 상단 헤더 + GNB + 좌측 LNB + 본문" %>
<%@ attribute name="title"      required="false" description="브라우저 탭 제목. 비면 브랜드 문구." %>
<%@ attribute name="head"       required="false" description="페이지 고유 head 조각(link/script/style)을 담은 문자열." %>
<%@ attribute name="bodyOnload" required="false" description="페이지의 body onload 값." %>
<%@ tag import="narainet.rlms.menu.MenuHelper" %>
<%@ tag import="narainet.rlms.menu.service.MenuLayoutVO" %>
<%@ tag import="egovframework.com.uss.ion.brd.service.Brand" %>
<%@ tag import="egovframework.com.uss.ion.brd.service.BrandInfo" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%
    // 관리자 레이아웃 모델(인증·GNB·활성LNB) 한 번에 — 계산은 MenuHelper 가 담당.
    MenuLayoutVO rlmsLayout = MenuHelper.resolveAdminLayout(request);
    jspContext.setAttribute("rlmsAuthenticated",   Boolean.valueOf(rlmsLayout.isAuthenticated()));
    jspContext.setAttribute("rlmsLoginUser",       rlmsLayout.getLoginUser());
    jspContext.setAttribute("rlmsMenuAdmin",       rlmsLayout.getMenuAdmin());
    jspContext.setAttribute("rlmsPath",            rlmsLayout.getPath());
    jspContext.setAttribute("rlmsLnbRoot",         rlmsLayout.getLnbRoot());
    jspContext.setAttribute("rlmsActiveMenuPrefix",rlmsLayout.getActiveMenuPrefix());
    jspContext.setAttribute("rlmsShowDbLnb",       Boolean.valueOf(rlmsLayout.isShowDbLnb()));
    jspContext.setAttribute("rlmsActiveSystem",    Boolean.valueOf(rlmsLayout.isActiveSystem()));
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
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <script>
  // PC 버전 보기(2026-08-06, RegNex front 와 동일 방식) — 모바일에서 데스크톱 레이아웃 강제.
  // viewport 메타를 1280 으로 바꾸면 미디어쿼리가 데스크톱 규칙으로 재평가된다(모바일 브라우저 전용 —
  // 데스크톱 브라우저는 이 메타를 무시하므로 무해). 켜기=전체메뉴 드로어 [PC 버전 보기],
  // 끄기=헤더 [모바일 버전]. localStorage 유지. head 인라인 = 첫 페인트 전 적용(깜빡임 없음).
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

  <%-- KRDS 디자인 시스템 --%>
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


  <%-- 페이지 별 추가 head --%>
  ${head}

  <c:if test="${rlmsActiveSystem and rlmsShowDbLnb}">
  <style>
    .rlms-admin-main > .user-manage-wrap > .user-manage-left,
    .rlms-admin-main > .author-manage-wrap > .author-manage-left,
    .rlms-admin-main > .author-role-wrap > .author-role-left,
    .rlms-admin-main > .role-manage-wrap > .role-manage-left,
    .rlms-admin-main > .author-group-wrap > .author-group-left { display: none !important; }
    .rlms-admin-main > .user-manage-wrap,
    .rlms-admin-main > .author-manage-wrap,
    .rlms-admin-main > .author-role-wrap,
    .rlms-admin-main > .role-manage-wrap,
    .rlms-admin-main > .author-group-wrap { display: block; position: static; }
    .rlms-admin-main > .user-manage-wrap > .user-manage-main,
    .rlms-admin-main > .author-manage-wrap > .author-manage-main,
    .rlms-admin-main > .author-role-wrap > .author-role-main,
    .rlms-admin-main > .role-manage-wrap > .role-manage-main,
    .rlms-admin-main > .author-group-wrap > .author-group-main { display: block; width: 100%; }
  </style>
  </c:if>

  <%-- 레이아웃 CSS 는 /resources/krds/css/rlms-compat.css 에서 통일 관리. --%>
</head>
<%-- 데코레이트되는 페이지의 <body onload> 를 되살린다. SiteMesh 는 페이지의 <body> 태그를 버리고
     이 태그를 쓰므로, 명시적으로 왕복시키지 않으면 onload 가 소멸해 초기화 함수가 영영 안 돈다.
     ★BodyTagRule 은 속성명 casing 을 보존한다(body.onload 와 body.onLoad 는 서로 다른 키) → 둘 다 요청.
       해당 프로퍼티가 없으면 PropertyTag 는 아무것도 출력하지 않으므로 빈 속성이 남지 않는다. --%>
<body<c:if test="${not empty bodyOnload}"> onload="${bodyOnload}"</c:if>>

  <%-- 글자 크기 설정(접근성) 모달+로직 공용 include (동적) --%>
  <jsp:include page="/WEB-INF/inc/display-settings.jsp" />

  <%-- ── 상단 헤더 + GNB ─────────────────────────────── --%>
  <header class="rlms-header">
    <a class="rlms-header-brand" href="<c:url value='/main.do'/>">
      <c:choose>
        <c:when test="${brandIsImage}"><img class="rlms-brand-img" src="<c:url value='/cmm/brand/logo.do'/>?v=${brandVer}" alt="<c:out value='${brandText}'/>"<c:if test="${not empty brandRawText}"> title="<c:out value='${brandRawText}'/>"</c:if>/></c:when>
        <c:otherwise><c:out value="${brandText}"/></c:otherwise>
      </c:choose>
    </a>

    <%-- 상단 GNB (메가 메뉴) — KRDS 스타일 --%>
    <%-- 데이터기반 GNB — COMTNMENUINFO(ADMIN) + COMTNMENUCREATDTLS 권한 필터.
         하드코딩 제거. 메뉴/프로그램 등록은 표준 프로그램관리·메뉴관리 화면에서 수정. --%>
    <nav class="rlms-gnb">
      <ul class="rlms-gnb-list">
      <c:choose>
        <%-- 데이터기반 메뉴(시드 적용 시): 권한별 COMTNMENUINFO 렌더 --%>
        <c:when test="${not empty rlmsMenuAdmin}">
          <c:forEach var="m1" items="${rlmsMenuAdmin}">
            <li class="rlms-gnb-item">
              <a href="<c:url value='${m1.href}'/>" class="rlms-gnb-link"<c:if test="${m1.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m1.menuNm}"/></a>
              <c:if test="${not empty m1.children}">
                <div class="rlms-gnb-mega">
                  <p class="rlms-gnb-mega-tit"><c:out value="${m1.menuNm}"/></p>
                  <ul class="rlms-gnb-mega-grid">
                    <c:forEach var="m2" items="${m1.children}">
                      <li>
                        <a href="<c:url value='${m2.href}'/>"<c:if test="${m2.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m2.menuNm}"/></a>
                        <c:if test="${not empty m2.children}">
                          <ul class="rlms-gnb-submenu">
                            <c:forEach var="m3" items="${m2.children}">
                              <li><a href="<c:url value='${m3.href}'/>"<c:if test="${m3.external}"> target="_blank" rel="noopener"</c:if>><c:out value="${m3.menuNm}"/></a></li>
                            </c:forEach>
                          </ul>
                        </c:if>
                      </li>
                    </c:forEach>
                  </ul>
                </div>
              </c:if>
            </li>
          </c:forEach>
        </c:when>
        <%-- 폴백(시드 미적용/조회 실패 시) --%>
        <c:otherwise>
          <li class="rlms-gnb-item"><a href="<c:url value='/main.do'/>" class="rlms-gnb-link">메뉴 준비중</a></li>
        </c:otherwise>
      </c:choose>
      </ul>
    </nav>

    <div class="rlms-header-actions">
      <c:choose>
        <c:when test="${rlmsAuthenticated}">
          <span class="rlms-user-name"><c:out value="${rlmsLoginUser.name}"/> 님</span>
          <%-- 승인 워크플로 배지는 규정관리 도메인 — 송무 단독(LexPortal)엔 없음 --%>
          <button type="button" class="rlms-link rlms-ds-trigger" data-ds-open><span class="rlms-ds-ico" aria-hidden="true">가</span>글자 크기</button>
          <%-- 소송비용 계산기 — 어느 화면에서나 바로 여는 상시 도구(모달은 아래 _calcModal.jspf).
               PC 는 [계산기][로그아웃] 나란히, 모바일(≤1024)은 로그아웃이 드로어로 빠지고 이 자리를 계산기가 쓴다. --%>
          <button type="button" class="rlms-link" onclick="fnOpenCalc();" title="소송비용 계산기(인지액·송달료·변호사비·지연이자)">계산기</button>
          <a href="<c:url value='/uat/uia/actionLogout.do'/>" class="rlms-link rlms-logout-link">로그아웃</a>
        </c:when>
        <c:otherwise>
          <a href="<c:url value='/uat/uia/egovLoginUsr.do'/>" class="rlms-link">로그인</a>
        </c:otherwise>
      </c:choose>
      <%-- PC 버전 강제 중일 때만 노출(JS) — 반응형(모바일 레이아웃)으로 복귀 --%>
      <button type="button" class="rlms-link" id="rlmsMobileViewBtn" style="display:none;" onclick="rlmsSetPcView(false)" title="모바일 화면으로 돌아가기">모바일 버전</button>
      <%-- 전체메뉴(모바일/태블릿 ≤1024) — 데스크톱에선 CSS 로 숨김 --%>
      <button type="button" class="rlms-burger" id="rlmsBurger" aria-label="전체 메뉴 열기" aria-controls="rlmsMnav" aria-expanded="false">
        <span></span><span></span><span></span>
      </button>
    </div>
  </header>

  <%-- ── 모바일 전체메뉴 드로어 (≤1024 햄버거로 오픈) ─────────────
       '대시보드'(구 송무 홈)는 GNB 미노출 정책(2026-08-04 메뉴 재편)의 모바일 짝으로 여기에만 노출.
       그룹 아코디언은 details/summary(JS 불요) — 현재 화면이 속한 그룹은 기본 펼침. --%>
  <div class="rlms-mnav" id="rlmsMnav" hidden>
    <button type="button" class="rlms-mnav-backdrop" data-mnav-close tabindex="-1" aria-hidden="true"></button>
    <aside class="rlms-mnav-panel" role="dialog" aria-modal="true" aria-label="전체 메뉴">
      <div class="rlms-mnav-head">
        <span class="rlms-mnav-tit">전체 메뉴</span>
        <button type="button" class="rlms-mnav-close" data-mnav-close aria-label="닫기">&times;</button>
      </div>
      <nav class="rlms-mnav-body">
        <a class="rlms-mnav-home" href="<c:url value='/main.do'/>">대시보드</a>
        <c:forEach var="m1" items="${rlmsMenuAdmin}">
          <c:choose>
            <c:when test="${not empty m1.children}">
              <details class="rlms-mnav-grp"<c:if test="${not empty rlmsLnbRoot and rlmsLnbRoot.menuNo eq m1.menuNo}"> open</c:if>>
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
        <%-- PC 버전 보기 — 모바일에서 데스크톱 레이아웃 강제(viewport 1280). 복귀=헤더 [모바일 버전] --%>
        <button type="button" class="rlms-mnav-pcview" onclick="rlmsSetPcView(true)">PC 버전 보기</button>
        <%-- 로그아웃 — 좁은 화면에선 헤더에서 빠지고 여기로(2026-08-06 사용자 지시). 헤더 그 자리는 [계산기]. --%>
        <c:if test="${rlmsAuthenticated}">
          <a class="rlms-mnav-logout" href="<c:url value='/uat/uia/actionLogout.do'/>">로그아웃</a>
        </c:if>
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
    try { if (on) { localStorage.setItem('rlmsPcView', 'Y'); } else { localStorage.removeItem('rlmsPcView'); } } catch (e) {}
    var m = document.querySelector('meta[name="viewport"]');
    if (m) { m.setAttribute('content', on ? 'width=1280' : 'width=device-width, initial-scale=1'); }
    var b = document.getElementById('rlmsMobileViewBtn');
    if (b) { b.style.display = on ? '' : 'none'; }
    var nav = document.getElementById('rlmsMnav');
    if (on && nav && !nav.hidden) {          // 드로어에서 켠 경우 — 켜자마자 드로어는 닫는다
      nav.hidden = true;
      document.body.classList.remove('rlms-mnav-open');
      var bg = document.getElementById('rlmsBurger');
      if (bg) { bg.setAttribute('aria-expanded', 'false'); }
    }
    // 폭이 바뀐 사실을 폭에 반응하는 스크립트(검색영역 접기·GNB 정렬)에 알린다.
    // 실기기는 viewport 메타 변경 시 resize 가 오지만, 오지 않는 환경도 있어 직접 쏜다(중복 발화는 무해).
    try { window.dispatchEvent(new Event('resize')); } catch (e) {}
  }
  (function () {
    try {
      if (localStorage.getItem('rlmsPcView') === 'Y') {
        var b = document.getElementById('rlmsMobileViewBtn');
        if (b) { b.style.display = ''; }
      }
    } catch (e) {}
  })();
  </script>

  <%-- ── 본문 영역 (좌측 LNB + 본문) ──────────────────── --%>
  <div class="rlms-admin-wrap">
    <c:if test="${rlmsShowDbLnb}">
      <%-- KRDS LNB(krds.go.kr 서비스패턴 좌측메뉴 스타일, 2026-07-08 사용자 확정) —
           제목 + 아코디언 그룹(셰브론 토글) + '·' 하위항목, 활성 항목의 그룹은 기본 펼침.
           ※ rlms-lnb-* 전용 클래스 — IDE(editor.do) 좌측 패널의 ide-actions 와 분리(그쪽은 유지). --%>
      <aside class="rlms-lnb" aria-label="${rlmsLnbRoot.menuNm} 메뉴">
        <h2 class="rlms-lnb-tit"><c:out value="${rlmsLnbRoot.menuNm}"/></h2>
        <nav aria-label="${rlmsLnbRoot.menuNm} 메뉴">
          <ul class="rlms-lnb-list">
          <c:forEach var="lnbMenu" items="${rlmsLnbRoot.children}">
            <c:set var="lnbActive" value="${not empty lnbMenu.url and (rlmsPath == lnbMenu.url or fn:startsWith(lnbMenu.url, rlmsActiveMenuPrefix) or fn:startsWith(rlmsPath, lnbMenu.url))}"/>
            <c:choose>
              <c:when test="${not empty lnbMenu.children}">
                <%-- 그룹(폴더) — 하위 활성 여부 선계산 → 해당 그룹만 기본 펼침 --%>
                <c:set var="grpOpen" value="false"/>
                <c:forEach var="lnbSub" items="${lnbMenu.children}">
                  <c:if test="${not empty lnbSub.url and (rlmsPath == lnbSub.url or fn:startsWith(lnbSub.url, rlmsActiveMenuPrefix) or fn:startsWith(rlmsPath, lnbSub.url))}">
                    <c:set var="grpOpen" value="true"/>
                  </c:if>
                </c:forEach>
                <li class="rlms-lnb-item">
                  <button type="button" class="rlms-lnb-btn" aria-expanded="${grpOpen}">
                    <c:out value="${lnbMenu.menuNm}"/>
                  </button>
                  <ul class="rlms-lnb-sub"<c:if test="${not grpOpen}"> hidden</c:if>>
                    <c:forEach var="lnbSub" items="${lnbMenu.children}">
                      <c:set var="lnbSubActive" value="${not empty lnbSub.url and (rlmsPath == lnbSub.url or fn:startsWith(lnbSub.url, rlmsActiveMenuPrefix) or fn:startsWith(rlmsPath, lnbSub.url))}"/>
                      <li>
                        <a href="<c:url value='${lnbSub.href}'/>" class="rlms-lnb-link ${lnbSubActive ? 'active' : ''}" aria-current="${lnbSubActive ? 'page' : 'false'}"<c:if test="${lnbSub.external}"> target="_blank" rel="noopener"</c:if>>
                          <c:out value="${lnbSub.menuNm}"/>
                        </a>
                      </li>
                    </c:forEach>
                  </ul>
                </li>
              </c:when>
              <c:otherwise>
                <%-- 단일 메뉴(leaf) — 셰브론 없는 링크 행 --%>
                <li class="rlms-lnb-item">
                  <a href="<c:url value='${lnbMenu.href}'/>" class="rlms-lnb-btn rlms-lnb-leaf ${lnbActive ? 'active' : ''}" aria-current="${lnbActive ? 'page' : 'false'}"<c:if test="${lnbMenu.external}"> target="_blank" rel="noopener"</c:if>>
                    <c:out value="${lnbMenu.menuNm}"/>
                  </a>
                </li>
              </c:otherwise>
            </c:choose>
          </c:forEach>
          </ul>
        </nav>
      </aside>
      <script>
      (function () {
        document.querySelectorAll('.rlms-lnb-btn[aria-expanded]').forEach(function (b) {
          b.addEventListener('click', function () {
            var open = b.getAttribute('aria-expanded') === 'true';
            b.setAttribute('aria-expanded', String(!open));
            var sub = b.nextElementSibling;
            if (sub) { sub.hidden = open; }
          });
        });
      })();
      </script>
    </c:if>

    <main class="rlms-admin-main">
      <jsp:doBody/>
    </main>
  </div>

  <%-- KRDS JS (krds.min.js 가 ui-script 를 번들 포함하므로 별도 로드 X) --%>
  <script src="<c:url value='/resources/krds/cdn/krds.min.js'/>"></script>
  <%-- 모바일(≤900) 검색영역 접기 — 화면 JSP 수정 없이 검색바 위에 [검색조건 ▾] 를 만든다(2026-08-06).
       팝업 데코(popup.jsp)에는 싣지 않는다 — 부서조회·파일명검색 등은 검색 자체가 본문이라 접을 대상이 아님. --%>
  <script src="<c:url value='/resources/js/rlms-search-fold.js'/>?v=20260806"></script>
  <%-- 모바일(≤768) 상세 표 → 카드 (소송·의뢰 상세의 5~8열 표) --%>
  <script src="<c:url value='/resources/js/rlms-table-stack.js'/>?v=20260806"></script>

  <%-- 소송비용 계산기 모달 — 헤더 [계산기]에서 상시 호출(2026-08-06 전역 이동).
       ⛔화면 JSP 들의 개별 include 는 제거했다(중복 id/함수 방지). 화면 안 [계산기] 버튼도 이 모달을 연다.
       ⛔.law-modal/.law-modal-back 기본 스타일은 rlms-compat.css 에 있어야 한다 —
         종전엔 화면 JSP 가 각자 정의해서, 그 정의가 없는 화면에 얹히면 모달이 접히지 않고 그대로 노출된다. --%>
  <%@ include file="/WEB-INF/jsp/law/cost/_calcModal.jspf" %>
  <%-- 메가 패널 내용 시작점을 GNB(대메뉴) 시작 위치에 맞춤 (CI/로고 아래가 아니라 첫 메뉴 아래).
       글자크기(body zoom) 변경에도 정렬 유지: rect 차이를 현재 zoom 으로 보정. 글자크기 변경 시 window.rlmsRecalcGnbLeft() 가 호출됨. --%>
  <script>
  (function () {
    function setGnbLeft() {
      var header = document.querySelector('.rlms-header');
      var link = document.querySelector('.rlms-gnb-item .rlms-gnb-link') || document.querySelector('.rlms-gnb');
      if (!header || !link) return;
      <%-- 배율 정본 = window.rlmsZoom(래퍼 zoom 이관 후 body.style.zoom 은 빈값) --%>
      var zoom = window.rlmsZoom || parseFloat(document.body.style.zoom) || 1;
      var rectDiff = link.getBoundingClientRect().left - header.getBoundingClientRect().left;
      var padL = parseFloat(getComputedStyle(link).paddingLeft) || 0;
      header.style.setProperty('--rlms-gnb-left', Math.round(rectDiff / zoom + padL) + 'px');
    }
    window.rlmsRecalcGnbLeft = setGnbLeft;
    if (document.readyState !== 'loading') setGnbLeft();
    else document.addEventListener('DOMContentLoaded', setGnbLeft);
    window.addEventListener('resize', setGnbLeft);
  })();
  </script>
</body>
</html>
