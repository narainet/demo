<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator"%>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comUssOlhFaq.faqVO.title" /></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.update" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/fms/EgovMultiFiles.js'/>"></script>
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<validator:javascript formName="faqVO" staticJavascript="false" xhtml="true" cdata="false" />
<style>
.faq-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
.faq-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.faq-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
.faq-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.faq-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #e8edf9; color: #1f3974; font-size: 13px; font-weight: 700; }
.faq-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 620px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
.faq-ide-main { min-height: 620px; border-right: 1px solid #d1d3d8; }
.faq-ide-main .ide-context-pane { padding: 24px; }
.faq-ide-main .ide-prov-head { align-items: center; flex-wrap: wrap; }
.faq-ide-main .ide-prov-head h2 { font-size: 21px; }
.faq-ide-main .ide-form-row { margin-bottom: 18px; }
.faq-ide-main .krds-input.small { max-width: 100%; }
.faq-ide-main textarea.krds-input { min-height: 190px; }
.faq-ide-main textarea.faq-answer-field { min-height: 260px; }
.faq-ide-main .ide-form-actions { margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
.faq-ide-main .form-hint-invalid { color: #d4351c; }
.faq-ide-right { min-height: 620px; }
.faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.faq-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; }
.faq-upload-box { padding: 12px; border-radius: 6px; background: #fff; color: #1d1d1d; }
.faq-upload-box input[type="file"] { width: 100%; min-height: 42px; padding: 9px 10px; border: 1px solid #c4c6cd; border-radius: 4px; background: #fff; box-sizing: border-box; font-size: 13px; }
.faq-upload-box #egovComFileList { margin-top: 8px; color: #333; font-size: 13px; }
.faq-current-files { margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #e1e5ee; }
.faq-current-files table,
.faq-current-files ul,
.faq-current-files div { max-width: 100%; color: #1d1d1d; }
.faq-current-files a { color: #1f3974; }
.required-mark { color: #d4351c; font-weight: 700; }
@media (max-width: 1024px) {
  .faq-ide-shell { grid-template-columns: 1fr; }
  .faq-ide-main { border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .faq-ide-right { min-height: 0; }
}
@media (max-width: 768px) {
  .faq-ide-head { align-items: flex-start; flex-direction: column; }
  .faq-ide-state { align-self: flex-start; }
  .faq-ide-main .ide-context-pane { padding: 18px; }
  .faq-ide-main .ide-form-actions { justify-content: flex-start; flex-wrap: wrap; }
}
</style>
<script type="text/javascript">
function fn_egov_init() {
    var maxFileNum = 3;
    var multi_selector = new MultiSelector(document.getElementById("egovComFileList"), maxFileNum);
    multi_selector.addElement(document.getElementById("egovComFileUploader"));

    if (document.getElementById("faqVO") && document.getElementById("faqVO").qestnSj) {
        document.getElementById("faqVO").qestnSj.focus();
    }
}

function fn_egov_updt_faq(form) {
    var resultExtension = EgovMultiFilesChecker.checkExtensions("egovComFileUploader", "<c:out value='${fileUploadExtensions}'/>");
    if (!resultExtension) return true;
    var resultSize = EgovMultiFilesChecker.checkFileSize("egovComFileUploader", <c:out value='${fileUploadMaxSize}'/>);
    if (!resultSize) return true;

    if (!validateFaqVO(form)) {
        return false;
    }
    if (confirm("<spring:message code='common.update.msg' />")) {
        form.submit();
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init();">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="faq-ide-page">
    <div class="faq-ide-head">
        <div>
            <span class="faq-ide-kicker">Helpdesk / FAQ</span>
            <h1>FAQ 수정</h1>
        </div>
        <span class="faq-ide-state">수정 모드</span>
    </div>

    <form:form modelAttribute="faqVO" cssClass="krds-form faq-edit-form" action="${pageContext.request.contextPath}/uss/olh/faq/updateFaq.do" method="post" onSubmit="fn_egov_updt_faq(document.forms[0]); return false;" enctype="multipart/form-data">
        <c:set var="inputTxt"><spring:message code="input.input" /></c:set>
        <c:set var="fileTitle"><spring:message code="comUssOlhFaq.faqVO.atchFile"/></c:set>

        <div class="faq-ide-shell">
            <main class="rlms-ide-main faq-ide-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>질문/답변 편집</h2>
                        <span class="ide-prov-status exist">저장됨</span>
                    </div>

                    <%-- FAQ 카테고리(ccm 'faqCode', RLMS 2026-07-09 확장) --%>
                    <div class="ide-form-row">
                        <label for="faqCode">카테고리</label>
                        <form:select path="faqCode" cssClass="krds-select">
                            <form:option value="" label="선택"/>
                            <c:forEach var="cd" items="${faqCodeList}">
                            <form:option value="${cd.code}" label="${cd.codeNm}"/>
                            </c:forEach>
                        </form:select>
                    </div>

                    <c:set var="title"><spring:message code="comUssOlhFaq.faqVO.qestnSj"/></c:set>
                    <div class="ide-form-row">
                        <label for="qestnSj">${title} <span class="required-mark">*</span></label>
                        <form:input path="qestnSj" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
                        <form:errors path="qestnSj" cssClass="form-hint-invalid" />
                    </div>

                    <c:set var="title"><spring:message code="comUssOlhFaq.faqVO.qestnCn"/></c:set>
                    <div class="ide-form-row">
                        <label for="qestnCn">${title} <span class="required-mark">*</span></label>
                        <form:textarea path="qestnCn" cssClass="krds-input faq-question-field" title="${title} ${inputTxt}" rows="9" />
                        <form:errors path="qestnCn" cssClass="form-hint-invalid" />
                    </div>

                    <c:set var="title"><spring:message code="comUssOlhFaq.faqVO.answerCn"/></c:set>
                    <div class="ide-form-row">
                        <label for="answerCn">${title} <span class="required-mark">*</span></label>
                        <form:textarea path="answerCn" cssClass="krds-input faq-answer-field" title="${title} ${inputTxt}" rows="12" />
                        <form:errors path="answerCn" cssClass="form-hint-invalid" />
                    </div>

                    <div class="ide-form-actions">
                        <button type="submit" class="krds-btn primary medium" title="<spring:message code='button.update' /> <spring:message code='input.button' />"><spring:message code="button.update" /></button>
                        <a href="<c:url value='/uss/olh/faq/selectFaqList.do' />" class="krds-btn secondary medium" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
                    </div>
                </div>
            </main>

            <aside class="rlms-ide-right faq-ide-right">
                <h3 class="ide-related-tit">FAQ 작업정보</h3>
                <div class="faq-side-block">
                    <span class="faq-side-label">상태</span>
                    <p class="faq-side-text">등록된 FAQ를 수정하고 있습니다.</p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label">${fileTitle}</span>
                    <div class="faq-upload-box">
                        <c:if test="${not empty faqVO.atchFileId}">
                            <div class="faq-current-files">
                                <c:import charEncoding="utf-8" url="/cmm/fms/selectFileInfsForUpdate.do">
                                    <c:param name="param_atchFileId" value="${egovc:encrypt(faqVO.atchFileId)}" />
                                </c:import>
                            </div>
                        </c:if>
                        <input type="file" multiple name="file_1" id="egovComFileUploader" title="${fileTitle}" />
                        <div id="egovComFileList"></div>
                    </div>
                </div>
            </aside>
        </div>

        <input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>" />
        <form:hidden path="faqId" />
        <form:hidden path="atchFileId" />
    </form:form>
</div>
</lay:layout>
