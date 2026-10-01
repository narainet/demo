<%
 /**
  * @Class Name : EgovArticleReply.jsp
  * @Description : EgovArticleReply 화면
  * @Modification Information
  * @
  * @ 수정일               수정자            수정내용
  
  *   2009.02.01   박정규            최초 생성
  *   2016.06.13   김연호            표준프레임워크 v3.6 개선
  *   2020.10.27   신용호            파일 업로드 수정
  *
  *  @author 공통서비스팀 
  *  @since 2009.02.01
  *  @version 1.0
  *  @see
  *  
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 첨부 업로더 제한값 — 태그파일 셸 도입(2026-08-07)으로 본문이 scriptless 가 되어
     인라인 스크립틀릿을 못 쓴다. 지시부 뒤에서 한 번 꺼내 EL 로 참조한다. --%>
<c:set var="fileMaxSize"><%= egovframework.com.cmm.service.EgovProperties.getProperty("Globals.fileUpload.maxSize") %></c:set>
<c:set var="fileExtensions"><%= egovframework.com.cmm.service.EgovProperties.getProperty("Globals.fileUpload.Extensions") %></c:set>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<c:set var="pageTitle"><spring:message code="comCopBbs.articleVO.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.create" /></c:set>
<c:set var="pageHead">
<!-- 게시글 답글 등록-->
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/cmm/jqueryui.css' />">
<script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/fms/EgovFileDropzone.js'/>" ></script>
<script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/utl/EgovCmmUtl.js'/>" ></script>
<script type="text/javascript" src="<c:url value='/html/egovframework/com/cmm/utl/ckeditor/ckeditor.js'/>" ></script>
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<script src="<c:url value='/js/egovframework/com/cmm/jqueryui.js' />"></script>
<validator:javascript formName="articleVO" staticJavascript="false" xhtml="true" cdata="false"/>
<script type="text/javascript">

/* ********************************************************
 * 초기화
 ******************************************************** */
function fn_egov_init(){

	// CKEditor 부착 — 등록/수정화면과 동일 설정(이미지 업로드 JSON 계약).
	// 기존 서버측 ckeditor:replace 태그립은 업로드 URL 을 실을 수 없어 이미지 첨부가 불가했다.
	var ckeditor_config = {
		filebrowserImageUploadUrl: '${pageContext.request.contextPath}/ckUploadImage?responseType=json',
		filebrowserUploadMethod: 'xhr'
	};
	CKEDITOR.replace('nttCn', ckeditor_config);

	// 첫 입력란에 포커스
	document.getElementById("articleVO").nttSj.focus();

}
/* ********************************************************
 * 답글저장처리화면
 ******************************************************** */
function fn_egov_reply_article(form){
	
	CKEDITOR.instances.nttCn.updateElement();
	
	//input item Client-Side validate
	if (!validateArticleVO(form)) {	
		return false;
	} else {
		
		var validateForm = document.getElementById("articleVO");
		
		
		//익명글은 공지게시 불가.
		if(validateForm.anonymousAt.checked) {
			if(validateForm.noticeAt.checked) {
				alert("<spring:message code="comCopBbs.articleVO.anonymousNotice" />");
				return;
			}
		}
		
		//게시기간 
		// 게시기간 — 선택입력. 안 넣으면 빈 값으로 저장(과거 sentinel 1900~9999 자동입력 폐기).
		var ntceBgnde = getRemoveFormat(validateForm.ntceBgnde.value);
		var ntceEndde = getRemoveFormat(validateForm.ntceEndde.value);

		// 둘 다 입력했을 때만 시작<=종료 검사.
		if(ntceBgnde != '' && ntceEndde != '' && ntceBgnde > ntceEndde){
			alert("<spring:message code="comCopBbs.articleVO.ntceDeError" />");
			return;
		}
		
		
		
		
		if(confirm("<spring:message code="common.regist.msg" />")){	
			form.submit();	
		}
	} 
}

