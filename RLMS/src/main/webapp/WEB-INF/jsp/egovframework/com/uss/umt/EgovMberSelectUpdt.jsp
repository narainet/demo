<%
 /**
  * @Class Name : EgovMberSelectUpdt.jsp
  * @Description : 일반회원상세조회, 수정 JSP
  * @Modification Information
  * @
  * @  수정일     수정자          수정내용
  * @ -------    --------    ---------------------------
  * @ 2009.03.02  조재영          최초 생성
  * @ 2015.06.16  조정국          password 중복필드 정리
  * @ 2016.06.13  장동한          표준프레임워크 v3.6 개선
  * @ 2017.07.21  장동한          로그인인증제한 작업
  * @ 2021.05.30  정진오          디지털원패스 연동해지
  *
  *  @author 공통서비스 개발팀 조재영
  *  @since 2009.03.02
  *  @version 1.0
  *  @see
  *
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comUssUmt.userManage.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.update" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="mberManageVO" staticJavascript="false" xhtml="true" cdata="false"/>
<script type="text/javaScript" language="javascript" defer="defer">
function fnListPage(){
    document.mberManageVO.action = "<c:url value='/uss/umt/EgovMberManage.do'/>";
    document.mberManageVO.submit();
}
function fnDeleteMber(checkedIds) {
	if(confirm("<spring:message code="common.delete.msg" />")){
	    document.mberManageVO.checkedIdForDel.value=checkedIds;
	    document.mberManageVO.action = "<c:url value='/uss/umt/EgovMberDelete.do'/>";
	    document.mberManageVO.submit();
	}
}
function fnPasswordMove(){
    document.mberManageVO.action = "<c:url value='/uss/umt/EgovMberPasswordUpdtView.do'/>";
    document.mberManageVO.submit();
}

function fnLockIncorrect(){
	if(confirm("<spring:message code="comUssUmt.common.lockAtConfirm" />")){
	    document.mberManageVO.action = "<c:url value='/uss/umt/EgovMberLockIncorrect.do'/>";
	    document.mberManageVO.selectedId.value=document.mberManageVO.uniqId.value;
	    document.mberManageVO.submit();
	}
}

function fnUpdate(form){
	if(confirm("<spring:message code="common.save.msg" />")){
		if(validateMberManageVO(form)){
			document.mberManageVO.submit();
			return true;
	    }else{
	    	return false;
	    }
	}
}

// 2021.05.30, 정진오, 디지털원패스 연동해지
function onepassCancel() {
	if (confirm("디지털원패스 연동해지를 진행하시겠습니까?")) { 
		document.onepassForm.action = "<c:url value='/uat/uia/onepass/onepassCancel.do'/>";
		document.onepassForm.submit();
		return true;
	} else {
		return false;
	}
}
</script>
<style>
.mber-page { display:flex; flex-direction:column; gap:14px; min-width:0; }
.mber-head { display:flex; align-items:center; justify-content:space-between; gap:16px; padding:14px 18px; border:1px solid #d1d3d8; border-radius:6px; background:#fff; }
.mber-kicker { display:block; margin-bottom:4px; color:#52617a; font-size:13px; font-weight:600; }
.mber-head h1 { margin:0; color:#1f3974; font-size:24px; line-height:1.35; }
.mber-state { flex:0 0 auto; padding:5px 10px; border-radius:4px; background:#e8edf9; color:#1f3974; font-size:13px; font-weight:700; }
.mber-shell { display:grid; grid-template-columns:minmax(0, 1fr) 300px; min-height:620px; border:1px solid #d1d3d8; border-radius:6px; overflow:hidden; background:#fff; }
.mber-main { min-height:620px; border-right:1px solid #d1d3d8; }
.mber-main .ide-context-pane { padding:24px; }
.mber-main .ide-prov-head { display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap; margin-bottom:18px; padding-bottom:14px; border-bottom:1px solid #e1e5ee; }
.mber-main .ide-prov-head h2 { margin:0; color:#1f3974; font-size:21px; line-height:1.35; }
.mber-main .ide-prov-status { display:inline-flex; align-items:center; min-height:28px; padding:0 10px; border-radius:4px; background:#edf3ff; color:#1f3974; font-size:13px; font-weight:700; }
.mber-form-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:18px 20px; }
.mber-form-row { display:flex; flex-direction:column; gap:7px; min-width:0; }
.mber-form-row.mber-full { grid-column:1 / -1; }
.mber-form-row label { color:#1f2937; font-size:14px; font-weight:700; }
.mber-form-row .krds-input,
.mber-form-row .krds-select { width:100%; max-width:100%; min-height:40px; box-sizing:border-box; }
.mber-inline-control { display:flex; align-items:center; gap:8px; }
.mber-inline-control .krds-input { flex:1 1 auto; }
.mber-tel-group { display:flex; align-items:center; gap:7px; }
.mber-tel-group .krds-input { min-width:0; text-align:center; }
.mber-readonly-value { min-height:40px; padding:10px 12px; border:1px solid #d1d3d8; border-radius:4px; background:#f8f9fb; color:#1d1d1d; box-sizing:border-box; }
.mber-main .ide-form-actions { display:flex; justify-content:flex-end; gap:8px; flex-wrap:wrap; margin-top:22px; padding-top:16px; border-top:1px solid #e1e5ee; }
.required-mark { color:#d4351c; font-weight:700; }
.mber-main .wTableFrm { width:100%; margin:0 !important; padding:0 !important; border:0 !important; background:transparent !important; }
.mber-main .wTableFrm > h2 { position:absolute; width:1px; height:1px; margin:-1px; padding:0; overflow:hidden; clip:rect(0,0,0,0); border:0; }
.mber-main .wTable { width:100% !important; border-collapse:collapse !important; table-layout:fixed; border-top:2px solid #1f3974 !important; border-bottom:1px solid #d1d3d8 !important; }
.mber-main .wTable caption { position:absolute; width:1px; height:1px; margin:-1px; padding:0; overflow:hidden; clip:rect(0,0,0,0); border:0; }
.mber-main .wTable th,
.mber-main .wTable td { padding:12px 14px !important; border:0 !important; border-bottom:1px solid #d8dde8 !important; font-size:14px; line-height:1.55; vertical-align:middle; box-sizing:border-box; }
.mber-main .wTable th { width:190px; background:#f4f6fb !important; color:#1f3974; text-align:left; font-weight:700; }
.mber-main .wTable td { background:#fff !important; color:#1d1d1d; }
.mber-main .wTable input[type="text"],
.mber-main .wTable input[type="password"],
.mber-main .wTable select { width:min(100%, 420px) !important; height:40px; padding:0 12px; border:1px solid #b8c0cc; border-radius:4px; background:#fff; color:#1d1d1d; box-sizing:border-box; font-size:14px; }
.mber-main .wTable input[readonly] { background:#f8f9fb; color:#555; }
.mber-main .wTable #areaNo,
.mber-main .wTable #middleTelno,
.mber-main .wTable #endTelno { width:72px !important; text-align:center; }
.mber-main .wTable #zip { width:110px !important; }
.mber-main .wTable #adres,
.mber-main .wTable #detailAdres { width:100% !important; max-width:620px; }
.mber-main .btn { display:flex; justify-content:flex-end; align-items:center; gap:8px; flex-wrap:wrap; margin:18px 0 0 !important; padding-top:16px; border-top:1px solid #e1e5ee; text-align:right; }
.mber-main .btn input,
.mber-main .btn button,
.mber-main .btn a,
.mber-main .btn02 { display:inline-flex; align-items:center; justify-content:center; min-width:84px; height:40px; padding:0 14px; border:1px solid #b8c0cc; border-radius:4px; background:#fff; color:#1d1d1d; box-sizing:border-box; font-size:14px; font-weight:700; line-height:1; text-decoration:none; cursor:pointer; }
.mber-main .btn .s_submit { border-color:#246beb; background:#246beb; color:#fff; }
.mber-main .btn_s,
.mber-main .btn_s2 { float:none !important; display:inline-flex; margin:0 !important; padding:0 !important; background:transparent !important; border:0 !important; }
.mber-main .error { display:block; margin-top:6px; color:#d4351c; font-size:13px; }
.mber-main .pilsu { color:#d4351c; font-weight:700; }
.mber-right { min-height:620px; background:#243b68; color:#fff; }
.mber-side-block { padding:14px 16px; border-bottom:1px solid rgba(255,255,255,0.15); }
.mber-side-label { display:block; margin-bottom:7px; color:rgba(255,255,255,0.74); font-size:12px; font-weight:700; }
.mber-side-text { margin:0; color:rgba(255,255,255,0.82); font-size:13px; line-height:1.6; word-break:keep-all; }
.mber-side-value { margin:0; color:#fff; font-size:14px; line-height:1.5; word-break:break-word; }
@media (max-width:1024px) {
  .mber-shell { grid-template-columns:1fr; }
  .mber-main { border-right:0; border-bottom:1px solid #d1d3d8; }
  .mber-right { min-height:0; }
}
@media (max-width:768px) {
  .mber-head { align-items:flex-start; flex-direction:column; }
  .mber-state { align-self:flex-start; }
  .mber-main .ide-context-pane { padding:18px; }
  .mber-form-grid { grid-template-columns:1fr; }
  .mber-inline-control { align-items:stretch; flex-direction:column; }
  .mber-main .wTable,
  .mber-main .wTable tbody,
  .mber-main .wTable tr,
  .mber-main .wTable th,
  .mber-main .wTable td { display:block; width:100% !important; }
  .mber-main .wTable th { border-bottom:0 !important; }
  .mber-main .btn { justify-content:flex-start; }
}
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<!-- content start -->
<div class="mber-page">
	<div class="mber-head">
		<div>
			<span class="mber-kicker">&#51068;&#48152;&#54924;&#50896;&#44288;&#47532;</span>
			<h1>${pageTitle} <spring:message code="title.update" /></h1>
		</div>
		<span class="mber-state">&#49688;&#51221;</span>
	</div>

<form:form modelAttribute="mberManageVO" action="${pageContext.request.contextPath}/uss/umt/EgovMberSelectUpdt.do" name="mberManageVO"  method="post" cssClass="krds-form mber-form" onSubmit="fnUpdate(document.forms[0]); return false;"> 

<!-- 상세정보 사용자 삭제시 prameter 전달용 input -->
<input name="checkedIdForDel" type="hidden" />
<!-- 검색조건 유지 -->
<input type="hidden" name="searchCondition" value="<c:out value='${userSearchVO.searchCondition}'/>"/>
<input type="hidden" name="searchKeyword" value="<c:out value='${userSearchVO.searchKeyword}'/>"/>
<input type="hidden" name="sbscrbSttus" value="<c:out value='${userSearchVO.sbscrbSttus}'/>"/>
<input type="hidden" name="pageIndex" value="<c:out value='${userSearchVO.pageIndex}'/>"/>
<!-- 우편번호검색 -->
<!-- 사용자유형정보 : password 수정화면으로 이동시 타겟 유형정보 확인용, 만약검색조건으로 유형이 포함될경우 혼란을 피하기위해 userTy명칭을 쓰지 않음-->
<input type="hidden" name="userTyForPassword" value="<c:out value='${mberManageVO.userTy}'/>" />
<!-- for validation -->
<input type="hidden" name="password" id="password" value="ex~Test#$12"/>
<input type="hidden" name="selectedId" id="selectedId" value=""/>

	<div class="mber-shell">
		<main class="rlms-ide-main mber-main">
			<div class="ide-context-pane">
				<div class="ide-prov-head">
					<h2>&#54924;&#50896; &#51221;&#48372;</h2>
					<span class="ide-prov-status">&#49688;&#51221;</span>
				</div>

<c:set var="inputTxt"><spring:message code="input.input" /></c:set>
<c:set var="inputSelect"><spring:message code="input.cSelect" /></c:set>
<div class="mber-form-grid">
	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.id"/></c:set>
	<div class="mber-form-row mber-full">
		<label for="mberId">${title} <span class="required-mark">*</span></label>
		<c:choose>
			<c:when test="${not empty onepassUserkey && not empty onepassIntfToken}">
				<div class="mber-inline-control">
					<form:input path="mberId" id="mberId" cssClass="krds-input" title="${title} ${inputTxt}" readonly="true" maxlength="20" />
					<a class="krds-btn tertiary medium" href="#" onclick="onepassCancel();return false;">Onepass</a>
				</div>
				<form:errors path="mberId" cssClass="form-hint-invalid" />
				<form:hidden path="uniqId" />
			</c:when>
			<c:otherwise>
				<form:input path="mberId" id="mberId" cssClass="krds-input" title="${title} ${inputTxt}" readonly="true" maxlength="20" />
				<form:errors path="mberId" cssClass="form-hint-invalid" />
				<form:hidden path="uniqId" />
			</c:otherwise>
		</c:choose>
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.name"/></c:set>
	<div class="mber-form-row">
		<label for="mberNm">${title} <span class="required-mark">*</span></label>
		<form:input path="mberNm" id="mberNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="60" />
		<form:errors path="mberNm" cssClass="form-hint-invalid" />
	</div>

	<%-- 2026-07-27 불용 필드 정리 — 비밀번호힌트·정답·성별·우편번호·주소·상세주소 제거 --%>
	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.tel"/></c:set>
	<div class="mber-form-row">
		<label for="areaNo">${title} <span class="required-mark">*</span></label>
		<div class="mber-tel-group">
			<form:input path="areaNo" id="areaNo" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="5" />
			<span>-</span>
			<form:input path="middleTelno" id="middleTelno" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="5" />
			<span>-</span>
			<form:input path="endTelno" id="endTelno" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="5" />
		</div>
		<form:errors path="areaNo" cssClass="form-hint-invalid" />
		<form:errors path="middleTelno" cssClass="form-hint-invalid" />
		<form:errors path="endTelno" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.fax"/></c:set>
	<div class="mber-form-row">
		<label for="mberFxnum">${title}</label>
		<form:input path="mberFxnum" id="mberFxnum" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="15" />
		<form:errors path="mberFxnum" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.phone"/></c:set>
	<div class="mber-form-row">
		<label for="moblphonNo">${title} <span class="required-mark">*</span></label>
		<form:input path="moblphonNo" id="moblphonNo" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="15" />
		<form:errors path="moblphonNo" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.email"/></c:set>
	<div class="mber-form-row">
		<label for="mberEmailAdres">${title} <span class="required-mark">*</span></label>
		<form:input path="mberEmailAdres" id="mberEmailAdres" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="50" />
		<form:errors path="mberEmailAdres" cssClass="form-hint-invalid" />
	</div>

	<%-- 사번 (RLMS 확장 — 2026-07-27) --%>
	<c:set var="title">사번</c:set>
	<div class="mber-form-row">
		<label for="emplNo">${title}</label>
		<form:input path="emplNo" id="emplNo" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="20" />
		<form:errors path="emplNo" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.groupId"/></c:set>
	<c:set var="inputSelect"><spring:message code="input.select"/></c:set>
	<%-- 부서 = 검색 선택 (규정편집기 소관부서 패턴, buseoListJson 재사용 — 2026-07-27) --%>
	<div class="mber-form-row">
		<label for="orgnztNmDisp">${title}</label>
		<div class="mber-tel-group">
			<form:hidden path="orgnztId" id="orgnztId"/>
			<c:set var="curOrgnztNm" value=""/>
			<c:forEach var="og" items="${orgnztId_result}"><c:if test="${og.code eq mberManageVO.orgnztId}"><c:set var="curOrgnztNm" value="${og.codeNm}"/></c:if></c:forEach>
			<input type="text" id="orgnztNmDisp" class="krds-input" readonly placeholder="(미지정)" style="text-align:left;" value="<c:out value='${curOrgnztNm}'/>"/>
			<button type="button" class="krds-btn secondary medium" style="flex:0 0 auto;" onclick="fnOpenBuseoModal();">선택</button>
			<button type="button" class="krds-btn secondary medium" style="flex:0 0 auto;" onclick="fnClearBuseo();">지움</button>
		</div>
		<form:errors path="orgnztId" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.status"/></c:set>
	<div class="mber-form-row">
		<label for="mberSttus">${title} <span class="required-mark">*</span></label>
		<form:select path="mberSttus" id="mberSttus" cssClass="krds-select" title="${title} ${inputSelect}">
			<form:option value="" label="${inputSelect}"/>
			<form:options items="${mberSttus_result}" itemValue="code" itemLabel="codeNm"/>
		</form:select>
		<form:errors path="mberSttus" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.common.lockAt"/></c:set>
	<div class="mber-form-row">
		<label for="lockAt">${title}</label>
		<div id="lockAt" class="mber-readonly-value">
			<c:choose>
				<c:when test="${mberManageVO.lockAt eq 'Y'}">Y</c:when>
				<c:otherwise>N</c:otherwise>
			</c:choose>
		</div>
	</div>
</div>

<div class="ide-form-actions">
	<button type="submit" class="krds-btn primary medium" title="<spring:message code='button.save' /> <spring:message code='input.button' />"><spring:message code="button.save" /></button>
	<a href="<c:url value='/uss/umt/EgovMberManage.do' />" class="krds-btn secondary medium" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
	<button type="button" class="krds-btn secondary medium" onclick="fnDeleteMber('<c:out value='${mberManageVO.userTy}'/>:<c:out value='${mberManageVO.uniqId}'/>'); return false;" title="<spring:message code='button.delete' /> <spring:message code='input.button' />"><spring:message code="button.delete" /></button>
	<button type="button" class="krds-btn tertiary medium" onclick="fnPasswordMove(); return false;" title="<spring:message code='comUssUmt.userManageModifyBtn.passwordChange' /> <spring:message code='input.button' />"><spring:message code="comUssUmt.userManageModifyBtn.passwordChange" /></button>
	<button type="button" class="krds-btn tertiary medium" onclick="fnLockIncorrect(); return false;" title="<spring:message code='comUssUmt.common.lockAtBtn' /> <spring:message code='input.button' />"><spring:message code="comUssUmt.common.lockAtBtn" /></button>
	<button type="button" class="krds-btn tertiary medium" onclick="document.mberManageVO.reset(); return false;" title="<spring:message code='button.reset' /> <spring:message code='input.button' />"><spring:message code="button.reset" /></button>
</div>
			</div>
		</main>
		<aside class="rlms-ide-right mber-right">
			<div class="mber-side-block">
				<span class="mber-side-label">&#54868;&#47732; &#49345;&#53468;</span>
				<p class="mber-side-text">&#51068;&#48152;&#54924;&#50896; &#51221;&#48372; &#49688;&#51221;</p>
			</div>
			<div class="mber-side-block">
				<span class="mber-side-label">&#54924;&#50896; ID</span>
				<p class="mber-side-value"><c:out value="${mberManageVO.mberId}"/></p>
			</div>
			<div class="mber-side-block">
				<span class="mber-side-label">&#51077;&#47141; &#50504;&#45236;</span>
				<p class="mber-side-text">&#48320;&#44221;&#54624; &#51221;&#48372;&#47484; &#49688;&#51221;&#54620; &#46244; &#51200;&#51109;&#54633;&#45768;&#45796;.</p>
			</div>
		</aside>
	</div>
</form:form>
</div>
<!-- content end -->

<!-- 2021.05.30, 정진오, 디지털원패스 연동해지 -->
<form id="onepassForm" name="onepassForm" method="post">
<input type="hidden" name="userKey" id="userKey" value="<c:out value='${onepassUserkey}'/>"/>
<input type="hidden" name="intfToken" id="intfToken" value="<c:out value='${onepassIntfToken}'/>"/>
</form>

<%-- 부서 검색 선택 모달 — 규정편집기 소관부서 패턴 이식(바닐라 JS, buseoListJson 재사용) --%>
<div id="buseoModal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,.45); z-index:1000; align-items:center; justify-content:center;" onclick="if(event.target===this)fnCloseBuseoModal();">
  <div style="background:#fff; border-radius:10px; width:460px; max-width:92vw; padding:20px 22px; box-shadow:0 8px 30px rgba(0,0,0,.25);">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
      <h3 style="margin:0; font-size:18px; color:#1f3974;">부서 선택</h3>
      <button type="button" onclick="fnCloseBuseoModal();" style="border:none; background:none; font-size:22px; line-height:1; cursor:pointer;" aria-label="닫기">×</button>
    </div>
    <div style="display:flex; gap:6px; margin-bottom:10px;">
      <input type="text" id="buseoSearchKw" class="krds-input" placeholder="부서명 검색 (Enter)" autocomplete="off" style="flex:1;"/>
      <button type="button" class="krds-btn secondary medium" style="flex:0 0 auto;" onclick="fnSearchBuseo();">검색</button>
    </div>
    <div id="buseoSearchList" style="max-height:320px; overflow-y:auto; border:1px solid #e3e6ec; border-radius:6px;">
      <p style="color:#888; margin:10px;">조회 중…</p>
    </div>
  </div>
</div>

<script type="text/javascript">
var BUSEO_LIST_URL = '<c:url value="/rlms/prom/buseoListJson.do"/>';
function fnEscHtml(s){ return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function fnOpenBuseoModal(){
    document.getElementById('buseoModal').style.display = 'flex';
    document.getElementById('buseoSearchKw').value = '';
    fnSearchBuseo();   /* 부서 수가 적어 열자마자 전체 목록 */
    setTimeout(function(){ document.getElementById('buseoSearchKw').focus(); }, 50);
}
function fnCloseBuseoModal(){ document.getElementById('buseoModal').style.display = 'none'; }
function fnClearBuseo(){
    document.getElementById('orgnztId').value = '';
    document.getElementById('orgnztNmDisp').value = '';
}
function fnSearchBuseo(){
    var kw = document.getElementById('buseoSearchKw').value || '';
    var box = document.getElementById('buseoSearchList');
    box.innerHTML = '<p style="color:#888; margin:10px;">조회 중…</p>';
    fetch(BUSEO_LIST_URL + '?keyword=' + encodeURIComponent(kw), { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
        .then(function(r){ return r.json(); })
        .then(function(list){
            if (!list || !list.length) { box.innerHTML = '<p style="color:#888; margin:10px;">결과 없음</p>'; return; }
            var h = '<ul style="list-style:none; margin:0; padding:4px;">';
            for (var i = 0; i < list.length; i++) {
                var b = list[i];
                var sub = (b.fullNm && b.fullNm !== b.buseoNm) ? ' <span style="color:#8a94a6; font-size:12px;">' + fnEscHtml(b.fullNm) + '</span>' : '';
                h += '<li><a href="#" style="display:block; padding:7px 10px; border-radius:5px; color:#1f2937; text-decoration:none;"'
                  +  ' onmouseover="this.style.background=\'#f4f7ff\';" onmouseout="this.style.background=\'\';"'
                  +  ' onclick="fnPickBuseo(\'' + fnEscHtml(b.orgnztId || '') + '\',\'' + fnEscHtml(b.buseoNm).replace(/'/g, "\\'") + '\'); return false;">'
                  +  fnEscHtml(b.buseoNm) + sub + '</a></li>';
            }
            h += '</ul>';
            box.innerHTML = h;
        })
        .catch(function(){ box.innerHTML = '<p style="color:#c00; margin:10px;">조회 실패</p>'; });
}
function fnPickBuseo(orgnztId, buseoNm){
    document.getElementById('orgnztId').value = orgnztId;
    document.getElementById('orgnztNmDisp').value = buseoNm;
    fnCloseBuseoModal();
}
document.addEventListener('keydown', function(e){
    if (document.getElementById('buseoModal').style.display === 'none') return;
    if (e.key === 'Enter' && e.target && e.target.id === 'buseoSearchKw') { e.preventDefault(); fnSearchBuseo(); }
    if (e.key === 'Escape') { fnCloseBuseoModal(); }
});
</script>
</lay:layout>
