<%--
 /**
  * @Class Name : EgovMenuList.jsp
  * @Description : 메뉴목록 화면
  * @Modification Information
  * @
  * @ 수정일               수정자             수정내용
  * @ ----------   --------   ---------------------------
  * @ 2009.03.10   이용               최초 생성
  *   2013.10.04   이기하            메뉴트리 위치 변경
  *   2018.09.10   신용호            표준프레임워크 v3.8 개선
  *
  *  @author 공통서비스 개발팀 이용
  *  @since 2009.03.10
  *  @version 1.0
  *  @see
  *
  */

  /* Image Path 설정 */
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
<%
//String imagePath_icon   = "/images/egovframework/com/sym/mnu/mpm/icon/";
//String imagePath_button = "/images/egovframework/com/sym/mnu/mpm/button/";
%>
<c:set var="pageTitle"><spring:message code="comSymMnuMpm.menuList.title" /></c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<script type="text/javascript" src="<c:url value="/validator.do" />"></script>
<script type="text/javascript">
var imgpath = "<c:url value='/images/egovframework/com/cmm/utl/'/>";
</script>
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/cmm/jqueryui.css' />">
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<script src="<c:url value='/js/egovframework/com/cmm/jqueryui.js' />"></script>

<%-- jsTree + 공통 wrapper (옛 createTree.js / 이미지 트리 대체) --%>
<link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
<script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
<script src="<c:url value='/resources/js/egov-menu-jstree.js' />"></script>
<%-- UL 기반 메뉴 트리 (HTML5 드래그 순서/이동) — 메인 트리에서 jstree 대체(번들에 dnd 없음). 상위메뉴 선택 팝업은 jstree 유지 --%>
<script src="<c:url value='/resources/js/rlms-menu-tree.js' />"></script>

<%-- 기존 EgovMenuList.js — validator 등 다른 함수가 들었지만 createTree 부분은 더 이상 호출 안 됨 --%>
<script language="javascript1.2" type="text/javaScript" src="<c:url value='/js/egovframework/com/sym/mnu/mpm/EgovMenuList.js' />"></script>
<script language="javascript1.2" type="text/javaScript">
<!--
/* ********************************************************
 * 메뉴등록 처리 함수
 ******************************************************** */
function insertMenuList() {
	if(!fn_validatorMenuList()){return;}
    if(document.menuManageVO.tmp_CheckVal.value == "U"){alert("<spring:message code="comSymMnuMpm.menuList.validate.checkVal" />"); return;} //상세조회시는 수정혹은 삭제만 가능합니다.
	document.menuManageVO.action = "<c:url value='/sym/mnu/mpm/EgovMenuListInsert.do'/>";
	menuManageVO.submit();

}

/* ********************************************************
 * 메뉴수정 처리 함수
 ******************************************************** */
function updateMenuList() {
    if(!fn_validatorMenuList()){return;}
    if(document.menuManageVO.tmp_CheckVal.value != "U"){alert("<spring:message code="comSymMnuMpm.menuList.validate.checkVal.update" />"); return;} //상세조회시는 수정혹은 삭제만 가능합니다. 초기화 하신 후 등록하세요.
	document.menuManageVO.action = "<c:url value='/sym/mnu/mpm/EgovMenuListUpdt.do'/>";
	menuManageVO.submit();
}

/* ********************************************************
 * 메뉴삭제 처리 함수
 ******************************************************** */
function deleteMenuList() {
    if(!fn_validatorMenuList()){return;}
    if(document.menuManageVO.tmp_CheckVal.value != "U"){alert("<spring:message code="comSymMnuMpm.menuList.validate.checkVal" />"); return;} //상세조회시는 수정혹은 삭제만 가능합니다.
	document.menuManageVO.action = "<c:url value='/sym/mnu/mpm/EgovMenuListDelete.do'/>";
	menuManageVO.submit();
}

/* ********************************************************
 * 메뉴리스트 조회 함수
 ******************************************************** */
