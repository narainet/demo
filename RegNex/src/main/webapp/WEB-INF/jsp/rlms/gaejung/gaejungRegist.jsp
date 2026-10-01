<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/gaejung/gaejungRegist.jsp
  개정구분등록/수정. 규정 편집 IDE 톤 + KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">개정구분 ${empty gaejungVO.gaejungNo ? '등록' : '수정'}</c:set>
<c:set var="pageHead">
  
  <style>
  .faq-ide-page { display: flex; flex-direction: column; gap: 14px; min-width: 0; }
  .faq-ide-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border: 1px solid #d1d3d8; border-radius: 6px; background: #fff; }
  .faq-ide-kicker { display: block; margin-bottom: 4px; color: #52617a; font-size: 13px; font-weight: 600; }
  .faq-ide-head h1 { margin: 0; color: #1f3974; font-size: 24px; line-height: 1.35; }
  .faq-ide-state { flex: 0 0 auto; padding: 5px 10px; border-radius: 4px; background: #e8edf9; color: #1f3974; font-size: 13px; font-weight: 700; }
  .faq-ide-shell { display: grid; grid-template-columns: minmax(0, 1fr) 280px; min-height: 520px; border: 1px solid #d1d3d8; border-radius: 6px; overflow: hidden; background: #fff; }
  .faq-ide-main { min-height: 520px; border-right: 1px solid #d1d3d8; }
  .faq-ide-main .ide-context-pane { padding: 24px; }
  .faq-ide-main .ide-prov-head { align-items: center; flex-wrap: wrap; }
  .faq-ide-main .ide-prov-head h2 { font-size: 21px; }
  .faq-ide-main .ide-form-row { margin-bottom: 18px; }
  .faq-ide-main .krds-input.small,
  .faq-ide-main .krds-input,
  .faq-ide-main .krds-select { width: 100%; max-width: 100%; box-sizing: border-box; }
  .faq-ide-main .ide-form-actions { margin-top: 22px; padding-top: 16px; border-top: 1px solid #e1e5ee; }
  .faq-ide-right { min-height: 520px; }
  .faq-side-block { padding: 14px 16px; border-bottom: 1px solid rgba(255,255,255,0.15); }
  .faq-side-label { display: block; margin-bottom: 7px; color: rgba(255,255,255,0.74); font-size: 12px; font-weight: 700; }
  .faq-side-text { margin: 0; color: rgba(255,255,255,0.82); font-size: 13px; line-height: 1.6; word-break: break-word; }
  .faq-side-value { margin: 0; color: #fff; font-size: 14px; line-height: 1.5; word-break: break-word; }
  .required-mark { color: #d4351c; font-weight: 700; }
  @media (max-width: 1024px) {
    .faq-ide-shell { grid-template-columns: 1fr; }
    .faq-ide-main { border-right: 0; border-bottom: 1px solid #d1d3d8; }
    .faq-ide-right { min-height: 0; }
  }
  @media (max-width: 768px) {
    .faq-ide-head { align-items: flex-start; flex-direction: column; }
    .faq-ide-state { align-self: flex-start; }
    .faq-ide-main .ide-context-pane { padding: 18px; }
    .faq-ide-main .ide-form-actions { justify-content: flex-start; flex-wrap: wrap; }
  }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <c:set var="isUpdate" value="${not empty gaejungVO.gaejungNo}" />
  <c:url var="formAction" value="${isUpdate ? '/rlms/gaejung/updateGaejung.do' : '/rlms/gaejung/insertGaejung.do'}"/>
  <c:url var="gaejungListUrl" value="/rlms/gaejung/selectGaejungList.do"/>

  <div class="faq-ide-page">
    <div class="faq-ide-head">
      <div>
        <span class="faq-ide-kicker">Regulation / Revision Type</span>
        <h1>개정구분 ${isUpdate ? '수정' : '등록'}</h1>
      </div>
      <span class="faq-ide-state">${isUpdate ? '수정 모드' : '신규 작성'}</span>
    </div>

    <form action="${formAction}" method="post" class="krds-form">
      <c:if test="${isUpdate}">
        <input type="hidden" name="gaejungNo" value="<c:out value='${gaejungVO.gaejungNo}'/>"/>
      </c:if>

      <div class="faq-ide-shell">
        <main class="rlms-ide-main faq-ide-main">
          <div class="ide-context-pane">
            <div class="ide-prov-head">
              <h2>개정구분정보 편집</h2>
              <span class="ide-prov-status ${isUpdate ? 'exist' : 'new'}">${isUpdate ? '저장됨' : '등록'}</span>
            </div>

            <div class="ide-form-row">
              <label for="gaejungNm">이름 <span class="required-mark">*</span></label>
              <input type="text" id="gaejungNm" name="gaejungNm" class="krds-input"
                     required maxlength="255" value="<c:out value='${gaejungVO.gaejungNm}'/>"/>
            </div>

            <div class="ide-form-row">
              <label for="seq">정렬순서</label>
              <input type="number" id="seq" name="seq" class="krds-input"
                     value="<c:out value='${gaejungVO.seq}'/>" placeholder="비우면 자동 채워짐"/>
            </div>

            <div class="ide-form-row">
              <label for="diffYn">신구대조 여부</label>
              <select id="diffYn" name="diffYn" class="krds-input">
                <option value="Y" <c:if test="${empty gaejungVO.diffYn or gaejungVO.diffYn eq 'Y'}">selected</c:if>>이전 개정본과 비교함 (신구대조 생성)</option>
                <option value="N" <c:if test="${gaejungVO.diffYn eq 'N'}">selected</c:if>>비교 없음 (제정 등)</option>
              </select>
            </div>

            <div class="ide-form-actions">
              <button type="button" class="krds-btn secondary medium"
                      onclick="location.href='${gaejungListUrl}'">취소</button>
              <button type="submit" class="krds-btn primary medium">저장</button>
            </div>
          </div>
        </main>

        <aside class="rlms-ide-right faq-ide-right">
          <h3 class="ide-related-tit">개정구분작업정보</h3>
          <div class="faq-side-block">
            <span class="faq-side-label">상태</span>
            <p class="faq-side-text">${isUpdate ? '등록된 개정 종류를 수정합니다.' : '신규 개정 종류를 등록합니다.'}</p>
          </div>
          <c:if test="${isUpdate}">
            <div class="faq-side-block">
              <span class="faq-side-label">개정구분번호</span>
              <p class="faq-side-value"><c:out value="${gaejungVO.gaejungNo}" /></p>
            </div>
          </c:if>
          <div class="faq-side-block">
            <span class="faq-side-label">신구대조</span>
            <p class="faq-side-text">개정본 간 비교가 필요한 종류는 [이전 개정본과 비교함]으로 설정합니다.</p>
          </div>
        </aside>
      </div>
    </form>
  </div>
</lay:layout>
