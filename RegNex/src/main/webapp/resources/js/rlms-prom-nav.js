/*!
 * rlms-prom-nav.js — 좌측 규정분류 펼침 드로어 (전역 네비게이션)
 *
 * 전문뷰어(provisionList.do)의 좌측 트리(구분>분류>규정명 leaf → 본문)를
 * 모든 사용자 페이지에서 쓸 수 있도록 자체완결 접이식 드로어로 추출한 컴포넌트.
 * 규정명 leaf 클릭 → /rlms/fulltext/provisionList.do?promNo=NN (본문 바로열기).
 *
 * 데이터원(재사용, 신규 API 0):
 *   전문분류  = /rlms/prom/treeJson.do      (id=# 기본 → 구분>분류>규정 한방)
 *   부서별    = /rlms/prom/treeJsonDept.do  (소관부서 그룹 → 규정. 2026-07-31 추가, 전문뷰어와 동일 3탭)
 *   기능별분류 = /rlms/prommap/treeJson.do   (TB_PROM_MAP)
 * 노드구조(jsTree식): { text, type:'gubun'|'cate', data:{promNo, promYn}, children:[...] }
 *   leaf 판정 = data.promNo != null && data.promYn !== 'N'  (prommap 폴더 promNo=0/promYn=N 방지)
 *   부서별 트리는 type 이 없어 폴더가 pn-cate 로 렌더된다(구분 색 강조만 빠짐 — 의도).
 *
 * 사용:
 *   RlmsPromNav.init({
 *     ctx:'', jeonUrl:'/rlms/prom/treeJson.do', deptUrl:'/rlms/prom/treeJsonDept.do',
 *     funcUrl:'/rlms/prommap/treeJson.do', viewerUrl:'/rlms/fulltext/provisionList.do'
 *   });
 *   전문뷰어처럼 페이지가 이미 자체 트리(#lvTree/.lawview-left)를 가지면 자동 스킵(중복 방지).
 *
 * 의존성: 없음(순수 JS). CSS/HTML 자체 주입.
 * © 2026 RLMS.
 */
