<%
 /**
  * @Class Name : EgovGuestArticleList.jsp
  * @Description : 게시판 방명록(GUEST) 엔진 — RLMS-KRDS 디자인 시스템
  * @Modification Information
  * @
  * @  수정일             수정자                   수정내용
  * @ -------    --------    ---------------------------
  * @ 2009.02.01   박정규              최초 생성
  *   2016.06.13   김연호              표준프레임워크 v3.6 개선
  *   2026.07.14   RLMS               템플릿 재설계 PHASE 2 — RLMS-KRDS 디자인 시스템으로 재작성
  *  @author 공통서비스팀
  *  @since 2009.02.01
  *  @version 1.0
  *  @see
  *
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<c:set var="pageTitle"><spring:message code="comCopBbs.articleVO.guest.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.detail" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
/* ********************************************************
 * 삭제처리
 ******************************************************** */
 function fn_egov_delete_guest(nttId){
	if(confirm("<spring:message code="common.delete.msg" />")){
		// Delete하기 위한 키값을 셋팅
		document.articleForm.nttId.value = nttId;
		document.articleForm.action = "<c:url value='/cop/bbs/deleteGuestArticle.do'/>";
		document.articleForm.submit();
	}
}
 /* ********************************************************
  * 등록처리
  ******************************************************** */
 function fn_egov_insert_guest(form) {
		if (!validateArticleVO(form)){
			return;
		}
		if (confirm('<spring:message code="common.regist.msg" />')) {
			form.submit();
		}
	}
 /* ********************************************************
  * 수정처리
  ******************************************************** */
	function fn_egov_updt_guest(form) {
		if (!validateArticleVO(form)){
			return;
		}

		if (confirm('<spring:message code="common.update.msg" />')) {

			form.action = "<c:url value='/cop/bbs/updateGuestArticle.do'/>";
			form.submit();
		}
	}
/* ********************************************************
 * 수정전 처리
 ******************************************************** */
	function fn_egov_selectGuestForupdt(nttId) {
		document.articleForm.nttId.value = nttId;
		document.articleForm.action = "<c:url value='/cop/bbs/updateGuestArticleView.do'/>";
		document.articleForm.submit();
	}


/* ********************************************************
 * 페이징 처리
 ******************************************************** */
function fn_egov_select_guestList(pageNo) {
	document.articleForm.pageIndex.value = pageNo;
	document.articleForm.nttId.value = 0;
	document.articleForm.action = "<c:url value='/cop/bbs/selectGuestArticleList.do'/>";
	document.articleForm.submit();
}
</script>
<!-- 댓글 작성 스크립트  -->
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="articleVO" staticJavascript="false" xhtml="true" cdata="false"/>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<!-- javascript warning tag  -->
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
	<h1><c:out value="${boardMasterVO.bbsNm}"/></h1><!-- 게시판명 -->
	<c:if test="${not empty fn:trim(boardMasterVO.bbsIntrcn)}">
		<p class="page-desc"><c:out value="${boardMasterVO.bbsIntrcn}"/></p><!-- 게시판 소개내용 -->
	</c:if>
</div>

<%-- 방명록 리스트 출력 --%>
<form name="articleForm" action="<c:url value='/cop/bbs/updateGuestArticleView.do'/>" method="post">
	<ul class="bbs-guest-list">
		<c:forEach var="result" items="${resultList}" varStatus="status">
		<li class="bbs-guest-item">
			<div class="bbs-guest-top">
				<span class="bbs-guest-writer"><c:out value="${result.frstRegisterNm}" /></span>
				<span class="bbs-guest-date"><c:out value="${result.frstRegisterPnttm}" /></span>
			</div>
			<p class="bbs-guest-body"><c:out value="${fn:replace(result.nttCn , crlf , '<br/>')}" escapeXml="false" /></p>
			<c:if test="${result.frstRegisterId == sessionUniqId}">
			<div class="bbs-guest-actions">
				<a class="krds-btn medium" href="javascript:fn_egov_selectGuestForupdt(<c:out value="${result.nttId}"/>)" title="<spring:message code="button.update" /> <spring:message code="input.button" />"><spring:message code="button.update" /></a>
				<a class="krds-btn medium" href="javascript:fn_egov_delete_guest(<c:out value="${result.nttId}"/>)" title="<spring:message code="button.delete" /> <spring:message code="input.button" />"><spring:message code="button.delete" /></a>
			</div>
			</c:if>
		</li>
		</c:forEach>
		<c:if test="${fn:length(resultList) == 0}">
		<li class="bbs-guest-empty"><spring:message code="common.noguest.msg" /></li>
		</c:if>
	</ul>

	<div class="krds-pagination">
		<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_guestList"/>
	</div>

	<input name="pageIndex" type="hidden" value="<c:out value='${articleVO.pageIndex}'/>">
	<input name="nttId" type="hidden" value="">
	<input name="bbsId" type="hidden" value="<c:out value='${boardMasterVO.bbsId}'/>">
</form>

<%-- 방명록 입력폼 --%>
<c:set var="title"><spring:message code="comCopBbs.articleVO.regist.nttCn"/> </c:set>
<form:form modelAttribute="articleVO" action="${pageContext.request.contextPath}/cop/bbs/insertGuestArticle.do" method="post" onSubmit="fn_egov_insert_guest(document.forms[1]); return false; ">
	<div class="bbs-guest-write">
		<label class="form-label" for="nttCn">${title}<span class="pilsu">*</span></label>
		<form:textarea path="nttCn" title="${title} ${inputTxt}" cols="300" rows="6" cssClass="krds-input"/>
		<div><form:errors path="nttCn" cssClass="error" /></div>
		<c:choose>
			<c:when test="${articleVO.nttId == '0'}">
				<a href="javascript:fn_egov_insert_guest(document.forms[1]); " class="krds-btn primary medium" title="<spring:message code="button.comment" /> <spring:message code="input.button" />"><spring:message code="button.comment" /><spring:message code="button.create" /></a>
			</c:when>
			<c:otherwise>
				<a href="javascript:fn_egov_updt_guest(document.forms[1]); " class="krds-btn primary medium" title="<spring:message code="button.update" /> <spring:message code="input.button" />"><spring:message code="button.comment" /><spring:message code="button.update" /></a>
			</c:otherwise>
		</c:choose>
	</div>

	<input name="nttId" type="hidden" value="<c:out value='${articleVO.nttId}'/>">
	<input name="bbsId" type="hidden" value="<c:out value='${boardMasterVO.bbsId}'/>">
	<!-- validator 검증용 -->
	<input name="nttSj" type="hidden" value="guestbook"/>
</form:form>
</lay:layout>
