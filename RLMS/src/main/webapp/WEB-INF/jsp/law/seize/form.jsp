<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/seize/form.jsp
  압류(가압류·가처분) 등록/수정 공용 폼 — LAW_MODULE_DESIGN.md §7.10.
   - 채권자*/채무자*/제3채무자*/담당부서/관할법원*/사건번호*/메모/첨부(5개·10MB).
   - 관할법원=LAW_COURT select + 직접입력(COURT_NM 텍스트 저장), 담당부서=COMTNORGNZTINFO select.
   - KRDS 정본 폼 패턴(규정관리 동일): krds-form + table.tbl-detail(th 라벨/td 입력). 첨부=게시판 드롭존(공용 inc).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><c:choose><c:when test="${mode eq 'edit'}">압류 수정</c:when><c:otherwise>압류 등록</c:otherwise></c:choose></c:set>
<c:set var="pageHead">
  
  <style>
    /* 입력 폼 — tbl-detail 셀 기본 가운데정렬을 좌측으로(입력 컨트롤 정렬) */
    #seizeForm table.tbl-detail td { text-align: left; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1><c:choose><c:when test="${mode eq 'edit'}">압류 수정</c:when><c:otherwise>압류 등록</c:otherwise></c:choose></h1>
    <p class="page-desc">가압류·가처분 사건 정보를 입력합니다. 첨부는 문서파일 5개·개당 10MB 이내입니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <form id="seizeForm" class="krds-form" action="<c:url value='/law/seize/save.do'/>" method="post" enctype="multipart/form-data">
    <input type="hidden" name="seizeId" value="<c:out value='${seize.seizeId}'/>"/>
    <input type="hidden" name="atchFileId" value="<c:out value='${seize.atchFileId}'/>"/>
    <input type="hidden" name="courtNm" id="courtNm" value=""/>

    <table class="krds-table tbl-detail">
      <colgroup><col style="width:18%"/><col/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label required" for="creditor">채권자</label></th>
          <td><input type="text" id="creditor" name="creditor" class="krds-input" maxlength="200" value="<c:out value='${seize.creditor}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label required" for="debtor">채무자</label></th>
          <td><input type="text" id="debtor" name="debtor" class="krds-input" maxlength="200" value="<c:out value='${seize.debtor}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label required" for="thirdDebtor">제3채무자</label></th>
          <td><input type="text" id="thirdDebtor" name="thirdDebtor" class="krds-input" maxlength="200" value="<c:out value='${seize.thirdDebtor}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="orgnztId">담당부서</label></th>
          <td>
            <select id="orgnztId" name="orgnztId" class="krds-select">
              <option value="">선택</option>
              <c:forEach var="og" items="${orgnzts}">
                <option value="<c:out value='${og.orgnztId}'/>" <c:if test="${seize.orgnztId eq og.orgnztId}">selected</c:if>><c:out value="${og.orgnztNm}"/></option>
              </c:forEach>
            </select>
          </td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label required" for="courtSel">관할법원</label></th>
          <td>
            <select id="courtSel" class="krds-select" onchange="fnCourtChange();">
              <option value="">직접입력</option>
              <c:forEach var="ct" items="${courts}">
                <option value="<c:out value='${ct.courtNm}'/>" <c:if test="${seize.courtNm eq ct.courtNm}">selected</c:if>><c:out value="${ct.courtNm}"/></option>
              </c:forEach>
            </select>
            <input type="text" id="courtNmIn" class="krds-input" style="margin-top:6px; display:none;" maxlength="150"
                   placeholder="법원명 직접입력" value="<c:out value='${seize.courtNm}'/>"/>
          </td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label required" for="caseNo">사건번호</label></th>
          <td><input type="text" id="caseNo" name="caseNo" class="krds-input" maxlength="100" value="<c:out value='${seize.caseNo}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="memo">메모</label></th>
          <td><textarea id="memo" name="memo" rows="4" class="krds-input" maxlength="4000"><c:out value="${seize.memo}"/></textarea></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label">첨부파일</label></th>
          <td>
            <c:set var="aId" value="seizeAtch" scope="request"/>
            <c:set var="aName" value="file_1" scope="request"/>
            <c:set var="aMax" value="5" scope="request"/>
            <c:set var="aNote" value="문서파일 5개·개당 10MB 이내" scope="request"/>
            <c:set var="aExistFileId" value="${seize.atchFileId}" scope="request"/>
            <c:set var="aExistFiles" value="${mode eq 'edit' ? seize.files : null}" scope="request"/>
            <jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
          </td>
        </tr>
      </tbody>
    </table>

    <div class="btn-area center">
      <button type="button" class="krds-btn primary medium" onclick="fnSubmit();">저장</button>
      <c:choose>
        <c:when test="${mode eq 'edit'}">
          <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/seize/view.do"/>?seizeId=<c:out value="${seize.seizeId}"/>';">취소</button>
        </c:when>
        <c:otherwise>
          <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/seize/list.do"/>';">취소</button>
        </c:otherwise>
      </c:choose>
    </div>
  </form>

  <script>
  function fnCourtChange() {
    var sel = document.getElementById('courtSel');
    document.getElementById('courtNmIn').style.display = sel.value === '' ? '' : 'none';
  }
  function fnSubmit() {
    var req = [['creditor','채권자'],['debtor','채무자'],['thirdDebtor','제3채무자'],['caseNo','사건번호']];
    for (var i=0;i<req.length;i++){ if(!document.getElementById(req[i][0]).value.trim()){ alert(req[i][1]+'은(는) 필수입니다.'); document.getElementById(req[i][0]).focus(); return; } }
    var sel = document.getElementById('courtSel');
    var courtNm = sel.value === '' ? document.getElementById('courtNmIn').value.trim() : sel.value;
    if (!courtNm) { alert('관할법원은 필수입니다.'); return; }
    document.getElementById('courtNm').value = courtNm;
    document.getElementById('seizeForm').submit();
  }
  (function init(){ fnCourtChange(); })();
  </script>
</lay:layout>
