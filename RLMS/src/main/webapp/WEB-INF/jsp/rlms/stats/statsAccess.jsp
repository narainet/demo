<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/stats/statsAccess.jsp
  접속통계 (COMTNWEBLOG — 페이지 요청 로그, 비로그인 포함). KRDS 디자인.
  차원 탭 9종(일별/최근7일/시간대/요일/월/연/메뉴/기기/브라우저) + 막대 차트 + 표.
  차트 데이터는 아래 표(tbody)의 data-* 를 그대로 읽는다 — 표가 단일 원천(이스케이프 일원화).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">접속통계</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <style>
    .as-tabs { display:flex; gap:6px; flex-wrap:wrap; margin:0 0 14px; }
    .as-tab { border:1px solid #d0d5dd; background:#fff; border-radius:8px; padding:7px 14px;
              font-size:14px; cursor:pointer; color:#374151; }
    .as-tab.on { background:#256ef4; border-color:#256ef4; color:#fff; font-weight:600; }
    .as-summary { margin:12px 0 6px; color:#374151; }
    .as-summary strong { font-size:18px; }
    .as-note { color:#8a919c; font-size:12.5px; margin:0 0 10px; }
    .as-chart-wrap { border:1px solid #e5e7ea; border-radius:10px; padding:16px 14px 8px;
                     margin:0 0 18px; overflow-x:auto; background:#fff; }
    .as-chart-title { font-size:14px; font-weight:600; color:#374151; margin:0 0 10px; }
    /* 가로 막대(메뉴/기기/브라우저) */
    .as-hbar-row { display:flex; align-items:center; gap:10px; padding:5px 0; }
    .as-hbar-label { flex:0 0 180px; max-width:180px; font-size:13.5px; color:#374151;
                     text-align:right; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
    .as-hbar-track { flex:1; min-width:120px; }
    .as-hbar-fill { height:16px; border-radius:0 4px 4px 0; background:#256ef4; min-width:2px; }
    .as-hbar-row:hover .as-hbar-fill { background:#0b50d0; }
    .as-hbar-val { flex:0 0 auto; font-size:13px; color:#374151; }
    /* SVG 컬럼 차트 */
    .as-col-svg .bar { fill:#256ef4; }
    .as-col-svg .bar:hover { fill:#0b50d0; }
    .as-col-svg .grid { stroke:#e5e7ea; stroke-width:1; }
    .as-col-svg .axis-text { fill:#6b7280; font-size:11px; }
    .as-col-svg .val-text { fill:#374151; font-size:11px; }
    #asTooltip { position:absolute; display:none; pointer-events:none; z-index:50;
                 background:#111827; color:#fff; font-size:12.5px; border-radius:6px;
                 padding:6px 10px; box-shadow:0 2px 8px rgba(0,0,0,.25); white-space:nowrap; }
    #asTooltip .tt-cnt { font-weight:700; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>접속통계</h1>
    <p class="page-desc">화면 접속(페이지 요청) 기준 통계입니다. 로그인하지 않은 접속도 포함되며, 접속자수는 로그인 사용자·비로그인 IP 기준입니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/stats/accessStats.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" id="dimension" name="dimension" value="<c:out value='${searchVO.dimension}'/>"/>

    <div class="as-tabs">
      <c:forTokens var="d" items="DAY,WEEK7,HOUR,DOW,MONTH,YEAR,MENU,DEVICE,BROWSER" delims=",">
        <button type="button" class="as-tab ${searchVO.dimension eq d ? 'on' : ''}" onclick="fnDim('${d}')">
          <c:choose>
            <c:when test="${d eq 'DAY'}">일별</c:when>
            <c:when test="${d eq 'WEEK7'}">최근 7일</c:when>
            <c:when test="${d eq 'HOUR'}">시간대별</c:when>
            <c:when test="${d eq 'DOW'}">요일별</c:when>
            <c:when test="${d eq 'MONTH'}">월별</c:when>
            <c:when test="${d eq 'YEAR'}">연도별</c:when>
            <c:when test="${d eq 'MENU'}">메뉴별</c:when>
            <c:when test="${d eq 'DEVICE'}">기기별</c:when>
            <c:otherwise>브라우저별</c:otherwise>
          </c:choose>
        </button>
      </c:forTokens>
    </div>

    <div class="form-group inline">
      <label class="form-label" for="fromDt">조회기간</label>
      <div class="form-conts">
        <input type="date" id="fromDt" name="fromDt" class="krds-input" value="<c:out value='${searchVO.fromDt}'/>"
               <c:if test="${searchVO.dimension eq 'WEEK7'}">disabled</c:if>/>
        <span>~</span>
        <input type="date" id="toDt" name="toDt" class="krds-input" value="<c:out value='${searchVO.toDt}'/>"
               <c:if test="${searchVO.dimension eq 'WEEK7'}">disabled</c:if>/>
      </div>
      <button type="submit" class="krds-btn primary medium" <c:if test="${searchVO.dimension eq 'WEEK7'}">disabled</c:if>>검색</button>
      <button type="button" class="krds-btn medium" onclick="fnExcel()"
              title="현재 탭·조회기간의 접속통계를 엑셀 파일로 내려받습니다">엑셀 다운로드</button>
    </div>
  </form>

  <p class="as-summary">기간 내 총 접속 <strong><fmt:formatNumber value="${totals.cnt}" type="number"/></strong> 회
     · 순 접속자 <strong><fmt:formatNumber value="${totals.ucnt}" type="number"/></strong> 명</p>
  <p class="as-note">
    <c:choose>
      <c:when test="${searchVO.dimension eq 'DAY'}">일별 차트는 최대 92일까지 표시됩니다(기간이 더 길면 종료일 기준으로 잘립니다).</c:when>
      <c:when test="${searchVO.dimension eq 'WEEK7'}">오늘을 포함한 최근 7일 고정 집계입니다.</c:when>
      <c:when test="${searchVO.dimension eq 'MONTH'}">월별 차트는 최대 36개월까지 표시됩니다.</c:when>
      <c:when test="${searchVO.dimension eq 'MENU'}">메뉴로 등록된 화면 URL 기준 상위 30개입니다(팝업·부속 요청은 제외).</c:when>
      <c:when test="${searchVO.dimension eq 'DEVICE' or searchVO.dimension eq 'BROWSER'}">'(수집 전)'은 기기·브라우저 수집 기능 추가(2026-07-20) 이전의 접속입니다.</c:when>
    </c:choose>
  </p>

  <%-- 차트는 아래 표의 시각적 중복이라 보조기기에는 숨긴다(표가 단일 원천) --%>
  <div class="as-chart-wrap" aria-hidden="true">
    <p class="as-chart-title">접속수</p>
    <div id="asChart"></div>
  </div>
  <div id="asTooltip" aria-hidden="true"></div>

  <table class="krds-table tbl-list" id="asTable">
    <thead>
      <tr>
        <th scope="col">구간</th>
        <th scope="col" style="width:18%">접속수</th>
        <th scope="col" style="width:18%">접속자수</th>
        <th scope="col" style="width:16%">비율</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="4" class="empty-row">접속 데이터가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}">
            <tr data-cnt="${row.cnt}" data-ucnt="${row.ucnt}">
              <td class="al"><c:out value="${row.label}"/></td>
              <td class="ar"><fmt:formatNumber value="${row.cnt}" type="number"/></td>
              <td class="ar"><fmt:formatNumber value="${row.ucnt}" type="number"/></td>
              <td class="ar">
                <c:choose>
                  <c:when test="${totals.cnt gt 0}"><fmt:formatNumber value="${row.cnt / totals.cnt}" type="percent" minFractionDigits="1" maxFractionDigits="1"/></c:when>
                  <c:otherwise>-</c:otherwise>
                </c:choose>
              </td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

<script>
  var AS_DIM = '<c:out value="${searchVO.dimension}"/>';

  function fnDim(d) {
    document.getElementById('dimension').value = d;
    // 차원 전환 시 기간은 차원별 기본값으로 리셋(서버가 채움) — 남은 기간이 다른 차원에 어색하게 이월되는 것 방지
    document.getElementById('fromDt').removeAttribute('disabled');
    document.getElementById('toDt').removeAttribute('disabled');
    document.getElementById('fromDt').value = '';
    document.getElementById('toDt').value = '';
    document.searchForm.submit();
  }

  function fnExcel() {
    var qs = ['dimension=' + encodeURIComponent(AS_DIM)];
    var f = document.getElementById('fromDt').value, t = document.getElementById('toDt').value;
    if (f) qs.push('fromDt=' + encodeURIComponent(f));
    if (t) qs.push('toDt=' + encodeURIComponent(t));
    location.href = '<c:url value="/rlms/stats/accessStatsExcel.do"/>' + '?' + qs.join('&');
  }

  /* ── 표(tbody data-*)를 원천으로 차트 데이터 구성 ── */
  function asData() {
    var out = [];
    $('#asTable tbody tr[data-cnt]').each(function () {
      out.push({ label: $(this).find('td').first().text(),
                 cnt: parseInt($(this).attr('data-cnt'), 10) || 0,
                 ucnt: parseInt($(this).attr('data-ucnt'), 10) || 0 });
    });
    return out;
  }

  var asTip = document.getElementById('asTooltip');
  function tipShow(ev, d) {
    asTip.innerHTML = asEsc(d.label) + ' — <span class="tt-cnt">' + d.cnt.toLocaleString()
        + '회</span> · 접속자 ' + d.ucnt.toLocaleString() + '명';
    asTip.style.display = 'block';
    tipMove(ev);
  }
  function tipMove(ev) {
    asTip.style.left = (ev.pageX + 14) + 'px';
    asTip.style.top = (ev.pageY - 12) + 'px';
  }
  function tipHide() { asTip.style.display = 'none'; }
  function asEsc(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

  /* ── 가로 막대 (메뉴/기기/브라우저) ── */
  function renderHBars(data) {
    var max = 0;
    data.forEach(function (d) { if (d.cnt > max) max = d.cnt; });
    var h = '';
    data.forEach(function (d, i) {
      var w = max > 0 ? Math.max(1.5, d.cnt / max * 100) : 0;
      h += '<div class="as-hbar-row" data-i="' + i + '">'
         + '<div class="as-hbar-label" title="' + asEsc(d.label) + '">' + asEsc(d.label) + '</div>'
         + '<div class="as-hbar-track"><div class="as-hbar-fill" style="width:' + w + '%"></div></div>'
         + '<div class="as-hbar-val">' + d.cnt.toLocaleString() + '</div>'
         + '</div>';
    });
    $('#asChart').html(h);
    $('#asChart .as-hbar-row')
      .on('mousemove', function (ev) { tipShow(ev, data[$(this).attr('data-i')]); })
      .on('mouseleave', tipHide);
  }

  /* ── 세로 컬럼 차트 (시간축) — SVG ── */
  function renderColumns(data) {
    var n = data.length;
    if (n === 0) { $('#asChart').html(''); return; }
    var max = 0;
    data.forEach(function (d) { if (d.cnt > max) max = d.cnt; });
    if (max === 0) max = 1;
    // 나이스 눈금 (1/2/5 × 10^k) — 눈금은 항상 step 의 정수배(고정 4분할이면 7.5 같은 소수 눈금이 생김)
    var step = niceStep(max / 4), ticks = Math.ceil(max / step), yMax = ticks * step;

    var padL = 46, padR = 12, padT = 14, padB = 34, plotH = 210;
    // 컨테이너 실폭에 맞춰 슬롯 산출 — 구간이 많으면 최소폭을 지키고 가로 스크롤로 넘긴다
    var availW = $('#asChart').width() || 860;
    var slot = Math.max(n > 40 ? 15 : 26, Math.floor((availW - padL - padR) / n));
    var barW = Math.min(48, Math.max(6, slot - 6));   // 구간이 적어도 마른 막대 유지
    var w = padL + padR + slot * n, h = padT + plotH + padB;
    var labelEvery = Math.max(1, Math.ceil(n / Math.max(1, Math.floor((w - padL - padR) / 56))));   // 라벨 간격 ≥56px

    var s = '<svg class="as-col-svg" width="' + w + '" height="' + h + '" role="img" aria-label="접속수 차트">';
    for (var g = 0; g <= ticks; g++) {
      var yv = step * g, y = padT + plotH - (yv / yMax) * plotH;
      s += '<line class="grid" x1="' + padL + '" y1="' + y + '" x2="' + (w - padR) + '" y2="' + y + '"/>';
      s += '<text class="axis-text" x="' + (padL - 6) + '" y="' + (y + 4) + '" text-anchor="end">' + yv.toLocaleString() + '</text>';
    }
    data.forEach(function (d, i) {
      var bh = (d.cnt / yMax) * plotH;
      var x = padL + slot * i + (slot - barW) / 2, y = padT + plotH - bh;
      // 상단만 4px 라운드, 바닥은 기준선에 고정
      var r = Math.min(4, barW / 2, bh);
      s += '<path class="bar" data-i="' + i + '" d="M' + x + ' ' + (padT + plotH)
         + ' V' + (y + r) + ' Q' + x + ' ' + y + ' ' + (x + r) + ' ' + y
         + ' H' + (x + barW - r) + ' Q' + (x + barW) + ' ' + y + ' ' + (x + barW) + ' ' + (y + r)
         + ' V' + (padT + plotH) + ' Z"/>';
      if (n <= 12 && d.cnt > 0) {
        s += '<text class="val-text" x="' + (x + barW / 2) + '" y="' + (y - 5) + '" text-anchor="middle">' + d.cnt.toLocaleString() + '</text>';
      }
      if (i % labelEvery === 0) {
        var lb = d.label;
        if (AS_DIM === 'DAY' || AS_DIM === 'WEEK7') lb = lb.substring(5);   // YYYY- 제거
        s += '<text class="axis-text" x="' + (x + barW / 2) + '" y="' + (padT + plotH + 18) + '" text-anchor="middle">' + asEsc(lb) + '</text>';
      }
    });
    s += '</svg>';
    $('#asChart').html(s);
    $('#asChart .bar')
      .on('mousemove', function (ev) { tipShow(ev, data[$(this).attr('data-i')]); })
      .on('mouseleave', tipHide);
  }

  function niceStep(raw) {
    if (raw <= 1) return 1;
    var pow = Math.pow(10, Math.floor(Math.log(raw) / Math.LN10));
    var f = raw / pow;
    return (f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10) * pow;
  }

  $(function () {
    var data = asData();
    if (AS_DIM === 'MENU' || AS_DIM === 'DEVICE' || AS_DIM === 'BROWSER') {
      renderHBars(data);
    } else {
      renderColumns(data);
      var rsTimer;
      $(window).on('resize', function () {
        clearTimeout(rsTimer);
        rsTimer = setTimeout(function () { renderColumns(data); }, 150);
      });
    }
  });
</script>
</lay:layout>
