<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/stats/statsDept.jsp
  부서별 규정통계 (현행 규정 수를 소관부서별 집계). KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">부서별 규정통계</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>부서별 규정통계</h1>
    <p class="page-desc">소관부서별 현행 규정 보유 건수입니다.</p>
  </div>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:10%">순위</th>
        <th scope="col">소관부서</th>
        <th scope="col" style="width:18%">규정수</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="3" class="empty-row">데이터가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="st">
            <tr>
              <td>${st.index + 1}</td>
              <td class="al"><c:out value="${row.label}"/></td>
              <td class="ar"><fmt:formatNumber value="${row.cnt}" type="number"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>
</lay:layout>
