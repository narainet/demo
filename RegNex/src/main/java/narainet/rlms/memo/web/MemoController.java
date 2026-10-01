/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/memo/web/MemoController.java
 */
package narainet.rlms.memo.web;

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
import narainet.rlms.memo.service.MemoService;
import narainet.rlms.memo.service.MemoVO;

@Controller
public class MemoController {

	private static final Logger LOGGER = LoggerFactory.getLogger(MemoController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "memoService")
	private MemoService memoService;

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

	@RequestMapping("/rlms/memo/selectMemoList.do")
	public String selectMemoList(@ModelAttribute("searchVO") MemoVO searchVO,
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

		Map<String, Object> result = memoService.selectMyMemoList(userId, searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		pi.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		return "rlms/memo/memoList";
	}

	/** 특정 법령의 내 메모 (prom 사이드 위젯용) */
	@RequestMapping("/rlms/memo/selectByLawJson.do")
	public ModelAndView selectByLawJson(@RequestParam("lawId") Long lawId,
			@RequestParam("sysId") String sysId) throws Exception {
		List<MemoVO> list = memoService.selectMemoListByLaw(currentUserId(), lawId, sysId);
		ModelAndView mav = new ModelAndView("jsonView");
		mav.addObject("resultList", list);
		return mav;
	}

	@RequestMapping("/rlms/memo/addMemo.do")
	public ModelAndView addMemo(@ModelAttribute("memoVO") MemoVO vo) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			mav.addObject("ok", false);
			mav.addObject("error", "not authenticated");
			return mav;
		}
		LoginVO user = currentUser();
		vo.setUserId(user == null ? "" : user.getUniqId());
		vo.setUserName(user == null || user.getName() == null ? "" : user.getName());
		// SBUSEO_ID 는 NOT NULL — 세션 사용자의 조직(부서) ID 로 채움. (없으면 클라이언트 값, 그래도 없으면 'ETC')
		if (vo.getBuseoId() == null || vo.getBuseoId().isEmpty()) {
			String org = (user == null) ? null : user.getOrgnztId();
			vo.setBuseoId((org != null && !org.isEmpty()) ? org : "ETC");
		}
		// 분류(SGUBUN) 미지정 안전망 — 화면이 안 보내도 개인(USER) 기본. (목록 분류필터와 정합)
		if (vo.getGubun() == null || vo.getGubun().isEmpty()) {
			vo.setGubun("USER");
		}

		try {
			memoService.addMemo(vo);
			mav.addObject("ok", true);
			mav.addObject("memoNo", vo.getMemoNo());
			mav.addObject("message", egovMessageSource.getMessage("memo.added"));
		} catch (Exception e) {
			mav.addObject("ok", false);
			mav.addObject("error", e.getMessage());
		}
		return mav;
	}

	@RequestMapping("/rlms/memo/updateMemo.do")
	public ModelAndView updateMemo(@ModelAttribute("memoVO") MemoVO vo) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		try {
			memoService.updateMemo(vo, currentUserId());
			mav.addObject("ok", true);
			mav.addObject("message", egovMessageSource.getMessage("memo.updated"));
		} catch (Exception e) {
			mav.addObject("ok", false);
			mav.addObject("error", e.getMessage());
		}
		return mav;
	}

	@RequestMapping("/rlms/memo/deleteMemo.do")
	public ModelAndView deleteMemo(@RequestParam("memoNo") Long memoNo) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		try {
			memoService.deleteMemo(memoNo, currentUserId());
			mav.addObject("ok", true);
			mav.addObject("message", egovMessageSource.getMessage("memo.deleted"));
		} catch (Exception e) {
			mav.addObject("ok", false);
			mav.addObject("error", e.getMessage());
		}
		return mav;
	}
}
