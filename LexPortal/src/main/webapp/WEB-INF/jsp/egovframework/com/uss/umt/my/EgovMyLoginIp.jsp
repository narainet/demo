<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/egovframework/com/uss/umt/my/EgovMyLoginIp.jsp
  내 로그인 IP 설정 (개인 셀프서비스). front decorator + KRDS.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">로그인 IP 설정</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>로그인 IP 설정</h1>
    <p class="page-desc">지정한 IP에서만 로그인하도록 본인 계정을 제한할 수 있습니다.</p>
  </div>

  <style>
    .mya-card { max-width: 760px; border:1px solid #e4e7ec; border-radius:10px; padding:24px 28px; background:#fff; }
    .mya-row { display:flex; align-items:center; gap:12px; margin-bottom:18px; }
    .mya-row > label.form-label { width:130px; flex:0 0 130px; font-weight:600; }
    .mya-cur-ip { font-weight:700; color:#175cd3; }
    .mya-warn { margin-top:6px; padding:10px 14px; border-radius:8px; background:#fffaeb; color:#b54708;
                border:1px solid #fec84b; font-size:13px; line-height:1.5; }
    .mya-msg-ok { margin-bottom:16px; padding:10px 14px; border-radius:8px; background:#ecfdf3; color:#067647; border:1px solid #abefc6; }
    .mya-msg-err{ margin-bottom:16px; padding:10px 14px; border-radius:8px; background:#fef3f2; color:#b42318; border:1px solid #fda29b; }
    .mya-actions { margin-top:8px; }
  </style>

  <c:if test="${param.saved eq 'Y'}"><div class="mya-msg-ok">로그인 IP 설정이 저장되었습니다.</div></c:if>
  <c:if test="${param.err eq 'lockout'}"><div class="mya-msg-err">로그인 제한을 사용하려면 <b>현재 접속 IP</b>만 등록할 수 있습니다. (본인 잠금 방지)</div></c:if>
  <c:if test="${param.err eq 'save'}"><div class="mya-msg-err">저장 중 오류가 발생했습니다. 다시 시도해 주세요.</div></c:if>

  <div class="mya-card">
    <div class="mya-row">
      <label class="form-label">현재 접속 IP</label>
      <span class="mya-cur-ip"><c:out value="${currentIp}"/></span>
    </div>

    <form id="ipForm" name="ipForm" action="<c:url value='/uss/umt/my/saveLoginIp.do'/>" method="post" class="krds-form">
      <div class="mya-row">
        <label class="form-label" for="lmttAt">로그인 제한</label>
        <div class="form-conts">
          <select id="lmttAt" name="lmttAt" class="krds-select">
            <option value="N" <c:if test="${empty policy.lmttAt or policy.lmttAt eq 'N'}">selected</c:if>>사용 안 함 (모든 IP 허용)</option>
            <option value="Y" <c:if test="${policy.lmttAt eq 'Y'}">selected</c:if>>사용 (등록 IP에서만 로그인)</option>
          </select>
        </div>
      </div>

      <div class="mya-row">
        <label class="form-label" for="ipInfo">허용 IP</label>
        <div class="form-conts">
          <input type="text" id="ipInfo" name="ipInfo" class="krds-input" style="width:260px;"
                 value="<c:out value='${policy.ipInfo}'/>" placeholder="예: 192.168.0.10"/>
          <button type="button" id="btnUseCur" class="krds-btn small" style="margin-left:8px;">현재 IP 입력</button>
        </div>
      </div>

      <div id="ipWarn" class="mya-warn" style="display:none;">
        ⚠ 로그인 제한을 <b>사용</b>하면 등록한 IP에서만 로그인할 수 있습니다.
        잘못 설정하면 본인이 로그인하지 못할 수 있어, 제한 사용 시 <b>현재 접속 IP</b>가 자동 입력됩니다.
      </div>

      <div class="mya-actions">
        <button type="submit" class="krds-btn primary medium">저장</button>
      </div>
    </form>
  </div>

  <script>
    (function() {
      var curIp = '<c:out value="${currentIp}"/>';
      var $lmtt = $('#lmttAt'), $ip = $('#ipInfo'), $warn = $('#ipWarn');

      function sync() {
        if ($lmtt.val() === 'Y') {
          // 제한 사용: 자기 잠금 방지 — 현재 IP 고정
          $ip.val(curIp).prop('readonly', true);
          $warn.show();
        } else {
          $ip.prop('readonly', false);
          $warn.hide();
        }
      }
      $lmtt.on('change', sync);
      $('#btnUseCur').on('click', function() { $ip.val(curIp); });
      sync();

      $('#ipForm').on('submit', function(e) {
        if ($lmtt.val() === 'Y' && $ip.val() !== curIp) {
          e.preventDefault();
          alert('로그인 제한 사용 시 현재 접속 IP(' + curIp + ')만 등록할 수 있습니다.');
        }
      });
    })();
  </script>
</lay:layout>
