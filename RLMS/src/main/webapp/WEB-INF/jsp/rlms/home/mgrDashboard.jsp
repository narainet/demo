<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/home/mgrDashboard.jsp
  업무관리자 대시보드 — 로그인 후 진입점.
  구성(2026-07-31 순서변경): ①바로가기 카드 ②승인대기/최근처리 2단 ③공지/인기검색어 2단 ④운영현황 스탯 타일
  (스탯 타일은 본래 최상단이었으나 공지 아래로 이동 — 업무 동선 카드를 먼저 보여준다)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ page import="java.util.List" %>
<%@ page import="egovframework.com.cmm.util.EgovUserDetailsHelper" %>
<%@ page import="egovframework.com.uss.ion.brd.service.BrandInfo" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 시스템관리 영역 링크(접속로그/사용자관리)는 ADMIN 전용 메뉴(L6 파생 403) —
     비ADMIN(승인자 등)에게는 링크를 노출하지 않는다 (2026-07-10, promWorkList 관례) --%>
<%
  List<String> _dashAuths = EgovUserDetailsHelper.getAuthorities();
  boolean _dashIsAdmin = _dashAuths != null && _dashAuths.contains("ROLE_ADMIN");
  pageContext.setAttribute("dashIsAdmin", _dashIsAdmin);
%>
<%-- 브랜드 문구는 관리자 > 브랜드설정(COM_BRAND) 단일 원천. 페이지 <title> 은 데코레이터보다
     먼저 렌더되므로 데코레이터가 담아 둔 pageContext 속성을 못 본다 → BrandInfo 를 직접 조회. --%>
<c:set var="pageTitle"><%= BrandInfo.getText() %> - 업무관리자 대시보드</c:set>
<lay:layout title="${pageTitle}">
<h1>업무관리자 대시보드</h1>
<p><c:out value="${loginUser.name}"/> 님 환영합니다.</p>

<%-- 비밀번호 유효기간 배너(Globals.ExpirePwdDay) — 임박(D-7)/만료 시에만 노출 --%>
<c:if test="${not empty pwdDaysLeft and pwdDaysLeft le 7}">
  <div class="rlms-pwd-banner ${pwdDaysLeft le 0 ? 'expired' : ''}">
    <span>
      <c:choose>
        <c:when test="${pwdDaysLeft le 0}">🔒 비밀번호가 <b>만료</b>되었습니다 — 변경 후 <c:out value="${pwdPassedDay}"/>일 경과 (유효기간 <c:out value="${pwdExpireDay}"/>일). 지금 변경해 주세요.</c:when>
        <c:otherwise>🔑 비밀번호 만료까지 <b><c:out value="${pwdDaysLeft}"/>일</b> 남았습니다 (변경 후 <c:out value="${pwdPassedDay}"/>일 경과).</c:otherwise>
      </c:choose>
    </span>
    <a class="krds-btn small ${pwdDaysLeft le 0 ? 'primary' : ''}" href="<c:url value='/uss/umt/my/password.do'/>">비밀번호 변경</a>
  </div>
</c:if>

<%-- 합성 필터(PENDING/MYREJ) — 스탯 카운트(pendingCnt/myRejectedCnt)와 동일 기준의 목록으로 직결 (2026-07-09).
     스탯 타일은 페이지 하단(공지 아래)으로 이동했으나, 이 URL 변수는 아래 카드/패널들도 함께 쓰므로 여기서 선언한다. --%>
<c:url var="rlmsWorkPendingUrl" value="/rlms/promwork/selectPromWorkList.do"><c:param name="st" value="PENDING"/></c:url>
<c:url var="rlmsWorkRejectUrl" value="/rlms/promwork/selectPromWorkList.do"><c:param name="st" value="MYREJ"/></c:url>

