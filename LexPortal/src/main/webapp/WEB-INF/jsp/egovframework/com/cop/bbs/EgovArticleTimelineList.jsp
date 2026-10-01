<%
 /**
  * @Class Name : EgovArticleTimelineList.jsp
  * @Description : 게시판 타임라인형(TIMELINE) 엔진 — 날짜별 세로 흐름 (RLMS-KRDS)
  * @ 2026.07.14   RLMS               템플릿 재설계 — 신규 렌더엔진(타임라인)
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
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
function fn_egov_init(){
	if (document.articleForm && document.articleForm.searchCnd) {
		document.articleForm.searchCnd.focus();
	}
}
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
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
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

<c:choose>
	<c:when test="${fn:length(resultList) == 0 and fn:length(noticeList) == 0}">
		<div class="empty-row"><spring:message code="common.nodata.msg" /></div>
	</c:when>
	<c:otherwise>
		<div class="bbs-tl">
			<%-- 공지 — 타임라인 최상단 고정 --%>
			<c:forEach items="${noticeList}" var="noticeInfo">
				<c:url var="noticeUrl" value="${bbsUrlBase}/selectArticleDetail.do">
					<c:param name="nttId" value="${noticeInfo.nttId}" />
					<c:param name="bbsId" value="${noticeInfo.bbsId}" />
					<c:param name="searchCnd" value="${searchVO.searchCnd}" />
					<c:param name="searchWrd" value="${searchVO.searchWrd}" />
					<c:param name="pageIndex" value="${searchVO.pageIndex}" />
				</c:url>
				<div class="bbs-tl-item bbs-tl-notice">
					<div class="bbs-tl-date"><span class="krds-badge bg-light-danger">공지</span></div>
					<div class="bbs-tl-card">
						<a class="bbs-tl-title bbs-strong" href="${preview == 'true' ? '#' : noticeUrl}"><c:out value="${noticeInfo.nttSj}" /></a>
						<div class="bbs-tl-meta">
							<span><c:out value="${noticeInfo.frstRegisterNm}" /></span>
							<span><c:out value="${noticeInfo.frstRegisterPnttm}" /></span>
						</div>
					</div>
				</div>
			</c:forEach>

			<%-- 게시글 — 각 글이 세로선 위의 한 노드 --%>
			<c:forEach items="${resultList}" var="resultInfo" varStatus="status">
				<c:url var="detailUrl" value="${bbsUrlBase}/selectArticleDetail.do">
					<c:param name="nttId" value="${resultInfo.nttId}" />
					<c:param name="bbsId" value="${resultInfo.bbsId}" />
					<c:param name="searchCnd" value="${searchVO.searchCnd}" />
					<c:param name="searchWrd" value="${searchVO.searchWrd}" />
					<c:param name="pageIndex" value="${searchVO.pageIndex}" />
				</c:url>
				<div class="bbs-tl-item">
					<%-- 시간축 눈금이라 날짜만 — 시:분은 아래 카드 메타(bbs-tl-meta)로 뺐다 (2026-07-31) --%>
					<div class="bbs-tl-date"><c:out value="${fn:substring(resultInfo.frstRegisterPnttm, 0, 10)}" /></div>
					<div class="bbs-tl-card">
						<c:choose>
							<%-- 삭제(톰스톤): 원본 제목 대신 고정 문구, 요약 비노출. 원본은 DB 보존. --%>
							<c:when test="${resultInfo.useAt == 'N'}">
								<span class="bbs-tl-title"><span class="bbs-deleted-title">이 글은 작성자에 의해서 삭제되었습니다.</span> <span class="krds-badge bg-light-gray">삭제됨</span></span>
							</c:when>
							<%-- 비밀글이며 작성자 본인이 아님: 클릭 불가 --%>
							<c:when test="${resultInfo.secretAt == 'Y' && sessionUniqId != resultInfo.frstRegisterId}">
								<span class="bbs-tl-title bbs-secret">&#128274; 비밀글입니다.</span>
							</c:when>
							<%-- 정상 --%>
							<c:otherwise>
								<a class="bbs-tl-title" href="${preview == 'true' ? '#' : detailUrl}"><c:out value="${resultInfo.nttSj}" /></a><c:if test="${resultInfo.commentCo != ''}"> <span class="bbs-cmt">[<c:out value="${resultInfo.commentCo}" />]</span></c:if>
								<c:if test="${not empty fn:trim(resultInfo.nttCn)}">
									<p class="bbs-tl-excerpt"><c:out value="${resultInfo.nttCn}" /></p>
								</c:if>
							</c:otherwise>
						</c:choose>
						<div class="bbs-tl-meta">
							<span><c:out value="${resultInfo.frstRegisterNm}" /></span>
							<span><c:out value="${fn:substring(resultInfo.frstRegisterPnttm, 11, 16)}" /></span>
							<span><spring:message code="comCopBbs.articleVO.list.inqireCo" /> <c:out value="${resultInfo.inqireCo}" /></span>
						</div>
					</div>
				</div>
			</c:forEach>
		</div>
	</c:otherwise>
</c:choose>

<c:if test="${boardMasterVO.pagingAt != 'N'}">
<div class="krds-pagination">
	<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_linkPage"/>
</div>
</c:if>
</lay:layout>
