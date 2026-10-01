<%
 /**
  * @Class Name : EgovMberInsert.jsp
  * @Description : 일반회원등록 JSP
  * @Modification Information
  * @
  * @  수정일         수정자                   수정내용
  * @ -------    --------    ---------------------------
  * @ 2009.03.02    조재영          최초 생성
  *   2016.06.13    장동한          표준프레임워크 v3.6 개선
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
<c:set var="pageTitle">${pageTitle} <spring:message code="title.create" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="mberManageVO" staticJavascript="false" xhtml="true" cdata="false"/>
<%-- 2026-07-27 불용 필드 정리 — 우편번호 팝업 미사용 (주소 항목 제거) --%>
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<script type="text/javaScript" language="javascript" defer="defer">
/*********************************************************
 * 초기화
 ******************************************************** */
function fn_egov_init(){

	//모달 셋팅
	fn_modal_setting();

}
/*********************************************************
 * 모달셋팅
 ******************************************************** */
function fn_modal_setting(){
	//버튼에 모달 연결
	$("#btnMbrId").egovModal( "egovModal" );
	
	//타이틀 설졍
	$("#egovModal").setEgovModalTitle("<spring:message code="comUssUmt.userManageRegistModal.title" />"); //아이디 중복 확인
	var content = "";
	content = content + "<div class='modal-alignL' style='margin:5px 0 0 0'>"+"<spring:message code="comUssUmt.userManageRegistModal.userIsId" /> :"+"</div>"; //사용할아이디
	content = content + "<div class='modal-alignL'>"+"<input type='text' id='checkIdModal' name='checkIdModal' value='' size='20' maxlength='20' />"+"</div>";	
	content += "<div style='clear:both;'></div>";
	content += "<div id='divModalResult' style='margin:10px 0 0 0'><spring:message code="comUssUmt.userManageRegistModal.initStatus" /></div>"; //결과 : 중복확인을 실행하십시오.
	//모달 body 설정
	$("#egovModal").setEgovModalBody(content);

	var footer = "";
	//footer += "<div class='modal-btn'><button class='btn_s2' id='btnModalOk' onclick='fn_id_checkOk()'>확인</button></div>";
	//footer += "<div class='modal-btn'><button class='btn_s2' id='btnModalSelect' onclick='fn_id_check()'>조회</button></div>";
	footer += "<span class='btn_style1 blue' id='btnModalOk' onclick='fn_id_checkOk()'><a href='#'>확인</a></span>&nbsp;";
	footer += "<span class='btn_style1 blue' id='btnModalSelect' onclick='fn_id_check()'><a href='#'>조회</a></span>&nbsp;";
	//모달 footer 설정
	$("#egovModal").setEgovModalfooter(footer);
	
	//엔터이벤트처리
	$("input[name=checkIdModal]").keydown(function (key) {
		if(key.keyCode == 13){
			fn_id_check();	
		}
	});
	footer = null;
	content = null;
}
/*********************************************************
 * 아이디 체크 AJAX
 ******************************************************** */
function fn_id_check(){	
	$.ajax({
		type:"POST",
		url:"<c:url value='/uss/umt/EgovIdDplctCnfirmAjax.do' />",
		data:{
			"checkId": $("#checkIdModal").val()			
		},
		dataType:'json',
		timeout:(1000*30),
		success:function(returnData, status){
			if(status == "success") {
				
				if(returnData.usedCnt > 0 ){
					//사용할수 없는 아이디입니다.
					$("#divModalResult").html("<font color='red'><spring:message code="comUssUmt.userManageRegistModal.result" /> : ["+returnData.checkId+"]<spring:message code="comUssUmt.userManageRegistModal.useMsg" /></font>");
				}else{
					//사용가능한 아이디입니다.
					$("#divModalResult").html("<font color='blue'><spring:message code="comUssUmt.userManageRegistModal.result" /> : ["+returnData.checkId+"]<spring:message code="comUssUmt.userManageRegistModal.notUseMsg" /></font>");
				}
			}else{ alert("ERROR!");return;} 
		}
		});
}

/*********************************************************
 * 아이디 체크 확인
 ******************************************************** */
function fn_id_checkOk(){
	$.ajax({
		type:"POST",
		url:"<c:url value='/uss/umt/EgovIdDplctCnfirmAjax.do' />",
		data:{
			"checkId": $("#checkIdModal").val()			
		},
		dataType:'json',
		timeout:(1000*30),
		success:function(returnData, status){
			if(status == "success") {
				if(returnData.usedCnt > 0 ){
					alert("<spring:message code="comUssUmt.userManageRegistModal.noIdMsg" />"); //사용이 불가능한 아이디 입니다.
					return;
				}else{
					
					$("input[name=mberId]").val(returnData.checkId);
					$("#egovModal").setEgovModalClose();
				}
			}else{ alert("ERROR!");return;} 
		}
		});
}