<%-- ① 바로가기 카드 --%>
<div class="krds-card-group">
  <a href="<c:url value='/rlms/prom/editor.do'/>" class="krds-card">
    <h3>규정 관리</h3>
    <p>규정 편집 — 연혁·조문 등록/수정, 본문 미리보기·대비표 (편집은 규정 편집 화면으로 일원화)</p>
  </a>
  <%-- 헤더 배지와 동일 동선: 승인대기(승인요청) 필터로 진입. 상태는 ASCII 코드(st)만 전달. --%>
  <a href="${rlmsWorkPendingUrl}" class="krds-card">
    <%-- 배지/현황은 mgr 데코레이터의 주기 폴링(badgeCountsJson.do)이 갱신 — 0 이면 숨김 --%>
    <h3>작업승인관리 <span class="dash-badge" id="dashPendingBadge" style="display:none;">승인대기 <span id="dashPendingCnt">0</span></span></h3>
    <p>승인요청 / 반려 처리</p>
    <p class="dash-reject" id="dashRejectLine" style="display:none;">⚠ 내 반려 <span id="dashRejectCnt">0</span>건 — 확인 후 재신청</p>
  </a>
  <a href="<c:url value='/rlms/prom/validateExisting.do'/>" class="krds-card">
    <h3>유효성 검사</h3>
    <p>운영 중인 모든 규정 무결성 검증</p>
  </a>
  <a href="<c:url value='/rlms/cate/selectCateTree.do'/>" class="krds-card">
    <h3>분류 관리</h3>
    <p>규정 분류 트리 + 부서/개정구분</p>
  </a>
  <%-- 사용자관리(90010000)는 ADMIN 전용 메뉴 — 비ADMIN 에겐 카드 숨김 --%>
  <c:if test="${dashIsAdmin}">
    <a href="<c:url value='/uss/umt/EgovUserManage.do'/>" class="krds-card">
      <h3>사용자 관리</h3>
      <p>사용자/권한/역할</p>
    </a>
  </c:if>
  <a href="<c:url value='/uss/olh/qna/selectQnaAnswerList.do'/>" class="krds-card">
    <h3>Q&amp;A 관리</h3>
    <p>사용자 문의 답변</p>
  </a>
</div>

<%-- ①.5 내 요청 현황(2026-07-28) — 작성자 관점: 내가 신청한 회차의 현재 상태(심사중/반려+사유/최근 승인).
     판정 기준은 배지·MYREJ 필터와 동일(사이클 마지막 승인요청 행=나). 요청 이력이 없으면 패널 숨김. --%>
<c:if test="${not empty dashMyWorks}">
<section class="dash-panel" style="margin-top:24px;">
  <div class="dash-panel-head">
    <h2>내 요청 현황
      <span class="dash-mychip ${myPendingCnt gt 0 ? 'on' : ''}">심사중 <c:out value="${empty myPendingCnt ? 0 : myPendingCnt}"/></span>
      <span class="dash-mychip danger ${myRejectedCnt gt 0 ? 'on' : ''}">반려 <c:out value="${empty myRejectedCnt ? 0 : myRejectedCnt}"/></span>
    </h2>
    <a class="dash-more" href="<c:url value='/rlms/promwork/selectPromWorkList.do'/>">전체보기</a>
  </div>
  <c:forEach var="w" items="${dashMyWorks}">
  <div class="dash-row">
    <span class="dash-chip ${w.status eq '승인반려' ? 'rej' : ''}${w.status eq '승인완료' ? 'ok' : ''}"><c:out value="${w.status}"/></span>
    <c:choose>
      <c:when test="${w.status eq '승인반려'}"><c:set var="myWorkUrl" value="${rlmsWorkRejectUrl}"/></c:when>
      <c:when test="${w.status eq '승인요청'}"><c:set var="myWorkUrl" value="${rlmsWorkPendingUrl}"/></c:when>
      <c:otherwise><c:set var="myWorkUrl"><c:url value='/rlms/promwork/selectPromWorkList.do'/></c:set></c:otherwise>
    </c:choose>
    <a class="dash-row-title" href="${myWorkUrl}" title="<c:out value='${w.title}'/><c:if test='${not empty w.reason}'> — 사유: <c:out value="${w.reason}"/></c:if>">
      <c:out value="${w.title}"/><c:if test="${w.status eq '승인반려' and not empty w.reason}"><span class="dash-myreason"> — 사유: <c:out value="${w.reason}"/></span></c:if>
    </a>
    <span class="dash-muted"><c:out value="${w.actorNm}"/> · <c:out value="${w.insDt}"/></span>
  </div>
  </c:forEach>
