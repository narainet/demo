<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/fulltext/comparisonList.jsp

  사용자 화면 — 신구대조 진입. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">신구대조</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
  <script src="<c:url value='/resources/js/rlms-cate-search-tree.js' />?v=20260804-fresp"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>신구대조</h1>
  </div>

  <c:choose>
    <c:when test="${not empty candidates}">
      <div class="krds-alert info">비교할 두 개정본을 선택하세요.</div>
      <form id="compareForm" action="<c:url value='/rlms/prom/diffByPromNo.do'/>" method="get" class="krds-form">
        <table class="krds-table tbl-list">
          <thead>
            <tr>
              <th scope="col">좌(이전)</th>
              <th scope="col">우(현행)</th>
              <th scope="col">회차</th>
              <th scope="col">제목</th>
              <th scope="col">공포일</th>
              <th scope="col">현행</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="row" items="${candidates}">
              <tr>
                <td><input type="radio" name="leftPromNo"  value="${row.promNo}"/></td>
                <td><input type="radio" name="rightPromNo" value="${row.promNo}"/></td>
                <td><c:out value="${row.lawNo}"/></td>
                <td><c:out value="${row.title}"/></td>
                <td><c:out value="${row.promDate}"/></td>
                <td>${row.existingYn eq 'Y' ? '현행' : '이전'}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
        <div class="btn-area right">
          <a href="<c:url value='/rlms/fulltext/comparisonList.do'/>" class="krds-btn medium">규정 선택으로</a>
          <button type="submit" class="krds-btn primary medium">비교</button>
        </div>
      </form>
    </c:when>

    <c:otherwise>
      <div class="rlms-search-layout">
        <aside class="rlms-search-tree-aside">
          <div class="rlms-search-tree-head">규정 분류</div>
          <div id="cateSearchTree" class="rlms-search-tree"></div>
        </aside>
        <div class="rlms-search-body">
      <form id="searchForm" name="searchForm" action="<c:url value='/rlms/fulltext/comparisonList.do'/>"
            method="get" class="krds-form search-form">
        <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
        <c:if test="${not empty searchVO.cateNo}"><input type="hidden" name="cateNo" value="${searchVO.cateNo}"/></c:if>
        <div class="form-group inline">
          <label class="form-label">분류</label>
          <div class="form-conts" style="display:flex;flex-wrap:wrap;gap:10px;align-items:center;">
            <c:forEach var="g" items="${gubunList}">
            <label style="font-weight:normal;display:inline-flex;align-items:center;gap:4px;"><input type="checkbox" name="gubunIds" value="${g.code}" <c:if test="${not empty searchVO.gubunIds and searchVO.gubunIds.contains(g.code)}">checked</c:if>/><c:out value="${g.label}"/></label>
            </c:forEach>
          </div>
        </div>
        <div class="form-group inline">
          <label class="form-label" for="searchCnd">검색조건</label>
          <div class="form-conts">
            <select id="searchCnd" name="searchCnd" class="krds-select">
              <option value="0" <c:if test="${searchVO.searchCnd eq '0'}">selected</c:if>>제목</option>
              <option value="1" <c:if test="${searchVO.searchCnd eq '1'}">selected</c:if>>본문</option>
            </select>
          </div>
          <label class="form-label" for="searchKeyword">키워드</label>
          <div class="form-conts">
            <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
                   value="<c:out value='${searchVO.searchKeyword}'/>"/>
          </div>
          <label class="form-label" for="searchFromDt">공포일</label>
          <div class="form-conts">
            <input type="date" id="searchFromDt" name="searchFromDt" class="krds-input" value="<c:out value='${searchVO.searchFromDt}'/>"/>
            <span>~</span>
            <input type="date" id="searchToDt" name="searchToDt" class="krds-input" value="<c:out value='${searchVO.searchToDt}'/>"/>
          </div>
          <button type="submit" class="krds-btn primary medium">검색</button>
          <a href="<c:url value='/rlms/fulltext/comparisonList.do'/>" class="krds-btn medium">초기화</a>
        </div>
      </form>

      <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건 — 신구대조할 규정을 선택하세요. (선택하면 회차 목록이 표시됩니다)</p>

      <table class="krds-table tbl-list">
        <thead>
          <tr>
            <th scope="col">No</th>
            <th scope="col">규정ID</th>
            <th scope="col">제목</th>
            <th scope="col">분류</th>
            <th scope="col">최신회차</th>
            <th scope="col">공포일</th>
          </tr>
        </thead>
        <tbody>
          <c:forEach var="row" items="${resultList}" varStatus="status">
            <c:set var="rowNum" value="${paginationInfo.totalRecordCount - ((paginationInfo.currentPageNo - 1) * paginationInfo.recordCountPerPage) - status.index}"/>
            <tr>
              <td><c:out value="${rowNum}"/></td>
              <td>
                <a href="<c:url value='/rlms/fulltext/comparisonList.do'/>?lawId=${row.lawId}">
                  <c:out value="${row.lawId}"/>
                </a>
              </td>
              <td><a href="<c:url value='/rlms/fulltext/comparisonList.do'/>?lawId=${row.lawId}"><c:out value="${row.title}"/></a>
                  <c:if test="${row.upcoming}"><span class="krds-badge bg-light-information" title="시행일 ${row.startDate}">시행예정</span></c:if></td>
              <td><c:out value="${row.cateNm}"/></td>
              <td><c:out value="${row.lawNo}"/></td>
              <td><c:out value="${row.promDate}"/></td>
            </tr>
          </c:forEach>
        </tbody>
      </table>

      <div class="krds-pagination">
        <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
      </div>

        </div>
      </div>

      <script>
        function fnLinkPage(pageNo) {
          document.searchForm.pageIndex.value = pageNo;
          document.searchForm.submit();
        }
        $(function() {
          RlmsCateSearchTree.init({
            containerId: 'cateSearchTree',
            jsonUrl:     '<c:url value="/rlms/cate/selectCateTreeJson.do"/>',
            searchUrl:   '<c:url value="/rlms/fulltext/comparisonList.do"/>'
          });
        });
      </script>
    </c:otherwise>
  </c:choose>
</lay:layout>
