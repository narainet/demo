<%
 /**
  * @Class Name : EgovArticleHistoryList.jsp
  * @Description : 게시판 연혁형(HISTORY) 엔진 — 연도별 연혁 페이지 (RLMS-KRDS)
  *                게시기간 시작일(없으면 등록일)을 연혁 시점으로 삼아 연도 그룹·역연대순으로 렌더.
  *                컨트롤러가 연혁형은 전건 조회하므로 페이저 없음.
  * @ 2026.07.14   RLMS               템플릿 재설계 — 신규 렌더엔진(연혁)
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 링크 접두 — 사용자 열람(EgovBoardUserController)은 /cop/bbs/user 를 넣어준다. 관리 화면은 기본값. --%>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<c:set var="pageTitle"><c:out value="${boardMasterVO.bbsNm}"/></c:set>
<c:set var="pageHead">
<!-- 게시판명 -->
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_egov_search_article(){
	document.articleForm.pageIndex.value = 1;
	document.articleForm.submit();
}
/* 연혁 렌더 — 숨김 데이터(#bbs-hist-src)에서 글을 읽어(제목=textContent 로 안전) 연도 그룹으로 렌더. */
function fn_bbs_hist_init(){
	var src = document.getElementById('bbs-hist-src');
	var host = document.getElementById('bbs-hist');
	if(!src || !host){ return; }
	var recs = [];
	var nodes = src.getElementsByClassName('bbs-hist-rec');
	for(var i=0;i<nodes.length;i++){
		var el = nodes[i];
		var start = el.getAttribute('data-start') || '';
		var end = el.getAttribute('data-end') || '';
		// 레거시 sentinel('19000101' 등 대시 없는 값)로 형식이 깨지면 등록일로 폴백 — 항목 누락 방지.
		if(!/^\d{4}-\d{2}-\d{2}$/.test(start)){ start = el.getAttribute('data-reg') || ''; }
		if(!/^\d{4}-\d{2}-\d{2}$/.test(start)){ continue; }
		if(!/^\d{4}-\d{2}-\d{2}$/.test(end) || end < start){ end = start; }
		recs.push({ start: start, end: end, url: el.getAttribute('data-url'), kind: el.getAttribute('data-kind'), title: el.textContent });
	}
	// 연혁 시점 내림차순(최신이 위) — 같은 날짜는 목록 순서 유지(stable sort)
	recs.sort(function(a,b){ return a.start < b.start ? 1 : (a.start > b.start ? -1 : 0); });
	var html = '';
	var curYear = '';
	for(var j=0;j<recs.length;j++){
		var y = recs[j].start.substr(0,4);
		if(y !== curYear){
			if(curYear !== ''){ html += '</ul></section>'; }
			html += '<section class="bbs-hist-year"><h2 class="bbs-hist-y">'+y+'</h2><ul class="bbs-hist-items">';
			curYear = y;
		}
		html += fn_bbs_hist_item(recs[j]);
	}
	if(curYear !== ''){ html += '</ul></section>'; }
	host.innerHTML = html;
}
function fn_bbs_hist_ym(ymd){
	return ymd.substr(0,4) + '.' + ymd.substr(5,2);
}
function fn_bbs_hist_item(r){
	// 제목은 textContent 로 담겨 안전하나, HTML 삽입 전 최소 이스케이프.
	var t = (r.title||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
	var body;
	if(r.kind === 'deleted'){ body = '<span class="bbs-deleted-title">이 글은 작성자에 의해서 삭제되었습니다.</span> <span class="krds-badge bg-light-gray">삭제됨</span>'; }
	else if(r.kind === 'secret'){ body = '<span class="bbs-secret">&#128274; 비밀글입니다.</span>'; }
	else if(!r.url || r.url === '#'){ body = '<span class="bbs-hist-title">'+t+'</span>'; }
	else { body = '<a class="bbs-hist-title" href="'+r.url+'" title="'+t+'">'+t+'</a>'; }
	if(r.kind === 'notice'){ body += ' <span class="krds-badge bg-light-danger">공지</span>'; }
	// 종료월이 시작월과 다르면 기간(시작~종료)으로 표시
	var range = '';
	if(r.end && r.end.substr(0,7) !== r.start.substr(0,7)){
		range = ' <span class="bbs-hist-range">'+fn_bbs_hist_ym(r.start)+' ~ '+fn_bbs_hist_ym(r.end)+'</span>';
	}
	return '<li class="bbs-hist-item"><span class="bbs-hist-month">'+r.start.substr(5,2)+'월</span><div class="bbs-hist-body">'+body+range+'</div></li>';
}
window.onload = fn_bbs_hist_init;
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
	<h1><c:out value="${boardMasterVO.bbsNm}"/></h1><!-- 게시판명 -->
	<c:if test="${not empty fn:trim(boardMasterVO.bbsIntrcn)}">
		<p class="page-desc"><c:out value="${boardMasterVO.bbsIntrcn}"/></p><!-- 게시판 소개내용 -->
	</c:if>
</div>

<%-- 검색 폼 --%>
<form name="articleForm" action="<c:url value='${bbsUrlBase}/selectArticleList.do'/>" method="get"
	  class="krds-form search-form" onSubmit="fn_egov_search_article(); return false;">
	<c:if test="${boardMasterVO.searchBoxAt != 'N'}">
	<div class="form-group inline">
		<label class="form-label" for="searchCnd"><spring:message code="title.searchCondition" /></label>
		<div class="form-conts">
			<select id="searchCnd" name="searchCnd" class="krds-select">
				<option value="0" <c:if test="${searchVO.searchCnd == '0'}">selected="selected"</c:if>><spring:message code="comCopBbs.articleVO.list.nttSj" /></option>
				<option value="1" <c:if test="${searchVO.searchCnd == '1'}">selected="selected"</c:if>><spring:message code="comCopBbs.articleVO.list.nttCn" /></option>
				<option value="2" <c:if test="${searchVO.searchCnd == '2'}">selected="selected"</c:if>><spring:message code="table.reger" /></option>
			</select>
			<input type="text" name="searchWrd" class="krds-input" value="<c:out value="${searchVO.searchWrd}"/>" maxlength="155"/>
		</div>
		<button type="submit" class="krds-btn primary medium"><spring:message code="button.inquire" /></button>
	</div>
	</c:if>
	<input name="bbsId" type="hidden" value="${boardMasterVO.bbsId}">
	<input name="pageIndex" type="hidden" value="">
</form>

<div class="list-top">
	<p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>
	<c:if test="${preview != 'true' and (empty bbsUserMode or bbsCanWrite)}">
		<span class="list-btns">
			<c:url var="insertUrl" value="${bbsUrlBase}/insertArticleView.do">
				<c:param name="bbsId" value="${boardMasterVO.bbsId}" />
				<c:param name="searchCnd" value="${searchVO.searchCnd}" />
				<c:param name="searchWrd" value="${searchVO.searchWrd}" />
				<c:param name="pageIndex" value="${searchVO.pageIndex}" />
			</c:url>
			<a class="krds-btn primary medium" href="${insertUrl}"><spring:message code="button.create" /></a>
		</span>
	</c:if>
</div>

<c:choose>
	<c:when test="${fn:length(resultList) == 0}">
		<div class="empty-row"><spring:message code="common.nodata.msg" /></div>
	</c:when>
	<c:otherwise>
		<%-- 연혁 데이터(숨김) — 제목은 c:out(텍스트)로 담아 JS 가 textContent 로 안전하게 읽는다.
		     공지(NOTICE_AT='Y')도 본문 목록에 포함되므로 별도 상단 고정 없이 연혁 시점에 배치(공지 배지). --%>
		<div id="bbs-hist-src" style="display:none;">
			<%-- 연혁 시점 = 게시기간(시작~종료). 없거나 sentinel(1900-01-01/9999-12-31)이면 등록일. --%>
			<c:forEach items="${resultList}" var="a">
				<c:url var="u" value="${bbsUrlBase}/selectArticleDetail.do">
					<c:param name="nttId" value="${a.nttId}" /><c:param name="bbsId" value="${a.bbsId}" />
					<c:param name="searchCnd" value="${searchVO.searchCnd}" /><c:param name="searchWrd" value="${searchVO.searchWrd}" /><c:param name="pageIndex" value="${searchVO.pageIndex}" />
				</c:url>
				<%-- kind 우선순위: deleted(최우선) > secret > notice — 뒤의 c:set 이 이긴다. --%>
				<c:set var="kind" value="normal" />
				<c:if test="${a.noticeAt == 'Y'}"><c:set var="kind" value="notice" /></c:if>
				<c:if test="${a.secretAt == 'Y' && sessionUniqId != a.frstRegisterId}"><c:set var="kind" value="secret" /></c:if>
				<c:if test="${a.useAt == 'N'}"><c:set var="kind" value="deleted" /></c:if>
				<c:set var="pBgn" value="${fn:trim(a.ntceBgnde)}" /><c:set var="pEnd" value="${fn:trim(a.ntceEndde)}" />
				<c:set var="histStart" value="${(not empty pBgn and pBgn ne '1900-01-01') ? fn:substring(pBgn,0,10) : fn:substring(a.frstRegisterPnttm,0,10)}" />
				<c:set var="histEnd" value="${(not empty pEnd and pEnd ne '9999-12-31') ? fn:substring(pEnd,0,10) : histStart}" />
				<%-- 비밀글·삭제글 제목은 서버에서 아예 미출력 — 숨김 div 도 페이지 소스로 읽히므로 JS 치환만으론 노출. --%>
				<div class="bbs-hist-rec" data-start="${histStart}" data-end="${histEnd}" data-reg="${fn:substring(a.frstRegisterPnttm,0,10)}" data-url="${preview == 'true' ? '#' : u}" data-kind="${kind}"><c:if test="${kind == 'normal' or kind == 'notice'}"><c:out value="${a.nttSj}"/></c:if></div>
			</c:forEach>
		</div>

		<%-- 연혁 렌더 대상 --%>
		<div id="bbs-hist" class="bbs-hist-wrap"></div>
	</c:otherwise>
</c:choose>
</lay:layout>
