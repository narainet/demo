<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/lawquest/lawQuestForm.jsp
  법령질의 등록/수정·회신 폼. 부서관리(EgovDeptManageInsert) 패턴 100% — 전체폭 shell(main+280px 사이드)
  + 다크 작업정보 패널 + 반응형(1024/768). 첨부=규정편집 krds-file-upload 컴포넌트 재사용.
  mode = insert | update / answerAdmin = 회신(respoCon) 작성 권한
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">법령질의 ${mode eq 'update' ? '수정·회신' : '등록'}</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <script src="<c:url value='/html/egovframework/com/cmm/utl/ckeditor/ckeditor.js'/>"></script>
  <style>
    .lq-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
    .lq-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
    .lq-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
    .lq-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
    .lq-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #fff7d6; color: #856404; font-size: 13px; font-weight: 700; }
    .lq-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 560px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
    .lq-ide-main { min-height: 560px; border-right: 1px solid #d1d3d8; }
    .lq-ide-main .ide-context-pane { padding: 24px; }
    .lq-ide-main .ide-prov-head { align-items: center; flex-wrap: wrap; }
    .lq-ide-main .ide-prov-head h2 { font-size: 21px; }
    .lq-ide-main .ide-form-row { margin-bottom: 18px; }
    .lq-ide-main .krds-input, .lq-ide-main .krds-input.small, .lq-ide-main .krds-select { max-width: 100%; }
    .lq-ide-main .ide-form-row.cols { display: flex; gap: 16px; }
    .lq-ide-main .ide-form-row.cols > .col { flex: 1; min-width: 0; }
    .lq-ide-main .ide-form-row.cols > .col label { display: block; }
    .lq-ide-main .ide-form-actions { margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
    .lq-ide-right { min-height: 560px; }
    .lq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
    .lq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
    .lq-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
    .lq-req { color: #d4351c; font-weight: 700; }
    .lq-exist { list-style: none; margin: 0 0 10px; padding: 0; }
    .lq-exist > li { display: flex; align-items: center; gap: 10px; padding: 6px 8px; border: 1px solid #e6e8ec; border-radius: 4px; background: #f7f8fa; margin-bottom: 6px; }
    .lq-exist .fn { flex: 1; min-width: 0; }
    .lq-ro { white-space: pre-wrap; word-break: break-all; min-height: 60px; padding: 8px; background: #f7f8fa; border: 1px solid #e6e8ec; border-radius: 4px; line-height: 1.6; }
    @media (max-width: 1024px) {
      .lq-ide-shell { grid-template-columns: 1fr; }
      .lq-ide-main { border-right: 0; border-bottom: 1px solid #d1d3d8; }
      .lq-ide-right { min-height: 0; }
    }
    @media (max-width: 768px) {
      .lq-ide-head { align-items: flex-start; flex-direction: column; }
      .lq-ide-state { align-self: flex-start; }
      .lq-ide-main .ide-context-pane { padding: 18px; }
      .lq-ide-main .ide-form-actions { justify-content: flex-start; flex-wrap: wrap; }
      .lq-ide-main .ide-form-row.cols { flex-direction: column; gap: 0; }
    }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <c:set var="actUrl" value="${mode eq 'update' ? '/rlms/lawquest/lawQuestUpdateDo.do' : '/rlms/lawquest/lawQuestInsertDo.do'}"/>

  <div class="lq-ide-page">
    <div class="lq-ide-head">
      <div>
        <span class="lq-ide-kicker">법령질의 / 법률자문</span>
        <h1>법령질의 <c:choose><c:when test="${mode eq 'update'}">수정·회신</c:when><c:otherwise>등록</c:otherwise></c:choose></h1>
      </div>
      <span class="lq-ide-state">${mode eq 'update' ? '수정' : '신규 작성'}</span>
    </div>

    <form id="lqForm" method="post" enctype="multipart/form-data" action="<c:url value='${actUrl}'/>" class="krds-form">
      <c:if test="${mode eq 'update'}"><input type="hidden" name="no" value="${info.no}"/></c:if>

      <div class="lq-ide-shell">
        <main class="rlms-ide-main lq-ide-main">
          <div class="ide-context-pane">
            <div class="ide-prov-head">
              <h2>법률자문 정보</h2>
              <span class="ide-prov-status ${mode eq 'update' ? 'exist' : 'new'}">${mode eq 'update' ? '수정' : '등록'}</span>
            </div>

            <div class="ide-form-row">
              <label for="subject">제목 <span class="lq-req">*</span></label>
              <input type="text" id="subject" name="subject" class="krds-input" style="width:100%"
                     value="<c:out value='${info.subject}'/>" required maxlength="200"/>
            </div>

            <div class="ide-form-row cols">
              <div class="col">
                <label for="year">작성연도 <span style="font-weight:400;color:#8a8f99;font-size:.85em;">(의뢰일자 선택 시 자동)</span></label>
                <input type="text" id="year" name="year" class="krds-input"
                       value="<c:out value='${info.year}'/>" maxlength="4" placeholder="예: 2026"/>
              </div>
              <div class="col">
                <label for="type">자문유형 <span class="lq-req">*</span></label>
                <select id="type" name="type" class="krds-select" required>
                  <option value="">선택</option>
                  <option value="일반" <c:if test="${info.type eq '일반'}">selected</c:if>>일반</option>
                  <option value="개발" <c:if test="${info.type eq '개발'}">selected</c:if>>개발</option>
                  <option value="비축" <c:if test="${info.type eq '비축'}">selected</c:if>>비축</option>
                  <option value="건설" <c:if test="${info.type eq '건설'}">selected</c:if>>건설</option>
                </select>
              </div>
            </div>

            <div class="ide-form-row cols">
              <div class="col">
                <label for="sosok">의뢰부서</label>
                <input type="text" id="sosok" name="sosok" class="krds-input" value="<c:out value='${info.sosok}'/>" maxlength="30"/>
              </div>
              <div class="col">
                <label for="gigwan">자문기관</label>
                <input type="text" id="gigwan" name="gigwan" class="krds-input" value="<c:out value='${info.gigwan}'/>" maxlength="30"/>
              </div>
            </div>

            <div class="ide-form-row cols">
              <div class="col">
                <label for="lawer">변호사</label>
                <input type="text" id="lawer" name="lawer" class="krds-input" value="<c:out value='${info.lawer}'/>" maxlength="50"/>
              </div>
              <div class="col">
                <label for="gumaek">자문금액(원)</label>
                <input type="number" id="gumaek" name="gumaek" class="krds-input" value="${info.gumaek}" min="0" step="1"/>
              </div>
            </div>

            <div class="ide-form-row cols">
              <div class="col">
                <label for="ilja1Picker">의뢰일자</label>
                <input type="date" id="ilja1Picker" class="krds-input" onchange="lqSyncDate('ilja1')"/>
                <input type="hidden" name="ilja1" id="ilja1" value="<c:out value='${info.ilja1}'/>"/>
              </div>
              <div class="col">
                <label for="ilja2Picker">회신일자</label>
                <input type="date" id="ilja2Picker" class="krds-input" onchange="lqSyncDate('ilja2')"/>
                <input type="hidden" name="ilja2" id="ilja2" value="<c:out value='${info.ilja2}'/>"/>
              </div>
            </div>

            <div class="ide-form-row cols">
              <div class="col">
                <%-- 예산은 금액 항목 — 자문금액과 같은 숫자 입력으로 통일 (고객 테스트 2026-07-29:
                     "예산 필드에 텍스트가 들어갈 수 있는게 맞는건지?"). 컬럼은 레거시 VARCHAR2 라
                     타입은 그대로 두고 화면에서 숫자만 받는다. --%>
                <label for="buget">예산(원)</label>
                <input type="number" id="buget" name="buget" class="krds-input"
                       value="<c:out value='${info.buget}'/>" min="0" step="1"
                       inputmode="numeric"/>
              </div>
              <div class="col">
                <label for="publicYn">공개구분</label>
                <select id="publicYn" name="publicYn" class="krds-select">
                  <option value="1" <c:if test="${info.publicYn eq '1'}">selected</c:if>>공개</option>
                  <option value="2" <c:if test="${info.publicYn eq '2' or empty info.publicYn}">selected</c:if>>비공개</option>
                </select>
              </div>
            </div>

            <div class="ide-form-row">
              <label for="questCon">질의내용</label>
              <textarea id="questCon" name="questCon" class="krds-input" rows="6" style="width:100%"><c:out value="${info.questCon}"/></textarea>
            </div>

            <div class="ide-form-row">
              <label for="respoCon">회신내용</label>
              <c:choose>
                <c:when test="${answerAdmin}">
                  <textarea id="respoCon" name="respoCon" class="krds-input" rows="6" style="width:100%"><c:out value="${info.respoCon}"/></textarea>
                </c:when>
                <c:otherwise>
                  <div class="lq-ro" id="respoRo"><c:out value="${info.respoCon}"/></div>
                  <p style="margin:6px 0 0;color:#8a8f99;font-size:.9em;">회신은 답변권한자만 작성할 수 있습니다.</p>
                </c:otherwise>
              </c:choose>
            </div>

            <div class="ide-form-row">
              <label>첨부파일 <span style="font-weight:400;color:#8a8f99;font-size:.9em;">(최대 3개)</span></label>

              <c:if test="${mode eq 'update' and not empty attachList}">
                <ul class="lq-exist">
                  <c:forEach var="a" items="${attachList}">
                    <li>
                      <a class="fn" href="<c:url value='/rlms/related/attachDownload.do'/>?attNo=${a.attNo}">&#128206; <c:out value="${a.name}"/></a>
                      <button type="button" class="krds-btn danger small" onclick="fnFileDel(${a.attNo})">삭제</button>
                    </li>
                  </c:forEach>
                </ul>
              </c:if>

              <%-- KRDS file-upload (component_09_04) — 규정편집 첨부 컴포넌트 재사용 --%>
              <div class="krds-file-upload">
                <div class="ide-file-drop" id="lqFileDrop">
                  <input type="file" id="lqFileInput" name="files" class="ide-file-native" multiple/>
                  <span class="txt">파일을 여기로 끌어다 놓거나 <strong>파일 선택</strong></span>
                </div>
                <div class="file-list">
                  <div class="total" id="lqFileTotal" style="display:none;">총 <span class="current">0</span>개</div>
                  <ul id="lqFileSelList" class="upload-list"></ul>
                </div>
              </div>
            </div>

            <div class="ide-form-actions">
              <a href="<c:url value='/rlms/lawquest/lawQuestList.do'/>" class="krds-btn secondary medium">목록</a>
              <button type="submit" class="krds-btn primary medium">저장</button>
            </div>
          </div>
        </main>

        <aside class="rlms-ide-right lq-ide-right">
          <h3 class="ide-related-tit">법령질의 작업정보</h3>
          <div class="lq-side-block">
            <span class="lq-side-label">상태</span>
            <p class="lq-side-text">
              <c:choose><c:when test="${mode eq 'update'}">기존 법률자문 의뢰를 수정·회신합니다.</c:when>
              <c:otherwise>새 법률자문 의뢰를 등록합니다.</c:otherwise></c:choose>
            </p>
          </div>
          <div class="lq-side-block">
            <span class="lq-side-label">문서번호</span>
            <p class="lq-side-text"><c:choose><c:when test="${mode eq 'update'}">No. ${info.no}</c:when><c:otherwise>저장 시 자동으로 발급됩니다.</c:otherwise></c:choose></p>
          </div>
          <div class="lq-side-block">
            <span class="lq-side-label">회신 권한</span>
            <p class="lq-side-text"><c:choose><c:when test="${answerAdmin}">회신(답변)을 작성할 수 있습니다.</c:when><c:otherwise>회신은 답변권한자만 작성합니다.</c:otherwise></c:choose></p>
          </div>
        </aside>
      </div>
    </form>
  </div>

  <c:if test="${mode eq 'update'}">
    <form id="fileDelForm" method="post" action="<c:url value='/rlms/lawquest/lawQuestFileDeleteDo.do'/>">
      <input type="hidden" name="no" value="${info.no}"/>
      <input type="hidden" name="attNo" id="fileDelAttNo"/>
    </form>
  </c:if>

  <script>
    $('#lqForm').on('submit', function() {
      if (window.CKEDITOR) { for (var k in CKEDITOR.instances) { try { CKEDITOR.instances[k].updateElement(); } catch (e) {} } }
      var s = $('[name=subject]').val().trim(), t = $('[name=type]').val();
      if (!s) { alert('제목을 입력하세요.'); return false; }
      if (!t) { alert('자문유형을 선택하세요.'); return false; }
      // 작성연도(YEAR NOT NULL) 보호: 비어있으면 의뢰일자에서 도출, 둘 다 없으면 차단
      var yf = document.getElementById('year');
      var y = (yf.value || '').trim();
      if (!y) {
        var d = (document.getElementById('ilja1').value || '').trim();
        if (/^\d{8}$/.test(d)) { y = d.slice(0, 4); yf.value = y; }
      }
      if (!y) { alert('작성연도 또는 의뢰일자를 입력하세요.'); return false; }
      return true;
    });
    function fnFileDel(attNo) {
      if (!confirm('첨부파일을 삭제하시겠습니까?')) return;
      document.getElementById('fileDelAttNo').value = attNo;
      document.getElementById('fileDelForm').submit();
    }

    // ── 일자 = date 피커(표시) ↔ hidden(YYYYMMDD 저장) 동기화 ──
    function lqInitDate(name) {
      var hid = document.getElementById(name), pk = document.getElementById(name + 'Picker');
      if (!hid || !pk) return;
      var v = (hid.value || '').trim();
      if (/^\d{8}$/.test(v)) pk.value = v.slice(0,4) + '-' + v.slice(4,6) + '-' + v.slice(6,8); // 유효 8자리만 표시
    }
    function lqSyncDate(name) {
      var hid = document.getElementById(name), pk = document.getElementById(name + 'Picker');
      if (hid && pk) hid.value = pk.value ? pk.value.replace(/-/g, '') : '';   // 선택 시 YYYYMMDD 로 저장
      if (name === 'ilja1' && pk && pk.value) {       // 의뢰일자 → 작성연도 자동 채움(편집 가능)
        var yf = document.getElementById('year');
        if (yf) yf.value = pk.value.slice(0, 4);
      }
    }
    lqInitDate('ilja1'); lqInitDate('ilja2');

    // ── 질의/회신 = CKEditor (기존 평문은 pbBodyToHtml 로 안전 변환) ──
    function lqPbToHtml(s) {
      s = s || '';
      if (!/<[a-z!\/][\s\S]*>/i.test(s)) {
        s = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
             .replace(/\r\n|\r/g, '\n').replace(/^\n+|\n+$/g, '').replace(/\n/g, '<br>');
      }
      return s;
    }
    function lqCkCfg() {
      return { height: 240, language: 'ko', removePlugins: 'elementspath',
        entities: false, entities_latin: false, basicEntities: true,
        toolbar: [
          { name: 'basic', items: ['Bold','Italic','Underline','Strike','RemoveFormat'] },
          { name: 'para',  items: ['NumberedList','BulletedList','-','Outdent','Indent','-','Blockquote'] },
          { name: 'insert',items: ['Table','HorizontalRule','SpecialChar'] },
          { name: 'clip',  items: ['PasteText','PasteFromWord','-','Undo','Redo'] },
          { name: 'tools', items: ['Maximize','Source'] }
        ] };
    }
    if (window.CKEDITOR) {
      ['questCon','respoCon'].forEach(function(id) {
        var el = document.getElementById(id);
        if (!el || el.tagName !== 'TEXTAREA') return;   // respoCon 은 답변권한자만 textarea
        el.value = lqPbToHtml(el.value);                // 레거시 평문 → HTML(줄바꿈 보존)
        try { CKEDITOR.replace(id, lqCkCfg()); } catch (e) {}
      });
      var ro = document.getElementById('respoRo');       // 비답변자: 회신 읽기전용 HTML 렌더
      if (ro) ro.innerHTML = lqPbToHtml(ro.textContent);
    }

    // ── 첨부 컴포넌트(krds-file-upload) — 규정편집 패턴: 미리보기/삭제/드래그앤드롭/개수 ──
    (function() {
      var input = document.getElementById('lqFileInput');
      var drop  = document.getElementById('lqFileDrop');
      var list  = document.getElementById('lqFileSelList');
      var total = document.getElementById('lqFileTotal');
      if (!input) return;
      function fmt(b) { if (b == null) return ''; if (b < 1024) return b + ' B'; if (b < 1048576) return (b/1024).toFixed(1) + ' KB'; return (b/1048576).toFixed(1) + ' MB'; }
      function esc(s) { return (s == null ? '' : String(s)).replace(/[&<>"]/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]; }); }
      var warned = false;
      function render() {
        var files = input.files || [];
        list.innerHTML = '';
        for (var i = 0; i < files.length; i++) {
          var f = files[i];
          var li = document.createElement('li');
          li.innerHTML = '<div class="file-info"><span class="file-name">' + esc(f.name)
            + ' <span class="fs">' + fmt(f.size) + '</span></span>'
            + '<div class="btn-wrap"><button type="button" class="upload-delete-btn" data-idx="' + i + '" title="삭제">삭제</button></div></div>';
          list.appendChild(li);
        }
        if (total) { total.style.display = files.length ? '' : 'none'; total.querySelector('.current').textContent = files.length; }
        if (files.length > 3 && !warned) { warned = true; alert('첨부는 최대 3개까지만 저장됩니다. 앞에서부터 3개만 등록됩니다.'); }
        if (files.length <= 3) warned = false;
      }
      input.addEventListener('change', render);
      list.addEventListener('click', function(e) {
        var btn = e.target.closest ? e.target.closest('.upload-delete-btn') : null;
        if (!btn) return;
        var idx = parseInt(btn.getAttribute('data-idx'), 10);
        try {
          var dt = new DataTransfer();
          for (var i = 0; i < input.files.length; i++) if (i !== idx) dt.items.add(input.files[i]);
          input.files = dt.files;
        } catch (err) { input.value = ''; }
        render();
      });
      ['dragover','dragenter'].forEach(function(ev){ drop.addEventListener(ev, function(e){ e.preventDefault(); drop.classList.add('active'); }); });
      ['dragleave','dragend'].forEach(function(ev){ drop.addEventListener(ev, function(){ drop.classList.remove('active'); }); });
      drop.addEventListener('drop', function(e) {
        e.preventDefault(); drop.classList.remove('active');
        if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length) {
          try { input.files = e.dataTransfer.files; } catch (err) {}
          render();
        }
      });
    })();
  </script>
</lay:layout>
