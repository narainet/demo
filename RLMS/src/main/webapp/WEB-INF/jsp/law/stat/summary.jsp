<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/stat/summary.jsp
  소송통계 ① 소송현황 — LAW_MODULE_DESIGN.md §7.12.
  구분(계/민사/행정/국가/심판) × 발생건수 / 확정·종결(계·승·패·승소율) / 계류.
  기간: 발생=소제기일(FR_DT), 종결=확정일(DCSN_DT), 계류=진행중 스냅샷.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송통계</c:set>
<c:set var="pageHead">
  
  <style>
    .law-stat-head { display:flex; justify-content:flex-end; gap:6px; margin:8px 0 12px; }
    .law-stat-table td, .law-stat-table th { text-align:center; }
    .law-stat-table tr.row-total { background:#f4f6fb; font-weight:700; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>소송통계</h1>
    <p class="page-desc">구분별 발생·확정/종결(승소율)·계류 현황입니다. 발생=소제기일, 종결=확정일 기준입니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/stat/summary.do'/>" method="get" class="krds-form search-form">
    <div class="form-group inline">
      <label class="form-label" for="fromDate">기간</label>
      <div class="form-conts">
        <input type="date" id="fromDate" name="fromDate" class="krds-input" value="<c:out value='${fromDate}'/>"/>
        <span>~</span>
        <input type="date" id="toDate" name="toDate" class="krds-input" value="<c:out value='${toDate}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">조회</button>
    </div>
  </form>

  <div class="law-stat-head">
    <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀 다운로드</button>
  </div>

  <table class="krds-table tbl-list law-stat-table">
    <thead>
      <tr>
        <th scope="col" rowspan="2">구분</th>
        <th scope="col" rowspan="2">발생건수</th>
        <th scope="col" colspan="4">확정·종결 건수</th>
        <th scope="col" rowspan="2">계류</th>
      </tr>
      <tr>
        <th scope="col">계</th>
        <th scope="col">승소</th>
        <th scope="col">패소</th>
        <th scope="col">승소율(%)</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${rows}" varStatus="st">
        <tr class="${st.first ? 'row-total' : ''}">
          <td><c:out value="${row.name}"/></td>
          <td><c:out value="${row.occurrenceCnt}"/></td>
          <td><c:out value="${row.totalCnt}"/></td>
          <td><c:out value="${row.winCnt}"/></td>
          <td><c:out value="${row.loseCnt}"/></td>
          <td><c:out value="${row.rate}"/></td>
          <td><c:out value="${row.processingCnt}"/></td>
        </tr>
      </c:forEach>
    </tbody>
  </table>

  <script>
  function fnExcel(){
    var f = document.getElementById('searchForm');
    var a = f.getAttribute('action');
    f.setAttribute('action', '<c:url value="/law/stat/summaryExcel.do"/>');
    f.submit();
    f.setAttribute('action', a);
  }
  </script>
</lay:layout>
