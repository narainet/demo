/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/web/FullTextController.java
 *
 * 사용자 화면(Front) 법령 검색 5종 Controller.
 *
 * 레거시 /lims/front/page/fulltext.html?pAct=... 대응:
 *   pAct=historyList    → /rlms/fulltext/historyList.do
 *   pAct=comparisonList → /rlms/fulltext/comparisonList.do
 *   pAct=provisionList  → /rlms/fulltext/provisionList.do
 *   pAct=nullifyList    → /rlms/fulltext/nullifyList.do
 *   pAct=latestList     → /rlms/fulltext/latestList.do
 *   pAct=searchList     → 기존 /rlms/prom/selectPromList.do 활용 (별도 액션 미생성)
 *
 * 권한 가드는 A 작업(사용자/권한) 에서 통합. 현재는 로그인 여부만 체크.
 */
package narainet.rlms.prom.web;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.common.service.FtGubunService;
import narainet.rlms.common.service.PublicFront;
import narainet.rlms.prom.service.PromService;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prom.service.ProvVrsnService;
import narainet.rlms.prom.service.impl.PromDocExporter;

@Controller
public class FullTextController {

	private static final org.slf4j.Logger LOGGER = org.slf4j.LoggerFactory.getLogger(FullTextController.class);

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	/** 자음검색 첫글자 앵커(레거시 HANGUL_PREFIX). idx i = 하한, idx i+1 = (배타)상한. 마지막은 힣 직후(힤). */
	private static final String[] HANGUL_ANCHORS = {
		"가", "나", "다", "라", "마", "바", "사", "아", "자", "차", "카", "타", "파", "하", "힤"
	};

	@Resource(name = "promService")
	private PromService promService;

	/** 즐겨찾기 확인 회차 기록(개정 소식 해소) — 뷰어 본문 실렌더 시 touch */
	@Resource(name = "favorService")
	private narainet.rlms.favor.service.FavorService favorService;

	/** 필수 열람(TB_READ_DUTY) — 대상자 배너/[숙지 확인] 버튼 + 열람 자동 기록(1단계) */
	@Resource(name = "readDutyService")
	private narainet.rlms.readduty.service.ReadDutyService readDutyService;

	@Resource(name = "provVrsnService")
	private ProvVrsnService provVrsnService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	/** 뷰 카운트 적재(TB_STATS_FT_VIEW) — 규정별 조회통계 원천 */
	@Resource(name = "statsService")
	private narainet.rlms.stats.service.StatsService statsService;

	/** 조문 누적 목록 → 전문 뷰어 HTML 렌더러 (stateless POJO) */
	private final narainet.rlms.prom.service.impl.ProvViewRenderer provViewRenderer =
			new narainet.rlms.prom.service.impl.ProvViewRenderer();

	/** 본문 [태그:…] 관련자료 토큰 해석기 (Spring 빈 — 관련자료 매퍼 주입) */
	@Resource(name = "provTokenResolver")
	private narainet.rlms.prom.service.impl.ProvTokenResolver provTokenResolver;

	@Resource(name = "autoLinkService")
	private narainet.rlms.prom.service.impl.AutoLinkService autoLinkService;

	@Resource
	private narainet.rlms.docu.mapper.DocuMapper docuMapper;

	/** 별표 개별 첨부 조회 — 관련자료 SFLAG='DOCUMENT' 축 (2026-07-30) */
	@Resource
	private narainet.rlms.related.mapper.RelVrsnMapper relVrsnMapper;

	@Resource
	private narainet.rlms.prom.mapper.ProvHtmlMapper provHtmlMapper;

	/** 규정형식(SPROV_FG)별 본문 표시 방식 결정 — 레거시 frontView 분기 */
	@Resource(name = "promBodyViewResolver")
	private narainet.rlms.prom.service.impl.PromBodyViewResolver promBodyViewResolver;

	@Resource(name = "ftGubunService")
	private FtGubunService ftGubunService;

	/** 분류별 열람제한 가드 (TB_CATE_READER) — 목록 SQL 게이트 + 뷰어/내보내기 단건 가드 */
	@Resource(name = "promReadGuard")
	private narainet.rlms.prom.service.PromReadGuard promReadGuard;

	/** 빠른검색(전 규정 조문/별표 제목) 조회용 */
	@Resource
	private narainet.rlms.prom.mapper.ProvVrsnMapper provVrsnMapper;

