<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comUssOlhQna.qnaVO.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.create" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<validator:javascript formName="qnaVO" staticJavascript="false" xhtml="true" cdata="false"/>
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
.faq-ide-main textarea.krds-input { min-height: 260px; }
.faq-ide-main .ide-form-actions { margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
.faq-ide-main .form-hint-invalid { color: #d4351c; }
.qna-field-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
.qna-phone-group { display: flex; align-items: center; gap: 8px; max-width: 360px; }
.qna-phone-group .krds-input { text-align: center; }
.qna-check-line { display: flex; align-items: center; gap: 8px; min-height: 40px; color: #1d1d1d; font-size: 14px; }
.qna-check-line input[type="checkbox"],
.qna-check-line .qna-native-check {
  appearance: auto !important;
  -webkit-appearance: checkbox !important;
  display: inline-block !important;
  position: static !important;
  visibility: visible !important;
  opacity: 1 !important;
  width: 16px !important;
  height: 16px !important;
  min-width: 16px !important;
  margin: 0 !important;
  padding: 0 !important;
  border: 1px solid #555 !important;
  background: #fff !important;
  vertical-align: middle !important;
}
.faq-ide-right { min-height: 620px; }
.faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.faq-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
.faq-side-value { margin: 0; color: #fff; font-size: 14px; line-height: 1.5; word-break: break-word; }
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
  .qna-field-grid { grid-template-columns: 1fr; gap: 0; }
  .qna-phone-group { max-width: 100%; }
}
</style>
<script type="text/javascript">
function fn_egov_init() {
    if (document.getElementById("qnaVO") && document.getElementById("qnaVO").qestnSj) {
        document.getElementById("qnaVO").qestnSj.focus();
    }
}

function fn_egov_regist_qna(form) {
    var emailValue = document.getElementById("emailAdres").value.length;
    var emailCheck = document.getElementById("emailAnswerAt1").checked;
    if (emailCheck && emailValue < 1) {
        alert("Enter your email address");
        return false;
    }

    if (!validateQnaVO(form)) {
        return false;
    }
    if (confirm("<spring:message code='common.regist.msg' />")) {
        form.action = "<c:url value='/uss/olh/qna/insertQna.do'/>";
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
            <span class="faq-ide-kicker">Helpdesk / Q&A</span>
            <h1>Q&A 등록</h1>
        </div>
        <span class="faq-ide-state">신규 작성</span>
    </div>

    <form:form modelAttribute="qnaVO" cssClass="krds-form faq-edit-form" method="post" onSubmit="fn_egov_regist_qna(document.forms[0]); return false;">
        <c:set var="inputTxt"><spring:message code="input.input" /></c:set>

        <div class="faq-ide-shell">
            <main class="rlms-ide-main faq-ide-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>질문 편집</h2>
                        <span class="ide-prov-status new">작성중</span>
                    </div>

                    <div class="qna-field-grid">
                        <c:set var="title"><spring:message code="table.reger"/> </c:set>
                        <div class="ide-form-row">
                            <label for="wrterNm">${title} <span class="required-mark">*</span></label>
                            <form:input path="wrterNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
                            <form:errors path="wrterNm" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssOlhQna.qnaVO.emailAdres"/> </c:set>
                        <div class="ide-form-row">
                            <label for="emailAdres">${title}</label>
                            <form:input path="emailAdres" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
                            <form:errors path="emailAdres" cssClass="form-hint-invalid" />
                        </div>
                    </div>

                    <div class="qna-field-grid">
                        <c:set var="title"><spring:message code="comUssOlhQna.qnaVO.telNo"/> </c:set>
                        <div class="ide-form-row">
                            <label for="areaNo">${title} <span class="required-mark">*</span></label>
                            <div class="qna-phone-group">
                                <form:input path="areaNo" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
                                <span>-</span>
                                <form:input path="middleTelno" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
                                <span>-</span>
                                <form:input path="endTelno" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
                            </div>
                            <form:errors path="areaNo" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssOlhQna.qnaVO.emailAnswerAt"/> </c:set>
                        <div class="ide-form-row">
                            <label for="emailAnswerAt1">${title}</label>
                            <label class="qna-check-line" for="emailAnswerAt1">
                                <form:checkbox path="emailAnswerAt" value="Y" cssClass="qna-native-check" />
                                <span>답변 등록 시 이메일로 알림을 받습니다.</span>
                            </label>
                        </div>
                    </div>

                    <c:set var="title"><spring:message code="comUssOlhQna.qnaVO.qnaProcessSttusCode"/> </c:set>
                    <div class="ide-form-row">
                        <label for="qnaProcessSttusCode">${title} <span class="required-mark">*</span></label>
                        <form:select path="qnaProcessSttusCode" cssClass="krds-input" title="${title} ${inputTxt}">
                            <form:options items="${qnaProcessSttusCode}" itemValue="code" itemLabel="codeNm" />
                        </form:select>
                        <form:errors path="qnaProcessSttusCode" cssClass="form-hint-invalid" />
                    </div>

                    <c:set var="title"><spring:message code="comUssOlhQna.qnaVO.qestnSj"/> </c:set>
                    <div class="ide-form-row">
                        <label for="qestnSj">${title} <span class="required-mark">*</span></label>
                        <form:input path="qestnSj" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
                        <form:errors path="qestnSj" cssClass="form-hint-invalid" />
                    </div>

                    <c:set var="title"><spring:message code="comUssOlhQna.qnaVO.qestnCn"/> </c:set>
                    <div class="ide-form-row">
                        <label for="qestnCn">${title} <span class="required-mark">*</span></label>
                        <form:textarea path="qestnCn" cssClass="krds-input" title="${title} ${inputTxt}" rows="12" />
                        <form:errors path="qestnCn" cssClass="form-hint-invalid" />
                    </div>

                    <div class="ide-form-actions">
                        <button type="submit" class="krds-btn primary medium" title="<spring:message code='button.create' /> <spring:message code='input.button' />"><spring:message code="button.create" /></button>
                        <a href="<c:url value='/uss/olh/qna/selectQnaList.do' />" class="krds-btn secondary medium" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
                    </div>
                </div>
            </main>

            <aside class="rlms-ide-right faq-ide-right">
                <h3 class="ide-related-tit">Q&A 작업정보</h3>
                <div class="faq-side-block">
                    <span class="faq-side-label">상태</span>
                    <p class="faq-side-text">등록 전 신규 문의입니다.</p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label">작성 기준</span>
                    <p class="faq-side-text">질문 제목과 내용을 입력하면 관리자 답변 대기 상태로 등록됩니다.</p>
                </div>
            </aside>
        </div>

        <input name="answerCn" type="hidden" value="<c:out value='answer'/>" />
        <input name="cmd" type="hidden" value="<c:out value='save'/>" />
    </form:form>
</div>
</lay:layout>
