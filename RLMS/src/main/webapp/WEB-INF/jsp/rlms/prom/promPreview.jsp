<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/prom/promPreview.jsp

  관리자 — 규정 미리보기 (레거시 관리자 규정미리보기 구조 + 사용자 전문뷰어와 동일 본문 렌더러).
    좌: 규정분류 | 연혁목차 탭 트리
    중앙: 미리보기 본문 (ProvViewRenderer)
    ✎ → 추록정보수정(개정유형) 팝업
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle">규정 미리보기 - <c:out value="${prom.title}"/></c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<c:set var="sysId" value="${prom.sysId}"/>
<style>
  .pv-toolbar{display:flex;justify-content:space-between;align-items:center;gap:8px;background:#eef2f8;
    border:1px solid #c9d6e8;border-radius:6px;padding:7px 10px;margin:4px 0 10px;position:sticky;top:0;z-index:30;flex-wrap:wrap;}
  .pv-toolbar .pvt{display:flex;align-items:center;gap:6px;flex-wrap:wrap;}
  .pvt-btn{font-size:13px;padding:7px 11px;border:1px solid #c2cee0;background:#fff;color:#1d2433;border-radius:5px;cursor:pointer;text-decoration:none;}
  .pvt-btn:hover{background:#e3ecf9;}
  .pvt-btn.active{background:#1f3974;color:#fff;border-color:#1f3974;font-weight:600;}
  .pvt-find{font-size:13px;padding:6px 9px;border:1px solid #c2cee0;border-radius:5px;width:160px;}

  .pv-wrap{display:flex;gap:12px;align-items:flex-start;}
  .pv-left{flex:0 0 270px;max-width:270px;}
  .pv-tabs{display:flex;border-bottom:2px solid #1f3974;}
  .pv-tab{font-size:13px;padding:7px 12px;cursor:pointer;border:1px solid #c9d6e8;border-bottom:0;background:#e9eef6;color:#445;border-radius:5px 5px 0 0;margin-right:3px;}
  .pv-tab.on{background:#1f3974;color:#fff;border-color:#1f3974;font-weight:600;}
  .pv-treebox{border:1px solid #e1e7f0;border-top:0;border-radius:0 0 6px 6px;background:#fcfdff;max-height:calc(calc(100vh / var(--rlms-zoom, 1)) - 200px);overflow:auto;padding:6px 0;}
  .pv-pane{display:none;} .pv-pane.on{display:block;}
  ul.pv-tree,ul.pv-tree ul{list-style:none;margin:0;padding:0;} ul.pv-tree ul{padding-left:14px;}
  .pv-tree li{font-size:13px;line-height:1.7;white-space:nowrap;}
  .pv-tree .t-tog{display:inline-block;width:13px;color:#88a;cursor:pointer;text-align:center;}
  .pv-tree .t-gubun>span.t-label{font-weight:700;color:#1f3974;}
  .pv-tree .t-cate>span.t-label{font-weight:600;color:#334;}
  .pv-tree a.t-prom{color:#27384f;text-decoration:none;padding:1px 4px;border-radius:3px;}
  .pv-tree a.t-prom:hover{background:#eef4fe;} .pv-tree a.t-prom.on{background:#1f3974;color:#fff;font-weight:600;}
  .pv-toc a{display:block;padding:4px 10px;color:#27384f;text-decoration:none;font-size:13px;border-left:3px solid transparent;}
  .pv-toc a:hover{background:#eef4fe;} .pv-toc a.grp{font-weight:700;color:#1f3974;cursor:default;}
  .pv-toc .sec{font-weight:700;color:#7a4a06;padding:8px 10px 3px;font-size:12.5px;border-top:1px solid #eee;margin-top:6px;}

  .pv-main{flex:1 1 auto;min-width:0;border:1px solid #e1e7f0;border-radius:6px;background:#fff;padding:22px 30px 50px;}
  .pv-titleblock{text-align:center;border-bottom:2px solid #1f3974;padding-bottom:12px;margin-bottom:6px;}
  .pv-titleblock h1{font-size:24px;font-weight:800;color:#15233b;margin:2px 0 8px;letter-spacing:-.3px;}
  .pv-titleblock .meta{font-size:13px;color:#445;margin:2px 0;}
  .pv-legend{font-size:12px;color:#667;margin:8px 0 4px;text-align:right;}
  /* 연혁 목록 펼치기 — 사용자 전문뷰어(provisionList) 와 동일 룩 */
  .pv-history{border:1px solid #e1e7f0;background:#f8fbff;border-radius:6px;margin:12px 0 6px;}
  .pv-history .pvh-head{padding:8px 12px;cursor:pointer;font-weight:600;color:#1f3974;font-size:13.5px;user-select:none;}
  .pv-history .pvh-head .arr{display:inline-block;width:14px;}
  .pv-history .pvh-body{display:none;padding:2px 14px 12px;}
  .pv-history .pvh-body.open{display:block;}
  .pv-history .pvh-item{font-size:13px;padding:3px 0;border-top:1px dotted #dde6f1;}
  .pv-history .pvh-item:first-child{border-top:0;}
  .pv-history .pvh-item a{color:#1a5fb4;text-decoration:none;}
  .pv-history .pvh-item .pvh-cur{color:#0b3d91;font-weight:700;}
  .pv-history .pvh-tag{display:inline-block;font-size:11px;color:#9a5b00;background:#fff4e5;border-radius:8px;padding:0 6px;margin-left:5px;}
  /* 외부 원문 참조 카드 (법제처 등 SURL 규정) — 사용자 전문뷰어(provisionList)와 동일 룩 */
  .lv-extref{margin:14px 0 18px;padding:16px 18px;border:1px solid #cdd9ef;background:#f4f8ff;border-radius:10px;}
  .lv-extref .lv-extref-tit{font-weight:700;color:#1f3974;margin-bottom:6px;font-size:15px;}
  .lv-extref .lv-extref-desc{margin:0 0 12px;color:#555;font-size:13.5px;line-height:1.6;}
  .lv-extref .lv-extref-btn{display:inline-flex;align-items:center;gap:6px;height:40px;padding:0 18px;background:#1f3974;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;font-size:14px;}
  .lv-extref .lv-extref-btn:hover{background:#163063;}
  /* 별표/별지서식 섹션 */
  .pv-body .prov-docu-sec{margin:26px 0 8px;padding-top:16px;border-top:1px dashed #cdd7e6;}
  .pv-body .prov-docu{margin:12px 0;}

  /* 본문 (ProvViewRenderer 출력) */
  .pv-body .prov-doc{font-size:15.5px;line-height:1.95;color:#1a2233;}
  .pv-body .prov-group{margin:22px 0 8px;font-size:16.5px;}
  .pv-body .prov-jo{margin:14px 0;scroll-margin-top:60px;}
  .pv-body .prov-jo-label{color:#1f3974;}
  .pv-body .prov-sub{margin:4px 0;} .pv-body .prov-sub-label{color:#34507a;font-weight:600;margin-right:3px;}
  .pv-body .prov-postscript{margin:24px 0 8px;padding-top:14px;border-top:1px dashed #cdd7e6;}
  .pv-body button.prov-info{margin-left:6px;border:1px solid #c9b08a;background:#fff8ec;border-radius:4px;cursor:pointer;font-size:12px;color:#9a5b00;padding:0 5px;line-height:1.6;vertical-align:middle;}
  .pv-body button.prov-info:hover{background:#fdeece;}
  /* 개정마크 — 배경 없이 글자색으로만 구분(2026-07-31, 뷰어와 동일) */
  .pv-body .prov-rev{font-size:11.5px;font-weight:600;margin-left:5px;vertical-align:middle;white-space:nowrap;}
  .pv-body .prov-rev-NEW{color:#1a7f37;}
  .pv-body .prov-rev-MODIFY_ALL,.pv-body .prov-rev-MODIFY_TITLE,.pv-body .prov-rev-MODIFY_CONTENTS{color:#9a5b00;}
  .pv-body .prov-rev-MOVE_ALL,.pv-body .prov-rev-MOVE_TITLE_MODIFY_CONTENTS,.pv-body .prov-rev-MOVE_CONTENTS_MODIFY_TITLE{color:#2347a3;}
  /* 과거 회차 개정 이력 주석(누적 최종개정일) — 사용자 뷰어와 동일 톤 (2026-07-24) */
  .pv-body .prov-hist{font-size:0.82em;font-weight:400;color:#8a8f99;margin-left:5px;white-space:nowrap;}
  .pv-body a.rel-file{color:#0b6b3a;text-decoration:underline;} .pv-body a.rel-link{color:#1a5fb4;text-decoration:underline;}
  .pv-body img.rel-img{max-width:100%;height:auto;display:block;margin:8px 0;border:1px solid #d6deea;}
  .pv-body .rel-html{margin:8px 0;padding:8px;background:#f7f9fc;border:1px solid #e1e7f0;border-radius:4px;}
  .pv-body a.xref{color:#1a5fb4;text-decoration:none;border-bottom:1px dashed #9db8e0;cursor:pointer;}
  .pv-body mark.lvhit{background:#ffe58a;} .pv-body mark.lvhit.cur{background:#ff9f1c;color:#fff;}

  #pvModal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:60;}
  #pvModal .box{position:absolute;top:14%;left:50%;transform:translateX(-50%);width:min(520px,calc(93vw / var(--rlms-zoom, 1)));background:#fff;border-radius:8px;box-shadow:0 10px 40px rgba(0,0,0,.3);}
  #pvModal .hd{display:flex;justify-content:space-between;align-items:center;padding:11px 16px;border-bottom:1px solid #e7edf6;font-weight:700;color:#1f3974;background:#eef2f8;border-radius:8px 8px 0 0;}
  #pvModal .hd .x{cursor:pointer;border:0;background:none;font-size:20px;color:#889;}
  #pvModal .bd{padding:14px 16px;font-size:13.5px;}
  #pvModal .jo{font-weight:700;color:#1f3974;margin-bottom:10px;}
  #pvModal label{display:block;font-size:12.5px;color:#556;margin:8px 0 3px;}
  #pvModal select,#pvModal textarea{width:100%;border:1px solid #c2cee0;border-radius:5px;padding:7px;font-size:13.5px;}
  #pvModal textarea{height:120px;white-space:pre-wrap;}
  #pvModal .save{margin-top:12px;padding:8px 16px;border:0;background:#1f3974;color:#fff;border-radius:5px;cursor:pointer;}
  #pvMsg{font-size:12.5px;margin-top:8px;}
  /* ---- 규정형식(SPROV_FG) 분기 — 파일 인라인 보기 / 안내 배너 ---- */
  .pv-fileview{margin-top:10px;}
  .pv-fileview .pvf-bar{display:flex;gap:6px;align-items:center;margin-bottom:6px;}
  .pv-fileview .pvf-mode{font-weight:700;color:#234;margin-right:auto;font-size:13px;}
  .pv-fileview .pvf-btn{font-size:12.5px;color:#1f3974;border:1px solid #c2cee0;border-radius:5px;padding:4px 10px;text-decoration:none;background:#fff;}
  .pv-fileview .pvf-frame{width:100%;height:calc(75vh / var(--rlms-zoom, 1));border:1px solid #ccd;background:#f6f7f9;}
  .pv-notice{margin:10px 0;padding:12px 14px;border:1px solid #e3d9b8;background:#fdf8e7;border-radius:6px;color:#5a4a12;font-size:13px;}
  .pv-notice b{display:block;margin-bottom:4px;color:#3f3308;}
  .pvn-files{max-height:200px;overflow:auto;margin-top:8px;border-top:1px solid #eee3bf;}
  .pvn-file{padding:4px 0;border-bottom:1px dotted #e8dcb4;}
  .pvn-file a{color:#1a5fb4;text-decoration:none;}
  .pvn-cate{margin-left:6px;font-size:11px;color:#8a7a3a;border:1px solid #d9cf9f;border-radius:3px;padding:0 4px;vertical-align:1px;}
  .pv-body .prov-html-body{margin:6px 0 14px;}
  /* 인라인 스타일 정리 (2026-06-11) — 툴바/JS 주입 조각 공통 */
  .pvt-ttl{font-weight:700;color:#1f3974;font-size:15px;padding:0 4px;}
  .pvt-find-cnt{font-size:12px;color:#667;}
  .pv-tree li.muted{padding:8px 12px;color:#99a;}
  .pv-tree li.err{padding:8px 12px;color:#b00;}
  .pv-toc .pv-muted{padding:6px 10px;color:#99a;font-size:12px;}
  .pv-toc a.cur{font-weight:700;color:#1f3974;}
  .pv-ok{color:#1a7f37;}
  .pv-err{color:#b00;}
  @media print{.pv-toolbar,.pv-left,button.prov-info,.pv-fileview .pvf-bar{display:none!important;}.pv-main{border:0;padding:0;}.pv-wrap{display:block;}}
</style>

<div class="pv-toolbar">
  <div class="pvt">
    <span class="pvt-ttl">규정미리보기</span>
  </div>
  <div class="pvt">
    <input id="pvFind" class="pvt-find" type="text" placeholder="화면 내 검색 (Enter)" onkeydown="if(event.key==='Enter'){pvFindNext();event.preventDefault();}">
    <span id="pvFindCnt" class="pvt-find-cnt"></span>
    <button type="button" class="pvt-btn" onclick="window.print()">프린트</button>
  </div>
</div>

<div class="pv-wrap">
  <aside class="pv-left">
    <div class="pv-tabs">
      <div class="pv-tab on" data-tab="cls" onclick="pvTab('cls')">규정분류</div>
      <div class="pv-tab" data-tab="toc" onclick="pvTab('toc')">연혁목차</div>
    </div>
    <div class="pv-treebox">
      <div class="pv-pane on" id="pvPaneCls"><ul class="pv-tree" id="pvTree"><li class="muted">불러오는 중…</li></ul></div>
      <div class="pv-pane" id="pvPaneToc">
        <div class="pv-toc" id="pvToc"></div>
        <div class="sec">■ 회차</div>
        <div class="pv-toc" id="pvVers"><span class="pv-muted">불러오는 중…</span></div>
      </div>
    </div>
  </aside>

  <main class="pv-main">
    <%-- 타이틀 — 사용자 전문뷰어(provisionList) 와 동일 형식 --%>
    <div class="pv-titleblock">
      <h1><c:out value="${prom.title}"/></h1>
      <p class="meta">[시행 ${prom.startDate}] [공포 ${prom.promDate}]<c:if test="${not empty prom.gaejungNm}"> &middot; <c:out value="${prom.gaejungNm}"/></c:if></p>
    </div>

    <%-- 연혁 목록 펼치기 — 사용자 전문뷰어와 동일 (현재 회차 표시) --%>
    <div class="pv-history">
      <div class="pvh-head" onclick="pvHistToggle()"><span class="arr" id="pvhArr">&#9654;</span> 연혁 목록 펼치기 (${fn:length(history)}건)</div>
      <div class="pvh-body" id="pvhBody">
        <c:forEach var="h" items="${history}">
          <div class="pvh-item">
            <c:choose>
              <c:when test="${h.promNo == prom.promNo}">
                <span class="pvh-cur">${h.promDate} <c:out value="${empty h.gaejungNm ? '회차' : h.gaejungNm}"/></span><span class="pvh-tag">현재</span>
              </c:when>
              <c:otherwise>
                <a href="<c:url value='/rlms/prom/preview.do'/>?promNo=${h.promNo}">${h.promDate} <c:out value="${empty h.gaejungNm ? '회차' : h.gaejungNm}"/></a>
              </c:otherwise>
            </c:choose>
          </div>
        </c:forEach>
      </div>
    </div>

    <%-- 외부 원문 참조(법제처/로앤비 등) — 사용자 전문뷰어(provisionList.jsp)와 동일 카드.
         본문 없는 링크-only 규정도 미리보기에서 원문 확인 가능. http(s) 만 허용(스킴 안전). --%>
    <c:set var="pvExtUrlLc" value="${fn:toLowerCase(prom.url)}"/>
    <c:if test="${not empty prom.url and (fn:startsWith(pvExtUrlLc,'http://') or fn:startsWith(pvExtUrlLc,'https://'))}">
      <div class="lv-extref">
        <div class="lv-extref-tit">🔗 외부 원문 참조</div>
        <p class="lv-extref-desc">이 규정은 외부 사이트(예: 법제처)의 원문을 참조합니다. 아래에서 원문을 새 창으로 확인하세요.</p>
        <a class="lv-extref-btn" href="${prom.url}" target="_blank" rel="noopener">원문 보기 ↗</a>
      </div>
    </c:if>

    <%-- 규정형식(SPROV_FG) 분기 — 사용자 전문뷰어(provisionList.jsp)와 동일 동선 --%>
    <c:choose>
      <c:when test="${not empty bodyViewAttNo}">
        <div class="pv-fileview">
          <div class="pvf-bar">
            <span class="pvf-mode"><c:choose><c:when test="${bodyMode eq 'VIEWER'}">PDF 파일 본문</c:when><c:otherwise>원문 파일 본문</c:otherwise></c:choose></span>
            <a class="pvf-btn" href="<c:url value='/rlms/related/attachView.do'/>?attNo=${bodyViewAttNo}" target="_blank" rel="noopener">새 창</a>
            <a class="pvf-btn" href="<c:url value='/rlms/related/attachDownload.do'/>?attNo=${bodyViewAttNo}">다운로드</a>
          </div>
          <%-- #zoom=100 : Chrome 내장 PDF 뷰어 초기 확대율 100% 고정(기본 자동맞춤 대신). 125% 로 바꾸려면 zoom=125. --%>
          <iframe class="pvf-frame" src="<c:url value='/rlms/related/attachView.do'/>?attNo=${bodyViewAttNo}#zoom=100" title="규정 원문"></iframe>
        </div>
      </c:when>
      <c:otherwise>
        <%-- 배너는 렌더할 본문이 정말 없을 때만 — HTML 형식인데 TB_PROV_HTML 본문이 있으면 오안내 (리뷰 #7) --%>
        <c:if test="${bodyMode eq 'VIEWER' or (bodyMode eq 'HTML' and bodyHtmlEmpty)}">
          <div class="pv-notice">
            <b>이 규정의 본문은 원문 파일로 제공됩니다.</b>
            <c:choose>
              <c:when test="${not empty bodyFiles}">
                <div class="pvn-files">
                  <c:forEach var="f" items="${bodyFiles}">
                    <div class="pvn-file">
                      <c:choose>
                        <c:when test="${not empty f.attNo}"><a href="<c:url value='/rlms/related/attachDownload.do'/>?attNo=${f.attNo}"><c:out value="${not empty f.attName ? f.attName : f.title}"/></a></c:when>
                        <c:otherwise><c:out value="${f.title}"/></c:otherwise>
                      </c:choose>
                      <span class="pvn-cate"><c:choose><c:when test="${f.cate eq 'REL_FILE_3'}">PDF뷰어용</c:when><c:when test="${f.cate eq 'REL_FILE_2'}">개정문</c:when><c:otherwise>관련파일</c:otherwise></c:choose></span>
                    </div>
                  </c:forEach>
                </div>
              </c:when>
              <c:otherwise><span class="muted">등록된 원문 파일이 없습니다.</span></c:otherwise>
            </c:choose>
          </div>
        </c:if>
        <c:if test="${bodyMode eq 'VERSION' and bodySkeleton}">
          <div class="pv-notice">
            <b>조문 본문이 등록되어 있지 않은 규정입니다.</b>
            조문 제목 목차만 표시됩니다. 본문 채움은 편집기에서 "문서에서 가져오기" 또는 일괄편집으로 가능합니다.
          </div>
        </c:if>
        <%-- LINK(링크형식)는 본문 없음 — 외부 원문 카드가 본문을 대신 --%>
        <c:if test="${bodyMode ne 'VIEWER' and bodyMode ne 'LINK'}">
          <div class="pv-legend">✎ 클릭 → 추록정보(개정유형) 수정 &nbsp;|&nbsp;
            <span class="prov-rev prov-rev-NEW">&lt;신설&gt;</span>
            <span class="prov-rev prov-rev-MODIFY_CONTENTS">&lt;개정&gt;</span>
            <span class="prov-rev prov-rev-MOVE_ALL">&lt;조항이동&gt;</span>
            — 직전 회차 대비 변경 (삭제 조문 숨김)
          </div>
          <div class="pv-body" id="pvBody">${provHtml}${docuHtml}</div>
        </c:if>
      </c:otherwise>
    </c:choose>
  </main>
</div>

<div id="pvModal" onclick="if(event.target===this)pvClose()">
  <div class="box">
    <div class="hd"><span>추록정보 수정</span><button type="button" class="x" onclick="pvClose()">&times;</button></div>
    <div class="bd">
      <div class="jo" id="pvmJo"></div>
      <label>추록종류 (개정유형)</label>
      <select id="pvmType">
        <option value="">(미지정)</option>
        <option value="EQUAL">변경없음</option>
        <option value="MODIFY_ALL">전부개정</option>
        <option value="MODIFY_CONTENTS">본문개정(개정)</option>
        <option value="MODIFY_TITLE">제목개정</option>
        <option value="NEW">신설</option>
        <option value="MOVE_ALL">조항이동</option>
        <option value="MOVE_TITLE_MODIFY_CONTENTS">조항이동·본문개정</option>
        <option value="MOVE_CONTENTS_MODIFY_TITLE">조항이동·제목개정</option>
      </select>
      <label>내용 (읽기 전용)</label>
      <textarea id="pvmBody" readonly></textarea>
      <button type="button" class="save" onclick="pvSaveType()">저장하기</button>
      <div id="pvMsg"></div>
    </div>
  </div>
</div>

<script>
  var PV_CTX='<c:url value="/"/>'.replace(/\/$/,'');
  var PV_PROMNO='${prom.promNo}', PV_LAWID='${prom.lawId}';
  function pvEsc(s){return (s==null?'':String(s)).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];});}
  function pvHistToggle(){var b=document.getElementById('pvhBody'),a=document.getElementById('pvhArr');
    var open=b.classList.toggle('open');a.innerHTML=open?'&#9660;':'&#9654;';}
  function pvDecode(s){var d=document.createElement('textarea');d.innerHTML=String(s==null?'':s);return d.value;}

  /* 규정분류 트리 */
  function pvNodes(nodes){var h='';(nodes||[]).forEach(function(nd){var d=nd.data||{};
    if(d.promNo!=null){var on=(String(d.promNo)===String(PV_PROMNO))?' on':'';
      h+='<li class="t-prom"><span class="t-tog">&nbsp;</span><a class="t-prom'+on+'" href="'+PV_CTX+'/rlms/prom/preview.do?promNo='+d.promNo+'">'+pvEsc(nd.text)+'</a></li>';
    }else{var cls=(nd.type==='gubun')?'t-gubun':'t-cate';var kids=nd.children&&nd.children.length?('<ul>'+pvNodes(nd.children)+'</ul>'):'';
      h+='<li class="'+cls+'"><span class="t-tog" onclick="pvTog(this)">&#9656;</span><span class="t-label">'+pvEsc(nd.text)+'</span><div class="t-ch">'+kids+'</div></li>';}});return h;}
  function pvTog(sp){var ch=sp.parentNode.querySelector('.t-ch');if(!ch)return;var o=ch.style.display!=='none';ch.style.display=o?'none':'block';sp.innerHTML=o?'&#9658;':'&#9656;';}
  /* 편집계 화면이므로 editorTreeJson — 승인 전 draft 연혁도 트리에 표시(마커 없음). front 드로어는 treeJson(현행만). */
  function pvLoadTree(){fetch(PV_CTX+'/rlms/prom/editorTreeJson.do',{headers:{'X-Requested-With':'XMLHttpRequest'}}).then(function(r){return r.json();}).then(function(j){
    document.getElementById('pvTree').innerHTML=pvNodes(j)||'<li class="muted">목록 없음</li>';
    var cur=document.querySelector('#pvTree a.t-prom.on');if(cur)cur.scrollIntoView({block:'center'});
  }).catch(function(e){document.getElementById('pvTree').innerHTML='<li class="err">오류</li>';});}
  function pvTab(t){document.querySelectorAll('.pv-tab').forEach(function(x){x.classList.toggle('on',x.getAttribute('data-tab')===t);});
    document.getElementById('pvPaneCls').classList.toggle('on',t==='cls');
    document.getElementById('pvPaneToc').classList.toggle('on',t==='toc');
    if(t==='toc')pvBuildToc();}

  /* 연혁목차 = 본문 조 목차(DOM) + 회차 목록 */
  var pvTocBuilt=false;
  function pvBuildToc(){ if(pvTocBuilt)return; pvTocBuilt=true;
    var h='';document.querySelectorAll('#pvBody .prov-group, #pvBody .prov-jo').forEach(function(el){
      var lbl=el.querySelector('.prov-jo-label, b'); var txt=lbl?lbl.textContent.trim():''; if(!txt)return;
      if(el.classList.contains('prov-group')) h+='<a class="grp">'+pvEsc(txt)+'</a>';
      else h+='<a href="#'+el.id+'" onclick="pvJump(\''+el.id+'\');return false;">'+pvEsc(txt)+'</a>';
    });
    document.getElementById('pvToc').innerHTML=h||'<span class="pv-muted">조문 없음</span>';
    fetch(PV_CTX+'/rlms/prom/historyJson.do?lawId='+PV_LAWID,{headers:{'X-Requested-With':'XMLHttpRequest'}}).then(function(r){return r.json();}).then(function(j){
      var vers=(j&&j[0]&&j[0].children)?j[0].children:[];var vh='';
      vers.forEach(function(v){var d=v.data||{};var cur=(String(d.promNo)===String(PV_PROMNO));
        vh+='<a href="'+PV_CTX+'/rlms/prom/preview.do?promNo='+d.promNo+'"'+(cur?' class="cur"':'')+'>'+(d.promDate||'')+' '+pvEsc(d.gaejungNm||('회차 '+d.promNo))+(cur?' ◀':'')+'</a>';});
      document.getElementById('pvVers').innerHTML=vh||'<span class="pv-muted">없음</span>';
    }).catch(function(){});
  }
  function pvJump(id){var el=document.getElementById(id);if(el){el.scrollIntoView({behavior:'smooth',block:'start'});el.style.background='#fff7df';setTimeout(function(){el.style.background='';},900);}}

  /* 상호참조 자동 링크 — 외부 법령 인용(「…법」·"…법"·"같은 법"·모법 "법" 등 미등재 법령) 뒤의
     제N조는 이 문서 조문이 아니므로 자기앵커 연결 금지. 전문뷰어 lvInitBody 와 동일 판정(2026-07-23). */
  (function(){var body=document.getElementById('pvBody');if(!body)return;var w=document.createTreeWalker(body,NodeFilter.SHOW_TEXT,null),tg=[],n;
    function extLawBefore(txt,idx){
      var pre=txt.slice(0,idx).replace(/\s+$/,'');
      /* "「…법」(이하 "법"이라 한다) 제N조" — 인용 뒤 괄호 주석은 건너뛰고 그 앞 문맥으로 판정 */
      var guard=0;
      while(pre.charAt(pre.length-1)===')'&&guard++<3){
        var d=0,k=pre.length-1,cut=-1;
        while(k>=0){var c=pre.charAt(k);if(c===')')d++;else if(c==='('){d--;if(d===0){cut=k;break;}}k--;}
        if(cut<0)break;
        pre=pre.slice(0,cut).replace(/\s+$/,'');
      }
      if(!pre)return false;
      var ch=pre.charAt(pre.length-1);
      if(ch==='」'||ch==='』'||ch==='”')return true;
      var mm=pre.match(/([가-힣A-Za-z0-9]*)(법률|시행령|시행규칙|시행세칙|조례|규칙|규정|지침|세칙|요령|정관|법|영|령)$/);
      if(!mm)return false;
      if(mm[1])return true;
      var pre2=pre.slice(0,pre.length-mm[2].length).replace(/\s+$/,'');
      var wd=(pre2.match(/[가-힣]+$/)||[''])[0];
      return !(wd==='이'||wd==='본');
    }
    function chainGlue(gap){return /^\s*(?:(?:또는|및|와|과|부터|내지)\s*|[,ㆍ·~]\s*)*$/.test(gap);}
    while(n=w.nextNode()){if(n.parentNode&&n.parentNode.closest&&n.parentNode.closest('a'))continue;if(/제\s*\d+\s*조(의\s*\d+)?/.test(n.nodeValue))tg.push(n);}
    tg.forEach(function(tn){var f=document.createDocumentFragment(),t=tn.nodeValue,re=/제\s*(\d+)\s*조(?:의\s*(\d+))?/g,last=0,m,extChain=false,prevEnd=-1;
      while(m=re.exec(t)){if(m.index>last)f.appendChild(document.createTextNode(t.slice(last,m.index)));var a='jo-'+m[1]+(m[2]?('-'+m[2]):'');
        var ext=extLawBefore(t,m.index)||(extChain&&prevEnd>=0&&chainGlue(t.slice(prevEnd,m.index)));
        if(!ext&&document.getElementById(a)){var el=document.createElement('a');el.className='xref';el.href='#'+a;el.textContent=m[0];el.onclick=(function(x){return function(e){e.preventDefault();pvJump(x);};})(a);f.appendChild(el);}else f.appendChild(document.createTextNode(m[0]));
        extChain=ext;prevEnd=re.lastIndex;last=re.lastIndex;}
      if(last<t.length)f.appendChild(document.createTextNode(t.slice(last)));tn.parentNode.replaceChild(f,tn);});})();

  /* 화면 내 검색 */
  var pvHits=[],pvCur=-1,pvLastQ='';
  function pvFindNext(){var q=document.getElementById('pvFind').value.trim();
    if(!document.getElementById('pvBody')){document.getElementById('pvFindCnt').textContent='없음';return;}   /* 파일 인라인 모드 — 본문 영역 없음 */
    if(q!==pvLastQ){document.querySelectorAll('#pvBody mark.lvhit').forEach(function(mk){var t=document.createTextNode(mk.textContent);mk.parentNode.replaceChild(t,mk);});document.getElementById('pvBody').normalize();pvHits=[];pvCur=-1;pvLastQ=q;
      if(q){var w=document.createTreeWalker(document.getElementById('pvBody'),NodeFilter.SHOW_TEXT,null),arr=[],n;while(n=w.nextNode()){if(n.nodeValue.indexOf(q)>=0)arr.push(n);}
        arr.forEach(function(tn){var t=tn.nodeValue,f=document.createDocumentFragment(),i,last=0;while((i=t.indexOf(q,last))>=0){if(i>last)f.appendChild(document.createTextNode(t.slice(last,i)));var mk=document.createElement('mark');mk.className='lvhit';mk.textContent=t.substr(i,q.length);f.appendChild(mk);pvHits.push(mk);last=i+q.length;}if(last<t.length)f.appendChild(document.createTextNode(t.slice(last)));tn.parentNode.replaceChild(f,tn);});}}
    if(!pvHits.length){document.getElementById('pvFindCnt').textContent='없음';return;}
    if(pvCur>=0&&pvHits[pvCur])pvHits[pvCur].classList.remove('cur');pvCur=(pvCur+1)%pvHits.length;var mk=pvHits[pvCur];mk.classList.add('cur');mk.scrollIntoView({behavior:'smooth',block:'center'});document.getElementById('pvFindCnt').textContent=(pvCur+1)+'/'+pvHits.length;}

  /* ✎ → 추록정보 수정 */
  function pvClose(){document.getElementById('pvModal').style.display='none';}
  document.addEventListener('click',function(e){var b=e.target.closest&&e.target.closest('button.prov-info');if(!b)return;pvOpenEdit(b.getAttribute('data-fi'),b.getAttribute('data-jo'));});
  function pvOpenEdit(fi,jo){
    document.getElementById('pvmJo').textContent=jo; document.getElementById('pvmJo').setAttribute('data-fi',fi);
    document.getElementById('pvmType').value=''; document.getElementById('pvmBody').value='불러오는 중…';
    document.getElementById('pvMsg').textContent=''; document.getElementById('pvModal').style.display='block';
    fetch(PV_CTX+'/rlms/prom/provVrsnFragmentJson.do?promNo='+PV_PROMNO+'&fullItem='+encodeURIComponent(fi),{headers:{'X-Requested-With':'XMLHttpRequest'}})
      .then(function(r){return r.json();}).then(function(j){
        if(j&&j.found){document.getElementById('pvmType').value=j.gaejungType||'';
          var body=pvDecode(j.contents||j.body||''); document.getElementById('pvmBody').value=body.replace(/<br\s*\/?>/gi,'\n').replace(/<[^>]+>/g,'');}
        else{document.getElementById('pvmBody').value='(조 정보를 불러오지 못했습니다)';}
      }).catch(function(e){console.error('provVrsnFragment', e);document.getElementById('pvmBody').value='조 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';});
  }
  function pvSaveType(){
    var fi=document.getElementById('pvmJo').getAttribute('data-fi'); var gt=document.getElementById('pvmType').value;
    var p={promNo:PV_PROMNO,fullItem:fi,gaejungType:gt};
    var body=Object.keys(p).map(function(k){return encodeURIComponent(k)+'='+encodeURIComponent(p[k]==null?'':p[k]);}).join('&');
    fetch(PV_CTX+'/rlms/prom/saveProvVrsn.do',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:body})
      .then(function(r){return r.text();}).then(function(t){var j={};try{j=JSON.parse(t);}catch(e){}
        if(j&&j.success){document.getElementById('pvMsg').innerHTML='<span class="pv-ok">저장되었습니다. (새로고침 시 개정마크 반영)</span>';}
        else{document.getElementById('pvMsg').innerHTML='<span class="pv-err">실패: '+pvEsc(String(j.message||'서버 오류').slice(0,140))+'</span>';}
      }).catch(function(e){console.error('saveProvVrsn', e);document.getElementById('pvMsg').innerHTML='<span class="pv-err">저장에 실패했습니다. 잠시 후 다시 시도해 주세요.</span>';});
  }

  pvLoadTree();
</script>
</lay:layout>
