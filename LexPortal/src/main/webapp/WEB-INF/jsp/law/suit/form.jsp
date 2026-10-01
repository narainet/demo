<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/suit/form.jsp
  소송 등록/수정 공용 폼 (LAW_MODULE_DESIGN.md §7.1).
   - 본체 단일 폼 + 서브그리드 4종(당사자/사건토지/수행자/진행상황) — 저장 시 hidden JSON 으로 일괄 전송.
   - 신규 등록 시 [원심 사건 연결] = 사건 검색 모달(§4.5 — FIRST_SUIT_ID 승계 + 공통 필드 프리필).
   - 주민번호는 선택 입력·저장 후 재표시하지 않음(마스킹) — 미입력이면 기존 값 유지(§4.4).
   - KRDS 정본 폼 패턴(규정관리 동일): 본체 필드=table.tbl-detail(th 라벨/td 입력, 2열), 서브그리드=krds 톤 편집표.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle"><c:choose><c:when test="${mode eq 'edit'}">소송 수정</c:when><c:otherwise>소송 등록</c:otherwise></c:choose></c:set>
<c:set var="pageHead">
  
  <style>
    /* 본체 입력 셀 좌측정렬 + 컨트롤 폭 */
    #suitForm table.tbl-detail td { text-align: left; }
    #suitForm table.tbl-detail td .krds-input,
    #suitForm table.tbl-detail td .krds-select { width: 100%; box-sizing: border-box; }
    #suitForm .field-row { display: flex; gap: 6px; align-items: center; }
    /* 섹션 제목 (KRDS 톤) */
    .law-sec-tit { margin: 24px 0 6px; padding-bottom: 6px; border-bottom: 2px solid #1f3974;
                   font-size: 1.05em; font-weight: 700; color: #1f3974; }
    /* 서브그리드(편집표) — krds 헤더 톤 + 조밀 셀 */
    .law-grid { width: 100%; border-collapse: collapse; margin: 6px 0 4px; background: #fff; }
    .law-grid thead th { padding: 8px 8px; background: #f0f2f5; color: #1f3974; font-weight: 600;
                         font-size: 0.9em; border-top: 2px solid #1f3974; border-bottom: 1px solid #d1d3d8; }
    .law-grid tbody td { padding: 5px 6px; border-bottom: 1px solid #e0e2e6; vertical-align: middle; }
    .law-grid tbody input, .law-grid tbody select { width: 100%; box-sizing: border-box; height: 40px;
                         border: 1px solid #c4c6cd; border-radius: 6px; padding: 0 10px; font-size: 14px; background-color: #fff; }
    .law-grid tbody select { -webkit-appearance: none; appearance: none; padding: 0 28px 0 10px;
                         background-image: url("data:image/svg+xml;charset=utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath d='M1 1l5 5 5-5' fill='none' stroke='%23555' stroke-width='1.8' stroke-linecap='round'/%3E%3C/svg%3E");
                         background-repeat: no-repeat; background-position: right 9px center; background-size: 10px; }
    .law-grid tbody input:focus, .law-grid tbody select:focus { outline: none; border-color: #2f6bd8; box-shadow: 0 0 0 2px rgba(47,107,216,.15); }
    .law-sub-head { display: flex; justify-content: space-between; align-items: center; margin-top: 18px; }
    .law-sub-head h3 { margin: 0; font-size: 1em; color: #333; }
    .law-note { font-size: 0.82em; color: #888; font-weight: 400; }
    .law-inst-box { background: #eef3fc; border: 1px solid #cdd9f5; border-radius: 6px; padding: 10px 14px; margin: 8px 0; font-size: 0.9em; }
    /* 검색 모달 */
    .law-modal-back { position: fixed; inset: 0; background: rgba(0,0,0,.45); display: none; z-index: 1000; }
    .law-modal { position: fixed; top: 50%; left: 50%; transform: translate(-50%,-50%); background: #fff; border-radius: 12px;
                 padding: 24px 28px; width: 680px; max-width: calc(94vw / var(--rlms-zoom, 1)); display: none; z-index: 1001; box-shadow: 0 8px 30px rgba(0,0,0,.2); }
    .law-modal h2 { margin: 0 0 14px; font-size: 1.15em; color: #1f3974; }
    .law-modal .mod-grid { max-height: 340px; overflow-y: auto; margin-top: 10px; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1><c:choose><c:when test="${mode eq 'edit'}">소송 수정</c:when><c:otherwise>소송 등록</c:otherwise></c:choose></h1>
    <p class="page-desc">사건 기본정보와 당사자·토지·수행자·진행상황을 입력합니다. 저장 시 한 번에 반영됩니다.</p>
  </div>

  <c:if test="${not empty message}">
    <script>alert('<c:out value="${message}"/>');</script>
  </c:if>

  <form id="suitForm" class="krds-form" action="<c:url value='/law/suit/save.do'/>" method="post">
    <input type="hidden" name="suitId" value="<c:out value='${suit.suitId}'/>"/>
    <input type="hidden" name="firstSuitId" id="firstSuitId" value="<c:out value='${suit.firstSuitId}'/>"/>
    <input type="hidden" name="caseNo" id="caseNo" value=""/>
    <input type="hidden" name="courtNm" id="courtNm" value=""/>
    <input type="hidden" name="caseNm" id="caseNm" value=""/>
    <input type="hidden" name="partiesJson" id="partiesJson"/>
    <input type="hidden" name="landsJson" id="landsJson"/>
    <input type="hidden" name="staffsJson" id="staffsJson"/>
    <input type="hidden" name="progsJson" id="progsJson"/>
    <c:if test="${not empty linkReqId}"><input type="hidden" name="reqId" value="<c:out value='${linkReqId}'/>"/></c:if>

    <c:if test="${not empty linkReq}">
      <div class="law-inst-box" style="background:#eef7ee; border-color:#bfe0c0;">
        <b>소송의뢰 연계 등록</b> — 승인된 소송의뢰에서 사건을 생성합니다. 저장 시 이 사건이 해당 의뢰에 연결됩니다.
        <div style="margin-top:6px; font-size:0.95em; color:#333;">
          의뢰부서: <b><c:out value="${linkReq.reqOrgnztNm}" default="-"/></b> ·
          의뢰담당자: <b><c:out value="${linkReq.reqUserNm}" default="${linkReq.reqUserId}"/></b> ·
          경과 <c:out value="${fn:length(linkReq.hists)}"/>건 · 보조자 <c:out value="${fn:length(linkReq.helpers)}"/>명 · 첨부 <c:out value="${fn:length(linkReq.files)}"/>건
        </div>
        <c:if test="${not empty linkReq.helpers}">
          <div style="margin-top:4px; font-size:0.85em; color:#555;">보조자:
            <c:forEach var="hp" items="${linkReq.helpers}" varStatus="s"><c:if test="${not s.first}">, </c:if><c:out value="${hp.helperNm}"/><c:if test="${not empty hp.deptNm}">(<c:out value="${hp.deptNm}"/>)</c:if></c:forEach>
          </div>
        </c:if>
        <div style="margin-top:4px;"><a href="<c:url value='/law/req/view.do'/>?reqId=${linkReqId}" target="_blank">의뢰 상세 보기(경과·첨부 원문) ↗</a></div>
      </div>
    </c:if>

    <c:if test="${mode ne 'edit'}">
      <div class="law-inst-box" id="instBox">
        상급심 사건이면 <button type="button" class="krds-btn small" onclick="fnOpenSearch();">원심 사건 연결</button>
        <span id="instLinked" style="display:none;">— 연결된 원심: <b id="instCaseNo"></b>
          <button type="button" class="krds-btn small" onclick="fnUnlink();">해제</button></span>
        <span class="law-note">원심을 연결하면 같은 사건군으로 묶이고 공통 정보가 채워집니다.</span>
      </div>
    </c:if>

    <%-- ── 기본정보 ── --%>
    <h3 class="law-sec-tit">기본정보</h3>
    <table class="krds-table tbl-detail">
      <colgroup><col style="width:15%"/><col style="width:35%"/><col style="width:15%"/><col style="width:35%"/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label required" for="caseKindCd">소송구분</label></th>
          <td>
            <select id="caseKindCd" name="caseKindCd" class="krds-select" required>
              <option value="">선택</option>
              <c:forEach var="cd" items="${caseKinds}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.caseKindCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
            </select>
          </td>
          <th scope="row"><label class="form-label required" for="instanceCd">심급</label></th>
          <td>
            <select id="instanceCd" name="instanceCd" class="krds-select" required>
              <option value="">선택</option>
              <c:forEach var="cd" items="${instances}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.instanceCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
            </select>
          </td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="itptKindCd">제·피소구분</label></th>
          <td>
            <select id="itptKindCd" name="itptKindCd" class="krds-select">
              <option value="">선택</option>
              <c:forEach var="cd" items="${itptKinds}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.itptKindCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
            </select>
          </td>
          <th scope="row"><label class="form-label" for="civilCaseCd">사건유형</label></th>
          <td>
            <select id="civilCaseCd" name="civilCaseCd" class="krds-select">
              <option value="">선택</option>
              <c:forEach var="cd" items="${civilCases}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.civilCaseCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
            </select>
          </td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="courtSel">법원</label></th>
          <td>
            <select id="courtSel" name="courtId" class="krds-select" onchange="fnCourtChange();">
              <option value="">직접입력</option>
              <c:forEach var="ct" items="${courts}"><option value="<c:out value='${ct.courtId}'/>" <c:if test="${suit.courtId eq ct.courtId}">selected</c:if>><c:out value="${ct.courtNm}"/></option></c:forEach>
            </select>
            <input type="text" id="courtNmIn" class="krds-input" style="margin-top:6px; display:none;" maxlength="50"
                   placeholder="법원명 직접입력" value="<c:out value='${empty suit.courtId ? suit.courtNm : ""}'/>"/>
          </td>
          <th scope="row"><label class="form-label" for="caseYear">사건번호</label></th>
          <td>
            <div class="field-row">
              <input type="text" id="caseYear" name="caseYear" class="krds-input" style="width:84px; flex:0 0 auto;" inputmode="numeric" maxlength="4" placeholder="연도" value="<c:out value='${suit.caseYear}'/>" oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,4);"/>
              <select id="caseSignCd" name="caseSignCd" class="krds-select" style="width:130px; flex:0 0 auto;">
                <option value="">부호</option>
                <c:forEach var="cd" items="${caseSigns}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.caseSignCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
              </select>
              <input type="text" id="caseSerial" name="caseSerial" class="krds-input" style="flex:1; min-width:0;" maxlength="15" placeholder="일련번호" value="<c:out value='${suit.caseSerial}'/>"/>
            </div>
          </td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="caseNmSel">사건명</label></th>
          <td>
            <select id="caseNmSel" name="caseNmCd" class="krds-select" onchange="fnCaseNmChange();">
              <option value="">선택</option>
              <c:forEach var="cd" items="${caseNms}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.caseNmCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
            </select>
            <input type="text" id="caseNmIn" class="krds-input" style="margin-top:6px; display:none;" maxlength="100"
                   placeholder="사건명 직접입력" value="<c:out value='${not empty suit.caseNm ? suit.caseNm : prefillCaseNm}'/>"/>
          </td>
          <th scope="row"><label class="form-label" for="suitAmt">소가(원)</label></th>
          <td>
            <div class="field-row">
              <input type="number" id="suitAmt" name="suitAmt" class="krds-input" min="0" value="<c:out value='${suit.suitAmt}'/>" style="flex:1;"/>
              <button type="button" class="krds-btn small" style="flex:0 0 auto;" onclick="fnOpenCalc();">계산기</button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>

    <%-- ── 일자 ── --%>
    <h3 class="law-sec-tit">일자</h3>
    <table class="krds-table tbl-detail">
      <colgroup><col style="width:15%"/><col style="width:35%"/><col style="width:15%"/><col style="width:35%"/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label" for="officeReceiptDt">행정청 접수일</label></th>
          <td><input type="date" id="officeReceiptDt" name="officeReceiptDt" class="krds-input" value="<c:out value='${suit.officeReceiptDt}'/>"/></td>
          <th scope="row"><label class="form-label" for="frDt">소제기일</label></th>
          <td><input type="date" id="frDt" name="frDt" class="krds-input" value="<c:out value='${suit.frDt}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="stcDt">선고일</label></th>
          <td><input type="date" id="stcDt" name="stcDt" class="krds-input" value="<c:out value='${suit.stcDt}'/>"/></td>
          <th scope="row"><label class="form-label" for="dcsnDt">확정일</label></th>
          <td><input type="date" id="dcsnDt" name="dcsnDt" class="krds-input" value="<c:out value='${suit.dcsnDt}'/>"/></td>
        </tr>
      </tbody>
    </table>

    <%-- ── 결과 ── --%>
    <h3 class="law-sec-tit">결과</h3>
    <table class="krds-table tbl-detail">
      <colgroup><col style="width:15%"/><col style="width:35%"/><col style="width:15%"/><col style="width:35%"/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label" for="rsltKindCd">소송결과</label></th>
          <td>
            <select id="rsltKindCd" name="rsltKindCd" class="krds-select">
              <option value="">선택</option>
              <c:forEach var="cd" items="${results}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.rsltKindCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
            </select>
          </td>
          <th scope="row"><label class="form-label" for="rsltKindNm">결과 직접입력</label></th>
          <td><input type="text" id="rsltKindNm" name="rsltKindNm" class="krds-input" maxlength="100" value="<c:out value='${suit.rsltKindNm}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="winAmt">승소금액(원)</label></th>
          <td><input type="number" id="winAmt" name="winAmt" class="krds-input" min="0" value="<c:out value='${suit.winAmt}'/>"/></td>
          <th scope="row"><label class="form-label" for="loseAmt">패소금액(원)</label></th>
          <td><input type="number" id="loseAmt" name="loseAmt" class="krds-input" min="0" value="<c:out value='${suit.loseAmt}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="lossCauseCd">패소원인</label></th>
          <td>
            <select id="lossCauseCd" name="lossCauseCd" class="krds-select">
              <option value="">선택</option>
              <c:forEach var="cd" items="${lossCauses}"><option value="<c:out value='${cd.code}'/>" <c:if test="${suit.lossCauseCd eq cd.code}">selected</c:if>><c:out value="${cd.codeNm}"/></option></c:forEach>
            </select>
          </td>
          <th scope="row"><label class="form-label" for="mergeCase">병합사건</label></th>
          <td><input type="text" id="mergeCase" name="mergeCase" class="krds-input" maxlength="150" placeholder="병합사건 번호 나열" value="<c:out value='${suit.mergeCase}'/>"/></td>
        </tr>
      </tbody>
    </table>

    <%-- ── 비용·보수 ── --%>
    <h3 class="law-sec-tit">비용·보수</h3>
    <table class="krds-table tbl-detail">
      <colgroup><col style="width:15%"/><col style="width:35%"/><col style="width:15%"/><col style="width:35%"/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label" for="costFixDt">비용확정결정일</label></th>
          <td><input type="date" id="costFixDt" name="costFixDt" class="krds-input" value="<c:out value='${suit.costFixDt}'/>"/></td>
          <th scope="row"><label class="form-label" for="costFixAmt">비용확정액(원)</label></th>
          <td><input type="number" id="costFixAmt" name="costFixAmt" class="krds-input" min="0" value="<c:out value='${suit.costFixAmt}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="costRcvAmt">비용회수액(원)</label></th>
          <td><input type="number" id="costRcvAmt" name="costRcvAmt" class="krds-input" min="0" value="<c:out value='${suit.costRcvAmt}'/>"/></td>
          <th scope="row"><label class="form-label" for="retainerAmt">착수금(원)</label></th>
          <td><input type="number" id="retainerAmt" name="retainerAmt" class="krds-input" min="0" value="<c:out value='${suit.retainerAmt}'/>"/></td>
        </tr>
        <tr>
          <th scope="row"><label class="form-label" for="successAmt">성공보수(원)</label></th>
          <td><input type="number" id="successAmt" name="successAmt" class="krds-input" min="0" value="<c:out value='${suit.successAmt}'/>"/></td>
          <th scope="row"></th>
          <td></td>
        </tr>
      </tbody>
    </table>

    <%-- ── 특이사항 ── --%>
    <h3 class="law-sec-tit">특이사항</h3>
    <table class="krds-table tbl-detail">
      <colgroup><col style="width:15%"/><col/></colgroup>
      <tbody>
        <tr>
          <th scope="row"><label class="form-label" for="specialDesc">특이사항</label></th>
          <td><textarea id="specialDesc" name="specialDesc" rows="3" class="krds-input" style="width:100%;"><c:out value="${not empty suit.specialDesc ? suit.specialDesc : prefillDesc}"/></textarea></td>
        </tr>
      </tbody>
    </table>

    <%-- ── 서브그리드: 당사자 ── --%>
    <div class="law-sub-head">
      <h3>당사자 <span class="law-note">주민번호는 선택 입력이며 저장 후 마스킹으로만 표시됩니다. 비워두면 기존 값이 유지됩니다.</span></h3>
      <button type="button" class="krds-btn small" onclick="addParty();">행 추가</button>
    </div>
    <table class="law-grid" id="partyTable">
      <thead>
        <tr><th style="width:110px;">구분</th><th>성명(법인명)</th><th style="width:120px;">생년월일</th>
            <th style="width:170px;">주민등록번호</th><th>대리인</th><th style="width:56px;">삭제</th></tr>
      </thead>
      <tbody></tbody>
    </table>

    <%-- ── 서브그리드: 사건토지 ── --%>
    <div class="law-sub-head">
      <h3>사건토지</h3>
      <button type="button" class="krds-btn small" onclick="addLand();">행 추가</button>
    </div>
    <table class="law-grid" id="landTable">
      <thead><tr><th>소재지</th><th style="width:30%;">지번</th><th style="width:56px;">삭제</th></tr></thead>
      <tbody></tbody>
    </table>

    <%-- ── 서브그리드: 소송수행자 ── --%>
    <div class="law-sub-head">
      <h3>소송수행자 <span class="law-note">첫 행이 수행자, 둘째 행부터 보조수행자로 표시됩니다.</span></h3>
      <button type="button" class="krds-btn small" onclick="addStaff();">행 추가</button>
    </div>
    <table class="law-grid" id="staffTable">
      <thead><tr><th style="width:40%;">부서</th><th>성명</th><th style="width:140px;">지정일</th><th style="width:56px;">삭제</th></tr></thead>
      <tbody></tbody>
    </table>

    <%-- ── 서브그리드: 진행상황 ── --%>
    <div class="law-sub-head">
      <h3>진행상황·기일 <span class="law-note">일정관리 달력에 함께 표시됩니다.</span></h3>
      <button type="button" class="krds-btn small" onclick="addProg();">행 추가</button>
    </div>
    <table class="law-grid" id="progTable">
      <thead>
        <tr><th style="width:100px;">종류</th><th style="width:120px;">기일구분</th><th style="width:130px;">일자</th>
            <th style="width:70px;">시각</th><th style="width:120px;">장소</th><th>내용</th>
            <th style="width:80px;">상태</th><th style="width:120px;">결과</th><th style="width:56px;">삭제</th></tr>
      </thead>
      <tbody></tbody>
    </table>

    <div class="btn-area center">
      <button type="button" class="krds-btn primary medium" onclick="fnSubmit();">저장</button>
      <c:choose>
        <c:when test="${mode eq 'edit'}">
          <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/suit/view.do"/>?suitId=<c:out value="${suit.suitId}"/>';">취소</button>
        </c:when>
        <c:otherwise>
          <button type="button" class="krds-btn medium" onclick="location.href='<c:url value="/law/suit/list.do"/>';">취소</button>
        </c:otherwise>
      </c:choose>
    </div>
  </form>

  <%-- 행 템플릿 (select 옵션은 서버 렌더 — JS 는 clone 만) --%>
  <template id="tplParty">
    <tr>
      <td><select data-f="partyType">
        <option value="P">원고</option><option value="D">피고</option><option value="S">보조참가인</option>
      </select></td>
      <td><input type="text" data-f="partyNm" maxlength="60"/><input type="hidden" data-f="partyId"/></td>
      <td><input type="text" data-f="birth" maxlength="8" placeholder="YYMMDD"/></td>
      <td><input type="text" data-f="jumin" maxlength="14" placeholder="선택 입력" autocomplete="off"/></td>
      <td><input type="text" data-f="agentNm" maxlength="30"/></td>
      <td style="text-align:center;"><button type="button" class="krds-btn small" onclick="delRow(this);">삭제</button></td>
    </tr>
  </template>
  <template id="tplLand">
    <tr>
      <td><input type="text" data-f="location" maxlength="80"/></td>
      <td><input type="text" data-f="jibun" maxlength="80"/></td>
      <td style="text-align:center;"><button type="button" class="krds-btn small" onclick="delRow(this);">삭제</button></td>
    </tr>
  </template>
  <template id="tplStaff">
    <tr>
      <td><select data-f="orgnztId">
        <option value="">선택</option>
        <c:forEach var="og" items="${orgnzts}">
          <option value="<c:out value='${og.orgnztId}'/>"><c:out value="${og.orgnztNm}"/></option>
        </c:forEach>
      </select></td>
      <td><input type="text" data-f="staffNm" maxlength="30"/></td>
      <td><input type="date" data-f="assignDt"/></td>
      <td style="text-align:center;"><button type="button" class="krds-btn small" onclick="delRow(this);">삭제</button></td>
    </tr>
  </template>
  <template id="tplProg">
    <tr>
      <td><select data-f="progKindCd">
        <option value="">선택</option>
        <c:forEach var="cd" items="${progKinds}">
          <option value="<c:out value='${cd.code}'/>"><c:out value="${cd.codeNm}"/></option>
        </c:forEach>
      </select></td>
      <td><select data-f="dyprKindCd">
        <option value="">선택</option>
        <c:forEach var="cd" items="${dyprKinds}">
          <option value="<c:out value='${cd.code}'/>"><c:out value="${cd.codeNm}"/></option>
        </c:forEach>
      </select></td>
      <td><input type="date" data-f="progDt"/></td>
      <td><input type="text" data-f="progTm" maxlength="4" placeholder="HHMM"/></td>
      <td><input type="text" data-f="place" maxlength="60"/></td>
      <td><input type="text" data-f="progDesc" maxlength="300"/></td>
      <td><select data-f="statCd">
        <option value="">선택</option>
        <c:forEach var="cd" items="${progStats}">
          <option value="<c:out value='${cd.code}'/>"><c:out value="${cd.codeNm}"/></option>
        </c:forEach>
      </select></td>
      <td><input type="text" data-f="resultDesc" maxlength="300"/></td>
      <td style="text-align:center;"><button type="button" class="krds-btn small" onclick="delRow(this);">삭제</button></td>
    </tr>
  </template>

  <%-- 수정 모드 초기 데이터 (HTML 이스케이프 경유 — JS 에서 JSON.parse) --%>
  <textarea id="initParties" hidden><c:out value="${partiesJsonStr}"/></textarea>
  <textarea id="initLands" hidden><c:out value="${landsJsonStr}"/></textarea>
  <textarea id="initStaffs" hidden><c:out value="${staffsJsonStr}"/></textarea>
  <textarea id="initProgs" hidden><c:out value="${progsJsonStr}"/></textarea>

  <%-- 사건 검색 모달 (원심 연결 — §4.5) --%>
  <div class="law-modal-back" id="searchBack" onclick="fnCloseSearch();"></div>
  <div class="law-modal" id="searchModal" role="dialog" aria-modal="true">
    <h2>원심 사건 검색</h2>
    <div style="display:flex; gap:6px;">
      <input type="text" id="searchKw" class="krds-input" style="flex:1;" placeholder="사건번호 또는 사건명"
             onkeydown="if(event.key==='Enter'){event.preventDefault();fnDoSearch();}"/>
      <button type="button" class="krds-btn primary medium" onclick="fnDoSearch();">검색</button>
      <button type="button" class="krds-btn medium" onclick="fnCloseSearch();">닫기</button>
    </div>
    <div class="mod-grid">
      <table class="law-grid" id="searchResult">
        <thead><tr><th>사건번호</th><th>사건명</th><th>법원</th><th style="width:70px;">심급</th><th style="width:64px;">선택</th></tr></thead>
        <tbody><tr><td colspan="5" style="text-align:center; color:#888;">검색어를 입력하세요.</td></tr></tbody>
      </table>
    </div>
  </div>

  <script>
  // ── 행 템플릿 유틸 ──────────────────────────────────
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
  function addParty(d) { return addRowFrom('tplParty', 'partyTable', d); }
  function addLand(d)  { return addRowFrom('tplLand', 'landTable', d); }
  function addStaff(d) { return addRowFrom('tplStaff', 'staffTable', d); }
  function addProg(d)  { return addRowFrom('tplProg', 'progTable', d); }
  function delRow(btn) { btn.closest('tr').remove(); }

  function collect(tableId) {
    var rows = [];
    document.querySelectorAll('#' + tableId + ' tbody tr').forEach(function (tr) {
      var o = {};
      var hasVal = false;
      tr.querySelectorAll('[data-f]').forEach(function (el) {
        var v = el.value == null ? '' : String(el.value).trim();
        o[el.dataset.f] = v === '' ? null : v;
        if (v !== '' && el.dataset.f !== 'partyType') { hasVal = true; }
      });
      if (hasVal) { rows.push(o); }
    });
    return rows;
  }

  // ── 파생 입력 (법원/사건명 직접입력 토글) ───────────
  function fnCourtChange() {
    var sel = document.getElementById('courtSel');
    document.getElementById('courtNmIn').style.display = sel.value === '' ? '' : 'none';
  }
  function fnCaseNmChange() {
    var sel = document.getElementById('caseNmSel');
    document.getElementById('caseNmIn').style.display = (sel.value === 'S999' || sel.value === '') ? '' : 'none';
  }

  // ── 원심 연결 (사건 검색 모달) ─────────────────────
  function fnOpenSearch() {
    document.getElementById('searchBack').style.display = 'block';
    document.getElementById('searchModal').style.display = 'block';
    document.getElementById('searchKw').focus();
  }
  function fnCloseSearch() {
    document.getElementById('searchBack').style.display = 'none';
    document.getElementById('searchModal').style.display = 'none';
  }
  function fnDoSearch() {
    var kw = document.getElementById('searchKw').value.trim();
    fetch('<c:url value="/law/suit/searchJson.do"/>?keyword=' + encodeURIComponent(kw),
          { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        var tb = document.querySelector('#searchResult tbody');
        tb.innerHTML = '';
        if (!d.success || !d.list || d.list.length === 0) {
          tb.innerHTML = '<tr><td colspan="5" style="text-align:center; color:#888;">검색 결과가 없습니다.</td></tr>';
          return;
        }
        d.list.forEach(function (s) {
          var tr = document.createElement('tr');
          function tdText(t) { var td = document.createElement('td'); td.textContent = t || '-'; return td; }
          tr.appendChild(tdText(s.caseNo));
          tr.appendChild(tdText(s.caseNm));
          tr.appendChild(tdText(s.courtNm));
          tr.appendChild(tdText(s.instanceNm));
          var td = document.createElement('td');
          td.style.textAlign = 'center';
          var btn = document.createElement('button');
          btn.type = 'button';
          btn.className = 'krds-btn small';
          btn.textContent = '선택';
          btn.addEventListener('click', function () { fnPickOrigin(s); });
          td.appendChild(btn);
          tr.appendChild(td);
          tb.appendChild(tr);
        });
      })
      .catch(function () { alert('검색에 실패했습니다.'); });
  }
  function fnPickOrigin(s) {
    document.getElementById('firstSuitId').value = s.firstSuitId || s.suitId;
    document.getElementById('instCaseNo').textContent = s.caseNo || ('사건 ' + s.suitId);
    document.getElementById('instLinked').style.display = '';
    // 공통 필드 프리필 (§4.5 — 값이 비어 있을 때만)
    function fill(id, v) { var el = document.getElementById(id); if (el && !el.value && v != null) { el.value = v; } }
    fill('caseKindCd', s.caseKindCd);
    fill('civilCaseCd', s.civilCaseCd);
    fill('suitAmt', s.suitAmt);
    var nmSel = document.getElementById('caseNmSel');
    if (!nmSel.value && s.caseNmCd) { nmSel.value = s.caseNmCd; }
    var nmIn = document.getElementById('caseNmIn');
    if (!nmIn.value && s.caseNm) { nmIn.value = s.caseNm; }
    fnCaseNmChange();
    fnCloseSearch();
  }
  function fnUnlink() {
    document.getElementById('firstSuitId').value = '';
    document.getElementById('instLinked').style.display = 'none';
  }

  // ── 저장 ───────────────────────────────────────────
  function fnSubmit() {
    var caseKind = document.getElementById('caseKindCd').value;
    var instance = document.getElementById('instanceCd').value;
    if (!caseKind) { alert('소송구분을 선택하세요.'); return; }
    if (!instance) { alert('심급을 선택하세요.'); return; }

    // 법원명 확정 (select 텍스트 또는 직접입력)
    var courtSel = document.getElementById('courtSel');
    document.getElementById('courtNm').value = courtSel.value === ''
        ? document.getElementById('courtNmIn').value.trim()
        : courtSel.options[courtSel.selectedIndex].text;

    // 사건명 확정
    var nmSel = document.getElementById('caseNmSel');
    var nmIn = document.getElementById('caseNmIn').value.trim();
    document.getElementById('caseNm').value = (nmSel.value === 'S999' || nmSel.value === '')
        ? nmIn : nmSel.options[nmSel.selectedIndex].text;

    // 사건번호 표시 결합 (연도 + 부호명 + 일련)
    var signSel = document.getElementById('caseSignCd');
    var signNm = signSel.value === '' ? '' : signSel.options[signSel.selectedIndex].text;
    document.getElementById('caseNo').value =
        (document.getElementById('caseYear').value.trim() + signNm + document.getElementById('caseSerial').value.trim());

    document.getElementById('partiesJson').value = JSON.stringify(collect('partyTable'));
    document.getElementById('landsJson').value = JSON.stringify(collect('landTable'));
    document.getElementById('staffsJson').value = JSON.stringify(collect('staffTable'));
    document.getElementById('progsJson').value = JSON.stringify(collect('progTable'));

    document.getElementById('suitForm').submit();
  }

  // ── 초기화 ─────────────────────────────────────────
  (function init() {
    function parseInit(id) {
      var t = document.getElementById(id).value.trim();
      if (!t) { return []; }
      try { return JSON.parse(t) || []; } catch (e) { return []; }
    }
    var parties = parseInit('initParties');
    var lands = parseInit('initLands');
    var staffs = parseInit('initStaffs');
    var progs = parseInit('initProgs');
    parties.forEach(function (p) {
      var row = addParty(p);
      if (p.hasJumin) {
        var jm = row.querySelector('[data-f=jumin]');
        jm.placeholder = (p.juminMask || '저장됨') + ' — 변경 시에만 입력';
      }
    });
    lands.forEach(addLand);
    staffs.forEach(function (s) { var r = addStaff(s); if (s.orgnztId) { r.querySelector('[data-f=orgnztId]').value = s.orgnztId; } });
    progs.forEach(addProg);
    if (parties.length === 0) { addParty({ partyType: 'P' }); addParty({ partyType: 'D' }); }
    if (staffs.length === 0) { addStaff(); }
    fnCourtChange();
    fnCaseNmChange();
    <c:if test="${mode eq 'edit' and not empty suit.caseNm and empty suit.caseNmCd}">
    document.getElementById('caseNmIn').value = '<c:out value="${suit.caseNm}"/>';
    </c:if>
  })();
  </script>

  <%-- 소송비용 계산기 모달은 mgr 데코레이터가 전역 포함(2026-08-06) — 화면별 include 제거. [계산기] 버튼은 그대로 fnOpenCalc() 호출 --%>
</lay:layout>
