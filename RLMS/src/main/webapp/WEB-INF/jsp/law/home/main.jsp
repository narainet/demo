<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/home/main.jsp
  송무 홈 — 송무관리 GNB 랜딩 대시보드 (LAW_MODULE_DESIGN.md §7.0).
  P1: 요약 카드 4종(클릭 시 해당 화면 이동). P4 에서 기일 그리드·최근 사건 확장.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">송무 홈</c:set>
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
    table.law-home-tbl { width:100%; border-collapse:collapse; }
    /* 표 글자 크기 = 표준 tbl-list 스케일(td 0.93em/th 0.95em) — 대시보드·타 송무 화면과 통일 */
    table.law-home-tbl th, table.law-home-tbl td { border:1px solid #ddd; padding:8px 10px; font-size:0.93em; }
    table.law-home-tbl th { background:#f7f8fa; font-size:0.95em; white-space:nowrap; }
    table.law-home-tbl td.nw { white-space:nowrap; }
    .law-home-empty { text-align:center; color:#888; padding:16px 0; }
    .law-cell-sub { color:#888; font-size:12px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>송무 홈</h1>
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
      <div class="law-home-sec"><span>오늘 기일</span><a href="<c:url value='/law/schedule/main.do'/>">일정관리 ›</a></div>
      <table class="law-home-tbl">
        <thead><tr><th style="width:11%;">시간</th><th style="width:22%;">사건번호</th><th style="width:16%;">기일구분</th><th>장소</th><th style="width:15%;">수행자</th></tr></thead>
        <tbody>
          <c:forEach var="h" items="${todayHearings}">
            <tr>
              <td class="nw"><c:if test="${fn:length(h.progTm) ge 4}">${fn:substring(h.progTm,0,2)}:${fn:substring(h.progTm,2,4)}</c:if></td>
              <td class="nw"><a href="<c:url value='/law/suit/view.do'/>?suitId=${h.suitId}"><c:out value="${h.caseNo}" default="(미입력)"/></a></td>
              <td class="nw"><c:out value="${h.dyprKindNm}" default="-"/></td>
              <td><c:out value="${h.place}" default="-"/></td>
              <td><c:out value="${h.staffNm}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty todayHearings}"><tr><td colspan="5" class="law-home-empty">오늘 기일이 없습니다.</td></tr></c:if>
        </tbody>
      </table>
    </div>
    <div>
      <div class="law-home-sec"><span>이번 주 기일</span><a href="<c:url value='/law/schedule/main.do'/>">일정관리 ›</a></div>
      <table class="law-home-tbl">
        <thead><tr><th style="width:13%;">일자</th><th style="width:11%;">시간</th><th style="width:22%;">사건번호</th><th style="width:16%;">기일구분</th><th>법원</th></tr></thead>
        <tbody>
          <c:forEach var="h" items="${weekHearings}">
            <tr>
              <td class="nw"><c:if test="${fn:length(h.progDt) ge 8}">${fn:substring(h.progDt,4,6)}-${fn:substring(h.progDt,6,8)}</c:if></td>
              <td class="nw"><c:if test="${fn:length(h.progTm) ge 4}">${fn:substring(h.progTm,0,2)}:${fn:substring(h.progTm,2,4)}</c:if></td>
              <td class="nw"><a href="<c:url value='/law/suit/view.do'/>?suitId=${h.suitId}"><c:out value="${h.caseNo}" default="(미입력)"/></a></td>
              <td class="nw"><c:out value="${h.dyprKindNm}" default="-"/></td>
              <td><c:out value="${h.courtNm}" default="-"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty weekHearings}"><tr><td colspan="5" class="law-home-empty">이번 주 기일이 없습니다.</td></tr></c:if>
        </tbody>
      </table>
    </div>
  </div>

  <div class="law-home-sec" style="margin-top:22px;"><span>최근 등록 사건</span><a href="<c:url value='/law/suit/list.do'/>">소송조회 ›</a></div>
  <table class="law-home-tbl">
    <thead><tr><th style="width:10%;">사건번호</th><th>사건명</th><th style="width:12%;">법원</th><th style="width:6%;">심급</th><th style="width:8%;">소송결과</th><th style="width:9%;">등록일</th></tr></thead>
    <tbody>
      <c:forEach var="s" items="${recentSuits}">
        <tr>
          <td class="nw"><a href="<c:url value='/law/suit/view.do'/>?suitId=${s.suitId}"><c:out value="${s.caseNo}" default="(미입력)"/></a></td>
          <td><c:out value="${s.caseNm}" default="-"/></td>
          <td><c:out value="${s.courtNm}" default="-"/></td>
          <td class="nw"><c:out value="${s.instanceNm}" default="-"/></td>
          <td class="nw"><c:out value="${s.rsltDispNm}" default="진행중"/></td>
          <td class="nw"><c:if test="${not empty s.regDt and fn:length(s.regDt) ge 8}">${fn:substring(s.regDt,0,4)}-${fn:substring(s.regDt,4,6)}-${fn:substring(s.regDt,6,8)}</c:if></td>
        </tr>
      </c:forEach>
      <c:if test="${empty recentSuits}"><tr><td colspan="6" class="law-home-empty">등록된 사건이 없습니다.</td></tr></c:if>
    </tbody>
  </table>
</lay:layout>
