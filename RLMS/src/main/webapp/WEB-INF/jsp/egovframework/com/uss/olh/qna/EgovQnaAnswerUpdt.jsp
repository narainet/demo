<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<%-- Q&A 답변 등록/수정 (관리자 — mgr 데코). egov 원형 → KRDS 재작성(2026-07-09).
     updateQnaAnswer 는 답변내용+처리상태+qaId 만 갱신 — 질문 필드는 읽기 표시만(hidden 불요).
     원형의 validateQnaVO(질문 폼 규칙)는 답변 폼에 부적합 → 답변내용 필수만 자체 검증. --%>
<c:set var="pageTitle" value="Q&A 답변" />
<c:set var="pageTitle">${pageTitle} 등록/수정</c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
.faq-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
.faq-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.faq-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
.faq-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.faq-ide-actions { display: inline-flex; flex-wrap: wrap; justify-content: flex-end; gap: 6px; }
.faq-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 620px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
.faq-ide-main { min-height: 620px; border-right: 1px solid #d1d3d8; }
.faq-ide-main .ide-context-pane { padding: 24px; }
.faq-ide-main .ide-prov-head { align-items: center; flex-wrap: wrap; }
.faq-ide-main .ide-prov-head h2 { font-size: 21px; }
.faq-detail-title { margin: 0 0 18px 0; padding: 16px 18px; border: 1px solid #d8dde8; border-radius: 6px; background: #f8f9fc; color: #1d1d1d; font-size: 20px; line-height: 1.45; word-break: break-word; }
.faq-read-block { margin-bottom: 18px; }
.faq-read-label { display: block; margin-bottom: 8px; color: #1f3974; font-weight: 700; font-size: 14px; }
.faq-read-content { min-height: 120px; padding: 18px; border: 1px solid #d8dde8; border-radius: 6px; background: #fff; color: #333; line-height: 1.75; word-break: break-word; }
.qna-answer-field { width: 100%; min-height: 220px; box-sizing: border-box; line-height: 1.7; resize: vertical; }
.qna-sttus-row { display: flex; align-items: center; gap: 10px; margin-bottom: 18px; }
.qna-sttus-row .krds-select { width: 200px; }
.faq-ide-right { min-height: 620px; }
.faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.faq-side-value { margin: 0; color: #fff; font-size: 14px; line-height: 1.5; word-break: break-word; }
.qna-info-line { display: block; margin-top: 3px; color: rgba(255,255,255,0.72); font-size: 12px; line-height: 1.5; }
@media (max-width: 1024px) {
  .faq-ide-shell { grid-template-columns: 1fr; }
  .faq-ide-main { border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .faq-ide-right { min-height: 0; }
}
@media (max-width: 768px) {
  .faq-ide-head { align-items: flex-start; flex-direction: column; }
  .faq-ide-actions { justify-content: flex-start; }
  .faq-ide-main .ide-context-pane { padding: 18px; }
}
</style>
<script type="text/javascript">
function fn_egov_updt_qna(form) {
    if (!form.answerCn.value || form.answerCn.value.replace(/^\s+|\s+$/g, '') === '') {
        alert("답변내용을 입력해 주세요.");
        form.answerCn.focus();
        return;
    }
    if (confirm("답변을 저장하시겠습니까?")) {
        form.submit();
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<%-- krds-select/krds-input 스타일은 .krds-form 하위 스코프 — 폼 클래스 필수 --%>
<form:form modelAttribute="qnaVO" cssClass="krds-form" action="${pageContext.request.contextPath}/uss/olh/qna/updateQnaAnswer.do" method="post" onsubmit="fn_egov_updt_qna(this); return false;">
    <div class="faq-ide-page">
        <div class="faq-ide-head">
            <div>
                <span class="faq-ide-kicker">Helpdesk / Q&A 관리</span>
                <h1>답변 등록/수정</h1>
            </div>
            <div class="faq-ide-actions">
                <button type="button" class="krds-btn primary medium" onclick="fn_egov_updt_qna(document.getElementById('qnaVO'));">저장</button>
                <a href="<c:url value='/uss/olh/qna/selectQnaAnswerList.do' />" class="krds-btn secondary medium" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
            </div>
        </div>

        <div class="faq-ide-shell">
            <main class="rlms-ide-main faq-ide-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>질문 확인 / 답변 작성</h2>
                        <span class="ide-prov-status exist"><c:out value="${qnaVO.qnaProcessSttusCodeNm}" /></span>
                    </div>

                    <h3 class="faq-detail-title"><c:out value="${qnaVO.qestnSj}" /></h3>

                    <div class="faq-read-block">
                        <span class="faq-read-label"><spring:message code="comUssOlhQna.qnaVO.qestnCn" /></span>
                        <div class="faq-read-content">
                            <c:out value="${fn:replace(qnaVO.qestnCn, crlf, '<br/>')}" escapeXml="false" />
                        </div>
                    </div>

                    <div class="qna-sttus-row">
                        <span class="faq-read-label" style="margin-bottom:0;"><spring:message code="comUssOlhQna.qnaVO.qnaProcessSttusCode" /> <span class="required-mark">*</span></span>
                        <form:select path="qnaProcessSttusCode" cssClass="krds-select">
                            <form:options items="${qnaProcessSttusCode}" itemValue="code" itemLabel="codeNm" />
                        </form:select>
                    </div>

                    <div class="faq-read-block">
                        <span class="faq-read-label"><spring:message code="comUssOlhQna.qnaVO.answerCn" /> <span class="required-mark">*</span></span>
                        <form:textarea path="answerCn" cssClass="krds-input qna-answer-field" rows="10" />
                    </div>
                </div>
            </main>

            <aside class="rlms-ide-right faq-ide-right">
                <h3 class="ide-related-tit">Q&A 정보</h3>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="table.reger" /></span>
                    <p class="faq-side-value"><c:out value="${qnaVO.wrterNm}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhQna.qnaVO.telNo" /></span>
                    <p class="faq-side-value"><c:out value="${qnaVO.areaNo}" /> - <c:out value="${qnaVO.middleTelno}" /> - <c:out value="${qnaVO.endTelno}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhQna.qnaVO.emailAdres" /></span>
                    <p class="faq-side-value">
                        <c:out value="${qnaVO.emailAdres}" />
                        <span class="qna-info-line">
                            <spring:message code="comUssOlhQna.qnaVO.emailAnswerAt" />:
                            <c:choose>
                                <c:when test="${qnaVO.emailAnswerAt == 'Y'}">Y</c:when>
                                <c:otherwise>N</c:otherwise>
                            </c:choose>
                        </span>
                    </p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="table.regdate" /></span>
                    <p class="faq-side-value"><c:out value="${qnaVO.frstRegisterPnttm}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label">답변일자</span>
                    <p class="faq-side-value"><c:out value="${empty qnaVO.answerDe ? '-' : qnaVO.answerDe}" /></p>
                </div>
            </aside>
        </div>
    </div>

    <form:hidden path="qaId" />
</form:form>
</lay:layout>
