<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/req/list.jsp
  소송의뢰 관리(법무팀 mgr) — LAW_MODULE_DESIGN.md §7.9, 레거시 sub01_02 "소송의뢰 조회".
  조건: 등록일자 기간·상태·사건명. 그리드: 상태/사건명/의뢰부서/담당자/의뢰일자/처리(승인·반려)/소송등록/처리자·일시·사유.
  승인·반려는 인라인 모달(POST JSON), 소송등록은 승인분에 한해 /law/suit/regist.do?reqId= 연계.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송의뢰관리</c:set>
<c:set var="pageHead">
  
  <style>
    .law-cell-sub { color:#888; font-size:12px; }
    .law-badge { display:inline-block; padding:2px 8px; border-radius:10px; font-size:12px; white-space:nowrap; }
    .law-badge.req  { background:#eef2ff; color:#3651d4; }
    .law-badge.appr { background:#e6f4ea; color:#1a7f37; }
    .law-badge.rjct { background:#fdecec; color:#c5303a; }
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
    <h1>소송의뢰관리</h1>
    <p class="page-desc">사용자가 신청한 소송의뢰를 검토하여 승인·반려하고, 승인분은 소송으로 등록합니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/req/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="form-group inline">
      <label class="form-label" for="searchFrom">등록일자</label>
      <div class="form-conts" style="display:flex; gap:6px; align-items:center;">
        <input type="date" id="searchFrom" name="searchFrom" class="krds-input" value="<c:out value='${searchVO.searchFrom}'/>"/>
        <span>~</span>
        <input type="date" id="searchTo" name="searchTo" class="krds-input" value="<c:out value='${searchVO.searchTo}'/>"/>
      </div>
    </div>
    <div class="form-group inline">
      <label class="form-label" for="searchStatus">상태</label>
      <div class="form-conts">
        <select id="searchStatus" name="searchStatus" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="st" items="${statuses}">
            <option value="<c:out value='${st.code}'/>" ${searchVO.searchStatus eq st.code ? 'selected' : ''}><c:out value="${st.codeNm}"/></option>
          </c:forEach>
        </select>
      </div>
    </div>
    <div class="form-group inline">
      <label class="form-label" for="searchKeyword">사건명</label>
      <div class="form-conts" style="display:flex; gap:6px;">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input" maxlength="100"
               value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="사건명 키워드"/>
        <button type="button" class="krds-btn primary medium" onclick="document.getElementById('pageIndex').value=1; document.getElementById('searchForm').submit();">검색</button>
      </div>
    </div>
  </form>

  <p class="law-total">총 <strong><c:out value="${resultCnt}"/></strong>건</p>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">No</th>
        <th scope="col" style="width:5%;">상태</th>
        <th scope="col">사건명</th>
        <th scope="col" style="width:8%;">의뢰부서</th>
        <th scope="col" style="width:7%;">의뢰담당자</th>
        <th scope="col" style="width:8%;">의뢰일자</th>
        <th scope="col" style="width:10%;">처리</th>
        <th scope="col" style="width:8%;">소송등록</th>
        <th scope="col" style="width:7%;">처리자</th>
        <th scope="col" style="width:8%;">처리일자</th>
        <th scope="col">사유</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td>
            <c:choose>
              <c:when test="${row.statusCd eq 'S002'}"><span class="law-badge appr">승인</span></c:when>
              <c:when test="${row.statusCd eq 'S003'}"><span class="law-badge rjct">반려</span></c:when>
              <c:otherwise><span class="law-badge req">신청</span></c:otherwise>
            </c:choose>
          </td>
          <td><a href="<c:url value='/law/req/view.do'/>?reqId=${row.reqId}"><c:out value="${row.reqTitl}" default="(제목 없음)"/></a></td>
          <td><c:out value="${row.reqOrgnztNm}" default="-"/></td>
          <td><c:out value="${row.reqUserNm}" default="${row.reqUserId}"/></td>
          <td><c:if test="${not empty row.reqDt and fn:length(row.reqDt) ge 8}">${fn:substring(row.reqDt,0,4)}-${fn:substring(row.reqDt,4,6)}-${fn:substring(row.reqDt,6,8)}</c:if></td>
          <td>
            <c:choose>
              <c:when test="${row.statusCd eq 'S001'}">
                <button type="button" class="law-chip-btn approve" onclick="fnApprove(${row.reqId});">승인</button>
                <button type="button" class="law-chip-btn reject" onclick="fnOpenReject(${row.reqId});">반려</button>
              </c:when>
              <c:otherwise><span class="law-cell-sub">처리 완료</span></c:otherwise>
            </c:choose>
          </td>
          <td>
            <c:choose>
              <c:when test="${not empty row.suitId}">
                <a class="law-chip-btn" href="<c:url value='/law/suit/view.do'/>?suitId=${row.suitId}"><c:out value="${row.caseNo}" default="사건보기"/></a>
              </c:when>
              <c:when test="${row.statusCd eq 'S002'}">
                <a class="law-chip-btn approve" href="<c:url value='/law/suit/regist.do'/>?reqId=${row.reqId}">소송등록</a>
              </c:when>
              <c:otherwise><span class="law-cell-sub">-</span></c:otherwise>
            </c:choose>
          </td>
          <td><c:out value="${row.aprvUserNm}" default="${row.aprvUserId}"/></td>
          <td><c:if test="${not empty row.aprvDt and fn:length(row.aprvDt) ge 8}">${fn:substring(row.aprvDt,0,4)}-${fn:substring(row.aprvDt,4,6)}-${fn:substring(row.aprvDt,6,8)}</c:if></td>
          <td style="white-space:pre-wrap;"><c:out value="${row.returnRsn}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="11" style="text-align:center; padding:32px 0; color:#888;">조회된 소송의뢰가 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <%-- 반려 사유 모달 --%>
  <div class="law-modal-back" id="modalBack" onclick="fnCloseReject();"></div>
  <div class="law-modal" id="rejectModal" role="dialog" aria-modal="true" aria-labelledby="rjTitle">
    <h2 id="rjTitle">의뢰 반려</h2>
    <input type="hidden" id="rj_reqId"/>
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
  function fnLinkPage(pageNo){ document.getElementById('pageIndex').value = pageNo; document.getElementById('searchForm').submit(); }

  function fnPost(reqId, action, opinion, ok){
    var p = new URLSearchParams(); p.set('reqId', reqId); p.set('action', action); if(opinion!=null) p.set('opinion', opinion);
    fetch(APPROVE_URL, { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ ok(); } else { alert(d.message||'처리 실패'); } })
      .catch(function(){ alert('처리 요청 실패'); });
  }
  function fnApprove(reqId){ if(!confirm('이 의뢰를 승인할까요? 승인 후 소송등록으로 사건을 생성할 수 있습니다.')) return; fnPost(reqId, 'approve', null, function(){ location.reload(); }); }
  function fnOpenReject(reqId){ document.getElementById('rj_reqId').value = reqId; document.getElementById('rj_opinion').value=''; document.getElementById('modalBack').style.display='block'; document.getElementById('rejectModal').style.display='block'; document.getElementById('rj_opinion').focus(); }
  function fnCloseReject(){ document.getElementById('modalBack').style.display='none'; document.getElementById('rejectModal').style.display='none'; }
  function fnReject(){
    var op = document.getElementById('rj_opinion').value.trim();
    if(!op){ alert('반려 사유를 입력하세요.'); return; }
    fnPost(document.getElementById('rj_reqId').value, 'reject', op, function(){ location.reload(); });
  }
  </script>
</lay:layout>
