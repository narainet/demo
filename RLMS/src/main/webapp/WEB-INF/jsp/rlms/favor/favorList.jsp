<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/favor/favorList.jsp
  내 즐겨찾기 페이지 (개인 격리). KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">즐겨찾기</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>즐겨찾기</h1>
    <p class="page-desc">내가 표시한 즐겨찾기 조항을 관리합니다.</p>
  </div>

  <style>
    tr.favor-stale td { color: #98a2b3; }
    .favor-stale-badge { display:inline-block; margin-left:6px; padding:1px 7px; border-radius:10px;
                         background:#fef0f0; color:#d92d20; font-size:12px; font-weight:600; }
    .favor-muted { color:#98a2b3; }
  </style>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/favor/selectFavorList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <div class="form-group inline">
      <label class="form-label" for="searchGubun">분류</label>
      <div class="form-conts">
        <select id="searchGubun" name="searchGubun" class="krds-select">
          <%-- SGUBUN 실데이터: PROVISION(조문)/FULLTEXT(전문)/PROM(규정) — "분류" 컬럼과 동일 차원 --%>
          <option value=""          <c:if test="${empty searchVO.searchGubun}">selected</c:if>>전체</option>
          <option value="PROVISION" <c:if test="${searchVO.searchGubun eq 'PROVISION'}">selected</c:if>>조문</option>
          <option value="FULLTEXT"  <c:if test="${searchVO.searchGubun eq 'FULLTEXT'}">selected</c:if>>전문</option>
          <option value="PROM"      <c:if test="${searchVO.searchGubun eq 'PROM'}">selected</c:if>>규정</option>
        </select>
      </div>
      <label class="form-label" for="searchKeyword">키워드</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">분류</th>
        <th scope="col">규정</th>
        <th scope="col">조항</th>
        <th scope="col">메모</th>
        <th scope="col">등록일</th>
        <th scope="col">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="7" class="empty-row">즐겨찾기가 비어 있습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}">
            <tr<c:if test="${row.provDeleted eq 'Y'}"> class="favor-stale"</c:if>>
              <td><c:out value="${row.favorNo}"/></td>
              <td>
                <c:choose>
                  <c:when test="${row.gubun eq 'PROVISION'}">조문</c:when>
                  <c:when test="${row.gubun eq 'FULLTEXT'}">전문</c:when>
                  <c:when test="${row.gubun eq 'PROM'}">규정</c:when>
                  <c:otherwise>기타</c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:choose>
                  <c:when test="${not empty row.promTitle}"><c:out value="${row.promTitle}"/><c:if test="${row.pendingYn eq 'Y'}"> <span class="krds-badge bg-light-information" title="현행본이 공포되었으나 아직 시행 전입니다">시행예정</span></c:if></c:when>
                  <c:otherwise><span class="favor-muted">(현행 없음 · 규정번호 <c:out value="${row.lawId}"/>)</span></c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:out value="${row.item}"/>
                <c:if test="${row.provDeleted eq 'Y'}"><span class="favor-stale-badge">삭제된 조문</span></c:if>
              </td>
              <td><c:out value="${row.description}"/></td>
              <td><c:out value="${row.insDt}"/></td>
              <td>
                <button type="button" class="krds-btn danger small btn-del"
                        data-favor-no="<c:out value='${row.favorNo}'/>">삭제</button>
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
    $('.btn-del').on('click', function() {
      var no = $(this).data('favor-no');
      if (!confirm('삭제하시겠습니까?')) return;
      $.post('<c:url value="/rlms/favor/deleteFavor.do"/>', { favorNo: no })
       .done(function(res) {
         if (res.ok) location.reload();
         else alert(res.error || '삭제 실패');
       });
    });
  </script>
</lay:layout>
