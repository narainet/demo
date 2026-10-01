<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/uss/ion/brd/EgovBrand.jsp

  브랜드설정 — 로고(텍스트/이미지)와 파비콘을 화면에서 지정한다.
  고객사별 리브랜딩 지점이라 표준 패키지에 둔다(다른 프로젝트 이식 대상).
  첨부 UI 는 공용 드롭존(cmm/fms/attachDropzone.jsp) 재사용.
--%>
<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">브랜드설정</c:set>
<c:set var="pageHead">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="<c:url value="/css/egovframework/com/com.css"/>" rel="stylesheet" type="text/css">
<link href="<c:url value="/css/egovframework/com/button.css"/>" rel="stylesheet" type="text/css">
<script type="text/javaScript" language="javascript">
function fncBrandSave() {
	var f = document.getElementById("brand");
	var ty = document.querySelector('input[name=logoTyCode]:checked').value;
	if (ty === 'TEXT' && !f.logoText.value.trim()) {
		alert("로고 텍스트를 입력하세요.");
		f.logoText.focus();
		return;
	}
	if (ty === 'IMAGE' && !document.getElementById("brdLogo").files.length
			&& document.getElementById("hasLogoImage").value !== 'Y') {
		alert("로고 이미지를 선택하세요.");
		return;
	}
	if (confirm("저장 하시겠습니까?")) {
		f.action = "<c:url value='/uss/ion/brd/updtBrand.do'/>";
		f.submit();
	}
}
/* 이미지 모드에서 안 쓰이는 칸만 흐리게.
   ★ 로고 텍스트는 흐리게 하지 않는다 — 이미지 모드에서도 브라우저 탭 제목·로고 툴팁·대체텍스트로
     계속 쓰이므로 언제든 편집할 수 있어야 한다(2026-07-31). */