<c:if test="${!empty resultMsg}">
alert("<spring:message code="${resultMsg}" />");
location.href = "<c:url value='${bbsUrlBase}/selectArticleList.do' />?bbsId=${boardMasterVO.bbsId}";
</c:if>
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init();">
<!-- javascript warning tag  -->
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<form:form modelAttribute="articleVO" action="${pageContext.request.contextPath}${bbsUrlBase}/replyArticle.do" method="post" onSubmit="fn_egov_reply_article(document.forms[0]); return false;" enctype="multipart/form-data"> 
<div class="wTableFrm">
	<!-- 타이틀 -->
	<h2>${pageTitle} <spring:message code="title.create" /></h2><!-- 게시글 답글 등록-->

	<!-- 등록폼 -->
	<table class="wTable" summary="<spring:message code="common.summary.list" arguments="${pageTitle}" />">
	<caption>${pageTitle } <spring:message code="title.create" /></caption>
	<colgroup>
		<col style="width: 20%;">
		<col style="width: ;">
		<col style="width: ;">
		<col style="width: ;">
	</colgroup>
	<tbody>
		<!-- 입력 -->
		<c:set var="inputTxt"><spring:message code="input.input" /></c:set>
		<!-- 글 제목, 제목 Bold여부   -->
		<c:set var="title"><spring:message code="comCopBbs.articleVO.reply.nttSj"/> </c:set>
		<tr>
			<th><label for="nttSj">${title} <span class="pilsu">*</span></label></th>
			<td class="left">
			    <input name="nttSj" type="text" size="70" maxlength="70" title="${title} ${inputTxt}" value="RE: <c:out value='${result.nttSj}'/>">
   				<div><form:errors path="nttSj" cssClass="error" /></div>     
			</td>
			<c:set var="title"><spring:message code="comCopBbs.articleVO.reply.sjBoldAt"/> </c:set>
			<th><label for="sjBoldAt">${title}</label></th>
			<td class="left">
			    <form:checkbox path="sjBoldAt" value="Y"/>
   				<div><form:errors path="sjBoldAt" cssClass="error" /></div>     
			</td>
		</tr>
		<!-- 글 내용  -->
		<c:set var="title"><spring:message code="comCopBbs.articleVO.reply.nttCn"/> </c:set>
		<tr>
			<th><label for="nttCn">${title } <span class="pilsu">*</span></label></th>
			<td class="nopd" colspan="3">
				<form:textarea path="nttCn" title="${title} ${inputTxt}" cols="300" rows="20" />
				<%-- CKEditor 부착은 fn_egov_init 의 CKEDITOR.replace 로 이동(이미지 업로드 URL 주입 목적). --%>
				<div><form:errors path="nttCn" cssClass="error" /></div>
			</td>
		</tr>
		
		<!-- 공지신청 여부  -->
		<c:set var="title"><spring:message code="comCopBbs.articleVO.reply.noticeAt"/> </c:set>
		<tr>
			<th><label for="noticeAt">${title}</label></th>
			<td class="left" colspan="3">
				<form:checkbox path="noticeAt" value="Y"/>
				<div><form:errors path="noticeAt" cssClass="error" /></div>       
			</td>
		</tr>
		
		<!-- 익명등록 여부  -->
		<c:set var="title"><spring:message code="comCopBbs.articleVO.reply.anonymousAt"/> </c:set>
		<tr>
			<th><label for="anonymousAt">${title}</label></th>
			<td class="left" colspan="3">
				<form:checkbox path="anonymousAt" value="Y"/>
				<div><form:errors path="anonymousAt" cssClass="error" /></div>       
			</td>
		</tr>
		
		<!-- 유효기간 설정  -->
		<c:set var="title"><spring:message code="comCopBbs.articleVO.reply.ntceDe"/> </c:set>
		<tr>
			<th><label for="ntceBgnde">${title} </label></th>
			<td class="left" colspan="3">
				<form:input path="ntceBgnde" type="date" title="${title} ${inputTxt}" />
				&nbsp;~&nbsp;<form:input path="ntceEndde" type="date" title="${title} ${inputTxt}" />
				<div><form:errors path="ntceBgnde" cssClass="error" /></div>
				<div><form:errors path="ntceEndde" cssClass="error" /></div>
				<%-- 캘린더형 게시판만 — 게시기간이 달력 배치일이 된다(목록 화면과 동일 규칙 안내). --%>
				<c:if test="${boardMasterVO.tmplatSeCode == 'CALENDAR' or (empty boardMasterVO.tmplatSeCode and boardMasterVO.bbsSkinCode == 'CALENDAR')}">
				<p class="bbs-cal-help">
					<span class="bbs-cal-help-ico" aria-hidden="true">&#128197;</span>
					<span><strong>표시 규칙</strong> — 게시기간의 <strong>시작일만</strong> 지정하면 그 날에만, <strong>시작일·종료일</strong>을 다르게 지정하면 그 기간에 걸쳐 표시됩니다. 게시기간을 <strong>입력하지 않으면</strong> 등록일에 표시됩니다.</span>
				</p>
				</c:if>
				<%-- 연혁형 게시판만 — 게시기간 시작일이 연혁 시점(연도·월)이 된다. --%>
				<c:if test="${boardMasterVO.tmplatSeCode == 'HISTORY' or (empty boardMasterVO.tmplatSeCode and boardMasterVO.bbsSkinCode == 'HISTORY')}">
				<p class="bbs-cal-help">
					<span class="bbs-cal-help-ico" aria-hidden="true">&#128220;</span>
					<span><strong>연혁 날짜</strong> — 게시기간의 <strong>시작일</strong>이 이 글의 연혁 시점(연도·월)으로 표시됩니다. <strong>종료일</strong>을 함께 지정하면 기간(시작~종료)으로 표시되고, <strong>입력하지 않으면</strong> 등록일 기준으로 표시됩니다.</span>
				</p>
				</c:if>
				<%-- 자료실형 게시판만 — 게시기간이 노출 기간이 된다. --%>
				<c:if test="${boardMasterVO.tmplatSeCode == 'ARCHIVE' or (empty boardMasterVO.tmplatSeCode and boardMasterVO.bbsSkinCode == 'ARCHIVE')}">
				<p class="bbs-cal-help">
					<span class="bbs-cal-help-ico" aria-hidden="true">&#128193;</span>
					<span><strong>노출 기간</strong> — 게시기간을 지정하면 <strong>그 기간에만</strong> 자료가 노출됩니다(시작일 전·종료일 후에는 사용자 화면에서 숨겨집니다). 게시기간을 <strong>입력하지 않으면</strong> 기간 제한 없이 항상 노출됩니다.</span>
				</p>
				</c:if>
			</td>
		</tr>
		
		<c:if test="${boardMasterVO.fileAtchPosblAt == 'Y'}">
		<!-- 첨부파일  -->
		<c:set var="title"><spring:message code="comCopBbs.articleVO.regist.atchFile"/></c:set><!-- 첨부파일 -->
		<tr>
			<th><label for="egovComFileUploader">${title}</label> </th>
			<td class="nopd" colspan="3">
				<%-- 드롭존 클래스는 KRDS 표준 .file-upload 가 아니라 .ide-file-drop —
				     krds.min.js 의 krds_fileUpload.init() 이 버튼 없는 .file-upload 에서
				     null.addEventListener 콘솔에러를 내므로 분리(스타일=rlms-compat). --%>
				<div class="krds-file-upload">
					<div class="ide-file-drop" id="bbsFileDrop">
						<input type="file" id="egovComFileUploader" name="file_1" class="ide-file-native" title="${title}" multiple />
						<span class="txt">파일을 여기로 끌어다 놓거나 <strong>파일 선택</strong></span>
					</div>
					<div class="file-list">
						<div class="total" id="bbsFileTotal" style="display:none;">총 <span class="current">0</span>개</div>
						<ul id="bbsFileSelList" class="upload-list"></ul>
					</div>
					<div id="bbsFileNotice" class="ide-file-notice" style="display:none;"></div>
				</div>
			</td>
		</tr>
	  	</c:if>
		
	</tbody>
	</table>

	<!-- 하단 버튼 -->
	<div class="btn">
		<input type="submit" class="s_submit" value="<spring:message code="button.create" />" title="<spring:message code="button.create" /> <spring:message code="input.button" />" /><!-- 등록 -->
		<span class="btn_s"><a href="<c:url value='${bbsUrlBase}/selectArticleList.do' />?bbsId=${boardMasterVO.bbsId}"  title="<spring:message code="button.list" />  <spring:message code="input.button" />"><spring:message code="button.list" /></a></span><!-- 목록 -->
	</div><div style="clear:both;"></div>
	
