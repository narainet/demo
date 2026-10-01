<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<%-- FAQ 관리 상세 (편집계 전용 — URL 가드 L2.6). 사용자 열람은 selectFaqUserList.do 아코디언(상세 미사용) --%>
<c:set var="pageTitle"><spring:message code="comUssOlhFaq.faqVO.title"/></c:set>
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
.faq-read-content { min-height: 140px; padding: 18px; border: 1px solid #d8dde8; border-radius: 6px; background: #fff; color: #333; line-height: 1.75; word-break: break-word; }
.faq-read-content.answer { min-height: 220px; }
.faq-ide-right { min-height: 620px; }
.faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.faq-side-value { margin: 0; color: #fff; font-size: 14px; line-height: 1.5; word-break: break-word; }
.faq-side-empty { margin: 0; color: rgba(255,255,255,0.7); font-size: 13px; line-height: 1.6; }
.faq-attach-box { padding: 12px; border-radius: 6px; background: #fff; color: #1d1d1d; }
.faq-attach-box table,
.faq-attach-box ul,
.faq-attach-box div { max-width: 100%; color: #1d1d1d; }
.faq-attach-box a { color: #1f3974; }
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
function fn_egov_delete_faq(faqId) {
    if (confirm("<spring:message code='common.delete.msg' />")) {
        document.faqForm.faqId.value = faqId;
        document.faqForm.action = "<c:url value='/uss/olh/faq/deleteFaq.do'/>";
        document.faqForm.submit();
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<form name="faqForm" class="faq-detail-form" action="<c:url value='/uss/olh/faq/updateFaqView.do'/>" method="post">
    <div class="faq-ide-page">
        <div class="faq-ide-head">
            <div>
                <span class="faq-ide-kicker">Helpdesk / FAQ</span>
                <h1>FAQ 상세</h1>
            </div>
            <div class="faq-ide-actions">
                <button type="submit" class="krds-btn primary medium" title="<spring:message code='title.update' /> <spring:message code='input.button' />"><spring:message code="button.update" /></button>
                <a href="<c:url value='/uss/olh/faq/deleteFaq.do' />" class="krds-btn danger medium" onclick="fn_egov_delete_faq('<c:out value="${result.faqId}"/>'); return false;" title="<spring:message code='button.delete' /> <spring:message code='input.button' />"><spring:message code="button.delete" /></a>
                <a href="<c:url value='/uss/olh/faq/selectFaqList.do' />" class="krds-btn secondary medium" title="<spring:message code='title.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
            </div>
        </div>

        <div class="faq-ide-shell">
            <main class="rlms-ide-main faq-ide-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>질문/답변 보기</h2>
                        <span class="ide-prov-status exist">상세</span>
                    </div>

                    <h3 class="faq-detail-title"><c:out value="${result.qestnSj}" /></h3>

                    <div class="faq-read-block">
                        <span class="faq-read-label"><spring:message code="comUssOlhFaq.faqVO.qestnCn" /></span>
                        <div class="faq-read-content">
                            <c:out value="${fn:replace(result.qestnCn, crlf, '<br/>')}" escapeXml="false" />
                        </div>
                    </div>

                    <div class="faq-read-block">
                        <span class="faq-read-label"><spring:message code="comUssOlhFaq.faqVO.answerCn" /></span>
                        <div class="faq-read-content answer">
                            <c:out value="${fn:replace(result.answerCn, crlf, '<br/>')}" escapeXml="false" />
                        </div>
                    </div>
                </div>
            </main>

            <aside class="rlms-ide-right faq-ide-right">
                <h3 class="ide-related-tit">FAQ 정보</h3>
                <div class="faq-side-block">
                    <span class="faq-side-label">카테고리</span>
                    <p class="faq-side-value"><c:out value="${empty result.faqCodeNm ? '-' : result.faqCodeNm}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhFaq.faqVO.inqireCo" /></span>
                    <p class="faq-side-value"><c:out value="${result.inqireCo}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="table.regdate" /></span>
                    <p class="faq-side-value"><c:out value="${result.frstRegisterPnttm}" /></p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label"><spring:message code="comUssOlhFaq.faqVO.atchFile" /></span>
                    <c:choose>
                        <c:when test="${not empty result.atchFileId}">
                            <div class="faq-attach-box">
                                <c:import url="/cmm/fms/selectFileInfs.do" charEncoding="utf-8">
                                    <c:param name="param_atchFileId" value="${egovc:encrypt(result.atchFileId)}" />
                                </c:import>
                            </div>
                        </c:when>
                        <c:otherwise>
                            <p class="faq-side-empty">첨부파일이 없습니다.</p>
                        </c:otherwise>
                    </c:choose>
                </div>
            </aside>
        </div>
    </div>

    <input name="faqId" type="hidden" value="<c:out value='${result.faqId}' />" />
    <input name="atchFileId" type="hidden" value="<c:out value='${result.atchFileId}' />" />
    <input name="cmd" type="hidden" value="" />
</form>
</lay:layout>
