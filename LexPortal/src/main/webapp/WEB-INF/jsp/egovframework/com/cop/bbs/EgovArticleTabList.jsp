<%
 /**
  * @Class Name : EgovArticleTabList.jsp
  * @Description : 게시판 탭 분류형(TAB) 엔진 — 여분필드1(코드형) 값으로 탭 분류 (RLMS-KRDS)
  *                분류 축 = 여분필드1(radio/select/checkbox + 공통코드). 탭 = 전체 + 코드값들.
  *                탭 선택 시 서버측에서 여분필드1(NTT_EXTRA_FIELD_1)로 걸러 표준 페이징한다(searchCategory).
  * @ 2026.07.14   RLMS               템플릿 재설계 — 신규 렌더엔진(탭 분류)
  * @ 2026.07.15   RLMS               서버측 분류 필터 + 표준 페이징으로 전환(탭 = 필터 링크)
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<%-- 분류 축 = 여분필드1(공통코드 지정 시). 서버 필터(NTT_EXTRA_FIELD_1)와 짝이 맞도록 반드시 1번 고정.
     맵 키가 Integer 라 리터럴 첨자(EL 은 Long 으로 처리→미스)를 피해 forEach 의 Integer 변수(ci=1)로 조회한다. --%>
<c:set var="catIdx" value="0" />
<c:set var="catOptions" value="${null}" />
<c:forEach begin="1" end="1" var="ci">
	<c:if test="${not empty bbsExtraCodeOptions[ci]}">
		<c:set var="catIdx" value="1" />
		<c:set var="catOptions" value="${bbsExtraCodeOptions[ci]}" />
	</c:if>
</c:forEach>
<c:set var="catLabel" value="${catIdx > 0 ? boardMasterVO.getBbsExtraField(1) : ''}" />
<c:set var="pageTitle"><c:out value="${boardMasterVO.bbsNm}"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_egov_search_article(){
	document.articleForm.pageIndex.value = 1;
	document.articleForm.submit();
}
/* 페이징 — 현재 검색어·선택 탭(searchCategory hidden)을 유지한 채 페이지만 이동. */
function fn_egov_select_linkPage(pageNo){
	document.articleForm.pageIndex.value = pageNo;
	document.articleForm.action = "<c:url value='${bbsUrlBase}/selectArticleList.do'/>";
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

<%-- 검색 폼 — 선택 탭(searchCategory)은 hidden 으로 실어 검색·페이징에서 유지한다. --%>
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
	<input name="searchCategory" type="hidden" value="<c:out value='${searchVO.searchCategory}'/>">
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
	<%-- 분류 여분필드(1번) 미설정 — 탭 없이 전체 목록만(그래도 페이징은 동작). --%>
	<c:when test="${catIdx == 0}">
		<p class="bbs-cal-help">
			<span class="bbs-cal-help-ico" aria-hidden="true">&#8505;</span>
			<span>탭 분류 기준이 될 <strong>여분필드 1</strong>에 공통코드가 게시판 속성에 설정되어 있지 않아 전체 목록으로 표시합니다. (게시판관리 &gt; 여분필드 1에서 라디오·셀렉트 유형 + 공통코드를 지정하세요.)</span>
		</p>
	</c:when>
	<%-- 탭 = 필터 링크. 선택 탭은 pageIndex=1 로 리셋하고 검색어는 유지. 활성 탭 = 현재 searchCategory. --%>
	<c:otherwise>
		<div class="bbs-tab-nav" role="tablist">
			<c:url var="tabAllUrl" value="${bbsUrlBase}/selectArticleList.do">
				<c:param name="bbsId" value="${boardMasterVO.bbsId}" />
				<c:param name="searchCnd" value="${searchVO.searchCnd}" />
				<c:param name="searchWrd" value="${searchVO.searchWrd}" />
			</c:url>
			<a class="bbs-tab-btn ${empty searchVO.searchCategory ? 'active' : ''}" href="${tabAllUrl}">전체</a>
			<c:forEach var="code" items="${catOptions}">
				<c:url var="tabUrl" value="${bbsUrlBase}/selectArticleList.do">
					<c:param name="bbsId" value="${boardMasterVO.bbsId}" />
					<c:param name="searchCnd" value="${searchVO.searchCnd}" />
					<c:param name="searchWrd" value="${searchVO.searchWrd}" />
					<c:param name="searchCategory" value="${code.code}" />
				</c:url>
				<a class="bbs-tab-btn ${searchVO.searchCategory == code.code ? 'active' : ''}" href="${tabUrl}"><c:out value="${code.codeNm}"/></a>
			</c:forEach>
		</div>
	</c:otherwise>
</c:choose>

<table class="krds-table tbl-list">
	<caption class="sr-only"><c:out value="${boardMasterVO.bbsNm}"/> — <c:out value="${catLabel}"/> 분류</caption>
	<colgroup>
		<col>
		<c:if test="${catIdx > 0}"><col style="width:14%;"></c:if>
		<col style="width:12%;">
		<col style="width:12%;">
		<col style="width:9%;">
	</colgroup>
	<thead>
	<tr>
		<th scope="col"><spring:message code="comCopBbs.articleVO.list.nttSj" /></th>
		<c:if test="${catIdx > 0}"><th scope="col"><c:out value="${catLabel}"/></th></c:if>
		<th scope="col"><spring:message code="table.reger" /></th>
		<th scope="col"><spring:message code="table.regdate" /></th>
		<th scope="col"><spring:message code="comCopBbs.articleVO.list.inqireCo" /></th>
	</tr>
	</thead>
	<tbody>
		<c:forEach items="${resultList}" var="resultInfo">
			<c:set var="catCode" value="${catIdx > 0 ? resultInfo.getNttExtraField(1) : ''}" />
			<c:url var="detailUrl" value="${bbsUrlBase}/selectArticleDetail.do">
				<c:param name="nttId" value="${resultInfo.nttId}" /><c:param name="bbsId" value="${resultInfo.bbsId}" />
				<c:param name="searchCnd" value="${searchVO.searchCnd}" /><c:param name="searchWrd" value="${searchVO.searchWrd}" /><c:param name="searchCategory" value="${searchVO.searchCategory}" /><c:param name="pageIndex" value="${searchVO.pageIndex}" />
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
				<c:if test="${catIdx > 0}">
					<td>
						<%-- 다중선택(checkbox) 여분필드1 은 쉼표로 이어진 여러 코드 → 각각 배지로 --%>
						<c:if test="${not empty catCode}">
							<c:forEach var="one" items="${fn:split(catCode, ',')}">
								<c:set var="oneNm" value="${fn:trim(one)}" />
								<c:if test="${not empty catOptions}">
									<c:forEach var="code" items="${catOptions}"><c:if test="${fn:trim(one) == code.code}"><c:set var="oneNm" value="${code.codeNm}" /></c:if></c:forEach>
								</c:if>
								<c:if test="${not empty fn:trim(one)}"><span class="krds-badge bg-light-primary"><c:out value="${oneNm}" /></span> </c:if>
							</c:forEach>
						</c:if>
					</td>
				</c:if>
				<td><c:out value="${resultInfo.frstRegisterNm}" /></td>
				<td class="bbs-date"><c:out value="${resultInfo.frstRegisterPnttm}" /></td>
				<td><c:out value="${resultInfo.inqireCo}" /></td>
			</tr>
		</c:forEach>
		<c:if test="${fn:length(resultList) == 0}">
			<tr><td colspan="${catIdx > 0 ? 5 : 4}" class="empty-row"><spring:message code="common.nodata.msg" /></td></tr>
		</c:if>
	</tbody>
</table>

<c:if test="${boardMasterVO.pagingAt != 'N'}">
<div class="krds-pagination">
	<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_linkPage"/>
</div>
</c:if>
</lay:layout>
