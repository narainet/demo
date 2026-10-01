<%
 /**
  * @Class Name : EgovDbCrypto.jsp
  * @Description : 설정값 암호화 도구 — globals.properties 에 넣을 암호문 생성(한 줄에 하나).
  *                암호화만 하고 파일은 고치지 않는다(관리자가 결과를 붙여넣고 WAS 재기동).
  *                ★암호화는 DB 종류와 무관 — context-crypto.xml 의 키 하나로만 암호화한다.
  * @ 2026.08.06   RLMS               신규 — 고객사 계정 교체 시 관리자가 손으로 암호화할 수단 제공
  */
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle" value="설정값 암호화"/>
<c:set var="pageHead">
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<script type="text/javascript">
function fn_dbcrypto_submit() {
	var f = document.getElementById("dbCryptoForm");
	if (!f.plainText.value.trim()) {
		alert("암호화할 값을 입력하세요.");
		f.plainText.focus();
		return false;
	}
	f.submit();
	return true;
}
function fn_dbcrypto_copy() {
	var ta = document.getElementById("cryptoResultText");
	if (!ta) { return; }
	ta.select();
	ta.setSelectionRange(0, ta.value.length);
	try {
		document.execCommand("copy");
		alert("암호문을 복사했습니다.");
	} catch (e) {
		alert("복사가 지원되지 않는 브라우저입니다. 직접 선택해 복사하세요.");
	}
}
</script>
<style>
	.dbc-hint { margin:6px 0 14px; font-size:13px; color:#667085; line-height:1.7; }
	.dbc-warn { margin:14px 0 0; padding:10px 12px; font-size:13px; line-height:1.7;
	            background:#fff8e1; border:1px solid #ffe08a; border-radius:6px; color:#7a5b00; }
	.dbc-area { width:100%; box-sizing:border-box; font-family:Consolas,'D2Coding',monospace;
	            font-size:13px; line-height:1.7; padding:10px; border:1px solid #d0d5dd;
	            border-radius:6px; background:#fbfcfd; }
	.dbc-cipher { font-family:Consolas,'D2Coding',monospace; font-size:12px; word-break:break-all; }
	.dbc-plain { font-family:Consolas,'D2Coding',monospace; font-size:12px; word-break:break-all; color:#475467; }
	.dbc-ok { color:#1a7f37; font-weight:600; }
	.dbc-ng { color:#b42318; font-weight:600; }
	.dbc-msg { margin:10px 0; color:#b42318; font-size:13px; }
	.dbc-keys { margin:4px 0 0; padding-left:18px; font-size:13px; color:#667085; line-height:1.8; }
</style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<noscript class="noScriptTitle">스크립트를 허용해 주세요.</noscript>

<div class="page-header">
	<h2>${pageTitle}</h2>
</div>

<p class="dbc-hint">
	<strong>globals.properties</strong> 에 넣을 암호문을 만들어 줍니다.
	이 화면은 <strong>암호화만</strong> 하고 서버 설정 파일을 고치지 않습니다 &mdash;
	결과를 복사해 해당 값을 바꾼 뒤 <strong>WAS 를 재기동</strong>하세요(설정은 기동할 때 한 번만 읽습니다).
</p>
<p class="dbc-hint" style="margin-bottom:4px;">암호화해서 넣는 항목 &mdash; DB 계정이 바뀌면 세 줄 모두 바꿉니다.</p>
<ul class="dbc-keys">
	<li><code>Globals.<em>&lt;DB구분&gt;</em>.Url</code> &nbsp;·&nbsp; <code>.UserName</code> &nbsp;·&nbsp; <code>.Password</code>
		<span style="color:#98a2b3;">(DB구분 = oracle / tibero / maria / postgres)</span></li>
</ul>
<p class="dbc-hint">
	암호화는 <strong>DB 종류와 무관</strong>합니다. <code>context-crypto.xml</code> 의 키 하나로만 암호화하므로
	같은 값이면 어느 DB 항목에 넣든 암호문이 같습니다.
</p>

<c:if test="${not empty message}">
	<p class="dbc-msg"><c:out value="${message}"/></p>
</c:if>

<form id="dbCryptoForm" name="dbCryptoForm" method="post"
      action="${pageContext.request.contextPath}/uss/ion/crypto/dbCryptoEncrypt.do"
      autocomplete="off">

<table class="krds-table tbl-detail">
	<caption class="sr-only">${pageTitle} 입력</caption>
	<colgroup>
		<col style="width:16%;">
		<col style="width:*;">
	</colgroup>
	<tbody>
		<tr>
			<th scope="row">평문</th>
			<td class="al">
				<textarea id="plainText" name="plainText" class="dbc-area" rows="5"
				          placeholder="한 줄에 하나씩 입력하세요.&#10;jdbc:oracle:thin:@127.0.0.1:1521:xe&#10;RLMS&#10;비밀번호"><c:out value="${plainText}"/></textarea>
				<p class="dbc-hint" style="margin:6px 0 0;">
					한 줄에 값 하나. 입력값은 저장되지 않습니다.
				</p>
			</td>
		</tr>
	</tbody>
</table>

<div class="btn-area" style="margin-top:14px;">
	<input type="submit" class="krds-btn primary medium" value="암호화" onclick="return fn_dbcrypto_submit();"/>
</div>

</form>

<c:if test="${not empty items}">
	<div class="page-header" style="margin-top:28px;">
		<h2>암호화 결과</h2>
	</div>

	<table class="krds-table tbl-detail">
		<caption class="sr-only">암호화 결과</caption>
		<colgroup>
			<col style="width:26%;">
			<col style="width:*;">
			<col style="width:12%;">
		</colgroup>
		<tbody>
			<tr>
				<th scope="col">평문</th>
				<th scope="col">암호문</th>
				<th scope="col">복호 확인</th>
			</tr>
			<c:forEach var="it" items="${items}">
				<tr>
					<td class="al dbc-plain"><c:out value="${it.plain}"/></td>
					<td class="al dbc-cipher"><c:out value="${it.cipher}"/></td>
					<td class="al">
						<c:choose>
							<c:when test="${it.verified}"><span class="dbc-ok">정상</span></c:when>
							<c:otherwise><span class="dbc-ng">실패</span></c:otherwise>
						</c:choose>
					</td>
				</tr>
			</c:forEach>
		</tbody>
	</table>

	<p class="dbc-hint" style="margin-top:14px;">암호문만 모아 둔 것입니다(입력한 순서).</p>
	<textarea id="cryptoResultText" class="dbc-area" rows="${fn:length(items) + 1}" readonly="readonly"><c:forEach var="it" items="${items}"><c:out value="${it.cipher}"/>
</c:forEach></textarea>

	<div class="btn-area" style="margin-top:12px;">
		<button type="button" class="krds-btn secondary medium" onclick="fn_dbcrypto_copy();">암호문 복사</button>
	</div>

	<p class="dbc-warn">
		<strong>주의</strong> &mdash; URL·ID·비밀번호는 <strong>세 항목 모두 암호문</strong>이어야 합니다.
		한 항목이라도 평문으로 남기면 기동할 때 오류가 나지 않고 <strong>깨진 값으로 접속을 시도</strong>해
		원인을 찾기 어렵습니다. 값을 바꾼 뒤에는 반드시 WAS 를 재기동해 접속을 확인하세요.
	</p>
</c:if>

<p class="dbc-hint" style="margin-top:24px;">
	<strong>설치 시점에는 이 화면을 쓸 수 없습니다</strong> &mdash; DB 접속이 되기 전에는 앱이 뜨지 않기 때문입니다.
	그때는 WAR 에 함께 배포되는 실행 파일로 같은 암호문을 만드세요. 배포본의 <code>WEB-INF</code> 폴더에 있습니다.
</p>
<textarea class="dbc-area" rows="4" readonly="readonly">[Windows]  cd 배포경로\WEB-INF
           encrypt.bat "접속URL" "계정ID" "비밀번호"
[Linux]    cd 배포경로/WEB-INF
           sh encrypt.sh "접속URL" "계정ID" "비밀번호"</textarea>
<p class="dbc-hint" style="margin-top:6px;">
	인자 없이 실행하면 한 줄에 하나씩 입력받습니다(비밀번호를 명령 이력에 남기지 않을 때).
	자세한 절차는 <code>database/INSTALL_CRYPTO.md</code> 참고.
</p>
</lay:layout>
