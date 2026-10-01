<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/promEditor.jsp

  규정 IDE (3-pane 편집기) — C 3단계: 조항 본문 CKEditor 편집.
  레거시 의 /lims/manage/layout.html?pAct=fulltext 화면 이관.

  트리 계층 (레거시 1:1):
    규정분류 탭:  SGUBUN 그룹 → 분류 → 규정(회차) → 📁조문 / 📁별표·별지서식 → 장 → (절) → 조
    연혁목차 탭:  규정(정관) → 회차들 → 📁조문 / 📁별표·별지서식 → 장 → (절) → 조

  데이터 흐름:
    - 규정분류 트리: /rlms/prom/treeJson.do  (SGUBUN→분류→규정 한 방. 회차→[조문,별표], 조문→장, 장→절·조 lazy)
    - 연혁목차 트리: /rlms/prom/historyJson.do?lawId=...  (규정 루트 + 회차들, 이하 treeJson 과 동일 lazy)
    - 조항 본문(HTML 규정): /rlms/prom/provFragmentJson.do?promNo=&item=  · 저장 /saveProvHtml.do
    - 조항 본문(VERSION 규정): /rlms/prom/provVrsnFragmentJson.do?promNo=&fullItem=  · 저장 /saveProvVrsn.do
    - 관련자료(우측 패널): /rlms/prom/relatedListJson.do?promNo=&fullItem=  (TB_REL_VRSN + TB_REL_VRSN_CATE, 카테고리별 그룹화)
    - 중앙 본문: 조 노드 선택 → CKEditor 폼 / 규정 노드 → 메타 폼 / 그 외 → 노드 정보
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">규정 편집 IDE</c:set>
<c:set var="pageHead">
  
  <%-- jsTree 3.3.16 (로컬 번들 — /resources/lib/jstree/) --%>
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css'/>"/>
  <style>
    /* 개정분기 카드 (별표/HTML조항 공용) — IDE 카드 톤. 맨몸 셀렉트+버튼 나열 금지 */
    .ide-branch-card{display:flex;align-items:center;gap:12px;flex-wrap:wrap;
      margin:2px 0 10px;padding:10px 14px;border:1px solid #f0e3c0;border-left:4px solid #d9a514;
      background:#fdf8e7;border-radius:6px;}
    .ide-branch-card .bc-text{flex:1 1 260px;min-width:200px;font-size:12.5px;color:#5a4a12;line-height:1.5;}
    .ide-branch-card .bc-text b{display:block;color:#3f3308;font-size:13px;margin-bottom:2px;}
    /* 설명문 중간 강조 — 제목용 block b 와 달리 줄 안에 흐르게 */
    .ide-branch-card .bc-text b.bc-inline{display:inline;font-size:inherit;margin:0;}
    .ide-branch-card .bc-actions{display:flex;align-items:center;gap:8px;white-space:nowrap;}
    .ide-branch-card .bc-actions label{font-size:12.5px;color:#5a4a12;margin:0;font-weight:600;}
    .ide-branch-card .bc-actions select{height:36px;padding:0 10px;font-size:13px;
      border:1px solid #c9bd8f;border-radius:6px;background:#fff;color:#3f3308;}
    /* 카드 안 버튼은 셀렉트와 같은 36px — krds-btn medium(48px) 그대로 두면 과대 */
    .ide-branch-card .bc-actions .krds-btn{margin:0;height:36px !important;
      font-size:13px !important;padding:0 14px !important;line-height:1 !important;}
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="rlms-ide-wrap">

    <%-- ── 좌측: 트리 영역 ─────────────────────────────────── --%>
    <aside class="rlms-ide-left">
      <div class="ide-actions-tit">규정관리</div>

      <%-- (A) 분류 모드 --%>
      <nav class="ide-actions" id="ideActionsCate">
        <a href="javascript:fnNewProm();"        class="ide-action">신규 규정 등록</a>
        <a href="javascript:fnPromBulkUpdate();" class="ide-action">규정 일괄 수정</a>
        <a href="<c:url value='/rlms/prom/validateExisting.do'/>"          class="ide-action">규정별 유효성 검사</a>
        <a href="<c:url value='/rlms/promwork/selectPromWorkList.do'/>"    class="ide-action">작업승인관리</a>
        <a href="javascript:fnPromWorkHistory();"                          class="ide-action">제·개정 내역 관리</a>
        <a href="javascript:fnApproveRequestList();"                       class="ide-action">개정승인요청목록</a>
        <a href="<c:url value='/rlms/prommap/manage.do'/>" target="_blank" class="ide-action">기능별분류관리</a>
      </nav>

      <%-- (B) 규정 모드 — 컴팩트(트리에 자리 양보)
           · 회차 메타 편집: 연혁목차 트리에서 회차(prom) 클릭 시 자동 진입
           · 본문 일괄 편집: 회차 하위 [조문] 그룹(provgrp) 클릭 시 자동 진입
           · 연혁 삭제 / 분류이동: 메타 편집 화면 헤더 toolbar 에 위치 --%>
      <nav class="ide-actions ide-actions-prom" id="ideActionsProm" style="display:none;">
        <%-- '연혁 일괄 수정' = 규정 모드 주요 액션. 단 진한 블록(ide-action-primary)이 '규정관리'
             타이틀 헤더와 똑같아 메뉴로 안 보인다는 지적 → 다른 항목과 같은 '편집' 그룹의 · 링크로 정리. --%>
        <div class="ide-actions-group">
          <h5 class="ide-actions-group-label">편집</h5>
          <a href="javascript:fnVrsnMultiUpdate();" class="ide-action ide-action-apply">연혁 일괄 수정</a>
        </div>
        <div class="ide-actions-group">
          <h5 class="ide-actions-group-label">보기 / 검증</h5>
          <a href="javascript:fnDiff();"    class="ide-action">규정 대비표 보기</a>
          <a href="javascript:fnPreview();" class="ide-action">규정 미리보기</a>
          <a href="javascript:fnVrsnValidate();" class="ide-action">연혁별 유효성 검사</a>
          <a href="<c:url value='/rlms/prom/validateExisting.do'/>" class="ide-action">규정별 유효성 검사</a>
        </div>
        <div class="ide-actions-group">
          <h5 class="ide-actions-group-label">결재 / 이력</h5>
          <a href="<c:url value='/rlms/promwork/selectPromWorkList.do'/>"    class="ide-action">작업승인관리</a>
          <a href="javascript:fnPromWorkHistory();"                          class="ide-action">제·개정 내역 관리</a>
          <a href="javascript:fnApproveRequestList();"                       class="ide-action">개정승인요청목록</a>
        </div>
      </nav>

      <%-- 트리 검색창 --%>
      <div class="ide-tree-search">
        <input type="text" id="ideTreeSearch" placeholder="트리 검색 (분류/규정/조항)..."/>
        <button type="button" onclick="ideClearSearch();" title="지우기">×</button>
      </div>

      <%-- 트리 탭 --%>
      <div class="ide-tabs">
        <button type="button" class="ide-tab active" data-tab="cate"    onclick="ideSwitchTab('cate', this);">규정분류</button>
        <button type="button" class="ide-tab"        data-tab="history" onclick="ideSwitchTab('history', this);">연혁목차</button>
        <button type="button" class="ide-tab"        data-tab="draft"   onclick="ideSwitchTab('draft', this);">작업중 <span id="ideDraftCnt" class="ide-draft-cnt" style="display:none;">0</span></button>
      </div>

      <%-- 트리 컨테이너 --%>
      <div id="ideTreeCate"    class="ide-tree-pane active"></div>
      <div id="ideTreeHistory" class="ide-tree-pane">
        <p class="ide-tree-hint">규정분류 트리에서 규정을 선택하면 연혁이 표시됩니다.</p>
      </div>
      <%-- 작업중(draft) 패널 — 미승인 draft 회차 재발견. 분류 트리는 현행만 실어 여기가 IDE 내 유일 진입점. --%>
      <div id="ideTreeDraft" class="ide-tree-pane">
        <p class="ide-tree-hint">불러오는 중…</p>
      </div>
    </aside>

    <%-- ── 중앙: 본문 편집 영역 ───────────────────────────── --%>
    <main class="rlms-ide-main">

      <%-- (0) 초기 안내 --%>
      <div id="idePlaceholder" class="ide-placeholder">
        <h2>좌측 트리에서 항목을 선택하세요</h2>
        <p>규정 / 개정본 / 조항 노드를 클릭하면 중앙에 해당 컨텍스트 화면이 표시됩니다.</p>
        <ul class="ide-help-list">
          <li>[분류] 선택 → 이 분류에 신규 규정 등록</li>
          <li>[규정] 선택 → 연혁 일괄 수정 / 대비표 / 미리보기 + 연혁목차 자동 표시</li>
          <li>[조항] 선택 → 본문 편집</li>
        </ul>
      </div>

      <%-- (1) 노드 정보 (그룹/분류 — 간단 표시) --%>
      <div id="ideContextInfo" class="ide-context-pane" style="display:none;">
        <div class="ide-context-info">
          <h2 id="ideContextTitle"></h2>
          <p>유형: <strong id="ideContextType"></strong> · ID: <code id="ideContextNodeId"></code></p>
          <p id="ideContextHint" class="ide-ctx-hint"></p>
          <div id="ideContextActions" class="ide-ctx-actions"></div>
        </div>
      </div>

      <%-- (2) 규정 메타 편집 폼 — 레거시 "연혁등록/연혁수정" 화면 1:1
           항목 순서/라벨/필수 표시 모두 레거시 기준. 자세한 사양 = memory/project_prom_ide_pptx_required_screens.md --%>
      <div id="ideContextProm" class="ide-context-pane" style="display:none;">
        <div class="ide-prov-head">
          <h2 id="idePromHead">규정 메타</h2>
          <span id="idePromStatus" class="ide-prov-status"></span>
          <%-- 회차 단위 액션 — 우측 [회차 작업 ▾] 드롭다운으로 통합.
               상태별 노출은 기존 JS(id 기반 show/hide) 그대로 재사용 — 가시 항목 0개면 트리거도 자동 숨김. --%>
          <div class="ide-prom-actions">
            <button type="button" id="idePromActionsBtn" class="krds-btn" style="display:none;"
                    onclick="idePromActionsToggle(event);">회차 작업 ▾</button>
            <div id="idePromActionsMenu" class="ide-actmenu">
              <button type="button" id="ideBtnReqApprove" style="display:none;" onclick="fnRequestApprove();"
                      title="작성 완료. 관리자 승인 받으면 사용자 화면에 노출됨">승인요청</button>
              <%-- [수정권한요청]/[수정완료] 버튼 폐지(2026-07-20) — 수정권한 워크플로 제거.
                   현행 회차 편집 = 작성권한(분류 작성자/소관부서) 가드만으로 허용. --%>
              <button type="button" id="ideBtnEditProv" style="display:none;" onclick="fnGoEditProv();"
                      title="이 회차의 조문 본문을 입력/편집합니다 (트리에서 조문 노드를 찾지 않아도 됨)">조문 입력</button>
              <button type="button" id="ideBtnMoveCate" style="display:none;" onclick="fnMoveCate();"
                      title="이 회차를 다른 분류로 이동">분류이동</button>
              <button type="button" id="ideBtnDeleteEmpty" class="danger" style="display:none;" onclick="fnDeleteProm();"
                      title="이 연혁(회차)을 삭제합니다. 조문이 있으면 함께 삭제되고 이전 연혁의 조문이 현행으로 승계됩니다">삭제</button>
            </div>
          </div>
        </div>
        <%-- 반려 사유 카드 — 최신 워크가 승인반려일 때만 JS 가 표시 --%>
        <div id="idePromRejectBox" class="ide-reject-box" style="display:none;"></div>
        <form id="idePromForm" onsubmit="return false;">
          <input type="hidden" name="promNo" id="idePromNo"/>
          <input type="hidden" name="cateNo" id="idePromCateNo"/>
          <input type="hidden" name="sysId"  id="idePromSysId"/>
          <%-- 개정 회차 등록(레거시 insertPromulgation 파리티): 비면 신규 규정 제정, 있으면 이 규정의 새 회차 --%>
          <input type="hidden" name="lawId"  id="idePromLawId"/>

          <%-- 연혁번호 (레거시 체계: 제정=10, 개정마다 +10. 자동값 미리 채우되 직접 입력/수정 가능) / 분류 --%>
          <div class="ide-form-row inline">
            <div class="ide-form-col w30">
              <label for="idePromLawNo">연혁번호 <span class="required">*</span></label>
              <input type="text" name="lawNo" id="idePromLawNo" class="krds-input" inputmode="numeric"
                     placeholder="(자동 채번)" title="제정 연혁의 연혁번호는 10번입니다. (개정마다 +10, 직접 수정 가능)"/>
              <small class="ide-form-hint">제정=10, 개정마다 +10 (수정 가능)</small>
            </div>
            <div class="ide-form-col w70">
              <label for="idePromCateNm">분류</label>
              <input type="text" id="idePromCateNm" class="krds-input" disabled/>
            </div>
          </div>

          <div class="ide-form-row">
            <label for="idePromTitle">규정명 <span class="required">*</span></label>
            <input type="text" name="title" id="idePromTitle" class="krds-input" placeholder="규정 명칭을 입력하세요 (예: 직제규정)"/>
          </div>
          <div class="ide-form-row">
            <label for="idePromSubTitle">규정명(부제)</label>
            <input type="text" name="subTitle" id="idePromSubTitle" class="krds-input" placeholder="부제·영문명·약칭 등 (선택)"/>
          </div>
          <div class="ide-form-row inline">
            <div class="ide-form-col">
              <label for="idePromNumber">제·개정번호</label>
              <input type="text" name="number" id="idePromNumber" class="krds-input" placeholder="예: 제2024-1호"/>
              <small class="form-hint-information">공포·등록번호 표기 (선택). 비우면 공백으로 저장됩니다.</small>
            </div>

            <div class="ide-form-col ide-form-checkcol">
              <label class="ide-col-spacer" aria-hidden="true">&nbsp;</label>
              <div class="ide-check-line">
                <div class="krds-check-area">
                  <div class="krds-form-check medium">
                    <input type="checkbox" name="dispYn" id="idePromDispYn" value="N"/>
                    <label for="idePromDispYn">이 연혁을 감춥니다.</label>
                  </div>
                  <div class="krds-form-check medium">
                    <input type="checkbox" name="stsfdgYn" id="idePromStsfdgYn" value="Y"/>
                    <label for="idePromStsfdgYn" title="체크하면 이 연혁의 전문뷰어 하단에 만족도 조사(별점·의견)가 노출됩니다">만족도 조사 사용</label>
                  </div>
                </div>
              </div>
            </div>
            <div class="ide-form-col ide-form-checkcol">
              <label class="ide-col-spacer" aria-hidden="true">&nbsp;</label>
              <div class="ide-check-line">
                <span class="ide-check-lbl">외부 열람 요청 공개 여부</span>
                <div class="krds-check-area">
                  <div class="krds-form-check medium">
                    <input type="radio" name="extDispYn" id="idePromExtDispYnY" value="Y"/>
                    <label for="idePromExtDispYnY">공개</label>
                  </div>
                  <div class="krds-form-check medium">
                    <input type="radio" name="extDispYn" id="idePromExtDispYnN" value="N"/>
                    <label for="idePromExtDispYnN">비공개</label>
                  </div>
                </div>
              </div>
            </div>

          </div>
          <%-- URL — 규정형식 '링크형식(LINK)' 일 때만 표시(필수). 다른 형식에선 숨김(값은 폼 제출 시 그대로 보존). --%>
          <div class="ide-form-row" id="idePromUrlRow" style="display:none;">
            <label for="idePromUrl">URL <span class="required">*</span></label>
            <input type="text" name="url" id="idePromUrl" class="krds-input" placeholder="https://… 외부 원문 링크 (링크형식 필수)"/>
          </div>

          <%-- 정렬순서 / 소관부서 --%>
          <div class="ide-form-row inline">
            <div class="ide-form-col narrow">
              <label for="idePromGaejungNo">개정구분 <span class="required">*</span></label>
              <select name="gaejungNo" id="idePromGaejungNo" class="krds-input">
                <option value="">(선택)</option>
              </select>
            </div>

            <div class="ide-form-col narrow">
              <label for="idePromOrderIdx">정렬순서 <span class="hint">(1~100)</span></label>
              <input type="number" name="orderIdx" id="idePromOrderIdx" class="krds-input" min="1" max="100"/>
            </div> 

            <div class="ide-form-col">
              <label>소관부서 <span class="required">*</span></label>
              <div class="ide-buseo-cell">
                <%-- 정본 키 = 표준 조직ID(COMTNORGNZTINFO). buseoNo 는 레거시 IBUSEO_NO 호환 파생 --%>
                <input type="hidden" name="orgnztId" id="idePromOrgnztId"/>
                <input type="hidden" name="buseoNo" id="idePromBuseoNo"/>
                <input type="text" id="idePromBuseoNm" class="krds-input" readonly placeholder="(미지정)"/>
                <button type="button" class="krds-btn" onclick="ideOpenBuseoModal();">선택</button>
                <button type="button" class="krds-btn" onclick="ideClearBuseo();">지움</button>
              </div>
            </div>

          </div>

 		<%-- 제·개정일자/ 시행일자 / 종료일자 --%>
          <div class="ide-form-row inline">
             <div class="ide-form-col">
              <label for="idePromPromDate">제·개정일자 <span class="required">*</span></label>
              <div class="ide-date-cell">
                <input type="date" name="promDate" id="idePromPromDate" class="krds-input ide-date"/>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromPromDate','today');">오늘</button>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromPromDate','');">리셋</button>
              </div>
            </div>                
            <div class="ide-form-col">
              <label for="idePromStartDate">시행일자 <span class="required">*</span></label>
              <div class="ide-date-cell">
                <input type="date" name="startDate" id="idePromStartDate" class="krds-input ide-date"/>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromStartDate','today');">오늘</button>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromStartDate','same:idePromPromDate');" title="제·개정일자와 동일">제·개정일자</button>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromStartDate','');">리셋</button>
              </div>
            </div>
            <div class="ide-form-col">
              <label for="idePromNullDate">종료일자</label>
              <div class="ide-date-cell">
                <input type="date" name="nullDate" id="idePromNullDate" class="krds-input ide-date"/>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromNullDate','today');">오늘</button>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromNullDate','same:idePromPromDate');" title="제·개정일자와 동일">제·개정일자</button>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromNullDate','same:idePromStartDate');" title="시행일자와 동일">시행일</button>
                <button type="button" class="krds-btn" onclick="ideSetDate('idePromNullDate','');">리셋</button>
              </div>
            </div>
          </div>

          <%-- 규정형식 (SPROV_FG + SPROV_STYLE_CD) --%>
          <div class="ide-form-row inline">
            <div class="ide-form-col">
              <label for="idePromProvFlag">규정형식 <span class="required">*</span></label>
              <div class="ide-flag-cell">
                <select name="provFlag" id="idePromProvFlag" class="krds-input" onchange="ideChangeProvFlag(this.value);">
                  <option value="VERSION">버전관리조문</option>
                  <option value="HTML">HTML형식조문</option>
                  <option value="VIEWER">PDF파일뷰어</option>
                  <option value="LINK">링크형식(외부 원문)</option>
                </select>
                <%-- 규정형식별 동적 요소 (레거시 changeProvisionFlag 1:1): VERSION=스타일 / HTML=관련파일 체크 / VIEWER=참조파일 select --%>
                <select name="provStyleCd" id="idePromProvStyleCd" class="krds-input">
                  <option value="NORMAL">사규[①,1,가]</option>
                  <option value="NORMAL2">사규[①,가,1]</option>
                  <option value="NORMAL3">사규[가,1),①]</option>
                  <option value="PYUNRAM">업무매뉴얼형식</option>
                </select>
                <select name="provFileNo" id="idePromProvFileNo" class="krds-input" style="display:none;">
                  <option value="-1">참조뷰어용 파일이 존재하지 않습니다.</option>
                </select>
                <%-- KRDS 표준 체크박스 (krds-form-check): label::before=박스, ::after=체크표시. input 은 KRDS 가 시각 숨김 --%>
                <div id="idePromRelFileViewWrap" class="krds-check-area" style="display:none;">
                  <div class="krds-form-check medium">
                    <input type="checkbox" name="relFileViewYn" id="idePromRelFileView" value="Y"/>
                    <label for="idePromRelFileView">관련파일 바로열람</label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%-- 본문 — 레거시 의 "개정이유 / 주요내용 / 부칙 / 서문" 탭 (순서 레거시 동일) --%>
          <div class="ide-form-row">
            <label>본문</label>
            <div class="ide-pbody-tabs">
              <button type="button" class="ide-pbtab active" data-pbtab="reason"   onclick="idePbTab('reason', this);">개정이유</button>
              <button type="button" class="ide-pbtab"        data-pbtab="gaejung"  onclick="idePbTab('gaejung', this);">주요내용</button>
              <button type="button" class="ide-pbtab"        data-pbtab="bylaw"    onclick="idePbTab('bylaw', this);">부칙</button>
              <button type="button" class="ide-pbtab"        data-pbtab="preamble" onclick="idePbTab('preamble', this);">서문</button>
            </div>
            <textarea name="reason"   id="idePromBody_reason"   class="ide-pbody" rows="14"></textarea>
            <textarea name="gaejung"  id="idePromBody_gaejung"  class="ide-pbody" rows="14" style="display:none;"></textarea>
            <textarea name="bylaw"    id="idePromBody_bylaw"    class="ide-pbody" rows="14" style="display:none;"></textarea>
            <textarea name="preamble" id="idePromBody_preamble" class="ide-pbody" rows="14" style="display:none;"></textarea>
          </div>

          <div class="ide-form-actions">
            <button type="button" class="krds-btn primary" id="idePromSaveBtn" onclick="ideSaveProm();">저장</button>
            <button type="button" class="krds-btn"         onclick="ideCancelEdit();">취소</button>
          </div>
        </form>
      </div>

      <%-- (3) 조항 본문 편집 폼 (CKEditor) --%>
      <div id="ideContextProv" class="ide-context-pane" style="display:none;">
        <div class="ide-prov-head">
          <h2 id="ideProvHead">조항 편집</h2>
          <span id="ideProvStatus" class="ide-prov-status"></span>
        </div>
        <%-- 별표 개정분기 액션 — 이전 회차 상속 별표를 열었을 때만 채워짐 (prov pane 내라 항상 가시) --%>
        <div id="ideDocuBranchBox"></div>
        <form id="ideProvForm" onsubmit="return false;">
          <input type="hidden" name="provHtmlNo" id="ideProvHtmlNo"/>
          <input type="hidden" name="promNo"     id="ideProvPromNo"/>
          <input type="hidden" name="item"       id="ideProvItem"/>
          <input type="hidden" name="fullItem"   id="ideProvFullItem"/>
          <input type="hidden" name="sysId"      id="ideProvSysId"/>
          <%-- 보고 있는 회차 — saveProvHtml 의 상속 행 in-place 수정 차단 가드용 --%>
          <input type="hidden" name="viewPromNo" id="ideProvViewPromNo"/>
          <%-- 보는 회차의 규정/연혁번호 — saveProvVrsn 저장 라우팅용(상속 조 편집 = 보는 회차의 개정으로 저장).
               vrsn 모드에서만 채움. html/docu 모드는 빈값 유지. --%>
          <input type="hidden" name="lawId" id="ideProvLawId"/>
          <input type="hidden" name="lawNo" id="ideProvLawNo"/>

          <%-- HTML 조항 등록·수정 시 노출 — 조 번호/가지번호 (SITEM = 조4 + 가지2).
               HTML형식은 이 번호가 곧 목록 순서(ORDER BY SITEM)라, 사이에 끼우거나 순서를 고치는 수단이다.
               상속(개정분기) 행에서는 숨긴다 — 계보 키라 바꾸면 이전 회차와 연결이 끊긴다. --%>
          <div class="ide-form-row inline" id="ideProvJoRow" style="display:none;">
            <div>
              <label for="ideProvJoNo">조 번호 <span class="required">*</span> <span class="hint">(예: 제20조 → 20)</span></label>
              <input type="number" id="ideProvJoNo" class="krds-input" min="1" max="9999"/>
            </div>
            <div>
              <label for="ideProvJoSubNo">가지번호 <span class="hint">(예: 7의2 의 "2" — 보통 0)</span></label>
              <input type="number" id="ideProvJoSubNo" class="krds-input" min="0" max="99" value="0"/>
            </div>
          </div>
          <p class="ide-form-hint" id="ideProvJoHint" style="display:none;">
            번호를 바꾸면 목록에서 그 위치로 이동합니다. 사이에 끼우려면 가지번호를 쓰세요
            (예: 제2조와 제3조 사이 → 조 번호 2 · 가지번호 2 = 제2조의2). 첨부·즐겨찾기는 함께 옮겨집니다.
          </p>

          <div class="ide-form-row">
            <label for="ideProvTitle">조문제목 <span class="required">*</span></label>
            <input type="text" name="title" id="ideProvTitle" class="krds-input" placeholder="예: 자본금"/>
          </div>

          <%-- 시행일자 (레거시 단건 조 화면과 동일) --%>
          <div class="ide-form-row">
            <label for="ideProvStartDate">시행일자</label>
            <div class="ide-date-cell">
              <input type="date" name="startDate" id="ideProvStartDate" class="krds-input ide-date"/>
              <button type="button" class="krds-btn" onclick="ideSetDate('ideProvStartDate','today');">오늘</button>
              <button type="button" class="krds-btn" onclick="ideSetDate('ideProvStartDate','same:idePromPromDate');" title="제·개정일자와 동일">제·개정일자</button>
              <button type="button" class="krds-btn" onclick="ideSetDate('ideProvStartDate','same:idePromStartDate');" title="시행일자와 동일">시행일</button>
              <button type="button" class="krds-btn" onclick="ideSetDate('ideProvStartDate','');">리셋</button>
            </div>
          </div>

          <%-- 관리자메모 (레거시 SREASON 활용) --%>
          <div class="ide-form-row">
            <label for="ideProvReason">관리자메모</label>
            <textarea name="reason" id="ideProvReason" class="krds-input" rows="3"></textarea>
          </div>

          <%-- 개정 유형은 레거시 단건 조 화면에 노출 안 됨 — hidden 으로 유지 (SGAEJUNG_TYPE 컬럼) --%>
          <input type="hidden" name="gaejungType" id="ideProvGaejungType"/>

          <div class="ide-form-row">
            <label for="ideProvContents">조문내용편집 <span class="hint">(평문 — 표/이미지/HTML 은 우측 "관련자료"에 첨부)</span></label>
            <div class="ide-charpalette" data-target="ideProvContents" title="클릭 → 커서 위치에 삽입">
              <span class="ide-cp-grp" title="원숫자(항)">
                <button type="button">①</button><button type="button">②</button><button type="button">③</button><button type="button">④</button><button type="button">⑤</button><button type="button">⑥</button><button type="button">⑦</button><button type="button">⑧</button><button type="button">⑨</button><button type="button">⑩</button><button type="button">⑪</button><button type="button">⑫</button><button type="button">⑬</button><button type="button">⑭</button><button type="button">⑮</button><button type="button">⑯</button><button type="button">⑰</button><button type="button">⑱</button><button type="button">⑲</button><button type="button">⑳</button>
              </span>
              <span class="ide-cp-grp" title="한글원자(목)">
                <button type="button">㉠</button><button type="button">㉡</button><button type="button">㉢</button><button type="button">㉣</button><button type="button">㉤</button><button type="button">㉥</button><button type="button">㉦</button><button type="button">㉧</button><button type="button">㉨</button><button type="button">㉩</button>
              </span>
              <span class="ide-cp-grp" title="기호">
                <button type="button">·</button><button type="button">※</button><button type="button">§</button><button type="button">¶</button><button type="button">–</button><button type="button">—</button><button type="button">“</button><button type="button">”</button><button type="button">‘</button><button type="button">’</button>
              </span>
            </div>
            <textarea name="contents" id="ideProvContents" rows="20" spellcheck="false"></textarea>
          </div>

          <div class="ide-form-actions">
            <button type="button" class="krds-btn primary" id="ideProvSaveBtn" onclick="ideSaveProv();">수정하기</button>
            <%-- 삭제 — own-회차 기존 별표/HTML조항일 때만 노출(setProvDeleteVisible). 상속/신규/vrsn 은 숨김 --%>
            <button type="button" class="krds-btn danger" id="ideProvDeleteBtn" style="display:none;" onclick="ideDeleteProv();">삭제</button>
            <button type="button" class="krds-btn"         onclick="ideCancelEdit();">취소</button>
          </div>
        </form>
      </div>

      <%-- (4) 버전관리용조문편집 — 레거시 "조문" 그룹 노드 클릭 시. 전체 본문 일괄 편집 --%>
      <div id="ideContextProvBulk" class="ide-context-pane" style="display:none;">
        <div class="ide-prov-head">
          <h2 id="ideBulkHead">버전관리용조문편집</h2>
          <span id="ideBulkStatus" class="ide-prov-status"></span>
        </div>
        <div class="ide-bulk-toolbar">
          <button type="button" id="ideBulkOutlineBtn" class="ide-bulk-outline-btn"
                  onclick="ideBulkToggleOutline();"
                  title="장·조 개요만 보거나 항·호·목까지 전체를 펼칩니다">개요만 보기</button>
          <button type="button" class="ide-bulk-import-btn"
                  onclick="document.getElementById('ideDocImportFile').click();"
                  title=".docx / .hwpx 문서에서 본문을 추출해 편집기에 채웁니다">
            ＋문서에서 가져오기</button>
          <input type="file" id="ideDocImportFile" accept=".docx,.hwpx" style="display:none"
                 onchange="ideDocImportPick(this);">
          <select id="ideBulkHistorySel" class="ide-bulk-history">
            <option value="">이전개정작업내용</option>
          </select>
          <button type="button" class="krds-btn" onclick="ideBulkLoadHistory();">불러오기</button>
          <button type="button" class="krds-btn" onclick="ideBulkDeleteHistory();">삭제</button>
          <button type="button" class="krds-btn"         onclick="ideBulkValidate();">유효성검사</button>
          <button type="button" class="krds-btn primary" id="ideBulkSaveBtn" onclick="ideBulkSave();">저장하기</button>
          <button type="button" class="krds-btn"         onclick="ideCancelEdit();">닫기</button>
          <span class="ide-bulk-meta">
            <span id="ideBulkRowCnt">0</span> 행
          </span>
        </div>
        <%-- 내부 동작(파서 ProvTextParser 분해 → SFULL_ITEM 행 → TB_PROV_VRSN 스냅샷 교체,
             백업 = TB_PROV_TEXT_HST)은 개발자 주석으로만 — 화면 안내문에 내부 명칭 노출 금지(2026-07-16). --%>
        <div class="ide-bulk-help">
          ※ [저장하기]를 누르면 본문이 장·조·항·호 단위로 자동 분해되어 <strong>이 회차의 조문 전체를 새로 교체</strong>합니다.
          저장 직전의 본문은 <strong>이전개정작업내용</strong>으로 자동 백업되므로,
          드롭다운에서 골라 [불러오기]로 되돌리거나 [삭제]로 정리할 수 있습니다.
        </div>
        <div class="ide-charpalette" data-target="ideBulkBody" title="클릭 → 커서 위치에 삽입">
          <span class="ide-cp-grp" title="원숫자(항)">
            <button type="button">①</button><button type="button">②</button><button type="button">③</button><button type="button">④</button><button type="button">⑤</button><button type="button">⑥</button><button type="button">⑦</button><button type="button">⑧</button><button type="button">⑨</button><button type="button">⑩</button><button type="button">⑪</button><button type="button">⑫</button><button type="button">⑬</button><button type="button">⑭</button><button type="button">⑮</button><button type="button">⑯</button><button type="button">⑰</button><button type="button">⑱</button><button type="button">⑲</button><button type="button">⑳</button>
          </span>
          <span class="ide-cp-grp" title="한글원자(목)">
            <button type="button">㉠</button><button type="button">㉡</button><button type="button">㉢</button><button type="button">㉣</button><button type="button">㉤</button><button type="button">㉥</button><button type="button">㉦</button><button type="button">㉧</button><button type="button">㉨</button><button type="button">㉩</button>
          </span>
          <span class="ide-cp-grp" title="기호">
            <button type="button">·</button><button type="button">※</button><button type="button">§</button><button type="button">¶</button><button type="button">–</button><button type="button">—</button><button type="button">“</button><button type="button">”</button><button type="button">‘</button><button type="button">’</button>
          </span>
        </div>
        <textarea id="ideBulkBody" class="ide-bulk-body" spellcheck="false" rows="32"></textarea>
      </div>
    </main>

    <%-- ── 우측: 관련자료 패널 ────────────────────────────── --%>
    <aside class="rlms-ide-right">
      <div class="ide-related-head">
        <h3 class="ide-related-tit">관련자료</h3>
        <%-- 레거시 우측 패널 — 카테고리 필터 드롭다운 (전체보기 + 7종) ── --%>
        <div class="ide-related-filter">
          <label for="ideRelKindFilter">표시</label>
          <select id="ideRelKindFilter" onchange="ideFilterRelKind(this.value);"
                  title="관련자료를 종류별로 걸러 봅니다">
            <option value="all">전체보기</option>
            <option value="file">일반파일</option>
            <option value="orgn">원본파일</option>
            <option value="word">분류파일</option>
            <option value="html">HTML표</option>
            <option value="image">그림파일</option>
            <option value="url">컨텐츠연계</option>
            <option value="dmn">관련규정연계</option>
          </select>
        </div>
        <button type="button" class="ide-cate-mgr-btn"
                onclick="ideOpenCateModal();"
                title="파일 분류(본문/붙임/양식 등) 추가·이름변경·순서·삭제">파일 분류 관리</button>
      </div>
      <ul class="ide-related-actions">
        <%-- 파일 업로드 3종(첨부파일·문서·이미지) 단일 입구 — 종류는 모달 안 탭에서 고른다 (2026-07-30).
             [문서(Word/HWP) 등록]·[이미지 첨부하기] 별도 메뉴는 같은 모달의 mode 차이일 뿐이라 통합. --%>
        <li><a href="javascript:fnAttachWord();">파일 등록 <span class="ide-ra-sub">(첨부·문서·이미지)</span></a></li>
        <%-- '원본 첨부하기'(ORGN/TB_REL_ORGN) 신규 입구 폐지 — '파일 등록'(REL_FILE_1)으로 단일화.
             분류 없는 평행 트랙이라 중복. 레거시 원본자료는 '원본파일' 필터·관련자료 패널에서 그대로 열람/다운로드.
             (서버 saveOrgn.do·TB_REL_ORGN·조회경로는 유지 — 기존 2천여 건 보존)
        <li><a href="javascript:fnAttachOrgn();">원본 첨부하기</a></li> --%>
        <li><a href="javascript:fnAttachHtml();">HTML 표 첨부하기</a></li>
        <li><a href="javascript:fnAttachUrl();">관련 URL 정보 연계</a></li>
        <li><a href="javascript:fnAttachProm();">관련 규정 정보 연계</a></li>
        <li><a href="javascript:fnDownloadAll();">일괄 다운로드</a></li>
      </ul>
      <div class="ide-related-list" id="ideRelatedList">
        <p class="empty">등록되어있는 자료가<br/>없습니다.</p>
      </div>

      <%-- ── 자동링크 제외범위 박스 (F3) — 회차 메타 보일 때만 노출 ── --%>
      <div class="ide-excl-box" id="ideExclLnkBox" style="display:none;">
        <div class="ide-excl-head">
          <h4 class="ide-excl-tit">자동링크 제외범위</h4>
          <button type="button" class="krds-btn ide-btn-edit-excl"
                  onclick="fnEditExclLnk();" title="제외범위 편집">수정</button>
        </div>
        <ul class="ide-excl-list" id="ideExclLnkList">
          <li class="empty">등록되어있는 항목이 없습니다.</li>
        </ul>
      </div>
    </aside>
  </div>

  <%-- ── 소관부서 선택 모달 (TB_BUSEO) ─────────────────────── --%>
  <%-- 별표/별지서식 신규 등록 모달 — TB_DOCU INSERT (SITEM = 유형2+번호4+가지2) --%>
  <div id="ideDocuAddModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseDocuAddModal();">
    <div class="ide-modal-box">
      <div class="ide-modal-head">
        <h3>별표/별지서식 등록</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseDocuAddModal()" aria-label="닫기">&times;</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-form-row">
          <label>유형 <span class="req">*</span></label>
          <select id="ideDocuAddType" class="ide-form-input">
            <option value="01">별표</option>
            <option value="02">별지서식</option>
            <option value="03">별첨</option>
          </select>
        </div>
        <div class="ide-form-row cols">
          <div>
            <label>번호 <span class="req">*</span> <span class="hint">(유형 내 일련번호 — 자동 제안)</span></label>
            <input type="number" id="ideDocuAddNo" class="ide-form-input" min="1" max="9999"/>
          </div>
          <div>
            <label>가지번호 <span class="hint">(예: 1의2 의 "2" — 보통 0)</span></label>
            <input type="number" id="ideDocuAddSubNo" class="ide-form-input" min="0" max="99" value="0"/>
          </div>
        </div>
        <div class="ide-form-row">
          <label>제목 <span class="req">*</span> <span class="hint">— "[별표 N]" 표기는 자동으로 붙습니다</span></label>
          <input type="text" id="ideDocuAddTitle" class="ide-form-input" maxlength="200" placeholder="예: 기구도"/>
        </div>
        <div class="ide-form-row">
          <label>등록 사유 <span class="hint">(선택)</span></label>
          <input type="text" id="ideDocuAddReason" class="ide-form-input" maxlength="300"/>
        </div>
        <p class="hint">
          별표의 실제 내용물(표 이미지·HWP 등)은 등록 후 트리에서 항목을 선택해 우측 "관련자료"로 첨부합니다.
        </p>
        <div class="ide-modal-actions">
          <span class="ide-file-progress" id="ideDocuAddStatus"></span>
          <button type="button" class="krds-btn primary medium" onclick="ideSubmitDocuAdd()">등록</button>
          <button type="button" class="krds-btn medium" onclick="ideCloseDocuAddModal()">취소</button>
        </div>
      </div>
    </div>
  </div>

  <%-- HTML형식조문 신규 조항 등록 모달은 폐기 — "HTML 조항 등록" 클릭 시 중앙 편집 폼으로 곧장 진입(조 번호/가지번호/제목 인라인). ideStartNewProvHtml() 참조 --%>

  <div id="ideBuseoModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseBuseoModal();">
    <div class="ide-modal-box">
      <div class="ide-modal-head">
        <h3>소관부서 선택</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseBuseoModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-modal-search">
          <input type="text" id="ideBuseoSearch" placeholder="부서명 검색 (입력 후 Enter)" autocomplete="off"/>
          <button type="button" class="krds-btn" onclick="ideSearchBuseo();">검색</button>
        </div>
        <div id="ideBuseoList" class="ide-modal-list">
          <p class="empty">검색어를 입력하거나 [검색] 으로 전체 목록 조회</p>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 분류이동 모달 (레거시 "분류이동" — F2) ─────────────── --%>
  <div id="ideMoveCateModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseMoveCateModal();">
    <div class="ide-modal-box ide-modal-box--w720">
      <div class="ide-modal-head">
        <h3>규정분류이동</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseMoveCateModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-move-cate-layout ide-split-layout">
          <%-- 좌측: 이동 가능 분류 트리 --%>
          <div class="ide-split-main">
            <div class="ide-split-tit">내규/편람 목록</div>
            <div id="ideMoveCateTree" class="ide-modal-tree ide-modal-tree--short"></div>
          </div>
          <%-- 우측: 이동전 / 이동후 정보 + 실행 버튼 --%>
          <div class="ide-split-side">
            <div class="ide-split-sec">
              <div class="ide-split-tit">이동전 정보</div>
              <table class="ide-modal-table">
                <tr>
                  <th>규정명</th>
                  <td id="ideMoveCateFromTitle"></td>
                </tr>
                <tr>
                  <th>분류명</th>
                  <td id="ideMoveCateFromNm"></td>
                </tr>
              </table>
            </div>
            <div>
              <div class="ide-split-tit">이동후 정보</div>
              <table class="ide-modal-table">
                <tr>
                  <th>분류명</th>
                  <%-- color 는 JS(ideMoveCateToNm.style.color)가 상태 따라 토글 — 인라인 유지 --%>
                  <td id="ideMoveCateToNm" style="color:#888;">(좌측 트리에서 분류 선택)</td>
                </tr>
              </table>
            </div>
            <div class="ide-modal-actions">
              <button type="button" class="krds-btn primary" onclick="ideMoveCateConfirm();">이동하기</button>
              <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseMoveCateModal();">취소</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 일괄편집 유효성검사 결과 모달 (레거시 "조문 유효성 검사 결과" — F4) ── --%>
  <div id="ideBulkValidateModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseBulkValidateModal();">
    <div class="ide-modal-box ide-modal-box--w680">
      <div class="ide-modal-head">
        <h3>조문 유효성 검사 결과</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseBulkValidateModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <p class="ide-modal-desc">조문 내용 유효성 검사 결과 목록 — 행을 클릭하면 편집기의 해당 라인으로 이동합니다.</p>
        <table class="ide-validate-tbl">
          <thead>
            <tr>
              <th class="col-no">위치</th>
              <th>조문내용</th>
              <th class="col-chk">검증내용</th>
              <th class="col-fix">변경방법</th>
            </tr>
          </thead>
          <tbody id="ideBulkValidateTbody">
            <tr><td colspan="4" class="status">검증 결과 없음</td></tr>
          </tbody>
        </table>
        <p id="ideBulkValidateSummary" class="ide-validate-summary">
          <span id="ideBulkValidateCount">0</span>건이 발견되었습니다.
        </p>
        <div class="ide-modal-actions">
          <button type="button" id="ideBulkValidateConfirmBtn" class="krds-btn primary" onclick="ideBulkValidateConfirm();">검증완료</button>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseBulkValidateModal();">창닫기</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 자동링크 제외범위 편집 모달 (레거시 "인용링크제외범위수정" — F3) ── --%>
  <div id="ideExclLnkModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseExclLnkModal();">
    <div class="ide-modal-box ide-modal-box--w760">
      <div class="ide-modal-head">
        <h3>인용링크 제외범위 수정</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseExclLnkModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-excl-ctx" id="ideExclLnkCtx"></div>
        <div class="ide-excl-layout ide-split-layout">
          <%-- 좌측: 대상선택 트리 (gubun > cate > prom) --%>
          <div class="ide-split-main">
            <div class="ide-split-tit">대상 선택</div>
            <div id="ideExclLnkTree" class="ide-modal-tree"></div>
            <div class="ide-modal-actions tight">
              <button type="button" class="krds-btn primary" onclick="ideExclLnkAddSelected();">→ 추가</button>
            </div>
          </div>
          <%-- 우측: 제외목록 --%>
          <div class="ide-split-side">
            <div class="ide-split-tit">제외 목록</div>
            <ul id="ideExclLnkSelectedList" class="ide-excl-modal-list">
              <li class="empty">선택 항목이 없습니다.</li>
            </ul>
          </div>
        </div>
        <div class="ide-modal-actions">
          <button type="button" class="krds-btn primary" onclick="ideExclLnkSave();">저장</button>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseExclLnkModal();">취소</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 연혁 일괄 수정 모달 (레거시 "연혁일괄수정" — multipleUpdate) ── --%>
  <div id="ideMultiUpdateModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseMultiUpdateModal();">
    <div class="ide-modal-box ide-modal-box--w980">
      <div class="ide-modal-head">
        <h3>연혁 일괄 수정</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseMultiUpdateModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-multi-ctx" id="ideMultiUpdateCtx"></div>
        <p class="ide-modal-desc">한 규정의 모든 연혁(회차) 메타정보를 한 표에서 일괄 수정합니다. 제명은 필수이며,
          [감추기] 체크 시 해당 회차가 목록·뷰어에서 숨겨집니다. 저장 시 현행 회차가 자동 재계산됩니다.</p>
        <div class="ide-multi-tbl-wrap">
          <table class="ide-multi-tbl">
            <thead>
              <tr>
                <th rowspan="2" class="col-lawno">연혁<br/>번호</th>
                <th class="col-gj">개정구분</th>
                <th colspan="3" class="col-title">제명</th>
                <th rowspan="2" class="col-hide">감추기</th>
                <th rowspan="2" class="col-view">보기</th>
                <th rowspan="2" class="col-del">삭제</th>
              </tr>
              <tr>
                <th class="col-num">제·개정번호</th>
                <th class="col-date">공포일자</th>
                <th class="col-date">시행일자</th>
                <th class="col-date">폐지일자</th>
              </tr>
            </thead>
            <tbody id="ideMultiUpdateTbody">
              <tr><td colspan="8" class="status">불러오는 중…</td></tr>
            </tbody>
          </table>
        </div>
        <div class="ide-modal-actions ide-multi-actions">
          <button type="button" class="krds-btn danger ide-multi-delall" onclick="ideMultiUpdateDeleteAll();">규정 전체 삭제</button>
          <span class="ide-multi-spacer"></span>
          <button type="button" class="krds-btn primary" onclick="ideMultiUpdateSave();">일괄 저장</button>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseMultiUpdateModal();">닫기</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 규정 일괄 수정 모달 (분류 단위 — 현행 규정 메타 일괄수정 + 정렬순서 드래그) ── --%>
  <div id="ideCateBulkModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseCateBulk();">
    <div class="ide-modal-box ide-modal-box--w980">
      <div class="ide-modal-head">
        <h3>규정 일괄 수정</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseCateBulk();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-multi-ctx" id="ideCateBulkCtx"></div>
        <p class="ide-modal-desc">선택한 분류의 <b>현행 규정</b>들을 한 표에서 일괄 수정합니다. 제명·개정구분·소관부서는 필수입니다.
          왼쪽 <b>≡ 핸들을 끌어</b> 정렬 순서를 바꿀 수 있고, [감추기] 체크 시 목록·뷰어에서 숨겨집니다.</p>
        <div class="ide-multi-tbl-wrap">
          <table class="ide-multi-tbl">
            <thead>
              <tr>
                <th style="width:44px;">순서</th>
                <th class="col-title">규정명</th>
                <th class="col-gj" style="width:150px;">개정구분</th>
                <th style="width:210px;">소관부서</th>
                <th class="col-hide" style="width:60px;">감추기</th>
                <th class="col-view" style="width:60px;">보기</th>
              </tr>
            </thead>
            <tbody id="ideCateBulkTbody">
              <tr><td colspan="6" class="status">불러오는 중…</td></tr>
            </tbody>
          </table>
        </div>
        <div class="ide-modal-actions ide-multi-actions">
          <span class="ide-multi-spacer"></span>
          <button type="button" class="krds-btn primary" onclick="ideCateBulkSave();">일괄 저장</button>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseCateBulk();">닫기</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 파일 일반/분류등록 모달 (FILE 액션) ──────────────── --%>
  <div id="ideFileModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseFileModal();">
    <div class="ide-modal-box">
      <div class="ide-modal-head">
        <h3 id="ideFileModalTitle">파일 등록</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseFileModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <%-- 파일 종류 탭 (2026-07-30) — 메뉴에 흩어져 있던 [파일 등록]·[문서(Word/HWP) 등록]·[이미지 첨부하기]
             3개 입구를 하나로 합친 자리. 같은 드롭존을 쓰고 저장 엔드포인트·허용 확장자만 달라진다. --%>
        <div class="ide-file-tabs" id="ideFileTabs" role="tablist">
          <button type="button" class="ide-file-tab active" data-mode="FILE"  role="tab"
                  onclick="ideFileTab('FILE');">첨부파일</button>
          <button type="button" class="ide-file-tab" data-mode="WORD"  role="tab"
                  onclick="ideFileTab('WORD');">문서(Word·HWP)</button>
          <button type="button" class="ide-file-tab" data-mode="IMAGE" role="tab"
                  onclick="ideFileTab('IMAGE');">이미지</button>
        </div>
        <div class="ide-file-ctx" id="ideFileCtx"></div>
        <form id="ideFileForm" enctype="multipart/form-data" onsubmit="return false;">
          <div class="ide-form-row" id="ideFileTitleRow">
            <label for="ideFileTitle">제목 <span class="hint">(미입력 시 파일명 사용)</span></label>
            <input type="text" id="ideFileTitle" class="krds-input" maxlength="200"/>
          </div>
          <div class="ide-form-row" id="ideFileCateRow">
            <label for="ideFileCate">분류</label>
            <select id="ideFileCate" class="krds-input">
              <option value="">(분류 없음)</option>
            </select>
          </div>
          <div class="ide-form-row">
            <label for="ideFileInput">파일 <span class="req">*</span> <span class="hint">(여러 개 선택 가능)</span></label>
            <%-- KRDS file-upload (component_09_04): 드롭존 + .file-list>.upload-list 목록.
                 드롭존 클래스는 KRDS 표준 .file-upload 가 아니라 .ide-file-drop — krds.min.js 의
                 krds_fileUpload.init() 가 버튼 없는 .file-upload 에서 null.addEventListener 콘솔에러를
                 내므로 클래스명을 분리(스타일은 rlms-compat .krds-file-upload .ide-file-drop 가 담당). --%>
            <div class="krds-file-upload">
              <div class="ide-file-drop" id="ideFileDrop">
                <input type="file" id="ideFileInput" name="file" class="ide-file-native" multiple required/>
                <span class="txt">파일을 여기로 끌어다 놓거나 <strong>파일 선택</strong></span>
              </div>
              <div class="file-list">
                <div class="total" id="ideFileTotal" style="display:none;">총 <span class="current">0</span>개</div>
                <ul id="ideFileSelList" class="upload-list"></ul>
              </div>
            </div>
            <div id="ideFileNotice" class="ide-file-notice" style="display:none;"></div>
          </div>
        </form>
        <div class="ide-modal-actions">
          <span id="ideFileProgress" class="ide-file-progress"></span>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseFileModal();">취소</button>
          <button type="button" class="krds-btn krds-btn--primary" id="ideFileUploadBtn" onclick="ideUploadFile();">업로드</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 카테고리 관리 모달 ───────────────────────────────── --%>
  <div id="ideCateModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseCateModal();">
    <div class="ide-modal-box ide-modal-box--wide">
      <div class="ide-modal-head">
        <h3>관련자료 카테고리 관리</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseCateModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-file-ctx" id="ideCateCtx"></div>

        <div class="ide-cate-add">
          <div class="ide-cate-add-title">새 카테고리 추가</div>
          <div class="ide-cate-add-grid">
            <div class="ide-cate-fld grow">
              <label for="ideCateNewTitle">이름</label>
              <input type="text" id="ideCateNewTitle" class="krds-input"
                     placeholder="예: 본문 / 붙임 / 양식" maxlength="50"/>
            </div>
            <div class="ide-cate-fld">
              <label for="ideCateNewSeq">순서</label>
              <input type="number" id="ideCateNewSeq" class="krds-input"
                     placeholder="자동" min="1" max="999"/>
            </div>
            <div class="ide-cate-fld">
              <label for="ideCateNewOrgnDown">원본 다운로드</label>
              <select id="ideCateNewOrgnDown" class="krds-input">
                <option value="N">허용 안 함</option>
                <option value="Y">허용</option>
              </select>
            </div>
            <div class="ide-cate-fld">
              <button type="button" class="krds-btn krds-btn--primary ide-cate-add-btn"
                      onclick="ideAddCate();">추가</button>
            </div>
          </div>
        </div>

        <div class="ide-cate-list" id="ideCateList">
          <p class="empty">목록을 불러오는 중...</p>
        </div>
      </div>
    </div>
  </div>

  <%-- ── HTML 표 첨부 모달 (B3) ───────────────────────────── --%>
  <div id="ideHtmlModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseHtmlModal();">
    <div class="ide-modal-box ide-modal-box--wide">
      <div class="ide-modal-head">
        <h3>HTML 표 첨부하기</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseHtmlModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-file-ctx" id="ideHtmlCtx"></div>
        <form id="ideHtmlForm" onsubmit="return false;">
          <div class="ide-form-row">
            <label for="ideHtmlTitle">제목 <span class="hint">(미입력 시 '(제목없음)')</span></label>
            <input type="text" id="ideHtmlTitle" class="krds-input" maxlength="200"/>
          </div>
          <div class="ide-form-row">
            <label for="ideHtmlBody">내용 <span class="hint">(표·서식 그대로 저장됩니다)</span></label>
            <textarea id="ideHtmlBody" name="html" rows="12"></textarea>
          </div>
        </form>
        <div class="ide-modal-actions">
          <span id="ideHtmlProgress" class="ide-file-progress"></span>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseHtmlModal();">취소</button>
          <button type="button" class="krds-btn krds-btn--primary" id="ideHtmlSaveBtn" onclick="ideSaveHtml();">저장</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 규정 연계 모달 (B4 DOMAIN_LINK) — 레거시 3-pane 재현 ──────── --%>
  <div id="ideDmnLnkModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseDmnLnkModal();">
    <div class="ide-modal-box ide-modal-box--wide ide-modal-box--w980">
      <div class="ide-modal-head">
        <h3>관련 규정 정보 연계하기</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseDmnLnkModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-file-ctx" id="ideDmnLnkCtx"></div>

        <%-- 상단: 좌 트리 + 우 (체크된 규정/조문 카드) --%>
        <div class="ide-dmn-split">
          <div class="ide-dmn-left">
            <div class="ide-dmn-left-head">대상 선택 <span class="hint">(분류 안의 규정에 체크)</span></div>
            <div id="ideDmnTree" class="ide-dmn-tree"></div>
          </div>
          <div class="ide-dmn-right ide-dmn-picker">
            <div class="ide-dmn-right-head">
              사규/규정문서/법무자료/업무매뉴얼 컨텐츠 목록
            </div>
            <div class="ide-dmn-picker-help">
              연결하고자 하는 컨텐츠를 선택한 후에 컨텐츠 추가 버튼을 클릭하세요.<br/>
              <span class="hint">이미 선택된 컨텐츠는 추가되지 않습니다.</span>
            </div>
            <div class="ide-dmn-picker-section">
              <div class="ide-dmn-picker-title">규정 (PROMULGATION 연계)</div>
              <div id="ideDmnPickerLaws" class="ide-dmn-picker-laws">
                <p class="empty">왼쪽 트리에서 규정을 체크하세요.</p>
              </div>
            </div>
            <div class="ide-dmn-picker-section">
              <div class="ide-dmn-picker-title">조문 (PROVISION 연계)</div>
              <div id="ideDmnPickerProvs" class="ide-dmn-picker-provs">
                <p class="empty">규정 체크 시 그 규정의 조문 목록이 표시됩니다.</p>
              </div>
            </div>
          </div>
        </div>

        <%-- 중단: 액션바 --%>
        <div class="ide-dmn-actbar">
          <span class="ide-dmn-actbar-title">연계할 규정 컨텐츠 목록 <span id="ideDmnStageCnt" class="ide-cate-badge">0</span></span>
          <button type="button" class="krds-btn krds-btn--primary" onclick="ideDmnAddChecked();">+ 추가하기</button>
          <button type="button" class="krds-btn krds-btn--primary" id="ideDmnSaveBtn" onclick="ideSaveDmnLnk();">저장하기</button>
        </div>

        <%-- 하단: staging 목록 --%>
        <div class="ide-dmn-list" id="ideDmnStageList">
          <p class="empty">선택된 항목이 없습니다.</p>
        </div>

        <div class="ide-modal-actions">
          <span id="ideDmnProgress" class="ide-file-progress"></span>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseDmnLnkModal();">닫기</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 관련 URL 정보 연계 모달 (B7) ──────────────────── --%>
  <div id="ideLnkModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseLnkModal();">
    <div class="ide-modal-box ide-modal-box--wide">
      <div class="ide-modal-head">
        <h3>관련 URL 정보 연계</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseLnkModal();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-file-ctx" id="ideLnkCtx"></div>

        <div class="ide-lnk-actbar">
          <span class="ide-lnk-actbar-title">URL 목록 <span id="ideLnkStageCnt" class="ide-cate-badge">0</span></span>
          <button type="button" class="krds-btn" onclick="ideLnkAddRow();">+ 행 추가</button>
        </div>

        <div class="ide-lnk-list" id="ideLnkStageList">
          <p class="empty">행 추가 버튼을 눌러 URL 을 입력하세요.</p>
        </div>

        <div class="ide-modal-actions">
          <span id="ideLnkProgress" class="ide-file-progress"></span>
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseLnkModal();">취소</button>
          <button type="button" class="krds-btn krds-btn--primary" id="ideLnkSaveBtn" onclick="ideSaveLnk();">저장</button>
        </div>
      </div>
    </div>
  </div>

  <%-- ── 단계 C: 관련자료 항목 상세 모달 (kind별 분기 렌더) ─────────── --%>
  <div id="ideRelDetailModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideCloseRelDetail();">
    <div class="ide-modal-box ide-modal-box--wide">
      <div class="ide-modal-head">
        <h3 id="ideRelDetailTitle">관련자료 상세</h3>
        <button type="button" class="ide-modal-close" onclick="ideCloseRelDetail();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-file-ctx" id="ideRelDetailCtx"></div>
        <div id="ideRelDetailBody" class="ide-rel-detail-body">
          <p class="empty">불러오는 중…</p>
        </div>
        <div class="ide-modal-actions">
          <button type="button" class="krds-btn ide-btn-cancel" onclick="ideCloseRelDetail();">닫기</button>
        </div>
      </div>
    </div>
  </div>

  <%-- 문서에서 가져오기 — 추출 미리보기 모달 --%>
  <div id="ideDocImportModal" class="ide-modal" style="display:none;" onclick="if(event.target===this)ideDocImportClose();">
    <div class="ide-modal-box ide-modal-box--wide">
      <div class="ide-modal-head">
        <h3>문서에서 가져오기 — 추출 결과</h3>
        <button type="button" class="ide-modal-close" onclick="ideDocImportClose();" aria-label="닫기">×</button>
      </div>
      <div class="ide-modal-body">
        <div class="ide-file-ctx" id="ideDocImportCtx"></div>
        <p class="ide-modal-desc small">
          ※ 문서에서 추출한 평문입니다. 편집기에 넣은 뒤 항·호(①/1./가) 기호를 정리하고 [저장하기]를 누르면 조문 단위로 자동 분해되어 저장됩니다.
        </p>
        <textarea id="ideDocImportPreview" class="ide-doc-import-preview"></textarea>
      </div>
      <div class="ide-modal-actions">
        <button type="button" class="krds-btn primary" onclick="ideDocImportApply('replace');">편집기 내용 교체</button>
        <button type="button" class="krds-btn"         onclick="ideDocImportApply('append')">뒤에 붙이기</button>
        <button type="button" class="krds-btn ide-btn-cancel" onclick="ideDocImportClose();">취소</button>
      </div>
    </div>
  </div>

  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <script>
    // 세션 만료 시 — Ajax(.do JSON) 호출이 302→로그인 페이지로 흘러 JSON 파싱 실패/오류화면이 뜨던 것을(#12)
    //   감지해 로그인 화면으로 보낸다. 로그인 응답 식별: HTTP 401, X-RLMS-Auth 헤더, 또는 본문의 loginForm 마커.
    (function(){
      var RLMS_LOGIN_URL = '<c:url value="/uat/uia/egovLoginUsr.do"/>';
      var _redir = false;
      window.rlmsGotoLoginOnExpiry = function(xhr){
        if(!xhr || _redir) return false;
        var hdr  = (xhr.getResponseHeader && xhr.getResponseHeader('X-RLMS-Auth')) || '';
        var body = (typeof xhr.responseText === 'string') ? xhr.responseText : '';
        if(xhr.status === 401 || hdr === 'login' || body.indexOf('id="loginForm"') >= 0){
          _redir = true; location.href = RLMS_LOGIN_URL; return true;
        }
        return false;
      };
      if(window.jQuery){ jQuery(document).ajaxComplete(function(e, xhr){ window.rlmsGotoLoginOnExpiry(xhr); }); }
    })();
  </script>
  <%-- jsTree 3.3.16 (로컬 번들) --%>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js'/>"></script>
  <%-- eGov 표준 제공 CKEditor 4 (번들) — provHtmlEdit.jsp 와 동일 --%>
  <script src="<c:url value='/html/egovframework/com/cmm/utl/ckeditor/ckeditor.js'/>"></script>
  <script>
    var TREE_URL = '<c:url value="/rlms/prom/treeJson.do"/>';
    var EDITOR_TREE_URL = '<c:url value="/rlms/prom/editorTreeJson.do"/>';   // 편집계 트리 — 승인 전 draft 연혁 포함(서버 역할게이트)
    var HIST_URL = '<c:url value="/rlms/prom/historyJson.do"/>';
    var PROV_GET = '<c:url value="/rlms/prom/provFragmentJson.do"/>';
    var PROV_SAVE= '<c:url value="/rlms/prom/saveProvHtml.do"/>';
    var PROV_VRSN_GET  = '<c:url value="/rlms/prom/provVrsnFragmentJson.do"/>';
    var PROV_VRSN_SAVE = '<c:url value="/rlms/prom/saveProvVrsn.do"/>';
    var DOCU_GET       = '<c:url value="/rlms/prom/docuFragmentJson.do"/>';
    var DOCU_SAVE      = '<c:url value="/rlms/prom/saveDocu.do"/>';
    var DOCU_INSERT    = '<c:url value="/rlms/prom/insertDocu.do"/>';
    var DOCU_NEXT_NO   = '<c:url value="/rlms/prom/docuNextItemJson.do"/>';
    var DOCU_BRANCH    = '<c:url value="/rlms/prom/branchDocu.do"/>';
    var DOCU_DELETE    = '<c:url value="/rlms/prom/deleteDocu.do"/>';
    var PROVHTML_BRANCH = '<c:url value="/rlms/prom/branchProvHtml.do"/>';
    var PROVHTML_DELETE = '<c:url value="/rlms/prom/deleteProvHtmlIde.do"/>';
    var VIEWER_FILES    = '<c:url value="/rlms/prom/viewerFileListJson.do"/>';
    var BULK_GET       = '<c:url value="/rlms/prom/provBulkBodyJson.do"/>';
    var DOC_IMPORT_URL = '<c:url value="/rlms/prom/importDocText.do"/>';
    var BULK_SAVE      = '<c:url value="/rlms/prom/saveProvBulkBody.do"/>';
    var BULK_HST_LIST  = '<c:url value="/rlms/prom/provTextHstListJson.do"/>';
    var BULK_HST_BODY  = '<c:url value="/rlms/prom/provTextHstBodyJson.do"/>';
    var BULK_HST_DEL   = '<c:url value="/rlms/prom/deleteProvTextHst.do"/>';
    var BUSEO_LIST     = '<c:url value="/rlms/prom/buseoListJson.do"/>';
    var PROM_DELETE    = '<c:url value="/rlms/prom/deletePromRevision.do"/>';   // 연혁 단건 삭제(2단계 확인)
    var PROM_GET = '<c:url value="/rlms/prom/promFragmentJson.do"/>';
    var DRAFT_LIST_URL = '<c:url value="/rlms/prom/draftListJson.do"/>';   // 작업중(draft) 패널
    var PROM_SAVE= '<c:url value="/rlms/prom/savePromMeta.do"/>';
    var NEXT_LAWNO = '<c:url value="/rlms/prom/nextLawNo.do"/>';
    var REL_LIST    = '<c:url value="/rlms/prom/relatedListJson.do"/>';
    var IMG_UPLOAD  = '<c:url value="/rlms/prom/objectFileUpload.do"/>';
    // ── 관련자료 8 액션 URL ─────────────────────────────────
    var REL_SAVE_FILE  = '<c:url value="/rlms/related/saveFile.do"/>';
    var REL_FILE_LIST  = '<c:url value="/rlms/related/fileList.do"/>';
    var REL_DEL_FILE   = '<c:url value="/rlms/related/deleteFile.do"/>';
    var REL_SAVE_ORGN  = '<c:url value="/rlms/related/saveOrgn.do"/>';
    var REL_ORGN_LIST  = '<c:url value="/rlms/related/orgnList.do"/>';
    var REL_DEL_ORGN   = '<c:url value="/rlms/related/deleteOrgn.do"/>';
    var REL_SAVE_HTML  = '<c:url value="/rlms/related/saveHtml.do"/>';
    var REL_HTML_LIST  = '<c:url value="/rlms/related/htmlList.do"/>';
    var REL_DEL_HTML   = '<c:url value="/rlms/related/deleteHtml.do"/>';
    var REL_SAVE_IMG   = '<c:url value="/rlms/related/saveImg.do"/>';
    var REL_IMG_LIST   = '<c:url value="/rlms/related/imgList.do"/>';
    var REL_DEL_IMG    = '<c:url value="/rlms/related/deleteImg.do"/>';
    var REL_LNK_LIST   = '<c:url value="/rlms/related/lnkList.do"/>';
    var REL_SAVE_LNK   = '<c:url value="/rlms/related/saveLnk.do"/>';
    var REL_DEL_LNK    = '<c:url value="/rlms/related/deleteLnk.do"/>';
    var REL_SAVE_WORD  = '<c:url value="/rlms/related/saveWord.do"/>';
    var REL_WORD_LIST  = '<c:url value="/rlms/related/wordList.do"/>';
    var REL_DEL_WORD   = '<c:url value="/rlms/related/deleteWord.do"/>';
    var REL_DETAIL_URL = '<c:url value="/rlms/related/relDetail.do"/>';
    var REL_ATT_DL_URL = '<c:url value="/rlms/related/attachDownload.do"/>';
    var REL_ZIP_URL    = '<c:url value="/rlms/related/downloadZip.do"/>';
    var REL_DEL_MASTER = '<c:url value="/rlms/related/deleteMaster.do"/>';
    var REL_DMN_LIST   = '<c:url value="/rlms/related/dmnLnkList.do"/>';
    var REL_SAVE_DMN   = '<c:url value="/rlms/related/saveDmnLnk.do"/>';
    var REL_DEL_DMN    = '<c:url value="/rlms/related/deleteDmnLnk.do"/>';
    var DMN_PROVS_URL  = '<c:url value="/rlms/prom/dmnLnkProvList.do"/>';
    var FRONT_VIEW_URL = '<c:url value="/rlms/fulltext/provisionList.do"/>';   // dmn 점프 — 사용자 전문뷰어
    var REL_CATE_LIST  = '<c:url value="/rlms/related/cateList.do"/>';
    var REL_CATE_INS   = '<c:url value="/rlms/related/cateInsert.do"/>';
    var REL_CATE_REN   = '<c:url value="/rlms/related/cateRename.do"/>';
    var REL_CATE_HIDE  = '<c:url value="/rlms/related/cateHide.do"/>';
    var REL_CATE_ORGN  = '<c:url value="/rlms/related/cateOrgnDown.do"/>';
    var REL_CATE_SEQ   = '<c:url value="/rlms/related/cateMoveSeq.do"/>';
    var REL_CATE_DEL   = '<c:url value="/rlms/related/cateDelete.do"/>';
    var SYS_ID   = '';   // 단일 시스템 — 프론트는 sysId 미전송, 서버가 SSYS_ID 정본값 처리
    // editor.do?promNo=N 딥링크 — 진입 시 해당 회차 자동 오픈 (숫자형 모델값이라 EL 직출력 안전)
    var DEEPLINK_PROM_NO = ${empty promNo ? 'null' : promNo};

    var ckPromBody = null;   // 회차 메타 4탭(주요내용/개정이유/부칙/서문) CKEditor — narrative 영역만 유지
    var curPbTab = 'reason'; // 레거시 기본 활성 탭 = 개정이유
    var ideProvMode = 'html';   // 'html' = TB_PROV_HTML 조 / 'vrsn' = TB_PROV_VRSN 조 / 'docu' = TB_DOCU 별표
    var ideDocuNo  = null;      // 현재 편집 중인 별표 docuNo (mode='docu' 일 때만)
    var ideDocuBranchPromNo = null;  // 별표 개정분기 대상 회차 — 상속 행을 새 회차에서 열었을 때만 (레거시 GAEJUNG_YN='Y')
    var ideDocuViewPromNo   = null;  // 별표를 열어본 회차(트리 컨텍스트) — saveDocu 서버 가드용
    var ideProvHtmlBranchPromNo = null;  // HTML 조항 개정분기 대상 회차 (별표와 동일 메커니즘)
    var ideProvHtmlViewPromNo   = null;  // HTML 조항을 열어본 회차 — saveProvHtml 서버 가드용
    function ckPromBodyCfg() {
      // #10 B(제한적 에디터) — 연혁 본문 4탭(개정이유/주요내용/부칙/서문)은 폰트색·링크·인라인이미지 없이
      //   줄바꿈·굵게·기울임·밑줄·리스트·들여쓰기 정도만. 이미지/표는 우측 '관련자료(B3 HTML표/B5 이미지)'·별표 첨부로.
      //   (HTML형식조문 본문 에디터·별표 에디터는 별도 설정으로 표/이미지 유지 — 이 함수와 무관.)
      return {
        height: 280, language: 'ko',
        removePlugins: 'elementspath,image,image2,link,colorbutton,colordialog,font,table,tabletools,tableselection',
        toolbar: [
          { name: 'clipboard',   items: ['Undo', 'Redo'] },
          { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Strike', 'RemoveFormat'] },
          { name: 'paragraph',   items: ['NumberedList', 'BulletedList', 'Outdent', 'Indent'] }
        ]
      };
    }
    function destroyCkPromBody() {
      if (ckPromBody) { try { ckPromBody.destroy(true); } catch (e) {} ckPromBody = null; }
    }
    // 본문 4탭(개정이유/주요내용/부칙/서문) 로드용 정규화.
    //  - 레거시 의 부칙(SBYLAW)은 평문 textarea 컬럼. CKEditor 는 평문의 줄바꿈/연속공백을
    //    하나로 병합하므로 그대로 넣으면 "제1조 … 제2조 …" 가 한 줄로 뭉친다.
    //  - 운영 데이터는 이관 과정에서 줄바꿈(\n)이 사라지고 들여쓰기 공백(예: 12칸)만 남아
    //    "            제1조 …            제2조 …" 형태가 됐다. 따라서 평문이면:
    //      ① <,>,& escape  ② 줄바꿈 → \n 정규화  ③ 2칸 이상 연속 공백(=잃어버린 줄바꿈)도 \n
    //      ④ 앞뒤 \n 정리  ⑤ \n → <br> 로 변환해 조(條) 단위 줄바꿈을 복원.
    //  - 개정이유/주요내용 등 HTML(SmartEditor) 컨텐츠는 태그가 있으므로 손대지 않는다.
    function pbBodyToHtml(s) {
      s = s || '';
      if (!/<[a-z!\/][\s\S]*>/i.test(s)) {
        s = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
             .replace(/\r\n|\r/g, '\n')
             .replace(/[ \t ]{2,}/g, '\n')
             .replace(/^\n+|\n+$/g, '')
             .replace(/\n/g, '<br>');
      }
      return s;
    }

    // ── 본문(조문) = plain text textarea 직통 ─────────────
    // 조문 본문은 ProvTextParser 가 정규식으로 분해하는 구조화 평문이라 WYSIWYG 불필요.
    // 표/이미지/HTML 은 우측 "관련자료" 의 HTML표 첨부(B3) / 이미지 첨부(B5) / 별표(docu) 로 분리.
    function bulkSetBody(text) {
      var ta = document.getElementById('ideBulkBody');
      if (ta) ta.value = text || '';
    }
    function bulkGetBody() {
      var ta = document.getElementById('ideBulkBody');
      return ta ? (ta.value || '') : '';
    }

    // ── 트리 탭 전환 (jsTree 가 컨테이너에 붙인 클래스 보존 — classList 만 토글) ──
    function ideSwitchTab(tab, btn) {
      var tabs = document.querySelectorAll('.ide-tab');
      for (var i = 0; i < tabs.length; i++) tabs[i].classList.remove('active');
      if (btn) btn.classList.add('active');
      document.getElementById('ideTreeCate').classList.toggle('active',    tab === 'cate');
      document.getElementById('ideTreeHistory').classList.toggle('active', tab === 'history');
      document.getElementById('ideTreeDraft').classList.toggle('active',   tab === 'draft');
      if (tab === 'draft' && window.ideLoadDraftPanel) window.ideLoadDraftPanel();   // 탭 진입 때마다 최신화
      ideRedrawActiveTree(tab);
    }
    // ── 회차 작업 드롭다운 — 항목 노출은 기존 id 기반 show/hide 로직 그대로,
    //    트리거([회차 작업 ▾])는 가시 항목 유무로 자동 동기화(MutationObserver) ──
    function idePromActionsToggle(e) {
      if (e) e.stopPropagation();
      var m = document.getElementById('idePromActionsMenu');
      if (m) m.classList.toggle('open');
    }
    document.addEventListener('click', function(e) {
      var m = document.getElementById('idePromActionsMenu');
      if (m && m.classList.contains('open') && !(e.target.closest && e.target.closest('.ide-prom-actions'))) {
        m.classList.remove('open');
      }
    });
    document.addEventListener('DOMContentLoaded', function() {
      var menu = document.getElementById('idePromActionsMenu');
      var btn  = document.getElementById('idePromActionsBtn');
      if (!menu || !btn) return;
      menu.addEventListener('click', function() { menu.classList.remove('open'); });   // 항목 실행 시 닫기
      var sync = function() {
        var any = false;
        for (var i = 0; i < menu.children.length; i++) {
          if (menu.children[i].style.display !== 'none') { any = true; break; }
        }
        btn.style.display = any ? '' : 'none';
        if (!any) menu.classList.remove('open');
      };
      new MutationObserver(sync).observe(menu, { attributes: true, subtree: true, attributeFilter: ['style'] });
      sync();
    });

    // jsTree 는 hidden→visible 전환 시 레이아웃 재계산이 필요
    function ideRedrawActiveTree(tab) {
      setTimeout(function() {
        try {
          var id = (tab === 'cate') ? 'ideTreeCate' : 'ideTreeHistory';
          var inst = (window.jQuery ? jQuery('#' + id).jstree(true) : null);
          if (inst && inst.redraw) inst.redraw(true);
        } catch (e) {}
      }, 0);
    }

    // ── 중앙 영역 전환 ──────────────────────────────────────
    function showCenterPane(which) {
      document.getElementById('idePlaceholder').style.display     = (which === 'placeholder') ? '' : 'none';
      document.getElementById('ideContextInfo').style.display     = (which === 'info') ? '' : 'none';
      document.getElementById('ideContextProm').style.display     = (which === 'prom') ? '' : 'none';
      document.getElementById('ideContextProv').style.display     = (which === 'prov') ? '' : 'none';
      document.getElementById('ideContextProvBulk').style.display = (which === 'bulk') ? '' : 'none';
      // 자동링크 제외범위 박스 — 회차 메타 화면일 때만 노출 (F3)
      var exclBox = document.getElementById('ideExclLnkBox');
      if (exclBox) exclBox.style.display = (which === 'prom') ? '' : 'none';
    }
    // ── HTML형식조문 조항 본문 직접편집 CKEditor (TB_PROV_HTML.SCONTENTS) ──
    //   VERSION/docu 조문은 평문 textarea 유지 — html 모드에서만 ideProvContents 를 CKEditor 로 치환.
    //   (저장위치: HTML형식조문=TB_PROV_HTML 통HTML / VERSION=TB_PROV_VRSN 분해 → html 본문은 리치 편집이 자연스러움)
    var ckProvHtml = null;
    function ckProvHtmlCfg() {
      return { height: 420, language: 'ko', removePlugins: 'elementspath',
               entities: false, entities_latin: false, basicEntities: true,
               filebrowserUploadUrl: IMG_UPLOAD, filebrowserUploadMethod: 'form' };
    }
    function setProvHint(html) {
      var h = document.querySelector('label[for="ideProvContents"] .hint');
      if (h) h.innerHTML = html;
    }
    // 저장 버튼 라벨 — 'new'(신규 등록) / 'edit'(기존 수정) / 'branch'(이 회차로 개정 등록)
    // 모든 prov-pane 셋업이 모드/식별자 세팅 후 이 함수를 호출하므로, 삭제버튼 가시성도 여기서 함께 재계산한다.
    function setProvSaveLabel(kind) {
      var b = document.getElementById('ideProvSaveBtn');
      if (b) {
        b.innerText = (kind === 'new')    ? '등록하기'
                    : (kind === 'branch') ? '이 회차로 개정 등록'
                    :                       '수정하기';
      }
      setProvDeleteVisible();
    }
    // 조 번호/가지번호 입력행 표시 토글 (신규 HTML 조항 등록 때만 노출)
    function toggleProvJoRow(show) {
      var r = document.getElementById('ideProvJoRow');
      if (r) r.style.display = show ? '' : 'none';
      var h = document.getElementById('ideProvJoHint');
      if (h) h.style.display = show ? '' : 'none';
    }
    // 삭제버튼 가시성 — own-회차 기존행(html: provHtmlNo & !branch / docu: ideDocuNo & !branch) 일 때만.
    // vrsn / 신규(식별자 없음) / 상속(branch) 모드에서는 숨김.
    function setProvDeleteVisible() {
      var b = document.getElementById('ideProvDeleteBtn');
      if (!b) return;
      var show =
        (ideProvMode === 'html' && document.getElementById('ideProvHtmlNo').value && !ideProvHtmlBranchPromNo) ||
        (ideProvMode === 'docu' && ideDocuNo && !ideDocuBranchPromNo);
      b.style.display = show ? '' : 'none';
    }
    function toggleProvCharPalette(show) {
      var p = document.querySelector('.ide-charpalette[data-target="ideProvContents"]');
      if (p) p.style.display = show ? '' : 'none';
    }
    // html 모드 진입 시 — ideProvContents 를 CKEditor 로 (표/이미지 인라인 직접편집)
    function mountCkProvHtml(contents) {
      destroyCkProv();                                  // 이전 CKEditor 정리 + textarea 복원
      var ta = document.getElementById('ideProvContents');
      if (ta) ta.value = contents || '';                // destroy 후 새 본문으로 덮어쓰기
      try {
        ckProvHtml = CKEDITOR.replace('ideProvContents', ckProvHtmlCfg());
        ckProvHtml.on('instanceReady', function() { try { ckProvHtml.setData(contents || ''); } catch (e) {} });
      } catch (e) { ckProvHtml = null; if (ta) ta.value = contents || ''; }
      toggleProvCharPalette(false);                     // CKEditor 자체 툴바 사용 — 특수문자 팔레트 숨김
      setProvHint('(HTML 직접편집 — 표·이미지를 본문에 바로 넣을 수 있습니다)');
    }
    // prov pane 떠날 때 / 평문(VERSION·docu) 모드 전환 시 — CKEditor 폐기하고 평문 textarea 복원
    function destroyCkProv() {
      if (ckProvHtml) {
        try { ckProvHtml.destroy(true); } catch (e) {}  // destroy(true) 가 textarea 복원 (updateElement 는 호출자가 필요시 먼저)
        ckProvHtml = null;
      }
      toggleProvCharPalette(true);
      setProvHint('(평문 — 표/이미지/HTML 은 우측 "관련자료"에 첨부)');
    }

    // ── 규정 본문 탭 전환 (활성 탭만 CKEditor) ───────────
    function idePbTab(tab, btn) {
      // 현재 탭 데이터 보존
      if (ckPromBody) {
        document.getElementById('idePromBody_' + curPbTab).value = ckPromBody.getData();
        destroyCkPromBody();
      }
      var btns = document.querySelectorAll('.ide-pbtab');
      for (var i = 0; i < btns.length; i++)
        btns[i].classList.toggle('active', btns[i].getAttribute('data-pbtab') === tab);
      var keys = ['gaejung', 'reason', 'bylaw', 'preamble'];
      for (var k = 0; k < keys.length; k++)
        document.getElementById('idePromBody_' + keys[k]).style.display = (keys[k] === tab) ? '' : 'none';
      curPbTab = tab;
      ckPromBody = CKEDITOR.replace('idePromBody_' + tab, ckPromBodyCfg());
    }

    // ── 우측: 레거시 식 관련자료 (TB_REL_VRSN + TB_REL_VRSN_CATE) — 카테고리별 그룹화 ──
    //  (레거시 TB_ATTACH 직접 조회 경로(loadAttachList/attachListJson.do)는 폐기 —
    //   TB_ATTACH 에 SREF_TABLE='TB_PROM'/'TB_PROV_HTML' 행을 쓰는 코드가 없어 구조적 0건이었음.
    //   모든 첨부는 관련자료(TB_REL_*) 경유 → 이 함수 하나가 우측 패널 단일 데이터 소스.)
    // kind: file/word/orgn/html/image/url/dmn/hbtml/unknown
    var KIND_ICON = { file:'📄', word:'📝', orgn:'📎', html:'📰', image:'🖼️',
                      url:'🔗', dmn:'🧷', hbtml:'📃', unknown:'·' };
    var KIND_LABEL = { file:'파일', word:'Word', orgn:'원본', html:'HTML', image:'이미지',
                       url:'URL', dmn:'규정연계', hbtml:'템플릿', unknown:'' };
    <%-- ideRelFlag() 는 ctx 를 보는 IIFE 안에서 window 에 노출된다(정의 위치는 ctx 선언 근처).
         여기서는 아직 없을 수 있으므로 방어적으로 호출. --%>
    function ideRelFlagSafe() {
      return (window.ideRelFlag ? window.ideRelFlag() : '');
    }
    function loadRelatedList(promNo, fullItem) {
      // 마지막 로딩한 컨텍스트를 window 에 캐시 — IIFE 바깥 함수(ideOpenRel, ideDeleteRelMaster 등) 가
      // ctx 클로저에 접근 못 하므로 이 캐시로 promNo/fullItem 을 공유.
      window.__ideRelCtx = { promNo: promNo, fullItem: fullItem, flag: ideRelFlagSafe() };
      var $box = $('#ideRelatedList');
      if (!promNo) {
        $box.html('<p class="empty">규정/조항을 선택하면<br/>관련자료가 표시됩니다.</p>');
        return;
      }
      $box.html('<p class="empty">불러오는 중...</p>');

      // ownSet: 이 회차가 직접 소유한 relVrsnNo 집합(null 이면 전부 소유로 간주 = 조 단위).
      //   상속(이전 회차) 자료 = 누적 목록엔 있으나 ownSet 엔 없는 것 → '상속' 배지 + 삭제버튼 미노출.
      function renderRelated(d, ownSet) {
        var groups = (d && d.groups) ? d.groups : [];
        if (!groups.length) {
          $box.html('<p class="empty">등록되어있는 자료가<br/>없습니다.</p>');
          return;
        }
        var h = '';
        for (var g = 0; g < groups.length; g++) {
          var grp = groups[g];
          var items = grp.items || [];
          var emptyCls = grp.isDefault ? ' is-empty-cate' : '';
          h += '<div class="ide-rel-group">'
            +    '<h4 class="ide-rel-cate-title' + emptyCls + '"'
            +       (grp.isDefault ? ' title="이 자료에는 분류가 지정되지 않았습니다."' : '')
            +    '>'
            +       ideEsc(grp.cateTitle || '(분류 미지정)')
            +       ' <span class="cnt">' + items.length + '</span>'
            +    '</h4>'
            +    '<ul class="ide-rel-items">';
          for (var i = 0; i < items.length; i++) {
            var it = items[i];
            var inherited = ownSet ? !ownSet[String(it.relVrsnNo)] : false;
            var icon  = KIND_ICON[it.kind] || KIND_ICON.unknown;
            var label = KIND_LABEL[it.kind] || '';
            var click = (it.kind === 'url' && it.url)
                        ? 'window.open(\'' + ideEsc(it.url).replace(/'/g, "\\'") + '\',\'_blank\');return false;'
                        : 'ideOpenRel(' + it.relVrsnNo + ',\'' + it.kind + '\');return false;';
            var safeTitle = ideEsc(it.title).replace(/'/g, "\\'");
            // 레거시 토큰 복사용 데이터 (kind/relVrsnNo/title/url/flag/fullItem) — data-* 로 전달
            var copyData = ' data-kind="' + ideEsc(it.kind) + '"'
                         + ' data-rvn="' + it.relVrsnNo + '"'
                         + ' data-title="' + ideEsc(it.title || '') + '"'
                         + ' data-url="' + ideEsc(it.url || '') + '"'
                         + ' data-flag="' + ideEsc(it.flag || '') + '"'
                         + ' data-fullitem="' + ideEsc(it.fullItem || '') + '"';
            h += '<li class="ide-rel-item kind-' + ideEsc(it.kind) + (inherited ? ' is-inherited' : '') + '">'
              +    '<span class="ide-rel-icon">' + icon + '</span>'
              +    '<a href="#" onclick="' + click + '">' + ideEsc(it.title) + '</a>'
              +    (label ? '<span class="ide-rel-kind">[' + ideEsc(label) + ']</span>' : '')
              +    (inherited ? '<span class="ide-rel-inherit" title="이전 회차에서 상속된 자료 — 이 회차에서는 보기/인용만, 삭제는 소유 회차에서">상속</span>' : '')
              +    '<button type="button" class="ide-rel-copy" title="본문 인용 토큰을 클립보드로 복사"'
              +        copyData
              +        ' onclick="event.stopPropagation();ideCopyRelTag(this);return false;">📋</button>'
              +    (inherited ? '' :
                     '<button type="button" class="ide-rel-del" title="삭제"'
              +        ' onclick="event.stopPropagation();ideDeleteRelMaster('
              +        it.relVrsnNo + ',\'' + ideEsc(it.kind) + '\',\'' + safeTitle + '\');return false;">×</button>')
              + '</li>';
          }
          h += '</ul></div>';
        }
        $box.html(h);
        // 현재 선택된 카테고리 필터 재적용 (재로딩으로 인한 필터 리셋 방지)
        var currentFilter = $('#ideRelKindFilter').val() || 'all';
        if (currentFilter !== 'all') ideFilterRelKind(currentFilter);
      }

      var failFn = function(xhr) { $box.html('<p class="empty">조회 실패 (' + ((xhr && xhr.status) || '') + ')</p>'); };
      // GET 캐싱 비활성 — 저장 직후 새 행 확인을 위해 매번 fresh
      if (fullItem) {
        // 조/별표 단위 — 그 항목의 자료(모두 이 회차 소유). 상속 구분 불필요.
        $.ajax({ url: REL_LIST, data: { promNo: promNo, fullItem: fullItem, flag: ideRelFlagSafe() },
                 dataType: 'json', cache: false })
          .done(function(d) { renderRelated(d, null); })
          .fail(failFn);
      } else {
        // 회차 단위 — 누적(상속 포함) 목록 + 자체보유 목록 동시 조회 → 상속 정밀 판별.
        //   본문 토큰이 참조하는 상속 이미지/파일이 패널에 안 보이던 문제 해소(서버 변경/재시작 불필요).
        var pCum = $.ajax({ url: REL_LIST, data: { promNo: promNo, cumulative: 'Y' }, dataType: 'json', cache: false });
        var pOwn = $.ajax({ url: REL_LIST, data: { promNo: promNo }, dataType: 'json', cache: false });
        $.when(pCum, pOwn).done(function(cum, own) {
          var cumData = cum[0], ownData = own[0];
          var ownSet = {};
          (((ownData && ownData.groups) || [])).forEach(function(grp) {
            (grp.items || []).forEach(function(it) { ownSet[String(it.relVrsnNo)] = true; });
          });
          renderRelated(cumData, ownSet);
        }).fail(failFn);
      }
    }
    // ── 레거시 자체 마크업 토큰 클립보드 복사 (TagType.java 1:1) ──
    //   본문/회차 reason 텍스트필드에 붙여넣으면 ProvTextParser (후속)가 HTML 로 치환.
    //   토큰 형식 (레거시 TagType.java):
    //     file/orgn: [태그:파일:relVrsnNo]제목[/태그]
    //     word:     [태그:워드이미지:relVrsnNo]
    //     image:    [태그:일반이미지:relVrsnNo]
    //     html:     [태그:HTML:relVrsnNo]
    //     url:      [태그:링크:URL]제목[/태그]
    //     dmn:      [태그:도메인링크:flag:Y:?:?:fullItem:?]제목[/태그]   ← lawId/lawNo/fileItem 미노출 → 메타 자리는 빈값
    //   레거시 의 @@ID 는 child PK 였으나 RLMS 는 master(relVrsnNo) 사용 — 파서가 stable 로 child 해석.
    window.ideCopyRelTag = function(btn) {
      var d   = btn.dataset || {};
      var k   = d.kind  || 'unknown';
      var id  = d.rvn   || '';
      var ttl = d.title || '';
      var u   = d.url   || '';
      var flg = d.flag  || '';
      var fi  = d.fullitem || '';
      var token = '';
      switch (k) {
        case 'file': case 'orgn': token = '[태그:파일:' + id + ']' + ttl + '[/태그]'; break;
        case 'word':              token = '[태그:워드이미지:' + id + ']'; break;
        case 'image':             token = '[태그:일반이미지:' + id + ']'; break;
        case 'html':              token = '[태그:HTML:' + id + ']'; break;
        case 'url':               token = '[태그:링크:' + u + ']' + ttl + '[/태그]'; break;
        case 'dmn':               token = '[태그:도메인링크:' + flg + ':Y:::' + fi + ':]' + ttl + '[/태그]'; break;
        default:                  token = ttl;
      }
      // navigator.clipboard 우선, 실패 시 textarea fallback (구브라우저/HTTP 컨텍스트)
      var ok = function() { ideToast('클립보드에 복사됨\n' + token); };
      var ng = function() { ideToast('복사 실패 — 브라우저 권한/HTTPS 확인'); };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(token).then(ok).catch(function() { ideCopyFallback(token, ok, ng); });
      } else {
        ideCopyFallback(token, ok, ng);
      }
    };
    function ideCopyFallback(text, ok, ng) {
      try {
        var ta = document.createElement('textarea');
        ta.value = text; ta.style.position = 'fixed'; ta.style.left = '-9999px';
        document.body.appendChild(ta); ta.select();
        var r = document.execCommand('copy');
        document.body.removeChild(ta);
        if (r) ok(); else ng();
      } catch (e) { ng(); }
    }
    // 우측 패널 전용 미니 토스트 (KRDS 풀스타일 토스트는 무거우므로 자체 구현)
    var ideToastTid = null;
    function ideToast(msg) {
      var $t = $('#ideToastBox');
      if (!$t.length) {
        $t = $('<div id="ideToastBox" class="ide-toast"></div>').appendTo('body');
      }
      $t.text(msg).addClass('show');
      if (ideToastTid) clearTimeout(ideToastTid);
      ideToastTid = setTimeout(function() { $t.removeClass('show'); }, 1800);
    }
    // ── 카테고리 필터 (레거시 전체보기/일반파일/원본파일/분류파일/HTML표/그림파일/컨텐츠연계/관련규정연계) ──
    //   - 항목 행은 CSS 가 .ide-related-list[data-filter=xxx] 로 숨김
    //   - 빈 그룹은 JS 가 직접 toggle
    window.ideFilterRelKind = function(kind) {
      var $box = $('#ideRelatedList');
      $box.attr('data-filter', kind || 'all');
      $box.find('.ide-rel-group').each(function() {
        var $g = $(this);
        if (!kind || kind === 'all') {
          $g.show();
        } else {
          var hasMatch = $g.find('.ide-rel-item.kind-' + kind).length > 0;
          $g.toggle(hasMatch);
        }
      });
    };
    // ── 단계 C: 관련자료 항목 상세 모달 ─────────────────────────
    //   kind: file/word/orgn/image/html/url/dmn
    //   file/word/orgn: 첨부 다운로드 링크 (이미지 워드 등은 ext 별 처리)
    //   image: img 인라인 + 다운로드
    //   html : SHTML 그대로 렌더
    //   url  : URL 목록 (외부 새창)
    //   dmn  : 연계 규정 목록 — 서버 해석 targetPromNo 로 사용자 전문뷰어 점프 (ideDmnJumpUrl)
    window.ideOpenRel = function(relVrsnNo, kind) {
      var kindLabel = ({ file:'파일', word:'문서', orgn:'원본', image:'이미지',
                          html:'HTML 표', url:'관련 URL', dmn:'규정 연계' })[kind] || kind;
      $('#ideRelDetailTitle').text('관련자료 상세 — ' + kindLabel);
      var rc = window.__ideRelCtx || {};
      $('#ideRelDetailCtx').text('회차 #' + (rc.promNo || '?')
        + (rc.fullItem ? ' / 조항 ' + rc.fullItem : ''));
      $('#ideRelDetailBody').html('<p class="empty">불러오는 중…</p>');
      $('#ideRelDetailModal').show();
      $.ajax({ url: REL_DETAIL_URL, dataType: 'json',
               data: { relVrsnNo: relVrsnNo, kind: kind } })
        .done(function(d) {
          if (!d || !d.ok) {
            $('#ideRelDetailBody').html('<p class="empty">조회 실패: '
              + ideEsc(d && d.error ? d.error : '?') + '</p>');
            return;
          }
          $('#ideRelDetailBody').html(ideRelDetailRender(kind, d.items || []));
        })
        .fail(function() {
          $('#ideRelDetailBody').html('<p class="empty">조회 통신 오류</p>');
        });
    };
    window.ideCloseRelDetail = function() {
      $('#ideRelDetailBody').empty();
      $('#ideRelDetailModal').hide();
    };

    // kind 별 자식 PK 필드명 + 삭제 URL/파라미터
    var IDE_REL_PK_BY_KIND = {
      file: 'relFileNo', orgn: 'relOrgnNo', image: 'relImgNo',
      word: 'relWordNo', html: 'relHtmlNo'
    };
    // 우측 목록의 한 행(마스터) 통째 삭제
    window.ideDeleteRelMaster = function(relVrsnNo, kind, title) {
      if (!relVrsnNo) return;
      if (!confirm('"' + title + '"\n관련자료 항목을 삭제합니다. 계속할까요?')) return;
      $.ajax({ url: REL_DEL_MASTER, type: 'POST',
               data: { relVrsnNo: relVrsnNo, kind: kind }, dataType: 'json' })
        .done(function(d) {
          if (d && d.ok) {
            var c = window.__ideRelCtx || {};
            loadRelatedList(c.promNo, c.fullItem);
          } else {
            alert('삭제 실패: ' + (d && d.error ? d.error : '알 수 없는 오류'));
          }
        })
        .fail(function() { alert('삭제 통신 오류'); });
    };

    window.ideRelDeleteItem = function(kind, childPk) {
      if (!childPk) return;
      if (!confirm('이 항목을 삭제합니다. 계속할까요?')) return;
      var url, paramName;
      switch (kind) {
        case 'file':  url = REL_DEL_FILE; paramName = 'relFileNo'; break;
        case 'orgn':  url = REL_DEL_ORGN; paramName = 'relOrgnNo'; break;
        case 'image': url = REL_DEL_IMG;  paramName = 'relImgNo';  break;
        case 'word':  url = REL_DEL_WORD; paramName = 'relWordNo'; break;
        case 'html':  url = REL_DEL_HTML; paramName = 'relHtmlNo'; break;
        default: alert('삭제 미지원 종류: ' + kind); return;
      }
      var data = {}; data[paramName] = childPk;
      $.ajax({ url: url, type: 'POST', data: data, dataType: 'json' })
        .done(function(d) {
          if (d && d.ok) {
            ideCloseRelDetail();
            var rc = window.__ideRelCtx || {};
            loadRelatedList(rc.promNo, rc.fullItem);
          } else {
            alert('삭제 실패: ' + (d && d.error ? d.error : '알 수 없는 오류'));
          }
        })
        .fail(function() { alert('삭제 통신 오류'); });
    };
    function ideRelDelBtn(kind, item) {
      var pkField = IDE_REL_PK_BY_KIND[kind];
      var pk = pkField ? item[pkField] : null;
      if (!pk) return '';
      return '<button type="button" class="ide-cate-del ide-rel-detail-del"'
           + ' onclick="ideRelDeleteItem(\'' + kind + '\',' + pk + ');">삭제</button>';
    }

    function ideRelDetailRender(kind, items) {
      if (!items || !items.length) return '<p class="empty">표시할 항목이 없습니다.</p>';
      var h = '';
      if (kind === 'file' || kind === 'orgn') {
        h += '<ul class="ide-rel-detail-list">';
        for (var i = 0; i < items.length; i++) {
          var it = items[i];
          var nm = it.attName || it.title || '(파일)';
          var sz = ideFmtSize ? ideFmtSize(it.attSize) : '';
          h += '<li>'
            +    '<span class="ide-rel-detail-icon">📄</span>'
            +    '<span class="ide-rel-detail-name">' + ideEsc(it.title || nm) + '</span>'
            +    '<span class="ide-rel-detail-meta">' + ideEsc(nm) + (sz ? ' · ' + sz : '') + '</span>'
            +    (it.attNo ? '<a class="krds-btn krds-btn--primary ide-rel-detail-dl"'
                            + ' href="' + REL_ATT_DL_URL + '?attNo=' + it.attNo + '">다운로드</a>' : '')
            +    ideRelDelBtn(kind, it)
            +  '</li>';
        }
        h += '</ul>';
      } else if (kind === 'word') {
        // 자체변환(.docx/.hwpx)된 문서는 본문 HTML 인라인 표시 + 원본 다운로드. 미변환(.doc/.hwp 등)은 다운로드만.
        h += '<ul class="ide-rel-detail-list">';
        for (var w = 0; w < items.length; w++) {
          var wt = items[w];
          var wnm = wt.attName || wt.title || '(문서)';
          var wsz = ideFmtSize ? ideFmtSize(wt.attSize) : '';
          h += '<li class="ide-rel-word-item">'
            +    '<div class="ide-rel-word-head">'
            +      '<span class="ide-rel-detail-icon">📄</span>'
            +      '<span class="ide-rel-detail-name">' + ideEsc(wt.title || wnm) + '</span>'
            +      (wt.type ? ' <span class="ide-cate-badge">' + ideEsc(wt.type) + '</span>' : '')
            +      '<span class="ide-rel-detail-meta">' + ideEsc(wnm) + (wsz ? ' · ' + wsz : '') + '</span>'
            +      (wt.attNo ? '<a class="krds-btn krds-btn--primary ide-rel-detail-dl"'
                              + ' href="' + REL_ATT_DL_URL + '?attNo=' + wt.attNo + '">원본 다운로드</a>' : '')
            +      ideRelDelBtn(kind, wt)
            +    '</div>'
            +    (wt.html
                  ? '<div class="ide-rel-word-body">' + wt.html + '</div>'
                  : '<div class="ide-rel-word-noconv">본문 미리보기 없음 — 원본 다운로드로 확인하세요. (자체변환은 .docx / .hwpx 만 지원)</div>')
            +  '</li>';
        }
        h += '</ul>';
      } else if (kind === 'image') {
        h += '<div class="ide-rel-detail-imgwrap">';
        for (var j = 0; j < items.length; j++) {
          var ii = items[j];
          h += '<div class="ide-rel-detail-imgcard">'
            +    (ii.attNo ? '<img src="' + REL_ATT_DL_URL + '?attNo=' + ii.attNo
                            + '" alt="' + ideEsc(ii.title || '') + '"/>' : '')
            +    '<div class="ide-rel-detail-imgcap">' + ideEsc(ii.title || '') + '</div>'
            +    '<div class="ide-rel-detail-imgactions">'
            +      (ii.attNo ? '<a class="krds-btn krds-btn--primary ide-rel-detail-dl"'
                              + ' href="' + REL_ATT_DL_URL + '?attNo=' + ii.attNo + '">다운로드</a>' : '')
            +      ideRelDelBtn(kind, ii)
            +    '</div>'
            +  '</div>';
        }
        h += '</div>';
      } else if (kind === 'html') {
        for (var k = 0; k < items.length; k++) {
          var hh = items[k];
          h += '<div class="ide-rel-detail-html">'
            +    '<div class="ide-rel-detail-htmltit">'
            +       '<span>' + ideEsc(hh.title || '') + '</span>'
            +       ideRelDelBtn(kind, hh)
            +    '</div>'
            +    '<div class="ide-rel-detail-htmlbody">' + (hh.html || '') + '</div>'
            +  '</div>';
        }
      } else if (kind === 'url') {
        h += '<ul class="ide-rel-detail-list">';
        for (var u = 0; u < items.length; u++) {
          var ul = items[u];
          var url = ul.url || '';
          h += '<li>'
            +    '<span class="ide-cate-badge">' + ideEsc(ul.cate || 'URL') + '</span> '
            +    '<a href="' + ideEsc(url) + '" target="_blank" rel="noopener">'
            +      ideEsc(ul.title || url)
            +    '</a>'
            +    '<span class="ide-rel-detail-meta">' + ideEsc(url) + '</span>'
            +  '</li>';
        }
        h += '</ul>';
      } else if (kind === 'dmn') {
        h += '<ul class="ide-rel-detail-list">';
        for (var m = 0; m < items.length; m++) {
          var dm = items[m];
          var kindL = (dm.flag === 'PROVISION') ? '조문'
                    : (dm.flag === 'DOCUMENT') ? '문서' : '규정';
          var jump = ideDmnJumpUrl(dm);
          h += '<li>'
            +    '<span class="ide-cate-badge">' + ideEsc(kindL) + '</span> '
            +    (jump
                  ? '<a href="' + jump + '" target="_blank" rel="noopener" title="사용자 전문뷰어에서 열기">'
                      + ideEsc(dm.title || dm.targetPromTitle || '') + ' ↗</a>'
                  : '<span class="ide-rel-detail-name">' + ideEsc(dm.title || dm.targetPromTitle || '') + '</span>')
            +    (dm.alwaysLatestYn === 'Y'
                  ? '<span class="ide-rel-detail-meta">항상 최신 회차</span>' : '')
            +    (jump ? '' : '<span class="ide-rel-detail-meta">대상 회차 없음 — 점프 불가</span>')
            +  '</li>';
        }
        h += '</ul>';
      } else {
        h += '<p class="empty">표시 형식이 없는 항목 (' + ideEsc(kind) + ')</p>';
      }
      return h;
    }
    function ideEsc(s) {
      return String(s == null ? '' : s)
        .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }
    /** dmn 항목 → 사용자 전문뷰어 점프 URL. 서버가 해석한 targetPromNo 사용
     *  (SAWS_LST_YN='Y'=현행, 'N'=저장 회차 — RelDmnLnk 매퍼 dmnTargetKeep 참조).
     *  조문 연계면 제목의 "제N조(의M)" 를 뷰어 앵커(jo-N[-M])로 변환. 해석 불가면 null. */
    function ideDmnJumpUrl(dm) {
      if (!dm || !dm.targetPromNo) return null;
      var u = FRONT_VIEW_URL + '?promNo=' + dm.targetPromNo;
      if (dm.flag === 'PROVISION') {
        var mm = /제\s*(\d+)\s*조(?:의\s*(\d+))?/.exec(dm.title || '');
        if (mm) u += '#jo-' + mm[1] + (mm[2] ? '-' + mm[2] : '');
      }
      return u;
    }
    // 특수문자 팔레트 — 클릭 시 대상 textarea 의 커서 위치에 삽입
    function ideInsertAtCursor(taId, text) {
      var ta = document.getElementById(taId);
      if (!ta) return;
      var s = (ta.selectionStart != null) ? ta.selectionStart : ta.value.length;
      var e = (ta.selectionEnd   != null) ? ta.selectionEnd   : ta.value.length;
      var v = ta.value;
      ta.value = v.slice(0, s) + text + v.slice(e);
      var pos = s + text.length;
      try { ta.setSelectionRange(pos, pos); } catch (ex) {}
      ta.focus();
      // change 이벤트로 묶인 핸들러(행수 카운트 등) 트리거
      try { ta.dispatchEvent(new Event('input',  { bubbles: true })); } catch (ex) {}
      try { ta.dispatchEvent(new Event('change', { bubbles: true })); } catch (ex) {}
    }
    $(function() {

      // 특수문자 팔레트 — 클릭 위임
      $(document).on('mousedown', '.ide-charpalette button', function(e) {
        e.preventDefault();   // textarea focus 유지
      });
      $(document).on('click', '.ide-charpalette button', function() {
        var taId = $(this).closest('.ide-charpalette').data('target');
        if (taId) ideInsertAtCursor(taId, this.textContent);
      });

      // ── 규정분류 트리 ───────────────────────────────────
      //   편집계 전용 editorTreeJson — 승인 전 draft 연혁도 일반 노드로 표시. front 드로어(treeJson)는 현행만.
      $('#ideTreeCate').jstree({
        core: {
          themes: { responsive: false, dots: true, icons: true },
          check_callback: true,
          data: function(node, cb) {
            $.ajax({ url: EDITOR_TREE_URL, data: { id: node.id }, dataType: 'json' })
              .done(function(d) { cb(d || []); })
              .fail(function(xhr) { console.error('editorTreeJson 실패', xhr.status, xhr.responseText); cb([]); });
          }
        },
        types: {
          gubun:   { icon: 'jstree-folder' },
          cate:    { icon: 'jstree-folder' },
          law:     { icon: 'jstree-folder' },   // 규정(정관)
          prom:    { icon: 'jstree-folder' },   // 회차
          provgrp: { icon: 'jstree-folder' },   // 📁조문
          docgrp:  { icon: 'jstree-folder' },   // 📁별표/별지서식
          grp:     { icon: 'jstree-folder' },   // 장 / 절
          prov:    { icon: 'jstree-file' },     // 조
          docu:    { icon: 'jstree-file' }      // 별표/별지서식 항목
        },
        search: { show_only_matches: true, show_only_matches_children: true, case_sensitive: false, fuzzy: false },
        plugins: ['types', 'search']
      });

      // ── 검색 (디바운스 250ms) ───────────────────────────
      var searchTimer = null;
      $('#ideTreeSearch').on('keyup input', function() {
        var q = $(this).val();
        clearTimeout(searchTimer);
        searchTimer = setTimeout(function() {
          var id = $('.ide-tree-pane.active').attr('id');
          if (!id) return;
          var $t = $('#' + id);
          if ($t.jstree(true)) $t.jstree('search', q);
        }, 250);
      });
      window.ideClearSearch = function() {
        $('#ideTreeSearch').val('');
        var id = $('.ide-tree-pane.active').attr('id');
        if (id) { var $t = $('#' + id); if ($t.jstree(true)) $t.jstree('clear_search'); }
      };

      // ── 노드 선택 (분류 트리) ───────────────────────────
      $('#ideTreeCate').on('select_node.jstree', function(e, data) {
        var n = data.node;
        ideOnSelectNode(n, 'cate');
        // 규정분류 트리에서 규정(prom) 클릭은 **연혁목차 탭으로 이동만** — 하위(조문/별표) 펼치지 않음.
        // (사용자 요청: 분류 트리는 규정 목록 탐색만, 본문/구조는 연혁목차에서)
        // 그 외 노드(provgrp/docgrp/grp 등) 는 사용자가 명시적으로 펼침 화살표 누르면 펼쳐짐.
        if (n.type !== 'prom' && ideExpandable(n.type)) data.instance.open_node(n);
      });
      function ideExpandable(t) {
        return t === 'prom' || t === 'provgrp' || t === 'docgrp' || t === 'grp';
      }

      // ── 연혁목차 트리 ───────────────────────────────────
      var loadedHistoryLawId = null;
      function loadHistoryTree(lawId) {
        // 이미 같은 규정으로 로드돼 있으면 트리 보존 (펼침 상태 유지) — 탭만 전환
        if (loadedHistoryLawId === lawId && $('#ideTreeHistory').jstree(true)) {
          switchTreeTab('history');
          return;
        }
        loadedHistoryLawId = lawId;
        var $h = $('#ideTreeHistory');
        if ($h.jstree(true)) $h.jstree('destroy');
        $h.empty();
        $h.jstree({
          core: {
            themes: { responsive: false, dots: true, icons: true },
            data: function(node, cb) {
              if (node.id === '#') {
                $.ajax({ url: HIST_URL, data: { lawId: lawId }, dataType: 'json' })
                  .done(function(d) { cb(d || []); }).fail(function() { cb([]); });
              } else {
                $.ajax({ url: TREE_URL, data: { id: node.id }, dataType: 'json' })
                  .done(function(d) { cb(d || []); }).fail(function() { cb([]); });
              }
            }
          },
          types: {
            law:     { icon: 'jstree-folder' },
            prom:    { icon: 'jstree-folder' },
            provgrp: { icon: 'jstree-folder' },
            docgrp:  { icon: 'jstree-folder' },
            grp:     { icon: 'jstree-folder' },
            prov:    { icon: 'jstree-file' },
            docu:    { icon: 'jstree-file' }
          },
          search: { show_only_matches: true, show_only_matches_children: true, case_sensitive: false },
          plugins: ['types', 'search']
        });
      }
      $(document).on('select_node.jstree', '#ideTreeHistory', function(e, data) {
        ideOnSelectNode(data.node, 'history');
        if (ideExpandable(data.node.type)) data.instance.open_node(data.node);
      });
      // 회차(prom) 노드 자식 로드 완료 시, 그 안의 provgrp 자식도 자동 펼침 (state.opened 누락 방어)
      // 자동 펼침 케이스는 ideAutoExpanding 플래그로 표시 → open_node 핸들러가 일괄편집 자동 진입을 skip
      var ideAutoExpanding = false;
      $(document).on('load_node.jstree', '#ideTreeHistory', function(e, data) {
        var n = data.node;
        if (!n || n.type !== 'prom') return;
        try {
          var inst = data.instance;
          (n.children || []).forEach(function(childId) {
            var child = inst.get_node(childId);
            if (child && child.type === 'provgrp') {
              setTimeout(function() {
                ideAutoExpanding = true;
                inst.open_node(child);
                setTimeout(function() { ideAutoExpanding = false; }, 50);
              }, 0);
            }
          });
        } catch (err) { console.warn('[load_node] auto-expand provgrp 실패', err); }
      });

      // provgrp 펼침 이벤트 = 일괄편집 진입 (jsTree 가 group 노드 select_node 를 누락하는 케이스 fallback).
      // 자동 펼침은 skip — 사용자가 직접 펼친 경우만 진입.
      $(document).on('open_node.jstree', '#ideTreeHistory', function(e, data) {
        var n = data.node;
        if (!n || n.type !== 'provgrp') return;
        if (ideAutoExpanding) return;
        var promNo = (n.data && n.data.promNo) || parseInt((n.id || '').split(':')[1], 10);
        if (!promNo) return;
        ideOnSelectNode(n, 'history');
      });

      // anchor 클릭 직접 감지 — jsTree 의 select_node 가 일부 노드(특히 자식 있는 group, lazy-load 자식)
      // 에서 누락되는 케이스 보완. anchor 클릭은 펼침 상태/자식 유무 무관 항상 발생.
      // 모든 노드 타입에 대해 ideOnSelectNode 호출 — select_node 와 중복 가능하지만 idempotent 라 무해.
      $(document).on('click', '#ideTreeHistory .jstree-anchor', function() {
        var nodeId = this.parentNode && this.parentNode.id;
        if (!nodeId) return;
        var inst = $.jstree.reference('#ideTreeHistory');
        if (!inst) return;
        var n = inst.get_node(nodeId);
        if (!n) return;
        ideOnSelectNode(n, 'history');
      });

      // ── 현재 선택 컨텍스트 ──────────────────────────────
      var ctx = { cateNo: null, cateNm: null, promNo: null, lawId: null, fullItem: null, item: null, docu: false };

      /**
       * 관련자료 부착 컨텍스트 플래그 — TB_REL_VRSN.SFLAG.
       *   DOCUMENT     = 별표/별지서식 단위 (2026-07-30 개별 첨부)
       *   PROVISION    = 조 단위
       *   PROMULGATION = 회차 전체
       * 저장(saveFile/saveHtml/saveLnk/…)과 조회(relatedListJson)가 같은 값을 써야 짝이 맞는다.
       * ctx 는 이 IIFE 안에만 있으므로 바깥(loadRelatedList 등)이 쓰도록 window 에 노출.
       */
      window.ideRelFlag = function() {
        if (!ctx.fullItem) return 'PROMULGATION';
        return ctx.docu ? 'DOCUMENT' : 'PROVISION';
      };

      // ── 노드 선택 처리 ──────────────────────────────────
      // fromTab: 'cate' = 규정분류 트리 / 'history' = 연혁목차 트리
      //   조문(provgrp) 클릭 시 "버전관리용조문편집" 은 연혁목차 에서만 띄움 (레거시 동일 정책)
      // ── 미저장 이탈 경고(dirty 추적) — 일괄편집기 등 대량 입력이 경고 없이 소실되던 갭 교정(2026-07-09) ──
      //   · 중앙 pane 의 ide* 입력에 타이핑하면 dirty (좌측 트리검색 등 .rlms-ide-left 안은 제외).
      //   · 저장 성공 시 각 저장 함수가 ideClearDirty() 호출. 임시저장은 정식 저장이 아니라 dirty 유지.
      //   · 페이지 이탈(좌측 링크·브라우저 닫기)은 beforeunload 네이티브 확인이 방어.
      window.ideDirty = false;
      window.ideClearDirty = function() { window.ideDirty = false; };
      $(document).on('input change', 'input[id^=ide], textarea[id^=ide], select[id^=ide]', function() {
        if ($(this).closest('.rlms-ide-left').length) return;
        window.ideDirty = true;
      });
      window.addEventListener('beforeunload', function(e) {
        if (window.ideDirty) { e.preventDefault(); e.returnValue = ''; }
      });

      function ideOnSelectNode(n, fromTab) {
        // 미저장 변경 가드 — 확인 없이 중앙 pane 이 교체되면 입력 전량 소실.
        // 취소 시 pane 은 유지(트리 하이라이트만 이동) — 원래 노드를 다시 클릭하면 그대로.
        if (window.ideDirty && !confirm('저장하지 않은 변경이 있습니다.\n다른 항목으로 이동하면 사라집니다. 계속하시겠습니까?')) {
          return;
        }
        window.ideClearDirty();
        // 개정분기 상태(별표/HTML조항)는 해당 노드 선택 시에만 유효 — 다른 노드로 이동하면 해제 (잔존 버튼 오동작 방어)
        ideDocuBranchPromNo = null;
        ideProvHtmlBranchPromNo = null;
        var _bb = document.getElementById('ideDocuBranchBox'); if (_bb) _bb.innerHTML = '';
        // jsTree 가 원본 JSON 의 data 필드를 n.original.data 또는 n.data 어느 쪽으로든 보존할 수 있어
        // 양쪽 모두 검사해서 머지 (필드 누락 방어)
        var data = {};
        if (n && n.original && typeof n.original.data === 'object' && n.original.data !== null) {
          $.extend(data, n.original.data);
        }
        if (n && typeof n.data === 'object' && n.data !== null) {
          for (var k in n.data) if (n.data.hasOwnProperty(k) && data[k] === undefined) data[k] = n.data[k];
        }
        ctx = { cateNo: null, cateNm: null, promNo: null, lawId: null, fullItem: null, item: null, docu: false };
        destroyCkProv();
        destroyCkPromBody();

        if (n.type === 'gubun') {
          switchActionSet('cate');
          showInfo(n, '규정 그룹입니다. 하위 분류를 선택하세요.');
          loadRelatedList(null, null);
        } else if (n.type === 'cate') {
          // 레거시: 분류 클릭 시 자동으로 빈 "연혁등록" 폼 표시 (Screen 1)
          ctx.cateNo = parseInt((n.id || '').split(':')[1], 10);
          ctx.cateNm = n.text;
          ctx.promNo = null; ctx.lawId = null;   // 규정 컨텍스트 초기화 — "규정 일괄 수정"이 이전 규정을 열지 않도록
          switchActionSet('cate');
          if (typeof window.fnNewProm === 'function') fnNewProm();
          else showInfo(n, '분류 "' + n.text + '" — 신규 규정 등록 폼 준비 중');
          loadRelatedList(null, null);
        } else if (n.type === 'law') {
          // 규정(정관) 루트 — 회차 선택 안내 + 새 연혁(개정) 등록 진입 (레거시 HistoryEventHandler ROOT 클릭 파리티)
          ctx.lawId = data.lawId || parseInt((n.id || '').split(':')[1], 10);
          switchActionSet('prom');
          showInfo(n, '규정 "' + n.text + '" — 아래 회차를 선택하면 조문/별표를 볼 수 있습니다.\n개정 작업을 시작하려면 [새 연혁(개정) 등록]을 누르세요.');
          document.getElementById('ideContextActions').innerHTML =
            '<button type="button" class="krds-btn primary medium" onclick="ideNewRevision(' + ctx.lawId + ')">＋ 새 연혁(개정) 등록</button>';
          loadRelatedList(null, null);
        } else if (n.type === 'prom') {
          // 회차(prom) 클릭 = 그 회차의 메타 편집 (분류 탭/연혁목차 탭 모두 동일).
          // 본문 일괄편집은 회차 하위 [조문] 그룹(provgrp) 클릭 시.
          ctx.promNo = data.promNo || parseInt((n.id || '').split(':')[1], 10);
          ctx.lawId  = data.lawId || null;
          switchActionSet('prom');
          loadPromForm(ctx.promNo);    // 응답의 lawId 로 연혁목차 자동 로드
          loadRelatedList(ctx.promNo, null);
        } else if (n.type === 'provgrp') {
          // 📁조문 그룹
          //  - VERSION 규정: "버전관리용조문편집" 일괄편집기 (레거시 와 동일)
          //  - HTML/VIEWER 규정: TB_PROV_HTML 평면 — 일괄편집기 비대상. 신규 조항 등록 버튼 제공.
          ctx.promNo = data.promNo || parseInt((n.id || '').split(':')[1], 10);
          switchActionSet('prom');
          if (!ctx.promNo) {
            alert('provgrp 노드에 promNo 가 없습니다. 콘솔에서 data 객체를 확인해주세요.');
          } else if (data.provFlag === 'HTML' || data.provFlag === 'VIEWER' || data.provFlag === 'FILE_VIEWER') {
            // HTML형식조문 — 펼치면 조항(TB_PROV_HTML) 목록. 신규 조항은 아래 버튼으로.
            showInfo(n, 'HTML형식조문입니다. 펼쳐서 조항을 선택해 수정하거나, 아래 버튼으로 새 조항을 등록하세요.');
            document.getElementById('ideContextActions').innerHTML =
              '<button type="button" class="krds-btn primary medium" onclick="ideStartNewProvHtml()">＋ HTML 조항 등록</button>';
          } else {
            loadProvBulkBody(ctx.promNo, n);
          }
          loadRelatedList(ctx.promNo, null);
        } else if (n.type === 'docgrp') {
          // 📁별표/별지서식 — 펼치면 TB_DOCU 누적 목록. 신규 등록 버튼 제공.
          ctx.promNo = data.promNo || parseInt((n.id || '').split(':')[1], 10) || null;
          switchActionSet('prom');
          showInfo(n, '별표/별지서식입니다. 펼쳐서 항목을 선택하거나, 아래 버튼으로 새 항목을 등록하세요.');
          document.getElementById('ideContextActions').innerHTML =
            '<button type="button" class="krds-btn primary medium" onclick="ideOpenDocuAddModal()">＋ 별표/별지서식 등록</button>';
          loadRelatedList(ctx.promNo, null);
        } else if (n.type === 'docu') {
          // 별표/별지서식 단건 — (docuNo) 식별
          var docuNo  = data.docuNo || parseInt((n.id || '').split(':')[1], 10);
          ctx.promNo  = data.promNo || data.currentPromNo || null;     // 본문 행이 저장된 회차
          ctx.lawId   = data.lawId || ctx.lawId || null;
          // 이전 회차 상속 행을 새 회차 컨텍스트에서 열면 = 개정분기 모드 (레거시 GAEJUNG_YN='Y')
          ideDocuBranchPromNo = (data.promNo && data.currentPromNo
              && String(data.promNo) !== String(data.currentPromNo)) ? data.currentPromNo : null;
          ideDocuViewPromNo = data.currentPromNo || data.promNo || null;
          // 별표 개별 첨부(2026-07-30) — 이 별표를 관련자료 컨텍스트로 삼는다.
          //   축: SFLAG='DOCUMENT' + SFULL_ITEM=별표 SITEM(data.item). 회차 불변 키라 개정 승계가 자연히 성립.
          ctx.fullItem = data.item || null;
          ctx.docu     = true;
          switchActionSet('prom');
          loadDocuForm(docuNo, n.text);
          loadRelatedList(ctx.promNo, ctx.fullItem);
        } else if (n.type === 'grp') {
          // 장/절 — 레거시 와 동일하게 펼침/닫힘만. 중앙·우측은 그대로 유지(현재 화면 보존).
          var gParts = (n.id || '').split(':');     // grp : lawId : lawNo : fullItem
          ctx.lawId    = data.lawId || parseInt(gParts[1], 10) || null;
          ctx.fullItem = data.fullItem || gParts[3] || null;
          ctx.promNo   = data.promNo || ctx.promNo || null;
          // (중앙 pane / 액션셋 / 관련자료 — 의도적으로 변경 안 함)
        } else if (n.type === 'prov') {
          var idParts = (n.id || '').split(':');    // prov : promNo(owner) : (item | fullItem)
          ctx.promNo   = data.promNo || parseInt(idParts[1], 10);
          ctx.lawId    = data.lawId || ctx.lawId || null;
          // VRSN 모드 판정 — data.vrsn=true 가 가장 확실. 누락 시(레거시/캐시) idParts[2] 길이로 폴백:
          //   TB_PROV_HTML SITEM 은 보통 6자 "002000", TB_PROV_VRSN SFULL_ITEM 은 60자 → 길이 ≥30 이면 VRSN.
          var isVrsn = (data.vrsn === true) || (data.vrsn === 'true')
                    || (idParts[2] && idParts[2].length >= 30);
          switchActionSet('prom');
          if (isVrsn) {
            // TB_PROV_VRSN 조 — (ownerPromNo, fullItem) 식별
            ctx.fullItem = data.fullItem || idParts[2];
            ctx.item     = data.item || null;
            loadProvVrsnForm(ctx.promNo, ctx.fullItem, n.text, ctx.lawId, data.lawNo);
          } else {
            // TB_PROV_HTML 조 — (ownerPromNo, item) 식별. 상속 행이면 개정분기 모드 (별표와 동일)
            ctx.fullItem = data.fullItem || idParts[2];
            ctx.item     = data.item || idParts[2];
            var _owner   = data.ownerPromNo || data.promNo || parseInt(idParts[1], 10);
            var _current = data.currentPromNo || _owner;
            ideProvHtmlBranchPromNo = (_owner && _current && String(_owner) !== String(_current))
                ? _current : null;
            ideProvHtmlViewPromNo = _current;
            loadProvForm(_owner, ctx.item, n.text);
            // 조항단위 관련자료는 loadProvForm 의 done 에서 loadRelatedList 로 갱신
          }
        }
      }

      function showInfo(n, hint) {
        document.getElementById('ideContextTitle').innerText = n.text;
        document.getElementById('ideContextType').innerText  = n.type || '-';
        document.getElementById('ideContextNodeId').innerText= n.id;
        document.getElementById('ideContextHint').innerText  = hint || '';
        document.getElementById('ideContextActions').innerHTML = '';   // 노드별 액션 버튼 초기화
        showCenterPane('info');
      }

      // ── 규정 메타 폼 로드 ───────────────────────────────
      function loadPromForm(promNo) {
        ideEnsureGaejungOptions();
        $.ajax({ url: PROM_GET, data: { promNo: promNo }, dataType: 'json' })
          .done(function(d) {
            if (!d.found) { alert('규정을 찾을 수 없습니다.'); showCenterPane('placeholder'); return; }
            document.getElementById('idePromNo').value        = d.promNo;
            document.getElementById('idePromCateNo').value    = (d.cateNo != null) ? d.cateNo : '';
            document.getElementById('idePromLawNo').value     = (d.lawNo  != null) ? d.lawNo  : '';
            document.getElementById('idePromTitle').value     = d.title || '';
            document.getElementById('idePromSubTitle').value  = d.subTitle || '';
            document.getElementById('idePromNumber').value    = d.number || '';
            document.getElementById('idePromOrderIdx').value  = (d.orderIdx != null) ? d.orderIdx : '';
            document.getElementById('idePromPromDate').value  = ideSafeIsoDate(d.promDate);
            document.getElementById('idePromStartDate').value = ideSafeIsoDate(d.startDate);
            document.getElementById('idePromNullDate').value  = ideSafeIsoDate(d.nullDate);
            document.getElementById('idePromUrl').value       = d.url || '';
            document.getElementById('idePromCateNm').value    = d.cateFullNm || d.cateNm || '';
            document.getElementById('idePromBuseoNo').value   = (d.buseoNo != null) ? d.buseoNo : '';
            document.getElementById('idePromOrgnztId').value  = d.orgnztId || '';
            document.getElementById('idePromBuseoNm').value   = d.buseoNm || '';
            document.getElementById('idePromGaejungNo').value = (d.gaejungNo != null) ? d.gaejungNo : '';
            // 레거시 의 "이 연혁을 감춥니다" = SDISP_YN='N' / "외부 열람 요청 공개 여부" = SEXT_DISP_YN='Y'
            document.getElementById('idePromDispYn').checked    = (d.dispYn === 'N');
            // 만족도 조사 사용 = SSTSFDG_YN='Y'
            document.getElementById('idePromStsfdgYn').checked  = (d.stsfdgYn === 'Y');
            // 외부 열람 공개 여부 — 라디오 (Y=공개 / N=비공개). 기존 값 없으면 둘 다 미선택.
            document.getElementById('idePromExtDispYnY').checked = (d.extDispYn === 'Y');
            document.getElementById('idePromExtDispYnN').checked = (d.extDispYn === 'N');
            // 규정형식 (SPROV_FG + SPROV_STYLE_CD) — 신규는 기본 VERSION/NORMAL. 구 코드 FILE_VIEWER → VIEWER 정규화.
            var _pf = (d.provFlag === 'FILE_VIEWER') ? 'VIEWER' : (d.provFlag || 'VERSION');
            document.getElementById('idePromProvFlag').value    = _pf;
            document.getElementById('idePromProvStyleCd').value = d.provStyleCd || 'NORMAL';
            if (document.getElementById('idePromRelFileView')) document.getElementById('idePromRelFileView').checked = (d.relFileViewYn === 'Y');
            idePendingProvFileNo = d.provFileNo;   // VIEWER 참조파일 — 후보 로드 후 선택 복원
            ideViewerFilesKey = null;              // 회차 바뀜 — 후보 캐시 무효화
            ideChangeProvFlag(_pf);   // 형식별 두번째 요소 동적 표시 (VIEWER 면 후보 로드)
            // 레거시: 회차 노드 클릭 → "연혁수정" 화면 (Screen — 연혁기본정보)
            var head = '연혁수정 — ' + (d.title || '(제목없음)');
            if (d.lawNo != null) head += ' ' + d.lawNo + '차';
            if (d.promDate)      head += ' (' + d.promDate + ')';
            if (d.existingYn === 'Y') head += ' [현행]';
            document.getElementById('idePromHead').innerText = head;
            // 상태 — 'Y' = 현행 노출 / 'N' = 작업중(사용자 비공개). 최신 워크상태(workStatus)로 세분화:
            //   반려면 사유 카드 표시 + 재요청 가능, 요청 진행 중이면 중복 요청 버튼 숨김(서버 가드와 일치).
            var _st = document.getElementById('idePromStatus');
            var _rejBox = document.getElementById('idePromRejectBox');
            _rejBox.style.display = 'none'; _rejBox.innerHTML = '';
            var _showReason = function(title, reason) {
              if (!reason || !String(reason).trim()) return;
              var esc = function(s){ return String(s==null?'':s).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];}); };
              _rejBox.innerHTML = '<b>' + esc(title) + '</b><div class="ide-reject-reason">' + esc(reason) + '</div>';
              _rejBox.style.display = '';
            };
            if (d.existingYn === 'Y') {
              _st.className = 'ide-prov-status exist';
              document.getElementById('ideBtnReqApprove').style.display = 'none';
              // 현행 회차 — 수정권한 워크플로 폐지(2026-07-20): 작성권한만 있으면 바로 편집
              if (d.workStatus === '승인요청') {
                _st.innerText = '운영중 (현행) — 승인요청 심사 중 (편집 잠금)';
              } else if (d.workStatus === '승인반려') {
                _st.innerText = '운영중 (현행) — 최근 승인요청이 반려됨';
                _showReason('반려 사유', d.workReason);
              } else {
                _st.innerText = '운영중 (현행)';
              }
              // 폐지일 변경 승인 대기 — 승인되면 반영, 반려되면 폐기 (2026-07-20)
              if (d.nullDatePendLabel) {
                _st.innerText += ' · 폐지일 변경 승인 대기: ' + d.nullDatePendLabel;
              }
            } else {
              if (d.workStatus === '승인반려') {
                _st.innerText = '승인반려 — 사유 확인 후 수정하여 다시 승인요청하세요';
                _st.className = 'ide-prov-status rejected';
                document.getElementById('ideBtnReqApprove').style.display = '';   // 재요청 가능
                _showReason('반려 사유', d.workReason);
              } else if (d.workStatus === '승인요청') {
                // 편집 잠금(PromEditGuard.isApprovalLocked)으로 아래에서 수정/삭제/분류이동 버튼이 모두 숨겨진다.
                // 사유를 라벨에 밝히지 않으면 "삭제할 방법이 없다"로 보인다 (2026-07-30).
                _st.innerText = '승인요청 진행 중 (관리자 승인 대기 — 사용자 비공개) · 편집 잠금 — 승인관리에서 승인/반려 처리 후 수정·삭제 가능';
                _st.className = 'ide-prov-status new';
                document.getElementById('ideBtnReqApprove').style.display = 'none';   // 중복 요청 방지
              } else {
                _st.innerText = '작업중 (사용자 비공개 — 승인 필요)';
                _st.className = 'ide-prov-status new';
                document.getElementById('ideBtnReqApprove').style.display = '';   // 승인 대기 회차에만 [승인요청]
              }
            }
            document.getElementById('ideBtnDeleteEmpty').style.display = '';   // 저장된 회차 → 삭제 버튼 노출
            document.getElementById('ideBtnMoveCate').style.display    = '';   // 저장된 회차 → 분류이동 버튼 노출
            // 조문 입력 — VERSION/HTML 형식 회차에만 노출(VIEWER=PDF뷰어·LINK=외부원문은 조문 없음). 트리 펼침 없이 바로 진입(#4)
            document.getElementById('ideBtnEditProv').style.display = (_pf === 'VIEWER' || _pf === 'LINK') ? 'none' : '';
            document.getElementById('idePromSaveBtn').innerText = '수정하기';
            // #8 B: 실제 편집권한(서버 canEdit = ADMIN/분류소유자) 없으면 워크플로·편집·저장 버튼을 숨겨
            //   '편집 가능한 것처럼' 보이다 저장 시 권한없음 팝업 맞는 불일치 제거(읽기 전용 표시).
            var _canEdit = (d.canEdit !== false);   // 구버전 응답(미정의)은 기존대로 허용
            if (!_canEdit) {
              ['ideBtnReqApprove','ideBtnEditProv','ideBtnDeleteEmpty','ideBtnMoveCate']
                .forEach(function(id){ var el = document.getElementById(id); if (el) el.style.display = 'none'; });
              var _sb = document.getElementById('idePromSaveBtn'); if (_sb) _sb.style.display = 'none';
              // 승인요청 잠금이면 상태라벨이 이미 '편집 잠금'을 말하므로 권한없음 문구는 그 외에만
              if (d.workStatus !== '승인요청') {
                document.getElementById('idePromStatus').innerText += ' · 읽기 전용(편집 권한 없음)';
              }
            } else {
              var _sb2 = document.getElementById('idePromSaveBtn'); if (_sb2) _sb2.style.display = '';
            }

            // 본문 4종 채움 (평문 부칙은 줄바꿈 보존을 위해 <br> 변환)
            document.getElementById('idePromBody_gaejung').value  = pbBodyToHtml(d.gaejung);
            document.getElementById('idePromBody_reason').value   = pbBodyToHtml(d.reason);
            document.getElementById('idePromBody_bylaw').value    = pbBodyToHtml(d.bylaw);
            document.getElementById('idePromBody_preamble').value = pbBodyToHtml(d.preamble);
            // 탭 리셋 → 개정이유 (레거시 첫 활성탭)
            var pbBtns = document.querySelectorAll('.ide-pbtab');
            for (var i = 0; i < pbBtns.length; i++)
              pbBtns[i].classList.toggle('active', pbBtns[i].getAttribute('data-pbtab') === 'reason');
            ['gaejung','reason','bylaw','preamble'].forEach(function(k){
              document.getElementById('idePromBody_'+k).style.display = (k === 'reason') ? '' : 'none';
            });
            curPbTab = 'reason';

            showCenterPane('prom');

            // CKEditor 초기화 (기본 탭 = 개정이유)
            destroyCkPromBody();
            ckPromBody = CKEDITOR.replace('idePromBody_reason', ckPromBodyCfg());

            // 연혁목차 — 응답의 lawId 로 (트리 노드 data 가 비어도 동작)
            ctx.lawId = d.lawId || null;
            if (ctx.lawId) {
              switchTreeTab('history');
              loadHistoryTree(ctx.lawId);
              loadExclLnkList(ctx.lawId);   // 자동링크 제외범위 박스 로드
            } else {
              document.getElementById('ideExclLnkBox').style.display = 'none';
            }
          })
          .fail(function(xhr) { alert('규정 메타 조회 실패: ' + xhr.status); });
      }
      // 규정형식 동적 전환 (레거시 changeProvisionFlag 1:1 + LINK 확장):
      //   VERSION=스타일 / HTML=관련파일 체크 / VIEWER=참조파일 select / LINK=URL 입력행(필수)
      window.ideChangeProvFlag = function(v) {
        var st = document.getElementById('idePromProvStyleCd');
        var fl = document.getElementById('idePromProvFileNo');
        var rl = document.getElementById('idePromRelFileViewWrap');
        var ur = document.getElementById('idePromUrlRow');
        if (st) st.style.display = (v === 'VERSION') ? '' : 'none';
        if (fl) fl.style.display = (v === 'VIEWER')  ? '' : 'none';
        if (rl) rl.style.display = (v === 'HTML')    ? 'inline-flex' : 'none';
        if (ur) ur.style.display = (v === 'LINK')    ? '' : 'none';
        if (v === 'VIEWER') ideEnsureViewerFiles();   // 참조파일 후보 lazy 로드 (파일등록/REL_FILE_3 누적 중 PDF)
      };

      // ── PDF파일뷰어 참조파일 후보 로드 (레거시 fillFileListForViewer + RLMS 보강) ──
      //    후보 = 규정 누적 관련파일 중 '파일 등록'(REL_FILE_1)·PDF뷰어용(REL_FILE_3) 에서 실제 PDF 만.
      //    value = TB_REL_FILE.IRFILE_NO. ('원본 첨부하기'는 TB_REL_ORGN 별도 테이블이라 후보 아님)
      var ideViewerFilesKey  = null;   // 'p:promNo' / 'l:lawId' — 같은 대상 중복 로드 방지
      var idePendingProvFileNo = null; // 폼 로드 시 저장돼 있던 SPROV_FILE_NO — 옵션 로드 후 선택 복원
      function ideEscOpt(s){ return String(s==null?'':s).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];}); }
      function ideEnsureViewerFiles(force) {
        var sel = document.getElementById('idePromProvFileNo');
        if (!sel) return;
        var promNo = (document.getElementById('idePromNo').value || '').trim();
        var key = promNo ? ('p:' + promNo) : (ctx.lawId ? ('l:' + ctx.lawId) : null);
        if (!key) {   // 완전 신규 규정 — 관련파일이 아직 없음
          ideViewerFilesKey = null;
          sel.innerHTML = '<option value="-1">참조뷰어용 파일이 존재하지 않습니다.</option>';
          return;
        }
        if (!force && ideViewerFilesKey === key) return;
        var params = promNo ? { promNo: promNo } : { lawId: ctx.lawId };
        $.getJSON(VIEWER_FILES, params).done(function(d) {
          ideViewerFilesKey = key;
          var files = (d && d.files) || [];
          var h;
          if (!files.length) {
            h = '<option value="-1">참조뷰어용 파일이 존재하지 않습니다.</option>';
          } else {
            h = '<option value="-1">(파일 선택)</option>';
            files.forEach(function(f) {
              h += '<option value="' + f.relFileNo + '">' + ideEscOpt(f.name || ('파일 ' + f.relFileNo)) + '</option>';
            });
          }
          sel.innerHTML = h;
          // 저장돼 있던 참조파일 선택 복원 — 후보 목록에 없으면(삭제됨) 표식 옵션으로 살림
          var want = idePendingProvFileNo;
          if (want != null && want !== '' && String(want) !== '-1' && String(want) !== '0') {
            sel.value = String(want);
            if (sel.value !== String(want)) {
              var o = document.createElement('option');
              o.value = String(want);
              o.text  = '(현재 지정 #' + want + ' — 후보 목록에 없음)';
              sel.appendChild(o);
              sel.value = String(want);
            }
          }
        });
      }
      window.ideSaveProm = function() {
        var _wasNew = !(document.getElementById('idePromNo').value || '').trim();   // 신규 등록 여부 (저장 후 폼 재로드 판단 — #4/#8)
        // 연혁번호(회차) 필수 + 숫자 검증 (레거시 동일). 제·개정번호(SNUM)는 선택 — 공백 허용.
        var _lawNoEl = document.getElementById('idePromLawNo');
        var _lawNoV = _lawNoEl ? (_lawNoEl.value || '').trim() : '';
        if (!_lawNoV) { alert('연혁번호를 입력하세요.'); if (_lawNoEl) _lawNoEl.focus(); return; }
        if (!/^[0-9]+$/.test(_lawNoV)) { alert('연혁번호는 숫자만 입력하세요.'); _lawNoEl.focus(); return; }
        // 개정구분/소관부서 필수 (서버 savePromMeta 도 동일 검증 — 0 디폴트는 안전망일 뿐)
        var _gjEl = document.getElementById('idePromGaejungNo');
        if (_gjEl && !(_gjEl.value || '').trim()) { alert('개정구분을 선택하세요.'); _gjEl.focus(); return; }
        var _orgEl = document.getElementById('idePromOrgnztId');
        var _bsEl  = document.getElementById('idePromBuseoNo');
        if (!((_orgEl && (_orgEl.value || '').trim()) || (_bsEl && (_bsEl.value || '').trim()))) {
          alert('소관부서를 선택하세요. ([선택] 버튼으로 부서를 지정합니다)'); return;
        }
        // 규정형식별 필수 검증 (레거시 1:1 + LINK): 버전관리=스타일, PDF뷰어=참조파일, 링크형식=URL(http/https)
        var _flag = document.getElementById('idePromProvFlag').value;
        if (_flag === 'VERSION' && document.getElementById('idePromProvStyleCd').value === '-1') { alert('규정 스타일을 선택하세요.'); return; }
        if (_flag === 'VIEWER'  && document.getElementById('idePromProvFileNo').value === '-1') { alert('뷰어로 제공할 파일을 선택하세요.'); return; }
        if (_flag === 'LINK') {
          var _u = (document.getElementById('idePromUrl').value || '').trim().toLowerCase();
          if (!(_u.indexOf('http://') === 0 || _u.indexOf('https://') === 0)) {
            alert('링크형식 규정은 URL(http:// 또는 https://)이 필수입니다.'); return;
          }
        }
        // 현재 활성 본문 탭의 CKEditor 데이터 → textarea 로 반영
        if (ckPromBody) document.getElementById('idePromBody_' + curPbTab).value = ckPromBody.getData();
        $.ajax({ url: PROM_SAVE, method: 'POST', data: $('#idePromForm').serialize(), dataType: 'json' })
          .done(function(d) {
            if (d.success) {
              ideToast(d.message || '저장되었습니다.');
              window.ideClearDirty();
              // 좌측 트리 즉시 갱신 — 새로고침 없이 추가/수정된 연혁이 트리에 반영되도록.
              //  · 규정분류 트리: refresh (신규 규정 등록분 반영)
              //  · 연혁목차 트리: 같은 lawId 면 재로드 스킵 가드가 있어 loadedHistoryLawId 를 비워 강제 재로드(신규 회차 반영)
              try { var $c = $('#ideTreeCate'); if ($c.jstree(true)) $c.jstree('refresh'); } catch (e) {}
              var _lawId = d.lawId || ctx.lawId;
              if (_lawId) {
                ctx.lawId = _lawId;
                loadedHistoryLawId = null;
                try { loadHistoryTree(_lawId); } catch (e) {}
              }
              // 신규 등록 직후 — 저장된 회차를 편집모드로 재로드해 [조문 입력]·[승인요청] 버튼이 바로 보이게 한다.
              //   (트리를 펼쳐 회차를 다시 클릭하지 않아도 됨.) #4 동선 + #8(최초 등록 시 승인버튼 누락) 해소.
              if (_wasNew && d.promNo) {
                ctx.promNo = d.promNo;
                loadPromForm(d.promNo);
              }
            } else { alert(d.message || '저장에 실패했습니다.'); }
          })
          .fail(function(xhr) { alert('저장 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || '')); });
      };

      // ── 조항 편집 폼 로드 (TB_PROV_HTML — provFlag=HTML 규정) ────
      function loadProvForm(promNo, item, nodeText) {
        $.ajax({ url: PROV_GET, data: { promNo: promNo, item: item }, dataType: 'json' })
          .done(function(d) {
            ideProvMode = 'html';
            document.getElementById('ideProvHtmlNo').value     = d.provHtmlNo || '';
            document.getElementById('ideProvPromNo').value     = d.promNo || promNo;
            document.getElementById('ideProvItem').value       = d.item || item;
            document.getElementById('ideProvFullItem').value   = '';
            document.getElementById('ideProvLawId').value      = '';   // vrsn 전용 — 잔존값 오동작 방지
            document.getElementById('ideProvLawNo').value      = '';
            document.getElementById('ideProvSysId').value      = SYS_ID;
            document.getElementById('ideProvTitle').value      = d.title || '';
            document.getElementById('ideProvGaejungType').value= d.gaejungType || '';
            document.getElementById('ideProvReason').value     = d.reason || '';
            document.getElementById('ideProvContents').value   = d.contents || '';
            document.getElementById('ideProvViewPromNo').value = ideProvHtmlViewPromNo || d.promNo || promNo;
            document.getElementById('ideProvHead').innerText   =
              (d.item || item) + (nodeText ? '  —  ' + nodeText : '');
            // 조번호/가지번호 — 자기 회차 기존행은 수정 허용(2026-07-30).
            //   HTML형식은 조 사이에 항목을 끼우거나 순서를 고치는 유일한 수단이 이 번호다(목록 정렬 = ORDER BY SITEM).
            //   상속(개정분기) 행은 계보 키라 잠근다 — 번호를 바꾸면 이전 회차 조항과 계보가 끊긴다.
            var _hItem = String(d.item || item || '');
            if (d.found && !ideProvHtmlBranchPromNo && /^[0-9]{6}$/.test(_hItem)) {
              document.getElementById('ideProvJoNo').value    = String(parseInt(_hItem.substring(0, 4), 10));
              document.getElementById('ideProvJoSubNo').value = String(parseInt(_hItem.substring(4, 6), 10));
              toggleProvJoRow(true);
            } else {
              toggleProvJoRow(false);
            }
            // 개정분기 모드(이전 회차 상속 행) — 저장이 새 회차 분기 등록으로 동작 (별표와 동일)
            if (ideProvHtmlBranchPromNo && d.found) {
              document.getElementById('ideProvStatus').innerText = '이전 회차 상속 — 개정분기 모드';
              document.getElementById('ideProvStatus').className = 'ide-prov-status new';
              setProvSaveLabel('branch');
              document.getElementById('ideDocuBranchBox').innerHTML = ideBranchCardHtml(
                'ideProvHtmlBranchType', 'ideBranchProvHtml',
                '이전 회차에 등록된 조항입니다',
                '내용을 수정한 뒤 <b class="bc-inline">[이 회차로 개정 등록]</b>을 누르면 ' +
                '현재 회차에 새 행으로 등록되고 원본 회차의 조항은 그대로 보존됩니다. (저장 버튼도 동일하게 동작)');
            } else {
              ideProvHtmlBranchPromNo = null;
              document.getElementById('ideProvStatus').innerText =
                d.found ? '기존 본문 (provHtmlNo=' + d.provHtmlNo + ')' : '신규 — 저장 시 새로 등록됩니다';
              document.getElementById('ideProvStatus').className =
                'ide-prov-status ' + (d.found ? 'exist' : 'new');
              setProvSaveLabel(d.found ? 'edit' : 'new');
              document.getElementById('ideDocuBranchBox').innerHTML = '';
            }

            showCenterPane('prov');
            mountCkProvHtml(d.contents || '');   // HTML형식조문 본문 = CKEditor 직접편집

            // 조항단위 관련자료 (TB_REL_VRSN SFLAG='PROVISION') — 8액션 저장 직후
            // 리프레시(loadRelatedList(ctx.promNo, ctx.fullItem))와 동일 인자로 대칭 유지.
            // (옛 loadAttachList('TB_PROV_HTML', …) 는 항상 0건인 레거시 경로라 폐기)
            loadRelatedList(ctx.promNo || d.promNo || promNo, ctx.fullItem || d.item || item);
          })
          .fail(function(xhr) {
            alert('조항 본문 조회 실패: ' + xhr.status);
          });
      }

      // ── 조항 편집 폼 로드 (TB_PROV_VRSN — 계층 트리 장>조 의 조 노드) ──
      function loadProvVrsnForm(promNo, fullItem, nodeText, lawId, lawNo) {
        var qs = '?promNo=' + promNo + '&fullItem=' + fullItem
               + (lawId != null ? '&lawId=' + lawId : '')
               + (lawNo != null ? '&lawNo=' + lawNo : '');
        var data = { promNo: promNo, fullItem: fullItem };
        if (lawId != null) data.lawId = lawId;
        if (lawNo != null) data.lawNo = lawNo;
        $.ajax({ url: PROV_VRSN_GET, data: data, dataType: 'json' })
          .done(function(d) {
            ideProvMode = 'vrsn';
            destroyCkProv();   // VERSION 조문 = 평문 textarea (이전 html 모드 CKEditor 정리)
            document.getElementById('ideProvHtmlNo').value     = '';
            document.getElementById('ideProvPromNo').value     = d.promNo || promNo;
            document.getElementById('ideProvItem').value       = d.item || '';
            document.getElementById('ideProvFullItem').value   = d.fullItem || fullItem;
            // 보는 회차 식별 — 저장이 상속 원본(owner) 회차를 소급 수정하지 않고 보는 회차의 개정으로 저장되게
            document.getElementById('ideProvLawId').value      = (lawId != null) ? lawId : '';
            document.getElementById('ideProvLawNo').value      = (lawNo != null) ? lawNo : '';
            document.getElementById('ideProvSysId').value      = SYS_ID;
            document.getElementById('ideProvTitle').value      = d.title || '';
            document.getElementById('ideProvStartDate').value  = ideSafeIsoDate(d.startDate);
            document.getElementById('ideProvGaejungType').value= d.gaejungType || '';
            document.getElementById('ideProvReason').value     = d.reason || '';
            document.getElementById('ideProvContents').value   = d.contents || '';
            // 레거시 화면 제목 1:1: "버전관리조문수정 — 제N조(제목)"
            document.getElementById('ideProvHead').innerText   = '버전관리조문수정 — ' + (nodeText || ('조항 ' + fullItem));
            document.getElementById('ideProvStatus').innerText =
              d.found ? '조항 단위 수정' : '조항을 찾을 수 없습니다';
            document.getElementById('ideProvStatus').className =
              'ide-prov-status ' + (d.found ? 'exist' : 'new');
            toggleProvJoRow(false);     // 버전관리 조 단위 수정 — 조번호/가지번호 입력행 숨김
            setProvSaveLabel('edit');

            showCenterPane('prov');
            // 본문은 plain text textarea — CKEditor 폐기됨

            // 조 단위 관련자료 — TB_REL_VRSN WHERE IPROM_NO=? AND SFLAG='PROVISION' AND SFULL_ITEM=?
            loadRelatedList(d.promNo || promNo, d.fullItem || fullItem);
          })
          .fail(function(xhr) {
            alert('조항 본문 조회 실패: ' + xhr.status);
          });
      }

      // ── 별표/별지서식 폼 로드 (TB_DOCU — docu 노드) ────────────
      function loadDocuForm(docuNo, nodeText) {
        $.ajax({ url: DOCU_GET, data: { docuNo: docuNo }, dataType: 'json' })
          .done(function(d) {
            ideProvMode = 'docu';
            destroyCkProv();   // 별표/별지서식 = 평문 textarea
            ideDocuNo   = d.docuNo || docuNo;
            // 폼 필드 재사용 — provHtmlNo / fullItem 은 비우고 promNo 는 owner 로
            document.getElementById('ideProvHtmlNo').value     = '';
            document.getElementById('ideProvPromNo').value     = d.promNo || '';
            document.getElementById('ideProvItem').value       = d.item || '';
            document.getElementById('ideProvFullItem').value   = '';
            document.getElementById('ideProvLawId').value      = '';   // vrsn 전용 — 잔존값 오동작 방지
            document.getElementById('ideProvLawNo').value      = '';
            document.getElementById('ideProvSysId').value      = SYS_ID;
            document.getElementById('ideProvTitle').value      = d.title || '';
            document.getElementById('ideProvGaejungType').value= d.gaejungType || '';
            document.getElementById('ideProvReason').value     = d.reason || '';
            document.getElementById('ideProvContents').value   = d.contents || '';
            var head = (d.grpTitle ? d.grpTitle + ' — ' : '별표 — ') + (d.title || nodeText || ('#'+(d.docuNo||docuNo)));
            document.getElementById('ideProvHead').innerText   = head;
            // 개정분기 모드(이전 회차 상속 행) — 저장이 새 회차 분기 등록으로 동작 (레거시 updateDo 화면의 "개정")
            // ※ 분기 UI 는 prov pane 내부 #ideDocuBranchBox 에 — #ideContextActions 는 info pane 이라 prov 화면에선 안 보임
            toggleProvJoRow(false);   // 별표/별지서식 — 조번호/가지번호 입력행 숨김
            if (ideDocuBranchPromNo) {
              document.getElementById('ideProvStatus').innerText = '이전 회차 상속 — 개정분기 모드';
              document.getElementById('ideProvStatus').className = 'ide-prov-status new';
              setProvSaveLabel('branch');
              document.getElementById('ideDocuBranchBox').innerHTML = ideBranchCardHtml(
                'ideDocuBranchType', 'ideBranchDocu',
                '이전 회차에 등록된 별표/별지서식입니다',
                '내용을 수정한 뒤 <b class="bc-inline">[이 회차로 개정 등록]</b>을 누르면 ' +
                '현재 회차에 새 행으로 등록되고 원본 회차의 별표는 그대로 보존됩니다. (저장 버튼도 동일하게 동작)');
            } else {
              document.getElementById('ideProvStatus').innerText =
                d.found ? '별표/별지서식 (TB_DOCU, docuNo=' + d.docuNo + ')' : '단위 행을 찾을 수 없습니다';
              document.getElementById('ideProvStatus').className =
                'ide-prov-status ' + (d.found ? 'exist' : 'new');
              setProvSaveLabel(d.found ? 'edit' : 'new');
              document.getElementById('ideDocuBranchBox').innerHTML = '';
            }

            showCenterPane('prov');
            // 본문은 plain text textarea — CKEditor 폐기됨

            // 별표 개별 첨부(2026-07-30) — 이 별표에 붙은 자료를 보여준다.
            //   ★ideOnSelectNode 가 이미 (promNo, SITEM) 으로 불러놨지만 이 콜백이 뒤늦게 도착하므로
            //     여기서 fullItem 을 빼면 회차 전체 목록으로 덮여 별표 첨부가 화면에서 사라진다.
            loadRelatedList(ctx.promNo || d.promNo || null, ctx.fullItem || d.item || null);
          })
          .fail(function(xhr) {
            alert('별표 본문 조회 실패: ' + xhr.status);
          });
      }

      // ── 별표/별지서식 신규 등록 모달 ─────────────────────────
      window.ideOpenDocuAddModal = function() {
        if (!ctx.promNo) { alert('회차가 선택되지 않았습니다. 연혁목차에서 회차를 먼저 선택하세요.'); return; }
        document.getElementById('ideDocuAddTitle').value  = '';
        document.getElementById('ideDocuAddReason').value = '';
        document.getElementById('ideDocuAddSubNo').value  = '0';
        document.getElementById('ideDocuAddStatus').innerText = '';
        document.getElementById('ideDocuAddModal').style.display = 'flex';
        ideDocuSuggestNo();
      };
      window.ideCloseDocuAddModal = function() {
        document.getElementById('ideDocuAddModal').style.display = 'none';
      };
      function ideDocuSuggestNo() {
        var ty = document.getElementById('ideDocuAddType').value;
        $.getJSON(DOCU_NEXT_NO, { promNo: ctx.promNo, itemType: ty })
          .done(function(d) { if (d.success) document.getElementById('ideDocuAddNo').value = d.nextNo; });
      }
      $(document).on('change', '#ideDocuAddType', ideDocuSuggestNo);
      window.ideSubmitDocuAdd = function() {
        var no    = (document.getElementById('ideDocuAddNo').value || '').trim();
        var title = (document.getElementById('ideDocuAddTitle').value || '').trim();
        if (!no)    { alert('번호를 입력하세요.'); document.getElementById('ideDocuAddNo').focus(); return; }
        if (!title) { alert('제목을 입력하세요.'); document.getElementById('ideDocuAddTitle').focus(); return; }
        document.getElementById('ideDocuAddStatus').innerText = '등록 중…';
        $.post(DOCU_INSERT, {
          promNo:   ctx.promNo,
          itemType: document.getElementById('ideDocuAddType').value,
          itemNo:   no,
          subNo:    document.getElementById('ideDocuAddSubNo').value || '0',
          title:    title,
          reason:   document.getElementById('ideDocuAddReason').value
        }, null, 'json').done(function(d) {
          document.getElementById('ideDocuAddStatus').innerText = '';
          if (!d || !d.success) { alert((d && d.message) || '등록에 실패했습니다.'); return; }
          ideCloseDocuAddModal();
          // 연혁목차 트리 즉시 갱신 — 새 별표 노드 반영 (열림/선택 상태 보존)
          try { var $h = $('#ideTreeHistory'); if ($h.jstree(true)) $h.jstree(true).refresh(); } catch (e) {}
          ideToast(d.message || '등록되었습니다.');
        }).fail(function(xhr) {
          document.getElementById('ideDocuAddStatus').innerText = '';
          alert('등록 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || ''));
        });
      };

      // ── 개정분기 카드 빌더 (별표/HTML조항 공용) — IDE 카드 톤 통일 ──
      function ideBranchCardHtml(selectId, btnFn, title, desc) {
        return '<div class="ide-branch-card">' +
          '<div class="bc-text"><b>' + title + '</b>' + desc + '</div>' +
          '<div class="bc-actions">' +
          '<label for="' + selectId + '">개정유형</label>' +
          '<select id="' + selectId + '">' +
          '<option value="MODIFY">개정</option>' +
          '<option value="NULLIFY_SEMANTIC">폐지(표시)</option>' +
          '<option value="NULLIFY">삭제(숨김)</option>' +
          '</select>' +
          '<button type="button" class="krds-btn primary medium" onclick="' + btnFn + '()">이 회차로 개정 등록</button>' +
          '</div></div>';
      }

      // ── HTML형식조문 — 신규 조항 등록 (모달 폐기 → 곧장 중앙 편집 폼) ──
      //   조 번호/가지번호는 폼 상단(ideProvJoRow)에서 인라인 입력 → 저장 시 SITEM 구성.
      window.ideStartNewProvHtml = function() {
        if (!ctx.promNo) { alert('회차가 선택되지 않았습니다. 연혁목차에서 회차를 먼저 선택하세요.'); return; }
        ideProvMode = 'html';
        ideProvHtmlBranchPromNo = null;
        ideProvHtmlViewPromNo   = ctx.promNo;
        document.getElementById('ideProvHtmlNo').value      = '';
        document.getElementById('ideProvPromNo').value      = ctx.promNo;
        document.getElementById('ideProvItem').value        = '';   // 저장 시 조번호/가지번호로 구성
        document.getElementById('ideProvFullItem').value    = '';
        document.getElementById('ideProvLawId').value       = '';   // vrsn 전용 — 잔존값 오동작 방지
        document.getElementById('ideProvLawNo').value       = '';
        document.getElementById('ideProvSysId').value       = SYS_ID;
        document.getElementById('ideProvViewPromNo').value  = ctx.promNo;
        document.getElementById('ideProvTitle').value       = '';
        document.getElementById('ideProvGaejungType').value = 'NEW';
        document.getElementById('ideProvReason').value      = '';
        document.getElementById('ideProvContents').value    = '';
        // 조 번호/가지번호 입력행 노출 + 초기화 (신규 등록 전용)
        document.getElementById('ideProvJoNo').value    = '';
        document.getElementById('ideProvJoSubNo').value = '0';
        toggleProvJoRow(true);
        document.getElementById('ideProvHead').innerText    = 'HTML 조항 등록 — 신규';
        document.getElementById('ideProvStatus').innerText  = '신규 — 조 번호·제목·본문을 입력하고 [등록하기]';
        document.getElementById('ideProvStatus').className  = 'ide-prov-status new';
        document.getElementById('ideDocuBranchBox').innerHTML = '';
        setProvSaveLabel('new');
        showCenterPane('prov');
        mountCkProvHtml('');   // 신규 HTML 조항 = CKEditor 직접편집
        loadRelatedList(ctx.promNo || null, null);   // 신규 조항 등록 중엔 회차 관련자료 노출
        try { document.getElementById('ideProvJoNo').focus(); } catch (e) {}
      };

      // ── HTML 조항 개정분기 등록 — 상속 행을 지금 보는 회차로 INSERT (별표와 동일 메커니즘) ──
      window.ideBranchProvHtml = function() {
        if (ckProvHtml) { try { ckProvHtml.updateElement(); } catch (e) {} }
        var srcNo = document.getElementById('ideProvHtmlNo').value;
        if (!srcNo || !ideProvHtmlBranchPromNo) { alert('분기 대상이 없습니다.'); return; }
        var typeSel = document.getElementById('ideProvHtmlBranchType');
        var chosenType = (typeSel && typeSel.value) || 'MODIFY';   // 콜백에서 select 가 제거되므로 사전 캡처
        var branchTarget = ideProvHtmlBranchPromNo;
        $.post(PROVHTML_BRANCH, {
          provHtmlNo:  srcNo,
          promNo:      branchTarget,
          title:       document.getElementById('ideProvTitle').value,
          contents:    document.getElementById('ideProvContents').value,
          reason:      document.getElementById('ideProvReason').value,
          gaejungType: chosenType
        }, null, 'json').done(function(d) {
          if (!d || !d.success) { alert((d && d.message) || '분기 등록에 실패했습니다.'); return; }
          // 분기 완료 — 이후 저장은 새 행 in-place. hidden 들을 새 행 기준으로 동기화
          ideProvHtmlBranchPromNo = null;
          ideProvHtmlViewPromNo = branchTarget;
          document.getElementById('ideProvHtmlNo').value      = d.provHtmlNo || '';
          document.getElementById('ideProvPromNo').value      = branchTarget;
          document.getElementById('ideProvViewPromNo').value  = branchTarget;
          document.getElementById('ideProvGaejungType').value = chosenType;
          document.getElementById('ideProvStatus').innerText  = '개정 분기 등록됨 (provHtmlNo=' + d.provHtmlNo + ')';
          document.getElementById('ideProvStatus').className  = 'ide-prov-status exist';
          setProvSaveLabel('edit');   // 분기 등록 후 = 새 행 in-place 수정
          document.getElementById('ideDocuBranchBox').innerHTML = '';
          try { var $h = $('#ideTreeHistory'); if ($h.jstree(true)) $h.jstree(true).refresh(); } catch (e) {}
          alert(d.message || '개정 분기 등록되었습니다.');
        }).fail(function(xhr) {
          alert('분기 등록 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || ''));
        });
      };

      // ── 별표 개정분기 등록 — 상속 행을 지금 보는 회차로 INSERT (레거시 gaejung()→insertDo) ──
      window.ideBranchDocu = function() {
        if (!ideDocuNo || !ideDocuBranchPromNo) { alert('분기 대상이 없습니다.'); return; }
        var typeSel = document.getElementById('ideDocuBranchType');
        var chosenType = (typeSel && typeSel.value) || 'MODIFY';   // 콜백에서 select 가 제거되므로 사전 캡처
        var branchTarget = ideDocuBranchPromNo;
        $.post(DOCU_BRANCH, {
          docuNo:      ideDocuNo,
          promNo:      branchTarget,
          title:       document.getElementById('ideProvTitle').value,
          contents:    document.getElementById('ideProvContents').value,
          reason:      document.getElementById('ideProvReason').value,
          gaejungType: chosenType
        }, null, 'json').done(function(d) {
          if (!d || !d.success) { alert((d && d.message) || '분기 등록에 실패했습니다.'); return; }
          // 분기 완료 — 이후 저장은 새 행 in-place. hidden 개정유형을 분기 유형으로 동기화
          // (미동기화 시 재저장이 원본 행의 유형으로 SGAEJUNG_TYPE 을 되돌리는 역행 버그)
          ideDocuNo = d.docuNo;
          ideDocuBranchPromNo = null;
          ideDocuViewPromNo = branchTarget;   // 새 행의 소유 회차 = 분기 대상 회차
          document.getElementById('ideProvGaejungType').value = chosenType;
          document.getElementById('ideProvPromNo').value = branchTarget;
          document.getElementById('ideProvStatus').innerText = '개정 분기 등록됨 (docuNo=' + d.docuNo + ')';
          document.getElementById('ideProvStatus').className = 'ide-prov-status exist';
          setProvSaveLabel('edit');   // 분기 등록 후 = 새 행 in-place 수정
          document.getElementById('ideDocuBranchBox').innerHTML = '';
          try { var $h = $('#ideTreeHistory'); if ($h.jstree(true)) $h.jstree(true).refresh(); } catch (e) {}
          alert(d.message || '개정 분기 등록되었습니다.');
        }).fail(function(xhr) {
          alert('분기 등록 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || ''));
        });
      };

      // ── 저장 (모드에 따라 TB_PROV_HTML / TB_PROV_VRSN / TB_DOCU) ──
      window.ideSaveProv = function() {
        // 본문은 textarea 직통 — CKEditor 동기화 불필요
        var url, payload;
        if (ideProvMode === 'docu') {
          // 개정분기 모드 — in-place 저장 대신 새 회차 분기 등록으로 라우팅 (레거시 화면과 동일)
          if (ideDocuBranchPromNo) { ideBranchDocu(); return; }
          url = DOCU_SAVE;
          payload = {
            docuNo:      ideDocuNo,
            viewPromNo:  ideDocuViewPromNo || '',   // 서버 가드 — 상속 행 in-place 수정 차단
            title:       document.getElementById('ideProvTitle').value,
            contents:    document.getElementById('ideProvContents').value,
            reason:      document.getElementById('ideProvReason').value,
            gaejungType: document.getElementById('ideProvGaejungType').value
          };
        } else {
          // HTML 조항 개정분기 모드 — in-place 저장 대신 새 회차 분기 등록 (별표와 동일)
          if (ideProvMode === 'html' && ideProvHtmlBranchPromNo) { ideBranchProvHtml(); return; }
          // 신규 HTML 조항 — 조번호/가지번호 입력행이 떠 있으면 SITEM(조4+가지2) 구성·검증
          if (ideProvMode === 'html' && document.getElementById('ideProvJoRow').style.display !== 'none') {
            var jo  = (document.getElementById('ideProvJoNo').value || '').trim();
            var sub = (document.getElementById('ideProvJoSubNo').value || '0').trim();
            if (!jo || !/^[0-9]+$/.test(jo) || +jo < 1 || +jo > 9999) {
              alert('조 번호는 1~9999 숫자입니다.'); document.getElementById('ideProvJoNo').focus(); return; }
            if (!/^[0-9]+$/.test(sub) || +sub < 0 || +sub > 99) {
              alert('가지번호는 0~99 숫자입니다.'); document.getElementById('ideProvJoSubNo').focus(); return; }
            if (!(document.getElementById('ideProvTitle').value || '').trim()) {
              alert('조문 제목을 입력하세요.'); document.getElementById('ideProvTitle').focus(); return; }
            document.getElementById('ideProvItem').value = ('0000' + jo).slice(-4) + ('00' + sub).slice(-2);
          }
          if (ideProvMode === 'html' && ckProvHtml) { try { ckProvHtml.updateElement(); } catch (e) {} }
          url = (ideProvMode === 'vrsn') ? PROV_VRSN_SAVE : PROV_SAVE;
          payload = $('#ideProvForm').serialize();
        }
        $.ajax({ url: url, method: 'POST', data: payload, dataType: 'json' })
          .done(function(d) {
            if (d.success) {
              if (ideProvMode === 'html' && d.provHtmlNo)
                document.getElementById('ideProvHtmlNo').value = d.provHtmlNo;
              var stat = '저장됨';
              if (ideProvMode === 'html' && d.provHtmlNo) stat += ' (provHtmlNo=' + d.provHtmlNo + ')';
              if (ideProvMode === 'docu' && d.docuNo)     stat += ' (docuNo='     + d.docuNo     + ')';
              document.getElementById('ideProvStatus').innerText = stat;
              document.getElementById('ideProvStatus').className = 'ide-prov-status exist';
              // 등록 완료 후에도 HTML 조항(자기 회차)은 번호 수정이 가능하므로 입력행을 남긴다(2026-07-30).
              toggleProvJoRow(ideProvMode === 'html' && !ideProvHtmlBranchPromNo);
              setProvSaveLabel('edit');   // 이후 저장은 수정
              if (ideProvMode === 'html' && d.item)
                document.getElementById('ideProvHead').innerText =
                  d.item + '  —  ' + (document.getElementById('ideProvTitle').value || '');
              // 트리 즉시 반영 — 저장된 제목/라벨이 노드 텍스트에 바로 보이도록 연혁목차 트리 새로고침
              // (refresh 는 열림/선택 상태를 보존하므로 사용자가 보던 위치 유지)
              try { var $h = $('#ideTreeHistory'); if ($h.jstree(true)) $h.jstree(true).refresh(); } catch (e) {}
              ideToast(d.message || '저장되었습니다.');
              window.ideClearDirty();
            } else {
              alert(d.message || '저장에 실패했습니다.');
            }
          }).fail(function(xhr) {
            alert('저장 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || ''));
          });
      };

      // ── 삭제 (모드별 라우팅) — own-회차 기존행만. 상속/신규/vrsn 은 버튼 자체가 숨김 ──
      //   상속(이전회차) 행은 서버 own-회차 가드가 거부 → "개정분기 후 삭제(숨김)" 경로로 안내.
      window.ideDeleteProv = function() {
        if (ideProvMode === 'docu') {
          if (!ideDocuNo || ideDocuBranchPromNo) { alert('삭제할 별표가 없습니다.'); return; }
          var dtitle = (document.getElementById('ideProvTitle').value || '이 별표/별지서식');
          if (!confirm('[' + dtitle + ']\n이 별표/별지서식을 완전히 삭제합니다.\n' +
                       '※ 자기 회차에 등록된 행만 물리 삭제되며 되돌릴 수 없습니다.\n' +
                       '   (이전 회차 보존본에는 영향 없음 — 이 회차 기준 이후 현행 목록에서 제거)\n계속하시겠습니까?')) return;
          $.post(DOCU_DELETE, { docuNo: ideDocuNo, viewPromNo: ideDocuViewPromNo || '' }, null, 'json')
            .done(ideAfterDelete).fail(ideDeleteFail);
        } else if (ideProvMode === 'html') {
          var hno = document.getElementById('ideProvHtmlNo').value;
          if (!hno || ideProvHtmlBranchPromNo) { alert('삭제할 조항이 없습니다.'); return; }
          var htitle = (document.getElementById('ideProvTitle').value ||
                        document.getElementById('ideProvItem').value || '이 조항');
          if (!confirm('[' + htitle + ']\n이 HTML 조항을 완전히 삭제합니다.\n' +
                       '※ 자기 회차에 등록된 행만 물리 삭제되며 되돌릴 수 없습니다.\n' +
                       '   (이전 회차 보존본에는 영향 없음 — 이 회차 기준 이후 현행 목록에서 제거)\n계속하시겠습니까?')) return;
          $.post(PROVHTML_DELETE, { provHtmlNo: hno, viewPromNo: ideProvHtmlViewPromNo || '' }, null, 'json')
            .done(ideAfterDelete).fail(ideDeleteFail);
        } else {
          alert('버전관리(VERSION) 조문은 단건 삭제 버튼이 없습니다.\n\n'
              + '삭제 방법: 좌측 트리에서 [조문] 그룹을 클릭해 일괄편집기를 열고,\n'
              + '해당 조 블록을 지운 뒤 [저장하기] 하면 그 조가 삭제(숨김) 처리됩니다.\n'
              + '(이전 회차 보존본에는 영향 없음)');
        }
      };
      function ideAfterDelete(d) {
        if (!d || !d.success) { alert((d && d.message) || '삭제에 실패했습니다.'); return; }
        // 트리에서 삭제 노드 제거 (열림/선택 상태 보존) + 편집 폼 닫고 안내 pane 복귀
        try { var $h = $('#ideTreeHistory'); if ($h.jstree(true)) $h.jstree(true).refresh(); } catch (e) {}
        ideCancelEdit();   // destroyCkProv + 중앙 pane 안내화면 복귀
        ideToast(d.message || '삭제되었습니다.');
      }
      function ideDeleteFail(xhr) {
        alert('삭제 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || ''));
      }

      // ── 버전관리용조문편집 (레거시 화면 그대로 — "조문" 그룹 클릭 시) ──
      var ideBulkFullBody = '';     // 항기호 포함 원본 본문
      var ideBulkPromNo   = null;   // 현재 편집 중인 회차 (저장 시 사용)
      function loadProvBulkBody(promNo, node) {
        destroyCkProv(); destroyCkPromBody();
        showCenterPane('bulk');
        ideBulkPromNo = promNo;
        document.getElementById('ideBulkHead').innerText  = '버전관리용조문편집';
        document.getElementById('ideBulkBody').value      = '';
        document.getElementById('ideBulkRowCnt').innerText = '0';
        document.getElementById('ideBulkStatus').innerText = '로딩...';
        $.ajax({ url: BULK_GET, data: { promNo: promNo }, dataType: 'json' })
          .done(function(d) {
            if (!d.found) {
              document.getElementById('ideBulkHead').innerText = '버전관리용조문편집';
              document.getElementById('ideBulkBody').value      = '';
              ideBulkFullBody = '';
              document.getElementById('ideBulkStatus').innerText = '본문 없음: ' + (d.error || '');
              document.getElementById('ideBulkStatus').className = 'ide-prov-status new';
              // 평문 textarea 직통 — 별도 init 불필요 (위에서 value='' 로 비움)
              return;
            }
            var title = d.title || '(제목없음)';
            ideBulkFullBody = d.body || '';
            document.getElementById('ideBulkHead').innerText  = '버전관리용조문편집 — ' + title;
            // 본문은 textarea 직통 — CKEditor 비동기 init 없이 즉시 적용
            ideBulkApplyHangToggle();
            document.getElementById('ideBulkRowCnt').innerText = String(d.rowCnt || 0);
            document.getElementById('ideBulkStatus').innerText = '누적 행 ' + (d.rowCnt || 0) + '건';
            document.getElementById('ideBulkStatus').className = 'ide-prov-status exist';
            ideBulkRefreshHistory();   // 이전개정작업내용 드롭다운 채움
          })
          .fail(function(xhr) {
            document.getElementById('ideBulkHead').innerText = '버전관리용조문편집';
            document.getElementById('ideBulkStatus').innerText = '조회 실패 (' + xhr.status + ')';
            document.getElementById('ideBulkStatus').className = 'ide-prov-status new';
          });
      }
      // 원문자 항 번호(①~㊿, 1~50) → 정수. 유니코드 원문자 3개 블록. 매칭 안 되면 0.
      //   charCodeAt 단순 뺄셈은 ⑳(U+2473) 이후 블록이 끊겨 21항부터 오작동 → 블록별 매핑.
      function rlmsCircledToInt(ch) {
        var c = ch.charCodeAt(0);
        if (c >= 0x2460 && c <= 0x2473) return c - 0x2460 + 1;    // ① ~ ⑳
        if (c >= 0x3251 && c <= 0x325F) return c - 0x3251 + 21;   // ㉑ ~ ㉟
        if (c >= 0x32B1 && c <= 0x32BF) return c - 0x32B1 + 36;   // ㊱ ~ ㊿
        return 0;
      }
      // 조문 펼침/개요 토글 — 기본은 전체 펼침. 개요 모드면 ①②③·1.2.·(1)·가. 로 시작하는
      //   항·호·목 행을 접어 장·조 골격만 표시. (레거시 "항기호 보기" 토글과 동작 동일, UI 만 상태표시 버튼)
      var ideBulkOutlineMode = false;   // false = 전체 펼침(기본) / true = 개요만
      // 현재 모드를 본문에 "적용"만 함 (상태 변경 없음) — 회차 로딩(loadProvBulkBody)/토글 후 공통 렌더
      function ideBulkApplyHangToggle() {
        ideBulkRenderOutlineBtn();
        if (!ideBulkOutlineMode || !ideBulkFullBody) {
          bulkSetBody(ideBulkFullBody);
          return;
        }
        var lines = ideBulkFullBody.split(/\r?\n/);
        var keep = [];
        var HANG_RE = /^\s*([①-⑳㉑-㉟㊱-㊿]|\d+\.|\([0-9]+\)|[가-힣]\.)\s*/;   // "N)" 는 단위 아님(연속본문, #6 2안) → 개요접힘 제외
        for (var i = 0; i < lines.length; i++) {
          if (!HANG_RE.test(lines[i])) keep.push(lines[i]);
        }
        bulkSetBody(keep.join('\n'));
      }
      // 버튼 클릭 — 모드 토글 후 적용
      function ideBulkToggleOutline() {
        ideBulkOutlineMode = !ideBulkOutlineMode;
        ideBulkApplyHangToggle();
      }
      // 버튼 라벨/스타일을 현재 모드에 맞게 (수행할 동작을 라벨로 표시)
      function ideBulkRenderOutlineBtn() {
        var btn = document.getElementById('ideBulkOutlineBtn');
        if (!btn) return;
        btn.textContent = ideBulkOutlineMode ? '전체 펼치기' : '개요만 보기';
        btn.classList.toggle('is-outline', ideBulkOutlineMode);
      }
      window.ideBulkToggleOutline = ideBulkToggleOutline;
      window.ideBulkToggleHang    = ideBulkApplyHangToggle;   // 하위호환 (외부 호출부 보호)

      // ── 문서에서 가져오기 (.docx/.hwpx → 평문 추출 → 미리보기 → 편집기 주입 + 원본 보존) ──
      var ideDocImportText = '';
      var ideDocImportFileObj = null;   // 원본 파일(File) — 반영 시 관련자료 FILE 로 보존
      window.ideDocImportPick = function(inp) {
        var f = inp.files && inp.files[0];
        inp.value = '';            // 같은 파일 재선택 허용
        if (!f) return;
        ideDocImportFileObj = f;
        var fd = new FormData();
        fd.append('file', f);
        ideToast('추출 중...');
        $.ajax({ url: DOC_IMPORT_URL, type: 'POST', data: fd,
                 processData: false, contentType: false, dataType: 'json' })
          .done(function(d) {
            if (!d || !d.ok) { alert('추출 실패: ' + (d&&d.error?d.error:'?')); return; }
            ideDocImportText = d.text || '';
            $('#ideDocImportCtx').text(d.fileName + '  -  ' + (d.lineCnt||0) + '행');
            $('#ideDocImportPreview').val(ideDocImportText);
            $('#ideDocImportModal').show();
          })
          .fail(function(x){ alert('추출 통신 오류 ('+x.status+')'); });
      };
      window.ideDocImportClose = function() { $('#ideDocImportModal').hide(); };
      // mode: 'replace' = 교체, 'append' = 뒤에 붙이기
      window.ideDocImportApply = function(mode) {
        var text = $('#ideDocImportPreview').val();   // 사용자가 미리보기에서 수정했을 수 있음
        // ideBulkFullBody 가 원본(개요 토글 기준)이므로 그쪽도 갱신
        if (mode === 'append') {
          var cur = ideBulkFullBody || '';
          ideBulkFullBody = cur ? (cur.replace(/\s+$/,'') + '\n\n' + text) : text;
        } else {
          ideBulkFullBody = text;
        }
        ideBulkOutlineMode = false;        // 가져온 직후엔 전체 펼침으로
        ideBulkApplyHangToggle();           // ideBulkBody 에 반영 + 버튼 라벨
        $('#ideDocImportModal').hide();
        ideToast('편집기에 ' + (mode==='append'?'추가':'반영') + '됨 — 항·호 정리 후 [저장하기]');
        // 원본 파일 보존 — 관련자료 FILE 로 업로드 → 좌측/우측에서 다운로드 가능
        ideDocImportSaveSource();
      };
      // 원본 문서를 관련자료 FILE 로 저장 (다운로드 보존용)
      function ideDocImportSaveSource() {
        if (!ideDocImportFileObj) return;
        if (!ideBulkPromNo) { ideDocImportFileObj = null; return; }
        var fd = new FormData();
        fd.append('promNo', ideBulkPromNo);
        fd.append('flag',   'PROMULGATION');         // 회차 단위
        fd.append('title',  ideDocImportFileObj.name);
        if (typeof SYS_ID!=='undefined'&&SYS_ID) fd.append('sysId', SYS_ID);   // 비면 미전송 → 서버 정본값
        fd.append('file',   ideDocImportFileObj);
        $.ajax({ url: REL_SAVE_FILE, type: 'POST', data: fd,
                 processData: false, contentType: false, dataType: 'json' })
          .done(function(d){
            if (d && d.ok) {
              ideToast('원본 파일도 보존됨 (관련자료에서 다운로드)');
              if (typeof loadRelatedList==='function')
                loadRelatedList(ideBulkPromNo, null);  // 우측 패널 갱신
            }
          })
          .always(function(){ ideDocImportFileObj = null; });
      }
      // ── 유효성 검사 결과 모달 (F4) — 레거시 "조문 유효성 검사 결과" ─────
      // 흐름:
      //   1) [유효성검사] 또는 [저장하기] 클릭 → ideBulkRunValidation 실행
      //   2) 검증 결과를 모달에 표시 (오류 N건 또는 "올바르게 작성된 조문입니다")
      //   3) [검증완료] 클릭 → 실저장 (ideBulkPerformSave)
      //   4) [창닫기] 클릭 → 모달 닫기만 (저장 안 함)
      var ideBulkValidateAfterOK = false;  // true = 검증완료 시 자동 저장 / false = 수동 검사만

      /** 본문 검증 — issues 배열 반환 ([{lineNo, where, content, problem, fix}])
       *  where = 사람이 찾는 위치 라벨("제4조(사업) ②" 등) — 행 번호만으로는 편집기에서 못 찾는 문제 해결 */
      function ideBulkRunValidation(text) {
        var issues = [];
        var lines = text.split(/\r?\n/);
        var joNumbers = {};        // 조 번호 → 라인번호 (중복 검사)
        var lastJoLineNo = -1;
        var lastHang = 0, lastHo = 0;
        var unitInJo = '';         // 현재 조 안 단위 ('hang' | 'ho' | '')
        var curJoLabel = '', curHangLabel = '';   // 위치 라벨 추적 (조 제목 포함, 항 원문자)
        function whereLabel() {
          return (curJoLabel + (curHangLabel ? ' ' + curHangLabel : '')).trim();
        }
        for (var i = 0; i < lines.length; i++) {
          var raw = lines[i];
          var s = raw.trim();
          if (!s) continue;
          var lineNo = i + 1;
          // 부칙 헤더 — 이후의 제N조는 본문과 별도 번호공간 (서버 ProvTextParser 가 POST_SCRIPT 로 분리)
          if (/^부\s*칙\s*(<.*)?$/.test(s)) {
            joNumbers = {}; lastJoLineNo = -1; lastHang = 0; lastHo = 0; unitInJo = '';
            curJoLabel = '부칙'; curHangLabel = '';
            continue;
          }
          // 장 / 조 / 항 / 호 매칭
          var m;
          if ((m = s.match(/^제\s*(\d+)\s*장/))) {
            // 장 — 검증 단순 (중복은 무시)
            lastHang = 0; lastHo = 0; unitInJo = '';
            continue;
          }
          if ((m = s.match(/^제\s*(\d+)\s*조(?:\s*의\s*(\d+))?\s*(\([^)]{1,40}\))?/))) {
            var jn = parseInt(m[1], 10);
            var jsub = m[2] ? parseInt(m[2], 10) : 0;
            var jkey = jn + '-' + jsub;
            var jlabel = '제' + jn + '조' + (jsub > 0 ? '의' + jsub : '') + (m[3] || '');
            curJoLabel = jlabel; curHangLabel = '';
            if (joNumbers[jkey] != null) {
              issues.push({ lineNo: lineNo, where: jlabel, content: s, problem: '중복 조 번호', fix: jlabel + ' 가 ' + joNumbers[jkey] + '행 에 이미 있습니다. 번호 정정 필요.' });
            } else {
              joNumbers[jkey] = lineNo;
            }
            lastJoLineNo = lineNo;
            lastHang = 0; lastHo = 0; unitInJo = '';
            continue;
          }
          if ((m = s.match(/^([①-⑳㉑-㉟㊱-㊿])\s*(.*)$/))) {
            var n = rlmsCircledToInt(m[1]);
            // ② 진입 시 lastHo 리셋 — 항이 바뀌면 호 번호 카운터도 초기화
            lastHo = 0;
            curHangLabel = m[1];
            if (lastHang > 0 && n !== lastHang + 1) {
              issues.push({ lineNo: lineNo, where: whereLabel(), content: s, problem: '항 번호 비순차', fix: '직전 항 ' + lastHang + '번 다음은 ' + (lastHang + 1) + '번 이어야 합니다.' });
            }
            lastHang = n; unitInJo = 'hang';
            continue;
          }
          // 호 = "N." 만. "N)"·"가)" 는 별개 단위로 보지 않고 앞 행 본문의 연속으로 처리(#6 2안) → 호 비순차 오탐 없음.
          if ((m = s.match(/^(\d+)\.\s*(.*)$/))) {
            var hn = parseInt(m[1], 10);
            if (lastHo > 0 && hn !== lastHo + 1) {
              issues.push({ lineNo: lineNo, where: whereLabel(), content: s, problem: '호 번호 비순차', fix: '직전 호 ' + lastHo + '번 다음은 ' + (lastHo + 1) + '번 이어야 합니다 (또는 새 항 ②/③ 가 빠졌을 수도).' });
            }
            lastHo = hn; unitInJo = 'ho';
            continue;
          }
          // 미인식 라인("N)"·"가)" 포함) — 이전 본문 이어쓰기로 간주 (parser 가 그렇게 처리). 오류 아님.
        }
        return issues;
      }

      /** 결과 모달 표시. autoSave=true 면 [검증완료] 클릭 시 실저장 호출. */
      function ideBulkShowValidateModal(issues, autoSave) {
        ideBulkValidateAfterOK = !!autoSave;
        var $tbody = $('#ideBulkValidateTbody');
        if (!issues || issues.length === 0) {
          $tbody.html('<tr><td colspan="4" class="status ok">올바르게 작성된 조문입니다.</td></tr>');
          document.getElementById('ideBulkValidateCount').innerText = '0';
        } else {
          var h = '';
          for (var i = 0; i < issues.length; i++) {
            var it = issues[i];
            // 행 클릭 → 편집기 해당 라인으로 점프 (행번호만으론 textarea 에서 위치를 못 찾는 문제 해결)
            h += '<tr class="v-jump" onclick="ideBulkJumpToLine(' + (it.lineNo || 0) + ')" title="클릭하면 편집기 ' + (it.lineNo || '?') + '행으로 이동">'
              +    '<td class="center"><span class="v-where">' + ideEsc(it.where || '') + '</span><span class="v-lineno">' + (it.lineNo || '') + '행</span></td>'
              +    '<td>' + ideEsc(it.content || '') + '</td>'
              +    '<td class="problem">' + ideEsc(it.problem || '') + '</td>'
              +    '<td class="fix">' + ideEsc(it.fix || '') + '</td>'
              +  '</tr>';
          }
          $tbody.html(h);
          document.getElementById('ideBulkValidateCount').innerText = String(issues.length);
        }
        // 검증완료 버튼: autoSave 면 저장, 아니면 단순 닫기.
        // 오류가 있어도 항상 활성 — 중간 저장 가능 (확인 다이얼로그로 한 번 더 묻기)
        var $btn = $('#ideBulkValidateConfirmBtn');
        $btn.prop('disabled', false).css('opacity', '1');
        if (autoSave) {
          if (issues && issues.length > 0) {
            $btn.text('검증완료 (오류 ' + issues.length + '건 무시하고 저장)');
          } else {
            $btn.text('검증완료 (저장)');
          }
        } else {
          $btn.text('검증완료');
        }
        // 오류 개수 메모 — confirm 메시지용
        $btn.data('issue-count', issues ? issues.length : 0);
        document.getElementById('ideBulkValidateModal').style.display = 'flex';
      }

      /** 검증 결과 행 클릭 → 모달 닫고 일괄편집 textarea 의 해당 라인 선택+스크롤.
       *  줄바꿈(soft wrap) 때문에 lineNo×행높이 추정은 어긋남 — 앞부분만 잘라 넣어 실제
       *  스크롤높이를 측정하는 방식(표준 기법). value 재대입으로 undo 스택은 초기화됨(수용). */
      window.ideBulkJumpToLine = function(lineNo) {
        ideCloseBulkValidateModal();
        var ta = document.getElementById('ideBulkBody');
        if (!ta || !lineNo) return;
        var lines = ta.value.split('\n');
        if (lineNo > lines.length) lineNo = lines.length;
        var start = 0;
        for (var i = 0; i < lineNo - 1; i++) start += lines[i].length + 1;
        var end = start + (lines[lineNo - 1] || '').length;
        var full = ta.value;
        ta.value = full.substring(0, start);
        var y = ta.scrollHeight;                      // 라인 시작까지의 실제 콘텐츠 높이(soft wrap 포함 실측)
        ta.value = full;
        // scrollHeight 는 clientHeight 가 하한 — 그 이하면 첫 화면 안이므로 최상단으로.
        var target = (y <= ta.clientHeight) ? 0 : (y - ta.clientHeight / 2);
        ta.setSelectionRange(start, end);             // 라인 전체 선택 = 하이라이트
        ta.focus();                                   // focus 가 커서 위치로 자동 스크롤하므로
        ta.scrollTop = target;                        // 스크롤은 반드시 마지막(라인을 중앙에)
      };

      window.ideCloseBulkValidateModal = function() {
        document.getElementById('ideBulkValidateModal').style.display = 'none';
        ideBulkValidateAfterOK = false;
      };

      /** [검증완료] 버튼 — autoSave 모드면 실저장, 아니면 단순 닫기.
          오류 있으면 한 번 더 confirm — 중간 저장 의도 보호. */
      window.ideBulkValidateConfirm = function() {
        if (!ideBulkValidateAfterOK) { ideCloseBulkValidateModal(); return; }
        var issueCount = $('#ideBulkValidateConfirmBtn').data('issue-count') || 0;
        if (issueCount > 0) {
          if (!confirm('검증 오류 ' + issueCount + ' 건이 있습니다.\n그대로 저장하시겠습니까? (작성 중인 본문은 보존됩니다)')) return;
        }
        ideCloseBulkValidateModal();
        ideBulkPerformSave();
      };

      /** [유효성검사] 버튼 — 결과만 표시 (저장 X) */
      window.ideBulkValidate = function() {
        var txt = bulkGetBody();
        var issues = ideBulkRunValidation(txt);
        ideBulkShowValidateModal(issues, false);
      };
      // ── 이전개정작업내용 (TB_PROV_TEXT_HST) ─────────────
      function ideBulkRefreshHistory() {
        var $sel = $('#ideBulkHistorySel');
        $sel.html('<option value="">이전개정작업내용 (로딩...)</option>');
        if (!ideBulkPromNo) {
          $sel.html('<option value="">이전개정작업내용</option>');
          return;
        }
        $.ajax({ url: BULK_HST_LIST, data: { promNo: ideBulkPromNo }, dataType: 'json' })
          .done(function(list) {
            var h = '<option value="">이전개정작업내용 (' + (list ? list.length : 0) + ')</option>';
            if (list) for (var i = 0; i < list.length; i++) {
              var hst = list[i];
              var label = (hst.insDt || '') + (hst.userId ? '  ' + hst.userId : '');
              h += '<option value="' + hst.provTextHstNo + '">' + ideEsc(label) + '</option>';
            }
            $sel.html(h);
          })
          .fail(function() { $sel.html('<option value="">이전개정작업내용 (조회 실패)</option>'); });
      }
      window.ideBulkLoadHistory = function() {
        var no = document.getElementById('ideBulkHistorySel').value;
        if (!no) { alert('이전개정작업내용 항목을 먼저 선택하세요.'); return; }
        if (!confirm('선택한 이전 작업 내용으로 본문을 교체합니다.\n현재 편집 내용은 사라집니다. 계속?')) return;
        $.ajax({ url: BULK_HST_BODY, data: { provTextHstNo: no }, dataType: 'json' })
          .done(function(d) {
            if (!d.found) { alert('본문을 찾을 수 없습니다.'); return; }
            ideBulkFullBody = d.body || '';
            ideBulkApplyHangToggle();
            document.getElementById('ideBulkStatus').innerText = '이전 작업본 불러옴 — ' + (d.insDt || '');
            document.getElementById('ideBulkStatus').className = 'ide-prov-status new';
          })
          .fail(function(xhr) { alert('불러오기 실패 (' + xhr.status + ')'); });
      };
      window.ideBulkDeleteHistory = function() {
        var no = document.getElementById('ideBulkHistorySel').value;
        if (!no) { alert('삭제할 항목을 먼저 선택하세요.'); return; }
        if (!confirm('선택한 이전 작업 내용을 삭제합니다. 계속?')) return;
        $.ajax({ url: BULK_HST_DEL, method: 'POST', data: { provTextHstNo: no }, dataType: 'json' })
          .done(function(d) {
            alert(d.message || (d.success ? '삭제되었습니다.' : '삭제 실패'));
            if (d.success) ideBulkRefreshHistory();
          })
          .fail(function(xhr) { alert('삭제 요청 실패: ' + xhr.status); });
      };

      // ── 중복 저장 방지 (2026-07-30 고객 테스트 지적) ────────────────────────────
      //  saveProvBulkBody 는 "회차 소유행 전량 DELETE → 재INSERT" 라, 첫 요청이 끝나기 전에
      //  두 번째 요청이 들어오면 두 트랜잭션이 겹쳐 조문이 2중으로 남는다.
      //  [저장 중] 글자만으로는 눈에 띄지 않아 실제로 두 번 눌린 사고가 보고됨 →
      //  ①진행 플래그로 재진입 차단 ②저장 버튼 비활성 ③상태 라벨을 눈에 띄게 표시.
      var ideBulkSaving = false;
      function ideBulkSetSaving(on) {
        ideBulkSaving = on;
        var btn = document.getElementById('ideBulkSaveBtn');
        if (btn) {
          btn.disabled = on;
          btn.innerText = on ? '저장 중…' : '저장하기';
        }
      }

      /** [저장하기] — 즉시 저장하지 않고 유효성검사 모달 띄움 (F4 흐름) */
      window.ideBulkSave = function() {
        if (ideBulkSaving) { ideToast('저장 중입니다. 잠시만 기다려 주세요.'); return; }
        if (!ideBulkPromNo) { alert('회차를 먼저 선택하세요.'); return; }
        if (ideBulkOutlineMode) {
          if (!confirm('지금은 개요 보기 상태입니다. 화면에 보이는 장·조 골격만 저장됩니다.\n계속하시겠습니까?\n(취소를 누르면 [전체 펼치기]로 되돌리고 다시 시도하세요)')) return;
        }
        var body = bulkGetBody();
        if (!body.trim()) { alert('본문이 비어 있습니다.'); return; }
        // 유효성검사 모달 — [검증완료] 클릭 시 자동 저장 (autoSave=true)
        var issues = ideBulkRunValidation(body);
        ideBulkShowValidateModal(issues, true);
      };

      /** 실제 저장 — 유효성검사 [검증완료] 클릭 시 호출 */
      function ideBulkPerformSave() {
        if (ideBulkSaving) { ideToast('저장 중입니다. 잠시만 기다려 주세요.'); return; }
        if (!ideBulkPromNo) { alert('회차를 먼저 선택하세요.'); return; }
        var body = bulkGetBody();
        if (!body.trim()) { alert('본문이 비어 있습니다.'); return; }
        ideBulkSetSaving(true);
        document.getElementById('ideBulkStatus').innerText = '저장 중…';
        document.getElementById('ideBulkStatus').className = 'ide-prov-status saving';
        // 본문은 text/plain 원시 본문으로 전송(promNo 는 쿼리스트링) — 한국법령 전문은 form-urlencoded 시
        //   한글이 ~4배 팽창해 Tomcat maxPostSize(기본 2MB)를 넘어 저장이 끊긴다. 원시 본문이면 팽창 없이 통과.
        $.ajax({ url: BULK_SAVE + '?promNo=' + encodeURIComponent(ideBulkPromNo), method: 'POST',
                 data: body, contentType: 'text/plain; charset=UTF-8', processData: false,
                 dataType: 'json' })
          .done(function(d) {
            if (d.success) {
              ideBulkFullBody = body;
              document.getElementById('ideBulkRowCnt').innerText = String(d.savedRow || 0);
              document.getElementById('ideBulkStatus').innerText = '저장됨 — ' + (d.savedRow || 0) + ' 행';
              document.getElementById('ideBulkStatus').className = 'ide-prov-status exist';
              ideToast(d.message || '저장되었습니다.');
              window.ideClearDirty();
              // 좌측 트리 새로고침 (저장한 본문 구조 반영)
              var $cate = $('#ideTreeCate');     if ($cate.jstree(true)) $cate.jstree('refresh');
              var $hist = $('#ideTreeHistory');  if ($hist.jstree(true)) $hist.jstree('refresh');
              // 이전개정작업내용 갱신 (방금 저장한 본문이 이력에 추가됨)
              ideBulkRefreshHistory();
            } else {
              document.getElementById('ideBulkStatus').innerText = '저장 실패';
              document.getElementById('ideBulkStatus').className = 'ide-prov-status new';
              alert(d.message || '저장에 실패했습니다.');
            }
          })
          .fail(function(xhr) {
            document.getElementById('ideBulkStatus').innerText = '저장 요청 실패 (' + xhr.status + ')';
            document.getElementById('ideBulkStatus').className = 'ide-prov-status new';
            alert('저장 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || ''));
          })
          .always(function() { ideBulkSetSaving(false); });
      }

      // ── 소관부서 선택 모달 ─────────────────────────────
      window.ideOpenBuseoModal = function() {
        document.getElementById('ideBuseoModal').style.display = 'flex';
        document.getElementById('ideBuseoSearch').value = '';
        document.getElementById('ideBuseoList').innerHTML = '<p class="empty">검색어 입력 또는 [검색] 으로 전체 조회</p>';
        setTimeout(function(){ document.getElementById('ideBuseoSearch').focus(); }, 50);
      };
      window.ideCloseBuseoModal = function() {
        document.getElementById('ideBuseoModal').style.display = 'none';
      };
      window.ideClearBuseo = function() {
        document.getElementById('idePromOrgnztId').value = '';
        document.getElementById('idePromBuseoNo').value = '';
        document.getElementById('idePromBuseoNm').value = '';
      };
      window.ideSearchBuseo = function() {
        var kw = document.getElementById('ideBuseoSearch').value || '';
        var $box = $('#ideBuseoList');
        $box.html('<p class="empty">조회 중...</p>');
        $.ajax({ url: BUSEO_LIST, data: { keyword: kw }, dataType: 'json' })
          .done(function(list) {
            if (!list || !list.length) { $box.html('<p class="empty">결과 없음</p>'); return; }
            var h = '<ul class="ide-buseo-list">';
            for (var i = 0; i < list.length; i++) {
              var b = list[i];
              var sub = b.fullNm && b.fullNm !== b.buseoNm ? ' <span class="fn">' + ideEsc(b.fullNm) + '</span>' : '';
              // 정본 키 = orgnztId. buseoNo 는 레거시 호환(표준화면 자체 생성 부서는 null)
              h += '<li><a href="#" onclick="idePickBuseo(\'' + ideEsc(b.orgnztId || '') + '\','
                +    (b.buseoNo != null ? b.buseoNo : 'null') + ',\''
                +    ideEsc(b.buseoNm).replace(/'/g,"\\'") + '\');return false;">'
                +    ideEsc(b.buseoNm) + sub
                +  '</a></li>';
            }
            h += '</ul>';
            $box.html(h);
          })
          .fail(function(xhr){ $box.html('<p class="empty">조회 실패 (' + xhr.status + ')</p>'); });
      };
      window.idePickBuseo = function(orgnztId, buseoNo, buseoNm) {
        document.getElementById('idePromOrgnztId').value = orgnztId || '';
        document.getElementById('idePromBuseoNo').value = (buseoNo != null) ? buseoNo : '';
        document.getElementById('idePromBuseoNm').value = buseoNm;
        ideCloseBuseoModal();
      };
      // Enter 키로 검색
      $(document).on('keydown', '#ideBuseoSearch', function(e) {
        if (e.which === 13) { e.preventDefault(); ideSearchBuseo(); }
      });
      // ESC 키로 닫기 (열려있는 모달 우선순위로 한 개만)
      $(document).on('keydown', function(e) {
        if (e.which !== 27) return;
        if (document.getElementById('ideMultiUpdateModal') &&
            document.getElementById('ideMultiUpdateModal').style.display !== 'none') {
          ideCloseMultiUpdateModal(); return;
        }
        if (document.getElementById('ideBulkValidateModal') &&
            document.getElementById('ideBulkValidateModal').style.display !== 'none') {
          ideCloseBulkValidateModal(); return;
        }
        if (document.getElementById('ideExclLnkModal') &&
            document.getElementById('ideExclLnkModal').style.display !== 'none') {
          ideCloseExclLnkModal(); return;
        }
        if (document.getElementById('ideMoveCateModal') &&
            document.getElementById('ideMoveCateModal').style.display !== 'none') {
          ideCloseMoveCateModal(); return;
        }
        if (document.getElementById('ideBuseoModal').style.display !== 'none') {
          ideCloseBuseoModal(); return;
        }
      });

      // ── 날짜 보조 ───────────────────────────────────────
      // 레거시 임포트 데이터의 폐지일 등은 "--" / "" / null 형태로 들어옴 →
      // <input type="date"> 는 "yyyy-MM-dd" 만 허용 → 그 외는 빈 문자열로 sanitize.
      function ideSafeIsoDate(s) {
        if (s == null) return '';
        var t = String(s).trim();
        return /^\d{4}-\d{2}-\d{2}$/.test(t) ? t : '';
      }
      window.ideSetDate = function(targetId, mode) {
        var el = document.getElementById(targetId);
        if (!el) return;
        if (mode === '') { el.value = ''; return; }
        if (mode === 'today') {
          var d = new Date(); var y = d.getFullYear();
          var m = ('0' + (d.getMonth()+1)).slice(-2);
          var dd= ('0' + d.getDate()).slice(-2);
          el.value = y + '-' + m + '-' + dd;
          return;
        }
        if (mode.indexOf('same:') === 0) {
          var src = document.getElementById(mode.substring(5));
          if (src) el.value = src.value;
          return;
        }
      };

      // ── 취소 ────────────────────────────────────────────
      window.ideCancelEdit = function() {
        destroyCkProv();
        destroyCkPromBody();
        showCenterPane('placeholder');
      };

      // ── 액션 set / 탭 전환 ──────────────────────────────
      function switchActionSet(mode) {
        document.getElementById('ideActionsCate').style.display = (mode === 'cate') ? '' : 'none';
        document.getElementById('ideActionsProm').style.display = (mode === 'prom') ? '' : 'none';
      }
      function switchTreeTab(tab) {
        var btns = document.querySelectorAll('.ide-tab');
        for (var i = 0; i < btns.length; i++)
          btns[i].classList.toggle('active', btns[i].getAttribute('data-tab') === tab);
        document.getElementById('ideTreeCate').classList.toggle('active',    tab === 'cate');
        document.getElementById('ideTreeHistory').classList.toggle('active', tab === 'history');
        document.getElementById('ideTreeDraft').classList.toggle('active',   tab === 'draft');
        ideRedrawActiveTree(tab);
      }

      // ── 작업중(draft) 패널 — 미승인 draft 회차 재발견 ─────────────────
      //   분류 트리(selectActivePromsForTree)는 현행만 실어 편집중/승인요청/승인반려 draft 가
      //   트리에서 사라짐(2026-06-30부터 신규도 승인 전 SEXISTING_YN='N') → 여기가 IDE 내 재진입점.
      //   항목 클릭 = loadPromForm(promNo) (editor.do 딥링크와 동일 경로, 연혁목차 자동 로드).
      window.ideLoadDraftPanel = function() {
        var pane = document.getElementById('ideTreeDraft');
        function esc(s){ return String(s==null?'':s).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];}); }
        $.ajax({ url: DRAFT_LIST_URL, dataType: 'json' })
          .done(function(list) {
            list = list || [];
            var cnt = document.getElementById('ideDraftCnt');
            if (cnt) { cnt.innerText = list.length; cnt.style.display = list.length ? '' : 'none'; }
            if (!list.length) {
              pane.innerHTML = '<p class="ide-tree-hint">작업중(미승인) 규정이 없습니다.</p>';
              return;
            }
            var html = '<p class="ide-tree-hint ide-draft-desc">승인 전 작업중(draft) 회차 — 분류 트리에는 현행만 표시되므로 여기서 이어서 편집하세요.</p>'
                     + '<div class="ide-draft-list">';
            list.forEach(function(d) {
              var sCls = (d.status === '편집중') ? 's-edit' : (d.status === '승인요청') ? 's-req' : 's-rej';
              html += '<button type="button" class="ide-draft-item" data-pno="' + esc(d.promNo) + '">'
                    +   '<span class="ide-draft-status ' + sCls + '">' + esc(d.status) + '</span>'
                    +   '<span class="ide-draft-title">' + esc(d.title || '(제목 없음)') + '</span>'
                    +   '<span class="ide-draft-meta">' + esc(d.cateNm || '미분류') + ' · ' + esc(d.userNm || '-')
                    +     ' · ' + esc(String(d.workDt || '').substring(0, 10)) + '</span>'
                    + '</button>';
            });
            html += '</div>';
            pane.innerHTML = html;
            var items = pane.querySelectorAll('.ide-draft-item');
            for (var i = 0; i < items.length; i++) {
              (function(el) {
                el.addEventListener('click', function() { loadPromForm(Number(el.getAttribute('data-pno'))); });
              })(items[i]);
            }
          })
          .fail(function() { pane.innerHTML = '<p class="ide-tree-hint">목록을 불러오지 못했습니다.</p>'; });
      };
      window.ideLoadDraftPanel();   // 초기 1회 — 탭 배지(건수) 표시용 (패널 자체는 숨김 상태로 렌더)

      // ── 분류 모드 액션 — 신규 규정 등록 (IDE 중앙 인라인 폼) ──
      window.fnNewProm = function() {
        if (!ctx.cateNo) { alert('좌측 트리에서 분류를 먼저 선택하세요.'); return; }
        destroyCkProv(); destroyCkPromBody();
        ideEnsureGaejungOptions();

        document.getElementById('idePromNo').value        = '';            // 빈값 → 서버가 insertProm
        document.getElementById('idePromLawId').value     = '';            // 빈값 = 신규 제정 (개정 등록은 ideNewRevision 이 세팅)
        document.getElementById('idePromCateNo').value    = ctx.cateNo;
        document.getElementById('idePromSysId').value     = SYS_ID;
        document.getElementById('idePromLawNo').value     = '10';          // 제정 연혁번호 = 10 (레거시, 직접 수정 가능)
        document.getElementById('idePromTitle').value     = '';
        document.getElementById('idePromSubTitle').value  = '';
        document.getElementById('idePromNumber').value    = '';
        document.getElementById('idePromOrderIdx').value  = '50';
        document.getElementById('idePromPromDate').value  = '';
        document.getElementById('idePromStartDate').value = '';
        document.getElementById('idePromNullDate').value  = '';
        document.getElementById('idePromUrl').value       = '';
        document.getElementById('idePromCateNm').value    = ctx.cateNm || '';
        document.getElementById('idePromOrgnztId').value  = '';   // 직전 편집분 부서 승계 차단 (필수검증 우회 방지)
        document.getElementById('idePromBuseoNo').value   = '';
        document.getElementById('idePromBuseoNm').value   = '';
        document.getElementById('idePromGaejungNo').value = '';
        document.getElementById('idePromDispYn').checked    = false;
        document.getElementById('idePromStsfdgYn').checked  = false;   // 신규 — 만족도 조사 기본 미사용
        // 신규 — 외부 열람 공개 여부 라디오는 미선택 (작성자가 명시 선택)
        document.getElementById('idePromExtDispYnY').checked = false;
        document.getElementById('idePromExtDispYnN').checked = false;
        document.getElementById('idePromProvFlag').value    = 'VERSION';
        document.getElementById('idePromProvStyleCd').value = 'NORMAL';
        if (document.getElementById('idePromRelFileView')) document.getElementById('idePromRelFileView').checked = false;
        idePendingProvFileNo = null;   // 신규 — 참조파일 미지정, 후보 캐시 무효화
        ideViewerFilesKey = null;
        ideChangeProvFlag('VERSION');
        document.getElementById('idePromBody_gaejung').value  = '';
        document.getElementById('idePromBody_reason').value   = '';
        document.getElementById('idePromBody_bylaw').value    = '';
        document.getElementById('idePromBody_preamble').value = '';
        // 레거시 Screen 1: "연혁등록" (분류 선택 시 자동 또는 신규 규정 등록 버튼)
        document.getElementById('idePromHead').innerText   = '연혁등록 — ' + (ctx.cateNm || '신규');
        document.getElementById('idePromStatus').innerText = '신규';
        document.getElementById('idePromStatus').className = 'ide-prov-status new';
        var _nRej = document.getElementById('idePromRejectBox');   // 이전 회차의 반려 사유 카드 잔존 방지
        if (_nRej) { _nRej.style.display = 'none'; _nRej.innerHTML = ''; }
        document.getElementById('ideBtnDeleteEmpty').style.display = 'none';   // 신규 등록 → 삭제 버튼 hide
        document.getElementById('ideBtnMoveCate').style.display    = 'none';   // 신규 → 분류이동 hide
        document.getElementById('ideBtnReqApprove').style.display  = 'none';   // 신규 → 승인요청 hide
        document.getElementById('ideBtnEditProv').style.display    = 'none';   // 신규 미저장 → 조문입력 hide (저장 후 노출)
        document.getElementById('idePromSaveBtn').innerText = '신규등록';

        // 본문 탭 리셋 → 개정이유 (레거시 첫 활성탭)
        var pbBtns = document.querySelectorAll('.ide-pbtab');
        for (var i = 0; i < pbBtns.length; i++)
          pbBtns[i].classList.toggle('active', pbBtns[i].getAttribute('data-pbtab') === 'reason');
        ['gaejung','reason','bylaw','preamble'].forEach(function(k){
          document.getElementById('idePromBody_'+k).style.display = (k === 'reason') ? '' : 'none';
        });
        curPbTab = 'reason';

        showCenterPane('prom');
        ckPromBody = CKEDITOR.replace('idePromBody_reason', ckPromBodyCfg());
      };

      // ── 새 연혁(개정) 등록 — 레거시 insertPromulgation(규정 루트 클릭) 파리티 ──
      //    · 작업중 draft(workingDraft=최신워크 편집중/승인요청/승인반려)가 있으면 차단 (서버도 동일 가드).
      //      ★existingYn==='N' 단독 판정 금지 — 과거 승인본도 전부 'N'(2026-07-09 오탐 교정)
      //    · 현행 회차 메타(제목/부제/분류/부서/규정형식)를 승계, 연혁번호는 +10 자동(수정 가능)
      window.ideNewRevision = function(lawId) {
        if (!lawId) { alert('규정을 먼저 선택하세요.'); return; }
        $.ajax({ url: HIST_URL, data: { lawId: lawId }, dataType: 'json' })
          .done(function(roots) {
            var proms = (roots && roots[0] && roots[0].children) ? roots[0].children : [];
            var working = proms.filter(function(nd){ return nd.data && nd.data.workingDraft === true; });
            if (working.length > 0) {
              alert('작업중(승인 대기) 회차가 이미 있습니다 — ' + working[0].text
                  + '\n해당 회차를 이어서 작업하거나, 승인(또는 삭제) 후 새 연혁을 등록하세요.');
              return;
            }
            var cur = null;
            for (var i = 0; i < proms.length; i++) {
              if (proms[i].data && proms[i].data.existingYn === 'Y') { cur = proms[i]; break; }
            }
            if (!cur) cur = proms[0];
            if (!cur || !cur.data || !cur.data.promNo) { alert('승계할 회차를 찾지 못했습니다.'); return; }
            $.ajax({ url: PROM_GET, data: { promNo: cur.data.promNo }, dataType: 'json' })
              .done(function(d) {
                if (!d.found) { alert('현행 회차 조회에 실패했습니다.'); return; }
                ctx.cateNo = d.cateNo;
                ctx.cateNm = d.cateFullNm || d.cateNm || '';
                fnNewProm();                                     // 폼 리셋 (분류 컨텍스트 반영)
                document.getElementById('idePromLawId').value    = lawId;
                document.getElementById('idePromTitle').value    = d.title || '';
                document.getElementById('idePromSubTitle').value = d.subTitle || '';
                document.getElementById('idePromOrgnztId').value = d.orgnztId || '';
                document.getElementById('idePromBuseoNo').value  = (d.buseoNo != null) ? d.buseoNo : '';
                document.getElementById('idePromBuseoNm').value  = d.buseoNm || '';
                var pf = (d.provFlag === 'FILE_VIEWER') ? 'VIEWER' : (d.provFlag || 'VERSION');
                document.getElementById('idePromProvFlag').value    = pf;
                document.getElementById('idePromProvStyleCd').value = d.provStyleCd || 'NORMAL';
                ideChangeProvFlag(pf);
                document.getElementById('idePromHead').innerText =
                    '연혁등록(개정) — ' + (d.title || '') + (d.lawNo != null ? ' (현행 ' + d.lawNo + '차 승계)' : '');
                // 연혁번호 자동 +10 (직접 수정 가능)
                $.ajax({ url: NEXT_LAWNO, data: { lawId: lawId }, dataType: 'json' })
                  .done(function(r) { if (r && r.lawNo != null) document.getElementById('idePromLawNo').value = r.lawNo; });
                // 개정구분 — '개정' 옵션이 있으면 기본 선택 (옵션 비동기 로드 직후 반영, 실패해도 필수검증이 잡음)
                setTimeout(function() {
                  var sel = document.getElementById('idePromGaejungNo');
                  for (var i = 0; i < sel.options.length; i++)
                    if (sel.options[i].textContent.trim() === '개정') { sel.value = sel.options[i].value; break; }
                }, 300);
              })
              .fail(function() { alert('현행 회차 조회에 실패했습니다.'); });
          })
          .fail(function() { alert('연혁 목록 조회에 실패했습니다.'); });
      };

      // ── 개정구분(TB_GAEJUNG) 옵션 1회 로드 + 캐시 ──
      var ideGaejungLoaded = false;
      function ideEnsureGaejungOptions() {
        if (ideGaejungLoaded) return;
        var sel = document.getElementById('idePromGaejungNo');
        if (!sel) return;
        $.ajax({ url: '<c:url value="/rlms/gaejung/selectGaejungJson.do"/>', dataType: 'json' })
          .done(function(d) {
            var list = (d && d.resultList) ? d.resultList : (Array.isArray(d) ? d : []);
            // 기존 옵션 보존 ("(선택)" 첫 번째)
            while (sel.options.length > 1) sel.remove(1);
            list.forEach(function(g){
              var opt = document.createElement('option');
              opt.value = g.gaejungNo;
              opt.textContent = g.gaejungNm || g.gaejungName || ('#' + g.gaejungNo);
              sel.appendChild(opt);
            });
            ideGaejungLoaded = true;
          })
          .fail(function(xhr){ console.warn('개정구분 옵션 로드 실패', xhr.status); });
      }
      // ── 연혁 일괄 수정 (레거시 PromulgationController.multipleUpdate) ─────
      //   분류 모드 "규정 일괄 수정" + 규정 모드 "연혁 일괄 수정" = 동일 모달.
      //   현재 선택된 규정(ctx.lawId / ctx.promNo)의 전 회차를 한 표에서 일괄편집.
      var MULTI_LIST_URL   = '<c:url value="/rlms/prom/promMultiUpdateListJson.do"/>';
      var MULTI_SAVE_URL   = '<c:url value="/rlms/prom/promMultiUpdateDo.do"/>';
      var MULTI_DELROW_URL = '<c:url value="/rlms/prom/deletePromRevision.do"/>';
      var MULTI_DELALL_URL = '<c:url value="/rlms/prom/deletePromAll.do"/>';
      var ideMultiUpdateLawId = null;
      var ideMultiGaejungOpts = null;   // [{no, nm}] 1회 캐시

      window.fnVrsnMultiUpdate = function() { ideOpenMultiUpdate(ctx.lawId, ctx.promNo); };

      // ── 규정 일괄 수정 (분류 단위) — 선택 분류의 현행 규정 메타 일괄수정 + 정렬순서(드래그) ──
      //    연혁일괄수정(한 규정의 회차)과 별개. ctx.cateNo 기준.
      var CATE_BULK_LIST_URL = '<c:url value="/rlms/prom/promCateBulkListJson.do"/>';
      var CATE_BULK_SAVE_URL = '<c:url value="/rlms/prom/promCateBulkUpdateDo.do"/>';
      var ideBuseoOpts = null;   // [{orgnztId, buseoNm}] 1회 캐시

      window.fnPromBulkUpdate = function() { ideOpenCateBulk(ctx.cateNo); };

      function ideEnsureBuseoOpts(cb) {
        if (ideBuseoOpts) { cb(); return; }
        $.ajax({ url: BUSEO_LIST, dataType: 'json' })
          .done(function(d) {
            ideBuseoOpts = [];
            (d || []).forEach(function(b) {
              var oid = b.orgnztId || b.orgnztID || b.ORGNZT_ID;
              if (oid) ideBuseoOpts.push({ orgnztId: oid, buseoNm: b.buseoNm || b.orgnztNm || oid });
            });
            cb();
          })
          .fail(function() { ideBuseoOpts = []; cb(); });
      }
      function ideGjSelHtml(sel) {
        var h = '<select class="krds-input cb-gj"><option value="">(선택)</option>';
        (ideMultiGaejungOpts || []).forEach(function(g) {
          h += '<option value="' + g.no + '"' + (String(g.no) === String(sel) ? ' selected' : '') + '>' + ideEsc(g.nm) + '</option>';
        });
        return h + '</select>';
      }
      function ideBsSelHtml(sel, selNm) {
        var found = false, opts = '';
        (ideBuseoOpts || []).forEach(function(b) {
          var isSel = (String(b.orgnztId) === String(sel));
          if (isSel) found = true;
          opts += '<option value="' + ideEsc(b.orgnztId) + '"' + (isSel ? ' selected' : '') + '>' + ideEsc(b.buseoNm) + '</option>';
        });
        var h = '<select class="krds-input cb-bs"><option value="">(선택)</option>';
        if (sel && !found) h += '<option value="' + ideEsc(sel) + '" selected>' + ideEsc(selNm || sel) + '</option>';   // 목록에 없는 현재값 보존
        return h + opts + '</select>';
      }
      function ideRenderCateBulkRows(rows) {
        var tb = document.getElementById('ideCateBulkTbody');
        if (!rows.length) { tb.innerHTML = '<tr><td colspan="6" class="status">현행 규정이 없습니다.</td></tr>'; return; }
        var html = '';
        rows.forEach(function(r) {
          html += '<tr class="ide-cbulk-row" data-pno="' + r.promNo + '">'
               +    '<td class="ide-cbulk-handle" draggable="true" title="끌어서 정렬 변경" style="cursor:move;text-align:center;font-size:17px;color:#8a93a6;user-select:none;">&#9776;</td>'
               +    '<td><input type="text" class="krds-input cb-title" value="' + ideEsc(r.title || '') + '"/></td>'
               +    '<td>' + ideGjSelHtml(r.gaejungNo) + '</td>'
               +    '<td>' + ideBsSelHtml(r.orgnztId, r.buseoNm) + '</td>'
               +    '<td class="col-hide" style="text-align:center;"><input type="checkbox" class="cb-hide"' + (r.dispYn === 'N' ? ' checked' : '') + '/></td>'
               +    '<td class="col-view" style="text-align:center;"><button type="button" class="krds-btn" onclick="ideCateBulkView(' + r.promNo + ')">보기</button></td>'
               +  '</tr>';
        });
        tb.innerHTML = html;
      }
      function ideOpenCateBulk(cateNo) {
        if (!cateNo) {
          alert('분류를 먼저 선택하세요.\n좌측 트리에서 분류를 클릭한 뒤 다시 시도하세요.');
          return;
        }
        ideEnsureMultiGaejung(function() {
          ideEnsureBuseoOpts(function() {
            $.ajax({ url: CATE_BULK_LIST_URL, data: { cateNo: cateNo }, dataType: 'json' })
              .done(function(d) {
                if (!d.success) { alert(d.message || '목록을 불러오지 못했습니다.'); return; }
                document.getElementById('ideCateBulkCtx').textContent =
                  '분류: ' + (d.cateTitle || '') + '   (현행 ' + (d.rows ? d.rows.length : 0) + ' 건)';
                ideRenderCateBulkRows(d.rows || []);
                document.getElementById('ideCateBulkModal').style.display = 'flex';
              })
              .fail(function(xhr) { alert('목록 요청 실패: ' + xhr.status); });
          });
        });
      }
      window.ideCloseCateBulk = function() { document.getElementById('ideCateBulkModal').style.display = 'none'; };
      window.ideCateBulkView  = function(pno) { ideCloseCateBulk(); if (typeof loadPromForm === 'function') loadPromForm(pno); };
      window.ideCateBulkSave  = function() {
        var trs = document.querySelectorAll('#ideCateBulkTbody tr.ide-cbulk-row');
        if (!trs.length) { alert('수정할 규정이 없습니다.'); return; }
        var promNos = [], params = {}, bad = null;
        trs.forEach(function(tr) {
          var pno = tr.getAttribute('data-pno');
          var title = (tr.querySelector('.cb-title').value || '').trim();
          var gj = tr.querySelector('.cb-gj').value;
          var bs = tr.querySelector('.cb-bs').value;
          var hide = tr.querySelector('.cb-hide').checked;
          if (!bad) { if (!title) bad = '제명을 입력하세요.'; else if (!gj) bad = '개정구분을 선택하세요. (' + title + ')'; else if (!bs) bad = '소관부서를 선택하세요. (' + title + ')'; }
          promNos.push(pno);
          params['title_' + pno] = title;
          params['gaejungNo_' + pno] = gj;
          params['orgnztId_' + pno] = bs;
          params['dispYn_' + pno] = hide ? 'N' : 'Y';
        });
        if (bad) { alert(bad); return; }
        params['promNos'] = promNos.join(',');   // 드래그 순서 = 저장 정렬순서(SORDERIDX)
        $.ajax({ url: CATE_BULK_SAVE_URL, type: 'POST', data: params, dataType: 'json' })
          .done(function(d) {
            alert(d.message || (d.success ? '저장되었습니다.' : '저장 실패'));
            if (d.success) {
              ideCloseCateBulk();
              try { if ($('#ideTreeCate').jstree(true)) $('#ideTreeCate').jstree(true).refresh(); } catch (e) {}
            }
          })
          .fail(function(xhr) { alert('저장 실패: ' + xhr.status); });
      };
      // 행 드래그 정렬 — ≡ 핸들에서만 시작(입력 필드 텍스트 선택 보존). HTML5 native DnD.
      (function() {
        var dragRow = null;
        function tbody() { return document.getElementById('ideCateBulkTbody'); }
        document.addEventListener('dragstart', function(e) {
          var h = e.target.closest && e.target.closest('.ide-cbulk-handle');
          if (!h) return;
          dragRow = h.closest('tr.ide-cbulk-row');
          if (dragRow) { dragRow.style.opacity = '0.4'; try { e.dataTransfer.effectAllowed = 'move'; e.dataTransfer.setData('text/plain', dragRow.getAttribute('data-pno')); } catch (x) {} }
        });
        document.addEventListener('dragend', function() { if (dragRow) dragRow.style.opacity = ''; dragRow = null; });
        document.addEventListener('dragover', function(e) {
          var tb = tbody(); if (!tb || !dragRow) return;
          var tr = e.target.closest && e.target.closest('tr.ide-cbulk-row');
          if (!tr || tr === dragRow || tr.parentNode !== tb) return;
          e.preventDefault();
          var rc = tr.getBoundingClientRect();
          var after = (e.clientY - rc.top) > rc.height / 2;
          tb.insertBefore(dragRow, after ? tr.nextSibling : tr);
        });
      })();

      function ideOpenMultiUpdate(lawId, promNo) {
        if (!lawId && !promNo) {
          alert('규정을 먼저 선택하세요.\n좌측 트리에서 규정 또는 회차를 클릭한 뒤 다시 시도하세요.');
          return;
        }
        ideEnsureMultiGaejung(function() {
          $.ajax({ url: MULTI_LIST_URL, data: { lawId: lawId || '', promNo: promNo || '' }, dataType: 'json' })
            .done(function(d) {
              if (!d.success) { alert(d.message || '목록을 불러오지 못했습니다.'); return; }
              ideMultiUpdateLawId = d.lawId;
              document.getElementById('ideMultiUpdateCtx').textContent =
                '규정: ' + (d.lawTitle || '') + '   (전 ' + (d.rows ? d.rows.length : 0) + ' 회차)';
              ideRenderMultiUpdateRows(d.rows || []);
              document.getElementById('ideMultiUpdateModal').style.display = 'flex';
            })
            .fail(function(xhr) { alert('목록 요청 실패: ' + xhr.status); });
        });
      }

      // 개정구분 옵션 1회 로드 — 행마다 select 빌드용 배열 캐시
      function ideEnsureMultiGaejung(cb) {
        if (ideMultiGaejungOpts) { cb(); return; }
        $.ajax({ url: '<c:url value="/rlms/gaejung/selectGaejungJson.do"/>', dataType: 'json' })
          .done(function(d) {
            ideMultiGaejungOpts = [];
            (d.resultList || []).forEach(function(g) {
              ideMultiGaejungOpts.push({ no: g.gaejungNo, nm: g.gaejungNm || g.gaejungName || ('#' + g.gaejungNo) });
            });
            cb();
          })
          .fail(function() { ideMultiGaejungOpts = []; cb(); });   // 옵션 못 받아도 표는 표시
      }

      function ideMultiGaejungSelectHtml(promNo, selectedNo) {
        var h = '<select class="ide-multi-gj" data-pno="' + promNo + '">';
        h += '<option value="">(선택)</option>';
        (ideMultiGaejungOpts || []).forEach(function(g) {
          var sel = (selectedNo != null && String(g.no) === String(selectedNo)) ? ' selected' : '';
          h += '<option value="' + g.no + '"' + sel + '>' + ideEsc(g.nm) + '</option>';
        });
        h += '</select>';
        return h;
      }

      function ideRenderMultiUpdateRows(rows) {
        var tb = document.getElementById('ideMultiUpdateTbody');
        if (!rows.length) { tb.innerHTML = '<tr><td colspan="8" class="status">회차가 없습니다.</td></tr>'; return; }
        var html = '';
        rows.forEach(function(r) {
          var pno = r.promNo;
          var cur = (r.existingYn === 'Y');
          var hideChk = (r.dispYn === 'N') ? ' checked' : '';
          html += '<tr class="ide-multi-row' + (cur ? ' is-current' : '') + '" data-pno="' + pno + '">';
          html += '<td rowspan="2" class="col-lawno">'
                + '<input type="number" class="ide-multi-lawno" data-pno="' + pno + '" value="' + (r.lawNo != null ? r.lawNo : '') + '"/>'
                + (cur ? '<span class="ide-multi-cur-badge">현행</span>' : '') + '</td>';
          html += '<td class="col-gj">' + ideMultiGaejungSelectHtml(pno, r.gaejungNo) + '</td>';
          html += '<td colspan="3" class="col-title"><input type="text" class="ide-multi-title" data-pno="' + pno + '" value="' + ideEsc(r.title) + '"/></td>';
          html += '<td rowspan="2" class="col-hide"><input type="checkbox" class="ide-multi-hide" data-pno="' + pno + '"' + hideChk + '/></td>';
          html += '<td rowspan="2" class="col-view"><button type="button" class="krds-btn" onclick="ideMultiUpdateView(' + pno + ')">보기</button></td>';
          html += '<td rowspan="2" class="col-del"><button type="button" class="krds-btn danger" onclick="ideMultiUpdateDeleteRow(' + pno + ')">삭제</button></td>';
          html += '</tr>';
          html += '<tr class="ide-multi-row2" data-pno="' + pno + '">';
          html += '<td class="col-num"><input type="text" class="ide-multi-num" data-pno="' + pno + '" value="' + ideEsc(r.number) + '"/></td>';
          html += '<td class="col-date"><input type="date" class="ide-multi-promdate" data-pno="' + pno + '" value="' + ideSafeIsoDate(r.promDate) + '"/></td>';
          html += '<td class="col-date"><input type="date" class="ide-multi-startdate" data-pno="' + pno + '" value="' + ideSafeIsoDate(r.startDate) + '"/></td>';
          html += '<td class="col-date"><input type="date" class="ide-multi-nulldate" data-pno="' + pno + '" value="' + ideSafeIsoDate(r.nullDate) + '"/></td>';
          html += '</tr>';
        });
        tb.innerHTML = html;
      }

      function ideMultiQVal(sel, pno) {
        var el = document.querySelector(sel + '[data-pno="' + pno + '"]');
        return el ? (el.value || '') : '';
      }

      function ideMultiUpdateSave() {
        var rows = document.querySelectorAll('#ideMultiUpdateTbody tr.ide-multi-row');
        if (!rows.length) { alert('저장할 데이터가 없습니다.'); return; }
        var promNos = [];
        var data = {};
        var bad = null;
        rows.forEach(function(tr) {
          var pno = tr.getAttribute('data-pno');
          var titleEl = document.querySelector('.ide-multi-title[data-pno="' + pno + '"]');
          var title = titleEl ? (titleEl.value || '').trim() : '';
          if (!title && !bad) bad = titleEl;
          promNos.push(pno);
          data['title_' + pno]     = title;
          data['lawNo_' + pno]     = ideMultiQVal('.ide-multi-lawno', pno);
          data['gaejungNo_' + pno] = ideMultiQVal('.ide-multi-gj', pno);
          data['number_' + pno]    = ideMultiQVal('.ide-multi-num', pno);
          var hideEl = document.querySelector('.ide-multi-hide[data-pno="' + pno + '"]');
          data['dispYn_' + pno]    = (hideEl && hideEl.checked) ? 'N' : 'Y';
          data['promDate_' + pno]  = ideMultiQVal('.ide-multi-promdate', pno);
          data['startDate_' + pno] = ideMultiQVal('.ide-multi-startdate', pno);
          data['nullDate_' + pno]  = ideMultiQVal('.ide-multi-nulldate', pno);
        });
        if (bad) { alert('제명을 입력하세요.'); bad.focus(); return; }
        if (!confirm('전 ' + promNos.length + ' 회차를 일괄 저장하시겠습니까?')) return;
        data['promNos'] = promNos.join(',');
        $.ajax({ url: MULTI_SAVE_URL, method: 'POST', data: data, dataType: 'json' })
          .done(function(d) {
            if (d.success) {
              ideToast(d.message || '저장되었습니다.');
              ideMultiUpdateRefreshTrees(d.lawId);
              ideOpenMultiUpdate(ideMultiUpdateLawId, null);   // 현행 재계산 반영해 표 갱신
            } else { alert(d.message || '저장에 실패했습니다.'); }
          })
          .fail(function(xhr) { alert('저장 요청 실패: ' + xhr.status); });
      }

      function ideMultiUpdateView(promNo) {
        ideCloseMultiUpdateModal();
        ctx.promNo = promNo;
        if (typeof loadPromForm === 'function') loadPromForm(promNo);
      }

      function ideMultiUpdateDeleteRow(promNo) {
        if (!confirm('이 연혁(회차)을 삭제하시겠습니까?\n* 삭제 시 이후 회차의 조문 누적에 영향이 있을 수 있습니다.')) return;
        ideMultiDoDeleteRow(promNo, false);
      }

      function ideMultiDoDeleteRow(promNo, force) {
        $.ajax({ url: MULTI_DELROW_URL, method: 'POST', data: { promNo: promNo, force: force ? 'Y' : '' }, dataType: 'json' })
          .done(function(d) {
            if (d.success) {
              ideToast(d.message || '삭제되었습니다.');
              ideMultiUpdateRefreshTrees(d.lawId);
              ideOpenMultiUpdate(ideMultiUpdateLawId, null);   // 표 갱신
            } else if (d.reason === 'NOT_EMPTY') {
              if (confirm((d.message || '') + '\n\n그래도 삭제하시겠습니까? (본문/문서/관련자료가 함께 삭제됩니다)')) {
                ideMultiDoDeleteRow(promNo, true);
              }
            } else { alert(d.message || '삭제에 실패했습니다.'); }
          })
          .fail(function(xhr) { alert('삭제 요청 실패: ' + xhr.status); });
      }

      function ideMultiUpdateDeleteAll() {
        if (!ideMultiUpdateLawId) { alert('대상 규정이 없습니다.'); return; }
        if (!confirm('이 규정의 모든 연혁(전 회차)을 삭제합니다.\n이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?')) return;
        if (!confirm('정말로 규정 전체를 삭제하시겠습니까?\n본문·문서·관련자료·연혁이 모두 영구 삭제됩니다.')) return;
        $.ajax({ url: MULTI_DELALL_URL, method: 'POST', data: { lawId: ideMultiUpdateLawId }, dataType: 'json' })
          .done(function(d) {
            if (d.success) {
              ideToast(d.message || '삭제되었습니다.');
              ideCloseMultiUpdateModal();
              try { var $c = $('#ideTreeCate'); if ($c.jstree(true)) $c.jstree('refresh'); } catch (e) {}
              ctx.lawId = null; ctx.promNo = null;
              loadedHistoryLawId = null;
              document.getElementById('ideTreeHistory').innerHTML =
                '<p class="ide-tree-hint">규정분류 트리에서 규정을 선택하면 연혁이 표시됩니다.</p>';
              if (typeof showCenterPane === 'function') showCenterPane('placeholder');
            } else { alert(d.message || '삭제에 실패했습니다.'); }
          })
          .fail(function(xhr) { alert('삭제 요청 실패: ' + xhr.status); });
      }

      function ideMultiUpdateRefreshTrees(lawId) {
        try { var $c = $('#ideTreeCate'); if ($c.jstree(true)) $c.jstree('refresh'); } catch (e) {}
        var _lawId = lawId || ctx.lawId || ideMultiUpdateLawId;
        if (_lawId) {
          ctx.lawId = _lawId;
          loadedHistoryLawId = null;
          try { loadHistoryTree(_lawId); } catch (e) {}
        }
      }

      function ideCloseMultiUpdateModal() {
        document.getElementById('ideMultiUpdateModal').style.display = 'none';
      }
      // 모달의 인라인 onclick(보기/삭제/저장/닫기/전체삭제)은 전역 스코프에서 실행되므로
      // 이 클로저의 함수들을 window 에 노출한다 (없으면 ReferenceError).
      window.ideMultiUpdateSave       = ideMultiUpdateSave;
      window.ideMultiUpdateView       = ideMultiUpdateView;
      window.ideMultiUpdateDeleteRow  = ideMultiUpdateDeleteRow;
      window.ideMultiUpdateDeleteAll  = ideMultiUpdateDeleteAll;
      window.ideCloseMultiUpdateModal = ideCloseMultiUpdateModal;
      window.fnVrsnValidate = function() {
        if (!ctx.lawId && !ctx.promNo) { alert('규정을 먼저 선택하세요.'); return; }
        // 검증은 lawId 기준 — lawId 우선, 없으면 promNo(서버가 lawId 로 해석)
        var q = ctx.lawId ? ('lawId=' + ctx.lawId) : ('promNo=' + ctx.promNo);
        location.href = '<c:url value="/rlms/prom/validateHistory.do"/>?' + q;
      };
      window.fnDiff = function() {
        // 대비표(신구대조)는 좌=이전/우=현행 두 회차가 필요 — 단일 promNo 직접호출은 leftPromNo/rightPromNo
        // 누락으로 400 에러였다(#9). 좌/우 회차 선택 화면(comparisonList)으로 보내 사용자가 두 회차를 고르게 한다.
        var lawId = ctx.lawId;
        if (!lawId) { alert('규정(연혁) 노드를 먼저 선택하세요.'); return; }
        location.href = '<c:url value="/rlms/fulltext/comparisonList.do"/>?lawId=' + lawId;
      };
      window.fnPreview = function() {
        if (!ctx.promNo) { alert('규정을 먼저 선택하세요.'); return; }
        window.open('<c:url value="/rlms/prom/preview.do"/>?promNo=' + ctx.promNo, 'rlmsPreview', 'width=900,height=800');
      };
      window.fnApproveRequestList = function() {
        location.href = '<c:url value="/rlms/promwork/selectPromWorkList.do"/>?st=REQ';
      };

      // 제·개정 내역 관리 — 회차(promNo) 선택 시 그 회차 상세이력으로, 없으면 전역 제·개정내역 목록으로.
      // (selectPromWorkHistory.do 는 promNo 필수 → 전역 진입은 selectPromWorkActLogList.do 로)
      window.fnPromWorkHistory = function() {
        if (ctx && ctx.promNo) {
          location.href = '<c:url value="/rlms/promwork/selectPromWorkHistory.do"/>?promNo=' + ctx.promNo;
        } else {
          location.href = '<c:url value="/rlms/promwork/selectPromWorkActLogList.do"/>';
        }
      };

      // ── 자동링크 제외범위 (F3) — 레거시 "인용링크제외범위수정" ─────
      var EXCL_LIST   = '<c:url value="/rlms/prom/relExclLnkListJson.do"/>';
      var EXCL_INSERT = '<c:url value="/rlms/prom/relExclLnkInsertJson.do"/>';
      var EXCL_DELETE = '<c:url value="/rlms/prom/relExclLnkDeleteJson.do"/>';
      var CATE_TREE_URL = '<c:url value="/rlms/prom/cateOnlyTreeJson.do"/>';
      var FULL_TREE_URL = '<c:url value="/rlms/prom/treeJson.do"/>';

      /** 우측 박스에 제외범위 목록 로드 (회차 메타 화면 진입 시) */
      function loadExclLnkList(lawId) {
        if (!lawId) {
          document.getElementById('ideExclLnkBox').style.display = 'none';
          return;
        }
        document.getElementById('ideExclLnkBox').style.display = '';
        var $ul = $('#ideExclLnkList');
        $ul.html('<li class="empty">로딩 중...</li>');
        $.ajax({ url: EXCL_LIST, data: { lawId: lawId }, dataType: 'json' })
          .done(function(d) {
            if (!d.success || !d.list || d.list.length === 0) {
              $ul.html('<li class="empty">등록되어있는 항목이 없습니다.</li>');
              return;
            }
            var h = '';
            for (var i = 0; i < d.list.length; i++) {
              var it = d.list[i];
              var name = ideEsc(it.displayName || '(?)');
              var kindLabel = (it.flag === 'full_text_gubun') ? '그룹' :
                              (it.flag === 'full_text_category') ? '분류' : '규정';
              h += '<li class="ide-excl-item">'
                +    '<span class="ide-excl-kind">[' + kindLabel + ']</span> '
                +    '<span class="ide-excl-name">' + name + '</span>'
                +  '</li>';
            }
            $ul.html(h);
          })
          .fail(function() { $ul.html('<li class="empty fail">조회 실패</li>'); });
      }

      // ★ staging 패턴 — 모달 안에서 추가/제거는 메모리만, [저장] 클릭 시 일괄 DB 반영
      var ideExclOriginalList = [];   // 모달 진입 시 DB 의 원본 (relnkNo 포함)
      var ideExclStagingList  = [];   // UI 의 임시 목록 (relnkNo === null = 신규 추가)

      /** 박스의 [수정] 클릭 → 편집 모달 */
      window.fnEditExclLnk = function() {
        if (!ctx.lawId) { alert('회차를 먼저 선택하세요.'); return; }
        document.getElementById('ideExclLnkCtx').innerText =
          '"' + (document.getElementById('idePromTitle').value || '(제목없음)') + '" 의 자동링크 처리 시 제외할 대상을 선택합니다. 추가/제거 후 [저장] 을 눌러야 반영됩니다.';
        document.getElementById('ideExclLnkModal').style.display = 'flex';

        // 트리 lazy init
        var $tree = $('#ideExclLnkTree');
        if (!$tree.data('jstree-built')) {
          $tree.jstree({
            core: {
              data: { url: FULL_TREE_URL + '?id=#', dataType: 'json' },
              themes: { name: 'default', dots: true, icons: true },
              check_callback: true
            },
            types: {
              gubun:   { icon: 'jstree-folder' },
              cate:    { icon: 'jstree-folder' },
              prom:    { icon: 'jstree-file'   },
              law:     { icon: 'jstree-file'   },
              provgrp: { icon: 'jstree-folder' },
              docgrp:  { icon: 'jstree-folder' },
              grp:     { icon: 'jstree-folder' },
              prov:    { icon: 'jstree-file'   }
            },
            plugins: ['types']
          });
          // 더블클릭으로 staging 추가 — anchor 영역만 잡아서 토글(펼침/접힘)과 분리
          $tree.on('dblclick.jstree', '.jstree-anchor', function(e) {
            e.preventDefault();
            ideExclLnkAddSelected();
          });
          $tree.data('jstree-built', true);
        }
        // 모달 진입 시 DB 목록 → staging 으로 복사
        ideExclLoadStaging();
      };

      window.ideCloseExclLnkModal = function() {
        document.getElementById('ideExclLnkModal').style.display = 'none';
        // staging 폐기 — DB 변경 없음. 우측 박스는 그대로(DB 상태와 일치).
        ideExclOriginalList = [];
        ideExclStagingList  = [];
      };

      /** 모달 진입 시: DB 목록을 staging 으로 복사 */
      function ideExclLoadStaging() {
        if (!ctx.lawId) return;
        var $ul = $('#ideExclLnkSelectedList');
        $ul.html('<li class="empty">로딩 중...</li>');
        $.ajax({ url: EXCL_LIST, data: { lawId: ctx.lawId }, dataType: 'json' })
          .done(function(d) {
            var list = (d.success && d.list) ? d.list : [];
            // 깊은 복사 (clone) — staging 조작이 original 에 영향 주지 않도록
            ideExclOriginalList = list.map(function(it) { return $.extend({}, it); });
            ideExclStagingList  = list.map(function(it) { return $.extend({}, it); });
            ideExclRenderStaging();
          })
          .fail(function() { $ul.html('<li class="empty fail">조회 실패</li>'); });
      }

      /** 우측 모달 목록을 staging 기반으로 렌더 */
      function ideExclRenderStaging() {
        var $ul = $('#ideExclLnkSelectedList');
        if (!ideExclStagingList || ideExclStagingList.length === 0) {
          $ul.html('<li class="empty">선택 항목이 없습니다.</li>');
          return;
        }
        var h = '';
        for (var i = 0; i < ideExclStagingList.length; i++) {
          var it = ideExclStagingList[i];
          var kindLabel = (it.flag === 'full_text_gubun') ? '그룹' :
                          (it.flag === 'full_text_category') ? '분류' : '규정';
          var isNew = (it.relnkNo == null);
          var nameHtml = ideEsc(it.displayName || '(?)')
                       + (isNew ? ' <em class="ide-excl-new">(추가)</em>' : '');
          h += '<li class="ide-excl-modal-item">'
            +    '<span class="ide-excl-kind">[' + kindLabel + ']</span>'
            +    '<span class="ide-excl-name">' + nameHtml + '</span>'
            +    '<button type="button" class="krds-btn ide-btn-cancel ide-btn-mini" onclick="ideExclLnkStageRemove(' + i + ')">제외</button>'
            +  '</li>';
        }
        $ul.html(h);
      }

      /** 좌측 트리에서 선택한 노드를 staging 에 추가 (DB 호출 X) */
      window.ideExclLnkAddSelected = function() {
        var inst = $.jstree.reference('#ideExclLnkTree');
        if (!inst) return;
        var sel = inst.get_selected(true);
        if (!sel || sel.length === 0) { alert('좌측 트리에서 추가할 대상을 선택하세요.'); return; }
        var n = sel[0];
        var newItem = { relnkNo: null, sysId: SYS_ID, exclLawId: ctx.lawId };
        var displayName = '';
        if (n.type === 'gubun') {
          newItem.flag = 'full_text_gubun';
          newItem.gubunId = (n.id || '').split(':')[1];
          displayName = n.text;
        } else if (n.type === 'cate') {
          newItem.flag = 'full_text_category';
          newItem.cateNo = parseInt((n.id || '').split(':')[1], 10);
          try { displayName = inst.get_path(n, ' > '); } catch (e) { displayName = n.text; }
        } else if (n.type === 'prom') {
          var lawId = (n.original && n.original.data && n.original.data.lawId)
                    || (n.data && n.data.lawId);
          if (!lawId) { alert('이 노드의 lawId 를 찾을 수 없습니다.'); return; }
          newItem.flag = 'full_text_leaf';
          newItem.lawId = lawId;
          try { displayName = inst.get_path(n, ' > '); } catch (e) { displayName = n.text; }
        } else {
          alert('이 노드는 제외 대상이 될 수 없습니다. (그룹/분류/규정 만 가능)');
          return;
        }
        newItem.displayName = displayName || '(이름없음)';

        // 중복 검사 — 같은 (flag, key) 가 staging 에 이미 있으면 skip
        for (var i = 0; i < ideExclStagingList.length; i++) {
          var it = ideExclStagingList[i];
          if (it.flag !== newItem.flag) continue;
          if (it.flag === 'full_text_gubun'    && it.gubunId === newItem.gubunId) { alert('이미 추가된 항목입니다.'); return; }
          if (it.flag === 'full_text_category' && it.cateNo  === newItem.cateNo)  { alert('이미 추가된 항목입니다.'); return; }
          if (it.flag === 'full_text_leaf'     && it.lawId   === newItem.lawId)   { alert('이미 추가된 항목입니다.'); return; }
        }

        ideExclStagingList.push(newItem);
        ideExclRenderStaging();
      };

      /** staging 에서 항목 제거 (DB 호출 X) — 신규 추가 항목은 단순 splice, 기존 항목은 "삭제 예정" 으로 staging 에서 빼기만 */
      window.ideExclLnkStageRemove = function(idx) {
        ideExclStagingList.splice(idx, 1);
        ideExclRenderStaging();
      };

      /** [저장] — diff 계산 + DB 일괄 반영 */
      window.ideExclLnkSave = function() {
        // diff
        var toInsert = ideExclStagingList.filter(function(it) { return it.relnkNo == null; });
        var stagingNos = {};
        ideExclStagingList.forEach(function(it) { if (it.relnkNo != null) stagingNos[it.relnkNo] = true; });
        var toDelete = ideExclOriginalList
            .filter(function(it) { return it.relnkNo != null && !stagingNos[it.relnkNo]; })
            .map(function(it) { return it.relnkNo; });

        if (toInsert.length === 0 && toDelete.length === 0) {
          alert('변경 사항이 없습니다.');
          return;
        }
        if (!confirm('추가 ' + toInsert.length + '건 / 제외 ' + toDelete.length + '건 을 저장합니다. 계속?')) return;

        var promises = [];
        toInsert.forEach(function(it) {
          var data = { sysId: SYS_ID, exclLawId: ctx.lawId, flag: it.flag };
          if (it.gubunId != null) data.gubunId = it.gubunId;
          if (it.cateNo  != null) data.cateNo  = it.cateNo;
          if (it.lawId   != null) data.lawId   = it.lawId;
          promises.push($.ajax({ url: EXCL_INSERT, method: 'POST', data: data, dataType: 'json' }));
        });
        toDelete.forEach(function(no) {
          promises.push($.ajax({ url: EXCL_DELETE, method: 'POST', data: { relnkNo: no }, dataType: 'json' }));
        });

        $.when.apply($, promises).done(function() {
          // 각 응답의 success 검사 — HTTP 200 + body success:false 케이스 잡기
          var results = (promises.length === 1) ? [arguments] : Array.prototype.slice.call(arguments);
          var failMessages = [];
          results.forEach(function(r) {
            // r = [data, statusText, jqXHR] 또는 단일 응답일 때 [data, statusText, jqXHR]
            var data = (r && r[0]) ? r[0] : null;
            if (data && data.success === false) {
              failMessages.push(data.message || '응답 success=false');
            }
          });
          if (failMessages.length > 0) {
            alert('일부 항목 저장 실패:\n' + failMessages.join('\n'));
          } else {
            ideToast('저장되었습니다.');
          }
          ideCloseExclLnkModal();
          if (ctx.lawId) loadExclLnkList(ctx.lawId);
        }).fail(function(xhr) {
          alert('일부 항목 저장에 실패했습니다. 다시 시도해주세요. (HTTP ' + (xhr && xhr.status) + ')');
          if (ctx.lawId) loadExclLnkList(ctx.lawId);
        });
      };

      // ── 승인요청 (레거시 워크플로 통합) ─────
      // 작성자가 본문 작성 완료 후 클릭. promwork 가 신청 row 등록 + 관리자 승인 시 SEXISTING_YN='Y' 승격.
      window.fnRequestApprove = function() {
        if (!ctx.promNo) { alert('회차를 먼저 선택하세요.'); return; }
        if (!confirm('이 회차의 승인을 요청합니다.\n관리자가 승인하면 사용자 화면에 노출됩니다. 계속?')) return;
        // returnUrl — 제출 후 IDE 로 복귀(상태라벨 '승인요청 진행 중'으로 결과 확인, 2026-07-09)
        location.href = '<c:url value="/rlms/promwork/insertPromWorkView.do"/>?promNo=' + ctx.promNo
            + '&returnUrl=' + encodeURIComponent('/rlms/prom/editor.do?promNo=' + ctx.promNo);
      };

      // (수정권한요청/수정완료 흐름 폐지 — 2026-07-20. 현행 회차 편집은 작성권한 가드만으로 허용)

      // ── 분류이동 (F2 — 레거시 "분류이동" 모달) ─────
      var ideMoveCateSelected = { cateNo: null, cateNm: null };  // 좌측 트리에서 선택한 분류

      window.fnMoveCate = function() {
        if (!ctx.promNo) { alert('회차를 먼저 선택하세요.'); return; }
        // 현재 회차 메타에서 이동전 정보 채움 (loadPromForm 응답 기반)
        var fromTitle = document.getElementById('idePromTitle').value || '(제목없음)';
        var fromCateNm = document.getElementById('idePromCateNm').value || '';
        document.getElementById('ideMoveCateFromTitle').innerText = fromTitle;
        document.getElementById('ideMoveCateFromNm').innerText    = fromCateNm;
        document.getElementById('ideMoveCateToNm').innerText      = '(좌측 트리에서 분류 선택)';
        document.getElementById('ideMoveCateToNm').style.color    = '#888';
        ideMoveCateSelected = { cateNo: null, cateNm: null };

        // 모달 표시
        document.getElementById('ideMoveCateModal').style.display = 'flex';

        // 트리 lazy init — 매번 새로 그리지 않고 첫 진입 시 한 번만 빌드
        var $tree = $('#ideMoveCateTree');
        if (!$tree.data('jstree-built')) {
          $tree.jstree({
            core: {
              data: { url: '<c:url value="/rlms/prom/cateOnlyTreeJson.do"/>', dataType: 'json' },
              themes: { name: 'default', dots: true, icons: true }
            },
            types: { gubun: { icon: 'jstree-folder' }, cate: { icon: 'jstree-folder' } },
            plugins: ['types']
          });
          $tree.on('select_node.jstree', function(e, data) {
            var n = data.node;
            if (!n || n.type !== 'cate') {
              // 그룹(gubun) 노드 선택은 무시
              ideMoveCateSelected = { cateNo: null, cateNm: null };
              document.getElementById('ideMoveCateToNm').innerText = '(분류를 선택하세요. 그룹 노드는 이동 대상이 아닙니다)';
              document.getElementById('ideMoveCateToNm').style.color = '#888';
              return;
            }
            // 전체 경로 — 그룹부터 자식까지 (예: "업무매뉴얼 > 개발")
            var fullPath = '';
            try { fullPath = data.instance.get_path(n, ' > '); } catch (err) { fullPath = n.text; }
            if (!fullPath) fullPath = n.text;
            ideMoveCateSelected.cateNo = parseInt((n.id || '').split(':')[1], 10);
            ideMoveCateSelected.cateNm = fullPath;
            document.getElementById('ideMoveCateToNm').innerText = fullPath;
            document.getElementById('ideMoveCateToNm').style.color = '#1f3974';
          });
          $tree.data('jstree-built', true);
        }
      };

      window.ideCloseMoveCateModal = function() {
        document.getElementById('ideMoveCateModal').style.display = 'none';
      };

      window.ideMoveCateConfirm = function() {
        if (!ctx.promNo) { alert('회차를 먼저 선택하세요.'); return; }
        if (!ideMoveCateSelected.cateNo) { alert('좌측 트리에서 이동할 분류를 선택하세요.'); return; }
        if (!confirm('이 회차를 [' + ideMoveCateSelected.cateNm + '] 분류로 이동합니다. 계속?')) return;
        $.ajax({
          url: '<c:url value="/rlms/prom/moveCategoryJson.do"/>',
          method: 'POST',
          data: { promNo: ctx.promNo, cateNo: ideMoveCateSelected.cateNo },
          dataType: 'json'
        }).done(function(d) {
          if (d.success) {
            alert(d.message || '분류를 이동했습니다.');
            ideCloseMoveCateModal();
            // 양쪽 트리 새로고침 + 현재 회차 다시 로드
            try { $('#ideTreeCate').jstree(true).refresh(); } catch (e) {}
            if (ctx.lawId) {
              try { loadHistoryTree(ctx.lawId); } catch (e) {}
            }
            loadPromForm(ctx.promNo);   // 새 분류명 반영
          } else {
            alert(d.message || '이동에 실패했습니다.');
          }
        }).fail(function(xhr) {
          alert('이동 요청 실패: ' + xhr.status + '\n' + (xhr.responseText || ''));
        });
      };

      // ── 본문 일괄 편집 단축 — 트리에서 조문 찾을 필요 없이 한 번에 ─────
      window.fnOpenBulkEditor = function() {
        if (!ctx.promNo) { alert('회차를 먼저 선택하세요.'); return; }
        loadProvBulkBody(ctx.promNo, null);
      };

      // ── [조문 입력] 헤더 버튼 — 규정형식에 맞는 조문 편집 진입 (#4) ─────
      //   VERSION = 본문 일괄 편집기 / HTML = HTML형식조문 신규 조항 폼. (VIEWER 는 버튼 자체가 hide)
      window.fnGoEditProv = function() {
        if (!ctx.promNo) { alert('회차를 먼저 선택/저장하세요.'); return; }
        var flag = document.getElementById('idePromProvFlag').value;
        if (flag === 'LINK') {
          alert('링크형식 규정은 본문(조문) 없이 외부 원문(URL)으로 연결됩니다.\nURL은 연혁 기본정보에서 수정하세요.');
          return;
        }
        if (flag === 'HTML') {
          ideStartNewProvHtml();
        } else {
          fnOpenBulkEditor();
        }
      };

      // ── 연혁(회차) 삭제 — 조문이 붙어 있어도 2단계 확인 후 삭제 (2026-07-23) ─────
      //    삭제 순서: ① 이 연혁에서 개정된 조문/별표/관련자료 삭제(서버 cascade)
      //               ② 삭제된 조문은 이전 연혁들 중 최종 조문이 현행으로 승계(누적 모델 + 현행 재배치)
      //               ③ 연혁 데이터 삭제
      window.fnDeleteProm = function() {
        if (!ctx.promNo) { alert('회차를 먼저 선택하세요.'); return; }
        if (!confirm('이 연혁(회차)을 삭제합니다.\n' +
                     '연혁에 조문이 있으면 함께 삭제되고, 이전 연혁의 조문이 현행으로 승계됩니다.\n' +
                     '계속하시겠습니까?')) return;
        ideDoDeleteProm(ctx.promNo, false);
      };
      function ideDoDeleteProm(promNo, force) {
        $.ajax({ url: PROM_DELETE, method: 'POST',
                 data: { promNo: promNo, force: force ? 'Y' : '' }, dataType: 'json' })
          .done(function(d) {
            if (d.success) {
              alert(d.message || '삭제되었습니다.');
              // 좌측 트리 양쪽 새로고침 — 삭제된 회차 사라짐
              var $cate = $('#ideTreeCate');     if ($cate.jstree(true)) $cate.jstree('refresh');
              var $hist = $('#ideTreeHistory');  if ($hist.jstree(true)) $hist.jstree('refresh');
              // 같은 lawId 의 다른 회차도 없으면 history 트리는 빈 상태 — 중앙은 placeholder 로
              showCenterPane('placeholder');
              ctx = { cateNo: null, cateNm: null, promNo: null, lawId: null, fullItem: null, item: null, docu: false };
            } else if (d.reason === 'NOT_EMPTY') {
              // 2단계 확인 — 조문/별표/관련자료가 있는 연혁: 승계 안내 후 강제 삭제 재호출
              if (confirm((d.message || '') + '\n\n그래도 삭제하시겠습니까?')) {
                ideDoDeleteProm(promNo, true);
              }
            } else {
              alert(d.message || '삭제에 실패했습니다.');
            }
          })
          .fail(function(xhr) {
            alert('삭제 요청 실패 (' + xhr.status + ')\n' + (xhr.responseText || ''));
          });
      }

      // ── 관련자료 8 액션 ─────────────────────────────────
      // B1: FILE 액션 — 일반/분류 통합 단일 진입점 (분류는 모달 안에서 선택, 선택 안 하면 미선택)
      window.fnAttachWord     = function() { ideOpenFileModal('FILE'); };
      // B2: ORGN 액션 — FILE 모달 재사용, 분류 숨김 + saveOrgn.do
      window.fnAttachOrgn     = function() { ideOpenFileModal('ORGN'); };
      // B5: IMAGE 액션 — accept=image/* + 썸네일 + saveImg.do
      // B6: WORD  액션 — accept=문서확장자 + saveWord.do (.docx/.hwpx 자체변환 → 미리보기·전문검색)
      //  ↑ 2026-07-30 별도 메뉴 항목 폐지 — [파일 등록] 모달의 탭으로 통합(ideFileTab).
      //    본문 토큰 삽입 등 다른 코드가 특정 종류로 바로 열 수 있게 함수는 남긴다.
      window.fnAttachImage    = function() { ideOpenFileModal('IMAGE'); };
      window.fnAttachDoc      = function() { ideOpenFileModal('WORD'); };
      // B3: HTML 표 첨부 (구현 완료)
      window.fnAttachHtml     = function() { ideOpenHtmlModal(); };
      // B4~B7: 후속 단계 placeholder
      // B7: URL 연계 (구현 완료)
      window.fnAttachUrl      = function() { ideOpenLnkModal(); };
      // B4: 규정 연계 (구현 완료)
      window.fnAttachProm     = function() { ideOpenDmnLnkModal(); };
      // 단계 C: 일괄 다운로드 — FILE/IMAGE/WORD 의 첨부를 ZIP 으로 묶어 새창 다운로드
      window.fnDownloadAll    = function() {
        if (!ctx.promNo) { alert('회차 또는 조항을 먼저 선택하세요.'); return; }
        var q = '?promNo=' + encodeURIComponent(ctx.promNo);
        q += '&flag=' + encodeURIComponent(window.ideRelFlag());
        if (ctx.fullItem) q += '&fullItem=' + encodeURIComponent(ctx.fullItem);
        // 새 탭/창보다는 hidden iframe 다운로드가 사용자 흐름 끊지 않음 — 단 ZIP 응답이라 location 이동 OK
        window.location.href = REL_ZIP_URL + q;
      };

      // ── B1: 파일 업로드 모달 ────────────────────────────
      //  2026-07-30: 메뉴에 흩어져 있던 파일 업로드 3개(파일 등록 / 문서(Word·HWP) 등록 / 이미지 첨부)를
      //  [파일 등록] 하나로 합치고, 종류는 모달 안 탭으로 고른다. 셋 다 같은 드롭존·같은 모달을 쓰면서
      //  저장 엔드포인트(saveFile/saveWord/saveImg)와 허용 확장자만 달랐던 것 — 사용자에겐 중복으로 보였다.
      //  ORGN(원본)은 신규 입구가 이미 폐지된 레거시 모드라 탭에 넣지 않는다(직접 호출 시엔 그대로 동작).
      var IDE_FILE_TABS = [
        { mode: 'FILE',  label: '첨부파일' },
        { mode: 'WORD',  label: '문서(Word·HWP)' },
        { mode: 'IMAGE', label: '이미지' }
      ];
      /** 확장자로 알맞은 탭 추정 — 파일을 먼저 고른 경우 종류를 자동으로 맞춰준다. */
      function ideGuessFileMode(fileName) {
        var ext = String(fileName || '').toLowerCase().replace(/^.*\./, '');
        if (/^(jpg|jpeg|png|gif|bmp|webp|svg)$/.test(ext)) return 'IMAGE';
        if (/^(doc|docx|hwp|hwpx|xls|xlsx|ppt|pptx|rtf|odt)$/.test(ext)) return 'WORD';
        return 'FILE';
      }
      /** 탭 클릭 — 열려 있는 모달의 종류만 바꾼다(선택한 파일 목록은 초기화). */
      window.ideFileTab = function(mode) {
        if (($('#ideFileModal').data('mode') || 'FILE') === mode) return;
        ideApplyFileMode(mode);
      };
      /** 모달의 종류(mode) 적용 — 제목·탭 활성·accept·안내문·분류행·카테고리 로드. */
      function ideApplyFileMode(mode) {
        mode = mode || 'FILE';
        var isOrgn  = (mode === 'ORGN');
        var isImage = (mode === 'IMAGE');
        var isWord  = (mode === 'WORD');
        var isFile  = (mode === 'FILE');
        $('#ideFileModalTitle').text(isOrgn ? '원본 첨부하기' : '파일 등록');
        $('#ideFileTabs .ide-file-tab').each(function() {
          $(this).toggleClass('active', $(this).attr('data-mode') === mode);
        });
        $('#ideFileTabs').toggle(!isOrgn);   // 레거시 ORGN 직접 호출은 탭 숨김
        var ctxText = '회차 #' + ctx.promNo
                    + (ctx.fullItem ? (ctx.docu ? ' / 별표 ' : ' / 조항 ') + ctx.fullItem : '');
        $('#ideFileCtx').text(ctxText);
        $('#ideFileTitle').val('');
        $('#ideFileInput').val('');
        // 모드별 accept — 탐색기에서 적합 확장자만 보이도록
        var accept = isImage ? 'image/*'
                   : isWord  ? '.doc,.docx,.hwp,.hwpx,.pdf,.xls,.xlsx,.ppt,.pptx,.rtf,.odt'
                   :           null;
        $('#ideFileInput').attr('accept', accept);
        // 모드별 안내 — 탭마다 무엇이 달라지는지 한 줄로 (통합 후 종류 선택 근거 제공)
        var notice = isWord
              ? '※ .docx / .hwpx 는 업로드 시 본문을 자동 변환하여 미리보기·전문검색에 활용합니다. .doc/.hwp/.pdf 등은 원본만 보관(다운로드 전용)합니다.'
              : isImage
              ? '※ 본문에 삽입할 그림입니다. 업로드 후 관련자료 목록에서 본문 토큰으로 넣을 수 있습니다.'
              : isFile
              ? '※ 규정에 딸린 참고 문서입니다. 분류(본문/붙임/양식)를 지정하면 사용자 화면에서 묶여 표시됩니다. PDF 는 [PDF파일뷰어] 형식의 본문으로도 지정할 수 있습니다.'
              : '';
        if (notice) { $('#ideFileNotice').text(notice).show(); }
        else { $('#ideFileNotice').empty().hide(); }
        $('#ideFileSelList').empty();
        $('#ideFileTotal').hide();
        $('#ideFileProgress').text('');
        $('#ideFileUploadBtn').prop('disabled', false);
        $('#ideFileCate').empty().append('<option value="">(분류 없음 — 미선택)</option>');
        $('#ideFileModal').data('mode', mode);
        // 분류 row 는 FILE 모드만 노출
        $('#ideFileCateRow').toggle(isFile);
        // 카테고리 옵션 로드 (FILE 모드 + lawId 있을 때만)
        if (isFile && ctx.lawId) {
          $.ajax({ url: REL_CATE_LIST, data: { promNo: ctx.promNo, lawId: ctx.lawId }, dataType: 'json' })
            .done(function(d) {
              var list = (d && d.list) ? d.list : [];
              var $sel = $('#ideFileCate');
              for (var i = 0; i < list.length; i++) {
                var c = list[i];
                $sel.append('<option value="' + c.cateNo + '" data-name="' + ideEsc(c.title) + '" data-order="' + (c.seq||0) + '">'
                            + ideEsc(c.title) + ' (' + (c.itemCount||0) + ')</option>');
              }
            });
        }
      }
      window.ideOpenFileModal = function(mode) {
        if (!ctx.promNo) { alert('회차 또는 조항을 먼저 선택하세요.'); return; }
        ideApplyFileMode(mode || 'FILE');
        $('#ideFileModal').show();
      };
      window.ideCloseFileModal = function() { $('#ideFileModal').hide(); };

      // 파일 선택 시 목록 프리뷰 + 다중 선택이면 제목 입력 비활성(파일별 파일명 사용)
      // 이미지 모드에선 썸네일을 함께 표시 (FileReader)
      $(document).on('change', '#ideFileInput', function() {
        var files = this.files || [];
        var mode  = $('#ideFileModal').data('mode') || 'FILE';
        // 통합 모달(2026-07-30) — 고른 파일이 다른 종류면 탭을 자동으로 맞춰준다.
        //   종류를 먼저 고르지 않아도 되게 만드는 게 통합의 실익. ORGN(레거시)은 자동 전환 대상 아님.
        if (files.length && mode !== 'ORGN') {
          var guess = ideGuessFileMode(files[0].name);
          if (guess !== mode) {
            // ★ FileList 는 input 에 딸린 live 객체 — 참조만 잡아두면 ideApplyFileMode 의
            //   val('') 로 같이 비워진다. 반드시 배열로 복사한 뒤 DataTransfer 로 되돌린다.
            var picked = [].slice.call(files);
            ideApplyFileMode(guess);
            $('#ideFileModal').data('mode', guess);
            try {
              var dt = new DataTransfer();
              for (var p = 0; p < picked.length; p++) { dt.items.add(picked[p]); }
              this.files = dt.files;
            } catch (e) { /* DataTransfer 미지원 브라우저는 탭만 전환 — 목록은 아래 폴백으로 표시 */ }
            mode  = guess;
            files = (this.files && this.files.length) ? this.files : picked;
          }
        }
        var isImg = (mode === 'IMAGE');
        var $list = $('#ideFileSelList').empty();
        for (var i = 0; i < files.length; i++) {
          var f = files[i];
          var $li = $('<li/>');
          var $info = $('<div class="file-info"/>');
          if (isImg && /^image\//.test(f.type)) {
            var $img = $('<img class="ide-file-thumb" alt=""/>');
            $info.append($img);
            (function(imgEl) {
              var fr = new FileReader();
              fr.onload = function(e) { imgEl.attr('src', e.target.result); };
              fr.readAsDataURL(f);
            })($img);
          }
          $info.append('<span class="file-name">' + ideEsc(f.name)
                  + ' <span class="fs">' + ideFmtSize(f.size) + '</span></span>'
                  + '<div class="btn-wrap"><button type="button" class="upload-delete-btn" data-idx="' + i + '" title="삭제">삭제</button></div>');
          $li.append($info);
          $list.append($li);
        }
        var total = document.getElementById('ideFileTotal');
        if (total) { total.style.display = files.length ? '' : 'none'; total.querySelector('.current').textContent = files.length; }
        var multi = files.length > 1;
        $('#ideFileTitle').prop('disabled', multi)
          .attr('placeholder', multi ? '여러 파일 — 각 파일명이 제목으로 사용됩니다' : '');
      });

      // 선택 파일 삭제 (DataTransfer 로 input.files 재구성) + 드래그앤드롭 (KRDS .file-upload.active)
      $(document).on('click', '#ideFileSelList .upload-delete-btn', function() {
        var idx = parseInt($(this).attr('data-idx'), 10);
        var input = document.getElementById('ideFileInput');
        try {
          var dt = new DataTransfer();
          for (var i = 0; i < input.files.length; i++) if (i !== idx) dt.items.add(input.files[i]);
          input.files = dt.files;
        } catch (e) { input.value = ''; }     // 구형 브라우저 — 전체 초기화
        $(input).trigger('change');
      });
      (function() {
        var drop = document.getElementById('ideFileDrop');
        if (!drop) return;
        ['dragover','dragenter'].forEach(function(ev){ drop.addEventListener(ev, function(e){ e.preventDefault(); drop.classList.add('active'); }); });
        ['dragleave','dragend'].forEach(function(ev){ drop.addEventListener(ev, function(){ drop.classList.remove('active'); }); });
        drop.addEventListener('drop', function(e){
          e.preventDefault(); drop.classList.remove('active');
          if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length) {
            try { document.getElementById('ideFileInput').files = e.dataTransfer.files; } catch (err) {}
            $('#ideFileInput').trigger('change');
          }
        });
      })();

      function ideFmtSize(b) {
        if (b == null) return '';
        if (b < 1024) return b + ' B';
        if (b < 1048576) return (b / 1024).toFixed(1) + ' KB';
        return (b / 1048576).toFixed(1) + ' MB';
      }

      window.ideUploadFile = function() {
        var $file = $('#ideFileInput')[0];
        if (!$file || !$file.files || $file.files.length === 0) { alert('파일을 선택하세요.'); return; }
        var mode    = $('#ideFileModal').data('mode') || 'FILE';
        var isOrgn  = (mode === 'ORGN');
        var isImage = (mode === 'IMAGE');
        var isWord  = (mode === 'WORD');
        var isFile  = (mode === 'FILE');
        var files   = $file.files;
        var multi   = files.length > 1;
        var url     = isImage ? REL_SAVE_IMG
                    : isOrgn  ? REL_SAVE_ORGN
                    : isWord  ? REL_SAVE_WORD
                    :           REL_SAVE_FILE;
        var typedTitle = $('#ideFileTitle').val();
        var $opt    = $('#ideFileCate option:selected');
        var cateNo  = isFile ? $opt.val() : '';

        $('#ideFileUploadBtn').prop('disabled', true);
        var done = 0, failed = [];

        function uploadOne(idx) {
          if (idx >= files.length) {
            $('#ideFileUploadBtn').prop('disabled', false);
            if (failed.length) {
              alert(files.length + '건 중 ' + failed.length + '건 실패:\n' + failed.join('\n'));
            }
            if (done > 0) {
              ideCloseFileModal();
              loadRelatedList(ctx.promNo, ctx.fullItem);
            }
            return;
          }
          var f  = files[idx];
          $('#ideFileProgress').text('업로드 중… (' + (idx + 1) + '/' + files.length + ') ' + f.name);
          var fd = new FormData();
          fd.append('promNo', ctx.promNo);
          fd.append('flag',   window.ideRelFlag());
          if (ctx.fullItem) fd.append('fullItem', ctx.fullItem);
          if (cateNo) {
            fd.append('cateNo',    cateNo);
            fd.append('cateName',  $opt.data('name') || '');
            fd.append('cateOrder', $opt.data('order') || 0);
          }
          // 단건일 때만 입력 제목 사용, 다건은 파일별 파일명(서버 디폴트)
          if (!multi && typedTitle) fd.append('title', typedTitle);
          if (SYS_ID) fd.append('sysId', SYS_ID);   // 비면 미전송 → 서버 정본값
          fd.append('file',  f);

          $.ajax({ url: url, type: 'POST', data: fd,
                   dataType: 'json', processData: false, contentType: false })
            .done(function(d) {
              if (d && d.ok) { done++; } else { failed.push(f.name + ' — ' + (d && d.error ? d.error : '오류')); }
            })
            .fail(function() { failed.push(f.name + ' — 통신 오류'); })
            .always(function() { uploadOne(idx + 1); });
        }
        uploadOne(0);
      };

      // ── B3: HTML 표 첨부 모달 (CKEditor) ────────────────
      var ckHtml = null;
      function ckHtmlCfg() {
        return {
          height: 320, language: 'ko',
          removePlugins: 'elementspath',
          entities: false, entities_latin: false, basicEntities: true,
          filebrowserUploadUrl: IMG_UPLOAD, filebrowserUploadMethod: 'form'
        };
      }
      function destroyCkHtml() {
        if (ckHtml) { try { ckHtml.destroy(true); } catch (e) {} ckHtml = null; }
      }
      window.ideOpenHtmlModal = function() {
        if (!ctx.promNo) { alert('회차 또는 조항을 먼저 선택하세요.'); return; }
        $('#ideHtmlCtx').text('회차 #' + ctx.promNo + (ctx.fullItem ? ' / 조항 ' + ctx.fullItem : ''));
        $('#ideHtmlTitle').val('');
        $('#ideHtmlProgress').text('');
        $('#ideHtmlSaveBtn').prop('disabled', false);
        $('#ideHtmlModal').show();
        destroyCkHtml();
        try { ckHtml = CKEDITOR.replace('ideHtmlBody', ckHtmlCfg()); }
        catch (e) { ckHtml = null; }
        if (ckHtml) { ckHtml.on('instanceReady', function() { ckHtml.setData(''); }); }
        else { $('#ideHtmlBody').val(''); }
      };
      window.ideCloseHtmlModal = function() {
        destroyCkHtml();
        $('#ideHtmlModal').hide();
      };
      window.ideSaveHtml = function() {
        var title = $('#ideHtmlTitle').val();
        var html  = '';
        if (ckHtml) { try { html = ckHtml.getData() || ''; } catch (e) { html = ''; } }
        else { html = $('#ideHtmlBody').val() || ''; }
        if (!html.replace(/<[^>]+>/g, '').replace(/&nbsp;/g, '').trim()) {
          alert('내용을 입력하세요.'); return;
        }
        $('#ideHtmlSaveBtn').prop('disabled', true);
        $('#ideHtmlProgress').text('저장 중…');
        $.ajax({
          url: REL_SAVE_HTML, type: 'POST', dataType: 'json',
          data: {
            promNo:   ctx.promNo,
            flag:     window.ideRelFlag(),
            fullItem: ctx.fullItem || '',
            title:    title,
            html:     html
          }
        })
        .done(function(d) {
          if (d && d.ok) {
            ideCloseHtmlModal();
            loadRelatedList(ctx.promNo, ctx.fullItem);
          } else {
            $('#ideHtmlSaveBtn').prop('disabled', false);
            $('#ideHtmlProgress').text('');
            alert('저장 실패: ' + (d && d.error ? d.error : '알 수 없는 오류'));
          }
        })
        .fail(function() {
          $('#ideHtmlSaveBtn').prop('disabled', false);
          $('#ideHtmlProgress').text('');
          alert('저장 통신 오류');
        });
      };

      // ── B4: 규정 연계 모달 (DOMAIN_LINK) — 레거시 3-pane ─────
      // state.laws: { [promNo]: {promNo, title, lawId, lawNo, provs:[{fullItem,title}], provsLoaded:bool} }
      // stage  : [{ flag, promNo?, lawId, lawNo, fullItem, title, alwaysLatestYn, kindLabel }]
      var ideDmnState = { laws: {} };
      var ideDmnStage = [];

      function ideDmnStageKey(it) {
        return (it.flag || 'PROMULGATION') + ':' + (it.lawId || '?') + ':'
             + (it.lawNo || 0) + ':' + (it.fullItem || '0');
      }
      function ideDmnStageHas(it) {
        var k = ideDmnStageKey(it);
        for (var i = 0; i < ideDmnStage.length; i++) {
          if (ideDmnStageKey(ideDmnStage[i]) === k) return true;
        }
        return false;
      }

      window.ideOpenDmnLnkModal = function() {
        if (!ctx.promNo) { alert('회차 또는 조항을 먼저 선택하세요.'); return; }
        $('#ideDmnLnkCtx').text('회차 #' + ctx.promNo + (ctx.fullItem ? ' / 조항 ' + ctx.fullItem : ''));
        $('#ideDmnProgress').text('');
        $('#ideDmnSaveBtn').prop('disabled', false);
        ideDmnState = { laws: {} };
        ideDmnStage = [];
        ideDmnRenderPicker();
        ideDmnRenderStage();
        $('#ideDmnLnkModal').show();
        ideDmnBuildTree();
        // 기존 링크 불러와 staging 초깃값으로
        $.ajax({
          url: REL_DMN_LIST, dataType: 'json',
          data: { promNo: ctx.promNo, flag: (window.ideRelFlag()),
                  fullItem: ctx.fullItem || '0' }
        }).done(function(d) {
          if (d && d.ok && d.list) {
            for (var i = 0; i < d.list.length; i++) {
              var r = d.list[i];
              ideDmnStage.push({
                flag:           r.flag || 'PROMULGATION',
                lawId:          r.lawId,
                lawNo:          r.lawNo,
                fullItem:       r.fullItem || '0',
                title:          r.title || r.targetPromTitle || '',
                alwaysLatestYn: r.alwaysLatestYn || 'N',
                kindLabel:      ((r.flag === 'PROVISION') ? '조문' : '규정')
              });
            }
            ideDmnRenderStage();
          }
        });
      };

      window.ideCloseDmnLnkModal = function() {
        try { jQuery('#ideDmnTree').jstree('destroy'); } catch (e) {}
        $('#ideDmnTree').empty();
        $('#ideDmnLnkModal').hide();
      };

      function ideDmnBuildTree() {
        try { jQuery('#ideDmnTree').jstree('destroy'); } catch (e) {}
        $('#ideDmnTree').empty();
        jQuery('#ideDmnTree').jstree({
          core: {
            themes: { dots: false, icons: true },
            data: function(node, cb) {
              $.ajax({ url: TREE_URL, dataType: 'json',
                       data: { id: node.id } })
                .done(function(arr) { cb.call(this, arr || []); })
                .fail(function() { cb.call(this, []); });
            }
          },
          checkbox: { cascade: '', three_state: false, whole_node: false, tie_selection: false },
          plugins: ['checkbox']
        });
        jQuery('#ideDmnTree').off('check_node.jstree uncheck_node.jstree')
          .on('check_node.jstree',   function(e, d) { ideDmnOnTreeCheck(d.node, true); })
          .on('uncheck_node.jstree', function(e, d) { ideDmnOnTreeCheck(d.node, false); });
      }

      function ideDmnOnTreeCheck(node, checked) {
        var nid = String(node.id || '');
        if (nid.indexOf('prom:') !== 0) return;            // prom 노드만 처리
        var promNo = parseInt(nid.slice(5), 10);
        if (isNaN(promNo)) return;
        var label = (node.text || '').replace(/<[^>]+>/g, '').trim();
        if (checked) {
          if (!ideDmnState.laws[promNo]) {
            ideDmnState.laws[promNo] = {
              promNo: promNo, title: label,
              lawId: null, lawNo: null,
              provs: [], provsLoaded: false
            };
          }
          ideDmnRenderPicker();
          // 조문 리스트 + lawId/lawNo 비동기 로드
          $.ajax({ url: DMN_PROVS_URL, dataType: 'json', data: { promNo: promNo } })
            .done(function(d) {
              if (!ideDmnState.laws[promNo]) return;          // 이미 uncheck 됐으면 무시
              if (d && d.ok) {
                ideDmnState.laws[promNo].lawId  = d.lawId;
                ideDmnState.laws[promNo].lawNo  = d.lawNo;
                ideDmnState.laws[promNo].title  = d.title || label;
                ideDmnState.laws[promNo].provs  = d.items || [];
              }
              ideDmnState.laws[promNo].provsLoaded = true;
              ideDmnRenderPicker();
            });
        } else {
          delete ideDmnState.laws[promNo];
          ideDmnRenderPicker();
        }
      }

      function ideDmnRenderPicker() {
        // 규정 sub-table
        var laws = ideDmnState.laws;
        var keys = Object.keys(laws);
        var $laws = $('#ideDmnPickerLaws');
        if (!keys.length) {
          $laws.html('<p class="empty">왼쪽 트리에서 규정을 체크하세요.</p>');
          $('#ideDmnPickerProvs').html('<p class="empty">규정 체크 시 그 규정의 조문 목록이 표시됩니다.</p>');
          return;
        }
        var h = '<table class="ide-cate-tbl ide-dmn-pick-tbl"><thead><tr>'
              + '<th class="col-pick">선택</th>'
              + '<th>규정명</th>'
              + '</tr></thead><tbody>';
        for (var i = 0; i < keys.length; i++) {
          var L = laws[keys[i]];
          var inStage = (L.lawId && ideDmnStageHas({flag:'PROMULGATION', lawId:L.lawId, lawNo:L.lawNo, fullItem:'0'}));
          h += '<tr data-prom-no="' + L.promNo + '" data-kind="LAW">'
            +    '<td class="col-pick"><input type="checkbox" class="ide-dmn-pick-cb ide-native-input"'
            +        (inStage ? ' disabled title="이미 추가됨"' : '')   // 레거시: 기본 체크 해제 — 사용자 명시 체크해야 추가
            +    '/></td>'
            +    '<td>' + ideEsc(L.title || ('규정 #' + L.promNo)) + '</td>'
            +  '</tr>';
        }
        h += '</tbody></table>';
        $laws.html(h);

        // 조문 sub-table — 체크된 규정마다 섹션
        var $provs = $('#ideDmnPickerProvs');
        var any = false;
        var ph = '';
        for (var j = 0; j < keys.length; j++) {
          var L2 = laws[keys[j]];
          ph += '<div class="ide-dmn-prov-sec">'
             +    '<div class="ide-dmn-prov-sec-head">' + ideEsc(L2.title) + '</div>';
          if (!L2.provsLoaded) {
            ph += '<p class="empty">조문 로딩 중…</p>';
          } else if (!L2.provs || !L2.provs.length) {
            ph += '<p class="empty">조문 없음</p>';
          } else {
            any = true;
            ph += '<table class="ide-cate-tbl ide-dmn-pick-tbl"><thead><tr>'
               +    '<th class="col-pick">선택</th><th>조문제목</th>'
               +    '</tr></thead><tbody>';
            for (var k = 0; k < L2.provs.length; k++) {
              var pr = L2.provs[k];
              var inStageP = (L2.lawId && ideDmnStageHas({flag:'PROVISION', lawId:L2.lawId, lawNo:L2.lawNo, fullItem:pr.fullItem||'0'}));
              ph += '<tr data-prom-no="' + L2.promNo + '" data-kind="PROV"'
                 +     ' data-full-item="' + ideEsc(pr.fullItem || '0') + '"'
                 +     ' data-title="' + ideEsc(pr.title || '') + '">'
                 +    '<td class="col-pick"><input type="checkbox" class="ide-dmn-pick-cb ide-native-input"'
                 +        (inStageP ? ' disabled title="이미 추가됨"' : '')
                 +    '/></td>'
                 +    '<td>' + ideEsc(pr.title || '') + '</td>'
                 +  '</tr>';
            }
            ph += '</tbody></table>';
          }
          ph += '</div>';
        }
        $provs.html(ph);
      }

      window.ideDmnAddChecked = function() {
        var added = 0, skipped = 0;
        // 규정 행
        $('#ideDmnPickerLaws tr[data-kind="LAW"]').each(function() {
          var $cb = $(this).find('input.ide-dmn-pick-cb');
          if (!$cb.prop('checked') || $cb.prop('disabled')) return;
          var promNo = parseInt($(this).data('promNo'), 10);
          var L = ideDmnState.laws[promNo];
          if (!L || !L.lawId) { skipped++; return; }
          var it = {
            flag:           'PROMULGATION',
            promNo:         promNo,
            lawId:          L.lawId,
            lawNo:          L.lawNo,
            fullItem:       '0',
            title:          L.title || '',
            alwaysLatestYn: 'N',
            kindLabel:      '규정'
          };
          if (ideDmnStageHas(it)) { skipped++; return; }
          ideDmnStage.push(it); added++;
        });
        // 조문 행
        $('#ideDmnPickerProvs tr[data-kind="PROV"]').each(function() {
          var $cb = $(this).find('input.ide-dmn-pick-cb');
          if (!$cb.prop('checked') || $cb.prop('disabled')) return;
          var promNo = parseInt($(this).data('promNo'), 10);
          var fi = String($(this).data('fullItem') || '0');
          var ttl = String($(this).data('title') || '');
          var L = ideDmnState.laws[promNo];
          if (!L || !L.lawId) { skipped++; return; }
          var it = {
            flag:           'PROVISION',
            promNo:         promNo,
            lawId:          L.lawId,
            lawNo:          L.lawNo,
            fullItem:       fi,
            title:          (L.title ? (L.title + ' > ') : '') + ttl,
            alwaysLatestYn: 'N',
            kindLabel:      '조문'
          };
          if (ideDmnStageHas(it)) { skipped++; return; }
          ideDmnStage.push(it); added++;
        });
        if (added === 0) {
          alert('체크된 새 항목이 없습니다.' + (skipped ? ' (중복/미준비 ' + skipped + '건 제외)' : ''));
        }
        ideDmnRenderPicker();    // 추가된 항목은 disabled 처리되도록 재렌더
        ideDmnRenderStage();
      };

      function ideDmnRenderStage() {
        $('#ideDmnStageCnt').text(ideDmnStage.length);
        var $box = $('#ideDmnStageList');
        if (!ideDmnStage.length) {
          $box.html('<p class="empty">선택된 항목이 없습니다.</p>'); return;
        }
        var h = '<table class="ide-cate-tbl ide-dmn-stage-tbl">'
              + '<thead><tr>'
              + '<th class="col-seq">#</th>'
              + '<th class="col-kind">종류</th>'
              + '<th class="col-name">제목</th>'
              + '<th class="col-cur">현재연혁</th>'
              + '<th class="col-act"></th>'
              + '</tr></thead><tbody>';
        for (var i = 0; i < ideDmnStage.length; i++) {
          var it = ideDmnStage[i];
          var kind = it.kindLabel || ((it.flag === 'PROVISION') ? '조문' : '규정');
          var awsChecked = (it.alwaysLatestYn === 'Y') ? ' checked' : '';
          h += '<tr>'
            +    '<td class="col-seq">' + (i + 1) + '</td>'
            +    '<td><span class="ide-cate-badge">' + ideEsc(kind) + '</span></td>'
            +    '<td class="col-name"><input type="text" class="ide-cate-inp"'
            +        ' value="' + ideEsc(it.title || '') + '"'
            +        ' onchange="ideDmnUpdate(' + i + ', \'title\', this.value);"/></td>'
            +    '<td class="col-cur">'
            +      '<input type="checkbox" class="ide-native-input"' + awsChecked
            +      ' onchange="ideDmnUpdate(' + i + ', \'alwaysLatestYn\', this.checked ? \'Y\' : \'N\');"'
            +      ' title="체크 시 항상 현행 회차로 자동 점프"/>'
            +    '</td>'
            +    '<td class="col-act"><button type="button" class="ide-cate-del" onclick="ideDmnRemove(' + i + ');">삭제</button></td>'
            +  '</tr>';
        }
        h += '</tbody></table>';
        $box.html(h);
      }

      window.ideDmnUpdate = function(idx, key, value) {
        if (ideDmnStage[idx]) ideDmnStage[idx][key] = value;
      };
      window.ideDmnRemove = function(idx) {
        ideDmnStage.splice(idx, 1);
        ideDmnRenderStage();
        ideDmnRenderPicker();   // 삭제된 항목 다시 체크 가능하도록
      };

      window.ideSaveDmnLnk = function() {
        $('#ideDmnSaveBtn').prop('disabled', true);
        $('#ideDmnProgress').text('저장 중…');
        var payload = {
          promNo:   ctx.promNo,
          flag:     window.ideRelFlag(),
          fullItem: ctx.fullItem || '0',
          items:    ideDmnStage
        };
        $.ajax({
          url: REL_SAVE_DMN, type: 'POST',
          contentType: 'application/json; charset=utf-8',
          data: JSON.stringify(payload), dataType: 'json'
        })
        .done(function(d) {
          if (d && d.ok) {
            ideCloseDmnLnkModal();
            loadRelatedList(ctx.promNo, ctx.fullItem);
          } else {
            $('#ideDmnSaveBtn').prop('disabled', false);
            $('#ideDmnProgress').text('');
            alert('저장 실패: ' + (d && d.error ? d.error : '알 수 없는 오류'));
          }
        })
        .fail(function() {
          $('#ideDmnSaveBtn').prop('disabled', false);
          $('#ideDmnProgress').text('');
          alert('저장 통신 오류');
        });
      };

      // ── B7: 관련 URL 정보 연계 모달 ──────────────────────
      // staging: [{ cate, title, url }]
      var ideLnkStage = [];

      window.ideOpenLnkModal = function() {
        if (!ctx.promNo) { alert('회차 또는 조항을 먼저 선택하세요.'); return; }
        $('#ideLnkCtx').text('회차 #' + ctx.promNo + (ctx.fullItem ? ' / 조항 ' + ctx.fullItem : ''));
        $('#ideLnkProgress').text('');
        $('#ideLnkSaveBtn').prop('disabled', false);
        ideLnkStage = [];
        ideLnkRender();
        $('#ideLnkModal').show();
        // 기존 링크 불러와 staging 초깃값
        $.ajax({
          url: REL_LNK_LIST, dataType: 'json',
          data: { promNo: ctx.promNo, flag: (window.ideRelFlag()),
                  fullItem: ctx.fullItem || '0' }
        }).done(function(d) {
          if (d && d.ok && d.list) {
            for (var i = 0; i < d.list.length; i++) {
              var r = d.list[i];
              ideLnkStage.push({
                cate:  r.cate  || 'URL',
                title: r.title || '',
                url:   r.url   || ''
              });
            }
            ideLnkRender();
          }
        });
      };

      window.ideCloseLnkModal = function() { $('#ideLnkModal').hide(); };

      window.ideLnkAddRow = function() {
        ideLnkStage.push({ cate: 'URL', title: '', url: '' });
        ideLnkRender();
        // 새로 추가된 마지막 행의 URL 입력에 포커스
        setTimeout(function() {
          var inputs = document.querySelectorAll('#ideLnkStageList .ide-lnk-url-inp');
          if (inputs.length) inputs[inputs.length - 1].focus();
        }, 0);
      };

      window.ideLnkUpdate = function(idx, key, value) {
        if (ideLnkStage[idx]) ideLnkStage[idx][key] = value;
      };
      window.ideLnkRemove = function(idx) {
        ideLnkStage.splice(idx, 1);
        ideLnkRender();
      };

      function ideLnkRender() {
        $('#ideLnkStageCnt').text(ideLnkStage.length);
        var $box = $('#ideLnkStageList');
        if (!ideLnkStage.length) {
          $box.html('<p class="empty">행 추가 버튼을 눌러 URL 을 입력하세요.</p>'); return;
        }
        var h = '<table class="ide-cate-tbl ide-lnk-stage-tbl">'
              + '<thead><tr>'
              + '<th class="col-seq">#</th>'
              + '<th class="col-cate">분류</th>'
              + '<th class="col-title">제목</th>'
              + '<th>URL</th>'
              + '<th class="col-act"></th>'
              + '</tr></thead><tbody>';
        for (var i = 0; i < ideLnkStage.length; i++) {
          var it = ideLnkStage[i];
          h += '<tr>'
            +    '<td class="col-seq">' + (i + 1) + '</td>'
            +    '<td><input type="text" class="ide-cate-inp"'
            +        ' value="' + ideEsc(it.cate || '') + '" placeholder="URL"'
            +        ' onchange="ideLnkUpdate(' + i + ', \'cate\', this.value);"/></td>'
            +    '<td><input type="text" class="ide-cate-inp"'
            +        ' value="' + ideEsc(it.title || '') + '" placeholder="(비우면 URL 자체를 제목으로)"'
            +        ' onchange="ideLnkUpdate(' + i + ', \'title\', this.value);"/></td>'
            +    '<td><input type="url" class="ide-cate-inp ide-lnk-url-inp"'
            +        ' value="' + ideEsc(it.url || '') + '" placeholder="https://..."'
            +        ' onchange="ideLnkUpdate(' + i + ', \'url\', this.value);"/></td>'
            +    '<td class="col-act"><button type="button" class="ide-cate-del" onclick="ideLnkRemove(' + i + ');">삭제</button></td>'
            +  '</tr>';
        }
        h += '</tbody></table>';
        $box.html(h);
      }

      window.ideSaveLnk = function() {
        // URL 빈 행 자동 정리 (백엔드도 skip 하지만 UX 차원에서 가시화)
        var clean = [];
        for (var i = 0; i < ideLnkStage.length; i++) {
          var it = ideLnkStage[i];
          if (it && it.url && it.url.trim()) clean.push(it);
        }
        $('#ideLnkSaveBtn').prop('disabled', true);
        $('#ideLnkProgress').text('저장 중…');
        var payload = {
          promNo:   ctx.promNo,
          flag:     window.ideRelFlag(),
          fullItem: ctx.fullItem || '0',
          items:    clean
        };
        $.ajax({
          url: REL_SAVE_LNK, type: 'POST',
          contentType: 'application/json; charset=utf-8',
          data: JSON.stringify(payload), dataType: 'json'
        })
        .done(function(d) {
          if (d && d.ok) {
            ideCloseLnkModal();
            loadRelatedList(ctx.promNo, ctx.fullItem);
          } else {
            $('#ideLnkSaveBtn').prop('disabled', false);
            $('#ideLnkProgress').text('');
            alert('저장 실패: ' + (d && d.error ? d.error : '알 수 없는 오류'));
          }
        })
        .fail(function() {
          $('#ideLnkSaveBtn').prop('disabled', false);
          $('#ideLnkProgress').text('');
          alert('저장 통신 오류');
        });
      };

      // ── 카테고리 관리 모달 ──────────────────────────────
      window.ideOpenCateModal = function() {
        if (!ctx.promNo || !ctx.lawId) { alert('회차를 먼저 선택하세요.'); return; }
        $('#ideCateCtx').text('회차 #' + ctx.promNo + ' / 규정 #' + ctx.lawId);
        $('#ideCateNewTitle').val('');
        $('#ideCateNewSeq').val('');
        $('#ideCateNewOrgnDown').val('N');
        ideReloadCateList();
        $('#ideCateModal').show();
      };
      window.ideCloseCateModal = function() { $('#ideCateModal').hide(); };

      window.ideReloadCateList = function() {
        var $box = $('#ideCateList');
        $box.html('<p class="empty">불러오는 중...</p>');
        $.ajax({ url: REL_CATE_LIST, data: { promNo: ctx.promNo, lawId: ctx.lawId }, dataType: 'json' })
          .done(function(d) {
            var list = (d && d.list) ? d.list : [];
            if (!list.length) { $box.html('<p class="empty">등록된 카테고리가 없습니다.</p>'); return; }
            var h = '<table class="ide-cate-tbl">'
                  + '<thead><tr>'
                  + '<th class="col-seq">순서</th><th class="col-name">이름</th>'
                  + '<th class="col-cnt">자료수</th><th class="col-orgn">원본 다운로드</th>'
                  + '<th class="col-act"></th>'
                  + '</tr></thead><tbody>';
            for (var i = 0; i < list.length; i++) {
              var c = list[i];
              h += '<tr data-cate-no="' + c.cateNo + '">'
                +    '<td class="col-seq">' + (c.seq || '') + '</td>'
                +    '<td class="col-name"><input type="text" class="ide-cate-inp"'
                +        ' value="' + ideEsc(c.title || '') + '"'
                +        ' onchange="ideRenameCate(' + c.cateNo + ', this.value);"/></td>'
                +    '<td class="col-cnt"><span class="ide-cate-badge">' + (c.itemCount || 0) + '</span></td>'
                +    '<td class="col-orgn"><select class="ide-cate-inp"'
                +        ' onchange="ideToggleOrgnDown(' + c.cateNo + ', this.value);">'
                +      '<option value="N"' + (c.orgnDownYn !== 'Y' ? ' selected' : '') + '>허용 안 함</option>'
                +      '<option value="Y"' + (c.orgnDownYn === 'Y' ? ' selected' : '') + '>허용</option>'
                +    '</select></td>'
                +    '<td class="col-act"><button type="button" class="ide-cate-del"'
                +      ' onclick="ideDeleteCate(' + c.cateNo + ');" title="삭제">삭제</button></td>'
                + '</tr>';
            }
            h += '</tbody></table>';
            $box.html(h);
          })
          .fail(function() { $box.html('<p class="empty">조회 실패</p>'); });
      };

      window.ideAddCate = function() {
        var title = $.trim($('#ideCateNewTitle').val());
        if (!title) { alert('이름을 입력하세요.'); return; }
        var seq = parseInt($('#ideCateNewSeq').val(), 10);
        var orgn = $('#ideCateNewOrgnDown').val();
        $.ajax({ url: REL_CATE_INS, type: 'POST', data: {
          promNo: ctx.promNo, lawId: ctx.lawId, title: title,
          seq: isNaN(seq) ? '' : seq, orgnDownYn: orgn
        }, dataType: 'json' })
          .done(function(d) {
            if (d && d.ok) ideReloadCateList();
            else alert('추가 실패: ' + (d && d.error ? d.error : ''));
          })
          .fail(function() { alert('추가 통신 오류'); });
      };

      window.ideRenameCate = function(cateNo, title) {
        $.ajax({ url: REL_CATE_REN, type: 'POST', data: { cateNo: cateNo, title: title }, dataType: 'json' })
          .done(function() { /* silent */ });
      };

      window.ideToggleOrgnDown = function(cateNo, yn) {
        $.ajax({ url: REL_CATE_ORGN, type: 'POST', data: { cateNo: cateNo, orgnDownYn: yn }, dataType: 'json' });
      };

      window.ideDeleteCate = function(cateNo) {
        if (!confirm('이 카테고리를 삭제합니다.\n매달린 자료가 있으면 표시가 안 될 수 있습니다.\n계속?')) return;
        $.ajax({ url: REL_CATE_DEL, type: 'POST', data: { cateNo: cateNo }, dataType: 'json' })
          .done(function(d) {
            if (d && d.ok) ideReloadCateList();
            else alert('삭제 실패: ' + (d && d.error ? d.error : ''));
          });
      };

      // ── 딥링크: editor.do?promNo=N — 회차(prom) 노드 클릭과 동일 경로로 자동 진입 ──
      //    loadPromForm 응답의 lawId 가 연혁목차 탭 전환+트리 로드까지 수행하므로 호출만 재현.
      //    트리 빌드 완료 시 해당 노드는 이벤트 억제(select_node 2번째 인자)로 표시만 — loadPromForm 중복 호출 방지.
      //    ⚠ jstree 는 triggerHandler 로 이벤트를 쏘므로(버블링 없음) document 위임이 아닌 엘리먼트 직접 바인딩 필수.
      if (DEEPLINK_PROM_NO) {
        $('#ideTreeHistory').one('ready.jstree', function() {
          var inst = $.jstree.reference('#ideTreeHistory');
          if (!inst) return;
          var n = inst.get_node('prom:' + DEEPLINK_PROM_NO);
          if (n && n.id) {
            inst.select_node(n, true);
            var el = document.getElementById(n.id);
            if (el && el.scrollIntoView) el.scrollIntoView({ block: 'center' });
          }
        });
        ctx.promNo = DEEPLINK_PROM_NO;
        switchActionSet('prom');
        loadPromForm(DEEPLINK_PROM_NO);
        loadRelatedList(DEEPLINK_PROM_NO, null);
      }
    });
  </script>
</lay:layout>
