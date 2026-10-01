<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/uss/umt/my/EgovMyProfile.jsp
  내정보수정 (개인 셀프서비스). front decorator + KRDS.
  수정 가능 = 이메일·휴대전화. 이름/아이디는 표시만(관리자 관리 영역).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">내정보수정</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>내정보수정</h1>
    <p class="page-desc">이메일과 휴대전화를 수정할 수 있습니다. 이름·소속 변경은 관리자에게 문의해 주세요.</p>
  </div>

  <style>
    .mya-card { max-width: 760px; border:1px solid #e4e7ec; border-radius:10px; padding:24px 28px; background:#fff; }
    .mya-row { display:flex; align-items:center; gap:12px; margin-bottom:18px; }
    .mya-row > label.form-label, .mya-row > .form-label { width:130px; flex:0 0 130px; font-weight:600; }
    .mya-static { color:#333; }
    .mya-msg-ok { margin-bottom:16px; padding:10px 14px; border-radius:8px; background:#ecfdf3; color:#067647; border:1px solid #abefc6; }
    .mya-msg-err{ margin-bottom:16px; padding:10px 14px; border-radius:8px; background:#fef3f2; color:#b42318; border:1px solid #fda29b; }
    .mya-actions { margin-top:8px; }
  </style>

  <c:if test="${not empty pfMsg}">
    <div class="${pfMsgType eq 'ok' ? 'mya-msg-ok' : 'mya-msg-err'}"><c:out value="${pfMsg}"/></div>
  </c:if>

  <div class="mya-card">
    <div class="mya-row">
      <span class="form-label">아이디</span>
      <span class="mya-static"><c:out value="${loginUser.id}"/></span>
    </div>
    <div class="mya-row">
      <span class="form-label">이름</span>
      <span class="mya-static"><c:out value="${profile.name}"/></span>
    </div>

    <form id="pfForm" name="pfForm" action="<c:url value='/uss/umt/my/saveProfile.do'/>" method="post" class="krds-form">
      <div class="mya-row">
        <label class="form-label" for="email">이메일</label>
        <div class="form-conts">
          <input type="text" id="email" name="email" class="krds-input" style="width:300px;"
                 value="<c:out value='${profile.email}'/>" placeholder="예: hong@example.com" maxlength="50"/>
        </div>
      </div>
      <div class="mya-row">
        <label class="form-label" for="mbtlnum">휴대전화</label>
        <div class="form-conts">
          <input type="text" id="mbtlnum" name="mbtlnum" class="krds-input" style="width:220px;"
                 value="<c:out value='${profile.mbtlnum}'/>" placeholder="예: 010-1234-5678" maxlength="20"/>
        </div>
      </div>

      <div class="mya-actions">
        <button type="submit" class="krds-btn primary medium">저장</button>
      </div>
    </form>
  </div>

  <script>
    (function() {
      $('#pfForm').on('submit', function(e) {
        var em = $.trim($('#email').val()), tel = $.trim($('#mbtlnum').val());
        var msg = null;
        if (em && !/^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(em)) { msg = '이메일 형식이 올바르지 않습니다.'; }
        else if (tel && !/^[0-9\-]{9,20}$/.test(tel)) { msg = '휴대전화는 숫자와 - 만으로 9~20자로 입력해 주세요.'; }
        if (msg) { e.preventDefault(); alert(msg); }
      });
    })();
  </script>
</lay:layout>
