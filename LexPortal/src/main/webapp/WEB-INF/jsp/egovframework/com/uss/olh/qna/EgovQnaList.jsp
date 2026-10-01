<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 사용자 화면(메뉴 30020000 Q&A) — 관리 동선은 EgovQnaAnswerList.jsp(Q&A 답변관리)로 분리돼 있다.
     제목·안내문에 '관리'가 남아 있어 사용자에게 관리 화면처럼 보이던 것 정정(2026-07-29 전 화면 스윕) --%>
<c:set var="pageTitle" value="Q&amp;A" />
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_egov_init() {
    if (document.qnaForm && document.qnaForm.searchCnd) {
        document.qnaForm.searchCnd.focus();
    }
}

function fn_egov_select_linkPage(pageNo) {
    document.qnaForm.pageIndex.value = pageNo;
    document.qnaForm.action = "<c:url value='/uss/olh/qna/selectQnaList.do'/>";
    document.qnaForm.submit();
}

function fn_egov_search_qna() {
    document.qnaForm.pageIndex.value = 1;
    document.qnaForm.action = "<c:url value='/uss/olh/qna/selectQnaList.do'/>";
    document.qnaForm.submit();
}

function fn_egov_inquire_qnadetail(qaId) {
    document.qnaForm.qaId.value = qaId;
    document.qnaForm.action = "<c:url value='/uss/olh/qna/selectQnaDetail.do'/>";
    document.qnaForm.submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
    <h1>Q&amp;A</h1>
    <p class="page-desc">규정에 대해 궁금한 점을 남기면 담당자가 답변합니다. 등록한 질문의 처리상태를 함께 확인할 수 있습니다.</p>
</div>

<form name="qnaForm" class="krds-form" action="<c:url value='/uss/olh/qna/selectQnaList.do'/>" method="post" onsubmit="fn_egov_search_qna(); return false;">
    <input name="qaId" type="hidden" value="<c:out value='${searchVO.qaId}'/>">
    <input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>">

    <div class="search-form" title="<spring:message code='common.searchCondition.msg' />">
        <div class="form-group inline">
            <label class="form-label" for="searchCnd">검색조건</label>
            <select id="searchCnd" name="searchCnd" class="krds-select" title="검색조건 선택">
                <option value="0" <c:if test="${searchVO.searchCnd == '0'}">selected="selected"</c:if>>작성자</option>
                <option value="1" <c:if test="${searchVO.searchCnd == '1'}">selected="selected"</c:if>>질문제목</option>
            </select>

            <label class="form-label" for="searchWrd">검색어</label>
            <input id="searchWrd" name="searchWrd" class="krds-input" type="text" value="<c:out value='${searchVO.searchWrd}'/>" maxlength="155" title="검색어 입력">

            <button type="submit" class="krds-btn primary medium">조회</button>
            <a href="<c:url value='/uss/olh/qna/insertQnaView.do'/>" class="krds-btn secondary medium">등록</a>
        </div>
    </div>

    <div class="list-total">
        전체 <strong><c:out value="${paginationInfo.totalRecordCount}" /></strong>건
    </div>

    <table class="krds-table tbl-list">
        <caption>Q&amp;A 목록</caption>
        <colgroup>
            <col style="width: 8%;">
            <col>
            <col style="width: 14%;">
            <col style="width: 14%;">
            <col style="width: 10%;">
            <col style="width: 16%;">
        </colgroup>
        <thead>
            <tr>
                <th scope="col">번호</th>
                <th scope="col">질문제목</th>
                <th scope="col">작성자</th>
                <th scope="col">처리상태</th>
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
                <c:url var="qnaDetailUrl" value="/uss/olh/qna/selectQnaDetail.do">
                    <c:param name="qaId" value="${resultInfo.qaId}" />
                    <c:param name="pageIndex" value="${searchVO.pageIndex}" />
                </c:url>
                <tr>
                    <td><c:out value="${(searchVO.pageIndex - 1) * searchVO.pageSize + status.count}" /></td>
                    <td class="left">
                        <a href="${qnaDetailUrl}" class="table-link" onclick="fn_egov_inquire_qnadetail('<c:out value="${resultInfo.qaId}"/>'); return false;">
                            <c:out value="${fn:substring(resultInfo.qestnSj, 0, 60)}" />
                        </a>
                    </td>
                    <td><c:out value="${resultInfo.wrterNm}" /></td>
                    <td><span class="rlms-status"><c:out value="${resultInfo.qnaProcessSttusCodeNm}" /></span></td>
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
