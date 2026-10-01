<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/tags/layout.tag

  화면 레이아웃 디스패처 — 모든 화면 JSP 가 이 태그 하나로 감싸진다.
  요청 URL 에 맞는 셸(/WEB-INF/tags/shell/*.tag)을 골라 본문을 그 안에 넣는다.

  ※ 2026-08-07 SiteMesh 2 제거로 도입. SiteMesh 는 "응답을 버퍼에 받아 파싱 → 데코레이터로 forward"
    구조라 Servlet 6.0(Tomcat 10.1+)에서 응답이 빈 채 커밋된다(2026-08-06 실측, 전 버전 동일).
    태그파일은 버퍼링도 dispatch 도 없이 본문을 제자리에 흘려보내므로 그 실패 모드가 성립하지 않는다.

  사용법 (화면 JSP):
      <%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
      <c:set var="pageTitle">규정 목록</c:set>
      <c:set var="pageHead">
        <link rel="stylesheet" href="..."/>
      </c:set>
      <lay:layout title="${pageTitle}" head="${pageHead}">
        ...본문...
      </lay:layout>

  속성:
    title      브라우저 탭 제목. 비면 셸이 브랜드 문구로 대체.
    head       페이지 고유 head 조각(link/script/style). 문자열로 넘긴다.
    bodyOnload 페이지의 body onload 값.
    name       셸 강제 지정("mgr"/"front"/"plain"/"popup"). 비우면 URL 매핑(WEB-INF/layouts.xml)으로 결정.
               ⛔ 같은 JSP 가 관리자/사용자 두 동선에서 모두 쓰이는 경우가 있어(예: /cop/bbs/* 와
                  /cop/bbs/user/*) 기본은 URL 매핑이다. name 은 정말 고정인 화면에만 쓸 것.

  ⛔ 본문(body-content)은 scriptless — 태그 안쪽엔 <% %> / <%= %> 를 못 쓴다.
     필요하면 <lay:layout> 여는 태그 "앞"에서 값을 만들어 두고 본문에선 EL 로 참조할 것.
--%>
<%@ tag pageEncoding="UTF-8" body-content="scriptless"
        description="요청 URL 에 맞는 레이아웃 셸로 본문을 감싼다." %>
<%@ attribute name="title"      required="false" description="브라우저 탭 제목. 비면 브랜드 문구." %>
<%@ attribute name="head"       required="false" description="페이지 고유 head 조각(link/script/style)을 담은 문자열." %>
<%@ attribute name="bodyOnload" required="false" description="페이지의 body onload 값." %>
<%@ attribute name="name"       required="false" description="셸 강제 지정. 비우면 layouts.xml 의 URL 매핑으로 결정." %>
<%@ tag import="egovframework.com.cmm.util.EgovLayoutResolver" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib tagdir="/WEB-INF/tags/shell" prefix="shell" %>
<%
    // ⛔ 다른 화면이 c:import / jsp:include 로 이 화면을 끌어 쓰는 중이면 셸을 씌우면 안 된다.
    //    (예: /cmm/fms/selectFileInfs.do, /sym/mnu/mcm/EgovMenuCreatSiteMapSelect.do)
    //    씌우면 페이지 한가운데에 <html><head> 통짜 문서가 박힌다.
    //    SiteMesh 도 필터가 REQUEST 전용이라 include 는 데코레이트하지 않았다 — 동일 규칙.
    boolean _included = request.getAttribute("javax.servlet.include.request_uri") != null;
    String _forced = (String) jspContext.getAttribute("name");
    jspContext.setAttribute("layShell",
        _included ? "none"
            : (_forced != null && _forced.trim().length() > 0)
                ? _forced.trim()
                : EgovLayoutResolver.resolve(request));
%><c:choose>
  <c:when test="${layShell eq 'none'}"><jsp:doBody/></c:when>
  <c:when test="${layShell eq 'mgr'}"
    ><shell:mgr   title="${title}" head="${head}" bodyOnload="${bodyOnload}"><jsp:doBody/></shell:mgr></c:when>
  <c:when test="${layShell eq 'front'}"
    ><shell:front title="${title}" head="${head}" bodyOnload="${bodyOnload}"><jsp:doBody/></shell:front></c:when>
  <c:when test="${layShell eq 'popup'}"
    ><shell:popup title="${title}" head="${head}" bodyOnload="${bodyOnload}"><jsp:doBody/></shell:popup></c:when>
  <c:otherwise
    ><shell:plain title="${title}" head="${head}" bodyOnload="${bodyOnload}"><jsp:doBody/></shell:plain></c:otherwise>
</c:choose>
