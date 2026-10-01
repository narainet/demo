<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/lawquest/lawQuestView.jsp
  법령질의 상세. 등록/수정 폼과 동일한 전체폭(lq-ide) 레이아웃 — 헤더 바 + 전체폭 카드.
  질의/회신은 HTML 렌더(에디터 작성분) + 레거시 평문 안전 변환.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">법령질의 상세</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <style>
    .lq-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
    .lq-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
    .lq-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
    .lq-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
    .lq-head-actions { flex: 0 0 auto; display: flex; gap: 8px; align-items: center; }
    .lq-ide-detail { border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; padding: 24px; }
    .lq-ide-detail .krds-table { margin: 0; }
    .lq-section { margin-top: 18px; }
    .lq-section > .lq-label { display: block; margin-bottom: 6px; color: #1f3974; font-weight: 700; font-size: 14px; }
    .lq-con { white-space: pre-wrap; word-break: break-all; min-height: 60px; padding: 10px 12px; background: #f7f8fa; border: 1px solid #e6e8ec; border-radius: 4px; line-height: 1.6; }
    .lq-files a { display: inline-block; margin-right: 12px; }
    @media (max-width: 768px) {
      .lq-ide-head { align-items: flex-start; flex-direction: column; }
      .lq-head-actions { flex-wrap: wrap; }
      .lq-ide-detail { padding: 18px; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="lq-ide-page">
    <div class="lq-ide-head">
      <div>
        <span class="lq-ide-kicker">법령질의 / 법률자문</span>
        <h1>법령질의 상세</h1>
      </div>
      <div class="lq-head-actions">
        <c:choose>
          <c:when test="${front}">
            <a href="<c:url value='/rlms/lawquest/lawQuestFrontList.do'/>" class="krds-btn medium">목록</a>
          </c:when>
          <c:otherwise>
            <a href="<c:url value='/rlms/lawquest/lawQuestList.do'/>" class="krds-btn medium">목록</a>
            <a href="<c:url value='/rlms/lawquest/lawQuestUpdate.do'/>?no=${info.no}" class="krds-btn primary medium">수정·회신</a>
            <button type="button" id="btnDel" class="krds-btn danger medium">삭제</button>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

    <div class="lq-ide-detail">
      <table class="krds-table tbl-view">
        <colgroup><col style="width:14%"><col style="width:36%"><col style="width:14%"><col style="width:36%"></colgroup>
        <tbody>
          <tr>
            <th scope="row">제목</th>
            <td colspan="3"><c:out value="${info.subject}"/></td>
          </tr>
          <tr>
            <th scope="row">작성연도</th><td><c:out value="${info.year}"/></td>
            <th scope="row">자문유형</th><td><c:out value="${info.type}"/></td>
          </tr>
          <tr>
            <th scope="row">의뢰부서</th><td><c:out value="${info.sosok}"/></td>
            <th scope="row">자문기관</th><td><c:out value="${info.gigwan}"/></td>
          </tr>
          <tr>
            <th scope="row">변호사</th><td><c:out value="${info.lawer}"/></td>
            <th scope="row">자문금액</th><td><fmt:formatNumber value="${info.gumaek}" type="number"/> 원</td>
          </tr>
          <tr>
            <th scope="row">의뢰일자</th><td><c:out value="${info.ilja1}"/></td>
            <th scope="row">회신일자</th><td><c:out value="${info.ilja2}"/></td>
          </tr>
          <tr>
            <%-- 예산 = 금액. 숫자면 자문금액과 같은 서식(천단위 콤마 + 원), 레거시 텍스트 값은 원문 그대로.
                 숫자 판정은 VO(bugetNumeric)가 담당 — JSTL 에 숫자 판별식이 없어 EL 로 흉내내면 오판한다. --%>
            <th scope="row">예산</th>
            <td><c:choose>
                  <c:when test="${info.bugetNumeric}"><fmt:formatNumber value="${info.buget}" type="number"/> 원</c:when>
                  <c:otherwise><c:out value="${info.buget}"/></c:otherwise>
                </c:choose></td>
            <th scope="row">작성자</th><td><c:out value="${info.name}"/> <span class="favor-muted">(<c:out value="${info.writeday}"/> · 조회 ${info.readnum})</span></td>
          </tr>
        </tbody>
      </table>

      <div class="lq-section">
        <span class="lq-label">질의내용</span>
        <div class="lq-con" id="lqQuest"><c:out value="${info.questCon}"/></div>
      </div>

      <div class="lq-section">
        <span class="lq-label">회신내용</span>
        <div class="lq-con" id="lqRespo"><c:out value="${info.respoCon}"/></div>
      </div>

      <div class="lq-section">
        <span class="lq-label">첨부파일</span>
        <div class="lq-files">
          <c:choose>
            <c:when test="${empty attachList}"><span class="favor-muted">첨부 없음</span></c:when>
            <c:otherwise>
              <c:forEach var="a" items="${attachList}">
                <a href="<c:url value='/rlms/related/attachDownload.do'/>?attNo=${a.attNo}">&#128206; <c:out value="${a.name}"/></a>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>
  </div>

  <script>
    // 질의/회신 = HTML 렌더(에디터 작성분) + 레거시 평문은 escape+줄바꿈 복원
    (function() {
      function lqPbToHtml(s) {
        s = s || '';
        if (!/<[a-z!\/][\s\S]*>/i.test(s)) {
          s = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
               .replace(/\r\n|\r/g, '\n').replace(/^\n+|\n+$/g, '').replace(/\n/g, '<br>');
        }
        return s;
      }
      ['lqQuest','lqRespo'].forEach(function(id) {
        var d = document.getElementById(id);
        if (d) { d.innerHTML = lqPbToHtml(d.textContent); d.style.whiteSpace = 'normal'; }
      });
    })();
  </script>

  <c:if test="${not front}">
    <form id="delForm" method="post" action="<c:url value='/rlms/lawquest/lawQuestDeleteDo.do'/>">
      <input type="hidden" name="no" value="${info.no}"/>
    </form>
    <script>
      $('#btnDel').on('click', function() {
        if (confirm('이 법령질의를 삭제하시겠습니까? (첨부 포함)')) document.getElementById('delForm').submit();
      });
    </script>
  </c:if>
</lay:layout>
