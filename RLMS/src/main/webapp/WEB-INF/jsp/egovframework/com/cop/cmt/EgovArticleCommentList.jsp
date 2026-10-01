<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%
 /**
  * @Class Name : EgovArticleCommentList.jsp
  * @Description : 댓글 (JSON/AJAX — 페이지 리로드 없이 등록/수정/삭제, 등록순·최신순 정렬, 케밥 수정/삭제, 인라인 편집)
  * @Modification Information
  * @  수정일        수정자    수정내용
  * @ -------       -------   ---------------------------
  * @ 2009.06.29   한성곤     최초 생성
  * @ 2026.07.10   RLMS      JSON/AJAX 재작성(정렬·케밥·인라인편집·글자수). 스타일 기조 유지, 아이콘/이미지첨부 없음.
  */
%>
<c:if test="${type == 'body'}">
<%-- 링크 접두 — 사용자 게시판(/cop/cmt/user)과 관리 게시판(/cop/cmt)이 이 조각을 공유한다. --%>
<c:set var="cmtUrlBase" value="${empty cmtUrlBase ? '/cop/cmt' : cmtUrlBase}"/>
<style type="text/css">
.rc-box { clear:both; margin:24px 0 0; border:1px solid #d9e1ec; border-radius:6px; background:#fff; }
.rc-box * { box-sizing:border-box; }
.rc-head { display:flex; align-items:center; justify-content:space-between; gap:12px; padding:14px 16px; border-bottom:1px solid #e8edf4; background:#f8fafc; }
.rc-head h3 { margin:0; font-size:15px; color:#1f2937; line-height:1.4; }
.rc-head .rc-count { color:#2f66b3; font-weight:700; margin-left:4px; }
.rc-sort { display:flex; align-items:center; gap:10px; }
.rc-sort-btn { border:0; background:none; padding:0; cursor:pointer; font-size:13px; color:#8a94a6; }
.rc-sort-btn.active { color:#1f2937; font-weight:700; }
.rc-refresh { border:0; background:none; padding:0 0 0 4px; cursor:pointer; font-size:14px; color:#8a94a6; }
.rc-list { padding:0 16px; }
.rc-list ul { margin:0; padding:0; list-style:none; }
.rc-list li { position:relative; padding:14px 0; border-bottom:1px solid #edf1f6; }
.rc-list li:last-child { border-bottom:0; }
.rc-meta { display:flex; align-items:center; gap:8px; margin-bottom:6px; color:#6b7280; font-size:12px; }
.rc-meta strong { color:#1f2937; font-size:13px; }
.rc-text { margin:0; color:#333; line-height:1.6; word-break:break-word; white-space:pre-wrap; }
.rc-empty { padding:26px 0; text-align:center; color:#8a94a6; }
/* 케밥(⋯) 메뉴 */
.rc-kebab { position:absolute; top:12px; right:0; }
.rc-kebab-btn { border:0; background:none; cursor:pointer; font-size:18px; line-height:1; color:#8a94a6; padding:2px 6px; }
.rc-kebab-menu { display:none; position:absolute; top:24px; right:0; min-width:96px; background:#fff; border:1px solid #d1d5db; border-radius:6px; box-shadow:0 4px 12px rgba(0,0,0,.12); padding:4px 0; z-index:20; }
.rc-kebab.open .rc-kebab-menu { display:block; }
.rc-kebab-menu button { display:block; width:100%; text-align:left; border:0; background:none; padding:8px 14px; cursor:pointer; font-size:13px; color:#374151; }
.rc-kebab-menu button:hover { background:#f4f6fb; }
/* 입력/편집 공용 */
.rc-write { padding:14px 16px; border-top:1px solid #e8edf4; background:#fbfcfe; }
.rc-writer { font-weight:700; color:#1f2937; font-size:13px; margin-bottom:8px; }
.rc-ta { width:100%; min-height:64px; border:1px solid #cbd5e1; border-radius:6px; padding:9px 11px; background:#fff; resize:vertical; font:inherit; line-height:1.5; }
.rc-bar { display:flex; align-items:center; justify-content:flex-end; gap:10px; margin-top:8px; }
.rc-counter { color:#98a2b3; font-size:12px; margin-right:auto; }
.rc-msg { color:#d04437; font-size:12px; margin:6px 16px 0; }
.rc-btn { border:1px solid #cbd5e1; background:#fff; color:#374151; border-radius:6px; padding:6px 16px; cursor:pointer; font-size:13px; }
.rc-btn.primary { border-color:#2f66b3; background:#2f66b3; color:#fff; }
.rc-btn:disabled { opacity:.5; cursor:default; }
.rc-edit { margin-top:8px; }
.rc-edit .rc-bar { margin-top:6px; }
</style>

<div class="rc-box" id="rcBox"
     data-base="<c:url value='${cmtUrlBase}'/>"
     data-bbsid="<c:out value='${searchVO.bbsId}'/>"
     data-nttid="<c:out value='${searchVO.nttId}'/>"
     data-max="1000">
  <div class="rc-head">
    <h3>댓글 <span class="rc-count" id="rcCount">0</span></h3>
    <div class="rc-sort">
      <button type="button" class="rc-sort-btn active" data-sort="reg">등록순</button>
      <button type="button" class="rc-sort-btn" data-sort="latest">최신순</button>
      <button type="button" class="rc-refresh" id="rcRefresh" title="새로고침">&#8635;</button>
    </div>
  </div>
  <p class="rc-msg" id="rcMsg" style="display:none;"></p>
  <div class="rc-list"><ul id="rcList"></ul></div>
  <div class="rc-write">
    <div class="rc-writer"><c:out value="${myName}"/></div>
    <textarea id="rcInput" class="rc-ta" maxlength="1000" placeholder="댓글을 남겨보세요"></textarea>
    <div class="rc-bar">
      <span class="rc-counter"><span id="rcCounterNum">0</span>/1000</span>
      <button type="button" class="rc-btn primary" id="rcSubmit">등록</button>
    </div>
  </div>
</div>

<script>
(function(){
  var box = document.getElementById('rcBox');
  if (!box || box.dataset.rcInit) return;
  box.dataset.rcInit = '1';

  var BASE  = box.getAttribute('data-base');
  var BBSID = box.getAttribute('data-bbsid');
  var NTTID = box.getAttribute('data-nttid');
  var MAX   = parseInt(box.getAttribute('data-max'), 10) || 1000;
  var LOGIN_URL = '<c:url value="/uat/uia/egovLoginUsr.do"/>';

  var listEl    = document.getElementById('rcList');
  var countEl   = document.getElementById('rcCount');
  var msgEl     = document.getElementById('rcMsg');
  var input     = document.getElementById('rcInput');
  var submitBtn = document.getElementById('rcSubmit');
  var counterN  = document.getElementById('rcCounterNum');
  var sort = 'reg';

  function showMsg(t){ if(!t){ msgEl.style.display='none'; return; } msgEl.textContent=t; msgEl.style.display='block'; }
  function form(obj){ var p=new URLSearchParams(); for(var k in obj) p.append(k, obj[k]); return p; }

  function post(url, obj){
    return fetch(url, {method:'POST', credentials:'same-origin',
        headers:{'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'},
        body: form(obj).toString()})
      .then(function(r){ return r.json(); })
      .then(function(d){ if(d && d.login){ location.href=LOGIN_URL; return {ok:false,handled:true}; } return d; });
  }

  // ── 렌더 ──────────────────────────────────────────────
  function render(data){
    listEl.innerHTML = '';
    countEl.textContent = data.count;
    if (!data.list || data.list.length === 0){
      var li = document.createElement('li');
      var e = document.createElement('p'); e.className='rc-empty'; e.textContent='등록된 댓글이 없습니다.';
      li.appendChild(e); listEl.appendChild(li); return;
    }
    data.list.forEach(function(c){ listEl.appendChild(row(c)); });
  }

  function row(c){
    var li = document.createElement('li');
    li.setAttribute('data-no', c.commentNo);

    var meta = document.createElement('div'); meta.className='rc-meta';
    var nm = document.createElement('strong'); nm.textContent = c.wrterNm || '';       // textContent = XSS 차단
    var sep = document.createElement('span'); sep.textContent='|';
    var dt = document.createElement('span'); dt.textContent = c.regDt || '';
    meta.appendChild(nm); meta.appendChild(sep); meta.appendChild(dt);

    var text = document.createElement('p'); text.className='rc-text'; text.textContent = c.content || '';

    li.appendChild(meta); li.appendChild(text);

    if (c.mine){
      li.appendChild(kebab(c));
    }
    return li;
  }

  function kebab(c){
    var wrap = document.createElement('div'); wrap.className='rc-kebab';
    var btn = document.createElement('button'); btn.type='button'; btn.className='rc-kebab-btn'; btn.innerHTML='&#8942;'; btn.title='더보기';
    var menu = document.createElement('div'); menu.className='rc-kebab-menu';
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
    var opened = listEl.querySelectorAll('.rc-kebab.open');
    for (var i=0;i<opened.length;i++){ if (opened[i]!==except) opened[i].classList.remove('open'); }
  }
  document.addEventListener('click', function(){ closeKebabs(null); });

  // ── 인라인 편집 ───────────────────────────────────────
  function beginEdit(c){
    var li = listEl.querySelector('li[data-no="'+c.commentNo+'"]');
    if (!li || li.querySelector('.rc-edit')) return;
    var text = li.querySelector('.rc-text');
    if (text) text.style.display='none';
    var kb = li.querySelector('.rc-kebab'); if (kb) kb.style.display='none';

    var box2 = document.createElement('div'); box2.className='rc-edit';
    var ta = document.createElement('textarea'); ta.className='rc-ta'; ta.maxLength=MAX; ta.value=c.content||'';
    var bar = document.createElement('div'); bar.className='rc-bar';
    var cnt = document.createElement('span'); cnt.className='rc-counter';
    var num = document.createElement('span'); num.textContent = (c.content||'').length;
    cnt.appendChild(num); cnt.appendChild(document.createTextNode('/'+MAX));
    var cancel = document.createElement('button'); cancel.type='button'; cancel.className='rc-btn'; cancel.textContent='취소';
    var save = document.createElement('button'); save.type='button'; save.className='rc-btn primary'; save.textContent='등록';
    bar.appendChild(cnt); bar.appendChild(cancel); bar.appendChild(save);
    box2.appendChild(ta); box2.appendChild(bar); li.appendChild(box2);
    ta.focus();
    ta.addEventListener('input', function(){ num.textContent = ta.value.length; });

    cancel.addEventListener('click', function(){ box2.remove(); if(text) text.style.display=''; if(kb) kb.style.display=''; });
    save.addEventListener('click', function(){
      var v = ta.value.trim();
      if (!v){ ta.focus(); return; }
      save.disabled = true;
      post(BASE+'/updateJson.do', {commentNo:c.commentNo, nttId:NTTID, bbsId:BBSID, commentCn:ta.value})
        .then(function(d){ if(d.handled) return; if(d && d.ok){ load(); } else { save.disabled=false; showMsg((d&&d.msg)||'수정 실패'); } })
        .catch(function(){ save.disabled=false; showMsg('수정 중 오류가 발생했습니다.'); });
    });
  }

  function doDelete(c){
    if (!confirm('댓글을 삭제하시겠습니까?')) return;
    post(BASE+'/deleteJson.do', {commentNo:c.commentNo, nttId:NTTID, bbsId:BBSID})
      .then(function(d){ if(d.handled) return; if(d && d.ok){ load(); } else { showMsg((d&&d.msg)||'삭제 실패'); } })
      .catch(function(){ showMsg('삭제 중 오류가 발생했습니다.'); });
  }

  // ── 등록 ──────────────────────────────────────────────
  input.addEventListener('input', function(){ counterN.textContent = input.value.length; });
  submitBtn.addEventListener('click', function(){
    var v = input.value.trim();
    if (!v){ input.focus(); return; }
    submitBtn.disabled = true;
    post(BASE+'/insertJson.do', {nttId:NTTID, bbsId:BBSID, commentCn:input.value})
      .then(function(d){ if(d.handled) return;
        submitBtn.disabled = false;
        if (d && d.ok){ input.value=''; counterN.textContent='0'; showMsg(''); load(); }
        else { showMsg((d&&d.msg)||'등록 실패'); }
      })
      .catch(function(){ submitBtn.disabled=false; showMsg('등록 중 오류가 발생했습니다.'); });
  });

  // ── 정렬/새로고침/로드 ────────────────────────────────
  var sortBtns = box.querySelectorAll('.rc-sort-btn');
  for (var i=0;i<sortBtns.length;i++){
    sortBtns[i].addEventListener('click', function(){
      sort = this.getAttribute('data-sort');
      for (var j=0;j<sortBtns.length;j++) sortBtns[j].classList.remove('active');
      this.classList.add('active');
      load();
    });
  }
  document.getElementById('rcRefresh').addEventListener('click', function(){ load(); });

  function load(){
    showMsg('');
    var url = BASE+'/listJson.do?bbsId='+encodeURIComponent(BBSID)+'&nttId='+encodeURIComponent(NTTID)+'&sort='+sort;
    fetch(url, {credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'}})
      .then(function(r){ return r.json(); })
      .then(function(d){ if(d && d.login){ location.href=LOGIN_URL; return; } if(d && d.ok){ render(d); } })
      .catch(function(){ showMsg('댓글을 불러오지 못했습니다.'); });
  }

  load();
})();
</script>
</c:if>
