<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/promDiff.jsp

  신구대조 비교 결과 화면. KRDS 디자인.
  - 색상 코딩(.diff-*) 은 비교 의미를 보존하기 위해 유지
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">신구대조</c:set>
<c:set var="pageHead">
  
  <style>
    .diff-table { width: 100%; border-collapse: collapse; }
    .diff-table th, .diff-table td { border: 1px solid #d1d3d8; padding: 6px; vertical-align: top; }
    .diff-table th { background: #f0f3fa; }
    .diff-added    { background: #e6ffe6; }
    .diff-removed  { background: #ffe6e6; }
    .diff-modified { background: #fff7d6; }
    .diff-unchanged{ background: #fafafa; color: #888; }
    .diff-cell { width: 47%; white-space: pre-wrap; word-break: break-all; }
    .summary span { padding: 4px 10px; margin-right: 6px; border-radius: 4px; display:inline-block; }
    .summary .added    { background: #c6f0c6; }
    .summary .removed  { background: #f0c6c6; }
    .summary .modified { background: #f0e6a0; }
    .summary .unchanged{ background: #e0e0e0; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>신구대조 비교 결과</h1>
  </div>

  <section class="krds-card">
    <p>
      <strong>좌(이전)</strong> :
      <c:out value="${leftProm.title}"/>
      (회차 <c:out value="${leftProm.lawNo}"/>, 공포일 <c:out value="${leftProm.promDate}"/>)
    </p>
    <p>
      <strong>우(현행)</strong> :
      <c:out value="${rightProm.title}"/>
      (회차 <c:out value="${rightProm.lawNo}"/>, 공포일 <c:out value="${rightProm.promDate}"/>)
    </p>
  </section>

  <div class="summary" style="margin:14px 0;">
    <strong>요약:</strong>
    <span class="added">신규 <c:out value="${addedCnt}"/></span>
    <span class="removed">삭제 <c:out value="${removedCnt}"/></span>
    <span class="modified">수정 <c:out value="${modifiedCnt}"/></span>
    <span class="unchanged">변경없음 <c:out value="${unchangedCnt}"/></span>
    <span style="margin-left:14px;color:#667;font-size:13px;">— 변경된 조항만 표시</span>
  </div>

  <%-- 사용자 화면: 내부 키(조항) 컬럼 숨김 + 변경된 항목(신규/삭제/수정)만 출력. 변경없음은 요약에만 집계. --%>
  <c:set var="changedCnt" value="${addedCnt + removedCnt + modifiedCnt}"/>
  <table class="krds-table diff-table">
    <thead>
      <tr>
        <th class="diff-cell" scope="col">좌(이전)</th>
        <th class="diff-cell" scope="col">우(현행)</th>
        <th scope="col">유형</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty diffList or changedCnt == 0}">
          <tr><td colspan="3" class="empty-row" style="text-align:center;color:#888;padding:18px;">변경된 조항이 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="d" items="${diffList}">
            <c:if test="${d.changeType != 'UNCHANGED'}">
            <tr class="diff-${fn:toLowerCase(d.changeType)}">
              <td class="diff-cell"><c:out value="${d.leftText}"/></td>
              <td class="diff-cell"><c:out value="${d.rightText}"/></td>
              <td>
                <c:choose>
                  <c:when test="${d.changeType == 'ADDED'}">신규</c:when>
                  <c:when test="${d.changeType == 'REMOVED'}">삭제</c:when>
                  <c:when test="${d.changeType == 'MODIFIED'}">수정</c:when>
                  <c:otherwise>변경</c:otherwise>
                </c:choose>
              </td>
            </tr>
            </c:if>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <%-- ── 별표/별지서식 대조 (2026-07-16) — 좌/우 누적 뷰 SITEM 매칭. 양쪽 다 별표가 없으면 섹션 생략 ── --%>
  <c:if test="${not empty docuDiffList}">
    <c:set var="docuChangedCnt" value="${docuAddedCnt + docuRemovedCnt + docuModifiedCnt}"/>
    <h2 style="margin:26px 0 4px;font-size:17px;">별표 / 별지서식 대조</h2>
    <div class="summary" style="margin:8px 0 14px;">
      <strong>요약:</strong>
      <span class="added">신규 <c:out value="${docuAddedCnt}"/></span>
      <span class="removed">삭제 <c:out value="${docuRemovedCnt}"/></span>
      <span class="modified">수정 <c:out value="${docuModifiedCnt}"/></span>
      <span class="unchanged">변경없음 <c:out value="${docuUnchangedCnt}"/></span>
      <span style="margin-left:14px;color:#667;font-size:13px;">— 변경된 별표만 표시</span>
    </div>
    <table class="krds-table diff-table">
      <thead>
        <tr>
          <th class="diff-cell" scope="col">좌(이전)</th>
          <th class="diff-cell" scope="col">우(현행)</th>
          <th scope="col">유형</th>
        </tr>
      </thead>
      <tbody>
        <c:choose>
          <c:when test="${docuChangedCnt == 0}">
            <tr><td colspan="3" class="empty-row" style="text-align:center;color:#888;padding:18px;">변경된 별표/별지서식이 없습니다.</td></tr>
          </c:when>
          <c:otherwise>
            <c:forEach var="d" items="${docuDiffList}">
              <c:if test="${d.changeType != 'UNCHANGED'}">
              <tr class="diff-${fn:toLowerCase(d.changeType)}">
                <td class="diff-cell"><c:out value="${d.leftText}"/></td>
                <td class="diff-cell"><c:out value="${d.rightText}"/></td>
                <td>
                  <c:choose>
                    <c:when test="${d.changeType == 'ADDED'}">신규</c:when>
                    <c:when test="${d.changeType == 'REMOVED'}">삭제</c:when>
                    <c:when test="${d.changeType == 'MODIFIED'}">수정</c:when>
                    <c:otherwise>변경</c:otherwise>
                  </c:choose>
                </td>
              </tr>
              </c:if>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </tbody>
    </table>
  </c:if>

  <div class="btn-area">
    <%-- 인페이지 iframe 모달에서 열린 경우 부모 창으로 이동(target=_top). 직접 진입 시엔 일반 이동과 동일. --%>
    <a href="<c:url value='/rlms/fulltext/comparisonList.do'/>?lawId=${leftProm.lawId}"
       target="_top" class="krds-btn medium">다른 개정본 선택</a>
  </div>
</lay:layout>
