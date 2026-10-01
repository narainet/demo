<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/lawyer/list.jsp
  변호사관리 (LAW_MODULE_DESIGN.md §7.7) — 목록·통합검색·등록/수정 모달·소프트삭제.
  만족도 평균★은 선임 단위 평가(LAW_LAWYER_SATIS)의 변호사 집계 — 평가 입력은 선임관리(P3).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">변호사관리</c:set>
<c:set var="pageHead">
  
  <style>
    .law-modal-back { position: fixed; inset: 0; background: rgba(0,0,0,.45); display: none; z-index: 1000; }
    .law-modal { position: fixed; top: 50%; left: 50%; transform: translate(-50%,-50%);
                 background: #fff; border-radius: 12px; padding: 28px 32px; width: 460px; max-width: calc(92vw / var(--rlms-zoom, 1));
                 display: none; z-index: 1001; box-shadow: 0 8px 30px rgba(0,0,0,.2); }
    .law-modal h2 { margin: 0 0 18px; font-size: 19px; }
    .law-modal .form-row { margin-bottom: 12px; }
    .law-modal .form-row label { display: block; font-size: 14px; margin-bottom: 4px; color: #333; }
    .law-modal .form-row input { width: 100%; }
    .law-modal .modal-btns { margin-top: 20px; text-align: right; display: flex; gap: 8px; justify-content: flex-end; }
    .law-satis-star { color: #f5a623; letter-spacing: 1px; }
    .law-cell-sub { color: #888; font-size: 12px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>변호사관리</h1>
    <p class="page-desc">선임 대상 변호사 명부입니다. 만족도는 선임 건 평가의 평균입니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/lawyer/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="form-group inline">
      <label class="form-label" for="searchKeyword">법무법인·변호사</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="법무법인 또는 변호사 성명"/>
      </div>
      <button type="submit" class="krds-btn primary medium" onclick="document.getElementById('pageIndex').value=1;">검색</button>
      <button type="button" class="krds-btn medium" onclick="fnOpenModal(null);">등록</button>
    </div>
  </form>

  <p class="law-total">총 <strong><c:out value="${resultCnt}"/></strong>명</p>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">No</th>
        <th scope="col">법무법인</th>
        <th scope="col">변호사</th>
        <th scope="col" style="width:8%;">등록일자</th>
        <th scope="col">이메일</th>
        <th scope="col" style="width:9%;">전화(사무실)</th>
        <th scope="col" style="width:9%;">휴대폰</th>
        <th scope="col" style="width:8%;">만족도</th>
        <th scope="col" style="width:10%;">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:out value="${row.lawFirm}"/></td>
          <td><c:out value="${row.lawyerNm}"/> <c:if test="${row.assignCnt > 0}"><span class="law-cell-sub">(선임 <c:out value="${row.assignCnt}"/>건)</span></c:if></td>
          <td><c:choose><c:when test="${not empty row.regDt}"><fmt:parseDate value="${row.regDt}" pattern="yyyyMMdd" var="rd"/><fmt:formatDate value="${rd}" pattern="yyyy-MM-dd"/></c:when><c:otherwise>-</c:otherwise></c:choose></td>
          <td><c:out value="${row.email}" default="-"/></td>
          <td><c:out value="${row.tel}" default="-"/></td>
          <td><c:out value="${row.mobile}" default="-"/></td>
          <td>
            <c:choose>
              <c:when test="${row.satisCnt > 0}"><span class="law-satis-star">★</span> <c:out value="${row.satisAvg}"/> <span class="law-cell-sub">(<c:out value="${row.satisCnt}"/>)</span></c:when>
              <c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
          <td>
            <button type="button" class="law-chip-btn btn-edit"
                    data-id="<c:out value='${row.lawyerId}'/>" data-firm="<c:out value='${row.lawFirm}'/>"
                    data-nm="<c:out value='${row.lawyerNm}'/>" data-email="<c:out value='${row.email}'/>"
                    data-tel="<c:out value='${row.tel}'/>" data-mobile="<c:out value='${row.mobile}'/>">수정</button>
            <button type="button" class="law-chip-btn btn-del" data-id="<c:out value='${row.lawyerId}'/>">삭제</button>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="9" style="text-align:center; padding:32px 0; color:#888;">등록된 변호사가 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <%-- 등록/수정 모달 --%>
  <div class="law-modal-back" id="modalBack" onclick="fnCloseModal();"></div>
  <div class="law-modal" id="lawyerModal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
    <h2 id="modalTitle">변호사 등록</h2>
    <form id="lawyerForm" onsubmit="return false;">
      <input type="hidden" id="m_lawyerId" name="lawyerId" value=""/>
      <div class="form-row">
        <label for="m_lawFirm">법무법인 <span style="color:#d3273e;">*</span></label>
        <input type="text" id="m_lawFirm" name="lawFirm" class="krds-input" maxlength="60" required/>
      </div>
      <div class="form-row">
        <label for="m_lawyerNm">변호사 성명 <span style="color:#d3273e;">*</span></label>
        <input type="text" id="m_lawyerNm" name="lawyerNm" class="krds-input" maxlength="30" required/>
      </div>
      <div class="form-row">
        <label for="m_email">이메일</label>
        <input type="text" id="m_email" name="email" class="krds-input" maxlength="60"/>
      </div>
      <div class="form-row">
        <label for="m_tel">전화(사무실)</label>
        <input type="text" id="m_tel" name="tel" class="krds-input" maxlength="20"/>
      </div>
      <div class="form-row">
        <label for="m_mobile">휴대폰</label>
        <input type="text" id="m_mobile" name="mobile" class="krds-input" maxlength="20"/>
      </div>
      <div class="modal-btns">
        <button type="button" class="krds-btn medium" onclick="fnCloseModal();">취소</button>
        <button type="button" class="krds-btn primary medium" onclick="fnSave();">저장</button>
      </div>
    </form>
  </div>

  <script>
  function fnLinkPage(pageNo) {
    document.getElementById('pageIndex').value = pageNo;
    document.getElementById('searchForm').submit();
  }
  document.addEventListener('click', function(e) {
    var edit = e.target.closest('.btn-edit');
    if (edit) {
      fnOpenModal({ lawyerId: edit.dataset.id, lawFirm: edit.dataset.firm, lawyerNm: edit.dataset.nm,
                    email: edit.dataset.email, tel: edit.dataset.tel, mobile: edit.dataset.mobile });
      return;
    }
    var del = e.target.closest('.btn-del');
    if (del) { fnDelete(del.dataset.id); }
  });
  function fnOpenModal(row) {
    document.getElementById('modalTitle').textContent = row ? '변호사 수정' : '변호사 등록';
    document.getElementById('m_lawyerId').value = row ? row.lawyerId : '';
    document.getElementById('m_lawFirm').value  = row ? row.lawFirm  : '';
    document.getElementById('m_lawyerNm').value = row ? row.lawyerNm : '';
    document.getElementById('m_email').value    = row ? row.email    : '';
    document.getElementById('m_tel').value      = row ? row.tel      : '';
    document.getElementById('m_mobile').value   = row ? row.mobile   : '';
    document.getElementById('modalBack').style.display = 'block';
    document.getElementById('lawyerModal').style.display = 'block';
    document.getElementById('m_lawFirm').focus();
  }
  function fnCloseModal() {
    document.getElementById('modalBack').style.display = 'none';
    document.getElementById('lawyerModal').style.display = 'none';
  }
  function fnSave() {
    var lawFirm = document.getElementById('m_lawFirm').value.trim();
    var lawyerNm = document.getElementById('m_lawyerNm').value.trim();
    if (!lawFirm) { alert('법무법인을 입력하세요.'); return; }
    if (!lawyerNm) { alert('변호사 성명을 입력하세요.'); return; }
    var params = new URLSearchParams();
    params.set('lawyerId', document.getElementById('m_lawyerId').value);
    params.set('lawFirm', lawFirm);
    params.set('lawyerNm', lawyerNm);
    params.set('email', document.getElementById('m_email').value.trim());
    params.set('tel', document.getElementById('m_tel').value.trim());
    params.set('mobile', document.getElementById('m_mobile').value.trim());
    fetch('<c:url value="/law/lawyer/saveJson.do"/>', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
      body: params.toString()
    }).then(function(r){ return r.json(); }).then(function(d){
      if (d.success) { location.reload(); }
      else { alert(d.message || '저장에 실패했습니다.'); }
    }).catch(function(){ alert('저장 요청에 실패했습니다.'); });
  }
  function fnDelete(lawyerId) {
    if (!confirm('이 변호사를 삭제할까요?\n선임 이력이 있으면 삭제되지 않습니다.')) return;
    var params = new URLSearchParams();
    params.set('lawyerId', lawyerId);
    fetch('<c:url value="/law/lawyer/deleteJson.do"/>', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
      body: params.toString()
    }).then(function(r){ return r.json(); }).then(function(d){
      if (d.success) { location.reload(); }
      else { alert(d.message || '삭제에 실패했습니다.'); }
    }).catch(function(){ alert('삭제 요청에 실패했습니다.'); });
  }
  </script>
</lay:layout>
