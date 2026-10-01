<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prommap/prommapView.jsp

  규정맵 사용자 뷰어 — 레거시 front/contents/fulltext_map 이관(읽기전용).
   - 좌측: 기능별분류 트리 (/rlms/prommap/treeJson.do)
   - 우측: 폴더 선택 시 그 안의 현행 규정목록 → 클릭 시 전문뷰어(/rlms/fulltext/provisionList.do)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">기능별 규정맵</c:set>
<c:set var="pageHead">
  
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css'/>"/>
  <style>
    .pmv-wrap { padding: 16px 20px; }
    .pmv-title { font-size: 20px; font-weight: 700; color: #1f3974; margin: 0 0 4px; }
    .pmv-desc { color: #555; font-size: 13px; margin: 0 0 14px; }
    .pmv-2pane { display: flex; gap: 14px; align-items: stretch; }
    .pmv-col { border: 1px solid #cdd6e6; border-radius: 6px; background: #fff; display: flex; flex-direction: column; }
    .pmv-col-tree { flex: 0 0 320px; }
    .pmv-col-list { flex: 1 1 0; min-width: 0; }
    .pmv-col-tit { background: #eef2fb; color: #1f3974; font-weight: 600; font-size: 13px; padding: 7px 10px; border-bottom: 1px solid #cdd6e6; border-radius: 6px 6px 0 0; }
    .pmv-tree { height: 580px; overflow: auto; padding: 6px; white-space: nowrap; }
    .pmv-list { height: 580px; overflow: auto; padding: 0; }
    .pmv-list table { width: 100%; border-collapse: collapse; font-size: 13px; }
    .pmv-list th, .pmv-list td { border-bottom: 1px solid #eee; padding: 9px 12px; text-align: left; }
    .pmv-list th { background: #f8fafd; color: #555; font-weight: 600; position: sticky; top: 0; }
    .pmv-list td.col-date { width: 130px; color: #777; white-space: nowrap; }
    .pmv-list a.pmv-prom { color: #1f3974; font-weight: 600; text-decoration: none; }
    .pmv-list a.pmv-prom:hover { text-decoration: underline; }
    .pmv-list .pmv-path { display: block; font-size: 11px; color: #999; margin-top: 2px; }
    .pmv-empty { text-align: center; color: #888; padding: 40px 0; }
    /* 반응형 (2026-08-04) — 좌 트리 320px 고정 2단이 좁은 화면에서 넘침 → 세로 스택 */
    @media (max-width: 900px) {
      .pmv-wrap { padding: 12px 8px; }
      .pmv-2pane { flex-direction: column; }
      .pmv-col-tree { flex: 0 0 auto; }
      .pmv-tree { height: 300px; }
      .pmv-list { height: auto; }
      .pmv-list td.col-date { width: auto; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="pmv-wrap">
    <h2 class="pmv-title">기능별 규정맵</h2>
    <p class="pmv-desc">기능별 분류 트리에서 폴더를 선택하면 해당 분류의 규정 목록이 표시됩니다. 규정명을 클릭하면 전문(現行)을 봅니다.</p>
    <div class="pmv-2pane">
      <section class="pmv-col pmv-col-tree">
        <div class="pmv-col-tit">기능별 분류</div>
        <div id="pmvTree" class="pmv-tree"></div>
      </section>
      <section class="pmv-col pmv-col-list">
        <div class="pmv-col-tit" id="pmvListTit">규정 목록</div>
        <div id="pmvList" class="pmv-list">
          <div class="pmv-empty">좌측에서 분류를 선택하세요.</div>
        </div>
      </section>
    </div>
  </div>

  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js'/>"></script>
  <script>
    // 단일 시스템 — sysId(SSYS_ID) 미사용
    var MAP_TREE_URL = '<c:url value="/rlms/prommap/treeJson.do"/>';
    var PROM_LIST_URL = '<c:url value="/rlms/prommap/promListJson.do"/>';
    var VIEWER_URL = '<c:url value="/rlms/fulltext/provisionList.do"/>';

    function pmvEsc(s) {
      return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    /* 시행예정(A안) — pending 규정 잎의 노드명 뒤에 뱃지 부착(jsTree 는 text 를 HTML 렌더) */
    function pmvDecorate(nodes) {
      (nodes || []).forEach(function(nd) {
        if (nd.data && nd.data.pending) {
          nd.text = pmvEsc(nd.text) + ' <span class="krds-badge bg-light-information">시행예정</span>';
        }
        pmvDecorate(nd.children);
      });
      return nodes;
    }

    $(function() {
      $('#pmvTree').jstree({
        core: {
          themes: { dots: true, icons: true },
          data: function(node, cb) {
            $.getJSON(MAP_TREE_URL, function(j) { cb.call(this, pmvDecorate(j)); });
          }
        },
        types: { pfolder: { icon: 'jstree-folder' }, pleaf: { icon: 'jstree-file' } },
        plugins: ['types']
      }).on('select_node.jstree', function(e, data) {
        var d = data.node.data || {};
        if (d.promYn === 'Y') {
          // 규정 잎 자체 클릭 → 바로 전문뷰어 (현행 promNo 는 목록 조회 없이 잎의 promNo 사용)
          if (d.promNo) window.open(VIEWER_URL + '?promNo=' + d.promNo, '_blank');
          return;
        }
        pmvLoadList(d.pmapNo, data.node.text);
      });
    });

    function pmvLoadList(pmapNo, title) {
      document.getElementById('pmvListTit').textContent = '규정 목록 — ' + title;
      var box = document.getElementById('pmvList');
      box.innerHTML = '<div class="pmv-empty">불러오는 중…</div>';
      $.ajax({ url: PROM_LIST_URL, data: { pmapNo: pmapNo }, dataType: 'json' })
        .done(function(d) {
          var items = (d && d.items) || [];
          if (!items.length) { box.innerHTML = '<div class="pmv-empty">이 분류에 등록된 규정이 없습니다.</div>'; return; }
          var h = '<table><thead><tr><th>규정명</th><th class="col-date">공포일자</th></tr></thead><tbody>';
          items.forEach(function(it) {
            h += '<tr><td>'
               + '<a class="pmv-prom" href="' + VIEWER_URL + '?promNo=' + it.promNo + '" target="_blank">' + pmvEsc(it.title) + '</a>'
               + (it.pending ? ' <span class="krds-badge bg-light-information" title="공포되었으나 아직 시행 전입니다">시행예정</span>' : '')
               + (it.catePath ? '<span class="pmv-path">' + pmvEsc(it.catePath) + '</span>' : '')
               + '</td><td class="col-date">' + pmvEsc(it.promDate) + '</td></tr>';
          });
          h += '</tbody></table>';
          box.innerHTML = h;
        })
        .fail(function(xhr) { box.innerHTML = '<div class="pmv-empty">목록을 불러오지 못했습니다. (' + xhr.status + ')</div>'; });
    }
  </script>
</lay:layout>
