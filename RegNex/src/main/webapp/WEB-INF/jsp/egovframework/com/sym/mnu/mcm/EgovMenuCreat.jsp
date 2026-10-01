<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%
 /**
  * @Class Name : EgovMenuCreat.jsp
  * @Description : 메뉴생성 화면
  * @Modification Information
  * @
  * @ 수정일               수정자             수정내용
  * @ ----------   --------   ---------------------------
  * @ 2009.03.10   이용               최초 생성
  *   2018.09.10   신용호            표준프레임워크 v3.8 개선
  *   2019.12.11   신용호            KISA 보안약점 조치 (크로스사이트 스크립트)
  *   2021.02.26   신용호            메뉴 목록 없는 경우 예외처리
  *
  *  @author 공통서비스 개발팀 이용
  *  @since 2009.03.10
  *  @version 1.0
  *  @see
  *
  */

  /* Image Path 설정 */
//  String imagePath_icon   = "/images/egovframework/com/sym/mnu/mcm/icon/";
//  String imagePath_button = "/images/egovframework/com/sym/mnu/mcm/button/";
%>
<c:set var="pageTitle"><spring:message code="comSymMnuMpm.MenuCreat.title" /></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<!-- 메뉴생성 -->
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<script type="text/javascript">
var imgpath = "<c:url value='/images/egovframework/com/cmm/utl/'/>";
</script>
<%-- jQuery + jsTree + 공통 wrapper (옛 createTree.js / 체크박스 이미지 트리 대체) --%>
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
<script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
<script src="<c:url value='/resources/js/egov-menu-jstree.js' />"></script>
<%-- 기존 EgovMenuCreat.js — createTree 함수 호출 안 됨(dead) --%>
<script language="javascript1.2" type="text/javaScript" src="<c:url value='/js/egovframework/com/sym/mnu/mcm/EgovMenuCreat.js' />"></script>
<script language="javascript1.2" type="text/javaScript">
<!--
/* ********************************************************
 * 조회 함수
 ******************************************************** */
function selectMenuCreatTmp() {
    document.menuCreatManageForm.action = "<c:url value='/sym/mnu/mcm/EgovMenuCreatSelect.do'/>";
    document.menuCreatManageForm.submit();
}

/* ********************************************************
 * 멀티입력 처리 함수 — jsTree 체크박스 → 메뉴번호 콤마 문자열
 ******************************************************** */
function fInsertMenuCreat() {
    // 사용자/관리자 두 트리의 체크(+부분체크 부모) 병합 — 저장이 권한코드 전체삭제 후 재삽입이라 둘 다 보내야 함
    var ids = EgovMenuTree.getCheckedIds('ideMenuTreeUser', true)
              .concat(EgovMenuTree.getCheckedIds('ideMenuTreeAdmin', true));
    ids = ids.filter(function(v, i) { return v !== '' && ids.indexOf(v) === i; });
    if (!ids.length) {
        alert("선택된 메뉴가 없습니다.");
        return false;
    }
    document.menuCreatManageForm.checkedMenuNoForInsert.value = ids.join(',');
    document.menuCreatManageForm.checkedAuthorForInsert.value = document.menuCreatManageForm.authorCode.value;
    document.menuCreatManageForm.action = "<c:url value='/sym/mnu/mcm/EgovMenuCreatInsert.do'/>";
    document.menuCreatManageForm.submit();
}
/* ********************************************************
 * 메뉴사이트맵 생성 화면 호출
 ******************************************************** */
function fMenuCreatSiteMap() {
	id = document.menuCreatManageForm.authorCode.value;
	window.open("<c:url value='/sym/mnu/mcm/EgovMenuCreatSiteMapSelect.do'/>?authorCode="+id,'Pop_SiteMap','scrollbars=yes, width=550, height=700');
}
<c:if test="${!empty resultMsg}">alert("${resultMsg}");</c:if>
-->
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<form name="menuCreatManageForm" action ="<c:url value='/sym/mnu/mcm/EgovMenuCreatSiteMapSelect.do' />" method="post" class="krds-form">
<input name="checkedMenuNoForInsert" type="hidden" >
<input name="checkedAuthorForInsert"  type="hidden" >

