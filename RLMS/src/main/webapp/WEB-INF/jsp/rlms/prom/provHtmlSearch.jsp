<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/provHtmlSearch.jsp

  본문 전문 검색 (Oracle Text) 결과 화면. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">본문 전문 검색</c:set>
<lay:layout title="${pageTitle}">
  <div class="page-header">
    <h1>본문 전문 검색</h1>
    <p class="page-desc">검색 연산자를 쓸 수 있습니다 — 예: <code>규정 AND 시행</code>, <code>"세부 규칙"</code> (따옴표는 구문 일치)</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/prom/searchFullText.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${paginationInfo.currentPageNo}"/>
    <div class="form-group inline">
      <label class="form-label" for="keyword">키워드</label>
      <div class="form-conts">
        <input type="text" id="keyword" name="keyword" class="krds-input"
               value="<c:out value='${keyword}'/>" required/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <c:if test="${not empty resultCnt}">
    <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

    <table class="krds-table tbl-list">
      <thead>
        <tr>
          <th scope="col">규정번호</th>
          <th scope="col">조항</th>
          <th scope="col">본문 일부</th>
          <th scope="col">관련도</th>
        </tr>
      </thead>
      <tbody>
        <c:choose>
          <c:when test="${empty resultList}">
            <tr><td colspan="4" class="empty-row">검색 결과 없음</td></tr>
          </c:when>
          <c:otherwise>
            <c:forEach var="row" items="${resultList}">
              <tr>
                <td>
                  <a href="<c:url value='/rlms/prom/selectPromDetail.do'/>?promNo=<c:out value='${row.promNo}'/>">
                    <c:out value="${row.promNo}"/>
                  </a>
                </td>
                <td><c:out value="${row.itemLabel}"/></td>
                <td>
                  <c:choose>
                    <c:when test="${fn:length(row.contents) gt 200}">
                      <c:out value="${fn:substring(row.contents, 0, 200)}"/>...
                    </c:when>
                    <c:otherwise>
                      <c:out value="${row.contents}"/>
                    </c:otherwise>
                  </c:choose>
                </td>
                <td><c:out value="${row.rank}"/></td>
              </tr>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </tbody>
    </table>

    <div class="krds-pagination">
      <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
    </div>
  </c:if>

  <%-- 보조: 관련자료 WORD 자체변환 본문(SSEARCH_TEXT) 검색 결과 --%>
  <c:if test="${not empty keyword}">
    <div class="page-header" style="margin-top:30px;">
      <h2 style="font-size:1.15rem;margin:0;">관련 문서(WORD·HWPX) 본문 검색</h2>
      <p class="page-desc">업로드된 관련 문서(.docx·.hwpx)의 본문에서 키워드를 찾습니다 (부분일치). 규정을 클릭하면 전문 뷰어에서 문서를 바로 볼 수 있습니다.</p>
    </div>
    <c:choose>
      <c:when test="${empty wordResults}">
        <p class="list-total">관련 문서 검색 결과 없음</p>
      </c:when>
      <c:otherwise>
        <p class="list-total">총 <strong><c:out value="${fn:length(wordResults)}"/></strong> 건 (최대 50)</p>
        <table class="krds-table tbl-list">
          <thead>
            <tr>
              <th scope="col">규정</th>
              <th scope="col">문서명</th>
              <th scope="col">본문 일부</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="w" items="${wordResults}">
              <tr>
                <td>
                  <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=<c:out value='${w.promNo}'/>">
                    <c:out value="${w.promTitle}"/> <c:if test="${not empty w.lawNo}">(${w.lawNo}차)</c:if>
                  </a>
                </td>
                <td><c:out value="${w.docTitle}"/></td>
                <td>
                  <c:out value="${fn:substring(w.snippet, 0, 160)}"/><c:if test="${fn:length(w.snippet) gt 160}">…</c:if>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </c:otherwise>
    </c:choose>
  </c:if>

  <div class="btn-area">
    <a href="<c:url value='/rlms/prom/selectPromList.do'/>" class="krds-btn medium">규정 목록으로</a>
  </div>

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }
  </script>
</lay:layout>
