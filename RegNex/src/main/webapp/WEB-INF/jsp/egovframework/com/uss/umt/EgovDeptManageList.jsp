<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/uss/umt/EgovDeptManageList.jsp

  부서관리 트리 화면 (2026-07-27 전환) — 공통코드관리(EgovCcmCodeTree.jsp)와 동일 골격.
  좌측 jsTree(본사·지사 최상위 > 하위부서, 단수 제한 없음: 3단·4단 …) + 우측 선택 정보/편집 폼.
  · 순서: ORDR (형제 내) — [▲ 위로][▼ 아래로] 즉시 저장(서버가 1..n 정규화 후 교환).
  · 최상위(본사·지사급) 추가 가능, 하위부서 추가는 선택 노드 아래로.
  · 수정 폼에서 상위부서 변경 가능(자기 자신·후손 제외, 서버 순환 가드 이중).
  · 삭제는 하위부서 없는 노드만(서버 가드). 순서 변경만 트리 리로드(선택 유지), 나머진 부분 갱신.
  기존 평면 목록/등록/수정 화면 흐름(EgovDeptManageInsert/Updt)은 이 화면으로 대체.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">부서관리</c:set>
<c:set var="pageHead">
  
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css'/>"/>
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js'/>"></script>
  <style>
    .dept-layout { display: flex; gap: 20px; align-items: stretch; }
    .dept-tree-pane { flex: 0 0 420px; border: 1px solid #d1d3d8; padding: 14px; min-height: 560px; border-radius: 6px; background: #fff; overflow: auto; }
    .dept-info-pane { flex: 1; border: 1px solid #d1d3d8; padding: 14px; min-height: 560px; border-radius: 6px; background: #fff; }
    .dept-info-pane h3 { margin: 0 0 12px; color: #1f3974; }
    .dept-empty { color: #666; padding: 12px 0; }
    .dept-message { margin-bottom: 12px; }
    .dept-detail { margin: 0 0 16px; padding: 12px; background: #f7f8fb; border: 1px solid #e1e4ea; border-radius: 6px; }
    .dept-detail dl { display: grid; grid-template-columns: 110px 1fr; gap: 8px 12px; margin: 0; }
    .dept-detail dt { color: #555; }
    .dept-detail dd { margin: 0; font-weight: 600; word-break: break-all; }
    .dept-toolbar { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 18px; }
    .dept-toolbar .sp { width: 12px; }
    .dept-form { border-top: 1px solid #e1e4ea; padding-top: 16px; }
    .dept-form-row { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
    .dept-form-row label { flex: 0 0 110px; font-weight: 600; color: #333; }
    .dept-form-row input[type="text"],
    .dept-form-row select { width: 100%; max-width: 420px; height: 36px; border: 1px solid #c9ced8; border-radius: 4px; padding: 0 10px; box-sizing: border-box; }
    .dept-form-row input[readonly] { background: #f3f4f7; color: #555; }
    .dept-form-actions { display: flex; gap: 8px; margin-left: 122px; }
    .dept-help { margin: 0 0 12px 122px; color: #666; }
    @media (max-width: 900px) {
      .dept-layout { flex-direction: column; }
      .dept-tree-pane { flex-basis: auto; min-height: 360px; }
      .dept-info-pane { min-height: 0; }
      .dept-form-row { display: block; }
      .dept-form-row label { display: block; margin-bottom: 6px; }
      .dept-form-actions,
      .dept-help { margin-left: 0; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>부서관리</h1>
    <p class="page-desc">본사·지사와 하위 부서를 트리로 관리합니다. 좌측에서 부서를 선택하고, ▲▼ 로 형제 간 순서를 바꿉니다.</p>
  </div>

  <div id="deptMessage" class="dept-message">
    <c:if test="${not empty message}">
      <div class="krds-alert info"><c:out value="${message}"/></div>
    </c:if>
  </div>

  <div class="dept-layout">
    <div class="dept-tree-pane">
      <div id="deptTree"></div>
      <div id="deptTreeEmpty" class="dept-empty" style="display:none;">등록된 부서가 없습니다. [최상위 추가]로 본사·지사를 등록하세요.</div>
    </div>
    <div class="dept-info-pane">
      <h3>선택한 부서</h3>
      <div class="dept-detail">
        <dl>
          <dt>부서 ID</dt>
          <dd id="selId">-</dd>
          <dt>부서명</dt>
          <dd id="selNm">(선택 없음)</dd>
          <dt>상위부서</dt>
          <dd id="selUpper">-</dd>
          <dt>순서</dt>
          <dd id="selOrdr">-</dd>
          <dt>설명</dt>
          <dd id="selDc">-</dd>
          <dt>하위부서 수</dt>
          <dd id="selChildCnt">-</dd>
        </dl>
      </div>

      <div class="dept-toolbar">
        <button type="button" id="btnAddRoot" class="krds-btn medium">최상위 추가</button>
        <button type="button" id="btnAddChild" class="krds-btn medium" disabled>하위부서 추가</button>
        <button type="button" id="btnEdit" class="krds-btn medium" disabled>수정</button>
        <button type="button" id="btnDelete" class="krds-btn danger medium" disabled>삭제</button>
        <span class="sp"></span>
        <button type="button" id="btnUp" class="krds-btn medium" disabled title="같은 상위부서 안에서 한 칸 위로">▲ 위로</button>
        <button type="button" id="btnDown" class="krds-btn medium" disabled title="같은 상위부서 안에서 한 칸 아래로">▼ 아래로</button>
      </div>

      <form id="deptEditForm" class="dept-form" onsubmit="return false;">
        <input type="hidden" id="formMode" value=""/>

        <p id="formHelp" class="dept-help">부서를 선택한 뒤 추가/수정을 선택하세요. 부서는 사용자 소속·소송 담당부서 등에서 참조되므로 삭제에 주의하세요.</p>

        <div class="dept-form-row">
          <label for="fNm">부서명</label>
          <input type="text" id="fNm" maxlength="60" disabled/>
        </div>
        <div class="dept-form-row" id="rowUpper" style="display:none;">
          <label for="fUpper">상위부서</label>
          <select id="fUpper" disabled></select>
        </div>
        <div class="dept-form-row">
          <label for="fDc">설명</label>
          <input type="text" id="fDc" maxlength="200" disabled/>
        </div>
        <div class="dept-form-actions">
          <button type="button" id="btnSave" class="krds-btn primary medium" disabled>저장</button>
          <button type="button" id="btnCancel" class="krds-btn medium" disabled>취소</button>
        </div>
      </form>
    </div>
  </div>

  <script>
    var TREE_JSON_URL = '<c:url value="/uss/umt/dpt/deptTreeJson.do"/>';
    var LOGIN_URL     = '<c:url value="/uat/uia/egovLoginUsr.do"/>';
    var INSERT_URL    = '<c:url value="/uss/umt/dpt/insertDeptAjax.do"/>';
    var UPDATE_URL    = '<c:url value="/uss/umt/dpt/updateDeptAjax.do"/>';
    var DELETE_URL    = '<c:url value="/uss/umt/dpt/deleteDeptAjax.do"/>';
    var REORDER_URL   = '<c:url value="/uss/umt/dpt/reorderDeptAjax.do"/>';

    $(function() {
      var selectedNode = null;
      var selectedData = {};

      loadTree();
      resetForm();

      function tree() { return $('#deptTree').jstree(true); }
      function hasSel() { return !!(selectedData && selectedData.orgnztId); }

      function bindTreeSelectionEvent() {
        $('#deptTree').off('select_node.jstree');
        $('#deptTree').on('select_node.jstree', function(_e, sel) {
          selectedNode = sel.node;
          selectedData = selectedNode.data || {};
          renderSelected();
          setToolbarState();
          resetForm();
        });
      }

      function loadTree(keepNodeId) {
        $('#deptTreeEmpty').hide();
        var inst = tree();
        if (inst) { inst.destroy(); }
        $('#deptTree').empty();

        $.getJSON(TREE_JSON_URL)
          .done(function(data) {
            if (data && data.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
            var nodes = (data && data.resultList) ? data.resultList : [];
            if (nodes.length === 0) { $('#deptTreeEmpty').show(); }
            bindTreeSelectionEvent();
            $('#deptTree').jstree({
              core: { data: nodes, themes: { name: 'default', dots: true, icons: true }, check_callback: true }
            }).one('ready.jstree', function() {
              var t = tree();
              t.open_all();   <%-- 부서 트리는 규모가 작아 전체 펼침이 기본 --%>
              if (keepNodeId && t.get_node(keepNodeId)) { focusNode(keepNodeId); }
            });
          })
          .fail(function() {
            showMessage('부서 트리를 불러오지 못했습니다.', false);
            $('#deptTreeEmpty').text('부서 트리를 불러오지 못했습니다.').show();
          });
      }

      function renderSelected() {
        $('#selId').text(dash(selectedData.orgnztId));
        $('#selNm').text(dash(selectedData.orgnztNm));
        $('#selUpper').text(upperName());
        $('#selOrdr').text(currentPosText());
        $('#selDc').text(dash(selectedData.orgnztDc));
        $('#selChildCnt').text(childCntOf(nodeId()));
      }

      function nodeId() { return hasSel() ? 'org_' + selectedData.orgnztId : null; }

      function upperName() {
        if (!hasSel()) return '-';
        if (!selectedData.upperOrgnztId) return '(최상위)';
        var p = tree().get_node('org_' + selectedData.upperOrgnztId);
        return p ? p.text : selectedData.upperOrgnztId;
      }

      <%-- 순서 표기 = 형제 내 실제 위치/형제 수 (ORDR 원값 대신 직관 표기) --%>
      function currentPosText() {
        if (!hasSel()) return '-';
        var t = tree(); var n = t.get_node(nodeId());
        if (!n) return '-';
        var kids = t.get_node(n.parent).children || [];
        return (kids.indexOf(n.id) + 1) + ' / ' + kids.length;
      }

      function childCntOf(id) {
        if (!id) return '-';
        var n = tree().get_node(id);
        return n ? (n.children || []).length : '-';
      }

      function setToolbarState() {
        var sel = hasSel();
        $('#btnAddChild, #btnEdit, #btnDelete').prop('disabled', !sel);
        var t = sel ? tree() : null;
        var n = sel ? t.get_node(nodeId()) : null;
        var kids = n ? (t.get_node(n.parent).children || []) : [];
        var idx = n ? kids.indexOf(n.id) : -1;
        $('#btnUp').prop('disabled', !(sel && idx > 0));
        $('#btnDown').prop('disabled', !(sel && idx >= 0 && idx < kids.length - 1));
      }

      $('#btnAddRoot').on('click', function() { beginInsert(null); });
      $('#btnAddChild').on('click', function() { if (hasSel()) beginInsert(selectedData.orgnztId); });
      $('#btnEdit').on('click', function() { if (hasSel()) beginUpdate(); });
      $('#btnDelete').on('click', function() { deleteSelected(); });
      $('#btnUp').on('click', function() { reorder('up'); });
      $('#btnDown').on('click', function() { reorder('down'); });
      $('#btnSave').on('click', function() { saveForm(); });
      $('#btnCancel').on('click', function() { resetForm(); });

      var insertParentId = null;   <%-- null=최상위 --%>

      function beginInsert(parentOrgnztId) {
        insertParentId = parentOrgnztId || null;
        enableForm('insert');
        $('#rowUpper').hide();
        if (insertParentId) {
          var p = tree().get_node('org_' + insertParentId);
          $('#formHelp').text('[' + (p ? p.text : insertParentId) + '] 아래에 하위부서를 등록합니다. 순서는 마지막에 붙습니다.');
        } else {
          $('#formHelp').text('최상위 조직(본사·지사급)을 등록합니다. 순서는 마지막에 붙습니다.');
        }
        $('#fNm').val('').focus();
        $('#fDc').val('');
      }

      function beginUpdate() {
        enableForm('update');
        $('#formHelp').text('선택한 부서를 수정합니다. 상위부서를 바꾸면 새 상위의 마지막 순서로 이동합니다.');
        $('#rowUpper').show();
        buildUpperOptions();
        $('#fNm').val(selectedData.orgnztNm || '').focus();
        $('#fDc').val(selectedData.orgnztDc || '');
      }

      <%-- 상위부서 셀렉트 — 트리 DFS 들여쓰기, 자기 자신+후손 제외(순환 방지, 서버 가드 이중) --%>
      function buildUpperOptions() {
        var t = tree();
        var self = nodeId();
        var selfNode = t.get_node(self);
        var banned = {};
        banned[self] = true;
        (selfNode.children_d || []).forEach(function(id) { banned[id] = true; });

        var opts = ['<option value="">(최상위)</option>'];
        function walk(id, depth) {
          (t.get_node(id).children || []).forEach(function(cid) {
            if (banned[cid]) return;
            var c = t.get_node(cid);
            var pad = new Array(depth + 1).join('　');
            var val = (c.data || {}).orgnztId || '';
            var sel = (selectedData.upperOrgnztId === val) ? ' selected' : '';
            opts.push('<option value="' + val + '"' + sel + '>' + pad + esc(c.text) + '</option>');
            walk(cid, depth + 1);
          });
        }
        walk('#', 0);
        $('#fUpper').html(opts.join(''));
        if (!selectedData.upperOrgnztId) { $('#fUpper').val(''); }
      }

      function enableForm(mode) {
        $('#formMode').val(mode);
        $('#fNm, #fDc, #fUpper').prop('disabled', false);
        $('#btnSave, #btnCancel').prop('disabled', false);
      }

      function resetForm() {
        $('#formMode').val('');
        $('#formHelp').text('부서를 선택한 뒤 추가/수정을 선택하세요. 부서는 사용자 소속·소송 담당부서 등에서 참조되므로 삭제에 주의하세요.');
        $('#rowUpper').hide();
        $('#fNm').val('');
        $('#fDc').val('');
        $('#fUpper').html('');
        $('#fNm, #fDc, #fUpper').prop('disabled', true);
        $('#btnSave, #btnCancel').prop('disabled', true);
      }

      function saveForm() {
        var mode = $('#formMode').val();
        if (!mode) return;
        var nm = $.trim($('#fNm').val());
        var dc = $.trim($('#fDc').val());
        if (!nm) { showMessage('부서명을 입력하세요.', false); $('#fNm').focus(); return; }

        $('#btnSave').prop('disabled', true);
        if (mode === 'insert') {
          $.post(INSERT_URL, { orgnztNm: nm, orgnztDc: dc, upperOrgnztId: insertParentId || '' }, null, 'json')
            .done(function(d) {
              if (d && d.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
              if (!(d && d.success)) { showMessage((d && d.resultMsg) || '저장 중 오류가 발생했습니다.', false); $('#btnSave').prop('disabled', false); return; }
              showMessage(d.resultMsg || '등록되었습니다.', true);
              var parent = insertParentId ? 'org_' + insertParentId : '#';
              var data = { orgnztId: d.orgnztId, orgnztNm: nm, orgnztDc: dc,
                           upperOrgnztId: insertParentId || '', ordr: d.ordr, childCnt: 0 };
              var nid = tree().create_node(parent, { id: 'org_' + d.orgnztId, text: nm, data: data }, 'last');
              $('#deptTreeEmpty').hide();
              resetForm();
              if (nid) { focusNode(nid); } else { loadTree('org_' + d.orgnztId); }
            })
            .fail(function() { showMessage('저장 요청 중 오류가 발생했습니다.', false); $('#btnSave').prop('disabled', false); });
        } else {
          var newUpper = $('#fUpper').val() || '';
          var oldUpper = selectedData.upperOrgnztId || '';
          $.post(UPDATE_URL, { orgnztId: selectedData.orgnztId, orgnztNm: nm, orgnztDc: dc, upperOrgnztId: newUpper }, null, 'json')
            .done(function(d) {
              if (d && d.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
              if (!(d && d.success)) { showMessage((d && d.resultMsg) || '저장 중 오류가 발생했습니다.', false); $('#btnSave').prop('disabled', false); return; }
              showMessage(d.resultMsg || '수정되었습니다.', true);
              var id = nodeId();
              var t = tree();
              var n = t.get_node(id);
              if (n) {
                n.data.orgnztNm = nm;
                n.data.orgnztDc = dc;
                n.data.upperOrgnztId = newUpper;
                n.data.ordr = d.ordr;
                t.rename_node(n, nm);
                if (newUpper !== oldUpper) {
                  t.move_node(id, newUpper ? 'org_' + newUpper : '#', 'last');
                }
                selectedData = n.data;
                resetForm();
                focusNode(id);
              } else {
                resetForm();
                loadTree(id);
              }
            })
            .fail(function() { showMessage('저장 요청 중 오류가 발생했습니다.', false); $('#btnSave').prop('disabled', false); });
        }
      }

      function deleteSelected() {
        if (!hasSel()) return;
        var cnt = childCntOf(nodeId());
        if (cnt > 0) { showMessage('하위 부서가 있어 삭제할 수 없습니다. 하위 부서를 먼저 이동/삭제하세요.', false); return; }
        if (!confirm('부서 [' + selectedData.orgnztNm + '] 을(를) 삭제하시겠습니까?\n\n※ 이 부서를 참조하는 사용자·사건이 있으면 표시가 깨질 수 있습니다.')) return;
        $.post(DELETE_URL, { orgnztId: selectedData.orgnztId }, null, 'json')
          .done(function(d) {
            if (d && d.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
            if (!(d && d.success)) { showMessage((d && d.resultMsg) || '삭제 중 오류가 발생했습니다.', false); return; }
            showMessage(d.resultMsg || '삭제되었습니다.', true);
            var t = tree();
            var id = nodeId();
            var parent = selectedData.upperOrgnztId ? 'org_' + selectedData.upperOrgnztId : null;
            if (t.get_node(id)) {
              t.delete_node(id);
              clearSelection();
              if (parent && t.get_node(parent)) { focusNode(parent); }
            } else {
              clearSelection();
              loadTree();
            }
          })
          .fail(function() { showMessage('삭제 요청 중 오류가 발생했습니다.', false); });
      }

      <%-- 순서 이동 — DB 저장 성공 후 트리 리로드(선택 유지). 부분 move 는 동일부모
           인덱스 보정이 미묘해 정본(DB 정렬) 재조회로 확실하게 맞춘다. --%>
      function reorder(dir) {
        if (!hasSel()) return;
        var keep = nodeId();
        $('#btnUp, #btnDown').prop('disabled', true);
        $.post(REORDER_URL, { orgnztId: selectedData.orgnztId, dir: dir }, null, 'json')
          .done(function(d) {
            if (d && d.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
            if (!(d && d.success)) { showMessage((d && d.resultMsg) || '순서 변경 중 오류가 발생했습니다.', false); setToolbarState(); return; }
            showMessage(d.resultMsg || '순서를 변경했습니다.', true);
            loadTree(keep);
          })
          .fail(function() { showMessage('순서 변경 요청 중 오류가 발생했습니다.', false); setToolbarState(); });
      }

      function focusNode(id) {
        var t = tree();
        t.deselect_all(true);
        if (t._open_to) t._open_to(id);
        t.select_node(id);
        var el = t.get_node(id, true);
        if (el && el.length && el[0].scrollIntoView) el[0].scrollIntoView({ block: 'nearest' });
      }

      function clearSelection() {
        selectedNode = null;
        selectedData = {};
        $('#selNm').text('(선택 없음)');
        $('#selId, #selUpper, #selOrdr, #selDc, #selChildCnt').text('-');
        setToolbarState();
        resetForm();
      }

      function showMessage(msg, ok) {
        $('#deptMessage').html('<div class="krds-alert ' + (ok ? 'success' : 'error') + '"></div>');
        $('#deptMessage .krds-alert').text(msg);
      }

      function dash(v) { return (v === null || v === undefined || v === '') ? '-' : v; }
      function esc(s) { return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
    });
  </script>
</lay:layout>
