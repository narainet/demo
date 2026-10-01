<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- FAQ 관리 목록 (편집계 전용 — URL 가드 L2.6). 사용자 열람은 selectFaqUserList.do(아코디언)로 분리(2026-07-09) --%>
<c:set var="pageTitle" value="FAQ 관리" />
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_egov_init() {
    if (document.faqForm && document.faqForm.searchCnd) {
        document.faqForm.searchCnd.focus();
    }
}

function fn_egov_select_linkPage(pageNo) {
    document.faqForm.pageIndex.value = pageNo;
    document.faqForm.action = "<c:url value='/uss/olh/faq/selectFaqList.do'/>";
    document.faqForm.submit();
}

function fn_egov_search_faq() {
    document.faqForm.pageIndex.value = 1;
    document.faqForm.action = "<c:url value='/uss/olh/faq/selectFaqList.do'/>";
    document.faqForm.submit();
}

function fn_egov_inquire_faqdetail(faqId) {
    document.faqForm.faqId.value = faqId;
    document.faqForm.action = "<c:url value='/uss/olh/faq/selectFaqDetail.do'/>";
    document.faqForm.submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
    <h1>FAQ 관리</h1>
    <p class="page-desc">자주 묻는 질문을 등록하고 관리합니다.</p>
</div>

<form name="faqForm" class="krds-form" action="<c:url value='/uss/olh/faq/selectFaqList.do'/>" method="post" onsubmit="fn_egov_search_faq(); return false;">
    <input name="faqId" type="hidden" value="<c:out value='${searchVO.faqId}'/>">
    <input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>">

    <div class="search-form" title="<spring:message code='common.searchCondition.msg' />">
        <div class="form-group inline">
            <label class="form-label" for="searchFaqCode">카테고리</label>
            <select id="searchFaqCode" name="searchFaqCode" class="krds-select" title="카테고리 선택">
                <option value="">전체</option>
                <c:forEach var="cd" items="${faqCodeList}">
                <option value="${cd.code}" <c:if test="${searchVO.searchFaqCode eq cd.code}">selected="selected"</c:if>><c:out value="${cd.codeNm}"/></option>
                </c:forEach>
            </select>

            <label class="form-label" for="searchCnd">검색조건</label>
            <select id="searchCnd" name="searchCnd" class="krds-select" title="검색조건 선택">
                <option value="0" <c:if test="${searchVO.searchCnd == '0'}">selected="selected"</c:if>>질문제목</option>
            </select>

            <label class="form-label" for="searchWrd">검색어</label>
            <input id="searchWrd" name="searchWrd" class="krds-input" type="text" value="<c:out value='${searchVO.searchWrd}'/>" maxlength="155" title="검색어 입력">

            <button type="submit" class="krds-btn primary medium">조회</button>
            <a href="<c:url value='/uss/olh/faq/insertFaqView.do'/>" class="krds-btn secondary medium">등록</a>
        </div>
    </div>

    <div class="list-total">
        전체 <strong><c:out value="${paginationInfo.totalRecordCount}" /></strong>건
    </div>

    <table class="krds-table tbl-list">
        <caption>FAQ 관리 목록</caption>
        <colgroup>
            <col style="width: 8%;">
            <col style="width: 14%;">
            <col>
            <col style="width: 12%;">
            <col style="width: 16%;">
        </colgroup>
        <thead>
            <tr>
                <th scope="col">번호</th>
                <th scope="col">카테고리</th>
                <th scope="col">질문제목</th>
                <th scope="col">조회수</th>
                <th scope="col">등록일자</th>
            </tr>
        </thead>
        <tbody>
            <c:if test="${fn:length(resultList) == 0}">
                <tr>
                    <td colspan="5" class="empty-row"><spring:message code="common.nodata.msg" /></td>
                </tr>
            </c:if>
            <c:forEach items="${resultList}" var="resultInfo" varStatus="status">
                <c:url var="faqDetailUrl" value="/uss/olh/faq/selectFaqDetail.do">
                    <c:param name="faqId" value="${resultInfo.faqId}" />
                </c:url>
                <tr>
                    <td><c:out value="${(searchVO.pageIndex - 1) * searchVO.pageSize + status.count}" /></td>
                    <td><c:out value="${empty resultInfo.faqCodeNm ? '-' : resultInfo.faqCodeNm}" /></td>
                    <td class="left">
                        <a href="${faqDetailUrl}" class="table-link" onclick="fn_egov_inquire_faqdetail('<c:out value="${resultInfo.faqId}"/>'); return false;">
                            <c:out value="${fn:substring(resultInfo.qestnSj, 0, 60)}" />
                        </a>
                    </td>
                    <td><c:out value="${resultInfo.inqireCo}" /></td>
                    <td><c:out value="${resultInfo.frstRegisterPnttm}" /></td>
                </tr>
            </c:forEach>
        </tbody>
    </table>

    <div class="krds-pagination">
        <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_linkPage" />
    </div>
</form>
</lay:layout>
