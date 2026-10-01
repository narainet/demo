/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/gaejung/web/GaejungController.java
 */
package narainet.rlms.gaejung.web;

import java.util.LinkedHashMap;
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
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.gaejung.service.GaejungService;
import narainet.rlms.gaejung.service.GaejungVO;

@Controller
public class GaejungController {

	private static final Logger LOGGER = LoggerFactory.getLogger(GaejungController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "gaejungService")
	private GaejungService gaejungService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	@Resource(name = "egovMessageSource")
	private EgovMessageSource egovMessageSource;

	@RequestMapping("/rlms/gaejung/selectGaejungList.do")
	public String selectGaejungList(@ModelAttribute("searchVO") GaejungVO searchVO,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
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

		Map<String, Object> result = gaejungService.selectGaejungList(searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		pi.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		return "rlms/gaejung/gaejungList";
	}

	/**
	 * prom 화면에서 셀렉트박스 채우기용 JSON.
	 * 클래스 레벨 @PreAuthorize('AUTH_PGM_001_04_08') 를 메서드 레벨에서 isAuthenticated() 로 완화.
	 * — 단순 옵션 리스트라 권한 분리 의미가 없음 + RoleHierarchy 캐시 미반영(Tomcat 미재기동) 시
	 *   accessDeniedUrl 로 redirect 되어 JSON 파싱 실패하던 문제 회피.
	 */
	@ResponseBody
	@RequestMapping("/rlms/gaejung/selectGaejungJson.do")
	public Map<String, Object> selectGaejungJson() throws Exception {
		Map<String, Object> res = new LinkedHashMap<>();
		res.put("resultList", gaejungService.selectAllForSelector());
		return res;
	}

	@RequestMapping("/rlms/gaejung/insertGaejungView.do")
	public String insertGaejungView(ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		model.addAttribute("gaejungVO", new GaejungVO());
		return "rlms/gaejung/gaejungRegist";
	}

	@RequestMapping("/rlms/gaejung/insertGaejung.do")
	public String insertGaejung(@ModelAttribute("gaejungVO") GaejungVO vo,
			org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		gaejungService.insertGaejung(vo);
		// flash(세션 1회성) — model 로 넣으면 redirect URL 쿼리 파라미터로 붙어 한글이 깨짐
		redirectAttributes.addFlashAttribute("resultMsg", egovMessageSource.getMessage("gaejung.inserted"));
		return "redirect:/rlms/gaejung/selectGaejungList.do";
	}

	@RequestMapping("/rlms/gaejung/updateGaejungView.do")
	public String updateGaejungView(@RequestParam("gaejungNo") Long gaejungNo,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		model.addAttribute("gaejungVO", gaejungService.selectGaejungByNo(gaejungNo));
		return "rlms/gaejung/gaejungRegist";
	}

	@RequestMapping("/rlms/gaejung/updateGaejung.do")
	public String updateGaejung(@ModelAttribute("gaejungVO") GaejungVO vo,
			org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		gaejungService.updateGaejung(vo);
		redirectAttributes.addFlashAttribute("resultMsg", egovMessageSource.getMessage("gaejung.updated"));
		return "redirect:/rlms/gaejung/selectGaejungList.do";
	}

	@RequestMapping("/rlms/gaejung/deleteGaejung.do")
	public String deleteGaejung(@RequestParam("gaejungNo") Long gaejungNo,
			org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		gaejungService.deleteGaejung(gaejungNo);
		redirectAttributes.addFlashAttribute("resultMsg", egovMessageSource.getMessage("gaejung.deleted"));
		return "redirect:/rlms/gaejung/selectGaejungList.do";
	}
}
