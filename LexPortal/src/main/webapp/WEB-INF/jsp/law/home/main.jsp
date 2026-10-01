<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/home/main.jsp
  대시보드 — 업무 진입 랜딩 현황판, URL=/law/index.do (LAW_MODULE_DESIGN.md §7.0. 2026-08-04 '송무 홈'에서 개명).
  P1: 요약 카드 4종(클릭 시 해당 화면 이동). P4 에서 기일 그리드·최근 사건 확장.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">대시보드</c:set>
<c:set var="pageHead">
  
  <style>
    .law-home-cards { display: flex; flex-wrap: wrap; gap: 16px; margin: 20px 0; }
    .law-home-card {
      flex: 1 1 200px; min-width: 200px; padding: 20px 24px;
      border: 1px solid var(--krds-color-light-gray-30, #d8d8d8); border-radius: 12px;
      background: #fff; text-decoration: none; color: inherit;
      transition: box-shadow .15s;
    }
    .law-home-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,.08); }
    .law-home-card .card-label { display: block; font-size: 15px; color: #555; margin-bottom: 8px; }
    .law-home-card .card-count { display: block; font-size: 32px; font-weight: 700; line-height: 1; }
    .law-home-card.accent .card-count { color: #256ef4; }
    .law-home-grids { display:grid; grid-template-columns:1fr 1fr; gap:18px; margin-top:8px; }
    @media (max-width:900px){ .law-home-grids { grid-template-columns:1fr; } }
    .law-home-sec { font-size:16px; font-weight:700; margin:14px 0 8px; display:flex; justify-content:space-between; align-items:center; }
    .law-home-sec a { font-size:13px; font-weight:400; color:#256ef4; text-decoration:none; }
    .law-home-sec-note { font-size:12.5px; font-weight:400; color:#8a919c; }
    table.law-home-tbl { width:100%; border-collapse:collapse; }
    /* 표 글자 크기 = 표준 tbl-list 스케일(td 0.93em/th 0.95em) — 대시보드·타 송무 화면과 통일 */
    table.law-home-tbl th, table.law-home-tbl td { border:1px solid #ddd; padding:8px 10px; font-size:0.93em; }
    table.law-home-tbl th { background:#f7f8fa; font-size:0.95em; white-space:nowrap; }
    table.law-home-tbl td.nw { white-space:nowrap; }
    .law-home-empty { text-align:center; color:#888; padding:16px 0; }
    .law-cell-sub { color:#888; font-size:12px; }

    /* ── 모바일(≤768) — 표를 카드 목록으로 (2026-08-06 사용자 지시)
         5~6열 표를 폰 폭에 밀어 넣으면 th 가 nowrap 이라 '심급소송결과등록일' 처럼 글자가 겹쳐 읽을 수 없었다.
         가로 스크롤 대신 행=카드로 세운다: 사건번호가 카드 제목(td.hd, order 로 맨 위),
         나머지는 [라벨 값] 줄(td::before = data-label). 값이 없는 보조 항목(td.nodata)은 아예 숨겨
         '- - -' 가 늘어서지 않게 한다. 데스크톱(>768)은 기존 표 그대로. ── */
    @media (max-width:768px){
      table.law-home-tbl { border:0; }
      table.law-home-tbl thead { display:none; }
      table.law-home-tbl, table.law-home-tbl tbody, table.law-home-tbl tr, table.law-home-tbl td { display:block; width:100%; box-sizing:border-box; }
      table.law-home-tbl tr {
        display:flex; flex-direction:column;
        margin:0 0 8px; padding:12px 14px;
        border:1px solid #e2e5ea; border-radius:10px; background:#fff;
      }
      table.law-home-tbl td { border:0; padding:2px 0; font-size:13.5px; white-space:normal; display:flex; gap:8px; }
      table.law-home-tbl td::before {
        content:attr(data-label); flex:0 0 60px;
        color:#6b7280; font-size:12.5px; line-height:1.65; font-weight:500;
      }
      /* 카드 제목 = 사건번호 (DOM 상 시간/일자 뒤라 order 로 끌어올린다) */
      table.law-home-tbl td.hd {
        order:-1; display:block;
        margin-bottom:6px; padding-bottom:6px; border-bottom:1px solid #eef0f4;
        font-size:15px; font-weight:700;
      }
      table.law-home-tbl td.hd::before { display:none; }
      table.law-home-tbl td.hd a { color:#1f3974; text-decoration:none; }
      table.law-home-tbl td.nodata { display:none; }
      /* 빈 상태 행은 카드가 아니라 안내 박스로 */
      table.law-home-tbl tr.law-home-emptyrow { display:block; padding:0; border-style:dashed; background:#fafbfc; }
      table.law-home-tbl tr.law-home-emptyrow td { display:block; font-size:13.5px; }
      table.law-home-tbl tr.law-home-emptyrow td::before { display:none; }

      /* ── 아코디언(≤768, 2026-08-06 사용자 지시) — 한 번에 한 구획만 펼침.
           기본 펼침 = 오늘 기일 > 이번 주 기일 > 최근 등록 사건 순으로 '내용이 있는 첫 구획'.
           카드가 20장 넘게 이어지던 대시보드를 한 화면에 들어오게 한다. ── */
      .law-home-sec[data-sec] {
        cursor:pointer; margin:0 0 8px; padding:11px 14px;
        border:1px solid #d6deea; border-radius:10px; background:#f3f6fb;
        font-size:15px; color:#1f3974; -webkit-tap-highlight-color:transparent;
      }
      .law-home-sec[data-sec][style] { margin-top:14px !important; }   /* 최근 등록 사건 인라인 margin 보정 */
      .law-home-sec[data-sec] a { flex:0 0 auto; }
      .law-home-arr {
        flex:0 0 auto; width:8px; height:8px; margin-left:10px;
        border-right:2px solid #3a5da8; border-bottom:2px solid #3a5da8;
        transform:translateY(-2px) rotate(45deg); transition:transform .15s ease;
      }
      .law-home-sec.is-open .law-home-arr { transform:translateY(2px) rotate(225deg); }
      .law-home-cnt { margin-left:6px; font-size:12.5px; font-weight:500; color:#45526b; }
      .law-home-grids { gap:0; }
    }
    /* 데스크톱은 아코디언 없음 — 표는 항상 보이고 셰브론·건수는 숨긴다 */
    @media (min-width:769px) {
      .law-home-arr, .law-home-cnt { display:none; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>대시보드</h1>
    <p class="page-desc">소송 사건 현황 요약입니다. 카드를 누르면 해당 화면으로 이동합니다.</p>
  </div>

  <div class="law-home-cards">
    <a class="law-home-card accent" href="<c:url value='/law/suit/list.do'/>">
      <span class="card-label">진행중 사건</span>
      <span class="card-count"><c:out value="${summary.activeSuits}" default="0"/></span>
    </a>
    <a class="law-home-card" href="<c:url value='/law/suit/list.do'/>">
      <span class="card-label">이번 달 신규 사건</span>
      <span class="card-count"><c:out value="${summary.newSuitsThisMonth}" default="0"/></span>
    </a>
    <a class="law-home-card" href="<c:url value='/law/req/list.do'/>">
      <span class="card-label">미처리 소송의뢰</span>
      <span class="card-count"><c:out value="${summary.pendingReqs}" default="0"/></span>
    </a>
    <a class="law-home-card" href="<c:url value='/law/doc/approvalList.do'/>">
      <span class="card-label">승인대기 문서</span>
      <span class="card-count"><c:out value="${summary.pendingDocs}" default="0"/></span>
    </a>
  </div>

  <div class="law-home-grids">
    <div>
      <div class="law-home-sec" data-sec="today"><span>오늘 기일</span><a href="<c:url value='/law/schedule/main.do'/>">일정관리 ›</a></div>
      <table class="law-home-tbl">
        <thead><tr><th style="width:11%;">시간</th><th style="width:22%;">사건번호</th><th style="width:16%;">기일구분</th><th>장소</th><th style="width:15%;">수행자</th></tr></thead>
        <tbody>
          <c:forEach var="h" items="${todayHearings}">
            <tr>
              <td class="nw" data-label="시간"><c:if test="${fn:length(h.progTm) ge 4}">${fn:substring(h.progTm,0,2)}:${fn:substring(h.progTm,2,4)}</c:if></td>
              <td class="nw hd" data-label="사건번호"><a href="<c:url value='/law/suit/view.do'/>?suitId=${h.suitId}"><c:out value="${h.caseNo}" default="(미입력)"/></a></td>
              <td class="nw ${empty h.dyprKindNm ? 'nodata' : ''}" data-label="기일구분"><c:out value="${h.dyprKindNm}" default="-"/></td>
              <td class="${empty h.place ? 'nodata' : ''}" data-label="장소"><c:out value="${h.place}" default="-"/></td>
              <td class="${empty h.staffNm ? 'nodata' : ''}" data-label="수행자"><c:out value="${h.staffNm}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty todayHearings}"><tr class="law-home-emptyrow"><td colspan="5" class="law-home-empty">오늘 기일이 없습니다.</td></tr></c:if>
        </tbody>
      </table>
    </div>
    <div>
      <div class="law-home-sec" data-sec="week"><span>이번 주 기일 <span class="law-home-sec-note">(오늘 제외)</span></span><a href="<c:url value='/law/schedule/main.do'/>">일정관리 ›</a></div>
      <table class="law-home-tbl">
        <thead><tr><th style="width:13%;">일자</th><th style="width:11%;">시간</th><th style="width:22%;">사건번호</th><th style="width:16%;">기일구분</th><th>법원</th></tr></thead>
        <tbody>
          <c:forEach var="h" items="${weekHearings}">
            <tr>
              <td class="nw" data-label="일자"><c:if test="${fn:length(h.progDt) ge 8}">${fn:substring(h.progDt,4,6)}-${fn:substring(h.progDt,6,8)}</c:if></td>
              <td class="nw" data-label="시간"><c:if test="${fn:length(h.progTm) ge 4}">${fn:substring(h.progTm,0,2)}:${fn:substring(h.progTm,2,4)}</c:if></td>
              <td class="nw hd" data-label="사건번호"><a href="<c:url value='/law/suit/view.do'/>?suitId=${h.suitId}"><c:out value="${h.caseNo}" default="(미입력)"/></a></td>
              <td class="nw ${empty h.dyprKindNm ? 'nodata' : ''}" data-label="기일구분"><c:out value="${h.dyprKindNm}" default="-"/></td>
              <td class="${empty h.courtNm ? 'nodata' : ''}" data-label="법원"><c:out value="${h.courtNm}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty weekHearings}"><tr class="law-home-emptyrow"><td colspan="5" class="law-home-empty">오늘 외에 이번 주 기일이 없습니다.</td></tr></c:if>
        </tbody>
      </table>
    </div>
  </div>

  <div class="law-home-sec" data-sec="recent" style="margin-top:22px;"><span>최근 등록 사건</span><a href="<c:url value='/law/suit/list.do'/>">소송조회 ›</a></div>
  <table class="law-home-tbl">
    <thead><tr><th style="width:10%;">사건번호</th><th>사건명</th><th style="width:12%;">법원</th><th style="width:6%;">심급</th><th style="width:8%;">소송결과</th><th style="width:9%;">등록일</th></tr></thead>
    <tbody>
      <c:forEach var="s" items="${recentSuits}">
        <tr>
          <td class="nw hd" data-label="사건번호"><a href="<c:url value='/law/suit/view.do'/>?suitId=${s.suitId}"><c:out value="${s.caseNo}" default="(미입력)"/></a></td>
          <td class="${empty s.caseNm ? 'nodata' : ''}" data-label="사건명"><c:out value="${s.caseNm}" default="-"/></td>
          <td class="${empty s.courtNm ? 'nodata' : ''}" data-label="법원"><c:out value="${s.courtNm}" default="-"/></td>
          <td class="nw ${empty s.instanceNm ? 'nodata' : ''}" data-label="심급"><c:out value="${s.instanceNm}" default="-"/></td>
          <td class="nw" data-label="소송결과"><c:out value="${s.rsltDispNm}" default="진행중"/></td>
          <td class="nw" data-label="등록일"><c:if test="${not empty s.regDt and fn:length(s.regDt) ge 8}">${fn:substring(s.regDt,0,4)}-${fn:substring(s.regDt,4,6)}-${fn:substring(s.regDt,6,8)}</c:if></td>
        </tr>
      </c:forEach>
      <c:if test="${empty recentSuits}"><tr class="law-home-emptyrow"><td colspan="6" class="law-home-empty">등록된 사건이 없습니다.</td></tr></c:if>
    </tbody>
  </table>

<script>
/* 모바일(≤768) 대시보드 아코디언 — 한 번에 한 구획만 펼친다(2026-08-06 사용자 지시).
   기본 펼침 = 오늘 기일 > 이번 주 기일 > 최근 등록 사건 순으로 '내용이 있는 첫 구획'
   (셋 다 비면 최근 등록 사건). 데스크톱(>768)은 전부 펼친 원형 — 표에 인라인 display 를 남기지 않는다.
   ⛔표시/숨김은 인라인 display 로 한다: 모바일 카드 규칙이 table 을 display:block 으로 바꾸므로
     클래스로 감추면 되돌릴 때 어떤 값으로 복귀할지가 화면 폭에 따라 갈린다. */
(function () {
  var mq = window.matchMedia ? window.matchMedia('(max-width: 768px)') : null;
  var secs = [];

  function dataRows(tbl) {
    return tbl ? tbl.querySelectorAll('tbody tr:not(.law-home-emptyrow)').length : 0;
  }

  Array.prototype.forEach.call(document.querySelectorAll('.law-home-sec[data-sec]'), function (head) {
    var tbl = head.nextElementSibling;
    if (!tbl || tbl.tagName !== 'TABLE') { return; }
    var cnt = dataRows(tbl);

    var title = head.querySelector('span');
    if (title) {
      var badge = document.createElement('span');
      badge.className = 'law-home-cnt';
      badge.textContent = cnt > 0 ? (cnt + '건') : '없음';
      title.appendChild(badge);
    }
    var arr = document.createElement('span');
    arr.className = 'law-home-arr';
    arr.setAttribute('aria-hidden', 'true');
    head.appendChild(arr);

    head.setAttribute('role', 'button');
    head.setAttribute('tabindex', '0');
    var sec = { head: head, tbl: tbl, cnt: cnt, open: false };
    secs.push(sec);

    function toggle(e) {
      if (e && e.target.closest('a')) { return; }   // 헤더 안 [일정관리 ›]·[소송조회 ›] 링크는 이동
      open(sec.open ? null : sec);
    }
    head.addEventListener('click', toggle);
    head.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ' || e.key === 'Spacebar') { e.preventDefault(); toggle(); }
    });
  });

  /* 하나를 펼치면 나머지는 접는다(단일 오픈 아코디언). target=null 이면 전부 접힘. */
  function open(target) {
    secs.forEach(function (s) {
      s.open = (s === target);
      s.head.classList.toggle('is-open', s.open);
      s.head.setAttribute('aria-expanded', s.open ? 'true' : 'false');
    });
    render();
  }

  function render() {
    var mobile = !mq || mq.matches;
    secs.forEach(function (s) {
      if (mobile && !s.open) { s.tbl.style.display = 'none'; }
      else { s.tbl.style.removeProperty('display'); }
    });
  }

  // 기본 펼침 — 내용이 있는 첫 구획(오늘 > 이번 주 > 최근), 셋 다 비면 최근 등록 사건
  var first = null;
  for (var i = 0; i < secs.length; i++) { if (secs[i].cnt > 0) { first = secs[i]; break; } }
  if (!first && secs.length) { first = secs[secs.length - 1]; }
  open(first);

  if (mq) {
    if (mq.addEventListener) { mq.addEventListener('change', render); }
    else if (mq.addListener) { mq.addListener(render); }
  }
  window.addEventListener('resize', render);
  window.addEventListener('load', render);
})();
</script>
</lay:layout>
