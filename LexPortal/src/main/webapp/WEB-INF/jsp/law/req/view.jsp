<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/req/view.jsp
  소송의뢰 상세(법무팀 mgr) — LAW_MODULE_DESIGN.md §7.9.
  신청 내용 전체(사실관계·경과·첨부·보조자) + [승인]/[반려(사유 필수)] + 승인분 소송등록 연계.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송의뢰 상세</c:set>
<c:set var="pageHead">
  
  <style>
    .law-view-sec { margin: 22px 0 8px; padding-bottom: 6px; border-bottom: 2px solid #222; font-size: 16px; font-weight: 700; }
    .law-dl { display:grid; grid-template-columns: 140px 1fr; gap:1px; background:#e5e7eb; border:1px solid #e5e7eb; }
    .law-dl dt { background:#f7f8fa; padding:9px 12px; font-size:14px; color:#333; margin:0; }
    .law-dl dd { background:#fff; padding:9px 12px; font-size:14px; margin:0; white-space:pre-wrap; }
    .law-sub-table { width:100%; border-collapse:collapse; margin-top:6px; }
    .law-sub-table th, .law-sub-table td { border:1px solid #ddd; padding:6px 8px; font-size:13px; text-align:left; }
    .law-sub-table th { background:#f7f8fa; }
    .law-file-link { display:block; font-size:13px; }
    .law-badge { display:inline-block; padding:2px 10px; border-radius:10px; font-size:13px; }
    .law-badge.req  { background:#eef2ff; color:#3651d4; }
    .law-badge.appr { background:#e6f4ea; color:#1a7f37; }
    .law-badge.rjct { background:#fdecec; color:#c5303a; }
    .law-btn-bar { margin-top:24px; display:flex; gap:8px; justify-content:center; }
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
    <h1>소송의뢰 상세</h1>
    <p class="page-desc">신청 내용을 검토하여 승인·반려하고, 승인분은 소송으로 등록합니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <div class="law-view-sec">기본 정보</div>
  <dl class="law-dl">
    <dt>상태</dt>
    <dd>
      <c:choose>
        <c:when test="${req.statusCd eq 'S002'}"><span class="law-badge appr">승인</span></c:when>
        <c:when test="${req.statusCd eq 'S003'}"><span class="law-badge rjct">반려</span></c:when>
        <c:otherwise><span class="law-badge req">신청</span></c:otherwise>
      </c:choose>
    </dd>
    <dt>사건명</dt>
    <dd><c:out value="${req.reqTitl}" default="-"/></dd>
    <dt>의뢰부서</dt>
    <dd><c:out value="${req.reqOrgnztNm}" default="-"/></dd>
    <dt>의뢰담당자</dt>
    <dd><c:out value="${req.reqUserNm}" default="${req.reqUserId}"/></dd>
    <dt>의뢰일자</dt>
    <dd><c:if test="${not empty req.reqDt and fn:length(req.reqDt) ge 8}">${fn:substring(req.reqDt,0,4)}-${fn:substring(req.reqDt,4,6)}-${fn:substring(req.reqDt,6,8)}</c:if></dd>
    <c:if test="${req.statusCd ne 'S001'}">
      <dt>처리자</dt>
      <dd><c:out value="${req.aprvUserNm}" default="${req.aprvUserId}"/></dd>
      <dt>처리일시</dt>
      <dd><c:if test="${not empty req.aprvDt and fn:length(req.aprvDt) ge 12}">${fn:substring(req.aprvDt,0,4)}-${fn:substring(req.aprvDt,4,6)}-${fn:substring(req.aprvDt,6,8)} ${fn:substring(req.aprvDt,8,10)}:${fn:substring(req.aprvDt,10,12)}</c:if></dd>
    </c:if>
    <c:if test="${req.statusCd eq 'S003'}">
      <dt>반려 사유</dt>
      <dd><c:out value="${req.returnRsn}" default="-"/></dd>
    </c:if>
    <c:if test="${not empty req.suitId}">
      <dt>연계 사건</dt>
      <dd><a href="<c:url value='/law/suit/view.do'/>?suitId=${req.suitId}"><c:out value="${req.caseNo}" default="사건 보기"/></a></dd>
    </c:if>
  </dl>

  <div class="law-view-sec">사실관계</div>
  <div style="border:1px solid #e5e7eb; background:#fff; padding:12px; font-size:14px; white-space:pre-wrap; min-height:48px;"><c:out value="${req.reqCn}" default="(입력 없음)"/></div>

  <div class="law-view-sec">기타 자료</div>
  <c:choose>
    <c:when test="${not empty req.files}">
      <c:set var="encReq" value="${egovc:encryptSession(req.atchFileId, pageContext.session.id)}"/>
      <c:forEach var="f" items="${req.files}">
        <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encReq}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a>
      </c:forEach>
    </c:when>
    <c:otherwise><span style="color:#888; font-size:13px;">첨부 없음</span></c:otherwise>
  </c:choose>

  <div class="law-view-sec">사건 경과 내역</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:210px;">기간</th><th>내용</th><th style="width:220px;">첨부</th></tr></thead>
    <tbody>
      <c:forEach var="h" items="${req.hists}">
        <tr>
          <td>
            <c:if test="${not empty h.staDt and fn:length(h.staDt) ge 8}">${fn:substring(h.staDt,0,4)}-${fn:substring(h.staDt,4,6)}-${fn:substring(h.staDt,6,8)}</c:if>
            <c:if test="${not empty h.endDt and fn:length(h.endDt) ge 8}"> ~ ${fn:substring(h.endDt,0,4)}-${fn:substring(h.endDt,4,6)}-${fn:substring(h.endDt,6,8)}</c:if>
          </td>
          <td style="white-space:pre-wrap;"><c:out value="${h.histCn}"/></td>
          <td>
            <c:if test="${not empty h.files}">
              <c:set var="encH" value="${egovc:encryptSession(h.atchFileId, pageContext.session.id)}"/>
              <c:forEach var="hf" items="${h.files}">
                <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encH}&amp;fileSn=${hf.fileSn}"><c:out value="${hf.orignlFileNm}"/></a>
              </c:forEach>
            </c:if>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty req.hists}"><tr><td colspan="3" style="text-align:center; color:#888;">경과 내역 없음</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-view-sec">소송수행 보조자</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:160px;">부서</th><th style="width:120px;">담당자</th><th>전화</th><th>휴대폰</th><th>이메일</th></tr></thead>
    <tbody>
      <c:forEach var="hp" items="${req.helpers}">
        <tr>
          <td><c:out value="${hp.deptNm}"/></td>
          <td><c:out value="${hp.helperNm}"/></td>
          <td><c:out value="${hp.tel}"/></td>
          <td><c:out value="${hp.mobile}"/></td>
          <td><c:out value="${hp.email}"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty req.helpers}"><tr><td colspan="5" style="text-align:center; color:#888;">보조자 없음</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-btn-bar">
    <c:if test="${req.statusCd eq 'S001'}">
      <button type="button" class="krds-btn primary large" onclick="fnApprove();">승인</button>
      <button type="button" class="krds-btn large" onclick="fnOpenReject();">반려</button>
    </c:if>
    <c:if test="${req.statusCd eq 'S002' and empty req.suitId}">
      <a class="krds-btn primary large" href="<c:url value='/law/suit/regist.do'/>?reqId=${req.reqId}">소송등록</a>
    </c:if>
    <c:if test="${not empty req.suitId}">
      <a class="krds-btn large" href="<c:url value='/law/suit/view.do'/>?suitId=${req.suitId}">연계 사건 보기</a>
    </c:if>
    <button type="button" class="krds-btn large" onclick="location.href='<c:url value="/law/req/list.do"/>';">목록</button>
  </div>

  <%-- 반려 사유 모달 --%>
  <div class="law-modal-back" id="modalBack" onclick="fnCloseReject();"></div>
  <div class="law-modal" id="rejectModal" role="dialog" aria-modal="true" aria-labelledby="rjTitle">
    <h2 id="rjTitle">의뢰 반려</h2>
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
  var APPROVE_URL = '<c:url value="/law/req/approveJson.do"/>';
  var REQ_ID = '<c:out value="${req.reqId}"/>';
  function fnPost(action, opinion, ok){
    var p = new URLSearchParams(); p.set('reqId', REQ_ID); p.set('action', action); if(opinion!=null) p.set('opinion', opinion);
    fetch(APPROVE_URL, { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ ok(); } else { alert(d.message||'처리 실패'); } })
      .catch(function(){ alert('처리 요청 실패'); });
  }
  function fnApprove(){ if(!confirm('이 의뢰를 승인할까요?')) return; fnPost('approve', null, function(){ location.reload(); }); }
  function fnOpenReject(){ document.getElementById('rj_opinion').value=''; document.getElementById('modalBack').style.display='block'; document.getElementById('rejectModal').style.display='block'; document.getElementById('rj_opinion').focus(); }
  function fnCloseReject(){ document.getElementById('modalBack').style.display='none'; document.getElementById('rejectModal').style.display='none'; }
  function fnReject(){
    var op = document.getElementById('rj_opinion').value.trim();
    if(!op){ alert('반려 사유를 입력하세요.'); return; }
    fnPost('reject', op, function(){ location.reload(); });
  }
  </script>
</lay:layout>
