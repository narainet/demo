<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/promwork/promWorkActLogList.jsp

  제·개정내역 관리 — 전역 액션 로그(TB_PROM_ACT_LOG) 목록 화면. KRDS 디자인.
   · "작업승인관리"(TB_PROM_WRK 결재흐름)와 구분되는 화면.
   · 규정의 제·개정/편집/별표·조문 등록·수정·삭제/승인 등 작업내역(감사로그)을 전역 검색·열람.
   · 각 행의 규정명을 클릭하면 그 회차의 상세 이력(selectPromWorkHistory)으로 진입.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">제·개정내역관리</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>제·개정내역관리</h1>
    <p class="page-desc">규정의 제·개정·편집·별표/조문 등록·수정·삭제·승인 등 작업내역(감사 로그)을 조회합니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/promwork/selectPromWorkActLogList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>

    <div class="form-group inline">
      <label class="form-label" for="searchKeyword">검색어</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               placeholder="규정명 / 작업명 / 작업자"
               value="<c:out value='${searchVO.searchKeyword}'/>"/>
      </div>

      <label class="form-label" for="searchActType">구분</label>
      <div class="form-conts">
        <select id="searchActType" name="searchActType" class="krds-select">
          <option value=""        <c:if test="${empty searchVO.searchActType}">selected</c:if>>전체</option>
          <option value="INSERT"  <c:if test="${searchVO.searchActType eq 'INSERT'}">selected</c:if>>등록</option>
          <option value="UPDATE"  <c:if test="${searchVO.searchActType eq 'UPDATE'}">selected</c:if>>수정</option>
          <option value="DELETE"  <c:if test="${searchVO.searchActType eq 'DELETE'}">selected</c:if>>삭제</option>
          <option value="APPROVE" <c:if test="${searchVO.searchActType eq 'APPROVE'}">selected</c:if>>승인</option>
          <option value="REJECT"  <c:if test="${searchVO.searchActType eq 'REJECT'}">selected</c:if>>반려</option>
        </select>
      </div>

      <label class="form-label" for="searchFromDt">기간</label>
      <div class="form-conts">
        <input type="date" id="searchFromDt" name="searchFromDt" class="krds-input"
               value="<c:out value='${searchVO.searchFromDt}'/>"/>
        <span>~</span>
        <input type="date" name="searchToDt" class="krds-input"
               value="<c:out value='${searchVO.searchToDt}'/>"/>
      </div>

      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">규정명</th>
        <th scope="col">작업</th>
        <th scope="col">구분</th>
        <th scope="col">설명</th>
        <th scope="col">작업자</th>
        <th scope="col">일시</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="7" class="empty-row">데이터가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="st">
            <tr>
              <td><c:out value="${paginationInfo.totalRecordCount - (paginationInfo.recordCountPerPage * (paginationInfo.currentPageNo - 1)) - st.index}"/></td>
              <td>
                <c:choose>
                  <c:when test="${not empty row.promTitle}">
                    <a href="<c:url value='/rlms/promwork/selectPromWorkHistory.do'/>?promNo=${row.promNo}"><c:out value="${row.promTitle}"/></a>
                  </c:when>
                  <c:otherwise>
                    <span class="text-muted">(규정 #<c:out value="${row.promNo}"/>)</span>
                  </c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.actNm}"/></td>
              <td>
                <c:choose>
                  <c:when test="${row.actType eq 'INSERT'}">등록</c:when>
                  <c:when test="${row.actType eq 'UPDATE'}">수정</c:when>
                  <c:when test="${row.actType eq 'DELETE'}">삭제</c:when>
                  <c:when test="${row.actType eq 'APPROVE'}">승인</c:when>
                  <c:when test="${row.actType eq 'REJECT'}">반려</c:when>
                  <c:otherwise>기타</c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.actDc}"/></td>
              <td><c:out value="${row.userNm}"/> (<c:out value="${row.userId}"/>)</td>
              <td><c:out value="${row.insDt}"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <div class="krds-pagination">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }
  </script>
</lay:layout>
