<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prommap/prommapManage.jsp

  기능별분류관리 (규정맵) — 레거시 system_promulgation_map.jsp 이관.
   - 좌측: 분류/규정 소스 트리 (기존 /rlms/prom/treeJson.do — gubun→분류→규정)
   - 가운데: 추가 → / ← 삭제
   - 우측: 기능별분류 트리 (/rlms/prommap/treeJson.do)
   - 끝: 분류정보(이름변경)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">기능별분류관리</c:set>
<c:set var="pageHead">
  
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css'/>"/>
  <style>
    .ppm-wrap { padding: 16px 20px; }
    .ppm-title { font-size: 20px; font-weight: 700; color: #1f3974; margin: 0 0 4px; }
    .ppm-desc { color: #555; font-size: 13px; margin: 0 0 14px; }
    .ppm-3pane { display: flex; gap: 12px; align-items: stretch; }
    .ppm-col { border: 1px solid #cdd6e6; border-radius: 6px; background: #fff; display: flex; flex-direction: column; }
    .ppm-col-src  { flex: 1 1 0; min-width: 0; }
    .ppm-col-map  { flex: 1 1 0; min-width: 0; }
    .ppm-col-mid  { flex: 0 0 92px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 18px; border: none; background: transparent; }
    .ppm-col-info { flex: 0 0 220px; }
    .ppm-col-tit { background: #eef2fb; color: #1f3974; font-weight: 600; font-size: 13px; padding: 7px 10px; border-bottom: 1px solid #cdd6e6; border-radius: 6px 6px 0 0; }
    .ppm-tree { height: 560px; overflow: auto; padding: 6px; white-space: nowrap; }
    .ppm-mid-btn { width: 72px; height: 44px; border: 1px solid #1f3974; background: #1f3974; color: #fff; border-radius: 6px; font-size: 13px; font-weight: 600; cursor: pointer; }
    .ppm-mid-btn:hover { background: #163265; }
    .ppm-mid-btn.danger { border-color: #c0392b; background: #c0392b; }
    .ppm-mid-btn.danger:hover { background: #a5311f; }
    .ppm-info-body { padding: 12px; }
    .ppm-info-body label { display: block; font-size: 12px; color: #555; margin: 0 0 4px; }
    .ppm-info-body input { width: 100%; box-sizing: border-box; height: 32px; padding: 4px 8px; border: 1px solid #c5d0e3; border-radius: 4px; margin-bottom: 10px; }
    .ppm-info-sel { font-size: 12px; color: #1f3974; background: #f4f7fd; border: 1px solid #dde6f5; border-radius: 4px; padding: 6px 8px; margin-bottom: 10px; min-height: 16px; word-break: break-all; }
    .ppm-hint { font-size: 11px; color: #888; margin: 8px 0 0; line-height: 1.5; }
    .ppm-btn { height: 32px; padding: 0 14px; border: 1px solid #1f3974; background: #1f3974; color: #fff; border-radius: 4px; font-size: 13px; cursor: pointer; }
    .ppm-btn:hover { background: #163265; }
    .ppm-legend { font-size: 12px; color: #666; margin: 10px 2px 0; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="ppm-wrap">
    <h2 class="ppm-title">기능별분류관리</h2>
    <p class="ppm-desc">1차 분류와 별개로, 규정을 임의의 <strong>기능별 분류 트리</strong>에 매핑합니다.
      좌측에서 분류(하위·규정 포함) 또는 규정 1건을 선택해 [추가 &rarr;] 하고, 우측 트리에서 폴더를 선택해 그 아래로 넣습니다.</p>

    <div class="ppm-3pane">
      <%-- 좌측: 소스(분류/규정) --%>
      <section class="ppm-col ppm-col-src">
        <div class="ppm-col-tit">분류 / 규정 목록</div>
        <div id="ppmSourceTree" class="ppm-tree"></div>
      </section>

      <%-- 가운데: 추가/삭제 --%>
      <section class="ppm-col-mid">
        <button type="button" class="ppm-mid-btn" onclick="ppmAdd();" title="좌측 선택 → 우측 폴더(또는 루트)에 추가">추가 &rarr;</button>
        <button type="button" class="ppm-mid-btn danger" onclick="ppmDelete();" title="우측 선택 노드 + 하위 삭제(좌측 원본은 유지)">&larr; 삭제</button>
      </section>

      <%-- 우측: 기능별분류 트리 --%>
      <section class="ppm-col ppm-col-map">
        <div class="ppm-col-tit">기능별분류</div>
        <div id="ppmMapTree" class="ppm-tree"></div>
      </section>

      <%-- 끝: 분류정보(이름변경) --%>
      <section class="ppm-col ppm-col-info">
        <div class="ppm-col-tit">분류정보</div>
        <div class="ppm-info-body">
          <label>선택한 기능별분류 노드</label>
          <div class="ppm-info-sel" id="ppmSelInfo">(우측 트리에서 폴더 선택)</div>
          <label for="ppmRenameInput">분류명</label>
          <input type="text" id="ppmRenameInput" placeholder="이름을 입력하세요" disabled/>
          <button type="button" class="ppm-btn" onclick="ppmRename();">저장</button>
          <p class="ppm-hint">폴더 노드만 이름을 바꿀 수 있습니다.<br/>규정(잎) 항목의 이름은 규정 제목을 따릅니다.</p>
        </div>
      </section>
    </div>
    <p class="ppm-legend">※ [추가 &rarr;] 시 우측에서 아무 폴더도 선택하지 않으면 <strong>루트</strong>에 새 기능별 분류로 추가됩니다(분류만 가능). 규정 1건은 폴더 선택이 필요합니다.</p>
  </div>

  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js'/>"></script>
  <script>
    // 단일 시스템 — sysId(SSYS_ID) 미사용
    var SRC_TREE_URL = '<c:url value="/rlms/prom/treeJson.do"/>';
    var MAP_TREE_URL = '<c:url value="/rlms/prommap/treeJson.do"/>';
    var IMPORT_URL   = '<c:url value="/rlms/prommap/importJson.do"/>';
    var RENAME_URL   = '<c:url value="/rlms/prommap/renameJson.do"/>';
    var DELETE_URL   = '<c:url value="/rlms/prommap/deleteJson.do"/>';

    var srcSel = null;   // {type:'cate'|'prom'|'gubun', no}
    var mapSel = null;   // {pmapNo, promYn, name}

    $(function() {
      // 좌측 소스 트리 — gubun→분류→규정 (한 방, 규정은 leaf)
      $('#ppmSourceTree').jstree({
        core: {
          themes: { dots: true, icons: true },
          data: { url: function(node) { return SRC_TREE_URL + '?id=' + (node.id === '#' ? '#' : encodeURIComponent(node.id)); }, dataType: 'json' }
        },
        types: {
          gubun: { icon: 'jstree-folder' }, cate: { icon: 'jstree-folder' },
          law: { icon: 'jstree-folder' }, prom: { icon: 'jstree-file' }
        },
        plugins: ['types']
      }).on('select_node.jstree', function(e, data) {
        var id = data.node.id || '';
        if (id.indexOf('cate:') === 0)      srcSel = { type: 'cate', no: parseInt(id.split(':')[1], 10) };
        else if (id.indexOf('prom:') === 0) srcSel = { type: 'prom', no: parseInt(id.split(':')[1], 10) };
        else                                srcSel = { type: 'gubun', no: null };
      });

      // 우측 기능별분류 트리
      $('#ppmMapTree').jstree({
        core: {
          themes: { dots: true, icons: true },
          data: { url: function(node) { return MAP_TREE_URL; }, dataType: 'json' },
          check_callback: true
        },
        types: { pfolder: { icon: 'jstree-folder' }, pleaf: { icon: 'jstree-file' } },
        plugins: ['types']
      }).on('select_node.jstree', function(e, data) {
        var d = data.node.data || {};
        mapSel = { pmapNo: d.pmapNo, promYn: d.promYn, name: data.node.text };
        document.getElementById('ppmSelInfo').textContent = data.node.text + (d.promYn === 'Y' ? '  (규정)' : '  (폴더)');
        var inp = document.getElementById('ppmRenameInput');
        if (d.promYn === 'N') { inp.disabled = false; inp.value = data.node.text; }
        else { inp.disabled = true; inp.value = data.node.text; }
      }).on('deselect_all.jstree', function() { mapSel = null; });
    });

    function ppmRefreshMap() {
      var t = $('#ppmMapTree').jstree(true);
      if (t) t.refresh();
      mapSel = null;
      document.getElementById('ppmSelInfo').textContent = '(우측 트리에서 폴더 선택)';
      var inp = document.getElementById('ppmRenameInput'); inp.value = ''; inp.disabled = true;
    }

    function ppmAdd() {
      if (!srcSel || srcSel.type === 'gubun' || !srcSel.no) {
        alert('좌측에서 분류 또는 규정을 선택하세요. (구분 그룹은 추가할 수 없습니다)');
        return;
      }
      // 우측 선택이 규정(잎)이면 그 아래로 넣을 수 없음 (레거시 동일)
      if (mapSel && mapSel.promYn === 'Y') {
        alert('규정(잎) 아래에는 추가할 수 없습니다. 폴더를 선택하거나 선택을 해제(루트 추가)하세요.');
        return;
      }
      var refPmapNo = (mapSel && mapSel.promYn === 'N') ? mapSel.pmapNo : 0;
      if (srcSel.type === 'prom' && !refPmapNo) {
        alert('규정 1건은 추가할 기능별분류 폴더를 먼저 선택하세요.');
        return;
      }
      var msg = (srcSel.type === 'cate')
        ? '이 분류와 모든 하위(하위분류 + 규정)를 기능별분류에 추가하시겠습니까?'
        : '선택한 규정을 폴더에 추가하시겠습니까?';
      if (!confirm(msg)) return;
      $.ajax({ url: IMPORT_URL, method: 'POST',
               data: { sourceType: srcSel.type, sourceNo: srcSel.no, refPmapNo: refPmapNo }, dataType: 'json' })
        .done(function(d) {
          if (d.success) { alert(d.message || '추가되었습니다.'); ppmRefreshMap(); }
          else alert(d.message || '추가에 실패했습니다.');
        })
        .fail(function(xhr) { alert('추가 요청 실패: ' + xhr.status); });
    }

    function ppmDelete() {
      if (!mapSel || !mapSel.pmapNo) { alert('우측 기능별분류 트리에서 삭제할 노드를 선택하세요.'); return; }
      if (!confirm('"' + mapSel.name + '" 노드와 모든 하위를 삭제하시겠습니까?\n(원본 규정/분류는 삭제되지 않습니다)')) return;
      $.ajax({ url: DELETE_URL, method: 'POST', data: { pmapNo: mapSel.pmapNo }, dataType: 'json' })
        .done(function(d) {
          if (d.success) { alert(d.message || '삭제되었습니다.'); ppmRefreshMap(); }
          else alert(d.message || '삭제에 실패했습니다.');
        })
        .fail(function(xhr) { alert('삭제 요청 실패: ' + xhr.status); });
    }

    function ppmRename() {
      if (!mapSel || !mapSel.pmapNo) { alert('이름을 바꿀 폴더를 선택하세요.'); return; }
      if (mapSel.promYn === 'Y') { alert('규정(잎) 항목의 이름은 변경할 수 없습니다.'); return; }
      var name = (document.getElementById('ppmRenameInput').value || '').trim();
      if (!name) { alert('분류명을 입력하세요.'); return; }
      $.ajax({ url: RENAME_URL, method: 'POST', data: { pmapNo: mapSel.pmapNo, name: name }, dataType: 'json' })
        .done(function(d) {
          if (d.success) {
            alert(d.message || '변경되었습니다.');
            var t = $('#ppmMapTree').jstree(true);
            if (t) t.rename_node('pmap:' + mapSel.pmapNo, name);
            mapSel.name = name;
          } else alert(d.message || '변경에 실패했습니다.');
        })
        .fail(function(xhr) { alert('변경 요청 실패: ' + xhr.status); });
    }
  </script>
</lay:layout>
