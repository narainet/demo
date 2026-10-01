<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/lawquest/lawQuestAdminList.jsp
  법령질의 답변권한자(레지스트리) 관리 — TB_LAWQUEST_ADMIN. ROLE_ADMIN 전용.
  ★회원 연동: 회원(COMVNUSERMASTER)을 검색·선택해 USER_ID 저장(ADMIN_SABUN=USER_ID).
  여기 등록된 회원만 회신(respoCon) 작성 가능(ROLE_ADMIN 은 bypass).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">법령질의 답변권한자 관리</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>법령질의 답변권한자 관리</h1>
    <p class="page-desc">회원(사용자)을 검색해 답변권한자로 지정합니다. 지정된 회원만 법령질의 <strong>회신</strong>을 작성할 수 있습니다. (전체관리자는 항상 가능)</p>
  </div>

  <div class="list-top">
    <p class="list-total">총 <strong>${fn:length(adminList)}</strong> 명</p>
    <a href="<c:url value='/rlms/lawquest/lawQuestList.do'/>" class="krds-btn medium">법령질의 목록</a>
  </div>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col" style="width:24%">사용자 ID</th>
        <th scope="col">성명</th>
        <th scope="col">부서</th>
        <th scope="col" style="width:12%">삭제</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty adminList}">
          <tr><td colspan="4" class="empty-row">등록된 답변권한자가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="a" items="${adminList}">
            <tr>
              <td><c:out value="${a.sabun}"/></td>
              <td class="al">
                <c:out value="${a.name}"/>
                <c:if test="${empty a.userNm}"><span class="favor-muted" style="font-size:.85em">(회원정보 미연동)</span></c:if>
              </td>
              <td><c:out value="${a.orgnztNm}"/></td>
              <td>
                <button type="button" class="krds-btn danger small"
                        onclick="fnDelAdmin('<c:out value="${a.sabun}"/>')">삭제</button>
              </td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <div class="page-header" style="margin-top:24px">
    <h2>답변권한자 추가</h2>
    <p class="page-desc">이름 또는 아이디로 회원을 검색해 [지정]하세요.</p>
  </div>

  <div class="krds-form">
    <div style="display:flex; gap:8px; align-items:center; margin-bottom:12px;">
      <input type="text" id="memKw" class="krds-input" style="max-width:280px" placeholder="이름 또는 아이디"/>
      <button type="button" class="krds-btn primary medium" id="memSearchBtn">회원 검색</button>
    </div>
    <table class="krds-table tbl-list" id="memTbl" style="display:none">
      <thead>
        <tr>
          <th scope="col">이름</th>
          <th scope="col">아이디</th>
          <th scope="col">부서</th>
          <th scope="col" style="width:10%">구분</th>
          <th scope="col" style="width:12%">지정</th>
        </tr>
      </thead>
      <tbody id="memBody"></tbody>
    </table>
    <p id="memEmpty" class="favor-muted" style="display:none">검색 결과가 없습니다.</p>
  </div>

  <form id="addForm" method="post" action="<c:url value='/rlms/lawquest/lawQuestAdminInsertDo.do'/>">
    <input type="hidden" name="sabun" id="addSabun"/>
    <input type="hidden" name="name" id="addName"/>
  </form>
  <form id="delForm" method="post" action="<c:url value='/rlms/lawquest/lawQuestAdminDeleteDo.do'/>">
    <input type="hidden" name="sabun" id="delSabun"/>
  </form>

  <script>
    var LQ_USER_SEARCH = '<c:url value="/rlms/lawquest/lawQuestUserSearch.do"/>';
    function lqEsc(s) { return (s == null ? '' : String(s)).replace(/[&<>"']/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }

    function fnDelAdmin(id) {
      if (!confirm('답변권한자(' + id + ')를 삭제하시겠습니까?')) return;
      document.getElementById('delSabun').value = id;
      document.getElementById('delForm').submit();
    }

    function fnSearchMem() {
      var kw = $('#memKw').val().trim();
      if (!kw) { alert('검색어(이름 또는 아이디)를 입력하세요.'); return; }
      $.getJSON(LQ_USER_SEARCH, { kw: kw }).done(function(list) {
        var $b = $('#memBody').empty();
        if (!list || !list.length) { $('#memTbl').hide(); $('#memEmpty').show(); return; }
        $('#memEmpty').hide(); $('#memTbl').show();
        list.forEach(function(u) {
          var se = (u.userSe === 'USR') ? '고정' : (u.userSe === 'GNR') ? '일반' : '기타';
          var act = (u.already > 0)
            ? '<span class="favor-muted">등록됨</span>'
            : '<button type="button" class="krds-btn primary small lq-add" data-id="' + lqEsc(u.userId) + '" data-nm="' + lqEsc(u.userNm) + '">지정</button>';
          $b.append('<tr><td class="al">' + lqEsc(u.userNm) + '</td><td>' + lqEsc(u.userId)
            + '</td><td>' + lqEsc(u.orgnztNm || '') + '</td><td>' + se + '</td><td>' + act + '</td></tr>');
        });
      }).fail(function() { alert('회원 검색 중 오류가 발생했습니다.'); });
    }

    $('#memSearchBtn').on('click', fnSearchMem);
    $('#memKw').on('keydown', function(e) { if (e.keyCode === 13) { e.preventDefault(); fnSearchMem(); } });
    $('#memBody').on('click', '.lq-add', function() {
      var id = $(this).attr('data-id'), nm = $(this).attr('data-nm');
      if (!confirm(nm + '(' + id + ') 님을 답변권한자로 지정하시겠습니까?')) return;
      document.getElementById('addSabun').value = id;
      document.getElementById('addName').value = nm;
      document.getElementById('addForm').submit();
    });
  </script>
</lay:layout>