function fncBrandToggle() {
	var ty = document.querySelector('input[name=logoTyCode]:checked').value;
	document.getElementById("rowLogoImage").style.opacity = (ty === 'IMAGE') ? '' : '0.45';
}
document.addEventListener("DOMContentLoaded", fncBrandToggle);
</script>
<style>
	.brd-input { width:100% !important; max-width:640px !important; box-sizing:border-box; }
	.brd-hint { display:block; margin-top:6px; font-size:12px; color:#667085; }
	.brd-cur { display:flex; align-items:center; gap:14px; margin-bottom:10px; }
	.brd-cur-img { max-width:320px; max-height:80px; padding:6px; box-sizing:border-box;
	               background:#fafbfc; border:1px solid #e4e7ec; border-radius:8px; }
	.brd-cur-ico { width:32px; height:32px; padding:3px; box-sizing:border-box;
	               background:#fafbfc; border:1px solid #e4e7ec; border-radius:6px; }
	.brd-none { color:#98a2b3; font-size:13px; }
	.brd-ty label { margin-right:18px; }
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg"/></noscript>

<form:form modelAttribute="brand" method="post" enctype="multipart/form-data"
           action="${pageContext.request.contextPath}/uss/ion/brd/updtBrand.do">
<div class="wTableFrm">
	<h2>브랜드설정</h2>
	<p class="brd-hint">로그인 화면·상단 헤더·브라우저 탭에 표시되는 이름과 아이콘을 지정합니다. 저장 즉시 반영됩니다.</p>

	<c:if test="${not empty message}"><p class="brd-hint" style="color:#1a7f37;"><c:out value="${message}"/></p></c:if>

	<input type="hidden" id="hasLogoImage" value="${not empty brand.logoAtchFileId ? 'Y' : 'N'}"/>

	<table class="wTable">
		<colgroup>
			<col style="width:16%" />
			<col style="" />
		</colgroup>
		<tr>
			<th>로고 표시 방식 <span class="pilsu">*</span></th>
			<td class="left brd-ty">
				<label><input type="radio" name="logoTyCode" value="TEXT" onclick="fncBrandToggle();"
				       <c:if test="${brand.logoTyCode ne 'IMAGE'}">checked="checked"</c:if> /> 텍스트</label>
				<label><input type="radio" name="logoTyCode" value="IMAGE" onclick="fncBrandToggle();"
				       <c:if test="${brand.logoTyCode eq 'IMAGE'}">checked="checked"</c:if> /> 이미지</label>
				<span class="brd-hint">이미지를 선택하면 헤더·로그인 화면에 텍스트 대신 그림이 표시됩니다. (아래 로고 텍스트는 두 방식 모두에서 쓰입니다)</span>
			</td>
		</tr>
		<tr id="rowLogoText">
			<th>로고 텍스트</th>
			<td class="left">
				<input id="logoText" type="text" name="logoText" maxlength="100" class="brd-input"
				       value="<c:out value='${brand.logoText}'/>" title="로고 텍스트" />
				<span class="brd-hint">화면에 나오는 한 줄 전체를 입력합니다. 예) LegalNex 법률규정통합관리시스템<br/>
				이미지로 표시하더라도 이 문구는 <b>브라우저 탭 제목</b>과 <b>로고 툴팁·대체텍스트</b>로 계속 사용됩니다.</span>
			</td>
		</tr>
		<tr id="rowLogoImage">
			<th>로고 이미지</th>
			<td class="left">
				<c:choose>
					<c:when test="${not empty brand.logoAtchFileId}">
						<div class="brd-cur">
							<img class="brd-cur-img" alt="현재 로고" src="<c:url value='/cmm/brand/logo.do'/>?v=${brandVersion}"/>
							<span class="brd-hint">현재 등록된 로고 — 새 파일을 올리면 교체됩니다.</span>
						</div>
					</c:when>
					<c:otherwise><p class="brd-none">등록된 로고 이미지가 없습니다.</p></c:otherwise>
				</c:choose>
				<c:set var="aId" value="brdLogo" scope="request"/>
				<c:set var="aName" value="logoFile" scope="request"/>
				<c:set var="aMax" value="1" scope="request"/>
				<c:set var="aAccept" value="image/png,image/jpeg,image/gif,image/svg+xml" scope="request"/>
				<c:set var="aNote" value="PNG · JPG · GIF · SVG. 헤더 높이에 맞춰 축소되므로 가로로 긴 이미지가 적합합니다." scope="request"/>
				<jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
			</td>
		</tr>
		<tr>
			<th>파비콘</th>
			<td class="left">
				<c:choose>
					<c:when test="${not empty brand.faviconAtchFileId}">
						<div class="brd-cur">
							<img class="brd-cur-ico" alt="현재 파비콘" src="<c:url value='/cmm/brand/favicon.do'/>?v=${brandVersion}"/>
							<span class="brd-hint">현재 등록된 파비콘 — 새 파일을 올리면 교체됩니다.</span>
						</div>
					</c:when>
					<c:otherwise><p class="brd-none">등록된 파비콘이 없습니다. (기본 아이콘이 표시됩니다)</p></c:otherwise>
				</c:choose>
				<c:set var="aId" value="brdFavicon" scope="request"/>
				<c:set var="aName" value="faviconFile" scope="request"/>
				<c:set var="aMax" value="1" scope="request"/>
				<c:set var="aAccept" value="image/png,image/svg+xml,image/x-icon,image/gif" scope="request"/>
				<c:set var="aNote" value="SVG · PNG · ICO. 정사각형(예: 32x32 이상) 이미지를 권장합니다." scope="request"/>
				<jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
			</td>
		</tr>
		<%-- 연락처(2026-08-04) — 포탈 공개 메인 '오시는 길'의 데이터원. 비워두면 해당 항목이 표시되지 않는다. --%>
		<tr>
			<th>주소</th>
			<td class="left">
				<input id="cntcAdres" type="text" name="cntcAdres" maxlength="100" class="brd-input"
				       value="<c:out value='${brand.cntcAdres}'/>" title="주소" />
				<span class="brd-hint">포탈 첫 화면(오시는 길)에 표시됩니다. 예) (34036) 대전광역시 유성구 테크노10로 33</span>
			</td>
		</tr>
		<tr>
			<th>대표전화</th>
			<td class="left">
				<input id="cntcTelno" type="text" name="cntcTelno" maxlength="30" class="brd-input" style="max-width:280px !important;"
				       value="<c:out value='${brand.cntcTelno}'/>" title="대표전화" />
			</td>
		</tr>
		<tr>
			<th>팩스</th>
			<td class="left">
				<input id="cntcFxnum" type="text" name="cntcFxnum" maxlength="30" class="brd-input" style="max-width:280px !important;"
				       value="<c:out value='${brand.cntcFxnum}'/>" title="팩스" />
			</td>
		</tr>
		<tr>
			<th>이메일</th>
			<td class="left">
				<input id="cntcEmailAdres" type="text" name="cntcEmailAdres" maxlength="100" class="brd-input" style="max-width:360px !important;"
				       value="<c:out value='${brand.cntcEmailAdres}'/>" title="이메일" />
				<span class="brd-hint">비워두면 포탈에서 해당 항목이 숨겨집니다.</span>
			</td>
		</tr>
	</table>

	<div class="btn">
		<input class="s_submit" type="submit" value="저장" onclick="fncBrandSave(); return false;" />
	</div>
</div>
</form:form>
</lay:layout>
