<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/fulltext/historyList.jsp

  사용자 화면 — 연혁검색. KRDS.
  목록 = 현행 규정(SEXISTING_YN='Y') 1행/규정, 5컬럼(번호/분류명/규정명/담당부서/개정일자).
  "상세검색" 버튼 → 레이어팝업(모달) 고급검색 폼 → detailMode=Y 로 제출 → 같은 목록에 결과 렌더.
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">규정검색</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
  <script src="<c:url value='/resources/js/rlms-cate-search-tree.js' />?v=20260804-fresp"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
  <div class="page-header" style="position:relative;">
    <h1>규정검색</h1>
    <p class="page-desc">현행 및 시행예정 규정을 조회합니다. 규정명을 클릭하면 본문을 볼 수 있습니다.</p>
    <a id="rdsOpenBtn" href="javascript:void(0)" style="position:absolute;top:0;right:0;">🔎 상세검색</a>
  </div>

  <div class="rlms-search-layout">
    <aside class="rlms-search-tree-aside">
      <div class="rlms-search-tree-head">규정 분류</div>
      <div id="cateSearchTree" class="rlms-search-tree"></div>
    </aside>
    <div class="rlms-search-body">

  <form id="searchForm" name="searchForm" action="<c:url value='/rlms/fulltext/historyList.do'/>"
        method="get" class="krds-form search-form">
    <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
    <c:if test="${not empty searchVO.cateNo}"><input type="hidden" name="cateNo" value="${searchVO.cateNo}"/></c:if>
    <%-- 상세검색 결과 상태 — 페이징 시 고급조건 유지 --%>
    <c:if test="${searchVO.detailMode eq 'Y'}">
      <input type="hidden" name="detailMode" value="Y"/>
      <input type="hidden" name="stTitle" value="${searchVO.stTitle}"/>
      <input type="hidden" name="stProvision" value="${searchVO.stProvision}"/>
      <input type="hidden" name="stDocument" value="${searchVO.stDocument}"/>
      <input type="hidden" name="stPaji" value="${searchVO.stPaji}"/>
      <input type="hidden" name="stParty" value="${searchVO.stParty}"/>
      <input type="hidden" name="hangulPrefix" value="${empty searchVO.hangulPrefix ? -1 : searchVO.hangulPrefix}"/>
      <input type="hidden" name="englishPrefix" value="${empty searchVO.englishPrefix ? -1 : searchVO.englishPrefix}"/>
      <input type="hidden" name="dateType" value="${searchVO.dateType}"/>
      <c:if test="${not empty searchVO.buseoNo}"><input type="hidden" name="buseoNo" value="${searchVO.buseoNo}"/></c:if>
    </c:if>

    <div class="form-group inline">
      <label class="form-label">분류</label>
      <div class="form-conts" style="display:flex;flex-wrap:wrap;gap:10px 16px;align-items:center;">
        <c:forEach var="g" items="${gubunList}">
        <label style="font-weight:normal;display:inline-flex;align-items:center;gap:4px;"><input type="checkbox" name="gubunIds" value="${g.code}" <c:if test="${not empty searchVO.gubunIds and searchVO.gubunIds.contains(g.code)}">checked</c:if>/><c:out value="${g.label}"/></label>
        </c:forEach>
      </div>
    </div>

    <div class="form-group inline">
      <label class="form-label" for="searchCnd">검색조건</label>
      <div class="form-conts">
        <select id="searchCnd" name="searchCnd" class="krds-select">
          <option value="0" <c:if test="${searchVO.searchCnd eq '0'}">selected</c:if>>제목</option>
          <option value="1" <c:if test="${searchVO.searchCnd eq '1'}">selected</c:if>>본문</option>
          <option value="2" <c:if test="${searchVO.searchCnd eq '2'}">selected</c:if>>분류</option>
          <option value="3" <c:if test="${searchVO.searchCnd eq '3'}">selected</c:if>>부서</option>
        </select>
      </div>
      <label class="form-label" for="searchKeyword">키워드</label>
      <div class="form-conts">
        <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input"
               value="<c:out value='${searchVO.searchKeyword}'/>"/>
      </div>
      <label class="form-label" for="searchFromDt">공포일</label>
      <div class="form-conts">
        <input type="date" id="searchFromDt" name="searchFromDt" class="krds-input" value="<c:out value='${searchVO.searchFromDt}'/>"/>
        <span>~</span>
        <input type="date" id="searchToDt" name="searchToDt" class="krds-input" value="<c:out value='${searchVO.searchToDt}'/>"/>
      </div>
      <button type="submit" class="krds-btn primary medium">검색</button>
      <a href="<c:url value='/rlms/fulltext/historyList.do'/>" class="krds-btn medium">초기화</a>
    </div>
  </form>

  <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건<c:if test="${searchVO.detailMode eq 'Y'}"> <span style="color:#1f3974;font-size:13px;">(상세검색)</span></c:if></p>

  <table class="krds-table tbl-list">
    <thead>
      <tr>
        <th scope="col">번호</th>
        <th scope="col">분류명</th>
        <th scope="col">규정명</th>
        <th scope="col">담당부서</th>
        <th scope="col">개정일자</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${empty resultList}">
          <tr><td colspan="5" class="empty-row">데이터가 없습니다.</td></tr>
        </c:when>
        <c:otherwise>
          <c:forEach var="row" items="${resultList}" varStatus="status">
            <c:set var="rowNum" value="${paginationInfo.totalRecordCount - ((paginationInfo.currentPageNo - 1) * paginationInfo.recordCountPerPage) - status.index}"/>
            <tr>
              <td><c:out value="${rowNum}"/></td>
              <td>[<c:out value="${gubunLabelMap[row.gubunId]}"/>]<c:out value="${row.cateNm}"/></td>
              <td>
                <%-- 외부 원문 참조(법제처 등): SURL 있으면 제목을 외부 새 창 링크로 (목록→새창, 사용자 제스처라 팝업차단 무관) --%>
                <c:set var="hlExtUrlLc" value="${fn:toLowerCase(row.url)}"/>
                <c:choose>
                  <c:when test="${not empty row.url and (fn:startsWith(hlExtUrlLc,'http://') or fn:startsWith(hlExtUrlLc,'https://'))}">
                    <a href="${row.url}" target="_blank" rel="noopener" title="외부 원문 (새 창)"><c:out value="${row.title}"/> <span class="ext-ico" aria-hidden="true">↗</span></a>
                  </c:when>
                  <c:otherwise>
                    <a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${row.promNo}"><c:out value="${row.title}"/></a>
                  </c:otherwise>
                </c:choose>
                <c:if test="${row.upcoming}"><span class="krds-badge bg-light-information" title="시행일 ${row.startDate}">시행예정</span></c:if>
              </td>
              <td><c:out value="${row.buseoNm}"/></td>
              <td><c:out value="${row.promDate}"/></td>
            </tr>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <div class="krds-pagination">
    <ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/>
  </div>

    </div>
  </div>

  <%-- ───────────── 상세검색 레이어팝업(모달) ───────────── --%>
  <div id="rdsBackdrop"></div>
  <div id="rdsModal">
    <div class="rds-head"><h3>상세검색하기</h3><button type="button" class="rds-x" title="닫기">&times;</button></div>
    <div class="rds-scroll">
      <form id="detailSearchForm" name="detailSearchForm" action="<c:url value='/rlms/fulltext/historyList.do'/>" method="get">
        <input type="hidden" name="detailMode" value="Y"/>
        <input type="hidden" name="pageIndex" value="1"/>
        <input type="hidden" name="hangulPrefix" value="-1"/>
        <input type="hidden" name="englishPrefix" value="-1"/>
        <div class="rds-row"><div class="rds-label">규정종류</div><div class="rds-conts">
          <c:forEach var="g" items="${gubunList}">
            <label><input type="checkbox" name="gubunIds" value="${g.code}" <c:if test="${not empty searchVO.gubunIds and searchVO.gubunIds.contains(g.code)}">checked</c:if>/> <c:out value="${g.label}"/></label>
          </c:forEach>
        </div></div>
        <div class="rds-row"><div class="rds-label">검색단위</div><div class="rds-conts">
          <label><input type="checkbox" name="stTitle" value="TRUE" <c:if test="${searchVO.stTitle eq 'TRUE'}">checked</c:if>/> 제목</label>
          <label><input type="checkbox" name="stProvision" value="TRUE" <c:if test="${searchVO.stProvision eq 'TRUE'}">checked</c:if>/> 본문내용</label>
          <label><input type="checkbox" name="stDocument" value="TRUE" <c:if test="${searchVO.stDocument eq 'TRUE'}">checked</c:if>/> 별표·별지서식내용</label>
          <label><input type="checkbox" name="stPaji" value="TRUE" <c:if test="${searchVO.stPaji eq 'TRUE'}">checked</c:if>/> 폐지사규</label>
          <label><input type="checkbox" name="stParty" value="TRUE" <c:if test="${searchVO.stParty eq 'TRUE'}">checked</c:if>/> 계약당사자</label>
        </div></div>
        <div class="rds-row"><div class="rds-label">검색어</div><div class="rds-conts">
          <input type="text" name="searchKeyword" value="<c:out value='${searchVO.searchKeyword}'/>" placeholder="검색어 입력"/>
        </div></div>
        <div class="rds-row"><div class="rds-label">검색일자</div><div class="rds-conts">
          <label><input type="radio" name="dateType" value="" <c:if test="${empty searchVO.dateType}">checked</c:if>/> 전체</label>
          <label><input type="radio" name="dateType" value="PROM" <c:if test="${searchVO.dateType eq 'PROM'}">checked</c:if>/> 개정일자</label>
          <label><input type="radio" name="dateType" value="START" <c:if test="${searchVO.dateType eq 'START'}">checked</c:if>/> 시행일자</label>
          <input type="date" name="searchFromDt" value="<c:out value='${searchVO.searchFromDt}'/>"/>
          <span>~</span>
          <input type="date" name="searchToDt" value="<c:out value='${searchVO.searchToDt}'/>"/>
        </div></div>
        <div class="rds-row"><div class="rds-label">소관부서</div><div class="rds-conts">
          <select name="buseoNo">
            <option value="">전체</option>
            <c:forEach var="b" items="${buseoList}">
              <option value="${b.buseoNo}" <c:if test="${searchVO.buseoNo eq b.buseoNo}">selected</c:if>><c:out value="${b.buseoNm}"/></option>
            </c:forEach>
          </select>
        </div></div>
        <div class="rds-row"><div class="rds-label">규정분류</div><div class="rds-conts">
          <select name="cateNo">
            <option value="">전체</option>
            <c:forEach var="ct" items="${cateList}">
              <option value="${ct.cateNo}" <c:if test="${searchVO.cateNo eq ct.cateNo}">selected</c:if>><c:out value="${ct.cateNm}"/></option>
            </c:forEach>
          </select>
        </div></div>
        <div class="rds-row"><div class="rds-label">자음검색</div><div class="rds-conts"><div class="rds-prefix">
          <c:set var="jaum" value="ㄱ,ㄴ,ㄷ,ㄹ,ㅁ,ㅂ,ㅅ,ㅇ,ㅈ,ㅊ,ㅋ,ㅌ,ㅍ,ㅎ"/>
          <c:forTokens var="j" items="${jaum}" delims="," varStatus="st">
            <a href="javascript:void(0)" data-h="${st.index}"><c:out value="${j}"/></a>
          </c:forTokens>
        </div></div></div>
        <div class="rds-row"><div class="rds-label">영문검색</div><div class="rds-conts"><div class="rds-prefix">
          <c:forEach var="i" begin="0" end="25">
            <a href="javascript:void(0)" data-e="${i}"><c:out value="${fn:substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ', i, i+1)}"/></a>
          </c:forEach>
        </div></div></div>
        <div class="rds-foot">
          <button type="submit" class="krds-btn primary medium" onclick="this.form.hangulPrefix.value=-1;this.form.englishPrefix.value=-1;">검색</button>
          <a href="<c:url value='/rlms/fulltext/historyList.do'/>" class="krds-btn medium">초기화</a>
        </div>
      </form>
    </div>
  </div>

  <script>
    function fnLinkPage(pageNo) {
      document.searchForm.pageIndex.value = pageNo;
      document.searchForm.submit();
    }
    $(function() {
      RlmsCateSearchTree.init({
        containerId: 'cateSearchTree',
        jsonUrl:     '<c:url value="/rlms/cate/selectCateTreeJson.do"/>',
        searchUrl:   '<c:url value="/rlms/fulltext/historyList.do"/>'
      });
    });
  </script>
  <script src="<c:url value='/resources/js/rlms-detail-search.js'/>?v=20260618b"></script>
  <script> if (window.RlmsDetailSearch) { RlmsDetailSearch.init(); } </script>
</lay:layout>
