<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/law/suit/view.jsp
  소송 상세 (LAW_MODULE_DESIGN.md §7.1) — 읽기전용 + [수정][삭제(소프트)][목록].
  사건 허브(문서·비용·선임)는 이후 페이즈에서 이 화면에 탭으로 확장. 결과변경 이력·심급사건은 여기서 표시.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="egovc" uri="/WEB-INF/tlds/egovc.tld" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">소송 상세</c:set>
<c:set var="pageHead">
  
  <style>
    .law-view-grid { display: grid; grid-template-columns: 140px 1fr 140px 1fr; border-top: 2px solid #222; }
    .law-view-grid > div { padding: 9px 12px; border-bottom: 1px solid #e3e3e3; font-size: 14px; }
    .law-view-grid > .k { background: #f7f8fa; color: #444; font-weight: 500; }
    .law-view-grid > .v.span3 { grid-column: 2 / span 3; }
    .law-sec { margin: 26px 0 8px; font-size: 16px; font-weight: 700; }
    .law-sub-table { width: 100%; border-collapse: collapse; }
    .law-sub-table th, .law-sub-table td { border: 1px solid #ddd; padding: 6px 8px; font-size: 13px; }
    .law-sub-table th { background: #f7f8fa; }
    .law-empty { color: #888; text-align: center; padding: 14px 0; }
    .law-btn-bar { margin-top: 26px; display: flex; gap: 8px; justify-content: center; }
    .law-num { text-align: right; }
    .law-now { background: #eef4ff; }
    .law-sec-bar { display:flex; justify-content:space-between; align-items:center; }
    .law-file-link { display:block; font-size:12px; }
    .law-cell-sub { color:#888; font-size:12px; }
    .law-badge { display:inline-block; padding:2px 8px; border-radius:10px; font-size:12px; }
    .law-badge.wait { background:#eef0f3; color:#555; }
    .law-badge.appr { background:#e6f4ea; color:#1a7f37; }
    .law-badge.rjct { background:#fdecec; color:#c5303a; }
    .law-satis-star { color:#f5a623; letter-spacing:1px; }
    .law-star-pick { font-size:30px; letter-spacing:4px; cursor:pointer; user-select:none; color:#d9d9d9; }
    .law-star-pick span.on { color:#f5a623; }
    .law-opinion-item { padding:8px 0; border-bottom:1px dashed #eee; font-size:13px; }
    .law-modal-back { position: fixed; inset:0; background:rgba(0,0,0,.45); display:none; z-index:1000; }
    .law-modal { position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#fff; border-radius:12px;
                 padding:26px 30px; width:480px; max-width:calc(94vw / var(--rlms-zoom, 1)); max-height:calc(88vh / var(--rlms-zoom, 1)); overflow-y:auto; display:none; z-index:1001; box-shadow:0 8px 30px rgba(0,0,0,.2); }
    .law-modal h2 { margin:0 0 16px; font-size:19px; }
    .law-modal .form-row { margin-bottom:12px; }
    .law-modal .form-row label { display:block; font-size:14px; margin-bottom:4px; color:#333; }
    .law-modal .form-row input[type=text], .law-modal .form-row input[type=date],
    .law-modal .form-row select, .law-modal .form-row textarea { width:100%; box-sizing:border-box; }
    .law-modal .modal-btns { margin-top:18px; display:flex; gap:8px; justify-content:flex-end; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>소송 상세</h1>
    <p class="page-desc"><c:out value="${suit.caseNo}"/> <c:out value="${suit.caseNm}"/></p>
  </div>

  <c:if test="${not empty message}">
    <script>alert('<c:out value="${message}"/>');</script>
  </c:if>

  <div class="law-view-grid">
    <div class="k">소송구분</div><div class="v"><c:out value="${suit.caseKindNm}" default="-"/></div>
    <div class="k">심급</div><div class="v"><c:out value="${suit.instanceNm}" default="-"/></div>
    <div class="k">제·피소구분</div><div class="v"><c:out value="${suit.itptKindNm}" default="-"/></div>
    <div class="k">사건유형</div><div class="v"><c:out value="${suit.civilCaseNm}" default="-"/></div>
    <div class="k">법원</div><div class="v"><c:out value="${suit.courtNm}" default="-"/></div>
    <div class="k">사건번호</div><div class="v"><c:out value="${suit.caseNo}" default="-"/></div>
    <div class="k">사건명</div><div class="v"><c:out value="${suit.caseNm}" default="-"/></div>
    <div class="k">소가</div><div class="v"><c:choose><c:when test="${suit.suitAmt != null}"><fmt:formatNumber value="${suit.suitAmt}"/> 원</c:when><c:otherwise>-</c:otherwise></c:choose></div>
    <div class="k">행정청 접수일</div><div class="v"><c:out value="${suit.officeReceiptDt}" default="-"/></div>
    <div class="k">소제기일</div><div class="v"><c:out value="${suit.frDt}" default="-"/></div>
    <div class="k">선고일</div><div class="v"><c:out value="${suit.stcDt}" default="-"/></div>
    <div class="k">확정일</div><div class="v"><c:out value="${suit.dcsnDt}" default="-"/></div>
    <div class="k">소송결과</div><div class="v"><c:out value="${suit.rsltDispNm}" default="-"/></div>
    <div class="k">패소원인</div><div class="v"><c:out value="${suit.lossCauseNm}" default="-"/></div>
    <div class="k">승소금액</div><div class="v"><c:choose><c:when test="${suit.winAmt != null}"><fmt:formatNumber value="${suit.winAmt}"/> 원</c:when><c:otherwise>-</c:otherwise></c:choose></div>
    <div class="k">패소금액</div><div class="v"><c:choose><c:when test="${suit.loseAmt != null}"><fmt:formatNumber value="${suit.loseAmt}"/> 원</c:when><c:otherwise>-</c:otherwise></c:choose></div>
    <div class="k">비용확정결정일</div><div class="v"><c:out value="${suit.costFixDt}" default="-"/></div>
    <div class="k">비용확정액</div><div class="v"><c:choose><c:when test="${suit.costFixAmt != null}"><fmt:formatNumber value="${suit.costFixAmt}"/> 원</c:when><c:otherwise>-</c:otherwise></c:choose></div>
    <div class="k">비용회수액</div><div class="v"><c:choose><c:when test="${suit.costRcvAmt != null}"><fmt:formatNumber value="${suit.costRcvAmt}"/> 원</c:when><c:otherwise>-</c:otherwise></c:choose></div>
    <div class="k">착수금 / 성공보수</div><div class="v">
      <c:choose><c:when test="${suit.retainerAmt != null}"><fmt:formatNumber value="${suit.retainerAmt}"/></c:when><c:otherwise>-</c:otherwise></c:choose>
      /
      <c:choose><c:when test="${suit.successAmt != null}"><fmt:formatNumber value="${suit.successAmt}"/></c:when><c:otherwise>-</c:otherwise></c:choose>
    </div>
    <div class="k">병합사건</div><div class="v span3"><c:out value="${suit.mergeCase}" default="-"/></div>
    <div class="k">특이사항</div><div class="v span3" style="white-space:pre-wrap;"><c:out value="${suit.specialDesc}" default="-"/></div>
  </div>

  <div class="law-sec">당사자</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:110px;">구분</th><th>성명(법인명)</th><th style="width:120px;">생년월일</th>
               <th style="width:160px;">주민등록번호</th><th>대리인</th></tr></thead>
    <tbody>
      <c:forEach var="p" items="${parties}">
        <tr>
          <td><c:choose><c:when test="${p.partyType eq 'P'}">원고</c:when><c:when test="${p.partyType eq 'D'}">피고</c:when><c:otherwise>보조참가인</c:otherwise></c:choose></td>
          <td><c:out value="${p.partyNm}"/></td>
          <td><c:out value="${p.birth}" default="-"/></td>
          <td><c:choose><c:when test="${p.hasJumin}"><c:out value="${p.juminMask}"/></c:when><c:otherwise>-</c:otherwise></c:choose></td>
          <td><c:out value="${p.agentNm}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty parties}"><tr><td colspan="5" class="law-empty">등록된 당사자가 없습니다.</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-sec">사건토지</div>
  <table class="law-sub-table">
    <thead><tr><th>소재지</th><th style="width:30%;">지번</th></tr></thead>
    <tbody>
      <c:forEach var="l" items="${lands}">
        <tr><td><c:out value="${l.location}" default="-"/></td><td><c:out value="${l.jibun}" default="-"/></td></tr>
      </c:forEach>
      <c:if test="${empty lands}"><tr><td colspan="2" class="law-empty">등록된 사건토지가 없습니다.</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-sec">소송수행자</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:70px;">구분</th><th style="width:36%;">부서</th><th>성명</th><th style="width:130px;">지정일</th></tr></thead>
    <tbody>
      <c:forEach var="s" items="${staffs}" varStatus="st">
        <tr>
          <td><c:choose><c:when test="${st.index == 0}">수행자</c:when><c:otherwise>보조</c:otherwise></c:choose></td>
          <td><c:out value="${s.orgnztNm}" default="-"/></td>
          <td><c:out value="${s.staffNm}" default="-"/></td>
          <td><c:out value="${s.assignDt}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty staffs}"><tr><td colspan="4" class="law-empty">등록된 수행자가 없습니다.</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-sec">진행상황·기일</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:90px;">종류</th><th style="width:120px;">기일구분</th><th style="width:110px;">일자</th>
               <th style="width:60px;">시각</th><th style="width:120px;">장소</th><th>내용</th>
               <th style="width:70px;">상태</th><th style="width:140px;">결과</th></tr></thead>
    <tbody>
      <c:forEach var="g" items="${progs}">
        <tr>
          <td><c:out value="${g.progKindNm}" default="-"/></td>
          <td><c:out value="${g.dyprKindNm}" default="-"/></td>
          <td><c:out value="${g.progDt}" default="-"/></td>
          <td><c:out value="${g.progTm}" default="-"/></td>
          <td><c:out value="${g.place}" default="-"/></td>
          <td><c:out value="${g.progDesc}" default="-"/></td>
          <td><c:out value="${g.statNm}" default="-"/></td>
          <td><c:out value="${g.resultDesc}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty progs}"><tr><td colspan="8" class="law-empty">등록된 진행상황이 없습니다.</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-sec">심급사건 (같은 사건군)</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:80px;">심급</th><th>사건번호</th><th>사건명</th><th>법원</th>
               <th style="width:110px;">소제기일</th><th style="width:110px;">선고일</th><th style="width:110px;">결과</th></tr></thead>
    <tbody>
      <c:forEach var="i" items="${instanceSuits}">
        <tr class="${i.suitId eq suit.suitId ? 'law-now' : ''}">
          <td><c:out value="${i.instanceNm}" default="-"/></td>
          <td>
            <c:choose>
              <c:when test="${i.suitId eq suit.suitId}"><c:out value="${i.caseNo}"/> <span style="color:#256ef4;">(현재)</span></c:when>
              <c:otherwise><a href="<c:url value='/law/suit/view.do'/>?suitId=<c:out value='${i.suitId}'/>"><c:out value="${i.caseNo}" default="(사건번호 미입력)"/></a></c:otherwise>
            </c:choose>
          </td>
          <td><c:out value="${i.caseNm}" default="-"/></td>
          <td><c:out value="${i.courtNm}" default="-"/></td>
          <td><c:out value="${i.frDt}" default="-"/></td>
          <td><c:out value="${i.stcDt}" default="-"/></td>
          <td><c:out value="${i.rsltDispNm}" default="-"/></td>
        </tr>
      </c:forEach>
    </tbody>
  </table>

  <div class="law-sec">결과변경 이력</div>
  <table class="law-sub-table">
    <thead><tr><th style="width:60px;">순번</th><th>결과</th><th style="width:120px;">종결일</th><th>비고</th>
               <th style="width:100px;">등록자</th><th style="width:140px;">등록일시</th></tr></thead>
    <tbody>
      <c:forEach var="h" items="${rsltHists}">
        <tr>
          <td><c:out value="${h.histSeq}"/></td>
          <td><c:out value="${h.rsltDispNm}" default="-"/></td>
          <td><c:out value="${h.endDt}" default="-"/></td>
          <td><c:out value="${h.histDesc}" default="-"/></td>
          <td><c:out value="${h.regUserId}" default="-"/></td>
          <td><c:out value="${h.regDt}" default="-"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty rsltHists}"><tr><td colspan="6" class="law-empty">결과변경 이력이 없습니다.</td></tr></c:if>
    </tbody>
  </table>

  <%-- ── 사건 허브: 소송문서 ── --%>
  <div class="law-sec law-sec-bar"><span>소송문서</span>
    <button type="button" class="krds-btn small" onclick="fnOpenDoc(null);">문서 등록</button></div>
  <table class="law-sub-table">
    <thead><tr><th style="width:130px;">문서종류</th><th>제목</th><th style="width:180px;">파일</th>
               <th style="width:80px;">승인상태</th><th style="width:110px;">등록일</th><th style="width:120px;">관리</th></tr></thead>
    <tbody>
      <c:forEach var="d" items="${docs}">
        <tr>
          <td><c:out value="${d.docKindNm}" default="-"/></td>
          <td><c:out value="${d.docTitl}" default="-"/></td>
          <td>
            <c:choose>
              <c:when test="${not empty d.files}">
                <c:set var="encFD" value="${egovc:encryptSession(d.atchFileId, pageContext.session.id)}"/>
                <c:forEach var="f" items="${d.files}"><a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encFD}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a></c:forEach>
              </c:when><c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
          <td>
            <c:choose>
              <c:when test="${d.appStsCd eq 'S002'}"><span class="law-badge appr">승인</span></c:when>
              <c:when test="${d.appStsCd eq 'S003'}"><span class="law-badge rjct" title="${fn:escapeXml(d.appOpinion)}">반려</span></c:when>
              <c:otherwise><span class="law-badge wait">대기</span></c:otherwise>
            </c:choose>
          </td>
          <td><c:if test="${not empty d.regDt and fn:length(d.regDt) ge 8}"><fmt:parseDate value="${fn:substring(d.regDt,0,8)}" pattern="yyyyMMdd" var="drd"/><fmt:formatDate value="${drd}" pattern="yyyy-MM-dd"/></c:if></td>
          <td>
            <button type="button" class="law-chip-btn btn-doc-edit" data-docid="${d.docId}" data-kind="${d.docKindCd}"
                    data-titl="<c:out value='${d.docTitl}'/>" data-memo="<c:out value='${d.docMemo}'/>">수정</button>
            <button type="button" class="law-chip-btn" onclick="fnDelDoc('${d.docId}');">삭제</button>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty docs}"><tr><td colspan="6" class="law-empty">등록된 문서가 없습니다.</td></tr></c:if>
    </tbody>
  </table>

  <%-- ── 사건 허브: 소송비용 ── --%>
  <div class="law-sec law-sec-bar"><span>소송비용</span>
    <span><button type="button" class="krds-btn small" onclick="fnOpenCalc();">계산기</button>
          <button type="button" class="krds-btn small" onclick="fnOpenCost(null);">비용 등록</button></span></div>
  <table class="law-sub-table">
    <thead><tr><th style="width:130px;">비용종류</th><th>내역</th><th style="width:140px;">금액</th>
               <th style="width:110px;">지급요청일</th><th style="width:120px;">관리</th></tr></thead>
    <tbody>
      <c:forEach var="ct" items="${costs}">
        <tr>
          <td><c:out value="${ct.costKindNm}" default="-"/></td>
          <td><c:out value="${ct.costDesc}" default="-"/></td>
          <td class="law-num"><c:choose><c:when test="${ct.costAmt != null}"><fmt:formatNumber value="${ct.costAmt}"/> 원</c:when><c:otherwise>-</c:otherwise></c:choose></td>
          <td><c:if test="${not empty ct.payDmndDt and fn:length(ct.payDmndDt) ge 8}">${fn:substring(ct.payDmndDt,0,4)}-${fn:substring(ct.payDmndDt,4,6)}-${fn:substring(ct.payDmndDt,6,8)}</c:if></td>
          <td>
            <button type="button" class="law-chip-btn btn-cost-edit" data-costid="${ct.costId}" data-kind="${ct.costKindCd}"
                    data-amt="${ct.costAmt}" data-desc="<c:out value='${ct.costDesc}'/>" data-pay="${ct.payDmndDt}">수정</button>
            <button type="button" class="law-chip-btn" onclick="fnDelCost('${ct.costId}');">삭제</button>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty costs}"><tr><td colspan="5" class="law-empty">등록된 비용이 없습니다.</td></tr></c:if>
      <c:if test="${not empty costs}">
        <tr class="law-now"><td colspan="2" style="text-align:right; font-weight:700;">합계</td>
          <td class="law-num" style="font-weight:700;">
            <c:set var="costTotal" value="0"/>
            <c:forEach var="ct" items="${costs}"><c:if test="${ct.costAmt != null}"><c:set var="costTotal" value="${costTotal + ct.costAmt}"/></c:if></c:forEach>
            <fmt:formatNumber value="${costTotal}"/> 원
          </td><td colspan="2"></td></tr>
      </c:if>
    </tbody>
  </table>

  <%-- ── 사건 허브: 선임 ── --%>
  <div class="law-sec law-sec-bar"><span>선임</span>
    <button type="button" class="krds-btn small" onclick="fnOpenAssign();">선임 등록</button></div>
  <table class="law-sub-table">
    <thead><tr><th>법무법인</th><th style="width:110px;">변호사</th><th style="width:170px;">계약서</th>
               <th style="width:100px;">선임일</th><th style="width:110px;">만족도</th><th style="width:120px;">관리</th></tr></thead>
    <tbody>
      <c:forEach var="a" items="${assigns}">
        <tr>
          <td><c:out value="${a.lawFirm}"/></td>
          <td><c:out value="${a.lawyerNm}"/></td>
          <td>
            <c:choose>
              <c:when test="${not empty a.files}">
                <c:set var="encFA" value="${egovc:encryptSession(a.atchFileId, pageContext.session.id)}"/>
                <c:forEach var="f" items="${a.files}"><a class="law-file-link" href="<c:url value='/cmm/fms/FileDown.do'/>?atchFileId=${encFA}&amp;fileSn=${f.fileSn}"><c:out value="${f.orignlFileNm}"/></a></c:forEach>
              </c:when><c:otherwise>-</c:otherwise>
            </c:choose>
          </td>
          <td><c:if test="${not empty a.assignDt and fn:length(a.assignDt) ge 8}">${fn:substring(a.assignDt,0,4)}-${fn:substring(a.assignDt,4,6)}-${fn:substring(a.assignDt,6,8)}</c:if></td>
          <td>
            <button type="button" class="law-chip-btn btn-satis" data-assignid="${a.assignId}"
                    data-label="<c:out value='${a.lawFirm}'/> / <c:out value='${a.lawyerNm}'/>">
              <c:choose><c:when test="${a.satisCnt > 0}"><span class="law-satis-star">★</span> <c:out value="${a.satisAvg}"/> (${a.satisCnt})</c:when><c:otherwise>평가</c:otherwise></c:choose>
            </button>
          </td>
          <td><button type="button" class="law-chip-btn" onclick="fnDelAssign('${a.assignId}');">삭제</button></td>
        </tr>
      </c:forEach>
      <c:if test="${empty assigns}"><tr><td colspan="6" class="law-empty">등록된 선임이 없습니다.</td></tr></c:if>
    </tbody>
  </table>

  <div class="law-btn-bar">
    <button type="button" class="krds-btn large" onclick="location.href='<c:url value="/law/suit/list.do"/>';">목록</button>
    <button type="button" class="krds-btn primary large" onclick="location.href='<c:url value="/law/suit/edit.do"/>?suitId=<c:out value="${suit.suitId}"/>';">수정</button>
    <button type="button" class="krds-btn large" onclick="fnDelete();">삭제</button>
  </div>

  <script>
  function fnDelete() {
    if (!confirm('이 사건을 삭제할까요?')) return;
    var params = new URLSearchParams();
    params.set('suitId', '<c:out value="${suit.suitId}"/>');
    fetch('<c:url value="/law/suit/deleteJson.do"/>', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
      body: params.toString()
    }).then(function (r) { return r.json(); }).then(function (d) {
      if (d.success) { location.href = '<c:url value="/law/suit/list.do"/>'; }
      else { alert(d.message || '삭제에 실패했습니다.'); }
    }).catch(function () { alert('삭제 요청에 실패했습니다.'); });
  }
  </script>

  <%-- ── 사건 허브 모달 ── --%>
  <div class="law-modal-back" id="modalBack"></div>

  <%-- 문서 등록/수정 (multipart) --%>
  <div class="law-modal" id="docModal" role="dialog" aria-modal="true">
    <h2 id="docTitle">문서 등록</h2>
    <form id="docForm" action="<c:url value='/law/doc/save.do'/>" method="post" enctype="multipart/form-data">
      <input type="hidden" name="suitId" value="${suit.suitId}"/>
      <input type="hidden" id="d_docId" name="docId" value=""/>
      <div class="form-row"><label for="d_docKind">문서종류</label>
        <select id="d_docKind" name="docKindCd" class="krds-select"><option value="">선택</option>
          <c:forEach var="c" items="${docKinds}"><option value="${c.code}"><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div class="form-row"><label for="d_docTitl">제목</label><input type="text" id="d_docTitl" name="docTitl" class="krds-input" maxlength="200"/></div>
      <div class="form-row"><label for="d_docMemo">메모</label><textarea id="d_docMemo" name="docMemo" class="krds-input" rows="3" maxlength="4000"></textarea></div>
      <div class="form-row"><label for="d_file">첨부파일</label>
        <div style="flex:1;">
          <c:set var="aId" value="d_file" scope="request"/>
          <c:set var="aName" value="file_1" scope="request"/>
          <c:set var="aExistFiles" value="${null}" scope="request"/>
          <jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
          <span class="law-cell-sub">등록·수정 시 승인상태는 '대기'로 설정됩니다.</span>
        </div></div>
      <div class="modal-btns">
        <button type="button" class="krds-btn medium" onclick="fnCloseModal('docModal');">취소</button>
        <button type="button" class="krds-btn primary medium" onclick="document.getElementById('docForm').submit();">저장</button>
      </div>
    </form>
  </div>

  <%-- 비용 등록/수정 --%>
  <div class="law-modal" id="costModal" role="dialog" aria-modal="true">
    <h2 id="costTitle">비용 등록</h2>
    <form id="costForm" action="<c:url value='/law/cost/save.do'/>" method="post">
      <input type="hidden" name="suitId" value="${suit.suitId}"/>
      <input type="hidden" id="c_costId" name="costId" value=""/>
      <div class="form-row"><label for="c_costKind">비용종류</label>
        <select id="c_costKind" name="costKindCd" class="krds-select"><option value="">선택</option>
          <c:forEach var="c" items="${costKinds}"><option value="${c.code}"><c:out value="${c.codeNm}"/></option></c:forEach></select></div>
      <div class="form-row"><label for="c_costAmt">금액(원)</label><input type="text" id="c_costAmt" name="costAmtStr" class="krds-input law-num" inputmode="numeric"/></div>
      <div class="form-row"><label for="c_costDesc">내역</label><input type="text" id="c_costDesc" name="costDesc" class="krds-input" maxlength="1000"/></div>
      <div class="form-row"><label for="c_payDmndDt">지급요청일</label><input type="date" id="c_payDmndDt" name="payDmndDt" class="krds-input"/></div>
      <div class="modal-btns">
        <button type="button" class="krds-btn medium" onclick="fnCloseModal('costModal');">취소</button>
        <button type="button" class="krds-btn primary medium" onclick="document.getElementById('costForm').submit();">저장</button>
      </div>
    </form>
  </div>

  <%-- 선임 등록 (multipart) --%>
  <div class="law-modal" id="assignModal" role="dialog" aria-modal="true">
    <h2>선임 등록</h2>
    <form id="assignForm" action="<c:url value='/law/assign/save.do'/>" method="post" enctype="multipart/form-data">
      <input type="hidden" name="suitId" value="${suit.suitId}"/>
      <input type="hidden" name="redirectSuitId" value="${suit.suitId}"/>
      <div class="form-row"><label for="a_lawyerId">변호사 <span style="color:#d3273e;">*</span></label>
        <select id="a_lawyerId" name="lawyerId" class="krds-select"><option value="">-- 선택 --</option>
          <c:forEach var="lw" items="${lawyerOptions}"><option value="${lw.lawyerId}"><c:out value="${lw.label}"/></option></c:forEach></select></div>
      <div class="form-row"><label for="a_assignDt">선임일</label><input type="date" id="a_assignDt" name="assignDt" class="krds-input"/></div>
      <div class="form-row"><label for="a_file">계약서 첨부</label>
        <div style="flex:1;">
          <c:set var="aId" value="a_file" scope="request"/>
          <c:set var="aName" value="file_1" scope="request"/>
          <c:set var="aExistFiles" value="${null}" scope="request"/>
          <jsp:include page="/WEB-INF/jsp/egovframework/com/cmm/fms/attachDropzone.jsp"/>
        </div></div>
      <div class="modal-btns">
        <button type="button" class="krds-btn medium" onclick="fnCloseModal('assignModal');">취소</button>
        <button type="button" class="krds-btn primary medium" onclick="fnSubmitAssign();">저장</button>
      </div>
    </form>
  </div>

  <%-- 만족도 --%>
  <div class="law-modal" id="satisModal" role="dialog" aria-modal="true">
    <h2 id="vsatisTitle">선임 만족도</h2>
    <input type="hidden" id="vst_assignId"/>
    <div class="form-row"><label>별점</label>
      <div id="vst_stars" class="law-star-pick"><span data-v="1">★</span><span data-v="2">★</span><span data-v="3">★</span><span data-v="4">★</span><span data-v="5">★</span></div></div>
    <div class="form-row"><label for="vst_opinion">의견 (선택)</label><textarea id="vst_opinion" class="krds-input" rows="3" maxlength="1000"></textarea></div>
    <div class="modal-btns">
      <button type="button" class="krds-btn medium" onclick="fnCloseModal('satisModal');">닫기</button>
      <button type="button" class="krds-btn primary medium" onclick="fnSaveSatis();">평가 저장</button></div>
    <div style="margin-top:14px;"><div class="law-cell-sub">등록된 의견</div>
      <div id="vst_opinions"><div class="law-cell-sub" style="padding:8px 0;">불러오는 중…</div></div></div>
  </div>

  <%@ include file="/WEB-INF/jsp/law/cost/_calcModal.jspf" %>

  <script>
  var VSAT = 0;
  function fnShowModal(id){ document.getElementById('modalBack').style.display='block'; document.getElementById(id).style.display='block'; }
  function fnCloseModal(id){ document.getElementById(id).style.display='none';
    var any = ['docModal','costModal','assignModal','satisModal'].some(function(m){ return document.getElementById(m).style.display==='block'; });
    if(!any) document.getElementById('modalBack').style.display='none'; }
  function vesc(s){ return (s==null?'':String(s)).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

  // 문서
  function fnOpenDoc(row){
    document.getElementById('docForm').reset();
    document.getElementById('docTitle').textContent = row ? '문서 수정' : '문서 등록';
    document.getElementById('d_docId').value = row ? row.docId : '';
    document.getElementById('d_docKind').value = row ? (row.docKindCd||'') : '';
    document.getElementById('d_docTitl').value = row ? (row.docTitl||'') : '';
    document.getElementById('d_docMemo').value = row ? (row.docMemo||'') : '';
    fnShowModal('docModal');
  }
  function fnDelDoc(id){ if(!confirm('이 문서를 삭제할까요?')) return; fnPostReload('<c:url value="/law/doc/deleteJson.do"/>', {docId:id}); }

  // 비용
  function fnOpenCost(row){
    document.getElementById('costForm').reset();
    document.getElementById('costTitle').textContent = row ? '비용 수정' : '비용 등록';
    document.getElementById('c_costId').value = row ? row.costId : '';
    document.getElementById('c_costKind').value = row ? (row.costKindCd||'') : '';
    document.getElementById('c_costAmt').value = (row && row.costAmt && row.costAmt!=='null') ? Number(row.costAmt).toLocaleString() : '';
    document.getElementById('c_costDesc').value = row ? (row.costDesc||'') : '';
    document.getElementById('c_payDmndDt').value = (row && row.payDmndDt && row.payDmndDt.length===8) ? (row.payDmndDt.substring(0,4)+'-'+row.payDmndDt.substring(4,6)+'-'+row.payDmndDt.substring(6,8)) : '';
    fnShowModal('costModal');
  }
  function fnDelCost(id){ if(!confirm('이 비용을 삭제할까요?')) return; fnPostReload('<c:url value="/law/cost/deleteJson.do"/>', {costId:id}); }
  document.getElementById('c_costAmt').addEventListener('input', function(){ var r=this.value.replace(/[^0-9]/g,''); this.value = r?Number(r).toLocaleString():''; });

  // 선임
  function fnOpenAssign(){ document.getElementById('assignForm').reset(); fnShowModal('assignModal'); }
  function fnSubmitAssign(){ if(!document.getElementById('a_lawyerId').value){ alert('변호사를 선택하세요.'); return; } document.getElementById('assignForm').submit(); }
  function fnDelAssign(id){ if(!confirm('이 선임을 삭제할까요?')) return; fnPostReload('<c:url value="/law/assign/deleteJson.do"/>', {assignId:id}); }

  function fnPostReload(url, params){
    var p = new URLSearchParams(); Object.keys(params).forEach(function(k){ p.set(k, params[k]); });
    fetch(url, { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'처리 실패'); } })
      .catch(function(){ alert('요청 실패'); });
  }

  // 만족도
  function fnOpenSatis(assignId, label){
    document.getElementById('vst_assignId').value = assignId;
    document.getElementById('vsatisTitle').textContent = '선임 만족도 — ' + label;
    document.getElementById('vst_opinion').value=''; fnSetStar(0);
    document.getElementById('vst_opinions').innerHTML = '<div class="law-cell-sub" style="padding:8px 0;">불러오는 중…</div>';
    fnShowModal('satisModal');
    fetch('<c:url value="/law/assign/satisDataJson.do"/>?assignId=' + assignId, { credentials:'same-origin', headers:{'X-Requested-With':'XMLHttpRequest'} })
      .then(function(r){ return r.json(); }).then(function(d){
        if(!d.success) return;
        if(d.mine){ fnSetStar(d.mine.score||0); document.getElementById('vst_opinion').value = d.mine.opinion||''; }
        var box = document.getElementById('vst_opinions');
        if(!d.list || !d.list.length){ box.innerHTML='<div class="law-cell-sub" style="padding:8px 0;">아직 의견이 없습니다.</div>'; return; }
        box.innerHTML = d.list.map(function(o){ var sc=o.score||0; var star='★★★★★'.slice(0,sc)+'☆☆☆☆☆'.slice(0,5-sc);
          return '<div class="law-opinion-item"><span class="law-satis-star">'+star+'</span> <strong>'+vesc(o.evaluatorNm||o.emplyrId||'')+'</strong>'+(o.opinion?'<div>'+vesc(o.opinion)+'</div>':'')+'</div>'; }).join('');
      }).catch(function(){});
  }
  function fnSetStar(n){ VSAT=n; Array.prototype.forEach.call(document.querySelectorAll('#vst_stars span'), function(s){ s.classList.toggle('on', parseInt(s.dataset.v,10)<=n); }); }
  function fnSaveSatis(){
    if(VSAT<1){ alert('별점을 선택하세요.'); return; }
    var p = new URLSearchParams(); p.set('assignId', document.getElementById('vst_assignId').value); p.set('score', VSAT); p.set('opinion', document.getElementById('vst_opinion').value);
    fetch('<c:url value="/law/assign/satisJson.do"/>', { method:'POST', credentials:'same-origin', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:p.toString() })
      .then(function(r){ return r.json(); }).then(function(d){ if(d.success){ location.reload(); } else { alert(d.message||'저장 실패'); } }).catch(function(){ alert('저장 요청 실패'); });
  }

  document.addEventListener('click', function(e){
    var de = e.target.closest('.btn-doc-edit'); if(de){ fnOpenDoc({docId:de.dataset.docid, docKindCd:de.dataset.kind, docTitl:de.dataset.titl, docMemo:de.dataset.memo}); return; }
    var ce = e.target.closest('.btn-cost-edit'); if(ce){ fnOpenCost({costId:ce.dataset.costid, costKindCd:ce.dataset.kind, costAmt:ce.dataset.amt, costDesc:ce.dataset.desc, payDmndDt:ce.dataset.pay}); return; }
    var sa = e.target.closest('.btn-satis'); if(sa){ fnOpenSatis(sa.dataset.assignid, sa.dataset.label); return; }
    var star = e.target.closest('#vst_stars span'); if(star){ fnSetStar(parseInt(star.dataset.v,10)); return; }
    if(e.target.id==='modalBack'){ ['docModal','costModal','assignModal','satisModal'].forEach(function(m){ document.getElementById(m).style.display='none'; }); document.getElementById('modalBack').style.display='none'; }
  });
  </script>
</lay:layout>
