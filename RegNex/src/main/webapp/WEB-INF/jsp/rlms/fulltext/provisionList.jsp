<%--
  물리적 저장 경로: /src/main/webapp/WEB-INF/jsp/rlms/fulltext/provisionList.jsp

  사용자 화면 — 규정 본문 보기 (레거시 lims 사용자 화면 구조 + law.go.kr 타이포).
    promNo 지정 : 3-pane (좌 규정분류트리 + 중앙 본문/연혁펼치기 + 우 소관부서/관련컨텐츠 + 조문정보관리 팝업)
    promNo 없음 : 규정 선택 목록
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="egovframework.com.cmm.util.EgovUserDetailsHelper" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://egovframework.gov/ctl/ui" prefix="ui" %>
<%@ taglib prefix="lay" tagdir="/WEB-INF/tags" %>
<%-- 공개열람(익명) 여부 — 태그파일 셸 도입(2026-08-07)으로 본문이 scriptless 가 되어
     인라인 스크립틀릿을 못 쓴다. 지시부 뒤에서 한 번 꺼내 EL 로 참조한다. --%>
<c:set var="lvAuthed" value="<%= Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated()) %>"/>
<%
  // [편집] 버튼은 editor.do 진입 가능 역할(EDITOR/APPROVER/ADMIN)에게만 노출 — URL보안과 동일 기준. USER 는 숨김.
  List<String> _rlmsAuths = EgovUserDetailsHelper.getAuthorities();
  boolean _rlmsCanEdit = _rlmsAuths != null
        && (_rlmsAuths.contains("ROLE_EDITOR") || _rlmsAuths.contains("ROLE_APPROVER") || _rlmsAuths.contains("ROLE_ADMIN"));
  pageContext.setAttribute("rlmsCanEdit", _rlmsCanEdit);
%>
<c:set var="pageTitle">규정 본문 보기</c:set>
<c:set var="pageHead">
  
  <script src="<c:url value='/js/egovframework/com/cmm/jquery-3.7.1.min.js'/>"></script>
  <link rel="stylesheet" href="<c:url value='/resources/lib/jstree/style.min.css' />"/>
  <script src="<c:url value='/resources/lib/jstree/jstree.min.js' />"></script>
  <script src="<c:url value='/resources/js/rlms-cate-search-tree.js' />?v=20260804-fresp"></script>
