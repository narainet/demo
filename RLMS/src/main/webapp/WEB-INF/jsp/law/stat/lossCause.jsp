<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/stat/lossCause.jsp
  소송통계 ⑥ 패소원인 — LAW_MODULE_DESIGN.md §7.12.
  패소원인(LAW_LOSS_CAUSE)별 건수 + 비율 + SVG 막대. 기간=확정일(DCSN_DT).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">패소원인 통계</c:set>
<c:set var="pageHead">
  
  <style>
    .law-stat-head { display:flex; justify-content:flex-end; gap:6px; margin:8px 0 12px; }
    .law-stat-table td, .law-stat-table th { text-align:center; }
    .law-stat-table td.txt-left { text-align:left; }
    .law-stat-table tr.row-total { background:#f4f6fb; font-weight:700; }
    .law-bar-cell { text-align:left; }
    .law-bar-bg { display:inline-block; vertical-align:middle; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>패소원인 통계</h1>
    <p class="page-desc">확정일 기준 기간 내 패소 사건을 원인별로 집계한 현황입니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/stat/lossCause.do'/>" method="get" class="krds-form search-form">
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
        <th scope="col" style="width:30%;">패소원인</th>
        <th scope="col" style="width:90px;">건수</th>
        <th scope="col" style="width:90px;">비율(%)</th>
        <th scope="col">분포</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${list}" varStatus="st">
        <tr class="${st.first ? 'row-total' : ''}">
          <td class="${st.first ? '' : 'txt-left'}"><c:out value="${row.codeName}"/></td>
          <td><c:out value="${row.cnt}"/></td>
          <td><c:out value="${row.rate}"/></td>
          <td class="law-bar-cell">
            <c:if test="${not st.first}">
              <svg class="law-bar-bg" width="180" height="14" role="img" aria-label="<c:out value='${row.cnt}'/>건">
                <rect x="0" y="0" width="180" height="14" fill="#eef1f7"/>
                <rect x="0" y="0" width="${maxCnt > 0 ? (row.cnt * 180 / maxCnt) : 0}" height="14" fill="#3d5afe"/>
              </svg>
            </c:if>
          </td>
        </tr>
      </c:forEach>
    </tbody>
  </table>

  <script>
  function fnExcel(){
    var f = document.getElementById('searchForm');
    var a = f.getAttribute('action');
    f.setAttribute('action', '<c:url value="/law/stat/lossCauseExcel.do"/>');
    f.submit();
    f.setAttribute('action', a);
  }
  </script>
</lay:layout>
