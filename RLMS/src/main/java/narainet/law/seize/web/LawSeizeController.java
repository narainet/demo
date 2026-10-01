/*
 * 물리적 저장 경로: /src/main/java/narainet/law/seize/web/LawSeizeController.java
 *
 * 압류관리(가압류·가처분) Controller — LAW_MODULE_DESIGN.md §7.10.
 *   목록(기간+검색축) + 등록/수정(첨부 5개·10MB 서버검증) + 상세(조회수 증가) + 삭제. 게시판형.
 *   담당부서=COMTNORGNZTINFO select, 관할법원=LAW_COURT select+직접입력(COURT_NM 텍스트 저장).
 */
package narainet.law.seize.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.common.LawTextUtil;
import narainet.law.common.mapper.LawComMapper;
import narainet.law.common.service.LawFileSupport;
import narainet.law.seize.service.LawSeizeService;
import narainet.law.seize.service.LawSeizeVO;

@Controller
public class LawSeizeController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawSeizeController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final int MAX_FILE_COUNT = 5;
	private static final long MAX_FILE_BYTES = 10L * 1024 * 1024; // 10MB

	@Resource(name = "lawSeizeService")
	private LawSeizeService lawSeizeService;

	@Resource(name = "lawComMapper")
	private LawComMapper lawComMapper;

	@Resource(name = "lawFileSupport")
	private LawFileSupport lawFileSupport;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	private LoginVO currentUser() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return u instanceof LoginVO ? (LoginVO) u : null;
	}

	private static String toDb(String d) {
		if (d == null) {
			return null;
		}
		String digits = d.replaceAll("[^0-9]", "");
		return digits.isEmpty() ? null : digits;
	}

	private void loadFormCodes(ModelMap model) {
		model.addAttribute("orgnzts", lawComMapper.selectOrgnztList());
		model.addAttribute("courts", lawComMapper.selectCourtList());
	}

	// ── 목록 ──
	@RequestMapping("/law/seize/list.do")
	public String list(@ModelAttribute("searchVO") LawSeizeVO searchVO, ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		searchVO.setSearchFrom(toDb(searchVO.getSearchFrom()));
		searchVO.setSearchTo(toDb(searchVO.getSearchTo()));
		searchVO.setSearchKeyword(LawTextUtil.unescape(searchVO.getSearchKeyword()));
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());
		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = lawSeizeService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		return "law/seize/list";
	}

	// ── 등록/수정 폼 ──
	@RequestMapping("/law/seize/regist.do")
	public String regist(ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		loadFormCodes(model);
		model.addAttribute("mode", "regist");
		return "law/seize/form";
	}

	@RequestMapping("/law/seize/edit.do")
	public String edit(@RequestParam("seizeId") Long seizeId, ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LawSeizeVO vo = lawSeizeService.getSeize(seizeId, false);
		if (vo == null) {
			ra.addFlashAttribute("message", "존재하지 않는 압류 정보입니다.");
			return "redirect:/law/seize/list.do";
		}
		loadFormCodes(model);
		model.addAttribute("seize", vo);
		model.addAttribute("mode", "edit");
		return "law/seize/form";
	}

	// ── 상세 (조회수 증가) ──
	@RequestMapping("/law/seize/view.do")
	public String view(@RequestParam("seizeId") Long seizeId, ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LawSeizeVO vo = lawSeizeService.getSeize(seizeId, true);
		if (vo == null) {
			ra.addFlashAttribute("message", "존재하지 않는 압류 정보입니다.");
			return "redirect:/law/seize/list.do";
		}
		model.addAttribute("seize", vo);
		return "law/seize/view";
	}

	// ── 저장 ──
	@RequestMapping(value = "/law/seize/save.do", method = RequestMethod.POST)
	public String save(final MultipartHttpServletRequest multiRequest,
			@ModelAttribute LawSeizeVO vo, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String backForm = vo.getSeizeId() == null ? "redirect:/law/seize/regist.do"
				: "redirect:/law/seize/edit.do?seizeId=" + vo.getSeizeId();
		try {
			// 필수값 검증
			if (isBlank(vo.getCreditor()) || isBlank(vo.getDebtor()) || isBlank(vo.getThirdDebtor())
					|| isBlank(vo.getCourtNm()) || isBlank(vo.getCaseNo())) {
				ra.addFlashAttribute("message", "채권자·채무자·제3채무자·법원·사건번호는 필수입니다.");
				return backForm;
			}
			List<MultipartFile> files = multiRequest.getFiles("file_1");
			// 첨부 개수·용량(5개·10MB) 서버 검증 — 기존 첨부(hidden atchFileId) 개수 합산
			String fileErr = lawFileSupport.validateFiles(vo.getAtchFileId(), files, MAX_FILE_COUNT, MAX_FILE_BYTES);
			if (fileErr != null) {
				ra.addFlashAttribute("message", fileErr);
				return backForm;
			}
			vo.setCreditor(LawTextUtil.unescape(vo.getCreditor()));
			vo.setDebtor(LawTextUtil.unescape(vo.getDebtor()));
			vo.setThirdDebtor(LawTextUtil.unescape(vo.getThirdDebtor()));
			vo.setCourtNm(LawTextUtil.unescape(vo.getCourtNm()));
			vo.setCaseNo(LawTextUtil.unescape(vo.getCaseNo()));
			vo.setMemo(LawTextUtil.unescape(vo.getMemo()));

			LoginVO user = currentUser();
			Long seizeId = lawSeizeService.save(vo, files, user == null ? null : user.getId());
			ra.addFlashAttribute("message", "저장했습니다.");
			return "redirect:/law/seize/view.do?seizeId=" + seizeId;
		} catch (Exception e) {
			LOGGER.warn("압류 정보 저장 실패", e);
			ra.addFlashAttribute("message", "저장 중 오류가 발생했습니다.");
			return backForm;
		}
	}

	@ResponseBody
	@RequestMapping(value = "/law/seize/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("seizeId") Long seizeId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			lawSeizeService.delete(seizeId);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("압류 정보 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}

	private static boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}
}
