/*!
 * rlms-menu-tree.js — UL 기반 메뉴 트리 (HTML5 드래그 순서/이동)
 *
 * jstree 번들에 dnd 플러그인이 없어, 메뉴 관리 트리는 중첩 <ul> 로 직접 렌더하고
 * 네이티브 HTML5 드래그로 순서변경(before/after) + 부모이동(into) 을 처리한다.
 * 서버는 별도 *Json.do 가 flat 목록을 반환, 이 컴포넌트가 flat→트리 변환 + 콜백 표준화.
 *
 * 사용:
 *   RlmsMenuTree.init({
 *     containerId: 'ideMenuTreeUser',                       // 필수
 *     jsonUrl:     '/sym/mnu/mpm/EgovMenuListJson.do',      // 필수
 *     fields:      { id:'menuNo', parent:'upperMenuId', text:'menuNm' },
 *     showId:      true,
 *     rowFilter:   function(row){ return row.menuSe==='USER'; },  // 선택
 *     emptyMsg:    '메뉴가 없습니다.',
 *     onSelect:    function(row){ ... },                    // 노드 클릭
 *     onMove:      function(movedId, newUpperId, siblingIds){ ... } // 드래그 확정
 *   });
 *   RlmsMenuTree.search(containerId, q);  RlmsMenuTree.clearSearch(containerId);
 *
 * 의존성: jQuery.  CSS: rlms-compat.css 의 .rmt-* 규칙.
 * © 2026 RLMS.
 */
