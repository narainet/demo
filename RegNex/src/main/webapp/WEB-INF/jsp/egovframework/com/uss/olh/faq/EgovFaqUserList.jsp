<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 사용자 FAQ (selectFaqUserList.do) — 관리 목록(selectFaqList.do)과 URL 분리(2026-07-09).
     krds.go.kr community FAQ 패턴: 카테고리/검색 + Q/A 아코디언. 읽기 전용 — 쓰기 진입점 없음(관리=FAQ 관리 메뉴). --%>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<c:set var="pageTitle" value="FAQ" />
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
/* KRDS FAQ 아코디언(krds.go.kr community FAQ 패턴) — LNB 처럼 전용 클래스로 재현 */
.faq-acc { border-top: 2px solid #1f3974; }
.faq-acc-item { border-bottom: 1px solid #d7dae2; }
.faq-acc-q { display: flex; align-items: center; gap: 12px; width: 100%; padding: 16px 10px;
             background: none; border: 0; cursor: pointer; text-align: left; font-size: 16px; color: #1a1a1a; }
.faq-acc-q:hover { background: #f8f9fb; }
.faq-acc-badge { flex: 0 0 auto; width: 28px; height: 28px; border-radius: 50%; display: inline-flex;
                 align-items: center; justify-content: center; font-weight: 700; font-size: 14px; color: #fff; }
.faq-acc-badge.q { background: #1f3974; }
.faq-acc-badge.a { background: #256ef4; }
.faq-acc-cat { flex: 0 0 auto; padding: 2px 10px; border-radius: 12px; background: #eef3fb;
               color: #1b5fbf; font-size: 12.5px; font-weight: 600; }
.faq-acc-title { font-weight: 600; min-width: 0; }
.faq-acc-meta { margin-left: auto; flex: 0 0 auto; color: #888; font-size: 13px; }
.faq-acc-chev { flex: 0 0 auto; color: #556; font-size: 12px; transition: transform .15s ease; }
.faq-acc-item.open .faq-acc-chev { transform: rotate(180deg); }
.faq-acc-a { display: none; padding: 18px 20px; background: #f4f6fb; border-top: 1px solid #e4e7ec; }
.faq-acc-item.open .faq-acc-a { display: flex; gap: 12px; align-items: flex-start; }
.faq-acc-body { min-width: 0; flex: 1; line-height: 1.7; color: #333; font-size: 15px; padding-top: 3px; }
.faq-acc-empty { padding: 40px 0; text-align: center; color: #888; border-bottom: 1px solid #d7dae2; }
</style>
<script type="text/javascript">
function fn_egov_init() {
    if (document.faqForm && document.faqForm.searchCnd) {
        document.faqForm.searchCnd.focus();
    }
}

function fn_faq_toggle(btn) {
    var item = btn.parentNode;
    var open = item.className.indexOf('open') >= 0;
    if (open) { item.className = item.className.replace(' open', ''); }
    else { item.className += ' open'; }
    btn.setAttribute('aria-expanded', open ? 'false' : 'true');
}

function fn_egov_select_linkPage(pageNo) {
    document.faqForm.pageIndex.value = pageNo;
    document.faqForm.action = "<c:url value='/uss/olh/faq/selectFaqUserList.do'/>";
    document.faqForm.submit();
}

function fn_egov_search_faq() {
    document.faqForm.pageIndex.value = 1;
    document.faqForm.action = "<c:url value='/uss/olh/faq/selectFaqUserList.do'/>";
    document.faqForm.submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="page-header">
    <h1>${pageTitle}</h1>
    <p class="page-desc">질문을 누르면 답변이 펼쳐집니다.</p>
</div>

<form name="faqForm" class="krds-form" action="<c:url value='/uss/olh/faq/selectFaqUserList.do'/>" method="post" onsubmit="fn_egov_search_faq(); return false;">
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
        </div>
    </div>

    <div class="list-total">
        전체 <strong><c:out value="${paginationInfo.totalRecordCount}" /></strong>건
    </div>

    <%-- KRDS FAQ 아코디언 — 질문(Q) 클릭 시 답변(A) 인라인 펼침 --%>
    <div class="faq-acc">
        <c:if test="${fn:length(resultList) == 0}">
            <div class="faq-acc-empty"><spring:message code="common.nodata.msg" /></div>
        </c:if>
        <c:forEach items="${resultList}" var="resultInfo" varStatus="status">
        <div class="faq-acc-item">
            <button type="button" class="faq-acc-q" aria-expanded="false" onclick="fn_faq_toggle(this);">
                <span class="faq-acc-badge q">Q</span>
                <c:if test="${not empty resultInfo.faqCodeNm}"><span class="faq-acc-cat"><c:out value="${resultInfo.faqCodeNm}"/></span></c:if>
                <span class="faq-acc-title"><c:out value="${resultInfo.qestnSj}" /></span>
                <span class="faq-acc-meta"><c:out value="${resultInfo.frstRegisterPnttm}" /></span>
                <span class="faq-acc-chev" aria-hidden="true">▼</span>
            </button>
            <div class="faq-acc-a">
                <span class="faq-acc-badge a">A</span>
                <div class="faq-acc-body"><c:out value="${fn:replace(resultInfo.answerCn, crlf, '<br/>')}" escapeXml="false" /></div>
            </div>
        </div>
        </c:forEach>
    </div>

    <div class="krds-pagination">
        <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_linkPage" />
    </div>
</form>
</lay:layout>
