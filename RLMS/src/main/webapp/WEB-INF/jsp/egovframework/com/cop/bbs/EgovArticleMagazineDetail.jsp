<%
 /**
  * @Class Name : EgovArticleMagazineDetail.jsp
  * @Description : 게시판 웹진/앨범형(MAGAZINE) 상세 — 사진 앨범(첨부 이미지 전체) + 매거진 리딩 레이아웃 + 이전/다음 글 네비.
  *                데이터 골격·버튼·댓글/만족도 조각은 EgovArticleDetail.jsp 와 동일, 프레젠테이션만 웹진풍.
  * @Modification Information
  * @
  * @  수정일             수정자                   수정내용
  * @ -------    --------    ---------------------------
  * @ 2026.07.14   RLMS               게시판 템플릿 재설계 PHASE 1 — 신규 렌더엔진
  * @ 2026.07.14   RLMS               PHASE 2 — RLMS-KRDS 디자인 시스템으로 재정렬
  * @ 2026.07.14   RLMS               사진 앨범(갤러리)+리딩 레이아웃+이전/다음 네비
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%pageContext.setAttribute("crlf", "\r\n"); %>
<c:set var="pageTitle"><spring:message code="comCopBbs.articleVO.title"/></c:set>
<%-- 링크 접두 — 사용자 열람(EgovBoardUserController)은 /cop/bbs/user, /cop/cmt/user 를 넣어준다. 관리 화면은 기본값. --%>
<c:set var="bbsUrlBase" value="${empty bbsUrlBase ? '/cop/bbs' : bbsUrlBase}"/>
<c:set var="cmtUrlBase" value="${empty cmtUrlBase ? '/cop/cmt' : cmtUrlBase}"/>
<c:set var="stfUrlBase" value="${empty stfUrlBase ? '/cop/stf' : stfUrlBase}"/>
<c:set var="pageTitle"><c:out value="${result.nttSj}"/></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_egov_delete_article(form){
	if(confirm("<spring:message code="common.delete.msg" />")){
		form.submit();
	}
}
/* 사진 앨범 — 메인 이미지 1장 표시, 썸네일/화살표로 전환. */
function fn_mgzd_album_init(){
	var album = document.getElementById('bbs-mgzd-album');
	if(!album){ return; }
	var imgs = album.getElementsByClassName('bbs-mgzd-album-img');
	var thumbs = document.querySelectorAll('#mgzd-thumbs .bbs-mgzd-thumb');
	var total = imgs.length;
	var cur = 0;
	function show(i){
		if(i < 0){ i = total - 1; }
		if(i >= total){ i = 0; }
		for(var k=0;k<imgs.length;k++){ imgs[k].style.display = (k === i) ? '' : 'none'; }
		for(var d=0;d<thumbs.length;d++){ thumbs[d].className = thumbs[d].className.replace(' active',''); }
		if(thumbs[i]){ thumbs[i].className += ' active'; }
		var cc = document.getElementById('mgzd-cur');
		if(cc){ cc.innerHTML = (i + 1); }
		cur = i;
	}
	var prev = document.getElementById('mgzd-prev');
	var next = document.getElementById('mgzd-next');
	if(prev){ prev.onclick = function(){ show(cur - 1); }; }
	if(next){ next.onclick = function(){ show(cur + 1); }; }
	for(var d=0;d<thumbs.length;d++){
		thumbs[d].onclick = function(){ show(parseInt(this.getAttribute('data-idx'), 10)); };
	}
}
if (window.addEventListener) { window.addEventListener('load', fn_mgzd_album_init); }
else { window.attachEvent('onload', fn_mgzd_album_init); }
</script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

<!-- 아티클 헤더: 게시판명 + 제목 + 메타 -->
<div class="bbs-mgzd-header">
	<p class="bbs-mgzd-board"><c:out value="${boardMasterVO.bbsNm}"/></p>
	<h1><c:out value="${result.nttSj}"/><c:if test="${result.useAt eq 'N'}"> <span class="krds-badge bg-light-gray">삭제됨</span></c:if></h1>
	<div class="bbs-mgzd-meta">
		<span><c:out value="${result.frstRegisterNm}"/></span>
		<span><c:out value="${result.frstRegisterPnttm}"/></span>
		<span><spring:message code="comCopBbs.articleVO.detail.inqireCo" /> <c:out value="${result.inqireCo}"/></span>
	</div>
</div>

