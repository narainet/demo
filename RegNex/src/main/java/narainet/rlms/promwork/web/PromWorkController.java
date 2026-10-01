/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/promwork/web/PromWorkController.java
 *
 * 법령 승인 워크플로 Controller.
 *
 * 운영 메뉴 매핑 (레거시 → RLMS):
 *   PGM-001-01-09 작업승인관리   → /rlms/promwork/selectPromWorkList.do
 *   PGM-001-01-08 승인요청       → /rlms/promwork/insertPromWorkView.do + insertPromWork.do (팝업)
 *                                + /rlms/promwork/approvePromWork.do  (관리자 승인)
 *                                + /rlms/promwork/rejectPromWork.do   (관리자 반려)
 *   PGM-001-01-11 수정권한요청   → 폐지(2026-07-20 사용자 결정) — 현행 회차 편집은 작성권한 가드만
 *   PGM-001-01-12 제·개정내역    → /rlms/promwork/selectPromWorkHistory.do
 *
 *   ※ PGM 권한 코드 가드는 A 작업(사용자/권한 시스템) 에서 통합 — 현재는 로그인 여부만 체크.
 */
package narainet.rlms.promwork.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.prom.service.PromEditGuard;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.promwork.service.PromWorkService;
import narainet.rlms.promwork.service.PromWorkActLogVO;
import narainet.rlms.promwork.service.PromWorkStatus;
import narainet.rlms.promwork.service.PromWorkVO;

