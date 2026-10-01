<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/home/userHome.jsp
  사용자 홈 — 로그인 후 진입점 (front decorator).

  구성(2026-07-31 재배치):
        ① 통합검색 콘솔(검색조건 + 구분 체크박스[ccm 정본] + 공포일)
        ② 읽어야 할 규정(필수 열람) + 공지사항(BBS) 2단 — 필수 열람 0건이면 공지사항 전폭
        ②.5 즐겨찾기 규정 개정 소식(해당 건 있을 때만)
        ③ 최근 개정 + 바로가기(내 메모·즐겨찾기·FAQ·Q&A) 2단
        ④ 현행 보유 규정 집계 — 맨 아래 전폭(구분이 늘면 타일이 줄바꿈)
        ⑤ 배너
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="/WEB-INF/tlds/egovc.tld" prefix="egovc" %>
<%@ page import="egovframework.com.uss.ion.brd.service.BrandInfo" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 브랜드 문구는 관리자 > 브랜드설정(COM_BRAND) 단일 원천. 페이지 <title> 은 데코레이터보다
     먼저 렌더되므로 데코레이터가 담아 둔 pageContext 속성을 못 본다 → BrandInfo 를 직접 조회. --%>
<%-- 홈은 좌측 규정분류 트리 제거(전역 드로어가 대체) — jstree/cate-search-tree 불요 --%>
<c:set var="pageTitle"><%= BrandInfo.getText() %> - 사용자 홈</c:set>
<lay:layout title="${pageTitle}">
<style>
  .rlms-home { margin-top:8px; }
  .rlms-home-card { background:#fff; border:1px solid #d1d3d8; border-radius:10px; padding:16px 18px; }
  .rlms-home-tree-head { font-weight:600; color:#1f3974; margin-bottom:10px; display:flex; align-items:center; gap:6px; font-size:15px; }
  #homeCateTree { font-size:13px; max-height:600px; overflow:auto; }
  .rlms-home-main { display:flex; flex-direction:column; gap:20px; min-width:0; }
  .rlms-home-search h2 { margin:0 0 12px; font-size:20px; color:#1f3974; }
  .rlms-search-row { display:flex; gap:8px; margin-bottom:12px; }
  .rlms-search-row input[type=text] { flex:1; min-width:0; }
  /* 통합검색 인풋/날짜 박스 — KRDS 기본 56px 가 너무 높아 44px 로 축소(폰트는 유지). 버튼 높이 정합. */
  .rlms-home-search .krds-input { height:44px !important; padding:6px 14px !important; box-sizing:border-box !important; }
  .rlms-home-search .krds-btn { height:44px !important; }
  .rlms-gubun-row { display:flex; flex-wrap:wrap; align-items:center; gap:12px; font-size:16px; color:#555; }
  .rlms-gubun-row label { font-weight:normal; display:flex; align-items:center; gap:5px; }
  .rlms-gubun-label { font-weight:600; color:#1f3974; }
  .rlms-section-head { display:flex; justify-content:space-between; align-items:baseline; margin-bottom:10px; }
  .rlms-section-head h2 { margin:0; font-size:16px; color:#1f3974; }
  .rlms-muted { color:#888; font-size:13px; }
  .rlms-more { color:#1f3974; font-size:13px; text-decoration:none; }
  .rlms-stats { display:grid; grid-template-columns:repeat(auto-fit, minmax(110px,1fr)); gap:12px; }
  .rlms-stat { background:#f4f6fb; border-radius:8px; padding:14px 16px; text-decoration:none; display:block; }
  .rlms-stat .t { font-size:13px; color:#555; }
  .rlms-stat .n { font-size:24px; font-weight:600; color:#1f3974; margin-top:2px; }
  .rlms-stat:hover { background:#e8edf9; }
  .rlms-home-2col { display:grid; grid-template-columns:1fr 1fr; gap:20px; }
  /* 상단 2단 — 읽어야 할 규정(좌) + 공지사항(우) (2026-07-31).
     두 카드 가로·세로를 같게: 1fr 1fr + stretch(기본) 로 짧은 쪽이 긴 쪽 높이에 맞춰 늘어난다.
     필수 열람이 0건이면 .single 로 공지사항이 전폭을 쓴다(빈 칸 방지). */
  .rlms-home-top2col { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:20px; }
  /* ⛔1fr(=minmax(auto,1fr))은 아이템 min-content 가 하한 — 긴 공지 제목(nowrap)이 카드를 화면 밖으로
     밀어낸다(RLMS 통합본 데이터로 실증, 2026-08-04). single·모바일 1열도 minmax(0,1fr) 필수. */
  .rlms-home-top2col.single { grid-template-columns:minmax(0,1fr); }
  .rlms-home-2col > *, .rlms-home-top2col > * { min-width:0; }
  .rlms-home-top2col .rlms-section-head { flex-wrap:wrap; gap:2px 10px; }
  /* 바로가기 타일 — 나의 규정·도움말을 링크 나열 대신 카드로. 항목이 늘어도 auto-fit 이 줄바꿈한다. */
  /* 200px 하한 — 우측 칼럼(≈544px)에서 2열이 되어 4개가 2×2 로 떨어진다.
     150px 면 3열이라 마지막 1개가 외톨이로 남는다. 항목이 늘면 auto-fit 이 알아서 채운다. */
  .rlms-quick { display:grid; grid-template-columns:repeat(auto-fit, minmax(200px,1fr)); gap:10px; }
  .rlms-quick-item { display:flex; flex-direction:column; gap:3px; padding:14px 16px; border:1px solid #e4e7ec;
                     border-radius:8px; background:#fff; text-decoration:none; }
  .rlms-quick-item:hover { border-color:#1f3974; background:#f4f6fb; }
  .rlms-quick-item .q-t { font-size:14px; font-weight:600; color:#1f3974; }
  .rlms-quick-item .q-d { font-size:12px; color:#667085; }
  .rlms-list-row { display:flex; justify-content:space-between; gap:10px; padding:8px 0; border-bottom:1px solid #eee; font-size:14px; }
  .rlms-list-row:last-child { border-bottom:0; }
  .rlms-list-row a { color:#1f3974; text-decoration:none; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .rlms-list-row a:hover { text-decoration:underline; }
  .rlms-list-row .rlms-muted { white-space:nowrap; }
  /* 필수 열람 카드 (2026-07-28) — D-day 뱃지, 기한 경과 붉은 강조 */
  .rlms-duty-badge { display:inline-block; font-size:12px; font-weight:600; padding:2px 8px; border-radius:10px;
                     background:#eef4fe; color:#1f3974; white-space:nowrap; align-self:center; }
  .rlms-duty-badge.over { background:#fef3f2; color:#b42318; }
  /* 행마다 상태·D-day 유무가 달라 칸이 밀리던 것 — 두 칸을 항상 렌더하고 폭을 고정해 줄 맞춤(2026-07-31).
     제목이 남는 폭을 모두 흡수(flex:1)하므로 오른쪽 칸들은 늘 같은 자리에 온다. */
  .rlms-duty-row > a { flex:1 1 auto; min-width:0; }
  .rlms-duty-read { flex:0 0 auto; width:92px; text-align:right;
                    font-size:12px; color:#667085; white-space:nowrap; align-self:center; }
  /* 108px — 가장 긴 뱃지("기한 경과 D+000", 실측 104px)가 넘치지 않는 폭 */
  .rlms-duty-dday { flex:0 0 auto; width:108px; text-align:center; align-self:center; }
  .rlms-duty-row > .rlms-muted { flex:0 0 auto; }
  .rlms-duty-note { margin:8px 0 0; font-size:12px; color:#888; }
  .rlms-pwd-banner { display:flex; justify-content:space-between; align-items:center; gap:12px; padding:12px 18px;
                     border:1px solid #fec84b; background:#fffaeb; color:#b54708; border-radius:10px; font-size:14px; }
  .rlms-pwd-banner.expired { border-color:#fda29b; background:#fef3f2; color:#b42318; }
  .rlms-pwd-banner a { white-space:nowrap; }
  /* 배너 — 표시 크기를 모두 같게(2026-07-31). 등록 이미지가 611x226(2.7:1)부터 361x45(8:1)까지
     비율이 제각각이라, 같은 크기의 칸에 넣고 object-fit:contain 으로 비율을 유지한 채 맞춘다.
     cover(꽉 채우기)는 가로로 긴 배너의 좌우 글자가 잘려나가므로 쓰지 않는다.
     auto-fill — 배너가 늘면 같은 크기로 다음 줄에 이어 붙는다(auto-fit 이면 몇 개 없을 때 혼자 커진다). */
  /* 배너는 한 줄만 보이고, 줄이 더 있으면 자동으로 아래로 순환한다(2026-07-31).
     높이를 한 줄(80px)로 고정. overflow-y:auto — 자동 순환과 별개로 휠·터치로 직접 굴릴 수도 있어야 한다.
     overscroll-behavior 는 일부러 두지 않는다: 끝에 닿으면 페이지 스크롤로 자연스럽게 넘어가야
     좁은 띠 위에서 휠이 갇히지 않는다. 스크롤바는 얇게. */
  .rlms-home-banner ul { display:grid; grid-template-columns:repeat(auto-fill, minmax(240px,1fr));
                         gap:12px; list-style:none; margin:0; padding:0 4px 0 0;
                         height:80px; overflow-y:auto; scrollbar-width:thin; }
  .rlms-home-banner ul::-webkit-scrollbar { width:6px; }
  .rlms-home-banner ul::-webkit-scrollbar-thumb { background:#cdd3dc; border-radius:3px; }
  .rlms-home-banner ul::-webkit-scrollbar-track { background:transparent; }
  .rlms-home-banner li { min-width:0; }
  .rlms-home-banner a { display:block; }
  .rlms-home-banner img { display:block; width:100%; height:80px; object-fit:contain; padding:6px;
                          box-sizing:border-box; background:#fafbfc; border-radius:8px; border:1px solid #e4e7ec; }
  @media (max-width: 900px) {
    .rlms-home { grid-template-columns:minmax(0,1fr); }
    .rlms-home-2col { grid-template-columns:minmax(0,1fr); }
    .rlms-home-top2col { grid-template-columns:minmax(0,1fr); }
  }
  /* 목록 행(공지·최근개정·필수열람) — 제목 a 가 flex 최소폭(auto) 탓에 안 줄어 넘치는 것 방지.
     좁은 화면은 제목 한 줄 전폭 + 뱃지·날짜가 다음 줄로 (반응형 2026-08-04) */
  @media (max-width: 640px) {
    .rlms-list-row { flex-wrap:wrap; row-gap:2px; }
    .rlms-list-row > a:first-child { flex:1 1 100%; min-width:0; }
    .rlms-duty-read, .rlms-duty-dday { width:auto; }
  }
</style>

<div class="rlms-home">

  <div class="rlms-home-main">

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

    <%-- ① 통합검색 콘솔 — 전용 통합검색 페이지(searchAll.do)로 제출. 홈은 인덱스, 검색은 전용 화면. --%>
    <section class="rlms-home-card rlms-home-search">
      <h2>법률규정 통합검색</h2>
      <form action="<c:url value='/rlms/fulltext/searchAll.do'/>" method="get">
        <div class="rlms-search-row">
          <input type="text" name="searchKeyword" class="krds-input" placeholder="규정명 · 본문 키워드 검색"/>
          <button type="submit" class="krds-btn primary medium">검색</button>
        </div>
        <div class="rlms-gubun-row">
          <span class="rlms-gubun-label">분류</span>
          <c:forEach var="g" items="${gubunList}">
            <label><input type="checkbox" name="gubunIds" value="${g.code}"/> <c:out value="${g.label}"/></label>
          </c:forEach>
          <span style="margin-left:6px;">공포일</span>
          <input type="date" name="searchFromDt" class="krds-input" style="width:190px;"/>
          <span>~</span>
          <input type="date" name="searchToDt" class="krds-input" style="width:190px;"/>
        </div>
      </form>
    </section>

    <%-- ② 읽어야 할 규정(필수 열람) + 공지사항 — 한 행에 나란히(2026-07-31).
         필수 열람이 0건이면 .single 로 공지사항이 전폭을 쓴다. --%>
    <div class="rlms-home-top2col ${empty readDuties ? 'single' : ''}">

      <%-- ②.1 읽어야 할 규정(필수 열람, 2026-07-28) — 내가 대상인 미숙지 지정, 기한 임박순(top 6).
           기한 경과 = 붉은 강조. 완료 = 뷰어 [숙지 확인] 버튼(본문 열람만으로는 사라지지 않음). 0건 = 카드 숨김. --%>
      <c:if test="${not empty readDuties}">
      <section class="rlms-home-card">
        <div class="rlms-section-head">
          <h2>읽어야 할 규정 (필수 열람)</h2>
        </div>
        <c:forEach var="p" items="${readDuties}">
          <%-- 상태·D-day 칸은 값이 없어도 빈 칸으로 렌더한다 — 있는 행/없는 행이 서로 밀리지 않게(2026-07-31) --%>
          <div class="rlms-list-row rlms-duty-row">
            <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${p.promNo}" title="<c:out value='${p.title}'/> 본문 열람"><c:out value="${p.title}"/></a>
            <c:if test="${p.pendingYn eq 'Y'}"><span class="krds-badge bg-light-information">시행예정</span></c:if>
            <span class="rlms-duty-read"><c:if test="${not empty p.readDt}"><span title="본문은 열람했으나 아직 숙지 확인 전입니다">열람함 · 숙지 필요</span></c:if></span>
            <span class="rlms-duty-dday">
              <c:choose>
                <c:when test="${not empty p.dueDt and p.dday lt 0}">
                  <span class="rlms-duty-badge over" title="열람 기한이 지났습니다">기한 경과 D+${-p.dday}</span>
                </c:when>
                <c:when test="${not empty p.dueDt}">
                  <span class="rlms-duty-badge">D-${p.dday eq 0 ? 'DAY' : p.dday}</span>
                </c:when>
              </c:choose>
            </span>
            <span class="rlms-muted"><c:out value="${p.promDate}"/> 개정</span>
          </div>
        </c:forEach>
        <p class="rlms-duty-note">규정 본문을 연 뒤 상단 [숙지 확인] 버튼을 눌러야 완료됩니다.</p>
      </section>
      </c:if>

      <%-- ②.2 공지사항 — 상단으로 올림(2026-07-31). 보드 미해석(noticeBbsId null) 시 ?bbsId= 깨진 링크 방지.
           열람 전용 URL(/cop/bbs/user/*) — 관리 URL 은 ADMIN 전용이라 일반 사용자가 403 이 난다. --%>
      <section class="rlms-home-card">
        <div class="rlms-section-head">
          <h2>공지사항</h2>
          <c:if test="${not empty noticeBbsId}"><a class="rlms-more" href="<c:url value='/cop/bbs/user/selectArticleList.do'/>?bbsId=${noticeBbsId}">더보기</a></c:if>
        </div>
        <c:choose>
          <c:when test="${empty notices}"><p class="rlms-muted">공지사항이 없습니다.</p></c:when>
          <c:otherwise>
            <c:forEach var="n" items="${notices}">
              <div class="rlms-list-row">
                <a href="<c:url value='/cop/bbs/user/selectArticleDetail.do'/>?bbsId=${noticeBbsId}&amp;nttId=${n.nttId}" title="<c:out value='${n.nttSj}'/>"><c:out value="${n.nttSj}"/></a>
                <span class="rlms-muted"><c:out value="${n.regDt}"/></span>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </section>

    </div>

    <%-- ②.5 즐겨찾기 규정 개정 소식(2026-07-28) — 내 즐겨찾기 규정에 새 현행 회차가 공포되면 노출.
         확인 = 해당 규정 본문 열람(뷰어가 확인 회차 기록) → 다음 방문부터 사라짐. 0건 = 카드 자체 숨김. --%>
    <c:if test="${not empty favorRevised}">
    <section class="rlms-home-card">
      <div class="rlms-section-head">
        <h2>즐겨찾기 규정 개정 소식</h2>
        <a class="rlms-more" href="<c:url value='/rlms/favor/selectFavorList.do'/>">내 즐겨찾기</a>
      </div>
      <c:forEach var="p" items="${favorRevised}">
        <div class="rlms-list-row">
          <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${p.promNo}" title="<c:out value='${p.title}'/> 본문 보기"><c:out value="${p.title}"/></a>
          <c:if test="${p.pendingYn eq 'Y'}"><span class="krds-badge bg-light-information">시행예정</span></c:if>
          <a class="rlms-muted" href="<c:url value='/rlms/prom/diffByPromNo.do'/>?promNo=${p.promNo}" target="_blank" title="신구대조 새 창">신구대조</a>
          <span class="rlms-muted"><c:out value="${p.promDate}"/> 개정</span>
        </div>
      </c:forEach>
    </section>
    </c:if>

    <%-- ③ 최근 개정 + 공지사항 --%>
    <div class="rlms-home-2col">
      <section class="rlms-home-card">
        <div class="rlms-section-head">
          <h2>최근 개정</h2>
          <a class="rlms-more" href="<c:url value='/rlms/fulltext/latestList.do'/>">더보기</a>
        </div>
        <c:choose>
          <c:when test="${empty recentProms}"><p class="rlms-muted">항목이 없습니다.</p></c:when>
          <c:otherwise>
            <c:forEach var="p" items="${recentProms}">
              <div class="rlms-list-row">
                <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${p.promNo}" title="<c:out value='${p.title}'/>"><c:out value="${p.title}"/></a>
                <c:if test="${p.pendingYn eq 'Y'}"><span class="krds-badge bg-light-information">시행예정</span></c:if>
                <span class="rlms-muted"><c:out value="${p.promDate}"/></span>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </section>

      <%-- ③.2 바로가기 — 나의 규정(메모·즐겨찾기) + 도움말(FAQ·Q&A)을 링크 나열 대신 타일로(2026-07-31).
           도움말은 표준 olh 직결(2026-07-09 커스텀 helpdesk 폐기 — 재사용 원칙). --%>
      <section class="rlms-home-card">
        <div class="rlms-section-head">
          <h2>바로가기</h2>
        </div>
        <div class="rlms-quick">
          <a class="rlms-quick-item" href="<c:url value='/rlms/memo/selectMemoList.do'/>">
            <span class="q-t">내 메모</span><span class="q-d">규정에 남긴 메모</span>
          </a>
          <a class="rlms-quick-item" href="<c:url value='/rlms/favor/selectFavorList.do'/>">
            <span class="q-t">즐겨찾기</span><span class="q-d">자주 보는 규정</span>
          </a>
          <a class="rlms-quick-item" href="<c:url value='/uss/olh/faq/selectFaqUserList.do'/>">
            <span class="q-t">FAQ</span><span class="q-d">자주 묻는 질문</span>
          </a>
          <a class="rlms-quick-item" href="<c:url value='/uss/olh/qna/selectQnaList.do'/>">
            <span class="q-t">Q&amp;A</span><span class="q-d">문의하기</span>
          </a>
        </div>
      </section>
    </div>

    <%-- ④ 현행 보유 규정 집계 — 맨 아래 전폭(2026-07-31). 구분별 건수, 클릭 시 그 구분 검색.
         .rlms-stats 가 auto-fit 이라 전폭에서는 한 줄로 길게 늘어서고, 구분이 늘면 줄바꿈된다. --%>
    <section class="rlms-home-card">
      <div class="rlms-section-head">
        <h2>현행 보유 규정</h2>
        <span class="rlms-muted">최종 업데이트 <c:out value="${lastInsDt}"/></span>
      </div>
      <div class="rlms-stats">
        <c:forEach var="g" items="${gubunList}">
          <c:set var="cnt" value="${gubunCounts[g.code]}"/>
          <a class="rlms-stat" href="<c:url value='/rlms/fulltext/historyList.do'/>?gubunIds=${g.code}">
            <div class="t"><c:out value="${g.label}"/></div>
            <div class="n"><fmt:formatNumber value="${empty cnt ? 0 : cnt}"/></div>
          </a>
        </c:forEach>
      </div>
    </section>

    <%-- ⑤ 배너(COMTNBANNER → 운영관리>배너관리 등록분, REFLCT_AT='Y' 정렬순).
         이미지 키는 세션 암호화(egovc:encryptSession) — cmm getImage 규약. --%>
    <c:if test="${not empty banners}">
    <section class="rlms-home-card rlms-home-banner" aria-label="배너">
      <ul>
        <c:forEach var="b" items="${banners}">
        <li>
          <c:choose>
            <c:when test="${not empty b.linkUrl and b.linkUrl ne '-'}">
              <a href="<c:out value='${b.linkUrl}'/>" target="_blank" title="<c:out value='${b.bannerNm}'/> — 새 창으로 이동"><img alt="<c:out value='${b.bannerNm}'/>" src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=<c:out value='${egovc:encryptSession(b.bannerImageFile, pageContext.session.id)}'/>"/></a>
            </c:when>
            <c:otherwise>
              <img alt="<c:out value='${b.bannerNm}'/>" title="<c:out value='${b.bannerNm}'/>" src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=<c:out value='${egovc:encryptSession(b.bannerImageFile, pageContext.session.id)}'/>"/>
            </c:otherwise>
          </c:choose>
        </li>
        </c:forEach>
      </ul>
    </section>
    </c:if>

  </div>
</div>

<%-- ⑤ 로그인 후 홈 진입 시 게시중인 팝업 자동 노출 (listMainPopup.do=게시기간 내 NTCE_AT='Y').
     ★window.open 대신 인페이지 모달(iframe) — 브라우저 팝업차단 무관.
     부모(홈)가 헤더(✕)+푸터(그만보기)를 제공하고 iframe 은 openPopupManage.do?embed=Y 본문만 로드.
     내용구분(F:파일URL / E:직접편집)은 openPopupManage.do 가 서버에서 분기. '그만보기' 쿠키(popupId=done) 존중. --%>
<style>
  .rlms-popup-card{position:fixed;z-index:11000;background:#fff;border:1px solid #c9ccd2;border-radius:10px;
    box-shadow:0 12px 44px rgba(0,0,0,.30);display:flex;flex-direction:column;overflow:hidden;max-width:calc(calc(100vw / var(--rlms-zoom, 1)) - 32px);}
  .rlms-popup-hd{display:flex;align-items:center;justify-content:space-between;gap:8px;
    padding:10px 14px;background:#1f3974;color:#fff;font-weight:600;font-size:15px;}
  .rlms-popup-hd .t{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
  .rlms-popup-hd .x{cursor:pointer;background:none;border:0;color:#fff;font-size:22px;line-height:1;padding:0 4px;}
  .rlms-popup-bd{flex:0 0 auto;background:#fff;} /* flex:1(=basis 0)은 인라인 height 를 무시하고 150px 로 붕괴시킨다 */
  .rlms-popup-bd iframe{width:100%;height:100%;border:0;display:block;}
  .rlms-popup-ft{display:flex;align-items:center;justify-content:space-between;gap:10px;
    padding:8px 14px;border-top:1px solid #e7e7e7;background:#f7f8fa;font-size:13px;color:#555;}
  .rlms-popup-ft label{display:flex;align-items:center;gap:6px;cursor:pointer;margin:0;font-weight:normal;}
  .rlms-popup-ft .close{cursor:pointer;border:1px solid #c9ccd2;background:#fff;border-radius:6px;padding:5px 16px;font-size:13px;}
  .rlms-popup-ft .close:hover{background:#eef1f6;}
</style>
<script>
(function(){
  function hasStop(id){
    return document.cookie.split(';').some(function(c){ return c.trim().indexOf(id + '=done') === 0; });
  }
  function setStop(id){
    var d = new Date(); d.setFullYear(d.getFullYear() + 1);
    document.cookie = id + '=done; path=/; expires=' + d.toUTCString() + ';';
  }
  function build(p, idx){
    if(!p || !p.popupId || hasStop(p.popupId)) return;
    var w     = Math.min(parseInt(p.popupWidthSize, 10)  || 440, window.innerWidth  - 32);
    var bodyH = Math.min(parseInt(p.popupVrticlSize, 10) || 360, window.innerHeight - 200);
    if(bodyH < 120){ bodyH = 120; }
    var left = parseInt(p.popupWidthLc, 10);   // POPUP_WIDTH_LC = 가로
    var top  = parseInt(p.popupVrticlLc, 10);  // POPUP_VRTICL_LC = 세로
    if(isNaN(left) || left <= 0){ left = Math.max(16, (window.innerWidth  - w) / 2) + idx * 28; }
    if(isNaN(top)  || top  <= 0){ top  = Math.max(16, (window.innerHeight - (bodyH + 96)) / 2) + idx * 28; }

    var url = '<c:url value="/uss/ion/pwm/openPopupManage.do"/>'
      + '?embed=Y'
      + '&popupId='   + encodeURIComponent(p.popupId)
      + '&stopVewAt=' + encodeURIComponent(p.stopvewSetupAt == null ? 'N' : p.stopvewSetupAt)
      + '&fileUrl='   + encodeURIComponent(p.fileUrl == null ? '' : p.fileUrl);

    var stopOn = (p.stopvewSetupAt === 'Y');  // STOPVEW_SETUP_AT: 그만보기 제공 여부 옵션

    var card = document.createElement('div');
    card.className = 'rlms-popup-card';
    card.style.width = w + 'px';
    card.style.left  = left + 'px';
    card.style.top   = top + 'px';
    card.innerHTML =
        '<div class="rlms-popup-hd"><span class="t"></span>'
      +   '<button type="button" class="x" title="닫기">&times;</button></div>'
      + '<div class="rlms-popup-bd" style="height:' + bodyH + 'px"><iframe title="팝업"></iframe></div>'
      + '<div class="rlms-popup-ft">'
      +   (stopOn ? '<label><input type="checkbox"> 다음부터 열지 않기</label>' : '<span></span>')
      +   '<button type="button" class="close">닫기</button></div>';
    card.querySelector('.t').textContent = p.popupTitleNm ? p.popupTitleNm : '알림';
    card.querySelector('iframe').src = url;

    function remove(){
      var chk = card.querySelector('.rlms-popup-ft input');
      if(chk && chk.checked){ setStop(p.popupId); }
      if(card.parentNode){ card.parentNode.removeChild(card); }
    }
    card.querySelector('.x').onclick = remove;
    card.querySelector('.rlms-popup-ft .close').onclick = remove;
    document.body.appendChild(card);
  }
  function load(){
    if(!window.fetch) return;
    fetch('<c:url value="/uss/ion/pwm/listMainPopup.do"/>',
          { method:'POST', headers:{ 'X-Requested-With':'XMLHttpRequest' } })
      .then(function(r){ return r.json(); })
      .then(function(d){ (d.resultList || []).forEach(build); })
      .catch(function(){});
  }
  if(document.readyState === 'loading'){ document.addEventListener('DOMContentLoaded', load); }
  else { load(); }
})();
</script>

<script>
/* 배너 자동 순환(2026-07-31) — 한 줄만 보이고 줄이 더 있으면 일정 간격으로 다음 줄로 내린다.
   · 한 줄에 다 들어가면 아무 것도 하지 않는다(스크롤 여지 없음).
   · 마우스를 올리면 멈춘다 — 클릭하려는 배너가 지나가 버리지 않게. 이때 휠로 직접 굴릴 수 있다.
   · 손으로 굴리는 중에도 멈춘다(터치·스크롤바 드래그 대비) — 잠시 뒤 자동 재개.
   · 탭이 백그라운드면 타이머를 쉬게 한다(불필요한 렌더 방지).
   · 동작 최소화(prefers-reduced-motion) 설정이면 자동 순환을 하지 않는다(수동 스크롤은 그대로). */
(function(){
  var ul = document.querySelector('.rlms-home-banner ul');
  if(!ul) return;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if(reduce) return;

  var GAP = 12, INTERVAL = 4000, timer = null, paused = false;

  function rowHeight(){
    var li = ul.querySelector('li');
    return li ? Math.round(li.getBoundingClientRect().height) + GAP : 0;
  }
  function tick(){
    if(paused || document.hidden) return;
    var max = ul.scrollHeight - ul.clientHeight;
    if(max <= 1) return;                                  /* 한 줄뿐 — 순환 불필요 */
    var h = rowHeight();
    var next = (ul.scrollTop + h > max + 1) ? 0 : ul.scrollTop + h;
    if(ul.scrollTo){ ul.scrollTo({ top: next, behavior: 'smooth' }); }
    else { ul.scrollTop = next; }
  }
  function start(){ if(!timer) timer = setInterval(tick, INTERVAL); }

  ul.addEventListener('mouseenter', function(){ paused = true; });
  ul.addEventListener('mouseleave', function(){ paused = false; });
  /* 키보드로 배너 링크에 포커스가 가 있는 동안에도 멈춘다 */
  ul.addEventListener('focusin',  function(){ paused = true; });
  ul.addEventListener('focusout', function(){ paused = false; });

  /* 손으로 굴리는 동안 자동 순환이 끼어들면 위치가 튄다 — 잠시 멈췄다 재개.
     터치 기기에는 mouseenter 가 없으므로 이 경로가 유일한 정지 수단이다. */
  var resumeTimer = null;
  function pauseAwhile(){
    paused = true;
    if(resumeTimer) clearTimeout(resumeTimer);
    resumeTimer = setTimeout(function(){ paused = false; }, 6000);
  }
  ['wheel','touchstart','pointerdown'].forEach(function(ev){
    ul.addEventListener(ev, pauseAwhile, { passive: true });
  });

  start();
})();
</script>
</lay:layout>
