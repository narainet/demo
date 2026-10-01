<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comCopTpl.template.title"/> <spring:message code="title.update" /></c:set>
<%
 /**
  * @Class Name : EgovTemplateUpdt.jsp
  * @Description : 템플릿 수정 — RLMS-KRDS. 렌더엔진(tmplatSeCode)·사용여부 수정, 삭제 지원.
  * @ 2009.03.18  이삼섭          최초 생성
  * @ 2026.07.14  RLMS            템플릿 재설계 P3 — RLMS-KRDS 재작성(경로·미리보기 폐기, 삭제 배선)
  */
%>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="templateInf" staticJavascript="false" xhtml="true" cdata="false"/>
<script type="text/javascript">
	function fn_egov_update_tmplatInfo() {
		if (!validateTemplateInf(document.templateInf)){ return; }
		if (confirm('<spring:message code="common.update.msg" />')) {
			document.templateInf.action = "<c:url value='/cop/tpl/updateTemplateInf.do'/>";
			document.templateInf.submit();
		}
	}
	function fn_egov_delete_tmplatInfo() {
		if (confirm('<spring:message code="common.delete.msg" />')) {
			document.templateInf.action = "<c:url value='/cop/bbs/deleteTemplateInf.do'/>";
			document.templateInf.submit();
		}
	}
	function fn_egov_select_tmplatInfo() {
		document.templateInf.action = "<c:url value='/cop/tpl/selectTemplateInfs.do'/>";
		document.templateInf.submit();
	}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<form:form modelAttribute="templateInf" name="templateInf" cssClass="krds-form" method="post">
<input type="hidden" name="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>" />
<input name="tmplatId" type="hidden" value='<c:out value="${TemplateInfVO.tmplatId}"/>' />
<input name="tmplatNm" type="hidden" value='<c:out value="${TemplateInfVO.tmplatNm}"/>' />

<div class="page-header">
	<h1>${pageTitle}</h1>
	<p class="page-desc">템플릿의 렌더엔진(표시형태)·사용여부를 수정합니다. 삭제하면 이 템플릿을 배정한 게시판은 기본(목록형)으로 표시됩니다.</p>
</div>

<table class="krds-table tbl-detail">
	<caption class="sr-only">${pageTitle}</caption>
	<colgroup>
		<col style="width:18%;">
		<col>
	</colgroup>
	<tbody>
	<tr>
		<th scope="row"><spring:message code="comCopTpl.template.name" /></th>
		<td class="left"><c:out value="${TemplateInfVO.tmplatNm}"/><form:errors path="tmplatId" cssClass="error" /></td>
	</tr>
	<tr>
		<th scope="row"><label for="tmplatSeCode">렌더엔진(표시형태) <span class="required-mark">*</span></label></th>
		<td class="left">
			<select id="tmplatSeCode" name="tmplatSeCode" class="krds-select" title="렌더엔진 선택">
				<option value=''>--<spring:message code="input.select" />--</option>
				<c:forEach var="result" items="${resultList}" varStatus="status">
					<option value='<c:out value="${result.code}"/>' <c:if test="${TemplateInfVO.tmplatSeCode == result.code}">selected="selected"</c:if>><c:out value="${result.codeNm}"/></option>
				</c:forEach>
			</select>
			<form:errors path="tmplatSeCode" cssClass="error" />
		</td>
	</tr>
	<tr>
		<th scope="row"><spring:message code="comCopTpl.template.useYN" /> <span class="required-mark">*</span></th>
		<td class="left">
			<label style="margin-right:16px;"><input type="radio" name="useAt" value="Y" <c:if test="${TemplateInfVO.useAt == 'Y'}">checked="checked"</c:if>> <spring:message code="button.use" /></label>
			<label><input type="radio" name="useAt" value="N" <c:if test="${TemplateInfVO.useAt == 'N'}">checked="checked"</c:if>> <spring:message code="button.notUsed" /></label>
		</td>
	</tr>
	</tbody>
</table>

<div class="btn-area">
	<button type="button" class="krds-btn primary medium" onclick="fn_egov_update_tmplatInfo();"><spring:message code="button.update" /></button>
	<button type="button" class="krds-btn danger medium" onclick="fn_egov_delete_tmplatInfo();"><spring:message code="button.delete" /></button>
	<button type="button" class="krds-btn secondary medium" onclick="fn_egov_select_tmplatInfo();"><spring:message code="button.list" /></button>
</div>

</form:form>
</lay:layout>
