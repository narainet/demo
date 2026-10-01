<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/gaejung/gaejungList.jsp
  개정 종류 관리. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">개정구분관리</c:set>
<lay:layout title="${pageTitle}">
  <div class="page-header">
    <h1>개정구분관리</h1>
    <p class="page-desc">규정 개정 구분(제정/개정/폐지 등) 코드를 관리합니다.</p>
  </div>

  <c:if test="${not empty resultMsg}">
    <div class="krds-alert success"><c:out value="${resultMsg}"/></div>
  </c:if>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/gaejung/selectGaejungList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <div class="form-group inline">
      <label class="form-label" for="searchKeyword">이름</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
      <button type="button" class="krds-btn medium"
              onclick="location.href='<c:url value="/rlms/gaejung/insertGaejungView.do"/>'">신규 등록</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">이름</th>
        <th scope="col">정렬순서</th>
        <th scope="col">신구대조 여부</th>
        <th scope="col">등록일</th>
        <th scope="col">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="6" class="empty-row">등록된 개정 종류가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}">
            <tr>
              <td><c:out value="${row.gaejungNo}"/></td>
              <td><c:out value="${row.gaejungNm}"/></td>
              <td><c:out value="${row.seq}"/></td>
              <td>${row.diffYn eq 'Y' ? '신구대조' : '-'}</td>
              <td><c:out value="${row.insDt}"/></td>
              <td>
                <a href="<c:url value='/rlms/gaejung/updateGaejungView.do'/>?gaejungNo=<c:out value='${row.gaejungNo}'/>"
                   class="krds-btn small">수정</a>
                <button type="button" class="krds-btn danger small"
                        onclick="fnDelete('<c:out value="${row.gaejungNo}"/>');">삭제</button>
              </td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <div class="krds-pagination">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <form id="deleteForm" name="deleteForm" action="<c:url value='/rlms/gaejung/deleteGaejung.do'/>" method="post">
    <input type="hidden" name="gaejungNo" id="deleteGaejungNo"/>
  </form>

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }
    function fnDelete(no) {
      if (!confirm('정말 삭제하시겠습니까? (사용 중인 규정이 있으면 차단됩니다)')) return;
      document.getElementById('deleteGaejungNo').value = no;
      document.deleteForm.submit();
    }
  </script>
</lay:layout>
