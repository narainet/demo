<%@ page contentType="text/html; charset=utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 세션 만료 감지용 마커 — Ajax/fetch 가 만료로 로그인 페이지를 받았을 때 클라이언트가 식별해 로그인으로 보냄(#12) --%>
<% response.setHeader("X-RLMS-Auth", "login"); %>
<%--
  로그인 화면 (KRDS).
   - SiteMesh plain 데코레이터로 감싸짐: 중앙 카드(.rlms-plain-card) + RLMS 브랜드 + KRDS CSS.
   - USER_SE 선택 없음(서버가 아이디로 COMVNUSERMASTER 자동판별).
   - 회원가입 / 아이디·비번 찾기 / 인증서 / 디지털원패스 / eGov 로고 제거.
   - 표준프레임워크 CSS/JS 의존 제거(jQuery 불필요). 초기화는 본문 끝 스크립트.
--%>
<c:set var="pageTitle"><spring:message code="comUatUia.title" /></c:set>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style>
  .rlms-login-title { font-size:1.375rem; font-weight:700; text-align:center; margin:4px 0 24px; }
  .rlms-login-form .form-group { margin-bottom:16px; }
  .rlms-login-form .krds-input { width:100%; }
  .rlms-login-saveid { margin:4px 0 20px; }
  .rlms-login-form .btn-area { margin-top:8px; }
  .rlms-login-form .btn-area .krds-btn { width:100%; }
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <noscript class="noScriptTitle"><spring:message code="common.noScriptTitle.msg" /></noscript>

  <h1 class="rlms-login-title">로그인</h1>

  <form name="loginForm" id="loginForm" action="<c:url value='/uat/uia/actionLogin.do'/>" method="post" class="krds-form rlms-login-form">
    <%-- USER_SE 는 서버에서 아이디로 자동판별 (사용자 선택 불필요) --%>
    <input type="hidden" name="userSe" value=""/>

    <div class="form-group">
      <label class="form-label" for="id">아이디</label>
      <div class="form-conts">
        <%-- 공백은 입력 즉시 제거 — 붙여넣기로 끼어든 앞뒤 공백이 로그인 실패로 이어지던 문제 (2026-07-29) --%>
        <input type="text" id="id" name="id" class="krds-input" maxlength="20"
               placeholder="아이디를 입력하세요" autocomplete="username" autofocus
               oninput="this.value=this.value.replace(/\s+/g,'');"/>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label" for="password">비밀번호</label>
      <div class="form-conts">
        <input type="password" id="password" name="password" class="krds-input" maxlength="20"
               placeholder="비밀번호를 입력하세요" autocomplete="current-password"
               onkeypress="if(event.keyCode===13){actionLogin();return false;}"/>
      </div>
    </div>

    <div class="krds-form-check medium rlms-login-saveid">
      <input type="checkbox" id="checkId" name="checkId" value="Y" onclick="saveid(this.form);"/>
      <label for="checkId">아이디 저장</label>
    </div>

    <div class="btn-area">
      <button type="button" class="krds-btn primary large" onclick="actionLogin();">로그인</button>
    </div>
  </form>

  <script type="text/javascript">
  function actionLogin() {
    var f = document.loginForm;
    // 붙여넣기·자동완성으로 앞뒤 공백이 섞여 들어와 "로그인 정보가 올바르지 않습니다"가 뜨던 문제
    // (고객 테스트 2026-07-29). 아이디는 공백을 허용하지 않으므로 전송 전에 제거한다.
    f.id.value = f.id.value.replace(/\s+/g, "");
    if (f.id.value === "") {
      alert("<spring:message code='comUatUia.validate.idCheck' />"); f.id.focus(); return;
    }
    if (f.password.value === "") {
      alert("<spring:message code='comUatUia.validate.passCheck' />"); f.password.focus(); return;
    }
    f.action = "<c:url value='/uat/uia/actionLogin.do'/>";
    f.submit();
  }

  function setCookie(name, value, expires) {
    document.cookie = name + "=" + escape(value) + "; path=/; expires=" + expires.toGMTString();
  }
  function getCookie(name) {
    var search = name + "=";
    if (document.cookie.length > 0) {
      var offset = document.cookie.indexOf(search);
      if (offset !== -1) {
        offset += search.length;
        var end = document.cookie.indexOf(";", offset);
        if (end === -1) end = document.cookie.length;
        return unescape(document.cookie.substring(offset, end));
      }
    }
    return "";
  }
  function saveid(form) {
    var expdate = new Date();
    if (form.checkId.checked) {
      expdate.setTime(expdate.getTime() + 1000 * 3600 * 24 * 30); // 30일
    } else {
      expdate.setTime(expdate.getTime() - 1); // 삭제
    }
    setCookie("saveid", form.id.value, expdate);
  }

  // 초기화 (body onload 대신 — SiteMesh 가 onload 를 데코레이터로 넘기지 않음)
  (function loginInit() {
    var f = document.loginForm;
    var saved = getCookie("saveid");
    if (saved) {
      f.id.value = saved;
      f.checkId.checked = true;
      f.password.focus();
    }
    <c:if test="${not empty fn:trim(loginMessage) && loginMessage ne ''}">
    alert("<c:out value='${loginMessage}'/>");
    </c:if>
  })();
  </script>
</lay:layout>
