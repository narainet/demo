<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/sym/ccm/cca/EgovCcmCodeTree.jsp

  공통코드 통합 관리 화면 — 분류 트리 관리(cateTree.jsp)와 동일 골격.
  좌측 jsTree(코드그룹 > 상세코드) + 우측 선택 정보/편집 폼. eGov 표준
  공통코드/공통상세코드 분할 화면(cca/cde) 폐기 대체(2026-07-08).
  저장/삭제는 트리 부분 갱신(create/rename/delete_node) — 전체 리로드는 펼침/스크롤/
  작업 위치를 잃으므로 폴백(노드 부재)에서만 사용(2026-07-08 사용자 지적 반영).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">공통코드관리</c:set>
<c:set var="pageHead">
  
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css'/>"/>
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js'/>"></script>
  <style>
    .code-layout { display: flex; gap: 20px; align-items: stretch; }
    .code-tree-pane { flex: 0 0 420px; border: 1px solid #d1d3d8; padding: 14px; min-height: 560px; border-radius: 6px; background: #fff; overflow: auto; }
    .code-info-pane { flex: 1; border: 1px solid #d1d3d8; padding: 14px; min-height: 560px; border-radius: 6px; background: #fff; }
    .code-info-pane h3 { margin: 0 0 12px; color: #1f3974; }
    .code-empty { color: #666; padding: 12px 0; }
    .code-message { margin-bottom: 12px; }
    .code-detail { margin: 0 0 16px; padding: 12px; background: #f7f8fb; border: 1px solid #e1e4ea; border-radius: 6px; }
    .code-detail dl { display: grid; grid-template-columns: 110px 1fr; gap: 8px 12px; margin: 0; }
    .code-detail dt { color: #555; }
    .code-detail dd { margin: 0; font-weight: 600; word-break: break-all; }
    .code-toolbar { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 18px; }
    .code-form { border-top: 1px solid #e1e4ea; padding-top: 16px; }
    .code-form-row { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
    .code-form-row label { flex: 0 0 110px; font-weight: 600; color: #333; }
    .code-form-row input[type="text"],
    .code-form-row select { width: 100%; max-width: 420px; height: 36px; border: 1px solid #c9ced8; border-radius: 4px; padding: 0 10px; box-sizing: border-box; }
    .code-form-row input[readonly] { background: #f3f4f7; color: #555; }
    .code-form-actions { display: flex; gap: 8px; margin-left: 122px; }
    .code-help { margin: 0 0 12px 122px; color: #666; }
    /* 미사용 코드 — 트리에서 흐리게 */
    #codeTree .code-node-off { color: #9aa0ab; }
    @media (max-width: 900px) {
      .code-layout { flex-direction: column; }
      .code-tree-pane { flex-basis: auto; min-height: 360px; }
      .code-info-pane { min-height: 0; }
      .code-form-row { display: block; }
      .code-form-row label { display: block; margin-bottom: 6px; }
      .code-form-actions,
      .code-help { margin-left: 0; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <c:url var="treeJsonUrl" value="/sym/ccm/cca/codeTreeJson.do"/>
  <c:url var="loginUrl" value="/uat/uia/egovLoginUsr.do"/>

  <div class="page-header">
    <h1>공통코드관리</h1>
    <p class="page-desc">공통코드 그룹과 상세코드를 한 화면에서 관리합니다. 좌측 트리에서 항목을 선택하세요.</p>
  </div>

  <div id="codeMessage" class="code-message">
    <c:if test="${not empty resultMsg}">
      <div class="krds-alert info"><c:out value="${resultMsg}"/></div>
    </c:if>
  </div>

  <div class="code-layout">
    <div class="code-tree-pane">
      <div id="codeTree"></div>
      <div id="codeTreeEmpty" class="code-empty" style="display:none;">등록된 공통코드가 없습니다.</div>
    </div>
    <div class="code-info-pane">
      <h3>선택한 코드</h3>
      <div class="code-detail">
        <dl>
          <dt>종류</dt>
          <dd id="selKind">(선택 없음)</dd>
          <dt>코드그룹 ID</dt>
          <dd id="selCodeId">-</dd>
          <dt>상세코드</dt>
          <dd id="selCode">-</dd>
          <dt>이름</dt>
          <dd id="selNm">-</dd>
          <dt>순번</dt>
          <dd id="selSeq">-</dd>
          <dt>설명</dt>
          <dd id="selDc">-</dd>
          <dt>사용 여부</dt>
          <dd id="selUseAt">-</dd>
          <dt>상세코드 수</dt>
          <dd id="selDetailCnt">-</dd>
        </dl>
      </div>

      <div class="code-toolbar">
        <button type="button" id="btnAddGroup" class="krds-btn medium">코드그룹 추가</button>
        <button type="button" id="btnAddDetail" class="krds-btn medium" disabled>상세코드 추가</button>
        <button type="button" id="btnEdit" class="krds-btn medium" disabled>수정</button>
        <button type="button" id="btnDelete" class="krds-btn danger medium" disabled>삭제</button>
      </div>

      <form id="codeEditForm" class="code-form" onsubmit="return false;">
        <input type="hidden" id="formMode" value=""/>

        <p id="formHelp" class="code-help">항목을 선택한 뒤 추가/수정을 선택하세요. 상세코드 값은 다른 화면·데이터에서 참조되므로 변경/삭제에 주의하세요.</p>

        <div class="code-form-row">
          <label for="fCodeId">코드그룹 ID</label>
          <input type="text" id="fCodeId" maxlength="20" disabled/>
        </div>
        <div class="code-form-row" id="rowCode" style="display:none;">
          <label for="fCode">상세코드</label>
          <input type="text" id="fCode" maxlength="20" disabled/>
        </div>
        <div class="code-form-row">
          <label for="fNm" id="lblNm">코드그룹명</label>
          <input type="text" id="fNm" maxlength="60" disabled/>
        </div>
        <div class="code-form-row" id="rowSeq" style="display:none;">
          <label for="fSeq">순번</label>
          <input type="text" id="fSeq" maxlength="3" inputmode="numeric" placeholder="그룹 내 표시 순서 — 비우면 마지막" disabled/>
        </div>
        <div class="code-form-row">
          <label for="fDc">설명</label>
          <input type="text" id="fDc" maxlength="200" disabled/>
        </div>
        <div class="code-form-row">
          <label for="fUseAt">사용 여부</label>
          <select id="fUseAt" disabled>
            <option value="Y">사용</option>
            <option value="N">미사용</option>
          </select>
        </div>
        <div class="code-form-actions">
          <button type="button" id="btnSave" class="krds-btn primary medium" disabled>저장</button>
          <button type="button" id="btnCancel" class="krds-btn medium" disabled>취소</button>
        </div>
      </form>
    </div>
  </div>

  <script>
    var TREE_JSON_URL = '<c:out value="${treeJsonUrl}"/>';
    var LOGIN_URL = '<c:out value="${loginUrl}"/>';
    var INSERT_CODE_URL   = '<c:url value="/sym/ccm/cca/insertCodeAjax.do"/>';
    var UPDATE_CODE_URL   = '<c:url value="/sym/ccm/cca/updateCodeAjax.do"/>';
    var DELETE_CODE_URL   = '<c:url value="/sym/ccm/cca/deleteCodeAjax.do"/>';
    var INSERT_DETAIL_URL = '<c:url value="/sym/ccm/cca/insertDetailAjax.do"/>';
    var UPDATE_DETAIL_URL = '<c:url value="/sym/ccm/cca/updateDetailAjax.do"/>';
    var DELETE_DETAIL_URL = '<c:url value="/sym/ccm/cca/deleteDetailAjax.do"/>';

    $(function() {
      var selectedNode = null;
      var selectedData = {};

      loadTree();
      resetForm();

      function bindTreeSelectionEvent() {
        $('#codeTree').off('select_node.jstree');
        $('#codeTree').on('select_node.jstree', function(_e, sel) {
          selectedNode = sel.node;
          selectedData = selectedNode.data || {};
          renderSelected();
          setToolbarState();
          resetForm();
        });
      }

      function loadTree(keepNodeId) {
        $('#codeTreeEmpty').hide();
        var inst = $('#codeTree').jstree(true);
        if (inst) { inst.destroy(); }
        $('#codeTree').empty();

        $.getJSON(TREE_JSON_URL)
          .done(function(data) {
            if (data && data.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
            var nodes = (data && data.resultList) ? data.resultList : [];
            if (nodes.length === 0) { $('#codeTreeEmpty').show(); }
            bindTreeSelectionEvent();
            $('#codeTree').jstree({
              core: { data: nodes, themes: { name: 'default', dots: true, icons: true }, check_callback: true }
            }).one('ready.jstree', function() {
              if (keepNodeId) { $('#codeTree').jstree('select_node', keepNodeId); }
            });
          })
          .fail(function() {
            showMessage('공통코드 트리를 불러오지 못했습니다.', false);
            $('#codeTreeEmpty').text('공통코드 트리를 불러오지 못했습니다.').show();
          });
      }

      function isGroup()  { return selectedData.nodeType === 'code'; }
      function isDetail() { return selectedData.nodeType === 'detail'; }

      function renderSelected() {
        if (isGroup()) {
          $('#selKind').text('코드그룹');
          $('#selCodeId').text(dash(selectedData.codeId));
          $('#selCode').text('-');
          $('#selNm').text(dash(selectedData.codeIdNm));
          $('#selSeq').text('-');
          $('#selDc').text(dash(selectedData.codeIdDc));
          $('#selUseAt').text(useAtLabel(selectedData.useAt));
          $('#selDetailCnt').text(num(selectedData.detailCnt));
        } else if (isDetail()) {
          var p = splitDc(selectedData.codeDc);
          $('#selKind').text('상세코드');
          $('#selCodeId').text(dash(selectedData.codeId));
          $('#selCode').text(dash(selectedData.code));
          $('#selNm').text(dash(selectedData.codeNm));
          $('#selSeq').text(dash(p.seq));
          $('#selDc').text(dash(p.desc));
          $('#selUseAt').text(useAtLabel(selectedData.useAt));
          $('#selDetailCnt').text('-');
        }
      }

      <%-- ── 순번 규약: ccm 엔 정렬 컬럼이 없어 CODE_DC 를 'NN_설명' 으로 조립해
           정렬키로 쓴다(소비 쿼리 selectCmmnCodeList 가 ORDER BY CODE_DC).
           화면에선 순번/설명을 분리 입력받고 저장 시 조립, 조회 시 분해. ── --%>
      function splitDc(dc) {
        if (dc === null || dc === undefined || dc === '') return { seq: '', desc: '' };
        var m = /^(\d{1,3})(?:_(.*))?$/.exec(String(dc));
        if (m) return { seq: String(parseInt(m[1], 10)), desc: m[2] || '' };
        return { seq: '', desc: String(dc) };
      }

      function composeDc(seq, desc) {
        if (seq === '') return desc;
        var n = parseInt(seq, 10);
        var p = (n < 10 ? '0' + n : String(n));
        return desc ? (p + '_' + desc) : p;
      }

      <%-- 그룹 내 형제들의 최대 순번 + 1 (아무도 순번이 없으면 빈값) --%>
      function nextSeq(codeId) {
        var t = tree(); var g = t && t.get_node('code_' + codeId);
        var kids = (g && g.children) || [];
        var max = 0, found = false;
        for (var i = 0; i < kids.length; i++) {
          var kd = (t.get_node(kids[i]) || {}).data || {};
          var s = splitDc(kd.codeDc).seq;
          if (s !== '') { found = true; max = Math.max(max, parseInt(s, 10)); }
        }
        return found ? String(max + 1) : '';
      }

      function setToolbarState() {
        $('#btnAddDetail').prop('disabled', !(isGroup() || isDetail()));
        $('#btnEdit').prop('disabled', !(isGroup() || isDetail()));
        $('#btnDelete').prop('disabled', !(isGroup() || isDetail()));
      }

      $('#btnAddGroup').on('click', function() { beginInsertGroup(); });
      $('#btnAddDetail').on('click', function() { if (isGroup() || isDetail()) beginInsertDetail(); });
      $('#btnEdit').on('click', function() {
        if (isGroup()) beginUpdateGroup();
        else if (isDetail()) beginUpdateDetail();
      });
      $('#btnDelete').on('click', function() { deleteSelected(); });
      $('#btnSave').on('click', function() { saveForm(); });
      $('#btnCancel').on('click', function() { resetForm(); });

      function beginInsertGroup() {
        enableForm('insertCode');
        $('#formHelp').text('새 코드그룹을 등록합니다. (예: faqCode)');
        $('#lblNm').text('코드그룹명');
        $('#rowCode').hide();
        $('#rowSeq').hide();
        $('#fCodeId').val('').prop('readonly', false).focus();
        $('#fCode').val('');
        $('#fNm').val('');
        $('#fSeq').val('');
        $('#fDc').val('');
        $('#fUseAt').val('Y');
      }

      function beginInsertDetail() {
        enableForm('insertDetail');
        $('#formHelp').text(dash(selectedData.codeId) + ' 그룹에 상세코드를 등록합니다. 순번은 그룹 내 표시 순서입니다(비우면 순번 없는 항목으로 마지막에).');
        $('#lblNm').text('상세코드명');
        $('#rowCode').show();
        $('#rowSeq').show();
        $('#fCodeId').val(selectedData.codeId || '').prop('readonly', true);
        $('#fCode').val('').prop('readonly', false).focus();
        $('#fNm').val('');
        $('#fSeq').val(nextSeq(selectedData.codeId));
        $('#fDc').val('');
        $('#fUseAt').val('Y');
      }

      function beginUpdateGroup() {
        enableForm('updateCode');
        $('#formHelp').text('선택한 코드그룹을 수정합니다. (그룹 ID 는 변경 불가)');
        $('#lblNm').text('코드그룹명');
        $('#rowCode').hide();
        $('#rowSeq').hide();
        $('#fCodeId').val(selectedData.codeId || '').prop('readonly', true);
        $('#fNm').val(selectedData.codeIdNm || '').focus();
        $('#fSeq').val('');
        $('#fDc').val(selectedData.codeIdDc || '');
        $('#fUseAt').val(selectedData.useAt === 'N' ? 'N' : 'Y');
      }

      function beginUpdateDetail() {
        enableForm('updateDetail');
        $('#formHelp').text('선택한 상세코드를 수정합니다. (코드 값은 변경 불가) 순번은 그룹 내 표시 순서입니다.');
        $('#lblNm').text('상세코드명');
        $('#rowCode').show();
        $('#rowSeq').show();
        var p = splitDc(selectedData.codeDc);
        $('#fCodeId').val(selectedData.codeId || '').prop('readonly', true);
        $('#fCode').val(selectedData.code || '').prop('readonly', true);
        $('#fNm').val(selectedData.codeNm || '').focus();
        $('#fSeq').val(p.seq);
        $('#fDc').val(p.desc);
        $('#fUseAt').val(selectedData.useAt === 'N' ? 'N' : 'Y');
      }

      function enableForm(mode) {
        $('#formMode').val(mode);
        $('#fCodeId, #fCode, #fNm, #fSeq, #fDc, #fUseAt').prop('disabled', false);
        $('#btnSave, #btnCancel').prop('disabled', false);
      }

      function resetForm() {
        $('#formMode').val('');
        $('#formHelp').text('항목을 선택한 뒤 추가/수정을 선택하세요. 상세코드 값은 다른 화면·데이터에서 참조되므로 변경/삭제에 주의하세요.');
        $('#lblNm').text('코드그룹명');
        $('#rowCode').hide();
        $('#rowSeq').hide();
        $('#fCodeId').val('').prop('readonly', false);
        $('#fCode').val('').prop('readonly', false);
        $('#fNm').val('');
        $('#fSeq').val('');
        $('#fDc').val('');
        $('#fUseAt').val('Y');
        $('#fCodeId, #fCode, #fNm, #fSeq, #fDc, #fUseAt').prop('disabled', true);
        $('#btnSave, #btnCancel').prop('disabled', true);
      }

      <%-- ── 부분 갱신 헬퍼 — 저장/삭제 시 트리 전체 리로드 없이 해당 노드만 반영
           (전체 리로드는 펼침 상태·스크롤·작업 위치를 잃음 — 2026-07-08 사용자 지적).
           라벨 조립은 서버(CodeTreeController.label)와 동일 형식 유지. ── --%>
      function tree() { return $('#codeTree').jstree(true); }

      function groupLabel(d) {
        var b = (d.codeIdNm || '(이름없음)') + ' (' + d.codeId + ')';
        if (d.useAt === 'N') b += ' — 미사용';
        return b + ' [' + num(d.detailCnt) + ']';
      }

      function detailLabel(d) {
        var b = (d.codeNm || '(이름없음)') + ' (' + d.code + ')';
        if (d.useAt === 'N') b += ' — 미사용';
        return b;
      }

      function refreshNode(id, label, data) {
        var t = tree(); var n = t.get_node(id);
        if (!n) return false;
        n.data = data;
        n.a_attr = n.a_attr || {};
        n.a_attr['class'] = (data.useAt === 'N') ? 'code-node-off' : '';
        t.rename_node(n, label);
        return true;
      }

      function bumpGroupCnt(codeId, delta) {
        var t = tree(); var g = t.get_node('code_' + codeId);
        if (!g || !g.data) return;
        g.data.detailCnt = num(g.data.detailCnt) + delta;
        t.rename_node(g, groupLabel(g.data));
      }

      <%-- 형제 정렬 위치(그룹=CODE_ID 오름차순 — 트리 JSON 정렬과 동일) --%>
      function sortedPos(parentId, key, isGroup) {
        var t = tree(); var p = t.get_node(parentId);
        var kids = (p && p.children) || [];
        for (var i = 0; i < kids.length; i++) {
          var kd = (t.get_node(kids[i]) || {}).data || {};
          var k = isGroup ? kd.codeId : kd.code;
          if (k && k > key) return i;
        }
        return 'last';
      }

      <%-- 상세 정렬 위치 — CODE_DC(순번) 우선, 없는 것은 뒤로, 동률은 CODE
           (서버 selectDetailListAll 의 ORDER BY CODE_DC NULLS LAST, CODE 와 동일) --%>
      function detailGreater(aDc, aCode, bDc, bCode) {
        var an = (aDc === null || aDc === undefined || aDc === '');
        var bn = (bDc === null || bDc === undefined || bDc === '');
        if (an !== bn) return an;                 <%-- 순번 없는 쪽이 뒤 --%>
        if (!an && aDc !== bDc) return aDc > bDc;
        return (aCode || '') > (bCode || '');
      }

      <%-- 인덱스는 현재 children 원본 배열 기준 — 동일부모 move_node 는 jstree 가
           자체 보정(제거 후 삽입)하므로 자기 자신을 제외하지 않고 계산한다.
           (자신은 데이터가 이미 갱신돼 '같음' 판정 → greater 아님) --%>
      function sortedDetailPos(parentId, dc, code) {
        var t = tree(); var p = t.get_node(parentId);
        var kids = (p && p.children) || [];
        for (var i = 0; i < kids.length; i++) {
          var kd = (t.get_node(kids[i]) || {}).data || {};
          if (detailGreater(kd.codeDc, kd.code, dc, code)) return i;
        }
        return 'last';
      }

      function focusNode(id) {
        var t = tree();
        t.deselect_all(true);
        if (t._open_to) t._open_to(id);
        t.select_node(id);   <%-- select 핸들러가 선택정보 카드 갱신 --%>
        var el = t.get_node(id, true);
        if (el && el.length && el[0].scrollIntoView) el[0].scrollIntoView({ block: 'nearest' });
      }

      function saveForm() {
        var mode = $('#formMode').val();
        if (!mode) return;
        var codeId = $.trim($('#fCodeId').val());
        var code   = $.trim($('#fCode').val());
        var nm     = $.trim($('#fNm').val());
        var dc     = $.trim($('#fDc').val());
        var useAt  = $('#fUseAt').val();

        if (!codeId) { showMessage('코드그룹 ID를 입력하세요.', false); $('#fCodeId').focus(); return; }
        if ((mode === 'insertDetail' || mode === 'updateDetail') && !code) {
          showMessage('상세코드를 입력하세요.', false); $('#fCode').focus(); return;
        }
        if (!nm) { showMessage('이름을 입력하세요.', false); $('#fNm').focus(); return; }

        if (mode === 'insertDetail' || mode === 'updateDetail') {
          var seq = $.trim($('#fSeq').val());
          if (seq !== '' && !/^\d{1,3}$/.test(seq)) {
            showMessage('순번은 1~3자리 숫자만 입력하세요.', false); $('#fSeq').focus(); return;
          }
          dc = composeDc(seq, dc);   <%-- 정렬키 규약: CODE_DC = 'NN_설명' --%>
        }

        var url, payload;
        if (mode === 'insertCode' || mode === 'updateCode') {
          url = (mode === 'insertCode') ? INSERT_CODE_URL : UPDATE_CODE_URL;
          payload = { codeId: codeId, codeIdNm: nm, codeIdDc: dc, useAt: useAt };
        } else {
          url = (mode === 'insertDetail') ? INSERT_DETAIL_URL : UPDATE_DETAIL_URL;
          payload = { codeId: codeId, code: code, codeNm: nm, codeDc: dc, useAt: useAt };
        }

        $('#btnSave').prop('disabled', true);
        $.post(url, payload, null, 'json')
          .done(function(data) {
            if (data && data.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
            if (!(data && data.success)) {
              showMessage((data && data.resultMsg) || '저장 중 오류가 발생했습니다.', false);
              $('#btnSave').prop('disabled', false);
              return;
            }
            showMessage(data.resultMsg || '저장되었습니다.', true);
            applySaveToTree(mode, codeId, code, nm, dc, useAt);
            resetForm();
          })
          .fail(function() {
            showMessage('저장 요청 중 오류가 발생했습니다.', false);
            $('#btnSave').prop('disabled', false);
          });
      }

      <%-- 저장 결과를 트리에 부분 반영 — 실패(노드 부재 등) 시에만 전체 리로드 폴백 --%>
      function applySaveToTree(mode, codeId, code, nm, dc, useAt) {
        var t = tree();
        var ok = true;
        if (mode === 'insertCode') {
          $('#codeTreeEmpty').hide();
          var gd = { nodeType: 'code', codeId: codeId, codeIdNm: nm, codeIdDc: dc, useAt: useAt, detailCnt: 0 };
          var gid = t.create_node('#',
            { id: 'code_' + codeId, text: groupLabel(gd), data: gd,
              a_attr: { 'class': (useAt === 'N') ? 'code-node-off' : '' } },
            sortedPos('#', codeId, true));
          ok = !!gid; if (ok) focusNode(gid);
        } else if (mode === 'updateCode') {
          var g = t.get_node('code_' + codeId);
          var cnt = (g && g.data) ? num(g.data.detailCnt) : 0;
          var gd2 = { nodeType: 'code', codeId: codeId, codeIdNm: nm, codeIdDc: dc, useAt: useAt, detailCnt: cnt };
          ok = refreshNode('code_' + codeId, groupLabel(gd2), gd2);
          if (ok) focusNode('code_' + codeId);
        } else if (mode === 'insertDetail') {
          var dd = { nodeType: 'detail', codeId: codeId, code: code, codeNm: nm, codeDc: dc, useAt: useAt };
          var did = t.create_node('code_' + codeId,
            { id: 'det_' + codeId + '__' + code, text: detailLabel(dd), icon: 'jstree-file', data: dd,
              a_attr: { 'class': (useAt === 'N') ? 'code-node-off' : '' } },
            sortedDetailPos('code_' + codeId, dc, code));
          ok = !!did;
          if (ok) { bumpGroupCnt(codeId, 1); focusNode(did); }
        } else {
          var dd2 = { nodeType: 'detail', codeId: codeId, code: code, codeNm: nm, codeDc: dc, useAt: useAt };
          var detId = 'det_' + codeId + '__' + code;
          var dcChanged = (selectedData.codeDc || '') !== (dc || '');
          ok = refreshNode(detId, detailLabel(dd2), dd2);
          if (ok && dcChanged) {   <%-- 순번 변경 → 형제들 사이 재배치 --%>
            t.move_node(detId, 'code_' + codeId, sortedDetailPos('code_' + codeId, dc, code));
          }
          if (ok) focusNode(detId);
        }
        if (!ok) {   <%-- 폴백: 트리 상태가 어긋난 경우만 리로드 --%>
          var keepId = (mode === 'insertCode' || mode === 'updateCode')
            ? 'code_' + codeId : 'det_' + codeId + '__' + code;
          clearSelection();
          loadTree(keepId);
        }
      }

      function deleteSelected() {
        var url, payload, wasDetail, delId, parentGroupId;
        if (isGroup()) {
          var cnt = num(selectedData.detailCnt);
          var msg = '코드그룹 [' + selectedData.codeId + '] 을(를) 삭제하시겠습니까?';
          if (cnt > 0) { msg += '\n하위 상세코드 ' + cnt + '건도 함께 삭제됩니다.'; }
          msg += '\n\n※ 이 코드를 참조하는 화면/데이터가 있으면 표시가 깨질 수 있습니다.';
          if (!confirm(msg)) return;
          url = DELETE_CODE_URL;
          payload = { codeId: selectedData.codeId };
          wasDetail = false;
          delId = 'code_' + selectedData.codeId;
        } else if (isDetail()) {
          if (!confirm('상세코드 [' + selectedData.code + '] 을(를) 삭제하시겠습니까?\n\n※ 이 코드를 참조하는 화면/데이터가 있으면 표시가 깨질 수 있습니다.')) return;
          url = DELETE_DETAIL_URL;
          payload = { codeId: selectedData.codeId, code: selectedData.code };
          wasDetail = true;
          delId = 'det_' + selectedData.codeId + '__' + selectedData.code;
          parentGroupId = 'code_' + selectedData.codeId;
        } else {
          return;
        }

        $.post(url, payload, null, 'json')
          .done(function(data) {
            if (data && data.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
            if (!(data && data.success)) {
              showMessage((data && data.resultMsg) || '삭제 중 오류가 발생했습니다.', false);
              return;
            }
            showMessage(data.resultMsg || '삭제되었습니다.', true);
            <%-- 부분 갱신: 해당 노드만 제거. 상세 삭제 후엔 부모 그룹 선택 유지 → 작업 위치 보존 --%>
            var t = tree();
            if (t && t.get_node(delId)) {
              var groupCodeId = payload.codeId;
              t.delete_node(delId);
              if (wasDetail) {
                bumpGroupCnt(groupCodeId, -1);
                focusNode(parentGroupId);
              } else {
                clearSelection();
              }
            } else {
              clearSelection();
              loadTree();
            }
          })
          .fail(function() { showMessage('삭제 요청 중 오류가 발생했습니다.', false); });
      }

      function clearSelection() {
        selectedNode = null;
        selectedData = {};
        $('#selKind').text('(선택 없음)');
        $('#selCodeId, #selCode, #selNm, #selSeq, #selDc, #selUseAt, #selDetailCnt').text('-');
        setToolbarState();
        resetForm();
      }

      function showMessage(msg, ok) {
        $('#codeMessage').html('<div class="krds-alert ' + (ok ? 'success' : 'error') + '"></div>');
        $('#codeMessage .krds-alert').text(msg);
      }

      function dash(v) { return (v === null || v === undefined || v === '') ? '-' : v; }
      function num(v) { var n = parseInt(v, 10); return isNaN(n) ? 0 : n; }
      function useAtLabel(v) { return v === 'N' ? '미사용' : '사용'; }
    });
  </script>
</lay:layout>
