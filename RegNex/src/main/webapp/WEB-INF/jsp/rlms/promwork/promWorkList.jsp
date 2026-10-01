<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/promwork/promWorkList.jsp

  규정 승인 워크플로 — 작업승인관리 목록 화면 (PGM-001-01-09). KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ page import="java.util.List" %>
<%@ page import="egovframework.com.cmm.util.EgovUserDetailsHelper" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 승인/반려 버튼은 승인권한(APPROVER/ADMIN)에게만 노출 — URL 층 L4·컨트롤러 assertApprover 와
     동일 기준 명시 열거(2026-07-08 사용자 확정). EDITOR 는 목록 열람만(L3). --%>
<%
  List<String> _pwlAuths = EgovUserDetailsHelper.getAuthorities();
  boolean _pwlCanApprove = _pwlAuths != null
      && (_pwlAuths.contains("ROLE_ADMIN") || _pwlAuths.contains("ROLE_APPROVER"));
  pageContext.setAttribute("pwlCanApprove", _pwlCanApprove);
%>
<c:set var="pageTitle">작업승인관리</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <style>
    /* 결재 열 (2026-07-30 개편) — 칩 5개 2줄이 가로·세로를 크게 먹던 것을 한 줄로.
       '이력' 열도 [⋯] 메뉴로 흡수해 열 하나를 없앴다. (고객 테스트 2026-07-29)
       2026-07-31: [내용]을 기본 버튼으로 승격(결재 판단의 첫 단계라 숨기지 않는다),
       [⋯]에는 비교/편집/이력만 남김. 열람지정은 별도 열로 분리. */
    .pwl-actions { display:flex; gap:4px; align-items:center; justify-content:center; flex-wrap:nowrap; }
    /* a 태그에도 그대로 쓴다(열람지정 칸 [현황] 링크) — 밑줄 제거·inline-block 포함 */
    .pwl-btn { font-size:12px; padding:3px 10px; border-radius:6px; border:1px solid #c2cee0;
               background:#fff; color:#1f3974; cursor:pointer; line-height:1.5; white-space:nowrap;
               text-decoration:none; display:inline-block; }
    .pwl-btn:hover { background:#eef4fe; }
    .pwl-btn.kebab { padding:3px 8px; font-weight:700; letter-spacing:1px; }
    /* 드롭다운은 position:fixed + JS 좌표 배치 — 테이블 셀 안에 absolute 로 두면 잘리거나 겹친다 */
    .pwl-menu { position:fixed; z-index:1200; min-width:132px; background:#fff; border:1px solid #c2cee0;
                border-radius:8px; box-shadow:0 8px 24px rgba(15,23,42,.18); padding:4px; display:none; }
    .pwl-menu button { display:block; width:100%; text-align:left; border:0; background:none; cursor:pointer;
                       font-size:13px; padding:7px 10px; border-radius:6px; color:#1f3974; white-space:nowrap; }
    .pwl-menu button:hover { background:#eef4fe; }
    .pwl-btn.approve { background:#1f3974; border-color:#1f3974; color:#fff; }
    .pwl-btn.approve:hover { background:#163063; }
    .pwl-btn.reject { background:#fff; border-color:#e03131; color:#c92a2a; }
    .pwl-btn.reject:hover { background:#ffe3e3; }
    /* 사유 열 — 말줄임 + 전체는 title 툴팁 (승인 판단 재료를 목록에서 바로, 2026-07-09) */
    .pwl-reason { max-width:200px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; color:#444; }
    /* 열람지정 열 (2026-07-31) — 결재 칸에 끼어 있던 버튼을 독립 열로 분리.
       행마다 있고/없고가 갈려 결재 칸 폭이 들쭉날쭉하던 것을 없애고, 지정 여부를 한눈에 읽게 한다. */
    .pwl-duty { text-align:center; white-space:nowrap; }
    .pwl-btn.duty-on { background:#eef4fe; border-color:#1f3974; color:#1f3974; font-weight:600; }
    .pwl-dash { color:#b6c0cf; }
    /* 필수 열람 지정 모달 (2026-07-28) — 승인완료 회차의 열람 의무 대상/기한 지정 */
    .rdm-modal { position:fixed; inset:0; background:rgba(15,23,42,.45); z-index:1000;
                 display:flex; align-items:center; justify-content:center; }
    .rdm-box { background:#fff; border-radius:12px; width:560px; max-width:94vw; max-height:88vh;
               display:flex; flex-direction:column; box-shadow:0 12px 40px rgba(0,0,0,.25); }
    .rdm-head { display:flex; align-items:center; justify-content:space-between;
                padding:14px 18px; border-bottom:1px solid #e2e8f0; }
    .rdm-head h3 { margin:0; font-size:17px; }
    .rdm-x { border:0; background:none; font-size:22px; cursor:pointer; color:#64748b; line-height:1; }
    .rdm-body { padding:14px 18px; overflow-y:auto; }
    .rdm-title { margin:0 0 10px; font-weight:600; color:#1f3974; }
    .rdm-row { display:flex; align-items:center; gap:10px; margin:8px 0; flex-wrap:wrap; }
    .rdm-row label { display:flex; align-items:center; gap:4px; }
    .rdm-search select { height:32px; border:1px solid #c2cee0; border-radius:6px; padding:0 6px; }
    .rdm-search input[type=text] { flex:1; height:32px; border:1px solid #c2cee0; border-radius:6px; padding:0 8px; }
    .rdm-result { max-height:150px; overflow-y:auto; border:1px solid #e2e8f0; border-radius:6px;
                  margin:6px 0; display:none; }
    .rdm-result a { display:block; padding:6px 10px; font-size:13px; color:#1e293b; text-decoration:none; }
    .rdm-result a:hover { background:#eef4fe; }
    .rdm-result .empty { padding:8px 10px; color:#94a3b8; font-size:13px; }
    .rdm-tgts { margin:6px 0; font-size:13px; }
    .rdm-tgts td, .rdm-tgts th { padding:5px 8px; }
    .rdm-tgts .ty { width:64px; text-align:center; color:#475569; }
    .rdm-tgts .del { width:40px; text-align:center; }
    .rdm-empty { color:#94a3b8; font-size:13px; padding:6px 2px; }
    .rdm-meta { margin:8px 0 0; font-size:12px; color:#64748b; }
    .rdm-foot { display:flex; gap:6px; align-items:center; padding:12px 18px; border-top:1px solid #e2e8f0; }
    .rdm-foot .sp { flex:1; }
    .rdm-due input[type=date] { height:32px; border:1px solid #c2cee0; border-radius:6px; padding:0 8px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>작업승인관리</h1>
    <p class="page-desc">규정 등록/수정 승인 워크플로를 처리합니다.</p>
  </div>

  <c:if test="${not empty resultMsg}">
    <div class="krds-alert success"><c:out value="${resultMsg}"/></div>
  </c:if>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/promwork/selectPromWorkList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>

    <div class="form-group inline">
      <label class="form-label" for="searchUserNm">신청자</label>
      <div class="form-conts">
        <input type="text" id="searchUserNm" name="searchUserNm" class="krds-input"
               value="<c:out value='${searchVO.searchUserNm}'/>"/>
      </div>

      <label class="form-label" for="st">상태</label>
      <div class="form-conts">
        <%-- URL 엔 ASCII 코드(st)만 노출, 내부 SSTATUS(한글 정본)는 서버에서 매핑(PromWorkStatus).
             옵션 목록도 서버(statusOptions: 코드→라벨)에서 내려받아 단일 원천 유지. --%>
        <select id="st" name="st" class="krds-select">
          <option value="" <c:if test="${empty searchStatusCode}">selected</c:if>>전체</option>
          <c:forEach var="opt" items="${statusOptions}">
            <option value="${opt.key}" <c:if test="${searchStatusCode eq opt.key}">selected</c:if>><c:out value="${opt.value}"/></option>
          </c:forEach>
        </select>
      </div>

      <label class="form-label" for="searchFromDt">기간</label>
      <div class="form-conts">
        <input type="date" id="searchFromDt" name="searchFromDt" class="krds-input"
               value="<c:out value='${searchVO.searchFromDt}'/>"/>
        <span>~</span>
        <input type="date" name="searchToDt" class="krds-input"
               value="<c:out value='${searchVO.searchToDt}'/>"/>
      </div>

      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">규정명</th>
        <th scope="col">분류</th>
        <th scope="col">부서</th>
        <th scope="col">신청자</th>
        <th scope="col">신청일시</th>
        <th scope="col">상태</th>
        <th scope="col">사유</th>
        <%-- '액션' → '결재' (고객 테스트 2026-07-29 용어 요청).
             '이력' 열은 결재 칸의 [⋯] 메뉴로 흡수 — 같은 요청의 "칸을 많이 차지함" 해소. --%>
        <th scope="col">결재</th>
        <%-- 열람지정은 결재(승인/반려)와 성격이 다른 후속 작업이라 별도 열로 분리(2026-07-31). --%>
        <th scope="col">열람지정</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="10" class="empty-row">데이터가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="st">
            <tr>
              <td><c:out value="${row.workNo}"/></td>
              <td><c:out value="${row.promTitle}"/></td>
              <td><c:out value="${row.cateNm}"/></td>
              <td><c:out value="${row.buseoNm}"/></td>
              <td><c:out value="${row.userNm}"/></td>
              <td><c:out value="${row.insDt}"/></td>
              <td><c:out value="${row.status}"/></td>
              <%-- 신청/반려 사유(SREASON) — 쿼리엔 이미 실려오나 미표시였음. 말줄임+툴팁(2026-07-09) --%>
              <td class="pwl-reason" title="<c:out value='${row.reason}'/>"><c:out value="${row.reason}"/></td>
              <td>
                <%-- 결재 판단 버튼 + [내용] 을 기본 노출하고, 나머지 동선(비교/편집/이력)만 [⋯] 옵션 메뉴에 접는다.
                     [내용]은 결재 판단의 첫 단계(본문 확인)라 메뉴 안에 숨기지 않는다(2026-07-31).
                     승인/반려는 해당 회차의 "최신" 워크 행에서만 + 승인권한(pwlCanApprove) 보유자에게만 노출 —
                     이미 후속 처리된 옛 요청 행에 버튼이 남아 중복 승인되는 것 방지 (latestYn = IPROM_NO 별 MAX(IPWRK_NO) 행),
                     EDITOR 가 눌렀다 403 나는 UI 갭 방지. --%>
                <div class="pwl-actions">
                  <c:choose>
                    <c:when test="${pwlCanApprove and row.status eq '승인요청' and row.latestYn eq 'Y'}">
                      <button type="button" class="pwl-btn approve"
                              onclick="fnApprove(${row.workNo}, ${row.promNo});">승인</button>
                      <button type="button" class="pwl-btn reject"
                              onclick="fnReject(${row.workNo}, ${row.promNo});">반려</button>
                    </c:when>
                    <%-- 수정승인/수정반려 폐지(2026-07-20) — 수정권한 워크플로 제거 --%>
                    <c:otherwise><c:if test="${empty row.promNo}"><span class="pwl-dash">-</span></c:if></c:otherwise>
                  </c:choose>
                  <c:if test="${not empty row.promNo}">
                    <button type="button" class="pwl-btn" title="규정 본문(본문/개정문/신구대조)을 새 창으로 봅니다"
                            onclick="fnViewContent(${row.promNo});">내용</button>
                    <button type="button" class="pwl-btn kebab" title="비교·편집·이력"
                            aria-haspopup="true" aria-expanded="false"
                            data-prom="${row.promNo}"
                            data-compare="${row.status eq '승인요청' and row.latestYn eq 'Y' ? 'Y' : 'N'}"
                            onclick="fnToggleRowMenu(this);">&#8943;</button>
                  </c:if>
                </div>
              </td>
              <%-- 열람지정 — 승인완료된 최신 회차에서만 지정 가능(2026-07-28 도입, 2026-07-31 독립 열).
                   지정 있음이면 '지정됨 ✓'(재클릭=수정) + [현황] 으로 그 회차의 열람/숙지 집계로 바로 넘긴다.
                   dutyNo 는 목록 쿼리가 실어온다(DUTY_NO) — 현황 화면이 dutyNo 로 상세를 펼친다. --%>
              <td class="pwl-duty">
                <c:choose>
                  <c:when test="${pwlCanApprove and row.status eq '승인완료' and row.latestYn eq 'Y' and not empty row.promNo}">
                    <div class="pwl-actions">
                      <button type="button" class="pwl-btn<c:if test="${not empty row.dutyNo}"> duty-on</c:if>"
                              data-duty-prom="${row.promNo}"
                              data-duty-title="<c:out value='${row.promTitle}'/>"
                              title="<c:choose><c:when test="${not empty row.dutyNo}">지정된 필수 열람 대상/기한을 수정합니다</c:when><c:otherwise>이 개정 회차의 필수 열람 대상/기한을 지정합니다</c:otherwise></c:choose>"
                              onclick="fnOpenDutyBtn(this);"><c:choose><c:when test="${not empty row.dutyNo}">지정됨 &#10003;</c:when><c:otherwise>지정</c:otherwise></c:choose></button>
                      <c:if test="${not empty row.dutyNo}">
                        <a class="pwl-btn" href="<c:url value='/rlms/readduty/dutyStatus.do'/>?dutyNo=${row.dutyNo}"
                           title="이 회차의 열람/숙지 현황(부서별 집계·개인 매트릭스)으로 이동합니다">현황</a>
                      </c:if>
                    </div>
                  </c:when>
                  <c:otherwise><span class="pwl-dash">-</span></c:otherwise>
                </c:choose>
              </td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <div class="krds-pagination">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

  <form id="actionForm" name="actionForm" method="post">
    <input type="hidden" name="workNo"  id="actWorkNo"/>
    <input type="hidden" name="promNo"  id="actPromNo"/>
    <input type="hidden" name="reason"  id="actReason"/>
  </form>

  <%-- 필수 열람 지정 모달 (2026-07-28) — 승인완료 회차의 열람 의무 대상(전사/부서/개인)·기한 지정.
       승인 직후 dutyPromNo 파라미터로 자동 유도(닫기=건너뛰기), 목록 [열람지정] 버튼으로 수동 진입/수정. --%>
  <div id="rdmModal" class="rdm-modal" style="display:none;" onclick="if(event.target===this)rdmClose();">
    <div class="rdm-box">
      <div class="rdm-head">
        <h3>필수 열람 지정</h3>
        <button type="button" class="rdm-x" onclick="rdmClose();" aria-label="닫기">&times;</button>
      </div>
      <div class="rdm-body">
        <p class="rdm-title" id="rdmPromTitle"></p>
        <div class="rdm-row">
          <label><input type="radio" name="rdmScope" value="ALL" onchange="rdmScopeChange();"> 전사(전 직원)</label>
          <label><input type="radio" name="rdmScope" value="PICK" checked onchange="rdmScopeChange();"> 대상 선택(부서/개인 혼합)</label>
        </div>
        <div id="rdmPickArea">
          <div class="rdm-row rdm-search">
            <select id="rdmTgtTy" aria-label="대상 유형">
              <option value="DEPT">부서</option>
              <option value="USER">개인</option>
            </select>
            <input type="text" id="rdmSearch" placeholder="부서명 / 이름·아이디 검색 (Enter)" autocomplete="off"/>
            <button type="button" class="pwl-btn" onclick="rdmSearch();">검색</button>
          </div>
          <div id="rdmSearchResult" class="rdm-result"></div>
          <table class="rdm-tgts krds-table">
            <thead><tr><th scope="col" class="ty">유형</th><th scope="col">대상</th><th scope="col" class="del"></th></tr></thead>
            <tbody id="rdmTgtBody"></tbody>
          </table>
        </div>
        <div class="rdm-row rdm-due">
          <label for="rdmDueDt">열람 기한(선택)</label>
          <input type="date" id="rdmDueDt"/>
          <span style="color:#94a3b8;font-size:12px;">비우면 무기한 — 기한 경과 시 대상자 홈에 붉게 강조</span>
        </div>
        <p class="rdm-meta" id="rdmMeta"></p>
      </div>
      <div class="rdm-foot">
        <button type="button" id="rdmDelBtn" class="pwl-btn reject" style="display:none" onclick="rdmDelete();">지정 삭제</button>
        <span class="sp"></span>
        <button type="button" class="pwl-btn" onclick="rdmClose();">닫기</button>
        <button type="button" class="pwl-btn approve" onclick="rdmSave();">저장</button>
      </div>
    </div>
  </div>

  <%-- 결재 칸 [⋯] 공용 드롭다운 — 행마다 메뉴를 심으면 DOM 이 커지고 테이블에 잘리므로
       페이지에 하나만 두고 클릭한 버튼 좌표로 옮겨 띄운다. --%>
  <div id="pwlMenu" class="pwl-menu" role="menu"></div>

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }

    /* ── 결재 칸 [⋯] 옵션 메뉴 (2026-07-30) ────────────────────────
       칩 5개가 2줄로 깔려 칸을 크게 먹던 것을 정리 — 결재 버튼만 남기고
       나머지는 이 메뉴로. '이력' 열도 여기로 흡수했다.
       2026-07-31 에 [내용]은 기본 버튼으로 빠져 여기엔 비교/편집/이력만 남는다. */
    var pwlMenuOwner = null;
    function fnCloseRowMenu() {
      var m = document.getElementById('pwlMenu');
      if (m) m.style.display = 'none';
      if (pwlMenuOwner) pwlMenuOwner.setAttribute('aria-expanded', 'false');
      pwlMenuOwner = null;
    }
    function fnToggleRowMenu(btn) {
      var m = document.getElementById('pwlMenu');
      if (!m) return;
      if (pwlMenuOwner === btn) { fnCloseRowMenu(); return; }
      fnCloseRowMenu();

      var promNo = btn.getAttribute('data-prom');
      /* [내용]은 기본 버튼으로 승격(2026-07-31) — 여기엔 나머지 옵션만 남긴다. */
      var items = [];
      if (btn.getAttribute('data-compare') === 'Y') items.push(['비교', 'fnCompare']);
      items.push(['편집', 'fnEditProm'], ['이력', 'fnHistory']);

      m.innerHTML = '';
      items.forEach(function (it) {
        var b = document.createElement('button');
        b.type = 'button';
        b.setAttribute('role', 'menuitem');
        b.textContent = it[0];
        b.onclick = function () { fnCloseRowMenu(); window[it[1]](Number(promNo)); };
        m.appendChild(b);
      });

      /* position:fixed 라 뷰포트 기준 좌표. 아래 공간이 모자라면 버튼 위로 띄운다. */
      m.style.display = 'block';
      var r = btn.getBoundingClientRect();
      var mh = m.offsetHeight, mw = m.offsetWidth;
      var top = (r.bottom + 4 + mh > window.innerHeight) ? (r.top - 4 - mh) : (r.bottom + 4);
      var left = Math.min(r.left, window.innerWidth - mw - 8);
      m.style.top = Math.max(8, top) + 'px';
      m.style.left = Math.max(8, left) + 'px';

      btn.setAttribute('aria-expanded', 'true');
      pwlMenuOwner = btn;
    }
    document.addEventListener('click', function (e) {
      if (!pwlMenuOwner) return;
      if (e.target.closest && (e.target.closest('#pwlMenu') || e.target === pwlMenuOwner)) return;
      fnCloseRowMenu();
    });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') fnCloseRowMenu(); });
    window.addEventListener('resize', fnCloseRowMenu);
    window.addEventListener('scroll', fnCloseRowMenu, true);
    function fnViewContent(promNo) {
      if (!promNo) { alert('연결된 규정이 없습니다.'); return; }
      // 승인자 내용 확인 — 규정 본문 뷰어(본문/개정문/신구대조). 목록 유지 위해 새창.
      window.open('<c:url value="/rlms/fulltext/provisionList.do"/>?promNo=' + promNo,
                  'rlmsPromContent', 'width=1100,height=900,scrollbars=yes,resizable=yes');
    }
    function fnEditProm(promNo) {
      if (!promNo) { alert('연결된 규정이 없습니다.'); return; }
      // 규정 IDE 편집기로 진입(딥링크). 편집중 draft·미승인 회차도 그대로 열림(SEXISTING 검사 없음) →
      // 링크-only 외부참조 규정을 출처 개정에 맞춰 SURL/회차 갱신하는 재진입 동선.
      location.href = '<c:url value="/rlms/prom/editor.do"/>?promNo=' + promNo;
    }
    function fnCompare(promNo) {
      if (!promNo) { alert('연결된 규정이 없습니다.'); return; }
      // 요청 회차 vs 직전 회차 본문 diff — 승인 판단 재료를 목록에서 직결(새창)
      window.open('<c:url value="/rlms/prom/compareProvHtml.do"/>?promNo=' + promNo,
                  'rlmsPromCompare', 'width=1200,height=900,scrollbars=yes,resizable=yes');
    }
    <%-- 반려 사유 필수 — 빈 사유면 편집자 화면에 사유 카드가 안 떠 인지가 끊김(서버도 blank 거부) --%>
    function askReason(msg) {
      while (true) {
        var r = prompt(msg);
        if (r === null) return null;
        if (r.replace(/\s/g, '') !== '') return r;
        alert('반려 사유는 필수입니다.');
      }
    }
    function fnApprove(workNo, promNo) {
      if (!confirm('해당 요청을 승인하시겠습니까?')) return;
      submitAction('<c:url value="/rlms/promwork/approvePromWork.do"/>', workNo, promNo, '');
    }
    function fnReject(workNo, promNo) {
      var reason = askReason('반려 사유를 입력하세요.');
      if (reason === null) return;
      submitAction('<c:url value="/rlms/promwork/rejectPromWork.do"/>', workNo, promNo, reason);
    }
    function fnHistory(promNo) {
      location.href = '<c:url value="/rlms/promwork/selectPromWorkHistory.do"/>?promNo=' + promNo;
    }
    function submitAction(url, workNo, promNo, reason) {
      var f = document.actionForm;
      f.action = url;
      document.getElementById('actWorkNo').value = workNo;
      document.getElementById('actPromNo').value = promNo;
      document.getElementById('actReason').value = reason;
      f.submit();
    }

    /* ── 필수 열람 지정 모달 (2026-07-28) ─────────────────────────────
       승인완료 회차에 열람 의무 대상(전사/부서/개인 혼합)·기한을 지정.
       부서 검색 = 규정편집 buseoListJson 재사용, 개인 검색 = readduty userSearchJson.
       저장은 tgt 반복 파라미터("DEPT:ORGNZT_ID"/"USER:ESNTL_ID") — $.param traditional. */
    var RD_URL = {
      info:    '<c:url value="/rlms/readduty/dutyInfoJson.do"/>',
      save:    '<c:url value="/rlms/readduty/saveDuty.do"/>',
      del:     '<c:url value="/rlms/readduty/deleteDuty.do"/>',
      usearch: '<c:url value="/rlms/readduty/userSearchJson.do"/>',
      bsearch: '<c:url value="/rlms/prom/buseoListJson.do"/>',
      listApr: '<c:url value="/rlms/promwork/selectPromWorkList.do"/>?st=APR'
    };
    var rdmState = { promNo: null, dutyNo: null, tgts: [] };

    function fnOpenDutyBtn(btn) {
      fnOpenDuty($(btn).data('duty-prom'), $(btn).data('duty-title') || '');
    }
    function fnOpenDuty(promNo, title) {
      rdmState = { promNo: promNo, dutyNo: null, tgts: [] };
      $('#rdmPromTitle').text(title || ('회차 #' + promNo));
      $('#rdmDueDt').val('');
      $('input[name=rdmScope][value=PICK]').prop('checked', true);
      $('#rdmSearch').val('');
      $('#rdmSearchResult').hide().empty();
      $('#rdmDelBtn').hide();
      $('#rdmMeta').text('');
      rdmRenderTgts();
      rdmScopeChange();
      $('#rdmModal').css('display', 'flex');
      // 기존 지정 로드 — 있으면 수정 모드(기한/대상 복원 + 삭제 버튼)
      $.getJSON(RD_URL.info, { promNo: promNo }).done(function (res) {
        if (!res || !res.success || !res.duty) return;
        rdmState.dutyNo = res.duty.dutyNo;
        if (res.duty.dueDt && /^\d{8}$/.test(res.duty.dueDt)) {
          $('#rdmDueDt').val(res.duty.dueDt.replace(/^(\d{4})(\d{2})(\d{2})$/, '$1-$2-$3'));
        }
        if (res.duty.allYn === 'Y') {
          $('input[name=rdmScope][value=ALL]').prop('checked', true);
        } else if (res.tgtList) {
          for (var i = 0; i < res.tgtList.length; i++) {
            rdmState.tgts.push({ ty: res.tgtList[i].tgtTy, id: res.tgtList[i].tgtId, nm: res.tgtList[i].tgtNm });
          }
        }
        if (res.duty.insNm) {
          $('#rdmMeta').text('기존 지정: ' + res.duty.insNm + ' · '
            + String(res.duty.insDt || '').replace(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2}).*$/, '$1-$2-$3 $4:$5'));
        }
        $('#rdmDelBtn').show();
        rdmScopeChange();
        rdmRenderTgts();
      });
    }
    function rdmClose() { $('#rdmModal').hide(); }
    function rdmScopeChange() {
      $('#rdmPickArea').toggle($('input[name=rdmScope]:checked').val() !== 'ALL');
    }
    function rdmSearch() {
      var kw = $.trim($('#rdmSearch').val());
      if (!kw) { alert('검색어를 입력하세요.'); return; }
      var $box = $('#rdmSearchResult').show().html('<div class="empty">검색 중…</div>');
      if ($('#rdmTgtTy').val() === 'DEPT') {
        $.getJSON(RD_URL.bsearch, { keyword: kw }).done(function (list) {
          var items = [];
          if (list && list.length) {
            for (var i = 0; i < list.length; i++) {
              items.push({ ty: 'DEPT', id: list[i].orgnztId, nm: (list[i].fullNm || list[i].buseoNm || list[i].orgnztId) });
            }
          }
          rdmRenderResult(items);
        }).fail(function () { $box.html('<div class="empty">검색 실패</div>'); });
      } else {
        $.getJSON(RD_URL.usearch, { keyword: kw }).done(function (res) {
          var items = [], list = (res && res.resultList) || [];
          for (var i = 0; i < list.length; i++) {
            items.push({ ty: 'USER', id: list[i].esntlId,
              nm: list[i].userNm + ' (' + list[i].userId + (list[i].orgnztNm ? ' · ' + list[i].orgnztNm : '') + ')' });
          }
          rdmRenderResult(items);
        }).fail(function () { $box.html('<div class="empty">검색 실패</div>'); });
      }
    }
    function rdmRenderResult(items) {
      var $box = $('#rdmSearchResult').empty().show();
      if (!items.length) { $box.html('<div class="empty">검색 결과가 없습니다.</div>'); return; }
      for (var i = 0; i < items.length; i++) {
        (function (it) {
          $('<a href="#"></a>').text((it.ty === 'DEPT' ? '[부서] ' : '[개인] ') + it.nm)
            .on('click', function (e) { e.preventDefault(); rdmAddTgt(it); })
            .appendTo($box);
        })(items[i]);
      }
    }
    function rdmAddTgt(it) {
      for (var i = 0; i < rdmState.tgts.length; i++) {
        if (rdmState.tgts[i].ty === it.ty && rdmState.tgts[i].id === it.id) { return; }
      }
      rdmState.tgts.push(it);
      rdmRenderTgts();
    }
    function rdmRemoveTgt(idx) { rdmState.tgts.splice(idx, 1); rdmRenderTgts(); }
    function rdmRenderTgts() {
      var $b = $('#rdmTgtBody').empty();
      if (!rdmState.tgts.length) {
        $b.append('<tr><td colspan="3" class="rdm-empty">추가된 대상이 없습니다. 부서/개인을 검색해 추가하세요.</td></tr>');
        return;
      }
      for (var i = 0; i < rdmState.tgts.length; i++) {
        (function (t, idx) {
          var $tr = $('<tr></tr>');
          $tr.append($('<td class="ty"></td>').text(t.ty === 'DEPT' ? '부서' : '개인'));
          $tr.append($('<td></td>').text(t.nm || t.id));
          $tr.append($('<td class="del"></td>').append(
            $('<button type="button" class="pwl-btn" title="제거">&times;</button>')
              .on('click', function () { rdmRemoveTgt(idx); })));
          $b.append($tr);
        })(rdmState.tgts[i], i);
      }
    }
    function rdmSave() {
      var all = $('input[name=rdmScope]:checked').val() === 'ALL';
      if (!all && !rdmState.tgts.length) { alert('열람 대상을 1건 이상 추가하거나 전사를 선택하세요.'); return; }
      var tgtArr = [];
      if (!all) {
        for (var i = 0; i < rdmState.tgts.length; i++) { tgtArr.push(rdmState.tgts[i].ty + ':' + rdmState.tgts[i].id); }
      }
      var data = { promNo: rdmState.promNo, allYn: all ? 'Y' : 'N', dueDt: $('#rdmDueDt').val() || '', tgt: tgtArr };
      $.post(RD_URL.save, $.param(data, true), null, 'json').done(function (res) {
        if (res && res.success) { alert('필수 열람 지정을 저장했습니다.'); location.href = RD_URL.listApr; }
        else { alert((res && res.message) || '저장에 실패했습니다.'); }
      }).fail(function () { alert('저장 요청이 실패했습니다.'); });
    }
    function rdmDelete() {
      if (!rdmState.dutyNo) return;
      if (!confirm('이 회차의 필수 열람 지정을 삭제할까요?\n대상자의 열람/숙지 확인 기록도 함께 삭제됩니다.')) return;
      $.post(RD_URL.del, { dutyNo: rdmState.dutyNo }, null, 'json').done(function (res) {
        if (res && res.success) { alert('지정을 삭제했습니다.'); location.href = RD_URL.listApr; }
        else { alert((res && res.message) || '삭제에 실패했습니다.'); }
      });
    }
    $(function () {
      $('#rdmSearch').on('keydown', function (e) { if (e.which === 13) { e.preventDefault(); rdmSearch(); } });
      // 승인 직후 자동 유도 — dutyPromNo 파라미터로 지정 모달 오픈(닫기=건너뛰기).
      // 파라미터는 즉시 URL 에서 제거해 새로고침 시 재오픈을 막는다.
      var autoProm = '<c:out value="${param.dutyPromNo}"/>';
      if (/^\d+$/.test(autoProm)) {
        if (window.history && history.replaceState) {
          history.replaceState(null, '', location.pathname);
        }
        var $btn = $('.pwl-btn[data-duty-prom="' + autoProm + '"]').first();
        if ($btn.length) { fnOpenDutyBtn($btn[0]); }
        else { fnOpenDuty(parseInt(autoProm, 10), ''); }
      }
    });
  </script>
</lay:layout>
