<%
	/**
	 * @Class Name : EgovArticleUpdt.jsp
	 * @Description : EgovArticleUpdt 화면
	 */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator"%>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 첨부 업로더 제한값 — 태그파일 셸 도입(2026-08-07)으로 본문이 scriptless 가 되어
     인라인 스크립틀릿을 못 쓴다. 지시부 뒤에서 한 번 꺼내 EL 로 참조한다. --%>
<c:set var="fileMaxSize"><%= egovframework.com.cmm.service.EgovProperties.getProperty("Globals.fileUpload.maxSize") %></c:set>
<c:set var="fileExtensions"><%= egovframework.com.cmm.service.EgovProperties.getProperty("Globals.fileUpload.Extensions") %></c:set>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<c:set var="pageTitle"><spring:message code="comCopBbs.articleVO.title" /></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.update" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/cmm/jqueryui.css' />">
<script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/fms/EgovFileDropzone.js'/>" ></script>
<script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/utl/EgovCmmUtl.js'/>" ></script>
<script type="text/javascript" src="<c:url value='/html/egovframework/com/cmm/utl/ckeditor/ckeditor.js?t=B37D54V'/>" ></script>
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<script src="<c:url value='/js/egovframework/com/cmm/jqueryui.js' />"></script>
<validator:javascript formName="articleVO" staticJavascript="false" xhtml="true" cdata="false" />
<style>
.article-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
.article-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.article-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
.article-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.article-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #e8edf9; color: #1f3974; font-size: 13px; font-weight: 700; }
.article-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 620px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
.article-ide-main { min-height: 620px; border-right: 1px solid #d1d3d8; }
.article-ide-main .ide-context-pane { padding: 24px; }
.article-ide-main .ide-prov-head { align-items: center; flex-wrap: wrap; }
.article-ide-main .ide-prov-head h2 { font-size: 21px; }
.article-ide-main .ide-form-row { margin-bottom: 18px; }
.article-ide-main .krds-input.small { width: 100%; max-width: 100%; box-sizing: border-box; }
.article-ide-main textarea.krds-input { min-height: 260px; }
.article-ide-main .ide-form-actions { margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
.article-ide-main .form-hint-invalid { color: #d4351c; }
.article-option-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
.article-date-group { display: flex; align-items: center; gap: 8px; max-width: 340px; }
.article-date-group .krds-input { text-align: center; }
.article-check-line { display: flex; align-items: center; gap: 8px; min-height: 40px; color: #1d1d1d; font-size: 14px; }
.article-check-line input[type="checkbox"] { appearance: auto !important; -webkit-appearance: checkbox !important; display: inline-block !important; position: static !important; visibility: visible !important; opacity: 1 !important; width: 16px !important; height: 16px !important; min-width: 16px !important; margin: 0 !important; padding: 0 !important; border: 1px solid #555 !important; background: #fff !important; vertical-align: middle !important; }
.bbs-extra-choice-group { display: flex; flex-wrap: wrap; gap: 8px 16px; min-height: 40px; align-items: center; }
.bbs-extra-choice-group input[type="radio"] { appearance: auto !important; -webkit-appearance: radio !important; display: inline-block !important; position: static !important; visibility: visible !important; opacity: 1 !important; width: 16px !important; height: 16px !important; min-width: 16px !important; margin: 0 !important; padding: 0 !important; }
.article-ide-right { min-height: 620px; }
.article-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.article-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.article-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
.article-file-current { padding: 12px; border-radius: 6px; background: #fff; color: #1d1d1d; }
/* 남색 사이드바 위 드롭존 — rlms-compat 텍스트색(밝은 배경 기준: #555/#1f3974/#6b7280)이 묻힘 → 4클래스 특이도로 재역전 */
.article-side-block .krds-file-upload .ide-file-drop .txt { color: rgba(255,255,255,0.78); }
.article-side-block .krds-file-upload .ide-file-drop .txt strong { color: #fff; text-decoration: underline; }
.article-side-block .krds-file-upload .file-list .total { color: rgba(255,255,255,0.78); }
.article-side-block .krds-file-upload .file-list .total .current { color: #9ec1ff; }
.article-side-block .krds-file-upload .ide-file-notice { color: #ffb4a8; }
.article-file-current table { width: 100%; }
.required-mark { color: #d4351c; font-weight: 700; }
@media (max-width: 1024px) {
  .article-ide-shell { grid-template-columns: 1fr; }
  .article-ide-main { border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .article-ide-right { min-height: 0; }
}
@media (max-width: 768px) {
  .article-ide-head { align-items: flex-start; flex-direction: column; }
  .article-ide-state { align-self: flex-start; }
  .article-ide-main .ide-context-pane { padding: 18px; }
  .article-ide-main .ide-form-actions { justify-content: flex-start; flex-wrap: wrap; }
  .article-option-grid { grid-template-columns: 1fr; gap: 0; }
  .article-date-group { max-width: 100%; }
}
.bbs-restore-notice { margin: 0 0 12px; padding: 11px 14px; border: 1px solid #f3c1bb; border-radius: 5px; background: #fdf1ef; color: #a3271a; font-size: 13px; line-height: 1.5; }
</style>
<script type="text/javascript">
function fn_egov_init() {
	// 등록화면과 동일 설정으로 통일. 기존 /utl/wed/insertImageCk.do 는 ADMIN 전용 catch-all 에 걸리고
	// 응답이 SiteMesh 로 장식되던 결함 경로라 폐기 → 개방·비장식·검증된 /ckUploadImage 로 수렴.
	var ckeditor_config = {
		filebrowserImageUploadUrl: '${pageContext.request.contextPath}/ckUploadImage?responseType=json',
		filebrowserUploadMethod: 'xhr'
	};

	// 게시판 속성(RICH_EDITOR_AT='N')이면 CKEditor 미적용 — 일반 텍스트 입력으로.
	if ("${boardMasterVO.richEditorAt}" != "N") {
		CKEDITOR.replace('nttCn', ckeditor_config);
	}
	document.getElementById("articleVO").nttSj.focus();
}

function fn_egov_updt_article(form) {
	if (typeof CKEDITOR !== 'undefined' && CKEDITOR.instances.nttCn) {
		CKEDITOR.instances.nttCn.updateElement();
	}

	if (!validateArticleVO(form)) {
		return false;
	}

	var validateForm = document.getElementById("articleVO");

	// 비밀글 미허용(SECRET_POSBL_AT='N') 게시판은 secretAt 컨트롤이 없으므로 널가드.
	if (validateForm.secretAt && validateForm.secretAt.checked) {
		if (validateForm.sjBoldAt.checked) {
			alert("<spring:message code='comCopBbs.articleVO.secretBold' />");
			return false;
		}
		if (validateForm.noticeAt.checked) {
			alert("<spring:message code='comCopBbs.articleVO.secretNotice' />");
			return false;
		}
	}

	// 게시기간 — 선택입력. 안 넣으면 빈 값으로 저장(과거 sentinel 1900~9999 자동입력 폐기).
	var ntceBgnde = getRemoveFormat(validateForm.ntceBgnde.value);
	var ntceEndde = getRemoveFormat(validateForm.ntceEndde.value);

	// 둘 다 입력했을 때만 시작<=종료 검사.
	if (ntceBgnde != '' && ntceEndde != '' && ntceBgnde > ntceEndde) {
		alert("<spring:message code='comCopBbs.articleVO.ntceDeError' />");
		return false;
	}

	if (confirm("<spring:message code='common.update.msg' />")) {
		form.submit();
	}
	return false;
}

function fn_egov_inqire_articlelist() {
	articleVO.action = "<c:url value='${bbsUrlBase}/selectArticleList.do'/>";
	articleVO.submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init();">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="article-ide-page">
	<div class="article-ide-head">
		<div>
			<span class="article-ide-kicker">Board / Article</span>
			<h1><c:out value="${boardMasterVO.bbsNm}" /> <spring:message code="title.update" /></h1>
		</div>
		<span class="article-ide-state">&#49688;&#51221;&#51473;</span>
	</div>

	<form:form modelAttribute="articleVO" cssClass="krds-form article-edit-form" action="${pageContext.request.contextPath}${bbsUrlBase}/updateArticle.do" method="post" onSubmit="fn_egov_updt_article(document.forms[0]); return false;" enctype="multipart/form-data">
		<c:set var="inputTxt"><spring:message code="input.input" /></c:set>
		<c:set var="hasExtraFields" value="${not empty boardMasterVO.bbsExtraField1 or not empty boardMasterVO.bbsExtraField2 or not empty boardMasterVO.bbsExtraField3 or not empty boardMasterVO.bbsExtraField4 or not empty boardMasterVO.bbsExtraField5 or not empty boardMasterVO.bbsExtraField6 or not empty boardMasterVO.bbsExtraField7 or not empty boardMasterVO.bbsExtraField8 or not empty boardMasterVO.bbsExtraField9 or not empty boardMasterVO.bbsExtraField10}" />

		<div class="article-ide-shell">
			<main class="rlms-ide-main article-ide-main">
				<div class="ide-context-pane">
					<div class="ide-prov-head">
						<h2>&#44172;&#49884;&#44544; &#49688;&#51221;</h2>
						<span class="ide-prov-status new">&#54200;&#51665;&#51473;</span>
					</div>

					<c:set var="title"><spring:message code="comCopBbs.articleVO.updt.nttSj" /></c:set>
					<div class="ide-form-row">
						<label for="nttSj">${title} <span class="required-mark">*</span></label>
						<form:input path="nttSj" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
						<form:errors path="nttSj" cssClass="form-hint-invalid" />
					</div>

					<c:set var="title"><spring:message code="comCopBbs.articleVO.updt.nttCn" /></c:set>
					<div class="ide-form-row">
						<label for="nttCn">${title} <span class="required-mark">*</span></label>
						<form:textarea path="nttCn" cssClass="krds-input article-content-field" title="${title} ${inputTxt}" rows="16" />
						<form:errors path="nttCn" cssClass="form-hint-invalid" />
					</div>

					<c:if test="${hasExtraFields}">
						<c:forEach begin="1" end="10" var="i">
							<c:set var="fieldLabel" value="${boardMasterVO.getBbsExtraField(i)}" />
							<c:set var="fieldType" value="${boardMasterVO.getBbsExtraFieldType(i)}" />
							<c:set var="fieldOptions" value="${bbsExtraCodeOptions[i]}" />
							<c:set var="fieldValue" value="${articleVO.getNttExtraField(i)}" />
							<c:if test="${not empty fieldLabel}">
								<div class="ide-form-row">
									<label for="nttExtraField${i}"><c:out value="${fieldLabel}" /></label>
									<c:choose>
										<c:when test="${fieldType == 'select' and not empty fieldOptions}">
											<select name="nttExtraField${i}" id="nttExtraField${i}" class="krds-select">
												<option value="">&#49440;&#53469;</option>
												<c:forEach var="code" items="${fieldOptions}">
													<option value="${fn:escapeXml(code.code)}" <c:if test="${fieldValue == code.code}">selected="selected"</c:if>><c:out value="${code.codeNm}" /></option>
												</c:forEach>
											</select>
										</c:when>
										<c:when test="${fieldType == 'radio' and not empty fieldOptions}">
											<div class="bbs-extra-choice-group">
												<c:forEach var="code" items="${fieldOptions}" varStatus="status">
													<label class="article-check-line" for="nttExtraField${i}_${status.index}">
														<input type="radio" name="nttExtraField${i}" id="nttExtraField${i}_${status.index}" value="${fn:escapeXml(code.code)}" <c:if test="${fieldValue == code.code}">checked="checked"</c:if>>
														<span><c:out value="${code.codeNm}" /></span>
													</label>
												</c:forEach>
											</div>
										</c:when>
										<c:when test="${fieldType == 'checkbox' and not empty fieldOptions}">
											<%-- 다중선택 — 값은 쉼표로 이어 한 칸에 저장한다. 이름은 nttExtraField{i} 가 아니라
											     nttExtraFieldChk{i}(+숨김 마커). 같은 이름으로 다중값을 보내면 String 속성 바인딩이 깨진다. --%>
											<c:set var="selectedWrapped" value=",${fieldValue}," />
											<input type="hidden" name="nttExtraFieldChkMark${i}" value="1">
											<div class="bbs-extra-choice-group">
												<c:forEach var="code" items="${fieldOptions}" varStatus="status">
													<c:set var="codeWrapped" value=",${code.code}," />
													<label class="article-check-line" for="nttExtraFieldChk${i}_${status.index}">
														<input type="checkbox" name="nttExtraFieldChk${i}" id="nttExtraFieldChk${i}_${status.index}" value="${fn:escapeXml(code.code)}" <c:if test="${fn:contains(selectedWrapped, codeWrapped)}">checked="checked"</c:if>>
														<span><c:out value="${code.codeNm}" /></span>
													</label>
												</c:forEach>
											</div>
										</c:when>
										<c:otherwise>
											<input type="text" name="nttExtraField${i}" id="nttExtraField${i}" class="krds-input" maxlength="200" value="${fn:escapeXml(fieldValue)}">
										</c:otherwise>
									</c:choose>
								</div>
							</c:if>
						</c:forEach>
					</c:if>

					<div class="article-option-grid">
						<c:set var="title"><spring:message code="comCopBbs.articleVO.updt.sjBoldAt" /></c:set>
						<div class="ide-form-row">
							<label for="sjBoldAt">${title}</label>
							<label class="article-check-line" for="sjBoldAt1">
								<form:checkbox path="sjBoldAt" value="Y" />
								<span>${title}</span>
							</label>
							<form:errors path="sjBoldAt" cssClass="form-hint-invalid" />
						</div>

						<c:set var="title"><spring:message code="comCopBbs.articleVO.updt.noticeAt" /></c:set>
						<div class="ide-form-row">
							<label for="noticeAt">${title}</label>
							<label class="article-check-line" for="noticeAt1">
								<form:checkbox path="noticeAt" value="Y" />
								<span>${title}</span>
							</label>
							<form:errors path="noticeAt" cssClass="form-hint-invalid" />
						</div>

						<%-- 비밀글 허용(SECRET_POSBL_AT)이 N 인 게시판은 비밀글 설정을 노출하지 않는다. --%>
						<c:if test="${boardMasterVO.secretPosblAt != 'N'}">
						<c:set var="title"><spring:message code="comCopBbs.articleVO.updt.secretAt" /></c:set>
						<div class="ide-form-row">
							<label for="secretAt">${title}</label>
							<label class="article-check-line" for="secretAt1">
								<form:checkbox path="secretAt" value="Y" />
								<span>${title}</span>
							</label>
							<form:errors path="secretAt" cssClass="form-hint-invalid" />
						</div>
						</c:if>
					</div>

					<c:set var="title"><spring:message code="comCopBbs.articleVO.updt.ntceDe" /></c:set>
					<div class="ide-form-row">
						<label for="ntceBgnde">${title}</label>
						<div class="article-date-group">
							<form:input path="ntceBgnde" type="date" cssClass="krds-input" title="${title} ${inputTxt}" />
							<span>~</span>
							<form:input path="ntceEndde" type="date" cssClass="krds-input" title="${title} ${inputTxt}" />
						</div>
						<form:errors path="ntceBgnde" cssClass="form-hint-invalid" />
						<form:errors path="ntceEndde" cssClass="form-hint-invalid" />
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
					</div>

					<c:if test="${articleVO.useAt eq 'N' and isAdmin}">
						<p class="bbs-restore-notice">삭제된 게시물입니다. '복구'를 누르면 목록·사용자 화면에 다시 노출됩니다. (제목·본문·첨부는 삭제 시점 그대로 보존되어 있습니다.)</p>
					</c:if>
					<div class="ide-form-actions">
						<button type="submit" class="krds-btn primary medium" title="<spring:message code='button.update' /> <spring:message code='input.button' />"><spring:message code="button.update" /></button>
						<c:if test="${articleVO.useAt eq 'N' and isAdmin}">
						<%-- 복구는 별도 동선(restoreArticle.do) — 수정폼 onSubmit(검증) 우회를 위해 동적 폼 제출 --%>
						<button type="button" class="krds-btn primary medium" onclick="fn_bbs_restore_article(); return false;">복구</button>
						</c:if>
						<a href="<c:url value='${bbsUrlBase}/selectArticleList.do' />?bbsId=${boardMasterVO.bbsId}&searchCnd=${searchVO.searchCnd}&searchWrd=${searchVO.searchWrd}&pageIndex=${searchVO.pageIndex}" class="krds-btn secondary medium" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
					</div>
				</div>
			</main>

			<aside class="rlms-ide-right article-ide-right">
				<h3 class="ide-related-tit">&#44172;&#49884;&#44544; &#51089;&#50629;&#51221;&#48372;</h3>
				<div class="article-side-block">
					<span class="article-side-label">&#44172;&#49884;&#54032;</span>
					<p class="article-side-text"><c:out value="${boardMasterVO.bbsNm}" /></p>
				</div>
				<div class="article-side-block">
					<span class="article-side-label">&#49828;&#53416;</span>
					<p class="article-side-text"><c:out value="${boardMasterVO.bbsSkinCode}" /></p>
				</div>
				<div class="article-side-block">
					<span class="article-side-label">&#44172;&#49884;&#44544; ID</span>
					<p class="article-side-text"><c:out value="${articleVO.nttId}" /></p>
				</div>
				<c:if test="${boardMasterVO.fileAtchPosblAt == 'Y'}">
					<c:set var="fileTitle"><spring:message code="comCopBbs.articleVO.updt.atchFile" /></c:set>
					<%-- 기존 첨부가 있을 때만 노출 — 없으면 빈 흰 박스만 남는다. 전량 삭제 케이스는 아래 init JS 가 fileListCnt=0 으로 숨김 --%>
					<c:if test="${not empty fn:trim(articleVO.atchFileId)}">
					<div class="article-side-block" id="bbsCurrentFilesBlock">
						<span class="article-side-label">${fileTitle}</span>
						<div class="article-file-current">
							<c:import url="/cmm/fms/selectFileInfsForUpdate.do" charEncoding="utf-8">
								<c:param name="param_atchFileId" value="${egovc:encrypt(articleVO.atchFileId)}" />
							</c:import>
						</div>
					</div>
					</c:if>
					<c:set var="fileAddTitle"><spring:message code="comCopBbs.articleVO.updt.atchFileAdd" /></c:set>
					<div class="article-side-block">
						<span class="article-side-label">${fileAddTitle}</span>
						<%-- 드롭존 클래스는 KRDS 표준 .file-upload 가 아니라 .ide-file-drop —
						     krds.min.js 의 krds_fileUpload.init() 이 버튼 없는 .file-upload 에서
						     null.addEventListener 콘솔에러를 내므로 분리(스타일=rlms-compat). --%>
						<div class="krds-file-upload">
							<div class="ide-file-drop" id="bbsFileDrop">
								<input type="file" id="egovComFileUploader" name="file_1" class="ide-file-native" title="${fileAddTitle}" multiple />
								<span class="txt">파일을 여기로 끌어다 놓거나 <strong>파일 선택</strong></span>
							</div>
							<div class="file-list">
								<div class="total" id="bbsFileTotal" style="display:none;">총 <span class="current">0</span>개</div>
								<ul id="bbsFileSelList" class="upload-list"></ul>
							</div>
							<div id="bbsFileNotice" class="ide-file-notice" style="display:none;"></div>
						</div>
					</div>
				</c:if>
			</aside>
		</div>

		<input name="searchCnd" type="hidden" value="<c:out value='${searchVO.searchCnd}'/>" />
		<input name="searchWrd" type="hidden" value="<c:out value='${searchVO.searchWrd}'/>" />
		<input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>" />
		<input type="hidden" name="bbsTyCode" value="<c:out value='${boardMasterVO.bbsTyCode}'/>" />
		<input type="hidden" name="replyPosblAt" value="<c:out value='${boardMasterVO.replyPosblAt}'/>" />
		<input type="hidden" name="fileAtchPosblAt" value="<c:out value='${boardMasterVO.fileAtchPosblAt}'/>" />
		<input type="hidden" id="atchPosblFileNumber" name="atchPosblFileNumber" value="<c:out value='${boardMasterVO.atchPosblFileNumber}'/>" />
		<input type="hidden" name="atchPosblFileSize" value="<c:out value='${boardMasterVO.atchPosblFileSize}'/>" />
		<input type="hidden" name="tmplatId" value="<c:out value='${boardMasterVO.tmplatId}'/>" />
		<input name="nttId" type="hidden" value="<c:out value='${articleVO.nttId}'/>">
		<input name="bbsId" type="hidden" value="<c:out value='${boardMasterVO.bbsId}'/>">
	</form:form>
</div>

<!-- 삭제글 복구 — 수정폼 onSubmit(검증/저장) 을 우회해 restoreArticle.do 로 별도 POST -->
<script type="text/javascript">
function fn_bbs_restore_article(){
	if(!confirm('이 게시물을 복구하시겠습니까?')){ return; }
	var f = document.forms['articleVO'];
	var g = function(n){ var el = f.elements[n]; return el ? el.value : ''; };
	var nf = document.createElement('form');
	nf.method = 'post';
	nf.action = '<c:url value="/cop/bbs/restoreArticle.do"/>';
	var fields = { nttId: g('nttId'), bbsId: g('bbsId'), searchCnd: g('searchCnd'), searchWrd: g('searchWrd'), pageIndex: g('pageIndex') };
	for(var k in fields){
		var i = document.createElement('input');
		i.type = 'hidden'; i.name = k; i.value = fields[k];
		nf.appendChild(i);
	}
	document.body.appendChild(nf);
	nf.submit();
}
</script>

<!-- 첨부파일 드롭존 초기화 (첨부불가 게시판이면 대상 부재로 무동작) -->
<script type="text/javascript">
// 기존 첨부가 전량 삭제된 상태(atchFileId 는 있으나 detail 0건)면 빈 박스 숨김
(function(){
	var cnt = document.getElementById('fileListCnt');
	var blk = document.getElementById('bbsCurrentFilesBlock');
	if (blk && cnt && (parseInt(cnt.value, 10) || 0) === 0) { blk.style.display = 'none'; }
})();
var atchPosblFileNumber = document.getElementById('atchPosblFileNumber');
EgovFileDropzone.init({
	input: 'egovComFileUploader', drop: 'bbsFileDrop',
	list: 'bbsFileSelList', total: 'bbsFileTotal', notice: 'bbsFileNotice',
	maxCount: parseInt(atchPosblFileNumber ? atchPosblFileNumber.value : '', 10) || 3,
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
