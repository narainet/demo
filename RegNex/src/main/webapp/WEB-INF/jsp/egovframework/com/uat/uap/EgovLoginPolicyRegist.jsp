<%-- Login policy registration --%>
<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="validator" uri="http://www.springmodules.org/tags/commons-validator" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comUatUap.loginPolicyRegist.title"/></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<link href="<c:url value='/css/egovframework/com/com.css' />" rel="stylesheet" type="text/css">
<link href="<c:url value='/css/egovframework/com/button.css' />" rel="stylesheet" type="text/css">
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="loginPolicy" staticJavascript="false" xhtml="true" cdata="false"/>
<script type="text/javascript">
function fncSelectLoginPolicyList() {
    var varFrom = document.getElementById("loginPolicy");
    varFrom.action = "<c:url value='/uat/uap/selectLoginPolicyList.do'/>";
    varFrom.method = "get";
    varFrom.submit();
}

function fncLoginPolicyInsert() {
    var varFrom = document.getElementById("loginPolicy");
    varFrom.action = "<c:url value='/uat/uap/addLoginPolicy.do'/>";
    if (confirm("<spring:message code='comUatUap.loginPolicyRegist.validate.confirm.save'/>")) {
        if (!validateLoginPolicy(varFrom)) {
            return;
        }
        if (ipValidate()) {
            varFrom.submit();
        }
    }
}

