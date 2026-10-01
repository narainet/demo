<%--
  물리적 저장 경로: /WEB-INF/jsp/rlms/fulltext/searchAll.jsp
  통합검색 (사용자) — 규정제목/조문/별표서식/자료/게시판/FAQ 6축 + 전체 탭.
  front 데코레이터 자동 적용(/rlms/fulltext/*). 좌측 분류트리(rlms-cate-search-tree) 연동.
  분류 체크박스 = 규정 구분(FT_GUBUN_N) + 축 토글(AXIS_BBS/AXIS_FAQ) — 무체크=전축 검색.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">통합검색</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
  <script src="<c:url value='/resources/js/rlms-cate-search-tree.js' />?v=20260804-fresp"></script>
  <style>
    /* 통합검색 탭 — cateTree owner-tabs 밑줄형 복제 */
    .us-tabs { display:flex; gap:0; border-bottom:2px solid #d7dae2; margin:18px 0 16px; flex-wrap:wrap; }
    .us-tab { border:none; background:none; padding:9px 18px; font-size:15px; font-weight:600;
              color:#777; cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-2px; }
    .us-tab.on { color:#1f3974; border-bottom-color:#1f3974; }
    .us-tab .cnt { font-weight:400; color:#999; margin-left:4px; font-size:13px; }
    .us-tab.on .cnt { color:#1f3974; }
    /* 결과 리스트 */
    .us-sec { margin:0 0 26px; }
    .us-sec-head { display:flex; align-items:center; gap:10px; margin:0 0 8px; }
    .us-sec-head h2 { font-size:17px; margin:0; color:#1f3974; }
    .us-sec-head .more { margin-left:auto; }
    .us-item { border-bottom:1px solid #eceef2; padding:10px 4px; }
    .us-item .t { font-size:15px; }
    .us-item .t a { color:#1a1a1a; text-decoration:none; font-weight:600; }
    .us-item .t a:hover { text-decoration:underline; color:#1f3974; }
    .us-item .meta { font-size:13px; color:#888; margin-top:3px; }
    .us-item .snip { font-size:13.5px; color:#555; margin-top:4px; line-height:1.55;
                     overflow:hidden; text-overflow:ellipsis; }
    .us-kind { display:inline-block; padding:1px 8px; border-radius:10px; font-size:12px;
               background:#eef3fb; color:#1b5fbf; margin-right:6px; vertical-align:1px; }
    .us-results mark.ushit { background:#ffe58a; padding:0 1px; }
    .us-zero { color:#888; padding:26px 4px; }
    .us-ext { font-size:12px; color:#1b5fbf; }
    /* 검색 콘솔 — 홈 콘솔(rlms-home-search)과 동일 룩 */
    .us-console { background:#fff; border:1px solid #d1d3d8; border-radius:10px; padding:16px 18px; }
    .us-sch-row { display:flex; gap:8px; margin-bottom:12px; }
    .us-sch-row .krds-input { flex:1; min-width:0; height:44px !important; padding:6px 14px !important; box-sizing:border-box !important; }
    .us-sch-row .krds-btn { height:44px !important; }
    .us-filter-row { display:flex; flex-wrap:wrap; align-items:center; gap:10px 16px; font-size:15px; color:#555; }
    .us-filter-row label { font-weight:normal; display:inline-flex; align-items:center; gap:4px; }
    .us-filter-label { font-weight:600; color:#1f3974; }
    .us-filter-row input[type=date] { width:180px; height:40px !important; padding:4px 10px !important; box-sizing:border-box !important; }
    /* 인기 검색어 칩 */
    .us-chips { display:flex; flex-wrap:wrap; align-items:center; gap:8px; margin:12px 0 0; }
    .us-chips-label { font-size:13px; font-weight:600; color:#1f3974; }
    .us-chip { display:inline-block; padding:3px 12px; border:1px solid #d1d3d8; border-radius:14px;
               font-size:13px; color:#333; text-decoration:none; background:#fff; }
    .us-chip:hover { border-color:#1f3974; color:#1f3974; background:#f4f6fb; }
    /* 결과 요약 라인 */
    .us-summary { font-size:14px; color:#555; margin:16px 0 0; }
    .us-summary a { color:#1f3974; text-decoration:none; }
    .us-summary a:hover { text-decoration:underline; }
    /* 반응형(2026-08-04 사용자) — 좌측 규정분류 트리는 모바일에서 숨김.
       ≤900 이면 rlms-cate-search-tree.js 의 1열 전환으로 트리가 검색 콘솔 '위'에 쌓여
       화면만 밀어내는데, 통합검색에는 기여가 작다(분류 탐색은 전역 규정분류 드로어가 대체). */
    @media (max-width: 900px) {
      .rlms-search-tree-aside { display: none; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<div class="page-header" style="position:relative;">
  <h1>통합검색</h1>
  <p class="page-desc">규정 제목·조문·별표서식·관련자료·게시판 글·FAQ를 한 번에 검색합니다.</p>
</div>

<div class="rlms-search-layout">
  <aside class="rlms-search-tree-aside">
    <div class="rlms-search-tree-head">규정 분류</div>
    <div id="cateSearchTree" class="rlms-search-tree"></div>
  </aside>
  <div class="rlms-search-body">

  <%-- 검색 콘솔 — 홈(userHome) 콘솔과 동일 레이아웃: 큰 검색창+버튼 / 분류·공포일 필터 행 (2026-07-08 사용자 요청) --%>
  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/fulltext/searchAll.do'/>" method="get" class="krds-form us-console">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <input type="hidden" name="tab" value="<c:out value='${tab}'/>"/>
    <c:if test="${not empty searchVO.cateNo}"><input type="hidden" name="cateNo" value="${searchVO.cateNo}"/></c:if>
    <div class="us-sch-row">
      <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
             value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="규정명 · 본문 키워드 검색"/>
      <button type="submit" class="krds-btn primary medium" onclick="document.searchForm.pageIndex.value=1;">검색</button>
    </div>
    <div class="us-filter-row">
      <span class="us-filter-label">분류</span>
      <c:forEach var="g" items="${gubunList}">
      <label><input type="checkbox" name="gubunIds" value="${g.code}" <c:if test="${not empty searchVO.gubunIds and searchVO.gubunIds.contains(g.code)}">checked</c:if>/> <c:out value="${g.label}"/></label>
      </c:forEach>
      <%-- 콘텐츠 축 토글(게시판/FAQ) — 규정 구분과 같은 gubunIds 로 제출, 서버(UnifiedSearchServiceImpl)가 해석 --%>
      <span aria-hidden="true" style="color:#d1d3d8;">|</span>
      <label><input type="checkbox" name="gubunIds" value="AXIS_BBS" <c:if test="${not empty searchVO.gubunIds and searchVO.gubunIds.contains('AXIS_BBS')}">checked</c:if>/> 게시판</label>
      <label><input type="checkbox" name="gubunIds" value="AXIS_FAQ" <c:if test="${not empty searchVO.gubunIds and searchVO.gubunIds.contains('AXIS_FAQ')}">checked</c:if>/> FAQ</label>
      <%-- 공포일 범위 — 규정 축에만 적용(홈 콘솔과 동일 조건) --%>
      <span class="us-filter-label" style="margin-left:6px;" title="공포일 조건은 규정 검색 결과에만 적용됩니다">공포일</span>
      <input type="date" name="searchFromDt" class="krds-input" value="<c:out value='${searchVO.searchFromDt}'/>"/>
      <span>~</span>
      <input type="date" name="searchToDt" class="krds-input" value="<c:out value='${searchVO.searchToDt}'/>"/>
    </div>
  </form>

  <%-- 인기 검색어 칩 — 최근 30일 TB_STATS_KWD 상위 (클릭=바로 검색) --%>
  <c:if test="${not empty popularKwds}">
  <div class="us-chips">
    <span class="us-chips-label">인기 검색어</span>
    <c:forEach var="k" items="${popularKwds}">
      <c:url var="kUrl" value="/rlms/fulltext/searchAll.do"><c:param name="searchKeyword" value="${k}"/></c:url>
      <a class="us-chip" href="${kUrl}"><c:out value="${k}"/></a>
    </c:forEach>
  </div>
  </c:if>

  <c:choose>
    <c:when test="${not hasQuery}">
      <p class="us-zero">검색어를 입력하세요. 규정 제목, 조문 본문·제목, 별표/별지서식, 관련자료(제목·문서 본문), 게시판 글, FAQ를 한 번에 찾습니다.</p>
    </c:when>
    <c:otherwise>

      <%-- 결과 요약 — 축 클릭 시 해당 탭으로 --%>
      <%-- 제외 축(분류 미체크)은 0건과 구분해 '–' 표기 — 트리 클릭의 gubunIds 자동 주입에도 오독 없게 --%>
      <p class="us-summary">'<strong><c:out value="${searchVO.searchKeyword}"/></strong>' 검색결과 총 <strong>${totalCnt}</strong>건
        &nbsp;—&nbsp; <a href="javascript:fnTab('prom')">규정 ${promAxesOff ? '–' : counts.promCnt}</a> ·
        <a href="javascript:fnTab('prov')">조문 ${promAxesOff ? '–' : counts.provCnt}</a> ·
        <a href="javascript:fnTab('docu')">별표/서식 ${promAxesOff ? '–' : counts.docuCnt}</a> ·
        <a href="javascript:fnTab('rel')">자료 ${promAxesOff ? '–' : counts.relCnt}</a> ·
        <a href="javascript:fnTab('bbs')">게시판 ${bbsAxisOff ? '–' : counts.bbsCnt}</a> ·
        <a href="javascript:fnTab('faq')">FAQ ${faqAxisOff ? '–' : counts.faqCnt}</a></p>

      <div class="us-tabs">
        <button type="button" class="us-tab ${tab eq 'all'  ? 'on' : ''}" onclick="fnTab('all')">전체<span class="cnt">${totalCnt}</span></button>
        <button type="button" class="us-tab ${tab eq 'prom' ? 'on' : ''}" onclick="fnTab('prom')">규정<span class="cnt">${promAxesOff ? '–' : counts.promCnt}</span></button>
        <button type="button" class="us-tab ${tab eq 'prov' ? 'on' : ''}" onclick="fnTab('prov')">조문<span class="cnt">${promAxesOff ? '–' : counts.provCnt}</span></button>
        <button type="button" class="us-tab ${tab eq 'docu' ? 'on' : ''}" onclick="fnTab('docu')">별표/서식<span class="cnt">${promAxesOff ? '–' : counts.docuCnt}</span></button>
        <button type="button" class="us-tab ${tab eq 'rel'  ? 'on' : ''}" onclick="fnTab('rel')">자료<span class="cnt">${promAxesOff ? '–' : counts.relCnt}</span></button>
        <button type="button" class="us-tab ${tab eq 'bbs'  ? 'on' : ''}" onclick="fnTab('bbs')">게시판<span class="cnt">${bbsAxisOff ? '–' : counts.bbsCnt}</span></button>
        <button type="button" class="us-tab ${tab eq 'faq'  ? 'on' : ''}" onclick="fnTab('faq')">FAQ<span class="cnt">${faqAxisOff ? '–' : counts.faqCnt}</span></button>
      </div>

      <div class="us-results">

      <%-- ══════ 전체 탭: 축별 미리보기 ══════ --%>
      <c:if test="${tab eq 'all'}">
        <c:if test="${totalCnt == 0}">
          <p class="us-zero">'<strong><c:out value="${searchVO.searchKeyword}"/></strong>' 에 대한 결과가 없습니다.</p>
        </c:if>

        <c:if test="${counts.promCnt > 0}">
        <div class="us-sec">
          <div class="us-sec-head"><h2>규정</h2>
            <c:if test="${counts.promCnt > previewRows}"><button type="button" class="krds-btn small more" onclick="fnTab('prom')">전체보기 (${counts.promCnt}건)</button></c:if>
          </div>
          <c:forEach var="row" items="${promList}"><%@ include file="searchAllRowProm.jspf" %></c:forEach>
        </div>
        </c:if>

        <c:if test="${counts.provCnt > 0}">
        <div class="us-sec">
          <div class="us-sec-head"><h2>조문</h2>
            <c:if test="${counts.provCnt > previewRows}"><button type="button" class="krds-btn small more" onclick="fnTab('prov')">전체보기 (${counts.provCnt}건)</button></c:if>
          </div>
          <c:forEach var="row" items="${provList}"><%@ include file="searchAllRowProv.jspf" %></c:forEach>
        </div>
        </c:if>

        <c:if test="${counts.docuCnt > 0}">
        <div class="us-sec">
          <div class="us-sec-head"><h2>별표/별지서식</h2>
            <c:if test="${counts.docuCnt > previewRows}"><button type="button" class="krds-btn small more" onclick="fnTab('docu')">전체보기 (${counts.docuCnt}건)</button></c:if>
          </div>
          <c:forEach var="row" items="${docuList}"><%@ include file="searchAllRowDocu.jspf" %></c:forEach>
        </div>
        </c:if>

        <c:if test="${counts.relCnt > 0}">
        <div class="us-sec">
          <div class="us-sec-head"><h2>자료</h2>
            <c:if test="${counts.relCnt > previewRows}"><button type="button" class="krds-btn small more" onclick="fnTab('rel')">전체보기 (${counts.relCnt}건)</button></c:if>
          </div>
          <c:forEach var="row" items="${relList}"><%@ include file="searchAllRowRel.jspf" %></c:forEach>
        </div>
        </c:if>

        <c:if test="${counts.bbsCnt > 0}">
        <div class="us-sec">
          <div class="us-sec-head"><h2>게시판</h2>
            <c:if test="${counts.bbsCnt > previewRows}"><button type="button" class="krds-btn small more" onclick="fnTab('bbs')">전체보기 (${counts.bbsCnt}건)</button></c:if>
          </div>
          <c:forEach var="row" items="${bbsList}"><%@ include file="searchAllRowBbs.jspf" %></c:forEach>
        </div>
        </c:if>

        <c:if test="${counts.faqCnt > 0}">
        <div class="us-sec">
          <div class="us-sec-head"><h2>FAQ</h2>
            <c:if test="${counts.faqCnt > previewRows}"><button type="button" class="krds-btn small more" onclick="fnTab('faq')">전체보기 (${counts.faqCnt}건)</button></c:if>
          </div>
          <c:forEach var="row" items="${faqList}"><%@ include file="searchAllRowFaq.jspf" %></c:forEach>
        </div>
        </c:if>
      </c:if>

      <%-- ══════ 개별 탭: 페이징 목록 ══════ --%>
      <c:if test="${tab ne 'all'}">
        <p class="list-total">총 <strong>${paginationInfo.totalRecordCount}</strong> 건</p>
        <c:set var="curTabOff" value="${(tab eq 'bbs' and bbsAxisOff) or (tab eq 'faq' and faqAxisOff)
                                        or (tab ne 'bbs' and tab ne 'faq' and promAxesOff)}"/>
        <c:choose>
          <c:when test="${empty resultList and curTabOff}">
            <p class="us-zero">분류 선택에서 제외된 검색 대상입니다. 위 분류에서 해당 항목을 체크하거나 체크를 모두 해제하면 검색됩니다.</p>
          </c:when>
          <c:when test="${empty resultList}">
            <p class="us-zero">결과가 없습니다.</p>
          </c:when>
          <c:otherwise>
            <c:forEach var="row" items="${resultList}">
              <c:choose>
                <c:when test="${tab eq 'prom'}"><%@ include file="searchAllRowProm.jspf" %></c:when>
                <c:when test="${tab eq 'prov'}"><%@ include file="searchAllRowProv.jspf" %></c:when>
                <c:when test="${tab eq 'docu'}"><%@ include file="searchAllRowDocu.jspf" %></c:when>
                <c:when test="${tab eq 'rel'}"><%@ include file="searchAllRowRel.jspf" %></c:when>
                <c:when test="${tab eq 'bbs'}"><%@ include file="searchAllRowBbs.jspf" %></c:when>
                <c:otherwise><%@ include file="searchAllRowFaq.jspf" %></c:otherwise>
              </c:choose>
            </c:forEach>
            <div class="krds-pagination">
              <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
            </div>
          </c:otherwise>
        </c:choose>
      </c:if>

      </div><%-- /us-results --%>
    </c:otherwise>
  </c:choose>

  </div>
</div>

<script>
  function fnLinkPage(pageNo) {
    document.searchForm.pageIndex.value = pageNo;
    document.searchForm.submit();
  }
  function fnTab(t) {
    document.searchForm.tab.value = t;
    document.searchForm.pageIndex.value = 1;
    document.searchForm.submit();
  }
  $(function() {
    RlmsCateSearchTree.init({
      containerId: 'cateSearchTree',
      jsonUrl:     '<c:url value="/rlms/cate/selectCateTreeJson.do"/>',
      searchUrl:   '<c:url value="/rlms/fulltext/searchAll.do"/>'
    });
    /* 검색어 하이라이트 — 텍스트노드만 순회(XSS-safe, provisionList lvhit 선례) */
    var kw = document.getElementById('searchKeyword').value.trim();
    if (kw) {
      var root = document.querySelector('.us-results');
      if (root) {
        var kwLc = kw.toLowerCase();
        var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
        var targets = [];
        while (walker.nextNode()) {
          var n = walker.currentNode;
          if (n.parentNode && n.parentNode.tagName !== 'MARK' && n.nodeValue.toLowerCase().indexOf(kwLc) >= 0) {
            targets.push(n);
          }
        }
        targets.forEach(function(n) {
          var text = n.nodeValue, lc = text.toLowerCase();
          var frag = document.createDocumentFragment(), pos = 0, idx;
          while ((idx = lc.indexOf(kwLc, pos)) >= 0) {
            frag.appendChild(document.createTextNode(text.substring(pos, idx)));
            var mk = document.createElement('mark');
            mk.className = 'ushit';
            mk.textContent = text.substr(idx, kw.length);
            frag.appendChild(mk);
            pos = idx + kw.length;
          }
          frag.appendChild(document.createTextNode(text.substring(pos)));
          n.parentNode.replaceChild(frag, n);
        });
      }
    }
  });
</script>
</lay:layout>
