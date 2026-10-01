<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/requser/view.jsp
  나의 소송의뢰 상세(사용자 front, 읽기전용) — LAW_MODULE_DESIGN.md §7.8.
  본인 신청분만(컨트롤러 소유 검증). 상태·반려사유·경과·첨부·보조자 표시. 신청 상태면 수정 버튼.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">나의 소송의뢰 상세</c:set>
<c:set var="pageHead">
  
  <style>
    .law-view-sec { margin: 22px 0 8px; padding-bottom: 6px; border-bottom: 2px solid #222; font-size: 16px; font-weight: 700; }
    .law-dl { display:grid; grid-template-columns: 130px 1fr; gap:1px; background:#e5e7eb; border:1px solid #e5e7eb; }
    .law-dl dt { background:#f7f8fa; padding:9px 12px; font-size:14px; color:#333; margin:0; }
    /* pre-wrap 을 dd 전역에 걸면 JSP 들여쓰기 개행까지 렌더돼 상태 칸이 세로로 부푼다(2026-07-30 조정)
       — 여러 줄 보존이 필요한 칸(반려 사유)만 .pre 로 지정 */
    .law-dl dd { background:#fff; padding:9px 12px; font-size:14px; margin:0; }
    .law-dl dd.pre { white-space:pre-wrap; }
    .law-sub-table { width:100%; border-collapse:collapse; margin-top:6px; }
    .law-sub-table th, .law-sub-table td { border:1px solid #ddd; padding:6px 8px; font-size:13px; text-align:left; }
    .law-sub-table th { background:#f7f8fa; }
    .law-file-link { display:block; font-size:13px; }
    .law-badge { display:inline-block; padding:3px 12px; border-radius:12px; font-size:14px; }  /* 목록(list.jsp)과 동일 스케일 */
    .law-badge.req  { background:#eef2ff; color:#3651d4; }
    .law-badge.appr { background:#e6f4ea; color:#1a7f37; }
    .law-badge.rjct { background:#fdecec; color:#c5303a; }
    .law-btn-bar { margin-top:24px; display:flex; gap:8px; justify-content:center; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>나의 소송의뢰 상세</h1>
    <p class="page-desc">신청한 소송의뢰의 내용과 진행 상태입니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <%-- 진행 단계 (KRDS 단계 표시) — 신청(S001)=검토 대기 2단계, 승인/반려=처리 완료 3단계 --%>
  <c:set var="reqStepCur" value="${req.statusCd eq 'S002' or req.statusCd eq 'S003' ? 3 : 2}"/>
  <c:set var="reqStepStatus" value="${req.statusCd}"/>
  <%@ include file="reqStep.jspf" %>

  <div class="law-view-sec">기본 정보</div>
  <dl class="law-dl">
    <dt>상태</dt>
    <dd>
      <c:choose>
        <c:when test="${req.statusCd eq 'S002'}"><span class="law-badge appr">승인</span></c:when>
        <c:when test="${req.statusCd eq 'S003'}"><span class="law-badge rjct">반려</span></c:when>
        <c:otherwise><span class="law-badge req">신청</span></c:otherwise>
      </c:choose>
    </dd>
    <dt>사건명</dt>
    <dd><c:out value="${req.reqTitl}" default="-"/></dd>
    <dt>의뢰일자</dt>
    <dd><c:if test="${not empty req.reqDt and fn:length(req.reqDt) ge 8}">${fn:substring(req.reqDt,0,4)}-${fn:substring(req.reqDt,4,6)}-${fn:substring(req.reqDt,6,8)}</c:if></dd>
    <c:if test="${req.statusCd eq 'S003'}">
      <dt>반려 사유</dt>
      <dd class="pre"><c:out value="${req.returnRsn}" default="-"/></dd>
    </c:if>
    <c:if test="${req.statusCd eq 'S002' and not empty req.caseNo}">
      <dt>등록된 사건</dt>
      <dd><c:out value="${req.caseNo}"/></dd>
    </c:if>
  </dl>

  <div class="law-view-sec">사실관계</div>
  <div style="border:1px solid #e5e7eb; background:#fff; padding:12px; font-size:14px; white-space:pre-wrap; min-height:48px;"><c:out value="${req.reqCn}" default="(입력 없음)"/></div>

  <div class="law-view-sec">기타 자료</div>
  <c:choose>
    <c:when test="${not empty req.files}">
      <c:set var="encReq" value="${egovc:encryptSession(req.atchFileId, pageContext.session.id)}"/>
      <c:forEach var="f" items="${req.files}">
        <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encReq}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a>
      </c:forEach>
    </c:when>
    <c:otherwise><span style="color:#888; font-size:13px;">첨부 없음</span></c:otherwise>
  </c:choose>

  <div class="law-view-sec">사건 경과 내역</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:210px;">기간</th><th>내용</th><th style="width:220px;">첨부</th></tr></thead>
    <tbody>
      <c:forEach var="h" items="${req.hists}">
        <tr>
          <td>
            <c:if test="${not empty h.staDt and fn:length(h.staDt) ge 8}">${fn:substring(h.staDt,0,4)}-${fn:substring(h.staDt,4,6)}-${fn:substring(h.staDt,6,8)}</c:if>
            <c:if test="${not empty h.endDt and fn:length(h.endDt) ge 8}"> ~ ${fn:substring(h.endDt,0,4)}-${fn:substring(h.endDt,4,6)}-${fn:substring(h.endDt,6,8)}</c:if>
          </td>
          <td style="white-space:pre-wrap;"><c:out value="${h.histCn}"/></td>
          <td>
            <c:if test="${not empty h.files}">
              <c:set var="encH" value="${egovc:encryptSession(h.atchFileId, pageContext.session.id)}"/>
              <c:forEach var="hf" items="${h.files}">
                <a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encH}&amp;fileSn=${hf.fileSn}"><c:out value="${hf.orignlFileNm}"/></a>
              </c:forEach>
            </c:if>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty req.hists}"><tr><td colspan="3" style="text-align:center; color:#888;">경과 내역 없음</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-view-sec">소송수행 보조자</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:160px;">부서</th><th style="width:120px;">담당자</th><th>전화</th><th>휴대폰</th><th>이메일</th></tr></thead>
    <tbody>
      <c:forEach var="hp" items="${req.helpers}">
        <tr>
          <td><c:out value="${hp.deptNm}"/></td>
          <td><c:out value="${hp.helperNm}"/></td>
          <td><c:out value="${hp.tel}"/></td>
          <td><c:out value="${hp.mobile}"/></td>
          <td><c:out value="${hp.email}"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty req.helpers}"><tr><td colspan="5" style="text-align:center; color:#888;">보조자 없음</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-btn-bar">
    <c:if test="${req.statusCd eq 'S001'}">
      <a class="krds-btn primary large" href="<c:url value='/law/reqUser/regist.do'/>?reqId=${req.reqId}">수정</a>
    </c:if>
    <button type="button" class="krds-btn large" onclick="location.href='<c:url value="/law/reqUser/list.do"/>';">목록</button>
  </div>
</lay:layout>
