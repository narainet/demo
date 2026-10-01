<%
/**
 * @Class Name : EgovloginLogList.jsp
 * @Description : 접속로그 정보목록 화면
 * @Modification Information
 * @
 * @  수정일      수정자          수정내용
 * @  -------     --------    ---------------------------
 * @ 2009.03.11   이삼섭          최초 생성
 * @ 2011.07.08   이기하          패키지 분리로 경로 수정(sym.log -> sym.log.clg)
 * @ 2011.09.14   서준식          검색 후 화면에 검색일자 표시안되는 오류 수정
 * @ 2017.09.21   이정은          표준프레임워크 v3.7 개선
 * @author 공통서비스 개발팀 이삼섭
 * @since 2009.03.11
 * @version 1.0
 * @see
 *
 */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><spring:message code="comSymLogClg.loginLog.title"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/com.css' />">
<link type="text/css" rel="stylesheet" href="<c:url value='/css/egovframework/com/cmm/jqueryui.css' />">
<script src="<c:url value='/js/egovframework/com/cmm/jquery.js' />"></script>
<script src="<c:url value='/js/egovframework/com/cmm/jqueryui.js' />"></script>
<script type="text/javascript">
/*********************************************************
 * 초기화
 ******************************************************** */
function fn_egov_init(){
	// 첫 입력란에 포커스..
	document.LoginLogForm.searchWrd.focus();
}
/*********************************************************
 * 페이징 처리 함수
 ******************************************************** */
function fn_egov_select_linkPage(pageNo){
	document.LoginLogForm.pageIndex.value = pageNo;
	document.LoginLogForm.action = "<c:url value='/sym/log/clg/SelectLoginLogList.do'/>";
   	document.LoginLogForm.submit();
}
/*********************************************************
 * 조회 처리 함수
 ******************************************************** */
function fn_egov_search_loginLog(){
	var vFrom = document.LoginLogForm;

	 if(vFrom.searchEndDe.value != ""){
	     if(vFrom.searchBgnDe.value > vFrom.searchEndDe.value){
	         alert("<spring:message code="comSymLogClg.validate.dateCheck" />"); //검색조건의 시작일자가 종료일자보다  늦습니다. 검색조건 날짜를 확인하세요!
	         return;
		  }
	 }else{
		 vFrom.searchEndDe.value = "";
	 }

	vFrom.pageIndex.value = "1";
	vFrom.action = "<c:url value='/sym/log/clg/SelectLoginLogList.do'/>";
	vFrom.submit();
}
/* ********************************************************
 * 상세회면 처리 함수
 ******************************************************** */