function selectMenuList() {
    document.menuManageVO.action = "<c:url value='/sym/mnu/mpm/EgovMenuListSelect.do'/>";
    document.menuManageVO.submit();
}

/* ********************************************************
 * 메뉴 캐시 새로고침 — 변경한 메뉴(순서/이동/등록)를 사용자·관리자 GNB 에 즉시 반영.
 * 드래그/등록/수정은 DB 에만 저장되고, 이 버튼을 눌러야 실제 화면(GNB)에 적용됨.
 * (메뉴생성관리의 '메뉴 새로고침' 과 동일 — /rlms/mgr/reloadMenu.do → MenuHelper.clearCache)
 ******************************************************** */
function fncReloadMenu() {
    if (!confirm("변경한 메뉴(순서/이동/등록 등)를 지금 사용자·관리자 화면(GNB)에 적용할까요?\n(메뉴 캐시를 비워 다음 화면부터 즉시 반영됩니다)")) return;
    fetch("<c:url value='/rlms/mgr/reloadMenu.do'/>", { method: "POST" })
        .then(function(r){ return r.json(); })
        .then(function(res){ alert(res.message || (res.success ? "적용되었습니다." : "적용 실패")); })
        .catch(function(e){ alert("요청 실패: " + e); });
}

/* ********************************************************
 * 초기화 함수
 ******************************************************** */
function initlMenuList() {
	document.menuManageVO.menuNo.value="";
	document.menuManageVO.menuOrdr.value="";
	document.menuManageVO.menuNm.value="";
	document.menuManageVO.upperMenuId.value="";
	document.menuManageVO.menuDc.value="";
	document.menuManageVO.relateImagePath.value="";
	document.menuManageVO.relateImageNm.value="";
	document.menuManageVO.progrmFileNm.value="";
	document.menuManageVO.menuSe.value=(typeof menuActiveSe !== 'undefined' ? menuActiveSe : 'USER');
	document.getElementById('menuType').value="internal";
	applyMenuType();
	document.menuManageVO.menuNo.readOnly=false;
	document.menuManageVO.tmp_CheckVal.value = "";
	updateMenuFormMode("");
}

/* ********************************************************
 * 조회 함수

 ******************************************************** */
function selectMenuListTmp() {
	document.menuManageVO.req_RetrunPath.value = "/sym/mnu/mpm/EgovMenuList";
    document.menuManageVO.action = "<c:url value='/sym/mnu/mpm/EgovMenuListSelectTmp.do'/>";
    document.menuManageVO.submit();
}

/* ********************************************************
 * 상세내역조회 함수
 ******************************************************** */
 function choiceNodes(nodeNum) {
		var nodeValues = treeNodes[nodeNum].split("|");
		document.menuManageVO.menuNo.value = nodeValues[4];
		document.menuManageVO.menuOrdr.value = nodeValues[5];
		document.menuManageVO.menuNm.value = nodeValues[6];
		document.menuManageVO.upperMenuId.value = nodeValues[7];
		document.menuManageVO.menuDc.value = nodeValues[8];
		document.menuManageVO.relateImagePath.value = nodeValues[9];
		document.menuManageVO.relateImageNm.value = nodeValues[10];
		document.menuManageVO.progrmFileNm.value = nodeValues[11];
		document.menuManageVO.menuNo.readOnly=true;
		document.menuManageVO.tmp_CheckVal.value = "U";
		updateMenuFormMode("U");
}

function updateMenuFormMode(mode) {
	var isUpdate = mode === "U";
	var state = document.getElementById("menuFormState");
	var title = document.getElementById("menuFormTitle");
	if (state) {
		state.className = "ide-prov-status " + (isUpdate ? "exist" : "ready");
		state.innerHTML = isUpdate ? "수정 모드" : "등록 모드";
	}
	if (title) {
		title.innerHTML = isUpdate ? "메뉴 수정" : "메뉴 등록";
	}
	// 버튼 모드: 신규(등록)=등록만 / 수정모드=수정·삭제·신규
	var bIns = document.getElementById('btnMenuInsert');
	var bUpd = document.getElementById('btnMenuUpdate');
	var bDel = document.getElementById('btnMenuDelete');
	var bNew = document.getElementById('btnMenuNew');
	if (bIns) { bIns.style.display = isUpdate ? 'none' : ''; }
	if (bUpd) { bUpd.style.display = isUpdate ? '' : 'none'; }
	if (bDel) { bDel.style.display = isUpdate ? '' : 'none'; }
	if (bNew) { bNew.style.display = isUpdate ? '' : 'none'; }
}

