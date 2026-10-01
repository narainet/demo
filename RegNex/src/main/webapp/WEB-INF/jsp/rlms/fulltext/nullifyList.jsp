<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/fulltext/nullifyList.jsp

  사용자 화면 — 폐지 사규/규정 목록. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">폐지 사규/규정</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
  <script src="<c:url value='/resources/js/rlms-cate-search-tree.js' />?v=20260804-fresp"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>폐지 사규/규정</h1>
    <p class="page-desc">폐지된 사규/규정을 조회합니다. 제목을 클릭하면 폐지 당시 본문을 볼 수 있습니다.</p>
  </div>

  <div class="rlms-search-layout">
    <aside class="rlms-search-tree-aside">
      <div class="rlms-search-tree-head">규정 분류</div>
      <div id="cateSearchTree" class="rlms-search-tree"></div>
    </aside>
    <div class="rlms-search-body">

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/fulltext/nullifyList.do'/>"
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
          <option value="2" <c:if test="${searchVO.searchCnd eq '2'}">selected</c:if>>분류</option>
          <option value="3" <c:if test="${searchVO.searchCnd eq '3'}">selected</c:if>>부서</option>
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
      <a href="<c:url value='/rlms/fulltext/nullifyList.do'/>" class="krds-btn medium">초기화</a>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">관리번호</th>
        <th scope="col">제목</th>
        <th scope="col">분류</th>
        <th scope="col">담당부서</th>
        <th scope="col">공포일</th>
        <th scope="col">폐지일</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="7" class="empty-row">폐지된 항목이 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="status">
            <c:set var="rowNum" value="${paginationInfo.totalRecordCount - ((paginationInfo.currentPageNo - 1) * paginationInfo.recordCountPerPage) - status.index}"/>
            <tr>
              <td><c:out value="${rowNum}"/></td>
              <td><a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${row.promNo}"><c:out value="${row.promNo}"/></a></td>
              <td>
                <%-- 외부 원문 참조(법제처 등): SURL 있으면 제목을 외부 새 창 링크로 (historyList 와 동일 패턴) --%>
                <c:set var="nlExtUrlLc" value="${fn:toLowerCase(row.url)}"/>
                <c:choose>
                  <c:when test="${not empty row.url and (fn:startsWith(nlExtUrlLc,'http://') or fn:startsWith(nlExtUrlLc,'https://'))}">
                    <a href="${row.url}" target="_blank" rel="noopener" title="외부 원문 (새 창)"><c:out value="${row.title}"/> <span class="ext-ico" aria-hidden="true">↗</span></a>
                  </c:when>
                  <c:otherwise>
                    <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${row.promNo}">
                      <c:out value="${row.title}"/>
                    </a>
                  </c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.cateNm}"/></td>
              <td><c:out value="${row.buseoNm}"/></td>
              <td><c:out value="${row.promDate}"/></td>
              <td><c:out value="${row.nullDate}"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
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
        searchUrl:   '<c:url value="/rlms/fulltext/nullifyList.do"/>'
      });
    });
  </script>
</lay:layout>
