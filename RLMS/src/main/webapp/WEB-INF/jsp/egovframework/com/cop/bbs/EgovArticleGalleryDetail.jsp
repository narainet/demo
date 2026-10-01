<%
 /**
  * @Class Name : EgovArticleGalleryDetail.jsp
  * @Description : 게시글 상세 — 갤러리형(GALLERY) 전용. 내용 아래 첨부 이미지를 갤러리로 렌더(다중이면 슬라이드).
  *                공통 상세(EgovArticleDetail)와 동일 골격 + 첨부영역만 이미지 갤러리로 대체. KRDS 표준.
  * @ 2026.07.14   RLMS               템플릿 재설계 — 갤러리형 전용 상세(첨부 이미지 갤러리)
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<c:set var="pageTitle"><spring:message code="comCopBbs.articleVO.title"/></c:set>
<%-- 링크 접두 — 사용자 열람(EgovBoardUserController)은 /cop/bbs/user, /cop/cmt/user 를 넣어준다. 관리 화면은 기본값. --%>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<c:set var="cmtUrlBase" value="${empty cmtUrlBase ? '/cop/cmt' : cmtUrlBase}"/>
<c:set var="stfUrlBase" value="${empty stfUrlBase ? '/cop/stf' : stfUrlBase}"/>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.detail" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_egov_delete_article(form){
	if(confirm("<spring:message code="common.delete.msg" />")){
		form.submit();
	}
}
function fn_egov_reply_article() {
	document.articleForm.action = "<c:url value='/cop/bbs/replyArticleView.do'/>";
	document.articleForm.submit();
}
/* 첨부 이미지 슬라이드 — 다중 이미지일 때 한 장씩 표시, prev/next·점 인디케이터로 전환. */
function fn_bbs_gd_init(){
	var track = document.getElementById('bbs-gd-track');
	if(!track){ return; }
	var slides = track.getElementsByClassName('bbs-gd-slide');
	var dots = document.querySelectorAll('#bbs-gd-dots .bbs-gd-dot');
	var total = slides.length;
	var cur = 0;
	function show(i){
		if(i < 0){ i = total - 1; }
		if(i >= total){ i = 0; }
		for(var k=0;k<slides.length;k++){ slides[k].style.display = (k === i) ? '' : 'none'; }
		for(var d=0;d<dots.length;d++){ dots[d].className = dots[d].className.replace(' active',''); }
		if(dots[i]){ dots[i].className += ' active'; }
		var cc = document.getElementById('bbs-gd-cur');
		if(cc){ cc.innerHTML = (i + 1); }
		cur = i;
	}
	var prev = document.getElementById('bbs-gd-prev');
	var next = document.getElementById('bbs-gd-next');
	if(prev){ prev.onclick = function(){ show(cur - 1); }; }
	if(next){ next.onclick = function(){ show(cur + 1); }; }
	for(var d=0;d<dots.length;d++){
		dots[d].onclick = function(){ show(parseInt(this.getAttribute('data-idx'), 10)); };
	}
}
if (window.addEventListener) { window.addEventListener('load', fn_bbs_gd_init); }
else { window.attachEvent('onload', fn_bbs_gd_init); }
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
	<h2>${pageTitle} <spring:message code="title.detail" /></h2>
</div>

