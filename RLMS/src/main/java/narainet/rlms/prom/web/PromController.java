/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/web/PromController.java
 *
 * 법령(TB_PROM) 관리 Controller.
 * 레거시 /manage/page/promulgation.html?pAct=XXX → /rlms/prom/*.do 개별 메서드로 분리.
 *
 * 인증: EgovUserDetailsHelper (Spring Security 연동)
 * XSS: 본문 CLOB 5종 입력에 unscript 적용
 */
package narainet.rlms.prom.web;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.prom.service.DiffLineVO;
import narainet.rlms.prom.service.PromReadGuard;
import narainet.rlms.prom.service.PromService;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prom.service.ProvHtmlService;
import narainet.rlms.prom.service.ProvHtmlVO;
import narainet.rlms.prom.service.ProvVrsnService;
import narainet.rlms.prom.service.ProvVrsnVO;
import narainet.rlms.prom.service.ValidationIssueVO;
import narainet.rlms.prom.service.ValidationService;

/**
 * 법령 관리 Controller
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성 (레거시 PromulgationController → RLMS 이관)
 * </pre>
 */
@Controller
public class PromController {

	private static final Logger LOGGER = LoggerFactory.getLogger(PromController.class);

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "promService")
	private PromService promService;

	/** 분류별 열람제한 가드 (TB_CATE_READER) — 목록 SQL 게이트 + 상세/신구대조/미리보기 단건 가드 */
	@Resource(name = "promReadGuard")
	private PromReadGuard promReadGuard;

	/** 작성권한 가드 (관리자 OR TB_CATE_OWNER 분류 작성자) — 삭제 계열 방어 */
	@Resource
	private narainet.rlms.prom.service.PromEditGuard promEditGuard;

	@Resource(name = "provVrsnService")
	private ProvVrsnService provVrsnService;

	/** 규정미리보기 본문 렌더러 (사용자 전문뷰어와 동일 — law.go.kr/레거시 스타일 계층 출력) */
	private final narainet.rlms.prom.service.impl.ProvViewRenderer provViewRenderer =
			new narainet.rlms.prom.service.impl.ProvViewRenderer();

	@Resource(name = "provTokenResolver")
	private narainet.rlms.prom.service.impl.ProvTokenResolver provTokenResolver;

	@Resource(name = "autoLinkService")
	private narainet.rlms.prom.service.impl.AutoLinkService autoLinkService;

	@Resource
	private narainet.rlms.docu.mapper.DocuMapper docuMapper;

	@Resource
	private narainet.rlms.prom.mapper.ProvHtmlMapper provHtmlMapper;

	/** 규정형식(SPROV_FG)별 본문 표시 방식 결정 — 레거시 frontView 분기 */
	@Resource(name = "promBodyViewResolver")
	private narainet.rlms.prom.service.impl.PromBodyViewResolver promBodyViewResolver;

	@Resource(name = "provHtmlService")
	private ProvHtmlService provHtmlService;

	@Resource(name = "validationService")
	private ValidationService validationService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	@Resource(name = "egovMessageSource")
	private EgovMessageSource egovMessageSource;

	// ────────────────────────────────────────────────────────────────
	// 목록 / 상세
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/prom/selectPromList.do")
	public String selectPromList(@ModelAttribute("searchVO") PromVO searchVO,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();

		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());
		promReadGuard.applyReadGate(searchVO);   // 분류별 열람제한(면제역할 제외)

		Map<String, Object> result = promService.selectPromList(searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		pi.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("sessionUniqId",
				(user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		return "rlms/prom/promList";
	}

	@RequestMapping("/rlms/prom/selectPromDetail.do")
	public String selectPromDetail(@RequestParam("promNo") Long promNo,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		PromVO vo = promService.selectPromDetail(promNo);
		if (vo != null && !promReadGuard.canRead(vo)) {
			throw new org.springframework.security.access.AccessDeniedException(
					"이 규정은 열람 권한이 제한되어 있습니다. (지정된 부서/개인만 열람 가능)");
		}
		model.addAttribute("result", vo);
		// 조항 본문 목록 — promDetail.jsp 본문(${resultList})이 이 진입점에서 안 채워져
		// 항상 "조항이 아직 없습니다" 빈 화면으로 보이던 버그 수정(selectProvHtmlList.do 와 동일 조회).
		model.addAttribute("resultList", provHtmlService.selectProvHtmlList(promNo));
		// 같은 법령의 모든 개정본
		if (vo != null) {
			model.addAttribute("history", promService.selectPromHistory(vo.getLawId(), vo.getSysId()));
		}
		return "rlms/prom/promDetail";
	}

	// ────────────────────────────────────────────────────────────────
	// 등록 / 수정 — 규정 IDE(/rlms/prom/editor.do)로 일원화.
	// 레거시 핸들러(insertPromView/insertProm/updatePromView/updateProm)는 폐기(2026-07-09):
	// 화면 링크가 없고, promEditGuard(분류 작성자 가드) 없이 URL 직접 POST 로
	// 소관 외 분류에 규정을 생성/수정할 수 있는 무가드 경로였음. 정본=savePromMeta.do.
	// ────────────────────────────────────────────────────────────────

	// ────────────────────────────────────────────────────────────────
	// 삭제
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/prom/deleteProm.do")
	public String deleteProm(@RequestParam("promNo") Long promNo,
			org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		// 작성권한 가드 — 관리자 OR 분류(상속 포함) 작성자만 삭제 (2026-07-09, IDE 삭제류와 동일)
		promEditGuard.assertCanEditProm(promNo);
		promService.deleteProm(promNo);
		redirectAttributes.addFlashAttribute("resultMsg", egovMessageSource.getMessage("prom.deleted"));
		return "redirect:/rlms/prom/selectPromList.do";
	}

	@RequestMapping("/rlms/prom/deletePromList.do")
	public String deletePromList(@RequestParam("promNoList") String promNoListCsv,
			org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		List<Long> ids = Arrays.stream(promNoListCsv.split(","))
				.map(String::trim).filter(s -> !s.isEmpty())
				.map(Long::valueOf).collect(java.util.stream.Collectors.toList());
		// 작성권한 가드 — 전건 선검사 후 일괄 삭제 (일부만 지워지는 부분실패 방지)
		for (Long id : ids) {
			promEditGuard.assertCanEditProm(id);
		}
		promService.deletePromList(ids);
		redirectAttributes.addFlashAttribute("resultMsg", egovMessageSource.getMessageArgs("prom.multiple.delete.success", new Object[]{ids.size()}));
		return "redirect:/rlms/prom/selectPromList.do";
	}

	// ────────────────────────────────────────────────────────────────
	// 이력 검색 — 정렬(updatePromSequence)/분류이동(moveCategory) 레거시 핸들러는
	// 폐기(2026-07-09): 화면 링크 없음 + promEditGuard 무가드. 정본=IDE moveCategoryJson.do.
	//
	// searchHistory.do 도 폐기(2026-07-29): 어느 화면도 링크하지 않는데, promList 뷰를 돌려주면서
	// paginationInfo 를 안 담아 호출하면 그대로 500 이 났다(전 화면 스윕에서 발견). 사용자 이력 검색의
	// 정본은 front 의 /rlms/fulltext/historyList.do 다. 서비스·매퍼 질의(selectSearchHistoryList)까지 함께 제거.
	// ────────────────────────────────────────────────────────────────

	// ────────────────────────────────────────────────────────────────
	// 신구대조 비교 결과 (DiffLineVO 표시)
	//   진입: /rlms/fulltext/comparisonList.do?lawId=X → 좌/우 promNo 선택 →
	//          /rlms/prom/diffByPromNo.do?leftPromNo=A&rightPromNo=B
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/prom/diffByPromNo.do")
	public String diffByPromNo(@RequestParam("leftPromNo") Long leftPromNo,
			@RequestParam("rightPromNo") Long rightPromNo,
			ModelMap model,
			org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes) throws Exception {

		// 공개열람 모드면 익명도 신구대조 열람 가능(뷰어 동선의 연장) — 열람제한 가드는 아래에서 동일 적용
		if (!narainet.rlms.common.service.PublicFront.viewAllowed()) {
			return LOGIN_REDIRECT;
		}
		if (leftPromNo == null || rightPromNo == null || leftPromNo.equals(rightPromNo)) {
			redirectAttributes.addFlashAttribute("resultMsg",
					egovMessageSource.getMessage("prom.diff.invalid"));
			return "redirect:/rlms/fulltext/comparisonList.do";
		}

		PromVO leftProm  = promService.selectPromDetail(leftPromNo);
		PromVO rightProm = promService.selectPromDetail(rightPromNo);
		if ((leftProm != null && !promReadGuard.canRead(leftProm))
				|| (rightProm != null && !promReadGuard.canRead(rightProm))) {
			throw new org.springframework.security.access.AccessDeniedException(
					"이 규정은 열람 권한이 제한되어 있습니다. (지정된 부서/개인만 열람 가능)");
		}
		List<DiffLineVO> diffList = provVrsnService.diffByPromNo(leftPromNo, rightPromNo);

		// 변경 유형별 카운트 (UI 요약)
		int added = 0, removed = 0, modified = 0, unchanged = 0;
		for (DiffLineVO d : diffList) {
			if ("ADDED".equals(d.getChangeType())) added++;
			else if ("REMOVED".equals(d.getChangeType())) removed++;
			else if ("MODIFIED".equals(d.getChangeType())) modified++;
			else unchanged++;
		}

		model.addAttribute("leftProm",  leftProm);
		model.addAttribute("rightProm", rightProm);
		model.addAttribute("diffList",  diffList);
		model.addAttribute("addedCnt",     added);
		model.addAttribute("removedCnt",   removed);
		model.addAttribute("modifiedCnt",  modified);
		model.addAttribute("unchangedCnt", unchanged);

		// 별표/별지서식 대조 (2026-07-16) — 좌/우 누적 뷰를 SITEM 기준 매칭.
		// 코퍼스가 소규모(회차당 수 건)라 조문처럼 SQL FULL OUTER JOIN 하지 않고 Java 측 비교.
		List<DiffLineVO> docuDiff = buildDocuDiff(leftProm, rightProm);
		int dAdded = 0, dRemoved = 0, dModified = 0, dUnchanged = 0;
		for (DiffLineVO d : docuDiff) {
			if ("ADDED".equals(d.getChangeType())) dAdded++;
			else if ("REMOVED".equals(d.getChangeType())) dRemoved++;
			else if ("MODIFIED".equals(d.getChangeType())) dModified++;
			else dUnchanged++;
		}
		model.addAttribute("docuDiffList",     docuDiff);
		model.addAttribute("docuAddedCnt",     dAdded);
		model.addAttribute("docuRemovedCnt",   dRemoved);
		model.addAttribute("docuModifiedCnt",  dModified);
		model.addAttribute("docuUnchangedCnt", dUnchanged);
		return "rlms/prom/promDiff";
	}

	/**
	 * 별표/별지서식 회차간 대조 — 좌/우 회차의 누적(상속 포함) 별표 목록을 SITEM 으로 매칭.
	 * 노출 기준은 뷰어(renderDocuSection)와 동일: tombstone(SDISP_YN='N')·NULLIFY(삭제) 는 부재로 간주.
	 * 비교 = 제목+본문(trim). 변경유형 ADDED/REMOVED/MODIFIED/UNCHANGED (DiffLineVO 재사용).
	 */
	private List<DiffLineVO> buildDocuDiff(PromVO leftProm, PromVO rightProm) {
		List<DiffLineVO> out = new java.util.ArrayList<>();
		if (leftProm == null || rightProm == null
				|| leftProm.getLawId() == null || rightProm.getLawId() == null) return out;
		java.util.Map<String, narainet.rlms.docu.service.DocuVO> left  = docuDiffMap(leftProm);
		java.util.Map<String, narainet.rlms.docu.service.DocuVO> right = docuDiffMap(rightProm);
		java.util.Set<String> keys = new java.util.TreeSet<>();
		keys.addAll(left.keySet());
		keys.addAll(right.keySet());
		for (String k : keys) {
			narainet.rlms.docu.service.DocuVO l = left.get(k), r = right.get(k);
			DiffLineVO d = new DiffLineVO();
			d.setFullItem(k);
			d.setLeftText(docuDiffText(l));
			d.setRightText(docuDiffText(r));
			if (l == null)      d.setChangeType("ADDED");
			else if (r == null) d.setChangeType("REMOVED");
			else {
				boolean same = safeTrim(l.getTitle()).equals(safeTrim(r.getTitle()))
						&& safeTrim(l.getContents()).equals(safeTrim(r.getContents()));
				d.setChangeType(same ? "UNCHANGED" : "MODIFIED");
				if (!same && r.getGaejungType() != null) d.setGaejungType(r.getGaejungType());
			}
			out.add(d);
		}
		return out;
	}

	private java.util.Map<String, narainet.rlms.docu.service.DocuVO> docuDiffMap(PromVO prom) {
		java.util.Map<String, narainet.rlms.docu.service.DocuVO> map = new java.util.LinkedHashMap<>();
		List<narainet.rlms.docu.service.DocuVO> rows;
		try {
			rows = docuMapper.selectDocuListCumulative(prom.getLawId(), prom.getLawNo());
		} catch (Exception e) {
			return map;   // 별표 대조는 부가 기능 — 조회 실패가 조문 대조를 막지 않음
		}
		if (rows == null) return map;
		for (narainet.rlms.docu.service.DocuVO d : rows) {
			if (d == null || "N".equals(d.getDispYn())) continue;                    // tombstone
			String g = d.getGaejungType() == null ? "" : d.getGaejungType().trim();
			if ("NULLIFY".equals(g)) continue;                                       // 삭제 별표 — 부재 취급
			String key = (d.getItem() != null && !d.getItem().trim().isEmpty())
					? d.getItem().trim() : ("#" + d.getDocuNo());
			map.put(key, d);
		}
		return map;
	}

	private String docuDiffText(narainet.rlms.docu.service.DocuVO d) {
		if (d == null) return "";
		StringBuilder sb = new StringBuilder(safeTrim(d.getTitle()));
		String c = safeTrim(d.getContents());
		if (!c.isEmpty()) {
			if (sb.length() > 0) sb.append('\n');
			sb.append(c);
		}
		return sb.toString();
	}

	private static String safeTrim(String s) { return s == null ? "" : s.trim(); }

	// ────────────────────────────────────────────────────────────────
	// 유효성 검사 — PGM-001-01-04 (관리자 메뉴)
	// ────────────────────────────────────────────────────────────────

	/**
	 * 연혁별 유효성 검사 — 특정 lawId 의 모든 promNo 검증.
	 * IDE/링크는 promNo 를 보내고 검증은 lawId 기준이므로, lawId 또는 promNo 둘 다 허용한다
	 * (promNo 만 오면 해당 회차의 lawId 로 해석). 둘 다 없으면 친절한 안내 화면.
	 */
	@RequestMapping("/rlms/prom/validateHistory.do")
	public String validateHistory(
			@RequestParam(value = "lawId",  required = false) Long lawId,
			@RequestParam(value = "promNo", required = false) Long promNo,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		if (lawId == null && promNo != null) {
			narainet.rlms.prom.service.PromVO p = promService.selectPromDetail(promNo);
			if (p != null) lawId = p.getLawId();
		}
		if (lawId == null) {
			model.addAttribute("issues", new java.util.ArrayList<ValidationIssueVO>());
			model.addAttribute("scope", "(대상 미지정)");
			model.addAttribute("totalCnt", 0);
			model.addAttribute("resultMsg", "검증할 규정을 선택한 뒤 다시 실행하세요.");
			return "rlms/prom/promValidate";
		}
		List<ValidationIssueVO> issues = validationService.validateHistory(lawId);
		model.addAttribute("issues", issues);
		// scope 는 화면 표시 문자열 — 내부 필드명(lawId=) 대신 규정명 기반 문구(2026-07-16)
		model.addAttribute("scope", scopeLabelByLawId(lawId) + " 전체 연혁");
		model.addAttribute("totalCnt", issues.size());
		return "rlms/prom/promValidate";
	}

	/** 규정별 유효성 검사 — SEXISTING_YN='Y' 전체 검증 (운영 데이터 헬스 체크) */
	@RequestMapping("/rlms/prom/validateExisting.do")
	public String validateExisting(ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		List<ValidationIssueVO> issues = validationService.validateExistingAll();
		model.addAttribute("issues", issues);
		model.addAttribute("scope", "운영 중 모든 규정");
		model.addAttribute("totalCnt", issues.size());
		return "rlms/prom/promValidate";
	}

	/** 단일 법령 유효성 검사 */
	@RequestMapping("/rlms/prom/validateProm.do")
	public String validateProm(@RequestParam("promNo") Long promNo,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		List<ValidationIssueVO> issues = validationService.validateProm(promNo);
		model.addAttribute("issues", issues);
		narainet.rlms.prom.service.PromVO vp = promService.selectPromDetail(promNo);
		model.addAttribute("scope", (vp != null && vp.getTitle() != null ? vp.getTitle() : "규정") + " (선택한 회차)");
		model.addAttribute("totalCnt", issues.size());
		return "rlms/prom/promValidate";
	}

	/** 유효성 검사 scope 표시용 — lawId 의 현행(없으면 최신) 회차 제목. 못 찾으면 "선택한 규정". */
	private String scopeLabelByLawId(Long lawId) {
		try {
			List<narainet.rlms.prom.service.PromVO> hist = promService.selectPromHistory(lawId, null);
			if (hist != null && !hist.isEmpty() && hist.get(0).getTitle() != null) {
				return hist.get(0).getTitle();
			}
		} catch (Exception ignore) { }
		return "선택한 규정";
	}

	// ────────────────────────────────────────────────────────────────
	// 미리보기 — PGM-001-01-02 (관리자 메뉴)
	// ────────────────────────────────────────────────────────────────

	/**
	 * 본문 미리보기.
	 * promNo 로 prom 메타 + ProvHtmlVO 목록 + ProvVrsnVO 목록 모두 보여줌.
	 * 본문 종류(provFlag) 에 따라 화면이 갈리지만 단일 JSP 가 분기 처리.
	 */
	@RequestMapping("/rlms/prom/preview.do")
	public String preview(@RequestParam("promNo") Long promNo,
			javax.servlet.http.HttpServletRequest request, ModelMap model,
			org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		PromVO prom = promService.selectPromDetail(promNo);
		if (prom == null) {
			redirectAttributes.addFlashAttribute("resultMsg",
					egovMessageSource.getMessage("prom.notfound"));
			return "redirect:/rlms/prom/selectPromList.do";
		}
		if (!promReadGuard.canRead(prom)) {
			throw new org.springframework.security.access.AccessDeniedException(
					"이 규정은 열람 권한이 제한되어 있습니다. (지정된 부서/개인만 열람 가능)");
		}
		model.addAttribute("prom", prom);
		// 규정형식(SPROV_FG)별 본문 표시 — 사용자 전문뷰어(provisionList.do)와 동일 분기
		// (연혁을 먼저 조회해 본문 렌더의 조문 인라인 개정 주석 재료로도 사용 — 뷰어 파리티)
		java.util.List<PromVO> history = promService.selectPromHistory(prom.getLawId(), prom.getSysId());
		PromBodyModelSupport.addBodyModel(prom, promNo, request.getContextPath(), model,
				promBodyViewResolver, provVrsnService, provHtmlMapper, docuMapper,
				provViewRenderer, provTokenResolver, autoLinkService, history);
		// 연혁 아코디언 (사용자 전문뷰어와 동일)
		model.addAttribute("history", history);
		return "rlms/prom/promPreview";
	}

}