function fn_egov_detail_loginLog(logId) {
  	var width = 850;
  	var height = 330;
  	var top = 0;
  	var left = 0;
  	var url = "<c:url value='/sym/log/clg/SelectLoginLogDetail.do' />?logId="+logId;
  	var name = "LoginLogDetailPopup"
  	var openWindows = window.open(url,name, "width="+width+",height="+height+",top="+top+",left="+left+",toolbar=no,status=no,location=no,scrollbars=yes,menubar=no,resizable=yes");
}
</script>
<style>
.board_list tbody td img{align: middle;}
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}" bodyOnload="fn_egov_init();">
<!-- javascript warning tag  -->
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<form name="LoginLogForm" action="<c:url value='/sym/log/clg/SelectLoginLogList.do'/>" method="post" onSubmit="fn_egov_search_loginLog(); return false;"> 
<div class="board">
	<h1>${pageTitle}</h1>
	<!-- 검색영역 -->
	<!-- 발생일자 선택 -->
	<div class="search_box" title="<spring:message code="common.searchCondition.msg" />">
		<ul>
			<li>
				<spring:message code="comSymLogClg.loginLog.occrrncDe" />&nbsp;:&nbsp;<!-- 발생일자 -->
				<input type="date" name="searchBgnDe" id="searchBgnDe" class="krds-input" value="${searchVO.searchBgnDe}" title="<spring:message code="comSymLogClg.seachWrd.searchBgnDe" />" > ~ <!-- 검색시작일  -->
				<input type="date" name="searchEndDe" id="searchEndDe" class="krds-input" value="${searchVO.searchEndDe}" title="<spring:message code="comSymLogClg.seachWrd.searchEndDe" />" >&nbsp;&nbsp;&nbsp;<!-- 검색종료일  -->				
			</li>
			<%-- 로그유형: searchWrd 는 CONECT_MTHD 하나만 대상으로 하는 조건이라(매퍼 selectLoginLogInf 참조)
			     원래 자유입력 칸에 코드 'I'/'O' 를 직접 쳐야 했다. 목록이 라벨로 바뀐 만큼 선택형으로 교체 (2026-07-29) --%>
			<li>
				<spring:message code="comSymLogClg.loginLog.loginMthd" />&nbsp;:&nbsp;
				<select name="searchWrd" class="krds-select" title="<spring:message code="comSymLogClg.loginLog.loginMthd" /> 선택">
					<option value="" <c:if test="${empty searchVO.searchWrd}">selected</c:if>>전체</option>
					<option value="I" <c:if test="${searchVO.searchWrd eq 'I'}">selected</c:if>>로그인</option>
					<option value="O" <c:if test="${searchVO.searchWrd eq 'O'}">selected</c:if>>로그아웃</option>
				</select>&nbsp;
				<input type="submit" class="s_btn" value="<spring:message code="button.inquire" />" title="<spring:message code="title.inquire" /> <spring:message code="input.button" />" />
			</li>
		</ul>
	</div>
	
	<!-- 목록영역 -->
	<table class="board_list" summary="<spring:message code="common.summary.list" arguments="${pageTitle}" />">
	<caption>${pageTitle}<spring:message code="title.list" /></caption>
	<colgroup>
		<col style="width: 5%;">
		<col style="width: ;">
		<col style="width: ;">
		<col style="width: 10%;">
		<col style="width: 10%;">
		<col style="width: ;">
		<col style="width: 10%;">
	</colgroup>
	<thead>
	<tr>
		<th><spring:message code="table.num" /></th><!-- 번호 -->
		<th><spring:message code="comSymLogClg.loginLog.logId" /></th><!-- 로그ID -->
		<th><spring:message code="comSymLogClg.loginLog.occrrncDe" /></th><!-- 발생일자 -->
		<th><spring:message code="comSymLogClg.loginLog.loginMthd" /></th><!-- 로그유형 -->
		<th><spring:message code="comSymLogClg.loginLog.loginNm" /></th><!-- 사용자 -->
		<th><spring:message code="comSymLogClg.loginLog.loginIp" /></th><!-- 접속IP -->
		<th><spring:message code="comSymLogClg.loginLog.detail" /></th><!-- 상세보기 -->
	</tr>
	</thead>
	<tbody class="ov">
	<c:if test="${fn:length(resultList) == 0}">
	<tr>
		<td colspan="7"><spring:message code="common.nodata.msg" /></td>
	</tr>
	</c:if>
	<c:forEach items="${resultList}" var="result" varStatus="status">
	<tr>
		<td><c:out value="${(searchVO.pageIndex-1) * searchVO.pageSize + status.count}"/></td>
		<td><c:out value='${result.logId}'/></td>
		<td><c:out value='${fn:substring(result.creatDt,0,10)}'/></td>
		<%-- 코드 문자(I/O)를 그대로 보여주던 것을 라벨로 (2026-07-29) — '내 로그인 내역' 화면과 같은 표기 --%>
		<td>
			<c:choose>
				<c:when test="${result.loginMthd eq 'I'}">로그인</c:when>
				<c:when test="${result.loginMthd eq 'O'}">로그아웃</c:when>
				<c:otherwise><c:out value='${result.loginMthd}'/></c:otherwise>
			</c:choose>
		</td>
		<td><c:out value='${result.loginNm}'/></td>
		<td><c:out value='${result.loginIp}'/></td>
		<td>
		<img src="<c:url value='/images/egovframework/com/cmm/btn/btn_search.gif'/>"  class="cursor" onclick="fn_egov_detail_loginLog('<c:out value="${result.logId}"/>'); return false;" alt="<spring:message code="title.detail" />"  title="<spring:message code="title.detail" />">
		</td>
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
	 
</div>

<input name="pageIndex" type="hidden" value="<c:out value='${searchVO.pageIndex}'/>">
</form>
</lay:layout>