/* ********************************************************
 * 메뉴유형(내부프로그램/외부링크/폴더) 전환
 *  - 폴더   : PROGRM_FILE_NM='folder'   (URL 없음)
 *  - 외부링크: PROGRM_FILE_NM='externalLink' placeholder + RELATE_IMAGE_PATH=외부 URL
 *  - 내부   : 프로그램 검색 팝업으로 PROGRM_FILE_NM 선택
 ******************************************************** */
function applyMenuType() {
	var t = document.getElementById('menuType').value;
	var rowProgrm = document.getElementById('rowProgrm');
	var rowExtUrl = document.getElementById('rowExtUrl');
	var prog = document.menuManageVO.progrmFileNm;
	var ext  = document.menuManageVO.relateImagePath;
	if (t == 'folder') {
		rowProgrm.style.display = 'none';
		rowExtUrl.style.display = 'none';
		prog.value = 'folder';
		ext.value = '';
	} else if (t == 'external') {
		rowProgrm.style.display = 'none';
		rowExtUrl.style.display = '';
		prog.value = 'externalLink';
	} else {
		rowProgrm.style.display = '';
		rowExtUrl.style.display = 'none';
		ext.value = '';
		if (prog.value == 'folder' || prog.value == 'externalLink') {
			prog.value = '';
		}
	}
}

/* ********************************************************
 * 입력값 validator 함수
 ******************************************************** */
function fn_validatorMenuList() {

	if(document.menuManageVO.menuNo.value == ""){alert("<spring:message code="comSymMnuMpm.menuList.validate.menuNo.notNull" />"); return false;} //메뉴번호는 Not Null 항목입니다.
	if(!checkNumber(document.menuManageVO.menuNo.value)){alert("<spring:message code="comSymMnuMpm.menuList.validate.menuNo.onlyNumber" />"); return false;} //메뉴번호는 숫자만 입력 가능합니다.

	if(document.menuManageVO.menuOrdr.value == ""){alert("<spring:message code="comSymMnuMpm.menuList.validate.menuOrdr.notNull" />"); return false;} //메뉴순서는 Not Null 항목입니다.
	if(!checkNumber(document.menuManageVO.menuOrdr.value)){alert("<spring:message code="comSymMnuMpm.menuList.validate.menuOrdr.onlyNumber" />"); return false;} //메뉴순서는 숫자만 입력 가능합니다.

	if(document.menuManageVO.upperMenuId.value == ""){alert("<spring:message code="comSymMnuMpm.menuList.validate.upperMenuId.notNull" />"); return false;} //상위메뉴번호는 Not Null 항목입니다.
	if(!checkNumber(document.menuManageVO.upperMenuId.value)){alert("<spring:message code="comSymMnuMpm.menuList.validate.upperMenuId.onlyNumber" />"); return false;} //상위메뉴번호는 숫자만 입력 가능합니다.

	if(document.menuManageVO.progrmFileNm.value == ""){alert("<spring:message code="comSymMnuMpm.menuList.validate.progrmFileNm.notNull" />"); return false;} //프로그램파일명은 Not Null 항목입니다.
	if(document.menuManageVO.menuNm.value == ""){alert("<spring:message code="comSymMnuMpm.menuList.validate.menuNm.notNull" />"); return false;} //메뉴명은 Not Null 항목입니다.

	if(document.getElementById('menuType').value=='external' && document.menuManageVO.relateImagePath.value==''){alert("외부 링크 URL을 입력하세요."); return false;} //외부링크 URL 필수

    return true;
}

/* ********************************************************
 * 필드값 Number 체크 함수
 ******************************************************** */
