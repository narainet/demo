<%
/**
 * @Class Name : EgovRoleManage.java
 * @Description : EgovRoleManage jsp
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
<c:set var="pageTitle"><spring:message code="comCopSecRmt.title"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
.role-manage-main { display: block; background: #fff; overflow: auto; }
.role-list-page { min-width: 0; padding: 24px; }
.role-manage-left .ide-action.active { background: #e8edf9; color: #1f3974; font-weight: 700; }
.role-manage-left .ide-actions-group { padding: 8px 0; border-bottom: 1px solid #d1d3d8; background: #fff; }
.role-manage-left .ide-actions-group-label { margin: 0; padding: 6px 16px 4px; color: #5a6273; font-size: 12px; font-weight: 700; }
.role-list-page .page-header { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin-bottom: 18px; padding: 0 0 14px; border-bottom: 1px solid #d8dde8; }
.role-list-page .page-header h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.role-total { color: #52617a; font-size: 14px; font-weight: 600; }
.role-total strong { color: #1f3974; }
.search-form.role-search { margin-bottom: 18px; padding: 16px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.role-search .form-group.inline { display: flex; align-items: flex-end; gap: 10px; flex-wrap: wrap; }
.role-search .form-conts { display: flex; flex-direction: column; gap: 6px; min-width: 240px; flex: 1 1 320px; }
.role-search .form-label { color: #333d4b; font-size: 13px; font-weight: 700; }
.role-search .krds-input { height: 40px; }
.role-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-left: auto; }
.krds-table.tbl-list .check-cell,
.krds-table.tbl-list .detail-cell { text-align: center; }
.krds-table.tbl-list .role-code-link { color: #1f3974; font-weight: 700; text-decoration: underline; text-underline-offset: 3px; }
.krds-table.tbl-list .desc-cell,
.krds-table.tbl-list .name-cell { text-align: left; }
.krds-table.tbl-list .empty-row { height: 92px; color: #6b7280; text-align: center; }
.krds-pagination { margin-top: 18px; text-align: center; }
.role-check { width: 16px; height: 16px; accent-color: #1d56bc; }
@media (max-width: 768px) {
  .rlms-ide-wrap.role-manage-wrap { position: static; display: block; }
  .role-manage-left { display: block; width: 100%; border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .role-list-page { padding: 18px; }
  .role-list-page .page-header { align-items: flex-start; flex-direction: column; }
  .role-search .form-conts,
  .role-search .krds-input { width: 100%; }
  .role-actions { width: 100%; margin-left: 0; }
  .role-actions .krds-btn { flex: 1 1 120px; }
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
    var returnValue = "";
    var returnBoolean = false;
    var checkCount = 0;

    if(checkField) {
        if(checkField.length > 1) {
            for(var i=0; i<checkField.length; i++) {
                if(checkField[i].checked) {
                    checkCount++;
                    checkField[i].value = checkId[i].value;
                    if(returnValue == "") {
                        returnValue = checkField[i].value;
                    } else {
                        returnValue = returnValue + ";" + checkField[i].value;
                    }
                }
            }
            if(checkCount > 0) {
                returnBoolean = true;
            } else {
                alert("<spring:message code="comCopSecRmt.validate.groupSelect"/>");
                returnBoolean = false;
            }
        } else {
            if(document.listForm.delYn.checked == false) {
                alert("<spring:message code="comCopSecRmt.validate.groupSelect"/>");
                returnBoolean = false;
            }
            else {
                returnValue = checkId.value;
                returnBoolean = true;
            }
        }
    } else {
        alert("<spring:message code="comCopSecRmt.validate.groupSelectResult"/>");
    }

    document.listForm.roleCodes.value = returnValue;
    return returnBoolean;
}

function fncSelectRoleList(pageNo){
    document.listForm.searchCondition.value = "1";
    document.listForm.pageIndex.value = pageNo;
    document.listForm.action = "<c:url value='/sec/rmt/EgovRoleList.do'/>";
    document.listForm.submit();
}

function fncSelectRole(roleCode) {
    document.listForm.roleCode.value = roleCode;
    document.listForm.action = "<c:url value='/sec/rmt/EgovRole.do'/>";
    document.listForm.submit();
}

function fncAddRoleInsert() {
    location.href = "<c:url value='/sec/rmt/EgovRoleInsertView.do'/>";
}

function fncRoleListDelete() {
    if(fncManageChecked()) {
        if(confirm("<spring:message code="common.delete.msg" />")) {
            document.listForm.action = "<c:url value='/sec/rmt/EgovRoleListDelete.do'/>";
            document.listForm.submit();
        }
    }
}

function linkPage(pageNo){
    document.listForm.searchCondition.value = "1";
    document.listForm.pageIndex.value = pageNo;
    document.listForm.action = "<c:url value='/sec/rmt/EgovRoleList.do'/>";
    document.listForm.submit();
}

// URL 권한설정(역할/권한) 변경분을 재시작 없이 즉시 적용 (eGov reload())
function fncReloadSecurity(){
    if(!confirm("변경한 URL 권한설정을 지금 적용할까요?\n(앱 재시작 없이 즉시 반영됩니다)")) return;
    fetch("<c:url value='/rlms/mgr/reloadSecurity.do'/>", { method: "POST" })
        .then(function(r){ return r.json(); })
        .then(function(res){ alert(res.message || (res.success ? "적용되었습니다." : "적용 실패")); })
        .catch(function(e){ alert("요청 실패: " + e); });
}

function press(e) {
    var eventObj = e || window.event;
    if (eventObj.keyCode == 13) {
        if (eventObj.preventDefault) {
            eventObj.preventDefault();
        }
        fncSelectRoleList("1");
        return false;
    }
    return true;
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
        <form:form name="listForm" action="${pageContext.request.contextPath}/sec/rmt/EgovRoleList.do" method="post" cssClass="krds-form" onsubmit="fncSelectRoleList('1'); return false;">
            <div class="role-list-page">
                <div class="page-header">
                    <h1>${pageTitle}</h1>
                    <span class="role-total">롤수 <strong><c:out value="${paginationInfo.totalRecordCount}"/></strong></span>
                </div>

                <div class="search-form role-search" title="<spring:message code="common.searchCondition.msg" />">
                    <div class="form-group inline">
                        <div class="form-conts">
                            <label class="form-label" for="searchKeyword"><spring:message code="comCopSecRmt.searchCondition.searchKeywordText" /></label>
                            <input id="searchKeyword" class="krds-input" name="searchKeyword" type="text" title="<spring:message code="title.search" /> <spring:message code="input.input" />" value='<c:out value="${roleManageVO.searchKeyword}"/>' maxlength="155" onkeypress="return press(event);">
                        </div>
                        <div class="role-actions">
                            <button type="button" class="krds-btn medium primary" onclick="fncSelectRoleList('1'); return false;" title="<spring:message code="title.inquire" /> <spring:message code="input.button" />"><spring:message code="button.inquire" /></button>
                            <button type="button" class="krds-btn medium secondary" onclick="fncAddRoleInsert(); return false;" title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></button>
                            <button type="button" class="krds-btn medium danger" onclick="fncRoleListDelete(); return false;" title="<spring:message code="title.delete" /> <spring:message code="input.button" />"><spring:message code="title.delete" /></button>
                            <button type="button" class="krds-btn medium" style="background:#f57c00;border-color:#f57c00;color:#fff;" onclick="fncReloadSecurity(); return false;" title="변경한 URL 권한설정을 재시작 없이 즉시 적용">보안 적용</button>
                        </div>
                    </div>
                </div>

                <table class="krds-table tbl-list" summary="<spring:message code="common.summary.list" arguments="${pageTitle}" />">
                    <caption>${pageTitle} <spring:message code="title.list" /></caption>
                    <colgroup>
                        <col style="width: 6%;">
                        <col style="width: 15%;">
                        <col style="width: 22%;">
                        <col style="width: 10%;">
                        <col style="width: 10%;">
                        <col>
                        <col style="width: 12%;">
                        <col style="width: 10%;">
                    </colgroup>
                    <thead>
                        <tr>
                            <th scope="col" class="check-cell"><input type="checkbox" name="checkAll" class="role-check" onclick="fncCheckAll();" title="<spring:message code="input.selectAll.title" />"></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.rollId" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.rollNm" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.rollType" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.rollSort" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.rollDc" /></th>
                            <th scope="col"><spring:message code="table.regdate" /></th>
                            <th scope="col" class="detail-cell"><spring:message code="title.detail" /></th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:if test="${fn:length(roleList) == 0}">
                            <tr>
                                <td colspan="8" class="empty-row"><spring:message code="common.nodata.msg" /></td>
                            </tr>
                        </c:if>
                        <c:forEach var="role" items="${roleList}" varStatus="status">
                            <tr>
                                <td class="check-cell">
                                    <input type="checkbox" name="delYn" class="role-check" title="선택">
                                    <input type="hidden" name="checkId" value="<c:out value='${role.roleCode}'/>" />
                                </td>
                                <td><a class="role-code-link" href="<c:url value='/sec/rmt/EgovRole.do'/>?roleCode=<c:out value='${role.roleCode}'/>" onclick="fncSelectRole('<c:out value='${role.roleCode}'/>'); return false;"><c:out value="${role.roleCode}"/></a></td>
                                <td class="name-cell"><c:out value="${role.roleNm}"/></td>
                                <td><c:out value="${role.roleTyp}"/></td>
                                <td><c:out value="${role.roleSort}"/></td>
                                <td class="desc-cell"><c:out value="${role.roleDc}"/></td>
                                <td><c:out value="${fn:substring(role.roleCreatDe,0,10)}"/></td>
                                <td class="detail-cell">
                                    <button type="button" class="krds-btn small secondary" onclick="fncSelectRole('<c:out value='${role.roleCode}'/>'); return false;" title="<spring:message code="title.detail" />"><spring:message code="title.detail" /></button>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>

                <c:if test="${!empty roleManageVO.pageIndex }">
                    <div class="krds-pagination">
                        <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="linkPage"/>
                    </div>
                </c:if>

                <input type="hidden" name="roleCode"/>
                <input type="hidden" name="roleCodes"/>
                <input type="hidden" name="pageIndex" value="<c:out value='${roleManageVO.pageIndex}'/>"/>
                <input type="hidden" name="searchCondition" value="1"/>
            </div>
        </form:form>
    </main>
</div>
</lay:layout>
