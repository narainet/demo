<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/requser/regist.jsp
  소송의뢰 신청/수정(사용자 front) — LAW_MODULE_DESIGN.md §7.8.
   - 기본내용(사건명/사실관계) + 사건 경과 내역(기간~/내용/행별 첨부) + 기타 자료 첨부(다중) + 소송수행 보조자(부서/담당자/전화/휴대폰/이메일).
   - 서브그리드는 hidden JSON(경과·보조자)으로 전송, 파일은 multipart(기타=file_1, 경과 행별=histFile_<rowKey>).
   - 신청자·부서는 세션 자동. 신청(S001) 상태·본인만 수정(서버 이중 방어).
   - KRDS 정본 폼(규정관리 동일): 기본내용=table.tbl-detail, 서브그리드=krds 톤 편집표, 기타 첨부=게시판 드롭존(공용 inc).
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><c:choose><c:when test="${mode eq 'edit'}">소송의뢰 수정</c:when><c:otherwise>소송의뢰 신청</c:otherwise></c:choose></c:set>
<c:set var="pageHead">
  
  <style>
    #reqForm table.tbl-detail td { text-align: left; }
    #reqForm table.tbl-detail td .krds-input { width: 100%; box-sizing: border-box; }
    .law-sec-tit { margin: 24px 0 6px; padding-bottom: 6px; border-bottom: 2px solid #1f3974;
                   font-size: 1.05em; font-weight: 700; color: #1f3974; }
    .law-grid { width: 100%; border-collapse: collapse; margin: 6px 0 4px; background: #fff; }
    .law-grid thead th { padding: 10px 8px; background: #f0f2f5; color: #1f3974; font-weight: 600;
                         font-size: 0.95em; border-top: 2px solid #1f3974; border-bottom: 1px solid #d1d3d8; white-space: nowrap; }
    /* 서브그리드 셀 폰트 = 표준 목록표(krds-table td 0.93em ≈ 15.8px)와 동일 스케일(2026-07-30)
       — body 17px 상속 그대로 두면 기본내용 표보다 커 보인다 */
    .law-grid tbody td { padding: 8px; border-bottom: 1px solid #e0e2e6; vertical-align: top; font-size: 0.93em; }
    .law-grid tbody input[type=text], .law-grid tbody input[type=date], .law-grid tbody textarea {
                         width: 100%; box-sizing: border-box; border: 1px solid #c4c6cd; border-radius: 4px; padding: 8px 10px; font-size: 14px; }
    /* 그리드 내장 입력 = KRDS small(40px) 스케일 — 메인 폼(48px)보다 한 단계 컴팩트 */
    .law-grid tbody input[type=text], .law-grid tbody input[type=date] { height: 40px; }
    /* 파일 컨트롤이 좁은 화면에서 이웃(삭제) 칸을 침범하지 않게 셀 안에 가둠 */
    .law-grid tbody input[type=file] { width: 100%; box-sizing: border-box; font-size: 0.88em; }
    .law-sub-head { display: flex; justify-content: space-between; align-items: center; margin-top: 18px; }
    .law-sub-head h3 { margin: 0; font-size: 1em; color: #333; }
    /* 보조 텍스트는 부모 em 의존을 끊고 캡션 고정 크기(td 축소와 무관하게 13px 유지) */
    .law-note { font-size: 13px; color: #888; font-weight: 400; }
    .law-date-range { display: flex; gap: 4px; align-items: center; }
    .law-date-range input { flex: 1 1 0; min-width: 0; }
    .law-exist-file { font-size: 13px; color: #3651d4; display: block; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1><c:choose><c:when test="${mode eq 'edit'}">소송의뢰 수정</c:when><c:otherwise>소송의뢰 신청</c:otherwise></c:choose></h1>
    <p class="page-desc">사건 내용과 경과, 소송수행 보조자를 입력하여 법무팀에 소송의뢰를 신청합니다.</p>
  </div>

  <c:if test="${not empty message}"><script>alert('<c:out value="${message}"/>');</script></c:if>

  <%-- 진행 단계 (KRDS 단계 표시) — 작성 화면이라 1단계. 수정도 '신청' 상태에서만 열리므로 같은 단계다. --%>
  <c:set var="reqStepCur" value="1"/>
  <c:set var="reqStepStatus" value="${req.statusCd}"/>
  <%@ include file="reqStep.jspf" %>

  <form id="reqForm" class="krds-form" action="<c:url value='/law/reqUser/save.do'/>" method="post" enctype="multipart/form-data">
    <input type="hidden" name="reqId" value="<c:out value='${req.reqId}'/>"/>
    <input type="hidden" name="histsJson" id="histsJson"/>
    <input type="hidden" name="helpersJson" id="helpersJson"/>

    <h3 class="law-sec-tit">기본 내용</h3>
    <table class="krds-table tbl-detail">
      <colgroup><col style="width:16%"/><col/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label required" for="reqTitl">사건명</label></th>
          <td><input type="text" id="reqTitl" name="reqTitl" class="krds-input" maxlength="200" value="<c:out value='${req.reqTitl}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="reqCn">사실관계</label></th>
          <td><textarea id="reqCn" name="reqCn" rows="5" class="krds-input" maxlength="4000" placeholder="사건의 사실관계를 입력하세요."><c:out value="${req.reqCn}"/></textarea></td>
        </tr>
      </tbody>
    </table>

    <%-- ── 경과 내역 ── --%>
    <div class="law-sub-head">
      <h3>사건 경과 내역 <span class="law-note">기간·내용과 행별 첨부(선택)를 입력합니다.</span></h3>
      <button type="button" class="krds-btn small" onclick="addHist();">행 추가</button>
    </div>
    <table class="law-grid" id="histTable">
      <thead>
        <tr><th style="width:26%;">기간</th><th>내용</th><th style="width:20%;">첨부</th><th style="width:64px;">삭제</th></tr>
      </thead>
      <tbody></tbody>
    </table>

    <%-- ── 기타 자료 첨부 ── --%>
    <div class="law-sub-head">
      <h3>기타 자료 첨부 <span class="law-note">여러 파일을 선택할 수 있습니다.</span></h3>
    </div>
    <c:set var="aId" value="reqAtch" scope="request"/>
    <c:set var="aName" value="file_1" scope="request"/>
    <c:set var="aNote" value="" scope="request"/>
    <c:set var="aExistFileId" value="${req.atchFileId}" scope="request"/>
    <c:set var="aExistFiles" value="${mode eq 'edit' ? req.files : null}" scope="request"/>
    <jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>

    <%-- ── 소송수행 보조자 ── --%>
    <div class="law-sub-head">
      <h3>소송수행 보조자 <span class="law-note">사건 수행을 도울 담당자(외부 인원 포함)를 입력합니다.</span></h3>
      <button type="button" class="krds-btn small" onclick="addHelper();">행 추가</button>
    </div>
    <table class="law-grid" id="helperTable">
      <thead>
        <tr><th style="width:18%;">부서</th><th style="width:12%;">담당자</th><th style="width:15%;">전화</th><th style="width:15%;">휴대폰</th><th>이메일</th><th style="width:64px;">삭제</th></tr>
      </thead>
      <tbody></tbody>
    </table>

    <div class="btn-area center">
      <button type="button" class="krds-btn primary medium" onclick="fnSubmit();">저장</button>
      <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/reqUser/list.do"/>';">취소</button>
    </div>
  </form>

  <%-- 행 템플릿 --%>
  <template id="tplHist">
    <tr>
      <td>
        <div class="law-date-range">
          <input type="date" data-f="staDt"/><span>~</span><input type="date" data-f="endDt"/>
        </div>
      </td>
      <td><textarea data-f="histCn" rows="2" maxlength="1000"></textarea></td>
      <td>
        <input type="file" class="histFile"/>
        <input type="hidden" data-f="atchFileId"/>
        <input type="hidden" data-f="rowKey"/>
        <div class="existFiles"></div>
      </td>
      <td style="text-align:center;"><button type="button" class="krds-btn small" onclick="delRow(this);">삭제</button></td>
    </tr>
  </template>
  <template id="tplHelper">
    <tr>
      <td><input type="text" data-f="deptNm" maxlength="100"/></td>
      <td><input type="text" data-f="helperNm" maxlength="60"/></td>
      <td><input type="text" data-f="tel" maxlength="50"/></td>
      <td><input type="text" data-f="mobile" maxlength="50"/></td>
      <td><input type="text" data-f="email" maxlength="100"/></td>
      <td style="text-align:center;"><button type="button" class="krds-btn small" onclick="delRow(this);">삭제</button></td>
    </tr>
  </template>

  <%-- 초기 데이터 (HTML 이스케이프 경유 — JS 에서 JSON.parse) --%>
  <textarea id="initHists" hidden><c:out value="${histsJsonStr}"/></textarea>
  <textarea id="initHelpers" hidden><c:out value="${helpersJsonStr}"/></textarea>

  <script>
  var histKeySeq = 0;

  function addRowFrom(tplId, tableId, data) {
    var tpl = document.getElementById(tplId);
    var row = tpl.content.firstElementChild.cloneNode(true);
    if (data) {
      row.querySelectorAll('[data-f]').forEach(function (el) {
        var v = data[el.dataset.f];
        if (v !== undefined && v !== null) { el.value = v; }
      });
    }
    document.querySelector('#' + tableId + ' tbody').appendChild(row);
    return row;
  }
  function addHist(d) {
    var row = addRowFrom('tplHist', 'histTable', d);
    var key = 'h' + (++histKeySeq);
    row.querySelector('[data-f=rowKey]').value = key;
    row.querySelector('.histFile').name = 'histFile_' + key;
    // 기존 첨부 파일명 표시(수정 모드)
    if (d && d.files && d.files.length) {
      var box = row.querySelector('.existFiles');
      d.files.forEach(function (f) {
        var s = document.createElement('span');
        s.className = 'law-exist-file';
        s.textContent = '기존: ' + (f.orignlFileNm || '');
        box.appendChild(s);
      });
    }
    return row;
  }
  function addHelper(d) { return addRowFrom('tplHelper', 'helperTable', d); }
  function delRow(btn) { btn.closest('tr').remove(); }

  function collect(tableId, textFields) {
    var rows = [];
    document.querySelectorAll('#' + tableId + ' tbody tr').forEach(function (tr) {
      var o = {};
      var hasVal = false;
      tr.querySelectorAll('[data-f]').forEach(function (el) {
        var v = el.value == null ? '' : String(el.value).trim();
        o[el.dataset.f] = v === '' ? null : v;
        if (v !== '' && textFields.indexOf(el.dataset.f) >= 0) { hasVal = true; }
      });
      // 파일만 있어도 내용 행으로 취급
      var file = tr.querySelector('input[type=file]');
      if (file && file.files && file.files.length > 0) { hasVal = true; }
      if (hasVal) { rows.push(o); }
    });
    return rows;
  }

  function fnSubmit() {
    var titl = document.getElementById('reqTitl').value.trim();
    if (!titl) { alert('사건명을 입력하세요.'); document.getElementById('reqTitl').focus(); return; }
    document.getElementById('histsJson').value = JSON.stringify(collect('histTable', ['staDt', 'endDt', 'histCn']));
    document.getElementById('helpersJson').value = JSON.stringify(collect('helperTable', ['deptNm', 'helperNm', 'tel', 'mobile', 'email']));
    document.getElementById('reqForm').submit();
  }

  (function init() {
    function parseInit(id) {
      var t = document.getElementById(id).value.trim();
      if (!t) { return []; }
      try { return JSON.parse(t) || []; } catch (e) { return []; }
    }
    var hists = parseInit('initHists');
    var helpers = parseInit('initHelpers');
    hists.forEach(addHist);
    helpers.forEach(addHelper);
    if (hists.length === 0) { addHist(); }
    if (helpers.length === 0) { addHelper(); }
  })();
  </script>
</lay:layout>
