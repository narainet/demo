<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/lawquest/lawQuestList.jsp
  법령질의(법률자문 의뢰·회신) 목록. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">법령질의</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <c:set var="listUrl" value="${front ? '/rlms/lawquest/lawQuestFrontList.do' : '/rlms/lawquest/lawQuestList.do'}"/>
  <c:set var="viewUrl" value="${front ? '/rlms/lawquest/lawQuestFrontView.do' : '/rlms/lawquest/lawQuestView.do'}"/>

  <div class="page-header">
    <h1>법령질의</h1>
    <p class="page-desc">
      <c:choose>
        <c:when test="${front}">공개된 외부 법률자문 의뢰·회신 내역을 조회합니다.</c:when>
        <c:otherwise>외부 법률자문 의뢰·회신 내역을 관리합니다.</c:otherwise>
      </c:choose>
    </p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='${listUrl}'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <div class="form-group inline">
      <label class="form-label" for="searchYear">연도</label>
      <div class="form-conts">
        <select id="searchYear" name="searchYear" class="krds-select">
          <option value="" <c:if test="${empty searchVO.searchYear}">selected</c:if>>전체</option>
          <c:forEach var="y" items="${yearList}">
            <option value="${y}" <c:if test="${searchVO.searchYear eq y}">selected</c:if>>${y}</option>
          </c:forEach>
        </select>
      </div>
      <label class="form-label" for="searchType">자문유형</label>
      <div class="form-conts">
        <select id="searchType" name="searchType" class="krds-select">
          <option value=""     <c:if test="${empty searchVO.searchType}">selected</c:if>>전체</option>
          <option value="일반" <c:if test="${searchVO.searchType eq '일반'}">selected</c:if>>일반</option>
          <option value="개발" <c:if test="${searchVO.searchType eq '개발'}">selected</c:if>>개발</option>
          <option value="비축" <c:if test="${searchVO.searchType eq '비축'}">selected</c:if>>비축</option>
          <option value="건설" <c:if test="${searchVO.searchType eq '건설'}">selected</c:if>>건설</option>
        </select>
      </div>
      <label class="form-label" for="searchCnd">검색</label>
      <div class="form-conts">
        <select id="searchCnd" name="searchCnd" class="krds-select">
          <option value="subject" <c:if test="${searchVO.searchCnd eq 'subject'}">selected</c:if>>제목</option>
          <option value="gigwan"  <c:if test="${searchVO.searchCnd eq 'gigwan'}">selected</c:if>>자문기관</option>
          <option value="sosok"   <c:if test="${searchVO.searchCnd eq 'sosok'}">selected</c:if>>의뢰부서</option>
        </select>
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <div class="list-top">
    <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>
    <c:if test="${not front}">
      <span class="list-btns">
        <button type="button" class="krds-btn medium" onclick="fnExcel()">엑셀</button>
        <c:if test="${admin}">
          <a href="<c:url value='/rlms/lawquest/lawQuestAdminList.do'/>" class="krds-btn medium">답변자 관리</a>
        </c:if>
        <a href="<c:url value='/rlms/lawquest/lawQuestRegist.do'/>" class="krds-btn primary medium">등록</a>
      </span>
    </c:if>
  </div>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">연도</th>
        <th scope="col">유형</th>
        <th scope="col">제목</th>
        <th scope="col">의뢰부서</th>
        <th scope="col">자문기관</th>
        <th scope="col">금액</th>
        <th scope="col">첨부</th>
        <th scope="col">조회</th>
        <th scope="col">작성일</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="10" class="empty-row">등록된 법령질의가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="st">
            <tr>
              <td>${paginationInfo.totalRecordCount - (paginationInfo.currentPageNo-1)*paginationInfo.recordCountPerPage - st.index}</td>
              <td><c:out value="${row.year}"/></td>
              <td><c:out value="${row.type}"/></td>
              <td class="al">
                <a href="<c:url value='${viewUrl}'/>?no=${row.no}"><c:out value="${row.subject}"/></a>
              </td>
              <td><c:out value="${row.sosok}"/></td>
              <td><c:out value="${row.gigwan}"/></td>
              <td class="ar"><fmt:formatNumber value="${row.gumaek}" type="number"/></td>
              <td><c:if test="${row.attachCount > 0}">&#128206; ${row.attachCount}</c:if></td>
              <td><c:out value="${row.readnum}"/></td>
              <td><c:out value="${row.writeday}"/></td>
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
    function fnExcel() {
      var f = document.searchForm;
      var orig = f.getAttribute('action');
      f.setAttribute('action', '<c:url value="/rlms/lawquest/lawQuestExcel.do"/>');
      f.submit();
      f.setAttribute('action', orig);
    }
  </script>
</lay:layout>
