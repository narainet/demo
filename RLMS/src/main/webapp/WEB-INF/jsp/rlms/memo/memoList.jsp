<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/memo/memoList.jsp
  내 메모 페이지 (개인 격리). KRDS 디자인.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">메모관리</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header">
    <h1>메모관리</h1>
    <p class="page-desc">내가 작성한 규정 메모를 관리합니다.</p>
  </div>

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/memo/selectMemoList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <div class="form-group inline">
      <label class="form-label" for="searchGubun">분류</label>
      <div class="form-conts">
        <select id="searchGubun" name="searchGubun" class="krds-select">
          <%-- SGUBUN 실데이터: USER(사용자)/BUSEO(부서)/PROM(규정) — "분류" 컬럼과 동일 차원 --%>
          <option value=""      <c:if test="${empty searchVO.searchGubun}">selected</c:if>>전체</option>
          <option value="USER"  <c:if test="${searchVO.searchGubun eq 'USER'}">selected</c:if>>사용자</option>
          <option value="BUSEO" <c:if test="${searchVO.searchGubun eq 'BUSEO'}">selected</c:if>>부서</option>
          <option value="PROM"  <c:if test="${searchVO.searchGubun eq 'PROM'}">selected</c:if>>규정</option>
        </select>
      </div>
      <label class="form-label" for="searchKeyword">키워드</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건</p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">No</th>
        <th scope="col">분류</th>
        <th scope="col">규정 ID</th>
        <th scope="col">조항</th>
        <th scope="col">내용</th>
        <th scope="col">등록일</th>
        <th scope="col">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="7" class="empty-row">메모가 비어 있습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}">
            <tr data-memo-no="<c:out value='${row.memoNo}'/>"
                data-gubun="<c:out value='${row.gubun}'/>"
                data-item="<c:out value='${row.item}'/>"
                data-contents="<c:out value='${row.contents}'/>">
              <td><c:out value="${row.memoNo}"/></td>
              <td class="cell-gubun">
                <c:choose>
                  <c:when test="${row.gubun eq 'USER'}">사용자</c:when>
                  <c:when test="${row.gubun eq 'BUSEO'}">부서</c:when>
                  <c:when test="${row.gubun eq 'PROM'}">규정</c:when>
                  <c:otherwise>기타</c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${row.lawId}"/></td>
              <td class="cell-item"><c:out value="${row.item}"/></td>
              <td class="cell-contents"><c:out value="${row.contents}"/></td>
              <td><c:out value="${row.insDt}"/></td>
              <td class="cell-actions">
                <button type="button" class="krds-btn small btn-edit">수정</button>
                <button type="button" class="krds-btn danger small btn-del">삭제</button>
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

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }

    // 삭제
    $(document).on('click', '.btn-del', function() {
      var no = $(this).closest('tr').attr('data-memo-no');
      if (!confirm('삭제하시겠습니까?')) return;
      $.post('<c:url value="/rlms/memo/deleteMemo.do"/>', { memoNo: no })
       .done(function(res) {
         if (res.ok) location.reload();
         else alert(res.error || '삭제 실패');
       });
    });

    // 수정 — 행을 인라인 편집(분류 select + 조항 + 내용)으로 전환
    $(document).on('click', '.btn-edit', function() {
      var $tr = $(this).closest('tr');
      var gubun    = $tr.attr('data-gubun') || '';
      var item     = $tr.attr('data-item') || '';
      var contents = $tr.attr('data-contents') || '';
      var $g = $('<select class="krds-select edit-gubun"/>');
      $g.append('<option value="USER">사용자</option><option value="BUSEO">부서</option>');
      if (gubun === 'PROM') $g.append('<option value="PROM">규정</option>');
      $g.val(gubun === 'BUSEO' ? 'BUSEO' : (gubun === 'PROM' ? 'PROM' : 'USER'));
      $tr.find('.cell-gubun').empty().append($g);
      $tr.find('.cell-item').html('<input type="text" class="krds-input edit-item" style="width:90px;">');
      $tr.find('.cell-item .edit-item').val(item);
      $tr.find('.cell-contents').html('<input type="text" class="krds-input edit-contents" style="width:100%;">');
      $tr.find('.cell-contents .edit-contents').val(contents);
      $tr.find('.cell-actions').html(
        '<button type="button" class="krds-btn primary small btn-save">저장</button> ' +
        '<button type="button" class="krds-btn small btn-cancel">취소</button>');
    });

    // 저장 → updateMemo.do
    $(document).on('click', '.btn-save', function() {
      var $tr = $(this).closest('tr');
      var contents = $.trim($tr.find('.edit-contents').val());
      if (!contents) { alert('메모 내용을 입력하세요.'); return; }
      $.post('<c:url value="/rlms/memo/updateMemo.do"/>', {
        memoNo:   $tr.attr('data-memo-no'),
        gubun:    $tr.find('.edit-gubun').val(),
        item:     $.trim($tr.find('.edit-item').val()),
        contents: contents
      }).done(function(res) {
        if (res.ok) location.reload();
        else alert(res.error || '수정 실패');
      });
    });

    // 취소
    $(document).on('click', '.btn-cancel', function() { location.reload(); });
  </script>
</lay:layout>
