<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/stats/statsActionLog.jsp
  사용자 활동 로그 (TB_ACT_LOG). KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">사용자 활동 로그</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>사용자 활동 로그</h1>
    <p class="page-desc">기간·작업·사용자별 활동 로그입니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/stats/actionLog.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <div class="form-group inline">
      <label class="form-label" for="fromDt">기간</label>
      <div class="form-conts">
        <input type="date" id="fromDt" name="fromDt" class="krds-input" value="<c:out value='${searchVO.fromDt}'/>"/>
        <span>~</span>
        <input type="date" name="toDt" class="krds-input" value="<c:out value='${searchVO.toDt}'/>"/>
      </div>
      <label class="form-label" for="searchTask">작업</label>
      <div class="form-conts">
        <select id="searchTask" name="searchTask" class="krds-select">
          <option value="" <c:if test="${empty searchVO.searchTask}">selected</c:if>>전체</option>
          <c:forEach var="t" items="${taskKinds}">
            <option value="${t}" <c:if test="${searchVO.searchTask eq t}">selected</c:if>>${t}</option>
          </c:forEach>
        </select>
      </div>
      <label class="form-label" for="searchUser">사용자</label>
      <div class="form-conts">
        <input type="text" id="searchUser" name="searchUser" class="krds-input" value="<c:out value='${searchVO.searchUser}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:16%">일시</th>
        <th scope="col" style="width:12%">작업</th>
        <th scope="col" style="width:14%">사용자</th>
        <th scope="col">대상</th>
        <th scope="col" style="width:13%">IP</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="5" class="empty-row">로그가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}">
            <tr>
              <td><c:out value="${row.insDt}"/></td>
              <td><c:out value="${row.task}"/></td>
              <td><c:out value="${row.userName}"/></td>
              <td class="al"><c:out value="${row.refName}"/></td>
              <td><c:out value="${row.insIp}"/></td>
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
