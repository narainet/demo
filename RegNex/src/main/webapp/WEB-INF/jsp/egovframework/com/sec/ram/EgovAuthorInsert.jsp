<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comCopSecRam.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.create" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<validator:javascript formName="authorManage" staticJavascript="false" xhtml="true" cdata="false"/>
<style>
.author-manage-main { display: block; background: #fff; overflow: auto; }
.author-manage-main .author-ide-page { padding: 24px; }
.author-manage-left .ide-action.active { background: #e8edf9; color: #1f3974; font-weight: 700; }
.author-manage-left .ide-actions-group { padding: 8px 0; border-bottom: 1px solid #d1d3d8; background: #fff; }
.author-manage-left .ide-actions-group-label { margin: 0; padding: 6px 16px 4px; color: #5a6273; font-size: 12px; font-weight: 700; }
.author-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
.author-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.author-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
.author-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.author-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #e8edf9; color: #1f3974; font-size: 13px; font-weight: 700; }
.author-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 520px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
.author-ide-center { min-height: 520px; border-right: 1px solid #d1d3d8; background: #fff; }
.author-ide-center .ide-context-pane { padding: 24px; }
.author-ide-center .ide-prov-head { align-items: center; flex-wrap: wrap; }
.author-ide-center .ide-prov-head h2 { font-size: 21px; }
.author-form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px 20px; }
.author-form-row { display: flex; flex-direction: column; gap: 7px; min-width: 0; }
.author-form-row.author-full { grid-column: 1 / -1; }
.author-form-row label { color: #1f2937; font-size: 14px; font-weight: 700; }
.author-form-row .krds-input,
.author-form-row textarea.krds-input { width: 100%; max-width: 100%; }
.author-form-row .krds-input { min-height: 40px; }
.author-form-row textarea.krds-input { min-height: 220px; resize: vertical; }
.ide-form-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
.author-ide-right { min-height: 520px; }
.author-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.author-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.author-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
.required-mark { color: #d4351c; font-weight: 700; }
.form-hint-invalid,
.error { display: block; margin-top: 2px; color: #d4351c; font-size: 13px; }
@media (max-width: 1024px) {
  .author-ide-shell { grid-template-columns: 1fr; }
  .author-ide-center { border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .author-ide-right { min-height: 0; }
}
@media (max-width: 768px) {
  .rlms-ide-wrap.author-manage-wrap { position: static; display: block; }
  .author-manage-left { display: block; width: 100%; border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .author-manage-main .author-ide-page { padding: 18px; }
  .author-ide-head { align-items: flex-start; flex-direction: column; }
  .author-ide-state { align-self: flex-start; }
  .author-ide-center .ide-context-pane { padding: 18px; }
  .author-form-grid { grid-template-columns: 1fr; }
}
</style>
<script type="text/javaScript" language="javascript">
function fncSelectAuthorList() {
    var varFrom = document.getElementById("authorManage");
    varFrom.action = "<c:url value='/sec/ram/EgovAuthorList.do'/>";
    varFrom.submit();
}

function fncAuthorInsert(form) {
    if(confirm("<spring:message code="common.regist.msg" />")){
        if(!validateAuthorManage(form)){
            return false;
        }else{
            form.submit();
        }
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="rlms-ide-wrap author-manage-wrap">
    <aside class="rlms-ide-left author-manage-left">
        <div class="ide-actions-tit">시스템 관리</div>
        <nav class="ide-actions">
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">사용자 / 권한</h5>
                <a href="<c:url value='/uss/umt/EgovUserManage.do'/>" class="ide-action">업무사용자관리</a>
                <a href="<c:url value='/sec/ram/EgovAuthorList.do'/>" class="ide-action active">권한관리</a>
                <a href="<c:url value='/sec/rmt/EgovRoleList.do'/>" class="ide-action">역할관리</a>
                <a href="<c:url value='/sec/drm/EgovDeptAuthorList.do'/>" class="ide-action">부서권한관리</a>
            </div>
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">메뉴 / 프로그램</h5>
                <a href="<c:url value='/sym/prm/EgovProgramListManageSelect.do'/>" class="ide-action">프로그램관리</a>
                <a href="<c:url value='/sym/mnu/mpm/EgovMenuManageSelect.do'/>" class="ide-action">메뉴목록 관리</a>
                <a href="<c:url value='/sym/mnu/mpm/EgovMenuListSelect.do'/>" class="ide-action">메뉴 생성</a>
                <a href="<c:url value='/sym/mnu/mcm/EgovMenuCreatManageSelect.do'/>" class="ide-action">메뉴생성 관리</a>
                <a href="<c:url value='/sym/mnu/stm/EgovSiteMapng.do'/>" class="ide-action">사이트맵</a>
            </div>
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">코드 / 설정</h5>
                <a href="<c:url value='/sym/ccm/ccm/EgovCcmCmmnCodeManage.do'/>" class="ide-action">공통코드</a>
            </div>
        </nav>
    </aside>

    <main class="rlms-ide-main author-manage-main">
        <div class="author-ide-page">
            <div class="author-ide-head">
                <div>
                    <span class="author-ide-kicker">System / Authority</span>
                    <h1>${pageTitle} <spring:message code="title.create" /></h1>
                </div>
                <span class="author-ide-state">신규 작성</span>
            </div>

            <form:form id="authorManage" modelAttribute="authorManage" action="${pageContext.request.contextPath}/sec/ram/EgovAuthorInsert.do" method="post" cssClass="krds-form" onSubmit="fncAuthorInsert(document.forms[0]); return false;">
                <input type="hidden" name="searchCondition" id="searchCondition" value="<c:out value='${authorManage.searchCondition}' />">
                <input type="hidden" name="searchKeyword" id="searchKeyword" value="<c:out value='${authorManage.searchKeyword}' />">
                <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${authorManage.pageIndex}' />">
                <c:set var="inputTxt"><spring:message code="input.input" /></c:set>

                <div class="author-ide-shell">
                    <section class="author-ide-center">
                        <div class="ide-context-pane">
                            <div class="ide-prov-head">
                                <h2>권한 정보 편집</h2>
                                <span class="ide-prov-status new">등록</span>
                            </div>

                            <div class="author-form-grid">
                                <c:set var="title"><spring:message code="comCopSecRam.regist.authorCode" /></c:set>
                                <div class="author-form-row">
                                    <label for="authorCode">${title} <span class="required-mark">*</span></label>
                                    <form:input path="authorCode" id="authorCode" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="30" />
                                    <form:errors path="authorCode" cssClass="form-hint-invalid" />
                                </div>

                                <c:set var="title"><spring:message code="comCopSecRam.regist.authorNm" /></c:set>
                                <div class="author-form-row">
                                    <label for="authorNm">${title} <span class="required-mark">*</span></label>
                                    <form:input path="authorNm" id="authorNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="60" />
                                    <form:errors path="authorNm" cssClass="form-hint-invalid" />
                                </div>

                                <c:set var="title"><spring:message code="comCopSecRam.regist.authorDc" /></c:set>
                                <div class="author-form-row author-full">
                                    <label for="authorDc">${title}</label>
                                    <form:textarea path="authorDc" id="authorDc" cssClass="krds-input" title="${title} ${inputTxt}" rows="10" />
                                    <form:errors path="authorDc" cssClass="form-hint-invalid" />
                                </div>
                            </div>

                            <div class="ide-form-actions">
                                <button type="button" class="krds-btn secondary medium" onclick="fncSelectAuthorList(); return false;" title="<spring:message code="button.list" /> <spring:message code="input.button" />"><spring:message code="button.list" /></button>
                                <button type="submit" class="krds-btn primary medium" title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></button>
                            </div>
                        </div>
                    </section>

                    <aside class="rlms-ide-right author-ide-right">
                        <h3 class="ide-related-tit">권한 작업정보</h3>
                        <div class="author-side-block">
                            <span class="author-side-label">상태</span>
                            <p class="author-side-text">신규 권한을 등록합니다.</p>
                        </div>
                        <div class="author-side-block">
                            <span class="author-side-label">권한 코드</span>
                            <p class="author-side-text">역할과 사용자 권한에 연결되는 기준 코드입니다.</p>
                        </div>
                    </aside>
                </div>
            </form:form>
        </div>
    </main>
</div>
</lay:layout>
