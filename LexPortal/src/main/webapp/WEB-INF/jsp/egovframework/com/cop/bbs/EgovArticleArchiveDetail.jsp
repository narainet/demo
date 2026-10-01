<%
 /**
  * @Class Name : EgovArticleArchiveDetail.jsp
  * @Description : 게시글 상세 — 자료실형(ARCHIVE) 전용. 첨부 영역을 파일별 다운로드 수 + 다운로드 링크 표로 렌더.
  *                공통 상세(EgovArticleDetail)와 동일 골격 + 첨부영역만 자료실 파일표로 대체. KRDS 표준.
  * @ 2026.07.14   RLMS               템플릿 재설계 — 자료실형 전용 상세(파일별 다운로드 수)
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
		<%-- 여분필드(분류) --%>
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
		<%-- 게시기간(노출기간) --%>
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
		<!-- 첨부파일 — 자료실형은 파일별 다운로드 수를 함께 보여준다. -->
		<c:if test="${not empty result.atchFileId}">
		<tr>
			<th scope="row"><spring:message code="comCopBbs.articleVO.detail.atchFile" /></th>
			<td colspan="5">
				<c:choose>
					<c:when test="${not empty archiveFiles}">
						<%-- 중첩 table 은 바깥 tbl-detail 규칙(!important)에 오염되므로 ul/li 로 렌더. --%>
						<ul class="bbs-arcd-list">
							<li class="bbs-arcd-head">
								<span class="bbs-arcd-c-name">파일명</span>
								<span class="bbs-arcd-c-size">크기</span>
								<span class="bbs-arcd-c-cnt">다운로드</span>
							</li>
							<c:forEach items="${archiveFiles}" var="f">
								<c:set var="encF" value="${egovc:encryptSession(f.atchFileId, pageContext.session.id)}" />
								<li class="bbs-arcd-item">
									<a class="bbs-arcd-file" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encF}&amp;fileSn=${f.fileSn}">
										<c:if test="${not empty fn:trim(f.fileExtsn)}"><span class="bbs-arcd-ext"><c:out value="${fn:toUpperCase(f.fileExtsn)}"/></span></c:if>
										<span class="bbs-arcd-name"><c:out value="${f.orignlFileNm}"/></span>
									</a>
									<span class="bbs-arcd-size"><c:out value="${f.fileMg}"/> byte</span>
									<span class="bbs-arcd-cnt"><strong><c:out value="${f.dwldCo}"/></strong> 회</span>
								</li>
							</c:forEach>
						</ul>
					</c:when>
					<c:otherwise>
						<c:import url="/cmm/fms/selectFileInfs.do" charEncoding="utf-8">
							<c:param name="param_atchFileId" value="${egovc:encrypt(result.atchFileId)}" />
						</c:import>
					</c:otherwise>
				</c:choose>
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
