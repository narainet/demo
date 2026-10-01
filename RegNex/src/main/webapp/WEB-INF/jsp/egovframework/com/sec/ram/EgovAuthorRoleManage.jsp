<%
/**
 * @Class Name : EgovAuthorRoleManage.java
 * @Description : EgovAuthorRoleManage.jsp
 * @Modification Information
 *
 * @author lee.m.j
 * @since 2009.03.21
 * @version 1.0
 * @see
 */
%>
<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comCopSecRam.authorRoleList.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.list" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
.author-role-main { display: block; background: #fff; overflow: auto; }
.author-role-page { min-width: 0; padding: 24px; }
.author-role-left .ide-action.active { background: #e8edf9; color: #1f3974; font-weight: 700; }
.author-role-left .ide-actions-group { padding: 8px 0; border-bottom: 1px solid #d1d3d8; background: #fff; }
.author-role-left .ide-actions-group-label { margin: 0; padding: 6px 16px 4px; color: #5a6273; font-size: 12px; font-weight: 700; }
.author-role-page .page-header { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin-bottom: 18px; padding: 0 0 14px; border-bottom: 1px solid #d8dde8; }
.author-role-page .page-header h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.role-total { color: #52617a; font-size: 14px; font-weight: 600; }
.role-total strong { color: #1f3974; }
.search-form.author-role-search { margin-bottom: 18px; padding: 16px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.author-role-search .form-group.inline { display: flex; align-items: flex-end; gap: 10px; flex-wrap: wrap; }
.author-role-search .form-conts { display: flex; flex-direction: column; gap: 6px; min-width: 240px; flex: 1 1 320px; }
.author-role-search .form-label { color: #333d4b; font-size: 13px; font-weight: 700; }
.author-role-search .krds-input { height: 40px; }
.author-role-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-left: auto; }
.krds-table.tbl-list .check-cell,
.krds-table.tbl-list .reg-cell { text-align: center; }
.krds-table.tbl-list .desc-cell { text-align: left; }
.krds-table.tbl-list .empty-row { height: 92px; color: #6b7280; text-align: center; }
.krds-pagination { margin-top: 18px; text-align: center; }
.role-check { width: 16px; height: 16px; accent-color: #1d56bc; }
.author-role-select { width: 100%; min-width: 86px; height: 36px; padding: 0 10px; border: 1px solid #c6cbd6; border-radius: 4px; background: #fff; color: #1f2937; font-size: 14px; }
@media (max-width: 768px) {
  .rlms-ide-wrap.author-role-wrap { position: static; display: block; }
  .author-role-left { display: block; width: 100%; border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .author-role-page { padding: 18px; }
  .author-role-page .page-header { align-items: flex-start; flex-direction: column; }
  .author-role-search .form-conts,
  .author-role-search .krds-input { width: 100%; }
  .author-role-actions { width: 100%; margin-left: 0; }
  .author-role-actions .krds-btn { flex: 1 1 120px; }
}
</style>
<script type="text/javaScript" language="javascript" defer="defer">
function fncCheckAll() {
    var checkField = document.listForm.delYn;
    if(document.listForm.checkAll.checked) {
        if(checkField) {
            if(checkField.length > 1) {
                for(var i=0; i < checkField.length; i++) {
                    checkField[i].checked = true;
                }
            } else {
                checkField.checked = true;
            }
        }
    } else {
        if(checkField) {
            if(checkField.length > 1) {
                for(var j=0; j < checkField.length; j++) {
                    checkField[j].checked = false;
                }
            } else {
                checkField.checked = false;
            }
        }
    }
}

function fncManageChecked() {

    var checkField = document.listForm.delYn;
    var checkId = document.listForm.checkId;
    var checkRegYn = document.listForm.regYn;
    var returnValue = "";
    var returnRegYns = "";
    var checkedCount = 0;
    var returnBoolean = false;

    if(checkField) {
        if(checkField.length > 1) {
            for(var i=0; i<checkField.length; i++) {
                if(checkField[i].checked) {
                    checkedCount++;
                    checkField[i].value = checkId[i].value;

                    if(returnValue == "") {
                        returnValue = checkField[i].value;
                        returnRegYns = checkRegYn[i].value;
                    }
                    else {
                        returnValue = returnValue + ";" + checkField[i].value;
                        returnRegYns = returnRegYns + ";" + checkRegYn[i].value;
                    }
                }
            }

            if(checkedCount > 0) {
                returnBoolean = true;
            } else {
                alert("<spring:message code="comCopSecRam.authorRoleList.validate.alert.noSelect" />");
                returnBoolean = false;
            }
        } else {
             if(document.listForm.delYn.checked == false) {
                alert("<spring:message code="comCopSecRam.authorRoleList.validate.alert.noSelect" />");
                returnBoolean = false;
            }
            else {
                returnValue = checkId.value;
                returnRegYns = checkRegYn.value;

                returnBoolean = true;
            }
        }
    } else {
        alert("<spring:message code="comCopSecRam.authorRoleList.validate.alert.noResult" />");
    }

    document.listForm.roleCodes.value = returnValue;
    document.listForm.regYns.value = returnRegYns;

    return returnBoolean;

}

function fncSelectAuthorRoleList() {
    document.listForm.searchCondition.value = "1";
    document.listForm.pageIndex.value = "1";
    document.listForm.action = "<c:url value='/sec/ram/EgovAuthorRoleList.do'/>";
    document.listForm.submit();
}

function fncSelectAuthorList(){
    location.href = "<c:url value='/sec/ram/EgovAuthorList.do'/>";
}

function fncSelectAuthorRole(roleCode) {
    document.listForm.roleCode.value = roleCode;
    document.listForm.action = "<c:url value='/sec/ram/EgovRole.do'/>";
    document.listForm.submit();
}

function fncAddAuthorRoleInsert() {
    if(fncManageChecked()) {
        if(confirm("<spring:message code="comCopSecRam.authorRoleList.validate.confirm.regist" />")) {
            document.listForm.action = "<c:url value='/sec/ram/EgovAuthorRoleInsert.do'/>";
            document.listForm.submit();
        }
    } else return;
}

function linkPage(pageNo){
    document.listForm.searchCondition.value = "1";
    document.listForm.pageIndex.value = pageNo;
    document.listForm.action = "<c:url value='/sec/ram/EgovAuthorRoleList.do'/>";
    document.listForm.submit();
}

function press(e) {
    var eventObj = e || window.event;
    if (eventObj.keyCode == 13) {
        if (eventObj.preventDefault) {
            eventObj.preventDefault();
        }
        fncSelectAuthorRoleList();
        return false;
    }
    return true;
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="rlms-ide-wrap author-role-wrap">
    <aside class="rlms-ide-left author-role-left">
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

    <main class="rlms-ide-main author-role-main">
        <form:form name="listForm" action="${pageContext.request.contextPath}/sec/ram/EgovAuthorRoleList.do" method="post" cssClass="krds-form" onsubmit="fncSelectAuthorRoleList(); return false;">
            <div class="author-role-page">
                <div class="page-header">
                    <h1>${pageTitle} <spring:message code="title.list" /></h1>
                    <span class="role-total">롤수 <strong><c:out value="${paginationInfo.totalRecordCount}"/></strong></span>
                </div>

                <div class="search-form author-role-search" title="<spring:message code="common.searchCondition.msg" />">
                    <div class="form-group inline">
                        <div class="form-conts">
                            <label class="form-label" for="searchKeyword"><spring:message code="comCopSecRam.regist.authorCode" /></label>
                            <input id="searchKeyword" class="krds-input" name="searchKeyword" type="text" title="<spring:message code="title.search" /> <spring:message code="input.input" />" value='<c:out value="${searchVO.searchKeyword}"/>' maxlength="155" onkeypress="return press(event);">
                        </div>
                        <div class="author-role-actions">
                            <button type="button" class="krds-btn medium primary" onclick="fncSelectAuthorRoleList(); return false;" title="<spring:message code="title.inquire" /> <spring:message code="input.button" />"><spring:message code="button.inquire" /></button>
                            <button type="button" class="krds-btn medium secondary" onclick="fncSelectAuthorList(); return false;" title="<spring:message code="button.list" /> <spring:message code="input.button" />"><spring:message code="button.list" /></button>
                            <button type="button" class="krds-btn medium secondary" onclick="fncAddAuthorRoleInsert(); return false;" title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></button>
                        </div>
                    </div>
                </div>

                <table class="krds-table tbl-list" summary="<spring:message code="common.summary.list" arguments="${pageTitle}" />">
                    <caption>${pageTitle} <spring:message code="title.list" /></caption>
                    <colgroup>
                        <col style="width: 6%;">
                        <col style="width: 15%;">
                        <col style="width: 20%;">
                        <col style="width: 12%;">
                        <col style="width: 10%;">
                        <col>
                        <col style="width: 12%;">
                        <col style="width: 10%;">
                    </colgroup>
                    <thead>
                        <tr>
                            <th scope="col" class="check-cell"><input type="checkbox" name="checkAll" class="role-check" onclick="fncCheckAll();" title="<spring:message code="input.selectAll.title" />"></th>
                            <th scope="col"><spring:message code="comCopSecRam.authorRoleList.rollId" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.authorRoleList.rollNm" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.authorRoleList.rollType" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.authorRoleList.rollSort" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.authorRoleList.rollDc" /></th>
                            <th scope="col"><spring:message code="table.regdate" /></th>
                            <th scope="col" class="reg-cell"><spring:message code="comCopSecRam.authorRoleList.regYn" /></th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:if test="${fn:length(authorRoleList) == 0}">
                            <tr>
                                <td colspan="8" class="empty-row"><spring:message code="common.nodata.msg" /></td>
                            </tr>
                        </c:if>
                        <c:forEach var="authorRole" items="${authorRoleList}" varStatus="status">
                            <tr>
                                <td class="check-cell">
                                    <input type="checkbox" name="delYn" class="role-check" title="선택">
                                    <input type="hidden" name="checkId" value="<c:out value='${authorRole.roleCode}'/>" />
                                </td>
                                <td><c:out value="${authorRole.roleCode}"/></td>
                                <td><c:out value="${authorRole.roleNm}"/></td>
                                <td><c:out value="${authorRole.roleTyp}"/></td>
                                <td><c:out value="${authorRole.roleSort}"/></td>
                                <td class="desc-cell"><c:out value="${authorRole.roleDc}"/></td>
                                <td><c:out value="${fn:substring(authorRole.creatDt,0,10)}"/></td>
                                <td class="reg-cell">
                                    <select name="regYn" class="author-role-select" title="<spring:message code="comCopSecRam.authorRoleList.regYn" />">
                                        <option value="Y" <c:if test="${authorRole.regYn == 'Y'}">selected</c:if>><spring:message code="comCopSecRam.authorRoleList.regY" /></option>
                                        <option value="N" <c:if test="${authorRole.regYn == 'N'}">selected</c:if>><spring:message code="comCopSecRam.authorRoleList.regN" /></option>
                                    </select>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>

                <c:if test="${!empty authorRoleManageVO.pageIndex }">
                    <div class="krds-pagination">
                        <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="linkPage"/>
                    </div>
                </c:if>

                <input type="hidden" name="roleCode"/>
                <input type="hidden" name="roleCodes"/>
                <input type="hidden" name="regYns"/>
                <input type="hidden" name="pageIndex" value="<c:out value='${authorRoleManageVO.pageIndex}'/>"/>
                <input type="hidden" name="authorCode" value="<c:out value='${authorRoleManageVO.searchKeyword}'/>"/>
                <input type="hidden" name="searchCondition" value="1">
            </div>
        </form:form>
    </main>
</div>
</lay:layout>
