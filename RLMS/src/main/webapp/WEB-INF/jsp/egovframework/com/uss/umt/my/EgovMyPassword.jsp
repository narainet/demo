<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/uss/umt/my/EgovMyPassword.jsp
  비밀번호 변경 (개인 셀프서비스). front decorator + KRDS.
  유효기간(Globals.ExpirePwdDay) 경과 상태를 함께 안내 — 홈/대시보드 배너와 동일 데이터.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">비밀번호 변경</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>비밀번호 변경</h1>
    <p class="page-desc">비밀번호는 영문과 숫자를 포함해 8~20자로 설정합니다.
      <c:if test="${not empty pwdExpireDay}">변경일로부터 <b><c:out value="${pwdExpireDay}"/>일</b> 동안 유효합니다.</c:if>
    </p>
  </div>

  <style>
    .mya-card { max-width: 760px; border:1px solid #e4e7ec; border-radius:10px; padding:24px 28px; background:#fff; }
    .mya-row { display:flex; align-items:center; gap:12px; margin-bottom:18px; }
    .mya-row > label.form-label { width:160px; flex:0 0 160px; font-weight:600; }
    .mya-msg-ok { margin-bottom:16px; padding:10px 14px; border-radius:8px; background:#ecfdf3; color:#067647; border:1px solid #abefc6; }
    .mya-msg-err{ margin-bottom:16px; padding:10px 14px; border-radius:8px; background:#fef3f2; color:#b42318; border:1px solid #fda29b; }
    .mya-pwd-state { max-width:760px; margin-bottom:16px; padding:10px 14px; border-radius:8px; font-size:14px;
                     background:#f4f6fb; color:#1f3974; border:1px solid #d1d3d8; }
    .mya-pwd-state.warn { background:#fffaeb; color:#b54708; border-color:#fec84b; }
    .mya-pwd-state.expired { background:#fef3f2; color:#b42318; border-color:#fda29b; }
    .mya-actions { margin-top:8px; }
  </style>

  <c:if test="${not empty pwdMsg}">
    <div class="${pwdMsgType eq 'ok' ? 'mya-msg-ok' : 'mya-msg-err'}"><c:out value="${pwdMsg}"/></div>
  </c:if>

  <%-- 유효기간 상태 — 정책 사용 시에만 노출 --%>
  <c:if test="${not empty pwdDaysLeft}">
    <c:choose>
      <c:when test="${pwdDaysLeft le 0}">
        <div class="mya-pwd-state expired">🔒 비밀번호가 <b>만료</b>되었습니다 — 변경 후 <c:out value="${pwdPassedDay}"/>일 경과 (유효기간 <c:out value="${pwdExpireDay}"/>일). 지금 변경해 주세요.</div>
      </c:when>
      <c:when test="${pwdDaysLeft le 7}">
        <div class="mya-pwd-state warn">🔑 비밀번호 만료까지 <b><c:out value="${pwdDaysLeft}"/>일</b> 남았습니다 (변경 후 <c:out value="${pwdPassedDay}"/>일 경과).</div>
      </c:when>
      <c:otherwise>
        <div class="mya-pwd-state">현재 비밀번호는 변경 후 <c:out value="${pwdPassedDay}"/>일 경과 — 만료까지 <c:out value="${pwdDaysLeft}"/>일 남았습니다.</div>
      </c:otherwise>
    </c:choose>
  </c:if>

  <div class="mya-card">
    <form id="pwdForm" name="pwdForm" action="<c:url value='/uss/umt/my/savePassword.do'/>" method="post" class="krds-form" autocomplete="off">
      <div class="mya-row">
        <label class="form-label" for="oldPassword">현재 비밀번호</label>
        <div class="form-conts">
          <input type="password" id="oldPassword" name="oldPassword" class="krds-input" style="width:280px;" autocomplete="current-password"/>
        </div>
      </div>
      <div class="mya-row">
        <label class="form-label" for="newPassword">새 비밀번호</label>
        <div class="form-conts">
          <input type="password" id="newPassword" name="newPassword" class="krds-input" style="width:280px;" autocomplete="new-password" placeholder="영문+숫자 포함 8~20자"/>
        </div>
      </div>
      <div class="mya-row">
        <label class="form-label" for="newPassword2">새 비밀번호 확인</label>
        <div class="form-conts">
          <input type="password" id="newPassword2" name="newPassword2" class="krds-input" style="width:280px;" autocomplete="new-password"/>
        </div>
      </div>

      <div class="mya-actions">
        <button type="submit" class="krds-btn primary medium">변경</button>
      </div>
    </form>
  </div>

  <script>
    (function() {
      $('#pwdForm').on('submit', function(e) {
        var o = $('#oldPassword').val(), n = $('#newPassword').val(), n2 = $('#newPassword2').val();
        var msg = null;
        if (!o || !n || !n2) { msg = '모든 항목을 입력해 주세요.'; }
        else if (n !== n2) { msg = '새 비밀번호가 서로 일치하지 않습니다.'; }
        else if (!/^(?=.*[A-Za-z])(?=.*[0-9]).{8,20}$/.test(n)) { msg = '새 비밀번호는 영문과 숫자를 포함해 8~20자로 입력해 주세요.'; }
        else if (n === o) { msg = '현재 비밀번호와 다른 비밀번호를 입력해 주세요.'; }
        if (msg) { e.preventDefault(); alert(msg); }
      });
    })();
  </script>
</lay:layout>
