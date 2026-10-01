<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/schedule/main.jsp
  일정관리 (LAW_MODULE_DESIGN.md §7.5) — 월 달력(자체 렌더)+당일/주간 기일 그리드+일정등록 모달(사건검색 재사용)+일정검색+삭제.
  데이터=LAW_SUIT_PROG 기일(PROG_KIND_CD='S001') — 등록화면 진행상황과 공유. 외부 캘린더 라이브러리 미사용.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">일정관리</c:set>
<c:set var="pageHead">
  
  <style>
    .law-cell-sub { color:#888; font-size:12px; }
    .sc-cal { border:1px solid #e3e3e3; border-radius:10px; overflow:hidden; margin:14px 0; }
    .sc-cal-head { display:flex; justify-content:space-between; align-items:center; padding:10px 14px; background:#f7f8fa; }
    .sc-cal-head .m { font-size:17px; font-weight:700; }
    .sc-grid { display:grid; grid-template-columns:repeat(7,1fr); }
    .sc-grid .dow { text-align:center; padding:7px 0; font-size:13px; font-weight:600; background:#fafbfc; border-top:1px solid #eee; }
    .sc-grid .dow.sun { color:#d3273e; } .sc-grid .dow.sat { color:#256ef4; }
    .sc-cell { min-height:86px; border-top:1px solid #eee; border-left:1px solid #f0f0f0; padding:4px 5px; font-size:12px; cursor:pointer; vertical-align:top; }
    .sc-cell:hover { background:#f4f7ff; }
    .sc-cell .dnum { font-weight:600; color:#444; }
    .sc-cell.other .dnum { color:#c8c8c8; }
    .sc-cell.today { background:#eef4ff; }
    .sc-cell.today .dnum { color:#256ef4; }
    .sc-cell .sun { color:#d3273e; } .sc-cell .sat { color:#256ef4; }
    /* '외 N건 더보기' — 칸 클릭이 그날 목록을 여는 동선이라는 걸 드러낸다 (2026-07-30) */
    .sc-cell .sc-more { color:#256ef4; text-decoration:underline; }
    .sc-ev { background:#e8f0ff; border-radius:4px; padding:1px 4px; margin-top:2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .sc-grids { display:flex; flex-direction:column; gap:8px; }
    .sc-sec { font-size:16px; font-weight:700; margin:20px 0 8px; color:#1f3974; }
    /* .law-search-grid / .law-search-actions / .law-list-head 는 rlms-compat.css 공통 */
    /* 검색영역 한 줄 — 4필드(기간=한 셀)+버튼을 같은 행에 (2026-07-27). 좁은 화면은 2열로 복귀 */
    .sc-search-grid { grid-template-columns:repeat(4, minmax(0,1fr)) auto; }
    @media (max-width:1200px) {
      .sc-search-grid { grid-template-columns:repeat(2, 1fr); }
      .sc-search-grid .law-search-btns { grid-column:1 / -1; justify-content:center; }
    }
    .law-modal-back { position: fixed; inset:0; background:rgba(0,0,0,.45); display:none; z-index:1000; }
    .law-modal { position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#fff; border-radius:12px;
                 padding:26px 30px; width:480px; max-width:calc(94vw / var(--rlms-zoom, 1)); max-height:calc(88vh / var(--rlms-zoom, 1)); overflow-y:auto; display:none; z-index:1001; box-shadow:0 8px 30px rgba(0,0,0,.2); }
    .law-modal.narrow { width:440px; }
    /* 하루 일정 목록(2026-07-30) — 5열 표라 480px 에선 고정폭 열(388px)에 밀려 사건명이 한 자씩 세로로 쪼개진다.
       폭을 넓히고 각 행을 한 줄로 고정, 넘치면 목록만 가로 스크롤. */
    .law-modal.wide { width:900px; }
    .law-modal.wide .law-search-result { overflow-x:auto; }
    .law-modal.wide .sc-week { min-width:760px; }
    .law-modal.wide .sc-week th, .law-modal.wide .sc-week td { white-space:nowrap; vertical-align:middle; }
    .law-modal h2 { margin:0 0 16px; font-size:19px; }
    .law-modal .form-row { margin-bottom:12px; }
    .law-modal .form-row label { display:block; font-size:14px; margin-bottom:4px; color:#333; }
    .law-modal .form-row input, .law-modal .form-row select { width:100%; box-sizing:border-box; }
    .law-modal .modal-btns { margin-top:18px; display:flex; gap:8px; justify-content:flex-end; }
    .law-picked { background:#f4f7ff; border:1px solid #cdd9f5; border-radius:6px; padding:7px 10px; font-size:13px; }
    .law-search-result { max-height:260px; overflow-y:auto; border:1px solid #e3e3e3; border-radius:6px; margin-top:10px; }
    .law-search-result table { width:100%; border-collapse:collapse; }
    .law-search-result th, .law-search-result td { border-bottom:1px solid #eee; padding:6px 8px; font-size:13px; text-align:left; }
    .law-search-result tbody tr { cursor:pointer; } .law-search-result tbody tr:hover { background:#f4f7ff; }
    .sc-empty { text-align:center; color:#888; padding:24px 0; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>일정관리</h1>
    <p class="page-desc">사건 기일을 달력과 목록으로 관리합니다. 날짜를 누르면 그 날짜로 기일을 등록할 수 있습니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <%-- 일정검색 --%>
  <form id="searchForm" name="searchForm" action="<c:url value='/law/schedule/main.do'/>" method="get" class="krds-form search-form">
    <div class="law-search-grid sc-search-grid">
      <div><label for="searchCaseNo">사건번호</label><input type="text" id="searchCaseNo" name="searchCaseNo" class="krds-input" value="<c:out value='${searchVO.searchCaseNo}'/>"/></div>
      <div><label for="searchDyprKind">기일구분</label>
        <select id="searchDyprKind" name="searchDyprKind" class="krds-select"><option value="">전체</option>
          <c:forEach var="c" items="${dyprKinds}"><option value="${c.code}" ${searchVO.searchDyprKind eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div><label for="searchInstance">심급</label>
        <select id="searchInstance" name="searchInstance" class="krds-select"><option value="">전체</option>
          <c:forEach var="c" items="${instances}"><option value="${c.code}" ${searchVO.searchInstance eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div><label for="searchFrom">기간</label>
        <div class="law-date-range">
          <input type="date" id="searchFrom" name="searchFrom" class="krds-input" value="<c:out value='${searchVO.searchFrom}'/>"/>
          <span class="sep">~</span>
          <input type="date" id="searchTo" name="searchTo" class="krds-input" aria-label="기간(종료)" value="<c:out value='${searchVO.searchTo}'/>"/>
        </div></div>
      <div class="law-search-btns">
        <button type="submit" class="krds-btn small primary">검색</button>
        <button type="button" class="krds-btn small" onclick="location.href='<c:url value="/law/schedule/main.do"/>';">초기화</button>
      </div>
    </div>
  </form>

  <div class="law-list-head">
    <span></span>
    <button type="button" class="krds-btn primary medium" onclick="fnOpenReg(null);">＋ 일정 등록</button>
  </div>

  <%-- 월 달력 (자체 렌더) --%>
  <div class="sc-cal">
    <div class="sc-cal-head">
      <button type="button" class="krds-btn small" onclick="fnMonth(-1);">‹ 이전달</button>
      <span class="m" id="calTitle"></span>
      <button type="button" class="krds-btn small" onclick="fnMonth(1);">다음달 ›</button>
    </div>
    <div class="sc-grid" id="calGrid"></div>
  </div>

  <%-- 검색결과 --%>
  <c:if test="${searched}">
    <div class="sc-sec">검색 결과 (<c:out value="${fn:length(searchResults)}"/>건)</div>
    <table class="krds-table tbl-list" style="margin-bottom:18px;">
      <thead><tr><th style="width:100px;">일자</th><th style="width:60px;">시간</th><th style="width:120px;">사건번호</th><th style="width:100px;">기일구분</th><th>장소</th><th style="width:140px;">법원</th><th style="width:120px;">수행자</th><th>결과</th><th style="width:56px;">삭제</th></tr></thead>
      <tbody>
        <c:forEach var="h" items="${searchResults}">
          <tr>
            <td><c:if test="${fn:length(h.progDt) ge 8}">${fn:substring(h.progDt,0,4)}-${fn:substring(h.progDt,4,6)}-${fn:substring(h.progDt,6,8)}</c:if></td>
            <td><c:if test="${fn:length(h.progTm) ge 4}">${fn:substring(h.progTm,0,2)}:${fn:substring(h.progTm,2,4)}</c:if></td>
            <td><a href="<c:url value='/law/suit/view.do'/>?suitId=${h.suitId}"><c:out value="${h.caseNo}" default="(미입력)"/></a></td>
            <td><c:out value="${h.dyprKindNm}" default="-"/></td>
            <td><c:out value="${h.place}" default="-"/></td>
            <td><c:out value="${h.courtNm}" default="-"/></td>
            <td><c:out value="${h.staffNm}" default="-"/><c:if test="${not empty h.helperNm}"> / <c:out value="${h.helperNm}"/></c:if></td>
            <td><c:out value="${h.resultDesc}" default="-"/></td>
            <td><button type="button" class="krds-btn small btn-del" data-id="${h.progId}">삭제</button></td>
          </tr>
        </c:forEach>
        <c:if test="${empty searchResults}"><tr><td colspan="9" class="sc-empty">검색 결과가 없습니다.</td></tr></c:if>
      </tbody>
    </table>
  </c:if>

  <%-- 당일 / 주간 --%>
  <div class="sc-grids">
    <div>
      <div class="sc-sec">오늘 기일</div>
      <table class="krds-table tbl-list">
        <thead><tr><th style="width:56px;">시간</th><th style="width:110px;">사건번호</th><th style="width:90px;">기일구분</th><th>장소</th><th style="width:100px;">수행자</th><th style="width:50px;">삭제</th></tr></thead>
        <tbody>
          <c:forEach var="h" items="${todayHearings}">
            <tr>
              <td><c:if test="${fn:length(h.progTm) ge 4}">${fn:substring(h.progTm,0,2)}:${fn:substring(h.progTm,2,4)}</c:if></td>
              <td><a href="<c:url value='/law/suit/view.do'/>?suitId=${h.suitId}"><c:out value="${h.caseNo}" default="(미입력)"/></a></td>
              <td><c:out value="${h.dyprKindNm}" default="-"/></td>
              <td><c:out value="${h.place}" default="-"/></td>
              <td><c:out value="${h.staffNm}" default="-"/></td>
              <td><button type="button" class="krds-btn small btn-del" data-id="${h.progId}">삭제</button></td>
            </tr>
          </c:forEach>
          <c:if test="${empty todayHearings}"><tr><td colspan="6" class="sc-empty">오늘 기일이 없습니다.</td></tr></c:if>
        </tbody>
      </table>
    </div>
    <div>
      <div class="sc-sec">이번 주 기일</div>
      <table class="krds-table tbl-list">
        <thead><tr><th style="width:88px;">일자</th><th style="width:52px;">시간</th><th style="width:110px;">사건번호</th><th style="width:90px;">기일구분</th><th>법원</th><th style="width:50px;">삭제</th></tr></thead>
        <tbody>
          <c:forEach var="h" items="${weekHearings}">
            <tr>
              <td><c:if test="${fn:length(h.progDt) ge 8}">${fn:substring(h.progDt,4,6)}-${fn:substring(h.progDt,6,8)}</c:if></td>
              <td><c:if test="${fn:length(h.progTm) ge 4}">${fn:substring(h.progTm,0,2)}:${fn:substring(h.progTm,2,4)}</c:if></td>
              <td><a href="<c:url value='/law/suit/view.do'/>?suitId=${h.suitId}"><c:out value="${h.caseNo}" default="(미입력)"/></a></td>
              <td><c:out value="${h.dyprKindNm}" default="-"/></td>
              <td><c:out value="${h.courtNm}" default="-"/></td>
              <td><button type="button" class="krds-btn small btn-del" data-id="${h.progId}">삭제</button></td>
            </tr>
          </c:forEach>
          <c:if test="${empty weekHearings}"><tr><td colspan="6" class="sc-empty">이번 주 기일이 없습니다.</td></tr></c:if>
        </tbody>
      </table>
    </div>
  </div>

  <%-- 일정 등록 모달 --%>
  <div class="law-modal-back" id="modalBack"></div>
  <div class="law-modal" id="regModal" role="dialog" aria-modal="true">
    <h2>일정(기일) 등록</h2>
    <form id="regForm" action="<c:url value='/law/schedule/save.do'/>" method="post">
      <input type="hidden" id="r_suitId" name="suitId" value=""/>
      <input type="hidden" id="r_progDesc" name="progDesc" value=""/>
      <div class="form-row"><label>사건 <span style="color:#d3273e;">*</span></label>
        <div style="display:flex; gap:8px; align-items:center;">
          <span id="r_suitLabel" class="law-picked" style="flex:1;">사건을 선택하세요.</span>
          <button type="button" class="krds-btn small" onclick="fnOpenSuitSearch();">사건검색</button>
        </div></div>
      <div class="form-row"><label for="r_dypr">기일구분</label>
        <select id="r_dypr" name="dyprKindCd" class="krds-select"><option value="">선택</option>
          <c:forEach var="c" items="${dyprKinds}"><option value="${c.code}"><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div class="form-row"><label for="r_dt">기일 일자 <span style="color:#d3273e;">*</span></label><input type="date" id="r_dt" name="progDt" class="krds-input"/></div>
      <div class="form-row"><label for="r_tm">시각</label><input type="time" id="r_tm" name="progTm" class="krds-input"/></div>
      <div class="form-row"><label for="r_place">장소</label><input type="text" id="r_place" name="place" class="krds-input" maxlength="120"/></div>
      <div class="form-row"><label for="r_result">결과</label><input type="text" id="r_result" name="resultDesc" class="krds-input" maxlength="200"/></div>
      <div class="modal-btns">
        <button type="button" class="krds-btn medium" onclick="fnCloseModal('regModal');">취소</button>
        <button type="button" class="krds-btn primary medium" onclick="fnSubmitReg();">등록</button>
      </div>
    </form>
  </div>

  <%-- 하루 일정 목록 모달 (2026-07-30 고객 요청) —
       달력 칸에는 3건까지만 보이고 나머지는 '외 N' 텍스트라 확인할 방법이 없었다.
       일정이 있는 날을 클릭하면 등록창 대신 그날 전체 목록을 띄운다('외 N' 클릭도 같은 칸이라 동일 동작).
       등록 동선은 이 목록 안 [이 날짜에 등록] 으로 남겨 기존 흐름을 잃지 않는다. --%>
  <div class="law-modal wide" id="dayModal" role="dialog" aria-modal="true">
    <h2 id="dayModalTitle">일정</h2>
    <div class="law-search-result">
      <table class="sc-week">
        <thead><tr><th style="width:70px;">시각</th><th style="width:150px;">사건번호</th><th style="width:150px;">기일구분</th><th>사건명</th><th style="width:150px;">법원</th><th style="width:70px;"></th></tr></thead>
        <tbody id="dayList"></tbody>
      </table>
    </div>
    <div class="modal-btns">
      <button type="button" class="krds-btn medium" onclick="fnCloseModal('dayModal');">닫기</button>
      <button type="button" class="krds-btn primary medium" id="dayAddBtn">이 날짜에 등록</button>
    </div>
  </div>

  <%-- 사건 검색 모달 (공용) --%>
  <div class="law-modal narrow" id="suitSearchModal" role="dialog" aria-modal="true">
    <h2>사건 검색</h2>
    <div style="display:flex; gap:8px;">
      <input type="text" id="s_keyword" class="krds-input" style="flex:1;" placeholder="사건번호 또는 사건명" onkeydown="if(event.key==='Enter'){event.preventDefault();fnSuitSearch();}"/>
      <button type="button" class="krds-btn primary small" onclick="fnSuitSearch();">검색</button>
    </div>
    <div class="law-search-result">
      <table><thead><tr><th style="width:120px;">사건번호</th><th>사건명</th><th style="width:70px;">심급</th></tr></thead>
        <tbody id="s_result"><tr><td colspan="3" style="color:#888;">검색어를 입력하세요.</td></tr></tbody></table>
    </div>
    <div class="modal-btns"><button type="button" class="krds-btn medium" onclick="fnCloseModal('suitSearchModal');">닫기</button></div>
  </div>

  <script>
  var SC = {
    ym: '<c:out value="${ym}"/>',
    today: '<c:out value="${todayYmd}"/>',
    monthUrl: '<c:url value="/law/schedule/monthJson.do"/>',
    searchUrl: '<c:url value="/law/suit/searchJson.do"/>',
    delUrl: '<c:url value="/law/schedule/deleteJson.do"/>',
    events: <c:out value="${monthJsonStr}" escapeXml="false"/>
  };
  function esc(s){ return (s==null?'':String(s)).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

  function fnRenderCal(){
    var y = parseInt(SC.ym.substring(0,4),10), m = parseInt(SC.ym.substring(4,6),10);
    document.getElementById('calTitle').textContent = y + '년 ' + m + '월';
    var byDay = {};
    (SC.events||[]).forEach(function(e){ if(e.progDt){ (byDay[e.progDt]=byDay[e.progDt]||[]).push(e); } });
    var first = new Date(y, m-1, 1), startDow = first.getDay();
    var daysInMonth = new Date(y, m, 0).getDate();
    var prevDays = new Date(y, m-1, 0).getDate();
    var dows = ['일','월','화','수','목','금','토'];
    var html = dows.map(function(d,i){ return '<div class="dow'+(i===0?' sun':(i===6?' sat':''))+'">'+d+'</div>'; }).join('');
    var cellCount = Math.ceil((startDow + daysInMonth)/7)*7;
    for(var i=0;i<cellCount;i++){
      var dayNum, cls='sc-cell', ymd=null, isOther=false;
      if(i < startDow){ dayNum = prevDays - startDow + 1 + i; isOther=true; }
      else if(i >= startDow + daysInMonth){ dayNum = i - startDow - daysInMonth + 1; isOther=true; }
      else { dayNum = i - startDow + 1; ymd = SC.ym + ('0'+dayNum).slice(-2); }
      if(isOther) cls += ' other';
      if(ymd === SC.today) cls += ' today';
      var dow = i % 7;
      var numCls = dow===0?'sun':(dow===6?'sat':'');
      var evHtml = '';
      if(ymd && byDay[ymd]){ evHtml = byDay[ymd].slice(0,3).map(function(e){
        var tm = (e.progTm && e.progTm.length>=4) ? (e.progTm.substring(0,2)+':'+e.progTm.substring(2,4)+' ') : '';
        return '<div class="sc-ev" title="'+esc((e.caseNo||'')+' '+(e.dyprKindNm||''))+'">'+tm+esc(e.dyprKindNm||e.caseNo||'기일')+'</div>'; }).join('')
        + (byDay[ymd].length>3 ? '<div class="law-cell-sub sc-more">외 '+(byDay[ymd].length-3)+'건 더보기</div>' : ''); }
      html += '<div class="'+cls+'"'+(ymd?' data-ymd="'+ymd+'"':'')+'><span class="dnum '+numCls+'">'+dayNum+'</span>'+evHtml+'</div>';
    }
    document.getElementById('calGrid').innerHTML = html;
  }
  function fnMonth(delta){
    var y = parseInt(SC.ym.substring(0,4),10), m = parseInt(SC.ym.substring(4,6),10) + delta;
    var d = new Date(y, m-1, 1);
    SC.ym = d.getFullYear() + ('0'+(d.getMonth()+1)).slice(-2);
    fetch(SC.monthUrl + '?ym=' + SC.ym, { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
      .then(function(r){ return r.json(); }).then(function(dt){ SC.events = dt.success ? (dt.list||[]) : []; fnRenderCal(); });
  }

  var SC_MODALS = ['regModal','suitSearchModal','dayModal'];
  function fnShowModal(id){ document.getElementById('modalBack').style.display='block'; document.getElementById(id).style.display='block'; }
  function fnCloseModal(id){ document.getElementById(id).style.display='none';
    var any=SC_MODALS.some(function(m){return document.getElementById(m).style.display==='block';});
    if(!any) document.getElementById('modalBack').style.display='none'; }

  /* ── 하루 일정 목록 (2026-07-30) ─────────────────────────────
     달력 칸은 3건까지만 그리므로 '외 N' 이하를 볼 방법이 없었다 → 그날 전체를 목록으로. */
  function fnDayEvents(ymd){
    return (SC.events||[]).filter(function(e){ return e.progDt === ymd; })
      .sort(function(a,b){ return String(a.progTm||'').localeCompare(String(b.progTm||'')); });
  }
  function fnOpenDay(ymd){
    var list = fnDayEvents(ymd);
    document.getElementById('dayModalTitle').textContent =
      ymd.substring(0,4)+'-'+ymd.substring(4,6)+'-'+ymd.substring(6,8)+' 일정 ('+list.length+'건)';
    document.getElementById('dayList').innerHTML = list.map(function(e){
      var tm = (e.progTm && e.progTm.length>=4) ? (e.progTm.substring(0,2)+':'+e.progTm.substring(2,4)) : '-';
      var caseCell = e.suitId
        ? '<a href="<c:url value="/law/suit/view.do"/>?suitId='+e.suitId+'">'+esc(e.caseNo||'(미입력)')+'</a>'
        : esc(e.caseNo||'(미입력)');
      /* 사건명은 별도 열 — 기일구분 칸에 같이 넣으면 좁은 칸에서 줄바꿈이 지저분해진다(2026-07-30) */
      return '<tr><td>'+tm+'</td><td>'+caseCell+'</td><td>'+esc(e.dyprKindNm||'기일')+'</td>'
           + '<td>'+(e.caseNm ? '<span style="color:#888;">'+esc(e.caseNm)+'</span>' : '-')+'</td>'
           + '<td>'+esc(e.courtNm||'-')+'</td>'
           + '<td><button type="button" class="krds-btn small btn-del" data-id="'+e.progId+'">삭제</button></td></tr>';
    }).join('') || '<tr><td colspan="6" class="sc-empty">이 날짜의 일정이 없습니다.</td></tr>';
    document.getElementById('dayAddBtn').onclick = function(){ fnCloseModal('dayModal'); fnOpenReg(ymd); };
    fnShowModal('dayModal');
  }

  function fnOpenReg(ymd){
    document.getElementById('regForm').reset();
    document.getElementById('r_suitId').value=''; document.getElementById('r_suitLabel').textContent='사건을 선택하세요.';
    if(ymd && ymd.length===8){ document.getElementById('r_dt').value = ymd.substring(0,4)+'-'+ymd.substring(4,6)+'-'+ymd.substring(6,8); }
    fnShowModal('regModal');
  }
  function fnSubmitReg(){
    if(!document.getElementById('r_suitId').value){ alert('사건을 선택하세요.'); return; }
    if(!document.getElementById('r_dt').value){ alert('기일 일자를 입력하세요.'); return; }
    var sel = document.getElementById('r_dypr'); document.getElementById('r_progDesc').value = sel.options[sel.selectedIndex] ? sel.options[sel.selectedIndex].text.replace('선택','') : '';
    document.getElementById('regForm').submit();
  }

  // 사건검색 공용
  function fnOpenSuitSearch(){ document.getElementById('s_keyword').value=''; document.getElementById('s_result').innerHTML='<tr><td colspan="3" style="color:#888;">검색어를 입력하세요.</td></tr>'; fnShowModal('suitSearchModal'); document.getElementById('s_keyword').focus(); }
  function fnSuitSearch(){
    var kw=document.getElementById('s_keyword').value.trim();
    fetch(SC.searchUrl + '?keyword=' + encodeURIComponent(kw), { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
      .then(function(r){ return r.json(); }).then(function(d){
        var tb=document.getElementById('s_result');
        if(!d.success || !d.list || !d.list.length){ tb.innerHTML='<tr><td colspan="3" style="color:#888;">검색 결과가 없습니다.</td></tr>'; return; }
        tb.innerHTML = d.list.map(function(s){ return '<tr onclick="fnPickSuit('+s.suitId+',\''+esc(s.caseNo||'')+'\',\''+esc(s.caseNm||'')+'\')"><td>'+esc(s.caseNo||'(미입력)')+'</td><td>'+esc(s.caseNm||'')+'</td><td>'+esc(s.instanceNm||'')+'</td></tr>'; }).join('');
      }).catch(function(){ document.getElementById('s_result').innerHTML='<tr><td colspan="3" style="color:#c00;">검색 실패</td></tr>'; });
  }
  function fnPickSuit(suitId, caseNo, caseNm){
    document.getElementById('r_suitId').value=suitId;
    document.getElementById('r_suitLabel').textContent=(caseNo||'(미입력)')+' '+(caseNm||'');
    fnCloseModal('suitSearchModal');
  }

  function fnDel(id){ if(!confirm('이 일정을 삭제할까요?')) return;
    var p=new URLSearchParams(); p.set('progId', id);
    fetch(SC.delUrl, { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'삭제 실패'); } }).catch(function(){ alert('삭제 요청 실패'); });
  }

  document.addEventListener('click', function(e){
    var del = e.target.closest('.btn-del'); if(del){ fnDel(del.dataset.id); return; }
    var link = e.target.closest('#dayList a'); if(link){ return; }   /* 사건 상세 링크는 그대로 이동 */
    var cell = e.target.closest('.sc-cell[data-ymd]');
    if(cell){
      /* 일정이 있으면 목록 먼저 보여주고(고객 요청), 빈 날은 기존대로 바로 등록 */
      var ymd = cell.dataset.ymd;
      if(fnDayEvents(ymd).length) fnOpenDay(ymd); else fnOpenReg(ymd);
      return;
    }
    if(e.target.id==='modalBack'){ SC_MODALS.forEach(function(m){ document.getElementById(m).style.display='none'; }); document.getElementById('modalBack').style.display='none'; }
  });
  fnRenderCal();
  </script>
</lay:layout>
