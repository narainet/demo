<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/tags/shell/popup.tag

  팝업/iframe/검색 dialog 전용 레이아웃 셸(JSP 태그파일).
   - GNB 헤더 / 사이드 / 푸터 모두 없음 (부모 창에 이미 헤더가 있어 중복 방지)
   - KRDS CSS + rlms-compat.css 만 적용해서 톤은 본 화면과 동일
   - 대상: 파일명 검색 popup, 메뉴이동 dialog, 사용자 선택 popup,
           템플릿 미리보기, 즐겨찾기 popup 등
--%>
<%@ tag pageEncoding="UTF-8" body-content="scriptless"
        description="팝업/iframe/dialog 셸 — 헤더 없이 본문만(KRDS 톤 유지)" %>
<%@ attribute name="title"      required="false" description="브라우저 탭 제목. 비면 브랜드 문구." %>
<%@ attribute name="head"       required="false" description="페이지 고유 head 조각(link/script/style)을 담은 문자열." %>
<%@ attribute name="bodyOnload" required="false" description="페이지의 body onload 값." %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>${empty title ? '팝업' : title}</title>

  <%-- KRDS 디자인 시스템 (헤더는 안 그리지만 톤은 동일) --%>
  <link rel="icon" type="image/svg+xml" href="<c:url value='/resources/img/favicon.svg'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/cdn/krds.min.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/token/krds_tokens.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/common/common.css'/>"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/component/component.css'/>?v=20260728a"/>
  <link rel="stylesheet" href="<c:url value='/resources/krds/css/rlms-compat.css'/>?v=20260806-calc"/>

  ${head}
  <style>
    .rlms-popup-body {
      margin: 0;
      background: #f4f6fb;
      color: #1d1d1d;
      font-family: "Noto Sans KR", "Malgun Gothic", Arial, sans-serif;
    }
    .rlms-popup-main {
      min-height: calc(100vh / var(--rlms-zoom, 1));
      padding: 20px;
      box-sizing: border-box;
      background: #f4f6fb;
    }
    .rlms-popup-body .popup {
      width: 100% !important;
      max-width: none !important;
      margin: 0 !important;
      padding: 0 !important;
      border: 0 !important;
      background: transparent !important;
      box-sizing: border-box;
    }
    .rlms-popup-body .popup h1 {
      display: flex;
      align-items: center;
      min-height: 42px;
      margin: 0 0 16px !important;
      padding: 0 0 12px !important;
      border: 0 !important;
      border-bottom: 1px solid #d8dde8 !important;
      background: transparent !important;
      color: #1f3974 !important;
      font-size: 22px !important;
      font-weight: 700 !important;
      line-height: 1.35 !important;
    }
    .rlms-popup-body .popwTable {
      width: 100% !important;
      margin: 0 !important;
      border-collapse: collapse !important;
      border-top: 2px solid #1f3974 !important;
      border-bottom: 1px solid #d1d3d8 !important;
      background: #fff !important;
      table-layout: fixed;
      box-sizing: border-box;
    }
    .rlms-popup-body .popwTable caption {
      position: absolute;
      overflow: hidden;
      width: 1px;
      height: 1px;
      margin: -1px;
      padding: 0;
      clip: rect(0 0 0 0);
      white-space: nowrap;
      border: 0;
    }
    .rlms-popup-body .popwTable th,
    .rlms-popup-body .popwTable td {
      height: 42px !important;
      padding: 10px 12px !important;
      border: 1px solid #d8dde8 !important;
      border-left: 0 !important;
      border-right: 0 !important;
      box-sizing: border-box;
      color: #1d1d1d !important;
      font-size: 14px !important;
      line-height: 1.5 !important;
      vertical-align: middle !important;
      word-break: break-word;
    }
    .rlms-popup-body .popwTable th {
      width: 170px !important;
      background: #f4f6fb !important;
      color: #1f3974 !important;
      font-weight: 700 !important;
      text-align: left !important;
    }
    .rlms-popup-body .popwTable td {
      background: #fff !important;
      text-align: left !important;
    }
    .rlms-popup-body .btn {
      display: flex !important;
      justify-content: flex-end !important;
      gap: 8px;
      margin: 16px 0 0 !important;
      padding: 0 !important;
      border: 0 !important;
      background: transparent !important;
    }
    .rlms-popup-body .btn .btn_style3,
    .rlms-popup-body .btn button {
      display: inline-flex !important;
      align-items: center !important;
      justify-content: center !important;
      min-width: 72px !important;
      height: 40px !important;
      padding: 0 16px !important;
      border: 0 !important;
      border-radius: 0 !important;
      background: #246beb !important;
      color: #fff !important;
      font-size: 14px !important;
      font-weight: 600 !important;
      line-height: 1 !important;
      cursor: pointer !important;
    }
    .rlms-popup-body .btn .btn_style3:hover,
    .rlms-popup-body .btn button:hover {
      background: #1d56bd !important;
    }
  </style>
</head>
<%-- 페이지의 <body onload> 왕복 — 상세 설명은 mgr.jsp 동일 위치 주석 참조.
     ⛔ class 는 반드시 유지할 것: 위 인라인 스타일 전부가 .rlms-popup-body 스코프다. --%>
<body class="rlms-popup-body"<c:if test="${not empty bodyOnload}"> onload="${bodyOnload}"</c:if>>
  <main class="rlms-popup-main">
    <jsp:doBody/>
  </main>

  <script src="<c:url value='/resources/krds/cdn/krds.min.js'/>"></script>
</body>
</html>
