/*!
 * rlms-search-fold.js — 모바일(≤900px) 검색영역 접기/펼치기 (LexPortal 전 화면 공용, 2026-08-06)
 *
 *   폰에서 목록 화면을 열면 검색영역이 첫 화면을 통째로 차지해 정작 결과 목록이 접힘 아래로
 *   밀려나 있었다. RegNex 사용자화면(rlms-cate-search-tree.js 의 buildFoldBar)과 같은 방식으로
 *   검색영역 위에 [검색조건 ▾] 바를 만들고 기본 접힘(=결과 우선), 바를 누르면 펼친다.
 *   데스크톱(>900px)은 바가 숨겨지고 접힘도 적용되지 않는다 — 원형 불변.
 *
 *   ★LexPortal 은 관리자·송무 전 화면이 대상이라 검색 마크업이 3종 혼재한다.
 *     ① KRDS       : .search-form > .form-group.inline > (.form-label | .form-conts | 버튼)
 *     ② 송무 그리드  : .search-form > .law-search-grid > div... + .law-search-btns
 *     ③ 옛 eGov     : .search_box > ul > li  (라벨 텍스트·입력·버튼이 li 안에 혼재)
 *
 *   ⛔그래서 "패널 통째 숨김"이 아니라 조건 셀만 골라 숨긴다 — 검색영역 안에 [등록]/[삭제]나
 *     탭(접속통계 일별/월별…)이 같이 들어있는 화면이 많아(사용자관리·권한관리·회원관리·배너·
 *     변호사관리·통계) 통째로 접으면 그 동선이 모바일에서 사라진다. 접힘 중에도 비검색 버튼은
 *     남기고, 조건 말고 남는 게 하나도 없는 화면(송무 목록·로그 등)만 패널을 통째로 숨긴다.
 *
 *   ⛔숨김은 클래스가 아니라 인라인 display:none !important 로 한다 — rlms-compat.css 가
 *     검색폼의 display 를 !important 로 박아둔 지점이 여러 겹(5450행대 한줄강제·6094행대 송무
 *     그리드·6280행대 ≤768 해제)이라 클래스 특이성 싸움의 승패가 화면마다 달라진다.
 *     데스크톱 복귀 시엔 빌드 시점에 기억해 둔 원래 인라인 값으로 정확히 되돌린다(matchMedia 감시).
 *
 *   ⛔바는 <button> 이 아니라 div[role=button] — 옛 eGov JSP 가 form.elements 를 인덱스로 훑는
 *     경우가 있어 폼 안에 폼요소를 늘리지 않는다(검색영역이 <form> 내부인 화면이 다수).
 */