<!-- 상세조회 -->
<table class="krds-table tbl-detail">
	<caption class="sr-only">${pageTitle} <spring:message code="title.detail" /></caption>
	<colgroup>
		<col style="width:14%;">
		<col style="width:*;">
		<col style="width:14%;">
		<col style="width:20%;">
		<col style="width:14%;">
		<col style="width:14%;">
	</colgroup>
	<tbody>
		<!-- 글 제목 -->
		<tr>
			<th scope="row"><spring:message code="comCopBbs.articleVO.detail.nttSj" /></th>
			<td colspan="5" class="al"><c:out value="${result.nttSj}"/><c:if test="${result.useAt eq 'N'}"> <span class="krds-badge bg-light-gray">삭제됨</span></c:if></td>
		</tr>
		<!-- 작성자, 작성시각, 조회수 -->
		<tr>
			<th scope="row"><spring:message code="table.reger" /></th>
			<td class="al"><c:out value="${result.frstRegisterNm}"/></td>
			<th scope="row"><spring:message code="table.regdate" /></th>
			<td class="al"><c:out value="${result.frstRegisterPnttm}"/></td>
			<th scope="row"><spring:message code="comCopBbs.articleVO.detail.inqireCo" /></th>
			<td class="al"><c:out value="${result.inqireCo}"/></td>
		</tr>
		<!-- 글 내용 -->
		<tr>
			<th scope="row"><spring:message code="comCopBbs.articleVO.detail.nttCn" /></th>
			<td colspan="5" class="bbs-detail-content">
				<c:out value="${fn:replace(result.nttCn , crlf , '<br/>')}" escapeXml="false" />
			</td>
		</tr>
		<%-- 여분필드 --%>
		<c:forEach begin="1" end="10" var="i">
			<c:set var="fieldLabel" value="${boardMasterVO.getBbsExtraField(i)}" />
			<c:if test="${not empty fieldLabel}">
				<c:set var="fieldValue" value="${result.getNttExtraField(i)}" />
				<c:set var="displayValue" value="${fieldValue}" />
				<c:set var="fieldOptions" value="${bbsExtraCodeOptions[i]}" />
				<c:if test="${not empty fieldOptions and not empty fieldValue}">
					<c:set var="displayValue"><c:forTokens items="${fieldValue}" delims="," var="token" varStatus="tk"><c:if test="${not tk.first}">, </c:if><c:set var="tokenNm" value="${token}" /><c:forEach var="code" items="${fieldOptions}"><c:if test="${token == code.code}"><c:set var="tokenNm" value="${code.codeNm}" /></c:if></c:forEach>${tokenNm}</c:forTokens></c:set>
				</c:if>
				<tr>
					<th scope="row"><c:out value="${fieldLabel}" /></th>
					<td colspan="5" class="al"><c:out value="${displayValue}" /></td>
				</tr>
			</c:if>
		</c:forEach>
		<%-- 게시기간 --%>
		<c:set var="pBgn" value="${fn:trim(result.ntceBgnde)}" />
		<c:set var="pEnd" value="${fn:trim(result.ntceEndde)}" />
		<c:set var="showBgn" value="${not empty pBgn and pBgn ne '1900-01-01'}" />
		<c:set var="showEnd" value="${not empty pEnd and pEnd ne '9999-12-31'}" />
		<c:if test="${showBgn or showEnd}">
		<tr>
			<th scope="row"><spring:message code="comCopBbs.articleVO.detail.ntceDe" /></th>
			<td colspan="5" class="al">
				<c:out value="${showBgn ? pBgn : ''} ~ ${showEnd ? pEnd : ''}" />
			</td>
		</tr>
		</c:if>
		<!-- 첨부파일 — 갤러리형은 첨부 이미지를 갤러리(다중이면 슬라이드)로 먼저 보이고, 다운로드 목록을 아래에 둔다. -->
		<c:if test="${not empty result.atchFileId}">
		<tr>
			<th scope="row"><spring:message code="comCopBbs.articleVO.detail.atchFile" /></th>
			<td colspan="5">
				<c:if test="${not empty galleryImages}">
					<c:set var="encAtch" value="${egovc:encryptSession(result.atchFileId, pageContext.session.id)}" />
					<div class="bbs-gd-gallery">
						<c:choose>
							<%-- 이미지 1장 — 그대로 표시 --%>
							<c:when test="${fn:length(galleryImages) == 1}">
								<c:set var="img" value="${galleryImages[0]}" />
								<figure class="bbs-gd-single">
									<img src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=${encAtch}&amp;fileSn=${img.fileSn}" alt="<c:out value='${img.orignlFileNm}'/>">
									<figcaption class="bbs-gd-cap"><c:out value="${img.orignlFileNm}" /></figcaption>
								</figure>
							</c:when>
							<%-- 이미지 여러 장 — 슬라이드 --%>
							<c:otherwise>
								<div class="bbs-gd-slider">
									<button type="button" class="bbs-gd-nav prev" id="bbs-gd-prev" aria-label="이전 이미지">&#10094;</button>
									<div class="bbs-gd-track" id="bbs-gd-track">
										<c:forEach items="${galleryImages}" var="img" varStatus="st">
											<figure class="bbs-gd-slide" data-idx="${st.index}"<c:if test="${not st.first}"> style="display:none;"</c:if>>
												<img src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=${encAtch}&amp;fileSn=${img.fileSn}" alt="<c:out value='${img.orignlFileNm}'/>">
												<figcaption class="bbs-gd-cap"><c:out value="${img.orignlFileNm}" /></figcaption>
											</figure>
										</c:forEach>
									</div>
									<button type="button" class="bbs-gd-nav next" id="bbs-gd-next" aria-label="다음 이미지">&#10095;</button>
									<div class="bbs-gd-counter"><span id="bbs-gd-cur">1</span> / ${fn:length(galleryImages)}</div>
									<div class="bbs-gd-dots" id="bbs-gd-dots">
										<c:forEach items="${galleryImages}" var="img" varStatus="st">
											<button type="button" class="bbs-gd-dot<c:if test="${st.first}"> active</c:if>" data-idx="${st.index}" aria-label="${st.index + 1}번째 이미지"></button>
										</c:forEach>
									</div>
								</div>
							</c:otherwise>
						</c:choose>
					</div>
				</c:if>
				<%-- 다운로드 목록 — 이미지 외 첨부(문서 등)도 포함. --%>
				<c:import url="/cmm/fms/selectFileInfs.do" charEncoding="utf-8">
					<c:param name="param_atchFileId" value="${egovc:encrypt(result.atchFileId)}" />
				</c:import>
			</td>
		</tr>
	  	</c:if>

	</tbody>
