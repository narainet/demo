<%
 /**
  * @Class Name : EgovArticleGalleryList.jsp
  * @Description : 게시판 갤러리형(GALLERY) 엔진 — RLMS-KRDS 썸네일 카드 그리드
  * @Modification Information
  * @
  * @  수정일             수정자                   수정내용
  * @ -------    --------    ---------------------------
  * @ 2009.02.01   박정규              최초 생성
  *   2016.06.13   김연호              표준프레임워크 v3.6 개선
  *   2018.06.15   신용호              페이징 처리 오류 개선
  *   2024.10.29   LeeBaekHaeng       게시판 검색조건 유지
  *   2026.07.14   RLMS               템플릿 재설계 PHASE 2 — RLMS-KRDS 디자인 시스템으로 재작성
  *  @author 공통서비스팀
  *  @since 2009.02.01
  *  @version 1.0
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
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
	<%-- 관리 동선은 항상, 사용자 동선은 게시판별 작성권한(bbsCanWrite)이 있을 때만 등록 버튼을 보인다. --%>
	<c:if test="${preview != 'true' and (empty bbsUserMode or bbsCanWrite)}">
		<span class="list-btns">
			<c:url var="insertUrl" value="${bbsUrlBase}/insertArticleView.do">
				<c:param name="bbsId" value="${boardMasterVO.bbsId}" />
				<c:param name="searchCnd" value="${searchVO.searchCnd}" />
				<c:param name="searchWrd" value="${searchVO.searchWrd}" />
				<c:param name="pageIndex" value="${searchVO.pageIndex}" />
			</c:url>
			<a class="krds-btn primary medium" href="${insertUrl}"><spring:message code="button.create" /></a><!-- 등록 -->
		</span>
	</c:if>
</div>

<%-- 공지 — 그리드 위에 별도로. 항상 공지 배지 + 상세 링크. --%>
<c:if test="${fn:length(noticeList) > 0}">
	<table class="krds-table tbl-list">
		<caption class="sr-only"><c:out value="${boardMasterVO.bbsNm}"/> <spring:message code="title.list" /></caption>
		<colgroup>
			<col style="width:9%;">
			<col style="width:*;">
			<col style="width:13%;">
			<col style="width:13%;">
			<col style="width:10%;">
		</colgroup>
		<tbody>
			<c:forEach items="${noticeList}" var="noticeInfo">
				<c:url var="noticeUrl" value="${bbsUrlBase}/selectArticleDetail.do">
					<c:param name="nttId" value="${noticeInfo.nttId}" />
					<c:param name="bbsId" value="${noticeInfo.bbsId}" />
					<c:param name="searchCnd" value="${searchVO.searchCnd}" />
					<c:param name="searchWrd" value="${searchVO.searchWrd}" />
					<c:param name="pageIndex" value="${searchVO.pageIndex}" />
				</c:url>
				<tr>
					<td><span class="krds-badge bg-light-danger">공지</span></td>
					<td class="al">
						<a class="bbs-strong" href="${preview == 'true' ? '#' : noticeUrl}"><c:out value="${noticeInfo.nttSj}" /></a><c:if test="${noticeInfo.commentCo != ''}"> <span class="bbs-cmt">[<c:out value="${noticeInfo.commentCo}" />]</span></c:if>
					</td>
					<td><c:out value="${noticeInfo.frstRegisterNm}" /></td>
					<td class="bbs-date"><c:out value="${noticeInfo.frstRegisterPnttm}" /></td>
					<td><c:out value="${noticeInfo.inqireCo}" /></td>
				</tr>
			</c:forEach>
		</tbody>
	</table>
</c:if>

<c:choose>
	<c:when test="${fn:length(resultList) == 0}">
		<div class="empty-row"><spring:message code="common.nodata.msg" /></div>
	</c:when>
	<c:otherwise>
		<div class="bbs-gallery-grid">
			<c:forEach items="${resultList}" var="resultInfo">
				<c:url var="detailUrl" value="${bbsUrlBase}/selectArticleDetail.do">
					<c:param name="nttId" value="${resultInfo.nttId}" />
					<c:param name="bbsId" value="${resultInfo.bbsId}" />
					<c:param name="searchCnd" value="${searchVO.searchCnd}" />
					<c:param name="searchWrd" value="${searchVO.searchWrd}" />
					<c:param name="pageIndex" value="${searchVO.pageIndex}" />
				</c:url>
				<article class="bbs-gallery-card">
					<c:choose>
						<%-- 삭제(톰스톤): 원본 제목 대신 삭제됨 표기, 링크 없음. 원본은 DB 보존. --%>
						<c:when test="${resultInfo.useAt == 'N'}">
							<div class="bbs-gallery-thumb"><div class="bbs-gallery-empty-thumb">삭제됨</div></div>
							<div class="bbs-gallery-body">
								<strong class="bbs-gallery-title"><span class="bbs-deleted-title">이 글은 작성자에 의해서 삭제되었습니다.</span> <span class="krds-badge bg-light-gray">삭제됨</span></strong>
								<div class="bbs-gallery-meta">
									<span><c:out value="${resultInfo.frstRegisterNm}" /></span>
									<span><c:out value="${resultInfo.frstRegisterPnttm}" /></span>
								</div>
							</div>
						</c:when>
						<%-- 비밀글이며 작성자 본인이 아님: 클릭 불가 --%>
						<c:when test="${resultInfo.secretAt == 'Y' && sessionUniqId != resultInfo.frstRegisterId}">
							<div class="bbs-gallery-thumb"><div class="bbs-gallery-empty-thumb">비밀글</div></div>
							<div class="bbs-gallery-body">
								<strong class="bbs-gallery-title"><span class="bbs-secret">&#128274; 비밀글입니다.</span></strong>
								<div class="bbs-gallery-meta">
									<span><c:out value="${resultInfo.frstRegisterNm}" /></span>
									<span><c:out value="${resultInfo.frstRegisterPnttm}" /></span>
								</div>
							</div>
						</c:when>
						<%-- 정상 --%>
						<c:otherwise>
							<a href="${preview == 'true' ? '#' : detailUrl}">
								<div class="bbs-gallery-thumb">
									<c:choose>
										<c:when test="${not empty resultInfo.atchFileId}">
											<img class="bbs-gallery-img" src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=${egovc:encryptSession(resultInfo.atchFileId, pageContext.session.id)}" alt="">
										</c:when>
										<c:otherwise>
											<div class="bbs-gallery-empty-thumb">이미지 없음</div>
										</c:otherwise>
									</c:choose>
								</div>
								<div class="bbs-gallery-body">
									<strong class="bbs-gallery-title ${resultInfo.sjBoldAt == 'Y' ? 'bbs-strong' : ''}"><c:out value="${resultInfo.nttSj}" /><c:if test="${resultInfo.commentCo != ''}"> <span class="bbs-cmt">[<c:out value="${resultInfo.commentCo}" />]</span></c:if></strong>
									<div class="bbs-gallery-meta">
										<span><c:out value="${resultInfo.frstRegisterNm}" /></span>
										<span><c:out value="${resultInfo.frstRegisterPnttm}" /></span>
										<span><spring:message code="comCopBbs.articleVO.list.inqireCo" /> <c:out value="${resultInfo.inqireCo}" /></span>
									</div>
								</div>
							</a>
						</c:otherwise>
					</c:choose>
				</article>
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
