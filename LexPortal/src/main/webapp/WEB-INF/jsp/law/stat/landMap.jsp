<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/stat/landMap.jsp
  소송통계 ⑦ 사건지번표시도 — LAW_MODULE_DESIGN.md §7.12.
  기간 + 결과 그룹(진행중/종결/승소/패소) → 지번 → Kakao Geocoder 마커(사건번호·사건명).
  Globals.law.kakaoMapAppKey 미설정·차단 시 지번 목록으로 폴백(화면이 죽지 않게).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">사건지번표시도</c:set>
<c:set var="pageHead">
  
  <style>
    .law-stat-head { display:flex; justify-content:flex-end; gap:6px; margin:8px 0 12px; }
    #law-map { width:100%; height:460px; border:1px solid #d5d9e0; border-radius:6px; }
    .law-map-note { padding:10px 12px; background:#fff8e1; border:1px solid #ffe0a3; border-radius:6px; color:#8a6d3b; margin:8px 0 14px; }
    .law-stat-table th, .law-stat-table td { text-align:left; }
    .law-list-title { font-size:15px; margin:18px 0 8px; }
    .law-list-cnt { color:#888; font-weight:normal; }
    /* 결과 체크박스 — flex gap 의존 없이 margin 으로 확실히 간격 (항목 간·박스↔글자) */
    .law-chk-group label { display:inline-flex; align-items:center; font-weight:normal; margin-right:26px; }
    .law-chk-group label:last-child { margin-right:0; }
    .law-chk-group input[type=checkbox] { margin:0 8px 0 0; flex:none; }
    .law-map-wrap { display:flex; gap:8px; align-items:stretch; }
    .law-map-col { position:relative; flex:1 1 100%; min-width:0; }
    /* 로드뷰 = 전체 화면 오버레이 (닫기/ESC 로 지도 복귀) */
    #law-roadview-box { display:none; position:fixed; inset:0; z-index:9999; background:#000; flex-direction:column; }
    .law-map-wrap.rv-open #law-roadview-box { display:flex; }
    #law-roadview { flex:1; min-height:0; }
    .rv-bar { display:flex; justify-content:space-between; align-items:center; padding:10px 16px; background:#1f2937; color:#fff; font-size:14px; font-weight:600; }
    .rv-bar .krds-btn { flex:0 0 auto; }
    /* 지도 위 네이티브형 로드뷰 토글(좌상단) */
    .law-rv-toggle { position:absolute; top:10px; left:10px; z-index:5; width:40px; height:40px; padding:0;
      display:flex; align-items:center; justify-content:center; border-radius:50%; cursor:pointer;
      background:#fff; border:1px solid #b9c4d6; color:#33507a; box-shadow:0 1px 4px rgba(0,0,0,.28); }
    .law-rv-toggle:hover { background:#eef4ff; }
    .law-rv-toggle.active { background:#2f6bd8; border-color:#2f6bd8; color:#fff; }
    .law-rv-toggle svg { width:22px; height:22px; display:block; }
    @media (max-width: 900px){ .law-map-wrap{ flex-direction:column; } }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>사건지번표시도</h1>
    <p class="page-desc">기간·결과별 사건토지 지번을 지도에 표시하고, 아래에 지번 목록을 함께 보여줍니다. 지도 키가 없으면 목록만 표시됩니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/stat/landMap.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="searched" value="Y"/>
    <div class="form-group inline">
      <label class="form-label">결과</label>
      <div class="form-conts law-chk-group" style="flex-wrap:wrap;">
        <label><input type="checkbox" id="processing" name="processing" value="Y" ${chkProcessing ? 'checked' : ''}/>진행중</label>
        <label><input type="checkbox" id="terminate" name="terminate" value="Y" ${chkTerminate ? 'checked' : ''}/>종결</label>
        <label><input type="checkbox" id="win" name="win" value="Y" ${chkWin ? 'checked' : ''}/>승소</label>
        <label><input type="checkbox" id="lose" name="lose" value="Y" ${chkLose ? 'checked' : ''}/>패소</label>
      </div>
    </div>
    <div class="form-group inline">
      <label class="form-label" for="fromDate">기간</label>
      <div class="form-conts">
        <input type="date" id="fromDate" name="fromDate" class="krds-input" value="<c:out value='${fromDate}'/>"/>
        <span>~</span>
        <input type="date" id="toDate" name="toDate" class="krds-input" value="<c:out value='${toDate}'/>"/>
      </div>
      <button type="button" id="btnSearch" class="krds-btn primary medium">조회</button>
    </div>
  </form>

  <div class="law-stat-head">
    <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀 다운로드</button>
  </div>

  <c:choose>
    <c:when test="${not empty kakaoKey}">
      <div class="law-map-wrap">
        <div class="law-map-col">
          <div id="law-map"></div>
          <button type="button" id="btnRoadview" class="law-rv-toggle" title="로드뷰" aria-label="로드뷰 켜기/끄기">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 2.6a2.4 2.4 0 1 0 0 4.8 2.4 2.4 0 0 0 0-4.8zM8.4 8.6a1.6 1.6 0 0 0-1.55 1.2L5.6 14.6l1.85.5 1-3.7V22h2.05v-5.4h1V22h2.05v-9.6l1 3.7 1.85-.5-1.25-4.8A1.6 1.6 0 0 0 15.6 8.6z"/></svg>
          </button>
        </div>
        <div id="law-roadview-box">
          <div class="rv-bar"><span>거리뷰(로드뷰) — 닫기 또는 ESC 로 지도로 돌아갑니다</span><button type="button" id="btnRvClose" class="krds-btn small">닫기</button></div>
          <div id="law-roadview"></div>
        </div>
      </div>
      <p class="law-cell-sub" style="margin:8px 0 0; color:#888;">마커 <span id="markerCnt">0</span>건<span id="approxCnt"></span> · 마우스를 올리면 사건번호·사건명이 표시됩니다. 지도 <b>좌상단 로드뷰 아이콘</b>을 켜면 거리뷰가 있는 도로가 파란선으로 표시되고, <b>사람 아이콘을 도로 위에 놓거나 파란선을 클릭</b>하면 거리뷰가 열립니다(마커 클릭도 가능). 주소검색이 안 되는 지번(말소·합병된 옛 지번 등)은 <b>본번→동 기준 추정 위치</b>에 반투명 마커로 표시하고, 그것도 안 되면 목록에만 남습니다. <span id="rvMsg" style="color:#c0392b;"></span></p>
    </c:when>
    <c:otherwise>
      <div class="law-map-note">지도 표시용 키(Globals.law.kakaoMapAppKey)가 설정되지 않아 지번 목록으로만 표시합니다.</div>
    </c:otherwise>
  </c:choose>

  <h2 class="law-list-title">지번 목록 <span class="law-list-cnt">(<span id="landCnt"><c:out value="${fn:length(landList)}"/></span>건)</span></h2>
  <table class="krds-table tbl-list law-stat-table">
    <thead>
      <tr>
        <th scope="col" style="width:56px;">번호</th>
        <th scope="col" style="width:150px;">사건번호</th>
        <th scope="col">사건명</th>
        <th scope="col">소재지·지번</th>
      </tr>
    </thead>
    <tbody id="landListBody">
      <c:forEach var="row" items="${landList}" varStatus="st">
        <tr>
          <td><c:out value="${fn:length(landList) - st.index}"/></td>
          <td><c:out value="${row.caseNo}" default="-"/></td>
          <td><c:out value="${row.caseNm}" default="-"/></td>
          <td><c:out value="${row.address}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty landList}">
        <tr><td colspan="4" style="text-align:center; padding:28px 0; color:#888;">해당 조건의 사건토지 지번이 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <script>
  function fnQuery(){
    var f = document.getElementById('searchForm');
    return new URLSearchParams(new FormData(f)).toString();
  }
  function fnExcel(){
    window.location.href = '<c:url value="/law/stat/landMapExcel.do"/>' + '?' + fnQuery();
  }
  </script>

  <c:choose>
    <c:when test="${not empty kakaoKey}">
      <script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=<c:out value='${kakaoKey}'/>&libraries=services"></script>
      <script>
      (function(){
        var map, geocoder, markers = [], infowins = [];
        var roadview, roadviewClient, rvMode = false, walker = null, walkerImage = null;
        var CENTER_LAT = parseFloat('<c:out value="${mapCenterLat}"/>');
        var CENTER_LNG = parseFloat('<c:out value="${mapCenterLng}"/>');
        function ready(cb){
          if (window.kakao && kakao.maps && kakao.maps.services) { cb(); }
          else { setTimeout(function(){ ready(cb); }, 100); }
        }
        function clearMarkers(){
          for (var i=0;i<markers.length;i++){ markers[i].setMap(null); }
          for (var j=0;j<infowins.length;j++){ infowins[j].close(); }
          markers = []; infowins = [];
        }
        /* 지번에서 부번을 뗀 본번 ("663-1"→"663", "산12-3"→"산12"). 꼴이 지번이 아니면 null */
        function jibunBase(j){
          var m = /^(산\s*)?(\d+)(-\d+)?$/.exec((j || '').trim());
          return m ? ((m[1] || '') + m[2]) : null;
        }
        var approxCnt = 0;
        /* 지오코딩 폴백 체인 (2026-07-30) — 카카오 주소 DB 는 "현행" 지적만 반환해
           말소·합병된 옛 지번(예: 재개발 구역)은 ZERO_RESULT 가 난다(구글은 옛 지번도 근사 표시).
           정확 지번 → 본번 → 동(소재지) 순으로 재시도하고, 폴백 마커는 반투명 + '추정 위치' 라벨로 구분. */
        function place(item, idx){
          var tries = [ { addr: item.address, level: 0 } ];
          var base = jibunBase(item.jibun);
          if (base && item.location && base !== (item.jibun || '').trim()) {
            tries.push({ addr: item.location + ' ' + base, level: 1 });
          }
          if (item.location) { tries.push({ addr: item.location, level: 2 }); }
          attempt(0);
          function attempt(t){
            if (t >= tries.length) { markRow(idx, null); return; }
            geocoder.addressSearch(tries[t].addr, function(result, status){
              if (status === kakao.maps.services.Status.OK && result[0]) {
                addMarker(item, tries[t], result[0]);
                markRow(idx, tries[t].level);
              } else {
                attempt(t + 1);
              }
            });
          }
        }
        function addMarker(item, tryInfo, found){
          var approx = tryInfo.level > 0;
          var coords = new kakao.maps.LatLng(found.y, found.x);
          var marker = new kakao.maps.Marker({ map: map, position: coords, opacity: approx ? 0.55 : 1 });
          var label = (item.caseNo ? item.caseNo : '') + (item.caseNm ? ' ' + item.caseNm : '');
          var note = approx
            ? '<br><span style="color:#c0392b;">추정 위치 — 지번(' + escapeHtml(item.jibun || '') + ') 주소검색 불가, ' + escapeHtml(tryInfo.addr) + ' 기준</span>'
            : '';
          var iw = new kakao.maps.InfoWindow({ content: '<div style="padding:5px 8px;font-size:12px;">' + escapeHtml(label || item.address) + note + '</div>' });
          kakao.maps.event.addListener(marker, 'mouseover', function(){ iw.open(map, marker); });
          kakao.maps.event.addListener(marker, 'mouseout', function(){ iw.close(); });
          kakao.maps.event.addListener(marker, 'click', function(){ if (walker) { walker.setPosition(coords); } openRoadview(coords); });
          markers.push(marker); infowins.push(iw);
          document.getElementById('markerCnt').textContent = markers.length;
          if (approx) {
            approxCnt++;
            var ac = document.getElementById('approxCnt');
            if (ac) { ac.textContent = ' (이 중 추정 위치 ' + approxCnt + '건)'; }
          }
        }
        /* 목록 행에 지도 표시 상태 뱃지 — level 0=정확(뱃지 없음)/1·2=추정/null=미표시 */
        function markRow(idx, level){
          if (level === 0) { return; }
          var cell = document.querySelector('#landListBody tr[data-idx="' + idx + '"] td:last-child');
          if (!cell) { return; }
          var txt = (level == null) ? '지도 미표시(주소검색 불가)' : (level === 1 ? '지도 추정(본번)' : '지도 추정(동)');
          var color = (level == null) ? '#c0392b' : '#8a6d3b';
          cell.insertAdjacentHTML('beforeend',
            ' <span style="font-size:12px; color:' + color + '; border:1px solid currentColor; border-radius:8px; padding:1px 7px; white-space:nowrap;">' + txt + '</span>');
        }
        function escapeHtml(s){ return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
        function showRvMsg(msg){
          var el = document.getElementById('rvMsg');
          if (!el) { return; }
          el.textContent = msg || '';
          if (msg) { setTimeout(function(){ if (el.textContent === msg) { el.textContent = ''; } }, 4000); }
        }
        function openRoadview(position){
          if (!roadviewClient) { return; }
          roadviewClient.getNearestPanoId(position, 50, function(panoId){
            if (panoId === null) {
              roadviewClient.getNearestPanoId(position, 300, function(panoId2){
                if (panoId2 === null) { showRvMsg('이 위치 주변에는 거리뷰(로드뷰)가 없습니다.'); return; }
                showRoadview(panoId2, position);
              });
              return;
            }
            showRoadview(panoId, position);
          });
        }
        function showRoadview(panoId, position){
          showRvMsg('');
          document.querySelector('.law-map-wrap').classList.add('rv-open');
          roadview.setPanoId(panoId, position);
          setTimeout(function(){ roadview.relayout(); }, 60);
        }
        function closeRoadview(){
          document.querySelector('.law-map-wrap').classList.remove('rv-open');
        }
        function makeWalkerImage(){
          // 카카오 공식 로드뷰 맨워커 스프라이트(정면 프레임)
          return new kakao.maps.MarkerImage(
            '//t1.daumcdn.net/localimg/localimages/07/2018/pc/roadview_minimap_wk_2018.png',
            new kakao.maps.Size(26, 46),
            { spriteSize: new kakao.maps.Size(1666, 168), spriteOrigin: new kakao.maps.Point(705, 114), offset: new kakao.maps.Point(13, 46) }
          );
        }
        function enterRvMode(){
          rvMode = true;
          map.addOverlayMapTypeId(kakao.maps.MapTypeId.ROADVIEW);
          if (!walkerImage) { walkerImage = makeWalkerImage(); }
          walker = new kakao.maps.Marker({ map: map, position: map.getCenter(), image: walkerImage, draggable: true, zIndex: 20 });
          kakao.maps.event.addListener(walker, 'dragend', function(){ openRoadview(walker.getPosition()); });
          var btn = document.getElementById('btnRoadview');
          if (btn) { btn.classList.add('active'); btn.title = '로드뷰 종료'; }
          showRvMsg('파란선 도로를 클릭하거나 사람 아이콘을 도로 위에 놓으세요.');
        }
        function exitRvMode(){
          rvMode = false;
          map.removeOverlayMapTypeId(kakao.maps.MapTypeId.ROADVIEW);
          if (walker) { walker.setMap(null); walker = null; }
          closeRoadview();
          var btn = document.getElementById('btnRoadview');
          if (btn) { btn.classList.remove('active'); btn.title = '로드뷰'; }
          showRvMsg('');
        }
        function toggleRvMode(){ if (rvMode) { exitRvMode(); } else { enterRvMode(); } }
        function renderList(list){
          var tbody = document.getElementById('landListBody');
          if (!tbody) { return; }
          var cnt = document.getElementById('landCnt');
          if (cnt) { cnt.textContent = list.length; }
          if (!list.length){
            tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; padding:28px 0; color:#888;">해당 조건의 사건토지 지번이 없습니다.</td></tr>';
            return;
          }
          var html = '';
          for (var i=0;i<list.length;i++){
            var it = list[i];
            html += '<tr data-idx="' + i + '"><td>' + (list.length - i) + '</td>'
                  + '<td>' + (it.caseNo ? escapeHtml(it.caseNo) : '-') + '</td>'
                  + '<td>' + (it.caseNm ? escapeHtml(it.caseNm) : '-') + '</td>'
                  + '<td>' + (it.address ? escapeHtml(it.address) : '-') + '</td></tr>';
          }
          tbody.innerHTML = html;
        }
        function doSearch(){
          clearMarkers();
          approxCnt = 0;
          document.getElementById('markerCnt').textContent = '0';
          var ac = document.getElementById('approxCnt');
          if (ac) { ac.textContent = ''; }
          fetch('<c:url value="/law/stat/landMapJson.do"/>' + '?' + fnQuery(), { credentials:'same-origin' })
            .then(function(r){ return r.json(); })
            .then(function(list){
              renderList(list);
              // 폴백 체인이 건당 최대 3회 호출이라, 목록이 길 때 지오코더 쿼터에 안 걸리게 살짝 시차를 둔다
              for (var i=0;i<list.length;i++){
                (function(item, idx){ setTimeout(function(){ place(item, idx); }, idx * 150); })(list[i], i);
              }
            })
            .catch(function(){});
        }
        ready(function(){
          map = new kakao.maps.Map(document.getElementById('law-map'), { center: new kakao.maps.LatLng(CENTER_LAT, CENTER_LNG), level: 9 });
          map.addControl(new kakao.maps.ZoomControl(), kakao.maps.ControlPosition.RIGHT);
          geocoder = new kakao.maps.services.Geocoder();
          roadview = new kakao.maps.Roadview(document.getElementById('law-roadview'));
          roadviewClient = new kakao.maps.RoadviewClient();
          kakao.maps.event.addListener(map, 'click', function(mouseEvent){ if (rvMode) { if (walker) { walker.setPosition(mouseEvent.latLng); } openRoadview(mouseEvent.latLng); } });
          doSearch();
          document.getElementById('btnSearch').addEventListener('click', doSearch);
          var btnRv = document.getElementById('btnRoadview');
          if (btnRv) { btnRv.addEventListener('click', toggleRvMode); }
          var btnClose = document.getElementById('btnRvClose');
          if (btnClose) { btnClose.addEventListener('click', closeRoadview); }
          document.addEventListener('keydown', function(e){ if (e.key === 'Escape') { closeRoadview(); } });
        });
      })();
      </script>
    </c:when>
    <c:otherwise>
      <script>
      document.getElementById('btnSearch').addEventListener('click', function(){ document.getElementById('searchForm').submit(); });
      </script>
    </c:otherwise>
  </c:choose>
</lay:layout>
