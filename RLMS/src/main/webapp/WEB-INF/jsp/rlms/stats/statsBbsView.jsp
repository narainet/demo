<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/stats/statsBbsView.jsp
  게시판 조회통계 (TB_STATS_BBS_VIEW). KRDS 디자인.
  적재 = 사용자 게시글 상세(/cop/bbs/user/selectArticleDetail.do) GET 실열람 1회=1행 — EgovBoardUserController 배선.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">게시판 조회통계</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>게시판 조회통계</h1>
    <p class="page-desc">기간 내 게시글별 조회수 상위 200건입니다. (사용자 화면 게시글 열람 시 집계)</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/stats/bbsViewStats.do'/>"
        method="get" class="krds-form search-form">
    <div class="form-group inline">
      <label class="form-label" for="fromDt">조회기간</label>
      <div class="form-conts">
        <input type="date" id="fromDt" name="fromDt" class="krds-input" value="<c:out value='${searchVO.fromDt}'/>"/>
        <span>~</span>
        <input type="date" id="toDt" name="toDt" class="krds-input" value="<c:out value='${searchVO.toDt}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
      <button type="button" class="krds-btn medium" onclick="fnExcel()"
              title="현재 조회기간의 게시글별 조회수를 엑셀 파일로 내려받습니다">엑셀 다운로드</button>
    </div>
  </form>

  <p class="list-total">기간 내 총 조회수 <strong><fmt:formatNumber value="${totalCnt}" type="number"/></strong> 회</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:8%">순위</th>
        <th scope="col" style="width:20%">게시판</th>
        <th scope="col">글제목</th>
        <th scope="col" style="width:12%">조회수</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="4" class="empty-row">조회 데이터가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="st">
            <tr>
              <td>${st.index + 1}</td>
              <td><c:out value="${row.bbsNm}"/></td>
              <td class="al">
                <c:choose>
                  <c:when test="${row.useAt eq 'Y'}">
                    <a href="<c:url value='/cop/bbs/user/selectArticleDetail.do'/>?nttId=${row.nttId}&amp;bbsId=<c:out value='${row.bbsId}'/>" target="_blank"><c:out value="${row.label}"/></a>
                  </c:when>
                  <c:otherwise>
                    <c:out value="${row.label}"/><c:if test="${row.useAt eq 'N'}"> <span style="color:#888;">(삭제글)</span></c:if>
                  </c:otherwise>
                </c:choose>
              </td>
              <%-- 조회수 — 헤더(가운데)와 맞춰 가운데 정렬 (2026-07-30) --%>
              <td class="ac"><fmt:formatNumber value="${row.cnt}" type="number"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

<script>
  function fnExcel() {
    var f = document.getElementById('fromDt').value, t = document.getElementById('toDt').value;
    var qs = [];
    if (f) qs.push('fromDt=' + encodeURIComponent(f));
    if (t) qs.push('toDt=' + encodeURIComponent(t));
    location.href = '<c:url value="/rlms/stats/bbsViewStatsExcel.do"/>' + (qs.length ? '?' + qs.join('&') : '');
  }
</script>
</lay:layout>