function checkNumber(str) {
    var flag=true;
    if (str.length > 0) {
        for (i = 0; i < str.length; i++) {
            if (str.charAt(i) < '0' || str.charAt(i) > '9') {
                flag=false;
            }
        }
    }
    return flag;
}
<c:if test="${!empty resultMsg}">alert("${resultMsg}");</c:if>
-->
</script>
<%-- ────────────────────────────────────────────────
     팝업 — KRDS 모달 + ajax inject (iframe 없음 / jQuery UI dialog 없음)
     표준 팝업 JSP 무수정. 글로벌 함수(linkPage/selectProgramListSearch/
     choisProgramListSearch)를 호출 측에서 모달별 redefine 으로 가로채기.
──────────────────────────────────────────────── --%>
<script type="text/javascript">
    function ajaxLoadModal(modalId, url, data, onLoaded) {
        var $box = $('#' + modalId + '_body');
        $box.html('<p style="padding:20px;color:#888;">로딩...</p>');
        $.ajax({ url: url, type: data ? 'POST' : 'GET', data: data || null, dataType: 'html' })
            .done(function(html) {
                // popup decorator 가 감싼 경우: <main class="rlms-popup-main">...</main> 추출
                // 그렇지 않으면 <body>...</body> 추출, 마지막으로 raw html.
                var content;
                var mainMatch = html.match(/<main[^>]*class="[^"]*rlms-popup-main[^"]*"[^>]*>([\s\S]*?)<\/main>/i);
                if (mainMatch) {
                    content = mainMatch[1];
                } else {
                    var bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
                    content = bodyMatch ? bodyMatch[1] : html;
                }
                content = content.replace(new RegExp("<script[\\s\\S]*?<\\/script>", "gi"), "");
                $box.html(content);
                if (typeof onLoaded === 'function') onLoaded($box);
                // inject 된 영역의 인라인 <script> 들을 명시적 실행 (.html() 은 deferred 실행 보장 안 됨)
                $box.find('script').each(function() {
                    var src = $(this).attr('src');
                    if (src) {
                        $.getScript(src);
                    } else {
                        var code = $(this).text() || $(this).html() || '';
                        if (code.trim()) {
                            try { (new Function(code))(); }
                            catch (e) { console.warn('[ajaxLoadModal] inline script eval 실패', e, code.substring(0, 100)); }
                        }
                    }
                });
                // 호출 측에서 init 등 후처리 필요할 때
                if (typeof onLoaded === 'function') onLoaded($box);
            })
            .fail(function(xhr) {
                $box.html('<p style="padding:20px;color:#b03030;">조회 실패 (' + xhr.status + ')</p>');
            });
    }

    function bindProgramSearchModal($box) {
        $box.find('form[name="progrmManageForm"]').off('submit').on('submit', function(ev) {
            ev.preventDefault();
            this.pageIndex.value = 1;
            ajaxLoadModal('modalFileNm', this.action, $(this).serialize(), bindProgramSearchModal);
        });
    }

    $(document).ready(function() {

        // ── 파일명 검색 모달 ───────────────────────────
        $('#popupProgrmFileNm').off('click').on('click', function(e) {
            e.preventDefault();
            // 표준 JSP 글로벌 함수 redefine
            window.linkPage = function(pageNo) {
                var f = $('#modalFileNm_body form[name="progrmManageForm"]')[0];
                if (!f) return;
                f.pageIndex.value = pageNo;
                ajaxLoadModal('modalFileNm', f.action, $(f).serialize(), bindProgramSearchModal);
            };
            window.selectProgramListSearch = function() {
                var f = $('#modalFileNm_body form[name="progrmManageForm"]')[0];
                if (!f) return;
                f.pageIndex.value = 1;
                ajaxLoadModal('modalFileNm', f.action, $(f).serialize(), bindProgramSearchModal);
            };
            window.choisProgramListSearch = function(vFileNm) {
                document.menuManageVO.progrmFileNm.value = vFileNm;
                krds_modal.closeModal('modalFileNm');
            };
            // EgovFileNmSearchNew.jsp 가 호출하는 parent.$('.ui-dialog-content').dialog('close')
            // — jQuery UI dialog 가 없어도 safe 하도록 stub 제공
            if (!$.fn.dialog) {
                $.fn.dialog = function(action) {
                    if (action === 'close') krds_modal.closeModal('modalFileNm');
                    return this;
                };
            }
            ajaxLoadModal('modalFileNm', '<c:url value="/sym/prm/EgovProgramListSearchNew.do"/>', null, bindProgramSearchModal);
            krds_modal.openModal('modalFileNm');
        });

        // ── 상위메뉴 선택 모달 ───────────────────────────
        // 현재 등록/수정 중인 메뉴의 메뉴구분(USER/ADMIN)에 해당하는 트리만 노출.
        //  · 사용자 메뉴의 상위는 사용자 메뉴, 관리자 메뉴의 상위는 관리자 메뉴여야 한다.
        //  · 메뉴구분 select 값을 클릭 시점에 읽어 rowFilter 로 거른다(없으면 활성 탭 menuActiveSe → 기본 USER).
        $('#popupUpperMenuId').off('click').on('click', function(e) {
            e.preventDefault();
            var curSe = document.menuManageVO.menuSe.value
                        || (typeof menuActiveSe !== 'undefined' ? menuActiveSe : 'USER');
            var seLabel = (curSe === 'ADMIN') ? '관리자' : '사용자';
            $('#modalUpperMenuId_body').html('<div class="menu-select-modal"><div id="modalUpperMenuTree" class="menu-select-tree"></div></div>');
            EgovMenuTree.init({
                containerId: 'modalUpperMenuTree',
                jsonUrl:     '<c:url value="/sym/mnu/mpm/EgovMenuListJson.do"/>',
                fields:      { id: 'menuNo', parent: 'upperMenuId', text: 'menuNm' },
                opened:      true,
                showId:      true,
                rowFilter:   function(m) { return (m.menuSe || '') === curSe; },
                emptyMsg:    seLabel + ' 메뉴가 없습니다.',
                onSelect: function(node, m) {
                    document.menuManageVO.upperMenuId.value = m.menuNo;
                    krds_modal.closeModal('modalUpperMenuId');
                }
            });
            krds_modal.openModal('modalUpperMenuId');
        });
        updateMenuFormMode(document.menuManageVO.tmp_CheckVal.value);
        applyMenuType();
    });
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>
<form name="menuManageVO" action ="<c:url value='/sym/mnu/mpm/EgovMenuListInsert.do' />" method="post" class="krds-form menu-list-form">
<input type="hidden" name="req_RetrunPath" value="/sym/mnu/mpm/EgovMenuList">

