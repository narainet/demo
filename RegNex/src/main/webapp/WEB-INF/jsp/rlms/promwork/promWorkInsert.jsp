<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/promwork/promWorkInsert.jsp

  규정 승인 워크플로 — 승인요청 팝업 (PGM-001-01-08). KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">승인요청</c:set>
<lay:layout title="${pageTitle}">
  <div class="page-header">
    <h2>승인요청</h2>
  </div>

  <form id="addForm" name="addForm" action="<c:url value='/rlms/promwork/insertPromWork.do'/>"
        method="post" class="krds-form" onsubmit="return fnValidate();">
    <input type="hidden" name="promNo" value="<c:out value='${promWorkVO.promNo}'/>"/>
    <%-- 제출 후 복귀 URL (IDE 등에서 진입 시) — 서버가 내부 경로만 허용(safeReturnUrl) --%>
    <input type="hidden" name="returnUrl" value="<c:out value='${returnUrl}'/>"/>

    <table class="krds-table tbl-detail">
      <colgroup><col style="width:25%"/><col/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label">규정 제목</label></th>
          <td><c:out value="${promWorkVO.promTitle}"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label">분류</label></th>
          <td><c:out value="${promWorkVO.cateNm}"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label">현재 상태</label></th>
          <td><c:out value="${promWorkVO.status}"/></td>
        </tr>
        <c:if test="${empty blockMsg}">
        <tr>
          <th scope="row"><label class="form-label required" for="reason">사유</label></th>
          <td>
            <textarea id="reason" name="reason" class="krds-input" rows="8" required></textarea>
          </td>
        </tr>
        </c:if>
      </tbody>
    </table>

    <%-- 중복 요청 가드 — 이미 승인요청 진행 중이면 재요청 불가 --%>
    <c:if test="${not empty blockMsg}">
      <div class="krds-alert warn"><c:out value="${blockMsg}"/></div>
    </c:if>

    <div class="btn-area right">
      <%-- 전체 페이지 이동으로 진입(IDE 등) — 팝업이 아니므로 window.close() 대신 이전 화면으로 --%>
      <button type="button" class="krds-btn medium" onclick="fnGoBack();">돌아가기</button>
      <c:if test="${empty blockMsg}">
        <button type="submit" class="krds-btn primary medium">신청</button>
      </c:if>
    </div>
  </form>

  <script>
    function fnValidate() {
      var r = document.getElementById('reason');
      if (!r || !r.value || r.value.replace(/\s/g, '') === '') {
        alert('사유를 입력하세요.');
        if (r) r.focus();
        return false;
      }
      return true;
    }
    function fnGoBack() {
      if (history.length > 1) { history.back(); }
      else { location.href = '<c:url value="/rlms/promwork/selectPromWorkList.do"/>'; }
    }
  </script>
</lay:layout>
