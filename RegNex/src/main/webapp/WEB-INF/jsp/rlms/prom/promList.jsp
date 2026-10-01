<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/promList.jsp

  규정 목록 — 페이징/검색/등록·삭제 진입. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">규정 목록</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>규정 목록</h1>
    <p class="page-desc">규정(사규) 본문을 등록·수정·삭제합니다.</p>
  </div>

  <c:if test="${not empty resultMsg}">
    <div class="krds-alert success"><c:out value="${resultMsg}"/></div>
  </c:if>

  <!-- 검색 -->
  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/prom/selectPromList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <div class="form-group inline">
      <label class="form-label" for="searchCnd">검색 조건</label>
      <div class="form-conts">
        <select id="searchCnd" name="searchCnd" class="krds-select">
          <option value="0" <c:if test="${searchVO.searchCnd eq '0'}">selected</c:if>>제목</option>
          <option value="1" <c:if test="${searchVO.searchCnd eq '1'}">selected</c:if>>본문</option>
          <option value="2" <c:if test="${searchVO.searchCnd eq '2'}">selected</c:if>>분류</option>
          <option value="3" <c:if test="${searchVO.searchCnd eq '3'}">selected</c:if>>부서</option>
        </select>
      </div>
      <label class="form-label" for="searchKeyword">검색어</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="키워드 입력"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
      <%-- #3: 규정 등록/수정은 규정 IDE 로 일원화 — 옛 insertPromView 폼 대신 IDE 진입(분류 선택 후 신규) --%>
      <button type="button" class="krds-btn medium"
              onclick="location.href='<c:url value="/rlms/prom/editor.do"/>'">규정 IDE 열기</button>
      <button type="button" class="krds-btn medium"
              onclick="location.href='<c:url value="/rlms/prom/searchFullText.do"/>'">본문 전문 검색</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <form id="multiForm" name="multiForm" action="<c:url value='/rlms/prom/deletePromList.do'/>" method="post">
    <input type="hidden" name="promNoList" id="promNoList"/>
    <table class="krds-table tbl-list">
      <thead>
        <tr>
          <th scope="col"><input type="checkbox" id="chkAll"/></th>
          <th scope="col">No</th>
          <th scope="col">제목</th>
          <th scope="col">규정번호</th>
          <th scope="col">분류</th>
          <th scope="col">담당부서</th>
          <th scope="col">공포일</th>
          <th scope="col">시행일</th>
          <th scope="col">유효</th>
          <th scope="col">관리</th>
        </tr>
      </thead>
      <tbody>
        <c:choose>
          <c:when test="${empty resultList}">
            <tr><td colspan="10" class="empty-row">등록된 규정이 없습니다.</td></tr>
          </c:when>
          <c:otherwise>
            <c:forEach var="row" items="${resultList}">
              <tr>
                <td><input type="checkbox" name="chk" value="<c:out value='${row.promNo}'/>" class="row-chk"/></td>
                <td><c:out value="${row.promNo}"/></td>
                <td>
                  <a href="<c:url value='/rlms/prom/selectPromDetail.do'/>?promNo=<c:out value='${row.promNo}'/>">
                    <c:out value="${row.title}"/>
                  </a>
                </td>
                <td><c:out value="${row.number}"/></td>
                <td><c:out value="${row.cateFullNm}"/></td>
                <td><c:out value="${row.buseoNm}"/></td>
                <td><c:out value="${row.promDate}"/></td>
                <td><c:out value="${row.startDate}"/></td>
                <td>${row.existingYn eq 'Y' ? '현행' : '이전'}</td>
                <td>
                  <a href="<c:url value='/rlms/prom/editor.do'/>?promNo=<c:out value='${row.promNo}'/>"
                     class="krds-btn small">편집</a>
                  <button type="button" class="krds-btn danger small"
                          onclick="fnDelete('<c:out value="${row.promNo}"/>');">삭제</button>
                </td>
              </tr>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </tbody>
    </table>

    <c:if test="${not empty resultList}">
      <div class="btn-area right">
        <button type="button" class="krds-btn danger medium" onclick="fnDeleteMulti();">선택 삭제</button>
      </div>
    </c:if>
  </form>

  <div class="krds-pagination">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <form id="deleteForm" name="deleteForm" action="<c:url value='/rlms/prom/deleteProm.do'/>" method="post">
    <input type="hidden" name="promNo" id="deletePromNo"/>
  </form>

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }
    function fnDelete(promNo) {
      if (!confirm('정말 삭제하시겠습니까?')) return;
      document.getElementById('deletePromNo').value = promNo;
      document.deleteForm.submit();
    }
    function fnDeleteMulti() {
      var ids = [];
      document.querySelectorAll('.row-chk:checked').forEach(function(el){ ids.push(el.value); });
      if (ids.length === 0) { alert('항목을 선택하세요.'); return; }
      if (!confirm('선택한 ' + ids.length + '건을 삭제하시겠습니까?')) return;
      document.getElementById('promNoList').value = ids.join(',');
      document.getElementById('multiForm').submit();
    }
    document.getElementById('chkAll').addEventListener('change', function(){
      var c = this.checked;
      document.querySelectorAll('.row-chk').forEach(function(el){ el.checked = c; });
    });
  </script>
</lay:layout>
