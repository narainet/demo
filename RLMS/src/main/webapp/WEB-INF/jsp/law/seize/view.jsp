<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/seize/view.jsp
  압류 상세 — LAW_MODULE_DESIGN.md §7.10. 상세 열람 시 조회수 증가(컨트롤러). 첨부 다운로드=표준 FileDown.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">압류 상세</c:set>
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
    <h1>압류 상세</h1>
    <p class="page-desc">가압류·가처분 사건 상세입니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <dl class="law-dl">
    <dt>담당부서</dt>
    <dd><c:out value="${seize.orgnztNm}" default="-"/></dd>
    <dt>채권자</dt>
    <dd><c:out value="${seize.creditor}" default="-"/></dd>
    <dt>채무자</dt>
    <dd><c:out value="${seize.debtor}" default="-"/></dd>
    <dt>제3채무자</dt>
    <dd><c:out value="${seize.thirdDebtor}" default="-"/></dd>
    <dt>관할법원</dt>
    <dd><c:out value="${seize.courtNm}" default="-"/></dd>
    <dt>사건번호</dt>
    <dd><c:out value="${seize.caseNo}" default="-"/></dd>
    <dt>메모</dt>
    <dd><c:out value="${seize.memo}" default="-"/></dd>
    <dt>등록일</dt>
    <dd><c:if test="${not empty seize.regDt and fn:length(seize.regDt) ge 8}">${fn:substring(seize.regDt,0,4)}-${fn:substring(seize.regDt,4,6)}-${fn:substring(seize.regDt,6,8)}</c:if></dd>
    <dt>조회수</dt>
    <dd><c:out value="${seize.readCnt}" default="0"/></dd>
    <dt>첨부파일</dt>
    <dd>
      <c:choose>
        <c:when test="${not empty seize.files}">
          <c:set var="encF" value="${egovc:encryptSession(seize.atchFileId, pageContext.session.id)}"/>
          <c:forEach var="f" items="${seize.files}">
            <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encF}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a>
          </c:forEach>
        </c:when>
        <c:otherwise>첨부 없음</c:otherwise>
      </c:choose>
    </dd>
  </dl>

  <div class="law-btn-bar">
    <a class="krds-btn primary large" href="<c:url value='/law/seize/edit.do'/>?seizeId=${seize.seizeId}">수정</a>
    <button type="button" class="krds-btn large" onclick="fnDelete();">삭제</button>
    <button type="button" class="krds-btn large" onclick="location.href='<c:url value="/law/seize/list.do"/>';">목록</button>
  </div>

  <script>
  function fnDelete(){
    if(!confirm('이 압류 정보를 삭제할까요?')) return;
    var p = new URLSearchParams(); p.set('seizeId', '<c:out value="${seize.seizeId}"/>');
    fetch('<c:url value="/law/seize/deleteJson.do"/>', { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.href='<c:url value="/law/seize/list.do"/>'; } else { alert(d.message||'삭제 실패'); } })
      .catch(function(){ alert('삭제 요청 실패'); });
  }
  </script>
</lay:layout>
