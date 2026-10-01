<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comUssUmt.deptUserManage.title"/></c:set>
<c:set var="pageTitle">${pageTitle} <spring:message code="title.create" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript" src="<c:url value='/validator.do'/>"></script>
<validator:javascript formName="userManageVO" staticJavascript="false" xhtml="true" cdata="false"/>
<%-- 2026-07-27 불용 필드 정리 — 우편번호 팝업 미사용 (주소 항목 제거) --%>
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<style>
.user-manage-main { display: block; background: #fff; overflow: auto; }
.user-manage-main .faq-ide-page { padding: 24px; }
.user-manage-left .ide-action.active { background: #e8edf9; color: #1f3974; font-weight: 700; }
.user-manage-left .ide-actions-group { padding: 8px 0; border-bottom: 1px solid #d1d3d8; background: #fff; }
.user-manage-left .ide-actions-group-label { margin: 0; padding: 6px 16px 4px; color: #5a6273; font-size: 12px; font-weight: 700; }
.faq-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
.faq-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
.faq-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
.faq-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
.faq-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #e8edf9; color: #1f3974; font-size: 13px; font-weight: 700; }
.faq-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 560px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
.faq-ide-main { min-height: 560px; border-right: 1px solid #d1d3d8; }
.faq-ide-main .ide-context-pane { padding: 24px; }
.faq-ide-main .ide-prov-head { align-items: center; flex-wrap: wrap; }
.faq-ide-main .ide-prov-head h2 { font-size: 21px; }
.faq-ide-main .ide-form-actions { margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
.faq-ide-right { min-height: 560px; }
.faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
.faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
.faq-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
.faq-side-value { margin: 0; color: #fff; font-size: 14px; line-height: 1.5; word-break: break-word; }
.required-mark { color: #d4351c; font-weight: 700; }
.user-form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px 20px; }
.user-form-row { display: flex; flex-direction: column; gap: 7px; min-width: 0; }
.user-form-row.user-full { grid-column: 1 / -1; }
.user-form-row label { color: #1f2937; font-size: 14px; font-weight: 700; }
.user-form-row .krds-input,
.user-form-row select.krds-input { width: 100%; max-width: 100%; min-height: 40px; }
.user-inline-control { display: flex; gap: 8px; align-items: center; }
.user-inline-control .krds-input { flex: 1 1 auto; }
.user-tel-group { display: flex; align-items: center; gap: 7px; }
.user-tel-group .krds-input { min-width: 0; text-align: center; }
.password-guides { margin: 4px 0 0; padding-left: 18px; color: #52617a; font-size: 13px; line-height: 1.55; }
.form-hint-invalid,
.error { display: block; margin-top: 2px; color: #d4351c; font-size: 13px; }
.modal-content { width: 400px; }
.modal-alignL input { width: 100%; height: 38px; padding: 0 10px; border: 1px solid #b8c0cc; border-radius: 4px; }
@media (max-width: 1024px) {
  .faq-ide-shell { grid-template-columns: 1fr; }
  .faq-ide-main { border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .faq-ide-right { min-height: 0; }
}
@media (max-width: 768px) {
  .rlms-ide-wrap.user-manage-wrap { position: static; display: block; }
  .user-manage-left { display: block; width: 100%; border-right: 0; border-bottom: 1px solid #d1d3d8; }
  .user-manage-main .faq-ide-page { padding: 18px; }
  .faq-ide-head { align-items: flex-start; flex-direction: column; }
  .faq-ide-state { align-self: flex-start; }
  .faq-ide-main .ide-context-pane { padding: 18px; }
  .faq-ide-main .ide-form-actions { justify-content: flex-start; flex-wrap: wrap; }
  .user-form-grid { grid-template-columns: 1fr; }
  .user-inline-control { align-items: stretch; flex-direction: column; }
}
</style>
<script type="text/javaScript" language="javascript" defer="defer">
function fn_egov_init(){
    fn_modal_setting();
}

function fn_modal_setting(){
    $("#btnEmplyrId").egovModal("egovModal");
    $("#egovModal").setEgovModalTitle("<spring:message code="comUssUmt.userManageRegistModal.title" />");

    var content = "";
    content = content + "<div class='modal-alignL' style='margin:5px 0 0 0'>"+"<spring:message code="comUssUmt.userManageRegistModal.userIsId" /> :"+"</div>";
    content = content + "<div class='modal-alignL'>"+"<input type='text' id='checkIdModal' name='checkIdModal' value='' size='20' maxlength='20' />"+"</div>";
    content += "<div style='clear:both;'></div>";
    content += "<div id='divModalResult' style='margin:10px 0 0 0'><spring:message code="comUssUmt.userManageRegistModal.initStatus" /></div>";
    $("#egovModal").setEgovModalBody(content);

    var footer = "";
    footer += "<span class='btn_style1 blue' id='btnModalOk' onclick='fn_id_checkOk()'><a href='#'>확인</a></span>&nbsp;";
    footer += "<span class='btn_style1 blue' id='btnModalSelect' onclick='fn_id_check()'><a href='#'>조회</a></span>&nbsp;";
    $("#egovModal").setEgovModalfooter(footer);

    $("input[name=checkIdModal]").keydown(function (key) {
        if(key.keyCode == 13){
            fn_id_check();
        }
    });
}

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
                    $("#divModalResult").html("<font color='red'><spring:message code="comUssUmt.userManageRegistModal.result" /> : ["+returnData.checkId+"]<spring:message code="comUssUmt.userManageRegistModal.useMsg" /></font>");
                }else{
                    $("#divModalResult").html("<font color='blue'><spring:message code="comUssUmt.userManageRegistModal.result" /> : ["+returnData.checkId+"]<spring:message code="comUssUmt.userManageRegistModal.notUseMsg" /></font>");
                }
            }else{ alert("ERROR!");return; }
        }
    });
}

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
                    alert("<spring:message code="comUssUmt.userManageRegistModal.noIdMsg" />");
                    return;
                }else{
                    $("input[name=emplyrId]").val(returnData.checkId);
                    $("#egovModal").setEgovModalClose();
                }
            }else{ alert("ERROR!");return; }
        }
    });
}

function fnListPage(){
    document.userManageVO.action = "<c:url value='/uss/umt/EgovUserManage.do'/>";
    document.userManageVO.submit();
}

function fnInsert(form){
    if(confirm("<spring:message code="common.regist.msg" />")){
        if(validateUserManageVO(form)){
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
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="rlms-ide-wrap user-manage-wrap">
    <aside class="rlms-ide-left user-manage-left">
        <div class="ide-actions-tit">시스템 관리</div>
        <nav class="ide-actions">
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">사용자 / 권한</h5>
                <a href="<c:url value='/uss/umt/EgovUserManage.do'/>" class="ide-action active">업무사용자관리</a>
                <a href="<c:url value='/sec/ram/EgovAuthorList.do'/>" class="ide-action">권한관리</a>
                <a href="<c:url value='/sec/rmt/EgovRoleList.do'/>" class="ide-action">역할관리</a>
                <a href="<c:url value='/sec/drm/EgovDeptAuthorList.do'/>" class="ide-action">부서권한관리</a>
            </div>
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">메뉴 / 프로그램</h5>
                <a href="<c:url value='/sym/prm/EgovProgramListManageSelect.do'/>" class="ide-action">프로그램관리</a>
                <a href="<c:url value='/sym/mnu/mpm/EgovMenuManageSelect.do'/>" class="ide-action">메뉴목록 관리</a>
                <a href="<c:url value='/sym/mnu/mpm/EgovMenuListSelect.do'/>" class="ide-action">메뉴 생성</a>
                <a href="<c:url value='/sym/mnu/mcm/EgovMenuCreatManageSelect.do'/>" class="ide-action">메뉴생성 관리</a>
                <a href="<c:url value='/sym/mnu/stm/EgovSiteMapng.do'/>" class="ide-action">사이트맵</a>
            </div>
            <div class="ide-actions-group">
                <h5 class="ide-actions-group-label">코드 / 설정</h5>
                <a href="<c:url value='/sym/ccm/ccm/EgovCcmCmmnCodeManage.do'/>" class="ide-action">공통코드</a>
            </div>
        </nav>
    </aside>

    <main class="rlms-ide-main user-manage-main">
<div class="faq-ide-page">
    <div class="faq-ide-head">
        <div>
            <span class="faq-ide-kicker">User / Management</span>
            <h1>${pageTitle} <spring:message code="title.create" /></h1>
        </div>
        <span class="faq-ide-state">신규 작성</span>
    </div>

    <form:form modelAttribute="userManageVO" action="${pageContext.request.contextPath}/uss/umt/EgovUserInsert.do" name="userManageVO" method="post" cssClass="krds-form" onSubmit="fnInsert(document.forms[0]); return false;">
        <c:set var="inputTxt"><spring:message code="input.input" /></c:set>
        <c:set var="inputSelect"><spring:message code="input.select"/></c:set>

        <div class="faq-ide-shell">
            <main class="rlms-ide-main faq-ide-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>업무사용자 정보 편집</h2>
                        <span class="ide-prov-status new">등록</span>
                    </div>

                    <div class="user-form-grid">
                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.id"/></c:set>
                        <div class="user-form-row">
                            <label for="emplyrId">${title} <span class="required-mark">*</span></label>
                            <div class="user-inline-control">
                                <form:input path="emplyrId" id="emplyrId" cssClass="krds-input" title="${title} ${inputTxt}" readonly="true" maxlength="20" />
                                <button id="btnEmplyrId" type="button" class="krds-btn secondary medium" onClick="return false;" title="<spring:message code="comUssUmt.deptUserManageRegistBtn.idSearch" /> <spring:message code="input.button" />"><spring:message code="comUssUmt.deptUserManageRegistBtn.idSearch" /></button>
                            </div>
                            <form:errors path="emplyrId" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.name"/></c:set>
                        <div class="user-form-row">
                            <label for="emplyrNm">${title} <span class="required-mark">*</span></label>
                            <form:input path="emplyrNm" id="emplyrNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="60" />
                            <form:errors path="emplyrNm" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.pass"/></c:set>
                        <div class="user-form-row">
                            <label for="password">${title} <span class="required-mark">*</span></label>
                            <form:password path="password" id="password" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="20" />
                            <form:errors path="password" cssClass="form-hint-invalid" />
                            <ul class="password-guides">
                                <li><spring:message code="info.password.rule.password1" /></li>
                                <li><spring:message code="info.password.rule.pwdcheckcomb3" /></li>
                                <li><spring:message code="info.password.rule.pwdcheckseries" /></li>
                            </ul>
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.passConfirm"/></c:set>
                        <div class="user-form-row">
                            <label for="password2">${title} <span class="required-mark">*</span></label>
                            <input name="password2" id="password2" class="krds-input" title="${title} ${inputTxt}" type="password" maxlength="20" />
                        </div>

                        <%-- 2026-07-27 불용 필드 정리 — 비밀번호힌트·정답·생일·전화번호(집 3분할)·집전화번호·
                             우편번호·주소·상세주소 제거, 팩스번호(fxnum) 라벨 정정 유지 --%>
                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.insttCode"/></c:set>
                        <div class="user-form-row">
                            <label for="insttCode">${title}</label>
                            <form:select path="insttCode" id="insttCode" cssClass="krds-input" title="${title} ${inputSelect}">
                                <form:option value="" label="${inputSelect}"/>
                                <form:options items="${insttCode_result}" itemValue="code" itemLabel="codeNm"/>
                            </form:select>
                            <form:errors path="insttCode" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.orgnztId"/></c:set>
                        <%-- 부서 = 검색 선택 (규정편집기 소관부서 패턴, buseoListJson 재사용 — 2026-07-27) --%>
                        <div class="user-form-row">
                            <label for="orgnztNmDisp">${title}</label>
                            <div class="user-tel-group">
                                <form:hidden path="orgnztId" id="orgnztId"/>
                                <c:set var="curOrgnztNm" value=""/>
                                <c:forEach var="og" items="${orgnztId_result}"><c:if test="${og.code eq userManageVO.orgnztId}"><c:set var="curOrgnztNm" value="${og.codeNm}"/></c:if></c:forEach>
                                <input type="text" id="orgnztNmDisp" class="krds-input" readonly placeholder="(미지정)" style="text-align:left;" value="<c:out value='${curOrgnztNm}'/>"/>
                                <button type="button" class="krds-btn secondary medium" style="flex:0 0 auto;" onclick="fnOpenBuseoModal();">선택</button>
                                <button type="button" class="krds-btn secondary medium" style="flex:0 0 auto;" onclick="fnClearBuseo();">지움</button>
                            </div>
                            <form:errors path="orgnztId" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.ofcps"/></c:set>
                        <div class="user-form-row">
                            <label for="ofcpsNm">${title}</label>
                            <form:input path="ofcpsNm" id="ofcpsNm" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="50" />
                            <form:errors path="ofcpsNm" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.emplNum"/></c:set>
                        <div class="user-form-row">
                            <label for="emplNo">${title}</label>
                            <form:input path="emplNo" id="emplNo" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="20" />
                            <form:errors path="emplNo" cssClass="form-hint-invalid" />
                        </div>

                        <%-- 성별 항목 제거 (2026-07-27 지시) --%>

                        <c:set var="title">팩스번호</c:set>
                        <div class="user-form-row">
                            <label for="fxnum">${title}</label>
                            <form:input path="fxnum" id="fxnum" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="15" />
                            <form:errors path="fxnum" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.phone"/></c:set>
                        <div class="user-form-row">
                            <label for="moblphonNo">${title} <span class="required-mark">*</span></label>
                            <form:input path="moblphonNo" id="moblphonNo" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="15" />
                            <form:errors path="moblphonNo" cssClass="form-hint-invalid" />
                        </div>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.email"/></c:set>
                        <div class="user-form-row">
                            <label for="emailAdres">${title} <span class="required-mark">*</span></label>
                            <form:input path="emailAdres" id="emailAdres" cssClass="krds-input" title="${title} ${inputTxt}" maxlength="50" />
                            <form:errors path="emailAdres" cssClass="form-hint-invalid" />
                        </div>

                        <%-- 권한그룹 — 화면 선택 제거(2026-07-27 지시). groupId 는 필수값(검증규칙·INSERT)이라
                             기본그룹(목록 첫 항목)을 hidden 으로 제출. 역할 부여는 권한관리 화면에서. --%>
                        <c:set var="defGroupId" value=""/>
                        <c:forEach var="g" items="${groupId_result}" varStatus="st"><c:if test="${st.first}"><c:set var="defGroupId" value="${g.code}"/></c:if></c:forEach>
                        <input type="hidden" name="groupId" id="groupId" value="<c:out value='${defGroupId}'/>"/>

                        <c:set var="title"><spring:message code="comUssUmt.deptUserManageRegist.status"/></c:set>
                        <div class="user-form-row">
                            <label for="emplyrSttusCode">${title} <span class="required-mark">*</span></label>
                            <form:select path="emplyrSttusCode" id="emplyrSttusCode" cssClass="krds-input" title="${title} ${inputSelect}">
                                <form:option value="" label="${inputSelect}"/>
                                <form:options items="${emplyrSttusCode_result}" itemValue="code" itemLabel="codeNm"/>
                            </form:select>
                            <form:errors path="emplyrSttusCode" cssClass="form-hint-invalid" />
                        </div>
                    </div>

                    <div class="ide-form-actions">
                        <button type="button" class="krds-btn secondary medium" onclick="fnListPage(); return false;" title="<spring:message code="button.list" /> <spring:message code="input.button" />"><spring:message code="button.list" /></button>
                        <button type="submit" class="krds-btn primary medium" title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></button>
                    </div>
                </div>
            </main>

            <aside class="rlms-ide-right faq-ide-right">
                <h3 class="ide-related-tit">사용자 작업정보</h3>
                <div class="faq-side-block">
                    <span class="faq-side-label">상태</span>
                    <p class="faq-side-text">신규 업무사용자를 등록합니다.</p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label">아이디</span>
                    <p class="faq-side-text">중복 확인 후 사용할 아이디가 입력됩니다.</p>
                </div>
                <div class="faq-side-block">
                    <span class="faq-side-label">필수 정보</span>
                    <p class="faq-side-text">아이디, 이름, 비밀번호, 연락처, 이메일, 주소, 그룹과 상태를 확인해 주세요.</p>
                </div>
            </aside>
        </div>

        <form:hidden path="subDn" />
        <input type="hidden" name="searchCondition" value="<c:out value='${userSearchVO.searchCondition}'/>"/>
        <input type="hidden" name="searchKeyword" value="<c:out value='${userSearchVO.searchKeyword}'/>"/>
        <input type="hidden" name="sbscrbSttus" value="<c:out value='${userSearchVO.sbscrbSttus}'/>"/>
        <input type="hidden" name="pageIndex" value="<c:out value='${userSearchVO.pageIndex}'/>"/>
    </form:form>
</div>
    </main>
</div>

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
