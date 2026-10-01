/*!
 * rlms-cate-search-tree.js — 사용자 검색화면 좌측 "규정 분류" 트리 (공유 컴포넌트).
 *
 *   selectCateTreeJson.do 의 구분(SGUBUN)+분류(TB_CATE) 트리에 "전체" root 를 얹고,
 *   노드 클릭 시 해당 화면을 분류로 좁혀 재검색한다.
 *     · 전체   → 필터 해제 (무파라미터 = 전체)
 *     · 구분   → 그 구분 필터 (gubunIds=SGUBUN_ID 코드 그대로 — 신설 구분도 동작, 2026-07-10 동적화)
 *     · 분류   → cateNo 필터 (+부모 구분 gubunIds 동기화)
 *
 * 홈(userHome) + fulltext 검색 5종(연혁/신구대조/조별대조/폐지/최근) 공용.
 *
 * 사용:
 *   RlmsCateSearchTree.init({
 *     containerId: 'cateSearchTree',                       // 필수
 *     jsonUrl:     '/rlms/cate/selectCateTreeJson.do',     // 필수
 *     searchUrl:   '/rlms/fulltext/historyList.do'         // 필수 — 클릭 시 이동할 그 화면
 *   });
 *
 * 의존: jQuery, jstree.
 */
(function (global, $) {
	'use strict';

	var ALL_ID = 'rlms_all_root';

	// 레이아웃 CSS 1회 주입(페이지마다 중복 정의 없이 공유)
	(function injectStyle() {
		if (document.getElementById('rlms-cate-search-tree-style')) { return; }
		var css =
			'.rlms-search-layout{display:grid;grid-template-columns:230px 1fr;gap:18px;align-items:start;margin-top:6px;}' +
			'.rlms-search-tree-aside{background:#fff;border:1px solid #d1d3d8;border-radius:10px;padding:14px;}' +
			'.rlms-search-tree-head{font-weight:600;color:#1f3974;margin-bottom:8px;font-size:14px;}' +
			'.rlms-search-tree{font-size:13px;max-height:640px;overflow:auto;}' +
			'.rlms-search-body{min-width:0;}' +
			/* ≤900 접이식 검색영역(2026-08-04 사용자) — 1열 전환 구간에선 트리+검색폼이 목록 위를
			   차지하므로 기본 접힘, [검색조건·분류] 바 클릭으로 펼침. 바는 buildFoldBar 가
			   form.search-form 있는 화면(연혁검색 계열)에만 생성 — searchAll(us-console)은 미대상. */
			'.rlms-sch-fold{display:none;width:100%;margin:6px 0 10px;padding:10px 14px;border:1px solid #d6deea;' +
			'border-radius:6px;background:#f3f6fb;color:#1f3974;font-size:14px;font-weight:600;cursor:pointer;' +
			'text-align:left;box-sizing:border-box;justify-content:space-between;align-items:center;}' +
			'@media(max-width:900px){.rlms-search-layout{grid-template-columns:1fr;}' +
			'.rlms-sch-fold{display:flex;}' +
			'.rlms-search-layout.rlms-sch-folded .rlms-search-tree-aside{display:none;}' +
			'.rlms-search-layout.rlms-sch-folded .rlms-search-body form.search-form{display:none;}}' +
			'@media print{.rlms-sch-fold{display:none!important;}}';
		var st = document.createElement('style');
		st.id = 'rlms-cate-search-tree-style';
		st.appendChild(document.createTextNode(css));
		(document.head || document.documentElement).appendChild(st);
	})();

	// ≤900 접이식 검색영역 바 — 트리+검색폼(form.search-form)을 접었다 편다.
	// 데스크톱(>900)에선 CSS 가 바를 숨기고 접힘 클래스도 무효라 원형 유지.
	function buildFoldBar() {
		if (document.getElementById('rlmsSchFold')) { return; }
		var layout = document.querySelector('.rlms-search-layout');
		var form = layout ? layout.querySelector('.rlms-search-body form.search-form') : null;
		if (!layout || !form) { return; }
		layout.classList.add('rlms-sch-folded');   // 기본 접힘 — 목록(결과) 우선
		var bar = document.createElement('button');
		bar.type = 'button';
		bar.id = 'rlmsSchFold';
		bar.className = 'rlms-sch-fold';
		bar.setAttribute('aria-expanded', 'false');
		bar.innerHTML = '<span>검색조건·분류</span><span class="rlms-sch-fold-arr" aria-hidden="true">▾</span>';
		bar.addEventListener('click', function () {
			var folded = layout.classList.toggle('rlms-sch-folded');
			bar.setAttribute('aria-expanded', folded ? 'false' : 'true');
			var ar = bar.querySelector('.rlms-sch-fold-arr');
			if (ar) { ar.textContent = folded ? '▾' : '▴'; }
		});
		layout.parentNode.insertBefore(bar, layout);
	}

	// 노드 클릭 이동 시 현재 검색 상태 유지 — 키워드(입력 중 값 우선)와 통합검색 탭을 함께 실어 보낸다.
	// (없으면 트리 클릭마다 키워드가 사라짐 — 2026-07-07 사용자 지적. pageIndex 는 의도적으로 미유지=1페이지부터.)
	function carryQs() {
		var parts = [];
		try {
			var kw = document.getElementById('searchKeyword');
			var v = kw && kw.value ? kw.value.trim() : '';
			if (!v) {
				var m = location.search.match(/[?&]searchKeyword=([^&]*)/);
				if (m) { v = decodeURIComponent(m[1].replace(/\+/g, ' ')); }
			}
			if (v) { parts.push('searchKeyword=' + encodeURIComponent(v)); }
			var tab = document.querySelector('#searchForm input[name=tab]');   // 통합검색 전용 — 타 화면엔 없음
			if (tab && tab.value) { parts.push('tab=' + encodeURIComponent(tab.value)); }
		} catch (e) {}
		return parts.length ? '&' + parts.join('&') : '';
	}

	// 펼침 상태 유지 — 노드 클릭 시 페이지가 재로드돼도 트리가 닫히지 않게 sessionStorage 에 저장/복원.
	var OPEN_KEY = 'rlmsCateTreeOpen';
	function savedOpenIds() {
		try { return JSON.parse(sessionStorage.getItem(OPEN_KEY) || '[]'); } catch (e) { return []; }
	}
	function persistOpen(inst) {
		try {
			var open = [];
			(inst.get_json('#', { flat: true }) || []).forEach(function (n) {
				if (n.state && n.state.opened) { open.push(n.id); }
			});
			sessionStorage.setItem(OPEN_KEY, JSON.stringify(open));
		} catch (e) {}
	}

	function init(opt) {
		if (!opt || !opt.containerId || !opt.jsonUrl || !opt.searchUrl) {
			if (global.console) console.error('[RlmsCateSearchTree] containerId/jsonUrl/searchUrl 필수');
			return;
		}
		var $box = $('#' + opt.containerId);
		if (!$box.length) { return; }
		buildFoldBar();
		$box.html('<p style="color:#888;font-size:13px;padding:8px;">분류 로딩...</p>');

		$.getJSON(opt.jsonUrl)
			.done(function (data) {
				var nodes = (data && data.resultList) ? data.resultList.slice() : [];
				// 기존 최상위(구분, parent '#') 노드를 "전체" 밑으로 재배치 + 전체 root 주입
				nodes.forEach(function (n) {
					if (n.parent === '#' || n.parent == null) { n.parent = ALL_ID; }
				});
				nodes.unshift({
					id: ALL_ID, parent: '#', text: '전체',
					state: { opened: true }, data: { all: true }
				});

				// 저장된 펼침 상태 복원 — 클릭 후 재로드돼도 펼친 트리 유지
				var openIds = savedOpenIds();
				if (openIds.length) {
					nodes.forEach(function (n) {
						if (openIds.indexOf(n.id) !== -1) { n.state = n.state || {}; n.state.opened = true; }
					});
				}

				var suppressNav = false;   // 프로그램적 선택표시(하이라이트) 중엔 이동 차단

				$box.empty().jstree({
					core: { data: nodes, themes: { responsive: false, dots: true, icons: true } }
				}).on('open_node.jstree close_node.jstree', function (_e, d) {
					persistOpen(d.instance);
				}).on('loaded.jstree', function (_e, d) {
					// 현재 활성 필터(URL cateNo/gubunIds)에 해당하는 노드를 "선택 표시" — 이동 없이.
					// 클릭 후/페이징 후 재로드돼도 지금 보고 있는 분류가 트리에 하이라이트로 남게.
					// gubunIds = SGUBUN_ID 코드 그대로(FT_GUBUN_ 재조립·[1-5] 컷 폐기, 2026-07-10 동적화).
					// 정확히 1건이면 그 구분 노드, 복수/전무(=필터 없음=전체)면 "전체" root.
					try {
						var inst = d.instance, qs = location.search, model = inst._model.data, targetId = null;
						var mCate = qs.match(/[?&]cateNo=(\d+)/);
						var gubunIds = [], gm, gre = /[?&]gubunIds=([^&]*)/g;
						while ((gm = gre.exec(qs)) !== null) {
							var gv = decodeURIComponent(gm[1].replace(/\+/g, ' ')).trim();
							if (gv) { gubunIds.push(gv); }
						}
						if (mCate) {
							Object.keys(model).forEach(function (id) { var n = model[id]; if (n && n.data && String(n.data.cateNo) === mCate[1]) { targetId = id; } });
						} else if (gubunIds.length === 1) {
							Object.keys(model).forEach(function (id) { var n = model[id]; if (n && n.data && n.data.gubunId === gubunIds[0]) { targetId = id; } });
						} else {
							targetId = ALL_ID;
						}
						if (targetId) {
							suppressNav = true;
							inst.deselect_all();
							inst.select_node(targetId);   // 조상 자동 펼침 + jstree-clicked 하이라이트
							suppressNav = false;
							var $li = inst.get_node(targetId, true);
							var a = $li && $li.length ? $li.children('.jstree-anchor')[0] : null;
							if (a && a.scrollIntoView) { a.scrollIntoView({ block: 'center' }); }
						}
					} catch (e) {}
				}).on('select_node.jstree', function (_e, sel) {
					if (suppressNav) { return; }   // 하이라이트용 선택 — 이동 안 함
					var d = sel.node && sel.node.data;
					if (!d) { return; }
					// 전체 → 필터 해제(무파라미터=전체 — SQL 은 gubunIds 비면 필터 미적용)
					if (d.all) {
						location.href = opt.searchUrl + '?pageIndex=1' + carryQs();
						return;
					}
					// 분류(cateNo) → cateNo 필터 + 부모 구분도 체크(검색폼 구분 체크박스 동기화 — 코드 그대로)
					// ★'_NULL_' = SGUBUN_ID 없는 분류의 합성 그룹(CateServiceImpl.normalizeGubunId) —
					//   실제 코드가 아니라 필터에 실으면 항상 0건이므로 gubunIds 로 보내지 않는다.
					if (d.cateNo) {
						var pgid = '';
						var parents = sel.node.parents || [];
						for (var i = 0; i < parents.length; i++) {
							var pn = sel.instance.get_node(parents[i]);
							var pg = pn && pn.data && pn.data.gubunId;
							if (pg && String(pg) !== '_NULL_') { pgid = String(pg); break; }
						}
						location.href = opt.searchUrl + '?cateNo=' + encodeURIComponent(d.cateNo) + (pgid ? '&gubunIds=' + encodeURIComponent(pgid) : '') + carryQs();
						return;
					}
					// 구분 → 그 구분만 체크 (코드 그대로 — 신설 FT_GUBUN_6+ 도 이동, 2026-07-10 동적화)
					if (d.gubunId && String(d.gubunId) !== '_NULL_') {
						location.href = opt.searchUrl + '?gubunIds=' + encodeURIComponent(String(d.gubunId)) + carryQs();
					}
				});
			})
			.fail(function () {
				$box.html('<p style="color:#b03030;font-size:13px;padding:8px;">분류 트리 로드 실패</p>');
			});
	}

	global.RlmsCateSearchTree = { init: init };

})(window, jQuery);