<div class="program-form-page menu-list-page">
	<div class="program-form-head">
		<div>
			<span class="program-form-kicker">System / Menu</span>
			<h1><spring:message code="comSymMnuMpm.menuList.pageTop.title" /></h1><!-- 메뉴 목록 -->
		</div>
	</div>

	<div class="menu-list-shell">
		<aside class="rlms-ide-left menu-list-left">
			<div class="ide-actions-tit">메뉴 트리</div>
			<nav class="ide-actions">
				<a href="javascript:void(0);" class="ide-action" onclick="initlMenuList(); return false;">신규 메뉴 등록</a>
				<a href="javascript:void(0);" class="ide-action" onclick="selectMenuList(); return false;" title="DB 기준으로 트리를 다시 읽습니다">트리 다시읽기</a>
				<a href="javascript:void(0);" class="ide-action ide-action-apply" onclick="fncReloadMenu(); return false;" title="변경한 메뉴(순서/이동/등록)를 사용자·관리자 GNB 에 즉시 반영">★ 메뉴 새로고침 (사용자 적용)</a>
			</nav>
			<%-- 트리 검색창 (규정 IDE 와 동일) — 활성 탭 트리 검색 --%>
			<div class="ide-tree-search">
				<input type="text" id="menuTreeSearch" placeholder="메뉴 검색 (이름)..." oninput="menuTreeSearch(this.value);"/>
				<button type="button" onclick="menuTreeClearSearch(); return false;" title="지우기">&times;</button>
			</div>
			<%-- 사용자/관리자 구분 탭 (규정 IDE 트리 탭과 동일 패턴) --%>
			<div class="ide-tabs">
				<button type="button" class="ide-tab active" data-se="USER"  onclick="menuSwitchTab('USER', this);">사용자 메뉴</button>
				<button type="button" class="ide-tab"        data-se="ADMIN" onclick="menuSwitchTab('ADMIN', this);">관리자 메뉴</button>
			</div>
			<%-- UL 기반 트리(RlmsMenuTree). MENU_SE 별 2트리 + HTML5 드래그(순서/이동) --%>
			<div id="ideMenuTreeUser"  class="ide-tree-pane active" aria-label="사용자 메뉴 트리"></div>
			<div id="ideMenuTreeAdmin" class="ide-tree-pane"        aria-label="관리자 메뉴 트리"></div>
			<script type="text/javascript">
				var menuActiveSe = 'USER';

				// 선택 노드 → 우측 폼 채움 (옛 choiceNodes 대체). RlmsMenuTree 는 row 객체 1개 전달
				function fillMenuForm(m) {
					document.menuManageVO.menuNo.value          = m.menuNo;
					document.menuManageVO.menuOrdr.value        = m.menuOrdr;
					document.menuManageVO.menuNm.value          = m.menuNm;
					document.menuManageVO.upperMenuId.value     = m.upperMenuId;
					document.menuManageVO.menuDc.value          = m.menuDc;
					document.menuManageVO.relateImagePath.value = m.relateImagePath;
					document.menuManageVO.relateImageNm.value   = m.relateImageNm;
					document.menuManageVO.progrmFileNm.value    = m.progrmFileNm;
					document.menuManageVO.menuSe.value          = m.menuSe ? m.menuSe : menuActiveSe;
					document.getElementById('menuType').value   = (m.progrmFileNm == 'folder') ? 'folder' : (m.progrmFileNm == 'externalLink' ? 'external' : 'internal');
					applyMenuType();
					document.menuManageVO.menuNo.readOnly       = true;
					document.menuManageVO.tmp_CheckVal.value    = 'U';
					updateMenuFormMode('U');
				}

				// 드래그 이동/정렬 저장 (jsTree dnd → EgovMenuMoveJson.do)
				function persistMenuMove(movedNo, newUpper, siblingNos) {
					$.ajax({
						url:  '<c:url value="/sym/mnu/mpm/EgovMenuMoveJson.do"/>',
						type: 'POST',
						data: { upperMenuId: newUpper, siblings: siblingNos.join(',') },
						dataType: 'json'
					}).fail(function(xhr) {
						alert('메뉴 이동 저장 실패 (' + xhr.status + ') — 새로고침합니다.');
						selectMenuList();
					});
				}

				// 탭 전환 (사용자/관리자)
				function menuSwitchTab(se, btn) {
					menuActiveSe = se;
					$('.menu-list-left .ide-tab').removeClass('active');
					if (btn) { $(btn).addClass('active'); }
					$('#ideMenuTreeUser').toggleClass('active', se === 'USER');
					$('#ideMenuTreeAdmin').toggleClass('active', se === 'ADMIN');
				}
				function menuActiveTreeId() { return menuActiveSe === 'USER' ? 'ideMenuTreeUser' : 'ideMenuTreeAdmin'; }
				function menuTreeSearch(q) { RlmsMenuTree.search(menuActiveTreeId(), q); }
				function menuTreeClearSearch() { $('#menuTreeSearch').val(''); RlmsMenuTree.clearSearch(menuActiveTreeId()); }

				$(function() {
					function buildMenuTree(containerId, se) {
						RlmsMenuTree.init({
							containerId: containerId,
							jsonUrl:     '<c:url value="/sym/mnu/mpm/EgovMenuListJson.do"/>',
							fields:      { id: 'menuNo', parent: 'upperMenuId', text: 'menuNm' },
							showId:      true,
							rowFilter:   function(m) { return (m.menuSe || '') === se; },
							emptyMsg:    (se === 'USER' ? '사용자' : '관리자') + ' 메뉴가 없습니다. 메뉴 등록 후 사용하세요.',
							onSelect:    fillMenuForm,
							onMove:      persistMenuMove
						});
					}
					buildMenuTree('ideMenuTreeUser',  'USER');
					buildMenuTree('ideMenuTreeAdmin', 'ADMIN');
				});
			</script>
		</aside>

		<main class="rlms-ide-main program-form-main menu-list-main">
			<div class="ide-context-pane">
				<div class="ide-prov-head">
					<h2 id="menuFormTitle">메뉴 등록</h2>
					<span id="menuFormState" class="ide-prov-status ready">등록 모드</span>
				</div>

				<div class="menu-list-form-grid">
					<div class="ide-form-row">
						<label for="menuNo"><spring:message code="comSymMnuMpm.menuList.menuNo" /> <span class="required">*</span></label><!-- 메뉴No -->
						<input id="menuNo" class="krds-input numeric" name="menuNo" type="text" value="" maxlength="10" title="<spring:message code="comSymMnuMpm.menuList.menuNo" />"/>
					</div>
					<div class="ide-form-row">
						<label for="menuOrdr"><spring:message code="comSymMnuMpm.menuList.menuOrdr" /> <span class="required">*</span></label><!-- 메뉴순서 -->
						<input id="menuOrdr" class="krds-input numeric" name="menuOrdr" type="text" value="" maxlength="10" title="<spring:message code="comSymMnuMpm.menuList.menuOrdr" />"/>
					</div>
					<div class="ide-form-row">
						<label for="menuNm"><spring:message code="comSymMnuMpm.menuList.menuNm" /> <span class="required">*</span></label><!-- 메뉴명 -->
						<input id="menuNm" class="krds-input" name="menuNm" type="text" value="" maxlength="30" title="<spring:message code="comSymMnuMpm.menuList.menuNm" />">
					</div>
					<div class="ide-form-row">
						<label for="upperMenuId"><spring:message code="comSymMnuMpm.menuList.upperMenuId" /> <span class="required">*</span></label><!-- 상위메뉴No -->
						<div class="menu-list-input-action">
							<input id="upperMenuId" class="krds-input" name="upperMenuId" type="text" value="" maxlength="10" title="<spring:message code="comSymMnuMpm.menuList.upperMenuId" />"/>
							<a id="popupUpperMenuId" class="krds-btn small secondary" href="<c:url value='/sym/mnu/mpm/EgovMenuListSelectMvmn.do'/>" target="_blank" title="<spring:message code="comSymMnuMpm.menuList.upperMenuId" />"><spring:message code="comSymMnuMpm.menuList.mvmnMenuList" /></a><!-- 메뉴선택 검색 -->
						</div>
					</div>
					<div class="ide-form-row">
						<label for="menuSe">메뉴구분 <span class="required">*</span></label><!-- MENU_SE: 사용자 front / 관리자 GNB -->
						<select id="menuSe" class="krds-input" name="menuSe">
							<option value="USER">사용자(USER)</option>
							<option value="ADMIN">관리자(ADMIN)</option>
						</select>
					</div>
					<div class="ide-form-row">
						<label for="menuType">메뉴유형 <span class="required">*</span></label><!-- 내부프로그램 / 외부링크 / 폴더 -->
						<select id="menuType" class="krds-input" onchange="applyMenuType();">
							<option value="internal">내부 프로그램</option>
							<option value="external">외부 링크</option>
							<option value="folder">폴더(그룹)</option>
						</select>
					</div>
					<div class="ide-form-row" id="rowProgrm">
						<label for="progrmFileNm"><spring:message code="comSymMnuMpm.menuList.progrmFileNm" /> <span class="required">*</span></label><!-- 파일명 -->
						<div class="menu-list-input-action">
							<input id="progrmFileNm" class="krds-input" name="progrmFileNm" type="text" value="" maxlength="60" title="<spring:message code="comSymMnuMpm.menuList.progrmFileNm" />"/>
							<a id="popupProgrmFileNm" class="krds-btn small secondary" href="<c:url value='/sym/prm/EgovProgramListSearch.do'/>" target="_blank" title="<spring:message code="comSymMnuMpm.menuList.progrmFileNm" />"><spring:message code="comSymMnuMpm.menuList.searchFileNm" /></a>
						</div>
					</div>
					<div class="ide-form-row" id="rowExtUrl">
						<label for="relateImagePath">외부링크 URL <span class="required">*</span></label><!-- 외부링크(RELATE_IMAGE_PATH 에 외부 URL 저장) -->
						<input id="relateImagePath" class="krds-input" name="relateImagePath" type="text" value="" maxlength="100" placeholder="https://www.law.go.kr" title="외부링크 URL">
					</div>
					<input type="hidden" name="relateImageNm" value=""><!-- 미사용(round-trip 용) -->
					<div class="ide-form-row menu-list-wide">
						<label for="menuDc"><spring:message code="comSymMnuMpm.menuList.menuDc" /></label><!-- 메뉴설명 -->
						<textarea id="menuDc" name="menuDc" class="krds-input program-textarea menu-list-textarea" rows="8" title="<spring:message code="comSymMnuMpm.menuList.menuDc" />"></textarea>
					</div>
				</div>

				<div class="ide-form-actions">
					<%-- 신규(등록) 모드 = 등록 버튼만 / 노드선택(수정) 모드 = 수정·삭제·신규. updateMenuFormMode() 가 표시 토글 --%>
					<button type="button" id="btnMenuInsert" class="krds-btn primary medium" title="등록" onclick="insertMenuList(); return false;">등록</button>
					<button type="button" id="btnMenuUpdate" class="krds-btn primary medium" title="수정" onclick="updateMenuList(); return false;" style="display:none;">수정</button>
					<button type="button" id="btnMenuDelete" class="krds-btn danger medium" title="삭제" onclick="deleteMenuList(); return false;" style="display:none;">삭제</button>
					<button type="button" id="btnMenuNew" class="krds-btn secondary medium" title="신규" onclick="initlMenuList(); return false;" style="display:none;">신규</button>
				</div>
			</div>
		</main>
	</div>

    <input type="hidden" name="tmp_SearchElementName" value="">
    <input type="hidden" name="tmp_SearchElementVal" value="">
    <input type="hidden" name="tmp_CheckVal" value="">
