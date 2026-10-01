<%
/**
 * @Class Name  : EgovRoleUpdate.java
 * @Description : EgovRoleUpdate jsp
 *
 * @author lee.m.j
 * @since 2009.03.11
 * @version 1.0
 * @see
 */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comCopSecRmt.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.update" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<validator:javascript formName="roleManage" staticJavascript="false" xhtml="true" cdata="false"/>
<style>
.role-manage-main { display: block; background: #fff; overflow: auto; }
.role-manage-main .role-ide-page { padding: 24px; }
.role-manage-left .ide-action.active { background: #e8edf9; color: #1f3974; font-weight: 700; }
.role-manage-left .ide-actions-group { padding: 8px 0; border-bottom: 1px solid #d1d3d8; background: #fff; }
.role-manage-left .ide-actions-group-label { margin: 0; padding: 6px 16px 4px; color: #5a6273; font-size: 12px; font-weight: 700; }
.role-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
.role-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.role-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
.role-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.role-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #fff4e5; color: #8a4b00; font-size: 13px; font-weight: 700; }
.role-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 520px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
.role-ide-center { min-height: 520px; border-right: 1px solid #d1d3d8; background: #fff; }
.role-ide-center .ide-context-pane { padding: 24px; }
.role-ide-center .ide-prov-head { align-items: center; flex-wrap: wrap; }
.role-ide-center .ide-prov-head h2 { font-size: 21px; }
.role-form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px 20px; }
.role-form-row { display: flex; flex-direction: column; gap: 7px; min-width: 0; }
.role-form-row.role-full { grid-column: 1 / -1; }
.role-form-row label { color: #1f2937; font-size: 14px; font-weight: 700; }
.role-form-row .krds-input,
.role-form-row textarea.krds-input,
.role-form-row select.krds-input { width: 100%; max-width: 100%; }
.role-form-row .krds-input,
.role-form-row select.krds-input { min-height: 40px; }
.role-form-row textarea.krds-input { min-height: 180px; resize: vertical; }
.role-readonly-value { min-height: 40px; display: flex; align-items: center; padding: 0 12px; border: 1px solid #d1d3d8; border-radius: 4px; background: #f4f6fa; color: #1f2937; font-weight: 700; }
.ide-form-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
.role-ide-right { min-height: 520px; }
.role-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.role-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.role-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
.required-mark { color: #d4351c; font-weight: 700; }
.form-hint-invalid,
.error { display: block; margin-top: 2px; color: #d4351c; font-size: 13px; }
@media (max-width: 1024px) {
  .role-ide-shell { grid-template-columns: 1fr; }
  .role-ide-center { border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .role-ide-right { min-height: 0; }
}
@media (max-width: 768px) {
  .rlms-ide-wrap.role-manage-wrap { position: static; display: block; }
  .role-manage-left { display: block; width: 100%; border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .role-manage-main .role-ide-page { padding: 18px; }
  .role-ide-head { align-items: flex-start; flex-direction: column; }
  .role-ide-state { align-self: flex-start; }
  .role-ide-center .ide-context-pane { padding: 18px; }
  .role-form-grid { grid-template-columns: 1fr; }
}
</style>
<script type="text/javaScript" language="javascript">
function fncSelectRoleList() {
    var varFrom = document.getElementById("roleManage");
    varFrom.action = "<c:url value='/sec/rmt/EgovRoleList.do'/>";
    varFrom.submit();
}

function fncRoleUpdate(form) {
    if(confirm("<spring:message code="common.save.msg" />")){
        if(!validateRoleManage(form)){
            return false;
        }else{
            form.submit();
        }
    }
}

function fncRoleDelete() {
    var varFrom = document.getElementById("frmIdDelete");
    varFrom.action = "<c:url value='/sec/rmt/EgovRoleDelete.do'/>";
    if(confirm("<spring:message code="common.delete.msg" />")){
        varFrom.submit();
    }else{
        return false;
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="rlms-ide-wrap role-manage-wrap">
    <aside class="rlms-ide-left role-manage-left">
        <div class="ide-actions-tit">시스템 관리</div>
        <nav class="ide-actions">
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">사용자 / 권한</h5>
                <a href="<c:url value='/uss/umt/EgovUserManage.do'/>" class="ide-action">업무사용자관리</a>
                <a href="<c:url value='/sec/ram/EgovAuthorList.do'/>" class="ide-action">권한관리</a>
                <a href="<c:url value='/sec/rmt/EgovRoleList.do'/>" class="ide-action active">역할관리</a>
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

    <main class="rlms-ide-main role-manage-main">
        <div class="role-ide-page">
            <div class="role-ide-head">
                <div>
                    <span class="role-ide-kicker">System / Role</span>
                    <h1>${pageTitle} <spring:message code="title.update" /></h1>
                </div>
                <span class="role-ide-state">수정 중</span>
            </div>

            <form:form id="roleManage" modelAttribute="roleManage" method="post" action="${pageContext.request.contextPath}/sec/rmt/EgovRoleUpdate.do" cssClass="krds-form" onSubmit="fncRoleUpdate(document.forms[0]); return false;">
                <input type="hidden" name="roleCode" value="<c:out value='${roleManage.roleCode}'/>"/>
                <input type="hidden" name="searchCondition" value="<c:out value='${roleManageVO.searchCondition}'/>"/>
                <input type="hidden" name="searchKeyword" value="<c:out value='${roleManageVO.searchKeyword}'/>"/>
                <input type="hidden" name="pageIndex" value="<c:out value='${roleManageVO.pageIndex}'/>"/>
                <c:set var="inputTxt"><spring:message code="input.input" /></c:set>

                <div class="role-ide-shell">
                    <section class="role-ide-center">
                        <div class="ide-context-pane">
                            <div class="ide-prov-head">
                                <h2>롤 정보 수정</h2>
                                <span class="ide-prov-status edit">수정</span>
                            </div>

                            <div class="role-form-grid">
                                <c:set var="title"><spring:message code="comCopSecRam.list.rollId" /></c:set>
                                <div class="role-form-row">
                                    <label>${title}</label>
                                    <div class="role-readonly-value"><c:out value="${roleManage.roleCode}"/></div>
                                </div>

                                <c:set var="title"><spring:message code="comCopSecRam.regist.rollType" /></c:set>
                                <div class="role-form-row">
                                    <label for="roleTyp">${title} <span class="required-mark">*</span></label>
                                    <form:select path="roleTyp" id="roleTyp" cssClass="krds-input">
                                        <form:options items="${cmmCodeDetailList}" itemValue="code" itemLabel="codeNm"/>
                                    </form:select>
                                    <form:errors path="roleTyp" cssClass="form-hint-invalid" />
                                </div>

                                <c:set var="title"><spring:message code="comCopSecRam.regist.rollNm" /></c:set>
                                <div class="role-form-row">
                                    <label for="roleNm">${title} <span class="required-mark">*</span></label>
                                    <form:input path="roleNm" id="roleNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="50" />
                                    <form:errors path="roleNm" cssClass="form-hint-invalid" />
                                </div>

                                <c:set var="title"><spring:message code="comCopSecRam.regist.rollSort" /></c:set>
                                <div class="role-form-row">
                                    <label for="roleSort">${title} <span class="required-mark">*</span></label>
                                    <form:input path="roleSort" id="roleSort" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="10" />
                                    <form:errors path="roleSort" cssClass="form-hint-invalid" />
                                </div>

                                <c:set var="title"><spring:message code="comCopSecRam.regist.rollPtn" /></c:set>
                                <div class="role-form-row role-full">
                                    <label for="rolePtn">${title} <span class="required-mark">*</span></label>
                                    <form:input path="rolePtn" id="rolePtn" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="200" />
                                    <form:errors path="rolePtn" cssClass="form-hint-invalid" />
                                </div>

                                <c:set var="title"><spring:message code="comCopSecRam.regist.rollDc" /></c:set>
                                <div class="role-form-row role-full">
                                    <label for="roleDc">${title} <span class="required-mark">*</span></label>
                                    <form:textarea path="roleDc" id="roleDc" cssClass="krds-input" title="${title} ${inputTxt}" rows="8" />
                                    <form:errors path="roleDc" cssClass="form-hint-invalid" />
                                </div>
                            </div>

                            <div class="ide-form-actions">
                                <button type="button" class="krds-btn secondary medium" onclick="fncSelectRoleList(); return false;" title="<spring:message code="button.list" /> <spring:message code="input.button" />"><spring:message code="button.list" /></button>
                                <button type="button" class="krds-btn danger medium" onclick="fncRoleDelete(); return false;" title="<spring:message code="button.delete" /> <spring:message code="input.button" />"><spring:message code="button.delete" /></button>
                                <button type="submit" class="krds-btn primary medium" title="<spring:message code="button.save" /> <spring:message code="input.button" />"><spring:message code="button.save" /></button>
                            </div>
                        </div>
                    </section>

                    <aside class="rlms-ide-right role-ide-right">
                        <h3 class="ide-related-tit">롤 작업정보</h3>
                        <div class="role-side-block">
                            <span class="role-side-label">롤 ID</span>
                            <p class="role-side-text"><c:out value="${roleManage.roleCode}"/></p>
                        </div>
                        <div class="role-side-block">
                            <span class="role-side-label">작업</span>
                            <p class="role-side-text">기존 롤 정보를 수정하거나 삭제할 수 있습니다.</p>
                        </div>
                    </aside>
                </div>
            </form:form>
        </div>
    </main>
</div>

<form id="frmIdDelete" name="frmDelete" method="post">
    <input type="hidden" name="roleCode" value="<c:out value='${roleManage.roleCode}'/>"/>
    <input type="hidden" name="searchCondition" value="<c:out value='${roleManageVO.searchCondition}'/>"/>
    <input type="hidden" name="searchKeyword" value="<c:out value='${roleManageVO.searchKeyword}'/>"/>
    <input type="hidden" name="pageIndex" value="<c:out value='${roleManageVO.pageIndex}'/>"/>
</form>
</lay:layout>
