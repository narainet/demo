<%--
/**
 * @Class Name  : EgovBannerUpdt.jsp
 * @Description : EgovBannerUpdt.jsp
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
<%-- 현재 등록 이미지 미리보기 — getImage.do 는 atchFileId 를 세션 암호화해서 받는다(cmm 규약) --%>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="ussIonBnr.bannerUpdt.bannerUpdt"/></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<!-- 배너관리 수정 -->
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

function fncBannerUpdate() {
    var varFrom = document.getElementById("banner");
    varFrom.action = "<c:url value='/uss/ion/bnr/updtBanner.do'/>";

    if(confirm("<spring:message code="ussIonBnr.bannerUpdt.saveImage"/>")){/* 저장 하시겠습니까? */
        if(!validateBanner(varFrom)){           
            return;
        }else{
            varFrom.submit();
        } 
    }
}

function fncBannerDelete() {
    var varFrom = document.getElementById("banner");
    varFrom.action = "<c:url value='/uss/ion/bnr/removeBanner.do'/>";
    if(confirm("<spring:message code="ussIonBnr.bannerUpdt.deleteImage"/>")){/* 삭제 하시겠습니까? */
        varFrom.submit();
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

</script>
<style>
	/* 현재 등록 이미지 미리보기 — 배너 원본은 비율이 제각각(2.7:1~8:1)이라 고정 칸에 contain 으로 맞춘다 */
	.bnr-cur { display:flex; align-items:center; gap:14px; margin-bottom:10px; }
	.bnr-cur-img { width:260px; height:80px; object-fit:contain; padding:6px; box-sizing:border-box;
	               background:#fafbfc; border:1px solid #e4e7ec; border-radius:8px; }
	.bnr-cur-txt { margin:0; font-size:13px; color:#555; line-height:1.6; }
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg"/></noscript><!-- 자바스크립트를 지원하지 않는 브라우저에서는 일부 기능을 사용하실 수 없습니다. -->

<div class="wTableFrm">
	<!-- 타이틀 -->
	<h2><spring:message code="ussIonBnr.bannerUpdt.bannerUpdt"/></h2>

	<!-- 등록폼 -->
<form:form modelAttribute="banner" method="post" action="${pageContext.request.contextPath}/uss/ion/bnr/updtBanner.do" enctype="multipart/form-data"> 
<input type="hidden" name="posblAtchFileNumber" value="1"  >
	<table class="wTable">
		<colgroup>
			<col style="width:16%" />
			<col style="" />
		</colgroup>
		<tr>
			<th><spring:message code="ussIonBnr.bannerUpdt.bannerId"/> <span class="pilsu">*</span></th><!-- 배너ID -->
			<td class="left">
			    <input name="bannerId" id="bannerId" title="<spring:message code="ussIonBnr.bannerUpdt.bannerId"/>" type="text" value="<c:out value='${banner.bannerId}'/>" readonly="readonly" style="width:188px" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerUpdt.bannerNm"/> <span class="pilsu">*</span></th><!-- 배너명 -->
			<td class="left">
			    <input name="bannerNm" id="bannerNm" title="<spring:message code="ussIonBnr.bannerUpdt.bannerNm"/>" type="text" value="<c:out value='${banner.bannerNm}'/>" maxLength="10" style="width:188px" />&nbsp;<form:errors path="bannerNm" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerUpdt.linkUrl"/> <span class="pilsu">*</span></th><!-- 링크URL -->
			<td class="left">
			    <input name="linkUrl" id="linkUrl" title="<spring:message code="ussIonBnr.bannerUpdt.linkUrl"/>" type="text" value="<c:out value='${banner.linkUrl}'/>" maxLength="255" />&nbsp;<form:errors path="linkUrl" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerUpdt.bannerImage"/> <span class="pilsu">*</span></th><!-- 배너이미지 -->
			<td class="left">
				<%-- 현재 등록된 이미지 — 어떤 배너가 올라가 있는지 눈으로 확인(2026-07-31).
				     비율이 제각각이라 홈과 같은 방식(고정 칸 + contain)으로 보여준다. --%>
				<c:if test="${not empty banner.bannerImageFile}">
					<div class="bnr-cur">
						<img class="bnr-cur-img" alt="현재 등록된 배너 이미지"
						     src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=<c:out value='${egovc:encryptSession(banner.bannerImageFile, pageContext.session.id)}'/>"/>
						<p class="bnr-cur-txt">현재 등록된 이미지 — <c:out value="${banner.bannerImage}"/><br/>
						   새 파일을 올리면 이 이미지가 교체됩니다.</p>
					</div>
				</c:if>
				<%-- 첨부 UI 는 게시판과 동일한 공용 드롭존. 배너는 1개만 등록된다(posblAtchFileNumber=1). --%>
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
			<th><spring:message code="ussIonBnr.bannerUpdt.bannerDc"/></th><!-- 배너설명 -->
			<td class="left">
			    <input name="bannerDc" id="bannerDc" title="<spring:message code="ussIonBnr.bannerUpdt.bannerDc"/>" type="text" value="<c:out value='${banner.bannerDc}'/>" maxLength="100" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerUpdt.sortOrdr"/> <span class="pilsu">*</span></th><!-- 정렬순서 -->
			<td class="left">
			    <input name="sortOrdr" id="sortOrdr" title="<spring:message code="ussIonBnr.bannerUpdt.sortOrdr"/>" type="text" value="<c:out value='${banner.sortOrdr}'/>" maxLength="5" style="width:68px" />&nbsp;<form:errors path="sortOrdr" />
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerUpdt.reflctAtt"/> <span class="pilsu">*</span></th><!-- 반영여부 -->
			<td class="left">
				<select name="reflctAt" id="reflctAt" title="<spring:message code="ussIonBnr.bannerUpdt.reflctAtt"/>">
					<option value="Y" <c:if test="${banner.reflctAt == 'Y'}">selected</c:if> >Y</option>
					<option value="N" <c:if test="${banner.reflctAt == 'N'}">selected</c:if> >N</option>
				</select>
			</td>
		</tr>
		<tr>
			<th><spring:message code="ussIonBnr.bannerUpdt.regDate"/> <span class="pilsu">*</span></th><!-- 등록일시 -->
			<td class="left">
			    <input name="regDate" id="regDate" title="<spring:message code="ussIonBnr.bannerUpdt.regDate"/>" type="text" value="<c:out value="${fn:substring(banner.regDate,0,16)}"/>" maxLength="50" readonly="readonly" style="width:188px" /><!-- 분까지만 표시(2026-07-31) — 등록일시는 저장 대상이 아니라 되돌려 보내도 무시된다 -->
			</td>
		</tr>
	</table>

	<!-- 하단 버튼 -->
	<div class="btn">
		<input class="s_submit" type="submit" value='<spring:message code="button.save" />' onclick="fncBannerUpdate(); return false;" />
		<span class="btn_s"><a href="<c:url value='/uss/ion/bnr/removeBanner.do'/>?bannerId=<c:out value='${bannerVO.bannerId}'/>" onclick="fncBannerDelete(); return false;"><spring:message code="button.delete" /></a></span>
		<span class="btn_s"><a href="<c:url value='/uss/ion/bnr/selectBannerList.do'/>?pageIndex=<c:out value='${bannerVO.pageIndex}'/>&amp;searchKeyword=<c:out value="${bannerVO.searchKeyword}"/>&amp;searchCondition=1" onclick="fncSelectBannerList(); return false;"><spring:message code="button.list" /></a></span>
	</div>
	<div style="clear:both;"></div>
</div>

<!-- 검색조건 유지 -->
<input type="hidden" name="searchCondition" value="<c:out value='${bannerVO.searchCondition}'/>" >
<input type="hidden" name="searchKeyword" value="<c:out value='${bannerVO.searchKeyword}'/>" >
<input type="hidden" name="pageIndex" value="<c:out value='${bannerVO.pageIndex}'/>" >
</form:form>
</lay:layout>
