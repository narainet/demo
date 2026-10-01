<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%
 /**
  * @Class Name : EgovSatisfactionList.jsp
  * @Description : 만족도 (JSON/AJAX — 별점+내용 등록/수정/삭제, 등록순·최신순, 케밥 수정/삭제, 인라인 편집, 평균 별점 요약)
  * @Modification Information
  * @  수정일        수정자    수정내용
  * @ -------       -------   ---------------------------
  * @ 2009.06.29   한성곤     최초 생성
  * @ 2026.07.10   RLMS      JSON/AJAX 재작성(댓글과 동일 패턴). 아이콘/이미지첨부·익명 password 없음.
  */
%>
<c:if test="${type == 'body'}">
<%-- 링크 접두 — 사용자(/cop/stf/user)와 관리(/cop/stf)가 이 조각을 공유한다. --%>
<c:set var="stfUrlBase" value="${empty stfUrlBase ? '/cop/stf' : stfUrlBase}"/>
<style type="text/css">
.rs-box { clear:both; margin:16px 0 0; border:1px solid #d9e1ec; border-radius:6px; background:#fff; }
.rs-box * { box-sizing:border-box; }
.rs-head { display:flex; align-items:center; justify-content:space-between; gap:12px; padding:14px 16px; border-bottom:1px solid #e8edf4; background:#f8fafc; }
.rs-head h3 { margin:0; font-size:15px; color:#1f2937; line-height:1.4; }
.rs-head .rs-count { color:#2f66b3; font-weight:700; margin-left:4px; }
.rs-avg { color:#f59e0b; font-size:14px; }
.rs-avg .rs-avg-num { color:#6b7280; font-size:12px; margin-left:4px; }
.rs-sort { display:flex; align-items:center; gap:10px; }
.rs-sort-btn { border:0; background:none; padding:0; cursor:pointer; font-size:13px; color:#8a94a6; }
.rs-sort-btn.active { color:#1f2937; font-weight:700; }
.rs-refresh { border:0; background:none; padding:0 0 0 4px; cursor:pointer; font-size:14px; color:#8a94a6; }
.rs-list { padding:0 16px; }
.rs-list ul { margin:0; padding:0; list-style:none; }
.rs-list li { position:relative; padding:14px 0; border-bottom:1px solid #edf1f6; }
.rs-list li:last-child { border-bottom:0; }
.rs-meta { display:flex; align-items:center; gap:8px; margin-bottom:6px; color:#6b7280; font-size:12px; }
.rs-meta strong { color:#1f2937; font-size:13px; }
.rs-stars { color:#f59e0b; letter-spacing:1px; }
.rs-text { margin:0; color:#333; line-height:1.6; word-break:break-word; white-space:pre-wrap; }
.rs-empty { padding:26px 0; text-align:center; color:#8a94a6; }
.rs-kebab { position:absolute; top:12px; right:0; }
.rs-kebab-btn { border:0; background:none; cursor:pointer; font-size:18px; line-height:1; color:#8a94a6; padding:2px 6px; }
.rs-kebab-menu { display:none; position:absolute; top:24px; right:0; min-width:96px; background:#fff; border:1px solid #d1d5db; border-radius:6px; box-shadow:0 4px 12px rgba(0,0,0,.12); padding:4px 0; z-index:20; }
.rs-kebab.open .rs-kebab-menu { display:block; }
.rs-kebab-menu button { display:block; width:100%; text-align:left; border:0; background:none; padding:8px 14px; cursor:pointer; font-size:13px; color:#374151; }
.rs-kebab-menu button:hover { background:#f4f6fb; }
.rs-write { padding:14px 16px; border-top:1px solid #e8edf4; background:#fbfcfe; }
.rs-writer { font-weight:700; color:#1f2937; font-size:13px; margin-bottom:8px; }
.rs-rate { margin-bottom:8px; }
.rs-star { cursor:pointer; font-size:22px; color:#d1d5db; line-height:1; }
.rs-star.on { color:#f59e0b; }
.rs-ta { width:100%; min-height:56px; border:1px solid #cbd5e1; border-radius:6px; padding:9px 11px; background:#fff; resize:vertical; font:inherit; line-height:1.5; }
.rs-bar { display:flex; align-items:center; justify-content:flex-end; gap:10px; margin-top:8px; }
.rs-counter { color:#98a2b3; font-size:12px; margin-right:auto; }
.rs-msg { color:#d04437; font-size:12px; margin:6px 16px 0; }
.rs-btn { border:1px solid #cbd5e1; background:#fff; color:#374151; border-radius:6px; padding:6px 16px; cursor:pointer; font-size:13px; }
.rs-btn.primary { border-color:#2f66b3; background:#2f66b3; color:#fff; }
.rs-btn:disabled { opacity:.5; cursor:default; }
.rs-edit { margin-top:8px; }
.rs-edit .rs-bar { margin-top:6px; }
</style>

<div class="rs-box" id="rsBox"
     data-base="<c:url value='${stfUrlBase}'/>"
     data-bbsid="<c:out value='${searchVO.bbsId}'/>"
     data-nttid="<c:out value='${searchVO.nttId}'/>"
     data-max="1000">
  <div class="rs-head">
    <h3>만족도 <span class="rs-count" id="rsCount">0</span> <span class="rs-avg" id="rsAvg"></span></h3>
    <div class="rs-sort">
      <button type="button" class="rs-sort-btn active" data-sort="reg">등록순</button>
      <button type="button" class="rs-sort-btn" data-sort="latest">최신순</button>
      <button type="button" class="rs-refresh" id="rsRefresh" title="새로고침">&#8635;</button>
    </div>
  </div>
  <p class="rs-msg" id="rsMsg" style="display:none;"></p>
  <div class="rs-list"><ul id="rsList"></ul></div>
  <div class="rs-write">
    <div class="rs-writer"><c:out value="${myName}"/></div>
    <div class="rs-rate" id="rsRate" data-val="0">
      <span class="rs-star" data-v="1">&#9733;</span><span class="rs-star" data-v="2">&#9733;</span><span class="rs-star" data-v="3">&#9733;</span><span class="rs-star" data-v="4">&#9733;</span><span class="rs-star" data-v="5">&#9733;</span>
    </div>
    <textarea id="rsInput" class="rs-ta" maxlength="1000" placeholder="만족도 의견을 남겨보세요 (선택)"></textarea>
    <div class="rs-bar">
      <span class="rs-counter"><span id="rsCounterNum">0</span>/1000</span>
      <button type="button" class="rs-btn primary" id="rsSubmit">등록</button>
    </div>
  </div>
</div>

<script>
(function(){
  var box = document.getElementById('rsBox');
  if (!box || box.dataset.rsInit) return;
  box.dataset.rsInit = '1';

  var BASE  = box.getAttribute('data-base');
  var BBSID = box.getAttribute('data-bbsid');
  var NTTID = box.getAttribute('data-nttid');
  var MAX   = parseInt(box.getAttribute('data-max'), 10) || 1000;
  var LOGIN_URL = '<c:url value="/uat/uia/egovLoginUsr.do"/>';

  var listEl    = document.getElementById('rsList');
  var countEl   = document.getElementById('rsCount');
  var avgEl     = document.getElementById('rsAvg');
  var msgEl     = document.getElementById('rsMsg');
  var input     = document.getElementById('rsInput');
  var submitBtn = document.getElementById('rsSubmit');
  var counterN  = document.getElementById('rsCounterNum');
  var rate      = document.getElementById('rsRate');
  var sort = 'reg';

  function showMsg(t){ if(!t){ msgEl.style.display='none'; return; } msgEl.textContent=t; msgEl.style.display='block'; }
  function form(obj){ var p=new URLSearchParams(); for(var k in obj) p.append(k, obj[k]); return p; }
  function stars(n){ n=parseInt(n,10)||0; var s=''; for(var i=0;i<5;i++) s+= (i<n?'★':'☆'); return s; }

  function post(url, obj){
    return fetch(url, {method:'POST', credentials:'same-origin',
        headers:{'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'},
        body: form(obj).toString()})
      .then(function(r){ return r.json(); })
      .then(function(d){ if(d && d.login){ location.href=LOGIN_URL; return {ok:false,handled:true}; } return d; });
  }

  // 별점 선택 위젯(등록/편집 공용)
  function bindRate(el){
    var starsEl = el.querySelectorAll('.rs-star');
    function paint(v){ for(var i=0;i<starsEl.length;i++){ starsEl[i].classList.toggle('on', i < v); } }
    for (var i=0;i<starsEl.length;i++){
      (function(st){
        st.addEventListener('click', function(){ var v=parseInt(st.getAttribute('data-v'),10); el.setAttribute('data-val', v); paint(v); });
      })(starsEl[i]);
    }
    paint(parseInt(el.getAttribute('data-val'),10)||0);
    return { get:function(){ return parseInt(el.getAttribute('data-val'),10)||0; }, set:function(v){ el.setAttribute('data-val',v); paint(v); } };
  }
  var writeRate = bindRate(rate);

  // ── 렌더 ──────────────────────────────────────────────
  function render(data){
    listEl.innerHTML = '';
    countEl.textContent = data.count;
    var avg = parseFloat(data.summary || '0') || 0;
    avgEl.innerHTML = '';
    if (data.count > 0){
      var st = document.createElement('span'); st.textContent = stars(Math.round(avg));
      var nm = document.createElement('span'); nm.className='rs-avg-num'; nm.textContent = avg.toFixed(1);
      avgEl.appendChild(st); avgEl.appendChild(nm);
    }
    if (!data.list || data.list.length === 0){
      var li = document.createElement('li');
      var e = document.createElement('p'); e.className='rs-empty'; e.textContent='등록된 만족도가 없습니다.';
      li.appendChild(e); listEl.appendChild(li); return;
    }
    data.list.forEach(function(c){ listEl.appendChild(row(c)); });
  }

  function fmtDate(s){ if(!s) return ''; return s.length > 16 ? s.substring(0,16) : s; }

  function row(c){
    var li = document.createElement('li');
    li.setAttribute('data-no', c.stsfdgNo);

    var meta = document.createElement('div'); meta.className='rs-meta';
    var nm = document.createElement('strong'); nm.textContent = c.wrterNm || '';
    var star = document.createElement('span'); star.className='rs-stars'; star.textContent = stars(c.stsfdg);
    var sep = document.createElement('span'); sep.textContent='|';
    var dt = document.createElement('span'); dt.textContent = fmtDate(c.regDt);
    meta.appendChild(nm); meta.appendChild(star); meta.appendChild(sep); meta.appendChild(dt);

    li.appendChild(meta);
    if (c.content){
      var text = document.createElement('p'); text.className='rs-text'; text.textContent = c.content;
      li.appendChild(text);
    }
    if (c.mine){ li.appendChild(kebab(c)); }
    return li;
  }

  function kebab(c){
    var wrap = document.createElement('div'); wrap.className='rs-kebab';
    var btn = document.createElement('button'); btn.type='button'; btn.className='rs-kebab-btn'; btn.innerHTML='&#8942;'; btn.title='더보기';
    var menu = document.createElement('div'); menu.className='rs-kebab-menu';
    var eBtn = document.createElement('button'); eBtn.type='button'; eBtn.textContent='수정';
    var dBtn = document.createElement('button'); dBtn.type='button'; dBtn.textContent='삭제';
    menu.appendChild(eBtn); menu.appendChild(dBtn);
    wrap.appendChild(btn); wrap.appendChild(menu);
    btn.addEventListener('click', function(ev){ ev.stopPropagation(); closeKebabs(wrap); wrap.classList.toggle('open'); });
    eBtn.addEventListener('click', function(ev){ ev.stopPropagation(); wrap.classList.remove('open'); beginEdit(c); });
    dBtn.addEventListener('click', function(ev){ ev.stopPropagation(); wrap.classList.remove('open'); doDelete(c); });
    return wrap;
  }
  function closeKebabs(except){
    var opened = listEl.querySelectorAll('.rs-kebab.open');
    for (var i=0;i<opened.length;i++){ if (opened[i]!==except) opened[i].classList.remove('open'); }
  }
  document.addEventListener('click', function(){ closeKebabs(null); });

  // ── 인라인 편집 ───────────────────────────────────────
  function beginEdit(c){
    var li = listEl.querySelector('li[data-no="'+c.stsfdgNo+'"]');
    if (!li || li.querySelector('.rs-edit')) return;
    var text = li.querySelector('.rs-text'); if (text) text.style.display='none';
    var kb = li.querySelector('.rs-kebab'); if (kb) kb.style.display='none';

    var wrap = document.createElement('div'); wrap.className='rs-edit';
    var rt = document.createElement('div'); rt.className='rs-rate'; rt.setAttribute('data-val', c.stsfdg||0);
    rt.innerHTML = '<span class="rs-star" data-v="1">★</span><span class="rs-star" data-v="2">★</span><span class="rs-star" data-v="3">★</span><span class="rs-star" data-v="4">★</span><span class="rs-star" data-v="5">★</span>';
    var ta = document.createElement('textarea'); ta.className='rs-ta'; ta.maxLength=MAX; ta.value=c.content||'';
    var bar = document.createElement('div'); bar.className='rs-bar';
    var cnt = document.createElement('span'); cnt.className='rs-counter';
    var num = document.createElement('span'); num.textContent=(c.content||'').length;
    cnt.appendChild(num); cnt.appendChild(document.createTextNode('/'+MAX));
    var cancel = document.createElement('button'); cancel.type='button'; cancel.className='rs-btn'; cancel.textContent='취소';
    var save = document.createElement('button'); save.type='button'; save.className='rs-btn primary'; save.textContent='등록';
    bar.appendChild(cnt); bar.appendChild(cancel); bar.appendChild(save);
    wrap.appendChild(rt); wrap.appendChild(ta); wrap.appendChild(bar); li.appendChild(wrap);

    var editRate = bindRate(rt);
    ta.focus();
    ta.addEventListener('input', function(){ num.textContent = ta.value.length; });
    cancel.addEventListener('click', function(){ wrap.remove(); if(text) text.style.display=''; if(kb) kb.style.display=''; });
    save.addEventListener('click', function(){
      var v = editRate.get();
      if (v < 1){ showMsg('만족도(별점)를 선택해 주세요.'); return; }
      save.disabled = true;
      post(BASE+'/updateJson.do', {stsfdgNo:c.stsfdgNo, nttId:NTTID, bbsId:BBSID, stsfdg:v, stsfdgCn:ta.value})
        .then(function(d){ if(d.handled) return; if(d && d.ok){ load(); } else { save.disabled=false; showMsg((d&&d.msg)||'수정 실패'); } })
        .catch(function(){ save.disabled=false; showMsg('수정 중 오류가 발생했습니다.'); });
    });
  }

  function doDelete(c){
    if (!confirm('만족도를 삭제하시겠습니까?')) return;
    post(BASE+'/deleteJson.do', {stsfdgNo:c.stsfdgNo, nttId:NTTID, bbsId:BBSID})
      .then(function(d){ if(d.handled) return; if(d && d.ok){ load(); } else { showMsg((d&&d.msg)||'삭제 실패'); } })
      .catch(function(){ showMsg('삭제 중 오류가 발생했습니다.'); });
  }

  // ── 등록 ──────────────────────────────────────────────
  input.addEventListener('input', function(){ counterN.textContent = input.value.length; });
  submitBtn.addEventListener('click', function(){
    var v = writeRate.get();
    if (v < 1){ showMsg('만족도(별점)를 선택해 주세요.'); return; }
    submitBtn.disabled = true;
    post(BASE+'/insertJson.do', {nttId:NTTID, bbsId:BBSID, stsfdg:v, stsfdgCn:input.value})
      .then(function(d){ if(d.handled) return;
        submitBtn.disabled = false;
        if (d && d.ok){ input.value=''; counterN.textContent='0'; writeRate.set(0); showMsg(''); load(); }
        else { showMsg((d&&d.msg)||'등록 실패'); }
      })
      .catch(function(){ submitBtn.disabled=false; showMsg('등록 중 오류가 발생했습니다.'); });
  });

  // ── 정렬/새로고침/로드 ────────────────────────────────
  var sortBtns = box.querySelectorAll('.rs-sort-btn');
  for (var i=0;i<sortBtns.length;i++){
    sortBtns[i].addEventListener('click', function(){
      sort = this.getAttribute('data-sort');
      for (var j=0;j<sortBtns.length;j++) sortBtns[j].classList.remove('active');
      this.classList.add('active');
      load();
    });
  }
  document.getElementById('rsRefresh').addEventListener('click', function(){ load(); });

  function load(){
    showMsg('');
    var url = BASE+'/listJson.do?bbsId='+encodeURIComponent(BBSID)+'&nttId='+encodeURIComponent(NTTID)+'&sort='+sort;
    fetch(url, {credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'}})
      .then(function(r){ return r.json(); })
      .then(function(d){ if(d && d.login){ location.href=LOGIN_URL; return; } if(d && d.ok){ render(d); } })
      .catch(function(){ showMsg('만족도를 불러오지 못했습니다.'); });
  }
  load();
})();
</script>
</c:if>
