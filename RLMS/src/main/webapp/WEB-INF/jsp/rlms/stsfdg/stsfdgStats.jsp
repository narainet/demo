<%--
  물리적 저장 경로: /WEB-INF/jsp/rlms/stsfdg/stsfdgStats.jsp
  만족도 조사 현황 (관리자) — 규정 회차별 / 게시판 게시글별 집계 + 참여 상세 + 건별 삭제.
  /rlms/stats/* URL 이라 mgr 데코 자동 적용. gaejungList 관리자 목록 관례(krds-table + ui:pagination).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">만족도 조사 현황</c:set>
<c:set var="pageHead">
  
  <style>
    .ss-tabs { display:flex; gap:0; border-bottom:2px solid #d7dae2; margin:0 0 16px; }
    .ss-tab { border:none; background:none; padding:9px 18px; font-size:15px; font-weight:600;
              color:#777; cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-2px; }
    .ss-tab.on { color:#1f3974; border-bottom-color:#1f3974; }
    .ss-star { color:#f59e0b; letter-spacing:1px; }
    .ss-yn-y { color:#1b7f4d; font-weight:600; }
    .ss-yn-n { color:#999; }
    tr.ss-detail-row > td { background:#f8f9fb; padding:10px 16px; }
    .ss-detail-list { list-style:none; margin:0; padding:0; }
    .ss-detail-list li { display:flex; align-items:flex-start; gap:10px; padding:6px 2px;
                         border-bottom:1px solid #eceef2; font-size:13.5px; }
    .ss-detail-list li:last-child { border-bottom:none; }
    .ss-detail-list .who { font-weight:600; flex:0 0 auto; }
    .ss-detail-list .cn { min-width:0; flex:1; color:#444; white-space:pre-wrap; word-break:break-all; }
    .ss-detail-list .dt { color:#999; flex:0 0 auto; font-size:12.5px; }
    .ss-muted { color:#888; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<div class="page-header">
  <h1>만족도 조사 현황</h1>
  <p class="page-desc">규정(연혁 옵션)과 게시판의 만족도 참여 현황·집계를 확인하고, 부적절한 참여를 정리합니다.</p>
</div>

<form id="searchForm" name="searchForm" class="krds-form search-form" action="<c:url value='/rlms/stats/stsfdgStats.do'/>" method="get">
  <input type="hidden" name="pageIndex" value="${paginationInfo.currentPageNo}"/>
  <input type="hidden" name="tab" value="<c:out value='${tab}'/>"/>

  <div class="ss-tabs">
    <button type="button" class="ss-tab ${tab eq 'prom' ? 'on' : ''}" onclick="fnTab('prom')">규정</button>
    <button type="button" class="ss-tab ${tab eq 'bbs'  ? 'on' : ''}" onclick="fnTab('bbs')">게시판</button>
  </div>

  <div class="form-group inline">
    <label class="form-label" for="searchKeyword"><c:choose><c:when test="${tab eq 'bbs'}">게시판/글제목</c:when><c:otherwise>규정명</c:otherwise></c:choose></label>
    <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
           value="<c:out value='${searchKeyword}'/>" placeholder="검색어"/>
    <label class="form-label" for="fromDt" title="참여(수정)일 기준으로 집계·상세·엑셀에 함께 적용됩니다">참여기간</label>
    <input type="date" id="fromDt" name="fromDt" class="krds-input" style="width:170px;" value="<c:out value='${fromDt}'/>"/>
    <span>~</span>
    <input type="date" id="toDt" name="toDt" class="krds-input" style="width:170px;" value="<c:out value='${toDt}'/>"/>
    <button type="submit" class="krds-btn primary medium" onclick="document.searchForm.pageIndex.value=1;">검색</button>
    <button type="button" class="krds-btn medium" onclick="fnExcel()"
            title="규정·게시판 전체 참여 상세를 엑셀 파일로 내려받습니다 (참여기간 적용, 검색어 무관)">엑셀 다운로드</button>
  </div>
</form>

<p class="list-total">총 <strong>${resultCnt}</strong> 건</p>

<table class="krds-table tbl-list">
  <c:choose>
    <c:when test="${tab eq 'bbs'}">
      <thead>
        <tr><th>게시판</th><th>글제목</th><th style="width:80px;">참여수</th><th style="width:110px;">평균</th><th style="width:110px;">최근참여</th><th style="width:80px;">상세</th></tr>
      </thead>
      <tbody>
        <c:if test="${empty resultList}"><tr><td colspan="6" class="empty-row">만족도 참여가 없습니다.</td></tr></c:if>
        <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${row.bbsNm}"/></td>
          <td style="text-align:left;">
            <a href="<c:url value='/cop/bbs/user/selectArticleDetail.do'/>?nttId=${row.nttId}&amp;bbsId=<c:out value='${row.bbsId}'/>" target="_blank"><c:out value="${row.title}"/></a>
            <c:if test="${row.articleUseAt eq 'N'}"><span class="ss-muted">(삭제글)</span></c:if>
          </td>
          <td>${row.cnt}</td>
          <td><span class="ss-star" title="${row.avg}점">${row.avg}</span></td>
          <td><c:out value="${row.lastDt}"/></td>
          <td><button type="button" class="krds-btn small"
                onclick="fnDetail(this,'bbs',{bbsId:'<c:out value="${row.bbsId}"/>',nttId:'${row.nttId}'})">상세</button></td>
        </tr>
        </c:forEach>
      </tbody>
    </c:when>
    <c:otherwise>
      <thead>
        <tr><th style="width:120px;">분류</th><th>규정명</th><th style="width:130px;">소관부서</th><th style="width:90px;">연혁번호</th><th style="width:70px;">현행</th><th style="width:90px;">조사 옵션</th><th style="width:80px;">참여수</th><th style="width:90px;">평균</th><th style="width:110px;">최근참여</th><th style="width:80px;">상세</th></tr>
      </thead>
      <tbody>
        <c:if test="${empty resultList}"><tr><td colspan="10" class="empty-row">만족도 조사를 사용하는 회차가 없습니다.</td></tr></c:if>
        <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:choose><c:when test="${not empty row.cateNm}"><c:out value="${row.cateNm}"/></c:when><c:otherwise><span class="ss-muted">-</span></c:otherwise></c:choose></td>
          <td style="text-align:left;">
            <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${row.promNo}" target="_blank"><c:out value="${row.title}"/></a>
            <c:if test="${row.dispYn eq 'N'}"><span class="ss-muted">(감춤)</span></c:if>
          </td>
          <td><c:choose><c:when test="${not empty row.buseoNm}"><c:out value="${row.buseoNm}"/></c:when><c:otherwise><span class="ss-muted">-</span></c:otherwise></c:choose></td>
          <td>${row.lawNo}</td>
          <td><c:choose><c:when test="${row.existingYn eq 'Y'}">현행</c:when><c:otherwise><span class="ss-muted">-</span></c:otherwise></c:choose></td>
          <td><c:choose><c:when test="${row.stsfdgYn eq 'Y'}"><span class="ss-yn-y">사용</span></c:when><c:otherwise><span class="ss-yn-n">미사용</span></c:otherwise></c:choose></td>
          <td>${row.cnt}</td>
          <td><c:choose><c:when test="${not empty row.avg}"><span class="ss-star" title="${row.avg}점">${row.avg}</span></c:when><c:otherwise><span class="ss-muted">-</span></c:otherwise></c:choose></td>
          <td><c:choose><c:when test="${not empty row.lastDt}"><c:out value="${row.lastDt}"/></c:when><c:otherwise><span class="ss-muted">-</span></c:otherwise></c:choose></td>
          <td><button type="button" class="krds-btn small" <c:if test="${row.cnt == 0}">disabled</c:if>
                onclick="fnDetail(this,'prom',{promNo:'${row.promNo}'})">상세</button></td>
        </tr>
        </c:forEach>
      </tbody>
    </c:otherwise>
  </c:choose>
</table>

<div class="krds-pagination">
  <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
</div>

<script>
  var CTX_DETAIL = '<c:url value="/rlms/stats/stsfdgDetailJson.do"/>';
  var CTX_DELETE = '<c:url value="/rlms/stats/stsfdgDeleteJson.do"/>';
  var CTX_EXCEL  = '<c:url value="/rlms/stats/stsfdgExcel.do"/>';

  /* 현재 참여기간 파라미터 — 상세·엑셀에 동봉(집계와 행 정합) */
  function fnPeriodQs() {
    var f = document.getElementById('fromDt').value, t = document.getElementById('toDt').value;
    return (f ? '&fromDt=' + encodeURIComponent(f) : '') + (t ? '&toDt=' + encodeURIComponent(t) : '');
  }
  function fnExcel() {
    location.href = CTX_EXCEL + '?_=1' + fnPeriodQs();
  }

  function fnLinkPage(pageNo) {
    document.searchForm.pageIndex.value = pageNo;
    document.searchForm.submit();
  }
  function fnTab(t) {
    document.searchForm.tab.value = t;
    document.searchForm.pageIndex.value = 1;
    document.searchForm.searchKeyword.value = '';
    document.searchForm.submit();
  }

  /* 상세 토글 — 행 바로 아래 확장행에 참여 목록(fetch) 렌더. textContent 만 사용(XSS-safe). */
  function fnDetail(btn, tab, key) {
    var tr = btn.closest('tr');
    var next = tr.nextElementSibling;
    if (next && next.classList.contains('ss-detail-row')) { next.parentNode.removeChild(next); return; }
    document.querySelectorAll('tr.ss-detail-row').forEach(function(r){ r.parentNode.removeChild(r); });

    var dr = document.createElement('tr'); dr.className = 'ss-detail-row';
    var td = document.createElement('td'); td.colSpan = tr.children.length;
    td.textContent = '불러오는 중…';
    dr.appendChild(td);
    tr.parentNode.insertBefore(dr, tr.nextSibling);

    var qs = 'tab=' + tab + '&' + Object.keys(key).map(function(k){ return k + '=' + encodeURIComponent(key[k]); }).join('&') + fnPeriodQs();
    fetch(CTX_DETAIL + '?' + qs, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(function(r){ return r.json(); })
      .then(function(d){
        if (!d.ok) { td.textContent = d.message || '상세를 불러오지 못했습니다.'; return; }
        td.textContent = '';
        if (!d.list || !d.list.length) { td.textContent = '참여가 없습니다.'; return; }
        var ul = document.createElement('ul'); ul.className = 'ss-detail-list';
        d.list.forEach(function(c) {
          var li = document.createElement('li');
          var who = document.createElement('span'); who.className = 'who'; who.textContent = c.wrterNm || '사용자';
          var st = document.createElement('span'); st.className = 'ss-star';
          st.textContent = '★★★★★'.slice(0, +c.stsfdg || 0);
          var cn = document.createElement('span'); cn.className = 'cn'; cn.textContent = c.content || '';
          var dt = document.createElement('span'); dt.className = 'dt'; dt.textContent = c.regDt || '';
          var del = document.createElement('button'); del.type = 'button';
          del.className = 'krds-btn danger small'; del.textContent = '삭제';
          del.onclick = function() { fnDeleteEntry(tab, key, c); };
          li.appendChild(who); li.appendChild(st); li.appendChild(cn); li.appendChild(dt); li.appendChild(del);
          ul.appendChild(li);
        });
        td.appendChild(ul);
      })
      .catch(function(){ td.textContent = '상세를 불러오지 못했습니다.'; });
  }

  function fnDeleteEntry(tab, key, c) {
    if (!confirm('이 참여(' + (c.wrterNm || '사용자') + ', 별점 ' + c.stsfdg + '점)를 삭제할까요?')) return;
    var params = { tab: tab };
    if (tab === 'bbs') { params.stsfdgNo = c.stsfdgNo; }
    else { params.promNo = key.promNo; params.sinsId = c.wrterId; }
    var body = Object.keys(params).map(function(k){ return k + '=' + encodeURIComponent(params[k] == null ? '' : params[k]); }).join('&');
    fetch(CTX_DELETE, { method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' }, body: body })
      .then(function(r){ return r.json(); })
      .then(function(d){
        if (!d.ok) { alert(d.message || '삭제에 실패했습니다.'); return; }
        document.searchForm.submit();   /* 집계·목록 동기화 — 현재 탭/검색/페이지 유지 재조회 */
      })
      .catch(function(){ alert('삭제에 실패했습니다.'); });
  }
</script>
</lay:layout>