	/**
	 * 뷰어 좌측 빠른검색 보조 — 전 규정(현행 회차 기준 누적)의 조문/별표 제목 검색.
	 * 트리를 펼치지 않아도(다른 규정을 열지 않아도) 정관·시행령·업무매뉴얼 등 전체에서
	 * 조문 제목이 검색되도록 하는 서버 검색. 공백 무시 LIKE, 열람제한은 canReadLaw 후필터.
	 */
	@org.springframework.web.bind.annotation.ResponseBody
	@RequestMapping("/rlms/fulltext/quickSearchJson.do")
	public Map<String, Object> quickSearchJson(@RequestParam(value = "q", required = false) String q) {
		Map<String, Object> res = new java.util.LinkedHashMap<>();
		List<Map<String, Object>> list = new java.util.ArrayList<>();
		res.put("list", list);
		if (!PublicFront.viewAllowed()) return res;
		q = (q == null) ? "" : q.trim();
		if (q.replace(" ", "").length() < 2) return res;   // 2자 미만 — 과다 히트 방지
		try {
			List<Map<String, Object>> rows = provVrsnMapper.selectQuickTitleSearch(q);
			if (rows == null) return res;
			Map<Long, Boolean> readable = new java.util.HashMap<>();   // lawId 별 열람제한 판정 캐시
			for (Map<String, Object> r : rows) {
				if (list.size() >= 40) break;
				Long lawId = asLong(r.get("LAW_ID"));
				Boolean ok = readable.get(lawId);
				if (ok == null) { ok = promReadGuard.canReadLaw(lawId); readable.put(lawId, ok); }
				if (!Boolean.TRUE.equals(ok)) continue;
				Map<String, Object> m = new java.util.LinkedHashMap<>();
				m.put("src",      r.get("SRC"));
				m.put("promNo",   r.get("PROM_NO"));
				m.put("lawTitle", r.get("LAW_TITLE"));
				m.put("item",     r.get("ITEM"));
				m.put("subItem",  r.get("SUB_ITEM"));
				m.put("title",    r.get("TITLE"));
				m.put("anchorNo", r.get("ANCHOR_NO"));
				list.add(m);
			}
		} catch (Exception e) {
			LOGGER.warn("quickSearchJson fail: {}", e.getMessage());
		}
		return res;
	}

	private static Long asLong(Object o) {
		if (o == null) return null;
		if (o instanceof Number) return ((Number) o).longValue();
		try { return Long.valueOf(o.toString().trim()); } catch (NumberFormatException e) { return null; }
	}

	/** 구분(SGUBUN) 체크박스 목록 — 정본 ccm. 5개 검색폼 공용(매 요청 모델 주입). */
	@ModelAttribute("gubunList")
	public List<Map<String, Object>> gubunList() {
		return ftGubunService.gubunList();
	}

	// ────────────────────────────────────────────────────────────────
	// 1) 연혁검색 (historyList)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/fulltext/historyList.do")
	public String historyList(@ModelAttribute("searchVO") PromVO searchVO,
			ModelMap model) throws Exception {

		if (!PublicFront.viewAllowed()) {
			return LOGIN_REDIRECT;
		}
		addDetailDropdowns(model);   // 상세검색 모달 폼 데이터(부서/분류/구분라벨)
		setupPaging(searchVO);
		promReadGuard.applyReadGate(searchVO);   // 분류별 열람제한(면제역할 제외)
		PaginationInfo paginationInfo = paginationOf(searchVO);

		// 상세검색 모드면 상세검색 쿼리로, 아니면 일반 연혁검색으로 — 결과는 같은 목록 테이블에 렌더
		Map<String, Object> result;
		if ("Y".equals(searchVO.getDetailMode())) {
			applyAdvancedParams(searchVO);
			result = promService.selectDetailSearch(searchVO);
		} else {
			result = promService.selectFrontCurrentList(searchVO);   // 현행 규정만(SEXISTING_YN='Y')
		}
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		paginationInfo.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", paginationInfo);
		return "rlms/fulltext/historyList";
	}

