<%
 /**
  * @Class Name : EgovArticleArchiveList.jsp
  * @Description : 게시판 자료실형(ARCHIVE) 엔진 — 제목·내용·게시기간·첨부·여분필드1 분류 (RLMS-KRDS)
  *                게시기간이 설정된 글은 그 기간에만 노출(미설정=항상 노출). 사용자에겐 서버에서 게이팅해 숨기고,
  *                관리자는 예정·만료도 배지로 본다. 분류 축 = 여분필드1(코드형). 탭 = 서버측 필터 링크(searchCategory) + 표준 페이징.
  * @ 2026.07.14   RLMS               템플릿 재설계 — 신규 렌더엔진(자료실)
  * @ 2026.07.15   RLMS               서버측 분류 필터·게시기간 게이팅 + 표준 페이징으로 전환
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<%-- 오늘(yyyy-MM-dd) — 관리자 배지(노출예정·노출만료) 판정 기준. 사용자 노출 게이팅은 서버(SQL)가 이미 처리. --%>
<% pageContext.setAttribute("todayYmd", new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date())); %>
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
/* 페이징 — 현재 검색어·선택 분류(searchCategory hidden)를 유지한 채 페이지만 이동. */
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

<%-- 검색 폼 — 선택 분류(searchCategory)는 hidden 으로 실어 검색·페이징에서 유지한다. --%>
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

<%-- 분류 여분필드1 이 설정된 자료실만 탭(필터 링크)을 노출. 선택 탭은 pageIndex=1 로 리셋하고 검색어는 유지. --%>
<c:if test="${catIdx > 0}">
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
</c:if>

<table class="krds-table tbl-list bbs-arch">
	<caption class="sr-only"><c:out value="${boardMasterVO.bbsNm}"/> 자료실</caption>
	<colgroup>
		<col>
		<c:if test="${catIdx > 0}"><col style="width:13%;"></c:if>
		<col style="width:17%;">
		<col style="width:8%;">
		<col style="width:12%;">
	</colgroup>
	<thead>
	<tr>
		<th scope="col"><spring:message code="comCopBbs.articleVO.list.nttSj" /></th>
		<c:if test="${catIdx > 0}"><th scope="col"><c:out value="${catLabel}"/></th></c:if>
		<th scope="col"><spring:message code="comCopBbs.articleVO.detail.ntceDe" /></th>
		<th scope="col">첨부</th>
		<th scope="col"><spring:message code="table.regdate" /></th>
	</tr>
	</thead>
	<tbody>
		<c:forEach items="${resultList}" var="resultInfo">
			<%-- 게시기간 배지(관리자 표시용). 사용자 목록은 서버에서 이미 게이팅되어 활성 자료만 온다. --%>
			<c:set var="vBgn" value="${fn:trim(resultInfo.ntceBgnde)}" /><c:set var="vEnd" value="${fn:trim(resultInfo.ntceEndde)}" />
			<%-- 날짜 경계는 dash형(yyyy-MM-dd, 10자)만 유효 — sentinel·레거시 dashless 값은 무경계로 취급. --%>
			<c:set var="hasBgn" value="${not empty vBgn and vBgn ne '1900-01-01' and fn:length(vBgn) == 10}" /><c:set var="hasEnd" value="${not empty vEnd and vEnd ne '9999-12-31' and fn:length(vEnd) == 10}" />
			<c:set var="isPending" value="${hasBgn and todayYmd lt vBgn}" />
			<c:set var="isExpired" value="${hasEnd and todayYmd gt vEnd}" />
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
							<a class="bbs-arch-title ${resultInfo.sjBoldAt == 'Y' ? 'bbs-strong' : ''}" href="${preview == 'true' ? '#' : detailUrl}"><c:out value="${resultInfo.nttSj}" /></a><c:if test="${resultInfo.commentCo != ''}"> <span class="bbs-cmt">[<c:out value="${resultInfo.commentCo}" />]</span></c:if>
							<c:if test="${isPending}"> <span class="krds-badge bg-light-warning">노출예정</span></c:if>
							<c:if test="${isExpired}"> <span class="krds-badge bg-light-gray">노출만료</span></c:if>
							<c:if test="${not empty fn:trim(resultInfo.nttCn)}"><span class="bbs-arch-excerpt"><c:out value="${resultInfo.nttCn}" /></span></c:if>
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
				<td class="bbs-arch-period">
					<c:choose>
						<c:when test="${hasBgn or hasEnd}"><c:out value="${hasBgn ? vBgn : ''}" /> ~ <c:out value="${hasEnd ? vEnd : ''}" /></c:when>
						<c:otherwise><span class="bbs-arch-nolimit">제한 없음</span></c:otherwise>
					</c:choose>
				</td>
				<td class="bbs-arch-file">
					<c:if test="${not empty fn:trim(resultInfo.atchFileId)}"><span title="첨부파일 있음" aria-label="첨부파일 있음">&#128206;</span></c:if>
				</td>
				<td class="bbs-date"><c:out value="${resultInfo.frstRegisterPnttm}" /></td>
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
