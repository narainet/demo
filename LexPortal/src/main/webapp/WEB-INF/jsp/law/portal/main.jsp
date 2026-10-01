<%--
  물리적 저장 경로: /WEB-INF/jsp/law/portal/main.jsp

  포탈 공개 메인 (2026-08-04) — 변호사 사무실 홈페이지성 첫 화면. 비로그인 열람 허용.
   - 진입: "/" → /index.do (LawMainController.portal). Globals.law.portalMain=N 이면 이 화면 대신 로그인.
   - 자체 완결 레이아웃(SiteMesh 제외 /index.do*) — 관리자/사용자 데코와 독립. 스타일도 이 파일 안에서 완결.
   - 브랜드(로고·파비콘·시스템명)는 브랜드설정(COM_BRAND) 스냅샷을 그대로 사용.
   - 로그인 상태면 상단에 사용자명 + 업무 바로가기(역할별: 송무 홈/나의 소송의뢰) 노출.

  ★고객사 편집 지점 — 아래 3곳의 문구만 바꾸면 사무실 홈페이지로 완성된다.
    ① 히어로/소개 문구(.lxp-hero, #about)  ② 업무분야 카드(#fields)  ③ 연락처·오시는 길(#contact)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="egovframework.com.uss.ion.brd.service.Brand" %>
<%@ page import="egovframework.com.uss.ion.brd.service.BrandInfo" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    Brand _brand = BrandInfo.get();
    pageContext.setAttribute("brandIsImage", Boolean.valueOf(_brand.isImageLogo()));
    pageContext.setAttribute("brandHasIcon", Boolean.valueOf(_brand.hasFavicon()));
    pageContext.setAttribute("brandVer", BrandInfo.getVersion());
    pageContext.setAttribute("brandText", BrandInfo.getText());
    // 연락처(오시는 길) — 브랜드설정에서 관리(2026-08-04). 빈 항목은 화면에서 숨긴다.
    pageContext.setAttribute("brandCntcAdres", _brand.getCntcAdres());
    pageContext.setAttribute("brandCntcTelno", _brand.getCntcTelno());
    pageContext.setAttribute("brandCntcFxnum", _brand.getCntcFxnum());
    pageContext.setAttribute("brandCntcEmailAdres", _brand.getCntcEmailAdres());
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title><c:out value="${brandText}"/></title>
  <c:choose>
    <c:when test="${brandHasIcon}"><link rel="icon" href="<c:url value='/cmm/brand/favicon.do'/>?v=${brandVer}"/></c:when>
    <c:otherwise><link rel="icon" type="image/svg+xml" href="<c:url value='/resources/img/favicon.svg'/>"/></c:otherwise>
  </c:choose>
  <%-- KRDS 번들은 폰트(PretendardGOV)·리셋 용도로만 — 레이아웃은 아래 lxp-* 에서 완결 --%>
  <link rel="stylesheet" href="<c:url value='/resources/krds/cdn/krds.min.css'/>"/>
  <style>
    :root {
      --lxp-navy: #1f3974;
      --lxp-navy-deep: #16295a;
      --lxp-blue: #2f5cc9;
      --lxp-ink: #1e2124;
      --lxp-sub: #52617a;
      --lxp-line: #dfe3ec;
      --lxp-bg: #f6f8fc;
    }
    html { scroll-behavior: smooth; }
    body.lxp { margin: 0; color: var(--lxp-ink); background: #fff; word-break: keep-all; }
    .lxp a { text-decoration: none; color: inherit; }
    .lxp-inner { max-width: 1120px; margin: 0 auto; padding: 0 24px; }

    /* ── 상단 바 ── */
    .lxp-top { position: sticky; top: 0; z-index: 50; background: rgba(255,255,255,.94); backdrop-filter: blur(6px); border-bottom: 1px solid var(--lxp-line); }
    .lxp-top-in { display: flex; align-items: center; gap: 28px; height: 64px; }
    .lxp-logo { display: flex; align-items: center; font-size: 19px; font-weight: 800; color: var(--lxp-navy); white-space: nowrap; }
    .lxp-logo img { max-height: 34px; }
    .lxp-nav { display: flex; gap: 4px; margin-left: 8px; }
    .lxp-nav a { padding: 8px 14px; border-radius: 8px; font-size: 15px; font-weight: 600; color: #3a445a; }
    .lxp-nav a:hover { background: #eef2fa; color: var(--lxp-navy); }
    .lxp-top-act { margin-left: auto; display: flex; align-items: center; gap: 10px; }
    .lxp-user { font-size: 14px; color: var(--lxp-sub); }
    .lxp-btn { display: inline-flex; align-items: center; justify-content: center; height: 40px; padding: 0 18px; border-radius: 8px; font-size: 14.5px; font-weight: 700; border: 1px solid transparent; cursor: pointer; }
    .lxp-btn.line { border-color: #c3cbdd; color: #333d4b; background: #fff; }
    .lxp-btn.line:hover { border-color: var(--lxp-navy); color: var(--lxp-navy); }
    .lxp-btn.fill { background: var(--lxp-navy); color: #fff; }
    .lxp-btn.fill:hover { background: var(--lxp-navy-deep); }
    .lxp-btn.big { height: 50px; padding: 0 26px; font-size: 16px; }
    .lxp-btn.ghost { border-color: rgba(255,255,255,.55); color: #fff; }
    .lxp-btn.ghost:hover { background: rgba(255,255,255,.12); }
    .lxp-btn.white { background: #fff; color: var(--lxp-navy); }
    .lxp-btn.white:hover { background: #e8edf9; }

    /* ── 히어로 (★편집 지점 ①: 대표 문구) ── */
    .lxp-hero { background: linear-gradient(135deg, var(--lxp-navy-deep) 0%, var(--lxp-navy) 55%, #2b4a97 100%); color: #fff; }
    .lxp-hero-in { padding: 88px 24px 84px; }
    .lxp-hero-badge { display: inline-block; padding: 6px 14px; border: 1px solid rgba(255,255,255,.4); border-radius: 999px; font-size: 13px; letter-spacing: .04em; color: #dfe7ff; margin-bottom: 22px; }
    .lxp-hero h1 { margin: 0 0 16px; font-size: 42px; line-height: 1.25; letter-spacing: -0.01em; }
    .lxp-hero p { margin: 0 0 34px; font-size: 18px; line-height: 1.7; color: #d8e0f5; max-width: 640px; }
    .lxp-hero-cta { display: flex; gap: 12px; flex-wrap: wrap; }

    /* ── 공통 섹션 ── */
    .lxp-sec { padding: 76px 0; }
    .lxp-sec.alt { background: var(--lxp-bg); }
    .lxp-sec-tit { margin: 0 0 10px; font-size: 30px; color: var(--lxp-ink); text-align: center; }
    .lxp-sec-sub { margin: 0 auto 44px; font-size: 16px; color: var(--lxp-sub); text-align: center; max-width: 620px; line-height: 1.7; }

    /* 소개 3특징 */
    .lxp-feat { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
    .lxp-feat-card { background: #fff; border: 1px solid var(--lxp-line); border-radius: 14px; padding: 30px 26px; }
    .lxp-feat-card .num { display: inline-flex; align-items: center; justify-content: center; width: 40px; height: 40px; border-radius: 10px; background: #e8edf9; color: var(--lxp-navy); font-weight: 800; font-size: 17px; margin-bottom: 16px; }
    .lxp-feat-card h3 { margin: 0 0 8px; font-size: 18.5px; }
    .lxp-feat-card p { margin: 0; color: var(--lxp-sub); font-size: 15px; line-height: 1.7; }

    /* 업무분야 (★편집 지점 ②) */
    .lxp-fields { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }
    .lxp-field { background: #fff; border: 1px solid var(--lxp-line); border-left: 4px solid var(--lxp-navy); border-radius: 12px; padding: 24px 22px; transition: box-shadow .15s, transform .15s; }
    .lxp-field:hover { box-shadow: 0 10px 24px rgba(31,57,116,.10); transform: translateY(-2px); }
    .lxp-field h3 { margin: 0 0 8px; font-size: 17.5px; color: var(--lxp-navy); }
    .lxp-field p { margin: 0; font-size: 14.5px; color: var(--lxp-sub); line-height: 1.65; }

    /* 이용 안내 */
    .lxp-steps { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; counter-reset: step; margin-bottom: 26px; }
    .lxp-step { position: relative; background: #fff; border: 1px solid var(--lxp-line); border-radius: 14px; padding: 28px 24px 24px; }
    .lxp-step::before { counter-increment: step; content: counter(step); position: absolute; top: -16px; left: 22px; width: 34px; height: 34px; border-radius: 50%; background: var(--lxp-navy); color: #fff; font-weight: 800; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 10px rgba(31,57,116,.28); }
    .lxp-step h3 { margin: 6px 0 8px; font-size: 17px; }
    .lxp-step p { margin: 0; font-size: 14.5px; color: var(--lxp-sub); line-height: 1.65; }
    .lxp-guide-note { background: #eef2fa; border: 1px solid #d4ddf0; border-radius: 12px; padding: 18px 22px; font-size: 14.5px; color: #33405e; line-height: 1.7; }
    .lxp-guide-note strong { color: var(--lxp-navy); }

    /* 오시는 길 (★편집 지점 ③) */
    .lxp-contact { display: grid; grid-template-columns: 1.1fr .9fr; gap: 20px; }
    .lxp-contact-card { background: #fff; border: 1px solid var(--lxp-line); border-radius: 14px; padding: 28px 26px; }
    .lxp-contact-card h3 { margin: 0 0 16px; font-size: 18px; color: var(--lxp-navy); }
    .lxp-contact-row { display: flex; gap: 12px; padding: 9px 0; border-bottom: 1px solid #eef1f6; font-size: 15px; }
    .lxp-contact-row:last-child { border-bottom: none; }
    .lxp-contact-row .k { flex: 0 0 76px; color: var(--lxp-sub); font-weight: 700; }
    .lxp-cta-band { margin-top: 60px; background: var(--lxp-navy); border-radius: 18px; color: #fff; padding: 40px 36px; display: flex; align-items: center; justify-content: space-between; gap: 20px; flex-wrap: wrap; }
    .lxp-cta-band h3 { margin: 0 0 6px; font-size: 22px; }
    .lxp-cta-band p { margin: 0; color: #ccd7f2; font-size: 15px; }

    /* 푸터 */
    .lxp-foot { border-top: 1px solid var(--lxp-line); padding: 26px 0 34px; color: #7a869c; font-size: 13.5px; }
    .lxp-foot-in { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
    .lxp-foot a { color: #5c6a85; }
    .lxp-foot a:hover { color: var(--lxp-navy); }

    /* ── 반응형 ── */
    @media (max-width: 960px) {
      .lxp-nav { display: none; }              /* 앵커 내비 — 한 화면 스크롤 페이지라 모바일은 생략 */
      .lxp-hero h1 { font-size: 32px; }
      .lxp-hero-in { padding: 64px 24px 60px; }
      .lxp-feat, .lxp-fields, .lxp-steps { grid-template-columns: repeat(2, 1fr); }
      .lxp-contact { grid-template-columns: 1fr; }
      .lxp-sec { padding: 56px 0; }
    }
    @media (max-width: 620px) {
      .lxp-inner { padding: 0 16px; }
      .lxp-top-in { gap: 12px; }
      .lxp-user { display: none; }
      .lxp-hero h1 { font-size: 26px; }
      .lxp-hero p { font-size: 15.5px; }
      .lxp-hero-in { padding: 48px 16px 46px; }
      .lxp-sec-tit { font-size: 24px; }
      .lxp-feat, .lxp-fields { grid-template-columns: 1fr; }
      .lxp-steps { grid-template-columns: 1fr; gap: 26px; }
      .lxp-btn.big { height: 46px; padding: 0 20px; font-size: 15px; }
      .lxp-cta-band { padding: 28px 22px; }
    }
  </style>
</head>
<body class="lxp">

  <%-- ── 상단 바 ── --%>
  <header class="lxp-top">
    <div class="lxp-inner lxp-top-in">
      <a class="lxp-logo" href="<c:url value='/index.do'/>">
        <c:choose>
          <c:when test="${brandIsImage}"><img src="<c:url value='/cmm/brand/logo.do'/>?v=${brandVer}" alt="<c:out value='${brandText}'/>"/></c:when>
          <c:otherwise><c:out value="${brandText}"/></c:otherwise>
        </c:choose>
      </a>
      <nav class="lxp-nav" aria-label="포탈 메뉴">
        <a href="#about">사무실 소개</a>
        <a href="#fields">업무분야</a>
        <a href="#guide">이용 안내</a>
        <a href="#contact">오시는 길</a>
      </nav>
      <div class="lxp-top-act">
        <c:choose>
          <c:when test="${portalAuth}">
            <span class="lxp-user"><c:out value="${portalUserName}"/> 님</span>
            <a class="lxp-btn fill" href="<c:url value='${portalWorkUrl}'/>"><c:out value="${portalWorkLabel}"/></a>
            <a class="lxp-btn line" href="<c:url value='/uat/uia/actionLogout.do'/>">로그아웃</a>
          </c:when>
          <c:otherwise>
            <a class="lxp-btn fill" href="<c:url value='/uat/uia/egovLoginUsr.do'/>">로그인</a>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </header>

  <%-- ── 히어로 (★편집 지점 ①: 사무실 대표 문구) ── --%>
  <section class="lxp-hero">
    <div class="lxp-inner lxp-hero-in">
      <span class="lxp-hero-badge">LITIGATION MANAGEMENT PORTAL</span>
      <h1><c:out value="${brandText}"/></h1>
      <p>소송 사건의 의뢰부터 진행·종결까지 한 곳에서 투명하게 관리합니다.<br/>
         의뢰인은 온라인으로 소송을 의뢰하고, 사건 진행 상황을 언제든 확인할 수 있습니다.</p>
      <div class="lxp-hero-cta">
        <a class="lxp-btn big white" href="#guide">소송의뢰 안내</a>
        <c:choose>
          <c:when test="${portalAuth}"><a class="lxp-btn big ghost" href="<c:url value='${portalWorkUrl}'/>"><c:out value="${portalWorkLabel}"/> 바로가기</a></c:when>
          <c:otherwise><a class="lxp-btn big ghost" href="<c:url value='/uat/uia/egovLoginUsr.do'/>">업무시스템 로그인</a></c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>

  <%-- ── 사무실 소개 ── --%>
  <section class="lxp-sec" id="about">
    <div class="lxp-inner">
      <h2 class="lxp-sec-tit">사무실 소개</h2>
      <p class="lxp-sec-sub">오랜 소송 수행 경험과 체계적인 사건 관리로 의뢰인의 권리를 지킵니다.
         모든 사건은 전담 담당자가 접수부터 종결까지 책임지고 관리합니다.</p>
      <div class="lxp-feat">
        <div class="lxp-feat-card">
          <span class="num">01</span>
          <h3>분야별 전문성</h3>
          <p>민사·형사·행정·가사 등 분야별 전문 인력이 사건을 검토하고 최적의 수행 전략을 세웁니다.</p>
        </div>
        <div class="lxp-feat-card">
          <span class="num">02</span>
          <h3>신속한 대응</h3>
          <p>기일·서류 접수·보전처분까지 일정 기반으로 관리되어 놓치는 절차 없이 신속하게 대응합니다.</p>
        </div>
        <div class="lxp-feat-card">
          <span class="num">03</span>
          <h3>투명한 진행 공유</h3>
          <p>의뢰하신 사건의 진행 단계가 온라인으로 공유되어 언제든 현재 상태를 확인할 수 있습니다.</p>
        </div>
      </div>
    </div>
  </section>

  <%-- ── 업무분야 (★편집 지점 ②: 카드 구성·문구) ── --%>
  <section class="lxp-sec alt" id="fields">
    <div class="lxp-inner">
      <h2 class="lxp-sec-tit">업무분야</h2>
      <p class="lxp-sec-sub">소송 전 검토부터 판결 이후 집행까지, 분쟁 해결의 전 과정을 수행합니다.</p>
      <div class="lxp-fields">
        <div class="lxp-field"><h3>민사소송</h3><p>대여금·손해배상·계약분쟁·부동산 등 민사 전반의 소송 수행과 분쟁 해결</p></div>
        <div class="lxp-field"><h3>형사소송</h3><p>고소·고발 대리, 피의자·피고인 변호와 수사 단계 대응</p></div>
        <div class="lxp-field"><h3>행정소송</h3><p>행정처분 취소·무효 확인, 행정심판과 각종 인허가 분쟁 대응</p></div>
        <div class="lxp-field"><h3>가사소송</h3><p>이혼·상속·양육권 등 가사 사건의 소송과 조정 절차 수행</p></div>
        <div class="lxp-field"><h3>보전처분·강제집행</h3><p>가압류·가처분 신청과 판결 이후 채권 회수를 위한 집행 절차</p></div>
        <div class="lxp-field"><h3>기업 법률자문</h3><p>계약 검토, 분쟁 예방 자문과 기업 소송의 상시 대응</p></div>
      </div>
    </div>
  </section>

  <%-- ── 이용 안내 ── --%>
  <section class="lxp-sec" id="guide">
    <div class="lxp-inner">
      <h2 class="lxp-sec-tit">이용 안내</h2>
      <p class="lxp-sec-sub">의뢰인은 계정 발급 후 온라인으로 소송을 의뢰하고 진행 상황을 확인할 수 있습니다.</p>
      <div class="lxp-steps">
        <div class="lxp-step">
          <h3>계정 발급 · 로그인</h3>
          <p>사무실로 연락해 의뢰인 계정을 발급받고, 우측 상단 로그인으로 접속합니다.</p>
        </div>
        <div class="lxp-step">
          <h3>소송의뢰 신청</h3>
          <p>사건 개요와 관련 자료를 첨부해 온라인으로 소송의뢰를 신청합니다.</p>
        </div>
        <div class="lxp-step">
          <h3>진행 확인 · 결과 통지</h3>
          <p>담당자 검토·승인 후 사건으로 등록되며, 진행 단계를 온라인으로 확인합니다.</p>
        </div>
      </div>
      <div class="lxp-guide-note">
        <strong>임직원·송무 담당자</strong>는 부여받은 계정으로 로그인하면 사건·일정·문서·비용까지
        송무 업무 전반을 관리하는 업무시스템으로 연결됩니다.
      </div>
    </div>
  </section>

  <%-- ── 오시는 길 — 연락처는 관리자 > 브랜드설정에서 관리(COM_BRAND, 2026-08-04). 빈 항목은 숨김 ── --%>
  <section class="lxp-sec alt" id="contact">
    <div class="lxp-inner">
      <h2 class="lxp-sec-tit">오시는 길</h2>
      <p class="lxp-sec-sub">상담 예약 후 방문해 주시면 더 정확한 안내를 받으실 수 있습니다.</p>
      <c:set var="hasCntc" value="${not empty brandCntcAdres or not empty brandCntcTelno or not empty brandCntcFxnum or not empty brandCntcEmailAdres}"/>
      <div class="lxp-contact">
        <c:if test="${hasCntc}">
        <div class="lxp-contact-card">
          <h3>연락처</h3>
          <c:if test="${not empty brandCntcAdres}"><div class="lxp-contact-row"><span class="k">주소</span><span><c:out value="${brandCntcAdres}"/></span></div></c:if>
          <c:if test="${not empty brandCntcTelno}"><div class="lxp-contact-row"><span class="k">대표전화</span><span><c:out value="${brandCntcTelno}"/></span></div></c:if>
          <c:if test="${not empty brandCntcFxnum}"><div class="lxp-contact-row"><span class="k">팩스</span><span><c:out value="${brandCntcFxnum}"/></span></div></c:if>
          <c:if test="${not empty brandCntcEmailAdres}"><div class="lxp-contact-row"><span class="k">이메일</span><span><c:out value="${brandCntcEmailAdres}"/></span></div></c:if>
        </div>
        </c:if>
        <div class="lxp-contact-card">
          <h3>업무시간</h3>
          <div class="lxp-contact-row"><span class="k">평일</span><span>09:00 ~ 18:00</span></div>
          <div class="lxp-contact-row"><span class="k">점심시간</span><span>12:00 ~ 13:00</span></div>
          <div class="lxp-contact-row"><span class="k">주말·공휴일</span><span>휴무 (긴급 사건은 유선 문의)</span></div>
        </div>
      </div>
      <div class="lxp-cta-band">
        <div>
          <h3>소송, 혼자 고민하지 마세요</h3>
          <p>계정을 발급받으면 온라인으로 간편하게 소송을 의뢰할 수 있습니다.</p>
        </div>
        <c:choose>
          <c:when test="${portalAuth}"><a class="lxp-btn big white" href="<c:url value='${portalWorkUrl}'/>"><c:out value="${portalWorkLabel}"/></a></c:when>
          <c:otherwise><a class="lxp-btn big white" href="<c:url value='/uat/uia/egovLoginUsr.do'/>">로그인하고 의뢰하기</a></c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>

  <%-- ── 푸터 ── --%>
  <footer class="lxp-foot">
    <div class="lxp-inner lxp-foot-in">
      <span>&copy; <c:out value="${brandText}"/>. All rights reserved.</span>
      <a href="<c:url value='/uat/uia/egovLoginUsr.do'/>">업무시스템 로그인</a>
    </div>
  </footer>

</body>
</html>
