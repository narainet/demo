<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/receipt/list.jsp
  법원서류접수 — LAW_MODULE_DESIGN.md §7.11, 레거시 tbetia44.
  조건: 등록일자 기간+제목 검색. 목록: 번호/등록일자/제목/부서명/첨부. 인라인 등록 폼(제목/관련자료/관련부서1·2).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">법원서류접수</c:set>
<c:set var="pageHead">
  
  <style>
    .law-cell-sub { color:#888; font-size:12px; }
    .law-list-head { display:flex; justify-content:flex-end; margin:8px 0 12px; }
    .law-reg-box { border:1px solid #cdd9f5; background:#f4f7ff; border-radius:8px; padding:16px 18px; margin:8px 0 16px; display:none; }
    .law-reg-grid { display:grid; grid-template-columns:120px 1fr 120px 1fr; gap:10px 12px; align-items:center; }
    .law-reg-grid label { font-size:14px; }
    .law-reg-grid .req:after { content:' *'; color:#d3273e; }
    .law-reg-grid input[type=text], .law-reg-grid select, .law-reg-grid input[type=file] { width:100%; box-sizing:border-box; }
    .law-reg-grid .span3 { grid-column:2 / span 3; }
    .law-reg-btns { margin-top:14px; display:flex; gap:8px; justify-content:flex-end; }
    .law-file-link { display:block; font-size:12px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>법원서류접수</h1>
    <p class="page-desc">법원서류를 접수하고 관련부서를 지정합니다. (관련부서 알림 발송은 제공하지 않습니다)</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/receipt/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="form-group inline">
      <label class="form-label" for="searchKeyword">제목</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input" maxlength="100"
               value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="제목 키워드"/>
      </div>
      <label class="form-label" for="searchFrom">등록일자</label>
      <div class="form-conts">
        <input type="date" id="searchFrom" name="searchFrom" class="krds-input" value="<c:out value='${searchVO.searchFrom}'/>"/>
        <span>~</span>
        <input type="date" id="searchTo" name="searchTo" class="krds-input" value="<c:out value='${searchVO.searchTo}'/>"/>
      </div>
      <button type="button" class="krds-btn primary medium" onclick="document.getElementById('pageIndex').value=1; document.getElementById('searchForm').submit();">검색</button>
      <a href="<c:url value='/law/receipt/list.do'/>" class="krds-btn medium">초기화</a>
    </div>
  </form>

  <div class="law-list-head">
    <button type="button" class="krds-btn primary medium" onclick="fnToggleReg();">접수 등록</button>
  </div>

  <%-- 인라인 등록 폼 --%>
  <div class="law-reg-box" id="regBox">
    <form id="regForm" class="krds-form" action="<c:url value='/law/receipt/save.do'/>" method="post" enctype="multipart/form-data">
      <table class="krds-table tbl-detail" style="margin-top:0;">
        <colgroup><col style="width:16%"/><col/></colgroup>
        <tbody>
          <tr>
            <th scope="row"><label class="form-label required" for="receiptTitl">제목</label></th>
            <td style="text-align:left;"><input type="text" id="receiptTitl" name="receiptTitl" class="krds-input" style="width:100%; box-sizing:border-box;" maxlength="200"/></td>
          </tr>
          <tr>
            <th scope="row"><label class="form-label" for="relOrgnztId1">관련부서 1</label></th>
            <td style="text-align:left;">
              <select id="relOrgnztId1" name="relOrgnztId1" class="krds-select">
                <option value="">선택</option>
                <c:forEach var="og" items="${orgnzts}"><option value="<c:out value='${og.orgnztId}'/>"><c:out value="${og.orgnztNm}"/></option></c:forEach>
              </select>
            </td>
          </tr>
          <tr>
            <th scope="row"><label class="form-label" for="relOrgnztId2">관련부서 2</label></th>
            <td style="text-align:left;">
              <select id="relOrgnztId2" name="relOrgnztId2" class="krds-select">
                <option value="">선택</option>
                <c:forEach var="og" items="${orgnzts}"><option value="<c:out value='${og.orgnztId}'/>"><c:out value="${og.orgnztNm}"/></option></c:forEach>
              </select>
            </td>
          </tr>
          <tr>
            <th scope="row"><label class="form-label" for="file_1">관련자료</label></th>
            <td style="text-align:left;">
              <c:set var="aId" value="file_1" scope="request"/>
              <c:set var="aName" value="file_1" scope="request"/>
              <c:set var="aExistFiles" value="${null}" scope="request"/>
              <jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
            </td>
          </tr>
        </tbody>
      </table>
      <div class="law-reg-btns">
        <button type="button" class="krds-btn medium" onclick="fnToggleReg();">취소</button>
        <button type="button" class="krds-btn primary medium" onclick="fnRegSubmit();">저장</button>
      </div>
    </form>
  </div>

  <p class="law-total">총 <strong><c:out value="${resultCnt}"/></strong>건</p>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">No</th>
        <th scope="col" style="width:8%;">등록일자</th>
        <th scope="col">제목</th>
        <th scope="col" style="width:8%;">부서명</th>
        <th scope="col">첨부파일</th>
        <th scope="col" style="width:6%;">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:if test="${not empty row.regDt and fn:length(row.regDt) ge 8}">${fn:substring(row.regDt,0,4)}-${fn:substring(row.regDt,4,6)}-${fn:substring(row.regDt,6,8)}</c:if></td>
          <td><a href="<c:url value='/law/receipt/view.do'/>?receiptId=${row.receiptId}"><c:out value="${row.receiptTitl}" default="(제목 없음)"/></a></td>
          <td><c:out value="${row.orgnztNm}" default="-"/></td>
          <td>
            <c:choose>
              <c:when test="${not empty row.files}">
                <c:set var="encF" value="${egovc:encryptSession(row.atchFileId, pageContext.session.id)}"/>
                <c:forEach var="f" items="${row.files}">
                  <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encF}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a>
                </c:forEach>
              </c:when>
              <c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
          <td><button type="button" class="law-chip-btn" onclick="fnDelete(${row.receiptId});">삭제</button></td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="6" style="text-align:center; padding:32px 0; color:#888;">접수된 법원서류가 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <script>
  function fnLinkPage(pageNo){ document.getElementById('pageIndex').value = pageNo; document.getElementById('searchForm').submit(); }
  function fnToggleReg(){ var b=document.getElementById('regBox'); b.style.display = b.style.display==='block' ? 'none' : 'block'; if(b.style.display==='block'){ document.getElementById('receiptTitl').focus(); } }
  function fnRegSubmit(){
    if(!document.getElementById('receiptTitl').value.trim()){ alert('제목을 입력하세요.'); document.getElementById('receiptTitl').focus(); return; }
    document.getElementById('regForm').submit();
  }
  function fnDelete(receiptId){
    if(!confirm('이 접수 정보를 삭제할까요?')) return;
    var p = new URLSearchParams(); p.set('receiptId', receiptId);
    fetch('<c:url value="/law/receipt/deleteJson.do"/>', { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'삭제 실패'); } })
      .catch(function(){ alert('삭제 요청 실패'); });
  }
  </script>
</lay:layout>
