<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp
  공용 첨부 위젯 — 게시판(EgovArticleRegist)과 동일한 EgovFileDropzone 드래그드롭 존.

  네이티브 <input type="file"> 를 채우기만 하고 업로드는 폼 제출(multipart)에 실린다
  (AJAX 업로드 아님 — 검증·redirect 가 네이티브 제출 위에 있는 폼용).

  2026-07-31 이전: /WEB-INF/jsp/law/inc/attachDropzone.jsp 에 있었다. 송무는 옵션 모듈이라
  표준 화면(배너관리 등)이 그 경로에 의존하면 모듈을 빼는 순간 깨진다 → 표준 위치로 옮김.
  옮기면서 EgovFileDropzone.js 를 이 위젯이 직접 싣도록 고쳤다(호출 화면들이 아무도 안 싣고 있어
  EgovFileDropzone 이 undefined → init 이 ReferenceError 로 죽고 드래그드롭·목록·검증이 무동작이었다).

  호출부에서 include 직전 아래 변수를 <c:set> 으로 지정:
    aId          (필수) 이 위젯의 고유 base id (한 페이지에 여러 개면 서로 다르게)
    aName        입력 name (기본 file_1)
    aMax         최대 첨부 개수 (기본 0 = 서버 Globals 상한). 1 이면 단일 선택(multiple 미부여)
    aAccept      input accept 속성 (예: image/*) — 선택
    aNote        도움말 문구 (선택)
    aExistFileId 기존 첨부 atchFileId (수정 모드 — 다운로드 링크용, 선택)
    aExistFiles  기존 첨부 목록 List(fileSn/orignlFileNm) (선택)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<c:set var="aName" value="${empty aName ? 'file_1' : aName}"/>
<%-- aId 는 반드시 scope="request" 로 넘겨야 한다(jsp:include 는 별도 pageContext).
     빠뜨리면 id 가 통째로 비어 init 이 조용히 무동작이 되므로, 최소한 단일 위젯은 살도록 기본값을 준다. --%>
<c:set var="aId" value="${empty aId ? 'atchFile' : aId}"/>
<%-- 한 페이지에 위젯이 여러 개여도 스크립트는 한 번만 --%>
<c:if test="${empty requestScope.egovFileDropzoneJs}">
  <c:set var="egovFileDropzoneJs" value="Y" scope="request"/>
  <script type="text/javascript" src="<c:url value='/js/egovframework/com/cmm/fms/EgovFileDropzone.js'/>"></script>
</c:if>
<div class="krds-file-upload">
  <div class="ide-file-drop" id="${aId}Drop">
    <input type="file" id="${aId}" name="${aName}" class="ide-file-native" title="첨부파일"
           <c:if test="${not empty aAccept}">accept="${aAccept}"</c:if><c:if test="${aMax ne 1}"> multiple</c:if> />
    <span class="txt">파일을 여기로 끌어다 놓거나 <strong>파일 선택</strong></span>
  </div>
  <div class="file-list">
    <div class="total" id="${aId}Total" style="display:none;">총 <span class="current">0</span>개</div>
    <ul id="${aId}SelList" class="upload-list"></ul>
  </div>
  <div id="${aId}Notice" class="ide-file-notice" style="display:none;"></div>
  <c:if test="${not empty aNote}"><p class="ide-file-help"><c:out value="${aNote}"/></p></c:if>

  <c:if test="${not empty aExistFiles}">
    <c:set var="aEnc" value="${egovc:encryptSession(aExistFileId, pageContext.session.id)}"/>
    <div class="file-list law-exist-list">
      <p class="law-exist-tit">기존 첨부</p>
      <ul class="upload-list">
        <c:forEach var="ef" items="${aExistFiles}">
          <li>
            <div class="file-info">
              <span class="file-name">
                <a href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${aEnc}&amp;fileSn=${ef.fileSn}"><c:out value="${ef.orignlFileNm}"/></a>
              </span>
            </div>
          </li>
        </c:forEach>
      </ul>
      <p class="ide-file-help">새 파일을 올리면 기존 첨부에 추가됩니다.</p>
    </div>
  </c:if>
</div>
<script>
EgovFileDropzone.init({
  input: '${aId}', drop: '${aId}Drop',
  list: '${aId}SelList', total: '${aId}Total', notice: '${aId}Notice',
  maxCount: ${empty aMax ? 0 : aMax},
  maxSize: parseInt('<%= egovframework.com.cmm.service.EgovProperties.getProperty("Globals.fileUpload.maxSize") %>', 10) || 0,
  extensions: '<%= egovframework.com.cmm.service.EgovProperties.getProperty("Globals.fileUpload.Extensions") %>'
});
</script>
