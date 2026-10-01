<%--
 /**
  * @Class Name : EgovProgramListRegist.jsp
  * @Description : 프로그램목록 등록 화면
  * @Modification Information
  * @
  * @  수정일              수정자            수정내용
  * @ ----------   --------   ---------------------------
  * @ 2009.03.10   이용			최초 생성
  *   2018.09.03   신용호		공통컴포넌트 3.8 개선
  *   2024.10.29   권태성		등록 페이지 신규 경로로 변경
  *
  *  @author 공통서비스 개발팀 이용
  *  @since 2009.03.10
  *  @version 1.0
  *  @see
  *
  */
  /* Image Path 설정 */
  //String imagePath_icon   = "/images/egovframework/com/sym/prm/icon/";
 // String imagePath_button = "/images/egovframework/com/sym/prm/button/";
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
<c:set var="ImgUrl" value="/images/egovframework/com/sym/prm/"/>
<c:set var="CssUrl" value="/css/egovframework/com/sym/prm/"/>
<c:set var="pageTitle"><spring:message code="comSymPrm.programListRegist.title" /></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<!-- 프로그램목록등록 -->
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<script type="text/javascript" src="<c:url value="/validator.do" />"></script>
<validator:javascript formName="progrmManageVO" staticJavascript="false" xhtml="true" cdata="false"/>
<script language="javascript1.2" type="text/javaScript">
<!--
/* ********************************************************
 * 입력 처리 함수
 ******************************************************** */
function insertProgramListManage(form) {
	if(confirm("<spring:message code="common.save.msg"/>")){
		if(!validateProgrmManageVO(form)){
			return;
		}else{

			form.submit();
		}
	}
}
/* ********************************************************
 * 목록조회 함수
 ******************************************************** */
function selectList(){
	location.href = "<c:url value='/sym/prm/EgovProgramListManageSelect.do' />";
}

/* ********************************************************
 * focus 시작점 지정함수
 ******************************************************** */
 function fn_FocusStart(){
		var objFocus = document.getElementById('F1');
		objFocus.focus();
	}


<c:if test="${!empty resultMsg}">alert("${resultMsg}");</c:if>
-->
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<c:set var="vprogrmFileNm"><spring:message code="comSymPrm.programListRegist.progrmFileNm"/></c:set>
<c:set var="vprogrmStrePath"><spring:message code="comSymPrm.programListRegist.progrmStrePath"/></c:set>
<c:set var="vprogrmKoreanNm"><spring:message code="comSymPrm.programListRegist.progrmKoreanNm"/></c:set>
<c:set var="vprogrmDc"><spring:message code="comSymPrm.programListRegist.progrmDc"/></c:set>
<c:set var="vurl"><spring:message code="comSymPrm.programListDetailSelectUpdt.url"/></c:set>

<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>
<div class="program-form-page">
    <div class="program-form-head">
        <div>
            <span class="program-form-kicker">System / Program</span>
            <h1><spring:message code="comSymPrm.programListRegist.pageTop.title" /></h1><!-- 프로그램목록 등록 -->
        </div>
        <span class="program-form-state">등록</span>
    </div>

    <form:form id="progrmManageVO" modelAttribute="progrmManageVO" method="post" action="${pageContext.request.contextPath}/sym/prm/EgovProgramListRegist.do" cssClass="krds-form program-form">
        <div class="program-form-shell">
            <main class="rlms-ide-main program-form-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>프로그램 정보 입력</h2>
                        <span class="ide-prov-status new">신규</span>
                    </div>

                    <div class="ide-form-row">
                        <label for="F1"><spring:message code="comSymPrm.programListRegist.progrmFileNm"/> <span class="required">*</span></label>
                        <form:input path="progrmFileNm" maxlength="50" id="F1" cssClass="krds-input" title="${vprogrmFileNm}"/>
                        <form:errors path="progrmFileNm" cssClass="form-hint-invalid" />
                    </div>

                    <div class="ide-form-row">
                        <label for="progrmStrePath"><spring:message code="comSymPrm.programListRegist.progrmStrePath"/> <span class="required">*</span></label>
                        <form:input path="progrmStrePath" maxlength="60" cssClass="krds-input" title="${vprogrmStrePath}"/>
                        <form:errors path="progrmStrePath" cssClass="form-hint-invalid" />
                    </div>

                    <div class="ide-form-row">
                        <label for="progrmKoreanNm"><spring:message code="comSymPrm.programListRegist.progrmKoreanNm"/> <span class="required">*</span></label>
                        <form:input path="progrmKoreanNm" maxlength="60" cssClass="krds-input" title="${vprogrmKoreanNm}"/>
                        <form:errors path="progrmKoreanNm" cssClass="form-hint-invalid"/>
                    </div>

                    <div class="ide-form-row">
                        <label for="URL"><spring:message code="comSymPrm.programListRegist.url"/> <span class="required">*</span></label>
                        <form:input path="URL" maxlength="60" cssClass="krds-input" title="${vurl}"/>
                        <form:errors path="URL" cssClass="form-hint-invalid"/>
                    </div>

                    <div class="ide-form-row">
                        <label for="progrmDc"><spring:message code="comSymPrm.programListRegist.progrmDc"/> <span class="required">*</span></label>
                        <form:textarea path="progrmDc" rows="10" cssClass="krds-input program-textarea" title="${vprogrmDc}"/>
                        <form:errors path="progrmDc" cssClass="form-hint-invalid"/>
                    </div>

                    <div class="ide-form-actions">
                        <button type="button" class="krds-btn secondary medium" onclick="selectList(); return false;"><spring:message code="button.list" /></button>
                        <button type="submit" class="krds-btn primary medium" onclick="insertProgramListManage(document.forms[0]); return false;"><spring:message code="button.save" /></button>
                    </div>
                </div>
            </main>

            <aside class="program-form-side">
                <h3 class="program-side-title">작업 정보</h3>
                <div class="program-side-block">
                    <span class="program-side-label">상태</span>
                    <p class="program-side-text">새 프로그램 정보를 등록합니다.</p>
                </div>
                <div class="program-side-block">
                    <span class="program-side-label">URL</span>
                    <p class="program-side-text">메뉴와 연결할 실제 요청 경로를 입력합니다.</p>
                </div>
            </aside>
        </div>

        <input name="cmd" type="hidden" value="<c:out value='insert'/>"/>
    </form:form>
</div>
</lay:layout>
