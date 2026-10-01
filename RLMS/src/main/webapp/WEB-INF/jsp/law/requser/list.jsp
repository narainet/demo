<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/requser/list.jsp
  나의 소송의뢰(사용자 front) — LAW_MODULE_DESIGN.md §7.8.
  본인 신청분만(서버측 REG_USER_ID 필터). 열: 사건명/의뢰일자/상태/반려사유. 신청 상태에서만 수정·삭제.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">나의 소송의뢰</c:set>
<c:set var="pageHead">
  
  <style>
    /* 폰트 스케일 = 표준 목록(메모관리 등 krds-table) 기준(2026-07-30) — 표 본문 15.8px 옆에서
       12px 뱃지·칩이 튀게 작아 14px(버튼 스케일)로 통일 */
    .law-badge { display:inline-block; padding:3px 12px; border-radius:12px; font-size:14px; white-space:nowrap; }
    .law-badge.req  { background:#eef2ff; color:#3651d4; }
    .law-badge.appr { background:#e6f4ea; color:#1a7f37; }
    .law-badge.rjct { background:#fdecec; color:#c5303a; }
    .law-list-head { display:flex; justify-content:space-between; align-items:center; margin:8px 0 12px; }
    .law-sub { color:#888; font-size:14px; }
    .krds-table .law-chip-btn { font-size:14px; padding:4px 12px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>나의 소송의뢰</h1>
    <p class="page-desc">내가 신청한 소송의뢰의 진행 상태를 확인합니다. 신청 상태에서는 수정·삭제할 수 있습니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <div class="law-list-head">
    <span class="law-total" style="margin:0;">총 <strong><c:out value="${fn:length(resultList)}"/></strong>건</span>
    <a class="krds-btn primary medium" href="<c:url value='/law/reqUser/regist.do'/>">소송의뢰 신청</a>
  </div>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:4%;">No</th>
        <th scope="col">사건명</th>
        <th scope="col" style="width:8%;">의뢰일자</th>
        <th scope="col" style="width:6%;">상태</th>
        <th scope="col">반려 사유</th>
        <th scope="col" style="width:10%;">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${resultList}" varStatus="st">
        <tr>
          <td><c:out value="${fn:length(resultList) - st.index}"/></td>
          <td><a href="<c:url value='/law/reqUser/view.do'/>?reqId=${row.reqId}"><c:out value="${row.reqTitl}" default="(제목 없음)"/></a></td>
          <td><c:if test="${not empty row.reqDt and fn:length(row.reqDt) ge 8}">${fn:substring(row.reqDt,0,4)}-${fn:substring(row.reqDt,4,6)}-${fn:substring(row.reqDt,6,8)}</c:if></td>
          <td>
            <c:choose>
              <c:when test="${row.statusCd eq 'S002'}"><span class="law-badge appr">승인</span></c:when>
              <c:when test="${row.statusCd eq 'S003'}"><span class="law-badge rjct">반려</span></c:when>
              <c:otherwise><span class="law-badge req">신청</span></c:otherwise>
            </c:choose>
          </td>
          <td style="white-space:pre-wrap;"><c:out value="${row.returnRsn}" default="-"/></td>
          <td>
            <c:choose>
              <c:when test="${row.statusCd eq 'S001'}">
                <a class="law-chip-btn" href="<c:url value='/law/reqUser/regist.do'/>?reqId=${row.reqId}">수정</a>
                <button type="button" class="law-chip-btn" onclick="fnDelete(${row.reqId});">삭제</button>
              </c:when>
              <c:otherwise><span class="law-sub">-</span></c:otherwise>
            </c:choose>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty resultList}">
        <tr><td colspan="6" style="text-align:center; padding:32px 0; color:#888;">신청한 소송의뢰가 없습니다.</td></tr>
      </c:if>
    </tbody>
  </table>

  <script>
  function fnDelete(reqId){
    if(!confirm('이 소송의뢰를 삭제할까요?')) return;
    var p = new URLSearchParams(); p.set('reqId', reqId);
    fetch('<c:url value="/law/reqUser/deleteJson.do"/>', { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'삭제 실패'); } })
      .catch(function(){ alert('삭제 요청 실패'); });
  }
  </script>
</lay:layout>
