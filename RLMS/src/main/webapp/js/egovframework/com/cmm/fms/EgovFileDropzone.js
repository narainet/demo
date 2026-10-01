/**
 * EgovFileDropzone — 폼 제출형 파일 드롭존 (KRDS 톤: rlms-compat .krds-file-upload / .ide-file-drop 스타일 사용)
 *
 * 네이티브 <input type="file" multiple> 를 채우는 역할만 하며, 업로드 자체는 폼 제출(multipart)에 실린다.
 * (AJAX 업로드 아님 — 게시판처럼 검증·CKEditor·redirect 가 네이티브 제출 위에 있는 폼용.)
 *
 * 클라이언트 사전검사 3종(개수/확장자/크기)을 제공한다. 확장자·크기 위반을 서버까지 보내면
 * EgovMultipartResolver 가 파싱 단계에서 예외를 던져 작성 중이던 본문까지 유실되므로 사전 차단이 목적.
 *
 * 사용:
 *   EgovFileDropzone.init({
 *     input: 'egovComFileUploader',   // <input type="file"> id (필수)
 *     drop: 'bbsFileDrop',            // 드롭존 div id (필수)
 *     list: 'bbsFileSelList',         // 선택파일 <ul> id
 *     total: 'bbsFileTotal',          // "총 N개" div id (안엔 .current span)
 *     notice: 'bbsFileNotice',        // 경고문 div id
 *     maxCount: 3,                    // 최대 파일 수 (0/미지정 = 무제한)
 *     maxSize: 52428800,              // 파일당 최대 바이트 (0/미지정 = 무제한)
 *     extensions: '.gif.jpg...'       // 허용 확장자 목록(.구분 연결 문자열, 빈값 = 검사 생략)
 *   });
 *  대상 요소가 없으면 조용히 무시한다(첨부 불가 게시판 등 조건부 렌더 대응).
 */
var EgovFileDropzone = (function() {
	'use strict';

	function fmtSize(b) {
		if (b == null) { return ''; }
		if (b < 1024) { return b + ' B'; }
		if (b < 1048576) { return (b / 1024).toFixed(1) + ' KB'; }
		return (b / 1048576).toFixed(1) + ' MB';
	}

	function extOf(name) {
		var i = name.lastIndexOf('.');
		return i < 0 ? '' : name.substring(i).toLowerCase();
	}

	function init(opt) {
		var input = document.getElementById(opt.input);
		var drop = document.getElementById(opt.drop);
		if (!input || !drop) { return; }
		var list = document.getElementById(opt.list);
		var total = document.getElementById(opt.total);
		var notice = document.getElementById(opt.notice);
		var maxCount = parseInt(opt.maxCount, 10) || 0;
		var maxSize = parseInt(opt.maxSize, 10) || 0;
		var extensions = (opt.extensions || '').toLowerCase();

		function warn(msg) {
			if (notice) { notice.textContent = msg; notice.style.display = msg ? '' : 'none'; }
			else if (msg) { alert(msg); }
		}

		function validate(files) {
			if (maxCount && files.length > maxCount) {
				return '첨부파일은 최대 ' + maxCount + '개까지 등록할 수 있습니다.';
			}
			for (var i = 0; i < files.length; i++) {
				var f = files[i];
				var ext = extOf(f.name);
				// 목록은 ".gif.jpg...zip" 점 연결 — 끝에 '.' 을 붙여 항목 단위 정확 매치
				if (extensions && (ext === '' || (extensions + '.').indexOf(ext + '.') < 0)) {
					return '허용되지 않는 파일 형식입니다: ' + f.name;
				}
				if (maxSize && f.size > maxSize) {
					return '파일당 최대 크기(' + fmtSize(maxSize) + ')를 초과했습니다: ' + f.name;
				}
			}
			return '';
		}

		function render() {
			var files = input.files || [];
			if (list) {
				list.innerHTML = '';
				for (var i = 0; i < files.length; i++) {
					var li = document.createElement('li');
					var info = document.createElement('div');
					info.className = 'file-info';
					var nameSpan = document.createElement('span');
					nameSpan.className = 'file-name';
					nameSpan.textContent = files[i].name + ' ';
					var fs = document.createElement('span');
					fs.className = 'fs';
					fs.textContent = fmtSize(files[i].size);
					nameSpan.appendChild(fs);
					var btnWrap = document.createElement('div');
					btnWrap.className = 'btn-wrap';
					var btn = document.createElement('button');
					btn.type = 'button';
					btn.className = 'upload-delete-btn';
					btn.setAttribute('data-idx', i);
					btn.title = '삭제';
					btn.textContent = '삭제';
					btnWrap.appendChild(btn);
					info.appendChild(nameSpan);
					info.appendChild(btnWrap);
					li.appendChild(info);
					list.appendChild(li);
				}
			}
			if (total) {
				total.style.display = files.length ? '' : 'none';
				var cur = total.querySelector('.current');
				if (cur) { cur.textContent = files.length; }
			}
		}

		input.addEventListener('change', function() {
			var err = validate(input.files || []);
			if (err) { input.value = ''; }
			warn(err);
			render();
		});

		if (list) {
			list.addEventListener('click', function(e) {
				var btn = e.target.closest ? e.target.closest('.upload-delete-btn') : null;
				if (!btn) { return; }
				var idx = parseInt(btn.getAttribute('data-idx'), 10);
				try {
					var dt = new DataTransfer();
					for (var i = 0; i < input.files.length; i++) {
						if (i !== idx) { dt.items.add(input.files[i]); }
					}
					input.files = dt.files;
				} catch (err) { input.value = ''; }   // 구형 브라우저 — 전체 초기화
				input.dispatchEvent(new Event('change'));
			});
		}

		['dragover', 'dragenter'].forEach(function(ev) {
			drop.addEventListener(ev, function(e) { e.preventDefault(); drop.classList.add('active'); });
		});
		['dragleave', 'dragend'].forEach(function(ev) {
			drop.addEventListener(ev, function() { drop.classList.remove('active'); });
		});
		drop.addEventListener('drop', function(e) {
			e.preventDefault();
			drop.classList.remove('active');
			if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length) {
				try { input.files = e.dataTransfer.files; } catch (err) {}
				input.dispatchEvent(new Event('change'));
			}
		});
	}

	return { init: init };
})();
