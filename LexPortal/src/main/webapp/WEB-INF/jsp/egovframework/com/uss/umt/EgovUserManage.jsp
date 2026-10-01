<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comUssUmt.deptUserManage.title"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
.user-manage-main { background: #fff; }
.user-manage-main .user-list-page { min-width: 0; padding: 24px; }
.user-manage-left .ide-action.active { background: #e8edf9; color: #1f3974; font-weight: 700; }
.user-manage-left .ide-actions-group { padding: 8px 0; border-bottom: 1px solid #d1d3d8; background: #fff; }
.user-manage-left .ide-actions-group-label { margin: 0; padding: 6px 16px 4px; color: #5a6273; font-size: 12px; font-weight: 700; }
.user-list-page { min-width: 0; }
.user-list-page .page-header { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin-bottom: 18px; padding: 0 0 14px; border-bottom: 1px solid #d8dde8; }
.user-list-page .page-header h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.user-total { color: #52617a; font-size: 14px; font-weight: 600; }
.user-total strong { color: #1f3974; }
.search-form.user-search { margin-bottom: 18px; padding: 16px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.user-search .form-group.inline { display: flex; align-items: flex-end; gap: 14px 18px; flex-wrap: wrap; }
.user-search .form-conts { display: flex; flex-direction: column; gap: 6px; min-width: 150px; }
.user-search .form-conts.keyword { flex: 1 1 260px; }
.user-search .form-label { color: #333d4b; font-size: 13px; font-weight: 700; }
.user-search select.krds-input { min-width: 140px; }
.user-search .krds-input { height: 40px; }
.user-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-left: auto; }
.krds-table.tbl-list .check-cell { text-align: center; }
.krds-table.tbl-list .user-id-link { color: #1f3974; font-weight: 700; text-decoration: underline; text-underline-offset: 3px; }
.krds-table.tbl-list .empty-row { height: 92px; color: #6b7280; text-align: center; }
.krds-pagination { margin-top: 18px; text-align: center; }
.user-check { width: 16px; height: 16px; accent-color: #1d56bc; }
@media (max-width: 768px) {
  .rlms-ide-wrap.user-manage-wrap { position: static; display: block; }
  .user-manage-left { display: block; width: 100%; border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .user-manage-main .user-list-page { padding: 18px; }
  .user-list-page .page-header { align-items: flex-start; flex-direction: column; }
  .user-search .form-conts,
  .user-search .form-conts.keyword,
  .user-search select.krds-input,
  .user-search .krds-input { width: 100%; }
  .user-actions { width: 100%; margin-left: 0; }
  .user-actions .krds-btn { flex: 1 1 120px; }
}
</style>
<script type="text/javaScript" language="javascript" defer="defer">
function fncCheckAll() {
    var checkField = document.listForm.checkField;
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

function fnDeleteUser() {
    var checkField = document.listForm.checkField;
    var id = document.listForm.checkId;
    var checkedIds = "";
    var checkedCount = 0;
    if(checkField) {
        if(checkField.length > 1) {
            for(var i=0; i < checkField.length; i++) {
                if(checkField[i].checked) {
                    checkedIds += ((checkedCount==0? "" : ",") + id[i].value);
                    checkedCount++;
                }
            }
        } else {
            if(checkField.checked) {
                checkedIds = id.value;
            }
        }
    }
    if(checkedIds.length > 0) {
        if(confirm("<spring:message code="common.delete.msg" />")){
            document.listForm.checkedIdForDel.value=checkedIds;
            document.listForm.action = "<c:url value='/uss/umt/EgovUserDelete.do'/>";
            document.listForm.submit();
        }
    }
}

function fnSelectUser(id) {
    document.listForm.selectedId.value = id;
    array = id.split(":");
    if(array[0] == "") {
    } else {
        userTy = array[0];
        userId = array[1];
    }
    document.listForm.selectedId.value = userId;
    document.listForm.action = "<c:url value='/uss/umt/EgovUserSelectUpdtView.do'/>";
    document.listForm.submit();
}

function fnAddUserView() {
    document.listForm.action = "<c:url value='/uss/umt/EgovUserInsertView.do'/>";
    document.listForm.submit();
}

function fnLinkPage(pageNo){
    document.listForm.pageIndex.value = pageNo;
    document.listForm.action = "<c:url value='/uss/umt/EgovUserManage.do'/>";
    document.listForm.submit();
}

function fnSearch(){
    document.listForm.pageIndex.value = 1;
    document.listForm.action = "<c:url value='/uss/umt/EgovUserManage.do'/>";
    document.listForm.submit();
}

function press(e) {
    var eventObj = e || window.event;
    if (eventObj.keyCode == 13) {
        if (eventObj.preventDefault) {
            eventObj.preventDefault();
        }
        fnSearch();
        return false;
    }
    return true;
}

<c:if test="${!empty resultMsg}">alert("<spring:message code="${resultMsg}" />");</c:if>
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="rlms-ide-wrap user-manage-wrap">
    <aside class="rlms-ide-left user-manage-left">
        <div class="ide-actions-tit">시스템 관리</div>
        <nav class="ide-actions">
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">사용자 / 권한</h5>
                <a href="<c:url value='/uss/umt/EgovUserManage.do'/>" class="ide-action active">업무사용자관리</a>
                <a href="<c:url value='/sec/ram/EgovAuthorList.do'/>" class="ide-action">권한관리</a>
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

    <main class="rlms-ide-main user-manage-main">
<form name="listForm" action="<c:url value='/uss/umt/EgovUserManage.do'/>" method="post" class="krds-form" onsubmit="fnSearch(); return false;">
    <div class="user-list-page">
        <div class="page-header">
            <h1>${pageTitle}</h1>
            <span class="user-total">사용자수 <strong><c:out value="${paginationInfo.totalRecordCount}"/></strong></span>
        </div>

        <div class="search-form user-search" title="<spring:message code="common.searchCondition.msg" />">
            <div class="form-group inline">
                <div class="form-conts">
                    <label class="form-label" for="sbscrbSttus"><spring:message code="comUssUmt.userManageSsearch.sbscrbSttusTitle" /></label>
                    <select class="krds-input" name="sbscrbSttus" id="sbscrbSttus" title="<spring:message code="comUssUmt.userManageSsearch.sbscrbSttusTitle" />">
                        <option value="0" <c:if test="${empty userSearchVO.sbscrbSttus || userSearchVO.sbscrbSttus == '0'}">selected="selected"</c:if>><spring:message code="comUssUmt.userManageSsearch.sbscrbSttusAll" /></option>
                        <option value="A" <c:if test="${userSearchVO.sbscrbSttus == 'A'}">selected="selected"</c:if>><spring:message code="comUssUmt.userManageSsearch.sbscrbSttusA" /></option>
                        <option value="D" <c:if test="${userSearchVO.sbscrbSttus == 'D'}">selected="selected"</c:if>><spring:message code="comUssUmt.userManageSsearch.sbscrbSttusD" /></option>
                        <option value="P" <c:if test="${userSearchVO.sbscrbSttus == 'P'}">selected="selected"</c:if>><spring:message code="comUssUmt.userManageSsearch.sbscrbSttusP" /></option>
                    </select>
                </div>

                <div class="form-conts">
                    <label class="form-label" for="searchCondition">검색조건</label>
                    <select class="krds-input" name="searchCondition" id="searchCondition" title="<spring:message code="comUssUmt.userManageSsearch.searchConditioTitle" />">
                        <option value="0" <c:if test="${userSearchVO.searchCondition == '0'}">selected="selected"</c:if>><spring:message code="comUssUmt.userManageSsearch.searchConditionId" /></option>
                        <option value="1" <c:if test="${empty userSearchVO.searchCondition || userSearchVO.searchCondition == '1'}">selected="selected"</c:if>><spring:message code="comUssUmt.userManageSsearch.searchConditionName" /></option>
                    </select>
                </div>

                <div class="form-conts keyword">
                    <label class="form-label" for="searchKeyword"><spring:message code="title.search" /></label>
                    <input id="searchKeyword" class="krds-input" name="searchKeyword" type="text" title="<spring:message code="title.search" /> <spring:message code="input.input" />" value='<c:out value="${userSearchVO.searchKeyword}"/>' maxlength="255" onkeypress="return press(event);">
                </div>

                <div class="user-actions">
                    <button type="button" class="krds-btn medium primary" onclick="fnSearch(); return false;" title="<spring:message code="title.inquire" /> <spring:message code="input.button" />"><spring:message code="button.inquire" /></button>
                    <button type="button" class="krds-btn medium secondary" onclick="fnAddUserView(); return false;" title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></button>
                    <button type="button" class="krds-btn medium danger" onclick="fnDeleteUser(); return false;" title="<spring:message code="title.delete" /> <spring:message code="input.button" />"><spring:message code="title.delete" /></button>
                </div>
            </div>
        </div>

        <table class="krds-table tbl-list" summary="<spring:message code="common.summary.list" arguments="${pageTitle}" />">
            <caption>${pageTitle} <spring:message code="title.list" /></caption>
            <colgroup>
                <col style="width: 7%;">
                <col style="width: 6%;">
                <col style="width: 15%;">
                <col style="width: 14%;">
                <col>
                <col style="width: 15%;">
                <col style="width: 12%;">
                <col style="width: 12%;">
            </colgroup>
            <thead>
                <tr>
                    <th scope="col"><spring:message code="table.num" /></th>
                    <th scope="col" class="check-cell"><input type="checkbox" name="checkAll" class="user-check" onclick="fncCheckAll();" title="<spring:message code="input.selectAll.title" />"></th>
                    <th scope="col"><spring:message code="comUssUmt.userManageList.id" /></th>
                    <th scope="col"><spring:message code="comUssUmt.userManageList.name" /></th>
                    <th scope="col"><spring:message code="comUssUmt.userManageList.email" /></th>
                    <th scope="col"><spring:message code="comUssUmt.userManageList.phone" /></th>
                    <th scope="col"><spring:message code="table.regdate" /></th>
                    <th scope="col"><spring:message code="comUssUmt.userManageList.sbscrbSttus" /></th>
                </tr>
            </thead>
            <tbody>
                <c:if test="${fn:length(resultList) == 0}">
                    <tr>
                        <td colspan="8" class="empty-row"><spring:message code="common.nodata.msg" /></td>
                    </tr>
                </c:if>
                <c:forEach var="result" items="${resultList}" varStatus="status">
                    <tr>
                        <td><c:out value="${status.count}"/></td>
                        <td class="check-cell">
                            <input type="checkbox" name="checkField" class="user-check" title="선택"/>
                            <input name="checkId" type="hidden" value="<c:out value='${result.userTy}'/>:<c:out value='${result.uniqId}'/>"/>
                        </td>
                        <td><a class="user-id-link" href="<c:url value='/uss/umt/EgovUserSelectUpdtView.do'/>?selectedId=<c:out value="${result.uniqId}"/>" onclick="fnSelectUser('<c:out value="${result.userTy}"/>:<c:out value="${result.uniqId}"/>'); return false;"><c:out value="${result.userId}"/></a></td>
                        <td><c:out value="${result.userNm}"/></td>
                        <td class="left"><c:out value="${result.emailAdres}"/></td>
                        <td><c:out value="${result.areaNo}"/>)<c:out value="${result.middleTelno}"/>-<c:out value="${result.endTelno}"/></td>
                        <td><c:out value="${fn:substring(result.sbscrbDe,0,10)}"/></td>
                        <td>
                            <c:forEach var="emplyrSttusCode_result" items="${emplyrSttusCode_result}" varStatus="status">
                                <c:if test="${result.sttus == emplyrSttusCode_result.code}"><c:out value="${emplyrSttusCode_result.codeNm}"/></c:if>
                            </c:forEach>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>

        <div class="krds-pagination">
            <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
        </div>

        <input name="selectedId" type="hidden" />
        <input name="checkedIdForDel" type="hidden" />
        <input name="pageIndex" type="hidden" value="<c:out value='${userSearchVO.pageIndex}'/>"/>
    </div>
</form>
    </main>
</div>
</lay:layout>
