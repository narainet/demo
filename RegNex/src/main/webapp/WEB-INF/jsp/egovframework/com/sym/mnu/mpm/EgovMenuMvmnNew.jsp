<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%
 /**
  * @Class Name : EgovMenuMvmn.jsp
  * @Description : 메뉴이동 화면
  * @Modification Information
  * @
  * @ 수정일               수정자            수정내용
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
  String imagePath_icon   = "/images/egovframework/com/sym/mnu/mpm/icon/";
  String imagePath_button = "/images/egovframework/com/sym/mnu/mpm/button/";

%>
<c:set var="pageTitle"><spring:message code="comSymMnuMpm.menuMvmn.title"/></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<!-- 메뉴이동 -->
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<script type="text/javascript">
var imgpath = "<c:url value='/images/egovframework/com/cmm/utl/'/>";
</script>
<%-- jQuery (iframe 내부도 자체 jQuery 필요) --%>
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<%-- jsTree + 공통 wrapper (옛 createTree.js 대체) --%>
<link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
<script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
<script src="<c:url value='/resources/js/egov-menu-jstree.js' />"></script>
<script language="javascript1.2" type="text/javaScript">
<!--
function selectProgramListSearch() {
	progrmManageForm.submit();
}
function choisProgramListSearch(vFileNm) {
	eval("parent.document.all."+parent.document.all.tmp_SearchElementName.value).value = vFileNm;
	parent.$('.ui-dialog-content').dialog('close');
}

/* ********************************************************
 * 상세내역조회 함수
 ******************************************************** */
function choiceNodes(nodeNum) {
	var nodeValues = treeNodes[nodeNum].split("|");
	parent.document.menuManageVO.upperMenuId.value = nodeValues[4];
	parent.$('.ui-dialog-content').dialog('close');
}
/* ********************************************************
 * 조회 함수
 ******************************************************** */
function selectMenuListTmp() {
	document.menuListForm.req_RetrunPath.value = "<c:url value='/sym/mnu/mpm/EgovMenuMvmn'/>";
    document.menuListForm.action = "<c:url value='/sym/mnu/mpm/EgovMenuListSelectTmp.do'/>";
    document.menuListForm.submit();
}
-->
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<form name="searchUpperMenuIdForm" action ="<c:url value='/sym/mnu/mpm/EgovMenuListSelectTmp.do'/>" method="post">
<div style="visibility:hidden;display:none;"><input name="iptSubmit" type="submit" value="전송" title="전송"></div>
<input type="hidden" name="req_RetrunPath" value="/sym/mnu/mpm/EgovMenuMvmn">
<%-- 옛 hidden tmp_menuNmVal 더미 제거 — jsTree 는 JSON ajax 로 데이터 로드 --%>

<div class="wTableFrm" style="width:580px">
	<!-- 타이틀 -->
	<h2><spring:message code="comSymMnuMpm.menuMvmn.pageTop.title"/></h2><!-- 메뉴이동 -->

	<!-- 등록폼 -->
<%--
	<table class="wTable">
		<colgroup>
			<col style="width:20%" />
			<col style="" />
		</colgroup>
		<tr>
			<th><spring:message code="comSymMnuMpm.menuMvmn.menuNo"/></th><!-- 이동할메뉴명 -->
			<td class="left">
			    <input name="progrmFileNm" type="text" size="30" value=""  maxlength="60" title="<spring:message code="comSymMnuMpm.menuMvmn.menuNo"/>" readonly="readonly"/>
			</td>
		</tr>
	</table>
--%>
	<div style="clear:both;"></div>
</div>

<DIV id="main" style="display:">

<table width="570" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td height="10">&nbsp;</td>
  </tr>
</table>

<table width="570" cellpadding="8" class="table-line">
  <tr>
    <td>
 		<div class="tree" style="width:520px; height:400px; padding:6px; overflow:auto;">
			<div id="ideMenuTree" style="height:100%;"></div>
			<script type="text/javascript">
				$(function() {
					EgovMenuTree.init({
						containerId: 'ideMenuTree',
						jsonUrl:     '<c:url value="/sym/mnu/mpm/EgovMenuListJson.do"/>',
						fields:      { id: 'menuNo', parent: 'upperMenuId', text: 'menuNm' },
						opened:      true,
						emptyMsg:    '<spring:message code="comSymMnuMpm.menuMvmn.validate.alert.menu"/>',
						onSelect: function(node, m) {
							// iframe 안에서 부모(jquery-ui dialog) 의 폼에 결과 전달 + dialog 닫기
							if (parent && parent.document && parent.document.menuManageVO) {
								parent.document.menuManageVO.upperMenuId.value = m.menuNo;
							}
							try { parent.$('.ui-dialog-content').dialog('close'); } catch (e) {}
						}
					});
				});
			</script>
		</div>
    </td>
  </tr>
</table>
</DIV>

</form>
</lay:layout>
