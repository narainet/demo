<%--
/**
 * @Class Name  : EgovBannerRegist.jsp
 * @Description : EgovBannerRegist.jsp
 * @Modification Information
 * @
 * @  수정일         수정자          수정내용
 * @ -------    --------    ---------------------------
 * @ 2009.02.01    lee.m.j          최초 생성
 * @ 2018.08.30    이정은               공통컴포넌트 3.8 개선 
 *
 *  @author lee.m.j
 *  @since 2009.03.11
 *  @version 1.0
 *  @see
 *  
 *  Copyright (C) 2009 by MOPAS  All right reserved.
 */
 --%>

<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="ussIonBnr.bannerRegist.bannerRegist"/></c:set>
<c:set var="pageHead">
<!-- 배너관리 등록 -->
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<%-- <script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/fms/EgovMultiFile.js'/>" ></script> --%>
<script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/fms/EgovMultiFiles.js'/>" ></script>
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="banner" staticJavascript="false" xhtml="true" cdata="false"/>
<script type="text/javaScript" language="javascript">

function fncSelectBannerList() {
    var varFrom = document.getElementById("banner");
    varFrom.action = "<c:url value='/uss/ion/bnr/selectBannerList.do'/>";
    varFrom.submit();       
}

function fncBannerInsert() {
    var varFrom = document.getElementById("banner");
    varFrom.action = "<c:url value='/uss/ion/bnr/addBanner.do'/>";

    if(confirm("<spring:message code="ussIonBnr.bannerRegist.saveImage"/>")){/* 저장 하시겠습니까? */
        if(!validateBanner(varFrom)){           
            return;
        }else{
            if(varFrom.bannerImage.value != '') {
                varFrom.submit();
            } else {
                alert("<spring:message code="ussIonBnr.bannerRegist.ImageReq"/>");/* 배너이미지는 필수 입력값입니다. */
                return;
            }
        } 
    }
}

// 드롭존이 고른 파일명을 BANNER_IMAGE(hidden) 에 옮긴다. EgovFileDropzone.init 보다 뒤에
// 등록되므로, 확장자·용량 위반으로 dropzone 이 input 을 비운 경우에도 빈 값이 정확히 반영된다.
function fncBindBannerImageName() {
	var inp = document.getElementById("bannerFile");
	var hid = document.getElementById("bannerImage");
	if (!inp || !hid) { return; }
	inp.addEventListener("change", function() {
		hid.value = (inp.files && inp.files.length) ? inp.files[0].name : "";
	});
}
document.addEventListener("DOMContentLoaded", fncBindBannerImageName);

function fncBannerDelete() {
    var varFrom = document.getElementById("banner");
    varFrom.action = "<c:url value='/uss/ion/bnr/removeBanner.do'/>";
    if(confirm("<spring:message code="ussIonBnr.bannerRegist.deleteImage"/>")){/* 삭제 하시겠습니까? */
        varFrom.submit();
    }
}

