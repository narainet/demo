<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/doc/list.jsp
  소송문서 조회 (LAW_MODULE_DESIGN.md §7.2) — 검색·목록·승인상태·파일 다운로드(FileDown.do)·엑셀·ZIP 일괄(표준 FileZipDown.do).
  문서 등록·수정·삭제는 사건 상세(소송관리 view)에서. 여기는 조회 전용.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송문서조회</c:set>
<c:set var="pageHead">
  
  <style>
    .law-cell-sub { color:#888; font-size:12px; }
    .law-file-link { display:block; font-size:13px; }
    .law-badge { display:inline-block; padding:2px 8px; border-radius:10px; font-size:12px; }
    .law-badge.wait { background:#eef0f3; color:#555; }
    .law-badge.appr { background:#e6f4ea; color:#1a7f37; }
    .law-badge.rjct { background:#fdecec; color:#c5303a; }
    .law-dockind-box { display:flex; flex-wrap:wrap; gap:6px 14px; max-height:120px; overflow-y:auto;
                       border:1px solid #e3e3e3; border-radius:6px; padding:8px 10px; }
    <%-- 전체선택 칩 버튼 = rlms-compat.css .law-chip-btn 공통 --%>
    .law-dockind-box label { font-size:13px; white-space:nowrap; }
    <%-- 검색 그리드 = rlms-compat.css .law-search-grid 공통 --%>
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>소송문서조회</h1>
    <p class="page-desc">등록된 소송문서를 조건별로 조회하고 파일을 내려받습니다. 등록·수정은 소송 상세에서 합니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/law/doc/list.do'/>" method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" id="pageIndex" value="<c:out value='${searchVO.pageIndex}'/>"/>
    <div class="law-search-grid">
      <div>
        <label for="searchFrFrom">소제기일</label>
        <div class="law-date-range">
          <input type="date" id="searchFrFrom" name="searchFrFrom" class="krds-input" value="<c:out value='${searchVO.searchFrFrom}'/>"/>
          <span class="sep">~</span>
          <input type="date" id="searchFrTo" name="searchFrTo" class="krds-input" aria-label="소제기일(종료)" value="<c:out value='${searchVO.searchFrTo}'/>"/>
        </div>
      </div>
      <div>
        <label for="searchItpt">제·피소구분</label>
        <select id="searchItpt" name="searchItpt" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="c" items="${itptKinds}"><option value="${c.code}" ${searchVO.searchItpt eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach>
        </select>
      </div>
      <div>
        <label for="searchCaseKind">소송구분</label>
        <select id="searchCaseKind" name="searchCaseKind" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="c" items="${caseKinds}"><option value="${c.code}" ${searchVO.searchCaseKind eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach>
        </select>
      </div>
      <div>
        <label for="searchRslt">소송결과</label>
        <select id="searchRslt" name="searchRslt" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="c" items="${results}"><option value="${c.code}" ${searchVO.searchRslt eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach>
        </select>
      </div>
      <div>
        <label for="searchCaseYear">사건번호(연도)</label>
        <input type="text" id="searchCaseYear" name="searchCaseYear" class="krds-input" maxlength="4" value="<c:out value='${searchVO.searchCaseYear}'/>" placeholder="2026"/>
      </div>
      <div>
        <label for="searchCaseSign">사건부호</label>
        <select id="searchCaseSign" name="searchCaseSign" class="krds-select">
          <option value="">전체</option>
          <c:forEach var="c" items="${caseSigns}"><option value="${c.code}" ${searchVO.searchCaseSign eq c.code ? 'selected' : ''}><c:out value="${c.codeNm}"/></option></c:forEach>
        </select>
      </div>
      <div>
        <label for="searchCaseSerial">사건번호(일련)</label>
        <input type="text" id="searchCaseSerial" name="searchCaseSerial" class="krds-input" value="<c:out value='${searchVO.searchCaseSerial}'/>"/>
      </div>
      <div class="law-search-btns">
        <button type="submit" class="krds-btn small primary" onclick="document.getElementById('pageIndex').value=1;">검색</button>
        <button type="button" class="krds-btn small" onclick="location.href='<c:url value="/law/doc/list.do"/>';">초기화</button>
      </div>
      <div class="full">
        <label>문서종류 <button type="button" class="law-chip-btn" onclick="fnToggleDocKinds();">전체선택</button></label>
        <div class="law-dockind-box">
          <c:forEach var="c" items="${docKinds}">
            <label><input type="checkbox" name="searchDocKinds" value="${c.code}"
              <c:forEach var="sel" items="${searchVO.searchDocKinds}"><c:if test="${sel eq c.code}">checked</c:if></c:forEach>/> <c:out value="${c.codeNm}"/></label>
          </c:forEach>
        </div>
      </div>
    </div>
  </form>

  <div style="display:flex; justify-content:space-between; align-items:center; margin:14px 0 4px;">
    <span class="law-total" style="margin:0;">총 <strong><c:out value="${resultCnt}"/></strong>건</span>
    <span style="display:flex; gap:8px;">
      <button type="button" class="krds-btn medium" onclick="fnZipDownload();">ZIP 일괄</button>
      <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀</button>
    </span>
  </div>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:5%;">No</th>
        <th scope="col">법원명</th>
        <th scope="col">사건번호</th>
        <th scope="col">사건명</th>
        <th scope="col">문서종류</th>
        <th scope="col">파일명</th>
        <th scope="col" style="width:8%;">승인상태</th>
        <th scope="col" style="width:10%;">등록일자</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${resultCnt - ((searchVO.pageIndex-1) * searchVO.pageUnit) - st.index}"/></td>
          <td><c:out value="${row.courtNm}" default="-"/></td>
          <td><a href="<c:url value='/law/suit/view.do'/>?suitId=${row.suitId}"><c:out value="${row.caseNo}" default="(미입력)"/></a></td>
          <td><c:out value="${row.caseNm}" default="-"/> <c:if test="${not empty row.docTitl}"><span class="law-cell-sub">— <c:out value="${row.docTitl}"/></span></c:if></td>
          <td><c:out value="${row.docKindNm}" default="-"/></td>
          <td>
            <c:choose>
              <c:when test="${not empty row.files}">
                <c:set var="encF" value="${egovc:encryptSession(row.atchFileId, pageContext.session.id)}"/>
                <c:forEach var="f" items="${row.files}">
                  <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encF}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a>
                </c:forEach>
              </c:when>
              <c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
          <td>
            <c:choose>
              <c:when test="${row.appStsCd eq 'S002'}"><span class="law-badge appr">승인</span></c:when>
              <c:when test="${row.appStsCd eq 'S003'}"><span class="law-badge rjct">반려</span></c:when>
              <c:otherwise><span class="law-badge wait">대기</span></c:otherwise>
            </c:choose>
          </td>
          <td>
            <c:choose>
              <c:when test="${not empty row.regDt and fn:length(row.regDt) ge 8}"><fmt:parseDate value="${fn:substring(row.regDt,0,8)}" pattern="yyyyMMdd" var="rd"/><fmt:formatDate value="${rd}" pattern="yyyy-MM-dd"/></c:when>
              <c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="8" style="text-align:center; padding:32px 0; color:#888;">조회된 문서가 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <div class="paging" style="margin-top:16px;">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <%-- ZIP 일괄용 — 검색 결과 전체 문서의 첨부 ID(세션 암호화 토큰) --%>
  <div id="zipTokens" style="display:none;">
    <c:forEach var="fid" items="${zipAtchFileIds}">
      <span class="zip-fid" data-tok="${egovc:encryptSession(fid, pageContext.session.id)}"></span>
    </c:forEach>
  </div>

  <script>
  function fnLinkPage(pageNo){ document.getElementById('pageIndex').value = pageNo; document.getElementById('searchForm').submit(); }
  function fnToggleDocKinds(){
    var boxes = document.querySelectorAll('input[name="searchDocKinds"]');
    var allOn = Array.prototype.every.call(boxes, function(b){ return b.checked; });
    boxes.forEach(function(b){ b.checked = !allOn; });
  }
  function fnExcel(){
    var f = document.getElementById('searchForm');
    var act = f.action; f.action = '<c:url value="/law/doc/listExcel.do"/>'; f.submit(); f.action = act;
  }
  function fnZipDownload(){
    var toks = document.querySelectorAll('#zipTokens .zip-fid');
    if(!toks.length){ alert('내려받을 첨부가 있는 문서가 없습니다.'); return; }
    var form = document.createElement('form');
    form.method = 'post'; form.action = '<c:url value="/cmm/fms/FileZipDown.do"/>';
    toks.forEach(function(t){
      var i = document.createElement('input'); i.type='hidden'; i.name='atchFileId'; i.value=t.dataset.tok; form.appendChild(i);
    });
    var zn = document.createElement('input'); zn.type='hidden'; zn.name='zipName'; zn.value='소송문서_첨부'; form.appendChild(zn);
    document.body.appendChild(form); form.submit(); document.body.removeChild(form);
  }
  </script>
</lay:layout>
