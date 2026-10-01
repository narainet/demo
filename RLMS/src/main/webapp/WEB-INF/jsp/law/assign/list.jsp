<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/assign/list.jsp
  선임관리 (LAW_MODULE_DESIGN.md §7.6) — 목록·통합검색·선임등록 모달(사건검색 재사용·변호사 select·계약서 첨부)·삭제·만족도 모달.
  첨부 다운로드는 표준 FileDown.do(atchFileId 세션 암호화). 만족도는 선임 단위 1인 1회 MERGE.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">선임관리</c:set>
<c:set var="pageHead">
  
  <style>
    .law-modal-back { position: fixed; inset: 0; background: rgba(0,0,0,.45); display: none; z-index: 1000; }
    .law-modal { position: fixed; top: 50%; left: 50%; transform: translate(-50%,-50%);
                 background: #fff; border-radius: 12px; padding: 26px 30px; width: 520px; max-width: calc(94vw / var(--rlms-zoom, 1));
                 max-height: calc(88vh / var(--rlms-zoom, 1)); overflow-y: auto; display: none; z-index: 1001; box-shadow: 0 8px 30px rgba(0,0,0,.2); }
    .law-modal.narrow { width: 460px; }
    .law-modal h2 { margin: 0 0 18px; font-size: 19px; }
    .law-modal .form-row { margin-bottom: 12px; }
    .law-modal .form-row label { display: block; font-size: 14px; margin-bottom: 4px; color: #333; }
    .law-modal .form-row input[type=text], .law-modal .form-row input[type=date],
    .law-modal .form-row select, .law-modal .form-row textarea { width: 100%; box-sizing: border-box; }
    .law-modal .modal-btns { margin-top: 20px; text-align: right; display: flex; gap: 8px; justify-content: flex-end; }
    .law-satis-star { color: #f5a623; letter-spacing: 1px; }
    .law-cell-sub { color: #888; font-size: 12px; }
    .law-file-link { display: block; font-size: 13px; }
    .law-picked { background:#f4f7ff; border:1px solid #cdd9f5; border-radius:6px; padding:7px 10px; font-size:13px; min-height:18px; }
    .law-star-pick { font-size: 30px; letter-spacing: 4px; cursor: pointer; user-select: none; color:#d9d9d9; }
    .law-star-pick span.on { color:#f5a623; }
    .law-search-result { max-height: 260px; overflow-y: auto; border:1px solid #e3e3e3; border-radius:6px; margin-top:10px; }
    .law-search-result table { width:100%; border-collapse:collapse; }
    .law-search-result th, .law-search-result td { border-bottom:1px solid #eee; padding:6px 8px; font-size:13px; text-align:left; }
    .law-search-result tbody tr { cursor:pointer; }
    .law-search-result tbody tr:hover { background:#f4f7ff; }
    .law-opinion-list { margin-top:6px; border-top:1px solid #eee; }
    .law-opinion-item { padding:8px 0; border-bottom:1px dashed #eee; font-size:13px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>선임관리</h1>
    <p class="page-desc">사건별 변호사 선임 내역과 계약서, 선임 만족도를 관리합니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/assign/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="form-group inline">
      <label class="form-label" for="searchKeyword">법무법인·변호사·사건</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="법무법인·변호사·사건번호·사건명"/>
      </div>
      <button type="submit" class="krds-btn primary medium" onclick="document.getElementById('pageIndex').value=1;">검색</button>
      <button type="button" class="krds-btn medium" onclick="fnOpenAssignModal();">선임등록</button>
    </div>
  </form>

  <p class="law-total">총 <strong><c:out value="${resultCnt}"/></strong>건</p>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">No</th>
        <th scope="col">법무법인</th>
        <th scope="col" style="width:7%;">변호사</th>
        <th scope="col">계약서</th>
        <th scope="col" style="width:8%;">선임일</th>
        <th scope="col">사건번호</th>
        <th scope="col">사건명</th>
        <th scope="col" style="width:7%;">소송결과</th>
        <th scope="col" style="width:8%;">만족도</th>
        <th scope="col" style="width:6%;">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:out value="${row.lawFirm}"/></td>
          <td><c:out value="${row.lawyerNm}"/></td>
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
          <td><c:choose><c:when test="${not empty row.assignDt}"><fmt:parseDate value="${row.assignDt}" pattern="yyyyMMdd" var="ad"/><fmt:formatDate value="${ad}" pattern="yyyy-MM-dd"/></c:when><c:otherwise>-</c:otherwise></c:choose></td>
          <td><a href="<c:url value='/law/suit/view.do'/>?suitId=${row.suitId}"><c:out value="${row.caseNo}" default="(미입력)"/></a></td>
          <td><c:out value="${row.caseNm}" default="-"/></td>
          <td><c:out value="${row.rsltDispNm}" default="-"/></td>
          <td>
            <button type="button" class="law-chip-btn btn-satis" data-id="${row.assignId}"
                    data-label="<c:out value='${row.lawFirm}'/> / <c:out value='${row.lawyerNm}'/>">
              <c:choose>
                <c:when test="${row.satisCnt > 0}"><span class="law-satis-star">★</span> <c:out value="${row.satisAvg}"/> <span class="law-cell-sub">(<c:out value="${row.satisCnt}"/>)</span></c:when>
                <c:otherwise>평가</c:otherwise>
              </c:choose>
            </button>
          </td>
          <td><button type="button" class="law-chip-btn btn-del" data-id="${row.assignId}">삭제</button></td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="10" style="text-align:center; padding:32px 0; color:#888;">등록된 선임이 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <%-- ── 선임등록 모달 (multipart 폼 제출) ── --%>
  <div class="law-modal-back" id="modalBack"></div>
  <div class="law-modal" id="assignModal" role="dialog" aria-modal="true" aria-labelledby="assignTitle">
    <h2 id="assignTitle">선임 등록</h2>
    <form id="assignForm" action="<c:url value='/law/assign/save.do'/>" method="post" enctype="multipart/form-data">
      <input type="hidden" id="a_suitId" name="suitId" value=""/>
      <div class="form-row">
        <label>사건 <span style="color:#d3273e;">*</span></label>
        <div style="display:flex; gap:8px; align-items:center;">
          <span id="a_suitLabel" class="law-picked" style="flex:1;">사건을 선택하세요.</span>
          <button type="button" class="krds-btn small" onclick="fnOpenSuitSearch();">사건검색</button>
        </div>
      </div>
      <div class="form-row">
        <label for="a_lawyerId">변호사 <span style="color:#d3273e;">*</span></label>
        <select id="a_lawyerId" name="lawyerId" class="krds-select">
          <option value="">-- 선택 --</option>
          <c:forEach var="lw" items="${lawyerOptions}">
            <option value="${lw.lawyerId}"><c:out value="${lw.label}"/></option>
          </c:forEach>
        </select>
      </div>
      <div class="form-row">
        <label for="a_assignDt">선임일</label>
        <input type="date" id="a_assignDt" name="assignDt" class="krds-input"/>
      </div>
      <div class="form-row">
        <label for="a_file">계약서 첨부</label>
        <c:set var="aId" value="a_file" scope="request"/>
        <c:set var="aName" value="file_1" scope="request"/>
        <c:set var="aExistFiles" value="${null}" scope="request"/>
        <jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
        <span class="law-cell-sub">여러 파일 선택 가능. 저장 후 파일은 목록에서 다운로드됩니다.</span>
      </div>
      <div class="modal-btns">
        <button type="button" class="krds-btn medium" onclick="fnCloseModal('assignModal');">취소</button>
        <button type="button" class="krds-btn primary medium" onclick="fnSubmitAssign();">저장</button>
      </div>
    </form>
  </div>

  <%-- ── 사건 검색 모달 (공용) ── --%>
  <div class="law-modal narrow" id="suitSearchModal" role="dialog" aria-modal="true">
    <h2>사건 검색</h2>
    <div style="display:flex; gap:8px;">
      <input type="text" id="s_keyword" class="krds-input" style="flex:1;" placeholder="사건번호 또는 사건명" onkeydown="if(event.key==='Enter'){event.preventDefault();fnSuitSearch();}"/>
      <button type="button" class="krds-btn primary small" onclick="fnSuitSearch();">검색</button>
    </div>
    <div class="law-search-result">
      <table>
        <thead><tr><th style="width:120px;">사건번호</th><th>사건명</th><th style="width:70px;">심급</th></tr></thead>
        <tbody id="s_result"><tr><td colspan="3" style="color:#888;">검색어를 입력하세요.</td></tr></tbody>
      </table>
    </div>
    <div class="modal-btns"><button type="button" class="krds-btn medium" onclick="fnCloseModal('suitSearchModal');">닫기</button></div>
  </div>

  <%-- ── 만족도 평가·의견 모달 ── --%>
  <div class="law-modal narrow" id="satisModal" role="dialog" aria-modal="true">
    <h2 id="satisTitle">선임 만족도</h2>
    <input type="hidden" id="st_assignId" value=""/>
    <div class="form-row">
      <label>별점</label>
      <div id="st_stars" class="law-star-pick">
        <span data-v="1">★</span><span data-v="2">★</span><span data-v="3">★</span><span data-v="4">★</span><span data-v="5">★</span>
      </div>
    </div>
    <div class="form-row">
      <label for="st_opinion">의견 (선택)</label>
      <textarea id="st_opinion" class="krds-input" rows="3" maxlength="1000"></textarea>
    </div>
    <div class="modal-btns">
      <button type="button" class="krds-btn medium" onclick="fnCloseModal('satisModal');">닫기</button>
      <button type="button" class="krds-btn primary medium" onclick="fnSaveSatis();">평가 저장</button>
    </div>
    <div style="margin-top:14px;">
      <div class="law-cell-sub">등록된 의견</div>
      <div id="st_opinions" class="law-opinion-list"><div class="law-cell-sub" style="padding:8px 0;">불러오는 중…</div></div>
    </div>
  </div>

  <script>
  var LAW = {
    delUrl: '<c:url value="/law/assign/deleteJson.do"/>',
    searchUrl: '<c:url value="/law/suit/searchJson.do"/>',
    satisDataUrl: '<c:url value="/law/assign/satisDataJson.do"/>',
    satisSaveUrl: '<c:url value="/law/assign/satisJson.do"/>'
  };
  var stStar = 0;

  function fnLinkPage(pageNo) { document.getElementById('pageIndex').value = pageNo; document.getElementById('searchForm').submit(); }
  function esc(s){ return (s==null?'':String(s)).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

  function fnShowModal(id){ document.getElementById('modalBack').style.display='block'; document.getElementById(id).style.display='block'; }
  function fnCloseModal(id){ document.getElementById(id).style.display='none';
    var any = ['assignModal','suitSearchModal','satisModal'].some(function(m){ return document.getElementById(m).style.display==='block'; });
    if(!any) document.getElementById('modalBack').style.display='none'; }

  // 선임 등록
  function fnOpenAssignModal(){
    document.getElementById('assignForm').reset();
    document.getElementById('a_suitId').value='';
    document.getElementById('a_suitLabel').textContent='사건을 선택하세요.';
    fnShowModal('assignModal');
  }
  function fnSubmitAssign(){
    if(!document.getElementById('a_suitId').value){ alert('사건을 선택하세요.'); return; }
    if(!document.getElementById('a_lawyerId').value){ alert('변호사를 선택하세요.'); return; }
    document.getElementById('assignForm').submit();
  }

  // 사건 검색 (공용)
  function fnOpenSuitSearch(){ document.getElementById('s_keyword').value=''; document.getElementById('s_result').innerHTML='<tr><td colspan="3" style="color:#888;">검색어를 입력하세요.</td></tr>'; fnShowModal('suitSearchModal'); document.getElementById('s_keyword').focus(); }
  function fnSuitSearch(){
    var kw = document.getElementById('s_keyword').value.trim();
    fetch(LAW.searchUrl + '?keyword=' + encodeURIComponent(kw), { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
      .then(function(r){ return r.json(); }).then(function(d){
        var tb = document.getElementById('s_result');
        if(!d.success || !d.list || !d.list.length){ tb.innerHTML='<tr><td colspan="3" style="color:#888;">검색 결과가 없습니다.</td></tr>'; return; }
        tb.innerHTML = d.list.map(function(s){
          return '<tr onclick="fnPickSuit('+s.suitId+',\''+esc(s.caseNo||'')+'\',\''+esc(s.caseNm||'')+'\')">'
               + '<td>'+esc(s.caseNo||'(미입력)')+'</td><td>'+esc(s.caseNm||'')+'</td><td>'+esc(s.instanceNm||'')+'</td></tr>';
        }).join('');
      }).catch(function(){ document.getElementById('s_result').innerHTML='<tr><td colspan="3" style="color:#c00;">검색 실패</td></tr>'; });
  }
  function fnPickSuit(suitId, caseNo, caseNm){
    document.getElementById('a_suitId').value = suitId;
    document.getElementById('a_suitLabel').textContent = (caseNo||'(미입력)') + ' ' + (caseNm||'');
    fnCloseModal('suitSearchModal');
  }

  // 삭제
  function fnDeleteAssign(id){
    if(!confirm('이 선임을 삭제할까요?')) return;
    var p = new URLSearchParams(); p.set('assignId', id);
    fetch(LAW.delUrl, { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'삭제 실패'); } })
      .catch(function(){ alert('삭제 요청 실패'); });
  }

  // 만족도
  function fnOpenSatis(assignId, label){
    document.getElementById('st_assignId').value = assignId;
    document.getElementById('satisTitle').textContent = '선임 만족도 — ' + label;
    document.getElementById('st_opinion').value = '';
    fnSetStar(0);
    document.getElementById('st_opinions').innerHTML = '<div class="law-cell-sub" style="padding:8px 0;">불러오는 중…</div>';
    fnShowModal('satisModal');
    fetch(LAW.satisDataUrl + '?assignId=' + assignId, { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
      .then(function(r){ return r.json(); }).then(function(d){
        if(!d.success){ return; }
        if(d.mine){ fnSetStar(d.mine.score||0); document.getElementById('st_opinion').value = d.mine.opinion||''; }
        var box = document.getElementById('st_opinions');
        if(!d.list || !d.list.length){ box.innerHTML='<div class="law-cell-sub" style="padding:8px 0;">아직 의견이 없습니다.</div>'; return; }
        box.innerHTML = d.list.map(function(o){
          var sc = o.score || 0;
          var star = '★★★★★'.slice(0, sc) + '☆☆☆☆☆'.slice(0, 5-sc);
          return '<div class="law-opinion-item"><span class="law-satis-star">'+star+'</span> '
               + '<strong>'+esc(o.evaluatorNm||o.emplyrId||'')+'</strong>'
               + (o.opinion ? '<div>'+esc(o.opinion)+'</div>' : '') + '</div>';
        }).join('');
      }).catch(function(){});
  }
  function fnSetStar(n){ stStar = n;
    Array.prototype.forEach.call(document.querySelectorAll('#st_stars span'), function(s){ s.classList.toggle('on', parseInt(s.dataset.v,10) <= n); });
  }
  function fnSaveSatis(){
    if(stStar < 1){ alert('별점을 선택하세요.'); return; }
    var p = new URLSearchParams();
    p.set('assignId', document.getElementById('st_assignId').value);
    p.set('score', stStar);
    p.set('opinion', document.getElementById('st_opinion').value);
    fetch(LAW.satisSaveUrl, { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'저장 실패'); } })
      .catch(function(){ alert('저장 요청 실패'); });
  }

  // 이벤트 위임
  document.addEventListener('click', function(e){
    var del = e.target.closest('.btn-del'); if(del){ fnDeleteAssign(del.dataset.id); return; }
    var sat = e.target.closest('.btn-satis'); if(sat){ fnOpenSatis(sat.dataset.id, sat.dataset.label); return; }
    var star = e.target.closest('#st_stars span'); if(star){ fnSetStar(parseInt(star.dataset.v,10)); return; }
    if(e.target.id === 'modalBack'){ ['assignModal','suitSearchModal','satisModal'].forEach(function(m){ document.getElementById(m).style.display='none'; }); document.getElementById('modalBack').style.display='none'; }
  });
  </script>
</lay:layout>
