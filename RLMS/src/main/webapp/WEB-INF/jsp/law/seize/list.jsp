<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/seize/list.jsp
  압류관리(가압류·가처분) 목록 — LAW_MODULE_DESIGN.md §7.10, 레거시 tc_seize.
  조건: 등록일자 기간 + 검색축 select + 키워드. 그리드: 담당부서/채권자/채무자/제3채무자/관할법원/사건번호/등록일/첨부/관리.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">압류관리</c:set>
<c:set var="pageHead">
  
  <style>
    .law-cell-sub { color:#888; font-size:12px; }
    .law-list-head { display:flex; justify-content:flex-end; margin:8px 0 12px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>압류관리</h1>
    <p class="page-desc">가압류·가처분 사건을 등록·조회합니다. 첨부는 문서파일 5개·개당 10MB 이내입니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/seize/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="form-group inline">
      <label class="form-label" for="searchAxis">검색조건</label>
      <div class="form-conts">
        <select id="searchAxis" name="searchAxis" class="krds-select">
          <option value="" ${empty searchVO.searchAxis ? 'selected' : ''}>전체</option>
          <option value="ORGNZT" ${searchVO.searchAxis eq 'ORGNZT' ? 'selected' : ''}>담당부서</option>
          <option value="CREDITOR" ${searchVO.searchAxis eq 'CREDITOR' ? 'selected' : ''}>채권자</option>
          <option value="DEBTOR" ${searchVO.searchAxis eq 'DEBTOR' ? 'selected' : ''}>채무자</option>
          <option value="THIRD_DEBTOR" ${searchVO.searchAxis eq 'THIRD_DEBTOR' ? 'selected' : ''}>제3채무자</option>
          <option value="COURT" ${searchVO.searchAxis eq 'COURT' ? 'selected' : ''}>관할법원</option>
          <option value="CASE_NO" ${searchVO.searchAxis eq 'CASE_NO' ? 'selected' : ''}>사건번호</option>
        </select>
      </div>
      <label class="form-label" for="searchKeyword">키워드</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input" maxlength="100"
               value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="검색어"/>
      </div>
      <label class="form-label" for="searchFrom">등록일자</label>
      <div class="form-conts">
        <input type="date" id="searchFrom" name="searchFrom" class="krds-input" value="<c:out value='${searchVO.searchFrom}'/>"/>
        <span>~</span>
        <input type="date" id="searchTo" name="searchTo" class="krds-input" value="<c:out value='${searchVO.searchTo}'/>"/>
      </div>
      <button type="button" class="krds-btn primary medium" onclick="document.getElementById('pageIndex').value=1; document.getElementById('searchForm').submit();">검색</button>
      <a href="<c:url value='/law/seize/list.do'/>" class="krds-btn medium">초기화</a>
    </div>
  </form>

  <div class="law-list-head">
    <a class="krds-btn primary medium" href="<c:url value='/law/seize/regist.do'/>">등록</a>
  </div>

  <p class="law-total">총 <strong><c:out value="${resultCnt}"/></strong>건</p>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">No</th>
        <th scope="col" style="width:8%;">담당부서</th>
        <th scope="col">채권자</th>
        <th scope="col">채무자</th>
        <th scope="col">제3채무자</th>
        <th scope="col">관할법원</th>
        <th scope="col">사건번호</th>
        <th scope="col" style="width:8%;">등록일</th>
        <th scope="col" style="width:4%;">첨부</th>
        <th scope="col" style="width:10%;">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:out value="${row.orgnztNm}" default="-"/></td>
          <td><a href="<c:url value='/law/seize/view.do'/>?seizeId=${row.seizeId}"><c:out value="${row.creditor}" default="-"/></a></td>
          <td><c:out value="${row.debtor}" default="-"/></td>
          <td><c:out value="${row.thirdDebtor}" default="-"/></td>
          <td><c:out value="${row.courtNm}" default="-"/></td>
          <td><c:out value="${row.caseNo}" default="-"/></td>
          <td><c:if test="${not empty row.regDt and fn:length(row.regDt) ge 8}">${fn:substring(row.regDt,0,4)}-${fn:substring(row.regDt,4,6)}-${fn:substring(row.regDt,6,8)}</c:if></td>
          <td style="text-align:center;"><c:choose><c:when test="${not empty row.atchFileId and fn:trim(row.atchFileId) ne ''}">Y</c:when><c:otherwise>-</c:otherwise></c:choose></td>
          <td>
            <a class="law-chip-btn" href="<c:url value='/law/seize/edit.do'/>?seizeId=${row.seizeId}">수정</a>
            <button type="button" class="law-chip-btn" onclick="fnDelete(${row.seizeId});">삭제</button>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="10" style="text-align:center; padding:32px 0; color:#888;">조회된 압류 정보가 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <script>
  function fnLinkPage(pageNo){ document.getElementById('pageIndex').value = pageNo; document.getElementById('searchForm').submit(); }
  function fnDelete(seizeId){
    if(!confirm('이 압류 정보를 삭제할까요?')) return;
    var p = new URLSearchParams(); p.set('seizeId', seizeId);
    fetch('<c:url value="/law/seize/deleteJson.do"/>', { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'삭제 실패'); } })
      .catch(function(){ alert('삭제 요청 실패'); });
  }
  </script>
</lay:layout>