	// ────────────────────────────────────────────────────────────────
	// 2) 신구대조 (comparisonList) — lawId 받아서 좌/우 선택 UI
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/fulltext/comparisonList.do")
	public String comparisonList(@ModelAttribute("searchVO") PromVO searchVO,
			ModelMap model) throws Exception {

		if (!PublicFront.viewAllowed()) {
			return LOGIN_REDIRECT;
		}
		setupPaging(searchVO);
		promReadGuard.applyReadGate(searchVO);   // 분류별 열람제한(면제역할 제외)
		PaginationInfo paginationInfo = paginationOf(searchVO);

		// lawId 가 지정되면 좌/우 선택 후보 표시, 아니면 lawId 그룹 진입용 history 목록 표시
		if (searchVO.getLawId() != null && searchVO.getLawId() > 0L) {
			List<PromVO> candidates = promService.selectComparisonCandidates(searchVO.getLawId());
			model.addAttribute("candidates", candidates);
		} else {
			Map<String, Object> result = promService.selectFrontHistoryList(searchVO);
			int totCnt = Integer.parseInt((String) result.get("resultCnt"));
			paginationInfo.setTotalRecordCount(totCnt);
			model.addAttribute("resultList", result.get("resultList"));
			model.addAttribute("resultCnt", result.get("resultCnt"));
			model.addAttribute("paginationInfo", paginationInfo);
		}
		return "rlms/fulltext/comparisonList";
	}

