<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%
 /**
  * @Class Name : EgovMenuCreatManage.jsp
  * @Description : 메뉴생성관리 조회 화면
  * @Modification Information
  * @
  * @ 수정일               수정자             수정내용
  * @ ----------   --------   ---------------------------
  * @ 2009.03.10   이용               최초 생성
  *   2018.09.10   신용호            표준프레임워크 v3.8 개선
  *
  *  @author 공통서비스 개발팀 이용
  *  @since 2009.03.10
  *  @version 1.0
  *  @see
  *
  */

  /* Image Path 설정 */
  String imagePath_icon   = "/images/egovframework/com/sym/mnu/mcm/icon/";
  String imagePath_button = "/images/egovframework/com/sym/mnu/mcm/button/";
%>
<c:set var="pageTitle"><spring:message code="comSymMnuMpm.menuCreatManage.title" /></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<!-- 메뉴생성관리 -->
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<script  language="javascript1.2" type="text/javaScript">
<!--
/* ********************************************************
 * 최초조회 함수
 ******************************************************** */
function fMenuCreatManageSelect(){
    document.menuCreatManageForm.action = "<c:url value='/sym/mnu/mcm/EgovMenuCreatManageSelect.do'/>";
    document.menuCreatManageForm.submit();
}

/* ********************************************************
 * 페이징 처리 함수
 ******************************************************** */
function linkPage(pageNo){
	document.menuCreatManageForm.pageIndex.value = pageNo;
	document.menuCreatManageForm.action = "<c:url value='/sym/mnu/mcm/EgovMenuCreatManageSelect.do'/>";
   	document.menuCreatManageForm.submit();
}

/* ********************************************************
 * 조회 처리 함수
 ******************************************************** */
function selectMenuCreatManageList() {
	document.menuCreatManageForm.pageIndex.value = 1;
    document.menuCreatManageForm.action = "<c:url value='/sym/mnu/mcm/EgovMenuCreatManageSelect.do'/>";
    document.menuCreatManageForm.submit();
}

function press(e) {
    var eventObj = e || window.event;
    if (eventObj.keyCode == 13) {
        if (eventObj.preventDefault) {
            eventObj.preventDefault();
        }
        selectMenuCreatManageList();
        return false;
    }
    return true;
}

/* ********************************************************
 * 메뉴생성 화면 호출
 ******************************************************** */
function selectMenuCreat(vAuthorCode) {
	document.menuCreatManageForm.authorCode.value = vAuthorCode;
   	document.menuCreatManageForm.action = "<c:url value='/sym/mnu/mcm/EgovMenuCreatSelect.do'/>";
   	document.menuCreatManageForm.submit();
}

/* ********************************************************
 * 메뉴 캐시 새로고침 — 변경한 메뉴/권한매핑을 GNB 에 즉시 반영 (MenuHelper.clearCache)
 ******************************************************** */
function fncReloadMenu() {
	if(!confirm("변경한 메뉴/권한 매핑을 지금 적용할까요?\n(GNB 메뉴 캐시를 비워 즉시 반영됩니다)")) return;
	fetch("<c:url value='/rlms/mgr/reloadMenu.do'/>", { method: "POST" })
		.then(function(r){ return r.json(); })
		.then(function(res){ alert(res.message || (res.success ? "적용되었습니다." : "적용 실패")); })
		.catch(function(e){ alert("요청 실패: " + e); });
}
<c:if test="${!empty resultMsg}">alert("${resultMsg}");</c:if>
-->
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript><!-- 자바스크립트를 지원하지 않는 브라우저에서는 일부 기능을 사용하실 수 없습니다. -->

<div class="program-manage-list menu-creat-manage-list">
	<div class="page-header">
		<h1><spring:message code="comSymMnuMpm.menuCreatManage.pageTop.title" /></h1><!-- 메뉴생성관리 -->
	</div>

	<form name="menuCreatManageForm" action ="<c:url value='/sym/mnu/mcm/EgovMenuCreatManageSelect.do'/>" method="post" class="krds-form" onsubmit="selectMenuCreatManageList(); return false;">
	<input name="checkedMenuNoForDel" type="hidden" />
	<input name="authorCode"          type="hidden" />
	<input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>"/>

	<div class="search-form program-search menu-creat-search" title="<spring:message code="common.searchCondition.msg" />"><!-- 이 레이아웃은 하단 정보를 대한 검색 정보로 구성되어 있습니다. -->
		<div class="form-group inline">
			<label class="form-label" for="searchKeyword"><spring:message code="comSymMnuMpm.menuCreatManage.authCode" /></label><!-- 보안설정대상ID -->
			<div class="form-conts">
				<input id="searchKeyword" class="krds-input" name="searchKeyword" type="text" value='<c:out value="${searchVO.searchKeyword}"/>' maxlength="60" title="검색조건" onkeypress="return press(event);" />
			</div>
			<button type="button" class="krds-btn medium primary" title='<spring:message code="button.inquire" />' onclick="selectMenuCreatManageList(); return false;"><spring:message code="button.inquire" /></button>
			<button type="button" class="krds-btn medium secondary" title="변경한 메뉴/권한 매핑을 GNB 에 즉시 반영" onclick="fncReloadMenu(); return false;">메뉴 새로고침</button>
		</div>
	</div>

	<table class="krds-table tbl-list program-table menu-creat-table">
		<caption></caption>
		<colgroup>
			<col style="width:20%" />
			<col style="width:20%" />
			<col style="width:20%" />
			<col style="width:20%" />
			<col style="width:20%" />
		</colgroup>
		<thead>
			<tr>
			   <th scope="col"><spring:message code="comSymMnuMpm.menuCreatManage.authCode" /></th><!-- 권한코드 -->
			   <th scope="col"><spring:message code="comSymMnuMpm.menuCreatManage.authName" /></th><!-- 권한명 -->
			   <th scope="col"><spring:message code="comSymMnuMpm.menuCreatManage.authDesc" /></th><!-- 권한 설명 -->
			   <th scope="col"><spring:message code="comSymMnuMpm.menuCreatManage.creationStatus" /></th><!-- 메뉴생성여부 -->
			   <th scope="col"><spring:message code="comSymMnuMpm.menuCreatManage.createMenu" /></th><!-- 메뉴생성 -->
			</tr>
		</thead>
		<tbody>
			<c:if test="${fn:length(resultList) == 0}">
				<tr>
					<td colspan="5" class="empty-row"><spring:message code="common.nodata.msg" /></td>
				</tr>
			</c:if>
			<c:forEach var="result" items="${resultList}" varStatus="status">
			  <tr>
			    <td><c:out value="${result.authorCode}"/></td>
			    <td><c:out value="${result.authorNm}"/></td>
			    <td><c:out value="${result.authorDc}"/></td>
			    <td>
		          <c:if test="${result.chkYeoBu > 0}">Y</c:if>
		          <c:if test="${result.chkYeoBu == 0}">N</c:if>
			    </td>
			    <td>
			       <a class="krds-btn small secondary" href="<c:url value='/sym/mnu/mcm/EgovMenuCreatSelect.do'/>?authorCode=<c:out value="${result.authorCode}"/>"  onclick="selectMenuCreat('<c:out value="${result.authorCode}"/>'); return false;">메뉴생성</a>
			    </td>
			  </tr>
			 </c:forEach>
		</tbody>
	</table>

	<!-- paging navigation -->
	<div class="krds-pagination">
		<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="linkPage"/>
	</div>
	
	<input type="hidden" name="req_menuNo">
	</form>
	
</div>
</lay:layout>