(function(global, $) {
	'use strict';

	function esc(s) {
		return String(s == null ? '' : s)
			.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
	}

	// flat rows → 중첩 트리 (각 row 에 __children 부여)
	function buildTree(rows, fId, fParent) {
		var byId = {}, roots = [];
		(rows || []).forEach(function(r) { r.__children = []; byId[String(r[fId])] = r; });
		(rows || []).forEach(function(r) {
			var pid = r[fParent];
			var pidStr = (pid == null) ? '' : String(pid);
			if (pidStr === '' || pidStr === '0' || !byId[pidStr]) {
				roots.push(r);
			} else {
				byId[pidStr].__children.push(r);
			}
		});
		return roots;
	}

	function renderNodes(nodes, fId, fText, opt) {
		var html = '<ul class="rmt-list">';
		nodes.forEach(function(n) {
			var id = n[fId];
			var hasKids = n.__children && n.__children.length > 0;
			var label = esc(n[fText]);
			if (opt.showId !== false && id != null) {
				label += ' <span class="rmt-id">(' + esc(id) + ')</span>';
			}
			html += '<li class="rmt-node" data-id="' + esc(id) + '" draggable="true">';
			html +=   '<div class="rmt-row">';
			html +=     '<span class="rmt-toggle' + (hasKids ? '' : ' rmt-leaf') + '"></span>';
			html +=     '<span class="rmt-label">' + label + '</span>';
			html +=   '</div>';
			if (hasKids) {
				html += renderNodes(n.__children, fId, fText, opt);
			}
			html += '</li>';
		});
		html += '</ul>';
		return html;
	}

	function init(opt) {
		if (!opt || !opt.containerId || !opt.jsonUrl) {
			console.error('[RlmsMenuTree.init] containerId, jsonUrl 필수');
			return;
		}
		var fields = $.extend({ id: 'menuNo', parent: 'upperMenuId', text: 'menuNm' }, opt.fields || {});
		var $box = $('#' + opt.containerId);
		if (!$box.length) { console.error('[RlmsMenuTree.init] container 없음:', opt.containerId); return; }

		$box.html('<p class="rmt-loading">트리 로딩...</p>');
		$.ajax({ url: opt.jsonUrl, dataType: 'json', cache: false })
			.done(function(rows) {
				if (typeof opt.rowFilter === 'function') {
					rows = (rows || []).filter(opt.rowFilter);
				}
				var map = {};
				(rows || []).forEach(function(r) { map[String(r[fields.id])] = r; });
				var roots = buildTree(rows, fields.id, fields.parent);
				if (!roots.length) {
					$box.html('<p class="rmt-empty">' + esc(opt.emptyMsg || '메뉴가 없습니다.') + '</p>');
					return;
				}
				$box.html(renderNodes(roots, fields.id, fields.text, opt));
				bind($box, map, opt, fields);
			})
			.fail(function(xhr) {
				$box.html('<p class="rmt-error">트리 조회 실패 (' + xhr.status + ')</p>');
			});
	}

	function bind($box, map, opt, fields) {
		var dragId = null;   // 컨테이너별 closure — 탭(트리) 간 드래그 자동 차단

		// 펼침/접힘
		$box.off('.rmt').on('click.rmt', '.rmt-toggle', function(e) {
			e.stopPropagation();
			if ($(this).hasClass('rmt-leaf')) { return; }
			$(this).closest('.rmt-node').toggleClass('rmt-collapsed');
		});

		// 선택 → 우측 폼
		$box.on('click.rmt', '.rmt-row', function() {
			var id = $(this).closest('.rmt-node').data('id');
			$box.find('.rmt-row.rmt-selected').removeClass('rmt-selected');
			$(this).addClass('rmt-selected');
			if (typeof opt.onSelect === 'function') { opt.onSelect(map[String(id)] || {}); }
		});

		// ── HTML5 드래그 ──────────────────────────────
		$box.on('dragstart.rmt', '.rmt-node', function(e) {
			e.stopPropagation();
			dragId = $(this).data('id');
			var dt = e.originalEvent.dataTransfer;
			dt.effectAllowed = 'move';
			try { dt.setData('text/plain', String(dragId)); } catch (_) {}
			$(this).addClass('rmt-dragging');
		});
		$box.on('dragend.rmt', '.rmt-node', function() {
			dragId = null;
			$box.find('.rmt-dragging').removeClass('rmt-dragging');
			clearDropHints($box);
		});
		$box.on('dragover.rmt', '.rmt-row', function(e) {
			if (dragId == null) { return; }
			e.preventDefault(); e.stopPropagation();
			e.originalEvent.dataTransfer.dropEffect = 'move';
			var rect = this.getBoundingClientRect();
			var y = e.originalEvent.clientY - rect.top;
			clearDropHints($box);
			var $row = $(this);
			if (y < rect.height * 0.28) { $row.addClass('rmt-drop-before'); }
			else if (y > rect.height * 0.72) { $row.addClass('rmt-drop-after'); }
			else { $row.addClass('rmt-drop-into'); }
		});
		$box.on('drop.rmt', '.rmt-row', function(e) {
			e.preventDefault(); e.stopPropagation();
			var $row = $(this);
			var mode = $row.hasClass('rmt-drop-before') ? 'before'
			         : $row.hasClass('rmt-drop-after')  ? 'after' : 'into';
			clearDropHints($box);
			var $targetNode = $row.closest('.rmt-node');
			var targetId = $targetNode.data('id');
			if (dragId == null || String(dragId) === String(targetId)) { return; }
			var $drag = $box.find('.rmt-node[data-id="' + cssEsc(dragId) + '"]').first();
			// 자기 자신의 하위로는 이동 금지 (순환 방지)
			if ($targetNode.parents('.rmt-node[data-id="' + cssEsc(dragId) + '"]').length
			    || (mode === 'into' && $targetNode.closest('.rmt-node').is($drag))) {
				return;
			}
			applyMove($box, $drag, $targetNode, mode);
			notifyMove($box, $drag, opt);
		});
	}

	function clearDropHints($box) {
		$box.find('.rmt-drop-into, .rmt-drop-before, .rmt-drop-after')
			.removeClass('rmt-drop-into rmt-drop-before rmt-drop-after');
	}

	function applyMove($box, $drag, $targetNode, mode) {
		if (mode === 'into') {
			var $ul = $targetNode.children('ul.rmt-list');
			if (!$ul.length) {
				$ul = $('<ul class="rmt-list"></ul>').appendTo($targetNode);
				$targetNode.children('.rmt-row').find('.rmt-toggle').removeClass('rmt-leaf');
			}
			$targetNode.removeClass('rmt-collapsed');
			$ul.append($drag);
		} else if (mode === 'before') {
			$drag.insertBefore($targetNode);
		} else {
			$drag.insertAfter($targetNode);
		}
		// 옛 부모가 비었으면 leaf 표시 복원
		$box.find('ul.rmt-list').each(function() {
			var $ul = $(this);
			if (!$ul.children('.rmt-node').length) {
				var $owner = $ul.closest('.rmt-node');
				$ul.remove();
				if ($owner.length && !$owner.children('ul.rmt-list').length) {
					$owner.children('.rmt-row').find('.rmt-toggle').addClass('rmt-leaf');
				}
			}
		});
	}

	function notifyMove($box, $drag, opt) {
		if (typeof opt.onMove !== 'function') { return; }
		var $parentUl = $drag.parent('ul.rmt-list');
		var $parentNode = $parentUl.closest('.rmt-node');
		var newUpper = $parentNode.length ? String($parentNode.data('id')) : '0';
		var sibs = $parentUl.children('.rmt-node').map(function() {
			return String($(this).data('id'));
		}).get();
		opt.onMove(String($drag.data('id')), newUpper, sibs);
	}

	// data-id 는 숫자라 단순하지만, 안전하게 CSS 속성선택자 이스케이프
	function cssEsc(v) {
		return String(v).replace(/(["\\])/g, '\\$1');
	}

	function search(containerId, q) {
		var $box = $('#' + containerId);
		q = (q == null ? '' : String(q)).trim().toLowerCase();
		if (!q) {
			$box.find('.rmt-node').show();
			$box.find('.rmt-row.rmt-match').removeClass('rmt-match');
			return;
		}
		$box.find('.rmt-node').hide();
		$box.find('.rmt-row.rmt-match').removeClass('rmt-match');
		$box.find('.rmt-label').each(function() {
			if ($(this).text().toLowerCase().indexOf(q) >= 0) {
				var $node = $(this).closest('.rmt-node');
				$node.show();
				$node.parents('.rmt-node').show();   // 조상도 표시
				$(this).closest('.rmt-row').addClass('rmt-match');
			}
		});
	}

	function clearSearch(containerId) { search(containerId, ''); }

	global.RlmsMenuTree = { init: init, search: search, clearSearch: clearSearch };

})(window, jQuery);
