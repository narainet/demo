<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/stat/agent.jsp
  소송통계 ⑤ 대리인 — LAW_MODULE_DESIGN.md §7.12.
  상단: 계류사건 대리인 지정현황(변호사 선임 vs 공무원 수행 + 공무원 수행 비율).
  하단: 대리인별 통계(합계/진행중/종결/승/패/승소율/비용합계). 계류 스냅샷(무기간).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">대리인 통계</c:set>
<c:set var="pageHead">
  
  <style>
    .law-stat-head { display:flex; justify-content:flex-end; gap:6px; margin:8px 0 12px; }
    .law-stat-sub { margin:20px 0 8px; font-size:16px; font-weight:700; }
    .law-stat-table td, .law-stat-table th { text-align:center; }
    .law-stat-table td.txt-left { text-align:left; }
    .law-stat-table tr.row-total { background:#f4f6fb; font-weight:700; }
    .law-rate-wrap { display:flex; align-items:center; gap:10px; margin:6px 0 2px; }
    .law-rate-bar { flex:0 0 240px; height:14px; background:#e9edf5; border-radius:7px; overflow:hidden; }
    .law-rate-fill { height:100%; background:#3d5afe; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>대리인 통계</h1>
    <p class="page-desc">계류 사건의 대리인 지정 현황과 대리인별 소송 성과입니다. 기간을 입력하면 소제기일 기준으로 추려 봅니다(빈값=전체).</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/stat/agent.do'/>" method="get" class="krds-form search-form">
    <div class="form-group inline">
      <label class="form-label" for="fromDate">기간(소제기일)</label>
      <div class="form-conts">
        <input type="date" id="fromDate" name="fromDate" class="krds-input" value="<c:out value='${fromDate}'/>"/>
        <span>~</span>
        <input type="date" id="toDate" name="toDate" class="krds-input" aria-label="기간(종료)" value="<c:out value='${toDate}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">조회</button>
      <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/stat/agent.do"/>';">전체</button>
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
    f.setAttribute('action', '<c:url value="/law/stat/agentExcel.do"/>');
    f.submit();
    f.setAttribute('action', a);
  }
  </script>

  <div class="law-stat-sub">소송대리인 지정현황 (계류사건)</div>
  <div class="law-rate-wrap">
    <span>공무원 수행 비율 <strong><c:out value="${officialRate}"/>%</strong></span>
    <span class="law-rate-bar"><span class="law-rate-fill" style="width:<c:out value="${officialRate}"/>%;"></span></span>
  </div>
  <table class="krds-table tbl-list law-stat-table">
    <thead>
      <tr>
        <th scope="col">구분</th>
        <th scope="col">계</th>
        <th scope="col">민사</th>
        <th scope="col">행정</th>
        <th scope="col">국가</th>
        <th scope="col">심판</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${topList}" varStatus="st">
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

  <div class="law-stat-sub">대리인별 통계</div>
  <table class="krds-table tbl-list law-stat-table">
    <thead>
      <tr>
        <th scope="col">대리인</th>
        <th scope="col">소속</th>
        <th scope="col">합계</th>
        <th scope="col">진행중</th>
        <th scope="col">종결</th>
        <th scope="col">승</th>
        <th scope="col">패</th>
        <th scope="col">승소율(%)</th>
        <th scope="col">비용합계(원)</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${bottomList}">
        <tr>
          <td><c:out value="${row.name}" default="-"/></td>
          <td class="txt-left"><c:out value="${row.companyName}" default="-"/></td>
          <td><c:out value="${row.totCnt}"/></td>
          <td><c:out value="${row.processingCnt}"/></td>
          <td><c:out value="${row.terminatedCnt}"/></td>
          <td><c:out value="${row.winCnt}"/></td>
          <td><c:out value="${row.loseCnt}"/></td>
          <td><c:out value="${row.rate}"/></td>
          <td style="text-align:right;"><fmt:formatNumber value="${row.totAmt}" type="number"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty bottomList}">
        <tr><td colspan="9" style="text-align:center; padding:28px 0; color:#888;">대리인 데이터가 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>
</lay:layout>
