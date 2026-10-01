<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/stat/instance.jsp
  소송통계 ② 심급별 — LAW_MODULE_DESIGN.md §7.12.
  심급(합계/1심/2심/3심) × 진행중(계류) 구분별. 계류 스냅샷.
  기간(옵션)=소제기일 FR_DT 필터, 빈값=전체 (2026-07-27).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">심급별 통계</c:set>
<c:set var="pageHead">
  
  <style>
    .law-stat-head { display:flex; justify-content:flex-end; gap:6px; margin:8px 0 12px; }
    .law-stat-table td, .law-stat-table th { text-align:center; }
    .law-stat-table tr.row-total { background:#f4f6fb; font-weight:700; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>심급별 통계</h1>
    <p class="page-desc">진행 중(계류) 사건을 심급·구분별로 집계한 현황입니다. 기간을 입력하면 소제기일 기준으로 추려 봅니다(빈값=전체).</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/stat/instance.do'/>" method="get" class="krds-form search-form">
    <div class="form-group inline">
      <label class="form-label" for="fromDate">기간(소제기일)</label>
      <div class="form-conts">
        <input type="date" id="fromDate" name="fromDate" class="krds-input" value="<c:out value='${fromDate}'/>"/>
        <span>~</span>
        <input type="date" id="toDate" name="toDate" class="krds-input" aria-label="기간(종료)" value="<c:out value='${toDate}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">조회</button>
      <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/stat/instance.do"/>';">전체</button>
    </div>
  </form>

  <div class="law-stat-head">
    <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀 다운로드</button>
  </div>

  <table class="krds-table tbl-list law-stat-table">
    <thead>
      <tr>
        <th scope="col" rowspan="2">심급</th>
        <th scope="col" colspan="5">진행중(계류)</th>
      </tr>
      <tr>
        <th scope="col">계</th>
        <th scope="col">민사</th>
        <th scope="col">행정</th>
        <th scope="col">국가</th>
        <th scope="col">심판</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${rows}" varStatus="st">
        <tr class="${st.first ? 'row-total' : ''}">
          <td><c:out value="${row.name}"/></td>
          <td><c:out value="${row.totCnt}"/></td>
          <td><c:out value="${row.minsaCnt}"/></td>
          <td><c:out value="${row.hangjungCnt}"/></td>
          <td><c:out value="${row.kukgaCnt}"/></td>
          <td><c:out value="${row.simpanCnt}"/></td>
        </tr>
      </c:forEach>
    </tbody>
  </table>

  <script>
  <%-- 엑셀 = 현재 기간 조건 그대로 (summary 패턴) --%>
  function fnExcel(){
    var f = document.getElementById('searchForm');
    var a = f.getAttribute('action');
    f.setAttribute('action', '<c:url value="/law/stat/instanceExcel.do"/>');
    f.submit();
    f.setAttribute('action', a);
  }
  </script>
</lay:layout>
