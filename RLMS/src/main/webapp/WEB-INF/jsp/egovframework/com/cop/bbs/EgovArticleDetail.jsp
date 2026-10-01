<%
 /**
  * @Class Name : EgovArticleDetail.jsp
  * @Description : 게시글 상세조회 — 공용 상세 엔진(LIST/GALLERY/FAQ/QNA 공유). KRDS 표준 디자인.
  * @Modification Information
  * @
  * @  수정일             수정자                   수정내용
  * @ -------    --------    ---------------------------
  * @ 2009.02.01   박정규              최초 생성
  *   2016.06.13   김연호              표준프레임워크 v3.6 개선
  *   2024.10.29	LeeBaekHaeng	게시판 검색조건 유지
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
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
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
<!-- 게시글 상세조회 -->
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
/* ********************************************************
 * 삭제처리
 ******************************************************** */
 function fn_egov_delete_article(form){
	if(confirm("<spring:message code="common.delete.msg" />")){
		// Delete하기 위한 키값을 셋팅
		form.submit();
	}
}

/* ********************************************************
 * 답글작성
 ******************************************************** */
 function fn_egov_reply_article() {
		document.articleForm.action = "<c:url value='/cop/bbs/replyArticleView.do'/>";
		document.articleForm.submit();
	}

</script>
<%-- 댓글·만족도는 각 조각(cmt/stf)이 JSON/AJAX 로 자체 처리 — 부모의 폼 스크립트/validator/head import 불요(2026-07-10). --%>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<!-- javascript warning tag  -->
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
	<h2>${pageTitle} <spring:message code="title.detail" /></h2><!-- 게시글 상세조회 -->
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
		<%-- 여분필드는 필드마다 자기 라벨(게시판속성에서 정한 이름)을 <th> 로 하는 개별 행으로 낸다.
		     일반어 "확장필드" 헤더로 뭉치지 않고 제목·내용 등 다른 행과 동일한 구조를 쓴다. --%>
		<c:forEach begin="1" end="10" var="i">
			<c:set var="fieldLabel" value="${boardMasterVO.getBbsExtraField(i)}" />
			<c:if test="${not empty fieldLabel}">
				<c:set var="fieldValue" value="${result.getNttExtraField(i)}" />
				<c:set var="displayValue" value="${fieldValue}" />
				<c:set var="fieldOptions" value="${bbsExtraCodeOptions[i]}" />
				<%-- 코드형(radio/select/checkbox) 값은 코드→코드명 변환. checkbox 는 쉼표 다중값이라
				     토큰마다 바꿔 다시 잇는다(단일값도 토큰 1개라 같은 경로).
				     조립은 c:set 본문에 원문으로 담고, 출력에서 c:out 이 한 번만 이스케이프한다. --%>
				<c:if test="${not empty fieldOptions and not empty fieldValue}">
					<c:set var="displayValue"><c:forTokens items="${fieldValue}" delims="," var="token" varStatus="tk"><c:if test="${not tk.first}">, </c:if><c:set var="tokenNm" value="${token}" /><c:forEach var="code" items="${fieldOptions}"><c:if test="${token == code.code}"><c:set var="tokenNm" value="${code.codeNm}" /></c:if></c:forEach>${tokenNm}</c:forTokens></c:set>
				</c:if>
				<tr>
					<th scope="row"><c:out value="${fieldLabel}" /></th>
					<td colspan="5" class="al"><c:out value="${displayValue}" /></td>
				</tr>
			</c:if>
		</c:forEach>
		<%-- 게시기간 — 실제 기간이 설정된 글에만 표시한다.
		     빈 값이거나 무의미 sentinel(1900-01-01~9999-12-31, 과거 자동입력분)이면 행 자체를 감춘다.
		     CHAR(20) 공백패딩 대비 fn:trim 후 비교. --%>
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
		<!-- 첨부파일  -->
		<c:if test="${not empty result.atchFileId}">
		<tr>
			<th scope="row"><spring:message code="comCopBbs.articleVO.detail.atchFile" /></th>
			<td colspan="5">
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
	<%-- 관리 동선은 항상. 사용자 동선은 작성권한(bbsCanWrite) + 본인 글일 때만 수정/삭제를 보인다.
	     화면 게이팅일 뿐이고 실제 차단은 서버(BoardWriteGuard · assertOwnerInUserMode)가 한다. --%>
	<c:set var="bbsUserCanEdit" value="${bbsCanWrite and not empty sessionUniqId and result.frstRegisterId == sessionUniqId}" />
	<%-- 삭제(톰스톤, USE_AT='N') 글은 수정/삭제/답글 동선 자체를 감춘다 — 서버 가드와 쌍 --%>
	<c:if test="${result.useAt eq 'Y' and result.ntcrId != 'anonymous' and (empty bbsUserMode or bbsUserCanEdit)}">
	<!-- 익명글 수정/삭제 불가  -->
	<form name="articleForm" action="<c:url value='${bbsUrlBase}/updateArticleView.do'/>" method="get" style="display:inline;">
		<input type="submit" class="krds-btn primary medium" value="<spring:message code="button.update" />" title="<spring:message code="title.update" /> <spring:message code="input.button" />" /><!-- 수정 -->
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
		<input type="submit" class="krds-btn danger medium" value="<spring:message code="button.delete" />" title="<spring:message code="button.delete" /> <spring:message code="input.button" />" onclick="fn_egov_delete_article(this.form); return false;"><!-- 삭제 -->
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	</c:if>
	<c:if test="${result.useAt eq 'Y' and boardMasterVO.replyPosblAt == 'Y' and (empty bbsUserMode or bbsCanWrite)}">
	<form name="formReply" action="<c:url value='${bbsUrlBase}/replyArticleView.do'/>" method="post" style="display:inline;">
		<input type="submit" class="krds-btn secondary medium" value="<spring:message code="button.reply" />"><!-- 답글 -->
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
	</form>
	</c:if>
	<%-- 삭제글이면 관리자에게 '수정 / 복구' 진입만 노출 — 삭제/답글은 감춤 --%>
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
		<input type="submit" class="krds-btn secondary medium" value="<spring:message code="button.list" />"><!-- 목록 -->
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	<%-- 스크랩(cop/scp) 버튼 제거 — scp 모듈은 미사용 소스 정리 때 삭제되어 404 를 내던 죽은 버튼. --%>