</table>

<!-- 하단 버튼 -->
<div class="btn-area">
	<c:set var="bbsUserCanEdit" value="${bbsCanWrite and not empty sessionUniqId and result.frstRegisterId == sessionUniqId}" />
	<c:if test="${result.useAt eq 'Y' and result.ntcrId != 'anonymous' and (empty bbsUserMode or bbsUserCanEdit)}">
	<form name="articleForm" action="<c:url value='${bbsUrlBase}/updateArticleView.do'/>" method="get" style="display:inline;">
		<input type="submit" class="krds-btn primary medium" value="<spring:message code="button.update" />" title="<spring:message code="title.update" /> <spring:message code="input.button" />" />
		<input type="hidden" name="parnts" value="<c:out value='${result.parnts}'/>" >
		<input type="hidden" name="sortOrdr" value="<c:out value='${result.sortOrdr}'/>" >
		<input type="hidden" name="replyLc" value="<c:out value='${result.replyLc}'/>" >
		<input type="hidden" name="nttSj" value="<c:out value='${result.nttSj}'/>" >
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	<form name="formDelete" action="<c:url value='${bbsUrlBase}/deleteArticle.do'/>" method="post" style="display:inline;">
		<input type="submit" class="krds-btn danger medium" value="<spring:message code="button.delete" />" title="<spring:message code="button.delete" /> <spring:message code="input.button" />" onclick="fn_egov_delete_article(this.form); return false;">
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	</c:if>
	<c:if test="${result.useAt eq 'Y' and boardMasterVO.replyPosblAt == 'Y' and (empty bbsUserMode or bbsCanWrite)}">
	<form name="formReply" action="<c:url value='${bbsUrlBase}/replyArticleView.do'/>" method="post" style="display:inline;">
		<input type="submit" class="krds-btn secondary medium" value="<spring:message code="button.reply" />">
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
	</form>
	</c:if>
	<c:if test="${result.useAt eq 'N' and isAdmin}">
	<form name="articleForm" action="<c:url value='/cop/bbs/updateArticleView.do'/>" method="get" style="display:inline;">
		<input type="submit" class="krds-btn primary medium" value="수정 / 복구" />
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	</c:if>
	<form name="formList" action="<c:url value='${bbsUrlBase}/selectArticleList.do'/>" method="get" style="display:inline;">
		<input type="submit" class="krds-btn secondary medium" value="<spring:message code="button.list" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
</div>

<!-- 댓글 -->
<c:if test="${useComment == 'true'}">
	<c:import url="${cmtUrlBase}/selectArticleCommentList.do" charEncoding="utf-8"/>
</c:if>

<c:if test="${useSatisfaction == 'true'}">
	<c:import url="${stfUrlBase}/selectSatisfactionList.do" charEncoding="utf-8">
		<c:param name="type" value="body" />
	</c:import>
</c:if>
</lay:layout>
