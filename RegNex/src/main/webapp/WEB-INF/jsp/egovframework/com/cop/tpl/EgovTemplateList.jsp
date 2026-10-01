<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 화면명은 메뉴명(80020000 템플릿관리)을 따른다 — 공용 코드 comCopTpl.template.title 은
     템플릿 등록/수정 화면도 '템플릿'이라는 명사로 쓰므로 이 화면에서만 리터럴로 덮는다 (2026-07-29) --%>
<c:set var="pageTitle" value="템플릿관리"/>
<%
 /**
  * @Class Name : EgovTemplateList.jsp
  * @Description : 템플릿(게시판 표시형태) 목록 — RLMS-KRDS
  * @ 2009.03.18  이삼섭          최초 생성
  * @ 2026.07.14  RLMS            템플릿 재설계 P3 — RLMS-KRDS 재작성(템플릿경로 컬럼 폐기)
  * @ 2026.07.14  RLMS            등록 폐기 — 렌더엔진 코드고정(시드 6종=엔진 6종 1:1)이라 신규 등록은 중복 별칭만 생성
  */
%>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<script type="text/javascript">
	function press(event) {
		if (event.keyCode==13) { fn_egov_select_tmplatInfo('1'); }
	}
	function fn_egov_select_tmplatInfo(pageNo){
		document.frm.pageIndex.value = pageNo;
		document.frm.action = "<c:url value='/cop/tpl/selectTemplateInfs.do'/>";
		document.frm.submit();
	}
	function fn_egov_inqire_tmplatInfor(tmplatId){
		document.frm.tmplatId.value = tmplatId;
		document.frm.action = "<c:url value='/cop/tpl/selectTemplateInf.do'/>";
		document.frm.submit();
	}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<form name="frm" action="" method="post">
<input type="hidden" name="tmplatId" value="" />
<input type="hidden" name="pageIndex" value="${searchVO.pageIndex}" />

<div class="page-header">
	<h1>${pageTitle}</h1>
	<p class="page-desc">게시판의 표시형태(템플릿)를 관리합니다. 각 템플릿은 렌더엔진(목록형·갤러리형·FAQ형·Q&amp;A형·방명록형·웹진/앨범형)을 가지며, 게시판속성관리에서 게시판에 배정합니다.</p>
</div>

<div class="krds-form search-form">
	<div class="form-group inline">
		<label class="form-label" for="searchCnd"><spring:message code="title.search" /></label>
		<div class="form-conts">
			<select id="searchCnd" name="searchCnd" class="krds-select" title="검색조건선택">
				<option value="0" <c:if test="${searchVO.searchCnd == '0'}">selected="selected"</c:if>><spring:message code="comCopTpl.template.name"/></option>
				<option value="1" <c:if test="${searchVO.searchCnd == '1'}">selected="selected"</c:if>><spring:message code="comCopTpl.template.type"/></option>
			</select>
			<input type="text" name="searchWrd" class="krds-input" value='<c:out value="${searchVO.searchWrd}"/>' maxlength="35" onkeypress="press(event);" title="검색어입력" />
		</div>
		<button type="button" class="krds-btn primary medium" onclick="fn_egov_select_tmplatInfo('1');"><spring:message code="button.inquire" /></button>
	</div>
</div>

<div class="list-top">
	<p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>
</div>

<table class="krds-table tbl-list">
	<caption class="sr-only">${pageTitle}</caption>
	<colgroup>
		<col style="width:8%;">
		<col>
		<col style="width:20%;">
		<col style="width:12%;">
		<col style="width:16%;">
	</colgroup>
	<thead>
	<tr>
		<th scope="col"><spring:message code="table.num"/></th>
		<th scope="col"><spring:message code="comCopTpl.template.name"/></th>
		<th scope="col">렌더엔진</th>
		<th scope="col"><spring:message code="comCopTpl.template.useYN"/></th>
		<th scope="col"><spring:message code="comCopTpl.template.registDt"/></th>
	</tr>
	</thead>
	<tbody>
		<c:forEach var="result" items="${resultList}" varStatus="status">
		<tr>
			<td><c:out value="${(searchVO.pageIndex-1) * searchVO.pageSize + status.count}"/></td>
			<td class="al">
				<a href="<c:url value='/cop/tpl/selectTemplateInf.do'/>?tmplatId=<c:out value='${result.tmplatId}'/>"><c:out value="${result.tmplatNm}"/></a>
			</td>
			<td><c:out value="${result.tmplatSeCodeNm}"/></td>
			<td>
				<c:choose>
					<c:when test="${result.useAt == 'Y'}"><span class="krds-badge bg-light-success"><spring:message code="button.use" /></span></c:when>
					<c:otherwise><span class="krds-badge bg-light-gray"><spring:message code="button.notUsed" /></span></c:otherwise>
				</c:choose>
			</td>
			<td><c:out value="${result.frstRegisterPnttm}"/></td>
		</tr>
		</c:forEach>
		<c:if test="${fn:length(resultList) == 0}">
		<tr><td colspan="5" class="empty-row"><spring:message code="common.nodata.msg" /></td></tr>
		</c:if>
	</tbody>
</table>

<div class="krds-pagination">
	<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_tmplatInfo"/>
</div>

</form>
</lay:layout>