function ipValidate() {
    var varFrom = document.getElementById("loginPolicy");
    var IPvalue = varFrom.ipInfo.value;
    var ipPattern = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
    var ipArray = IPvalue.match(ipPattern);
    var result = true;

    if (IPvalue == "0.0.0.0" || IPvalue == "255.255.255.255") {
        alert(IPvalue + " : <spring:message code='comUatUap.loginPolicyRegist.validate.info.exceptionIP'/>");
        return false;
    }
    if (ipArray == null) {
        alert("<spring:message code='comUatUap.loginPolicyRegist.validate.info.invalidForm'/>");
        return false;
    }
    for (var i = 1; i < 5; i++) {
        if (ipArray[i] > 255) {
            alert("<spring:message code='comUatUap.loginPolicyRegist.validate.info.invalidForm'/>");
            result = false;
        }
    }
    return result;
}
</script>
<style>
.login-policy-page { display:flex; flex-direction:column; gap:14px; min-width:0; }
.login-policy-head { display:flex; align-items:center; justify-content:space-between; gap:16px; padding:14px 18px; border:1px solid #d1d3d8; border-radius:6px; background:#fff; }
.login-policy-kicker { display:block; margin-bottom:4px; color:#52617a; font-size:13px; font-weight:600; }
.login-policy-head h1 { margin:0; color:#1f3974; font-size:24px; line-height:1.35; }
.login-policy-state { flex:0 0 auto; padding:5px 10px; border-radius:4px; background:#e8edf9; color:#1f3974; font-size:13px; font-weight:700; }
.login-policy-shell { display:grid; grid-template-columns:minmax(0, 1fr) 300px; min-height:520px; border:1px solid #d1d3d8; border-radius:6px; overflow:hidden; background:#fff; }
.login-policy-main { min-height:520px; border-right:1px solid #d1d3d8; }
.login-policy-main .ide-context-pane { padding:24px; }
.login-policy-main .ide-prov-head { display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap; margin-bottom:18px; padding-bottom:14px; border-bottom:1px solid #e1e5ee; }
.login-policy-main .ide-prov-head h2 { margin:0; color:#1f3974; font-size:21px; line-height:1.35; }
.login-policy-main .ide-prov-status { display:inline-flex; align-items:center; min-height:28px; padding:0 10px; border-radius:4px; background:#edf3ff; color:#1f3974; font-size:13px; font-weight:700; }
.login-policy-grid { display:grid; grid-template-columns:repeat(2, minmax(0, 1fr)); gap:18px 20px; }
.login-policy-row { display:flex; flex-direction:column; gap:7px; min-width:0; }
.login-policy-row.login-policy-full { grid-column:1 / -1; }
.login-policy-row label { color:#1f2937; font-size:14px; font-weight:700; }
.login-policy-row .krds-input,
.login-policy-row .krds-select { width:100%; max-width:100%; min-height:40px; box-sizing:border-box; }
.login-policy-row .krds-input[readonly] { background:#f8f9fb; color:#555; }
.login-policy-main .form-hint-invalid,
.login-policy-main .error { display:block; margin-top:6px; color:#d4351c; font-size:13px; }
.login-policy-main .ide-form-actions { display:flex; justify-content:flex-end; gap:8px; flex-wrap:wrap; margin-top:22px; padding-top:16px; border-top:1px solid #e1e5ee; }
.required-mark { color:#d4351c; font-weight:700; }
.login-policy-right { min-height:520px; background:#243b68; color:#fff; }
.login-policy-side-block { padding:14px 16px; border-bottom:1px solid rgba(255,255,255,0.15); }
.login-policy-side-label { display:block; margin-bottom:7px; color:rgba(255,255,255,0.74); font-size:12px; font-weight:700; }
.login-policy-side-text { margin:0; color:rgba(255,255,255,0.82); font-size:13px; line-height:1.6; word-break:keep-all; }
.login-policy-side-value { margin:0; color:#fff; font-size:14px; line-height:1.5; word-break:break-word; }
@media (max-width:1024px) {
  .login-policy-shell { grid-template-columns:1fr; }
  .login-policy-main { border-right:0; border-bottom:1px solid #d1d3d8; }
  .login-policy-right { min-height:0; }
}
@media (max-width:768px) {
  .login-policy-head { align-items:flex-start; flex-direction:column; }
  .login-policy-state { align-self:flex-start; }
  .login-policy-main .ide-context-pane { padding:18px; }
  .login-policy-grid { grid-template-columns:1fr; }
  .login-policy-main .ide-form-actions { justify-content:flex-start; }
}
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<div class="login-policy-page">
    <div class="login-policy-head">
        <div>
            <span class="login-policy-kicker">&#47196;&#44536;&#51064;&#51221;&#52293;&#44288;&#47532;</span>
            <h1><spring:message code="comUatUap.loginPolicyRegist.pageTop.title"/></h1>
        </div>
        <span class="login-policy-state">&#49888;&#44508; &#46321;&#47197;</span>
    </div>

    <form:form modelAttribute="loginPolicy" id="loginPolicy" method="post" action="${pageContext.request.contextPath}/uat/uap/addLoginPolicy.do" cssClass="krds-form login-policy-form">
        <div class="login-policy-shell">
            <main class="rlms-ide-main login-policy-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>&#51221;&#52293; &#51221;&#48372;</h2>
                        <span class="ide-prov-status">&#51089;&#49457;&#51473;</span>
                    </div>

                    <div class="login-policy-grid">
                        <div class="login-policy-row">
                            <label for="emplyrId"><spring:message code="comUatUap.loginPolicyRegist.emplyrId"/> <span class="required-mark">*</span></label>
                            <input id="emplyrId" name="emplyrId" class="krds-input" type="text" value="<c:out value='${loginPolicy.emplyrId}'/>" title="<spring:message code='comUatUap.loginPolicyRegist.emplyrId'/>" maxlength="30" readonly="readonly">
                            <input name="emplyrIdEncrypt" id="emplyrIdEncrypt" value="${egovc:encrypt(loginPolicy.emplyrId)}" type="hidden">
                        </div>

                        <div class="login-policy-row">
                            <label for="emplyrNm"><spring:message code="comUatUap.loginPolicyRegist.emplyrNm"/> <span class="required-mark">*</span></label>
                            <input id="emplyrNm" type="text" name="emplyrNm" class="krds-input" value="<c:out value='${loginPolicy.emplyrNm}'/>" title="<spring:message code='comUatUap.loginPolicyRegist.emplyrNm'/>" maxlength="50" readonly="readonly">
                        </div>

                        <div class="login-policy-row">
                            <label for="ipInfo"><spring:message code="comUatUap.loginPolicyRegist.ipInfo"/> <span class="required-mark">*</span></label>
                            <input id="ipInfo" type="text" name="ipInfo" class="krds-input" title="<spring:message code='comUatUap.loginPolicyRegist.ipInfo'/>" maxlength="23">
                            <form:errors path="ipInfo" cssClass="form-hint-invalid" />
                        </div>

                        <div class="login-policy-row">
                            <label for="lmttAt"><spring:message code="comUatUap.loginPolicyRegist.lmttAt"/> <span class="required-mark">*</span></label>
                            <select name="lmttAt" id="lmttAt" class="krds-select" title="<spring:message code='comUatUap.loginPolicyRegist.lmttAt'/>">
                                <option value="Y">Y</option>
                                <option value="N">N</option>
                            </select>
                            <form:errors path="lmttAt" cssClass="form-hint-invalid" />
                        </div>
                    </div>

                    <div class="ide-form-actions">
                        <button type="button" class="krds-btn primary medium" onclick="fncLoginPolicyInsert();"><spring:message code="button.save" /></button>
                        <button type="button" class="krds-btn secondary medium" onclick="fncSelectLoginPolicyList();"><spring:message code="button.list" /></button>
                    </div>
                </div>
            </main>

            <aside class="rlms-ide-right login-policy-right">
                <div class="login-policy-side-block">
                    <span class="login-policy-side-label">&#49324;&#50857;&#51088; ID</span>
                    <p class="login-policy-side-value"><c:out value="${loginPolicy.emplyrId}"/></p>
                </div>
                <div class="login-policy-side-block">
                    <span class="login-policy-side-label">IP</span>
                    <p class="login-policy-side-text">&#46321;&#47197;&#54624; &#49324;&#50857;&#51088;&#51032; &#51217;&#49549; IP &#51221;&#52293;&#51012; &#51077;&#47141;&#54633;&#45768;&#45796;.</p>
                </div>
            </aside>
        </div>

        <input type="hidden" name="dplctPermAt" value="Y">
        <input type="hidden" name="searchCondition" value="<c:out value='${loginPolicyVO.searchCondition}'/>">
        <input type="hidden" name="searchKeyword" value="<c:out value='${loginPolicyVO.searchKeyword}'/>">
        <input type="hidden" name="pageIndex" value="<c:out value='${loginPolicyVO.pageIndex}'/>">
    </form:form>
</div>
</lay:layout>