</div>

<input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>"/>
<input type="hidden" name="bbsTyCode" value="<c:out value='${boardMasterVO.bbsTyCode}'/>" />
<input type="hidden" name="replyPosblAt" value="<c:out value='${boardMasterVO.replyPosblAt}'/>" />
<input type="hidden" name="fileAtchPosblAt" value="<c:out value='${boardMasterVO.fileAtchPosblAt}'/>" />
<input type="hidden" id="atchPosblFileNumber" name="atchPosblFileNumber" value="<c:out value='${boardMasterVO.atchPosblFileNumber}'/>" />
<input type="hidden" name="atchPosblFileSize" value="<c:out value='${boardMasterVO.atchPosblFileSize}'/>" />
<input type="hidden" name="tmplatId" value="<c:out value='${boardMasterVO.tmplatId}'/>" />

<input type="hidden" name="parnts" value="<c:out value='${result.parnts}'/>" />
<input type="hidden" name="sortOrdr" value="<c:out value='${result.sortOrdr}'/>" />
<input type="hidden" name="replyLc" value="<c:out value='${result.replyLc}'/>" />

<input name="nttId" type="hidden" value="${result.nttId}">
<input name="bbsId" type="hidden" value="${boardMasterVO.bbsId}">
<input name="cmd" type="hidden" value="<c:out value='save'/>">
</form:form>