function fnIdCheck1(){
    var retVal;
    var url = "<c:url value='/uss/umt/EgovIdDplctCnfirmView.do'/>";
    var varParam = new Object();
    varParam.checkId = document.mberManageVO.mberId.value;
    var openParam = "dialogWidth:303px;dialogHeight:250px;scroll:no;status:no;center:yes;resizable:yes;";
        
//    alert(1);
    return false;
    retVal = window.showModalDialog(url, varParam, openParam);
    if(retVal) {
    	document.mberManageVO.mberId.value = retVal;
    }
}

function showModalDialogCallback(retVal) {
	if(retVal) {
	    document.mberManageVO.mberId.value = retVal;
	}
}

function fnListPage(){
    document.mberManageVO.action = "<c:url value='/uss/umt/EgovMberManage.do'/>";
    document.mberManageVO.submit();
}

function fnInsert(form){
	
	if(confirm("<spring:message code="common.regist.msg" />")){	
		if(validateMberManageVO(form)){
			if(form.password.value != form.password2.value){
	            alert("<spring:message code="fail.user.passwordUpdate2" />");
	            return false;
	        }
			form.submit();
			return true;
	    }
	}

	

}
</script>
<style>
.modal-content {width: 400px;}
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
.mber-hint { margin:4px 0 0; padding-left:18px; color:#52617a; font-size:13px; line-height:1.55; }
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
.mber-main .wTable td > div + div { margin-top:6px; color:#52617a; font-size:13px; }
.mber-main .btn { display:flex; justify-content:flex-end; align-items:center; gap:8px; flex-wrap:wrap; margin:18px 0 0 !important; padding-top:16px; border-top:1px solid #e1e5ee; text-align:right; }
.mber-main .btn input,
.mber-main .btn button,
.mber-main .btn a,
.mber-main #btnMbrId,
.mber-main .btn02 { display:inline-flex; align-items:center; justify-content:center; min-width:84px; height:40px; padding:0 14px; border:1px solid #b8c0cc; border-radius:4px; background:#fff; color:#1d1d1d; box-sizing:border-box; font-size:14px; font-weight:700; line-height:1; text-decoration:none; cursor:pointer; }
.mber-main .btn .s_submit,
.mber-main #btnMbrId { border-color:#246beb; background:#246beb; color:#fff; }
.mber-main .btn_s,
.mber-main .btn_s2 { float:none !important; display:inline-flex; margin:0 !important; padding:0 !important; background:transparent !important; border:0 !important; }
.mber-main .error { display:block; margin-top:6px; color:#d4351c; font-size:13px; }
.mber-main .pilsu { color:#d4351c; font-weight:700; }
.mber-right { min-height:620px; background:#243b68; color:#fff; }
.mber-side-block { padding:14px 16px; border-bottom:1px solid rgba(255,255,255,0.15); }
.mber-side-label { display:block; margin-bottom:7px; color:rgba(255,255,255,0.74); font-size:12px; font-weight:700; }
.mber-side-text { margin:0; color:rgba(255,255,255,0.82); font-size:13px; line-height:1.6; word-break:keep-all; }
.modal-alignL input { width:100%; height:38px; padding:0 10px; border:1px solid #b8c0cc; border-radius:4px; box-sizing:border-box; }
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
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
<div class="mber-page">
	<div class="mber-head">
		<div>
			<span class="mber-kicker">&#51068;&#48152;&#54924;&#50896;&#44288;&#47532;</span>
			<h1>${pageTitle} <spring:message code="title.create" /></h1>
		</div>
		<span class="mber-state">&#49888;&#44508; &#51089;&#49457;</span>
	</div>

<form:form modelAttribute="mberManageVO" action="${pageContext.request.contextPath}/uss/umt/EgovMberInsert.do" name="mberManageVO"  method="post" cssClass="krds-form mber-form" onSubmit="fnInsert(document.forms[0]); return false;"> 

	<div class="mber-shell">
		<main class="rlms-ide-main mber-main">
			<div class="ide-context-pane">
				<div class="ide-prov-head">
					<h2>&#54924;&#50896; &#51221;&#48372;</h2>
					<span class="ide-prov-status">&#51077;&#47141;</span>
				</div>

<c:set var="inputTxt"><spring:message code="input.input" /></c:set>
<c:set var="inputSelect"><spring:message code="input.cSelect" /></c:set>
<div class="mber-form-grid">
	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.id"/></c:set>
	<div class="mber-form-row mber-full">
		<label for="mberId">${title} <span class="required-mark">*</span></label>
		<div class="mber-inline-control">
			<form:input path="mberId" id="mberId" cssClass="krds-input" title="${title} ${inputTxt}" readonly="true" maxlength="20" />
			<button type="button" id="btnMbrId" class="krds-btn tertiary medium" title="<spring:message code='comUssUmt.userManageRegistBtn.idSearch' /> <spring:message code='input.button' />"><spring:message code="comUssUmt.userManageRegistBtn.idSearch" /></button>
		</div>
		<form:errors path="mberId" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.name"/></c:set>
	<div class="mber-form-row">
		<label for="mberNm">${title} <span class="required-mark">*</span></label>
		<form:input path="mberNm" id="mberNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="50" />
		<form:errors path="mberNm" cssClass="form-hint-invalid" />
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.pass"/></c:set>
	<div class="mber-form-row">
		<label for="password">${title} <span class="required-mark">*</span></label>
		<form:password path="password" id="password" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="20" />
		<form:errors path="password" cssClass="form-hint-invalid" />
		<ul class="mber-hint">
			<li><spring:message code="info.password.rule.password1" /></li>
			<li><spring:message code="info.password.rule.pwdcheckcomb3" /></li>
			<li><spring:message code="info.password.rule.pwdcheckseries" /></li>
		</ul>
	</div>

	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.passConfirm"/></c:set>
	<div class="mber-form-row">
		<label for="password2">${title} <span class="required-mark">*</span></label>
		<input name="password2" id="password2" class="krds-input" title="${title} ${inputTxt}" type="password" maxlength="20" />
	</div>

	<%-- 2026-07-27 불용 필드 정리 — 비밀번호힌트·정답·성별·우편번호·주소·상세주소 제거 --%>
	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.tel"/></c:set>
	<div class="mber-form-row">
		<label for="areaNo">${title} <span class="required-mark">*</span></label>
		<div class="mber-tel-group">
			<form:input path="areaNo" id="areaNo" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="4" />
			<span>-</span>
			<form:input path="middleTelno" id="middleTelno" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="4" />
			<span>-</span>
			<form:input path="endTelno" id="endTelno" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="4" />
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

	<c:set var="inputSelect"><spring:message code="input.select"/></c:set>
	<c:set var="title"><spring:message code="comUssUmt.userManageRegist.groupId"/></c:set>
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
</div>

<div class="ide-form-actions">
	<button type="submit" class="krds-btn primary medium" title="<spring:message code='button.create' /> <spring:message code='input.button' />"><spring:message code="button.create" /></button>
	<a href="<c:url value='/uss/umt/EgovMberManage.do' />" class="krds-btn secondary medium" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
</div>
			</div>
		</main>
		<aside class="rlms-ide-right mber-right">
			<div class="mber-side-block">
				<span class="mber-side-label">&#54868;&#47732; &#49345;&#53468;</span>
				<p class="mber-side-text">&#51068;&#48152;&#54924;&#50896; &#49888;&#44508; &#46321;&#47197;</p>
			</div>
			<div class="mber-side-block">
				<span class="mber-side-label">&#51077;&#47141; &#50504;&#45236;</span>
				<p class="mber-side-text">&#54596;&#49688;&#44050;&#51012; &#47784;&#46160; &#51077;&#47141;&#54620; &#46244; &#46321;&#47197;&#54633;&#45768;&#45796;.</p>
			</div>
		</aside>
	</div>

<input name="checkedIdForDel" type="hidden" />
<!-- 검색조건 유지 -->
<input type="hidden" name="searchCondition" value="<c:out value='${userSearchVO.searchCondition}'/>"/>
<input type="hidden" name="searchKeyword" value="<c:out value='${userSearchVO.searchKeyword}'/>"/>
<input type="hidden" name="sbscrbSttus" value="<c:out value='${userSearchVO.sbscrbSttus}'/>"/>
<input type="hidden" name="pageIndex" value="<c:out value='${userSearchVO.pageIndex}'/>"/>
 <!-- 우편번호검색 -->
</form:form>
</div>

<!-- Egov Modal include  -->
<c:import url="/EgovModal.do" charEncoding="utf-8">
	<c:param name="scriptYn" value="Y" />
	<c:param name="modalName" value="egovModal" />
</c:import>

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