	// ────────────────────────────────────────────────────────────────
	// 3) 조별대조 (provisionList) — 특정 promNo 의 조항 목록
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/fulltext/provisionList.do")
	public String provisionList(@ModelAttribute("searchVO") PromVO searchVO,
			@RequestParam(value = "promNo", required = false) Long promNo,
			HttpServletRequest request, ModelMap model) throws Exception {

		if (!PublicFront.viewAllowed()) {
			return LOGIN_REDIRECT;
		}

		PromVO prom = (promNo != null) ? promService.selectPromDetail(promNo) : null;
		// 분류별 열람제한 — 차단이면 본문 렌더 대신 안내 + 목록 폴백 (면제역할은 통과)
		if (prom != null && !promReadGuard.canRead(prom)) {
			prom = null;
			model.addAttribute("resultMsg", "이 규정은 열람 권한이 제한되어 있습니다. (지정된 부서/개인만 열람 가능)");
		}
		// 미승인 draft — 비편집계 비노출 (목록/검색의 excludeUnapprovedDraft 와 정합.
		// 뷰어 딥링크만 승인상태를 안 봐 승인 전 본문이 URL 직타로 열렸음 — 2026-07-09 교정)
		if (prom != null && !hasEditorRole() && promService.isWorkingDraftProm(promNo)) {
			prom = null;
			model.addAttribute("resultMsg", "승인 전(작업중) 규정입니다. 승인 완료 후 열람할 수 있습니다.");
		}
		if (prom != null) {
			// 뷰 카운트 적재 — 가드(로그인·열람제한·미승인 draft) 전부 통과한 본문 실렌더만.
			// 새로고침/재제출 부풀림 방지 = 세션 직전 promNo 와 다를 때만(검색어 통계 선례)
			if (!promNo.equals(request.getSession().getAttribute("rlmsLastViewPromNo"))) {
				try {
					statsService.recordView(prom.getLawId(), prom.getGubunId());
				} catch (Exception e) {
					LOGGER.warn("뷰 카운트 적재 실패(무시): {}", e.getMessage());
				}
				// 사용자 활동 로그 — 뷰 카운트와 같은 세션 dedup(새로고침 부풀림 방지).
				// 공개열람 익명은 제외(뷰 카운트만 집계) — 활동 로그는 로그인 사용자 감사 용도.
				egovframework.com.cmm.LoginVO actUser =
						(egovframework.com.cmm.LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
				if (actUser != null) {
					statsService.recordAction("규정 열람", "TB_PROM", promNo, prom.getTitle(),
							actUser.getId(), actUser.getName(),
							egovframework.com.utl.sim.service.EgovClntInfo.getClntIP(request));
				}
				// 즐겨찾기 확인 회차 기록 — 홈 "즐겨찾기 규정 개정 소식" 해소. 실패가 뷰어를 막지 않게 무시.
				try {
					if (actUser != null) {
						favorService.touchSeen(actUser.getUniqId(), prom.getLawId(), prom.getLawNo());
					}
				} catch (Exception e) {
					LOGGER.warn("즐겨찾기 확인 회차 기록 실패(무시): {}", e.getMessage());
				}
				request.getSession().setAttribute("rlmsLastViewPromNo", promNo);
			}
			// 누적 조회수 노출 — 방금 적재분 포함. 통계 장애가 뷰어를 막지 않게 실패는 무시(미노출)
			try {
				model.addAttribute("viewCnt", statsService.getViewCount(prom.getLawId()));
			} catch (Exception e) {
				LOGGER.warn("누적 조회수 조회 실패(무시): {}", e.getMessage());
			}
			// 필수 열람 — 대상자면 배너/[숙지 확인] 버튼 노출 + 열람 자동 기록(1단계, 최초 1회 멱등).
			// 가드(로그인·열람제한·미승인 draft) 전부 통과한 본문 실렌더에서만. 실패가 뷰어를 막지 않게 무시.
			try {
				egovframework.com.cmm.LoginVO dutyUser =
						(egovframework.com.cmm.LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
				if (dutyUser != null) {
					java.util.Map<String, Object> myDuty = readDutyService.selectMyDutyForProm(
							promNo, dutyUser.getUniqId(), dutyUser.getOrgnztId(), dutyUser.getUserSe());
					if (myDuty != null) {
						if (myDuty.get("readDt") == null) {
							readDutyService.touchRead(((Number) myDuty.get("dutyNo")).longValue(),
									dutyUser.getUniqId(), dutyUser.getName(), dutyUser.getOrgnztId());
						}
						model.addAttribute("readDuty", myDuty);
					}
				}
			} catch (Exception e) {
				LOGGER.warn("필수 열람 상태 조회 실패(무시): {}", e.getMessage());
			}
			model.addAttribute("prom", prom);
			// 규정형식(SPROV_FG)별 본문 표시 — VERSION 조문렌더 / HTML 누적렌더 / VIEWER·파일열람 인라인
			// + 전 회차 목록 전달 → 조문 인라인 개정 주석(<개정 YYYY. M. D.>, 2026-07-24)
			PromBodyModelSupport.addBodyModel(prom, promNo, request.getContextPath(), model,
					promBodyViewResolver, provVrsnService, provHtmlMapper, docuMapper,
					provViewRenderer, provTokenResolver, autoLinkService,
					promService.selectPromHistory(prom.getLawId(), prom.getSysId()));
			// 신구대조 — 직전 회차 자동 비교용(레거시 getPrevious 동선). 없으면 제정 → 툴바 버튼 비활성.
			PromVO prevProm = promService.selectPreviousProm(promNo);
			if (prevProm != null) {
				model.addAttribute("prevPromNo", prevProm.getPromNo());
			}
		} else {
			// promNo 없이 진입(또는 삭제된/없는 promNo — stale 링크) — 법령 선택을 위한 history 목록
			if (promNo != null && !model.containsAttribute("resultMsg")) {
				model.addAttribute("resultMsg", "규정을 찾을 수 없습니다. (삭제되었거나 잘못된 링크)");
			}
			setupPaging(searchVO);
			promReadGuard.applyReadGate(searchVO);   // 폴백 목록에도 열람제한 적용
			PaginationInfo paginationInfo = paginationOf(searchVO);
			Map<String, Object> result = promService.selectFrontHistoryList(searchVO);
			int totCnt = Integer.parseInt((String) result.get("resultCnt"));
			paginationInfo.setTotalRecordCount(totCnt);
			model.addAttribute("resultList", result.get("resultList"));
			model.addAttribute("resultCnt", result.get("resultCnt"));
			model.addAttribute("paginationInfo", paginationInfo);
		}
		return "rlms/fulltext/provisionList";
	}

	/** 편집계 역할(EDITOR/APPROVER/ADMIN) — 미승인 draft 열람 허용 판정 */
	private static boolean hasEditorRole() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN")
				|| auths.contains("ROLE_EDITOR") || auths.contains("ROLE_APPROVER"));
	}

