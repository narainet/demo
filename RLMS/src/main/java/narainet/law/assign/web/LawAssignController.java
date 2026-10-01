/*
 * 물리적 저장 경로: /src/main/java/narainet/law/assign/web/LawAssignController.java
 *
 * 선임관리 Controller (LAW_MODULE_DESIGN.md §7.6).
 *   목록(법무법인·변호사·사건 통합검색, 만족도 집계) + 선임등록 모달(사건검색 재사용·변호사 select·계약서 첨부)
 *   + 행 삭제 + 만족도(선임 단위 1인 1회 MERGE) 평가·의견 모달.
 *   첨부 저장은 표준 COMTNFILE(EgovFileMngUtil.parseFileInf → insertFileInfs) — LawFileSupport 경유.
 */
package narainet.law.assign.web;

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
import narainet.law.assign.service.LawAssignService;
import narainet.law.assign.service.LawLawyerSatisVO;
import narainet.law.assign.service.LawSuitLawyerVO;
import narainet.law.common.LawTextUtil;
import narainet.law.common.mapper.LawComMapper;

@Controller
public class LawAssignController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawAssignController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "lawAssignService")
	private LawAssignService lawAssignService;

	@Resource(name = "lawComMapper")
	private LawComMapper lawComMapper;

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

	@RequestMapping("/law/assign/list.do")
	public String list(@ModelAttribute("searchVO") LawSuitLawyerVO searchVO, ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = lawAssignService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("lawyerOptions", lawComMapper.selectLawyerOptions());
		return "law/assign/list";
	}

	/** 선임 등록/수정 (모달 multipart POST — 계약서 첨부). suitId 는 사건검색 모달에서 채운다. */
	@RequestMapping(value = "/law/assign/save.do", method = RequestMethod.POST)
	public String save(final MultipartHttpServletRequest multiRequest,
			@ModelAttribute LawSuitLawyerVO vo,
			@RequestParam(value = "redirectSuitId", required = false) Long redirectSuitId,
			RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String back = redirectSuitId != null ? "redirect:/law/suit/view.do?suitId=" + redirectSuitId
				: "redirect:/law/assign/list.do";
		try {
			if (vo.getSuitId() == null || vo.getLawyerId() == null) {
				ra.addFlashAttribute("message", "사건과 변호사를 선택하세요.");
				return back;
			}
			vo.setAssignDt(toDb(vo.getAssignDt()));
			List<MultipartFile> files = multiRequest.getFiles("file_1");
			LoginVO user = currentUser();
			lawAssignService.save(vo, files, user == null ? null : user.getId());
			ra.addFlashAttribute("message", "저장했습니다.");
		} catch (Exception e) {
			LOGGER.warn("선임 저장 실패", e);
			ra.addFlashAttribute("message", "저장 중 오류가 발생했습니다.");
		}
		return back;
	}

	@ResponseBody
	@RequestMapping(value = "/law/assign/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("assignId") Long assignId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			lawAssignService.delete(assignId);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("선임 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}

	/** 만족도 모달 데이터 — 의견 목록 + 내 평가(있으면) */
	@ResponseBody
	@RequestMapping("/law/assign/satisDataJson.do")
	public Map<String, Object> satisDataJson(@RequestParam("assignId") Long assignId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			return res;
		}
		try {
			LoginVO user = currentUser();
			res.put("success", true);
			res.put("list", lawAssignService.getSatisList(assignId));
			res.put("mine", lawAssignService.getMySatis(assignId, user == null ? null : user.getId()));
		} catch (Exception e) {
			LOGGER.warn("만족도 조회 실패: {}", e.getMessage());
			res.put("success", false);
		}
		return res;
	}

	/** 만족도 저장 — 선임 단위 1인 1회 MERGE (POST) */
	@ResponseBody
	@RequestMapping(value = "/law/assign/satisJson.do", method = RequestMethod.POST)
	public Map<String, Object> satisJson(@ModelAttribute LawLawyerSatisVO vo) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			if (vo.getAssignId() == null || vo.getScore() == null || vo.getScore() < 1 || vo.getScore() > 5) {
				res.put("success", false);
				res.put("message", "별점(1~5)을 선택하세요.");
				return res;
			}
			LoginVO user = currentUser();
			vo.setEmplyrId(user == null ? null : user.getId());
			vo.setOpinion(LawTextUtil.unescape(vo.getOpinion()));
			lawAssignService.saveSatis(vo);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("만족도 저장 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "저장 중 오류가 발생했습니다.");
		}
		return res;
	}
}
