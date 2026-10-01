<%--
  Class Name : EgovPopupDetail.jsp
  Description : 팝업창관리 상세보기
  Modification Information

      수정일         수정자                   수정내용
    -------    --------    ---------------------------
     2009.09.16    장동한		최초 생성
     2018.08.29    이정은		공통컴포넌트 3.8 개선
     2024.10.29    권태성		formUpdt form 내에 cmd input box를 추가
     2026.07.13    RLMS		KRDS 톤 개편 + 미리보기 버튼 추가

    author   : 공통서비스 개발팀 장동한
    since    : 2009.09.16

    Copyright (C) 2009 by MOPAS  All right reserved.
--%>
<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<c:set var="pageTitle"><spring:message code="ussIonPwm.popupDetail.popupDetail"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<!-- 팝업창관리 상세보기 -->
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<style>
.popup-manage-page { display:flex; flex-direction:column; gap:14px; min-width:0; }
.popup-manage-head { display:flex; align-items:center; justify-content:space-between; gap:16px; padding:14px 18px; border:1px solid #d1d3d8; border-radius:6px; background:#fff; }
.popup-manage-kicker { display:block; margin-bottom:4px; color:#52617a; font-size:13px; font-weight:600; }
.popup-manage-head h1 { margin:0; color:#1f3974; font-size:24px; line-height:1.35; }
.popup-manage-state { flex:0 0 auto; padding:5px 10px; border-radius:4px; background:#e8edf9; color:#1f3974; font-size:13px; font-weight:700; }
.popup-manage-shell { display:grid; grid-template-columns:minmax(0, 1fr) 300px; min-height:520px; border:1px solid #d1d3d8; border-radius:6px; overflow:hidden; background:#fff; }
.popup-manage-main { min-height:520px; border-right:1px solid #d1d3d8; }
.popup-manage-main .ide-context-pane { padding:24px; }
.popup-manage-main .ide-prov-head { display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap; margin-bottom:20px; }
.popup-manage-main .ide-prov-head h2 { margin:0; color:#1f3974; font-size:21px; line-height:1.35; }
.popup-manage-main .ide-prov-status { padding:4px 9px; border-radius:4px; background:#edf2ff; color:#1f3974; font-size:12px; font-weight:700; }
.popup-manage-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:16px; }
.popup-manage-main .ide-form-row { margin-bottom:18px; }
.popup-manage-main .ide-form-row > label { display:block; margin-bottom:7px; color:#222; font-weight:700; }
.popup-detail-val { display:flex; align-items:center; min-height:40px; padding:8px 12px; border:1px solid #e1e5ee; border-radius:4px; background:#f7f8fb; color:#1a1a1a; box-sizing:border-box; word-break:break-all; }
.popup-detail-cn { max-height:320px; overflow:auto; padding:14px; border:1px solid #e1e5ee; border-radius:4px; background:#fff; }
.popup-detail-cn img { max-width:100%; height:auto; }
.popup-detail-badge { display:inline-flex; align-items:center; padding:4px 10px; border-radius:999px; font-size:13px; font-weight:700; }
.popup-detail-badge.on { background:#e6f4ea; color:#0f7b3d; }
.popup-detail-badge.off { background:#f1f2f5; color:#6b7684; }
.popup-manage-main .ide-form-actions { display:flex; justify-content:flex-end; gap:8px; margin-top:22px; padding-top:16px; border-top:1px solid #e1e5ee; }
.popup-manage-main .krds-btn { min-width:88px; height:40px; padding:0 16px; border:1px solid #1f5fd1; border-radius:4px; box-sizing:border-box; display:inline-flex; align-items:center; justify-content:center; font-weight:700; text-decoration:none; cursor:pointer; font-size:15px; background:#fff; }
.popup-manage-main .krds-btn.primary { background:#246beb; color:#fff; }
.popup-manage-main .krds-btn.secondary { background:#fff; color:#1f5fd1; }
.popup-manage-main .krds-btn.danger { border-color:#d4351c; background:#fff; color:#d4351c; }
.popup-manage-right { min-height:520px; }
.popup-side-block { padding:14px 16px; border-bottom:1px solid rgba(255,255,255,0.15); }
.popup-side-label { display:block; margin-bottom:7px; color:rgba(255,255,255,0.74); font-size:12px; font-weight:700; }
.popup-side-text { margin:0; color:rgba(255,255,255,0.82); font-size:13px; line-height:1.6; }
@media (max-width:1024px) {
  .popup-manage-shell { grid-template-columns:1fr; }
  .popup-manage-main { border-right:0; border-bottom:1px solid #d1d3d8; }
  .popup-manage-right { min-height:0; }
}
@media (max-width:768px) {
  .popup-manage-head { align-items:flex-start; flex-direction:column; }
  .popup-manage-state { align-self:flex-start; }
  .popup-manage-main .ide-context-pane { padding:18px; }
  .popup-manage-grid { grid-template-columns:1fr; }
  .popup-manage-main .ide-form-actions { flex-wrap:wrap; justify-content:flex-start; }
}
</style>
<script type="text/javaScript" language="javascript">
/* ********************************************************
 * 초기화
 ******************************************************** */
function fn_egov_init_PopupManage(){

}
/* ********************************************************
 * 목록 으로 가기
 ******************************************************** */
function fn_egov_list_PopupManage(){
	location.href = "<c:url value='/uss/ion/pwm/listPopup.do' />";
}
/* ********************************************************
 * 미리보기 - 등록된 옵션(크기/위치/그만보기) 그대로 새창 오픈
 ******************************************************** */
function fn_egov_preview_PopupManage(btn){
	var d = btn.dataset;
	var fileUrl = d.fileUrl || '';
	if(fileUrl === 'null'){ fileUrl = ''; }
	var url = "<c:url value='/uss/ion/pwm/openPopupManage.do' />?";
	url = url + "fileUrl=" + encodeURIComponent(fileUrl);
	url = url + "&stopVewAt=" + encodeURIComponent(d.stop || 'N');
	url = url + "&popupId=" + encodeURIComponent(d.popupId);
	var openWindows = window.open(url, d.popupId,
		"width=" + (d.w || 440) + ",height=" + (d.h || 360) + ",top=" + (d.top || 100) + ",left=" + (d.left || 100)
		+ ",toolbar=no,status=no,location=no,scrollbars=yes,menubar=no,resizable=yes");
	if(openWindows && window.focus){ openWindows.focus(); }
}
/* ********************************************************
 * 저장처리화면
 ******************************************************** */
function fn_egov_modify_PopupManage(){
	var vFrom = document.formUpdt;
	vFrom.cmd.value = '';
	vFrom.action = "<c:url value='/uss/ion/pwm/updtPopup.do' />";
	vFrom.submit();

}
/* ********************************************************
 * 삭제처리
 ******************************************************** */
function fn_egov_delete_PopupManage(){
	var vFrom = document.formDelete;
	if(confirm('<spring:message code="common.delete.msg"/>')){/* 삭제 하시겠습니까? */
		vFrom.cmd.value = 'del';
		vFrom.action = "<c:url value='/uss/ion/pwm/detailPopup.do' />";
		vFrom.submit();
	}else{
		vFrom.cmd.value = '';
	}
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init_PopupManage();">
<div class="popup-manage-page">
	<div class="popup-manage-head">
		<div>
			<span class="popup-manage-kicker">Popup / Window</span>
			<h1><spring:message code="ussIonPwm.popupDetail.popupDetail"/></h1><!-- 팝업창관리 상세보기 -->
		</div>
		<span class="popup-manage-state">상세</span>
	</div>

	<div class="popup-manage-shell">
		<main class="rlms-ide-main popup-manage-main">
			<div class="ide-context-pane">
				<div class="ide-prov-head">
					<h2><c:out value="${popupManageVO.popupTitleNm}" /></h2>
					<span class="ide-prov-status">
						<c:choose>
							<c:when test="${popupManageVO.cnSe eq 'E'}"><spring:message code="ussIonPwm.popupDetail.cnSeEditor"/></c:when>
							<c:otherwise><spring:message code="ussIonPwm.popupDetail.cnSeFile"/></c:otherwise>
						</c:choose>
					</span>
				</div>

				<c:choose>
					<c:when test="${popupManageVO.cnSe eq 'E'}">
						<div class="ide-form-row">
							<label><spring:message code="ussIonPwm.popupDetail.popupCn"/></label><!-- 팝업 내용 -->
							<div class="popup-detail-cn">${popupManageVO.popupCn}</div>
						</div>
					</c:when>
					<c:otherwise>
						<div class="ide-form-row">
							<label><spring:message code="ussIonPwm.popupDetail.fileUrl"/></label><!-- 팝업창URL -->
							<div class="popup-detail-val"><c:out value="${popupManageVO.fileUrl}" /></div>
						</div>
					</c:otherwise>
				</c:choose>

				<div class="popup-manage-grid">
					<div class="ide-form-row">
						<label><spring:message code="ussIonPwm.popupDetail.popupLoca"/></label><!-- 팝업창위치 -->
						<div class="popup-detail-val">
							<spring:message code="ussIonPwm.popupDetail.popupWlce"/>&nbsp;<c:out value="${popupManageVO.popupWlc}" />&nbsp;/&nbsp;<spring:message code="ussIonPwm.popupDetail.popupHlc"/>&nbsp;<c:out value="${popupManageVO.popupHlc}" />
						</div>
					</div>
					<div class="ide-form-row">
						<label><spring:message code="ussIonPwm.popupDetail.popupSize"/></label><!-- 팝업창사이즈 -->
						<div class="popup-detail-val">
							<spring:message code="ussIonPwm.popupDetail.popupWSize"/>&nbsp;<c:out value="${popupManageVO.popupWSize}" />&nbsp;/&nbsp;<spring:message code="ussIonPwm.popupDetail.popupHSize"/>&nbsp;<c:out value="${popupManageVO.popupHSize}" />
						</div>
					</div>
				</div>

				<div class="ide-form-row">
					<label><spring:message code="ussIonPwm.popupDetail.ntcePeriod"/></label><!-- 게시 기간 -->
					<c:set var="pBgn" value="${fn:trim(popupManageVO.ntceBgnde)}"/>
					<c:set var="pEnd" value="${fn:trim(popupManageVO.ntceEndde)}"/>
					<div class="popup-detail-val">
						<c:choose>
							<c:when test="${fn:length(pBgn) ge 12 and fn:length(pEnd) ge 12}">
								<c:out value="${fn:substring(pBgn, 0, 4)}"/>-<c:out value="${fn:substring(pBgn, 4, 6)}"/>-<c:out value="${fn:substring(pBgn, 6, 8)}"/>&nbsp;<c:out value="${fn:substring(pBgn, 8, 10)}"/>:<c:out value="${fn:substring(pBgn, 10, 12)}"/>
								&nbsp;~&nbsp;
								<c:out value="${fn:substring(pEnd, 0, 4)}"/>-<c:out value="${fn:substring(pEnd, 4, 6)}"/>-<c:out value="${fn:substring(pEnd, 6, 8)}"/>&nbsp;<c:out value="${fn:substring(pEnd, 8, 10)}"/>:<c:out value="${fn:substring(pEnd, 10, 12)}"/>
							</c:when>
							<c:otherwise>-</c:otherwise>
						</c:choose>
					</div>
				</div>

				<div class="popup-manage-grid">
					<div class="ide-form-row">
						<label><spring:message code="ussIonPwm.popupDetail.stopVewAt"/></label><!-- 그만보기 설정 여부 -->
						<div>
							<c:choose>
								<c:when test="${popupManageVO.stopVewAt eq 'Y'}"><span class="popup-detail-badge on">제공</span></c:when>
								<c:otherwise><span class="popup-detail-badge off">미제공</span></c:otherwise>
							</c:choose>
						</div>
					</div>
					<div class="ide-form-row">
						<label><spring:message code="ussIonPwm.popupDetail.ntceAt"/></label><!-- 게시 상태 -->
						<div>
							<c:choose>
								<c:when test="${popupManageVO.ntceAt eq 'Y'}"><span class="popup-detail-badge on">게시중</span></c:when>
								<c:otherwise><span class="popup-detail-badge off">비게시</span></c:otherwise>
							</c:choose>
						</div>
					</div>
				</div>

				<div class="ide-form-actions">
					<button type="button" class="krds-btn secondary"
						data-popup-id="<c:out value='${popupManageVO.popupId}'/>"
						data-file-url="<c:out value='${popupManageVO.fileUrl}'/>"
						data-stop="<c:out value='${popupManageVO.stopVewAt}'/>"
						data-w="<c:out value='${popupManageVO.popupWSize}'/>"
						data-h="<c:out value='${popupManageVO.popupHSize}'/>"
						data-top="<c:out value='${popupManageVO.popupHlc}'/>"
						data-left="<c:out value='${popupManageVO.popupWlc}'/>"
						onclick="fn_egov_preview_PopupManage(this); return false;">미리보기</button>
					<button type="button" class="krds-btn primary" onclick="fn_egov_modify_PopupManage(); return false;"><spring:message code="button.update" /></button>
					<button type="button" class="krds-btn danger" onclick="fn_egov_delete_PopupManage(); return false;"><spring:message code="button.delete" /></button>
					<a class="krds-btn secondary" href="<c:url value='/uss/ion/pwm/listPopup.do' />"><spring:message code="button.list" /></a>
				</div>
			</div>
		</main>

		<aside class="rlms-ide-right popup-manage-right">
			<h3 class="ide-related-tit">팝업창 관리</h3>
			<div class="popup-side-block">
				<span class="popup-side-label">미리보기</span>
				<p class="popup-side-text">등록된 크기·위치·그만보기 옵션 그대로 새 창으로 확인합니다. 실제 사용자 화면에서는 홈 접속 시 인페이지 모달로 노출됩니다.</p>
			</div>
			<div class="popup-side-block">
				<span class="popup-side-label">게시 조건</span>
				<p class="popup-side-text">게시상태가 '게시중'이고 오늘이 게시기간 안에 있을 때만 사용자 홈에 노출됩니다.</p>
			</div>
		</aside>
	</div>

	<form name="formUpdt" action="<c:url value='/uss/ion/pwm/updtPopup.do'/>" method="post" style="display:none">
		<input name="popupId" type="hidden" value="${popupManageVO.popupId}">
		<input name="cmd" type="hidden" value="<c:out value=''/>">
	</form>

	<form name="formDelete" action="<c:url value='/uss/ion/pwm/detailPopup.do'/>" method="post" style="display:none">
		<input name="popupId" type="hidden" value="${popupManageVO.popupId}">
		<input name="cmd" type="hidden" value="<c:out value='del'/>"/>
	</form>
</div>
</lay:layout>
