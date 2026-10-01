<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/provHtmlCompare.jsp

  본문 비교 결과 화면. KRDS 디자인.
  - 색상 코딩(.diff-*) 유지
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">본문 비교</c:set>
<c:set var="pageHead">
  
  <style>
    .diff-added    { background-color: #e6ffe6; }
    .diff-removed  { background-color: #ffe6e6; text-decoration: line-through; }
    .diff-modified { background-color: #fff5cc; }
    .diff-unchanged{ color: #888; }
    table.diff td { vertical-align: top; padding: 6px; border: 1px solid #d1d3d8; }
    table.diff    { width: 100%; border-collapse: collapse; }
    table.diff th { background:#f0f3fa; padding:6px; border:1px solid #d1d3d8; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>본문 비교</h1>
  </div>

  <c:choose>
    <c:when test="${previous == null}">
      <div class="krds-alert info">비교할 이전 개정본이 없습니다.</div>
      <div class="btn-area">
        <a href="<c:url value='/rlms/prom/selectPromDetail.do'/>?promNo=<c:out value='${current.promNo}'/>"
           class="krds-btn medium">상세로 돌아가기</a>
      </div>
    </c:when>
    <c:otherwise>
      <table class="krds-table tbl-detail">
        <colgroup><col style="width:15%"/><col/></colgroup>
        <tbody>
          <tr>
            <th scope="row">이전</th>
            <td>
              <c:out value="${previous.title}"/>
              (<c:out value="${previous.number}"/>, <c:out value="${previous.promDate}"/>)
            </td>
          </tr>
          <tr>
            <th scope="row">현재</th>
            <td>
              <c:out value="${current.title}"/>
              (<c:out value="${current.number}"/>, <c:out value="${current.promDate}"/>)
            </td>
          </tr>
        </tbody>
      </table>

      <h2>조문 단위 비교</h2>
      <c:choose>
        <c:when test="${empty mainDiff}">
          <div class="krds-alert info">변경 없음</div>
        </c:when>
        <c:otherwise>
          <table class="krds-table diff">
            <thead>
              <tr><th style="width: 15%" scope="col">조항</th>
                  <th style="width: 40%" scope="col">이전</th>
                  <th style="width: 40%" scope="col">현재</th>
                  <th style="width: 5%"  scope="col">유형</th></tr>
            </thead>
            <tbody>
              <c:forEach var="d" items="${mainDiff}">
                <tr class="diff-${fn:toLowerCase(d.changeType)}">
                  <td><c:out value="${d.itemLabel}"/></td>
                  <td>${d.leftText}</td>
                  <td>${d.rightText}</td>
                  <td>
                    <c:choose>
                      <c:when test="${d.changeType == 'REMOVED'}">삭제</c:when>
                      <c:when test="${d.gaejungType == 'NEW'}">신설</c:when>
                      <c:when test="${d.gaejungType == 'MODIFY_ALL'}">전부개정</c:when>
                      <c:when test="${d.gaejungType == 'MODIFY_TITLE'}">제목개정</c:when>
                      <c:when test="${d.gaejungType == 'MODIFY_CONTENTS'}">본문개정</c:when>
                      <c:when test="${d.gaejungType == 'MOVE_ALL'}">조항이동</c:when>
                      <c:when test="${d.gaejungType == 'MOVE_TITLE_MODIFY_CONTENTS'}">이동·본문개정</c:when>
                      <c:when test="${d.gaejungType == 'MOVE_CONTENTS_MODIFY_TITLE'}">이동·제목개정</c:when>
                      <c:when test="${d.changeType == 'ADDED'}">추가</c:when>
                      <c:when test="${d.changeType == 'MODIFIED'}">변경</c:when>
                      <c:otherwise>동일</c:otherwise>
                    </c:choose>
                    <c:if test="${not empty d.moveFullItem}"><br><small style="color:#667">→ <c:out value="${d.moveItemLabel}"/></small></c:if>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>

      <h2>부칙 비교</h2>
      <c:choose>
        <c:when test="${empty bylawDiff}">
          <div class="krds-alert info">부칙 변경 없음</div>
        </c:when>
        <c:otherwise>
          <table class="krds-table diff">
            <thead>
              <tr><th style="width: 10%" scope="col">라인</th>
                  <th style="width: 40%" scope="col">이전</th>
                  <th style="width: 40%" scope="col">현재</th>
                  <th style="width: 10%" scope="col">유형</th></tr>
            </thead>
            <tbody>
              <c:forEach var="d" items="${bylawDiff}">
                <tr class="diff-${fn:toLowerCase(d.changeType)}">
                  <td><c:out value="${d.itemLabel}"/></td>
                  <td><c:out value="${d.leftText}"/></td>
                  <td><c:out value="${d.rightText}"/></td>
                  <td>
                    <c:choose>
                      <c:when test="${d.changeType == 'ADDED'}">추가</c:when>
                      <c:when test="${d.changeType == 'REMOVED'}">삭제</c:when>
                      <c:when test="${d.changeType == 'MODIFIED'}">변경</c:when>
                      <c:otherwise>동일</c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>

      <div class="btn-area">
        <a href="<c:url value='/rlms/prom/selectPromDetail.do'/>?promNo=<c:out value='${current.promNo}'/>"
           class="krds-btn medium">상세로 돌아가기</a>
      </div>
    </c:otherwise>
  </c:choose>
</lay:layout>