</c:set>
<lay:layout title="${pageTitle}" head="${pageHead}">
<c:choose>
  <c:when test="${not empty prom}">
  <c:set var="sysId" value="${prom.sysId}"/>
  <style>
    .lawview-toolbar{display:flex;justify-content:space-between;align-items:center;gap:8px;
      background:#f3f6fb;border:1px solid #d6deea;border-radius:6px;padding:7px 10px;margin:6px 0 10px;
      position:sticky;top:0;z-index:30;flex-wrap:wrap;}
    .lawview-toolbar .lvt-left,.lawview-toolbar .lvt-right{display:flex;align-items:center;gap:6px;flex-wrap:wrap;}
    .lvt-btn{display:inline-block;font-size:13px;line-height:1;padding:7px 11px;border:1px solid #c2cee0;
      background:#fff;color:#1d2433;border-radius:5px;cursor:pointer;text-decoration:none;}
    .lvt-btn:hover{background:#eaf1fb;border-color:#9db8e0;}
    .lvt-btn.active{background:#0b3d91;color:#fff;border-color:#0b3d91;font-weight:600;}
    .lvt-find{font-size:13px;padding:6px 9px;border:1px solid #c2cee0;border-radius:5px;width:170px;}

    .lawview-wrap{display:flex;gap:12px;align-items:flex-start;}

    /* 좌측 규정분류 트리 */
    .lawview-left{flex:0 0 264px;max-width:264px;}
    /* 트리 폭 드래그 조절 스플리터 + 접기 버튼 (2026-07-24) — 트리와 본문 사이 세로 핸들 */
    .lv-splitter{flex:0 0 8px;align-self:stretch;cursor:col-resize;border-radius:4px;background:transparent;min-height:120px;position:relative;}
    /* 핸들 위치가 항상 보이도록 중앙 세로선 상시 표시 (hover/드래그 시 전체 바 강조) */
    .lv-splitter::before{content:'';position:absolute;top:0;bottom:0;left:50%;width:2px;transform:translateX(-50%);
      background:#d0dcee;border-radius:1px;}
    .lv-splitter:hover,.lv-splitter.on{background:#c9d9f2;}
    .lv-splitter:hover::before,.lv-splitter.on::before{background:transparent;}
    .lv-sp-btn{position:absolute;top:4px;left:50%;transform:translateX(-50%);width:20px;height:34px;padding:0;
      border:1px solid #c2cee0;border-radius:5px;background:#fff;color:#4a6390;font-size:10px;line-height:1;
      cursor:pointer;box-shadow:0 1px 3px rgba(20,40,80,.12);z-index:5;}
    .lv-sp-btn:hover{background:#eef4fe;color:#0b3d91;}
    .lv-quick{display:flex;gap:5px;margin-bottom:8px;}
    .lv-quick input{flex:1 1 auto;font-size:13px;padding:6px 8px;border:1px solid #c2cee0;border-radius:5px;min-width:0;}
    .lv-quick button{font-size:12px;padding:6px 8px;border:1px solid #c2cee0;background:#fff;border-radius:5px;cursor:pointer;}
    .lv-tabs{display:flex;border-bottom:2px solid #0b3d91;}
    .lv-tabs .lv-tab{font-size:13px;padding:7px 12px;cursor:pointer;border:1px solid #d6deea;border-bottom:0;
      background:#eef2f8;color:#445;border-radius:5px 5px 0 0;margin-right:3px;}
    .lv-tabs .lv-tab.on{background:#0b3d91;color:#fff;border-color:#0b3d91;font-weight:600;}
    .lv-treebox{border:1px solid #e1e7f0;border-top:0;border-radius:0 0 6px 6px;background:#fcfdff;
      max-height:calc(calc(100vh / var(--rlms-zoom, 1)) - 220px);overflow:auto;padding:6px 0;}
    ul.lv-tree,ul.lv-tree ul{list-style:none;margin:0;padding:0;}
    ul.lv-tree ul{padding-left:14px;}
    .lv-tree li{font-size:13px;line-height:1.7;white-space:nowrap;}
    .lv-tree .t-tog{display:inline-block;width:20px;color:#4b5563;cursor:pointer;text-align:center;user-select:none;font-size:15px;font-weight:700;}
    .lv-tree .t-gubun>span.t-label{font-weight:700;color:#0b2e6f;}
    .lv-tree .t-cate>span.t-label{font-weight:600;color:#334;}
    .lv-tree a.t-prom{color:#27384f;text-decoration:none;padding:1px 4px;border-radius:3px;}
    .lv-tree a.t-prom:hover{background:#eef4fe;}
    .lv-tree a.t-prom.on{background:#0b3d91;color:#fff;font-weight:600;}
    /* 현재 규정 조문 개요(장→조) — 클릭=본문 점프 (2026-07-24) */
    .lv-tree ul.lv-outline{list-style:none;margin:3px 0 5px 12px;padding:0 0 0 9px;border-left:1px dashed #c9d6ea;}
    .lv-tree ul.lv-outline ul{list-style:none;margin:0 0 0 12px;padding:0;}
    .lv-tree ul.lv-outline li{margin:1px 0;white-space:nowrap;}
    .lv-tree ul.lv-outline a{color:#33445c;text-decoration:none;font-size:12.5px;padding:1px 4px;border-radius:3px;}
    .lv-tree ul.lv-outline a:hover{background:#eef4fe;color:#0b3d91;}
    .lv-tree ul.lv-outline a.lv-ol-grp{font-weight:600;color:#27384f;}
    .lv-tree ul.lv-outline .t-tog{cursor:pointer;}
    /* 본문 장 단위 접기 (긴 규정 스크롤 대책 2026-07-24) */
    .lv-chap-head{cursor:pointer;border-radius:4px;}
    .lv-chap-head:hover{background:#f2f6fd;}
    .lv-chap-mk{color:#1f3974;font-size:17px;margin-right:6px;vertical-align:-1px;}
    /* 별표/별지서식 — 목록형 접기 + 개별 첨부 (2026-07-30 고객 요청 9-②·9-③) */
    .lv-docu-head{cursor:pointer;border-radius:4px;display:inline-block;}
    .lv-docu-head:hover{background:#f2f6fd;}
    .lv-docu-mk{color:#1f3974;font-size:15px;margin-right:5px;vertical-align:-1px;}
    .lv-docu-clip{margin-left:8px;font-size:12px;color:#0b3d91;font-weight:600;}
    .lv-docu-files{margin:8px 0 4px;padding:8px 12px;background:#f7f9fd;border:1px solid #e2e9f4;border-radius:6px;}
    .lv-docu-files>b{display:block;font-size:12.5px;color:#33445c;margin-bottom:4px;}
    .lv-docu-files ul{margin:0;padding-left:18px;}
    .lv-docu-files li{margin:2px 0;font-size:13px;}
    .lv-docu-size{color:#7b8aa3;font-size:12px;}
    /* 본문 상단 바 — KRDS 토글 스위치(krds-form-toggle-switch) 2종.
       개정주석 표시는 항상, 장 전체 펼치기는 장 구조가 있는 규정에만 (2026-07-31) */
    .lv-chap-bar{margin:0 0 12px;display:flex;gap:18px;justify-content:flex-end;align-items:center;flex-wrap:wrap;}
    .lv-chap-bar .krds-form-toggle-switch label{cursor:pointer;color:#33445c;}
    .lawview-body.hide-rev .prov-rev,.lawview-body.hide-rev .prov-hist{display:none;}
    /* 전 규정 조문/별표 제목 검색 결과 (빠른검색 보조) */
    .lv-qsbox{margin:4px 0 6px;border:1px solid #cfdcef;border-radius:6px;background:#f7faff;max-height:250px;overflow:auto;padding:4px;}
    .lv-qsbox .lvqs-head{font-size:12px;color:#456;font-weight:600;padding:2px 4px 4px;}
    .lv-qsbox a{display:block;font-size:12.5px;color:#27384f;text-decoration:none;padding:2px 5px;border-radius:4px;line-height:1.45;}
    .lv-qsbox a:hover{background:#e7f0ff;color:#0b3d91;}
    .lv-qsbox a b{color:#0b3d91;font-weight:600;}
    .lv-tree .t-date{color:#99a;font-size:11px;}

    /* 중앙 본문 */
    .lawview-main{flex:1 1 auto;min-width:0;border:1px solid #e1e7f0;border-radius:6px;background:#fff;padding:24px 30px 50px;}
    .lawview-titleblock{text-align:center;border-bottom:2px solid #0b2e6f;padding-bottom:12px;margin-bottom:6px;}
    .lawview-titleblock .lv-title{font-size:24px;font-weight:800;color:#15233b;margin:2px 0 8px;letter-spacing:-.3px;}
    .lawview-titleblock .lv-meta{font-size:13px;color:#445;margin:2px 0;}

    /* 필수 열람 배너 (2026-07-28) — 대상자 전용. 미숙지=노랑 경고 / 숙지 완료=녹색 */
    .lv-duty{display:flex;align-items:center;justify-content:space-between;gap:12px;margin:10px 0 4px;
      padding:10px 14px;border:1px solid #fec84b;background:#fffaeb;border-radius:8px;font-size:14px;color:#7a4d0b;}
    .lv-duty.done{border-color:#a6f4c5;background:#f0fdf4;color:#067647;}
    .lv-duty-over{color:#b42318;font-weight:700;}
    .lv-duty-dday{font-weight:700;color:#1f3974;}
    .lv-duty-btn{flex-shrink:0;padding:7px 16px;border-radius:8px;border:1px solid #1f3974;background:#1f3974;
      color:#fff;cursor:pointer;font-size:14px;font-weight:600;}
    .lv-duty-btn:hover{background:#163063;}
    @media print{.lv-duty{display:none;}}

    /* 연혁 펼치기 */
    .lv-history{border:1px solid #e1e7f0;background:#f8fbff;border-radius:6px;margin:12px 0 6px;}
    .lv-history .lvh-head{padding:8px 12px;cursor:pointer;font-weight:600;color:#0b2e6f;font-size:13.5px;user-select:none;}
    .lv-history .lvh-head .arr{display:inline-block;width:14px;}
    .lv-history .lvh-body{display:none;padding:2px 14px 12px;}
    .lv-history .lvh-body.open{display:block;}
    .lv-history .lvh-item{font-size:13px;padding:3px 0;border-top:1px dotted #dde6f1;}
    .lv-history .lvh-item:first-child{border-top:0;}
    .lv-history .lvh-item a{color:#1a5fb4;text-decoration:none;}
    .lv-history .lvh-item .lvh-cur{color:#0b3d91;font-weight:700;}
    .lv-history .lvh-tag{display:inline-block;font-size:11px;color:#9a5b00;background:#fff4e5;border-radius:8px;padding:0 6px;margin-left:5px;}
    /* 외부 원문 참조 카드 (법제처 등 SURL 규정) */
    .lv-extref{margin:14px 0 18px;padding:16px 18px;border:1px solid #cdd9ef;background:#f4f8ff;border-radius:10px;}
    .lv-extref .lv-extref-tit{font-weight:700;color:#1f3974;margin-bottom:6px;font-size:15px;}
    .lv-extref .lv-extref-desc{margin:0 0 12px;color:#555;font-size:13.5px;line-height:1.6;}
    .lv-extref .lv-extref-btn{display:inline-flex;align-items:center;gap:6px;height:40px;padding:0 18px;background:#1f3974;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;font-size:14px;}
    .lv-extref .lv-extref-btn:hover{background:#163063;}

    .lawview-legend{font-size:12px;color:#667;margin:8px 0 4px;text-align:right;}

    /* 본문 문서 타이포 */
    .lawview-body .prov-doc{font-size:15.5px;line-height:1.95;color:#1a2233;}
    .lawview-body .prov-group{margin:22px 0 8px;font-size:16.5px;}
    .lawview-body .prov-jo{margin:14px 0;scroll-margin-top:60px;}
    .lawview-body .prov-jo-label{color:#0b2e6f;}
    <%-- 조문 링크/본문 복사는 ✎(조문정보관리) 팝업 안으로 통합 — 라벨 옆 아이콘 3개 나열이
         과했음(간격 과다, 2026-07-24 사용자 피드백). 액션은 lvOpenInfo 의 lvm-act 목록 참조. --%>
    .lawview-body .prov-sub{margin:4px 0;}
    .lawview-body .prov-sub-label{color:#34507a;font-weight:600;margin-right:3px;}
    .lawview-body .prov-postscript{margin:24px 0 8px;padding-top:14px;border-top:1px dashed #cdd7e6;scroll-margin-top:60px;}
    .lawview-body .prov-docu-sec{margin:26px 0 8px;padding-top:16px;border-top:1px dashed #cdd7e6;}
    .lawview-body .prov-docu{margin:12px 0;}
    .lawview-body .prov-body{margin-top:3px;}
    .lawview-body button.prov-info{margin-left:6px;border:1px solid #d6deea;background:#fff;border-radius:4px;
      cursor:pointer;font-size:12px;color:#5a7;padding:0 5px;line-height:1.6;vertical-align:middle;}
    .lawview-body button.prov-info:hover{background:#eef9f0;border-color:#9ccfab;}
    /* 개정마크 — 배경 없이 글자색으로만 구분(2026-07-31). 본문 끝에 붙는 주석이라 칩(배경+라운드)은 과했다. */
    .lawview-body .prov-rev{font-size:11.5px;font-weight:600;margin-left:5px;vertical-align:middle;white-space:nowrap;}
    .lawview-body .prov-rev-NEW{color:#1a7f37;}
    .lawview-body .prov-rev-MODIFY_ALL,.lawview-body .prov-rev-MODIFY_TITLE,.lawview-body .prov-rev-MODIFY_CONTENTS{color:#9a5b00;}
    .lawview-body .prov-rev-MOVE_ALL,.lawview-body .prov-rev-MOVE_TITLE_MODIFY_CONTENTS,.lawview-body .prov-rev-MOVE_CONTENTS_MODIFY_TITLE{color:#2347a3;}
    /* 과거 회차 개정 이력 주석(누적 최종개정일) — 법제처 <개정 YYYY. M. D.> 톤의 무채색 (2026-07-24) */
    .lawview-body .prov-hist{font-size:0.82em;font-weight:400;color:#8a8f99;margin-left:5px;white-space:nowrap;}
    .lawview-body a.rel-file{color:#0b6b3a;text-decoration:underline;}
    .lawview-body a.rel-link{color:#1a5fb4;text-decoration:underline;}
    .lawview-body .rel-dmnlnk{color:#2347a3;border-bottom:1px dotted #2347a3;cursor:help;}
    .lawview-body img.rel-img{max-width:100%;height:auto;display:block;margin:8px 0;border:1px solid #d6deea;}
    .lawview-body .rel-html{margin:8px 0;padding:8px;background:#f7f9fc;border:1px solid #e1e7f0;border-radius:4px;overflow-x:auto;}
    .lawview-body .rel-missing{color:#b00;text-decoration:line-through;}
    .lawview-body a.xref{color:#1a5fb4;text-decoration:none;border-bottom:1px dashed #9db8e0;cursor:pointer;}
    .lawview-body a.xref:hover{background:#eef4fe;}
    /* 자동링크 — 등록 규정명(사전 기반, 서버 렌더) */
    .lawview-body a.prov-autolink{color:#1a5fb4;text-decoration:none;border-bottom:1px solid #9db8e0;cursor:pointer;}
    .lawview-body a.prov-autolink:hover{background:#eef4fe;}
    .lv-autolink-pop{position:absolute;z-index:1000;background:#fff;border:1px solid #c9d4e8;border-radius:6px;box-shadow:0 4px 14px rgba(0,0,0,.14);min-width:220px;max-width:340px;padding:4px 0 6px;}
    .lv-autolink-pop .hd{padding:6px 12px;font-size:12px;color:#777;border-bottom:1px solid #eee;margin-bottom:4px;}
    .lv-autolink-pop a{display:block;padding:7px 12px;color:#1a5fb4;text-decoration:none;font-size:14px;}
    .lv-autolink-pop a:hover{background:#eef4fe;}
    .lv-autolink-pop a small{color:#888;margin-left:6px;font-size:12px;}
    .lawview-body mark.lvhit{background:#ffe58a;padding:0 1px;}
    .lawview-body mark.lvhit.cur{background:#ff9f1c;color:#fff;}

    /* 우측 소관부서 / 관련컨텐츠 */
    .lawview-right{flex:0 0 210px;max-width:210px;}
    .lv-side{border:1px solid #e1e7f0;border-radius:6px;margin-bottom:12px;overflow:hidden;}
    .lv-side .lvs-head{font-size:13px;font-weight:700;padding:7px 11px;color:#15314f;}
    .lv-side.dept .lvs-head{background:#e6effb;}
    .lv-side.cont .lvs-head{background:#fdeede;color:#7a4a06;}
    .lv-side .lvs-body{padding:9px 11px;font-size:13px;color:#27384f;}
    .lv-side .lvs-body .muted{color:#99a;}

    /* 조문정보관리 / 메모 팝업 */
    #lvModal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:60;}
    #lvModal .lvm-box{position:absolute;top:14%;left:50%;transform:translateX(-50%);width:min(460px,calc(92vw / var(--rlms-zoom, 1)));
      background:#fff;border-radius:8px;box-shadow:0 10px 40px rgba(0,0,0,.3);}
    #lvModal .lvm-head{display:flex;justify-content:space-between;align-items:center;padding:11px 16px;
      border-bottom:1px solid #e7edf6;font-weight:700;color:#b3261e;background:#fdecec;border-radius:8px 8px 0 0;}
    #lvModal .lvm-head .lvm-x{cursor:pointer;border:0;background:none;font-size:20px;color:#889;}
    #lvModal .lvm-body{padding:14px 16px;font-size:13.5px;}
    #lvModal .lvm-jo{font-weight:700;color:#0b2e6f;margin-bottom:10px;}
    #lvModal .lvm-act{display:block;width:100%;text-align:left;padding:9px 12px;margin:6px 0;border:1px solid #d6deea;
      background:#f7faff;border-radius:6px;cursor:pointer;font-size:13.5px;color:#1d2433;}
    #lvModal .lvm-act:hover{background:#eaf1fb;}
    #lvModal textarea{width:100%;height:70px;border:1px solid #c2cee0;border-radius:5px;padding:7px;font-size:13px;margin-top:4px;}
    #lvModal .lvm-save{margin-top:6px;padding:7px 14px;border:0;background:#0b3d91;color:#fff;border-radius:5px;cursor:pointer;}
    /* 즐겨찾기/메모 read-back (2026-07-16) */
    #lvModal .lvm-fav-on{padding:9px 12px;margin:6px 0;border:1px solid #f2dc9b;background:#fdf8e7;border-radius:6px;font-size:13.5px;color:#6b5310;}
    #lvModal .lvm-fav-desc{color:#8a7430;font-size:12.5px;margin-left:4px;}
    #lvModal .lvm-mini{padding:3px 9px;border:1px solid #c2cee0;background:#fff;border-radius:4px;cursor:pointer;font-size:12px;color:#334;}
    #lvModal .lvm-mini:hover{background:#eef4fe;}
    #lvModal .lv-memo-form{display:flex;flex-direction:column;gap:4px;margin-top:4px;}
    #lvModal .lv-memo-gubun{align-self:flex-start;padding:4px 8px;border:1px solid #c2cee0;border-radius:4px;font-size:12.5px;}
    #lvModal .lv-memo-list{list-style:none;margin:10px 0 0;padding:0;max-height:180px;overflow-y:auto;}
    #lvModal .lv-memo-list li{padding:7px 4px;border-top:1px solid #eef1f6;font-size:13px;line-height:1.5;}
    #lvModal .lv-memo-list li.muted{color:#99a;border-top:0;}
    #lvModal .lv-memo-tag{display:inline-block;padding:1px 7px;margin-right:6px;border-radius:9px;background:#e8eef8;color:#33518a;font-size:11.5px;}
    #lvModal .lv-memo-txt{word-break:break-all;}
    #lvModal .lv-memo-edit{width:100%;height:56px;border:1px solid #c2cee0;border-radius:5px;padding:6px;font-size:13px;margin:2px 0 6px;}
    /* 관련자료 WORD 자체변환 본문 인라인 미리보기 모달 (.docx/.hwpx) */
    #lvDocModal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:61;}
    #lvDocModal .lvd-box{position:absolute;top:8%;left:50%;transform:translateX(-50%);width:min(840px,calc(94vw / var(--rlms-zoom, 1)));
      max-height:calc(84vh / var(--rlms-zoom, 1));display:flex;flex-direction:column;background:#fff;border-radius:8px;box-shadow:0 10px 40px rgba(0,0,0,.3);overflow:hidden;}
    #lvDocModal .lvd-head{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:11px 16px;
      border-bottom:1px solid #e3e8f0;font-weight:700;color:#0b2e6f;}
    #lvDocModal .lvd-head-r{display:flex;align-items:center;gap:14px;}
    #lvDocModal .lvd-doc-dl{font-size:13px;color:#0b3d91;text-decoration:underline;white-space:nowrap;}
    #lvDocModal .lvm-x{cursor:pointer;border:0;background:none;font-size:20px;color:#889;}
    #lvDocModal .lvd-body{padding:16px 18px;overflow:auto;font-size:13.5px;line-height:1.7;color:#222;}
    #lvDocModal .lvd-body p{margin:0 0 .6em;white-space:pre-wrap;word-break:break-word;}
    #lvDocModal .lvd-body p:last-child{margin-bottom:0;}
    /* 연혁 목록 개정문 버튼 + 개정문 모달 표 (#14) */
    .lvh-gj-btn{margin-left:6px;font-size:12px;padding:1px 8px;border:1px solid #b9c2d0;border-radius:11px;background:#fff;color:#0b3d91;cursor:pointer;}
    .lvh-gj-btn:hover{background:#eef3fb;}
    .lvg-table{width:100%;border-collapse:collapse;}
    .lvg-table th{width:108px;text-align:left;vertical-align:top;background:#f4f6fa;border:1px solid #d7dde7;padding:8px 10px;font-weight:600;color:#333;white-space:nowrap;}
    .lvg-table td{border:1px solid #d7dde7;padding:8px 12px;vertical-align:top;}
    .lvg-table .lvg-cell{white-space:normal;word-break:break-word;}
    #lvMsg{font-size:12.5px;margin-top:8px;}

    /* ---- 규정형식(SPROV_FG) 분기 — 파일 인라인 보기 / 안내 배너 ---- */
    .lv-fileview{margin-top:10px;}
    .lv-fileview .lvf-bar{display:flex;gap:6px;align-items:center;margin-bottom:6px;}
    .lv-fileview .lvf-mode{font-weight:700;color:#234;margin-right:auto;font-size:13px;}
    .lv-fileview .lvf-frame{width:100%;height:calc(75vh / var(--rlms-zoom, 1));border:1px solid #ccd;background:#f6f7f9;}
    .lv-notice{margin:10px 0;padding:12px 14px;border:1px solid #e3d9b8;background:#fdf8e7;border-radius:6px;color:#5a4a12;font-size:13px;}
    .lv-notice b{display:block;margin-bottom:4px;color:#3f3308;}
    .lvn-files{max-height:200px;overflow:auto;margin-top:8px;border-top:1px solid #eee3bf;}
    .lvn-file{padding:4px 0;border-bottom:1px dotted #e8dcb4;}
    .lvn-file a{color:#1a5fb4;text-decoration:none;}
    .lvn-cate{margin-left:6px;font-size:11px;color:#8a7a3a;border:1px solid #d9cf9f;border-radius:3px;padding:0 4px;vertical-align:1px;}
    .prov-html-body{margin:6px 0 14px;}
    .lvs-grp{margin-top:6px;font-weight:700;font-size:12px;color:#556;}

    /* 인라인 스타일 정리 (2026-06-11) — JS 주입 조각 공통 */
    .lvt-find-cnt{font-size:12px;color:#667;}
    .lv-tree li.muted{padding:8px 12px;color:#99a;}
    .lv-tree li.err{padding:8px 12px;color:#b00;}
    .lv-err{color:#b00;}
    .lv-ok{color:#1a7f37;}
    .lv-rel-row{padding:3px 0;border-top:1px dotted #eee;}
    .lv-rel-row a{color:#1a5fb4;text-decoration:none;}
    /* 관련규정연계(dmn) — 여러 건일 때 행 아래 펼침 목록 */
    .lv-dmn-sub{margin:4px 0 2px 12px;padding-left:8px;border-left:2px solid #dbe4f2;}
    .lv-dmn-sub a{color:#1a5fb4;text-decoration:none;font-size:12.5px;}
    .lv-dmn-cur{font-size:11px;color:#9a5b00;background:#fff4e5;border-radius:8px;padding:0 6px;}
    .lv-hist-empty{color:#99a;margin-top:6px;}
    .lv-chg-tbl{width:100%;font-size:12.5px;margin-top:6px;border-collapse:collapse;}
    .lv-chg-tbl th{text-align:left;border-bottom:1px solid #eee;}
    .lv-chg-tbl td{border-bottom:1px solid #f3f3f3;}

    /* 툴바 — 비활성 버튼 / 내보내기 드롭다운 */
    .lvt-btn.lvt-disabled{opacity:.45;cursor:default;}
    .lvt-btn.lvt-disabled:hover{background:#fff;border-color:#c2cee0;}
    .lvt-export{position:relative;display:inline-block;}
    .lvt-export .lvt-menu{display:none;position:absolute;top:calc(100% + 3px);left:0;z-index:40;min-width:130px;
      background:#fff;border:1px solid #c2cee0;border-radius:6px;box-shadow:0 6px 22px rgba(0,0,0,.16);padding:4px;}
    .lvt-export .lvt-menu.open{display:block;}
    .lvt-export .lvt-menu a{display:block;padding:7px 12px;font-size:13px;color:#1d2433;text-decoration:none;border-radius:4px;white-space:nowrap;}
    .lvt-export .lvt-menu a:hover{background:#eaf1fb;}
    /* 개정문 패널 — 빈 셀 안내 / HTML 본문 여백 */
    .lvg-table .lvg-cell p{margin:0 0 .5em;}
    .lvg-table .lvg-cell:last-child{max-height:calc(46vh / var(--rlms-zoom, 1));overflow:auto;}
    /* 인쇄 옵션 / 본문저장 옵션 모달 — 같은 톤(2026-07-30 저장 옵션 추가) */
    <%-- id 대신 .lvp-modal 공용 클래스로 스코프 — 인쇄/본문저장 두 모달이 같은 규칙을 쓴다.
         열고 닫기는 JS 가 인라인 style.display 로 하므로 특이도 하향은 무해. --%>
    .lvp-modal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:62;}
    .lvp-modal .lvp-box{position:absolute;top:14%;left:50%;transform:translateX(-50%);width:min(500px,calc(93vw / var(--rlms-zoom, 1)));
      background:#fff;border-radius:8px;box-shadow:0 10px 40px rgba(0,0,0,.3);}
    .lvp-modal .lvp-head{display:flex;justify-content:space-between;align-items:center;padding:11px 16px;
      border-bottom:1px solid #e7edf6;font-weight:700;color:#0b2e6f;}
    .lvp-modal .lvp-body{padding:14px 16px;font-size:13.5px;}
    .lvp-modal .lvp-row{margin:10px 0;display:flex;flex-wrap:wrap;align-items:center;gap:10px;}
    .lvp-modal .lvp-row>b{flex:0 0 86px;color:#334;font-weight:600;}
    .lvp-modal .lvp-row label{font-weight:normal;display:inline-flex;align-items:center;gap:4px;}
    .lvp-modal .lvp-sel{font-size:13px;padding:5px 7px;border:1px solid #c2cee0;border-radius:5px;max-width:180px;}
    .lvp-modal .lvp-memo{flex:1 1 auto;font-size:13px;padding:6px 9px;border:1px solid #c2cee0;border-radius:5px;min-width:0;}
    .lvp-modal .lvp-note{color:#5a6b85;font-size:12.5px;}
    .lvp-modal .lvp-act{margin-top:14px;padding-top:12px;border-top:1px solid #eef2f7;display:flex;justify-content:flex-end;gap:8px;}
    /* 인쇄/저장 실행 버튼 — #lvModal 스코프 lvm-save 가 안 먹어 밋밋하던 것 수정. 시스템 1차 버튼 톤(파랑). */
    .lvp-modal .lvp-act .lvm-save{margin:0;padding:8px 20px;border:0;background:#0b3d91;color:#fff;
      border-radius:5px;cursor:pointer;font-size:14px;font-weight:600;line-height:1.2;}
    .lvp-modal .lvp-act .lvm-save:hover{background:#0a3179;}
    .lvp-modal .lvp-act .lvp-cancel{padding:8px 16px;border:1px solid #c2cee0;background:#fff;color:#334;
      border-radius:5px;cursor:pointer;font-size:14px;line-height:1.2;}
    .lvp-modal .lvp-act .lvp-cancel:hover{background:#f2f5fa;}
    /* 인쇄 본문 머리말(메모) — 화면에선 숨김, 인쇄시에만 노출 */
    #lvPrintHeader{display:none;}
    /* 신구대조 인페이지 모달 (iframe) */
    #lvCmpModal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:61;}
    #lvCmpModal .lvc-box{position:absolute;top:5%;left:50%;transform:translateX(-50%);width:min(1120px,calc(96vw / var(--rlms-zoom, 1)));height:calc(88vh / var(--rlms-zoom, 1));
      display:flex;flex-direction:column;background:#fff;border-radius:8px;box-shadow:0 10px 40px rgba(0,0,0,.3);overflow:hidden;}
    #lvCmpModal .lvc-head{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:11px 16px;
      border-bottom:1px solid #e3e8f0;font-weight:700;color:#0b2e6f;}
    #lvCmpModal .lvc-head-r{display:flex;align-items:center;gap:14px;}
    #lvCmpModal .lvc-open{font-size:13px;color:#0b3d91;text-decoration:underline;white-space:nowrap;}
    #lvCmpModal .lvc-frame{flex:1 1 auto;width:100%;border:0;background:#fff;}

    /* ---- 반응형 (2026-08-04) — ≤1024: 좌 트리=오프캔버스 드로어, 우 패널=본문 아래 스택.
         기본값(데스크톱)을 먼저 두고 미디어가 나중에 이기도록 소스 순서 유지.
         스플리터 JS 가 남긴 인라인 flex/max-width/display(localStorage 복원값)는 !important 로 무력화. ---- */
    #lvMobBackdrop{position:fixed;inset:0;background:rgba(0,0,0,.28);z-index:1199;opacity:0;visibility:hidden;transition:opacity .2s;}
    .lv-mob-x{display:none;position:absolute;top:4px;right:6px;border:0;background:none;font-size:22px;color:#889;cursor:pointer;padding:2px 6px;line-height:1;}
    /* 트리 핸들 — 전역 규정분류 드로어(rlms-prom-nav #pnHandle)와 동일 룩/위치.
       접근 방식 통일(2026-08-04 사용자): 홈 등 다른 화면과 같은 좌측 책갈피(≤768=하단 알약)로 연다.
       열리는 내용물만 뷰어 자체 트리(3탭+조문 개요)일 뿐. 데스크톱(≥1025)은 트리가 상주라 핸들 불요. */
    #lvTreeHandle{display:none;}
    @media (max-width:1024px){
      .lawview-wrap{display:block;}
      .lv-splitter{display:none!important;}
      #lvTreeHandle{display:block;position:fixed;left:0;top:42%;z-index:1190;background:#1f3974;color:#fff;border:0;
        padding:18px 13px;border-radius:0 8px 8px 0;cursor:pointer;writing-mode:vertical-rl;text-orientation:upright;
        font-size:14px;letter-spacing:2px;font-weight:700;box-shadow:2px 1px 8px rgba(0,0,0,.22);line-height:1.1;}
      #lvTreeHandle:hover{background:#16306a;}
      #lvTreeHandle.hidden{display:none;}
      #lvMobBackdrop.on{opacity:1;visibility:visible;}
      .lawview-left{position:fixed;left:0;top:0;bottom:0;z-index:1200;
        width:min(320px, calc(88vw / var(--rlms-zoom, 1)));max-width:none!important;flex:none!important;
        display:flex!important;flex-direction:column;background:#fff;box-shadow:3px 0 14px rgba(0,0,0,.22);
        padding:30px 10px 12px;margin:0;transform:translateX(-105%);transition:transform .22s ease;}
      .lawview-left.lv-mob-open{transform:translateX(0);}
      .lv-mob-x{display:block;}
      .lv-treebox{max-height:none;flex:1 1 auto;}
      .lawview-right{max-width:none;margin-top:14px;display:grid;
        grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px;}
      .lawview-right .lv-side{margin-bottom:0;}
    }
    @media (max-width:768px){
      .lawview-main{padding:16px 14px 40px;}
      .lawview-titleblock .lv-title{font-size:20px;}
      .lvt-find{width:120px;}
      /* 트리 핸들 — 하단 알약 FAB 로 전환(전역 드로어 #pnHandle ≤768 과 동일) */
      #lvTreeHandle{top:auto;bottom:16px;writing-mode:horizontal-tb;text-orientation:mixed;letter-spacing:0;
        padding:11px 16px;border-radius:0 22px 22px 0;font-size:13px;}
      /* 본문 내 컨텐츠 표(HTML형식 조문·별표 등) — 넘치면 표만 가로 스크롤 */
      .lawview-body table{display:block;max-width:100%;overflow-x:auto;}
    }
    /* ≤640(폰 — 아이폰 프로맥스 430·갤럭시 울트라 412): 툴바 버튼군이 3줄을 먹어 본문을 밀어냄
       → 기본 접힘 + [도구 ▾] 토글로 펼침(2026-08-04 사용자). 아이패드(768~)는 현행 노출 유지.
       토글 버튼은 .lvt-left 밖(툴바 직속) — PJAX 가 .lvt-left innerHTML 만 갈아끼우므로 생존. */
    #lvToolsTog{display:none;}
    @media (max-width:640px){
      #lvToolsTog{display:inline-block;}
      .lawview-toolbar .lvt-left,.lawview-toolbar .lvt-right{display:none;}
      .lawview-toolbar.lv-tools-open .lvt-left,.lawview-toolbar.lv-tools-open .lvt-right{display:flex;}
    }

    @media print{.lawview-toolbar,.lawview-left,.lawview-right,.lv-history,.lawview-legend,.lv-splitter,
      button.prov-info,.lv-fileview .lvf-bar,#lvModal,#lvDocModal,#lvPrintModal,#lvCmpModal,.lvt-menu,.lv-stsfdg,#lvMobBackdrop,#lvTreeHandle{display:none!important;}
      .lv-chap-body{display:block!important;}.lv-chap-bar,.lv-chap-mk{display:none!important;}
      /* 인쇄는 항상 전체 — 접힌 별표 본문도 펼쳐 출력하고 토글 마커·첨부 상자는 뺀다 */
      .lv-docu-body{display:block!important;}
      .lv-docu-mk,.lv-docu-clip,.lv-docu-files{display:none!important;}
      .lawview-main{border:0;padding:0;}.lawview-wrap{display:block;}
      #lvPrintHeader{display:block!important;border-bottom:1px solid #999;margin-bottom:14px;padding-bottom:8px;
        font-size:12px;color:#333;white-space:pre-wrap;}
      #lvBody mark.lvhit{background:none!important;color:inherit!important;}}
  </style>

  <!-- 툴바 -->
  <div class="lawview-toolbar">
    <%-- 폰(≤640) 전용 도구 토글 — 버튼군(개정문/신구대조/저장/검색/인쇄)을 접었다 편다. 그 외 폭은 CSS 로 숨김 --%>
    <button type="button" class="lvt-btn" id="lvToolsTog" aria-expanded="false" onclick="lvToolsToggle()">도구 <span id="lvToolsTogArr" aria-hidden="true">&#9662;</span></button>
    <div class="lvt-left">
      <span class="lvt-btn active">본문</span>
      <button type="button" class="lvt-btn" onclick="lvOpenGaejungCurrent()" title="개정이유·주요내용·부칙·서문">개정문</button>
      <%-- 신구대조 — 직전 회차 자동 비교(레거시 getPrevious)를 인페이지 iframe 모달로. 제정 회차면 비활성 --%>
      <c:choose>
        <c:when test="${not empty prevPromNo}">
          <button type="button" class="lvt-btn" onclick="lvOpenCompare()">신구대조</button>
        </c:when>
        <c:otherwise><span class="lvt-btn lvt-disabled" title="최초 제정 — 비교할 이전 회차가 없습니다">신구대조</span></c:otherwise>
      </c:choose>
      <%-- 본문저장 — 이 회차 본문을 문서로 내보내기(PDF/Word/한글).
           2026-07-30 고객 요청 "조문별 저장 — 인쇄기능에 있는 내용 적용" 에 따라
           드롭다운(형식만) → 저장 옵션 모달(범위 + 형식)로 교체. 범위 규칙은 인쇄와 동일. --%>
      <button type="button" class="lvt-btn" onclick="lvOpenExport()">본문저장</button>
      <%-- 연혁일괄저장 — 이 규정의 전체 회차를 한 문서로 --%>
      <span class="lvt-export">
        <button type="button" class="lvt-btn" onclick="lvToggleMenu(event,'lvExpHist')">연혁일괄저장 &#9662;</button>
        <span class="lvt-menu" id="lvExpHist">
          <a href="<c:url value='/rlms/fulltext/exportPromHistory.do'/>?lawId=${prom.lawId}&amp;format=pdf">PDF (.pdf)</a>
          <a href="<c:url value='/rlms/fulltext/exportPromHistory.do'/>?lawId=${prom.lawId}&amp;format=docx">Word (.docx)</a>
          <a href="<c:url value='/rlms/fulltext/exportPromHistory.do'/>?lawId=${prom.lawId}&amp;format=hwpx">한글 (.hwpx)</a>
        </span>
      </span>
      <c:if test="${rlmsCanEdit}"><a class="lvt-btn" href="<c:url value='/rlms/prom/editor.do'/>?promNo=${prom.promNo}">편집(관리자)</a></c:if>
    </div>
    <div class="lvt-right">
      <input id="lvFind" class="lvt-find" type="text" placeholder="화면 내 검색 (Enter)" onkeydown="if(event.key==='Enter'){lvFindNext();event.preventDefault();}">
      <span id="lvFindCnt" class="lvt-find-cnt"></span>
      <button type="button" class="lvt-btn" onclick="lvOpenPrint()">인쇄</button>
    </div>
  </div>

  <%-- 모바일 트리 드로어 배경·핸들 — lawview-wrap 밖(PJAX 교체 영향권 밖).
       핸들은 전역 규정분류 드로어와 동일한 좌측 책갈피(≤768=하단 알약) — 접근 방식 통일. --%>
  <div id="lvMobBackdrop" onclick="lvMobTree(false)"></div>
  <button type="button" id="lvTreeHandle" onclick="lvMobTree(true)" title="규정 분류 — 분류를 펼쳐 규정 본문 바로열기">규정분류</button>

  <div class="lawview-wrap">
    <!-- 좌측 규정분류 트리 -->
    <aside class="lawview-left">
      <button type="button" class="lv-mob-x" onclick="lvMobTree(false)" title="분류 트리 닫기">&times;</button>
      <div class="lv-quick">
        <input id="lvQuick" type="text" placeholder="규정명·조문제목 빠른검색" onkeyup="lvQuickInput(this.value)">
      </div>
      <%-- 전 규정 조문/별표 제목 검색 결과 — 트리를 펼치지 않아도 다른 규정(정관·시행령·매뉴얼 등)의
           조문이 검색됨. 클릭 = 해당 규정으로 PJAX 이동 + 조문 앵커 점프 (2026-07-24) --%>
      <div id="lvQsBox" class="lv-qsbox" style="display:none"></div>
      <div class="lv-tabs">
        <div class="lv-tab on" data-tab="jeon" onclick="lvTab('jeon')">전문분류</div>
        <div class="lv-tab" data-tab="dept" onclick="lvTab('dept')">부서별</div>
        <div class="lv-tab" data-tab="func" onclick="lvTab('func')">기능별분류</div>
      </div>
      <div class="lv-treebox"><ul class="lv-tree" id="lvTree"><li class="muted">규정 목록 불러오는 중…</li></ul></div>
    </aside>

    <%-- 트리/본문 사이 스플리터 — 드래그=폭 조절, ◀ 버튼=트리 숨김/복원 (localStorage 유지) --%>
    <div class="lv-splitter" id="lvSplitter" title="드래그하여 트리 폭 조절 (더블클릭=기본 폭)">
      <button type="button" class="lv-sp-btn" id="lvTreeHideBtn" title="트리 숨기기/펼치기">&#9664;</button>
    </div>

    <!-- 중앙 본문 -->
    <main class="lawview-main" id="lvMain" data-promno="${prom.promNo}" data-lawid="${prom.lawId}" data-sysid="${sysId}" data-prevno="${prevPromNo}">
      <div id="lvPrintHeader"></div>
      <div class="lawview-titleblock">
        <h1 class="lv-title"><c:out value="${prom.title}"/></h1>
        <p class="lv-meta">[시행 ${prom.startDate}] [공포 ${prom.promDate}]<c:if test="${not empty prom.gaejungNm}"> &middot; <c:out value="${prom.gaejungNm}"/></c:if><c:if test="${prom.upcoming}"> <span class="krds-badge bg-light-information" title="공포되었으나 아직 시행 전입니다">시행예정</span></c:if><c:if test="${not empty viewCnt}"> &middot; <span title="이 규정의 누적 조회수입니다 (전체 회차 합산)">조회 <fmt:formatNumber value="${viewCnt}" type="number"/></span></c:if></p>
      </div>

      <%-- 필수 열람 배너 (2026-07-28) — 대상자에게만 노출. 본문 열람은 컨트롤러가 자동 기록(1단계),
           [숙지 확인] 버튼이 최종 증빙(2단계). 개요트리(lvBuildOutline)는 조문 셀렉터만 스캔 — 배너 무영향. --%>
      <c:if test="${not empty readDuty}">
        <div class="lv-duty${empty readDuty.confDt ? '' : ' done'}" id="lvDuty">
          <c:choose>
            <c:when test="${empty readDuty.confDt}">
              <span class="lv-duty-msg"><b>필수 열람 대상 규정</b>입니다.
                <c:if test="${not empty readDuty.dueDt}">
                  <c:choose>
                    <c:when test="${readDuty.dday lt 0}"><span class="lv-duty-over">열람 기한 경과 (D+${-readDuty.dday})</span></c:when>
                    <c:otherwise><span class="lv-duty-dday">기한 D-${readDuty.dday eq 0 ? 'DAY' : readDuty.dday}</span></c:otherwise>
                  </c:choose>
                </c:if>
                본문을 읽은 뒤 [숙지 확인]을 눌러 주세요.</span>
              <button type="button" class="lv-duty-btn" onclick="lvDutyConfirm(${readDuty.dutyNo})">숙지 확인</button>
            </c:when>
            <c:otherwise>
              <span class="lv-duty-msg">필수 열람 — <b>숙지 완료</b> (<c:out value="${readDuty.confDtFmt}"/>)</span>
            </c:otherwise>
          </c:choose>
        </div>
        <script>
          /* 숙지 확인 — 명시적 재확인 후 기록(증빙, 취소 불가). 성공 시 배너를 완료 상태로 교체 */
          function lvDutyConfirm(dutyNo){
            if(!confirm('이 규정의 내용을 충분히 읽고 숙지하셨습니까?\n숙지 확인은 열람 증빙으로 기록되며 취소할 수 없습니다.')) return;
            var fd=new URLSearchParams(); fd.append('dutyNo', dutyNo);
            fetch('<c:url value="/rlms/readduty/confirmDuty.do"/>', {method:'POST', body:fd})
              .then(function(r){ return r.json(); })
              .then(function(res){
                if(res && res.success){
                  var el=document.getElementById('lvDuty');
                  el.className='lv-duty done';
                  el.innerHTML='<span class="lv-duty-msg">필수 열람 — <b>숙지 완료</b> 처리되었습니다.</span>';
                } else { alert((res && res.message) || '처리에 실패했습니다.'); }
              })
              .catch(function(){ alert('요청이 실패했습니다.'); });
          }
        </script>
      </c:if>

      <!-- 연혁 목록 펼치기 -->
      <div class="lv-history">
        <div class="lvh-head" onclick="lvHistToggle()"><span class="arr">&#9654;</span> 연혁 목록 펼치기 <span id="lvHistCnt"></span></div>
        <div class="lvh-body" id="lvHistBody">불러오는 중…</div>
      </div>

      <%-- 외부 원문 참조(법제처/로앤비 등) — 규정 URL(SURL)이 있으면 내부 본문 대신 외부 원문 링크 카드.
           레거시 동선 파리티: 본문 없는 외부참조 규정은 외부 사이트로 연결. http(s) 만 허용(스킴 안전). --%>
      <c:set var="lvExtUrlLc" value="${fn:toLowerCase(prom.url)}"/>
      <c:if test="${not empty prom.url and (fn:startsWith(lvExtUrlLc,'http://') or fn:startsWith(lvExtUrlLc,'https://'))}">
        <div class="lv-extref">
          <div class="lv-extref-tit">🔗 외부 원문 참조</div>
          <p class="lv-extref-desc">이 규정은 외부 사이트(예: 법제처)의 원문을 참조합니다. 아래에서 원문을 새 창으로 확인하세요.</p>
          <a class="lv-extref-btn" href="${prom.url}" target="_blank" rel="noopener">원문 보기 ↗</a>
        </div>
      </c:if>

      <%-- 규정형식(SPROV_FG) 분기 — 레거시 frontView 동선: 파일 인라인 보기 / 본문 미등록 안내 --%>
      <c:choose>
        <c:when test="${not empty bodyViewAttNo}">
          <%-- HTML(관련파일 바로열람) / VIEWER — 원문 PDF 인라인 (레거시 documentViewer/viewer.htm 대응) --%>
          <div class="lv-fileview">
            <div class="lvf-bar">
              <span class="lvf-mode"><c:choose><c:when test="${bodyMode eq 'VIEWER'}">PDF 파일 본문</c:when><c:otherwise>원문 파일 본문</c:otherwise></c:choose></span>
              <a class="lvt-btn" href="<c:url value='/rlms/related/attachView.do'/>?attNo=${bodyViewAttNo}" target="_blank" rel="noopener">새 창</a>
              <a class="lvt-btn" href="<c:url value='/rlms/related/attachDownload.do'/>?attNo=${bodyViewAttNo}">다운로드</a>
            </div>
            <%-- #zoom=100 : Chrome 내장 PDF 뷰어 초기 확대율 100% 고정(기본 자동맞춤 대신). 125% 로 바꾸려면 zoom=125. --%>
            <iframe class="lvf-frame" src="<c:url value='/rlms/related/attachView.do'/>?attNo=${bodyViewAttNo}#zoom=100" title="규정 원문"></iframe>
          </div>
        </c:when>
        <c:otherwise>
          <%-- 배너는 렌더할 본문이 정말 없을 때만 — HTML 형식인데 TB_PROV_HTML 본문이 있으면 오안내 (리뷰 #7) --%>
          <c:if test="${bodyMode eq 'VIEWER' or (bodyMode eq 'HTML' and bodyHtmlEmpty)}">
            <div class="lv-notice">
              <b>이 규정의 본문은 원문 파일로 제공됩니다.</b>
              <c:choose>
                <c:when test="${not empty bodyFiles}">
                  아래 파일에서 본문을 확인하세요.
                  <div class="lvn-files">
                    <c:forEach var="f" items="${bodyFiles}">
                      <div class="lvn-file">
                        <c:choose>
                          <c:when test="${not empty f.attNo}"><a href="<c:url value='/rlms/related/attachDownload.do'/>?attNo=${f.attNo}"><c:out value="${not empty f.attName ? f.attName : f.title}"/></a></c:when>
                          <c:otherwise><c:out value="${f.title}"/></c:otherwise>
                        </c:choose>
                        <span class="lvn-cate"><c:choose><c:when test="${f.cate eq 'REL_FILE_3'}">PDF뷰어용</c:when><c:when test="${f.cate eq 'REL_FILE_2'}">개정문</c:when><c:otherwise>관련파일</c:otherwise></c:choose></span>
                      </div>
                    </c:forEach>
                  </div>
                </c:when>
                <c:otherwise><span class="muted">등록된 원문 파일이 없습니다. 관리자에게 문의하세요.</span></c:otherwise>
              </c:choose>
            </div>
          </c:if>
          <c:if test="${bodyMode eq 'VERSION' and bodySkeleton}">
            <div class="lv-notice">
              <b>조문 본문이 등록되어 있지 않은 규정입니다.</b>
              조문 제목 목차만 표시됩니다. 본문은 원문 파일을 참조하세요.
              <c:if test="${not empty bodyFiles}">
                <div class="lvn-files">
                  <c:forEach var="f" items="${bodyFiles}">
                    <div class="lvn-file">
                      <c:choose>
                        <c:when test="${not empty f.attNo}"><a href="<c:url value='/rlms/related/attachDownload.do'/>?attNo=${f.attNo}"><c:out value="${not empty f.attName ? f.attName : f.title}"/></a></c:when>
                        <c:otherwise><c:out value="${f.title}"/></c:otherwise>
                      </c:choose>
                      <span class="lvn-cate"><c:choose><c:when test="${f.cate eq 'REL_FILE_3'}">PDF뷰어용</c:when><c:when test="${f.cate eq 'REL_FILE_2'}">개정문</c:when><c:otherwise>관련파일</c:otherwise></c:choose></span>
                    </div>
                  </c:forEach>
                </div>
              </c:if>
            </div>
          </c:if>
          <%-- LINK(링크형식)는 본문 없음 — 외부 원문 카드가 본문을 대신하므로 범례/본문 영역 생략 --%>
          <c:if test="${bodyMode ne 'VIEWER' and bodyMode ne 'LINK'}">
            <div class="lawview-legend">
              <span class="prov-rev prov-rev-NEW">&lt;신설&gt;</span>
              <span class="prov-rev prov-rev-MODIFY_CONTENTS">&lt;개정&gt;</span>
              <span class="prov-rev prov-rev-MOVE_ALL">&lt;조항이동&gt;</span>
              &mdash; 직전 회차 대비 변경 (삭제 조문 숨김)
            </div>
            <div class="lawview-body" id="lvBody">${provHtml}${docuHtml}</div>
          </c:if>
        </c:otherwise>
      </c:choose>

      <%-- 만족도 조사 — 연혁 옵션(TB_PROM.SSTSFDG_YN='Y') 회차만 노출. #lvMain 내부라 PJAX 회차 이동 시
           마크업이 함께 교체되고, lvNavigate 가 lvLoadStsfdg() 를 재호출해 데이터를 다시 그린다. --%>
      <c:if test="${prom.stsfdgYn == 'Y'}">
      <section class="lv-stsfdg" id="lvStsfdg">
        <style>
          .lv-stsfdg { margin:34px 0 8px; border:1px solid #d7dae2; border-radius:10px; background:#fafbfd; padding:16px 20px; }
          .lv-stsfdg .lvs-title { font-weight:700; color:#1f3974; font-size:15px; }
          .lv-stsfdg .lvs-sum { color:#555; font-size:13.5px; margin-left:8px; }
          .lv-stsfdg .lvs-star { cursor:pointer; font-size:22px; color:#c9ced8; user-select:none; }
          .lv-stsfdg .lvs-star.on { color:#f59e0b; }
          .lv-stsfdg .lvs-form { display:flex; gap:8px; align-items:flex-start; margin-top:10px; flex-wrap:wrap; }
          .lv-stsfdg textarea { flex:1; min-width:240px; min-height:44px; padding:8px 10px; border:1px solid #d1d3d8; border-radius:6px; font:inherit; }
          .lv-stsfdg .lvs-list { list-style:none; margin:12px 0 0; padding:0; border-top:1px solid #e4e7ec; }
          .lv-stsfdg .lvs-list li { padding:8px 2px; border-bottom:1px solid #eef0f4; font-size:13.5px; }
          .lv-stsfdg .lvs-list .who { font-weight:600; margin-right:6px; }
          .lv-stsfdg .lvs-list .st { color:#f59e0b; margin-right:6px; letter-spacing:1px; }
          .lv-stsfdg .lvs-list .dt { color:#999; margin-left:6px; font-size:12.5px; }
          .lv-stsfdg .muted { color:#888; }
          .lv-stsfdg .lvs-msg { min-height:18px; font-size:13px; margin-top:6px; }
          .lv-stsfdg .lvs-msg.ok { color:#1b7f4d; }
          .lv-stsfdg .lvs-msg.err { color:#b03030; }
        </style>
        <div>
          <span class="lvs-title">규정 만족도 조사</span>
          <span class="lvs-sum" id="lvsSum"></span>
        </div>
        <div class="lvs-form">
          <span id="lvsStars" role="radiogroup" aria-label="별점 선택"><span class="lvs-star" data-v="1">&#9733;</span><span class="lvs-star" data-v="2">&#9733;</span><span class="lvs-star" data-v="3">&#9733;</span><span class="lvs-star" data-v="4">&#9733;</span><span class="lvs-star" data-v="5">&#9733;</span></span>
          <textarea id="lvsCn" maxlength="1000" placeholder="의견 (선택, 1000자 이내)"></textarea>
          <button type="button" class="krds-btn primary small" id="lvsSaveBtn" onclick="lvStsfdgSave()">등록</button>
          <button type="button" class="krds-btn small" id="lvsDelBtn" onclick="lvStsfdgDelete()" style="display:none;">참여 취소</button>
        </div>
        <div class="lvs-msg" id="lvsMsg" aria-live="polite"></div>
        <ul class="lvs-list" id="lvsList"></ul>
      </section>
      </c:if>
    </main>

    <!-- 우측 소관부서 / 관련컨텐츠 -->
    <aside class="lawview-right">
      <div class="lv-side dept">
        <div class="lvs-head">소관부서</div>
        <div class="lvs-body"><c:choose><c:when test="${not empty prom.buseoNm}"><c:out value="${prom.buseoNm}"/></c:when><c:otherwise><span class="muted">미지정</span></c:otherwise></c:choose></div>
      </div>
      <div class="lv-side cont">
        <div class="lvs-head">관련컨텐츠</div>
        <div class="lvs-body" id="lvRelBox"><span class="muted">불러오는 중…</span></div>
      </div>
    </aside>
  </div>

  <!-- 조문정보관리 / 메모 팝업 -->
  <div id="lvModal" onclick="if(event.target===this)lvClose()">
    <div class="lvm-box">
      <div class="lvm-head"><span>조문 정보 관리</span><button type="button" class="lvm-x" onclick="lvClose()">&times;</button></div>
      <div class="lvm-body" id="lvmBody"></div>
    </div>
  </div>

  <%-- 관련자료 WORD 자체변환 본문 미리보기 모달 (.docx/.hwpx) --%>
  <div id="lvDocModal" onclick="if(event.target===this)lvDocClose()">
    <div class="lvd-box">
      <div class="lvd-head">
        <span id="lvDocTitle">문서</span>
        <span class="lvd-head-r"><span id="lvDocDl"></span><button type="button" class="lvm-x" onclick="lvDocClose()">&times;</button></span>
      </div>
      <div class="lvd-body" id="lvDocBody"></div>
    </div>
  </div>

  <%-- 본문저장 옵션 모달 (2026-07-30) — 인쇄 옵션과 같은 범위 선택 + 파일 형식.
       조 단위 부분 저장은 서버가 렌더된 전문에서 해당 구간만 잘라 문서를 만든다(exportProm.do fromJo/toJo). --%>
  <div id="lvExportModal" class="lvp-modal" onclick="if(event.target===this)lvCloseExport()">
    <div class="lvp-box">
      <div class="lvp-head"><span>본문저장</span><button type="button" class="lvm-x" onclick="lvCloseExport()">&times;</button></div>
      <div class="lvp-body">
        <div class="lvp-row"><b>저장 범위</b>
          <label><input type="radio" name="lvxScope" value="all" checked onchange="lvExportScope()"> 전체</label>
          <label><input type="radio" name="lvxScope" value="part" onchange="lvExportScope()"> 부분(조 단위)</label>
        </div>
        <div class="lvp-row" id="lvxRangeRow" style="display:none">
          <b>범위 선택</b>
          <select id="lvxFrom" class="lvp-sel"></select> 부터
          <select id="lvxTo" class="lvp-sel"></select> 까지
        </div>
        <div class="lvp-row"><b>파일 형식</b>
          <label><input type="radio" name="lvxFmt" value="pdf" checked> PDF (.pdf)</label>
          <label><input type="radio" name="lvxFmt" value="docx"> Word (.docx)</label>
          <label><input type="radio" name="lvxFmt" value="hwpx"> 한글 (.hwpx)</label>
        </div>
        <div class="lvp-row" id="lvxPartNote" style="display:none">
          <span class="lvp-note">부분 저장에는 서문·부칙·별표가 포함되지 않습니다.</span>
        </div>
        <div class="lvp-act">
          <button type="button" class="lvp-cancel" onclick="lvCloseExport()">취소</button>
          <button type="button" class="lvm-save" onclick="lvDoExport()">저장</button>
        </div>
      </div>
    </div>
  </div>

  <%-- 인쇄 옵션 모달 (레거시 fulltext_print_option 이식 — IE ActiveX → 표준 window.print) --%>
  <div id="lvPrintModal" class="lvp-modal" onclick="if(event.target===this)lvClosePrint()">
    <div class="lvp-box">
      <div class="lvp-head"><span>인쇄하기</span><button type="button" class="lvm-x" onclick="lvClosePrint()">&times;</button></div>
      <div class="lvp-body">
        <div class="lvp-row"><b>인쇄 범위</b>
          <label><input type="radio" name="lvpScope" value="all" checked onchange="lvPrintScope()"> 전체</label>
          <label><input type="radio" name="lvpScope" value="part" onchange="lvPrintScope()"> 부분(조 단위)</label>
        </div>
        <div class="lvp-row" id="lvpRangeRow" style="display:none">
          <b>범위 선택</b>
          <select id="lvpFrom" class="lvp-sel"></select> 부터
          <select id="lvpTo" class="lvp-sel"></select> 까지
        </div>
        <div class="lvp-row"><b>글자 크기</b>
          <label><input type="radio" name="lvpSize" value="14pt"> 크게(14pt)</label>
          <label><input type="radio" name="lvpSize" value="12pt" checked> 보통(12pt)</label>
          <label><input type="radio" name="lvpSize" value="10pt"> 작게(10pt)</label>
        </div>
        <div class="lvp-row"><b>인쇄 메모</b><input type="text" id="lvpMemo" class="lvp-memo" placeholder="상단에 출력할 메모 (선택)"></div>
        <div class="lvp-act">
          <button type="button" class="lvp-cancel" onclick="lvClosePrint()">취소</button>
          <button type="button" class="lvm-save" onclick="lvDoPrint()">인쇄</button>
        </div>
      </div>
    </div>
  </div>

  <%-- 신구대조 인페이지 모달 — 직전 회차 대비(diffByPromNo.do)를 헤더리스 iframe 으로 (화면 이동 X) --%>
  <div id="lvCmpModal" onclick="if(event.target===this)lvCmpClose()">
    <div class="lvc-box">
      <div class="lvc-head">
        <span>신구대조 &mdash; 직전 회차 대비</span>
        <span class="lvc-head-r">
          <a id="lvCmpOpen" class="lvc-open" target="_blank" rel="noopener">새 창으로</a>
          <button type="button" class="lvm-x" onclick="lvCmpClose()">&times;</button>
        </span>
      </div>
      <iframe id="lvCmpFrame" class="lvc-frame" title="신구대조 비교 결과"></iframe>
    </div>
  </div>

  <script>
    var LV_CTX='<c:url value="/"/>'.replace(/\/$/,'');
    var LV_PROMNO='${prom.promNo}', LV_LAWID='${prom.lawId}', LV_SYS='${sysId}', LV_PREVNO='${prevPromNo}';
    /* 공개열람(익명) 여부 — 익명이면 개인화(즐겨찾기/메모/만족도) UI 를 걷어내고 해당 fetch 를 건너뛴다.
       (개인화 URL 은 익명 미개방이라 302 로그인 응답 → front 데코의 세션만료 fetch 래퍼가 페이지를
        로그인으로 강제 이동시키는 오동작 방지 — 열람 자체는 익명 허용) */
    var LV_AUTHED=${lvAuthed};

    /* ---- 좌측 규정분류 트리 ---- */
    function lvEsc(s){return (s==null?'':String(s)).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];});}
    function lvBuildNodes(nodes){
      var h='';
      (nodes||[]).forEach(function(nd){
        var d=nd.data||{};
        if(d.promNo!=null && d.promYn!=='N'){   // prommap 폴더는 promNo=0/promYn='N' → 잎 오인 방지(prom 트리는 promYn 없음→영향 없음)
          var on=(String(d.promNo)===String(LV_PROMNO))?' on':'';
          var pend=d.pending?' <span class="lvh-tag" title="공포되었으나 아직 시행 전입니다">시행예정</span>':'';
          <%-- 규정 잎에도 + 토글 — 열지 않은 규정도 개요(장→조·부칙·별표)를 펼쳐볼 수 있게(lvLawTogClick) --%>
          h+='<li class="t-prom"><span class="t-tog" onclick="lvLawTogClick(this)" title="조문 개요 펼치기/접기">+</span><a class="t-prom'+on+'" href="'+LV_CTX+'/rlms/fulltext/provisionList.do?promNo='+d.promNo+'">'+lvEsc(nd.text)+pend+'</a></li>';
        } else {
          var cls=(nd.type==='gubun')?'t-gubun':'t-cate';
          var kids=nd.children&&nd.children.length?('<ul>'+lvBuildNodes(nd.children)+'</ul>'):'';
          <%-- 기본 접힘(+) — 이전엔 조건이 'block':'block' 으로 전 트리(3천+ 규정)가 항상 펼쳐져
               렌더/토글 부담이 컸음(2026-07-09 교정). 현재 규정 경로는 로드 후 lvExpandToCurrent 가 펼침. --%>
          h+='<li class="'+cls+'"><span class="t-tog" onclick="lvTog(this)">+</span><span class="t-label">'+lvEsc(nd.text)+'</span><div class="t-ch" style="display:none">'+kids+'</div></li>';
        }
      });
      return h;
    }
    function lvTog(sp){
      var ch=sp.parentNode.querySelector('.t-ch'); if(!ch)return;
      var open=ch.style.display!=='none'; ch.style.display=open?'none':'block'; sp.innerHTML=open?'+':'−';
    }
    <%-- 현재 보고 있는 규정의 조상 폴더만 펼침 (기본 접힘 트리에서 위치 노출) --%>
    function lvExpandToCurrent(){
      var cur=document.querySelector('#lvTree a.t-prom.on'); if(!cur)return;
      var li=cur.closest('li');
      while(li && li.id!=='lvTree' && li.nodeType===1){
        var ch=li.querySelector(':scope > .t-ch');
        if(ch){ ch.style.display='block'; var tg=li.querySelector(':scope > .t-tog'); if(tg && tg.getAttribute('onclick'))tg.innerHTML='−'; }
        li = li.parentNode ? li.parentNode.closest('li') : null;
      }
      cur.scrollIntoView({block:'center'});
    }
    function lvLoadTree(url){
      url=url||(LV_CTX+'/rlms/prom/treeJson.do');
      document.getElementById('lvTree').innerHTML='<li class="muted">불러오는 중…</li>';
      fetch(url,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(j){
          document.getElementById('lvTree').innerHTML=lvBuildNodes(j)||'<li class="muted">목록 없음</li>';
          lvExpandToCurrent();
          lvBuildOutline();
        }).catch(function(e){console.error('lvTree', e);document.getElementById('lvTree').innerHTML='<li class="err">규정 분류를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.</li>';});
    }
    <%-- 현재 규정 조문 개요(장→절→조 + 부칙 + 별표/별지서식) — 본문 렌더의 앵커
         (.prov-group/.prov-jo/.prov-postscript/.prov-docu)에서 생성해 현재 규정 노드 아래에 부착.
         장/절 = 토글 폴더(라벨 클릭 = 본문 점프 + 펼침), 조 = 클릭 시 본문 해당 위치로 이동(lvJump).
         부칙·별표/별지서식은 각각 전용 폴더로 묶음(다건이라 최상위 나열 시 어수선). PJAX 전환 시 재생성. 2026-07-24 --%>
    <%-- 본문 요소 → 개요 ul 생성 공용 빌더.
         isCurrent=true : 항목 클릭 = 같은 문서 앵커 점프(lvJump)
         isCurrent=false: 항목 클릭 = 그 규정으로 PJAX 이동 + 앵커 점프(위임 핸들러가 처리)
         비어 있으면 null. --%>
    function lvOutlineFromBody(body,promNo,isCurrent){
      var items=body.querySelectorAll('.prov-group[id],.prov-jo[id],.prov-postscript[id],.prov-docu[id]');
      if(!items.length)return null;
      var root=document.createElement('ul');root.className='lv-outline';
      var stack=[{ind:-1,ul:root}];
      var psUl=null,docuUl=null;   /* 부칙 / 별표·별지서식 폴더 (첫 항목에서 생성 — 문서 순서 위치 유지) */
      function jumpHref(id){return isCurrent?('#'+id):(LV_CTX+'/rlms/fulltext/provisionList.do?promNo='+promNo+'#'+id);}
      function wireJump(a,id){
        if(isCurrent){ a.onclick=(function(x){return function(e){e.preventDefault();lvJump(x);};})(id); }
        /* 비현재 규정 = href 그대로 두면 위임 PJAX 핸들러가 이동+점프 처리 */
      }
      function mkFolder(name){
        var li=document.createElement('li');
        var tog=document.createElement('span');tog.className='t-tog';tog.textContent='+';
        var b=document.createElement('a');b.href='#';b.className='lv-ol-grp';b.textContent=name;
        var ch=document.createElement('ul');ch.style.display='none';
        var flip=function(e){if(e)e.preventDefault();var open=ch.style.display!=='none';ch.style.display=open?'none':'block';tog.textContent=open?'+':'−';};
        tog.onclick=flip; b.onclick=flip;
        li.appendChild(tog);li.appendChild(b);li.appendChild(ch);
        root.appendChild(li);
        return ch;
      }
      function mkJump(lab,id,ul){
        var li=document.createElement('li');
        var a=document.createElement('a');a.href=jumpHref(id);a.className='lv-ol-jo';a.textContent=lab;
        wireJump(a,id);
        li.appendChild(a);ul.appendChild(li);
      }
      items.forEach(function(el){
        var isJo=el.classList.contains('prov-jo'),isPs=el.classList.contains('prov-postscript'),
            isDocu=el.classList.contains('prov-docu');
        var ind=parseInt(el.style.marginLeft||'0',10)||0;
        var lab=(((isJo||isDocu)?el.querySelector('.prov-jo-label'):el.querySelector('b'))||el).textContent.replace(/\s+/g,' ').trim().slice(0,42);
        if(!lab)return;
        if(isPs){
          if(!psUl)psUl=mkFolder('부칙');
          mkJump(lab.replace(/^\[부칙\]\s*/,''),el.id,psUl);
        }else if(isDocu){
          if(!docuUl)docuUl=mkFolder('별표/별지서식');
          mkJump(lab,el.id,docuUl);
        }else if(isJo){
          mkJump(lab,el.id,stack[stack.length-1].ul);
        }else{
          while(stack.length>1&&ind<=stack[stack.length-1].ind)stack.pop();
          var li=document.createElement('li');
          var a=document.createElement('a');a.href=jumpHref(el.id);a.className='lv-ol-grp';a.textContent=lab;
          var tog=document.createElement('span');tog.className='t-tog';tog.textContent='+';
          var ch=document.createElement('ul');ch.style.display='none';
          tog.onclick=function(){var open=ch.style.display!=='none';ch.style.display=open?'none':'block';tog.textContent=open?'+':'−';};
          if(isCurrent){
            a.onclick=(function(id){return function(e){e.preventDefault();lvJump(id);ch.style.display='block';tog.textContent='−';};})(el.id);
          }
          li.appendChild(tog);li.appendChild(a);li.appendChild(ch);
          stack[stack.length-1].ul.appendChild(li);
          stack.push({ind:ind,ul:ch});
        }
      });
      /* 하위 조가 없는 장/절 — 토글 대신 점(·) 표시 (빈 폴더 펼침 방지) */
      root.querySelectorAll('li > ul').forEach(function(u){
        if(!u.children.length){
          var t=u.parentNode.querySelector('.t-tog'); if(t){t.textContent='·';t.onclick=null;}
          u.parentNode.removeChild(u);
        }
      });
      return root;
    }
    <%-- 현재 규정 개요 자동 생성 — 렌더된 본문(#lvBody)에서. PJAX 전환 시 재생성(cur 마커만 정리 —
         사용자가 +로 펼쳐둔 다른 규정 개요는 보존, 링크가 PJAX href 라 그대로 유효). --%>
    function lvBuildOutline(){
      document.querySelectorAll('#lvTree ul.lv-outline.cur').forEach(function(u){
        var tg=u.parentNode.querySelector(':scope > .t-tog');
        if(tg)tg.textContent='+';
        u.parentNode.removeChild(u);
      });
      var cur=document.querySelector('#lvTree a.t-prom.on'), body=document.getElementById('lvBody');
      if(!cur||!body)return;
      var host=cur.closest('li');
      var old=host.querySelector(':scope > ul.lv-outline');   /* +로 미리 펼쳐뒀던 개요 → 현재용(lvJump)으로 교체 */
      if(old)old.parentNode.removeChild(old);
      var root=lvOutlineFromBody(body,String(LV_PROMNO),true);
      var htg=host.querySelector(':scope > .t-tog');
      if(!root){ if(htg)htg.textContent='·'; return; }
      root.classList.add('cur');
      host.appendChild(root);
      if(htg)htg.textContent='−';   /* 접기/펼치기는 공용 lvLawTogClick 이 처리 */
    }
    <%-- 규정 잎 + 토글 — 개요가 있으면 접기/펼치기, 없으면(다른 규정) 그 규정 페이지를 XHR 로 받아
         본문에서 개요를 만들어 부착(캐시). 항목 클릭 = 그 규정으로 이동 + 조문 점프. 2026-07-24 --%>
    function lvLawTogClick(tg){
      var li=tg.parentNode;
      var ol=li.querySelector(':scope > ul.lv-outline');
      if(ol){
        var open=ol.style.display!=='none';
        ol.style.display=open?'none':'block';
        tg.textContent=open?'+':'−';
        return;
      }
      if(tg.textContent==='…'||tg.textContent==='·')return;   /* 로딩 중/빈 규정 */
      var a=li.querySelector(':scope > a.t-prom'); if(!a)return;
      var m=(a.getAttribute('href')||'').match(/promNo=(\d+)/); if(!m)return;
      tg.textContent='…';
      fetch(a.href,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.text();})
        .then(function(html){
          var doc=new DOMParser().parseFromString(html,'text/html');
          var b=doc.getElementById('lvBody');
          var ul=b?lvOutlineFromBody(b,m[1],false):null;
          if(!ul){tg.textContent='·';return;}   /* 본문 없음/열람불가 — 펼칠 개요 없음 */
          li.appendChild(ul);
          tg.textContent='−';
        }).catch(function(){tg.textContent='+';});
    }
    function lvTreeFilter(q){
      q=(q||'').trim();
      var tree=document.getElementById('lvTree'); if(!tree)return;
      var old=document.getElementById('lvTreeNoRes'); if(old&&old.parentNode)old.parentNode.removeChild(old);
      var allLi=tree.querySelectorAll('li');
      if(!q){ allLi.forEach(function(li){li.style.display='';}); return; }
      // 1) 전부 숨김 → 2) 매칭 규정 잎 + 그 조상 폴더만 펼쳐 표시 (빈 폴더 잔존/미클릭 버그 해소)
      // ★공백 무시 정규화(2026-07-24) — 규정명이 "국제 자본 …"처럼 띄어 쓰여도 "국제자본"으로 검색되게.
      var norm=function(s){return (s||'').toLowerCase().replace(/\s+/g,'');};
      var ql=norm(q);
      allLi.forEach(function(li){li.style.display='none';});
      var matched=0;
      var showChain=function(li){
        while(li && li!==tree && li.nodeType===1){
          li.style.display='';
          var ch=li.querySelector(':scope > .t-ch');
          if(ch){ ch.style.display='block'; var tg=li.querySelector(':scope > .t-tog'); if(tg && tg.getAttribute('onclick'))tg.innerHTML='−'; }
          li = li.parentNode ? li.parentNode.closest('li') : null;
        }
      };
      tree.querySelectorAll('a.t-prom').forEach(function(a){
        if(norm(a.textContent).indexOf(ql)<0)return;
        matched++;
        showChain(a.closest('li'));
      });
      // ★분류(폴더)명 매칭(2026-07-24) — 검색어가 분류명이면 그 분류 하위 전체(하위분류+규정)를 펼쳐 표시
      tree.querySelectorAll('.t-label').forEach(function(lb){
        if(norm(lb.textContent).indexOf(ql)<0)return;
        matched++;
        var li=lb.closest('li');
        showChain(li);
        li.querySelectorAll('li').forEach(function(d){d.style.display='';});
        li.querySelectorAll('.t-ch').forEach(function(c){c.style.display='block';});
        li.querySelectorAll('.t-tog').forEach(function(t){if(t.getAttribute('onclick'))t.innerHTML='−';});
      });
      // ★조문 개요 매칭(2026-07-24) — 현재 보는 규정의 장/조/부칙/별표 라벨도 검색.
      //   매칭 항목의 개요 내부 체인(접힌 장 폴더 포함)을 펼쳐 표시 → 클릭하면 본문 해당 위치로 점프.
      tree.querySelectorAll('ul.lv-outline a').forEach(function(a){
        if(norm(a.textContent).indexOf(ql)<0)return;
        matched++;
        var p=a.closest('li');
        // 매칭이 장/부칙/별표 폴더면 하위 전체도 표시
        var chUl=p.querySelector(':scope > ul');
        if(chUl){
          chUl.style.display='block';
          var t2=p.querySelector(':scope > .t-tog'); if(t2&&t2.textContent!=='·')t2.textContent='−';
          chUl.querySelectorAll('li').forEach(function(d){d.style.display='';});
        }
        while(p && !(p.classList&&p.classList.contains('t-prom'))){
          if(p.tagName==='LI'){ p.style.display=''; }
          else if(p.tagName==='UL'&&p.style.display==='none'){
            p.style.display='block';
            var tg=(p.parentNode&&p.parentNode.querySelector)?p.parentNode.querySelector(':scope > .t-tog'):null;
            if(tg&&tg.textContent!=='·')tg.textContent='−';
          }
          p=p.parentNode;
        }
        if(p)showChain(p);   // 현재 규정 잎 + 그 조상 분류 폴더 표시
      });
      if(matched===0){ tree.insertAdjacentHTML('beforeend','<li id="lvTreeNoRes" class="muted">검색 결과가 없습니다.</li>'); }
    }
    <%-- 빠른검색 입력 핸들러 — 로컬 트리 필터(즉시) + 전 규정 조문/별표 제목 서버검색(300ms 디바운스).
         서버검색은 현행 회차 기준 누적 제목 LIKE(공백 무시) — 트리를 펼치지 않아도 전 규정에서 검색됨. --%>
    var lvQsTimer=null;
    function lvQuickInput(v){
      lvTreeFilter(v);
      if(lvQsTimer){clearTimeout(lvQsTimer);lvQsTimer=null;}
      var q=(v||'').trim();
      var box=document.getElementById('lvQsBox');
      if(q.replace(/\s+/g,'').length<2){ if(box){box.style.display='none';box.innerHTML='';} return; }
      lvQsTimer=setTimeout(function(){ lvQuickRemote(q); },300);
    }
    function lvQuickRemote(q){
      fetch(LV_CTX+'/rlms/fulltext/quickSearchJson.do?q='+encodeURIComponent(q),{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(j){
          var box=document.getElementById('lvQsBox'); if(!box)return;
          // 늦게 도착한 응답이 비워진 검색창을 덮지 않게 — 현재 입력과 대조
          var curQ=(document.getElementById('lvQuick').value||'').trim();
          if(curQ.replace(/\s+/g,'').length<2){box.style.display='none';box.innerHTML='';return;}
          var list=(j&&j.list)||[];
          if(!list.length){box.style.display='none';box.innerHTML='';return;}
          var h='<div class="lvqs-head">조문·별표 검색 결과 ('+list.length+')</div>';
          list.forEach(function(r){
            var anc='',label='';
            if(r.src==='JO'){
              var jo=parseInt(r.item,10)||0, sb=parseInt(r.subItem,10)||0;
              anc='jo-'+jo+(sb>0?('-'+sb):'');
              label='제'+jo+'조'+(sb>0?('의'+sb):'')+(r.title?('('+r.title+')'):'');
            }else if(r.src==='PHTML'){
              var it=String(r.item||'').trim();
              var jo2=parseInt(it.substring(0,4),10)||0, sb2=parseInt(it.substring(4,6),10)||0;
              anc='phtml-'+r.anchorNo;
              label='제'+jo2+'조'+(sb2>0?('의'+sb2):'')+(r.title?('('+r.title+')'):'');
            }else{
              anc='docu-'+r.anchorNo;
              label=r.title||'';
            }
            h+='<a href="'+LV_CTX+'/rlms/fulltext/provisionList.do?promNo='+r.promNo+'#'+anc+'">'
              +'<b>'+lvEsc(r.lawTitle||'')+'</b> — '+lvEsc(label)+'</a>';
          });
          box.innerHTML=h; box.style.display='block';
        }).catch(function(){});
    }
    var lvCurTab='jeon';
    function lvTab(t){
      if(t===lvCurTab)return;
      lvCurTab=t;
      document.querySelectorAll('.lv-tab').forEach(function(x){x.classList.toggle('on',x.getAttribute('data-tab')===t);});
      // 전문분류=규정 분류트리(/rlms/prom) · 부서별=소관부서 그룹(deptTreeJson) · 기능별분류=규정맵(/rlms/prommap).
      // 읽기전용 — 잎 클릭 시 PJAX 전문뷰어. 단일 시스템이라 sysId(SSYS_ID) 필터 안 씀.
      if(t==='func'){
        lvLoadTree(LV_CTX+'/rlms/prommap/treeJson.do');
      }else if(t==='dept'){
        lvLoadTree(LV_CTX+'/rlms/prom/treeJsonDept.do');
      }else{
        lvLoadTree(LV_CTX+'/rlms/prom/treeJson.do');
      }
    }

    /* ---- 연혁 목록 펼치기 ---- */
    var lvHistLoaded=false;
    function lvHistToggle(){
      var b=document.getElementById('lvHistBody'),hd=document.querySelector('.lvh-head .arr');
      var open=b.classList.toggle('open'); hd.innerHTML=open?'&#9660;':'&#9654;';
      if(open&&!lvHistLoaded){lvHistLoaded=true;lvLoadHist();}
    }
    var lvHistData={};
    function lvLoadHist(){
      fetch(LV_CTX+'/rlms/prom/historyJson.do?lawId='+LV_LAWID,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(j){
          var vers=(j&&j[0]&&j[0].children)?j[0].children:[];
          document.getElementById('lvHistCnt').textContent='('+vers.length+'건)';
          if(!vers.length){document.getElementById('lvHistBody').innerHTML='<span class="muted">연혁 없음</span>';return;}
          lvHistData={};
          var h='';
          vers.forEach(function(v){
            var d=v.data||{}; var cur=(String(d.promNo)===String(LV_PROMNO));
            lvHistData[d.promNo]={title:d.title,gaejungNm:d.gaejungNm,promDate:d.promDate,startDate:d.startDate,reason:d.reason,gaejung:d.gaejung};
            h+='<div class="lvh-item">'+(d.promDate?d.promDate+' ':'')+
               '<a href="'+LV_CTX+'/rlms/fulltext/provisionList.do?promNo='+d.promNo+'" class="'+(cur?'lvh-cur':'')+'">'+lvEsc(d.gaejungNm||d.title||('회차 '+d.promNo))+'</a>'+
               (cur?'<span class="lvh-tag">현재</span>':'')+
               (d.pending?'<span class="lvh-tag" title="공포되었으나 아직 시행 전입니다">시행예정</span>':'')+
               ' <button type="button" class="lvh-gj-btn" onclick="lvOpenGaejung(\''+d.promNo+'\')">개정문</button>'+
               '</div>';
          });
          document.getElementById('lvHistBody').innerHTML=h;
        }).catch(function(e){console.error('lvHist', e);document.getElementById('lvHistBody').innerHTML='<span class="lv-err">연혁을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.</span>';});
    }
    /* 개정문 보기 — 회차의 개정구분/개정일자/시행일자 + 개정이유·주요내용·부칙·서문 (레거시 frontGaejungView 이식).
       reason/gaejung/bylaw/preamble 은 관리자 작성 CLOB(HTML) — 그대로 렌더, 빈 값은 폴백.
       부칙·서문 CLOB 은 historyJson 경량 유지를 위해 단건 gaejungJson.do 로 지연 로드. */
    function lvGjText(v){ return (v==null||String(v).replace(/<[^>]*>/g,'').replace(/&nbsp;|\s/g,'').trim()==='')?'<span class="muted">(등록된 내용 없음)</span>':String(v); }
    function lvOpenGaejungCurrent(){ lvOpenGaejung(LV_PROMNO); }
    function lvOpenGaejung(promNo){
      if(!promNo){return;}
      document.getElementById('lvDocTitle').textContent='개정문';
      document.getElementById('lvDocDl').innerHTML='';
      document.getElementById('lvDocBody').innerHTML='<div class="muted" style="padding:8px">불러오는 중…</div>';
      document.getElementById('lvDocModal').style.display='block';
      fetch(LV_CTX+'/rlms/prom/gaejungJson.do?promNo='+encodeURIComponent(promNo),{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(d){
          if(!d||!d.ok){document.getElementById('lvDocBody').innerHTML='<div class="lv-err" style="padding:8px">개정문을 불러올 수 없습니다.</div>';return;}
          var rows=''
            +'<tr><th>개정구분</th><td>'+lvEsc(d.gaejungNm||'-')+'</td></tr>'
            +'<tr><th>개정일자(공포)</th><td>'+lvEsc(d.promDate||'-')+'</td></tr>'
            +'<tr><th>시행일자</th><td>'+lvEsc(d.startDate||'-')+'</td></tr>'
            +'<tr><th>개정이유</th><td class="lvg-cell">'+lvGjText(d.reason)+'</td></tr>'
            +'<tr><th>주요내용</th><td class="lvg-cell">'+lvGjText(d.gaejung)+'</td></tr>'
            +'<tr><th>부칙</th><td class="lvg-cell">'+lvGjText(d.bylaw)+'</td></tr>'
            +'<tr><th>서문</th><td class="lvg-cell">'+lvGjText(d.preamble)+'</td></tr>';
          document.getElementById('lvDocTitle').textContent='개정문 — '+(d.gaejungNm||d.title||('회차 '+promNo));
          document.getElementById('lvDocBody').innerHTML='<table class="lvg-table">'+rows+'</table>';
        }).catch(function(){document.getElementById('lvDocBody').innerHTML='<div class="lv-err" style="padding:8px">개정문을 불러올 수 없습니다.</div>';});
    }
    /* 신구대조 — 직전 회차 대비를 인페이지 iframe 모달로 (전체 페이지 이동 X, 헤더리스 popup 데코) */
    function lvOpenCompare(){
      if(!LV_PREVNO){return;}
      var url=LV_CTX+'/rlms/prom/diffByPromNo.do?leftPromNo='+encodeURIComponent(LV_PREVNO)+'&rightPromNo='+encodeURIComponent(LV_PROMNO);
      document.getElementById('lvCmpFrame').src=url;
      document.getElementById('lvCmpOpen').href=url;
      document.getElementById('lvCmpModal').style.display='block';
    }
    function lvCmpClose(){
      document.getElementById('lvCmpModal').style.display='none';
      document.getElementById('lvCmpFrame').src='about:blank';   // iframe 정리(다음 회차 비교 시 갱신)
    }

    /* 내보내기 드롭다운 토글 + 인쇄 옵션 ------------------------------------------------- */
    function lvToggleMenu(ev,id){
      if(ev){ev.stopPropagation();}
      var m=document.getElementById(id),open=m&&m.classList.contains('open');
      document.querySelectorAll('.lvt-menu.open').forEach(function(x){x.classList.remove('open');});
      if(m&&!open)m.classList.add('open');
    }
    document.addEventListener('click',function(){document.querySelectorAll('.lvt-menu.open').forEach(function(x){x.classList.remove('open');});});
    function lvClosePrint(){document.getElementById('lvPrintModal').style.display='none';}

    /* ── 본문저장 옵션 (2026-07-30 고객 요청 "조문별 저장 — 인쇄기능에 있는 내용 적용") ──
       인쇄와 같은 조 목록·같은 범위 규칙을 쓰고, 실제 문서 생성은 서버(exportProm.do)가 한다. */
    var LV_EXPORT_URL = '<c:url value="/rlms/fulltext/exportProm.do"/>?promNo=${prom.promNo}';
    function lvCloseExport(){document.getElementById('lvExportModal').style.display='none';}
    function lvExportScope(){
      var part=document.querySelector('input[name=lvxScope]:checked').value==='part';
      document.getElementById('lvxRangeRow').style.display=part?'flex':'none';
      document.getElementById('lvxPartNote').style.display=part?'flex':'none';
    }
    function lvOpenExport(){
      var jos=lvPrintJoEls();
      var fromSel=document.getElementById('lvxFrom'),toSel=document.getElementById('lvxTo');
      fromSel.innerHTML='';toSel.innerHTML='';
      jos.forEach(function(jo){
        var lab=(jo.querySelector('.prov-jo-label')||jo).textContent.replace(/\s+/g,' ').trim().slice(0,40);
        var opt='<option value="'+lvEsc(jo.id)+'">'+lvEsc(lab)+'</option>';
        fromSel.insertAdjacentHTML('beforeend',opt);
        toSel.insertAdjacentHTML('beforeend',opt);
      });
      if(jos.length){toSel.value=jos[jos.length-1].id;}
      /* 부분 저장은 조 본문(VERSION)일 때만 의미 — 조가 없으면 전체로 고정 */
      var partRadio=document.querySelector('input[name=lvxScope][value=part]');
      partRadio.disabled=!jos.length;
      document.querySelector('input[name=lvxScope][value=all]').checked=true;
      lvExportScope();
      document.getElementById('lvExportModal').style.display='block';
    }
    function lvDoExport(){
      var fmt=(document.querySelector('input[name=lvxFmt]:checked')||{}).value||'pdf';
      var scope=(document.querySelector('input[name=lvxScope]:checked')||{}).value||'all';
      var url=LV_EXPORT_URL+'&format='+encodeURIComponent(fmt);
      if(scope==='part'){
        var from=document.getElementById('lvxFrom').value, to=document.getElementById('lvxTo').value;
        if(!from){alert('저장할 조 범위를 선택하세요.');return;}
        /* 화면 순서 기준으로 앞뒤가 뒤집혀 선택돼도 정상 동작하도록 정렬(인쇄와 동일) */
        var ids=lvPrintJoEls().map(function(j){return j.id;});
        if(ids.indexOf(to)>=0 && ids.indexOf(from)>ids.indexOf(to)){var t=from;from=to;to=t;}
        url+='&fromJo='+encodeURIComponent(from)+'&toJo='+encodeURIComponent(to);
      }
      lvCloseExport();
      location.href=url;
    }
    function lvPrintScope(){
      var part=document.querySelector('input[name=lvpScope]:checked').value==='part';
      document.getElementById('lvpRangeRow').style.display=part?'flex':'none';
    }
    /* 인쇄 옵션 열기 — 본문의 조(.prov-jo) 목록으로 부분인쇄 범위 콤보 채움 */
    function lvPrintJoEls(){return Array.prototype.slice.call(document.querySelectorAll('#lvBody .prov-jo'));}
    function lvOpenPrint(){
      var body=document.getElementById('lvBody');
      var jos=lvPrintJoEls();
      var partOk=!!body && jos.length>0;
      var fromSel=document.getElementById('lvpFrom'),toSel=document.getElementById('lvpTo');
      fromSel.innerHTML='';toSel.innerHTML='';
      jos.forEach(function(jo,i){
        var lab=(jo.querySelector('.prov-jo-label')||jo).textContent.replace(/\s+/g,' ').trim().slice(0,40);
        fromSel.insertAdjacentHTML('beforeend','<option value="'+i+'">'+lvEsc(lab)+'</option>');
        toSel.insertAdjacentHTML('beforeend','<option value="'+i+'">'+lvEsc(lab)+'</option>');
      });
      if(jos.length){toSel.value=String(jos.length-1);}
      // 부분인쇄는 조 본문(VERSION)일 때만 의미 — 조가 없으면 전체로 고정
      var partRadio=document.querySelector('input[name=lvpScope][value=part]');
      partRadio.disabled=!partOk;
      document.querySelector('input[name=lvpScope][value=all]').checked=true;
      lvPrintScope();
      document.getElementById('lvpMemo').value='';
      document.getElementById('lvPrintModal').style.display='block';
    }
    /* 실제 인쇄 — 글자크기/부분범위/메모 적용 → window.print → 원복 (레거시 인쇄옵션 동선) */
    function lvDoPrint(){
      var size=(document.querySelector('input[name=lvpSize]:checked')||{}).value||'12pt';
      var scope=(document.querySelector('input[name=lvpScope]:checked')||{}).value||'all';
      var memo=document.getElementById('lvpMemo').value.trim();
      var body=document.getElementById('lvBody');
      var hdr=document.getElementById('lvPrintHeader');
      var hidden=[];
      if(body){
        body.style.fontSize=size;
        if(scope==='part'){
          var jos=lvPrintJoEls();
          var from=parseInt(document.getElementById('lvpFrom').value,10)||0;
          var to=parseInt(document.getElementById('lvpTo').value,10)||0;
          if(to<from){var t=from;from=to;to=t;}
          var fromEl=jos[from], toEl=jos[to];
          var doc=body.querySelector('.prov-doc');
          if(doc&&fromEl){
            // 시작 조 이전 형제 + 종료 조 다음 조부터 끝까지 숨김(같은 조의 항/호는 형제로 이어짐)
            var kids=Array.prototype.slice.call(doc.children);
            var endBoundary=null,seenTo=false;
            for(var k=0;k<kids.length;k++){ if(kids[k]===toEl){ // toEl 다음 .prov-jo 가 종료 경계
                for(var n=k+1;n<kids.length;n++){ if(kids[n].classList.contains('prov-jo')){endBoundary=kids[n];break;} }
                break; } }
            var on=false;
            kids.forEach(function(c){
              if(c===fromEl)on=true;
              if(endBoundary&&c===endBoundary)on=false;
              if(!on){c.style.display='none';hidden.push(c);}
            });
          }
        }
      }
      if(hdr){
        hdr.textContent=(memo?memo+'\n':'')+'인쇄일시: '+new Date().toLocaleString('ko-KR');
      }
      window.print();
      // 원복
      setTimeout(function(){
        if(body)body.style.fontSize='';
        hidden.forEach(function(c){c.style.display='';});
        if(hdr)hdr.textContent='';
      },200);
      lvClosePrint();
    }

    /* ---- 우측 관련컨텐츠 ----
       relatedListJson 응답 = {groups:[{cateTitle, items:[{relVrsnNo, kind, title, url}]}]}.
       첨부형(kind=file/orgn/image/word)은 attNo 가 응답에 없어 클릭 시 relDetail 로 2단계 해석. */
    function lvLoadRel(){
      fetch(LV_CTX+'/rlms/prom/relatedListJson.do?promNo='+LV_PROMNO+'&cumulative=Y',{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(j){
          var groups=(j&&j.groups)||[];
          var box=document.getElementById('lvRelBox');
          var h='',cnt=0;
          groups.forEach(function(g){
            // 관련컨텐츠 패널 = 레거시 동선: 관련규정연계(dmn)·외부링크(url) 만.
            //   첨부파일(file/word/orgn/image/html)은 규정 자체 자료라 본문/관련파일 영역에 표시 → 패널 제외.
            //   (이관 데이터의 ICTNS_ID 가 행마다 달라 누적중복이 심해 패널이 첨부로 도배되던 문제도 함께 해소)
            var items=(g.items||[]).filter(function(it){return it.kind==='dmn'||it.kind==='url';});
            if(!items.length)return;
            var gh='';
            items.forEach(function(it){
              var title=lvEsc(it.title||'(제목 없음)');
              var row;
              var safeUrl=(it.url&&/^(https?:\/\/|\/)/i.test(String(it.url).trim()))?String(it.url).trim():null;   /* javascript: 등 비http 스킴 차단 */
              if(it.kind==='url'&&safeUrl){
                row='<a href="'+lvEsc(safeUrl)+'" target="_blank" rel="noopener">'+title+'</a>';
              } else if(it.kind==='file'||it.kind==='orgn'||it.kind==='image'||it.kind==='word'){
                row='<a href="javascript:void(0)" onclick="lvRelOpen('+it.relVrsnNo+',\''+it.kind+'\')">'+title+'</a>';
              } else if(it.kind==='dmn'){
                /* 관련규정연계 — relDetail 로 대상 회차 해석 후 점프 (1건=새창, 여러 건=하위 목록 펼침) */
                row='<a href="javascript:void(0)" onclick="lvRelOpenDmn('+it.relVrsnNo+',this)" title="연계 규정으로 이동">'+title+'</a>';
              } else {
                row='<span>'+title+'</span>';
              }
              gh+='<div class="lv-rel-row">'+row+'</div>';
              cnt++;
            });
            if(gh){h+=(g.cateTitle?'<div class="lvs-grp">'+lvEsc(g.cateTitle)+'</div>':'')+gh;}
          });
          box.innerHTML=cnt?h:'<span class="muted">관련 컨텐츠가 없습니다</span>';
        }).catch(function(e){document.getElementById('lvRelBox').innerHTML='<span class="lv-err">오류</span>';});
    }
    /* dmn 항목 → 전문뷰어 점프 URL. 서버 해석 targetPromNo + 조문이면 "제N조(의M)" 앵커 */
    function lvDmnUrl(it){
      var u=LV_CTX+'/rlms/fulltext/provisionList.do?promNo='+it.targetPromNo;
      if(it.flag==='PROVISION'){
        var m=/제\s*(\d+)\s*조(?:의\s*(\d+))?/.exec(it.title||'');
        if(m)u+='#jo-'+m[1]+(m[2]?'-'+m[2]:'');
      }
      return u;
    }
    /* 관련규정연계 클릭 — relDetail 2단계 해석. 1건=바로 새창, 여러 건=행 아래 목록 토글.
       더블클릭 레이스 가드: 응답 대기 중 재클릭 무시(busy) + 삽입 직전 중복 재확인 */
    function lvRelOpenDmn(relVrsnNo,a){
      var host=a&&a.parentNode;
      var old=host&&host.querySelector('.lv-dmn-sub');
      if(old){old.parentNode.removeChild(old);return;}
      if(a&&a.getAttribute('data-busy')==='1')return;
      if(a)a.setAttribute('data-busy','1');
      function done(){if(a)a.removeAttribute('data-busy');}
      fetch(LV_CTX+'/rlms/related/relDetail.do?relVrsnNo='+relVrsnNo+'&kind=dmn',{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(j){
          done();
          var items=((j&&j.items)||[]).filter(function(it){return it.targetPromNo;});
          if(!items.length){alert('연계된 규정을 찾을 수 없습니다. (대상 회차 없음)');return;}
          if(items.length===1){window.open(lvDmnUrl(items[0]),'_blank');return;}
          if(host&&host.querySelector('.lv-dmn-sub'))return;
          var h='<div class="lv-dmn-sub">';
          items.forEach(function(it){
            h+='<div><a href="'+lvDmnUrl(it)+'" target="_blank" rel="noopener">'
              +lvEsc(it.title||it.targetPromTitle||'(제목없음)')+'</a>'
              +(it.alwaysLatestYn==='Y'?' <span class="lv-dmn-cur">현행</span>':'')+'</div>';
          });
          h+='</div>';
          if(host){host.insertAdjacentHTML('beforeend',h);}
        }).catch(function(){done();alert('연계 정보를 불러오지 못했습니다.');});
    }
    function lvRelOpen(relVrsnNo,kind){
      fetch(LV_CTX+'/rlms/related/relDetail.do?relVrsnNo='+relVrsnNo+'&kind='+encodeURIComponent(kind),{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(j){
          var it=(j&&j.items&&j.items.length)?j.items[0]:null;
          if(!it){alert('연결된 첨부 파일이 없습니다.');return;}
          /* WORD 자체변환(.docx/.hwpx) 본문이 있으면 인라인 미리보기, 없으면 원본 다운로드 */
          if(kind==='word'&&it.html){lvDocOpen(it);return;}
          if(it.attNo){window.open(LV_CTX+'/rlms/related/attachDownload.do?attNo='+it.attNo,'_blank');}
          else{alert('연결된 첨부 파일이 없습니다.');}
        }).catch(function(){alert('첨부 정보를 불러오지 못했습니다.');});
    }
    /* WORD 변환본문 인라인 모달 — it.html 은 서버 생성(XSS 이스케이프 완료)이라 innerHTML 안전 */
    function lvDocOpen(it){
      document.getElementById('lvDocTitle').textContent=it.title||'문서';
      document.getElementById('lvDocDl').innerHTML=it.attNo
        ? '<a class="lvd-doc-dl" href="'+LV_CTX+'/rlms/related/attachDownload.do?attNo='+it.attNo+'" target="_blank" rel="noopener">원본 다운로드</a>'
        : '';
      document.getElementById('lvDocBody').innerHTML=it.html;
      document.getElementById('lvDocModal').style.display='block';
    }
    function lvDocClose(){document.getElementById('lvDocModal').style.display='none';}

    /* ---- 조문정보관리 팝업 (✎) ---- */
    function lvClose(){document.getElementById('lvModal').style.display='none';}
    document.addEventListener('click',function(e){
      var btn=e.target.closest&&e.target.closest('button.prov-info'); if(!btn)return;
      var host=btn.closest('[id]');   /* .prov-jo — 링크/본문 복사용 앵커 */
      lvOpenInfo(btn.getAttribute('data-fi'),btn.getAttribute('data-jo'),host?host.id:'');
    });
    function lvOpenInfo(fi,jo,anc){
      var b=document.getElementById('lvmBody');
      /* 익명(공개열람) — 개인화(즐겨찾기/메모)는 미노출, 열람성 액션(변경 내역·링크/본문 복사)만 제공 */
      b.innerHTML='<div class="lvm-jo">'+lvEsc(jo)+'</div>'+
        '<button type="button" class="lvm-act" onclick="lvShowChg()">&#128203; 조문 변경 내역</button>'+
        (LV_AUTHED?'<div id="lvFavArea"><button type="button" class="lvm-act" onclick="lvDoFavor()">&#11088; 즐겨찾기 추가</button></div>'+
        '<button type="button" class="lvm-act" onclick="lvShowMemo()">&#128221; 메모</button>':'')+
        (anc?'<button type="button" class="lvm-act" onclick="lvCopyJoLink()">&#128279; 조문 링크 복사</button>'+
             '<button type="button" class="lvm-act" onclick="lvCopyJoBody()">&#10697; 조문 본문 복사</button>':'')+
        '<div id="lvMsg"></div><div id="lvSub"></div>';
      b.setAttribute('data-fi',fi); b.setAttribute('data-jo',jo); b.setAttribute('data-anc',anc||'');
      document.getElementById('lvModal').style.display='block';
      if(LV_AUTHED)lvLoadFavState();   // read-back — 이미 즐겨찾기된 조문이면 상태+삭제 버튼으로 전환
    }
    /* 조문 링크/본문 복사 — ✎ 팝업 액션. 결과는 팝업 내 lvMsg 로 피드백 */
    function lvCopyJoLink(){
      var anc=document.getElementById('lvmBody').getAttribute('data-anc'); if(!anc)return;
      var url=location.origin+LV_CTX+'/rlms/fulltext/provisionList.do?promNo='+LV_PROMNO+'#'+anc;
      lvCopyText(url).then(function(ok){lvMsg(ok?'조문 링크가 복사되었습니다. 붙여넣어 공유하세요.':'복사에 실패했습니다.',ok);});
    }
    function lvCopyJoBody(){
      var anc=document.getElementById('lvmBody').getAttribute('data-anc');
      var el=anc?document.getElementById(anc):null; if(!el)return;
      lvCopyText(lvJoUnitText(el)).then(function(ok){lvMsg(ok?'조문 본문이 복사되었습니다. (항·호 포함)':'복사에 실패했습니다.',ok);});
    }
    function lvCurFi(){return document.getElementById('lvmBody').getAttribute('data-fi');}
    function lvCurJo(){return document.getElementById('lvmBody').getAttribute('data-jo');}
    function lvMsg(t,ok){document.getElementById('lvMsg').innerHTML='<span class="'+(ok?'lv-ok':'lv-err')+'">'+lvEsc(t)+'</span>';}
    /* ---- 즐겨찾기 read-back: 이 조문(SFULL_ITEM)이 내 즐겨찾기에 있는지 ---- */
    function lvLoadFavState(){
      if(!LV_LAWID)return;
      fetch(LV_CTX+'/rlms/favor/selectByLawJson.do?lawId='+LV_LAWID,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(d){
          var list=(d&&d.resultList)?d.resultList:[],fi=lvCurFi(),hit=null;
          for(var i=0;i<list.length;i++){if(list[i].item===fi){hit=list[i];break;}}
          var area=document.getElementById('lvFavArea'); if(!area)return;
          if(hit){
            area.innerHTML='<div class="lvm-fav-on">&#11088; 즐겨찾기됨'
              +(hit.description?' <span class="lvm-fav-desc">'+lvEsc(hit.description)+'</span>':'')
              +' <button type="button" class="lvm-mini" onclick="lvDelFavor('+hit.favorNo+')">삭제</button></div>';
          }
          /* 없으면 기본 [추가] 버튼 유지 */
        }).catch(function(){/* read-back 실패는 무시 — 추가 버튼 폴백 */});
    }
    function lvDelFavor(no){
      lvPost('/rlms/favor/deleteFavor.do',{favorNo:no},'즐겨찾기에서 삭제했습니다.',function(){
        var area=document.getElementById('lvFavArea');
        if(area)area.innerHTML='<button type="button" class="lvm-act" onclick="lvDoFavor()">&#11088; 즐겨찾기 추가</button>';
      });
    }
    function lvShowChg(){
      var s=document.getElementById('lvSub'); s.innerHTML='조회 중…';
      fetch(LV_CTX+'/rlms/prom/provTextHstListJson.do?promNo='+LV_PROMNO,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(rows){
          if(!rows||!rows.length){s.innerHTML='<div class="lv-hist-empty">기록된 변경 작업 이력이 없습니다. (신구대조에서 회차 간 비교 가능)</div>';return;}
          var h='<table class="lv-chg-tbl"><tr><th>일시</th><th>작성자</th></tr>';
          rows.forEach(function(r){h+='<tr><td>'+lvEsc(r.insDt)+'</td><td>'+lvEsc(r.userId)+'</td></tr>';});
          s.innerHTML=h+'</table>';
        }).catch(function(e){console.error('provHst', e);s.innerHTML='<span class="lv-err">변경 내역을 불러오지 못했습니다.</span>';});
    }
    /* ---- 메모: 등록 폼 + 이 조문의 내 메모 목록(read-back, 수정/삭제) ---- */
    function lvShowMemo(){
      document.getElementById('lvSub').innerHTML=
        '<div class="lv-memo-form">'
        +'<select id="lvMemoGubun" class="lv-memo-gubun" title="메모 분류"><option value="USER">개인</option><option value="BUSEO">부서</option></select>'
        +'<textarea id="lvMemoTxt" placeholder="메모 내용"></textarea>'
        +'<button type="button" class="lvm-save" onclick="lvDoMemo()">메모 저장</button></div>'
        +'<ul class="lv-memo-list" id="lvMemoList"><li class="muted">불러오는 중…</li></ul>';
      lvLoadMemos();
    }
    function lvLoadMemos(){
      var ul=document.getElementById('lvMemoList'); if(!ul||!LV_LAWID)return;
      fetch(LV_CTX+'/rlms/memo/selectByLawJson.do?lawId='+LV_LAWID,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();}).then(function(d){
          var all=(d&&d.resultList)?d.resultList:[],fi=lvCurFi(),jo=lvCurJo();
          /* 이 조문 메모 = item 이 조 라벨(신규 형식) 또는 SFULL_ITEM 코드(구 형식) */
          var mine=all.filter(function(m){return m.item===jo||m.item===fi;});
          if(!mine.length){ul.innerHTML='<li class="muted">이 조문에 등록된 내 메모가 없습니다.'+(all.length?' (이 규정 전체 '+all.length+'건)':'')+'</li>';return;}
          ul.innerHTML='';
          mine.forEach(function(m){
            var li=document.createElement('li');
            li.innerHTML='<span class="lv-memo-tag">'+lvEsc(m.gubun==='BUSEO'?'부서':(m.gubun==='USER'?'개인':(m.gubun||'')))+'</span>'
              +'<span class="lv-memo-txt">'+lvEsc(m.contents||'')+'</span> '
              +'<button type="button" class="lvm-mini" data-act="edit">수정</button> '
              +'<button type="button" class="lvm-mini" data-act="del">삭제</button>';
            li.querySelector('[data-act=del]').onclick=function(){
              if(!confirm('이 메모를 삭제하시겠습니까?'))return;
              lvPost('/rlms/memo/deleteMemo.do',{memoNo:m.memoNo},'메모를 삭제했습니다.',lvLoadMemos);
            };
            li.querySelector('[data-act=edit]').onclick=function(){
              li.innerHTML='';
              var ta=document.createElement('textarea');ta.value=m.contents||'';ta.className='lv-memo-edit';
              var sv=document.createElement('button');sv.type='button';sv.className='lvm-mini';sv.textContent='저장';
              var cc=document.createElement('button');cc.type='button';cc.className='lvm-mini';cc.textContent='취소';
              sv.onclick=function(){
                var t=ta.value.trim(); if(!t){lvMsg('메모 내용을 입력하세요.',false);return;}
                lvPost('/rlms/memo/updateMemo.do',{memoNo:m.memoNo,gubun:m.gubun||'USER',item:m.item||'',contents:t},'메모를 수정했습니다.',lvLoadMemos);
              };
              cc.onclick=lvLoadMemos;
              li.appendChild(ta);li.appendChild(sv);li.appendChild(document.createTextNode(' '));li.appendChild(cc);
            };
            ul.appendChild(li);
          });
        }).catch(function(){ul.innerHTML='<li class="muted">메모를 불러오지 못했습니다.</li>';});
    }
    function lvPost(url,params,okMsg,onOk){
      var body=Object.keys(params).map(function(k){return encodeURIComponent(k)+'='+encodeURIComponent(params[k]==null?'':params[k]);}).join('&');
      return fetch(LV_CTX+url,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:body})
        .then(function(r){return r.text();}).then(function(t){
          var j={}; try{j=JSON.parse(t);}catch(e){}
          <%-- 서버 오류 원문(j.error — 예외·SQL 문구 가능)은 화면에 싣지 않음(2026-07-16) --%>
          if(j&&j.ok===false){console.error('lvSave', j.error);lvMsg('저장에 실패했습니다. 잠시 후 다시 시도해 주세요.',false);}
          else{lvMsg(okMsg,true); if(onOk)onOk();}
        }).catch(function(e){console.error('lvSave', e);lvMsg('저장에 실패했습니다. 잠시 후 다시 시도해 주세요.',false);});
    }
    function lvDoFavor(){
      /* gubun=PROVISION — 조문 단위 북마크. favorList '조문' 필터 + 삭제조문 스테일 판정(PROV_DELETED)과 연동
         (기존 'PROM' 전송은 분류 오기록으로 필터 누락 + 스테일 판정 미적용이었음, 2026-07-16 교정) */
      lvPost('/rlms/favor/addFavor.do',{gubun:'PROVISION',lawId:LV_LAWID,sysId:LV_SYS,item:lvCurFi(),description:lvCurJo()},'즐겨찾기에 추가했습니다.',lvLoadFavState);
    }
    function lvDoMemo(){
      var t=document.getElementById('lvMemoTxt').value.trim(); if(!t){lvMsg('메모 내용을 입력하세요.',false);return;}
      var g=(document.getElementById('lvMemoGubun')||{value:'USER'}).value;
      /* item = 조 라벨(사람이 읽는 형식, promDetail 위젯·메모관리 목록과 정합. 구형식 SFULL_ITEM 코드는 조회시 양쪽 매칭) */
      lvPost('/rlms/memo/addMemo.do',{gubun:g,lawId:LV_LAWID,sysId:LV_SYS,item:lvCurJo(),contents:t},'메모를 등록했습니다.',function(){
        document.getElementById('lvMemoTxt').value=''; lvLoadMemos();
      });
    }

    /* ---- 만족도 조사 (연혁 옵션 SSTSFDG_YN='Y' 회차 전용 위젯) ----
       마크업은 #lvMain 안 서버 조건부 렌더 → 함수는 #lvStsfdg 존재시에만 동작(PJAX 후 재호출 안전).
       1인 1회: 목록 응답의 my 로 폼을 프리필하고 버튼을 등록/수정 토글. 렌더는 textContent 만(XSS-safe). */
    var lvsSel=0;
    function lvsPaint(n){document.querySelectorAll('#lvsStars .lvs-star').forEach(function(s){s.classList.toggle('on',+s.getAttribute('data-v')<=n);});}
    function lvLoadStsfdg(){
      var box=document.getElementById('lvStsfdg'); if(!box)return;
      /* 익명(공개열람) — 만족도는 로그인 사용자 참여 기능이라 위젯째 숨김(302 응답 → 래퍼 오동작 방지) */
      if(!LV_AUTHED){box.style.display='none';return;}
      lvsSel=0; lvsPaint(0);        /* 동기 리셋 — PJAX 회차 이동 직후 이전 회차 별점 잔존값으로 저장되는 창 차단 */
      box.querySelectorAll('#lvsStars .lvs-star').forEach(function(s){
        s.onclick=function(){lvsSel=+s.getAttribute('data-v');lvsPaint(lvsSel);};
      });
      var reqPromNo=LV_PROMNO;      /* 응답 순서 가드 — 연혁 연속 클릭 시 늦게 온 이전 회차 응답 폐기 */
      fetch(LV_CTX+'/rlms/fulltext/stsfdgListJson.do?promNo='+reqPromNo,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();})
        .then(function(d){
          if(reqPromNo!==LV_PROMNO)return;
          if(!d.ok){box.style.display='none';return;}
          document.getElementById('lvsSum').textContent='평균 '+(d.avg!=null?d.avg:0)+'점 · '+(d.count!=null?d.count:0)+'명 참여';
          var btn=document.getElementById('lvsSaveBtn'), del=document.getElementById('lvsDelBtn');
          if(d.my){lvsSel=+d.my.stsfdg||0;lvsPaint(lvsSel);document.getElementById('lvsCn').value=d.my.content||'';btn.textContent='내 평가 수정';del.style.display='';}
          else{lvsSel=0;lvsPaint(0);document.getElementById('lvsCn').value='';btn.textContent='등록';del.style.display='none';}
          var ul=document.getElementById('lvsList');ul.innerHTML='';
          if(!d.list||!d.list.length){var li=document.createElement('li');li.className='muted';li.textContent='아직 참여가 없습니다. 이 규정에 대한 첫 의견을 남겨주세요.';ul.appendChild(li);return;}
          d.list.forEach(function(c){
            var li=document.createElement('li');
            var who=document.createElement('span');who.className='who';who.textContent=(c.wrterNm||'사용자')+(c.mine?' (나)':'');
            var st=document.createElement('span');st.className='st';st.textContent='★★★★★'.slice(0,+c.stsfdg||0);
            li.appendChild(who);li.appendChild(st);
            if(c.content){li.appendChild(document.createTextNode(c.content));}
            var dt=document.createElement('span');dt.className='dt';dt.textContent=c.regDt||'';li.appendChild(dt);
            ul.appendChild(li);
          });
        }).catch(function(){box.style.display='none';});
    }
    /* lvMsg 는 조문정보 모달 내부(#lvMsg) 전용이라 위젯에선 못 씀 — 위젯 자체 메시지 라인 사용.
       타이머 핸들 보관 — 동일 문구 연속 표시(저장 2연타)에서 이전 타이머가 새 메시지를 조기 소거하지 않게. */
    var lvsMsgTimer=null;
    function lvsMsg(t,ok){
      var m=document.getElementById('lvsMsg'); if(!m)return;
      if(lvsMsgTimer){clearTimeout(lvsMsgTimer);lvsMsgTimer=null;}
      m.textContent=t; m.className='lvs-msg '+(ok?'ok':'err');
      lvsMsgTimer=setTimeout(function(){lvsMsgTimer=null;m.textContent='';m.className='lvs-msg';},2500);
    }
    function lvsPost(url,params,okMsg){
      var body=Object.keys(params).map(function(k){return encodeURIComponent(k)+'='+encodeURIComponent(params[k]==null?'':params[k]);}).join('&');
      fetch(LV_CTX+url,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:body})
        .then(function(r){return r.json();})
        .then(function(j){
          if(j&&j.login){location.href='<c:url value="/uat/uia/egovLoginUsr.do"/>';return;}
          if(!j||j.ok!==true){lvsMsg(j&&j.message?j.message:'저장에 실패했습니다. 잠시 후 다시 시도해 주세요.',false);return;}
          lvsMsg(okMsg,true); lvLoadStsfdg();
        }).catch(function(){lvsMsg('저장에 실패했습니다. 잠시 후 다시 시도해 주세요.',false);});
    }
    function lvStsfdgSave(){
      if(lvsSel<1){lvsMsg('별점(1~5)을 선택하세요.',false);return;}
      lvsPost('/rlms/fulltext/stsfdgSaveJson.do',{promNo:LV_PROMNO,stsfdg:lvsSel,stsfdgCn:document.getElementById('lvsCn').value},'만족도 평가를 저장했습니다.');
    }
    function lvStsfdgDelete(){
      if(!confirm('내 만족도 평가를 취소할까요?'))return;
      lvsPost('/rlms/fulltext/stsfdgDeleteJson.do',{promNo:LV_PROMNO},'참여를 취소했습니다.');
    }

    /* ---- 조문 점프 / 상호참조 / 화면검색 ---- */
    function lvJump(anc){var el=document.getElementById(anc);if(el){lvEnsureChapOpen(el);lvEnsureDocuOpen(el);el.scrollIntoView({behavior:'smooth',block:'start'});el.style.background='#fff7df';setTimeout(function(){el.style.background='';},900);}}

    <%-- 본문 장 단위 접기(2026-07-24) — 긴 규정(조특법 시행령 등) 무한 스크롤 대책.
         최상위 그룹(장 — 들여쓰기 최소 레벨) 헤더별로 다음 장 전까지를 래퍼로 묶어 접이식으로.
         조문 점프(lvJump — 트리/상호참조/딥링크)와 화면 내 검색은 대상 장을 자동 펼침. 인쇄는 항상 전체.

         ★2026-07-30 고객 요청: "장 전체가 접혀 표시되는 기능은 필요 없음 — 전체 펼치기를 기본값으로".
         접기 UI(장 헤더 토글 + [장 전체 펼치기/접기] 바)는 그대로 두고 **기본 상태만 펼침**으로 바꾼다.
         LV_FOLD_DEFAULT_JO = 0 이면 기본 접힘 비활성(조문 수와 무관하게 항상 펼친 채 시작).
         되돌리려면 임계 조문 수(예전 값 60)를 다시 넣으면 된다. --%>
    var LV_FOLD_DEFAULT_JO = 0;

    <%-- ── 별표/별지서식 — 목록형 접기(9-②) + 개별 첨부(9-③). 고객 요청 2026-07-29 ──
         ② "별표/서식은 접힌 상태로 표시 → 목록만 보이게 → 눌렀을 때 펼쳐지거나"
         ③ "별표/서식은 첨부파일이 개별적으로 필요 → 표시/다운로드"
         첨부 축은 신규 테이블 없이 관련자료 SFLAG='DOCUMENT' + SFULL_ITEM=별표 SITEM 재사용.
         (기존엔 별표 hwp 가 SFLAG='PROMULGATION' 로 규정 전체 자료에 섞여 어느 별표 것인지 알 수 없었다.) --%>
    function lvFmtSize(n){
      n = Number(n) || 0;
      if(n <= 0) return '';
      if(n < 1024) return n + ' B';
      if(n < 1024*1024) return (n/1024).toFixed(1) + ' KB';
      return (n/1024/1024).toFixed(1) + ' MB';
    }
    function lvInitDocuSection(){
      var body=document.getElementById('lvBody'); if(!body)return;
      var sec=body.querySelector('.prov-docu-sec');
      if(!sec||sec.getAttribute('data-docu-init'))return;
      var items=sec.querySelectorAll(':scope > .prov-docu');
      if(!items.length)return;
      sec.setAttribute('data-docu-init','Y');
      items.forEach(function(it){
        var label=it.querySelector('.prov-jo-label'); if(!label)return;
        /* 본문(.prov-body)만 접이 영역으로 옮긴다 — 제목·개정마크는 접힌 상태에서도 보여야 목록 구실을 한다.
           첨부 목록도 이 영역 안에 붙어 함께 펼쳐진다(lvLoadDocuFiles). */
        var wrap=document.createElement('div'); wrap.className='lv-docu-body';
        var b=it.querySelector(':scope > .prov-body');
        if(b) wrap.appendChild(b);
        it.appendChild(wrap);
        var mk=document.createElement('span'); mk.className='lv-docu-mk'; mk.textContent='▸';
        label.insertBefore(mk,label.firstChild);
        label.classList.add('lv-docu-head');
        var set=function(open){ wrap.style.display=open?'':'none'; mk.textContent=open?'▾':'▸'; };
        it._lvDocuSet=set;
        label.addEventListener('click',function(e){
          if(e.target.closest&&e.target.closest('a,button'))return;   /* 자동링크·첨부 링크 클릭은 통과 */
          set(wrap.style.display==='none');
        });
        set(false);   /* 기본 접힘 = "목록만 보이게" */
      });
      lvLoadDocuFiles();
    }
    /* 별표 딥링크(#docu-N)·화면검색이 접힌 별표를 가리키면 자동으로 펼친다 */
    function lvEnsureDocuOpen(el){
      var host=el&&el.closest?el.closest('.prov-docu'):null;
      if(host&&host._lvDocuSet) host._lvDocuSet(true);
    }
    function lvLoadDocuFiles(){
      fetch(LV_CTX+'/rlms/fulltext/docuFilesJson.do?promNo='+encodeURIComponent(LV_PROMNO),
            {credentials:'same-origin',headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.ok?r.json():null;})
        .then(function(j){
          var files=(j&&j.files)||{};
          Object.keys(files).forEach(function(docuNo){
            var host=document.getElementById('docu-'+docuNo); if(!host)return;
            var list=files[docuNo]||[]; if(!list.length)return;
            var h='<div class="lv-docu-files"><b>첨부파일</b><ul>';
            list.forEach(function(f){
              var sz=lvFmtSize(f.fileSize);
              var dc=Number(f.downCnt)||0;   /* TB_ATTACH.IDOWN_CNT — 다운로드 집계 (2026-07-30) */
              h+='<li><a href="'+LV_CTX+'/rlms/related/attachDownload.do?attNo='+encodeURIComponent(f.attNo)+'">'
                +lvEsc(f.title||'파일')+'</a>'
                +'<span class="lv-docu-size">'+(sz?' ('+sz+')':'')
                +' · 다운로드 '+dc+'회</span></li>';
            });
            h+='</ul></div>';
            (host.querySelector('.lv-docu-body')||host).insertAdjacentHTML('beforeend',h);
            /* 접힌 상태에서도 첨부 유무를 알 수 있게 제목 옆에 건수 배지 */
            var label=host.querySelector('.prov-jo-label');
            if(label&&!label.querySelector('.lv-docu-clip')){
              label.insertAdjacentHTML('beforeend',
                ' <span class="lv-docu-clip" title="첨부파일 '+list.length+'건">&#128206;'+list.length+'</span>');
            }
          });
        }).catch(function(){ /* 첨부 조회 실패는 본문 표시를 막지 않는다 */ });
    }

    <%-- 개정주석(<신설 …>/<개정 …>) 표시 스위치 — 선택은 localStorage 유지, 기본은 표시.
         범례도 같이 숨긴다(주석을 껐는데 범례만 남으면 어색). --%>
    function lvRevShown(){ try{ return localStorage.getItem('lvRevShow')!=='N'; }catch(e){ return true; } }
    function lvApplyRev(on){
      var b=document.getElementById('lvBody'); if(b)b.classList.toggle('hide-rev',!on);
      var lg=document.querySelector('.lawview-legend'); if(lg)lg.style.display=on?'':'none';
    }
    <%-- KRDS 토글 스위치 — 정식 마크업은 div.krds-form-toggle-switch > (숨긴 input + label > span.switch-toggle > i).
         input 은 rlms-compat 이 시각적으로 숨기고(포커스는 유지) label 이 스위치를 그린다. --%>
    function lvSwitch(id,text,checked,title){
      var w=document.createElement('div');
      w.className='krds-form-toggle-switch medium';
      if(title)w.title=title;
      var ck=document.createElement('input'); ck.type='checkbox'; ck.id=id; ck.checked=!!checked;
      var lb=document.createElement('label'); lb.setAttribute('for',id);
      var tg=document.createElement('span'); tg.className='switch-toggle'; tg.appendChild(document.createElement('i'));
      lb.appendChild(tg); lb.appendChild(document.createTextNode(text));
      w.appendChild(ck); w.appendChild(lb);
      return w;
    }
    <%-- 본문 상단 바. 개정주석 스위치는 항상, [장 전체 펼치기] 스위치는 장 접기가 적용된 문서에만 뒤에 덧붙인다. --%>
    function lvBodyBar(doc,withChapSw,chapOpen){
      var bar=doc.querySelector(':scope > .lv-chap-bar');
      if(!bar){
        bar=document.createElement('div'); bar.className='lv-chap-bar';
        var sw=lvSwitch('lvRevChk','개정주석 표시',lvRevShown(),
                        '조문에 붙는 <신설/개정 …> 표기를 숨기거나 다시 표시합니다');
        bar.appendChild(sw);
        doc.insertBefore(bar,doc.firstChild);
        var ck=sw.querySelector('input');
        lvApplyRev(ck.checked);
        ck.addEventListener('change',function(){
          lvApplyRev(ck.checked);
          try{ localStorage.setItem('lvRevShow',ck.checked?'Y':'N'); }catch(e){}
        });
      }
      if(withChapSw && !bar.querySelector('#lvChapChk')){
        var sw2=lvSwitch('lvChapChk','장 전체 펼치기',chapOpen!==false,'장(章) 전체를 펼치거나 접습니다');
        bar.appendChild(sw2);
        sw2.querySelector('input').addEventListener('change',function(){ lvChapAll(this.checked); });
      }
      return bar;
    }
    <%-- 장을 하나씩 접었다 폈을 때 스위치 상태를 실제와 맞춘다(하나라도 접혀 있으면 꺼짐). --%>
    function lvChapSync(){
      var ck=document.getElementById('lvChapChk'); if(!ck)return;
      var ws=document.querySelectorAll('#lvBody .lv-chap-body'); if(!ws.length)return;
      var anyClosed=false;
      ws.forEach(function(w){ if(w.style.display==='none')anyClosed=true; });
      ck.checked=!anyClosed;
    }

    function lvFoldChapters(){
      var body=document.getElementById('lvBody'); if(!body)return;
      var doc=body.querySelector('.prov-doc'); if(!doc)return;
      lvBodyBar(doc,false);   /* 개정주석 토글은 장 구조 유무와 무관하게 항상 */
      if(doc.getAttribute('data-folded'))return;
      var grps=doc.querySelectorAll(':scope > .prov-group[id]');
      if(!grps.length)return;
      var minInd=null;
      grps.forEach(function(g){var i=parseInt(g.style.marginLeft||'0',10)||0;if(minInd===null||i<minInd)minInd=i;});
      var heads=[];
      grps.forEach(function(g){if((parseInt(g.style.marginLeft||'0',10)||0)===minInd)heads.push(g);});
      if(heads.length<2)return;   /* 장 구조가 없거나 1개 — 접기 무의미 */
      doc.setAttribute('data-folded','Y');
      var collapsed=LV_FOLD_DEFAULT_JO>0&&doc.querySelectorAll('.prov-jo').length>LV_FOLD_DEFAULT_JO;
      heads.forEach(function(h){
        var wrap=document.createElement('div');wrap.className='lv-chap-body';
        var n=h.nextSibling;
        while(n){
          if(n.nodeType===1){
            if(heads.indexOf(n)>=0)break;
            if(n.classList&&(n.classList.contains('prov-docu-sec')||n.classList.contains('prov-postscript')))break;
          }
          var nx=n.nextSibling; wrap.appendChild(n); n=nx;
        }
        h.parentNode.insertBefore(wrap,h.nextSibling);
        var mk=document.createElement('span');mk.className='lv-chap-mk';
        h.insertBefore(mk,h.firstChild);
        h.classList.add('lv-chap-head');
        var set=function(open){wrap.style.display=open?'':'none';mk.textContent=open?'▾':'▸';};
        h._lvSet=set;
        h.addEventListener('click',function(e){
          if(e.target.closest&&e.target.closest('a,button'))return;   /* 자동링크/조문정보 버튼 클릭은 통과 */
          set(wrap.style.display==='none');
          lvChapSync();
        });
        set(!collapsed);
      });
      /* [장 전체 펼치기] 스위치 — 장 접기가 적용된 문서에만, 개정주석 스위치 뒤에 덧붙인다 */
      lvBodyBar(doc,true,!collapsed);
    }
    window.lvChapAll=function(open){
      document.querySelectorAll('#lvBody .lv-chap-head').forEach(function(h){if(h._lvSet)h._lvSet(open);});
      lvChapSync();
    };
    /* 점프/검색 대상이 접힌 장 안이면 그 장을 펼침 */
    function lvEnsureChapOpen(el){
      if(!el||!el.closest)return;
      var w=el.closest('.lv-chap-body');
      if(w&&w.style.display==='none'){
        var h=w.previousElementSibling;
        if(h&&h._lvSet)h._lvSet(true);
        lvChapSync();
      }
    }
    /* 외부 법령 인용 문맥 판정(2026-07-23) — 미등재 법령(사전에 없어 서버 자동링크가 안 걸린
       「부가가치세법」·"법인세법"·"법(모법)"·"같은 법" 등) 바로 뒤의 제N조는 이 문서의 조문이
       아니므로 자기문서 앵커로 연결하지 않는다. "이 법/본 규정" 류 자기 지칭은 유지.
       (등재 법령명+조 연쇄는 서버가 <a>로 통째 소비하므로 여기 도달하는 건 미등재 인용뿐) */
    function lvExtLawBefore(txt,idx){
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
      if(ch==='」'||ch==='』'||ch==='”')return true;   /* 「…」/『…』/"…" 인용 직후 */
      var m=pre.match(/([가-힣A-Za-z0-9]*)(법률|시행령|시행규칙|시행세칙|조례|규칙|규정|지침|세칙|요령|정관|법|영|령)$/);
      if(!m)return false;
      if(m[1])return true;                                          /* "부가가치세법" 등 고유명 어근 */
      /* 단독 단위어("법"/"영"/"규정"…) — "이/본" 수식 = 자기 지칭, 그 외("같은 법"/"동"/맨몸=모법)는 외부 */
      var pre2=pre.slice(0,pre.length-m[2].length).replace(/\s+$/,'');
      var w=(pre2.match(/[가-힣]+$/)||[''])[0];
      return !(w==='이'||w==='본');
    }
    /* 외부 조 참조 연쇄 글루 — "제48조 또는 제49조", "제10조ㆍ제11조", "제3조부터 제5조" */
    function lvChainGlue(gap){
      return /^\s*(?:(?:또는|및|와|과|부터|내지)\s*|[,ㆍ·~]\s*)*$/.test(gap);
    }
    function lvInitBody(){
      var body=document.getElementById('lvBody'); if(!body)return;
      var walker=document.createTreeWalker(body,NodeFilter.SHOW_TEXT,null),targets=[],n;
      while(n=walker.nextNode()){ if(n.parentNode&&n.parentNode.closest&&n.parentNode.closest('a'))continue; if(/제\s*\d+\s*조(의\s*\d+)?/.test(n.nodeValue))targets.push(n); }
      targets.forEach(function(tn){
        var frag=document.createDocumentFragment(),txt=tn.nodeValue,re=/제\s*(\d+)\s*조(?:의\s*(\d+))?/g,last=0,m,extChain=false,prevEnd=-1;
        while(m=re.exec(txt)){
          if(m.index>last)frag.appendChild(document.createTextNode(txt.slice(last,m.index)));
          /* 외부 법령 문맥 또는 외부 참조에 글루(또는/및/ㆍ…)로 이어지는 연쇄 → 자기링크 금지 */
          var ext=lvExtLawBefore(txt,m.index)||(extChain&&prevEnd>=0&&lvChainGlue(txt.slice(prevEnd,m.index)));
          var anc='jo-'+m[1]+(m[2]?('-'+m[2]):'');
          if(!ext&&document.getElementById(anc)){var a=document.createElement('a');a.className='xref';a.href='#'+anc;a.textContent=m[0];a.onclick=(function(an){return function(e){e.preventDefault();lvJump(an);};})(anc);frag.appendChild(a);}
          else frag.appendChild(document.createTextNode(m[0]));
          extChain=ext; prevEnd=re.lastIndex;
          last=re.lastIndex;
        }
        if(last<txt.length)frag.appendChild(document.createTextNode(txt.slice(last)));
        tn.parentNode.replaceChild(frag,tn);
      });
    }
    <%-- ── 조문 링크/본문 복사 헬퍼 — ✎ 조문정보관리 팝업의 액션(lvCopyJoLink/lvCopyJoBody)이 사용.
         (위로(WiLaw) 벤치마크 2026-07-24 → 라벨 옆 아이콘 나열 대신 팝업 통합, 사용자 피드백) --%>
    function lvCopyExec(t){
      try{var ta=document.createElement('textarea');ta.value=t;ta.style.cssText='position:fixed;top:-999px;opacity:0;';
        document.body.appendChild(ta);ta.focus();ta.select();var ok=document.execCommand('copy');document.body.removeChild(ta);return ok;
      }catch(e){return false;}
    }
    function lvCopyText(t){
      if(navigator.clipboard&&navigator.clipboard.writeText&&window.isSecureContext){
        return navigator.clipboard.writeText(t).then(function(){return true;},function(){return lvCopyExec(t);});
      }
      return Promise.resolve(lvCopyExec(t));
    }
    /* 조문 블록 → 평문 — UI 요소(✎ 버튼)와 시스템 렌더 주석(.prov-rev/.prov-hist 개정마크)은 제외.
       DB 본문에 원래 박힌 <개정 YYYY. M. D.> 원문 표기는 그대로 남는다. */
    function lvJoPlainText(el){
      var cl=el.cloneNode(true);
      cl.querySelectorAll('button,.prov-info,.prov-rev,.prov-hist').forEach(function(b){if(b.parentNode)b.parentNode.removeChild(b);});
      return cl.innerText.replace(/\n{3,}/g,'\n\n').trim();
    }
    /* 조문 "전체 단위" 평문 — 렌더 구조상 항·호·목(.prov-sub)은 조(.prov-jo)의 형제 div 라서
       조 블록만 복사하면 ①항 한 줄로 끝남 → 다음 조/장/부칙/별표 경계 전까지 형제를 이어붙인다.
       (부분인쇄의 조 범위 경계 판정과 동일 규칙. 장 접기 래퍼 안에서도 형제 관계 유지됨) */
    function lvJoUnitText(el){
      var parts=[lvJoPlainText(el)];
      var n=el.nextElementSibling;
      while(n){
        var c=n.classList;
        if(c&&(c.contains('prov-jo')||c.contains('prov-group')||c.contains('prov-postscript')
             ||c.contains('prov-docu')||c.contains('prov-docu-sec')||c.contains('lv-chap-body')))break;
        var t=lvJoPlainText(n);
        if(t)parts.push(t);
        n=n.nextElementSibling;
      }
      return parts.join('\n');
    }
    var lvHits=[],lvCur=-1,lvLastQ='';
    function lvBuildHits(q){
      if(!document.getElementById('lvBody')){lvHits=[];return;}   /* 파일 인라인 모드 — 본문 영역 없음 */
      document.querySelectorAll('#lvBody mark.lvhit').forEach(function(mk){var t=document.createTextNode(mk.textContent);mk.parentNode.replaceChild(t,mk);});
      document.getElementById('lvBody').normalize();lvHits=[];lvCur=-1;if(!q)return;
      var walker=document.createTreeWalker(document.getElementById('lvBody'),NodeFilter.SHOW_TEXT,null),arr=[],n;
      while(n=walker.nextNode()){if(n.nodeValue.indexOf(q)>=0)arr.push(n);}
      arr.forEach(function(tn){var txt=tn.nodeValue,frag=document.createDocumentFragment(),idx,last=0;
        while((idx=txt.indexOf(q,last))>=0){if(idx>last)frag.appendChild(document.createTextNode(txt.slice(last,idx)));var mk=document.createElement('mark');mk.className='lvhit';mk.textContent=txt.substr(idx,q.length);frag.appendChild(mk);lvHits.push(mk);last=idx+q.length;}
        if(last<txt.length)frag.appendChild(document.createTextNode(txt.slice(last)));tn.parentNode.replaceChild(frag,tn);});
    }
    function lvFindNext(){
      var q=document.getElementById('lvFind').value.trim();
      if(q!==lvLastQ){lvBuildHits(q);lvLastQ=q;}
      if(!lvHits.length){document.getElementById('lvFindCnt').textContent='없음';return;}
      if(lvCur>=0&&lvHits[lvCur])lvHits[lvCur].classList.remove('cur');
      lvCur=(lvCur+1)%lvHits.length;var mk=lvHits[lvCur];mk.classList.add('cur');lvEnsureChapOpen(mk);mk.scrollIntoView({behavior:'smooth',block:'center'});
      document.getElementById('lvFindCnt').textContent=(lvCur+1)+'/'+lvHits.length;
    }

    /* ---- PJAX: 트리/연혁 클릭 시 본문(디테일) 영역만 교체 — 전체 페이지 리로드 X ---- */
    function lvSetTreeActive(promNo){
      document.querySelectorAll('#lvTree a.t-prom.on').forEach(function(a){a.classList.remove('on');});
      var sel=document.querySelector('#lvTree a.t-prom[href*="promNo='+promNo+'"]');
      if(sel){sel.classList.add('on');lvExpandToCurrent();}   /* 기본 접힘 트리 — 새 현재 규정 경로 펼침+스크롤 */
      lvBuildOutline();   /* 새 회차 본문 기준 조문 개요 재생성 (PJAX 후 호출 시점 = 본문 교체 완료) */
    }
    function lvNavigate(url,push){
      fetch(url,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.text();})
        .then(function(html){
          var doc=new DOMParser().parseFromString(html,'text/html');
          var nm=doc.getElementById('lvMain');
          if(!nm){location.href=url;return;}              /* #lvMain 없음(목록/로그인 리다이렉트) → 전체이동 폴백 */
          LV_PROMNO=nm.getAttribute('data-promno')||'';
          LV_LAWID =nm.getAttribute('data-lawid')||'';
          LV_SYS   =nm.getAttribute('data-sysid')||LV_SYS;
          LV_PREVNO=nm.getAttribute('data-prevno')||'';
          document.getElementById('lvMain').innerHTML=nm.innerHTML;
          var tl=doc.querySelector('.lawview-toolbar .lvt-left');
          if(tl)document.querySelector('.lawview-toolbar .lvt-left').innerHTML=tl.innerHTML;
          var dp=doc.querySelector('.lawview-right .lv-side.dept .lvs-body');
          if(dp)document.querySelector('.lawview-right .lv-side.dept .lvs-body').innerHTML=dp.innerHTML;
          lvInitBody();
          lvFoldChapters();   /* PJAX 본문 교체 후 장 접기 재적용 */
          lvInitDocuSection();/* 별표 목록형 접기 + 개별 첨부도 재적용 */
          lvHistLoaded=false;
          var hb=document.getElementById('lvHistBody');if(hb){hb.classList.remove('open');hb.innerHTML='불러오는 중…';}
          var ar=document.querySelector('.lv-history .lvh-head .arr');if(ar)ar.innerHTML='&#9654;';
          var hc=document.getElementById('lvHistCnt');if(hc)hc.textContent='';
          var rb=document.getElementById('lvRelBox');if(rb)rb.innerHTML='<span class="muted">불러오는 중…</span>';
          lvLoadRel();
          lvLoadStsfdg();   /* 만족도 위젯 — 새 회차 마크업(innerHTML 교체분)에 데이터 재바인딩 */
          lvSetTreeActive(LV_PROMNO);
          lvHits=[];lvCur=-1;lvLastQ='';
          var fc=document.getElementById('lvFindCnt');if(fc)fc.textContent='';
          var fv=document.getElementById('lvFind');if(fv)fv.value='';
          /* 자동링크/딥링크 해시(#jo-N 등) — PJAX 교체 후 대상 조문으로 점프, 없으면 최상단 */
          var hs=(url.indexOf('#')>=0)?url.slice(url.indexOf('#')+1):'';
          if(hs&&/^(jo-|grp-|docu-|phtml-)[0-9A-Za-z_-]*$/.test(hs)&&document.getElementById(hs)){
            window.scrollTo(0,0);setTimeout(function(){lvJump(hs);},80);
          }else{
            window.scrollTo(0,0);
          }
          if(push!==false)history.pushState({pn:LV_PROMNO},'',url);
        })
        .catch(function(){location.href=url;});             /* 네트워크 오류 → 전체이동 폴백 */
    }
    /* ---- 자동링크: 동명 규정 목록 팝업 (a.prov-autolink-multi 의 data-cands 소비) ---- */
    function lvCloseAlPop(){var p=document.getElementById('lvAlPop');if(p&&p.parentNode)p.parentNode.removeChild(p);}
    document.addEventListener('click',function(e){
      var a=e.target.closest&&e.target.closest('a.prov-autolink-multi');
      if(!a){ if(!(e.target.closest&&e.target.closest('#lvAlPop')))lvCloseAlPop(); return; }
      e.preventDefault(); lvCloseAlPop();
      var cands;try{cands=JSON.parse(a.getAttribute('data-cands')||'[]');}catch(x){cands=[];}
      if(!cands.length)return;
      var jo=a.getAttribute('data-jo')||'';
      var pop=document.createElement('div');pop.id='lvAlPop';pop.className='lv-autolink-pop';
      var hd=document.createElement('div');hd.className='hd';hd.textContent='동명 규정 '+cands.length+'건 — 이동할 규정 선택';pop.appendChild(hd);
      cands.forEach(function(c){
        var l=document.createElement('a');
        l.href='<c:url value="/rlms/fulltext/provisionList.do"/>?promNo='+c.p+(jo?('#jo-'+jo):'');
        l.textContent=c.t;
        if(c.c){var s=document.createElement('small');s.textContent=c.c;l.appendChild(s);}
        l.addEventListener('click',function(){lvCloseAlPop();});
        pop.appendChild(l);
      });
      document.body.appendChild(pop);
      var r=a.getBoundingClientRect();
      pop.style.left=Math.max(8,Math.min(window.scrollX+r.left,window.scrollX+document.documentElement.clientWidth-pop.offsetWidth-12))+'px';
      pop.style.top=(window.scrollY+r.bottom+4)+'px';
    });

    document.addEventListener('click',function(e){
      var a=e.target.closest&&e.target.closest('a');if(!a||a.target==='_blank')return;
      if((a.getAttribute('href')||'').indexOf('/rlms/fulltext/provisionList.do?promNo=')>=0){
        e.preventDefault(); lvNavigate(a.href,true);
      }
    });
    window.addEventListener('popstate',function(){lvNavigate(location.href,false);});

    /* ---- 폰(≤640) 툴바 도구 접기/펼치기 (2026-08-04 반응형) ---- */
    function lvToolsToggle(){
      var tb=document.querySelector('.lawview-toolbar'), b=document.getElementById('lvToolsTog');
      if(!tb||!b)return;
      var open=tb.classList.toggle('lv-tools-open');
      b.setAttribute('aria-expanded', open?'true':'false');
      var ar=document.getElementById('lvToolsTogArr');
      if(ar)ar.innerHTML=open?'&#9652;':'&#9662;';
    }

    /* ---- 모바일(≤1024) 좌측 트리 드로어 토글 (2026-08-04 반응형) ---- */
    function lvMobTree(open){
      var left=document.querySelector('.lawview-left'), bd=document.getElementById('lvMobBackdrop'),
          h=document.getElementById('lvTreeHandle');
      if(!left||!bd)return;
      left.classList.toggle('lv-mob-open',open);
      bd.classList.toggle('on',open);
      if(h)h.classList.toggle('hidden',open);   /* 전역 드로어(#pnHandle)와 동일 — 열림 중엔 핸들 숨김 */
    }
    (function(){
      var left=document.querySelector('.lawview-left');
      if(!left)return;
      /* 트리에서 규정/조문 링크를 고르면 드로어 자동 닫힘(PJAX 이동과 병행) */
      left.addEventListener('click',function(e){
        var a=e.target.closest&&e.target.closest('a');
        if(a&&left.classList.contains('lv-mob-open'))lvMobTree(false);
      });
      document.addEventListener('keydown',function(e){
        if(e.key==='Escape'&&left.classList.contains('lv-mob-open'))lvMobTree(false);
      });
    })();

    /* ---- 트리 폭 드래그 조절 + 접기/펼치기 (localStorage 유지) ---- */
    (function(){
      var sp=document.getElementById('lvSplitter'), left=document.querySelector('.lawview-left'),
          btn=document.getElementById('lvTreeHideBtn');
      if(!sp||!left||!btn)return;
      var MIN=170, MAX=640;
      /* 최소 폭 = 분류 탭 줄(전문분류/부서별/기능별분류) 실측 폭 — 좁혀도 탭이 잘리지 않게 */
      var tabRow=left.querySelector('.lv-tabs');
      if(tabRow&&tabRow.children.length){
        var tw=10,tc=tabRow.children;
        for(var ti=0;ti<tc.length;ti++) tw+=tc[ti].offsetWidth+3; /* +margin-right */
        MIN=Math.max(MIN,tw);
      }
      function applyW(w){ w=Math.max(MIN,Math.min(MAX,w)); left.style.flex='0 0 '+w+'px'; left.style.maxWidth=w+'px'; return w; }
      function setHidden(h){
        left.style.display=h?'none':'';
        btn.innerHTML=h?'&#9654;':'&#9664;';
        sp.style.cursor=h?'default':'col-resize';
        try{ localStorage.setItem('lvTreeHide', h?'Y':'N'); }catch(e){}
      }
      try{
        var w0=parseInt(localStorage.getItem('lvTreeW'),10); if(w0)applyW(w0);
        if(localStorage.getItem('lvTreeHide')==='Y')setHidden(true);
      }catch(e){}
      btn.addEventListener('click',function(e){
        e.stopPropagation();
        setHidden(left.style.display!=='none');
      });
      var drag=false,sx=0,sw=0;
      sp.addEventListener('pointerdown',function(e){
        if(e.target===btn||left.style.display==='none')return;
        drag=true; sx=e.clientX; sw=left.getBoundingClientRect().width;
        sp.classList.add('on'); document.body.style.userSelect='none';
        try{ sp.setPointerCapture(e.pointerId); }catch(x){}
        e.preventDefault();
      });
      sp.addEventListener('pointermove',function(e){ if(drag)applyW(sw+(e.clientX-sx)); });
      function endDrag(){
        if(!drag)return;
        drag=false; sp.classList.remove('on'); document.body.style.userSelect='';
        try{ localStorage.setItem('lvTreeW', String(Math.round(left.getBoundingClientRect().width))); }catch(e){}
      }
      sp.addEventListener('pointerup',endDrag);
      sp.addEventListener('pointercancel',endDrag);
      sp.addEventListener('dblclick',function(e){
        if(e.target===btn)return;
        left.style.flex=''; left.style.maxWidth='';
        try{ localStorage.removeItem('lvTreeW'); }catch(x){}
      });
    })();

    lvInitBody(); lvFoldChapters(); lvInitDocuSection(); lvLoadTree(); lvLoadRel(); lvLoadStsfdg();

    /* 딥링크 앵커 점프 — 관련규정연계(dmn) 점프(window.open …#jo-N)·외부 딥링크가 특정 조문으로
       바로 스크롤+강조. 본문(provHtml)은 인라인이라 로드시 대상이 존재 → 네이티브 앵커 스크롤
       위에 부드러운 이동+노란 강조를 덧입혀, 본문내 상호참조(xref) 점프와 동일한 UX 보장.
       location.hash 가 알려진 앵커(jo-/grp-/docu-/phtml-)이고 대상이 실재할 때만 동작. */
    (function(){
      var anc=(location.hash||'').replace(/^#/,'');
      if(anc && /^(jo-|grp-|docu-|phtml-)[0-9A-Za-z_-]*$/.test(anc) && document.getElementById(anc)){
        setTimeout(function(){ lvJump(anc); }, 80);   // 레이아웃 안정(인라인 본문) 후 정확 위치
      }
    })();
  </script>
  </c:when>

  <c:otherwise>
    <div class="page-header"><h1>규정 본문 보기</h1></div>
    <%-- 뷰어 진입 실패 안내 (열람 제한 / 삭제·잘못된 링크) — 컨트롤러 resultMsg --%>
    <c:if test="${not empty resultMsg}">
      <div style="margin:0 0 16px; padding:12px 16px; border:1px solid #f0c4c4; background:#fdf4f4; color:#a33a3a; border-radius:6px; font-size:15px;">
        <c:out value="${resultMsg}"/>
      </div>
    </c:if>
    <div class="rlms-search-layout">
      <aside class="rlms-search-tree-aside">
        <div class="rlms-search-tree-head">규정 분류</div>
        <div id="cateSearchTree" class="rlms-search-tree"></div>
      </aside>
      <div class="rlms-search-body">
    <form id="searchForm" name="searchForm" action="<c:url value='/rlms/fulltext/provisionList.do'/>" method="get" class="krds-form search-form">
      <input type="hidden" name="pageIndex" value="${searchVO.pageIndex}"/>
      <c:if test="${not empty searchVO.cateNo}"><input type="hidden" name="cateNo" value="${searchVO.cateNo}"/></c:if>
      <div class="form-group inline">
        <label class="form-label">분류</label>
        <div class="form-conts" style="display:flex;flex-wrap:wrap;gap:10px;align-items:center;">
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
          </select>
        </div>
        <label class="form-label" for="searchKeyword">키워드</label>
        <div class="form-conts">
          <input type="text" id="searchKeyword" name="searchKeyword" class="krds-input" value="<c:out value='${searchVO.searchKeyword}'/>"/>
        </div>
        <label class="form-label" for="searchFromDt">공포일</label>
        <div class="form-conts">
          <input type="date" id="searchFromDt" name="searchFromDt" class="krds-input" value="<c:out value='${searchVO.searchFromDt}'/>"/>
          <span>~</span>
          <input type="date" id="searchToDt" name="searchToDt" class="krds-input" value="<c:out value='${searchVO.searchToDt}'/>"/>
        </div>
        <button type="submit" class="krds-btn primary medium">검색</button>
        <a href="<c:url value='/rlms/fulltext/provisionList.do'/>" class="krds-btn medium">초기화</a>
      </div>
    </form>
    <p class="list-total">총 <strong><c:out value="${resultCnt}"/></strong> 건 — 본문을 볼 규정을 선택하세요.</p>
    <table class="krds-table tbl-list">
      <thead><tr><th scope="col">No</th><th scope="col">관리번호</th><th scope="col">제목</th><th scope="col">분류</th><th scope="col">회차</th><th scope="col">공포일</th></tr></thead>
      <tbody>
        <c:if test="${empty resultList}">
          <tr><td colspan="6" style="text-align:center;">데이터가 없습니다.</td></tr>
        </c:if>
        <c:forEach var="row" items="${resultList}" varStatus="status">
          <c:set var="rowNum" value="${paginationInfo.totalRecordCount - ((paginationInfo.currentPageNo - 1) * paginationInfo.recordCountPerPage) - status.index}"/>
          <tr>
            <td><c:out value="${rowNum}"/></td>
            <td><a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${row.promNo}"><c:out value="${row.promNo}"/></a></td>
            <td><a href="<c:url value='/rlms/fulltext/provisionList.do'/>?promNo=${row.promNo}"><c:out value="${row.title}"/></a>
                <c:if test="${row.upcoming}"><span class="krds-badge bg-light-information" title="시행일 ${row.startDate}">시행예정</span></c:if></td>
            <td><c:out value="${row.cateNm}"/></td>
            <td><c:out value="${row.lawNo}"/></td>
            <td><c:out value="${row.promDate}"/></td>
          </tr>
        </c:forEach>
      </tbody>
    </table>
    <div class="krds-pagination"><ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="fnLinkPage"/></div>
      </div>
    </div>
    <script>
      function fnLinkPage(pageNo){document.searchForm.pageIndex.value=pageNo;document.searchForm.submit();}
      $(function(){ RlmsCateSearchTree.init({ containerId:'cateSearchTree', jsonUrl:'<c:url value="/rlms/cate/selectCateTreeJson.do"/>', searchUrl:'<c:url value="/rlms/fulltext/provisionList.do"/>' }); });
    </script>
  </c:otherwise>
</c:choose>
</lay:layout>
