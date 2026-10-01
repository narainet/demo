<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/cate/cateTree.jsp

  분류 트리 관리 화면. jsTree 기반으로 분류 조회/등록/수정/삭제를 제공한다.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- ※ manage=Y 는 c:param 로 넣지 말 것 — TREE_JSON_URL 이 c:out 경유라 '&'가 '&amp;'로
       이스케이프되어 파라미터명이 깨짐(amp;manage). loadTree() 의 AJAX data 로 전달. --%>
<%-- 단일 시스템 — sysId(SSYS_ID) 파라미터 미전송 (selectCateTreeJson 이 필터에 미사용) --%>
<c:set var="pageTitle">분류관리</c:set>
<c:set var="pageHead">
  
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css'/>"/>
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js'/>"></script>
  <style>
    .cate-layout { display: flex; gap: 20px; align-items: stretch; }
    .cate-tree-pane { flex: 0 0 380px; border: 1px solid #d1d3d8; padding: 14px; min-height: 560px; border-radius: 6px; background: #fff; }
    .cate-info-pane { flex: 1; border: 1px solid #d1d3d8; padding: 14px; min-height: 560px; border-radius: 6px; background: #fff; }
    .cate-info-pane h3 { margin: 0 0 12px; color: #1f3974; }
    .cate-empty { color: #666; padding: 12px 0; }
    .cate-message { margin-bottom: 12px; }
    .cate-detail { margin: 0 0 16px; padding: 12px; background: #f7f8fb; border: 1px solid #e1e4ea; border-radius: 6px; }
    .cate-detail dl { display: grid; grid-template-columns: 110px 1fr; gap: 8px 12px; margin: 0; }
    .cate-detail dt { color: #555; }
    .cate-detail dd { margin: 0; font-weight: 600; word-break: break-all; }
    .cate-toolbar { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 18px; }
    .cate-form { border-top: 1px solid #e1e4ea; padding-top: 16px; }
    .cate-form-row { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
    .cate-form-row label { flex: 0 0 110px; font-weight: 600; color: #333; }
    .cate-form-row input[type="text"],
    .cate-form-row input[type="number"],
    .cate-form-row select { width: 100%; max-width: 420px; height: 36px; border: 1px solid #c9ced8; border-radius: 4px; padding: 0 10px; box-sizing: border-box; }
    .cate-form-row input[readonly] { background: #f3f4f7; color: #555; }
    .cate-form-actions { display: flex; gap: 8px; margin-left: 122px; }
    .cate-help { margin: 0 0 12px 122px; color: #666; }
    @media (max-width: 900px) {
      .cate-layout { flex-direction: column; }
      .cate-tree-pane { flex-basis: auto; min-height: 360px; }
      .cate-info-pane { min-height: 0; }
      .cate-form-row { display: block; }
      .cate-form-row label { display: block; margin-bottom: 6px; }
      .cate-form-actions,
      .cate-help { margin-left: 0; }
    }

    /* 작성자 관리 모달 */
    .owner-add { display:flex; flex-wrap:wrap; align-items:center; gap:14px; border:1px solid #e3e6ec; background:#f9fafc; border-radius:6px; padding:12px 14px; margin-bottom:16px; }
    .owner-add label { display:flex; align-items:center; gap:6px; font-weight:600; color:#333; margin:0; }
    .owner-add select, .owner-add input[type=text] { height:34px; border:1px solid #c4c6cd; border-radius:5px; padding:0 10px; box-sizing:border-box; }
    .owner-add input[type=text] { width:240px; }
    table.owner-tbl { width:100%; border-collapse:collapse; }
    table.owner-tbl th, table.owner-tbl td { border:1px solid #e0e0e0; padding:8px 10px; text-align:left; font-size:14px; }
    table.owner-tbl th { background:#f5f6f8; }
    .owner-tag { display:inline-block; padding:1px 8px; border-radius:10px; font-size:12px; }
    .owner-tag-dept { background:#e6f0ff; color:#1b5fbf; }
    .owner-tag-user { background:#eaf7ec; color:#2a7d3a; }
    .owner-muted { color:#888; font-size:13px; }
  /* 인라인 스타일 정리 (2026-06-11) */
  .owner-intro { margin:0 0 14px; line-height:1.6; }
  .owner-intro strong { color:#1f3974; }
  .owner-modal-close-btn { margin-left:auto; }
  /* 권한 관리 모달 탭 — 작성자(수정권한) / 열람 제한 (2026-07-07 read 축 신설) */
  .owner-tabs { display:flex; gap:0; border-bottom:2px solid #d7dae2; margin:0 0 16px; }
  .owner-tab { border:none; background:none; padding:9px 18px; font-size:15px; font-weight:600;
               color:#777; cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-2px; }
  .owner-tab.on { color:#1f3974; border-bottom-color:#1f3974; }
  /* 개인 대상 사용자 검색(이름/로그인ID) 결과 목록 */
  .user-pick { border:1px solid #d7dae2; border-radius:6px; background:#fff; margin:-8px 0 14px;
               max-height:180px; overflow-y:auto; }
  .user-pick .up-item { display:block; width:100%; text-align:left; border:none; background:none;
               padding:7px 12px; font-size:14px; cursor:pointer; border-bottom:1px solid #f0f1f4; }
  .user-pick .up-item:hover { background:#eef3fb; }
  .user-pick .up-empty { padding:10px 12px; color:#888; font-size:13px; }
  .gubun-notice { border:1px solid #e3e6ec; background:#f9fafc; border-radius:6px;
               padding:14px 16px; color:#555; line-height:1.7; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <c:url var="treeJsonUrl" value="/rlms/cate/selectCateTreeJson.do"/>
  <c:url var="insertAjaxUrl" value="/rlms/cate/insertCateAjax.do"/>
  <c:url var="updateAjaxUrl" value="/rlms/cate/updateCateAjax.do"/>
  <c:url var="deleteAjaxUrl" value="/rlms/cate/deleteCateAjax.do"/>
  <c:url var="loginUrl" value="/uat/uia/egovLoginUsr.do"/>

  <div class="page-header">
    <h1>분류관리</h1>
  </div>

  <div id="cateMessage" class="cate-message">
    <c:if test="${not empty resultMsg}">
      <div class="krds-alert info"><c:out value="${resultMsg}"/></div>
    </c:if>
  </div>

  <div class="cate-layout">
    <div class="cate-tree-pane">
      <div id="cateTree"></div>
      <div id="cateTreeEmpty" class="cate-empty" style="display:none;">등록된 분류가 없습니다.</div>
    </div>
    <div class="cate-info-pane">
      <h3>선택한 분류</h3>
      <div class="cate-detail">
        <dl>
          <dt>분류명</dt>
          <dd id="selCateNm">(선택 없음)</dd>
          <dt>분류 번호</dt>
          <dd id="selCateNo">-</dd>
          <dt>구분 ID</dt>
          <dd id="selGubunId">-</dd>
          <dt>전체 경로</dt>
          <dd id="selFullNm">-</dd>
          <dt>표시 여부</dt>
          <dd id="selDispYn">-</dd>
          <dt>규정 수</dt>
          <dd id="selPromCnt">0</dd>
          <dt>하위 분류 수</dt>
          <dd id="selChildCnt">0</dd>
        </dl>
      </div>

      <div class="cate-toolbar">
        <button type="button" id="btnAddGubun" class="krds-btn medium">구분 추가</button>
        <button type="button" id="btnAddChild" class="krds-btn medium" disabled>하위 분류 추가</button>
        <button type="button" id="btnEdit" class="krds-btn medium" disabled>수정</button>
        <button type="button" id="btnDelete" class="krds-btn danger medium" disabled>삭제</button>
        <button type="button" id="btnOwner" class="krds-btn medium" disabled>권한 관리</button>
      </div>

      <form id="cateEditForm" class="cate-form">
        <input type="hidden" id="formMode" value=""/>
        <input type="hidden" id="nodeType" name="nodeType"/>
        <input type="hidden" id="sysId" name="sysId" value="<c:out value='${sysId}'/>"/>
        <input type="hidden" id="cateNo" name="cateNo"/>
        <input type="hidden" id="ref" name="ref"/>
        <c:if test="${not empty _csrf}">
          <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
        </c:if>

        <p id="formHelp" class="cate-help">분류를 선택한 뒤 하위 분류 추가 또는 수정을 선택하세요.</p>

        <div class="cate-form-row">
          <label for="cateNm">분류명</label>
          <input type="text" id="cateNm" name="cateNm" maxlength="200" disabled/>
        </div>
        <div class="cate-form-row">
          <label for="gubunId">구분 ID</label>
          <input type="text" id="gubunId" name="gubunId" maxlength="50" disabled/>
        </div>
        <div class="cate-form-row">
          <label for="seq">정렬 순서</label>
          <input type="number" id="seq" name="seq" min="0" disabled/>
        </div>
        <div class="cate-form-row">
          <label for="dispYn">표시 여부</label>
          <select id="dispYn" name="dispYn" disabled>
            <option value="Y">표시</option>
            <option value="N">숨김</option>
          </select>
        </div>
        <div class="cate-form-actions">
          <button type="button" id="btnSave" class="krds-btn primary medium" disabled>저장</button>
          <button type="button" id="btnCancel" class="krds-btn medium" disabled>취소</button>
        </div>
      </form>
    </div>
  </div>

  <!-- 권한 관리 모달 — [작성자(수정권한)] / [열람 제한] 2탭 -->
  <div id="ownerModal" class="ide-modal" style="display:none;">
    <div class="ide-modal-box ide-modal-box--wide">
      <div class="ide-modal-head">
        <h3>분류 권한 관리</h3>
        <button type="button" class="ide-modal-close" id="ownerModalClose" aria-label="닫기">&times;</button>
      </div>
      <div class="ide-modal-body">
        <p class="owner-muted owner-intro">
          분류: <strong id="ownerCateNm">-</strong>
        </p>

        <div class="owner-tabs">
          <button type="button" class="owner-tab on" id="ownerTabEdit">작성자(작성권한)</button>
          <button type="button" class="owner-tab" id="ownerTabRead">열람 제한</button>
        </div>

        <div id="ownerPane">
        <%-- 구분(최상위) 노드 선택 시 — 작성권한은 분류 단위만 지원 --%>
        <div id="ownerGubunNotice" class="gubun-notice" style="display:none;">
          구분(최상위) 단위 <strong>작성권한</strong>은 지원하지 않습니다.<br/>
          작성자는 하위 <strong>분류를 선택</strong>해 지정하세요. (열람 제한은 [열람 제한] 탭에서 구분 단위로 지정 가능)
        </div>
        <div id="ownerCateControls">
        <p class="owner-muted owner-intro">
          관리자는 모든 규정을 수정할 수 있으며, 여기서 지정된 작성자는 해당 분류(상속 시 하위 포함)의 규정을 수정할 수 있습니다.
        </p>

        <div class="owner-add">
          <label>유형
            <select id="ownerTy">
              <option value="DEPT">부서</option>
              <option value="USER">개인</option>
            </select>
          </label>
          <label id="ownerDeptWrap">부서
            <select id="ownerDeptSel"><option value="">(로딩중…)</option></select>
          </label>
          <label id="ownerUserWrap" style="display:none;">사용자
            <input type="text" id="ownerUserKw" placeholder="이름/로그인ID 검색 후 선택"/>
            <button type="button" class="krds-btn medium" id="ownerUserSearchBtn">검색</button>
          </label>
          <label><input type="checkbox" id="ownerInherit" checked/> 하위분류 상속</label>
          <button type="button" class="krds-btn primary medium" id="ownerAdd">추가</button>
        </div>
        <div id="ownerUserPick" class="user-pick" style="display:none;"></div>

        <table class="owner-tbl">
          <thead>
            <tr>
              <th style="width:90px;">유형</th>
              <th>대상</th>
              <th style="width:80px;">상속</th>
              <th style="width:80px;">삭제</th>
            </tr>
          </thead>
          <tbody id="ownerBody">
            <tr><td colspan="4" class="owner-muted">로딩중…</td></tr>
          </tbody>
        </table>
        </div><%-- /ownerCateControls --%>
        </div>

        <div id="readerPane" style="display:none;">
        <p class="owner-muted owner-intro">
          열람 제한 대상을 지정하면 해당 분류(상속 시 하위 포함)의 규정은 지정된 부서/개인만 열람할 수 있습니다.<br/>
          <strong>아무도 지정하지 않으면 전체 공개</strong>이며, 관리자·편집자·승인자는 항상 열람할 수 있습니다.
        </p>

        <div class="owner-add">
          <label>유형
            <select id="readerTy">
              <option value="DEPT">부서</option>
              <option value="USER">개인</option>
            </select>
          </label>
          <label id="readerDeptWrap">부서
            <select id="readerDeptSel"><option value="">(로딩중…)</option></select>
          </label>
          <label id="readerUserWrap" style="display:none;">사용자
            <input type="text" id="readerUserKw" placeholder="이름/로그인ID 검색 후 선택"/>
            <button type="button" class="krds-btn medium" id="readerUserSearchBtn">검색</button>
          </label>
          <label id="readerInheritWrap"><input type="checkbox" id="readerInherit" checked/> 하위분류 상속</label>
          <button type="button" class="krds-btn primary medium" id="readerAdd">추가</button>
        </div>
        <div id="readerUserPick" class="user-pick" style="display:none;"></div>

        <table class="owner-tbl">
          <thead>
            <tr>
              <th style="width:90px;">유형</th>
              <th>대상</th>
              <th style="width:80px;">상속</th>
              <th style="width:80px;">삭제</th>
            </tr>
          </thead>
          <tbody id="readerBody">
            <tr><td colspan="4" class="owner-muted">로딩중…</td></tr>
          </tbody>
        </table>
        </div>

        <div class="ide-modal-actions">
          <button type="button" class="krds-btn medium owner-modal-close-btn" id="ownerModalCancel">닫기</button>
        </div>
      </div>
    </div>
  </div>

  <script>
    var TREE_JSON_URL = '<c:out value="${treeJsonUrl}"/>';
    var INSERT_AJAX_URL = '<c:out value="${insertAjaxUrl}"/>';
    var UPDATE_AJAX_URL = '<c:out value="${updateAjaxUrl}"/>';
    var DELETE_AJAX_URL = '<c:out value="${deleteAjaxUrl}"/>';
    var INSERT_GUBUN_URL = '<c:url value="/rlms/cate/insertGubunAjax.do"/>';
    var UPDATE_GUBUN_URL = '<c:url value="/rlms/cate/updateGubunAjax.do"/>';
    var DELETE_GUBUN_URL = '<c:url value="/rlms/cate/deleteGubunAjax.do"/>';
    var LOGIN_URL = '<c:out value="${loginUrl}"/>';
    var OWNER_LIST_URL   = '<c:url value="/rlms/cate/ownerListJson.do"/>';
    var OWNER_DEPTS_URL  = '<c:url value="/rlms/cate/ownerDeptOptions.do"/>';
    var OWNER_INSERT_URL = '<c:url value="/rlms/cate/ownerInsert.do"/>';
    var OWNER_DELETE_URL = '<c:url value="/rlms/cate/ownerDelete.do"/>';
    var READER_LIST_URL   = '<c:url value="/rlms/cate/readerListJson.do"/>';
    var READER_INSERT_URL = '<c:url value="/rlms/cate/readerInsert.do"/>';
    var READER_DELETE_URL = '<c:url value="/rlms/cate/readerDelete.do"/>';
    var READER_GUBUN_LIST_URL   = '<c:url value="/rlms/cate/readerGubunListJson.do"/>';
    var READER_GUBUN_INSERT_URL = '<c:url value="/rlms/cate/readerGubunInsert.do"/>';
    var READER_GUBUN_DELETE_URL = '<c:url value="/rlms/cate/readerGubunDelete.do"/>';
    var READER_USER_SEARCH_URL  = '<c:url value="/rlms/cate/readerUserSearch.do"/>';

    $(function() {
      var selectedNode = null;
      var selectedData = {};

      loadTree();
      resetForm();

      function bindTreeSelectionEvent() {
        $('#cateTree').off('select_node.jstree');
        $('#cateTree').on('select_node.jstree', function(_e, sel) {
          selectedNode = sel.node;
          selectedData = selectedNode.data || {};
          renderSelected();
          setToolbarState();
          syncFormToSelection();
        });
      }

      $('#btnAddGubun').on('click', function() {
        beginInsertGubun();
      });

      $('#btnAddChild').on('click', function() {
        if (!selectedData.cateNo && !isGubunSelected()) return;
        beginInsertChild();
      });

      $('#btnEdit').on('click', function() {
        if (isGubunSelected()) { beginUpdateGubun(); return; }   // 구분(최상위) — 이름/순서 수정
        if (!selectedData.cateNo) return;
        beginUpdate();
      });

      $('#btnDelete').on('click', function() {
        deleteSelected();
      });

      $('#btnOwner').on('click', function() {
        if (selectedData.cateNo) {
          openOwnerModal(selectedData.cateNo, selectedData.cateNm, null);
        } else if (isGubunSelected()) {
          // 구분(최상위) 노드 — 열람 제한만 구분 단위 지원 (작성자 탭은 안내)
          openOwnerModal(null, selectedData.gubunNm || (selectedNode ? selectedNode.text : ''), selectedData.gubunId);
        }
      });

      // 권한 관리 모달 (작성자 / 열람 제한 2탭) — 분류(cate) 또는 구분(gubun) 단위
      var ownerCateNo = null;
      var ownerGubunId = null;
      var ownerDeptsLoaded = false;
      var ownerPickedUser = null;   // 사용자 검색 선택 결과 {esntlId, userNm, userId}
      var readerPickedUser = null;

      $('#ownerTy').on('change', toggleOwnerType);
      $('#ownerAdd').on('click', addOwner);
      $('#ownerModalClose, #ownerModalCancel').on('click', closeOwnerModal);
      $('#ownerModal').on('click', function(e) { if (e.target === this) closeOwnerModal(); });
      $('#ownerBody').on('click', '.owner-del', function() {
        delOwner($(this).attr('data-ty'), $(this).attr('data-id'));
      });

      // 열람 제한 탭
      $('#ownerTabEdit').on('click', function() { switchOwnerTab('owner'); });
      $('#ownerTabRead').on('click', function() { switchOwnerTab('reader'); });
      $('#readerTy').on('change', toggleReaderType);
      $('#readerAdd').on('click', addReader);
      $('#readerBody').on('click', '.reader-del', function() {
        delReader($(this).attr('data-ty'), $(this).attr('data-id'));
      });

      // 개인 대상 사용자 검색(이름/로그인ID) — 작성자/열람제한 공용 컴포넌트
      bindUserPicker('owner');
      bindUserPicker('reader');

      function bindUserPicker(prefix) {
        var $kw = $('#' + prefix + 'UserKw');
        $('#' + prefix + 'UserSearchBtn').on('click', function() { runUserSearch(prefix); });
        $kw.on('keydown', function(e) {
          if (e.key === 'Enter') { e.preventDefault(); runUserSearch(prefix); }
        });
        $kw.on('input', function() { setPickedUser(prefix, null); });   // 다시 타이핑 = 선택 해제
        $('#' + prefix + 'UserPick').on('click', '.up-item', function() {
          setPickedUser(prefix, {
            esntlId: $(this).attr('data-esntl'),
            userNm:  $(this).attr('data-nm'),
            userId:  $(this).attr('data-uid')
          });
          $kw.val($(this).attr('data-nm') + ' (' + $(this).attr('data-uid') + ')');
          $('#' + prefix + 'UserPick').hide();
        });
      }

      function setPickedUser(prefix, user) {
        if (prefix === 'owner') { ownerPickedUser = user; } else { readerPickedUser = user; }
      }

      function getPickedUser(prefix) {
        return (prefix === 'owner') ? ownerPickedUser : readerPickedUser;
      }

      function runUserSearch(prefix) {
        var kw = $.trim($('#' + prefix + 'UserKw').val());
        var $box = $('#' + prefix + 'UserPick');
        if (!kw) { $box.hide(); return; }
        $box.html('<div class="up-empty">검색 중…</div>').show();
        $.getJSON(READER_USER_SEARCH_URL, { keyword: kw }).done(function(res) {
          var list = (res && res.resultList) || [];
          if (!list.length) {
            $box.html('<div class="up-empty">일치하는 사용자가 없습니다.</div>');
            return;
          }
          $box.html(list.map(function(u) {
            return '<button type="button" class="up-item" data-esntl="' + escapeHtml(u.esntlId)
              + '" data-uid="' + escapeHtml(u.userId || '') + '" data-nm="' + escapeHtml(u.userNm || '') + '">'
              + escapeHtml(u.userNm || '(이름없음)') + ' <span class="owner-muted">' + escapeHtml(u.userId || '')
              + (u.orgnztNm ? ' · ' + escapeHtml(u.orgnztNm) : '') + '</span></button>';
          }).join(''));
        }).fail(function() { $box.html('<div class="up-empty">검색 요청 중 오류가 발생했습니다.</div>'); });
      }

      $('#btnSave').on('click', function() {
        saveForm();
      });

      $('#btnCancel').on('click', function() {
        resetForm();
      });

      function loadTree(keepCateNo, keepNodeId) {
        $('#cateTreeEmpty').hide();
        var treeInstance = $('#cateTree').jstree(true);
        if (treeInstance) {
          treeInstance.destroy();
        }
        $('#cateTree').empty();

        <%-- manage=Y — 분류관리 화면만 숨김 구분 포함(복구 입구). 서버가 편집계 역할 재검증. --%>
        $.getJSON(TREE_JSON_URL, { manage: 'Y' })
          .done(function(data) {
            if (data && data.resultMsg === 'UNAUTHORIZED') {
              location.href = LOGIN_URL;
              return;
            }
            var nodes = (data && data.resultList) ? data.resultList : [];
            if (nodes.length === 0) {
              $('#cateTreeEmpty').show();
            }
            bindTreeSelectionEvent();
            $('#cateTree').jstree({
              core: {
                data: nodes,
                themes: { name: 'default', dots: true, icons: true },
                check_callback: true
              }
            }).one('ready.jstree', function() {
              if (keepNodeId) {
                $('#cateTree').jstree('select_node', keepNodeId);
              } else if (keepCateNo) {
                $('#cateTree').jstree('select_node', 'cate_' + keepCateNo);
              }
            });
          })
          .fail(function() {
            showMessage('분류 트리를 불러오지 못했습니다.', false);
            $('#cateTreeEmpty').text('분류 트리를 불러오지 못했습니다.').show();
          });
      }

      function renderSelected() {
        if (isGubunSelected()) {
          $('#selCateNm').text(emptyToDash(selectedData.gubunNm || selectedNode.text));
          $('#selCateNo').text('-');
          $('#selGubunId').text(emptyToDash(selectedData.gubunId));
          $('#selFullNm').text('최상위 구분');
          <%-- 구분 = ccm USE_AT — 숨김이면 이 화면 외 전 화면 비노출 --%>
          $('#selDispYn').text(selectedData.useAt === 'N' ? '숨김 (분류관리 외 전 화면 비노출)' : '표시');
          $('#selPromCnt').text('0');
          $('#selChildCnt').text('0');
          return;
        }
        $('#selCateNm').text(emptyToDash(selectedData.cateNm));
        $('#selCateNo').text(emptyToDash(selectedData.cateNo));
        $('#selGubunId').text(emptyToDash(selectedData.gubunId));
        $('#selFullNm').text(emptyToDash(selectedData.fullNm));
        $('#selDispYn').text(selectedData.dispYn === 'N' ? '숨김' : '표시');
        $('#selPromCnt').text(numberOrZero(selectedData.promCnt));
        $('#selChildCnt').text(numberOrZero(selectedData.childCnt));
      }

      function setToolbarState() {
        var hasCateSelection = !!selectedData.cateNo;
        var hasGubunSelection = isGubunSelected();
        $('#btnAddChild').prop('disabled', !(hasCateSelection || hasGubunSelection));
        // 수정/삭제 — 분류 + 구분 (2026-07-09 구분 관리를 공통코드 화면에서 이 화면으로 이관.
        //   구분 삭제는 서버가 참조 검사 — 분류/규정이 쓰는 구분은 차단되어 실사용 구분은 자연 보호)
        $('#btnEdit').prop('disabled', !(hasCateSelection || hasGubunSelection));
        $('#btnDelete').prop('disabled', !(hasCateSelection || hasGubunSelection));
        // 권한 관리 — 분류(작성자+열람제한) / 구분(열람제한만) 모두 진입 가능
        $('#btnOwner').prop('disabled', !(hasCateSelection || hasGubunSelection));
      }

      function beginInsertRoot() {
        enableForm('insert');
        var gubunId = selectedData.gubunId || '';
        var gubunNm = selectedData.gubunNm || (selectedNode ? selectedNode.text : '');
        $('#nodeType').val('cate');
        $('#formHelp').text(emptyToDash(gubunNm) + ' 구분에 루트 분류를 등록합니다.');
        $('#cateNo').val('');
        $('#ref').val('0');
        $('#cateNm').val('').focus();
        $('#gubunId').val(gubunId).prop('readonly', true);
        $('#seq').val('');
        $('#dispYn').val('Y');
      }

      function beginInsertChild() {
        if (isGubunSelected()) {
          beginInsertRoot();
          return;
        }
        enableForm('insert');
        $('#nodeType').val('cate');
        $('#formHelp').text('선택한 분류의 하위 분류를 등록합니다.');
        $('#cateNo').val('');
        $('#ref').val(selectedData.cateNo);
        $('#cateNm').val('').focus();
        $('#gubunId').val(selectedData.gubunId || '').prop('readonly', true);
        $('#seq').val('');
        $('#dispYn').val('Y');
      }

      function isGubunSelected() {
        return selectedData.nodeType === 'gubun'
          || (!!selectedData.gubunId && !selectedData.cateNo
              && selectedNode && (selectedNode.id || '').indexOf('gubun:') === 0);
      }

      // ── 구분(최상위) 관리 — 추가/수정(이름·순서)/삭제. 저장소는 ccm 'SGUBUN'(전 화면 공통 정본),
      //    관리 입구는 이 화면 단일(공통코드 화면은 비노출, 2026-07-09 사용자 확정). ──
      function beginInsertGubun() {
        enableForm('insertGubun');
        $('#nodeType').val('gubun');
        $('#formHelp').text('새 구분(최상위)을 등록합니다. 구분 ID는 자동으로 부여됩니다. '
            + '표시 여부를 [숨김]으로 하면 이 화면을 제외한 전 화면(트리/검색/목록)에서 구분과 소속 규정이 보이지 않습니다.');
        $('#cateNo').val('');
        $('#ref').val('');
        $('#cateNm').val('').focus();
        $('#gubunId').val('(자동 채번)').prop('readonly', true);
        $('#seq').val('');
        $('#dispYn').val('Y');   // 표시 여부 선택 가능 (숨김=전 화면 비노출, 권한 무관)
      }

      function beginUpdateGubun(noFocus) {
        enableForm('updateGubun');
        $('#nodeType').val('gubun');
        $('#formHelp').text('구분(최상위)의 이름/순서/표시 여부를 수정합니다. '
            + '[숨김]이면 이 화면을 제외한 전 화면(트리/검색/목록)에서 구분과 소속 규정이 보이지 않습니다(권한 무관).');
        $('#cateNo').val('');
        $('#ref').val('');
        $('#cateNm').val(selectedData.gubunNm || (selectedNode ? selectedNode.text : ''));
        if (!noFocus) $('#cateNm').focus();
        $('#gubunId').val(selectedData.gubunId || '').prop('readonly', true);
        var m = /^(\d{1,3})_/.exec(String(selectedData.codeDc || ''));
        $('#seq').val(m ? parseInt(m[1], 10) : '');
        $('#dispYn').val(selectedData.useAt === 'N' ? 'N' : 'Y');
      }

      function beginUpdate(noFocus) {
        enableForm('update');
        $('#nodeType').val('cate');
        $('#formHelp').text('선택한 분류를 수정합니다.');
        $('#cateNo').val(selectedData.cateNo || '');
        $('#ref').val(selectedData.ref === null || selectedData.ref === undefined ? '0' : selectedData.ref);
        $('#cateNm').val(selectedData.cateNm || '');
        if (!noFocus) $('#cateNm').focus();
        $('#gubunId').val(selectedData.gubunId || '').prop('readonly', true);
        $('#seq').val(selectedData.seq === null || selectedData.seq === undefined ? '' : selectedData.seq);
        $('#dispYn').val(selectedData.dispYn === 'N' ? 'N' : 'Y');
      }

      /**
       * 트리 선택이 바뀌면 하단 편집 폼도 새 선택으로 재조준한다 (고객 테스트 2026-07-29).
       *  · 수정 중이었으면 새로 선택한 노드 값으로 다시 채운다 — 상단 [선택한 분류] 카드만 바뀌고
       *    하단 폼은 이전 선택 그대로였던 불일치 해소.
       *  · 추가(신규 등록) 중이었으면 폼을 닫는다 — 이전 선택 기준으로 입력하던 값이 남아
       *    엉뚱한 부모 아래에 저장되는 사고를 막는다.
       */
      function syncFormToSelection() {
        var mode = $('#formMode').val();
        if (!mode) return;                       // 폼이 닫힌 상태 — 건드릴 것 없음
        if (mode === 'update' || mode === 'updateGubun') {
          if (isGubunSelected())          beginUpdateGubun(true);
          else if (selectedData.cateNo)   beginUpdate(true);
          else                            resetForm();
          return;
        }
        resetForm();                             // insert / insertGubun / insertRoot
      }

      function enableForm(mode) {
        $('#formMode').val(mode);
        $('#cateNm').prop('disabled', false);
        $('#gubunId').prop('disabled', false);
        $('#seq').prop('disabled', false);
        $('#dispYn').prop('disabled', false);
        $('#btnSave').prop('disabled', false);
        $('#btnCancel').prop('disabled', false);
      }

      function resetForm() {
        $('#formMode').val('');
        $('#nodeType').val('');
        $('#cateNo').val('');
        $('#ref').val('');
        $('#formHelp').text('분류를 선택한 뒤 하위 분류 추가 또는 수정을 선택하세요.');
        $('#cateNm').val('').prop('disabled', true);
        $('#gubunId').val('').prop('readonly', false).prop('disabled', true);
        $('#seq').val('').prop('disabled', true);
        $('#dispYn').val('Y').prop('disabled', true);
        $('#btnSave').prop('disabled', true);
        $('#btnCancel').prop('disabled', true);
      }

      function saveForm() {
        var mode = $('#formMode').val();
        var nodeType = $('#nodeType').val();
        var cateNm = $.trim($('#cateNm').val());
        var gubunId = $.trim($('#gubunId').val());

        if (!mode) return;
        if (!cateNm) {
          showMessage(mode === 'updateGubun' ? '구분명을 입력하세요.' : '분류명을 입력하세요.', false);
          $('#cateNm').focus();
          return;
        }

        // 구분(최상위) 추가/수정 — ccm 'SGUBUN' 행 INSERT/UPDATE (insertGubunAjax/updateGubunAjax)
        if (mode === 'insertGubun' || mode === 'updateGubun') {
          var seqv = $.trim($('#seq').val());
          if (seqv !== '' && !/^\d{1,3}$/.test(seqv)) {
            showMessage('순서는 1~3자리 숫자만 입력하세요.', false);
            $('#seq').focus();
            return;
          }
          var gubunUrl = (mode === 'insertGubun') ? INSERT_GUBUN_URL : UPDATE_GUBUN_URL;
          var keepGubunNodeId = (mode === 'updateGubun' && selectedNode) ? selectedNode.id : null;
          setSaving(true);
          $.ajax({ url: gubunUrl, type: 'POST',
                   data: $('#cateEditForm').serialize(), dataType: 'json' })
            .done(function(data) {
              if (data && data.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
              if (data && data.success) {
                showMessage(data.resultMsg || '저장되었습니다.', true);
                var keepId = keepGubunNodeId || (data.gubunId ? 'gubun:' + data.gubunId : null);
                selectedNode = null; selectedData = {};
                resetForm(); clearSelected();
                loadTree(null, keepId);
              } else {
                showMessage((data && data.resultMsg) ? data.resultMsg : '저장 중 오류가 발생했습니다.', false);
              }
            })
            .fail(function() { showMessage('저장 요청 중 오류가 발생했습니다.', false); })
            .always(function() { setSaving(false); });
          return;
        }

        if ($('#ref').val() === '0' && !gubunId) {
          showMessage('루트 분류는 구분 ID를 입력해야 합니다.', false);
          $('#gubunId').focus();
          return;
        }

        var url = mode === 'update' ? UPDATE_AJAX_URL : INSERT_AJAX_URL;
        setSaving(true);
        $.ajax({
          url: url,
          type: 'POST',
          data: $('#cateEditForm').serialize(),
          dataType: 'json'
        }).done(function(data) {
          if (data && data.resultMsg === 'UNAUTHORIZED') {
            location.href = LOGIN_URL;
            return;
          }
          if (data && data.success) {
            showMessage(data.resultMsg || '저장되었습니다.', true);
            var keepCateNo = data.cateNo || (mode === 'update' ? $('#cateNo').val() : null);
            selectedNode = null;
            selectedData = {};
            resetForm();
            clearSelected();
            loadTree(keepCateNo);
          } else {
            showMessage((data && data.resultMsg) ? data.resultMsg : '저장 중 오류가 발생했습니다.', false);
          }
        }).fail(function() {
          showMessage('저장 요청 중 오류가 발생했습니다.', false);
        }).always(function() {
          setSaving(false);
        });
      }

      function deleteSelected() {
        // 구분(최상위) 삭제 — 서버가 참조 검사(사용 중인 분류/규정 있으면 차단)
        if (isGubunSelected()) {
          var gnm = selectedData.gubunNm || (selectedNode ? selectedNode.text : '');
          if (!confirm('구분 [' + gnm + '] 을(를) 삭제하시겠습니까?\n(이 구분을 사용 중인 분류나 규정이 있으면 삭제되지 않습니다)')) return;
          $.ajax({
            url: DELETE_GUBUN_URL,
            type: 'POST',
            data: gubunPayload(),
            dataType: 'json'
          }).done(function(data) {
            if (data && data.resultMsg === 'UNAUTHORIZED') { location.href = LOGIN_URL; return; }
            if (data && data.success) {
              showMessage(data.resultMsg || '삭제되었습니다.', true);
              selectedNode = null; selectedData = {};
              clearSelected(); resetForm();
              loadTree();
            } else {
              showMessage((data && data.resultMsg) ? data.resultMsg : '삭제 중 오류가 발생했습니다.', false);
            }
          }).fail(function() { showMessage('삭제 요청 중 오류가 발생했습니다.', false); });
          return;
        }
        if (!selectedData.cateNo) return;
        if (numberOrZero(selectedData.promCnt) > 0) {
          showMessage('선택한 분류에 연결된 규정이 있어 삭제할 수 없습니다.', false);
          return;
        }
        if (numberOrZero(selectedData.childCnt) > 0) {
          showMessage('하위 분류가 있어 삭제할 수 없습니다.', false);
          return;
        }
        if (!confirm('선택한 분류를 삭제하시겠습니까?')) return;

        $.ajax({
          url: DELETE_AJAX_URL,
          type: 'POST',
          data: deletePayload(),
          dataType: 'json'
        }).done(function(data) {
          if (data && data.resultMsg === 'UNAUTHORIZED') {
            location.href = LOGIN_URL;
            return;
          }
          if (data && data.success) {
            showMessage(data.resultMsg || '삭제되었습니다.', true);
            selectedNode = null;
            selectedData = {};
            clearSelected();
            resetForm();
            loadTree();
          } else {
            showMessage((data && data.resultMsg) ? data.resultMsg : '삭제 중 오류가 발생했습니다.', false);
          }
        }).fail(function() {
          showMessage('삭제 요청 중 오류가 발생했습니다.', false);
        });
      }

      function deletePayload() {
        var payload = { cateNo: selectedData.cateNo };
        var csrfName = $('#cateEditForm input[type="hidden"]').filter(function() {
          return this.name && this.name !== 'cateNo' && this.name !== 'ref';
        }).attr('name');
        if (csrfName) {
          payload[csrfName] = $('input[name="' + csrfName + '"]').val();
        }
        return payload;
      }

      function gubunPayload() {
        var payload = { gubunId: selectedData.gubunId };
        var csrfName = $('#cateEditForm input[type="hidden"]').filter(function() {
          return this.name && this.name !== 'cateNo' && this.name !== 'ref' && this.name !== 'nodeType' && this.name !== 'sysId';
        }).attr('name');
        if (csrfName) {
          payload[csrfName] = $('input[name="' + csrfName + '"]').val();
        }
        return payload;
      }

      function setSaving(saving) {
        var active = !!$('#formMode').val();
        $('#btnSave').prop('disabled', saving || !active);
        $('#btnCancel').prop('disabled', saving || !active);
      }

      function clearSelected() {
        $('#selCateNm').text('(선택 없음)');
        $('#selCateNo').text('-');
        $('#selGubunId').text('-');
        $('#selFullNm').text('-');
        $('#selDispYn').text('-');
        $('#selPromCnt').text('0');
        $('#selChildCnt').text('0');
        setToolbarState();
      }

      function showMessage(message, success) {
        var typeClass = success ? 'info' : 'danger';
        $('#cateMessage').html('<div class="krds-alert ' + typeClass + '">' + escapeHtml(message) + '</div>');
      }

      function emptyToDash(value) {
        return value === null || value === undefined || value === '' ? '-' : value;
      }

      function numberOrZero(value) {
        var parsed = parseInt(value, 10);
        return isNaN(parsed) ? 0 : parsed;
      }

      function escapeHtml(value) {
        return String(value || '').replace(/[&<>"']/g, function(ch) {
          return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch];
        });
      }

      function openOwnerModal(cateNo, name, gubunId) {
        ownerCateNo = cateNo;
        ownerGubunId = gubunId || null;
        var isGubun = !!ownerGubunId;
        $('#ownerCateNm').text(isGubun
            ? ((name ? name + ' ' : '') + '(구분 전체)')
            : ((name ? name + ' ' : '') + '(No.' + cateNo + ')'));
        $('#ownerTy').val('DEPT');
        $('#ownerUserKw').val('');
        setPickedUser('owner', null);
        $('#ownerUserPick').hide().empty();
        $('#ownerInherit').prop('checked', true);
        toggleOwnerType();
        $('#readerTy').val('DEPT');
        $('#readerUserKw').val('');
        setPickedUser('reader', null);
        $('#readerUserPick').hide().empty();
        $('#readerInherit').prop('checked', true);
        toggleReaderType();
        // 구분 모드 — 작성자 탭은 안내만, 상속 체크박스 숨김(항상 구분 전체 적용), 기본 탭 = 열람 제한
        $('#ownerGubunNotice').toggle(isGubun);
        $('#ownerCateControls').toggle(!isGubun);
        $('#readerInheritWrap').toggle(!isGubun);
        switchOwnerTab(isGubun ? 'reader' : 'owner');
        $('#ownerModal').css('display', 'flex');
        if (!ownerDeptsLoaded) { loadOwnerDepts(); }
        if (!isGubun) { loadOwnerList(); }
        loadReaderList();
      }

      function closeOwnerModal() {
        $('#ownerModal').hide();
        ownerCateNo = null;
        ownerGubunId = null;
      }

      function switchOwnerTab(pane) {
        var owner = (pane === 'owner');
        $('#ownerTabEdit').toggleClass('on', owner);
        $('#ownerTabRead').toggleClass('on', !owner);
        $('#ownerPane').toggle(owner);
        $('#readerPane').toggle(!owner);
      }

      function toggleOwnerType() {
        var ty = $('#ownerTy').val();
        $('#ownerDeptWrap').toggle(ty === 'DEPT');
        $('#ownerUserWrap').toggle(ty === 'USER');
      }

      function toggleReaderType() {
        var ty = $('#readerTy').val();
        $('#readerDeptWrap').toggle(ty === 'DEPT');
        $('#readerUserWrap').toggle(ty === 'USER');
      }

      function loadOwnerDepts() {
        $.getJSON(OWNER_DEPTS_URL).done(function(res) {
          if (!res || !res.success || !res.resultList) {
            $('#ownerDeptSel, #readerDeptSel').html('<option value="">(없음)</option>');
            return;
          }
          var opts = res.resultList.map(function(d) {
            return '<option value="' + escapeHtml(d.orgnztId) + '">' + escapeHtml(d.orgnztNm) + '</option>';
          }).join('');
          $('#ownerDeptSel').html(opts);
          $('#readerDeptSel').html(opts);
          ownerDeptsLoaded = true;
        });
      }

      function loadOwnerList() {
        var reqCateNo = ownerCateNo;
        $.getJSON(OWNER_LIST_URL, { cateNo: reqCateNo }).done(function(res) {
          if (reqCateNo !== ownerCateNo) return;   /* 모달 빠른 재오픈 시 stale 응답 무시 */
          var list = (res && res.resultList) || [];
          var $body = $('#ownerBody');
          if (!list.length) {
            $body.html('<tr><td colspan="4" class="owner-muted">지정된 작성자가 없습니다. (관리자만 수정 가능)</td></tr>');
            return;
          }
          $body.html(list.map(function(o) {
            var tag = (o.ownerTy === 'DEPT')
              ? '<span class="owner-tag owner-tag-dept">부서</span>'
              : '<span class="owner-tag owner-tag-user">개인</span>';
            var nm = escapeHtml(o.ownerNm || o.ownerId);
            return '<tr>'
              + '<td>' + tag + '</td>'
              + '<td>' + nm + ' <span class="owner-muted">(' + escapeHtml(o.ownerId) + ')</span></td>'
              + '<td>' + (o.inheritYn === 'Y' ? '상속' : '-') + '</td>'
              + '<td><button type="button" class="krds-btn danger small owner-del" data-ty="' + escapeHtml(o.ownerTy)
                + '" data-id="' + escapeHtml(o.ownerId) + '">삭제</button></td>'
              + '</tr>';
          }).join(''));
        });
      }

      /* 개인 대상 확정 — 검색 선택이 정본, 직접 붙여넣은 고유아이디(USRCNFRM_…)는 폴백 허용 */
      function resolvePickedId(prefix) {
        var picked = getPickedUser(prefix);
        if (picked && picked.esntlId) { return picked.esntlId; }
        var raw = $.trim($('#' + prefix + 'UserKw').val());
        if (/^USRCNFRM_/.test(raw)) { return raw; }
        return null;
      }

      function addOwner() {
        if (!ownerCateNo) return;
        var ty = $('#ownerTy').val();
        var id;
        if (ty === 'DEPT') {
          id = $('#ownerDeptSel').val();
          if (!id) { alert('부서를 선택하세요.'); return; }
        } else {
          id = resolvePickedId('owner');
          if (!id) { alert('이름/로그인ID로 검색한 뒤 목록에서 사용자를 선택하세요.'); return; }
        }
        $.post(OWNER_INSERT_URL, {
          cateNo: ownerCateNo, ownerTy: ty, ownerId: id,
          inheritYn: $('#ownerInherit').is(':checked') ? 'Y' : 'N'
        }, null, 'json').done(function(res) {
          if (!res || !res.success) { alert('추가 실패: ' + ((res && res.resultMsg) || '')); return; }
          if (ty === 'USER') { $('#ownerUserKw').val(''); setPickedUser('owner', null); }
          loadOwnerList();
        }).fail(function() { alert('추가 요청 중 오류가 발생했습니다.'); });
      }

      function delOwner(ty, id) {
        if (!ownerCateNo) return;
        if (!confirm('이 작성자를 해제할까요?')) return;
        $.post(OWNER_DELETE_URL, { cateNo: ownerCateNo, ownerTy: ty, ownerId: id }, null, 'json')
          .done(function(res) {
            if (!res || !res.success) { alert('삭제 실패: ' + ((res && res.resultMsg) || '')); return; }
            loadOwnerList();
          }).fail(function() { alert('삭제 요청 중 오류가 발생했습니다.'); });
      }

      /* ---- 열람 제한 탭 (TB_CATE_READER — 작성자 탭 미러) ---- */

      function loadReaderList() {
        var isGubun = !!ownerGubunId;
        var reqKey = isGubun ? ownerGubunId : ownerCateNo;
        var url    = isGubun ? READER_GUBUN_LIST_URL : READER_LIST_URL;
        var params = isGubun ? { gubunId: ownerGubunId } : { cateNo: ownerCateNo };
        $.getJSON(url, params).done(function(res) {
          if (reqKey !== (ownerGubunId || ownerCateNo)) return;   /* 모달 빠른 재오픈 시 stale 응답 무시 */
          var list = (res && res.resultList) || [];
          var $body = $('#readerBody');
          if (!list.length) {
            $body.html('<tr><td colspan="4" class="owner-muted">열람 제한이 없습니다. (전체 공개)</td></tr>');
            return;
          }
          $body.html(list.map(function(o) {
            var tag = (o.readerTy === 'DEPT')
              ? '<span class="owner-tag owner-tag-dept">부서</span>'
              : '<span class="owner-tag owner-tag-user">개인</span>';
            var nm = escapeHtml(o.readerNm || o.readerId);
            /* 이름 미해석 = 삭제/오타 대상 — 제한은 살아 있는데 매칭될 사람이 없을 수 있어 경고 */
            var warn = (!o.readerNm)
              ? ' <span class="owner-tag" style="background:#fdecec;color:#c0392b;">미확인 대상</span>' : '';
            var scope = o.gubunId ? '구분 전체' : (o.inheritYn === 'Y' ? '상속' : '-');
            return '<tr>'
              + '<td>' + tag + '</td>'
              + '<td>' + nm + warn + ' <span class="owner-muted">(' + escapeHtml(o.readerId) + ')</span></td>'
              + '<td>' + scope + '</td>'
              + '<td><button type="button" class="krds-btn danger small reader-del" data-ty="' + escapeHtml(o.readerTy)
                + '" data-id="' + escapeHtml(o.readerId) + '">삭제</button></td>'
              + '</tr>';
          }).join(''));
        });
      }

      function addReader() {
        if (!ownerCateNo && !ownerGubunId) return;
        var ty = $('#readerTy').val();
        var id;
        if (ty === 'DEPT') {
          id = $('#readerDeptSel').val();
          if (!id) { alert('부서를 선택하세요.'); return; }
        } else {
          id = resolvePickedId('reader');
          if (!id) { alert('이름/로그인ID로 검색한 뒤 목록에서 사용자를 선택하세요.'); return; }
        }
        var isGubun = !!ownerGubunId;
        var url    = isGubun ? READER_GUBUN_INSERT_URL : READER_INSERT_URL;
        var params = isGubun
          ? { gubunId: ownerGubunId, readerTy: ty, readerId: id }
          : { cateNo: ownerCateNo, readerTy: ty, readerId: id,
              inheritYn: $('#readerInherit').is(':checked') ? 'Y' : 'N' };
        $.post(url, params, null, 'json').done(function(res) {
          if (!res || !res.success) { alert('추가 실패: ' + ((res && res.resultMsg) || '')); return; }
          if (ty === 'USER') { $('#readerUserKw').val(''); setPickedUser('reader', null); }
          loadReaderList();
        }).fail(function() { alert('추가 요청 중 오류가 발생했습니다.'); });
      }

      function delReader(ty, id) {
        if (!ownerCateNo && !ownerGubunId) return;
        if (!confirm('이 열람 제한을 해제할까요?')) return;
        var isGubun = !!ownerGubunId;
        var url    = isGubun ? READER_GUBUN_DELETE_URL : READER_DELETE_URL;
        var params = isGubun
          ? { gubunId: ownerGubunId, readerTy: ty, readerId: id }
          : { cateNo: ownerCateNo, readerTy: ty, readerId: id };
        $.post(url, params, null, 'json')
          .done(function(res) {
            if (!res || !res.success) { alert('삭제 실패: ' + ((res && res.resultMsg) || '')); return; }
            loadReaderList();
          }).fail(function() { alert('삭제 요청 중 오류가 발생했습니다.'); });
      }
    });
  </script>
</lay:layout>
