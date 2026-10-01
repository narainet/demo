<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/promDetail.jsp

  규정 상세 + 조항 본문 목록 + 개정 이력. KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">규정 상세</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <style>
    /* ===== 규정 상세(promDetail) 디자인 정리(2026-06-30): 버튼 크기/위계 통일 + 사이드 위젯 확대 =====
         모든 규칙은 .pd-wrap 스코프 — 데코레이터(상단 검색 등) 버튼엔 영향 없음. */
    .pd-wrap { --pd-navy:#1f3974; }
    .pd-wrap .page-header h1 { font-size:22px; margin:0 0 14px; }
    .pd-wrap .page-header h1 small { font-size:14px; }
    .pd-wrap h2 { font-size:16px; color:var(--pd-navy); margin:24px 0 10px; padding-bottom:7px; border-bottom:2px solid #e5e7ed; }

    .layout-detail { display:flex; gap:22px; align-items:flex-start; }
    .main-area     { flex:1; min-width:0; }
    .side-area     { width:300px; flex:0 0 300px; }

    .clob-view { padding:8px 0; line-height:1.7; }
    .prov-html-item { margin-bottom:14px; padding:14px 16px; background:#fff; border:1px solid #e0e2e8; border-radius:8px; }
    .prov-html-item h3 { margin:0 0 8px; color:var(--pd-navy); font-size:15px; display:flex; align-items:center; gap:8px; }

    /* ── 버튼: KRDS medium(48px) 과대 → 38px 통일 + 위계(주요=남색채움/보조=남색선/위험=빨강선) ── */
    .pd-wrap .krds-btn {
      height:38px !important; min-height:0 !important; padding:0 16px !important;
      font-size:14px !important; line-height:1 !important; border-radius:6px !important;
      display:inline-flex; align-items:center; justify-content:center; gap:4px; min-width:0 !important;
      background:#fff !important; color:var(--pd-navy) !important; border:1px solid var(--pd-navy) !important;
      font-weight:500; text-decoration:none; cursor:pointer;
    }
    .pd-wrap .krds-btn:hover { background:#eef2fb !important; }
    .pd-wrap .krds-btn.primary { background:var(--pd-navy) !important; color:#fff !important; }
    .pd-wrap .krds-btn.primary:hover { background:#163063 !important; }
    .pd-wrap .krds-btn.danger { color:#c0392b !important; border-color:#d98b84 !important; background:#fff !important; }
    .pd-wrap .krds-btn.danger:hover { background:#fdecea !important; }
    .pd-wrap .krds-btn.small { height:32px !important; font-size:13px !important; padding:0 12px !important; }

    .pd-wrap .btn-area { display:flex; gap:8px; flex-wrap:wrap; align-items:center; margin:12px 0; }
    .pd-wrap .btn-area.right { justify-content:flex-end; }
    .pd-wrap .btn-area.foot { margin-top:22px; padding-top:16px; border-top:1px solid #e5e7ed; }

    /* ── 사이드 위젯: 카드형 + 입력 풀폭(기존 70/110/150px·12px 옹색 해소) ── */
    .side-area .pd-card { background:#fff; border:1px solid #e3e5ea; border-radius:10px; padding:16px; margin-bottom:16px; }
    .side-area .pd-card > h3 { margin:0 0 12px; font-size:14px; color:var(--pd-navy); }
    .side-area ul { list-style:none; padding:0; margin:0; }
    .side-area li { padding:9px 0; border-bottom:1px solid #eef0f3; font-size:13px; line-height:1.55; }
    .side-area li:last-child { border-bottom:none; }
    .side-area .pd-more { display:inline-block; margin-top:12px; font-size:12.5px; color:var(--pd-navy); }

    .memo-form { display:flex; flex-direction:column; gap:8px; margin-bottom:14px; }
    .memo-form .memo-row { display:flex; gap:8px; }
    .memo-form select,
    .memo-form input[type=text] {
      height:38px; padding:0 11px; font-size:13px; box-sizing:border-box; width:100%;
      border:1px solid #c4c6cd; border-radius:6px; background:#fff; color:#333;
    }
    .memo-form .memo-gubun { flex:0 0 88px; }
    .memo-form .memo-item  { flex:1; }

    /* 목록 항목 인라인 액션(수정/삭제/★/저장/취소) — 일관 pill */
    .btn-fav {
      display:inline-flex; align-items:center; justify-content:center;
      height:26px; padding:0 10px; margin:0 2px 0 0; font-size:12px; line-height:1;
      border:1px solid #c4c6cd; background:#fff; color:#455; border-radius:6px; cursor:pointer; vertical-align:middle;
    }
    .btn-fav:hover { background:#f0f2f5; }
    .btn-fav.active { background:#ffd54a; border-color:#e6b800; color:#5a4500; }
    .memo-edit-input { height:32px; padding:0 9px; font-size:12.5px; box-sizing:border-box; border:1px solid #c4c6cd; border-radius:5px; }
    .memo-tag { display:inline-block; font-size:10.5px; padding:1px 7px; margin-right:5px; background:#e8edf9; color:var(--pd-navy); border-radius:9px; vertical-align:middle; }
  </style>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <c:set var="vo" value="${result != null ? result : prom}"/>

  <div class="pd-wrap">

  <div class="page-header">
    <h1><c:out value="${vo.title}"/> <small style="color:#666;font-weight:normal;"><c:out value="${vo.number}"/></small></h1>
  </div>

  <div class="layout-detail">
    <div class="main-area">

      <table class="krds-table tbl-detail">
        <colgroup>
          <col style="width:15%"/><col/><col style="width:15%"/><col/>
        </colgroup>
        <tbody>
          <tr>
            <th scope="row">분류</th><td><c:out value="${vo.cateFullNm}"/></td>
            <th scope="row">담당부서</th><td><c:out value="${vo.buseoNm}"/></td>
          </tr>
          <tr>
            <th scope="row">공포일</th><td><c:out value="${vo.promDate}"/></td>
            <th scope="row">시행일</th><td><c:out value="${vo.startDate}"/></td>
          </tr>
          <tr>
            <th scope="row">유효</th><td>${vo.existingYn eq 'Y' ? '유효(현행)' : '비유효'}</td>
            <th scope="row">표시</th><td>${vo.dispYn eq 'Y' ? '표시' : '숨김'}</td>
          </tr>
        </tbody>
      </table>

      <%-- 외부 원문 참조(법제처 등) — 뷰어/미리보기와 동일 카드(.lv-extref, rlms-compat.css). http(s) 만 허용. --%>
      <c:set var="pdExtUrlLc" value="${fn:toLowerCase(vo.url)}"/>
      <c:if test="${not empty vo.url and (fn:startsWith(pdExtUrlLc,'http://') or fn:startsWith(pdExtUrlLc,'https://'))}">
        <div class="lv-extref">
          <div class="lv-extref-tit">🔗 외부 원문 참조</div>
          <p class="lv-extref-desc">이 규정은 외부 사이트(예: 법제처)의 원문을 참조합니다. 아래에서 원문을 새 창으로 확인하세요.</p>
          <a class="lv-extref-btn" href="${vo.url}" target="_blank" rel="noopener">원문 보기 ↗</a>
        </div>
      </c:if>

      <c:if test="${not empty vo.preamble}">
        <h2>전문</h2>
        <section class="krds-card">
          <div class="clob-view">${vo.preamble}</div>
        </section>
      </c:if>

      <h2>조항 본문</h2>
      <div class="btn-area">
        <%-- #3: 규정편집은 IDE(규정 관리)로 일원화 — 상세화면의 '조항 추가'(옛 진입점) 제거. 조항 등록/수정은 IDE 에서. --%>
        <button type="button" class="krds-btn"
                onclick="location.href='<c:url value="/rlms/prom/compareProvHtml.do"/>?promNo=<c:out value="${vo.promNo}"/>'">
          이전 개정본과 비교
        </button>
      </div>

      <c:choose>
        <c:when test="${empty resultList}">
          <div class="krds-alert info">조항이 아직 없습니다.</div>
        </c:when>
        <c:otherwise>
          <c:forEach var="ph" items="${resultList}">
            <div class="prov-html-item" data-item="<c:out value='${ph.item}'/>">
              <h3>
                <c:out value="${ph.item}"/> <c:out value="${ph.title}"/>
                <button type="button" class="btn-fav"
                        data-item="<c:out value='${ph.item}'/>"
                        data-law-id="<c:out value='${vo.lawId}'/>"
                        data-sys-id="<c:out value='${vo.sysId}'/>"
                        title="즐겨찾기 추가">★</button>
              </h3>
              <div class="clob-view">${ph.contents}</div>
              <div class="btn-area right">
                <a href="<c:url value='/rlms/prom/editor.do'/>?promNo=<c:out value='${ph.promNo}'/>"
                   class="krds-btn small">수정</a>
                <a href="<c:url value='/rlms/prom/deleteProvHtml.do'/>?provHtmlNo=<c:out value='${ph.provHtmlNo}'/>&promNo=<c:out value='${ph.promNo}'/>"
                   class="krds-btn danger small"
                   onclick="return confirm('이 조항을 삭제하시겠습니까?');">삭제</a>
              </div>
            </div>
          </c:forEach>
        </c:otherwise>
      </c:choose>

      <c:if test="${not empty history}">
        <h2>개정 이력</h2>
        <table class="krds-table tbl-list">
          <thead>
            <tr>
              <th scope="col">회차</th>
              <th scope="col">제목</th>
              <th scope="col">공포일</th>
              <th scope="col">유효</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="h" items="${history}">
              <tr>
                <td><c:out value="${h.lawNo}"/></td>
                <td>
                  <a href="<c:url value='/rlms/prom/selectPromDetail.do'/>?promNo=<c:out value='${h.promNo}'/>">
                    <c:out value="${h.title}"/>
                  </a>
                </td>
                <td><c:out value="${h.promDate}"/></td>
                <td>${h.existingYn eq 'Y' ? '현행' : '이전'}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </c:if>

      <div class="btn-area foot">
        <a href="<c:url value='/rlms/prom/selectPromList.do'/>" class="krds-btn">목록으로</a>
        <%-- #3: 규정 등록/수정은 규정 IDE(규정 관리)로 일원화 — 옛 'updatePromView' 폼 진입점 제거. --%>
        <a href="<c:url value='/rlms/prom/editor.do'/>?promNo=<c:out value='${vo.promNo}'/>"
           class="krds-btn primary">규정 IDE에서 편집</a>
      </div>
    </div>

    <aside class="side-area">
      <section class="pd-card">
        <h3>★ 내 즐겨찾기 <small style="color:#888;font-weight:normal;">(이 규정)</small></h3>
        <ul id="favorListInLaw">
          <li>로딩 중...</li>
        </ul>
        <a class="pd-more" href="<c:url value='/rlms/favor/selectFavorList.do'/>">전체 즐겨찾기 보기 →</a>
      </section>

      <section class="pd-card">
        <h3>📝 내 메모 <small style="color:#888;font-weight:normal;">(이 규정)</small></h3>
        <div class="memo-form">
          <div class="memo-row">
            <select id="memoNewGubun" class="memo-gubun" title="메모 분류">
              <option value="USER">개인</option>
              <option value="BUSEO">부서</option>
            </select>
            <input type="text" id="memoNewItem" class="memo-item" placeholder="조항 (예: 제3조)"/>
          </div>
          <input type="text" id="memoNewContents" placeholder="메모 내용"/>
          <button type="button" id="btnAddMemo" class="krds-btn primary">메모 추가</button>
        </div>
        <ul id="memoListInLaw">
          <li>로딩 중...</li>
        </ul>
        <a class="pd-more" href="<c:url value='/rlms/memo/selectMemoList.do'/>">전체 메모 보기 →</a>
      </section>
    </aside>
  </div>

  </div><%-- /pd-wrap --%>

  <script>
    var LAW_ID = '<c:out value="${vo.lawId}"/>';
    var SYS_ID = '<c:out value="${vo.sysId}"/>';

    function refreshFavorWidget() {
      if (!LAW_ID || !SYS_ID) {
        $('#favorListInLaw').html('<li>(규정 정보 없음)</li>');
        return;
      }
      $.getJSON('<c:url value="/rlms/favor/selectByLawJson.do"/>?lawId=' + LAW_ID)
        .done(function(data) {
          var list = (data && data.resultList) ? data.resultList : [];
          var $ul = $('#favorListInLaw').empty();
          if (list.length === 0) {
            $ul.append('<li>(없음 — 본문 ★ 버튼으로 추가)</li>');
            return;
          }
          var favItems = {};
          list.forEach(function(f) {
            favItems[f.item] = true;
            var $li = $('<li/>');
            $li.append($('<strong/>').text(f.item));
            if (f.description) $li.append(' — ').append($('<span/>').text(f.description));
            $li.append(' ');
            var $del = $('<button type="button" class="btn-fav">삭제</button>');
            $del.on('click', function() {
              if (!confirm('이 즐겨찾기를 삭제하시겠습니까?')) return;
              $.post('<c:url value="/rlms/favor/deleteFavor.do"/>', { favorNo: f.favorNo })
                .done(function(res) {
                  if (res.ok) refreshFavorWidget();
                  else alert(res.error || '삭제 실패');
                });
            });
            $li.append($del);
            $ul.append($li);
          });
          $('.btn-fav[data-item]').each(function() {
            var item = $(this).data('item');
            if (favItems[item]) $(this).addClass('active').attr('title', '이미 즐겨찾기에 있음');
          });
        })
        .fail(function() {
          $('#favorListInLaw').html('<li>(로드 실패)</li>');
        });
    }

    $('.btn-fav[data-item]').on('click', function() {
      var $btn = $(this);
      if ($btn.hasClass('active')) {
        alert('이미 즐겨찾기에 추가되어 있습니다.');
        return;
      }
      var desc = prompt('이 조항에 대한 메모(선택):', '');
      $.post('<c:url value="/rlms/favor/addFavor.do"/>', {
        lawId: $btn.data('law-id'),
        item:  $btn.data('item'),
        sysId: $btn.data('sys-id'),
        description: desc || ''
      }).done(function(res) {
        if (res.ok) {
          $btn.addClass('active');
          refreshFavorWidget();
        } else {
          alert(res.error || '추가 실패');
        }
      });
    });

    refreshFavorWidget();

    function memoGubunLabel(g) {
      return g === 'USER' ? '개인' : (g === 'BUSEO' ? '부서' : (g === 'PROM' ? '규정' : (g || '')));
    }

    // 메모 1건 — 보기 모드 (분류칩 + 조항 + 내용 + 수정/삭제)
    function renderMemoView($li, m) {
      $li.empty();
      if (m.gubun) $li.append($('<span class="memo-tag"/>').text(memoGubunLabel(m.gubun)));
      $li.append($('<strong/>').text(m.item || '(전체)'));
      $li.append(': ').append($('<span/>').text(m.contents));
      $li.append(' ');
      var $edit = $('<button type="button" class="btn-fav">수정</button>');
      $edit.on('click', function() { renderMemoEdit($li, m); });
      var $del = $('<button type="button" class="btn-fav">삭제</button>');
      $del.on('click', function() {
        if (!confirm('이 메모를 삭제하시겠습니까?')) return;
        $.post('<c:url value="/rlms/memo/deleteMemo.do"/>', { memoNo: m.memoNo })
          .done(function(res) {
            if (res.ok) refreshMemoWidget();
            else alert(res.error || '삭제 실패');
          });
      });
      $li.append($edit).append(' ').append($del);
    }

    // 메모 1건 — 편집 모드 (분류 select + 조항 + 내용 + 저장/취소 → updateMemo.do)
    function renderMemoEdit($li, m) {
      $li.empty();
      var $g = $('<select class="memo-edit-input" style="flex:0 0 84px;"/>');
      $g.append('<option value="USER">개인</option><option value="BUSEO">부서</option>');
      if (m.gubun === 'PROM') $g.append('<option value="PROM">규정</option>');
      $g.val(m.gubun === 'BUSEO' ? 'BUSEO' : (m.gubun === 'PROM' ? 'PROM' : 'USER'));
      var $item = $('<input type="text" class="memo-edit-input" placeholder="조항" style="flex:1;min-width:0;"/>').val(m.item || '');
      var $cont = $('<input type="text" class="memo-edit-input" placeholder="메모 내용" style="width:100%;box-sizing:border-box;margin-top:6px;"/>').val(m.contents || '');
      var $save = $('<button type="button" class="btn-fav">저장</button>');
      $save.on('click', function() {
        var contents = $.trim($cont.val());
        if (!contents) { alert('메모 내용을 입력하세요.'); return; }
        $.post('<c:url value="/rlms/memo/updateMemo.do"/>', {
          memoNo: m.memoNo, gubun: $g.val(), item: $.trim($item.val()), contents: contents
        }).done(function(res) {
          if (res.ok) refreshMemoWidget();
          else alert(res.error || '수정 실패');
        });
      });
      var $cancel = $('<button type="button" class="btn-fav">취소</button>');
      $cancel.on('click', function() { renderMemoView($li, m); });
      var $row1 = $('<div style="display:flex;gap:6px;"/>').append($g).append($item);
      var $btns = $('<div style="margin-top:6px;"/>').append($save).append(' ').append($cancel);
      $li.append($row1).append($cont).append($btns);
    }

    function refreshMemoWidget() {
      if (!LAW_ID || !SYS_ID) {
        $('#memoListInLaw').html('<li>(규정 정보 없음)</li>');
        return;
      }
      $.getJSON('<c:url value="/rlms/memo/selectByLawJson.do"/>?lawId=' + LAW_ID)
        .done(function(data) {
          var list = (data && data.resultList) ? data.resultList : [];
          var $ul = $('#memoListInLaw').empty();
          if (list.length === 0) {
            $ul.append('<li>(없음)</li>');
            return;
          }
          list.forEach(function(m) {
            var $li = $('<li/>');
            renderMemoView($li, m);
            $ul.append($li);
          });
        })
        .fail(function() {
          $('#memoListInLaw').html('<li>(로드 실패)</li>');
        });
    }

    $('#btnAddMemo').on('click', function() {
      var item     = $('#memoNewItem').val().trim();
      var contents = $('#memoNewContents').val().trim();
      if (!contents) { alert('메모 내용을 입력하세요.'); return; }
      $.post('<c:url value="/rlms/memo/addMemo.do"/>', {
        lawId: LAW_ID,
        item:  item,
        sysId: SYS_ID,
        gubun: $('#memoNewGubun').val(),
        contents: contents
      }).done(function(res) {
        if (res.ok) {
          $('#memoNewItem').val('');
          $('#memoNewContents').val('');
          refreshMemoWidget();
        } else {
          alert(res.error || '추가 실패');
        }
      });
    });

    refreshMemoWidget();
  </script>
</lay:layout>
