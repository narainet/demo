<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/cost/list.jsp
  소송비용 조회 (LAW_MODULE_DESIGN.md §7.3) — 검색(문서조회 패턴+사건명)·목록·합계 행·엑셀·계산기(공용 모달).
  비용 등록·수정은 사건 상세(소송관리 view)에서. 여기는 조회 전용.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송비용조회</c:set>
<c:set var="pageHead">
  
  <style>
    .law-cell-sub { color:#888; font-size:12px; }
    .law-num { text-align:right; }
    <%-- 검색 그리드 = rlms-compat.css .law-search-grid 공통 --%>
    .law-total-row td { background:#f4f7ff; font-weight:700; }
    /* 계산기 공용 모달 베이스 (프래그먼트가 참조) */
    .law-modal-back { position: fixed; inset:0; background:rgba(0,0,0,.45); display:none; z-index:1000; }
    .law-modal { position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#fff; border-radius:12px;
                 padding:26px 30px; display:none; z-index:1001; box-shadow:0 8px 30px rgba(0,0,0,.2); }
    .law-modal h2 { font-size:19px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>소송비용조회</h1>
    <p class="page-desc">등록된 소송비용을 조건별로 조회하고 합계를 확인합니다. 인지액·송달료·변호사비·지연이자 계산기를 제공합니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/cost/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="law-search-grid">
      <div><label for="searchFrFrom">소제기일</label>
        <div class="law-date-range">
          <input type="date" id="searchFrFrom" name="searchFrFrom" class="krds-input" value="<c:out value='${searchVO.searchFrFrom}'/>"/>
          <span class="sep">~</span>
          <input type="date" id="searchFrTo" name="searchFrTo" class="krds-input" aria-label="소제기일(종료)" value="<c:out value='${searchVO.searchFrTo}'/>"/>
        </div></div>
      <div><label for="searchItpt">제·피소구분</label>
        <select id="searchItpt" name="searchItpt" class="krds-select"><option value="">전체</option>
          <c:forEach var="c" items="${itptKinds}"><option value="${c.code}" ${searchVO.searchItpt eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div><label for="searchCaseKind">소송구분</label>
        <select id="searchCaseKind" name="searchCaseKind" class="krds-select"><option value="">전체</option>
          <c:forEach var="c" items="${caseKinds}"><option value="${c.code}" ${searchVO.searchCaseKind eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div><label for="searchRslt">소송결과</label>
        <select id="searchRslt" name="searchRslt" class="krds-select"><option value="">전체</option>
          <c:forEach var="c" items="${results}"><option value="${c.code}" ${searchVO.searchRslt eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div><label for="searchCostKind">비용종류</label>
        <select id="searchCostKind" name="searchCostKind" class="krds-select"><option value="">전체</option>
          <c:forEach var="c" items="${costKinds}"><option value="${c.code}" ${searchVO.searchCostKind eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div><label for="searchCaseSerial">사건번호(일련)</label><input type="text" id="searchCaseSerial" name="searchCaseSerial" class="krds-input" value="<c:out value='${searchVO.searchCaseSerial}'/>"/></div>
      <div><label for="searchCaseNm">사건명</label><input type="text" id="searchCaseNm" name="searchCaseNm" class="krds-input" value="<c:out value='${searchVO.searchCaseNm}'/>"/></div>
      <div class="law-search-btns">
        <button type="submit" class="krds-btn small primary" onclick="document.getElementById('pageIndex').value=1;">검색</button>
        <button type="button" class="krds-btn small" onclick="location.href='<c:url value="/law/cost/list.do"/>';">초기화</button>
      </div>
    </div>
  </form>

  <div style="display:flex; justify-content:space-between; align-items:center; margin:14px 0 4px;">
    <span class="law-total" style="margin:0;">총 <strong><c:out value="${resultCnt}"/></strong>건</span>
    <span style="display:flex; gap:8px;">
      <button type="button" class="krds-btn primary medium" onclick="fnOpenCalc();">계산기</button>
      <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀</button>
    </span>
  </div>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">No</th>
        <th scope="col">법원명</th>
        <th scope="col">사건번호</th>
        <th scope="col">사건명</th>
        <th scope="col" style="width:8%;">비용종류</th>
        <th scope="col">내역</th>
        <th scope="col" style="width:8%;">금액</th>
        <th scope="col" style="width:8%;">등록일자</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:out value="${row.courtNm}" default="-"/></td>
          <td><a href="<c:url value='/law/suit/view.do'/>?suitId=${row.suitId}"><c:out value="${row.caseNo}" default="(미입력)"/></a></td>
          <td><c:out value="${row.caseNm}" default="-"/></td>
          <td><c:out value="${row.costKindNm}" default="-"/></td>
          <td><c:out value="${row.costDesc}" default="-"/></td>
          <td class="law-num"><c:choose><c:when test="${row.costAmt != null}"><fmt:formatNumber value="${row.costAmt}"/></c:when><c:otherwise>-</c:otherwise></c:choose></td>
          <td>
            <c:choose>
              <c:when test="${not empty row.regDt and fn:length(row.regDt) ge 8}"><fmt:parseDate value="${fn:substring(row.regDt,0,8)}" pattern="yyyyMMdd" var="rd"/><fmt:formatDate value="${rd}" pattern="yyyy-MM-dd"/></c:when>
              <c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="8" style="text-align:center; padding:32px 0; color:#888;">조회된 비용이 없습니다.</td></tr>
      </c:if>
    </tbody>
    <c:if test="${not empty resultList}">
      <tfoot>
        <tr class="law-total-row">
          <td colspan="6" style="text-align:right;">검색 결과 합계</td>
          <td class="law-num"><fmt:formatNumber value="${totalAmt}"/></td>
          <td></td>
        </tr>
      </tfoot>
    </c:if>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <%@ include file="/WEB-INF/jsp/law/cost/_calcModal.jspf" %>

  <script>
  function fnLinkPage(pageNo){ document.getElementById('pageIndex').value = pageNo; document.getElementById('searchForm').submit(); }
  function fnExcel(){
    var f = document.getElementById('searchForm');
    var act = f.action; f.action = '<c:url value="/law/cost/listExcel.do"/>'; f.submit(); f.action = act;
  }
  </script>
</lay:layout>
