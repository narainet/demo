<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/readduty/dutyStatus.jsp

  필수열람 현황 (2026-07-28) — 지정건 목록 + 지정건별 부서 집계/개인 매트릭스 (컴플라이언스 증빙).
  확인 2단계 분리 표시: 열람(뷰어 자동 기록) / 숙지(버튼 — 최종 증빙). 엑셀 = HTML→.xls 관행.
  진입 = 통계 메뉴 45050000 (ADMIN/EDITOR/APPROVER).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">필수열람 현황</c:set>
<c:set var="pageHead">
  
  <style>
    .rds-rate { display:flex; align-items:center; gap:8px; min-width:130px; }
    .rds-bar { flex:1; height:8px; background:#e9edf5; border-radius:4px; overflow:hidden; }
    .rds-bar i { display:block; height:100%; background:#1f3974; border-radius:4px; }
    .rds-bar i.full { background:#12b76a; }
    .rds-num { font-size:12px; color:#475569; white-space:nowrap; }
    .rds-badge { display:inline-block; font-size:12px; font-weight:600; padding:2px 8px; border-radius:10px; white-space:nowrap; }
    .rds-badge.none { background:#f1f5f9; color:#64748b; }
    .rds-badge.read { background:#eef4fe; color:#1f3974; }
    .rds-badge.conf { background:#ecfdf3; color:#067647; }
    .rds-badge.over { background:#fef3f2; color:#b42318; }
    .rds-detail { margin-top:26px; }
    .rds-detail-head { display:flex; align-items:baseline; justify-content:space-between; gap:10px; margin-bottom:8px; }
    .rds-detail-head h2 { margin:0; font-size:17px; color:#1f3974; }
    .rds-summary { font-size:13px; color:#475569; margin:0 0 12px; }
    .rds-2col { display:grid; grid-template-columns:minmax(260px, 1fr) 2fr; gap:20px; align-items:start; }
    @media (max-width: 1100px) { .rds-2col { grid-template-columns:1fr; } }
    .rds-sel { background:#f4f7ff; }
    .rds-muted { color:#94a3b8; }
    .rds-btn { font-size:12px; padding:3px 10px; border-radius:6px; border:1px solid #c2cee0;
               background:#fff; color:#1f3974; cursor:pointer; white-space:nowrap; text-decoration:none; display:inline-block; }
    .rds-btn:hover { background:#eef4fe; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>필수열람 현황</h1>
    <p class="page-desc">개정 승인 시 지정한 필수 열람 의무의 열람/숙지 현황을 확인합니다. (열람=본문 열람 자동 기록, 숙지=대상자의 [숙지 확인] 클릭 — 최종 증빙)</p>
  </div>

  <form id="searchForm" action="<c:url value='/rlms/readduty/dutyStatus.do'/>" method="get" class="krds-form search-form">
    <div class="form-group inline">
      <label class="form-label" for="keyword">규정명</label>
      <div class="form-conts">
        <input type="text" id="keyword" name="keyword" class="krds-input" value="<c:out value='${keyword}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${fn:length(dutyList)}" default="0"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">규정명</th>
        <th scope="col">개정일</th>
        <th scope="col">대상</th>
        <th scope="col">기한</th>
        <th scope="col">지정</th>
        <th scope="col">대상</th>
        <th scope="col">열람</th>
        <th scope="col">숙지</th>
        <th scope="col">숙지율</th>
        <th scope="col">상세</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty dutyList}">
          <tr><td colspan="10" class="empty-row">지정된 필수 열람이 없습니다. (작업승인관리의 승인완료 행 [열람지정] 버튼으로 지정)</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="d" items="${dutyList}">
            <tr class="${d.dutyNo eq dutySummary.dutyNo ? 'rds-sel' : ''}">
              <td style="text-align:left;">
                <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${d.promNo}" target="_blank"
                   title="본문 새 창"><c:out value="${d.title}"/></a>
              </td>
              <td><c:out value="${d.promDate}"/></td>
              <td><c:choose><c:when test="${d.allYn eq 'Y'}">전사</c:when><c:otherwise>부서/개인</c:otherwise></c:choose></td>
              <td>
                <c:choose>
                  <c:when test="${empty d.dueDt}"><span class="rds-muted">무기한</span></c:when>
                  <c:when test="${d.dday lt 0}"><span class="rds-badge over" title="기한 경과">D+${-d.dday}</span></c:when>
                  <c:otherwise><c:out value="${d.dueDt}"/> (D-${d.dday eq 0 ? 'DAY' : d.dday})</c:otherwise>
                </c:choose>
              </td>
              <td title="<c:out value='${d.insNm}'/>"><c:out value="${d.insDt}"/></td>
              <td><fmt:formatNumber value="${d.tgtCnt}"/></td>
              <td><fmt:formatNumber value="${d.readCnt}"/></td>
              <td><fmt:formatNumber value="${d.confCnt}"/></td>
              <td>
                <div class="rds-rate">
                  <c:set var="rate" value="${d.tgtCnt gt 0 ? (d.confCnt * 100 / d.tgtCnt) : 0}"/>
                  <span class="rds-bar"><i class="${rate ge 100 ? 'full' : ''}" style="width:${rate gt 100 ? 100 : rate}%"></i></span>
                  <span class="rds-num"><fmt:formatNumber value="${rate}" maxFractionDigits="0"/>%</span>
                </div>
              </td>
              <td>
                <a class="rds-btn" href="<c:url value='/rlms/readduty/dutyStatus.do'/>?dutyNo=${d.dutyNo}<c:if test='${not empty keyword}'>&amp;keyword=<c:out value="${keyword}"/></c:if>">상세</a>
              </td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <c:if test="${not empty dutySummary}">
  <div class="rds-detail">
    <div class="rds-detail-head">
      <h2><c:out value="${dutySummary.title}"/> — 열람/숙지 상세</h2>
      <a class="rds-btn" href="<c:url value='/rlms/readduty/dutyStatusExcel.do'/>?dutyNo=${dutySummary.dutyNo}">엑셀 다운로드</a>
    </div>
    <p class="rds-summary">
      개정일 <c:out value="${dutySummary.promDate}"/> ·
      대상 <c:choose><c:when test="${dutySummary.allYn eq 'Y'}">전사(전 직원)</c:when><c:otherwise>부서/개인 지정</c:otherwise></c:choose> ·
      기한 <c:choose>
            <c:when test="${empty dutySummary.dueDt}">무기한</c:when>
            <c:when test="${dutySummary.dday lt 0}"><span class="rds-badge over">경과 D+${-dutySummary.dday}</span></c:when>
            <c:otherwise><c:out value="${dutySummary.dueDt}"/> (D-${dutySummary.dday eq 0 ? 'DAY' : dutySummary.dday})</c:otherwise>
          </c:choose> ·
      지정 <c:out value="${dutySummary.insNm}"/> (<c:out value="${dutySummary.insDt}"/>)
    </p>

    <div class="rds-2col">
      <div>
        <h3 style="font-size:14px;color:#1f3974;margin:0 0 6px;">부서별 집계</h3>
        <table class="krds-table tbl-list">
          <thead><tr><th scope="col">부서</th><th scope="col">대상</th><th scope="col">열람</th><th scope="col">숙지</th><th scope="col">숙지율</th></tr></thead>
          <tbody>
            <c:forEach var="g" items="${deptSummary}">
              <tr>
                <td style="text-align:left;"><c:out value="${g.orgnztNm}"/></td>
                <td><fmt:formatNumber value="${g.tgtCnt}"/></td>
                <td><fmt:formatNumber value="${g.readCnt}"/></td>
                <td><fmt:formatNumber value="${g.confCnt}"/></td>
                <td><fmt:formatNumber value="${g.tgtCnt gt 0 ? (g.confCnt * 100 / g.tgtCnt) : 0}" maxFractionDigits="0"/>%</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <div>
        <h3 style="font-size:14px;color:#1f3974;margin:0 0 6px;">개인별 상세</h3>
        <table class="krds-table tbl-list">
          <thead><tr><th scope="col">부서</th><th scope="col">이름</th><th scope="col">아이디</th><th scope="col">열람일시</th><th scope="col">숙지일시</th><th scope="col">상태</th></tr></thead>
          <tbody>
            <c:forEach var="u" items="${userMatrix}">
              <tr>
                <td style="text-align:left;"><c:out value="${u.orgnztNm}"/></td>
                <td><c:out value="${u.userNm}"/></td>
                <td><c:out value="${u.userId}"/></td>
                <td><c:out value="${u.readDtFmt}"/><c:if test="${empty u.readDt}"><span class="rds-muted">-</span></c:if></td>
                <td><c:out value="${u.confDtFmt}"/><c:if test="${empty u.confDt}"><span class="rds-muted">-</span></c:if></td>
                <td>
                  <c:choose>
                    <c:when test="${not empty u.confDt}"><span class="rds-badge conf">숙지 완료</span></c:when>
                    <c:when test="${not empty u.readDt}"><span class="rds-badge read">열람(숙지 전)</span></c:when>
                    <c:otherwise><span class="rds-badge none">미열람</span></c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </div>
  </div>
  </c:if>
</lay:layout>