	// ────────────────────────────────────────────────────────────────
	// 4) 폐지 (nullifyList)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/fulltext/nullifyList.do")
	public String nullifyList(@ModelAttribute("searchVO") PromVO searchVO,
			ModelMap model) throws Exception {

		if (!PublicFront.viewAllowed()) {
			return LOGIN_REDIRECT;
		}
		setupPaging(searchVO);
		promReadGuard.applyReadGate(searchVO);   // 분류별 열람제한(면제역할 제외)
		PaginationInfo paginationInfo = paginationOf(searchVO);

		Map<String, Object> result = promService.selectFrontNullifyList(searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		paginationInfo.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", paginationInfo);
		return "rlms/fulltext/nullifyList";
	}

	// ────────────────────────────────────────────────────────────────
	// 5) 최근 개정내용 (latestList)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/fulltext/latestList.do")
	public String latestList(@ModelAttribute("searchVO") PromVO searchVO,
			ModelMap model) throws Exception {

		if (!PublicFront.viewAllowed()) {
			return LOGIN_REDIRECT;
		}
		setupPaging(searchVO);
		promReadGuard.applyReadGate(searchVO);   // 분류별 열람제한(면제역할 제외)
		PaginationInfo paginationInfo = paginationOf(searchVO);

		Map<String, Object> result = promService.selectFrontLatestList(searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		paginationInfo.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", paginationInfo);
		return "rlms/fulltext/latestList";
	}

	/**
	 * 별표/별지서식별 개별 첨부 목록 (2026-07-30 고객 요청 9-③).
	 * 뷰어가 본문 렌더 후 비동기로 받아 각 별표(.prov-docu[id=docu-N]) 밑에 붙인다.
	 * 응답: {"success":true,"files":{"21":[{attNo,title,ext,fileSize}, ...]}}
	 */
	@ResponseBody
	@RequestMapping("/rlms/fulltext/docuFilesJson.do")
	public Map<String, Object> docuFilesJson(@RequestParam("promNo") Long promNo) throws Exception {
		Map<String, Object> res = new java.util.LinkedHashMap<>();
		Map<String, Object> byDocu = new java.util.LinkedHashMap<>();
		res.put("success", true);
		res.put("files", byDocu);

		PromVO prom = promService.selectPromDetail(promNo);
		// 열람제한 규정은 첨부 목록도 내주지 않는다(본문 가드와 동일 기준)
		if (prom == null || !promReadGuard.canRead(prom)) {
			return res;
		}
		List<narainet.rlms.docu.service.DocuVO> docus =
				docuMapper.selectDocuListCumulative(prom.getLawId(), prom.getLawNo());
		if (docus == null || docus.isEmpty()) {
			return res;
		}
		List<Long> docuNos = new java.util.ArrayList<>();
		for (narainet.rlms.docu.service.DocuVO d : docus) {
			if (d != null && d.getDocuNo() != null) {
				docuNos.add(d.getDocuNo());
			}
		}
		if (docuNos.isEmpty()) {
			return res;
		}
		for (Map<String, Object> row : relVrsnMapper.selectDocuFilesByDocuNos(docuNos)) {
			String key = String.valueOf(row.get("docuNo"));
			@SuppressWarnings("unchecked")
			List<Map<String, Object>> list = (List<Map<String, Object>>) byDocu.get(key);
			if (list == null) {
				list = new java.util.ArrayList<>();
				byDocu.put(key, list);
			}
			list.add(row);
		}
		return res;
	}

	// ────────────────────────────────────────────────────────────────
	// 본문저장 / 연혁일괄저장 — 규정 전문 → 문서 내보내기 (PDF / Word .docx)
	//   레거시 본문저장(미리 생성한 DOC/HWP/PDF 다운로드) 대응. 원본이 이관되지 않아 서버측에서 신규 생성.
	//   본문 HTML 은 뷰어와 동일(PromBodyModelSupport) + 서문(SPREAMBLE)/부칙(SBYLAW) CLOB.
	// ────────────────────────────────────────────────────────────────

	/** 문서 변환기(stateless POJO) — PDF(flying-saucer)/DOCX(ZIP+WordML). */
	private final narainet.rlms.prom.service.impl.PromDocExporter promDocExporter =
			new narainet.rlms.prom.service.impl.PromDocExporter();

	/**
	 * 본문저장 — 이 회차 전문을 문서로. fromJo/toJo 를 주면 그 조 범위만 담는다(조문별 저장).
	 * 인쇄의 [부분(조 단위)] 과 같은 범위 규칙 — 시작 조부터 종료 조의 다음 조 직전까지(항/호/목 포함).
	 * 고객 요청 2026-07-29 "조문별 저장기능 — 인쇄기능에 있는 내용 적용".
	 */
	@RequestMapping("/rlms/fulltext/exportProm.do")
	public void exportProm(@RequestParam("promNo") Long promNo,
			@RequestParam(value = "format", defaultValue = "pdf") String format,
			@RequestParam(value = "fromJo", required = false) String fromJo,
			@RequestParam(value = "toJo", required = false) String toJo,
			HttpServletRequest request, HttpServletResponse response) throws Exception {

		if (!PublicFront.viewAllowed()) {
			response.sendRedirect(request.getContextPath() + "/uat/uia/egovLoginUsr.do");
			return;
		}
		PromVO prom = promService.selectPromDetail(promNo);
		if (prom == null) { response.sendError(HttpServletResponse.SC_NOT_FOUND); return; }
		if (!promReadGuard.canRead(prom)) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		PromDocExporter.Section sec = buildExportSection(prom, request.getContextPath(), fromJo, toJo);
		String baseName = prom.getTitle();
		if (notEmpty(fromJo)) {
			baseName = baseName + "(발췌)";   // 전문과 구분되게 파일명에 표시
		}
		writeExport(response, java.util.Collections.singletonList(sec), baseName, format);
	}

	@RequestMapping("/rlms/fulltext/exportPromHistory.do")
	public void exportPromHistory(@RequestParam("lawId") Long lawId,
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId,
			@RequestParam(value = "format", defaultValue = "pdf") String format,
			HttpServletRequest request, HttpServletResponse response) throws Exception {

		if (!PublicFront.viewAllowed()) {
			response.sendRedirect(request.getContextPath() + "/uat/uia/egovLoginUsr.do");
			return;
		}
		List<PromVO> versions = promService.selectPromHistory(lawId, sysId);   // ILAW_NO DESC
		if (versions == null || versions.isEmpty()) { response.sendError(HttpServletResponse.SC_NOT_FOUND); return; }
		if (!promReadGuard.canRead(versions.get(0))) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		java.util.List<PromVO> ordered = new java.util.ArrayList<>(versions);
		java.util.Collections.reverse(ordered);   // 제정 → 최신 순으로 문서 구성
		java.util.List<PromDocExporter.Section> secs = new java.util.ArrayList<>();
		String docTitle = null;
		for (PromVO v : ordered) {
			PromVO full = promService.selectPromDetail(v.getPromNo());   // 서문/부칙 CLOB 포함 재로드
			if (full == null) continue;
			if (docTitle == null) docTitle = full.getTitle();
			secs.add(buildExportSection(full, request.getContextPath()));
		}
		if (secs.isEmpty()) { response.sendError(HttpServletResponse.SC_NOT_FOUND); return; }
		writeExport(response, secs, (docTitle != null ? docTitle : ("규정 " + lawId)) + " 연혁일괄", format);
	}

	/** PromVO → 내보내기 Section (뷰어와 동일한 본문 HTML + 서문/부칙 CLOB + 메타라인). */
	private PromDocExporter.Section buildExportSection(PromVO prom, String ctxPath) throws Exception {
		return buildExportSection(prom, ctxPath, null, null);
	}

	private PromDocExporter.Section buildExportSection(PromVO prom, String ctxPath,
			String fromJo, String toJo) throws Exception {
		ModelMap m = new ModelMap();
		PromBodyModelSupport.addBodyModel(prom, prom.getPromNo(), ctxPath, m,
				promBodyViewResolver, provVrsnService, provHtmlMapper, docuMapper,
				provViewRenderer, provTokenResolver, autoLinkService,
				promService.selectPromHistory(prom.getLawId(), prom.getSysId()));
		PromDocExporter.Section s = new PromDocExporter.Section();
		s.title = prom.getTitle();
		StringBuilder meta = new StringBuilder();
		if (notEmpty(prom.getStartDate())) meta.append("[시행 ").append(prom.getStartDate()).append("] ");
		if (notEmpty(prom.getPromDate()))  meta.append("[공포 ").append(prom.getPromDate()).append("]");
		if (notEmpty(prom.getGaejungNm())) meta.append(" · ").append(prom.getGaejungNm());
		s.metaLine = meta.toString().trim();
		String provHtml = (String) m.get("provHtml");
		String docuHtml = (String) m.get("docuHtml");
		if (notEmpty(fromJo)) {
			// 조 범위 발췌 — 서문/부칙/별표는 조 범위 밖이므로 함께 빼고 본문만 담는다.
			s.metaLine = s.metaLine + (s.metaLine.isEmpty() ? "" : " · ") + "발췌";
			s.preambleHtml = null;
			s.bylawHtml    = null;
			s.bodyHtml     = sliceProvHtmlByJo(provHtml, fromJo, notEmpty(toJo) ? toJo : fromJo);
			return s;
		}
		s.preambleHtml = prom.getPreamble();
		s.bylawHtml    = prom.getBylaw();
		s.bodyHtml = (provHtml == null ? "" : provHtml) + (docuHtml == null ? "" : docuHtml);
		return s;
	}

	/**
	 * 렌더된 전문 HTML 에서 조 범위만 남긴다 — 인쇄의 [부분(조 단위)] 과 같은 규칙:
	 * 시작 조부터, 종료 조 다음 조가 나오기 직전까지(그 사이 항/호/목·소제목 모두 포함).
	 * <p>
	 * ProvViewRenderer 는 최상위 자식마다 개행으로 끝내므로 "줄 머리가 자식 마커인 줄"이 새 블록의 시작이다.
	 * 본문에 개행이 섞여 생긴 이어지는 줄은 마커로 시작하지 않으므로 앞 블록에 그대로 붙는다.
	 *
	 * @param fromJo 시작 조 앵커(jo-N). 비어 있으면 원본 그대로
	 * @param toJo   종료 조 앵커(jo-N). 시작보다 앞서면 한 조만 담긴다
	 */
	private static String sliceProvHtmlByJo(String provHtml, String fromJo, String toJo) {
		if (provHtml == null || provHtml.isEmpty() || !notEmpty(fromJo)) {
			return provHtml == null ? "" : provHtml;
		}
		String[] lines = provHtml.split("\n", -1);
		StringBuilder out = new StringBuilder("<div class=\"prov-doc\">\n");
		boolean on = false;
		boolean seenTo = false;
		// 0번=래퍼 여는 줄, 마지막=래퍼 닫는 줄 — 자체 래퍼를 쓰므로 건너뛴다
		for (int i = 1; i < lines.length - 1; i++) {
			String line = lines[i];
			String anchor = line.startsWith("<div class=\"prov-jo\"") ? idAttrOf(line) : null;
			if (anchor != null) {
				if (seenTo) {
					break;                       // 종료 조 다음 조 = 경계
				}
				if (anchor.equals(fromJo)) {
					on = true;
				}
				if (on && anchor.equals(toJo)) {
					seenTo = true;
				}
			}
			if (on) {
				out.append(line).append('\n');
			}
		}
		out.append("</div>");
		// 범위 밖 앵커가 오면 빈 문서가 되므로 안내 문구로 대체(빈 PDF 다운로드 방지)
		if (!on) {
			return "<p class=\"prov-empty\">선택한 범위에 해당하는 조문이 없습니다.</p>";
		}
		return out.toString();
	}

	/** {@code <div ... id="jo-3" ...>} 에서 id 값. 없으면 null. */
	private static String idAttrOf(String line) {
		int i = line.indexOf("id=\"");
		if (i < 0) {
			return null;
		}
		int s = i + 4;
		int e = line.indexOf('"', s);
		return e < 0 ? null : line.substring(s, e);
	}

	/** 변환 + 다운로드 헤더 기록. */
	private void writeExport(HttpServletResponse response, java.util.List<PromDocExporter.Section> secs,
			String baseName, String format) throws Exception {
		byte[] bytes; String ext, ctype;
		if ("docx".equalsIgnoreCase(format)) {
			bytes = promDocExporter.toDocx(secs, baseName);
			ext = "docx"; ctype = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
		} else if ("hwpx".equalsIgnoreCase(format)) {
			bytes = promDocExporter.toHwpx(secs, baseName);
			ext = "hwpx"; ctype = "application/hwp+zip";
		} else {
			String fontPath;
			try { fontPath = propertyService.getString("Globals.rlms.PdfFontPath"); }
			catch (Exception e) { fontPath = null; }
			if (fontPath == null || fontPath.trim().isEmpty()) fontPath = "C:/Windows/Fonts/malgun.ttf";
			bytes = promDocExporter.toPdf(secs, baseName, fontPath);
			ext = "pdf"; ctype = "application/pdf";
		}
		String fname = sanitizeFileName(baseName) + "." + ext;
		String enc = java.net.URLEncoder.encode(fname, "UTF-8").replace("+", "%20");
		// RFC 6266: 비확장 filename 은 ASCII 폴백(비ASCII→'_'), 한글 원본명은 filename* 로만 전달.
		String asciiName = fname.replaceAll("[^\\x20-\\x7E]", "_");
		response.reset();
		response.setContentType(ctype);
		response.setHeader("Content-Disposition", "attachment; filename=\"" + asciiName + "\"; filename*=UTF-8''" + enc);
		response.setContentLength(bytes.length);
		response.getOutputStream().write(bytes);
		response.getOutputStream().flush();
	}

	private static boolean notEmpty(String s) { return s != null && !s.trim().isEmpty(); }
	private static String sanitizeFileName(String s) {
		if (s == null || s.trim().isEmpty()) return "regulation";
		return s.trim().replaceAll("[\\\\/:*?\"<>|\\r\\n\\t]", "_");
	}

	// 상세검색은 별도 페이지가 아니라 연혁검색(historyList) 의 레이어팝업 모달 폼 →
	// historyList.do?detailMode=Y 로 제출(applyAdvancedParams + selectDetailSearch).
	// (구 standalone /rlms/fulltext/detailSearch.do 액션은 제거됨.)

	// ────────────────────────────────────────────────────────────────
	// helpers
	// ────────────────────────────────────────────────────────────────

	/** 상세검색 모달 폼 데이터(소관부서/규정분류 드롭다운 + 구분ID→라벨 맵) 모델 주입. */
	private void addDetailDropdowns(ModelMap model) {
		model.addAttribute("buseoList", promService.selectDetailBuseoList());
		model.addAttribute("cateList", promService.selectDetailCateList());
		java.util.Map<String, String> gubunLabelMap = new java.util.HashMap<>();
		for (Map<String, Object> g : ftGubunService.gubunList()) {
			gubunLabelMap.put(String.valueOf(g.get("code")), String.valueOf(g.get("label")));
		}
		model.addAttribute("gubunLabelMap", gubunLabelMap);
	}

	/** 자음/영문 첫글자 → SUBSTR 경계 계산 + 검색어 있는데 검색단위 미선택 시 제목 기본. */
	private void applyAdvancedParams(PromVO searchVO) {
		Integer hp = searchVO.getHangulPrefix();
		Integer ep = searchVO.getEnglishPrefix();
		if (hp != null && hp >= 0 && hp < 14) {
			searchVO.setPrefixType("HAN");
			searchVO.setPrefixFrom(HANGUL_ANCHORS[hp]);
			searchVO.setPrefixTo(HANGUL_ANCHORS[hp + 1]);
		} else if (ep != null && ep >= 0 && ep < 26) {
			char c = (char) ('A' + ep);
			searchVO.setPrefixType("ENG");
			searchVO.setPrefixFrom(String.valueOf(c));
			searchVO.setPrefixTo(String.valueOf(Character.toLowerCase(c)));
		}
		boolean anyUnit = "TRUE".equals(searchVO.getStTitle()) || "TRUE".equals(searchVO.getStProvision())
				|| "TRUE".equals(searchVO.getStDocument()) || "TRUE".equals(searchVO.getStParty());
		if (searchVO.getSearchKeyword() != null && !searchVO.getSearchKeyword().trim().isEmpty() && !anyUnit) {
			searchVO.setStTitle("TRUE");
		}
	}

	private void setupPaging(PromVO vo) {
		vo.setPageUnit(propertyService.getInt("pageUnit"));
		vo.setPageSize(propertyService.getInt("pageSize"));
		PaginationInfo p = new PaginationInfo();
		p.setCurrentPageNo(vo.getPageIndex());
		p.setRecordCountPerPage(vo.getPageUnit());
		p.setPageSize(vo.getPageSize());
		vo.setFirstIndex(p.getFirstRecordIndex());
		vo.setLastIndex(p.getLastRecordIndex());
		vo.setRecordCountPerPage(p.getRecordCountPerPage());
	}

	private PaginationInfo paginationOf(PromVO vo) {
		PaginationInfo p = new PaginationInfo();
		p.setCurrentPageNo(vo.getPageIndex());
		p.setRecordCountPerPage(vo.getPageUnit());
		p.setPageSize(vo.getPageSize());
		return p;
	}
}
