/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/favor/web/FavorController.java
 *
 * 사용자 즐겨찾기 Controller.
 *  - /rlms/favor/selectFavorList.do : 내 즐겨찾기 목록
 *  - /rlms/favor/selectByLawJson.do : 특정 법령의 내 즐겨찾기 (prom 본문 위젯에서 호출)
 *  - /rlms/favor/addFavor.do        : 추가 (prom 본문에서 Ajax 호출)
 *  - /rlms/favor/updateFavor.do     : 수정
 *  - /rlms/favor/deleteFavor.do     : 삭제 (본인 소유만)
 */
package narainet.rlms.favor.web;

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
import org.springframework.web.servlet.ModelAndView;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.favor.service.FavorService;
import narainet.rlms.favor.service.FavorVO;
import narainet.rlms.prom.service.PromReadGuard;

@Controller
public class FavorController {

	private static final Logger LOGGER = LoggerFactory.getLogger(FavorController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "favorService")
	private FavorService favorService;

	/** 규정 열람제한 가드 — 즐겨찾기 목록 은닉 + 추가 시 열람가능 검증(분류/구분별 read 게이트). */
	@Resource(name = "promReadGuard")
	private PromReadGuard promReadGuard;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	@Resource(name = "egovMessageSource")
	private EgovMessageSource egovMessageSource;

	private LoginVO currentUser() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return u instanceof LoginVO ? (LoginVO) u : null;
	}

	private String currentUserId() {
		LoginVO u = currentUser();
		return (u == null || u.getUniqId() == null) ? "" : u.getUniqId();
	}

	// ────────────────────────────────────────────────────────────────
	// 목록 (내 즐겨찾기 페이지)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/favor/selectFavorList.do")
	public String selectFavorList(@ModelAttribute("searchVO") FavorVO searchVO,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		String userId = currentUserId();
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		// 열람제한 게이트 — 비면제 사용자는 열람제한(분류/구분) 규정의 즐겨찾기를 목록에서 숨긴다.
		searchVO.setApplyReadGate(promReadGuard.gateNeeded());
		searchVO.setReaderEsntlId(promReadGuard.readerEsntlId());
		searchVO.setReaderOrgnztId(promReadGuard.readerOrgnztId());

		Map<String, Object> result = favorService.selectMyFavorList(userId, searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		pi.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		return "rlms/favor/favorList";
	}

	// ────────────────────────────────────────────────────────────────
	// 특정 법령의 내 즐겨찾기 (prom 본문 사이드 위젯용 JSON)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/favor/selectByLawJson.do")
	public ModelAndView selectByLawJson(@RequestParam("lawId") Long lawId,
			@RequestParam("sysId") String sysId) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		// IDOR 방어 — 열람제한 규정의 즐겨찾기는 본문 위젯 직접호출로도 노출하지 않는다.
		if (!promReadGuard.canReadLaw(lawId)) {
			mav.addObject("resultList", java.util.Collections.emptyList());
			return mav;
		}
		List<FavorVO> list = favorService.selectFavorListByLaw(currentUserId(), lawId, sysId);
		mav.addObject("resultList", list);
		return mav;
	}

	// ────────────────────────────────────────────────────────────────
	// 추가 (Ajax)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/favor/addFavor.do")
	public ModelAndView addFavor(@ModelAttribute("favorVO") FavorVO vo) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			mav.addObject("ok", false);
			mav.addObject("error", "not authenticated");
			return mav;
		}
		LoginVO user = currentUser();
		vo.setUserId(user == null ? "" : user.getUniqId());
		vo.setUserName(user == null || user.getName() == null ? "" : user.getName());

		// 열람제한 규정은 즐겨찾기 추가 차단 — 목록 게이트와 정합(읽을 수 없는 규정 북마크 금지).
		if (!promReadGuard.canReadLaw(vo.getLawId())) {
			mav.addObject("ok", false);
			mav.addObject("error", "이 규정은 열람 권한이 제한되어 있습니다.");
			return mav;
		}

		try {
			favorService.addFavor(vo);
			mav.addObject("ok", true);
			mav.addObject("favorNo", vo.getFavorNo());
			mav.addObject("message", egovMessageSource.getMessage("favor.added"));
		} catch (Exception e) {
			mav.addObject("ok", false);
			mav.addObject("error", e.getMessage());
		}
		return mav;
	}

	@RequestMapping("/rlms/favor/updateFavor.do")
	public ModelAndView updateFavor(@ModelAttribute("favorVO") FavorVO vo) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		try {
			favorService.updateFavor(vo, currentUserId());
			mav.addObject("ok", true);
			mav.addObject("message", egovMessageSource.getMessage("favor.updated"));
		} catch (Exception e) {
			mav.addObject("ok", false);
			mav.addObject("error", e.getMessage());
		}
		return mav;
	}

	@RequestMapping("/rlms/favor/deleteFavor.do")
	public ModelAndView deleteFavor(@RequestParam("favorNo") Long favorNo) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		try {
			favorService.deleteFavor(favorNo, currentUserId());
			mav.addObject("ok", true);
			mav.addObject("message", egovMessageSource.getMessage("favor.deleted"));
		} catch (Exception e) {
			mav.addObject("ok", false);
			mav.addObject("error", e.getMessage());
		}
		return mav;
	}
}
