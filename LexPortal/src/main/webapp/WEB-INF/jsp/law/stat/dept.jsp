<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/stat/dept.jsp
  소송통계 ④ 부서별 — LAW_MODULE_DESIGN.md §7.12.
  전 부서(COMTNORGNZTINFO) × 구분(계/민사/행정/국가/심판) × (변호사 선임 / 직접 수행).
  부서 귀속=LAW_SUIT_STAFF.ORGNZT_ID, 계류 스냅샷(무기간).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">부서별 통계</c:set>
<c:set var="pageHead">
  
  <style>
    .law-stat-head { display:flex; justify-content:flex-end; gap:6px; margin:8px 0 12px; }
    .law-stat-table td, .law-stat-table th { text-align:center; }
    .law-stat-table td.txt-left { text-align:left; }
    .law-stat-table tr.row-total { background:#f4f6fb; font-weight:700; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>부서별 통계</h1>
    <p class="page-desc">진행 중(계류) 사건을 담당 부서·구분별로, 변호사 선임/직접 수행으로 나눈 현황입니다. 기간을 입력하면 소제기일 기준으로 추려 봅니다(빈값=전체).</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/stat/dept.do'/>" method="get" class="krds-form search-form">
    <div class="form-group inline">
      <label class="form-label" for="fromDate">기간(소제기일)</label>
      <div class="form-conts">
        <input type="date" id="fromDate" name="fromDate" class="krds-input" value="<c:out value='${fromDate}'/>"/>
        <span>~</span>
        <input type="date" id="toDate" name="toDate" class="krds-input" aria-label="기간(종료)" value="<c:out value='${toDate}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">조회</button>
      <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/stat/dept.do"/>';">전체</button>
    </div>
  </form>

  <div class="law-stat-head">
    <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀 다운로드</button>
  </div>
  <script>
  <%-- 엑셀 = 현재 기간 조건 그대로 (summary 패턴) --%>
  function fnExcel(){
    var f = document.getElementById('searchForm');
    var a = f.getAttribute('action');
    f.setAttribute('action', '<c:url value="/law/stat/deptExcel.do"/>');
    f.submit();
    f.setAttribute('action', a);
  }
  </script>

  <div style="overflow-x:auto;">
  <table class="krds-table tbl-list law-stat-table">
    <thead>
      <tr>
        <th scope="col" rowspan="2" style="width:140px;">부서</th>
        <th scope="col" colspan="2">계</th>
        <th scope="col" colspan="2">민사</th>
        <th scope="col" colspan="2">행정</th>
        <th scope="col" colspan="2">국가</th>
        <th scope="col" colspan="2">심판</th>
      </tr>
      <tr>
        <th scope="col">변호사</th><th scope="col">직접</th>
        <th scope="col">변호사</th><th scope="col">직접</th>
        <th scope="col">변호사</th><th scope="col">직접</th>
        <th scope="col">변호사</th><th scope="col">직접</th>
        <th scope="col">변호사</th><th scope="col">직접</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${rows}" varStatus="st">
        <tr class="${st.first ? 'row-total' : ''}">
          <td class="${st.first ? '' : 'txt-left'}"><c:out value="${row.name}" default="-"/></td>
          <td><c:out value="${row.totLawer}"/></td><td><c:out value="${row.totGong}"/></td>
          <td><c:out value="${row.minsaLawer}"/></td><td><c:out value="${row.minsaGong}"/></td>
          <td><c:out value="${row.hangjungLawer}"/></td><td><c:out value="${row.hangjungGong}"/></td>
          <td><c:out value="${row.kukgaLawer}"/></td><td><c:out value="${row.kukgaGong}"/></td>
          <td><c:out value="${row.simpanLawer}"/></td><td><c:out value="${row.simpanGong}"/></td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
  </div>
</lay:layout>
