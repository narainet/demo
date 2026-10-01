/*!
 * rlms-detail-search.js — "상세검색" 레이어팝업(인라인 모달) 컨트롤러 (공유).
 *
 * 검색 화면(연혁검색 등)에 들어있는 상세검색 모달 폼을 열고/닫고, 자음/영문 버튼을
 * 처리한다. 모달 폼은 호스트 페이지(historyList.do?detailMode=Y)로 제출 →
 * 호스트 컨트롤러가 상세검색 쿼리로 결과를 "원래 목록"에 렌더한다(폼=팝업, 결과=본문 목록).
 *
 * 페이지 마크업 약속:
 *   - 여는 버튼: id="rdsOpenBtn"
 *   - 백드롭:   id="rdsBackdrop"
 *   - 모달:     id="rdsModal" (안에 .rds-x 닫기버튼)
 *   - 모달 폼:  id="detailSearchForm" (hidden hangulPrefix/englishPrefix 보유)
 *   - 자음 버튼: [data-h], 영문 버튼: [data-e]
 *
 * 의존성: 없음(순수 JS). CSS 자체 주입.
 * © 2026 RLMS.
 */
(function (window, document) {
	'use strict';

	function injectCSS() {
		if (document.getElementById('rds-style')) { return; }
		var css =
			'#rdsOpenBtn{display:inline-flex;align-items:center;gap:5px;height:36px;padding:0 14px;border:1px solid #1f3974;' +
			'background:#1f3974;color:#fff;border-radius:6px;font-size:14px;font-weight:600;cursor:pointer;text-decoration:none;}' +
			'#rdsOpenBtn:hover{background:#16306a;}' +
			'#rdsBackdrop{position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:1300;display:none;}' +
			'#rdsBackdrop.on{display:block;}' +
			'#rdsModal{position:fixed;z-index:1301;top:50%;left:50%;transform:translate(-50%,-50%);width:980px;max-width:96vw;' +
			'max-height:90vh;background:#fff;border-radius:10px;box-shadow:0 10px 40px rgba(0,0,0,.35);display:none;flex-direction:column;overflow:hidden;}' +
			'#rdsModal.on{display:flex;}' +
			'#rdsModal .rds-head{display:flex;align-items:center;gap:8px;padding:12px 18px;background:#1f3974;color:#fff;flex:0 0 auto;}' +
			'#rdsModal .rds-head h3{margin:0;font-size:16px;font-weight:700;flex:1;}' +
			'#rdsModal .rds-x{background:transparent;border:0;color:#fff;font-size:24px;line-height:1;cursor:pointer;padding:0 4px;}' +
			'#rdsModal .rds-scroll{overflow:auto;padding:18px 20px;}' +
			'#rdsModal .rds-row{display:flex;align-items:flex-start;gap:12px;padding:7px 0;border-bottom:1px dashed #e2e4e9;}' +
			'#rdsModal .rds-row:last-child{border-bottom:0;}' +
			'#rdsModal .rds-label{flex:0 0 84px;font-weight:600;color:#1f3974;padding-top:6px;font-size:14px;}' +
			'#rdsModal .rds-conts{flex:1;min-width:0;display:flex;flex-wrap:wrap;align-items:center;gap:8px 14px;}' +
			'#rdsModal .rds-conts label{font-weight:normal;display:inline-flex;align-items:center;gap:4px;font-size:14px;}' +
			'#rdsModal .rds-conts input[type=text],#rdsModal .rds-conts input[type=date]{height:34px;box-sizing:border-box;padding:4px 10px;border:1px solid #c7ccd6;border-radius:5px;}' +
			'#rdsModal .rds-conts input[name=searchKeyword]{width:320px;max-width:100%;}' +
			'#rdsModal .rds-conts select{height:34px;border:1px solid #c7ccd6;border-radius:5px;padding:0 8px;max-width:340px;}' +
			'#rdsModal .rds-prefix{display:flex;flex-wrap:wrap;gap:3px;}' +
			'#rdsModal .rds-prefix a{display:inline-block;min-width:25px;text-align:center;padding:3px 4px;border:1px solid #c7ccd6;' +
			'border-radius:4px;background:#fff;color:#33405a;text-decoration:none;font-size:13px;cursor:pointer;}' +
			'#rdsModal .rds-prefix a:hover{background:#e8edf9;border-color:#1f3974;color:#16306a;}' +
			'#rdsModal .rds-foot{flex:0 0 auto;text-align:center;padding:12px;border-top:1px solid #eee;}' +
			'@media print{#rdsOpenBtn,#rdsBackdrop,#rdsModal{display:none!important;}}';
		var st = document.createElement('style');
		st.id = 'rds-style';
		st.textContent = css;
		document.head.appendChild(st);
	}

	function init() {
		injectCSS();
		var modal = document.getElementById('rdsModal');
		var backdrop = document.getElementById('rdsBackdrop');
		var openBtn = document.getElementById('rdsOpenBtn');
		var form = document.getElementById('detailSearchForm');
		if (!modal || !backdrop || !openBtn || !form) { return; }

		function open() { backdrop.classList.add('on'); modal.classList.add('on'); }
		function close() { backdrop.classList.remove('on'); modal.classList.remove('on'); }

		openBtn.addEventListener('click', open);
		backdrop.addEventListener('click', close);
		var x = modal.querySelector('.rds-x');
		if (x) { x.addEventListener('click', close); }
		document.addEventListener('keydown', function (e) {
			if (e.key === 'Escape' && modal.classList.contains('on')) { close(); }
		});

		// 자음/영문 첫글자 — prefix 설정(다른 prefix 해제) 후 모달 폼 제출
		Array.prototype.forEach.call(modal.querySelectorAll('[data-h]'), function (a) {
			a.addEventListener('click', function () {
				form.hangulPrefix.value = a.getAttribute('data-h');
				form.englishPrefix.value = -1;
				form.submit();
			});
		});
		Array.prototype.forEach.call(modal.querySelectorAll('[data-e]'), function (a) {
			a.addEventListener('click', function () {
				form.englishPrefix.value = a.getAttribute('data-e');
				form.hangulPrefix.value = -1;
				form.submit();
			});
		});
	}

	window.RlmsDetailSearch = { init: init };

})(window, document);
