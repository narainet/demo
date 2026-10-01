<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ page isErrorPage="true" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="title.html"/></c:set>
<c:set var="pageHead">
<meta charset="utf-8">

<link href="<c:url value='/css/egovframework/com/com.css' />" rel="stylesheet" type="text/css" />

<script language="javascript">
function fncGoAfterErrorPage(){
    history.back(-2);
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<!-- File Extension Error !!! -->
<div style="width: 1000px; margin: 50px auto 50px;">
	<p style="font-size: 18px; color: #000; margin-bottom: 10px; "><img src="<c:url value='/images/egovframework/com/cmm/er_logo.jpg' />" width="379" height="57" /></p>
	<div style="border: ppx solid #666; padding: 20px;">
		<!-- Xss(Cross Site Scripting) Error -->
		<p style="color:red; margin-bottom: 8px; ">File Extension Error</p>

		<div class="boxType1" style="width: 700px;">
			<div class="box">
				<div class="error">
					<p class="title">${exception.message}</p>
					<%-- <p class="cont mb20">${exception['class'].name}</p> --%>
					<p class="cont mb20"><spring:message code="${exception.messageKey}"/><br /></p>
					<span class="btn_style1 blue"><a href="javascript:fncGoAfterErrorPage();"><spring:message code="comCmmErr.button" /><!-- 이전 페이지 --></a></span>
				</div>
			</div>
		</div>
	</div>
</div>
</lay:layout>
