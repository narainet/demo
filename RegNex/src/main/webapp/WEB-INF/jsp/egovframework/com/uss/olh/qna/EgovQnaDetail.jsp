<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<%-- 사용자/관리자 공용 화면(2026-07-09 사용자 개방) — 질문 수정/삭제는 작성자 본인만 노출(서버도 EgovXssChecker 본인확인) --%>
<% Object rlmsU = egovframework.com.cmm.util.EgovUserDetailsHelper.getAuthenticatedUser();
   pageContext.setAttribute("rlmsUniqId",
     (rlmsU instanceof egovframework.com.cmm.LoginVO) ? ((egovframework.com.cmm.LoginVO) rlmsU).getUniqId() : ""); %>
<c:set var="pageTitle"><spring:message code="comUssOlhQna.qnaVO.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.detail" /></c:set>
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
.faq-read-content { min-height: 170px; padding: 18px; border: 1px solid #d8dde8; border-radius: 6px; background: #fff; color: #333; line-height: 1.75; word-break: break-word; }
.faq-read-content.answer { min-height: 160px; background: #f8f9fc; }
.faq-ide-right { min-height: 620px; }
.faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.faq-side-value { margin: 0; color: #fff; font-size: 14px; line-height: 1.5; word-break: break-word; }
.faq-side-empty { margin: 0; color: rgba(255,255,255,0.7); font-size: 13px; line-height: 1.6; }
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
function fn_egov_delete_qna(form) {
    if (confirm("<spring:message code='common.delete.msg' />")) {
        form.action = "<c:url value='/uss/olh/qna/deleteQna.do'/>";
        form.submit();
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<form name="qnaForm" action="<c:url value='/uss/olh/qna/updateQnaView.do'/>" method="post">
    <div class="faq-ide-page">
        <div class="faq-ide-head">
            <div>
                <span class="faq-ide-kicker">Helpdesk / Q&A</span>
                <h1>Q&A 상세</h1>
            </div>
            <div class="faq-ide-actions">
                <c:if test="${not empty rlmsUniqId and rlmsUniqId eq result.frstRegisterId}">
                <button type="submit" class="krds-btn primary medium" title="<spring:message code='title.update' /> <spring:message code='input.button' />"><spring:message code="button.update" /></button>
                <button type="button" class="krds-btn danger medium" onclick="fn_egov_delete_qna(document.qnaForm);" title="<spring:message code='button.delete' /> <spring:message code='input.button' />"><spring:message code="button.delete" /></button>
                </c:if>
                <a href="<c:url value='/uss/olh/qna/selectQnaList.do' />" class="krds-btn secondary medium" title="<spring:message code='title.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
            </div>
        </div>

        <div class="faq-ide-shell">
            <main class="rlms-ide-main faq-ide-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>질문/답변 보기</h2>
                        <span class="ide-prov-status exist"><c:out value="${result.qnaProcessSttusCodeNm}" /></span>
                    </div>

                    <h3 class="faq-detail-title"><c:out value="${result.qestnSj}" /></h3>

                    <div class="faq-read-block">
                        <span class="faq-read-label"><spring:message code="comUssOlhQna.qnaVO.qestnCn" /></span>
                        <div class="faq-read-content">
                            <c:out value="${fn:replace(result.qestnCn, crlf, '<br/>')}" escapeXml="false" />
                        </div>
                    </div>

                    <c:if test="${result.qnaProcessSttusCode == '3'}">
                        <div class="faq-read-block">
                            <span class="faq-read-label"><spring:message code="comUssOlhQna.qnaVO.answerCn" /></span>
                            <div class="faq-read-content answer">
                                <c:out value="${fn:replace(result.answerCn, crlf, '<br/>')}" escapeXml="false" />
                            </div>
                        </div>
                    </c:if>
                </div>
            </main>

            <aside class="rlms-ide-right faq-ide-right">
                <h3 class="ide-related-tit">Q&A 정보</h3>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="table.reger" /></span>
                    <p class="faq-side-value"><c:out value="${result.wrterNm}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhQna.qnaVO.telNo" /></span>
                    <p class="faq-side-value"><c:out value="${result.areaNo}" /> - <c:out value="${result.middleTelno}" /> - <c:out value="${result.endTelno}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhQna.qnaVO.emailAdres" /></span>
                    <p class="faq-side-value">
                        <c:out value="${result.emailAdres}" />
                        <span class="qna-info-line">
                            <spring:message code="comUssOlhQna.qnaVO.emailAnswerAt" />:
                            <c:choose>
                                <c:when test="${result.emailAnswerAt == 'Y'}">Y</c:when>
                                <c:otherwise>N</c:otherwise>
                            </c:choose>
                        </span>
                    </p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="table.regdate" /></span>
                    <p class="faq-side-value"><c:out value="${result.frstRegisterPnttm}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhQna.qnaVO.inqireCo" /></span>
                    <p class="faq-side-value"><c:out value="${result.inqireCo}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhQna.qnaVO.qnaProcessSttusCode" /></span>
                    <p class="faq-side-value"><c:out value="${result.qnaProcessSttusCodeNm}" /></p>
                </div>
            </aside>
        </div>
    </div>

    <input name="qaId" type="hidden" value="<c:out value='${result.qaId}' />" />
    <input name="cmd" type="hidden" value="" />
</form>
</lay:layout>
