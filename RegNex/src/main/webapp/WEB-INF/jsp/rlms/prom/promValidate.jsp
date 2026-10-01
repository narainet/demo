<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/promValidate.jsp

  유효성 검사 결과 화면 (PGM-001-01-04). KRDS 디자인.
   - severity 별 색상은 의미 보존을 위해 유지.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">규정별 유효성검사</c:set>
<c:set var="pageHead">
  
  <style>
    .sev-ERROR { color: #c0392b; font-weight: bold; }
    .sev-WARN  { color: #d68910; font-weight: bold; }
    .sev-INFO  { color: #2874a6; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>규정별 유효성검사</h1>
    <p class="page-desc">
      검사 범위: <strong><c:out value="${scope}"/></strong> /
      총 이슈: <strong><c:out value="${totalCnt}"/></strong> 건
    </p>
  </div>

  <c:choose>
    <c:when test="${empty issues}">
      <div class="krds-alert success">
        검사 범위 안의 모든 항목이 정상입니다. 이슈가 없습니다.
      </div>
    </c:when>
    <c:otherwise>
      <table class="krds-table tbl-list">
        <thead>
          <tr>
            <th scope="col">심각도</th>
            <th scope="col">분류</th>
            <th scope="col">규정</th>
            <th scope="col">조항</th>
            <th scope="col">메시지</th>
          </tr>
        </thead>
        <tbody>
          <c:forEach var="i" items="${issues}">
            <tr>
              <%-- 심각도·분류는 내부 코드(ERROR/DUPLICATE_ITEM 등) — 화면엔 한국어 라벨만(2026-07-16) --%>
              <td class="sev-${i.severity}">
                <c:choose>
                  <c:when test="${i.severity == 'ERROR'}">오류</c:when>
                  <c:when test="${i.severity == 'WARN'}">경고</c:when>
                  <c:otherwise>정보</c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:choose>
                  <c:when test="${i.category == 'DUPLICATE_ITEM'}">조항 중복</c:when>
                  <c:when test="${i.category == 'EMPTY_CONTENT'}">본문 없음</c:when>
                  <c:when test="${i.category == 'DATE_INVALID'}">날짜 모순</c:when>
                  <c:when test="${i.category == 'TREE_INCONSISTENT'}">조항 구조 이상</c:when>
                  <c:when test="${i.category == 'PROV_MISSING'}">본문 누락</c:when>
                  <c:otherwise>기타</c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:if test="${not empty i.promNo}">
                  <a href="<c:url value='/rlms/prom/selectPromDetail.do'/>?promNo=${i.promNo}">
                    <c:out value="${i.promTitle}"/> (#${i.promNo})
                  </a>
                </c:if>
              </td>
              <td><c:out value="${i.itemLabel}"/></td>
              <td><c:out value="${i.message}"/></td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </c:otherwise>
  </c:choose>

  <div class="btn-area">
    <a href="<c:url value='/rlms/prom/selectPromList.do'/>" class="krds-btn medium">규정 목록으로</a>
  </div>
</lay:layout>
