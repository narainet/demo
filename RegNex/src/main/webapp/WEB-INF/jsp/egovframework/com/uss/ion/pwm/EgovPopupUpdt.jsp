<%--
  Class Name : EgovPopupUpdt.jsp
  Description : 팝업창관리 수정 페이지
  Modification Information

      수정일         수정자                   수정내용
    -------    --------    ---------------------------
     2009.09.16    장동한          최초 생성
     2018.08.29    이정은          공통컴포넌트 3.8 개선

    author   : 공통서비스 개발팀 장동한
    since    : 2009.09.16

    Copyright (C) 2009 by MOPAS  All right reserved.
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
<%pageContext.setAttribute("crlf", "\r\n"); %>
<c:set var="pageTitle"><spring:message code="ussIonPwm.popupUpdt.popupUpdt"/></c:set>
<c:set var="pageHead">
                                                        
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<!-- 팝업창관리 수정 -->
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/cmm/jqueryui.css"/>" rel="stylesheet" type="text/css">
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="popupManageVO" staticJavascript="false" xhtml="true" cdata="false"/>
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<script src="<c:url value='/js/egovframework/com/cmm/jqueryui.js' />"></script>
<script src="<c:url value='/html/egovframework/com/cmm/utl/ckeditor/ckeditor.js'/>"></script>
<style>
.popup-manage-page { display:flex; flex-direction:column; gap:14px; min-width:0; }
.popup-manage-head { display:flex; align-items:center; justify-content:space-between; gap:16px; padding:14px 18px; border:1px solid #d1d3d8; border-radius:6px; background:#fff; }
.popup-manage-kicker { display:block; margin-bottom:4px; color:#52617a; font-size:13px; font-weight:600; }
.popup-manage-head h1 { margin:0; color:#1f3974; font-size:24px; line-height:1.35; }
.popup-manage-state { flex:0 0 auto; padding:5px 10px; border-radius:4px; background:#e8edf9; color:#1f3974; font-size:13px; font-weight:700; }
.popup-manage-shell { display:grid; grid-template-columns:minmax(0, 1fr) 300px; min-height:620px; border:1px solid #d1d3d8; border-radius:6px; overflow:hidden; background:#fff; }
.popup-manage-main { min-height:620px; border-right:1px solid #d1d3d8; }
.popup-manage-main .ide-context-pane { padding:24px; }
.popup-manage-main .ide-prov-head { display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap; margin-bottom:20px; }
.popup-manage-main .ide-prov-head h2 { margin:0; color:#1f3974; font-size:21px; line-height:1.35; }
.popup-manage-main .ide-prov-status { padding:4px 9px; border-radius:4px; background:#edf2ff; color:#1f3974; font-size:12px; font-weight:700; }
.popup-manage-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:16px; }
.popup-manage-main .ide-form-row { margin-bottom:18px; }
.popup-manage-main .ide-form-row label { display:block; margin-bottom:7px; color:#222; font-weight:700; }
.popup-manage-main .krds-input,
.popup-manage-main .krds-select { width:100%; height:40px; max-width:100%; border:1px solid #c8ced8; border-radius:4px; padding:0 10px; background:#fff; box-sizing:border-box; }
.popup-manage-main textarea.krds-input { height:auto; min-height:180px; padding:12px; resize:vertical; }
.popup-manage-radio { display:flex; align-items:center; flex-wrap:wrap; gap:14px; min-height:40px; }
.popup-manage-radio label { display:inline-flex !important; align-items:center; gap:6px; margin:0 !important; font-weight:600 !important; }
.popup-measure-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:10px; }
.popup-measure-field { display:flex; align-items:center; gap:8px; }
.popup-measure-field span { flex:0 0 auto; min-width:54px; color:#52617a; font-size:13px; font-weight:700; }
.popup-date-range { display:flex; align-items:center; flex-wrap:wrap; gap:8px; }
.popup-date-range .krds-input { width:130px; }
.popup-date-range .krds-select { width:74px; }
.popup-manage-main .ide-form-actions { display:flex; justify-content:flex-end; gap:8px; margin-top:22px; padding-top:16px; border-top:1px solid #e1e5ee; }
.popup-manage-main .krds-btn { min-width:88px; height:40px; padding:0 16px; border:1px solid #1f5fd1; border-radius:4px; box-sizing:border-box; display:inline-flex; align-items:center; justify-content:center; font-weight:700; text-decoration:none; cursor:pointer; }
.popup-manage-main .krds-btn.primary { background:#246beb; color:#fff; }
.popup-manage-main .krds-btn.secondary { background:#fff; color:#1f5fd1; }
.popup-manage-main .form-hint-invalid,
.popup-manage-main .error { display:block; margin-top:6px; color:#d4351c; font-size:13px; }
.popup-manage-right { min-height:620px; }
.popup-side-block { padding:14px 16px; border-bottom:1px solid rgba(255,255,255,0.15); }
.popup-side-label { display:block; margin-bottom:7px; color:rgba(255,255,255,0.74); font-size:12px; font-weight:700; }
.popup-side-text { margin:0; color:rgba(255,255,255,0.82); font-size:13px; line-height:1.6; }
.required-mark { color:#d4351c; font-weight:700; }
@media (max-width:1024px) {
  .popup-manage-shell { grid-template-columns:1fr; }
  .popup-manage-main { border-right:0; border-bottom:1px solid #d1d3d8; }
  .popup-manage-right { min-height:0; }
}
@media (max-width:768px) {
  .popup-manage-head { align-items:flex-start; flex-direction:column; }
  .popup-manage-state { align-self:flex-start; }
  .popup-manage-main .ide-context-pane { padding:18px; }
  .popup-manage-grid,
  .popup-measure-grid { grid-template-columns:1fr; }
  .popup-manage-main .ide-form-actions { flex-wrap:wrap; justify-content:flex-start; }
}
</style>
<script type="text/javaScript" language="javascript">
/* ********************************************************
 * 초기화
 ******************************************************** */
function fn_egov_init_PopupManage(){
	fn_egov_toggle_cnSe();
}
/* ********************************************************
 * 내용구분(F:파일URL / E:직접편집) 토글
 ******************************************************** */
function fn_egov_toggle_cnSe(){
	var cnSe = fn_egov_RadioBoxValue('cnSe');
	if(cnSe == 'E'){
		document.getElementById('rowFileUrl').style.display = 'none';
		document.getElementById('rowPopupCn').style.display = '';
		// 숨김 상태 CKEditor 초기화 문제 회피 — 직접편집 모드 진입 시 지연 생성
		if(typeof CKEDITOR != 'undefined' && !CKEDITOR.instances['popupCn']){
			// 이미지 업로드(CK필터 /ckUploadImage). 게시판과 동일하게 ?responseType=json + xhr 로
			// 다이얼로그·드래그드롭·붙여넣기가 모두 JSON 응답 계약으로 수렴하게 한다.
			CKEDITOR.replace('popupCn', {
				height: 320,
				language: 'ko',
				filebrowserImageUploadUrl: '${pageContext.request.contextPath}/ckUploadImage?responseType=json',
				filebrowserUploadMethod: 'xhr'
			});
		}
	}else{
		document.getElementById('rowFileUrl').style.display = '';
		document.getElementById('rowPopupCn').style.display = 'none';
	}
}
/* ********************************************************
 * 저장처리화면
 ******************************************************** */
function fn_egov_save_PopupManage(){

	var varFrom = document.popupManageVO;
	var cnSe = fn_egov_RadioBoxValue('cnSe');

	if(confirm("<spring:message code="common.save.msg" />")){
		varFrom.action =  "<c:url value='/uss/ion/pwm/updtPopup.do' />";

		// 내용구분별 필수 검증 (validator 앞 공통항목만 검증)
		if(cnSe == 'E'){
			if(typeof CKEDITOR != 'undefined' && CKEDITOR.instances['popupCn']){
				CKEDITOR.instances['popupCn'].updateElement();
			}
			if(varFrom.popupCn.value.trim() == ''){
				alert('<spring:message code="ussIonPwm.popupManage.validate.popupCn"/>');/* 팝업 내용 */
				return;
			}
		}else{
			if(varFrom.fileUrl.value.trim() == ''){
				alert('<spring:message code="ussIonPwm.popupManage.validate.fileUrl"/>');/* 팝업창 URL */
				varFrom.fileUrl.focus();
				return;
			}
		}

		if(!validatePopupManageVO(varFrom)){
			return;
		}else{

			var ntceBgndeYYYMMDD = document.getElementById('ntceBgndeYYYMMDD').value;
			var ntceEnddeYYYMMDD = document.getElementById('ntceEnddeYYYMMDD').value;

			/* 년도 자리수 검증 — 등록 화면과 동일. '202666-07-23' 저장 사고 방지 (2026-07-29) */
			if(!fn_egov_chkPopupDate(ntceBgndeYYYMMDD, '게시 시작일')) return;
			if(!fn_egov_chkPopupDate(ntceEnddeYYYMMDD, '게시 종료일')) return;

			var iChkBeginDe = Number( ntceBgndeYYYMMDD.replaceAll("-","") );
			var iChkEndDe = Number( ntceEnddeYYYMMDD.replaceAll("-","") );

			if(iChkBeginDe > iChkEndDe || iChkEndDe < iChkBeginDe ){
				alert("<spring:message code="ussIonPwm.popupUpdt.validate.iChkDate"/>");/* 게시시작일자는 게시종료일자 보다 클수 없고, 게시종료일자는 게시시작일자 보다 작을수 없습니다. */
				return;
			}

			varFrom.ntceBgnde.value = ntceBgndeYYYMMDD.replaceAll('-','') + fn_egov_SelectBoxValue('ntceBgndeHH') +  fn_egov_SelectBoxValue('ntceBgndeMM');
			varFrom.ntceEndde.value = ntceEnddeYYYMMDD.replaceAll('-','') + fn_egov_SelectBoxValue('ntceEnddeHH') +  fn_egov_SelectBoxValue('ntceEnddeMM');

			varFrom.submit();
		}
	}
}
/* ********************************************************
* 팝업창 URL 정규화 — 등록 화면과 동일 규칙(스킴 없는 외부 호스트에 https:// 부착).
******************************************************** */
function fn_egov_normalizePopupUrl(el){
	if(!el) return;
	var s = (el.value || '').trim();
	if(!s) { el.value = s; return; }
	if(/^https?:\/\//i.test(s)) { el.value = s; return; }
	if(s.indexOf(':') >= 0 || s.charAt(0) === '/') { el.value = s; return; }
	var host = s.split('/')[0];
	if(host.indexOf('.') > 0 && host.charAt(host.length-1) !== '.' && host.indexOf(' ') < 0){
		s = 'https://' + s;
	}
	el.value = s;
}

/* ********************************************************
* 게시기간 일자 검증 — YYYY-MM-DD 4자리 년도만 허용 (1900~2999). 등록 화면과 동일 규칙.
******************************************************** */
function fn_egov_chkPopupDate(v, label){
	if(!v){ alert(label + '을(를) 입력하세요.'); return false; }
	if(!/^\d{4}-\d{2}-\d{2}$/.test(v)){
		alert(label + '의 형식이 올바르지 않습니다. (YYYY-MM-DD, 년도 4자리)');
		return false;
	}
	var y = Number(v.substring(0,4));
	if(y < 1900 || y > 2999){
		alert(label + '의 년도가 올바르지 않습니다. (1900~2999)');
		return false;
	}
	return true;
}

/* ********************************************************
* RADIO BOX VALUE FUNCTION
******************************************************** */
function fn_egov_RadioBoxValue(sbName)
{
	var FLength = document.getElementsByName(sbName).length;
	var FValue = "";
	for(var i=0; i < FLength; i++)
	{
		if(document.getElementsByName(sbName)[i].checked == true){
			FValue = document.getElementsByName(sbName)[i].value;
		}
	}
	return FValue;
}
/* ********************************************************
* SELECT BOX VALUE FUNCTION
******************************************************** */
function fn_egov_SelectBoxValue(sbName)
{
	var FValue = "";
	for(var i=0; i < document.getElementById(sbName).length; i++)
	{
		if(document.getElementById(sbName).options[i].selected == true){

			FValue=document.getElementById(sbName).options[i].value;
		}
	}

	return  FValue;
}
/* ********************************************************
* PROTOTYPE JS FUNCTION
******************************************************** */
String.prototype.trim = function(){
	return this.replace(/^\s+|\s+$/g, "");
}

String.prototype.replaceAll = function(src, repl){
	 var str = this;
	 if(src == repl){return str;}
	 while(str.indexOf(src) != -1) {
	 	str = str.replace(src, repl);
	 }
	 return str;
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init_PopupManage();">
<div class="popup-manage-page">
	<div class="popup-manage-head">
		<div>
			<span class="popup-manage-kicker">Popup / Window</span>
			<h1><spring:message code="ussIonPwm.popupUpdt.popupUpdt"/></h1>
		</div>
		<span class="popup-manage-state">&#49688;&#51221;</span>
	</div>

	<form:form modelAttribute="popupManageVO" name="popupManageVO" cssClass="krds-form popup-manage-form" action="${pageContext.request.contextPath}/uss/ion/pwm/updtPopup.do" method="post" >
		<div class="popup-manage-shell">
			<main class="rlms-ide-main popup-manage-main">
				<div class="ide-context-pane">
					<div class="ide-prov-head">
						<h2>&#54045;&#50629;&#52285; &#49444;&#51221;</h2>
						<span class="ide-prov-status">&#49688;&#51221;&#51473;</span>
					</div>

					<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.popupTitleNm"/></c:set>
					<div class="ide-form-row">
						<label for="popupTitleNm">${title} <span class="required-mark">*</span></label>
						<form:input path="popupTitleNm" cssClass="krds-input" maxlength="255"/>
						<form:errors path="popupTitleNm" cssClass="form-hint-invalid"/>
					</div>

					<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.cnSe"/></c:set>
					<div class="ide-form-row">
						<label>${title} <span class="required-mark">*</span></label>
						<div class="popup-manage-radio">
							<label><input type="radio" name="cnSe" value="F" onclick="fn_egov_toggle_cnSe();" <c:if test="${popupManageVO.cnSe ne 'E'}">checked="checked"</c:if>/> <spring:message code="ussIonPwm.popupUpdt.cnSeFile"/></label>
							<label><input type="radio" name="cnSe" value="E" onclick="fn_egov_toggle_cnSe();" <c:if test="${popupManageVO.cnSe eq 'E'}">checked="checked"</c:if>/> <spring:message code="ussIonPwm.popupUpdt.cnSeEditor"/></label>
						</div>
					</div>

					<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.fileUrl"/></c:set>
					<div id="rowFileUrl" class="ide-form-row">
						<label for="fileUrl">${title} <span class="required-mark">*</span></label>
						<%-- 등록 화면과 동일 — 스킴 없는 외부 주소는 https:// 를 붙여 실제 열릴 주소를 보여준다. --%>
						<form:input path="fileUrl" cssClass="krds-input" maxlength="255"
							onblur="fn_egov_normalizePopupUrl(this);"/>
						<p class="form-hint">외부 주소는 <code>https://</code> 를 포함해 입력하세요. 생략하면 자동으로 붙습니다.</p>
						<form:errors path="fileUrl" cssClass="form-hint-invalid"/>
					</div>

					<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.popupCn"/></c:set>
					<div id="rowPopupCn" class="ide-form-row" style="display:none">
						<label for="popupCn">${title} <span class="required-mark">*</span></label>
						<form:textarea path="popupCn" id="popupCn" rows="12" cssClass="krds-input"/>
					</div>

					<div class="popup-manage-grid">
						<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.popupLoca"/></c:set>
						<div class="ide-form-row">
							<label>${title} <span class="required-mark">*</span></label>
							<div class="popup-measure-grid">
								<div class="popup-measure-field">
									<span><spring:message code="ussIonPwm.popupUpdt.popupWlce"/></span>
									<form:input path="popupWlc" maxlength="10" cssClass="krds-input"/>
								</div>
								<div class="popup-measure-field">
									<span><spring:message code="ussIonPwm.popupUpdt.popupHlc"/></span>
									<form:input path="popupHlc" maxlength="10" cssClass="krds-input"/>
								</div>
							</div>
							<form:errors path="popupWlc" cssClass="form-hint-invalid"/>
							<form:errors path="popupHlc" cssClass="form-hint-invalid"/>
						</div>

						<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.popupSize"/></c:set>
						<div class="ide-form-row">
							<label>${title} <span class="required-mark">*</span></label>
							<div class="popup-measure-grid">
								<div class="popup-measure-field">
									<span><spring:message code="ussIonPwm.popupUpdt.popupWSize"/></span>
									<form:input path="popupWSize" maxlength="10" cssClass="krds-input"/>
								</div>
								<div class="popup-measure-field">
									<span><spring:message code="ussIonPwm.popupUpdt.popupHSize"/></span>
									<form:input path="popupHSize" maxlength="10" cssClass="krds-input"/>
								</div>
							</div>
							<form:errors path="popupWSize" cssClass="form-hint-invalid"/>
							<form:errors path="popupHSize" cssClass="form-hint-invalid"/>
						</div>
					</div>

					<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.ntcePeriod"/></c:set>
					<div class="ide-form-row">
						<label for="ntceBgndeYYYMMDD">${title} <span class="required-mark">*</span></label>
						<%-- CHAR(20) 공백패딩 대비: trim 후 8자 미만이면 빈 값(native date input 은 yyyy-MM-dd 만 허용) --%>
						<c:set var="pBgn" value="${fn:trim(popupManageVO.ntceBgnde)}"/>
						<c:set var="pBgnDate" value=""/>
						<c:if test="${fn:length(pBgn) ge 8}"><c:set var="pBgnDate" value="${fn:substring(pBgn,0,4)}-${fn:substring(pBgn,4,6)}-${fn:substring(pBgn,6,8)}"/></c:if>
						<c:set var="pEnd" value="${fn:trim(popupManageVO.ntceEndde)}"/>
						<c:set var="pEndDate" value=""/>
						<c:if test="${fn:length(pEnd) ge 8}"><c:set var="pEndDate" value="${fn:substring(pEnd,0,4)}-${fn:substring(pEnd,4,6)}-${fn:substring(pEnd,6,8)}"/></c:if>
						<div class="popup-date-range">
							<input type="date" name="ntceBgndeYYYMMDD" id="ntceBgndeYYYMMDD" class="krds-input" value="${pBgnDate}" min="1900-01-01" max="2999-12-31" />
							<form:select path="ntceBgndeHH" cssClass="krds-select">
								<form:options items="${ntceBgndeHH}" itemValue="code" itemLabel="codeNm"/>
							</form:select><span>H</span>
							<form:select path="ntceBgndeMM" cssClass="krds-select">
								<form:options items="${ntceBgndeMM}" itemValue="code" itemLabel="codeNm"/>
							</form:select><span>M</span>
							<span>~</span>
							<input type="date" name="ntceEnddeYYYMMDD" id="ntceEnddeYYYMMDD" class="krds-input" value="${pEndDate}" min="1900-01-01" max="2999-12-31" />
							<form:select path="ntceEnddeHH" cssClass="krds-select">
								<form:options items="${ntceEnddeHH}" itemValue="code" itemLabel="codeNm"/>
							</form:select><span>H</span>
							<form:select path="ntceEnddeMM" cssClass="krds-select">
								<form:options items="${ntceEnddeMM}" itemValue="code" itemLabel="codeNm"/>
							</form:select><span>M</span>
						</div>
					</div>

					<div class="popup-manage-grid">
						<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.stopVewAt"/></c:set>
						<div class="ide-form-row">
							<label for="stopVewAt">${title} <span class="required-mark">*</span></label>
							<div class="popup-manage-radio">
								<label><input id="stopVewAt" type="radio" name="stopVewAt" value="Y" <c:if test="${popupManageVO.stopVewAt eq 'Y'}">checked="checked"</c:if>/>Y</label>
								<label><input type="radio" name="stopVewAt" value="N" <c:if test="${popupManageVO.stopVewAt eq 'N'}">checked="checked"</c:if>/>N</label>
							</div>
						</div>

						<c:set var="title"><spring:message code="ussIonPwm.popupUpdt.ntceAt"/></c:set>
						<div class="ide-form-row">
							<label for="ntceAt">${title} <span class="required-mark">*</span></label>
							<div class="popup-manage-radio">
								<label><input id="ntceAt" type="radio" name="ntceAt" value="Y" <c:if test="${popupManageVO.ntceAt eq 'Y'}">checked="checked"</c:if>/>Y</label>
								<label><input type="radio" name="ntceAt" value="N" <c:if test="${popupManageVO.ntceAt eq 'N'}">checked="checked"</c:if>/>N</label>
							</div>
						</div>
					</div>

					<div class="ide-form-actions">
						<button class="krds-btn primary medium" type="button" onclick="fn_egov_save_PopupManage(); return false;"><spring:message code="button.save" /></button>
						<a class="krds-btn secondary medium" href="<c:url value='/uss/ion/pwm/listPopup.do' />"><spring:message code="button.list" /></a>
					</div>
				</div>
			</main>

			<aside class="rlms-ide-right popup-manage-right">
				<h3 class="ide-related-tit">&#54045;&#50629;&#52285; &#44288;&#47532;</h3>
				<div class="popup-side-block">
					<span class="popup-side-label">URL / Editor</span>
					<p class="popup-side-text">&#54028;&#51068; URL&#44284; &#51649;&#51217;&#51077;&#47141; &#51473; &#49324;&#50857;&#54624; &#45236;&#50857; &#50976;&#54805;&#51012; &#49440;&#53469;&#54633;&#45768;&#45796;.</p>
				</div>
				<div class="popup-side-block">
					<span class="popup-side-label">&#44172;&#49884;&#44592;&#44036;</span>
					<p class="popup-side-text">&#49884;&#51089;&#51068;&#51088;&#50752; &#51333;&#47308;&#51068;&#51088;&#47484; &#51648;&#51221;&#54644; &#54045;&#50629; &#45432;&#52636; &#44592;&#44036;&#51012; &#44288;&#47532;&#54633;&#45768;&#45796;.</p>
				</div>
			</aside>
		</div>

		<form:hidden path="ntceBgnde" />
		<form:hidden path="ntceEndde" />
		<input name="popupId" type="hidden" value="${popupManageVO.popupId}">
		<input name="cmd" type="hidden" value="<c:out value='save'/>"/>
	</form:form>
</div>
</lay:layout>
