<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/suit/list.jsp
  소송조회 (LAW_MODULE_DESIGN.md §7.1) — 14열 그리드·검색·페이징·[등록][엑셀].
  등록·상세는 목록 내 버튼 흐름(별도 메뉴 없음).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송조회</c:set>
<c:set var="pageHead">
  
  <style>
    /* .law-total / .law-cell-sub / .law-search-grid 는 rlms-compat.css 공통 (송무 전 화면 통일) */
    .law-suit-table td, .law-suit-table th { font-size: 13px; }
    .law-suit-table td { vertical-align: middle; }
    .law-row-link { cursor: pointer; }
    .law-row-link:hover { background: #f4f7ff; }
    .law-num { text-align: right; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>소송조회</h1>
    <p class="page-desc">소송 사건 목록입니다. 행을 누르면 상세로 이동합니다.</p>
  </div>

  <c:if test="${not empty message}">
    <script>alert('<c:out value="${message}"/>');</script>
  </c:if>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/suit/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="law-search-grid">
      <div>
        <label for="searchFixFrom">확정일</label>
        <div class="law-date-range">
          <input type="date" id="searchFixFrom" name="searchFixFrom" class="krds-input" value="<c:out value='${searchVO.searchFixFrom}'/>"/>
          <span class="sep">~</span>
          <input type="date" id="searchFixTo" name="searchFixTo" class="krds-input" aria-label="확정일(종료)" value="<c:out value='${searchVO.searchFixTo}'/>"/>
        </div>
      </div>
      <div>
        <label for="searchItpt">제·피소</label>
        <select id="searchItpt" name="searchItpt" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="cd" items="${itptKinds}">
            <option value="<c:out value='${cd.code}'/>" <c:if test="${searchVO.searchItpt eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option>
          </c:forEach>
        </select>
      </div>
      <div>
        <label for="searchCaseKind">소송구분</label>
        <select id="searchCaseKind" name="searchCaseKind" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="cd" items="${caseKinds}">
            <option value="<c:out value='${cd.code}'/>" <c:if test="${searchVO.searchCaseKind eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option>
          </c:forEach>
        </select>
      </div>
      <div>
        <label for="searchRslt">소송결과</label>
        <select id="searchRslt" name="searchRslt" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="cd" items="${results}">
            <option value="<c:out value='${cd.code}'/>" <c:if test="${searchVO.searchRslt eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option>
          </c:forEach>
        </select>
      </div>
      <div>
        <label for="searchCaseYear">사건번호(연도)</label>
        <input type="text" id="searchCaseYear" name="searchCaseYear" class="krds-input" inputmode="numeric" maxlength="4" placeholder="2026" value="<c:out value='${searchVO.searchCaseYear}'/>" oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,4);"/>
      </div>
      <div>
        <label for="searchCaseSign">사건부호</label>
        <select id="searchCaseSign" name="searchCaseSign" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="cd" items="${caseSigns}">
            <option value="<c:out value='${cd.code}'/>" <c:if test="${searchVO.searchCaseSign eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option>
          </c:forEach>
        </select>
      </div>
      <div>
        <label for="searchCaseSerial">사건번호(일련)</label>
        <input type="text" id="searchCaseSerial" name="searchCaseSerial" class="krds-input" placeholder="일련번호" value="<c:out value='${searchVO.searchCaseSerial}'/>"/>
      </div>
      <div class="law-search-btns">
        <button type="submit" class="krds-btn small primary" onclick="document.getElementById('pageIndex').value=1;">검색</button>
        <a href="<c:url value='/law/suit/list.do'/>" class="krds-btn small">초기화</a>
      </div>
    </div>
  </form>

  <div class="law-list-head">
    <span class="law-total" style="margin:0;">총 <strong><c:out value="${resultCnt}"/></strong>건</span>
    <span class="law-actions">
      <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/suit/regist.do"/>';">등록</button>
      <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀</button>
    </span>
  </div>
  <div style="overflow-x:auto;">
  <table class="krds-table tbl-list law-suit-table">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">번호</th>
        <th scope="col">소송구분</th>
        <th scope="col">법원명</th>
        <th scope="col">사건번호</th>
        <th scope="col">사건명</th>
        <th scope="col">심급</th>
        <th scope="col">원고</th>
        <th scope="col">피고</th>
        <th scope="col">사건토지 소재지·지번</th>
        <th scope="col">소송진행상황</th>
        <th scope="col">소제기일</th>
        <th scope="col">최종선고일</th>
        <th scope="col">소가</th>
        <th scope="col">승(패)소금액</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr class="law-row-link" data-id="<c:out value='${row.suitId}'/>">
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:out value="${row.caseKindNm}" default="-"/></td>
          <td><c:out value="${row.courtNm}" default="-"/></td>
          <td><c:out value="${row.caseNo}" default="-"/></td>
          <td><c:out value="${row.caseNm}" default="-"/></td>
          <td><c:out value="${row.instanceNm}" default="-"/></td>
          <td><c:out value="${row.plaintiffNm}" default="-"/><c:if test="${row.plaintiffCnt > 1}"> <span class="law-cell-sub">외 <c:out value="${row.plaintiffCnt - 1}"/></span></c:if></td>
          <td><c:out value="${row.defendantNm}" default="-"/><c:if test="${row.defendantCnt > 1}"> <span class="law-cell-sub">외 <c:out value="${row.defendantCnt - 1}"/></span></c:if></td>
          <td><c:out value="${row.landSummary}" default="-"/><c:if test="${row.landCnt > 1}"> <span class="law-cell-sub">외 <c:out value="${row.landCnt - 1}"/></span></c:if></td>
          <td><c:out value="${row.progSummary}" default="-"/></td>
          <td><c:out value="${row.frDt}" default="-"/></td>
          <td><c:out value="${row.stcDt}" default="-"/></td>
          <td class="law-num"><c:choose><c:when test="${row.suitAmt != null}"><fmt:formatNumber value="${row.suitAmt}"/></c:when><c:otherwise>-</c:otherwise></c:choose></td>
          <td class="law-num">
            <c:choose>
              <c:when test="${row.winAmt != null}"><fmt:formatNumber value="${row.winAmt}"/></c:when>
              <c:when test="${row.loseAmt != null}"><fmt:formatNumber value="${row.loseAmt}"/></c:when>
              <c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="14" style="text-align:center; padding:32px 0; color:#888;">조회된 사건이 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>
  </div>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <script>
  function fnLinkPage(pageNo) {
    document.getElementById('pageIndex').value = pageNo;
    document.getElementById('searchForm').submit();
  }
  function fnExcel() {
    var f = document.getElementById('searchForm');
    var org = f.action;
    f.action = '<c:url value="/law/suit/listExcel.do"/>';
    f.submit();
    f.action = org;
  }
  document.querySelectorAll('.law-row-link').forEach(function (tr) {
    tr.addEventListener('click', function () {
      location.href = '<c:url value="/law/suit/view.do"/>?suitId=' + this.dataset.id;
    });
  });
  </script>
</lay:layout>
