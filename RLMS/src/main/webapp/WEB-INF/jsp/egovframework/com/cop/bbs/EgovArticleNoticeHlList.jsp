<%
 /**
  * @Class Name : EgovArticleNoticeHlList.jsp
  * @Description : 게시판 공지 강조형(NOTICEHL) 엔진 — 공지를 상단 카드로 강조 + 일반글 목록 (RLMS-KRDS)
  *                공지(NOTICE_AT='Y')는 noticeList(상단 카드), 본문 목록은 공지 제외한 일반글.
  * @ 2026.07.14   RLMS               템플릿 재설계 — 신규 렌더엔진(공지 강조)
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<%-- 오늘(yyyy-MM-dd) — 상단 강조 카드의 게시기간 게이팅 기준. --%>
<% pageContext.setAttribute("todayYmd", new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date())); %>
<c:set var="pageTitle"><c:out value="${boardMasterVO.bbsNm}"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_egov_select_linkPage(pageNo){
	document.articleForm.pageIndex.value = pageNo;
	document.articleForm.action = "<c:url value='${bbsUrlBase}/selectArticleList.do'/>";
	document.articleForm.submit();
}
function fn_egov_search_article(){
	document.articleForm.pageIndex.value = 1;
	document.articleForm.submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
	<h1><c:out value="${boardMasterVO.bbsNm}"/></h1>
	<c:if test="${not empty fn:trim(boardMasterVO.bbsIntrcn)}">
		<p class="page-desc"><c:out value="${boardMasterVO.bbsIntrcn}"/></p>
	</c:if>
</div>

<%-- 상단 강조 — 공지(NOTICE_AT='Y') 중 게시기간이 유효한(또는 무기한) 것만.
     게시기간이 지난(만료) 또는 아직 시작 안 한(예정) 공지는 상단 카드에서 제외한다. 기간 미설정=영구 노출.
     ★상단 카드만 게이팅한다 — 본문 목록은 그대로 전건 표시(글 자체가 사라지진 않음). --%>
<c:set var="activeNoticeCnt" value="0" />
<c:forEach items="${noticeList}" var="n">
	<c:set var="nB" value="${fn:trim(n.ntceBgnde)}" /><c:set var="nE" value="${fn:trim(n.ntceEndde)}" />
	<c:set var="nHasB" value="${not empty nB and nB ne '1900-01-01' and fn:length(nB) == 10}" />
	<c:set var="nHasE" value="${not empty nE and nE ne '9999-12-31' and fn:length(nE) == 10}" />
	<c:if test="${not (nHasB and todayYmd lt nB) and not (nHasE and todayYmd gt nE)}"><c:set var="activeNoticeCnt" value="${activeNoticeCnt + 1}" /></c:if>
</c:forEach>
<c:if test="${activeNoticeCnt > 0}">
<div class="bbs-nh-hl">
	<c:forEach items="${noticeList}" var="n">
		<c:set var="nB" value="${fn:trim(n.ntceBgnde)}" /><c:set var="nE" value="${fn:trim(n.ntceEndde)}" />
		<c:set var="nHasB" value="${not empty nB and nB ne '1900-01-01' and fn:length(nB) == 10}" />
		<c:set var="nHasE" value="${not empty nE and nE ne '9999-12-31' and fn:length(nE) == 10}" />
		<c:if test="${not (nHasB and todayYmd lt nB) and not (nHasE and todayYmd gt nE)}">
			<c:url var="nUrl" value="${bbsUrlBase}/selectArticleDetail.do">
				<c:param name="nttId" value="${n.nttId}" /><c:param name="bbsId" value="${n.bbsId}" />
				<c:param name="searchCnd" value="${searchVO.searchCnd}" /><c:param name="searchWrd" value="${searchVO.searchWrd}" /><c:param name="pageIndex" value="${searchVO.pageIndex}" />
			</c:url>
			<a class="bbs-nh-card" href="${preview == 'true' ? '#' : nUrl}">
				<span class="krds-badge bg-light-danger">공지</span>
				<span class="bbs-nh-card-title"><c:out value="${n.nttSj}" /></span>
				<span class="bbs-nh-card-meta"><c:out value="${n.frstRegisterNm}" /> · <c:out value="${n.frstRegisterPnttm}" /></span>
			</a>
		</c:if>
	</c:forEach>
</div>
</c:if>

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
	<input name="pageUnit" type="hidden" value="${searchVO.pageUnit}">
</form>

<div class="list-top">
	<p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>
	<c:if test="${fn:length(pageUnitOptions) > 1}">
		<span class="list-pagesize" style="margin-left:auto;display:inline-flex;align-items:center;gap:6px;">
			<label for="pageUnitSel" style="font-size:0.92em;color:#47516a;">표시 개수</label>
			<select id="pageUnitSel" class="krds-select" onchange="document.articleForm.pageUnit.value=this.value;document.articleForm.pageIndex.value=1;document.articleForm.submit();">
				<c:forEach var="opt" items="${pageUnitOptions}">
					<option value="${opt}" ${searchVO.pageUnit == opt ? 'selected="selected"' : ''}><c:out value="${opt}"/></option>
				</c:forEach>
			</select>
		</span>
	</c:if>
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

<table class="krds-table tbl-list">
	<caption class="sr-only"><c:out value="${boardMasterVO.bbsNm}"/></caption>
	<colgroup>
		<col>
		<col style="width:13%;">
		<col style="width:13%;">
		<col style="width:10%;">
	</colgroup>
	<thead>
	<tr>
		<th scope="col"><spring:message code="comCopBbs.articleVO.list.nttSj" /></th>
		<th scope="col"><spring:message code="table.reger" /></th>
		<th scope="col"><spring:message code="table.regdate" /></th>
		<th scope="col"><spring:message code="comCopBbs.articleVO.list.inqireCo" /></th>
	</tr>
	</thead>
	<tbody>
		<%-- 본문 목록 = 전체 글(공지 포함). 공지는 상단 카드로 강조되고, 본문 목록에도 표기해 어느 페이지에서도 유실되지 않는다. --%>
		<c:forEach items="${resultList}" var="resultInfo">
			<c:url var="detailUrl" value="${bbsUrlBase}/selectArticleDetail.do">
				<c:param name="nttId" value="${resultInfo.nttId}" /><c:param name="bbsId" value="${resultInfo.bbsId}" />
				<c:param name="searchCnd" value="${searchVO.searchCnd}" /><c:param name="searchWrd" value="${searchVO.searchWrd}" /><c:param name="pageIndex" value="${searchVO.pageIndex}" />
			</c:url>
			<tr>
				<td class="al">
					<c:choose>
						<c:when test="${resultInfo.useAt == 'N'}">
							<a class="bbs-deleted-title" href="${preview == 'true' ? '#' : detailUrl}">이 글은 작성자에 의해서 삭제되었습니다.</a>
							<span class="krds-badge bg-light-gray">삭제됨</span>
						</c:when>
						<c:when test="${resultInfo.secretAt == 'Y' && sessionUniqId != resultInfo.frstRegisterId}">
							<span class="bbs-secret">&#128274; 비밀글입니다.</span>
						</c:when>
						<c:otherwise>
							<c:if test="${resultInfo.noticeAt == 'Y'}"><span class="krds-badge bg-light-danger">공지</span> </c:if>
							<a class="${resultInfo.sjBoldAt == 'Y' ? 'bbs-strong' : ''}" href="${preview == 'true' ? '#' : detailUrl}"><c:out value="${resultInfo.nttSj}" /></a><c:if test="${resultInfo.commentCo != ''}"> <span class="bbs-cmt">[<c:out value="${resultInfo.commentCo}" />]</span></c:if>
						</c:otherwise>
					</c:choose>
				</td>
				<td><c:out value="${resultInfo.frstRegisterNm}" /></td>
				<td class="bbs-date"><c:out value="${resultInfo.frstRegisterPnttm}" /></td>
				<td><c:out value="${resultInfo.inqireCo}" /></td>
			</tr>
		</c:forEach>
		<c:if test="${fn:length(resultList) == 0}">
			<tr><td colspan="4" class="empty-row"><spring:message code="common.nodata.msg" /></td></tr>
		</c:if>
	</tbody>
</table>

<c:if test="${boardMasterVO.pagingAt != 'N'}">
<div class="krds-pagination">
	<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_linkPage"/>
</div>
</c:if>
</lay:layout>
