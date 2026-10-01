<%--
 /**
  * @Class Name : EgovProgramListDetailSelectUpdt.jsp
  * @Description : 프로그램목록 상세조회및 수정 화면
  * @Modification Ination
  * @
  * @  수정일              수정자            수정내용
  * @ ----------   --------   ---------------------------
  * @ 2009.03.10   이용			최초 생성
  *   2018.09.03   신용호		공통컴포넌트 3.8 개선
  *   2024.10.29   권태성		수정 페이지 신규 경로로 변경
  *
  *  @author 공통서비스 개발팀 이용
  *  @since 2009.03.10
  *  @version 1.0
  *  @see
  *
  */
  /* Image Path 설정 */
  //String imagePath_icon   = "/images/egovframework/com/sym/prm/icon/";
  //String imagePath_button = "/images/egovframework/com/sym/prm/button/";
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
<c:set var="pageTitle"><spring:message code="comSymPrm.programListDetailSelectUpdt.title"/></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<!-- 프로그램목록 상세조회 /수정 -->
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<script type="text/javascript" src="<c:url value="/validator.do"/>"></script>
<validator:javascript formName="progrmManageVO" staticJavascript="false" xhtml="true" cdata="false"/>
<script language="javascript1.2" type="text/javaScript">
<!--
/* ********************************************************
 * 수정처리 함수
 ******************************************************** */
function updateProgramListManage(form) {
	if(confirm("<spring:message code="common.save.msg" />")){
		if(!validateProgrmManageVO(form)){
			return;
		}else{
            form.action="<c:url value='/sym/prm/EgovProgramListDetailSelectUpdt.do' />";
			form.submit();
		}
	}
}

/* ********************************************************
 * 삭제처리함수
 ******************************************************** */
function deleteProgramListManage(form) {
	if(confirm("<spring:message code="common.delete.msg" />")){
        form.action="<c:url value='/sym/prm/EgovProgramListManageDelete.do' />";
		form.submit();
	}
}

/* ********************************************************
 * 목록조회 함수
 ******************************************************** */
function selectList(){
	
    var varForm = document.getElementById("progrmManageVO");
    varForm.action = "<c:url value='/sym/prm/EgovProgramListManageSelect.do' />";
    varForm.submit();

}
<c:if test="${!empty resultMsg}">alert("${resultMsg}");</c:if>
-->
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<c:set var="vprogrmFileNm"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmFileNm"/></c:set>
<c:set var="vprogrmStrePath"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmStrePath"/></c:set>
<c:set var="vprogrmKoreanNm"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmKoreanNm"/></c:set>
<c:set var="vprogrmDc"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmDc"/></c:set>
<c:set var="vurl"><spring:message code="comSymPrm.programListDetailSelectUpdt.url"/></c:set>

<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>
<div class="program-form-page">
    <div class="program-form-head">
        <div>
            <span class="program-form-kicker">System / Program</span>
            <h1><spring:message code="comSymPrm.programListDetailSelectUpdt.pageTop.title"/></h1><!-- 프로그램목록 상세조회 /수정 -->
        </div>
        <span class="program-form-state">수정</span>
    </div>

<form:form id="progrmManageVO" modelAttribute="progrmManageVO" method="post" action="${pageContext.request.contextPath}/sym/prm/EgovProgramListDetailSelectUpdt.do" cssClass="krds-form program-form">
    <!-- 검색조건 유지 -->
    <input type="hidden" name="searchCondition" value="<c:out value='${searchVO.searchCondition}'/>"/>
    <input type="hidden" name="searchKeyword" value="<c:out value='${searchVO.searchKeyword}'/>"/>
    <input type="hidden" name="pageIndex" value="<c:out value='${searchVO.pageIndex}' default='1' />"/>

        <div class="program-form-shell">
            <main class="rlms-ide-main program-form-main">
                <div class="ide-context-pane">
                    <div class="ide-prov-head">
                        <h2>프로그램 정보 수정</h2>
                        <span class="ide-prov-status exist">저장됨</span>
                    </div>

                    <div class="ide-form-row">
                        <label for="progrmFileNm"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmFileNm"/> <span class="required">*</span></label>
                        <form:input path="progrmFileNm" maxlength="50" title="${vprogrmFileNm}" readonly="true" cssClass="krds-input"/>
                    </div>

                    <div class="ide-form-row">
                        <label for="progrmStrePath"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmStrePath"/> <span class="required">*</span></label>
                        <form:input path="progrmStrePath" maxlength="50" title="${vprogrmStrePath}" cssClass="krds-input"/>
                        <form:errors path="progrmStrePath" cssClass="form-hint-invalid"/>
                    </div>

                    <div class="ide-form-row">
                        <label for="progrmKoreanNm"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmKoreanNm"/> <span class="required">*</span></label>
                        <form:input path="progrmKoreanNm" maxlength="60" title="${vprogrmKoreanNm}" cssClass="krds-input"/>
                        <form:errors path="progrmKoreanNm" cssClass="form-hint-invalid" />
                    </div>

                    <div class="ide-form-row">
                        <label for="URL"><spring:message code="comSymPrm.programListDetailSelectUpdt.url"/> <span class="required">*</span></label>
                        <form:input path="URL" maxlength="60" title="${vurl}" cssClass="krds-input"/>
                        <form:errors path="URL" cssClass="form-hint-invalid" />
                    </div>

                    <div class="ide-form-row">
                        <label for="progrmDc"><spring:message code="comSymPrm.programListDetailSelectUpdt.progrmDc"/> <span class="required">*</span></label>
                        <form:textarea path="progrmDc" rows="10" title="${vprogrmDc}" cssClass="krds-input program-textarea"/>
                        <form:errors path="progrmDc" cssClass="form-hint-invalid"/>
                    </div>

                    <div class="ide-form-actions">
                        <button type="button" class="krds-btn secondary medium" onclick="selectList(); return false;"><spring:message code="button.list"/></button>
                        <button type="button" class="krds-btn danger medium" onclick="deleteProgramListManage(document.forms[0]); return false;"><spring:message code="button.delete" /></button>
                        <button type="submit" class="krds-btn primary medium" onclick="updateProgramListManage(document.forms[0]); return false;"><spring:message code="button.update" /></button>
                    </div>
                </div>
            </main>

            <aside class="program-form-side">
                <h3 class="program-side-title">작업 정보</h3>
                <div class="program-side-block">
                    <span class="program-side-label">프로그램 파일명</span>
                    <p class="program-side-value"><c:out value="${progrmManageVO.progrmFileNm}" /></p>
                </div>
                <div class="program-side-block">
                    <span class="program-side-label">상태</span>
                    <p class="program-side-text">등록된 프로그램 정보를 수정합니다.</p>
                </div>
            </aside>
        </div>

<input name="cmd" type="hidden" value="<c:out value='update'/>"/>
</form:form>
</div>
</lay:layout>
