<%
 /**
  * @Class Name : EgovBBSMasterList.jsp
  * @Description : EgovBBSMasterList 화면
  * @Modification Information
  * @
  * @  수정일             수정자                   수정내용
  * @ -------    --------    ---------------------------
  * @ 2009.02.01   박정규              최초 생성
  * @ 2016.06.13   김연호              표준프레임워크 v3.6 개선
  * @ 2018.10.15   최두영             표준프레임워크 V3.8 개선
  *  @author 공통서비스팀
  *  @since 2009.02.01
  *  @version 1.0
  *  @see
  *
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 화면명은 메뉴명(80010000 게시판속성관리)을 따른다 — 공용 코드 comCopBbs.boardMasterVO.title 은
     게시판 모듈 전반이 '게시판'이라는 명사로 쓰므로 이 화면에서만 리터럴로 덮는다 (2026-07-29) --%>
<c:set var="pageTitle" value="게시판속성관리"/>
<c:set var="pageHead">
<!-- 게시판 목록 -->
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<style>
.bbs-master-list-head {display:flex;align-items:flex-end;justify-content:space-between;gap:16px;margin-bottom:18px;}
.bbs-master-list-head h1 {margin:0;font-size:28px;line-height:1.3;color:#1d1d1d;font-weight:700;}
.bbs-master-list-search {display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin:0 0 24px;padding:16px;border:1px solid #d8dde8;background:#f7f9fc;box-sizing:border-box;}
.bbs-master-list-search select,
.bbs-master-list-search input[type="text"] {height:40px;border:1px solid #c8ced8;padding:0 10px;background:#fff;box-sizing:border-box;}
.bbs-master-list-search select {min-width:150px;}
.bbs-master-list-search input[type="text"] {min-width:260px;}
.bbs-master-list-search .s_btn,
.bbs-master-list-create {height:40px;padding:0 16px;border:0;background:#246beb;color:#fff;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;justify-content:center;box-sizing:border-box;}
.bbs-master-list-search .s_btn:hover,
.bbs-master-list-create:hover {background:#1d56bd;color:#fff;text-decoration:none;}
.bbs-master-id {display:block;margin-top:3px;color:#7b8496;font-size:11px;font-family:Consolas,monospace;word-break:break-all;}
.bbs-menu-badge {display:inline-block;min-width:48px;padding:2px 7px;border-radius:3px;font-size:12px;font-weight:700;text-align:center;}
.bbs-menu-badge.on {background:#e4f0e6;color:#1c6b33;}
.bbs-menu-badge.off {background:#eceef1;color:#6b7280;}
.bbs-tmpl-badge {display:inline-block;padding:2px 9px;border-radius:3px;font-size:12px;font-weight:600;background:#eaf1fd;color:#1d56bd;}
.bbs-tmpl-badge.default {background:#eceef1;color:#6b7280;font-weight:500;}
@media (max-width:640px) {
	.bbs-master-list-head {display:block;}
	.bbs-master-list-search {align-items:stretch;}
	.bbs-master-list-search select,
	.bbs-master-list-search input[type="text"],
	.bbs-master-list-search .s_btn,
	.bbs-master-list-create {width:100%;min-width:0;}
}
</style>
<script type="text/javascript">
/*********************************************************
 * 초기화
 ******************************************************** */
function fn_egov_init(){
	// 첫 입력란에 포커스..
	document.BBSMasterForm.searchCnd.focus();
}

/*********************************************************
 * 페이징 처리 함수
 ******************************************************** */
function fn_egov_select_linkPage(pageNo){
	document.BBSMasterForm.pageIndex.value = pageNo;
	document.BBSMasterForm.action = "<c:url value='/cop/bbs/selectBBSMasterInfs.do'/>";
   	document.BBSMasterForm.submit();
}
/*********************************************************
 * 조회 처리 함수
 ******************************************************** */
function fn_egov_search_bbssj(){
	document.BBSMasterForm.pageIndex.value = 1;
	document.BBSMasterForm.submit();
}
/* ********************************************************
 * 상세회면 처리 함수
 ******************************************************** */