@Controller
public class PromWorkController {

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "promWorkService")
	private PromWorkService promWorkService;

	@Resource
	private PromMapper promMapper;

	@Resource
	private PromEditGuard promEditGuard;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	@Resource(name = "egovMessageSource")
	private EgovMessageSource egovMessageSource;

	// ────────────────────────────────────────────────────────────────
	// 1) 작업승인관리 — 목록 (PGM-001-01-09)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/promwork/selectPromWorkList.do")
	public String selectPromWorkList(@ModelAttribute("searchVO") PromWorkVO searchVO,
			@RequestParam(value = "st", required = false) String st,
			ModelMap model) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}

		// 상태 필터: URL 엔 ASCII 코드(st)만, 내부 SSTATUS(한글 정본)로 매핑해 SQL 에 전달.
		// 합성 필터(PENDING/MYREJ)는 배지 카운트와 동일 기준의 전용 조건으로 — 배지 숫자와
		// 클릭 후 목록이 3중으로 어긋나던 갭 교정(2026-07-09).
		String stCode = PromWorkStatus.normalizeCode(st);
		if (PromWorkStatus.CODE_PENDING.equals(stCode)) {
			searchVO.setSearchPending(true);
		} else if (PromWorkStatus.CODE_MYREJ.equals(stCode)) {
			LoginVO me = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
			searchVO.setSearchMyRejectedUserId(me != null ? me.getId() : "-");
		} else {
			searchVO.setSearchStatus(PromWorkStatus.toStatus(st));
		}

		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(searchVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(searchVO.getPageUnit());
		paginationInfo.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		searchVO.setLastIndex(paginationInfo.getLastRecordIndex());
		searchVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		Map<String, Object> result = promWorkService.selectPromWorkList(searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		paginationInfo.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("searchStatusCode", PromWorkStatus.normalizeCode(st));  // 드롭다운 선택/페이징 폼 재현용
		model.addAttribute("statusOptions", PromWorkStatus.options());             // 코드 → 라벨(한글)

		return "rlms/promwork/promWorkList";
	}

	// ────────────────────────────────────────────────────────────────
	// 1-b) 제·개정내역 관리 — 전역 액션 로그 목록 (TB_PROM_ACT_LOG)
	//   "작업승인관리"(TB_PROM_WRK 결재흐름)와 구분되는 화면. 규정의 제·개정/편집/삭제/승인
	//   작업내역(감사로그)을 전역 검색·열람하고, 각 행에서 그 회차 이력으로 진입.
	//   (레거시 ActionLogController / statistic_action_log_search 파리티)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/promwork/selectPromWorkActLogList.do")
	public String selectPromWorkActLogList(@ModelAttribute("searchVO") PromWorkActLogVO searchVO,
			ModelMap model) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}

		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(searchVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(searchVO.getPageUnit());
		paginationInfo.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		searchVO.setLastIndex(paginationInfo.getLastRecordIndex());
		searchVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		Map<String, Object> result = promWorkService.selectActLogList(searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		paginationInfo.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", paginationInfo);

		return "rlms/promwork/promWorkActLogList";
	}

	// ────────────────────────────────────────────────────────────────
	// 2) 승인요청 (PGM-001-01-08) — 사용자가 신청
	// ────────────────────────────────────────────────────────────────

	/** 신청요청 폼 (팝업) — promNo 받아서 prom 정보 + 최신 work 상태 표시 */
	@RequestMapping("/rlms/promwork/insertPromWorkView.do")
	public String insertPromWorkView(@RequestParam("promNo") Long promNo,
			@RequestParam(value = "returnUrl", required = false) String returnUrl,
			ModelMap model) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}

		PromWorkVO latest = promWorkService.selectLatestByPromNo(promNo);
		if (latest == null) {
			latest = new PromWorkVO();
			latest.setPromNo(promNo);
		}
		fillPromInfo(latest);   // 워크 이력 없는 규정 — 제목/분류/상태를 TB_PROM 에서 보강
		model.addAttribute("promWorkVO", latest);
		model.addAttribute("blockMsg", requestBlockMsg(latest.getStatus()));   // 중복 요청 가드
		model.addAttribute("mode", "insert");
		model.addAttribute("returnUrl", safeReturnUrl(returnUrl));   // 제출 후 복귀(IDE 등) — 내부 경로만
		return "rlms/promwork/promWorkInsert";
	}

	/** 신청요청 처리 */
	@RequestMapping("/rlms/promwork/insertPromWork.do")
	public String insertPromWork(@ModelAttribute("promWorkVO") PromWorkVO vo,
			@RequestParam(value = "returnUrl", required = false) String returnUrl,
			RedirectAttributes redirectAttributes) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		// 소유권 가드 — 관리자 또는 대상 규정 분류(상속 포함) 작성자만 승인요청 가능.
		// IDE 는 canEdit=false 면 버튼을 숨기지만 서버 검사가 없어 직접 POST 우회가 가능했음(2026-07-09).
		promEditGuard.assertCanEditProm(vo.getPromNo());
		// 서버측 중복 요청 가드 — 화면 가드 우회(직접 POST) 방지. 차단 사유는 flash 로 안내(2026-07-09).
		PromWorkVO cur = promWorkService.selectLatestByPromNo(vo.getPromNo());
		String block = requestBlockMsg(cur != null ? cur.getStatus() : null);
		if (block != null) {
			redirectAttributes.addFlashAttribute("resultMsg", block);
			return "redirect:/rlms/promwork/selectPromWorkList.do?st=REQ";
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		applyLoginUser(vo, user);

		try {
			promWorkService.requestApproval(vo);
		} catch (IllegalStateException e) {
			// 서비스 잠금 후 재검사(경합/인터리브)에 걸림 — 사유 안내
			redirectAttributes.addFlashAttribute("resultMsg", e.getMessage());
			return "redirect:/rlms/promwork/selectPromWorkList.do?st=REQ";
		}
		// flash(세션 1회성) — model 로 넣으면 redirect URL 쿼리 파라미터로 붙어 한글이 깨짐
		redirectAttributes.addFlashAttribute("resultMsg",
				egovMessageSource.getMessage("promwork.requested"));
		// IDE 등에서 진입했으면 원화면 복귀 — 상태라벨('승인요청 진행 중')로 결과 확인 (2026-07-09)
		String back = safeReturnUrl(returnUrl);
		return "redirect:" + (back != null ? back : "/rlms/promwork/selectPromWorkList.do");
	}

	/** 신청승인 처리 */
	@RequestMapping("/rlms/promwork/approvePromWork.do")
	public String approvePromWork(@ModelAttribute("promWorkVO") PromWorkVO vo,
			RedirectAttributes redirectAttributes) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		assertApprover();
		// 상태 가드 — 최신 워크가 '승인요청'이 아니면(이미 처리됨 등) 중복 승인 차단(2026-07-08).
		// 목록 LATEST_YN 교정과 쌍 — 직접 POST·낡은 화면에서의 옛 회차 재승격 방지.
		PromWorkVO latest = promWorkService.selectLatestByPromNo(vo.getPromNo());
		if (latest == null || !PromWorkVO.STATUS_REQ_PEND.equals(latest.getStatus())) {
			redirectAttributes.addFlashAttribute("resultMsg",
					egovMessageSource.getMessage("promwork.stale"));
			return "redirect:/rlms/promwork/selectPromWorkList.do";
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		applyLoginUser(vo, user);

		try {
			promWorkService.approveRequest(vo);
		} catch (IllegalStateException e) {
			redirectAttributes.addFlashAttribute("resultMsg", e.getMessage());
			return "redirect:/rlms/promwork/selectPromWorkList.do";
		}
		redirectAttributes.addFlashAttribute("resultMsg",
				egovMessageSource.getMessage("promwork.approved"));
		// 승인 직후 필수 열람 지정 유도 — 목록 JSP 가 dutyPromNo 를 보고 지정 모달을 자동으로 연다(건너뛰기 가능)
		return "redirect:/rlms/promwork/selectPromWorkList.do?dutyPromNo=" + vo.getPromNo();
	}

	/** 신청반려 처리 */
	@RequestMapping("/rlms/promwork/rejectPromWork.do")
	public String rejectPromWork(@ModelAttribute("promWorkVO") PromWorkVO vo,
			RedirectAttributes redirectAttributes) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		assertApprover();
		// 반려 사유 필수 — 빈 사유면 편집자 IDE 의 반려사유 카드가 표시되지 않아 인지 단절(2026-07-09)
		if (vo.getReason() == null || vo.getReason().trim().isEmpty()) {
			redirectAttributes.addFlashAttribute("resultMsg", "반려 사유를 입력해야 합니다.");
			return "redirect:/rlms/promwork/selectPromWorkList.do";
		}
		// 상태 가드 — approvePromWork 와 동일(승인요청 상태의 최신행만 반려 가능)
		PromWorkVO latest = promWorkService.selectLatestByPromNo(vo.getPromNo());
		if (latest == null || !PromWorkVO.STATUS_REQ_PEND.equals(latest.getStatus())) {
			redirectAttributes.addFlashAttribute("resultMsg",
					egovMessageSource.getMessage("promwork.stale"));
			return "redirect:/rlms/promwork/selectPromWorkList.do";
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		applyLoginUser(vo, user);

		try {
			promWorkService.rejectRequest(vo);
		} catch (IllegalStateException e) {
			redirectAttributes.addFlashAttribute("resultMsg", e.getMessage());
			return "redirect:/rlms/promwork/selectPromWorkList.do";
		}
		redirectAttributes.addFlashAttribute("resultMsg",
				egovMessageSource.getMessage("promwork.rejected"));
		return "redirect:/rlms/promwork/selectPromWorkList.do";
	}

	// (수정권한요청 흐름(PGM-001-01-11) 폐지 — 2026-07-20 사용자 결정.
	//  현행 회차 편집 = 작성권한(분류 작성자/소관부서) 가드만으로 허용. 관련 화면·전이·배지 축 제거.)

	/** 승인요청 팝업 정보 보강 — 워크 이력이 없는 규정(레거시 현행 등)은
	 *  selectLatestByPromNo(최신 워크행 조인)가 null 이라 제목/분류/상태가 비어 표시되는 갭을
	 *  TB_PROM 직접 조회로 채운다. 상태는 현행 여부로 표시. */
	private void fillPromInfo(PromWorkVO vo) {
		if (vo == null || vo.getPromNo() == null) return;
		if (notBlank(vo.getPromTitle()) && notBlank(vo.getStatus())) return;
		PromVO p = promMapper.selectPromByNo(vo.getPromNo());
		if (p == null) return;
		if (!notBlank(vo.getPromTitle())) vo.setPromTitle(p.getTitle());
		if (!notBlank(vo.getCateNm()))    vo.setCateNm(p.getCateNm());
		if (!notBlank(vo.getStatus())) {
			vo.setStatus("Y".equals(p.getExistingYn())
					? "현행 운영중 (결재 이력 없음)" : "작업중 (결재 이력 없음)");
		}
	}

	private static boolean notBlank(String s) { return s != null && !s.trim().isEmpty(); }

	/** 승인권한(APPROVER/ADMIN) 보유 여부 — URL 층 L4 규칙(context-security \A/rlms/promwork/(approve|reject)... )과
	 *  동일 기준의 방어심층 + 배지/버튼 노출 판정. getAuthorities() 는 RoleHierarchy 미확장(사용자당 1역할)이라
	 *  ROLE_ADMIN 을 반드시 함께 열거(PromReadGuard.isExempt 관례). */
	private boolean hasApproverRole() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN") || auths.contains("ROLE_APPROVER"));
	}

	/** 승인자 액션 강제 — 비승인자는 AccessDeniedException(URL층 L4 통과 후의 방어심층 —
	 *  직접 POST 는 L4 가 먼저 차단한다). 두 층 모두 403 + accessDenied.do 로 나간다. */
	private void assertApprover() {
		if (!hasApproverRole()) {
			throw new AccessDeniedException("승인/반려 처리는 승인자(APPROVER) 또는 관리자만 할 수 있습니다.");
		}
	}

	/** 제출 후 복귀 URL 화이트리스트 — 내부(/rlms/) 경로만 허용, 그 외 null (open redirect 방지) */
	private static String safeReturnUrl(String url) {
		if (url == null) return null;
		String u = url.trim();
		if (!u.startsWith("/rlms/")) return null;
		if (u.contains("//") || u.contains(":") || u.contains("\r") || u.contains("\n")) return null;
		return u;
	}

	/** 요청 불가 상태 안내문 — null 이면 요청 가능. 이미 승인요청 진행 중이면 중복 요청 차단. */
	private String requestBlockMsg(String status) {
		if ("승인요청".equals(status))
			return "이미 승인요청이 진행 중입니다. 관리자 승인을 기다려 주세요.";
		return null;
	}

	// ────────────────────────────────────────────────────────────────
	// 3-b) 알림/배지 카운트 (관리자 헤더·대시보드 — 주기 폴링)
	//   pendingApproval = 전역 미처리 승인요청(승인자용)
	//   myRejected      = 내가 신청했다가 반려된 건(작성자용)
	// ────────────────────────────────────────────────────────────────

	@ResponseBody
	@RequestMapping("/rlms/promwork/badgeCountsJson.do")
	public Map<String, Object> badgeCountsJson() {
		Map<String, Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("pendingApproval", 0);
			res.put("myRejected", 0);
			return res;
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		// 승인대기 배지는 승인권한(APPROVER/ADMIN)에게만 — 비승인자는 0 → 헤더/대시보드 배지 자동 숨김(2026-07-08)
		res.put("pendingApproval", hasApproverRole() ? promWorkService.countPendingApproval() : 0);
		res.put("myRejected", promWorkService.countMyRejected(user != null ? user.getId() : null));
		return res;
	}

	// ────────────────────────────────────────────────────────────────
	// 4) 이력 (history)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/promwork/selectPromWorkHistory.do")
	public String selectPromWorkHistory(@RequestParam(value = "promNo", required = false) Long promNo,
			ModelMap model) throws Exception {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}

		// promNo 없이 진입(전역 메뉴/북마크 등) — 전역 제·개정내역 관리 목록으로.
		// 목록의 각 행(규정)에서 클릭하면 그 회차 promNo 로 이 상세 이력 화면에 다시 진입한다.
		if (promNo == null) {
			return "redirect:/rlms/promwork/selectPromWorkActLogList.do";
		}

		Map<String, Object> history = promWorkService.selectHistory(promNo);
		model.addAttribute("workList", history.get("workList"));
		model.addAttribute("logList", history.get("logList"));
		model.addAttribute("promNo", promNo);
		return "rlms/promwork/promWorkHistory";
	}

	// ────────────────────────────────────────────────────────────────
	// helpers
	// ────────────────────────────────────────────────────────────────

	private void applyLoginUser(PromWorkVO vo, LoginVO user) {
		if (user == null) {
			return;
		}
		if (vo.getUserId() == null || vo.getUserId().isEmpty()) {
			vo.setUserId(user.getId());
		}
		if (vo.getUserNm() == null || vo.getUserNm().isEmpty()) {
			vo.setUserNm(user.getName());
		}
	}
}