(function () {
	'use strict';

	var MQ = '(max-width: 900px)';                 // RegNex 접이식 검색영역과 같은 경계
	var PANEL_SEL = '.search-form, .search_box';
	var SKIP_SEL = '[data-nofold], [role="dialog"], dialog, [class*="modal"], [class*="Modal"], [id*="modal"], [id*="Modal"]';
	var FIELD_SEL = 'input:not([type="hidden"]):not([type="submit"]):not([type="button"]):not([type="reset"]), select, textarea';
	var BTN_SEL = 'button, input[type="submit"], input[type="button"], input[type="reset"], a';
	// 검색계 버튼(조건과 함께 접는다). '전체'=기간필터 해제(송무 통계) 처럼 조건 초기화 계열도 포함.
	var SEARCH_TXT = /^(검색|조회|재조회|초기화|초기화하기|재설정|전체|전체보기|다시\s*검색|search|reset)$/i;
	var ICON = '<svg class="rlms-schf-ico" viewBox="0 0 20 20" aria-hidden="true" focusable="false">' +
		'<circle cx="9" cy="9" r="5.2" fill="none" stroke="currentColor" stroke-width="1.8"/>' +
		'<path d="M13.2 13.2L17 17" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>';

	var mq = window.matchMedia ? window.matchMedia(MQ) : null;
	var folds = [];

	function each(list, fn) { Array.prototype.forEach.call(list || [], fn); }
	function some(list, fn) { return Array.prototype.some.call(list || [], fn); }

	function label(el) {
		var s = (el.tagName === 'INPUT') ? (el.value || '') : (el.textContent || '');
		return s.replace(/\s+/g, ' ').trim();
	}

	// 조건 입력(라벨 포함)인가 — 자기 자신이 입력이거나 입력을 품고 있으면 조건 셀.
	function isField(el) {
		return el.matches(FIELD_SEL) || !!el.querySelector(FIELD_SEL);
	}
	function isLabel(el) {
		return el.tagName === 'LABEL' || el.classList.contains('form-label');
	}
	function buttonsIn(el) {
		var list = el.matches(BTN_SEL) ? [el] : [];
		return list.concat(Array.prototype.slice.call(el.querySelectorAll(BTN_SEL)));
	}
	// 버튼만 들어있고 그 전부가 검색계(검색/조회/초기화)인 셀 — 조건과 함께 접는다.
	function isSearchOnly(el) {
		var btns = buttonsIn(el);
		return btns.length > 0 && btns.every(function (b) { return SEARCH_TXT.test(label(b)); });
	}

	// li 안의 맨몸 텍스트("발생일자 : ")는 요소가 아니라 CSS/인라인으로 못 숨긴다 → span 으로 감싼다.
	function wrapTextNodes(li) {
		each(Array.prototype.slice.call(li.childNodes), function (n) {
			if (n.nodeType !== 3 || !n.nodeValue || !n.nodeValue.trim()) { return; }
			var sp = document.createElement('span');
			sp.className = 'rlms-schf-txt';
			li.replaceChild(sp, n);
			sp.appendChild(n);
		});
	}

	// 접을 대상(조건 셀·검색버튼) 수집. 구조 3종 + 폴백.
	function collectTargets(panel) {
		var targets = [];
		function take(cell) {
			if (cell.matches('input[type="hidden"], script, style, template, link, meta')) { return; }
			if (isField(cell) || isLabel(cell) || isSearchOnly(cell)) { targets.push(cell); return; }
			var btns = buttonsIn(cell);
			// 입력도 버튼도 없는 셀 = 라벨·구분 텍스트. 옛 eGov 은 <div>부서 : </div> 처럼 label 이 아닌
			// 태그로 두는 곳이 있어(부서권한관리) 태그 대신 "내용물"로 판정한다.
			if (!btns.length) { targets.push(cell); return; }
			// 액션 셀(등록·삭제·탭 등) — 그 안의 검색계 버튼만 골라 접는다(나머지는 접힘 중에도 노출).
			each(btns, function (b) { if (SEARCH_TXT.test(label(b))) { targets.push(b); } });
		}

		// ①KRDS 행 · ②송무 검색 그리드
		each(panel.querySelectorAll('.form-group, .law-search-grid'), function (row) {
			each(row.children, take);
		});

		// ③옛 eGov 검색바 — li 안이 라벨텍스트+입력+버튼 혼재라 요소 단위로 본다.
		if (panel.classList.contains('search_box')) {
			each(panel.querySelectorAll('ul > li'), function (li) {
				wrapTextNodes(li);
				each(li.children, function (el) {
					if (el.classList.contains('rlms-schf-txt')) { targets.push(el); return; }
					take(el);
				});
			});
		}

		// ④행 밖 직계 자식(탭·행 없이 놓인 셀렉트 등) — 위에서 이미 잡은 것과 겹치면 건너뛴다.
		//   ⛔겹침 검사 없이 훑으면 legacy 의 <ul> 통째가 대상이 돼 안에 있는 [등록] 까지 접힌다.
		each(panel.children, function (c) {
			if (some(targets, function (t) { return t === c || c.contains(t) || t.contains(c); })) { return; }
			take(c);
		});

		return targets;
	}

	// 자식이 전부 접힘 대상이면 부모(행·li)를 대신 접는다 — 빈 껍데기 행이 남아 높이만 먹는 것 방지.
	// (옛 eGov 검색바는 li 가 inline-flex·line-height 40px 이라 내용만 숨기면 빈 줄이 그대로 남는다.)
	function foldEmptyParents(panel, targets) {
		var changed = true;
		while (changed) {
			changed = false;
			var parents = [];
			each(targets, function (t) {
				var p = t.parentElement;
				if (p && p !== panel && panel.contains(p) && parents.indexOf(p) === -1) { parents.push(p); }
			});
			for (var i = 0; i < parents.length; i++) {
				var kids = Array.prototype.slice.call(parents[i].children);
				if (!kids.length || !kids.every(function (k) { return targets.indexOf(k) !== -1; })) { continue; }
				targets = targets.filter(function (t) { return kids.indexOf(t) === -1; });
				targets.push(parents[i]);
				changed = true;
				break;                                   // 목록이 바뀌었으니 부모 목록부터 다시
			}
		}
		return targets;
	}

	// 접었을 때 패널에 남는 게 있는가(등록·삭제 버튼, 탭 등) — 없으면 패널을 통째로 접는다.
	function remains(panel, targets) {
		var all = panel.querySelectorAll('button, input:not([type="hidden"]), select, textarea, a');
		return some(all, function (el) {
			return !some(targets, function (t) { return t === el || t.contains(el); });
		});
	}

	// 바에 적을 현재 검색조건 요약 — 값이 들어있는 항목만(사용자 입력이므로 textContent 로만 넣는다).
	function summarize(panel) {
		var out = [];
		each(panel.querySelectorAll('input, select, textarea'), function (el) {
			if (el.disabled || el.type === 'hidden' || el.type === 'password' ||
				el.type === 'submit' || el.type === 'button' || el.type === 'reset') { return; }
			var v = '';
			if (el.type === 'checkbox' || el.type === 'radio') {
				if (el.checked) {
					var lb = el.id ? document.querySelector('label[for="' + el.id + '"]') : null;
					v = lb ? label(lb) : '';
				}
			} else if (el.tagName === 'SELECT') {
				// 첫 옵션(전체)은 조건이 아니다 — selectedIndex 0 이거나 빈 값이면 제외.
				// ⛔'검색조건(아이디/이름)' 처럼 전체 옵션이 없는 셀렉트는 필터가 아니라 검색 '모드' 라
				//   요약에 넣으면 조건이 걸린 것처럼 보인다 → 첫 옵션이 전체(빈 값/'전체')인 것만 센다.
				var first = el.options[0];
				var isFilter = first && (first.value === '' || /^(전체|전체보기|all)$/i.test(label(first)));
				if (isFilter && el.selectedIndex > 0 && el.value !== '' && el.options[el.selectedIndex]) {
					v = label(el.options[el.selectedIndex]);
				}
			} else {
				v = el.value || '';
			}
			v = (v || '').replace(/\s+/g, ' ').trim();
			if (!v || out.indexOf(v) !== -1) { return; }
			out.push(v.length > 16 ? v.slice(0, 16) + '…' : v);
		});
		return out.slice(0, 4).join(' · ');
	}

	function storeKey(idx) { return 'rlmsSchFold:' + location.pathname + ':' + idx; }
	function loadState(idx) {
		try { return sessionStorage.getItem(storeKey(idx)) !== '0'; } catch (e) { return true; }   // 기본=접힘
	}
	function saveState(idx, folded) {
		try { sessionStorage.setItem(storeKey(idx), folded ? '1' : '0'); } catch (e) {}
	}

	function render(f) {
		var hide = (!mq || mq.matches) && f.folded;
		each(f.targets, function (el) {
			if (hide) {
				el.style.setProperty('display', 'none', 'important');
			} else if (el.rlmsSchfDisp) {
				el.style.setProperty('display', el.rlmsSchfDisp, el.rlmsSchfPri);   // 페이지가 원래 갖고 있던 인라인 값 복원
			} else {
				el.style.removeProperty('display');
			}
		});
		f.bar.setAttribute('aria-expanded', f.folded ? 'false' : 'true');
		f.bar.classList.toggle('is-open', !f.folded);
	}

	function build(panel, idx) {
		var targets = foldEmptyParents(panel, collectTargets(panel));
		if (!targets.length) { return; }
		// 실제 입력이 하나도 없는 폼(페이징 전용 폼 등)은 접을 게 없다.
		if (!some(targets, function (t) { return t.matches(FIELD_SEL) || t.querySelector(FIELD_SEL); })) { return; }
		if (!remains(panel, targets)) { targets = [panel]; }

		each(targets, function (el) {
			el.rlmsSchfDisp = el.style.getPropertyValue('display');
			el.rlmsSchfPri = el.style.getPropertyPriority('display');
		});

		if (!panel.id) { panel.id = 'rlmsSchPanel' + (idx + 1); }
		var bar = document.createElement('div');
		bar.className = 'rlms-schf-bar';
		bar.setAttribute('role', 'button');
		bar.setAttribute('tabindex', '0');
		bar.setAttribute('aria-controls', panel.id);
		bar.innerHTML = ICON + '<span class="rlms-schf-tit">검색조건</span>' +
			'<span class="rlms-schf-sum"></span><span class="rlms-schf-arr" aria-hidden="true"></span>';
		bar.querySelector('.rlms-schf-sum').textContent = summarize(panel);
		panel.parentNode.insertBefore(bar, panel);

		var f = { panel: panel, bar: bar, targets: targets, folded: loadState(idx) };
		folds.push(f);

		function toggle() {
			f.folded = !f.folded;
			saveState(idx, f.folded);
			render(f);
		}
		bar.addEventListener('click', toggle);
		bar.addEventListener('keydown', function (e) {
			if (e.key === 'Enter' || e.key === ' ' || e.key === 'Spacebar') { e.preventDefault(); toggle(); }
		});
		render(f);
	}

	function init() {
		var panels = [];
		each(document.querySelectorAll(PANEL_SEL), function (p) {
			if (p.closest(SKIP_SEL)) { return; }                                       // 모달·다이얼로그 안은 제외
			if (some(panels, function (q) { return q.contains(p); })) { return; }       // 중첩 패널 중복 방지
			panels.push(p);
		});
		panels.forEach(build);

		// 경계(900px)를 넘나들 때 인라인 숨김을 걷어내거나 다시 씌운다 — 창 크기 조절·기기 회전 대응.
		// matchMedia 와 resize 를 함께 듣는다(브라우저/에뮬레이션에 따라 한쪽만 오는 경우가 있음).
		var onChange = function () { folds.forEach(render); };
		if (mq) {
			if (mq.addEventListener) { mq.addEventListener('change', onChange); }
			else if (mq.addListener) { mq.addListener(onChange); }
		}
		window.addEventListener('resize', onChange);          // 대상 몇 개의 style 조작뿐이라 스로틀 불요
		window.addEventListener('orientationchange', onChange);
		// DOMContentLoaded 시점의 폭이 최종 폭이 아닐 수 있는 환경(iframe·늦게 적용되는 레이아웃) 보정.
		window.addEventListener('load', onChange);
	}

	if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', init); }
	else { init(); }
})();
