/*!
 * egov-menu-jstree.js — 표준프레임워크 메뉴/사이트맵 트리 jsTree 변환 wrapper
 *
 * 옛 createTree() (이미지 기반 / document.write) 를 jsTree 로 대체.
 * 서버는 별도 *Json.do 엔드포인트가 List 를 반환하고, 이 wrapper 가
 * flat → nested 트리 변환 + 선택 콜백을 표준화한다.
 *
 * 사용:
 *   EgovMenuTree.init({
 *     containerId: 'ideMenuTree',                              // 필수
 *     jsonUrl:     '/sym/mnu/mpm/EgovMenuListJson.do',         // 필수
 *     fields:      { id: 'menuNo', parent: 'upperMenuId',      // 선택 — 기본값과 동일
 *                    text: 'menuNm', icon: null },
 *     opened:      true,                                       // 선택 — 기본 펼침
 *     showId:      true,                                       // 선택 — 라벨에 (id) suffix
 *     checkbox:    false,                                      // 선택 — 체크박스 트리 (메뉴생성용)
 *     checkedKey:  'chkYeoBu',                                 // 선택 — checkbox=true 시 초기 체크 필드(Y/1)
 *     urlKey:      null,                                       // 선택 — 노드별 URL 필드명 (사이트맵)
 *     onSelect:    function(node, data) { ... },               // 선택 노드 → row data
 *     onCheck:     function(checkedIds, checkedRows) { ... },  // 체크 변경 (checkbox=true 시)
 *     onReady:     function(inst) { ... }                       // 트리 로드 완료
 *   });
 *
 * 반환: jstree 인스턴스에 대한 jQuery 객체.
 *
 * 의존성: jQuery, jstree.min.js
 *   <link rel="stylesheet" href="/resources/lib/jstree/style.min.css"/>
 *   <script src="/resources/lib/jstree/jstree.min.js"></script>
 *
 * © 2026 RLMS — 표준 일관성 단일화 (prom 에디터와 동일 컴포넌트).
 */
