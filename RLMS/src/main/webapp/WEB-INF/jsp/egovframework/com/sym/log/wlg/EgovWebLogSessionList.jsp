<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/sym/log/wlg/EgovWebLogSessionList.jsp

  접속 세션 현황 — 웹로그(COMTNWEBLOG)를 SESN_ID 로 묶어 '한 번의 접속'을 한 줄로. KRDS 디자인.
  접속로그는 로그아웃 버튼을 눌러야 종료가 남지만 실제로는 대부분 창을 닫고 나가므로,
  마지막 요청 시각을 종료로 보는 이 화면이 체류 파악에 정확하다.
  화면명은 메뉴명(90090500 접속 세션 현황)과 같아야 한다(tools/namecheck.ps1).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">접속 세션 현황</c:set>
<lay:layout title="${pageTitle}">
  <div class="page-header">
    <h1>접속 세션 현황</h1>
    <p class="page-desc">한 번의 접속을 한 줄로 봅니다. 로그아웃 버튼을 누르지 않고 창을 닫아도 마지막 활동 시각까지 남습니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/sym/log/wlg/SelectWebLogSessionList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <div class="form-group inline">
      <label class="form-label" for="searchBgnDe">기간</label>
      <div class="form-conts">
        <input type="date" id="searchBgnDe" name="searchBgnDe" class="krds-input" value="<c:out value='${searchVO.searchBgnDe}'/>"/>
        <span>~</span>
        <input type="date" name="searchEndDe" class="krds-input" value="<c:out value='${searchVO.searchEndDe}'/>"/>
      </div>
      <label class="form-label" for="searchDviceSe">기기</label>
      <div class="form-conts">
        <select id="searchDviceSe" name="searchDviceSe" class="krds-select">
          <option value="" <c:if test="${empty searchVO.searchDviceSe}">selected</c:if>>전체</option>
          <option value="PC"     <c:if test="${searchVO.searchDviceSe eq 'PC'}">selected</c:if>>PC</option>
          <option value="MOBILE" <c:if test="${searchVO.searchDviceSe eq 'MOBILE'}">selected</c:if>>모바일</option>
          <option value="TABLET" <c:if test="${searchVO.searchDviceSe eq 'TABLET'}">selected</c:if>>태블릿</option>
          <option value="BOT"    <c:if test="${searchVO.searchDviceSe eq 'BOT'}">selected</c:if>>봇</option>
          <option value="ETC"    <c:if test="${searchVO.searchDviceSe eq 'ETC'}">selected</c:if>>기타</option>
        </select>
      </div>
      <label class="form-label" for="searchRqster">사용자</label>
      <div class="form-conts">
        <input type="text" id="searchRqster" name="searchRqster" class="krds-input"
               value="<c:out value='${searchVO.searchRqster}'/>" placeholder="이름 또는 ID"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
      <button type="button" class="krds-btn medium" onclick="fnExcel();">엑셀 다운로드</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <colgroup>
      <col style="width:11%"><col style="width:14%"><col style="width:14%"><col style="width:7%">
      <col style="width:6%"><col style="width:6%"><col style="width:7%"><col style="width:9%"><col>
    </colgroup>
    <thead>
      <tr>
        <th scope="col">사용자</th>
        <th scope="col">접속 시작</th>
        <th scope="col">마지막 활동</th>
        <th scope="col">체류</th>
        <th scope="col">요청</th>
        <th scope="col">화면</th>
        <th scope="col">기기</th>
        <th scope="col">브라우저</th>
        <th scope="col">마지막 화면</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="9" class="empty-row">접속 세션이 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}">
            <tr>
              <td>
                <c:choose>
                  <c:when test="${empty row.rqsterNm}"><span class="rlms-muted">(비로그인)</span></c:when>
                  <c:otherwise><c:out value="${row.rqsterNm}"/></c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.bgnDt}"/></td>
              <td><c:out value="${fn:substring(row.endDt, 11, 19)}"/></td>
              <td>
                <%-- EL 의 나눗셈은 실수라 '2.0시간' 이 되므로, 60 의 배수만 남겨 정수로 출력한다 --%>
                <c:choose>
                  <c:when test="${row.durMin >= 60}">
                    <fmt:formatNumber value="${(row.durMin - row.durMin % 60) / 60}" pattern="#"/>시간
                    <c:if test="${row.durMin % 60 > 0}"><c:out value="${row.durMin % 60}"/>분</c:if>
                  </c:when>
                  <c:when test="${row.durMin > 0}"><c:out value="${row.durMin}"/>분</c:when>
                  <c:otherwise><span class="rlms-muted">1분 미만</span></c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.reqCnt}"/></td>
              <td><c:out value="${row.pageCnt}"/></td>
              <td>
                <c:choose>
                  <c:when test="${row.dviceSe eq 'PC'}">PC</c:when>
                  <c:when test="${row.dviceSe eq 'MOBILE'}">모바일</c:when>
                  <c:when test="${row.dviceSe eq 'TABLET'}">태블릿</c:when>
                  <c:when test="${row.dviceSe eq 'BOT'}">봇</c:when>
                  <c:when test="${row.dviceSe eq 'ETC'}">기타</c:when>
                  <c:otherwise><span class="rlms-muted">-</span></c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${empty row.browserNm ? '-' : row.browserNm}"/></td>
              <td class="al"><c:out value="${row.lastUrl}"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <div class="krds-pagination">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }
    function fnExcel() {
      var f = document.searchForm;
      var q = '?searchBgnDe=' + encodeURIComponent(f.searchBgnDe.value)
            + '&searchEndDe=' + encodeURIComponent(f.searchEndDe.value)
            + '&searchDviceSe=' + encodeURIComponent(f.searchDviceSe.value)
            + '&searchRqster=' + encodeURIComponent(f.searchRqster.value);
      location.href = '<c:url value="/sym/log/wlg/SelectWebLogSessionExcel.do"/>' + q;
    }
  </script>
</lay:layout>
