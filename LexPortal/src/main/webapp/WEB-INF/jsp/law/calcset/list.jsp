<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/calcset/list.jsp
  소송비용 요율설정 (LAW_MODULE_DESIGN.md §7.13) — 4탭(인지액/송달료/변호사비/법정이율) × 적용시작일별 세트 편집.
  세트 목록(현행 뱃지)·새 적용기준 추가(복사)·행 편집(추가/수정/삭제)·저장·삭제(미래=물리/과거=이력보존).
  요율 변경은 계산기 결과에만 영향(기존 저장 비용 데이터 불변).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송비용 요율설정</c:set>
<c:set var="pageHead">
  
  <style>
    .cs-tabs { display:flex; gap:4px; border-bottom:2px solid #256ef4; margin:10px 0 16px; }
    .cs-tab { padding:9px 22px; border:1px solid #ddd; border-bottom:none; border-radius:8px 8px 0 0; background:#f7f8fa; color:#555; cursor:pointer; font-size:14px; }
    .cs-tab.on { background:#256ef4; color:#fff; border-color:#256ef4; font-weight:600; }
    .cs-wrap { display:grid; grid-template-columns:260px 1fr; gap:20px; }
    .cs-setlist { border:1px solid #e3e3e3; border-radius:8px; padding:10px; height:fit-content; }
    .cs-set { display:flex; justify-content:space-between; align-items:center; padding:9px 10px; border-radius:6px; cursor:pointer; font-size:14px; }
    .cs-set:hover { background:#f4f7ff; }
    .cs-set.on { background:#e8f0ff; font-weight:600; }
    .cs-badge { font-size:11px; background:#1a7f37; color:#fff; border-radius:9px; padding:1px 7px; }
    .cs-help { background:#f7f8fa; border-radius:6px; padding:8px 12px; font-size:12.5px; color:#555; margin-bottom:10px; }
    .cs-grid { width:100%; border-collapse:collapse; }
    .cs-grid th, .cs-grid td { border:1px solid #ddd; padding:5px 6px; font-size:13px; }
    .cs-grid th { background:#f7f8fa; }
    .cs-grid input, .cs-grid select { width:100%; box-sizing:border-box; border:1px solid #ccc; border-radius:4px; padding:4px 5px; font-size:13px; }
    .cs-grid td.num input { text-align:right; }
    .cs-toolbar { display:flex; justify-content:space-between; align-items:center; margin:12px 0; gap:10px; flex-wrap:wrap; }
    .cs-applyrow { display:flex; align-items:center; gap:8px; }
    /* 계산기 공용 모달 베이스 (_calcModal.jspf 가 참조) */
    .law-modal-back { position:fixed; inset:0; background:rgba(0,0,0,.45); display:none; z-index:1000; }
    .law-modal { position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#fff; border-radius:12px;
                 padding:26px 30px; display:none; z-index:1001; box-shadow:0 8px 30px rgba(0,0,0,.2); }
    .law-modal h2 { font-size:19px; }
    /* 반응형 (2026-08-04 전면 적용) — 세트목록 상단 스택, 탭 줄바꿈, 요율 그리드 자체 가로 스크롤 */
    @media (max-width: 900px) {
      .cs-wrap { grid-template-columns: 1fr; }
    }
    @media (max-width: 640px) {
      .cs-tabs { flex-wrap: wrap; row-gap: 6px; }
      .cs-tab { padding: 9px 14px; flex: 0 0 auto; }
      .cs-tabs .krds-btn { margin-left: 0 !important; }
      .cs-grid { display: block; overflow-x: auto; }
      .law-modal { max-width: calc(100% - 24px); box-sizing: border-box; padding: 20px 16px; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>소송비용 요율설정</h1>
    <p class="page-desc">소송비용 계산기의 요율을 시점별 세트로 관리합니다. 요율 변경은 계산기 결과에만 반영되며 기존 저장된 비용은 바뀌지 않습니다.</p>
  </div>

  <div class="cs-tabs">
    <div class="cs-tab on" data-t="STAMP" onclick="fnTab('STAMP');">인지액</div>
    <div class="cs-tab" data-t="POST" onclick="fnTab('POST');">송달료</div>
    <div class="cs-tab" data-t="LAWYER" onclick="fnTab('LAWYER');">변호사비</div>
    <div class="cs-tab" data-t="LEGAL_INT" onclick="fnTab('LEGAL_INT');">법정이율</div>
    <button type="button" class="krds-btn small primary" style="margin-left:auto; align-self:center; margin-bottom:6px;"
            onclick="fnOpenCalcFromSet();" title="선택한 세트의 적용시작일을 기준일로 계산기를 엽니다">소송비용 계산기</button>
  </div>

  <div class="cs-wrap">
    <div class="cs-setlist">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
        <strong style="font-size:14px;">적용시작일 세트</strong>
      </div>
      <div id="cs_sets"><div style="color:#888; font-size:13px; padding:8px 0;">불러오는 중…</div></div>
      <button type="button" class="krds-btn small primary" style="width:100%; margin-top:10px;" onclick="fnNewSet();">＋ 새 적용기준 추가</button>
    </div>

    <div>
      <div id="cs_help" class="cs-help"></div>
      <div class="cs-toolbar">
        <div class="cs-applyrow">
          <label for="cs_applyDt" style="font-size:13px;">적용시작일</label>
          <input type="date" id="cs_applyDt" style="width:170px;"/>
        </div>
        <div style="display:flex; gap:6px;">
          <button type="button" class="krds-btn small" onclick="fnAddRow();">＋ 행 추가</button>
          <button type="button" class="krds-btn small" onclick="fnDeleteSet();">세트 삭제</button>
          <button type="button" class="krds-btn small primary" onclick="fnSaveSet();">저장</button>
        </div>
      </div>
      <table class="cs-grid">
        <thead>
          <tr>
            <th style="width:130px;">요율종류</th>
            <th style="width:90px;">항목코드</th>
            <th style="width:130px;">구간하한(원)</th>
            <th style="width:110px;">값</th>
            <th style="width:120px;">가산·정액(원)</th>
            <th>근거</th>
            <th style="width:50px;">삭제</th>
          </tr>
        </thead>
        <tbody id="cs_rows"></tbody>
      </table>
      <p style="font-size:12px; color:#888; margin-top:8px;">
        · 값 의미: 구간표=율(예 0.005), 배율=배수(예 1.5), 단가·회수=정수, 이율=% · 구간표 행은 구간하한 필수(오름차순·중복 금지) · 정액사건(강제경매 등)은 값 0 + 가산·정액에 금액.
      </p>
    </div>
  </div>

  <script>
  var TAB = 'STAMP';
  var TAB_TYPES = {
    STAMP: [['STAMP','구간표'], ['STAMP_MULT','사건종류배율']],
    POST: [['POST_UNIT','우편료단가'], ['POST_COUNT','사건유형회수']],
    LAWYER: [['LAWYER','구간표']],
    LEGAL_INT: [['LEGAL_INT','법정이율']]
  };
  var TAB_HELP = {
    STAMP: '인지액 = 구간표(소가 구간별 율·가산액)로 산출 후 사건종류 배율 적용. 항목코드: 배율은 C1~C8, 최소액은 MIN_AMT(값=최소 인지액).',
    POST: '송달료 = 사건유형별 회수 × 당사자수 × 우편료 단가. 단가는 POST_UNIT 1행(값=원), 회수는 POST_COUNT 유형별(항목 T01~T17, 값=회수).',
    LAWYER: '변호사비 산입 상한 = 구간표(소가 구간별 base=가산액 + 초과분×율). 구간하한 오름차순.',
    LEGAL_INT: '지연이자 계산기의 이율 프리셋. 항목코드 CIVIL(민사)/COMM(상사)/SOCHOK(소촉법), 값=연 %.'
  };
  var CUR_LATEST = null;

  function esc(s){ return (s==null?'':String(s)).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
  function fmtDate(d){ return (d && d.length===8) ? d.substring(0,4)+'-'+d.substring(4,6)+'-'+d.substring(6,8) : ''; }
  function toYmd(v){ return (v||'').replace(/-/g,''); }
  function todayYmd(){ var d=new Date(); return d.getFullYear()+('0'+(d.getMonth()+1)).slice(-2)+('0'+d.getDate()).slice(-2); }

  function fnTab(t){
    TAB = t;
    Array.prototype.forEach.call(document.querySelectorAll('.cs-tab'), function(b){ b.classList.toggle('on', b.dataset.t===t); });
    document.getElementById('cs_help').textContent = TAB_HELP[t];
    fnLoadSets();
  }

  function fnLoadSets(sel){
    fetch('<c:url value="/law/calcset/setDatesJson.do"/>?tab=' + TAB, { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
      .then(function(r){ return r.json(); }).then(function(d){
        if(!d.success){ document.getElementById('cs_sets').innerHTML='<div style="color:#c00;">'+esc(d.message||'조회 실패')+'</div>'; return; }
        CUR_LATEST = d.latest;
        var today = todayYmd();
        // 현행 = APPLY_DT <= today 중 최신
        var current = null;
        d.sets.forEach(function(s){ if(s.applyDt <= today && (current===null || s.applyDt > current)) current = s.applyDt; });
        var html = d.sets.map(function(s){
          var badge = (s.applyDt === current) ? '<span class="cs-badge">현행</span>' : '';
          return '<div class="cs-set" data-dt="'+s.applyDt+'" onclick="fnLoadSet(\''+s.applyDt+'\')">'
               + '<span>'+fmtDate(s.applyDt)+' <span style="color:#888;font-size:12px;">('+s.cnt+')</span></span>'+badge+'</div>';
        }).join('');
        document.getElementById('cs_sets').innerHTML = html || '<div style="color:#888; font-size:13px; padding:8px 0;">세트가 없습니다. [새 적용기준 추가]로 등록하세요.</div>';
        var pick = sel || (d.sets.length ? d.sets[0].applyDt : null);
        if(pick) fnLoadSet(pick); else { document.getElementById('cs_rows').innerHTML=''; document.getElementById('cs_applyDt').value=''; }
      }).catch(function(){ document.getElementById('cs_sets').innerHTML='<div style="color:#c00;">조회 실패</div>'; });
  }

  function fnMarkActive(dt){
    Array.prototype.forEach.call(document.querySelectorAll('.cs-set'), function(el){ el.classList.toggle('on', el.dataset.dt===dt); });
  }

  function fnLoadSet(applyDt){
    fnMarkActive(applyDt);
    document.getElementById('cs_applyDt').value = fmtDate(applyDt);
    fetch('<c:url value="/law/calcset/setRowsJson.do"/>?tab='+TAB+'&applyDt='+applyDt, { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
      .then(function(r){ return r.json(); }).then(function(d){
        if(!d.success){ alert(d.message||'조회 실패'); return; }
        renderRows(d.rows);
      });
  }

  function typeSelect(sel){
    return '<select class="c-type">' + TAB_TYPES[TAB].map(function(t){
      return '<option value="'+t[0]+'"'+(t[0]===sel?' selected':'')+'>'+t[1]+'</option>'; }).join('') + '</select>';
  }
  function rowHtml(r){
    r = r || {};
    return '<tr>'
      + '<td>'+typeSelect(r.calcType || TAB_TYPES[TAB][0][0])+'</td>'
      + '<td><input class="c-item" value="'+esc(r.itemCd||'')+'"/></td>'
      + '<td class="num"><input class="c-section" inputmode="numeric" value="'+(r.sectionAmt!=null?r.sectionAmt:'')+'"/></td>'
      + '<td class="num"><input class="c-rate" inputmode="decimal" value="'+(r.rateVal!=null?r.rateVal:'')+'"/></td>'
      + '<td class="num"><input class="c-add" inputmode="numeric" value="'+(r.addAmt!=null?r.addAmt:'')+'"/></td>'
      + '<td><input class="c-rmk" value="'+esc(r.rmk||'')+'"/></td>'
      + '<td style="text-align:center;"><button type="button" class="krds-btn small" onclick="this.closest(\'tr\').remove();">×</button></td>'
      + '</tr>';
  }
  function renderRows(rows){
    document.getElementById('cs_rows').innerHTML = (rows||[]).map(rowHtml).join('');
  }
  function fnAddRow(){ document.getElementById('cs_rows').insertAdjacentHTML('beforeend', rowHtml(null)); }

  // 새 적용기준 추가 = 현재 표시된 세트(또는 최신) 행 복사 + 적용일 오늘로
  function fnNewSet(){
    if(!document.getElementById('cs_rows').children.length && CUR_LATEST){
      fnLoadSet(CUR_LATEST); // 최신 세트를 편집판에 올린 뒤
    }
    // 복사본을 새 적용일로 저장하도록 적용일만 오늘로 세팅(기존 세트는 그대로 남고 새 세트 생성)
    var t = todayYmd();
    document.getElementById('cs_applyDt').value = fmtDate(t);
    fnMarkActive(null);
    alert('현재 세트가 편집판에 복사되었습니다. 적용시작일을 개정 시행일로 바꾸고 요율을 수정한 뒤 [저장]하세요.');
  }

  function collectRows(){
    var rows = [];
    Array.prototype.forEach.call(document.querySelectorAll('#cs_rows tr'), function(tr){
      var section = tr.querySelector('.c-section').value.replace(/[^0-9]/g,'');
      var rate = tr.querySelector('.c-rate').value.replace(/[^0-9.]/g,'');
      var add = tr.querySelector('.c-add').value.replace(/[^0-9]/g,'');
      rows.push({
        calcType: tr.querySelector('.c-type').value,
        itemCd: tr.querySelector('.c-item').value.trim() || null,
        sectionAmt: section==='' ? null : parseInt(section,10),
        rateVal: rate==='' ? null : parseFloat(rate),
        addAmt: add==='' ? null : parseInt(add,10),
        rmk: tr.querySelector('.c-rmk').value.trim() || null
      });
    });
    return rows;
  }

  function fnSaveSet(){
    var applyDt = toYmd(document.getElementById('cs_applyDt').value);
    if(applyDt.length !== 8){ alert('적용시작일을 입력하세요.'); return; }
    var rows = collectRows();
    if(!rows.length){ alert('요율 행을 1개 이상 입력하세요.'); return; }
    var p = new URLSearchParams();
    p.set('tab', TAB); p.set('applyDt', applyDt); p.set('rowsJson', JSON.stringify(rows));
    fetch('<c:url value="/law/calcset/saveSetJson.do"/>', { method:'POST', credentials:'same-origin',
        headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){
        if(d.success){ alert('저장했습니다.'); fnLoadSets(applyDt); } else { alert(d.message||'저장 실패'); }
      }).catch(function(){ alert('저장 요청 실패'); });
  }

  function fnDeleteSet(){
    var applyDt = toYmd(document.getElementById('cs_applyDt').value);
    if(applyDt.length !== 8){ alert('삭제할 세트를 선택하세요.'); return; }
    var future = applyDt > todayYmd();
    if(!confirm(future ? '이 미래 적용 세트를 삭제할까요?' : '이 세트를 삭제(비활성)할까요?\n과거·현행 세트는 이력 보존을 위해 비활성 처리됩니다.')) return;
    var p = new URLSearchParams(); p.set('tab', TAB); p.set('applyDt', applyDt);
    fetch('<c:url value="/law/calcset/deleteSetJson.do"/>', { method:'POST', credentials:'same-origin',
        headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){
        if(d.success){ alert('처리했습니다.'); fnLoadSets(); } else { alert(d.message||'삭제 실패'); }
      }).catch(function(){ alert('삭제 요청 실패'); });
  }

  // 초기 로드
  document.getElementById('cs_help').textContent = TAB_HELP[TAB];
  fnLoadSets();

  // 소송비용 계산기 — 편집 중(선택) 세트의 적용시작일을 기준일로 열어, 저장한 요율이 그 시점 계산에
  // 그대로 반영되는지 즉석 검증. 세트 미선택이면 공용 기본(오늘)이 유지된다. ★저장 후 확인 (미저장 편집분은 미반영)
  function fnOpenCalcFromSet(){
    fnOpenCalc();
    var v = document.getElementById('cs_applyDt').value;
    if(v){ document.getElementById('calc_baseDt').value = v; fnCalcLoadRates(); }
  }
  </script>

  <%-- 소송비용 계산기 공용 모달 — cost/suit 와 동일 프래그먼트 --%>
  <%-- 소송비용 계산기 모달은 mgr 데코레이터가 전역 포함(2026-08-06) — 화면별 include 제거. [계산기] 버튼은 그대로 fnOpenCalc() 호출 --%>
</lay:layout>