<%-- 사진 앨범 — 첨부 이미지 전체(galleryImages). 메인 1장 + 썸네일/화살표 전환. 이미지가 없으면 앨범 자체 생략. --%>
<c:if test="${not empty galleryImages}">
	<c:set var="encAtch" value="${egovc:encryptSession(result.atchFileId, pageContext.session.id)}" />
	<div class="bbs-mgzd-album" id="bbs-mgzd-album">
		<div class="bbs-mgzd-album-main">
			<c:if test="${fn:length(galleryImages) > 1}"><button type="button" class="bbs-gd-nav prev" id="mgzd-prev" aria-label="이전 이미지">&#10094;</button></c:if>
			<c:forEach items="${galleryImages}" var="img" varStatus="st">
				<img class="bbs-mgzd-album-img" data-idx="${st.index}"<c:if test="${not st.first}"> style="display:none;"</c:if> src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=${encAtch}&amp;fileSn=${img.fileSn}" alt="<c:out value='${img.orignlFileNm}'/>">
			</c:forEach>
			<c:if test="${fn:length(galleryImages) > 1}"><button type="button" class="bbs-gd-nav next" id="mgzd-next" aria-label="다음 이미지">&#10095;</button></c:if>
			<c:if test="${fn:length(galleryImages) > 1}"><div class="bbs-mgzd-album-counter"><span id="mgzd-cur">1</span> / ${fn:length(galleryImages)}</div></c:if>
		</div>
		<c:if test="${fn:length(galleryImages) > 1}">
		<div class="bbs-mgzd-album-thumbs" id="mgzd-thumbs">
			<c:forEach items="${galleryImages}" var="img" varStatus="st">
				<button type="button" class="bbs-mgzd-thumb${st.first ? ' active' : ''}" data-idx="${st.index}" aria-label="${st.index + 1}번째 이미지">
					<img src="<c:url value='/cmm/fms/getImage.do'/>?atchFileId=${encAtch}&amp;fileSn=${img.fileSn}" alt="">
				</button>
			</c:forEach>
		</div>
		</c:if>
	</div>
</c:if>

<!-- 본문 -->
<div class="bbs-mgzd-content">
	<c:out value="${fn:replace(result.nttCn , crlf , '<br/>')}" escapeXml="false" />
</div>

<%-- 여분필드 — 필드마다 자기 라벨 카드. 코드형 값은 코드→코드명 변환. --%>
<c:set var="hasExtraField" value="false" />
<c:forEach begin="1" end="10" var="i">
	<c:if test="${not empty boardMasterVO.getBbsExtraField(i)}"><c:set var="hasExtraField" value="true" /></c:if>
</c:forEach>
<c:if test="${hasExtraField}">
<div class="bbs-mgzd-extra">
	<c:forEach begin="1" end="10" var="i">
		<c:set var="fieldLabel" value="${boardMasterVO.getBbsExtraField(i)}" />
		<c:if test="${not empty fieldLabel}">
			<c:set var="fieldValue" value="${result.getNttExtraField(i)}" />
			<c:set var="displayValue" value="${fieldValue}" />
			<c:set var="fieldOptions" value="${bbsExtraCodeOptions[i]}" />
			<c:if test="${not empty fieldOptions and not empty fieldValue}">
				<c:set var="displayValue"><c:forTokens items="${fieldValue}" delims="," var="token" varStatus="tk"><c:if test="${not tk.first}">, </c:if><c:set var="tokenNm" value="${token}" /><c:forEach var="code" items="${fieldOptions}"><c:if test="${token == code.code}"><c:set var="tokenNm" value="${code.codeNm}" /></c:if></c:forEach>${tokenNm}</c:forTokens></c:set>
			</c:if>
			<p><strong><c:out value="${fieldLabel}" /></strong><span><c:out value="${displayValue}" /></span></p>
		</c:if>
	</c:forEach>
</div>
</c:if>

<%-- 게시기간 — 실제 기간이 설정된 글에만. 무의미 sentinel(1900-01-01~9999-12-31)은 감춘다. --%>
<c:set var="pBgn" value="${fn:trim(result.ntceBgnde)}" />
<c:set var="pEnd" value="${fn:trim(result.ntceEndde)}" />
<c:set var="showBgn" value="${not empty pBgn and pBgn ne '1900-01-01'}" />
<c:set var="showEnd" value="${not empty pEnd and pEnd ne '9999-12-31'}" />
<c:if test="${showBgn or showEnd}">
<p class="bbs-mgzd-period"><spring:message code="comCopBbs.articleVO.detail.ntceDe" /> : <c:out value="${showBgn ? pBgn : ''} ~ ${showEnd ? pEnd : ''}" /></p>
</c:if>

<!-- 첨부파일 (다운로드 목록) -->
<c:if test="${not empty result.atchFileId}">
<div class="bbs-mgzd-files">
	<h2><spring:message code="comCopBbs.articleVO.detail.atchFile" /></h2>
	<c:import url="/cmm/fms/selectFileInfs.do" charEncoding="utf-8">
		<c:param name="param_atchFileId" value="${egovc:encrypt(result.atchFileId)}" />
	</c:import>
</div>
</c:if>

