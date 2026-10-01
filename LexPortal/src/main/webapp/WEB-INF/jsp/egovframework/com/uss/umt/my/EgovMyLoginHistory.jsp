<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/uss/umt/my/EgovMyLoginHistory.jsp
  내 로그인 내역 (개인 격리: 본인 접속로그만). front decorator + KRDS.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">로그인 내역</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>로그인 내역</h1>
    <p class="page-desc">내 계정의 로그인·로그아웃 기록을 확인합니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/uss/umt/my/loginHistory.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="1"/>
    <div class="form-group inline">
      <label class="form-label" for="searchBgnDe">기간</label>
      <div class="form-conts">
        <input type="date" id="searchBgnDe" name="searchBgnDe" class="krds-input"
               value="<c:out value='${searchVO.searchBgnDe}'/>"/>
        <span style="margin:0 6px;">~</span>
        <input type="date" id="searchEndDe" name="searchEndDe" class="krds-input"
               value="<c:out value='${searchVO.searchEndDe}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">조회</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">일시</th>
        <th scope="col">구분</th>
        <th scope="col">접속 IP</th>
        <th scope="col">결과</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="5" class="empty-row">로그인 기록이 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="st">
            <tr>
              <td>${(searchVO.pageIndex-1) * searchVO.pageUnit + st.count}</td>
              <td><c:out value="${row.creatDt}"/></td>
              <td>
                <c:choose>
                  <c:when test="${row.conectMthd eq 'I'}">로그인</c:when>
                  <c:when test="${row.conectMthd eq 'O'}">로그아웃</c:when>
                  <c:otherwise><c:out value="${row.conectMthd}"/></c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.conectIp}"/></td>
              <td>
                <c:choose>
                  <c:when test="${row.errOccrrAt eq 'Y'}"><span style="color:#b42318;">오류</span></c:when>
                  <c:otherwise>정상</c:otherwise>
                </c:choose>
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

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }
  </script>
</lay:layout>
