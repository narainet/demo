<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comCopSecRam.title"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
.author-manage-main { display: block; background: #fff; overflow: auto; }
.author-list-page { min-width: 0; padding: 24px; }
.author-manage-left .ide-action.active { background: #e8edf9; color: #1f3974; font-weight: 700; }
.author-manage-left .ide-actions-group { padding: 8px 0; border-bottom: 1px solid #d1d3d8; background: #fff; }
.author-manage-left .ide-actions-group-label { margin: 0; padding: 6px 16px 4px; color: #5a6273; font-size: 12px; font-weight: 700; }
.author-list-page .page-header { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; margin-bottom: 18px; padding: 0 0 14px; border-bottom: 1px solid #d8dde8; }
.author-list-page .page-header h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.author-total { color: #52617a; font-size: 14px; font-weight: 600; }
.author-total strong { color: #1f3974; }
.search-form.author-search { margin-bottom: 18px; padding: 16px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.author-search .form-group.inline { display: flex; align-items: flex-end; gap: 10px; flex-wrap: wrap; }
.author-search .form-conts { display: flex; flex-direction: column; gap: 6px; min-width: 240px; flex: 1 1 320px; }
.author-search .form-label { color: #333d4b; font-size: 13px; font-weight: 700; }
.author-search .krds-input { height: 40px; }
.author-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-left: auto; }
.krds-table.tbl-list .check-cell,
.krds-table.tbl-list .role-cell { text-align: center; }
.krds-table.tbl-list .author-code-link { color: #1f3974; font-weight: 700; text-decoration: underline; text-underline-offset: 3px; }
.krds-table.tbl-list .empty-row { height: 92px; color: #6b7280; text-align: center; }
.krds-pagination { margin-top: 18px; text-align: center; }
.author-check { width: 16px; height: 16px; accent-color: #1d56bc; }
@media (max-width: 768px) {
  .rlms-ide-wrap.author-manage-wrap { position: static; display: block; }
  .author-manage-left { display: block; width: 100%; border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .author-list-page { padding: 18px; }
  .author-list-page .page-header { align-items: flex-start; flex-direction: column; }
  .author-search .form-conts,
  .author-search .krds-input { width: 100%; }
  .author-actions { width: 100%; margin-left: 0; }
  .author-actions .krds-btn { flex: 1 1 120px; }
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
                    checkField[i].value = checkId[i].value;
                    if(returnValue == "") {
                        returnValue = checkField[i].value;
                    } else {
                        returnValue = returnValue + ";" + checkField[i].value;
                    }
                    checkCount++;
                }
            }
            if(checkCount > 0) {
                returnBoolean = true;
            } else {
                alert("<spring:message code="comCopSecRam.validate.authorSelect" />");
                returnBoolean = false;
            }
        } else {
            if(document.listForm.delYn.checked == false) {
                alert("<spring:message code="comCopSecRam.validate.authorSelect" />");
                returnBoolean = false;
            } else {
                returnValue = checkId.value;
                returnBoolean = true;
            }
        }
    } else {
        alert("<spring:message code="comCopSecRam.validate.authorSelectResult" />");
    }

    document.listForm.authorCodes.value = returnValue;
    return returnBoolean;
}

function fncSelectAuthorList(pageNo){
    document.listForm.searchCondition.value = "1";
    document.listForm.pageIndex.value = pageNo;
    document.listForm.action = "<c:url value='/sec/ram/EgovAuthorList.do'/>";
    document.listForm.submit();
}

function fncSelectAuthor(author) {
    document.listForm.authorCode.value = author;
    document.listForm.action = "<c:url value='/sec/ram/EgovAuthor.do' />";
    document.listForm.submit();
}

function fncAddAuthorInsert() {
    location.href = "<c:url value='/sec/ram/EgovAuthorInsertView.do' />?searchCondition=<c:out value='${authorManageVO.searchCondition}' />&searchKeyword=<c:out value='${authorManageVO.searchKeyword}' />&pageIndex=<c:out value='${authorManageVO.pageIndex}' />";
}

function fncAuthorDeleteList() {
    if(fncManageChecked()) {
        if(confirm("<spring:message code="common.delete.msg" />")){
            document.listForm.action = "<c:url value='/sec/ram/EgovAuthorListDelete.do'/>";
            document.listForm.submit();
        }
    }
}

function fncSelectAuthorRole(author) {
    document.listForm.searchKeyword.value = author;
    document.listForm.action = "<c:url value='/sec/ram/EgovAuthorRoleList.do'/>";
    document.listForm.submit();
}

function linkPage(pageNo){
    document.listForm.searchCondition.value = "1";
    document.listForm.pageIndex.value = pageNo;
    document.listForm.action = "<c:url value='/sec/ram/EgovAuthorList.do'/>";
    document.listForm.submit();
}

function press(e) {
    var eventObj = e || window.event;
    if (eventObj.keyCode == 13) {
        if (eventObj.preventDefault) {
            eventObj.preventDefault();
        }
        fncSelectAuthorList("1");
        return false;
    }
    return true;
}

function fn_egov_onload() {
    var message = '<c:out value="${param.message}" />';
    if (!!message) {
        alert(message);
    }
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_onload();">
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
        <form:form name="listForm" action="${pageContext.request.contextPath}/sec/ram/EgovAuthorList.do" method="get" cssClass="krds-form" onsubmit="fncSelectAuthorList('1'); return false;">
            <div class="author-list-page">
                <div class="page-header">
                    <h1>${pageTitle}</h1>
                    <span class="author-total">권한수 <strong><c:out value="${paginationInfo.totalRecordCount}"/></strong></span>
                </div>

                <div class="search-form author-search" title="<spring:message code="common.searchCondition.msg" />">
                    <div class="form-group inline">
                        <div class="form-conts">
                            <label class="form-label" for="searchKeyword"><spring:message code="comCopSecRam.list.searchKeywordText" /></label>
                            <input id="searchKeyword" class="krds-input" name="searchKeyword" type="text" title="<spring:message code="title.search" /> <spring:message code="input.input" />" value='<c:out value="${authorManageVO.searchKeyword}"/>' maxlength="155" onkeypress="return press(event);">
                        </div>
                        <div class="author-actions">
                            <button type="button" class="krds-btn medium primary" onclick="fncSelectAuthorList('1'); return false;" title="<spring:message code="title.inquire" /> <spring:message code="input.button" />"><spring:message code="button.inquire" /></button>
                            <button type="button" class="krds-btn medium secondary" onclick="location.href='<c:url value='/sec/ram/EgovAuthorList.do' />'; return false;" title="<spring:message code="button.list" /> <spring:message code="input.button" />"><spring:message code="button.list" /></button>
                            <button type="button" class="krds-btn medium secondary" onclick="fncAddAuthorInsert(); return false;" title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></button>
                            <button type="button" class="krds-btn medium danger" onclick="fncAuthorDeleteList(); return false;" title="<spring:message code="title.delete" /> <spring:message code="input.button" />"><spring:message code="title.delete" /></button>
                        </div>
                    </div>
                </div>

                <table class="krds-table tbl-list" summary="<spring:message code="common.summary.list" arguments="${pageTitle}" />">
                    <caption>${pageTitle} <spring:message code="title.list" /></caption>
                    <colgroup>
                        <col style="width: 7%;">
                        <col style="width: 25%;">
                        <col style="width: 22%;">
                        <col>
                        <col style="width: 12%;">
                        <col style="width: 10%;">
                    </colgroup>
                    <thead>
                        <tr>
                            <th scope="col" class="check-cell"><input type="checkbox" name="checkAll" class="author-check" onclick="fncCheckAll();" title="<spring:message code="input.selectAll.title" />"></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.authorRollId" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.authorNm" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.authorDc" /></th>
                            <th scope="col"><spring:message code="table.regdate" /></th>
                            <th scope="col"><spring:message code="comCopSecRam.list.authorRoll" /></th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:if test="${fn:length(authorList) == 0}">
                            <tr>
                                <td colspan="6" class="empty-row"><spring:message code="common.nodata.msg" /></td>
                            </tr>
                        </c:if>
                        <c:forEach var="author" items="${authorList}" varStatus="status">
                            <tr>
                                <td class="check-cell">
                                    <input type="checkbox" name="delYn" class="author-check" title="선택">
                                    <input type="hidden" name="checkId" value="<c:out value='${author.authorCode}'/>" />
                                </td>
                                <td><a class="author-code-link" href="<c:url value='/sec/ram/EgovAuthor.do' />?authorCode=<c:out value='${author.authorCode}' />" onclick="fncSelectAuthor('<c:out value='${author.authorCode}' />'); return false;"><c:out value="${author.authorCode}"/></a></td>
                                <td><c:out value="${author.authorNm}"/></td>
                                <td class="left"><c:out value="${author.authorDc}"/></td>
                                <td><c:out value="${fn:substring(author.authorCreatDe,0,10)}"/></td>
                                <td class="role-cell">
                                    <button type="button" class="krds-btn small secondary" onclick="fncSelectAuthorRole('<c:out value='${author.authorCode}'/>'); return false;" title="<spring:message code="comCopSecRam.list.authorRoll" />">보기</button>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>

                <c:if test="${!empty authorManageVO.pageIndex }">
                    <div class="krds-pagination">
                        <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="linkPage"/>
                    </div>
                </c:if>

                <input type="hidden" name="authorCode"/>
                <input type="hidden" name="authorCodes"/>
                <input type="hidden" name="pageIndex" value="<c:out value='${authorManageVO.pageIndex}'/>"/>
                <input type="hidden" name="searchCondition" value="1"/>
            </div>
        </form:form>
    </main>
</div>
</lay:layout>