</div>

</form>

<%-- ── KRDS 모달 마크업 (파일명 검색 + 상위메뉴 선택) — body 끝에 위치 ── --%>
<div class="krds-modal" id="modalFileNm" aria-hidden="true" role="dialog" aria-labelledby="modalFileNm_title">
  <div class="modal-back"></div>
  <div class="modal-dialog modal-md">
    <div class="modal-content">
      <div class="modal-header">
        <h2 class="modal-title" id="modalFileNm_title"><spring:message code="comSymPrm.fileNmSearch.pageTop.title"/></h2>
      </div>
      <div class="modal-conts" id="modalFileNm_body"></div>
      <button type="button" class="btn-close" aria-label="닫기"
              onclick="krds_modal.closeModal('modalFileNm');">&times;</button>
    </div>
  </div>
</div>

<div class="krds-modal" id="modalUpperMenuId" aria-hidden="true" role="dialog" aria-labelledby="modalUpperMenuId_title">
  <div class="modal-back"></div>
  <div class="modal-dialog modal-md">
    <div class="modal-content">
      <div class="modal-header">
        <h2 class="modal-title" id="modalUpperMenuId_title">상위메뉴 선택</h2>
      </div>
      <div class="modal-conts" id="modalUpperMenuId_body"></div>
      <button type="button" class="btn-close" aria-label="닫기"
              onclick="krds_modal.closeModal('modalUpperMenuId');">&times;</button>
    </div>
  </div>
</div>

<!-- ********** 여기까지 내용 *************** -->
</lay:layout>
