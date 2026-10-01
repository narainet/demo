<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- Q&A 답변관리 목록 (관리자 — mgr 데코). egov 원형 → KRDS 재작성(2026-07-09, FAQ 관리 목록 관용구) --%>
<c:set var="pageTitle" value="Q&A 관리" />
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
.qna-st { display: inline-block; padding: 2px 10px; border-radius: 11px; font-size: 12.5px; font-weight: 600;
          background: #eef3fb; color: #1b5fbf; }
.qna-st.done { background: #ecfdf3; color: #067647; }
</style>
<script type="text/javascript">
function fn_egov_init() {
    if (document.qnaForm && document.qnaForm.searchCnd) {
        document.qnaForm.searchCnd.focus();
    }
}

function fn_egov_select_linkPage(pageNo) {
    document.qnaForm.pageIndex.value = pageNo;
    document.qnaForm.action = "<c:url value='/uss/olh/qna/selectQnaAnswerList.do'/>";
    document.qnaForm.submit();
}

function fn_egov_search_qna() {
    document.qnaForm.pageIndex.value = 1;
    document.qnaForm.action = "<c:url value='/uss/olh/qna/selectQnaAnswerList.do'/>";
    document.qnaForm.submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
    <h1>Q&amp;A 관리</h1>
    <p class="page-desc">사용자 문의를 확인하고 답변을 등록합니다.</p>
</div>

<form name="qnaForm" class="krds-form" action="<c:url value='/uss/olh/qna/selectQnaAnswerList.do'/>" method="post" onsubmit="fn_egov_search_qna(); return false;">
    <input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>">

    <div class="search-form" title="<spring:message code='common.searchCondition.msg' />">
        <div class="form-group inline">
            <label class="form-label" for="searchCnd">검색조건</label>
            <select id="searchCnd" name="searchCnd" class="krds-select" title="검색조건 선택">
                <option value="0" <c:if test="${searchVO.searchCnd == '0'}">selected="selected"</c:if>>작성자</option>
                <option value="1" <c:if test="${searchVO.searchCnd == '1'}">selected="selected"</c:if>>진행상태</option>
            </select>

            <label class="form-label" for="searchWrd">검색어</label>
            <input id="searchWrd" name="searchWrd" class="krds-input" type="text" value="<c:out value='${searchVO.searchWrd}'/>" maxlength="155" title="검색어 입력">

            <button type="submit" class="krds-btn primary medium">조회</button>
        </div>
    </div>

    <div class="list-total">
        전체 <strong><c:out value="${paginationInfo.totalRecordCount}" /></strong>건
    </div>

    <table class="krds-table tbl-list">
        <caption>Q&amp;A 답변관리 목록</caption>
        <colgroup>
            <col style="width: 8%;">
            <col>
            <col style="width: 12%;">
            <col style="width: 12%;">
            <col style="width: 10%;">
            <col style="width: 14%;">
        </colgroup>
        <thead>
            <tr>
                <th scope="col">번호</th>
                <th scope="col">질문제목</th>
                <th scope="col">작성자</th>
                <th scope="col">진행상태</th>
                <th scope="col">조회수</th>
                <th scope="col">등록일자</th>
            </tr>
        </thead>
        <tbody>
            <c:if test="${fn:length(resultList) == 0}">
                <tr>
                    <td colspan="6" class="empty-row"><spring:message code="common.nodata.msg" /></td>
                </tr>
            </c:if>
            <c:forEach items="${resultList}" var="resultInfo" varStatus="status">
                <c:url var="qnaAnswerDetailUrl" value="/uss/olh/qna/selectQnaAnswerDetail.do">
                    <c:param name="qaId" value="${resultInfo.qaId}" />
                </c:url>
                <tr>
                    <td><c:out value="${(searchVO.pageIndex - 1) * searchVO.pageSize + status.count}" /></td>
                    <td class="left">
                        <a href="${qnaAnswerDetailUrl}" class="table-link"><c:out value="${fn:substring(resultInfo.qestnSj, 0, 60)}" /></a>
                    </td>
                    <td><c:out value="${resultInfo.wrterNm}" /></td>
                    <td><span class="qna-st ${resultInfo.qnaProcessSttusCode == '3' ? 'done' : ''}"><c:out value="${resultInfo.qnaProcessSttusCodeNm}" /></span></td>
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
