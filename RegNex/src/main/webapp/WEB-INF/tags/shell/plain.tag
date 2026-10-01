<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/tags/shell/plain.tag

  단순 화면 레이아웃 셸(JSP 태그파일) — 로그인, 에러 페이지 등.
   - 헤더/사이드 없이 중앙 단일 컬럼
   - KRDS CSS 만 적용 (브랜딩 통일)
--%>
<%@ tag pageEncoding="UTF-8" body-content="scriptless"
        description="단순 화면 셸 — 로그인/에러 등 중앙 단일 컬럼 카드" %>
<%@ attribute name="title"      required="false" description="브라우저 탭 제목. 비면 브랜드 문구." %>
<%@ attribute name="head"       required="false" description="페이지 고유 head 조각(link/script/style)을 담은 문자열." %>
<%@ attribute name="bodyOnload" required="false" description="페이지의 body onload 값." %>
<%@ tag import="egovframework.com.uss.ion.brd.service.Brand" %>
<%@ tag import="egovframework.com.uss.ion.brd.service.BrandInfo" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // 브랜드(로고·파비콘) — 관리자 > 브랜드설정 화면에서 지정. 기동 시 적재된 캐시라 DB 를 치지 않는다.
    // EL 메서드 호출(EL 3.0)에 의존하지 않도록 판정 결과를 속성으로 미리 담는다.
    Brand _brand = BrandInfo.get();
    String _brandText = _brand.getLogoText();
    jspContext.setAttribute("brandIsImage",   Boolean.valueOf(_brand.isImageLogo()));
    jspContext.setAttribute("brandHasIcon",   Boolean.valueOf(_brand.hasFavicon()));
    jspContext.setAttribute("brandVer",       BrandInfo.getVersion());
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
  <title>${empty title ? brandText : title}</title>

  <%-- 파비콘 — 브랜드설정에 업로드한 것이 있으면 그것, 없으면 기본 아이콘 --%>
  <c:choose>
    <c:when test="${brandHasIcon}"><link rel="icon" href="<c:url value='/cmm/brand/favicon.do'/>?v=${brandVer}"/></c:when>
    <c:otherwise><link rel="icon" type="image/svg+xml" href="<c:url value='/resources/img/favicon.svg'/>"/></c:otherwise>
  </c:choose>
  <link rel="stylesheet" href="<c:url value='/resources/krds/cdn/krds.min.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/token/krds_tokens.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/common/common.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/component/component.css'/>?v=20260728a"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/rlms-compat.css'/>?v=20260804-fresp5"/>

  ${head}

  <%-- 레이아웃 CSS 는 rlms-compat.css 에서 통일 관리 --%>
</head>
<%-- 페이지의 <body onload> 왕복 — 상세 설명은 mgr.jsp 동일 위치 주석 참조. --%>
<body<c:if test="${not empty bodyOnload}"> onload="${bodyOnload}"</c:if>>
  <div class="rlms-plain-wrap">
    <div class="rlms-plain-card">
      <div class="rlms-plain-brand">
        <c:choose>
          <c:when test="${brandIsImage}"><img class="rlms-brand-img" src="<c:url value='/cmm/brand/logo.do'/>?v=${brandVer}" alt="<c:out value='${brandText}'/>"<c:if test="${not empty brandRawText}"> title="<c:out value='${brandRawText}'/>"</c:if>/></c:when>
          <c:otherwise><c:out value="${brandText}"/></c:otherwise>
        </c:choose>
      </div>
      <jsp:doBody/>
    </div>
  </div>

  <script src="<c:url value='/resources/krds/cdn/krds.min.js'/>"></script>
</body>
</html>