<!-- 첨부파일 드롭존 초기화 (첨부불가 게시판이면 대상 부재로 무동작 — 기존 무가드 null 오류 소멸) -->
<script type="text/javascript">
EgovFileDropzone.init({
	input: 'egovComFileUploader', drop: 'bbsFileDrop',
	list: 'bbsFileSelList', total: 'bbsFileTotal', notice: 'bbsFileNotice',
	maxCount: parseInt(document.getElementById('atchPosblFileNumber').value, 10) || 3,
	maxSize: parseInt('${fileMaxSize}', 10) || 0,
	extensions: '${fileExtensions}'
});
</script>

<script>
// <input type="date"> 는 yyyy-MM-dd 만 허용한다. NTCE_BGNDE/NTCE_ENDDE 는 CHAR(20) 이라
// 공백 패딩이 붙어 오고, 그 값은 브라우저가 거부해 el.value 가 빈 문자열이 된다(속성은 남아 있다).
// → 속성에서 원문을 읽어 trim 후 ISO 형식일 때만 되돌려 넣는다. (promEditor.jsp ideSafeIsoDate 와 동일 취지)
(function(){
	var els = document.querySelectorAll('input[type="date"]');
	for (var i = 0; i < els.length; i++) {
		var raw = (els[i].getAttribute('value') || '').trim();
		els[i].value = /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : '';
	}
})();
</script>
</lay:layout>
