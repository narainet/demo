<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/doc/approvalList.jsp
  소송문서 승인 (LAW_MODULE_DESIGN.md §7.2, 레거시 sub02_01 "승인요청 현황").
  기본 탭=대기(S001) [승인][반려] / 처리 탭=완료(S002·S003, 처리자·일시·사유·상태필터).
  반려 사유 필수(모달). 자기 등록 문서 승인 허용. 처리는 POST JSON.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">문서 승인</c:set>
<c:set var="pageHead">
  
  <style>
    .law-cell-sub { color:#888; font-size:12px; }
    .law-file-link { display:block; font-size:13px; }
    .law-tabs { display:flex; gap:6px; border-bottom:2px solid #256ef4; margin:8px 0 16px; }
    .law-tab { padding:9px 20px; border:1px solid #ddd; border-bottom:none; border-radius:8px 8px 0 0; background:#f7f8fa; color:#555; text-decoration:none; font-size:14px; }
    .law-tab.on { background:#256ef4; color:#fff; border-color:#256ef4; font-weight:600; }
    .law-badge { display:inline-block; padding:2px 8px; border-radius:10px; font-size:12px; }
    .law-badge.appr { background:#e6f4ea; color:#1a7f37; }
    .law-badge.rjct { background:#fdecec; color:#c5303a; }
    <%-- 승인/반려 칩 버튼 = rlms-compat.css .law-chip-btn 공통 (approve/reject 변형 포함) --%>
    .law-modal-back { position: fixed; inset:0; background:rgba(0,0,0,.45); display:none; z-index:1000; }
    .law-modal { position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#fff; border-radius:12px;
                 padding:26px 30px; width:460px; max-width:calc(92vw / var(--rlms-zoom, 1)); display:none; z-index:1001; box-shadow:0 8px 30px rgba(0,0,0,.2); }
    .law-modal h2 { margin:0 0 16px; font-size:19px; }
    .law-modal textarea { width:100%; box-sizing:border-box; }
    .law-modal .modal-btns { margin-top:18px; display:flex; gap:8px; justify-content:flex-end; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>문서 승인</h1>
    <p class="page-desc">등록된 소송문서의 승인·반려를 처리합니다. 문서가 수정되면 다시 대기로 전환됩니다.</p>
  </div>

  <div class="law-tabs">
    <a class="law-tab ${tab eq 'PENDING' ? 'on' : ''}" href="<c:url value='/law/doc/approvalList.do'/>?searchAppSts=S001">대기</a>
    <a class="law-tab ${tab eq 'DONE' ? 'on' : ''}" href="<c:url value='/law/doc/approvalList.do'/>?searchAppSts=DONE">처리 완료</a>
  </div>

  <c:if test="${tab eq 'DONE'}">
    <form id="searchForm" name="searchForm" action="<c:url value='/law/doc/approvalList.do'/>" method="get" class="krds-form search-form">
      <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
      <div class="form-group inline">
        <label class="form-label" for="searchAppSts">상태</label>
        <div class="form-conts">
          <select id="searchAppSts" name="searchAppSts" class="krds-select" onchange="document.getElementById('pageIndex').value=1; this.form.submit();">
            <option value="DONE" ${searchVO.searchAppSts eq 'DONE' ? 'selected' : ''}>전체</option>
            <option value="S002" ${searchVO.searchAppSts eq 'S002' ? 'selected' : ''}>승인</option>
            <option value="S003" ${searchVO.searchAppSts eq 'S003' ? 'selected' : ''}>반려</option>
          </select>
        </div>
      </div>
    </form>
  </c:if>
  <c:if test="${tab eq 'PENDING'}">
    <form id="searchForm" name="searchForm" action="<c:url value='/law/doc/approvalList.do'/>" method="get">
      <input type="hidden" name="searchAppSts" value="S001"/>
      <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    </form>
  </c:if>

  <p class="law-cell-sub" style="margin:8px 0 4px;">총 <c:out value="${resultCnt}"/>건</p>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:5%;">No</th>
        <th scope="col">문서종류</th>
        <th scope="col">문서명 · 파일</th>
        <th scope="col">사건번호</th>
        <th scope="col">사건명</th>
        <th scope="col" style="width:8%;">신청인</th>
        <th scope="col" style="width:10%;">신청일자</th>
        <c:choose>
          <c:when test="${tab eq 'PENDING'}"><th scope="col" style="width:12%;">처리</th></c:when>
          <c:otherwise>
            <th scope="col">상태</th>
            <th scope="col">처리자</th>
            <th scope="col">처리일시</th>
            <th scope="col">사유·의견</th>
          </c:otherwise>
        </c:choose>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:out value="${row.docKindNm}" default="-"/></td>
          <td>
            <c:out value="${row.docTitl}" default="(제목 없음)"/>
            <c:if test="${not empty row.files}">
              <c:set var="encF" value="${egovc:encryptSession(row.atchFileId, pageContext.session.id)}"/>
              <c:forEach var="f" items="${row.files}">
                <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encF}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a>
              </c:forEach>
            </c:if>
          </td>
          <td><a href="<c:url value='/law/suit/view.do'/>?suitId=${row.suitId}"><c:out value="${row.caseNo}" default="(미입력)"/></a></td>
          <td><c:out value="${row.caseNm}" default="-"/></td>
          <td><c:out value="${row.regUserNm}" default="${row.regUserId}"/></td>
          <td>
            <c:if test="${not empty row.regDt and fn:length(row.regDt) ge 8}"><fmt:parseDate value="${fn:substring(row.regDt,0,8)}" pattern="yyyyMMdd" var="rd"/><fmt:formatDate value="${rd}" pattern="yyyy-MM-dd"/></c:if>
          </td>
          <c:choose>
            <c:when test="${tab eq 'PENDING'}">
              <td>
                <button type="button" class="law-chip-btn approve" onclick="fnApprove(${row.docId});">승인</button>
                <button type="button" class="law-chip-btn reject" onclick="fnOpenReject(${row.docId});">반려</button>
              </td>
            </c:when>
            <c:otherwise>
              <td>
                <c:choose>
                  <c:when test="${row.appStsCd eq 'S002'}"><span class="law-badge appr">승인</span></c:when>
                  <c:otherwise><span class="law-badge rjct">반려</span></c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.appUserNm}" default="${row.appUserId}"/></td>
              <td><c:if test="${not empty row.appDt and fn:length(row.appDt) ge 12}">${fn:substring(row.appDt,0,4)}-${fn:substring(row.appDt,4,6)}-${fn:substring(row.appDt,6,8)} ${fn:substring(row.appDt,8,10)}:${fn:substring(row.appDt,10,12)}</c:if></td>
              <td style="white-space:pre-wrap;"><c:out value="${row.appOpinion}" default="-"/></td>
            </c:otherwise>
          </c:choose>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="${tab eq 'PENDING' ? 8 : 11}" style="text-align:center; padding:32px 0; color:#888;">
          <c:choose><c:when test="${tab eq 'PENDING'}">승인 대기 중인 문서가 없습니다.</c:when><c:otherwise>처리된 문서가 없습니다.</c:otherwise></c:choose>
        </td></tr>
      </c:if>
    </tbody>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <%-- 반려 사유 모달 --%>
  <div class="law-modal-back" id="modalBack" onclick="fnCloseReject();"></div>
  <div class="law-modal" id="rejectModal" role="dialog" aria-modal="true" aria-labelledby="rjTitle">
    <h2 id="rjTitle">문서 반려</h2>
    <input type="hidden" id="rj_docId"/>
    <div>
      <label for="rj_opinion" style="display:block; font-size:14px; margin-bottom:5px;">반려 사유 <span style="color:#d3273e;">*</span></label>
      <textarea id="rj_opinion" rows="4" class="krds-input" maxlength="1000" placeholder="반려 사유를 입력하세요."></textarea>
    </div>
    <div class="modal-btns">
      <button type="button" class="krds-btn medium" onclick="fnCloseReject();">취소</button>
      <button type="button" class="krds-btn primary medium" onclick="fnReject();">반려 처리</button>
    </div>
  </div>

  <script>
  var APPROVE_URL = '<c:url value="/law/doc/approveJson.do"/>';
  function fnLinkPage(pageNo){ document.getElementById('pageIndex').value = pageNo; document.getElementById('searchForm').submit(); }

  function fnPost(docId, action, opinion, ok){
    var p = new URLSearchParams(); p.set('docId', docId); p.set('action', action); if(opinion!=null) p.set('opinion', opinion);
    fetch(APPROVE_URL, { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ ok(); } else { alert(d.message||'처리 실패'); } })
      .catch(function(){ alert('처리 요청 실패'); });
  }
  function fnApprove(docId){ if(!confirm('이 문서를 승인할까요?')) return; fnPost(docId, 'approve', null, function(){ location.reload(); }); }
  function fnOpenReject(docId){ document.getElementById('rj_docId').value = docId; document.getElementById('rj_opinion').value=''; document.getElementById('modalBack').style.display='block'; document.getElementById('rejectModal').style.display='block'; document.getElementById('rj_opinion').focus(); }
  function fnCloseReject(){ document.getElementById('modalBack').style.display='none'; document.getElementById('rejectModal').style.display='none'; }
  function fnReject(){
    var op = document.getElementById('rj_opinion').value.trim();
    if(!op){ alert('반려 사유를 입력하세요.'); return; }
    fnPost(document.getElementById('rj_docId').value, 'reject', op, function(){ location.reload(); });
  }
  </script>
</lay:layout>
