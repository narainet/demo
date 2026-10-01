<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comUssUmt.deptManage.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.create" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<validator:javascript formName="deptManage" staticJavascript="false" xhtml="true" cdata="false"/>
<style>
.faq-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
.faq-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.faq-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
.faq-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.faq-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #e8edf9; color: #1f3974; font-size: 13px; font-weight: 700; }
.faq-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 560px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
.faq-ide-main { min-height: 560px; border-right: 1px solid #d1d3d8; }
.faq-ide-main .ide-context-pane { padding: 24px; }
.faq-ide-main .ide-prov-head { align-items: center; flex-wrap: wrap; }
.faq-ide-main .ide-prov-head h2 { font-size: 21px; }
.faq-ide-main .ide-form-row { margin-bottom: 18px; }
.faq-ide-main .krds-input.small,
.faq-ide-main .krds-input { max-width: 100%; }
.faq-ide-main textarea.krds-input { min-height: 220px; resize: vertical; }
.faq-ide-main .ide-form-actions { margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
.faq-ide-main .form-hint-invalid,
.faq-ide-main .error { display: block; margin-top: 6px; color: #d4351c; font-size: 13px; }
.faq-ide-right { min-height: 560px; }
.faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.faq-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
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
function fncSelectDeptManageList() {
    var varFrom = document.getElementById("deptManage");
    varFrom.action = "<c:url value='/uss/umt/dpt/selectDeptManageList.do'/>";
    varFrom.submit();
}

function fncDeptManageInsert() {
    var varFrom = document.getElementById("deptManage");
    varFrom.action = "<c:url value='/uss/umt/dpt/addDeptManage.do'/>";

    if (confirm("<spring:message code='common.save.msg' />")) {
        if (typeof validateDeptManage == "function" && !validateDeptManage(varFrom)) {
            return;
        }
        varFrom.submit();
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="faq-ide-page">
    <div class="faq-ide-head">
        <div>
            <span class="faq-ide-kicker">Organization / Department</span>
            <h1>${pageTitle} <spring:message code="title.create" /></h1>
        </div>
        <span class="faq-ide-state">신규 작성</span>
    </div>

    <form:form id="deptManage" modelAttribute="deptManage" method="post" action="${pageContext.request.contextPath}/uss/umt/dpt/addDeptManage.do" cssClass="krds-form" onSubmit="fncDeptManageInsert(); return false;">
        <c:set var="inputTxt"><spring:message code="input.input" /></c:set>

        <div class="faq-ide-shell">
            <main class="rlms-ide-main faq-ide-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>부서 정보 편집</h2>
                        <span class="ide-prov-status new">등록</span>
                    </div>

                    <c:set var="title"><spring:message code="comUssUmt.deptManageRegist.deptName" /></c:set>
                    <div class="ide-form-row">
                        <label for="orgnztNm">${title} <span class="required-mark">*</span></label>
                        <form:input path="orgnztNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="200" />
                        <form:errors path="orgnztNm" cssClass="form-hint-invalid" />
                    </div>

                    <c:set var="title"><spring:message code="comUssUmt.deptManageRegist.deptDc" /></c:set>
                    <div class="ide-form-row">
                        <label for="orgnztDc">${title} <span class="required-mark">*</span></label>
                        <form:textarea path="orgnztDc" cssClass="krds-input" title="${title} ${inputTxt}" rows="10" />
                        <form:errors path="orgnztDc" cssClass="form-hint-invalid" />
                    </div>

                    <div class="ide-form-actions">
                        <button type="button" class="krds-btn secondary medium" onclick="fncSelectDeptManageList(); return false;" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></button>
                        <button type="submit" class="krds-btn primary medium" title="<spring:message code='button.create' /> <spring:message code='input.button' />"><spring:message code="button.create" /></button>
                    </div>
                </div>
            </main>

            <aside class="rlms-ide-right faq-ide-right">
                <h3 class="ide-related-tit">부서 작업정보</h3>
                <div class="faq-side-block">
                    <span class="faq-side-label">상태</span>
                    <p class="faq-side-text">신규 부서를 등록합니다.</p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label">부서 ID</span>
                    <p class="faq-side-text">저장 시 자동으로 발급됩니다.</p>
                </div>
            </aside>
        </div>

        <input type="hidden" name="orgnztId" value="" />
        <input type="hidden" name="searchCondition" value="<c:out value='${deptManageVO.searchCondition}'/>" />
        <input type="hidden" name="searchKeyword" value="<c:out value='${deptManageVO.searchKeyword}'/>" />
        <input type="hidden" name="pageIndex" value="<c:out value='${deptManageVO.pageIndex}'/>" />
    </form:form>
</div>
</lay:layout>
