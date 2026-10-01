/*!
 * rlms-table-stack.js — 모바일(≤768px) 상세 화면의 다열 표 → 카드 목록 (LexPortal 공용, 2026-08-06)
 *
 *   소송 상세처럼 5~8열짜리 표가 여러 개 붙는 화면은 폰 폭에서 열이 뭉개져(헤더 글자 겹침·값 잘림)
 *   읽을 수가 없다. 가로 스크롤 대신 행을 카드로 세우고 각 셀에 헤더 라벨을 붙인다.
 *
 *   ★JSP 를 건드리지 않는다 — thead 의 th 텍스트를 그대로 td 의 data-label 로 복사하고,
 *     실제 카드 배치는 rlms-compat.css 의 ≤768 규칙(td::before{content:attr(data-label)})이 담당한다.
 *     새 표가 생겨도 class="law-sub-table"(또는 data-stack) 만 붙이면 자동 적용.
 *
 *   ⛔colspan 이 섞인 행(빈 상태 '등록된 ~ 없습니다', 합계 행)은 라벨 대응이 무의미 →
 *     통짜 행(rlms-tsk-plain)으로 표시. 열 수가 헤더와 다른 행도 같은 취급(안전측).
 *   ⛔값이 없는 칸('-'/빈칸)은 숨긴다 — 카드에서 '장소 -' 같은 빈 줄이 쌓이면 오히려 읽기 나쁘다.
 *     단 버튼·링크·입력이 들어있는 칸은 텍스트가 없어도 남긴다(관리 열).
 */
(function () {
	'use strict';

	// law-sub-table = 상세 화면 읽기표, law-grid = 등록/수정 화면 편집표(입력이 든 행), data-stack = 임의 지정
	var SEL = 'table.law-sub-table, table.law-grid, table[data-stack]';

	function each(list, fn) { Array.prototype.forEach.call(list || [], fn); }

	function label(el) {
		return (el.textContent || '').replace(/\s+/g, ' ').trim();
	}

	function stack(table) {
		var ths = table.querySelectorAll('thead th');
		if (!ths.length) { return; }
		var labels = Array.prototype.map.call(ths, label);

		each(table.querySelectorAll('tbody tr'), function (tr) {
			if (tr.classList.contains('rlms-tsk-card') || tr.classList.contains('rlms-tsk-plain')) { return; }
			var tds = tr.children;
			var plain = tds.length !== labels.length;
			for (var i = 0; !plain && i < tds.length; i++) {
				if ((tds[i].getAttribute('colspan') || '1') !== '1') { plain = true; }
			}
			if (plain) { tr.classList.add('rlms-tsk-plain'); return; }

			for (var j = 0; j < tds.length; j++) {
				var td = tds[j];
				td.setAttribute('data-label', labels[j]);
				var txt = label(td);
				if ((!txt || txt === '-') && !td.querySelector('a, button, input, select, img')) {
					td.classList.add('rlms-tsk-empty');
				}
			}
			tr.classList.add('rlms-tsk-card');
		});

		table.classList.add('rlms-tsk');
	}

	function init() {
		each(document.querySelectorAll(SEL), function (t) {
			stack(t);
			watch(t);
		});
	}

	// ★편집표는 [행 추가]·검색결과 렌더로 행이 나중에 생긴다 — tbody 변화를 보고 새 행에도 라벨을 붙인다.
	//   (라벨이 없으면 그 행만 카드에서 라벨 없는 줄로 보인다)
	function watch(table) {
		if (table.rlmsTskWatched || !window.MutationObserver) { return; }
		var body = table.tBodies && table.tBodies[0];
		if (!body) { return; }
		table.rlmsTskWatched = true;
		new MutationObserver(function () { stack(table); }).observe(body, { childList: true });
	}

	// 필요 시 외부에서도 재적용 가능(동적 표 직접 렌더 등)
	window.rlmsTableStack = init;

	if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', init); }
	else { init(); }
})();
