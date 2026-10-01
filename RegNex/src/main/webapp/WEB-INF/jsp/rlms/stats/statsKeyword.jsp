<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/stats/statsKeyword.jsp
  기간별 검색어 통계 (TB_STATS_KWD). KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">검색어 통계</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>검색어 통계</h1>
    <p class="page-desc">기간 내 전문검색 검색어 상위 200건입니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/stats/keywordStats.do'/>"
        method="get" class="krds-form search-form">
    <div class="form-group inline">
      <label class="form-label" for="fromDt">조회기간</label>
      <div class="form-conts">
        <input type="date" id="fromDt" name="fromDt" class="krds-input" value="<c:out value='${searchVO.fromDt}'/>"/>
        <span>~</span>
        <input type="date" name="toDt" class="krds-input" value="<c:out value='${searchVO.toDt}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:10%">순위</th>
        <th scope="col">검색어</th>
        <th scope="col" style="width:18%">검색횟수</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="3" class="empty-row">검색어 데이터가 없습니다.</td></tr>
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