function fn_egov_inquire_bbsdetail(bbsId) {
	// 사이트 키값(siteId) 셋팅.
	document.BBSMasterForm.bbsId.value = bbsId;
  	document.BBSMasterForm.action = "<c:url value='/cop/bbs/selectBBSMasterDetail.do'/>";
  	document.BBSMasterForm.submit();
}
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init()">
<!-- javascript warning tag  -->
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<form name="BBSMasterForm" action="<c:url value='/cop/bbs/selectBBSMasterInfs.do'/>" method="post" onSubmit="fn_egov_search_bbssj(); return false;"> 
<div class="board">
	<div class="bbs-master-list-head">
		<h1>${pageTitle}</h1><!-- 게시판 목록 -->
	</div>
	<!-- 하단 버튼 -->
	<div class="bbs-master-list-search" title="<spring:message code="common.searchCondition.msg" />">
		<select name="searchCnd" title="<spring:message code="title.searchCondition" /> <spring:message code="input.cSelect" />">
			<option value="0"  <c:if test="${searchVO.searchCnd == '0'}">selected="selected"</c:if> ><spring:message code="comCopBbs.boardMasterVO.list.bbsNm" /></option><!-- 게시판명 -->
			<option value="1"  <c:if test="${searchVO.searchCnd == '1'}">selected="selected"</c:if> ><spring:message code="comCopBbs.boardMasterVO.list.bbsIntrcn" /></option><!-- 게시판 소개내용 -->
		</select>
		<input class="s_input" name="searchWrd" type="text" size="35" title="<spring:message code="title.search" /> <spring:message code="input.input" />" value="<c:out value="${searchVO.searchWrd}"/>" maxlength="155">
		<input type="submit" class="s_btn" value="<spring:message code="button.inquire" />" title="<spring:message code="title.inquire" /> <spring:message code="input.button" />"><!-- 조회 -->
		<c:url var="insertBBSMasterUrl" value="/cop/bbs/insertBBSMasterView.do">
			<c:param name="cmmntyId" value="${searchVO.cmmntyId}" />
		</c:url>
		<a class="bbs-master-list-create" href="${insertBBSMasterUrl}" title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></a><!-- 등록 -->
	</div>
	
	<!-- 목록영역 -->
	<table class="board_list" summary="<spring:message code="common.summary.list" arguments="${pageTitle}" />">
	<caption>${pageTitle}<spring:message code="title.list" /></caption>
	<colgroup>
		<col style="width: 6%;">
		<col style="width: 28%;">
		<col style="width: 14%;">
		<col style="width: 18%;">
		<col style="width: 12%;">
		<col style="width: 13%;">
		<col style="width: 8%;">
	</colgroup>
	<thead>
	<tr>
		<th><spring:message code="table.num" /></th><!-- 번호 -->
		<th class="board_th_link"><spring:message code="comCopBbs.boardMasterVO.list.bbsNm" /></th><!-- 게시판명 -->
		<th>표시형태</th><!-- 사용중인 템플릿 -->
		<th>사용자 메뉴</th>
		<th><spring:message code="table.reger" /></th><!-- 작성자명 -->
		<th><spring:message code="table.regdate" /></th><!-- 작성시각 -->
		<th><spring:message code="comCopBbs.boardMasterVO.list.useAt" /></th><!-- 사용여부 -->
	</tr>
	</thead>
	<tbody class="ov">
	<c:if test="${fn:length(resultList) == 0}">
	<tr>
		<td colspan="7"><spring:message code="common.nodata.msg" /></td>
	</tr>
	</c:if>
	<c:forEach items="${resultList}" var="resultInfo" varStatus="status">
	<c:set var="boardMenu" value="${boardMenuMap[resultInfo.bbsId]}"/>
	<tr>
		<%-- 번호는 내림차순(최신=전체건수, 마지막=1) --%>
		<td><c:out value="${resultCnt - (searchVO.pageIndex-1) * searchVO.pageUnit - status.index}"/></td>
		<td class="left">
			<a href="<c:url value='/cop/bbs/selectBBSMasterDetail.do?bbsId=${resultInfo.bbsId}'/>" onClick="fn_egov_inquire_bbsdetail('<c:out value="${resultInfo.bbsId}"/>');return false;"><c:out value='${fn:substring(resultInfo.bbsNm, 0, 40)}'/></a>
			<span class="bbs-master-id"><c:out value='${resultInfo.bbsId}'/></span>
		</td>
		<td>
			<c:choose>
				<c:when test="${not empty resultInfo.tmplatNm}"><span class="bbs-tmpl-badge"><c:out value='${resultInfo.tmplatNm}'/></span></c:when>
				<c:otherwise><span class="bbs-tmpl-badge default">목록형(기본)</span></c:otherwise>
			</c:choose>
		</td>
		<td>
			<c:choose>
				<c:when test="${not empty boardMenu}">
					<span class="bbs-menu-badge on">노출</span> <c:out value='${boardMenu.menuNm}'/>
				</c:when>
				<c:otherwise><span class="bbs-menu-badge off">비노출</span></c:otherwise>
			</c:choose>
		</td>
		<td><c:out value='${resultInfo.frstRegisterNm}'/></td>
		<td><c:out value='${resultInfo.frstRegisterPnttm}'/></td>
		<td><c:out value='${resultInfo.useAt}'/></td>
	</tr>
	</c:forEach>
	</tbody>
	</table>
	
	<!-- paging navigation -->
	<div class="pagination">
		<ul>
		<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fn_egov_select_linkPage"/>
		</ul>
	</div>
	
	<!-- 등록버튼 -->
	<!-- 
	<div class="btn">
		<span class="btn_s"><a href="<c:url value='/cop/bbs/insertBBSMasterView.do' />"  title="<spring:message code="button.create" /> <spring:message code="input.button" />"><spring:message code="button.create" /></a></span>
	</div>
	-->
	
</div>
<input name="cmmntyId" type="hidden" value="<c:out value='${searchVO.cmmntyId}'/>">
<input name="bbsId" type="hidden" value="">
<input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>">
</form>
</lay:layout>