<%-- 이전 글 / 다음 글 네비 (비밀글·삭제글 제외됨). --%>
<c:if test="${not empty prevArticle or not empty nextArticle}">
<nav class="bbs-mgzd-nav" aria-label="이전 다음 글">
	<c:choose>
		<c:when test="${not empty prevArticle}">
			<a class="bbs-mgzd-nav-item prev" href="<c:url value='${bbsUrlBase}/selectArticleDetail.do'/>?nttId=${prevArticle.nttId}&amp;bbsId=${boardMasterVO.bbsId}">
				<span class="bbs-mgzd-nav-dir">&#8249; 이전 글</span>
				<span class="bbs-mgzd-nav-title"><c:out value="${prevArticle.nttSj}"/></span>
			</a>
		</c:when>
		<c:otherwise><span class="bbs-mgzd-nav-item disabled"><span class="bbs-mgzd-nav-dir">&#8249; 이전 글</span><span class="bbs-mgzd-nav-title">없음</span></span></c:otherwise>
	</c:choose>
	<c:choose>
		<c:when test="${not empty nextArticle}">
			<a class="bbs-mgzd-nav-item next" href="<c:url value='${bbsUrlBase}/selectArticleDetail.do'/>?nttId=${nextArticle.nttId}&amp;bbsId=${boardMasterVO.bbsId}">
				<span class="bbs-mgzd-nav-dir">다음 글 &#8250;</span>
				<span class="bbs-mgzd-nav-title"><c:out value="${nextArticle.nttSj}"/></span>
			</a>
		</c:when>
		<c:otherwise><span class="bbs-mgzd-nav-item next disabled"><span class="bbs-mgzd-nav-dir">다음 글 &#8250;</span><span class="bbs-mgzd-nav-title">없음</span></span></c:otherwise>
	</c:choose>
</nav>
</c:if>

<!-- 하단 버튼 -->
<div class="btn-area">
	<%-- 관리 동선은 항상. 사용자 동선은 작성권한(bbsCanWrite) + 본인 글일 때만 수정/삭제를 보인다. --%>
	<c:set var="bbsUserCanEdit" value="${bbsCanWrite and not empty sessionUniqId and result.frstRegisterId == sessionUniqId}" />
	<c:if test="${result.useAt eq 'Y' and result.ntcrId != 'anonymous' and (empty bbsUserMode or bbsUserCanEdit)}">
	<form name="articleForm" action="<c:url value='${bbsUrlBase}/updateArticleView.do'/>" method="get" style="display:inline;">
		<button type="submit" class="krds-btn primary medium" title="<spring:message code="title.update" /> <spring:message code="input.button" />"><spring:message code="button.update" /></button><!-- 수정 -->
		<input type="hidden" name="parnts" value="<c:out value='${result.parnts}'/>" >
		<input type="hidden" name="sortOrdr" value="<c:out value='${result.sortOrdr}'/>" >
		<input type="hidden" name="replyLc" value="<c:out value='${result.replyLc}'/>" >
		<input type="hidden" name="nttSj" value="<c:out value='${result.nttSj}'/>" >
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	<form name="formDelete" action="<c:url value='${bbsUrlBase}/deleteArticle.do'/>" method="post" style="display:inline;">
		<button type="submit" class="krds-btn danger medium" title="<spring:message code="button.delete" /> <spring:message code="input.button" />" onclick="fn_egov_delete_article(this.form); return false;"><spring:message code="button.delete" /></button><!-- 삭제 -->
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	</c:if>
	<c:if test="${result.useAt eq 'Y' and boardMasterVO.replyPosblAt == 'Y' and (empty bbsUserMode or bbsCanWrite)}">
	<form name="formReply" action="<c:url value='${bbsUrlBase}/replyArticleView.do'/>" method="post" style="display:inline;">
		<button type="submit" class="krds-btn secondary medium"><spring:message code="button.reply" /></button><!-- 답글 -->
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
	</form>
	</c:if>
	<c:if test="${result.useAt eq 'N' and isAdmin}">
	<form name="articleForm" action="<c:url value='/cop/bbs/updateArticleView.do'/>" method="get" style="display:inline;">
		<button type="submit" class="krds-btn primary medium">수정 / 복구</button>
		<input name="nttId" type="hidden" value="<c:out value="${result.nttId}" />">
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
	</c:if>
	<form name="formList" action="<c:url value='${bbsUrlBase}/selectArticleList.do'/>" method="get" style="display:inline;">
		<button type="submit" class="krds-btn secondary medium"><spring:message code="button.list" /></button><!-- 목록 -->
		<input name="bbsId" type="hidden" value="<c:out value="${boardMasterVO.bbsId}" />">
		<input name="searchCnd" type="hidden" value="<c:out value="${searchVO.searchCnd}" />">
		<input name="searchWrd" type="hidden" value="<c:out value="${searchVO.searchWrd}" />">
		<input name="pageIndex" type="hidden" value="<c:out value="${searchVO.pageIndex}" />">
	</form>
</div>

<!-- 댓글 -->
<c:if test="${useComment == 'true'}">
	<c:import url="${cmtUrlBase}/selectArticleCommentList.do" charEncoding="utf-8"/>
</c:if>

<c:if test="${useSatisfaction == 'true'}">
	<c:import url="${stfUrlBase}/selectSatisfactionList.do" charEncoding="utf-8">
		<c:param name="type" value="body" />
	</c:import>
</c:if>
</lay:layout>
