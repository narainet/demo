<%--
  Class Name : EgovPopupContent.jsp
  Description : 팝업창관리 - 직접편집(에디터) 모드 본문 렌더링
                CN_SE='E' 인 팝업의 DB 저장 HTML(POPUP_CN)을 출력한다.

      수정일         수정자                   수정내용
    -------    --------    ---------------------------
     2026.06.25    -            최초 생성 (팝업 내용 2-모드)
--%>
<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 관리자가 CKEditor 로 작성한 HTML(POPUP_CN) 원문을 그대로 출력 (escape 안 함) --%>
<c:set var="pageTitle"><c:out value="${popupTitleNm}"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">

<script type="text/javaScript" language="javascript">
/* ********************************************************
 * 그만보기(쿠키) 설정
 ******************************************************** */
function fnSetCookiePopup( name, value, expiredays ) {
	var todayDate = new Date();
	todayDate.setDate( todayDate.getDate() + expiredays );
	document.cookie = name + "=" + escape( value ) + "; path=/; expires=" + todayDate.toGMTString() + ";"
}
/* ********************************************************
 * 다음부터 창 열지 않기 체크
 ******************************************************** */
function fnPopupCheck() {
	fnSetCookiePopup( "${popupId}", "done" , 365);
	window.close();
}
</script>
<style type="text/css">
<!--
body { margin:0; padding:0; }
#popupContent { display:block; padding:12px; word-break:break-all; line-height:1.5; }
#popupBottom { display:block; padding:6px 12px; font-size:9pt; border-top:1px solid #e0e0e0; background:#f7f7f7; }
//-->
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<div id="popupContent">
	${popupCn}
</div>
<%-- embed=Y(홈 인페이지 모달) 이면 그만보기/닫기는 부모 카드가 제공 → 자체 푸터 숨김. 직접 window.open 일 때만 표시 --%>
<c:if test="${param.embed ne 'Y'}">
<div id="popupBottom">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg"/></noscript>
<c:if test="${stopVewAt eq 'Y'}">
<label><input type="checkbox" name="chkPopup" value="" onClick="fnPopupCheck()" title="다음부터창열지않기체크"> <spring:message code="ussIonPwm.popupSample.checkBox"/></label>
</c:if>
</div>
</c:if>
</lay:layout>