(function (window, document) {
	'use strict';

	var CFG = null, drawerOpen = false, treeLoaded = false, curTab = 'jeon';
	var KEY_OPEN = 'rlmsPromNavOpen', KEY_TAB = 'rlmsPromNavTab';

	function esc(s) {
		return (s == null ? '' : String(s)).replace(/[&<>"]/g, function (c) {
			return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
		});
	}

	/* flat jsTree-style nodes(children 내장) → 중첩 UL. 폴더 기본 접힘. */
	function buildNodes(nodes) {
		var h = '';
		(nodes || []).forEach(function (nd) {
			var d = nd.data || {};
			if (d.promNo != null && d.promYn !== 'N') {           // 규정 leaf
				var pend = d.pending ? ' <span class="pn-badge" title="공포되었으나 아직 시행 전입니다">시행예정</span>' : '';
				h += '<li class="pn-prom"><a href="' + CFG.viewerUrl + '?promNo=' + d.promNo + '">' + esc(nd.text) + pend + '</a></li>';
			} else {                                              // 구분/분류 폴더
				var cls = (nd.type === 'gubun') ? 'pn-gubun' : 'pn-cate';
				var kids = (nd.children && nd.children.length) ? ('<ul class="pn-ch">' + buildNodes(nd.children) + '</ul>') : '';
				h += '<li class="' + cls + '"><div class="pn-row" onclick="RlmsPromNav._tog(this)">' +
					'<span class="pn-tog">' + (kids ? '+' : '·') + '</span>' +
					'<span class="pn-label">' + esc(nd.text) + '</span></div>' + kids + '</li>';
			}
		});
		return h;
	}

	function togRow(rowEl) {
		var li = rowEl.parentNode;
		var ch = li.querySelector(':scope > ul.pn-ch');
		if (!ch) { return; }
		var open = ch.classList.toggle('open');
		var tog = rowEl.querySelector('.pn-tog');
		if (tog) { tog.innerHTML = open ? '−' : '+'; }
	}

	function loadTree(url) {
		var box = document.getElementById('pnTree');
		box.innerHTML = '<li class="pn-msg">불러오는 중…</li>';
		fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
			.then(function (r) { return r.json(); })
			.then(function (j) {
				box.innerHTML = buildNodes(j) || '<li class="pn-msg">목록 없음</li>';
			})
			.catch(function (e) {
				console.error('RlmsPromNav', e);   // 진단은 콘솔로만 — 예외 원문을 화면에 노출하지 않음(2026-07-16)
				box.innerHTML = '<li class="pn-err">규정분류 목록을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.</li>';
			});
	}

	/** 탭 → 트리 URL. 모르는 값이면 전문분류로 폴백. */
	function tabUrl(t) {
		if (t === 'func') { return CFG.funcUrl; }
		if (t === 'dept') { return CFG.deptUrl; }
		return CFG.jeonUrl;
	}

	function tab(t) {
		curTab = t;
		try { sessionStorage.setItem(KEY_TAB, t); } catch (_) {}
		Array.prototype.forEach.call(document.querySelectorAll('.pn-tab'), function (x) {
			x.classList.toggle('on', x.getAttribute('data-tab') === t);
		});
		var q = document.getElementById('pnQuick'); if (q) { q.value = ''; }
		loadTree(tabUrl(t));
	}

	/* QUICK 규정명검색 — 매칭 leaf + 조상 폴더만 펼쳐 표시, 비우면 기본(접힘) 복원 */
	function filter(q) {
		q = (q || '').trim();
		var tree = document.getElementById('pnTree');
		var lis = tree.querySelectorAll('li');
		var i;
		if (!q) {
			for (i = 0; i < lis.length; i++) { lis[i].style.display = ''; }
			Array.prototype.forEach.call(tree.querySelectorAll('ul.pn-ch.open'), function (ch) {
				ch.classList.remove('open');
				var tog = ch.parentNode.querySelector(':scope > .pn-row .pn-tog');
				if (tog && tog.innerHTML !== '·') { tog.innerHTML = '+'; }
			});
			return;
		}
		for (i = 0; i < lis.length; i++) { lis[i].style.display = 'none'; }
		Array.prototype.forEach.call(tree.querySelectorAll('li.pn-prom'), function (li) {
			var a = li.querySelector('a');
			if (a && a.textContent.indexOf(q) >= 0) {
				li.style.display = '';
				var p = li.parentNode;
				while (p && p !== tree) {
					if (p.tagName === 'LI') { p.style.display = ''; }
					if (p.classList && p.classList.contains('pn-ch')) {
						p.classList.add('open');
						var tog = p.parentNode.querySelector(':scope > .pn-row .pn-tog');
						if (tog) { tog.innerHTML = '−'; }
					}
					p = p.parentNode;
				}
			}
		});
	}

	function setOpen(open) {
		drawerOpen = open;
		document.getElementById('pnDrawer').classList.toggle('open', open);
		document.getElementById('pnBackdrop').classList.toggle('on', open);
		document.getElementById('pnHandle').classList.toggle('hidden', open);
		try { sessionStorage.setItem(KEY_OPEN, open ? '1' : '0'); } catch (_) {}
		if (open && !treeLoaded) {
			treeLoaded = true;
			loadTree(tabUrl(curTab));
		}
	}

	function injectCSS() {
		if (document.getElementById('pn-style')) { return; }
		var css =
			'#pnHandle{position:fixed;left:0;top:42%;z-index:1190;background:#1f3974;color:#fff;border:0;' +
			'padding:18px 13px;border-radius:0 8px 8px 0;cursor:pointer;writing-mode:vertical-rl;text-orientation:upright;' +
			'font-size:14px;letter-spacing:2px;font-weight:700;box-shadow:2px 1px 8px rgba(0,0,0,.22);line-height:1.1;}' +
			'#pnHandle:hover{background:#16306a;}#pnHandle.hidden{display:none;}' +
			'#pnBackdrop{position:fixed;inset:0;background:rgba(0,0,0,.18);z-index:1199;opacity:0;visibility:hidden;transition:opacity .2s;}' +
			'#pnBackdrop.on{opacity:1;visibility:visible;}' +
			/* 높이=top/bottom 고정 — 100vh 는 글자크기 zoom 래퍼 안에서 과대/과소 렌더(vh 금지, LexPortal 8/4 동일) */
			'#pnDrawer{position:fixed;left:0;top:0;bottom:0;width:320px;max-width:calc(86vw / var(--rlms-zoom, 1));z-index:1200;background:#fff;' +
			'box-shadow:3px 0 14px rgba(0,0,0,.22);display:flex;flex-direction:column;transform:translateX(-100%);transition:transform .22s ease;}' +
			'#pnDrawer.open{transform:translateX(0);}' +
			'#pnDrawer .pn-head{display:flex;align-items:center;gap:8px;padding:12px 14px;background:#1f3974;color:#fff;flex:0 0 auto;}' +
			'#pnDrawer .pn-head h3{margin:0;font-size:15px;font-weight:700;flex:1;}' +
			'#pnDrawer .pn-x{background:transparent;border:0;color:#fff;font-size:22px;line-height:1;cursor:pointer;padding:0 4px;}' +
			'#pnDrawer .pn-quickwrap{padding:10px 12px 6px;flex:0 0 auto;}' +
			'#pnDrawer #pnQuick{width:100%;box-sizing:border-box;height:34px;padding:0 10px;border:1px solid #c7ccd6;border-radius:5px;font-size:13px;}' +
			'#pnDrawer .pn-tabs{display:flex;gap:0;padding:0 12px;flex:0 0 auto;border-bottom:1px solid #e3e6ec;}' +
			'#pnDrawer .pn-tab{flex:1;text-align:center;padding:8px 4px;cursor:pointer;font-size:13px;color:#5a6172;border-bottom:2px solid transparent;margin-bottom:-1px;}' +
			'#pnDrawer .pn-tab.on{color:#1f3974;font-weight:700;border-bottom-color:#1f3974;}' +
			'#pnTreeWrap{flex:1 1 auto;overflow:auto;padding:8px 6px 16px;}' +
			'#pnTree,#pnTree ul{list-style:none;margin:0;padding:0;}' +
			'#pnTree ul.pn-ch{padding-left:14px;display:none;}#pnTree ul.pn-ch.open{display:block;}' +
			/* 행 전체가 토글 클릭 영역 — +/− 아이콘(사용자 확정) + 행 높이 확보 (2026-07-09) */
			'#pnTree .pn-row{display:flex;align-items:center;gap:6px;padding:6px 8px;border-radius:6px;cursor:pointer;min-height:32px;}' +
			'#pnTree .pn-row:hover{background:#eef3fb;}' +
			'#pnTree .pn-tog{width:22px;flex:0 0 22px;text-align:center;color:#4b5563;font-size:16px;font-weight:700;line-height:1;}' +
			'#pnTree .pn-label{font-size:14px;color:#26303f;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}' +
			'#pnTree .pn-gubun > .pn-row .pn-label{color:#1f3974;}' +
			'#pnTree li.pn-prom{padding:2px 6px 2px 28px;}' +
			'#pnTree li.pn-prom a{display:block;font-size:13px;color:#33405a;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding:2px 4px;border-radius:4px;}' +
			'#pnTree li.pn-prom a:hover{background:#e8edf9;color:#16306a;}' +
			/* 시행예정 뱃지(A안) — 뷰어 .lvh-tag 와 동일 amber pill 톤 */
			'#pnTree .pn-badge{display:inline-block;margin-left:4px;padding:1px 6px;border-radius:9px;background:#fff4e5;color:#9a5b00;font-size:11px;font-weight:700;vertical-align:1px;}' +
			'#pnTree .pn-msg{padding:10px 12px;color:#99a;font-size:13px;}#pnTree .pn-err{padding:10px 12px;color:#b00;font-size:13px;}' +
			/* ≤768 반응형 — 세로 책갈피 핸들이 좁은 화면에서 본문을 가리므로 하단 알약 FAB 로 전환
			   (rlms-compat.css ≤768 이 .rlms-front-main 좌 예약 폭을 해제하고 하단 여백 72px 를 확보) */
			'@media (max-width:768px){#pnHandle{top:auto;bottom:16px;writing-mode:horizontal-tb;text-orientation:mixed;' +
			'letter-spacing:0;padding:11px 16px;border-radius:0 22px 22px 0;font-size:13px;}}' +
			'@media print{#pnHandle,#pnDrawer,#pnBackdrop{display:none!important;}}';
		var st = document.createElement('style');
		st.id = 'pn-style';
		st.textContent = css;
		document.head.appendChild(st);
	}

	function injectHTML() {
		if (document.getElementById('pnDrawer')) { return; }
		var handle = document.createElement('button');
		handle.id = 'pnHandle';
		handle.type = 'button';
		handle.title = '규정 분류 — 분류를 펼쳐 규정 본문 바로열기';
		handle.innerHTML = '규정분류';
		handle.onclick = function () { setOpen(true); };

		var backdrop = document.createElement('div');
		backdrop.id = 'pnBackdrop';
		backdrop.onclick = function () { setOpen(false); };

		var drawer = document.createElement('aside');
		drawer.id = 'pnDrawer';
		drawer.innerHTML =
			'<div class="pn-head"><h3>규정 분류</h3>' +
			'<button type="button" class="pn-x" title="닫기" onclick="RlmsPromNav._close()">×</button></div>' +
			'<div class="pn-quickwrap"><input id="pnQuick" type="text" placeholder="규정명 빠른검색" ' +
			'oninput="RlmsPromNav._filter(this.value)" autocomplete="off"></div>' +
			/* 탭 순서·명칭은 전문뷰어 좌측 트리와 동일하게 맞춘다(전문분류/부서별/기능별분류) */
			'<div class="pn-tabs">' +
			'<div class="pn-tab on" data-tab="jeon" onclick="RlmsPromNav._tab(\'jeon\')">전문분류</div>' +
			'<div class="pn-tab" data-tab="dept" onclick="RlmsPromNav._tab(\'dept\')">부서별</div>' +
			'<div class="pn-tab" data-tab="func" onclick="RlmsPromNav._tab(\'func\')">기능별분류</div></div>' +
			'<div id="pnTreeWrap"><ul id="pnTree"><li class="pn-msg">규정분류를 여는 중…</li></ul></div>';

		document.body.appendChild(handle);
		document.body.appendChild(backdrop);
		document.body.appendChild(drawer);

		document.addEventListener('keydown', function (e) {
			if (e.key === 'Escape' && drawerOpen) { setOpen(false); }
		});
	}

	function init(cfg) {
		// 전문뷰어 등 이미 자체 좌측 트리가 있는 페이지는 중복 주입 안 함
		if (document.querySelector('#lvTree, .lawview-left')) { return; }
		CFG = {
			ctx: (cfg && cfg.ctx) || '',
			jeonUrl: (cfg && cfg.jeonUrl) || '/rlms/prom/treeJson.do',
			deptUrl: (cfg && cfg.deptUrl) || '/rlms/prom/treeJsonDept.do',
			funcUrl: (cfg && cfg.funcUrl) || '/rlms/prommap/treeJson.do',
			viewerUrl: (cfg && cfg.viewerUrl) || '/rlms/fulltext/provisionList.do'
		};
		try {
			var t = sessionStorage.getItem(KEY_TAB);
			if (t === 'func' || t === 'dept' || t === 'jeon') { curTab = t; }
		} catch (_) {}
		injectCSS();
		injectHTML();
		/* 이전 세션에서 고른 탭 복원 — 탭이 늘어도 손대지 않게 data-tab 매칭으로 일반화(2026-07-31) */
		if (curTab !== 'jeon') {
			Array.prototype.forEach.call(document.querySelectorAll('.pn-tab'), function (x) {
				x.classList.toggle('on', x.getAttribute('data-tab') === curTab);
			});
		}
		var wasOpen = false;
		try { wasOpen = sessionStorage.getItem(KEY_OPEN) === '1'; } catch (_) {}
		if (wasOpen) { setOpen(true); }
	}

	window.RlmsPromNav = {
		init: init,
		_tog: togRow,
		_tab: tab,
		_filter: filter,
		_close: function () { setOpen(false); }
	};

})(window, document);
