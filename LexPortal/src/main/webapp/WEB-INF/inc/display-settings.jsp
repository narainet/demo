<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
  글자 크기 설정 (KRDS 접근성) — mgr.jsp / front.jsp 데코레이터 공용 include (jsp:include 동적 포함).
  방식: 내부 래퍼(#rlmsZoomWrap) zoom (0.9 / 1 / 1.1 / 1.3 / 1.5 — KRDS --krds-zoom-* 와 동일 값).
        우리 커스텀 CSS 가 px 위주라 rem 루트 스케일은 안 통함 → zoom 이 px 까지 전부 확대(KRDS 도 동일 채택).
  ⛔ zoom 을 body/html 에 직접 걸면 안 됨 — body 는 문서 스크롤러라 Chrome 이 배율≠1 에서
     스크롤 상한을 잘못 계산해 페이지 하단이 도달 불가가 된다(2026-07-24 소송의뢰 폼에서 실증).
     래퍼에는 zoom 만 준다 — 표준화된 zoom(Chrome 128+)이 %/auto 폭을 자체 보정하므로
     width 보정을 덧대면 이중보정으로 화면이 옆으로 넘친다(같은 날 '작게'에서 실증).
     파싱 초기엔 래퍼가 아직 없어 body 에 임시 적용 → DOMContentLoaded 의 apply() 가 래퍼로 이관.
  저장: localStorage('rlmsFontScale') → 매 페이지 로드 시 재적용. 현재 배율은 window.rlmsZoom 으로 공개(GNB 보정용).
  트리거: 각 데코레이터 헤더의 data-ds-open 버튼이 모달 오픈.
  정적 include 라 taglib 불필요(순수 HTML/JS).
--%>
<script>
/* 로드 즉시 저장값 적용 (FOUC 최소화) — 임시로 body, 이관은 아래 apply() */
(function () {
  try {
    var z = { sm: 0.9, md: 1, lg: 1.1, xlg: 1.3, xxlg: 1.5 }[localStorage.getItem('rlmsFontScale') || 'md'] || 1;
    window.rlmsZoom = z;
    /* vh/vw 보정 변수 — zoom 안에서 vh/vw 는 배율만큼 과대/과소 렌더되므로
       CSS 는 calc(Nvh / var(--rlms-zoom, 1)) 로 나눠 실제 뷰포트 기준을 유지한다. */
    document.documentElement.style.setProperty('--rlms-zoom', z);
    document.body.style.zoom = z;
  } catch (e) {}
})();
</script>

<div id="rlmsDsOverlay" class="rlms-ds-overlay" hidden>
  <div class="rlms-ds-modal" role="dialog" aria-modal="true" aria-labelledby="rlmsDsTitle">
    <div class="rlms-ds-head">
      <h2 id="rlmsDsTitle" class="rlms-ds-title">글자 크기 설정</h2>
      <button type="button" class="rlms-ds-close" data-ds-close aria-label="닫기">&#215;</button>
    </div>
    <div class="rlms-ds-body">
      <p class="rlms-ds-sub">글자 크기</p>
      <ul class="rlms-ds-opts">
        <li><label><input type="radio" name="rlmsFontScale" value="sm"><span>작게</span></label></li>
        <li><label><input type="radio" name="rlmsFontScale" value="md"><span>보통</span></label></li>
        <li><label><input type="radio" name="rlmsFontScale" value="lg"><span>조금 크게</span></label></li>
        <li><label><input type="radio" name="rlmsFontScale" value="xlg"><span>크게</span></label></li>
        <li><label><input type="radio" name="rlmsFontScale" value="xxlg"><span>가장 크게</span></label></li>
      </ul>
    </div>
    <div class="rlms-ds-foot">
      <button type="button" class="rlms-ds-btn" data-ds-reset>초기화</button>
      <button type="button" class="rlms-ds-btn rlms-ds-btn-primary" data-ds-close>닫기</button>
    </div>
  </div>
</div>

<script>
(function () {
  var KEY = 'rlmsFontScale', SCALE = { sm: 0.9, md: 1, lg: 1.1, xlg: 1.3, xxlg: 1.5 };
  function apply(l) {
    var z = SCALE[l] || 1;
    try {
      window.rlmsZoom = z;
      document.documentElement.style.setProperty('--rlms-zoom', z);
      var b = document.body, w = document.getElementById('rlmsZoomWrap');
      if (!w && z !== 1) {
        w = document.createElement('div');
        w.id = 'rlmsZoomWrap';
        while (b.firstChild) { w.appendChild(b.firstChild); }
        b.appendChild(w);
      }
      b.style.zoom = '';
      if (w) {
        /* 폭은 건드리지 않는다 — 표준화된 zoom(Chrome 128+)은 %/auto 폭을 부모 기준으로
           자체 보정하므로 width:calc(100%/z) 를 주면 이중보정되어 화면이 z만큼 옆으로
           넘친다(2026-07-24 '작게'에서 우측 클리핑·레이아웃 붕괴 실증). zoom 만 준다. */
        w.style.width = '';
        w.style.zoom = (z === 1) ? '' : z;
      }
    } catch (e) {}
    if (window.rlmsRecalcGnbLeft) { try { window.rlmsRecalcGnbLeft(); } catch (e) {} }
  }
  function get() { try { return localStorage.getItem(KEY) || 'md'; } catch (e) { return 'md'; } }
  function save(l) { try { localStorage.setItem(KEY, l); } catch (e) {} }
  function sync(l) { var r = document.querySelector('input[name="' + KEY + '"][value="' + l + '"]'); if (r) r.checked = true; }
  function ready(fn) { if (document.readyState !== 'loading') fn(); else document.addEventListener('DOMContentLoaded', fn); }
  ready(function () {
    var ov = document.getElementById('rlmsDsOverlay');
    apply(get()); sync(get());
    document.addEventListener('click', function (e) {
      if (e.target.closest('[data-ds-open]')) { e.preventDefault(); ov.hidden = false; }
      else if (e.target.closest('[data-ds-close]') || e.target === ov) { ov.hidden = true; }
      else if (e.target.closest('[data-ds-reset]')) { apply('md'); save('md'); sync('md'); }
    });
    document.querySelectorAll('input[name="' + KEY + '"]').forEach(function (inp) {
      inp.addEventListener('change', function () { apply(inp.value); save(inp.value); });
    });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && ov && !ov.hidden) ov.hidden = true; });
  });
})();
</script>