(function(global, $) {
	'use strict';

	function _esc(s) {
		return String(s == null ? '' : s)
			.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
	}

	function _toNodes(rows, fields, opt) {
		var fId = fields.id, fParent = fields.parent, fText = fields.text;
		var fIcon = fields.icon;   // null 이면 default
		var ckKey = opt.checkedKey || 'chkYeoBu';
		return (rows || []).map(function(m) {
			var id  = m[fId];
			var pid = m[fParent];
			var lbl = m[fText];
			var pidStr = (pid == null) ? '' : String(pid);
			var idStr  = (id  == null) ? '' : String(id);
			var isRoot = (pidStr === '' || pidStr === '0' || pidStr === idStr);
			var label  = _esc(lbl);
			if (opt.showId !== false && idStr) {
				label += ' <span style="color:#888;font-size:11px;">(' + _esc(idStr) + ')</span>';
			}
			// URL 필드가 있으면 라벨에 (외부 링크) 표기
			if (opt.urlKey && m[opt.urlKey]) {
				label += ' <span style="color:#1f3974;font-size:10px;">[link]</span>';
			}
			// 체크박스 초기 상태 (Y/1/true 만 체크)
			var ckRaw = m[ckKey];
			var ckOn  = (ckRaw === 'Y' || ckRaw === 'y' || ckRaw === '1' ||
			             ckRaw === 1   || ckRaw === true);
			return {
				id:     'n_' + idStr,
				parent: isRoot ? '#' : 'n_' + pidStr,
				text:   label,
				icon:   fIcon ? m[fIcon] : undefined,
				data:   m,
				state:  {
					opened:   opt.opened !== false,
					selected: opt.checkbox ? false : undefined,
					checked:  opt.checkbox ? ckOn : undefined
				}
			};
		});
	}

	function init(opt) {
		if (!opt || !opt.containerId) {
			console.error('[EgovMenuTree.init] containerId 필수');
			return null;
		}
		if (!opt.jsonUrl) {
			console.error('[EgovMenuTree.init] jsonUrl 필수');
			return null;
		}
		var fields = $.extend(
			{ id: 'menuNo', parent: 'upperMenuId', text: 'menuNm', icon: null },
			opt.fields || {});
		var $box = $('#' + opt.containerId);
		if (!$box.length) {
			console.error('[EgovMenuTree.init] container 없음:', opt.containerId);
			return null;
		}

		$box.html('<p style="color:#888;padding:12px;font-size:13px;">트리 로딩...</p>');

		$.ajax({ url: opt.jsonUrl, dataType: 'json', cache: false })
			.done(function(rows) {
				// 행 필터 (예: MENU_SE 별 탭 분리) — 노드 변환 전에 적용
				if (typeof opt.rowFilter === 'function') {
					rows = (rows || []).filter(opt.rowFilter);
				}
				var nodes = _toNodes(rows, fields, opt);
				if (!nodes.length) {
					$box.html('<p style="color:#888;padding:12px;font-size:13px;">' +
						(opt.emptyMsg || '메뉴가 존재하지 않습니다. 메뉴 등록 후 사용하세요.') +
						'</p>');
					return;
				}
				var plugins = ['types', 'search'];
				if (opt.checkbox) plugins.push('checkbox');
				if (opt.dnd) plugins.push('dnd');          // 드래그로 순서/이동
				if (opt.wholerow) plugins.push('wholerow');

				var $inst = $box.empty().jstree({
					core: {
						themes: { responsive: false, dots: true, icons: true },
						check_callback: true,
						data: nodes
					},
					types: {
						default: { icon: 'jstree-folder' }
					},
					search: { show_only_matches: true, show_only_matches_children: true,
					          case_sensitive: false, fuzzy: false },
					checkbox: opt.checkbox ? {
						three_state: true, whole_node: false, tie_selection: false
					} : undefined,
					plugins: plugins
				}).on('select_node.jstree', function(e, data) {
					// URL 노드 클릭 시 새 창
					if (opt.urlKey && data.node.data && data.node.data[opt.urlKey]) {
						var u = data.node.data[opt.urlKey];
						if (u && String(u).trim() && String(u) !== '#') {
							try { window.open(u, '_blank'); } catch (e2) {}
						}
					}
					if (typeof opt.onSelect === 'function') {
						opt.onSelect(data.node, data.node.data || {});
					}
				}).on('check_node.jstree uncheck_node.jstree', function(e, data) {
					if (!opt.checkbox || typeof opt.onCheck !== 'function') return;
					var inst = data.instance;
					var ids = inst.get_checked();
					var rows = ids.map(function(nid) {
						var n = inst.get_node(nid);
						return n ? (n.data || {}) : {};
					});
					opt.onCheck(ids, rows);
				}).on('move_node.jstree', function(e, data) {
					// 드래그 이동/정렬 — 새 부모(UPPER_MENU_NO=0 if root) + 새 부모의 자식 순서를 콜백에 전달
					if (typeof opt.onMove !== 'function') return;
					var inst = data.instance;
					var parentId = data.parent;
					var newUpper = (parentId === '#' || parentId == null) ? '0' : String(parentId).replace(/^n_/, '');
					var movedNo  = String(data.node.id).replace(/^n_/, '');
					var pnode = inst.get_node(parentId);
					var sibs = (pnode && pnode.children ? pnode.children : []).map(function(cid) {
						return String(cid).replace(/^n_/, '');
					});
					opt.onMove(movedNo, newUpper, sibs);
				}).on('ready.jstree', function(e, data) {
					if (typeof opt.onReady === 'function') opt.onReady(data.instance);
				});
			})
			.fail(function(xhr) {
				$box.html('<p style="color:#b03030;padding:12px;font-size:13px;">' +
					'트리 데이터 조회 실패 (' + xhr.status + ')</p>');
				if (typeof opt.onError === 'function') opt.onError(xhr);
			});
		return $box;
	}

	// 검색 — 컨테이너 내부 jsTree 에 검색어 적용
	function search(containerId, q) {
		var $t = $('#' + containerId);
		if ($t.jstree(true)) $t.jstree('search', q || '');
	}

	function clearSearch(containerId) {
		var $t = $('#' + containerId);
		if ($t.jstree(true)) $t.jstree('clear_search');
	}

	function refresh(containerId) {
		var $t = $('#' + containerId);
		if ($t.jstree(true)) $t.jstree('refresh');
	}

	// 체크박스 트리 — 현재 체크된 메뉴 id 들 반환 (n_ prefix 제거).
	// withUndetermined=true 면 부분체크(undetermined) 부모도 포함 — 체크된 하위가 GNB 에서
	// 보이려면 그 부모(폴더)도 권한배정돼야 하므로 메뉴생성 저장 시 사용.
	function getCheckedIds(containerId, withUndetermined) {
		var $t = $('#' + containerId);
		if (!$t.jstree(true)) return [];
		var inst = $t.jstree(true);
		var ids = inst.get_checked() || [];
		if (withUndetermined) {
			ids = ids.concat(inst.get_undetermined() || []);
		}
		return ids.map(function(s) { return String(s).replace(/^n_/, ''); });
	}

	// 체크된 노드의 row data 들
	function getCheckedRows(containerId) {
		var $t = $('#' + containerId);
		if (!$t.jstree(true)) return [];
		var inst = $t.jstree(true);
		var ids = inst.get_checked() || [];
		return ids.map(function(nid) {
			var n = inst.get_node(nid);
			return n ? (n.data || {}) : {};
		});
	}

	global.EgovMenuTree = {
		init:            init,
		search:          search,
		clearSearch:     clearSearch,
		refresh:         refresh,
		getCheckedIds:   getCheckedIds,
		getCheckedRows:  getCheckedRows
	};

})(window, jQuery);