</section>
</c:if>

<%-- ② 승인대기 / 최근 처리 2단 --%>
<div class="dash-2col">
  <section class="dash-panel">
    <div class="dash-panel-head">
      <h2>승인대기 최근 5건</h2>
      <a class="dash-more" href="${rlmsWorkPendingUrl}">전체보기</a>
    </div>
    <c:choose>
      <c:when test="${empty dashPending}"><p class="dash-empty">승인대기 건이 없습니다.</p></c:when>
      <c:otherwise>
        <c:forEach var="w" items="${dashPending}">
        <div class="dash-row">
          <span class="dash-chip"><c:out value="${w.status}"/></span>
          <a class="dash-row-title" href="${rlmsWorkPendingUrl}" title="<c:out value='${w.title}'/>"><c:out value="${w.title}"/></a>
          <span class="dash-muted"><c:out value="${w.userNm}"/> · <c:out value="${w.insDt}"/></span>
        </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </section>
  <section class="dash-panel">
    <div class="dash-panel-head">
      <h2>최근 처리 이력</h2>
      <a class="dash-more" href="<c:url value='/rlms/promwork/selectPromWorkHistory.do'/>">전체보기</a>
    </div>
    <c:choose>
      <c:when test="${empty dashRecentWorks}"><p class="dash-empty">처리 이력이 없습니다.</p></c:when>
      <c:otherwise>
        <c:forEach var="w" items="${dashRecentWorks}">
        <div class="dash-row">
          <span class="dash-chip"><c:out value="${w.status}"/></span>
          <span class="dash-row-title" title="<c:out value='${w.title}'/>"><c:out value="${w.title}"/></span>
          <span class="dash-muted"><c:out value="${w.userNm}"/> · <c:out value="${w.insDt}"/></span>
        </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </section>
</div>