</script>
<style>
	/* 입력 폭 — 배너명/링크URL/배너설명. 셀 폭에 맞춰 늘리되 과도하게 길어지지 않게 상한을 둔다(2026-07-31).
	   ⛔ !important 필요 — rlms-compat 의 `body .rlms-admin-main table.wTable input[type="text"]{width:auto}`
	      가 특이도(0,2,3)로 클래스 선택자를 이긴다. */
	.bnr-input { width:100% !important; max-width:640px !important; box-sizing:border-box; }
	.bnr-input.short { max-width:360px !important; }
	.bnr-hint { margin-left:8px; font-size:12px; color:#667085; }
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg"/></noscript><!-- 자바스크립트를 지원하지 않는 브라우저에서는 일부 기능을 사용하실 수 없습니다. -->
<form:form modelAttribute="banner" method="post" action="${pageContext.request.contextPath}/uss/ion/bnr/addBanner.do" enctype="multipart/form-data"> 
<div class="wTableFrm">
	<!-- 타이틀 -->
	<h2><spring:message code="ussIonBnr.bannerRegist.bannerRegist"/></h2><!-- 배너관리 등록 -->

	<!-- 등록폼 -->
	<input type="hidden" name="posblAtchFileNumber" value="1" >
	<table class="wTable">
		<colgroup>
			<col style="width:16%" />
			<col style="" />
		</colgroup>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.bannerId"/> <span class="pilsu">*</span></th><!-- 배너ID -->
			<td class="left">
				<input id="bannerId" type="text" name="bannerId" value="<c:out value='${banner.bannerId}'/>" title="<spring:message code="ussIonBnr.bannerRegist.bannerId"/>" readonly="readonly" style="width:188px" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.bannerNm"/> <span class="pilsu">*</span></th><!-- 배너명 -->
			<td class="left">
				<%-- BANNER_NM 은 VARCHAR2(60) — 한글 기준 20자까지 안전(바이트 의미), 기존 10자는 과하게 짧았다 --%>
				<input id="bannerNm" type="text" name="bannerNm" value="<c:out value='${banner.bannerNm}'/>" title="<spring:message code="ussIonBnr.bannerRegist.bannerNm"/>" maxLength="20" class="bnr-input short" />
				<form:errors path="bannerNm" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.linkUrl"/> <span class="pilsu">*</span></th><!-- 링크URL -->
			<td class="left">
				<input id="linkUrl" type="text" name="linkUrl" value="<c:out value='${banner.linkUrl}'/>" title="<spring:message code="ussIonBnr.bannerRegist.linkUrl"/>" maxLength="255" class="bnr-input" />
				<form:errors path="linkUrl" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.bannerImage"/> <span class="pilsu">*</span></th><!-- 배너이미지 -->
			<td class="left">
				<%-- 첨부 UI 는 게시판과 동일한 공용 드롭존(2026-07-31). 배너는 1개만 등록된다(posblAtchFileNumber=1). --%>
				<%-- ⛔ scope="request" 필수 — jsp:include 는 별도 pageContext 라 page 스코프 변수는 안 넘어간다 --%>
				<c:set var="aId" value="bannerFile" scope="request"/>
				<c:set var="aName" value="file_1" scope="request"/>
				<c:set var="aMax" value="1" scope="request"/>
				<c:set var="aAccept" value="image/*" scope="request"/>
				<jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
				<%-- BANNER_IMAGE(파일명)은 저장 대상이자 필수 검증 대상 — 드롭존이 고른 파일명으로 채운다 --%>
				<input name="bannerImage" id="bannerImage" type="hidden" value="<c:out value="${banner.bannerImage}"/>" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.bannerDc"/> </th><!-- 배너설명 -->
			<td class="left">
				<input id="bannerDc" type="text" name="bannerDc" value="<c:out value='${banner.bannerDc}'/>" title="<spring:message code="ussIonBnr.bannerRegist.bannerDc"/>" maxLength="100" class="bnr-input" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.sortOrdr"/> <span class="pilsu">*</span></th><!-- 정렬순서 -->
			<td class="left">
				<%-- 정렬순서는 DB 의 현재 최대값 + 1 로 서버가 채운다(2026-07-31) — 사용자가 세지 않도록 읽기전용.
				     순서를 바꾸려면 등록 후 수정 화면에서 조정한다. --%>
				<input id="sortOrdr" type="text" name="sortOrdr" title="<spring:message code="ussIonBnr.bannerRegist.sortOrdr"/>" value="<c:out value='${banner.sortOrdr}'/>" maxLength="5" style="width:68px" readonly="readonly" />
				<span class="bnr-hint">맨 뒤 순서로 자동 지정됩니다. 순서 변경은 등록 후 수정 화면에서 하세요.</span>
				<form:errors path="sortOrdr" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.reflctAtt"/> <span class="pilsu">*</span></th><!-- 반영여부 -->
			<td class="left">
				<select id="reflctAt" name="reflctAt" title="<spring:message code="ussIonBnr.bannerRegist.reflctAtt"/>">
					<option value="Y" <c:if test="${banner.reflctAt == 'Y'}">selected</c:if> >Y</option>
					<option value="N" <c:if test="${banner.reflctAt == 'N'}">selected</c:if> >N</option>
				</select>
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerRegist.regDate"/> <span class="pilsu">*</span></th><!-- 등록일시 -->
			<td class="left">
				<input id="regDate" type="text" name="regDate" value="<c:out value="${banner.regDate}"/>" title="<spring:message code="ussIonBnr.bannerRegist.regDate"/>" maxLength="20" readonly="readonly" style="width:128px" />
			</td>
		</tr>
	</table>

	<!-- 하단 버튼 -->
	<div class="btn">
		<input class="s_submit" type="submit" value="<spring:message code="button.save" />" onclick="fncBannerInsert(); return false;" />
		<span class="btn_s"><a href="<c:url value='/uss/ion/bnr/selectBannerList.do'/>?pageIndex=<c:out value='${bannerVO.pageIndex}'/>&amp;searchKeyword=<c:out value="${bannerVO.searchKeyword}"/>&amp;searchCondition=1" onclick="fncSelectBannerList(); return false;"><spring:message code="button.list" /></a></span>
	</div>
	<div style="clear:both;"></div>
</div>

<!-- 검색조건 유지 -->
<input type="hidden" name="searchCondition" value="<c:out value='${bannerVO.searchCondition}'/>" >
<input type="hidden" name="searchKeyword" value="<c:out value='${bannerVO.searchKeyword}'/>" >
<input type="hidden" name="pageIndex" value="<c:out value='${bannerVO.pageIndex}'/>" >

<!-- 검색조건 유지 -->
</form:form>
</lay:layout>