</div>

<!-- 댓글 -->
<%-- 서버측 include — Spring Security 필터는 REQUEST 만 타므로 조각 자체는 인가검사를 거치지 않는다.
     쓰기(insert/update/delete)만 실제 요청이라 URL 보안(사용자=/cop/cmt/user/*)이 적용된다. --%>
<c:if test="${useComment == 'true'}">
	<%-- ⛔ c:param 을 붙이지 말 것.
	     include 는 쿼리 파라미터를 원 요청 파라미터에 "덧붙여" 전달하므로(서블릿 스펙 aggregation),
	     nttId·bbsId 처럼 원 요청에 이미 있는 값을 다시 넘기면 getParameterValues 가 길이 2 배열이 되고
	     CommentVO 바인딩이 BindException 으로 터진다(상세화면 500). 네 값 모두 원 요청에서 상속된다.
	     type=body 는 컨트롤러가 모델에 넣어준다. (c:import 의 자식은 c:param 만 허용 — c:if 도 금지) --%>
	<c:import url="${cmtUrlBase}/selectArticleCommentList.do" charEncoding="utf-8"/>
</c:if>

<c:if test="${useSatisfaction == 'true'}">
	<%-- 만족도 조각도 JSON/AJAX 자체 처리. bbsId·nttId 는 원 요청에서 상속, type=body 만 넘긴다
	     (type 은 원 요청에 없어 include 파라미터 aggregation 문제 없음). --%>
	<c:import url="${stfUrlBase}/selectSatisfactionList.do" charEncoding="utf-8">
		<c:param name="type" value="body" />
	</c:import>
</c:if>
</lay:layout>
