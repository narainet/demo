<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/receipt/view.jsp
  법원서류접수 상세 — LAW_MODULE_DESIGN.md §7.11. 제목/등록부서/관련부서1·2/첨부/등록일. 첨부 다운로드=표준 FileDown.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">법원서류접수 상세</c:set>
<c:set var="pageHead">
  
  <style>
    .law-dl { display:grid; grid-template-columns: 140px 1fr; gap:1px; background:#e5e7eb; border:1px solid #e5e7eb; }
    .law-dl dt { background:#f7f8fa; padding:9px 12px; font-size:14px; color:#333; margin:0; }
    .law-dl dd { background:#fff; padding:9px 12px; font-size:14px; margin:0; white-space:pre-wrap; }
    .law-file-link { display:block; font-size:13px; }
    .law-btn-bar { margin-top:24px; display:flex; gap:8px; justify-content:center; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>법원서류접수 상세</h1>
    <p class="page-desc">법원서류 접수 상세입니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <dl class="law-dl">
    <dt>제목</dt>
    <dd><c:out value="${receipt.receiptTitl}" default="-"/></dd>
    <dt>등록부서</dt>
    <dd><c:out value="${receipt.orgnztNm}" default="-"/></dd>
    <dt>관련부서 1</dt>
    <dd><c:out value="${receipt.relOrgnztNm1}" default="-"/></dd>
    <dt>관련부서 2</dt>
    <dd><c:out value="${receipt.relOrgnztNm2}" default="-"/></dd>
    <dt>등록일</dt>
    <dd><c:if test="${not empty receipt.regDt and fn:length(receipt.regDt) ge 8}">${fn:substring(receipt.regDt,0,4)}-${fn:substring(receipt.regDt,4,6)}-${fn:substring(receipt.regDt,6,8)}</c:if></dd>
    <dt>관련자료</dt>
    <dd>
      <c:choose>
        <c:when test="${not empty receipt.files}">
          <c:set var="encF" value="${egovc:encryptSession(receipt.atchFileId, pageContext.session.id)}"/>
          <c:forEach var="f" items="${receipt.files}">
            <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encF}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a>
          </c:forEach>
        </c:when>
        <c:otherwise>첨부 없음</c:otherwise>
      </c:choose>
    </dd>
  </dl>

  <div class="law-btn-bar">
    <button type="button" class="krds-btn large" onclick="fnDelete();">삭제</button>
    <button type="button" class="krds-btn large" onclick="location.href='<c:url value="/law/receipt/list.do"/>';">목록</button>
  </div>

  <script>
  function fnDelete(){
    if(!confirm('이 접수 정보를 삭제할까요?')) return;
    var p = new URLSearchParams(); p.set('receiptId', '<c:out value="${receipt.receiptId}"/>');
    fetch('<c:url value="/law/receipt/deleteJson.do"/>', { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.href='<c:url value="/law/receipt/list.do"/>'; } else { alert(d.message||'삭제 실패'); } })
      .catch(function(){ alert('삭제 요청 실패'); });
  }
  </script>
</lay:layout>