<%-- ③ 공지 / 인기 검색어 2단 --%>
<div class="dash-2col">
  <section class="dash-panel">
    <div class="dash-panel-head">
      <h2>공지사항</h2>
      <%-- 보드 미해석(noticeBbsId null) 시 ?bbsId= 깨진 링크 방지.
           열람은 사용자 URL(/cop/bbs/user/*) — 관리 URL(/cop/bbs/*)은 ADMIN 전용이라 편집자·승인자가 403 이 난다.
           게시글 관리(등록/수정)는 시스템관리 > 게시판관리 동선. --%>
      <c:if test="${not empty noticeBbsId}"><a class="dash-more" href="<c:url value='/cop/bbs/user/selectArticleList.do'/>?bbsId=${noticeBbsId}">전체보기</a></c:if>
    </div>
    <c:choose>
      <c:when test="${empty notices}"><p class="dash-empty">등록된 공지가 없습니다.</p></c:when>
      <c:otherwise>
        <c:forEach var="n" items="${notices}">
        <div class="dash-row">
          <a class="dash-row-title" href="<c:url value='/cop/bbs/user/selectArticleDetail.do'/>?bbsId=${noticeBbsId}&amp;nttId=${n.nttId}" title="<c:out value='${n.nttSj}'/>"><c:out value="${n.nttSj}"/></a>
          <span class="dash-muted"><c:out value="${n.regDt}"/></span>
        </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </section>
  <section class="dash-panel">
    <div class="dash-panel-head">
      <h2>인기 검색어 <span class="dash-muted" style="font-weight:normal;font-size:12px;">최근 30일</span></h2>
      <a class="dash-more" href="<c:url value='/rlms/stats/keywordStats.do'/>">검색어 통계</a>
    </div>
    <c:choose>
      <c:when test="${empty popularKwds}"><p class="dash-empty">집계된 검색어가 없습니다.</p></c:when>
      <c:otherwise>
        <div class="dash-kwds">
          <c:forEach var="k" items="${popularKwds}" varStatus="st">
          <c:url var="kUrl" value="/rlms/fulltext/searchAll.do"><c:param name="searchKeyword" value="${k}"/></c:url>
          <a class="dash-kwd" href="${kUrl}"><span class="rank">${st.index + 1}</span><c:out value="${k}"/></a>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </section>
</div>

<%-- ④ 운영 현황 스탯 타일 — 공지사항 아래(2026-07-31 이동) --%>
<c:if test="${not empty dash}">
<div class="dash-stats">
  <a class="dash-stat" href="<c:url value='/rlms/prom/selectPromList.do'/>">
    <span class="t">현행 규정</span><span class="v"><c:out value="${dash.curProms}"/></span>
  </a>
  <a class="dash-stat" href="<c:url value='/rlms/prom/selectPromList.do'/>">
    <span class="t">전체 규정</span><span class="v"><c:out value="${dash.totalLaws}"/></span>
  </a>
  <a class="dash-stat ${pendingCnt gt 0 ? 'warn' : ''}" href="${rlmsWorkPendingUrl}">
    <span class="t">승인대기</span><span class="v"><c:out value="${empty pendingCnt ? 0 : pendingCnt}"/></span>
  </a>
  <a class="dash-stat ${myRejectedCnt gt 0 ? 'danger' : ''}" href="${rlmsWorkRejectUrl}">
    <span class="t">내 반려</span><span class="v"><c:out value="${empty myRejectedCnt ? 0 : myRejectedCnt}"/></span>
  </a>
  <a class="dash-stat ${dash.qnaNoAnswer gt 0 ? 'warn' : ''}" href="<c:url value='/uss/olh/qna/selectQnaAnswerList.do'/>">
    <span class="t">미답변 Q&amp;A</span><span class="v"><c:out value="${dash.qnaNoAnswer}"/></span>
  </a>
  <%-- 접속로그 화면은 ADMIN 전용 — 비ADMIN 은 숫자만(링크 없음) --%>
  <c:choose>
    <c:when test="${dashIsAdmin}">
      <a class="dash-stat" href="<c:url value='/sym/log/clg/SelectLoginLogList.do'/>">
        <span class="t">오늘 접속</span><span class="v"><c:out value="${dash.todayLogins}"/></span>
      </a>
    </c:when>
    <c:otherwise>
      <span class="dash-stat">
        <span class="t">오늘 접속</span><span class="v"><c:out value="${dash.todayLogins}"/></span>
      </span>
    </c:otherwise>
  </c:choose>
</div>
</c:if>

<style>
  .rlms-pwd-banner { display:flex; justify-content:space-between; align-items:center; gap:12px; padding:12px 18px;
                     margin-top:16px; border:1px solid #fec84b; background:#fffaeb; color:#b54708; border-radius:10px; font-size:14px; }
  .rlms-pwd-banner.expired { border-color:#fda29b; background:#fef3f2; color:#b42318; }
  .rlms-pwd-banner a { white-space:nowrap; }
  /* 운영 현황 스탯 타일 */
  .dash-stats { display:grid; grid-template-columns:repeat(auto-fit, minmax(140px, 1fr)); gap:12px; margin-top:24px; }
  .dash-stat { display:block; background:#f4f6fb; border-radius:8px; padding:14px 16px; text-decoration:none; }
  .dash-stat .t { display:block; font-size:13px; color:#555; }
  .dash-stat .v { display:block; font-size:24px; font-weight:700; color:#1f3974; margin-top:4px; }
  .dash-stat:hover { background:#e9eef8; }
  .dash-stat.warn .v { color:#b54708; }
  .dash-stat.danger .v { color:#b42318; }
  .krds-card-group {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 16px; margin-top: 24px;
  }
  .krds-card {
    display: block; padding: 20px; background: #fff; border: 1px solid #d1d3d8;
    border-radius: 8px; text-decoration: none; color: #333;
    transition: box-shadow .15s ease;
  }
  .krds-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.08); border-color: #1f3974; }
  .krds-card h3 { margin: 0 0 8px; color: #1f3974; }
  .krds-card p { margin: 0; color: #666; font-size: 0.92em; }
  /* 승인 현황 배지 (작업승인관리 카드) */
  .dash-badge {
    display: inline-flex; align-items: center; gap: 4px;
    padding: 2px 9px; margin-left: 6px; border-radius: 11px;
    background: #c0392b; color: #fff; font-size: 0.72em; font-weight: 700;
    vertical-align: middle;
  }
  .dash-reject {
    margin-top: 8px !important; color: #b0392b !important; font-weight: 600;
  }
  /* 2단 패널 */
  .dash-2col { display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:24px; }
  @media (max-width: 900px) { .dash-2col { grid-template-columns:1fr; } }
  .dash-panel { background:#fff; border:1px solid #d1d3d8; border-radius:8px; padding:16px 18px; min-width:0; }
  .dash-panel-head { display:flex; justify-content:space-between; align-items:baseline; margin-bottom:8px; }
  .dash-panel-head h2 { margin:0; font-size:16px; color:#1f3974; }
  .dash-more { color:#1f3974; font-size:13px; text-decoration:none; }
  .dash-more:hover { text-decoration:underline; }
  .dash-row { display:flex; align-items:center; gap:8px; padding:7px 0; border-bottom:1px solid #eceef2; font-size:14px; min-width:0; }
  .dash-row:last-child { border-bottom:0; }
  .dash-row-title { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:#1a1a1a; text-decoration:none; }
  a.dash-row-title:hover { text-decoration:underline; color:#1f3974; }
  .dash-muted { color:#888; font-size:12.5px; white-space:nowrap; }
  .dash-chip { flex:0 0 auto; padding:1px 8px; border-radius:10px; font-size:12px; background:#eef3fb; color:#1b5fbf; }
  /* 내 요청 현황 — 상태 칩 색 + 헤더 카운트 칩 + 반려 사유 인라인 */
  .dash-chip.rej { background:#fef3f2; color:#b42318; }
  .dash-chip.ok { background:#e6f4ea; color:#1a7f37; }
  .dash-mychip { display:inline-block; margin-left:8px; padding:1px 10px; border-radius:11px; font-size:12.5px;
                 font-weight:600; background:#eef3fb; color:#556; vertical-align:middle; }
  .dash-mychip.on { background:#fff4e5; color:#9a5b00; }
  .dash-mychip.danger.on { background:#fef3f2; color:#b42318; }
  .dash-myreason { color:#b42318; font-size:12.5px; }
  .dash-empty { color:#888; font-size:13.5px; padding:10px 0; margin:0; }
  .dash-kwds { display:flex; flex-wrap:wrap; gap:8px; padding-top:4px; }
  .dash-kwd { display:inline-flex; align-items:center; gap:6px; padding:3px 12px; border:1px solid #d1d3d8;
              border-radius:14px; font-size:13px; color:#333; text-decoration:none; background:#fff; }
  .dash-kwd .rank { font-weight:700; color:#1f3974; font-size:12px; }
  .dash-kwd:hover { border-color:#1f3974; color:#1f3974; background:#f4f6fb; }
</style>
</lay:layout>