<div class="program-form-page menu-creat-page">
	<div class="program-form-head">
		<div>
			<span class="program-form-kicker">System / Menu</span>
			<h1><spring:message code="comSymMnuMpm.MenuCreat.pageTop.title" /></h1><!-- 메뉴생성 -->
		</div>
		<span class="program-form-state">권한별 메뉴</span>
	</div>

	<div class="program-form-shell menu-creat-shell">
		<main class="rlms-ide-main program-form-main menu-creat-main">
			<div class="ide-context-pane">
				<div class="ide-prov-head">
					<h2>메뉴 생성 대상 선택</h2>
					<span class="ide-prov-status exist">체크 저장</span>
				</div>

				<div class="ide-form-row">
					<label for="authorCode"><spring:message code="comSymMnuMpm.MenuCreat.authCode" /></label><!-- 권한코드 -->
					<input id="authorCode" class="krds-input" name="authorCode" type="text" value="<c:out value='${resultVO.authorCode}'/>" maxlength="30" title="<spring:message code="comSymMnuMpm.MenuCreat.authCode" />" readonly="readonly" /><!-- 권한코드 -->
				</div>

				<%-- 사용자/관리자 구분 탭 — 사용자화면 노출(USER) / 관리자화면 노출(ADMIN) 메뉴 분리 --%>
				<div class="menu-creat-tabs">
					<button type="button" class="mct-tab active" data-se="USER"  onclick="mcmSwitchTab('USER', this);">사용자 화면 메뉴</button>
					<button type="button" class="mct-tab"        data-se="ADMIN" onclick="mcmSwitchTab('ADMIN', this);">관리자 화면 메뉴</button>
				</div>
				<%-- jsTree 체크박스 트리(MENU_SE 별 2트리) — EgovMenuCreatListJson.do 권한별 메뉴 로드.
				     chkYeoBu>0 메뉴 초기 체크. 상위 체크 시 하위 자동 체크(three_state). --%>
				<div class="menu-creat-tree" aria-label="메뉴 생성 트리">
					<div id="ideMenuTreeUser"></div>
					<div id="ideMenuTreeAdmin" style="display:none;"></div>
					<script type="text/javascript">
						function mcmSwitchTab(se, btn) {
							$('.menu-creat-tabs .mct-tab').removeClass('active');
							if (btn) { $(btn).addClass('active'); }
							$('#ideMenuTreeUser').toggle(se === 'USER');
							$('#ideMenuTreeAdmin').toggle(se === 'ADMIN');
						}
						$(function() {
							function buildCreatTree(containerId, se) {
								EgovMenuTree.init({
									containerId: containerId,
									jsonUrl:     '<c:url value="/sym/mnu/mcm/EgovMenuCreatListJson.do"/>?authorCode=<c:out value="${resultVO.authorCode}"/>',
									fields:      { id: 'menuNo', parent: 'upperMenuId', text: 'menuNm' },
									opened:      true,
									checkbox:    true,
									checkedKey:  'chkYeoBu',
									rowFilter:   function(m) { return (m.menuSe || '') === se; },
									emptyMsg:    (se === 'USER' ? '사용자' : '관리자') + ' 화면 메뉴가 없습니다.'
								});
							}
							buildCreatTree('ideMenuTreeUser',  'USER');
							buildCreatTree('ideMenuTreeAdmin', 'ADMIN');
						});
					</script>
				</div>

				<div class="ide-form-actions">
					<button type="button" class="krds-btn secondary medium" onclick="location.href='<c:url value='/sym/mnu/mcm/EgovMenuCreatManageSelect.do'/>'; return false;"><spring:message code="button.list" /></button>
					<button type="button" class="krds-btn secondary medium" onclick="fMenuCreatSiteMap(); return false;"><spring:message code="comSymMnuMpm.MenuCreat.viewSiteMap" /></button><!-- 사이트맵보기 -->
					<button type="button" class="krds-btn primary medium" onclick="fInsertMenuCreat(); return false;"><spring:message code="comSymMnuMpm.MenuCreat.createMenu" /></button><!-- 메뉴생성 -->
				</div>
			</div>
		</main>

		<aside class="program-form-side">
			<h3 class="program-side-title">작업 정보</h3>
			<div class="program-side-block">
				<span class="program-side-label">권한코드</span>
				<p class="program-side-value"><c:out value="${resultVO.authorCode}" /></p>
			</div>
			<div class="program-side-block">
				<span class="program-side-label">처리 방식</span>
				<p class="program-side-text">트리에서 사용할 메뉴를 선택한 뒤 메뉴생성을 저장합니다.</p>
			</div>
		</aside>
	</div>
</div>

<input type="hidden" name="req_menuNo">
</form>
</lay:layout>
