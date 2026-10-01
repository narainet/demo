<%
 /**
  * @Class Name : EgovArticleCalendarList.jsp
  * @Description : 게시판 캘린더형(CALENDAR) 엔진 — 월간 달력에 글을 게시기간(없으면 등록일)으로 배치 (RLMS-KRDS)
  *                컨트롤러가 캘린더형은 전건 조회하므로 페이저 없음 — 월 이동은 전 글 범위에서 클라이언트 렌더.
  * @ 2026.07.14   RLMS               템플릿 재설계 — 신규 렌더엔진(캘린더)
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
/* 달력 렌더 — 숨김 데이터(#bbs-cal-src)에서 글을 읽어(제목=textContent 로 안전) 월 그리드에 배치. */
function fn_bbs_cal_init(){
	var src = document.getElementById('bbs-cal-src');
	var host = document.getElementById('bbs-cal');
	if(!src || !host){ return; }
	var recs = [];
	var nodes = src.getElementsByClassName('bbs-cal-rec');
	for(var i=0;i<nodes.length;i++){
		var el = nodes[i];
		var start = el.getAttribute('data-start') || '';
		var end = el.getAttribute('data-end') || start;
		// 레거시 sentinel('19000101' 등 대시 없는 값)로 형식이 깨지면 등록일로 폴백 — 항목 누락 방지.
		if(!/^\d{4}-\d{2}-\d{2}$/.test(start)){ start = el.getAttribute('data-reg') || ''; }
		if(!/^\d{4}-\d{2}-\d{2}$/.test(start)){ continue; }
		if(!/^\d{4}-\d{2}-\d{2}$/.test(end)){ end = start; }
		recs.push({ start: start, end: end, url: el.getAttribute('data-url'), kind: el.getAttribute('data-kind'), title: el.textContent });
	}
	var byDay = {};
	var maxYmd = '';
	for(var j=0;j<recs.length;j++){
		var r = recs[j];
		// 게시기간(시작~종료)의 각 날짜 셀에 배치. 기간 미설정 글은 시작=종료(하루).
		var span = fn_bbs_cal_range(r.start, r.end);
		for(var k=0;k<span.length;k++){ (byDay[span[k]] = byDay[span[k]] || []).push(r); }
		if(r.start > maxYmd){ maxYmd = r.start; }
	}
	var now = new Date();
	var cur = maxYmd ? new Date(parseInt(maxYmd.substr(0,4),10), parseInt(maxYmd.substr(5,2),10)-1, 1)
	                 : new Date(now.getFullYear(), now.getMonth(), 1);
	var WD = ['일','월','화','수','목','금','토'];
	var todayYmd = fn_bbs_cal_ymd(now.getFullYear(), now.getMonth()+1, now.getDate());

	function render(){
		var y = cur.getFullYear(), m = cur.getMonth();
		var first = new Date(y, m, 1).getDay();
		var days = new Date(y, m+1, 0).getDate();
		var html = '';
		html += '<div class="bbs-cal-head">';
		html += '<button type="button" class="krds-btn medium" id="bbs-cal-prev">&#9664;</button>';
		html += '<span class="bbs-cal-title">'+y+'년 '+(m+1)+'월</span>';
		html += '<button type="button" class="krds-btn medium" id="bbs-cal-next">&#9654;</button>';
		html += '</div>';
		html += '<div class="bbs-cal-grid">';
		for(var w=0;w<7;w++){ html += '<div class="bbs-cal-wd'+(w===0?' sun':(w===6?' sat':''))+'">'+WD[w]+'</div>'; }
		for(var b=0;b<first;b++){ html += '<div class="bbs-cal-cell bbs-cal-empty"></div>'; }
		for(var d=1;d<=days;d++){
			var ymd = fn_bbs_cal_ymd(y, m+1, d);
			var dow = new Date(y, m, d).getDay();
			var cls = 'bbs-cal-cell'+(dow===0?' sun':(dow===6?' sat':''))+(ymd===todayYmd?' bbs-cal-today':'');
			html += '<div class="'+cls+'"><div class="bbs-cal-day">'+d+'</div>';
			var evs = byDay[ymd] || [];
			for(var e=0;e<evs.length;e++){ html += fn_bbs_cal_ev(evs[e]); }
			html += '</div>';
		}
		html += '</div>';
		host.innerHTML = html;
		var p = document.getElementById('bbs-cal-prev');
		var n = document.getElementById('bbs-cal-next');
		if(p){ p.onclick = function(){ cur = new Date(cur.getFullYear(), cur.getMonth()-1, 1); render(); }; }
		if(n){ n.onclick = function(){ cur = new Date(cur.getFullYear(), cur.getMonth()+1, 1); render(); }; }
	}
	render();
}
function fn_bbs_cal_ymd(y, m, d){
	return y + '-' + (m<10?'0'+m:m) + '-' + (d<10?'0'+d:d);
}
/* 시작~종료(YYYY-MM-DD) 사이의 날짜 목록. 종료<시작이면 시작 하루. 폭주 방지 62일 캡. */
function fn_bbs_cal_range(start, end){
	if(end < start){ return [start]; }
	var out = [];
	var d = new Date(parseInt(start.substr(0,4),10), parseInt(start.substr(5,2),10)-1, parseInt(start.substr(8,2),10));
	var e = new Date(parseInt(end.substr(0,4),10), parseInt(end.substr(5,2),10)-1, parseInt(end.substr(8,2),10));
	var cap = 0;
	while(d <= e && cap < 62){
		out.push(fn_bbs_cal_ymd(d.getFullYear(), d.getMonth()+1, d.getDate()));
		d.setDate(d.getDate()+1);
		cap++;
	}
	return out.length ? out : [start];
}
function fn_bbs_cal_ev(r){
	// 제목은 textContent 로 담겨 안전하나, HTML 삽입 전 최소 이스케이프.
	var t = (r.title||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
	if(r.kind === 'deleted'){ return '<span class="bbs-cal-ev deleted">삭제된 글</span>'; }
	if(r.kind === 'secret'){ return '<span class="bbs-cal-ev secret">&#128274; 비밀글</span>'; }
	var cls = 'bbs-cal-ev' + (r.kind === 'notice' ? ' notice' : '');
	if(!r.url || r.url === '#'){ return '<span class="'+cls+'">'+t+'</span>'; }
	return '<a class="'+cls+'" href="'+r.url+'" title="'+t+'">'+t+'</a>';
}
window.onload = fn_bbs_cal_init;
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

<%-- 달력 데이터(숨김) — 제목은 c:out(텍스트)로 담아 JS 가 textContent 로 안전하게 읽는다.
     공지(NOTICE_AT='Y')도 본문 목록(resultList)에 포함되므로 noticeList 는 쓰지 않는다(이중 렌더 방지). --%>
<div id="bbs-cal-src" style="display:none;">
	<%-- 캘린더 배치일 = 게시기간(시작~종료). 없거나 sentinel(1900-01-01/9999-12-31)이면 작성일 하루. --%>
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
		<c:set var="calStart" value="${(not empty pBgn and pBgn ne '1900-01-01') ? fn:substring(pBgn,0,10) : fn:substring(a.frstRegisterPnttm,0,10)}" />
		<c:set var="calEnd" value="${(not empty pEnd and pEnd ne '9999-12-31') ? fn:substring(pEnd,0,10) : calStart}" />
		<%-- 비밀글·삭제글 제목은 서버에서 아예 미출력 — 숨김 div 도 페이지 소스로 읽히므로 JS 치환만으론 노출. --%>
		<div class="bbs-cal-rec" data-start="${calStart}" data-end="${calEnd}" data-reg="${fn:substring(a.frstRegisterPnttm,0,10)}" data-url="${preview == 'true' ? '#' : u}" data-kind="${kind}"><c:if test="${kind == 'normal' or kind == 'notice'}"><c:out value="${a.nttSj}"/></c:if></div>
	</c:forEach>
</div>

<%-- 달력 렌더 대상 --%>
<div id="bbs-cal" class="bbs-cal-wrap"></div>
</lay:layout>
