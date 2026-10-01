<%
 /**
  * @Class Name : EgovBBSMasterDetail.jsp
  * @Description : EgovBBSMasterDetail 화면
  * @Modification Information
  * @
  * @  수정일             수정자                   수정내용
  * @ -------    --------    ---------------------------
  * @ 2009.02.01   박정규              최초 생성
  *   2016.06.13   김연호              표준프레임워크 v3.6 개선
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
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<c:set var="pageTitle"><spring:message code="comCopBbs.boardMasterVO.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.detail" /></c:set>
<c:set var="pageHead">
<!-- 게시판 상세조회 -->
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<style>
.bbs-extra-field-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:10px; }
.bbs-extra-field-item { display:grid; grid-template-columns:88px minmax(0, 1fr); gap:6px 10px; padding:12px; border:1px solid #e1e5ee; border-radius:6px; background:#f8f9fb; }
.bbs-extra-field-item strong { color:#1f3974; font-size:13px; }
.bbs-extra-field-item span { color:#1d1d1d; word-break:break-word; }
.bbs-extra-field-item em { color:#52617a; font-size:12px; font-style:normal; }
@media (max-width:768px) {
	.bbs-extra-field-grid { grid-template-columns:1fr; }
	.bbs-extra-field-item { grid-template-columns:1fr; }
}
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<!-- javascript warning tag  -->
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<form name="BBSMasterForm" action="<c:url value='/cop/bbs/updateBBSMasterView.do'/>" method="post">
<div class="wTableFrm">
	<!-- 타이틀 -->
	<h2>${pageTitle} <spring:message code="title.detail" /></h2><!-- 게시판 상세조회 -->

	<!-- 상세조회 -->
	<table class="wTable" summary="<spring:message code="common.summary.inqire" arguments="${pageTitle}" />">
	<caption>${pageTitle} <spring:message code="title.detail" /></caption>
	<colgroup>
		<col style="width: ;">
		<col style="width: ;">
		<col style="width: ;">
		<col style="width: ;">
		<col style="width: ;">
		<col style="width: ;">
	</colgroup>
	<tbody>
		<!-- 게시판명 / 표시형태(템플릿) -->
		<tr>
			<th><spring:message code="comCopBbs.boardMasterVO.detail.bbsNm" /></th>
			<td colspan="3" class="left"><c:out value="${result.bbsNm}"/></td>
			<th>표시형태</th>
			<td class="left">
				<c:choose>
					<c:when test="${not empty result.tmplatNm}"><c:out value="${result.tmplatNm}"/></c:when>
					<c:otherwise>목록형(기본)</c:otherwise>
				</c:choose>
			</td>
		</tr>
		<!-- 등록자, 등록일, 사용여부 -->
		<tr>
			<th><spring:message code="table.reger" /></th>
			<td class="left"><c:out value="${result.frstRegisterNm}"/></td>
			<th><spring:message code="table.regdate" /></th>
			<td class="left"><c:out value="${result.frstRegisterPnttm}"/></td>
			<th><spring:message code="comCopBbs.boardMasterVO.detail.useAt" /></th>
			<td class="left"><c:out value="${result.useAt}"/></td>
		</tr>
		<!-- 답장가능여부, 파일첨부가능여부, 첨부가능파일숫자 -->
		<tr>
			<th><spring:message code="comCopBbs.boardMasterVO.detail.replyPosblAt" /></th>
			<td class="left"><c:out value="${result.replyPosblAt}"/></td>
			<th><spring:message code="comCopBbs.boardMasterVO.detail.fileAtchPosblAt" /></th>
			<td class="left"><c:out value="${result.fileAtchPosblAt}"/></td>
			<th><spring:message code="comCopBbs.boardMasterVO.detail.atchPosblFileNumber" /></th>
			<td class="left"><c:out value="${result.atchPosblFileNumber}"/></td>
		</tr>
		<!-- 표시·정책 설정 -->
		<tr>
			<th>페이지당 게시물 수</th>
			<td class="left"><c:choose><c:when test="${not empty fn:trim(result.listPageUnit)}"><c:out value="${result.listPageUnit}"/></c:when><c:otherwise>기본값(전역)</c:otherwise></c:choose></td>
			<th>페이징 사용</th>
			<td class="left"><c:out value="${result.pagingAt}"/></td>
			<th>목록 검색창</th>
			<td class="left"><c:out value="${result.searchBoxAt}"/></td>
		</tr>
		<tr>
			<th>비밀글 허용</th>
			<td class="left"><c:out value="${result.secretPosblAt}"/></td>
			<th>에디터(서식) 사용</th>
			<td class="left"><c:out value="${result.richEditorAt}"/></td>
			<th>통합검색 노출</th>
			<td class="left"><c:out value="${result.searchIncldAt}"/></td>
		</tr>
		<tr>
			<th>첨부 파일 최대 용량</th>
			<td colspan="5" class="left"><c:choose><c:when test="${not empty fn:trim(result.atchPosblFileSize)}"><c:out value="${result.atchPosblFileSize}"/> MB</c:when><c:otherwise>시스템 기본값</c:otherwise></c:choose></td>
		</tr>
		<!-- 게시판 소개내용 -->
		<tr>
			<th><spring:message code="comCopBbs.boardMasterVO.detail.bbsIntrcn" /></th>
			<td colspan="5" class="cnt">
				<c:out value="${fn:replace(result.bbsIntrcn , crlf , '<br/>')}" escapeXml="false" />
			</td>
		</tr>
		<tr>
			<th>여분필드</th>
			<td colspan="5" class="left">
				<div class="bbs-extra-field-grid bbs-extra-field-grid-view">
					<c:forEach begin="1" end="10" var="i">
						<c:set var="fieldLabel" value="${result.getBbsExtraField(i)}"/>
						<c:set var="fieldType" value="${result.getBbsExtraFieldType(i)}"/>
						<c:set var="fieldCodeId" value="${result.getBbsExtraFieldCodeId(i)}"/>
						<c:if test="${not empty fieldLabel}">
							<div class="bbs-extra-field-item">
								<strong>&#50668;&#48516;&#54596;&#46300; ${i}</strong>
								<span><c:out value="${fieldLabel}"/></span>
								<em>&#51077;&#47141;&#53440;&#51077;</em>
								<span><c:out value="${fieldType}"/></span>
								<em>&#44277;&#53685;&#53076;&#46300;</em>
								<span><c:out value="${fieldCodeId}"/></span>
							</div>
						</c:if>
					</c:forEach>
				</div>
				<p style="margin:10px 0 0;color:#52617a;font-size:12px;line-height:1.6;">&#8505; <strong>여분필드 1</strong>에 공통코드를 지정하면 <strong>탭분류형·자료실형</strong> 게시판에서 그 값이 <strong>무조건 분류(카테고리) 기준</strong>으로 쓰입니다. (탭분류형은 이 값으로 상단 탭을 나눠 탭별로 페이지를 매겨 표시합니다.)</p>
			</td>
		</tr>
		
		<c:if test="${result.useAt == 'Y' }">
			<tr>
				<th><spring:message code="comCopBbs.boardMasterVO.detail.bbsAdres" /></th>
				<td colspan="5" class="cnt">
				<a href="<c:url value='/cop/bbs/selectArticleList.do?bbsId=${result.bbsId}' />">/cop/bbs/selectArticleList.do?bbsId=${result.bbsId }</a>	
				</td>
			</tr>
		</c:if>
		<tr>
			<th><spring:message code="comCopBbs.boardMasterVO.detail.option" /></th><!-- 추가선택사항 -->
			<td colspan="5" class="cnt">
				<%-- 댓글(ANSWER_AT)·만족도(STSFDG_AT)는 독립 플래그라 동시에 켤 수 있다.
				     레거시 option(단일선택)만 보면 둘 다 켠 보드에서 '댓글'이 사라져 보인다. --%>
				<c:set var="optLabels" value=""/>
				<c:if test="${result.commentAt == 'Y'}"><c:set var="optLabels"><spring:message code="comCopBbs.boardMasterVO.detail.option2" /></c:set></c:if>
				<c:if test="${result.stsfdgAt == 'Y'}"><c:set var="optLabels">${optLabels}<c:if test="${not empty optLabels}">, </c:if><spring:message code="comCopBbs.boardMasterVO.detail.option3" /></c:set></c:if>
				<%-- c:choose 의 자식으로는 c:when/c:otherwise 만 올 수 있다.
				     HTML 주석은 "텍스트"라 JstlCoreTLV 가 JSP 번역단계에서 거부한다(미선택 = option1). --%>
				<c:choose>
					<c:when test="${empty optLabels}"><spring:message code="comCopBbs.boardMasterVO.detail.option1" /></c:when>
					<c:otherwise><c:out value="${optLabels}"/></c:otherwise>
				</c:choose>
			</td>
		</tr>
		<tr>
			<th>작성 권한</th>
			<td colspan="5" class="cnt">
				<c:choose>
					<c:when test="${empty result.writeAuthorCodes}">
						관리자만 작성
					</c:when>
					<c:otherwise>
						<c:forEach items="${result.writeAuthorCodes}" var="code" varStatus="st"><c:if test="${not st.first}">, </c:if><c:choose><c:when test="${not empty menuRoleLabels[code]}"><c:out value="${menuRoleLabels[code]}"/></c:when><c:otherwise><c:out value="${code}"/></c:otherwise></c:choose></c:forEach>
					</c:otherwise>
				</c:choose>
			</td>
		</tr>
		<tr>
			<th>사용자 메뉴</th>
			<td colspan="5" class="cnt">
				<c:choose>
					<c:when test="${empty boardMenu}">
						비노출 (관리자만 접근)
					</c:when>
					<c:otherwise>
						<c:out value="${boardMenu.menuNm}"/> (메뉴번호 <c:out value="${boardMenu.menuNo}"/>, 순서 <c:out value="${boardMenu.menuOrdr}"/>)
						<br>열람 권한:
						<c:forEach items="${boardMenu.authorCodes}" var="code" varStatus="st"><c:if test="${not st.first}">, </c:if><c:choose><c:when test="${not empty menuRoleLabels[code]}"><c:out value="${menuRoleLabels[code]}"/></c:when><c:otherwise><c:out value="${code}"/></c:otherwise></c:choose></c:forEach>
					</c:otherwise>
				</c:choose>
			</td>
		</tr>
	</tbody>
	</table>
	<!-- 하단 버튼 -->
	<div class="btn">
		<input type="submit" class="s_submit" value="<spring:message code="button.update" />" title="<spring:message code="title.update" /> <spring:message code="input.button" />" /><!-- 수정 -->
		<span class="btn_s"><a href="<c:url value='/cop/bbs/selectBBSMasterInfs.do' /><c:if test='${result.cmmntyId != null}'>?cmmntyId=${result.cmmntyId}</c:if>"  title="<spring:message code="title.list" /> <spring:message code="input.button" />"><spring:message code="button.list" /></a></span><!-- 목록 -->
	</div><div style="clear:both;"></div>
	
</div>

<input name="cmmntyId" type="hidden" value="<c:out value="${result.cmmntyId}" />">
<input name="bbsId" type="hidden" value="<c:out value="${result.bbsId}" />">
<input name="cmd" type="hidden" value="">
</form>
</lay:layout>
