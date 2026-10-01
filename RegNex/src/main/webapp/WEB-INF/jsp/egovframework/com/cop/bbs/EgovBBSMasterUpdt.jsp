<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comCopBbs.boardMasterVO.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.update" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<validator:javascript formName="boardMasterVO" staticJavascript="false" xhtml="true" cdata="false"/>
<style>
.bbs-master-page { display:flex; flex-direction:column; gap:14px; min-width:0; }
.bbs-master-head { display:flex; align-items:center; justify-content:space-between; gap:16px; padding:14px 18px; border:1px solid #d1d3d8; border-radius:6px; background:#fff; }
.bbs-master-kicker { display:block; margin-bottom:4px; color:#52617a; font-size:13px; font-weight:600; }
.bbs-master-head h1 { margin:0; color:#1f3974; font-size:24px; line-height:1.35; }
.bbs-master-state { flex:0 0 auto; padding:5px 10px; border-radius:4px; background:#e8edf9; color:#1f3974; font-size:13px; font-weight:700; }
.bbs-master-shell { display:grid; grid-template-columns:minmax(0, 1fr) 300px; min-height:620px; border:1px solid #d1d3d8; border-radius:6px; overflow:hidden; background:#fff; }
.bbs-master-main { min-height:620px; border-right:1px solid #d1d3d8; }
.bbs-master-main .ide-context-pane { padding:24px; }
.bbs-master-main .ide-prov-head { align-items:center; flex-wrap:wrap; }
.bbs-master-main .ide-prov-head h2 { font-size:21px; }
.bbs-master-main .ide-form-row { margin-bottom:18px; }
.bbs-master-main .krds-input,
.bbs-master-main .krds-select { width:100%; max-width:100%; box-sizing:border-box; }
.bbs-master-main textarea.krds-input { min-height:150px; resize:vertical; }
.bbs-master-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:16px; }
.bbs-extra-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:12px 16px; }
.bbs-extra-field-item { display:flex; flex-direction:column; gap:8px; padding:14px; border:1px solid #e1e5ee; border-radius:6px; background:#f8f9fb; }
.bbs-extra-field-title { margin:0; color:#1f3974; font-size:14px; font-weight:700; }
.bbs-extra-field-row { display:grid; grid-template-columns:88px minmax(0, 1fr); align-items:center; gap:8px; }
.bbs-extra-field-row label { margin:0; color:#444; font-size:13px; font-weight:700; }
/* 컨트롤 높이 통일(입력 36px vs 셀렉트 41px 들쭉) + 상하패딩 제거로 placeholder 수직 중앙정렬.
   krds css(.krds-input.small=36px)가 로드순서로 이기므로 특이도 3단으로 재역전 */
.bbs-master-main .bbs-extra-field-row .krds-input,
.bbs-master-main .bbs-extra-field-row .krds-select { height:40px; padding-top:0; padding-bottom:0; box-sizing:border-box; }
.bbs-master-section-title { margin:28px 0 14px; color:#1f3974; font-size:17px; font-weight:700; }
.bbs-master-hint { margin:7px 0 0; color:#666; font-size:13px; line-height:1.5; }
.bbs-menu-box { padding:16px; border:1px solid #e1e5ee; border-radius:6px; background:#f8f9fb; }
.bbs-menu-roles { display:flex; flex-wrap:wrap; gap:8px 18px; margin:6px 0 0; }
.bbs-menu-roles label { display:inline-flex; align-items:center; gap:6px; margin:0; color:#333; font-size:14px; font-weight:600; }
.bbs-menu-roles input { width:16px; height:16px; }
.bbs-menu-error { margin:0 0 14px; padding:11px 14px; border:1px solid #f3c1bb; border-radius:5px; background:#fdf1ef; color:#a3271a; font-size:14px; }
.bbs-master-main .ide-form-actions { margin-top:22px; padding-top:16px; border-top:1px solid #e1e5ee; }
.bbs-master-main .form-hint-invalid { color:#d4351c; }
.bbs-master-right { min-height:620px; }
.bbs-side-block { padding:14px 16px; border-bottom:1px solid rgba(255,255,255,0.15); }
.bbs-side-label { display:block; margin-bottom:7px; color:rgba(255,255,255,0.74); font-size:12px; font-weight:700; }
.bbs-side-text { margin:0; color:rgba(255,255,255,0.82); font-size:13px; line-height:1.6; word-break:break-word; }
.required-mark { color:#d4351c; font-weight:700; }
@media (max-width:1024px) {
  .bbs-master-shell { grid-template-columns:1fr; }
  .bbs-master-main { border-right:0; border-bottom:1px solid #d1d3d8; }
  .bbs-master-right { min-height:0; }
}
@media (max-width:768px) {
  .bbs-master-head { align-items:flex-start; flex-direction:column; }
  .bbs-master-state { align-self:flex-start; }
  .bbs-master-main .ide-context-pane { padding:18px; }
  .bbs-master-grid,
  .bbs-extra-grid { grid-template-columns:1fr; gap:0; }
  .bbs-extra-grid { gap:12px; }
  .bbs-extra-field-row { grid-template-columns:1fr; align-items:stretch; }
  .bbs-master-main .ide-form-actions { flex-wrap:wrap; justify-content:flex-start; }
}
</style>
<script type="text/javascript">
/* 템플릿ID → 렌더엔진코드 맵 (COMTNTMPLATINFO). 표현형태의 단일 정본 축. */
var tmplatEngine = {
<c:forEach items="${templateList}" var="t" varStatus="s"><c:if test="${not s.first}">,</c:if>
	"<c:out value='${t.tmplatId}'/>": "<c:out value='${t.tmplatSeCode}'/>"</c:forEach>
};

function fn_egov_init(){
	fn_egov_regist_fileAtchPosblAt_validation();
	fn_toggleMenuExpose();
	if (document.getElementById("boardMasterVO") && document.getElementById("boardMasterVO").bbsNm) {
		document.getElementById("boardMasterVO").bbsNm.focus();
	}
}

/* 노출을 끄면 메뉴명·순서·역할 입력을 숨긴다(값은 서버가 무시). */
function fn_toggleMenuExpose(){
	var form = document.getElementById("boardMasterVO");
	var box = document.getElementById("bbsMenuBox");
	if(!form || !form.menuExposeAt || !box){ return; }
	box.style.display = (form.menuExposeAt.value == "Y") ? "" : "none";
}

/* 선택한 템플릿의 엔진을 반환(없으면 LIST). */
function fn_currentEngine(){
	var f = document.getElementById("boardMasterVO");
	if(!f || !f.tmplatId){ return "LIST"; }
	return tmplatEngine[f.tmplatId.value] || "LIST";
}

/* 템플릿을 바꾸면 — 스킨 컬럼을 엔진과 동기하고, 방명록형(GUEST)이면 답글·첨부를 강제 off. */
function fn_onTemplateChange(){
	var f = document.getElementById("boardMasterVO");
	if(!f){ return; }
	var engine = fn_currentEngine();
	if(f.bbsSkinCode){ f.bbsSkinCode.value = engine; }
	// 방명록(GUEST)은 첨부 불가 → 첨부 가능 파일 수 0 (첨부가능여부는 파생 N).
	if(engine === "GUEST" && f.atchPosblFileNumber){ f.atchPosblFileNumber.value = "0"; }
	fn_egov_regist_fileAtchPosblAt_validation();  // 첨부가능 파생 + 정책 게이팅
}

/* 엔진·페이징·첨부개수에 따라 무의미한 정책 입력칸을 비활성(회색)한다.
   비활성 컨트롤은 저장 직전 되살아나 값은 그대로 전송되고, 서버가 최종 판정한다 — UI 정합용. */
function fn_applyPolicyGating(){
	var f = document.getElementById("boardMasterVO");
	if(!f){ return; }
	var engine = fn_currentEngine();
	var fullFetch = (engine === "CALENDAR" || engine === "HISTORY");   // 전건조회 엔진
	var pagingOn = (!f.pagingAt || f.pagingAt.value !== "N");
	var cnt = f.atchPosblFileNumber ? (parseInt(f.atchPosblFileNumber.value, 10) || 0) : 0;
	if(f.pagingAt){ f.pagingAt.disabled = fullFetch; }
	if(f.listPageUnit){ f.listPageUnit.disabled = (fullFetch || !pagingOn); }
	if(f.atchPosblFileSize){ f.atchPosblFileSize.disabled = (cnt === 0); }
	var replyOk = (engine==="LIST"||engine==="FAQ"||engine==="QNA"||engine==="NOTICEHL"||engine==="TAB");
	if(f.replyPosblAt){
		if(replyOk){ f.replyPosblAt.disabled = false; }
		else { f.replyPosblAt.value = "N"; f.replyPosblAt.disabled = true; }
	}
}

function fn_egov_updt_bbs(form){
	if (!validateBoardMasterVO(form)) {
		return false;
	}

	var validateForm = document.getElementById("boardMasterVO");
	if(!validateForm.tmplatId.value){
		alert("표시형태(템플릿)를 선택하세요.");
		validateForm.tmplatId.focus();
		return false;
	}

	if(fn_currentEngine() === "GUEST") {
		if(validateForm.replyPosblAt.value == "Y") {
			alert("<spring:message code='comCopBbs.boardMasterVO.guestReply' />");
			return false;
		}
		if(validateForm.fileAtchPosblAt.value == "Y") {
			alert("<spring:message code='comCopBbs.boardMasterVO.guestFile' />");
			return false;
		}
	} else if(validateForm.fileAtchPosblAt.value == "Y" && validateForm.atchPosblFileNumber.value == "0") {
		alert("Select the number of attachable files.");
		return false;
	}

	if(confirm("<spring:message code='common.update.msg' />")) {
		fn_enableDisabledControls(validateForm);
		form.submit();
	}
	return false;
}

function fn_enableDisabledControls(form){
	if(!form){ return; }
	var fields = form.querySelectorAll("select:disabled, input:disabled, textarea:disabled");
	for(var i = 0; i < fields.length; i++){
		fields[i].disabled = false;
	}
}

function fn_egov_regist_fileAtchPosblAt_validation(){
	var validateForm = document.getElementById("boardMasterVO");
	if(!validateForm || !validateForm.fileAtchPosblAt || !validateForm.atchPosblFileNumber) {
		return;
	}
	// 첨부파일가능여부(히든)는 첨부 가능 파일 수에서 파생 — 0보다 크면 Y, 아니면 N(서버도 동일 규칙으로 재설정).
	var cnt = parseInt(validateForm.atchPosblFileNumber.value, 10) || 0;
	validateForm.fileAtchPosblAt.value = (cnt > 0) ? "Y" : "N";
	fn_applyPolicyGating();
}

function fn_egov_inqire_bbslist() {
	document.getElementById("boardMasterVO").action = "<c:url value='/cop/bbs/selectBBSMasterInfs.do'/>";
	document.getElementById("boardMasterVO").submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init();">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="bbs-master-page">
	<div class="bbs-master-head">
		<div>
			<span class="bbs-master-kicker">Board / Master</span>
			<h1>${pageTitle} <spring:message code="title.update" /></h1>
		</div>
		<span class="bbs-master-state">&#49688;&#51221;</span>
	</div>

	<form:form modelAttribute="boardMasterVO" cssClass="krds-form bbs-master-form" action="${pageContext.request.contextPath}/cop/bbs/updateBBSMaster.do" method="post" onSubmit="fn_egov_updt_bbs(document.forms[0]); return false;">
		<c:set var="inputTxt"><spring:message code="input.input" /></c:set>

		<c:if test="${not empty menuLinkError}">
			<p class="bbs-menu-error"><c:out value="${menuLinkError}"/></p>
		</c:if>

		<div class="bbs-master-shell">
			<main class="rlms-ide-main bbs-master-main">
				<div class="ide-context-pane">
					<div class="ide-prov-head">
						<h2>&#44172;&#49884;&#54032; &#49444;&#51221;</h2>
						<span class="ide-prov-status done">&#49688;&#51221;&#51473;</span>
					</div>

					<c:set var="title"><spring:message code="comCopBbs.boardMasterVO.updt.bbsNm"/></c:set>
					<div class="ide-form-row">
						<label for="bbsNm">${title} <span class="required-mark">*</span></label>
						<form:input path="bbsNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="70" />
						<form:errors path="bbsNm" cssClass="form-hint-invalid" />
					</div>

					<c:set var="title"><spring:message code="comCopBbs.boardMasterVO.updt.bbsIntrcn"/></c:set>
					<div class="ide-form-row">
						<label for="bbsIntrcn">${title} <span class="required-mark">*</span></label>
						<form:textarea path="bbsIntrcn" cssClass="krds-input" title="${title} ${inputTxt}" rows="6" />
						<form:errors path="bbsIntrcn" cssClass="form-hint-invalid" />
					</div>

					<div class="bbs-master-grid">
						<%-- 표시형태 = 템플릿(정본). 유형·스킨 select 폐기 → 템플릿 하나로 표현형태를 고른다. --%>
						<div class="ide-form-row">
							<label for="tmplatId">표시형태(템플릿) <span class="required-mark">*</span></label>
							<form:select path="tmplatId" cssClass="krds-select" title="표시형태 템플릿 선택" onchange="fn_onTemplateChange();">
								<form:option value="" label="-- 선택 --" />
								<form:options items="${templateList}" itemValue="tmplatId" itemLabel="tmplatNm" />
							</form:select>
							<p class="bbs-master-hint">목록형·갤러리형·FAQ형·Q&amp;A형·방명록형·웹진/앨범형 중 선택합니다. 방명록형은 답글·첨부가 자동으로 꺼집니다.</p>
						</div>

						<%-- 유형·스킨은 폼에서 폐기하되 저장 컬럼은 유지(유형=NOT NULL, 스킨=과도기 fallback). 템플릿 선택에 따라 JS 가 채운다. --%>
						<form:hidden path="bbsTyCode" />
						<form:hidden path="bbsSkinCode" />

						<c:set var="title"><spring:message code="comCopBbs.boardMasterVO.regist.replyPosblAt"/></c:set>
						<div class="ide-form-row">
							<label for="replyPosblAt">${title} <span class="required-mark">*</span></label>
							<form:select path="replyPosblAt" cssClass="krds-select" title="${title} ${inputTxt}">
								<form:option value="" label="-- select --" />
								<form:option value="Y" label="Y" />
								<form:option value="N" label="N" />
							</form:select>
							<form:errors path="replyPosblAt" cssClass="form-hint-invalid" />
						</div>

						<%-- 첨부파일가능여부는 히든 — 아래 '첨부 가능 파일 수'에서 파생(0보다 크면 Y, 서버도 동일 규칙으로 재설정). --%>
						<form:hidden path="fileAtchPosblAt" />

						<c:set var="title"><spring:message code="comCopBbs.boardMasterVO.updt.atchPosblFileNumber"/></c:set>
						<div class="ide-form-row">
							<label for="atchPosblFileNumber">${title} <span class="required-mark">*</span></label>
							<form:select path="atchPosblFileNumber" cssClass="krds-select" title="${title} ${inputTxt}" onchange="fn_egov_regist_fileAtchPosblAt_validation()">
								<form:option value="0" label="0" />
								<form:option value="1" label="1" />
								<form:option value="2" label="2" />
								<form:option value="3" label="3" />
								<form:option value="4" label="4" />
								<form:option value="5" label="5" />
								<form:option value="6" label="6" />
								<form:option value="7" label="7" />
								<form:option value="8" label="8" />
								<form:option value="9" label="9" />
								<form:option value="10" label="10" />
							</form:select>
							<form:errors path="atchPosblFileNumber" cssClass="form-hint-invalid" />
						</div>

						<%-- 첨부 1파일 최대 용량(MB). 첨부 가능 파일 수 옆. 시스템 한도(50MB) 초과 시 서버가 상한. --%>
						<div class="ide-form-row">
							<label for="atchPosblFileSize">첨부 파일 최대 용량(MB)</label>
							<form:input path="atchPosblFileSize" cssClass="krds-input" title="첨부 파일 최대 용량(MB)" maxlength="4" placeholder="5" />
							<p class="bbs-master-hint">한 파일의 최대 크기(MB). 비우면 시스템 기본값. 시스템 한도를 넘으면 자동으로 낮춰 저장됩니다.</p>
						</div>

						<c:set var="title"><spring:message code="comCopBbs.boardMasterVO.updt.useAt"/></c:set>
						<div class="ide-form-row">
							<label for="useAt">${title} <span class="required-mark">*</span></label>
							<form:select path="useAt" cssClass="krds-select" title="${title} ${inputTxt}">
								<form:option value="" label="-- select --" />
								<form:option value="Y" label="Y" />
								<form:option value="N" label="N" />
							</form:select>
							<form:errors path="useAt" cssClass="form-hint-invalid" />
						</div>
					</div>

					<h3 class="bbs-master-section-title">표시·정책 설정</h3>
					<div class="bbs-master-grid">
						<div class="ide-form-row">
							<label for="listPageUnit">목록 페이지당 게시물 수</label>
							<form:input path="listPageUnit" cssClass="krds-input" title="목록 페이지당 게시물 수" maxlength="50" placeholder="예: 10  또는  10,20,30,40,50" />
							<p class="bbs-master-hint">비우면 전역 설정을 씁니다. <strong>한 개</strong>(예: 10)면 그 수로 고정, <strong>쉼표로 여러 개</strong>(예: 10,20,30,40,50)면 사용자가 목록 상단에서 개수를 선택할 수 있습니다. 페이징 사용이 N이면 무시됩니다.</p>
						</div>
						<div class="ide-form-row">
							<label for="pagingAt">페이징 사용</label>
							<form:select path="pagingAt" cssClass="krds-select" title="페이징 사용 여부" onchange="fn_applyPolicyGating()">
								<form:option value="Y" label="Y (페이지 나눔)" />
								<form:option value="N" label="N (전체 한 페이지)" />
							</form:select>
						</div>
						<div class="ide-form-row">
							<label for="searchBoxAt">목록 검색창 표시</label>
							<form:select path="searchBoxAt" cssClass="krds-select" title="목록 검색창 표시 여부">
								<form:option value="Y" label="Y (표시)" />
								<form:option value="N" label="N (숨김)" />
							</form:select>
						</div>
						<div class="ide-form-row">
							<label for="secretPosblAt">비밀글 허용</label>
							<form:select path="secretPosblAt" cssClass="krds-select" title="비밀글 허용 여부">
								<form:option value="Y" label="Y (작성자가 비밀글 설정 가능)" />
								<form:option value="N" label="N (비밀글 불가)" />
							</form:select>
						</div>
						<div class="ide-form-row">
							<label for="richEditorAt">에디터(서식) 사용</label>
							<form:select path="richEditorAt" cssClass="krds-select" title="리치텍스트 에디터 사용 여부">
								<form:option value="Y" label="Y (서식·이미지 에디터)" />
								<form:option value="N" label="N (일반 텍스트)" />
							</form:select>
						</div>
						<div class="ide-form-row">
							<label for="searchIncldAt">통합검색 노출</label>
							<form:select path="searchIncldAt" cssClass="krds-select" title="통합검색 노출 여부">
								<form:option value="Y" label="Y (통합검색에 포함)" />
								<form:option value="N" label="N (제외)" />
							</form:select>
						</div>
					</div>
					<p class="bbs-master-hint">페이징을 N으로 하면 목록을 한 페이지에 모두 싣고 페이저를 숨깁니다. 검색창·통합검색·비밀글·에디터는 게시판 성격에 맞게 켜고 끕니다.</p>

					<%-- 댓글·만족도는 독립 플래그(ANSWER_AT / STSFDG_AT) — 동시 사용 가능, 언제든 토글 가능.
					     옛 단일선택 option 은 disabled 여도 fn_enableDisabledControls 로 되살아나 저장 때마다
					     다른 쪽 옵션을 'N' 으로 덮어썼다(2026-07-10 교정). --%>
					<c:if test="${useComment == 'true'}">
						<c:set var="cmtTitle"><spring:message code="comCopBbs.boardMasterVO.detail.option2"/></c:set>
						<div class="ide-form-row">
							<label for="commentAt">${cmtTitle}</label>
							<select name="commentAt" id="commentAt" class="krds-select" title="${cmtTitle}">
								<option value="N" <c:if test="${boardMasterVO.commentAt != 'Y'}">selected="selected"</c:if>>N</option>
								<option value="Y" <c:if test="${boardMasterVO.commentAt == 'Y'}">selected="selected"</c:if>>Y</option>
							</select>
						</div>
					</c:if>
					<c:if test="${useSatisfaction == 'true'}">
						<c:set var="stfTitle"><spring:message code="comCopBbs.boardMasterVO.detail.option3"/></c:set>
						<div class="ide-form-row">
							<label for="stsfdgAt">${stfTitle}</label>
							<select name="stsfdgAt" id="stsfdgAt" class="krds-select" title="${stfTitle}">
								<option value="N" <c:if test="${boardMasterVO.stsfdgAt != 'Y'}">selected="selected"</c:if>>N</option>
								<option value="Y" <c:if test="${boardMasterVO.stsfdgAt == 'Y'}">selected="selected"</c:if>>Y</option>
							</select>
						</div>
					</c:if>

					<%-- 사용자 메뉴 노출 — 저장과 동시에 프로그램·메뉴·역할매핑이 동기화된다.
					     URL(/cop/bbs/user/selectArticleList.do?bbsId=...)은 서버가 조립하므로 입력란이 없다. --%>
					<h3 class="bbs-master-section-title">사용자 메뉴 노출</h3>
					<div class="ide-form-row">
						<label for="menuExposeAt">사용자 화면에 노출</label>
						<select name="menuExposeAt" id="menuExposeAt" class="krds-select" title="사용자 메뉴 노출 여부" onchange="fn_toggleMenuExpose();">
							<option value="Y" <c:if test="${boardMasterVO.menuExposeAt == 'Y'}">selected="selected"</c:if>>Y (게시판 메뉴에 추가)</option>
							<option value="N" <c:if test="${boardMasterVO.menuExposeAt != 'Y'}">selected="selected"</c:if>>N (관리자만 접근)</option>
						</select>
						<p class="bbs-master-hint">노출을 끄면 사용자 GNB 에서 사라지고, 주소를 직접 입력해도 관리자 외에는 열리지 않습니다.</p>
					</div>

					<div id="bbsMenuBox" class="bbs-menu-box">
						<div class="bbs-master-grid">
							<div class="ide-form-row">
								<label for="menuNm">메뉴명</label>
								<input type="text" name="menuNm" id="menuNm" class="krds-input" maxlength="60" title="메뉴명 입력" value="${fn:escapeXml(boardMasterVO.menuNm)}">
								<p class="bbs-master-hint">비워두면 게시판명을 그대로 씁니다.</p>
							</div>
							<div class="ide-form-row">
								<label for="menuOrdr">메뉴 순서</label>
								<input type="text" name="menuOrdr" id="menuOrdr" class="krds-input" maxlength="3" title="메뉴 순서 입력" value="<c:out value='${boardMasterVO.menuOrdr}'/>">
								<p class="bbs-master-hint">비워두면 기존 순서를 유지합니다.</p>
							</div>
						</div>
						<div class="ide-form-row">
							<label>열람 권한</label>
							<c:set var="selRoles" value=",${fn:join(boardMasterVO.menuAuthorCodes, ',')},"/>
							<div class="bbs-menu-roles">
								<c:forEach items="${menuRoleLabels}" var="role">
									<c:if test="${role.key ne 'ROLE_ADMIN'}">
										<label>
											<input type="checkbox" name="menuAuthorCodes" value="<c:out value='${role.key}'/>"
												<c:if test="${fn:contains(selRoles, role.key)}">checked="checked"</c:if>>
											<c:out value="${role.value}"/>
										</label>
									</c:if>
								</c:forEach>
							</div>
							<p class="bbs-master-hint">관리자는 항상 열람할 수 있고, 상위 역할(승인자 &gt; 편집자 &gt; 조회자)은 하위 역할에 허용한 게시판을 함께 열람합니다. 송무담당자는 조회자 게시판까지 함께 열람합니다(편집자·승인자와는 별개 역할).</p>
						</div>
					</div>


					<%-- 작성 권한 — 열람권한과 직교하는 축(COMTNBBSWRITEAUTHOR). 여기에 조회자를 체크하면
					     조회자도 이 게시판에 글을 쓸 수 있다. 노출 여부와 무관하게 저장된다. --%>
					<h3 class="bbs-master-section-title">작성 권한</h3>
					<div class="bbs-menu-box">
						<div class="ide-form-row">
							<label>글을 쓸 수 있는 역할</label>
							<c:set var="selWriteRoles" value=",${fn:join(boardMasterVO.writeAuthorCodes, ',')}," />
							<div class="bbs-menu-roles">
								<c:forEach items="${menuRoleLabels}" var="role">
									<c:if test="${role.key ne 'ROLE_ADMIN'}">
										<label>
											<input type="checkbox" name="writeAuthorCodes" value="<c:out value='${role.key}'/>"
												<c:if test="${fn:contains(selWriteRoles, role.key)}">checked="checked"</c:if>>
											<c:out value="${role.value}"/>
										</label>
									</c:if>
								</c:forEach>
							</div>
							<p class="bbs-master-hint">아무것도 체크하지 않으면 관리자만 글을 쓸 수 있습니다. 작성은 열람을 전제하므로, 열람 권한이 없는 역할은 체크해도 글을 쓸 수 없습니다. 수정·삭제는 본인이 쓴 글에만 가능합니다.</p>
						</div>
					</div>

					<h3 class="bbs-master-section-title">&#50668;&#48516;&#54596;&#46300;</h3>
					<p class="bbs-master-hint">입력타입이 text 가 아니면(radio/select/checkbox) 공통코드를 입력해야 그 형태로 표시됩니다. 코드가 비어 있으면 텍스트 입력칸으로 나갑니다. checkbox 는 여러 개를 고를 수 있고, 선택값은 쉼표로 이어 저장됩니다.</p>
						<p class="bbs-master-hint"><strong>여분필드 1</strong>에 공통코드(radio·select 권장)를 지정하면 <strong>탭분류형·자료실형</strong> 게시판에서 그 값이 <strong>무조건 분류(카테고리) 기준</strong>으로 쓰입니다. 탭분류형은 이 값으로 상단 탭을 나누고 탭별로 페이지를 매겨 보여 줍니다.</p>
					<div class="bbs-extra-grid">
						<c:forEach begin="1" end="10" var="i">
							<div class="bbs-extra-field-item">
								<p class="bbs-extra-field-title">&#50668;&#48516;&#54596;&#46300; ${i}</p>
								<div class="bbs-extra-field-row">
									<label for="bbsExtraField${i}">&#54596;&#46300;&#47749;</label>
									<input type="text" name="bbsExtraField${i}" id="bbsExtraField${i}" class="krds-input" maxlength="200" value="${fn:escapeXml(boardMasterVO.getBbsExtraField(i))}">
								</div>
								<div class="bbs-extra-field-row">
									<label for="bbsExtraFieldType${i}">&#51077;&#47141;&#53440;&#51077;</label>
									<select name="bbsExtraFieldType${i}" id="bbsExtraFieldType${i}" class="krds-select">
										<option value="text" <c:if test="${boardMasterVO.getBbsExtraFieldType(i) == 'text'}">selected="selected"</c:if>>text</option>
										<option value="radio" <c:if test="${boardMasterVO.getBbsExtraFieldType(i) == 'radio'}">selected="selected"</c:if>>radio</option>
										<option value="select" <c:if test="${boardMasterVO.getBbsExtraFieldType(i) == 'select'}">selected="selected"</c:if>>select</option>
										<option value="checkbox" <c:if test="${boardMasterVO.getBbsExtraFieldType(i) == 'checkbox'}">selected="selected"</c:if>>checkbox</option>
									</select>
								</div>
								<div class="bbs-extra-field-row">
									<label for="bbsExtraFieldCodeId${i}">&#44277;&#53685;&#53076;&#46300;</label>
									<input type="text" name="bbsExtraFieldCodeId${i}" id="bbsExtraFieldCodeId${i}" class="krds-input" maxlength="30" placeholder="CODE_ID" value="${fn:escapeXml(boardMasterVO.getBbsExtraFieldCodeId(i))}">
								</div>
							</div>
						</c:forEach>
					</div>

					<div class="ide-form-actions">
						<button type="submit" class="krds-btn primary medium" title="<spring:message code='button.update' /> <spring:message code='input.button' />"><spring:message code="button.update" /></button>
						<a href="<c:url value='/cop/bbs/selectBBSMasterInfs.do' /><c:if test='${boardMasterVO.cmmntyId != null}'>?cmmntyId=${boardMasterVO.cmmntyId}</c:if>" class="krds-btn secondary medium" title="<spring:message code='button.list' /> <spring:message code='input.button' />"><spring:message code="button.list" /></a>
					</div>
				</div>
			</main>

			<aside class="rlms-ide-right bbs-master-right">
				<h3 class="ide-related-tit">&#44172;&#49884;&#54032; &#49444;&#51221; &#51221;&#48372;</h3>
				<div class="bbs-side-block">
					<span class="bbs-side-label">BBS ID</span>
					<p class="bbs-side-text"><c:out value="${boardMasterVO.bbsId}" /></p>
				</div>
				<div class="bbs-side-block">
					<span class="bbs-side-label">&#54364;&#49884;&#54805;&#53000; &#53685;</span>
					<p class="bbs-side-text">게시판의 표시형태를 템플릿으로 고릅니다. 목록형·갤러리형·FAQ형·Q&amp;A형·방명록형·웹진/앨범형이 있으며, 템플릿은 [템플릿관리]에서 추가·관리합니다.</p>
				</div>
				<div class="bbs-side-block">
					<span class="bbs-side-label">&#50668;&#48516;&#54596;&#46300;</span>
					<p class="bbs-side-text">&#51060;&#47492;&#51012; &#51077;&#47141;&#54620; &#54596;&#46300;&#47564; &#49324;&#50857;&#51088; &#44172;&#49884;&#44544; &#46321;&#47197;&#54868;&#47732;&#50640; &#54364;&#49884;&#46121;&#45768;&#45796;.</p>
				</div>
			</aside>
		</div>

		<input name="cmmntyId" type="hidden" value="<c:out value='${boardMasterVO.cmmntyId}'/>">
		<input name="bbsId" type="hidden" value="<c:out value='${boardMasterVO.bbsId}'/>">
	</form:form>
</div>
</lay:layout>
