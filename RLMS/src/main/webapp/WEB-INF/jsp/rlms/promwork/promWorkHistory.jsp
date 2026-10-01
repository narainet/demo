<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/promwork/promWorkHistory.jsp

  규정 승인 워크플로 — 이력 화면. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">승인 이력</c:set>
<lay:layout title="${pageTitle}">
  <div class="page-header">
    <h1>승인 이력 (규정 No: <c:out value="${promNo}"/>)</h1>
  </div>

  <h2>승인 처리 이력</h2>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">상태</th>
        <th scope="col">액션</th>
        <th scope="col">신청자/처리자</th>
        <th scope="col">일시</th>
        <th scope="col">사유</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty workList}">
          <tr><td colspan="6" class="empty-row">이력이 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${workList}" varStatus="st">
            <tr>
              <td><c:out value="${row.workNo}"/></td>
              <td><c:out value="${row.status}"/></td>
              <td><c:out value="${row.actNm}"/></td>
              <td><c:out value="${row.userNm}"/> (<c:out value="${row.userId}"/>)</td>
              <td><c:out value="${row.insDt}"/></td>
              <td><c:out value="${row.reason}"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <h2>작업 내역</h2>
  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">구분</th>
        <th scope="col">액션</th>
        <th scope="col">설명</th>
        <th scope="col">사용자</th>
        <th scope="col">일시</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty logList}">
          <tr><td colspan="6" class="empty-row">로그가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="log" items="${logList}">
            <tr>
              <td><c:out value="${log.actLogNo}"/></td>
              <td>
                <c:choose>
                  <c:when test="${log.actType eq 'INSERT'}">등록</c:when>
                  <c:when test="${log.actType eq 'UPDATE'}">수정</c:when>
                  <c:when test="${log.actType eq 'DELETE'}">삭제</c:when>
                  <c:when test="${log.actType eq 'APPROVE'}">승인</c:when>
                  <c:when test="${log.actType eq 'REJECT'}">반려</c:when>
                  <c:otherwise>기타</c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${log.actNm}"/></td>
              <td><c:out value="${log.actDc}"/></td>
              <td><c:out value="${log.userNm}"/> (<c:out value="${log.userId}"/>)</td>
              <td><c:out value="${log.insDt}"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <div class="btn-area">
    <a href="<c:url value='/rlms/promwork/selectPromWorkList.do'/>" class="krds-btn medium">목록으로</a>
  </div>
</lay:layout>
