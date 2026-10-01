package egovframework.com.uss.umt.web;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;
import org.springmodules.validation.commons.DefaultBeanValidator;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.annotation.IncludedInfo;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.uss.umt.service.DeptManageVO;
import egovframework.com.uss.umt.service.EgovDeptManageService;

/**
 * 부서관련 처리를  비지니스 클래스로 전달하고 처리된결과를  해당   웹 화면으로 전달하는  Controller를 정의한다
 * @author 공통서비스 개발팀 조재영
 * @since 2009.00.00
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *
 *   수정일      수정자           수정내용
 *  -------    --------    ---------------------------
 *   2009.02.01  lee.m.j     최초 생성
 *   2015.06.16  조정국      서비스 화면 접근시 조회결과를 표시하도록 수정
 *   2021.05.30  정진오      로그인인증제한
 * </pre>
 */

@Controller
public class EgovDeptManageController {

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "egovMessageSource")
	EgovMessageSource egovMessageSource;

	@Resource(name = "egovDeptManageService")
	private EgovDeptManageService egovDeptManageService;

	/** Message ID Generation */
	@Resource(name = "egovDeptManageIdGnrService")
	private EgovIdGnrService egovDeptManageIdGnrService;

	@Autowired
	private DefaultBeanValidator beanValidator;

	/**
	 * 부서 목록화면 이동
	 * @return String
	 * @exception Exception
	 */
	@IncludedInfo(name = "부서관리", order = 461, gid = 50)
	@RequestMapping("/uss/umt/dpt/selectDeptManageListView.do")
	public String selectDeptManageListView() throws Exception {

		// 2021.05.30, 정진오, 로그인인증제한
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		if (!isAuthenticated) {
			return LOGIN_REDIRECT;
		}

		return "forward:/uss/umt/dpt/selectDeptManageList.do";
	}

	/**
	 * 부서를 관리하기 위해 등록된 부서목록을 조회한다.
	 * @param bannerVO - 배너 VO
	 * @return String - 리턴 URL
	 * @throws Exception
	 */

	@RequestMapping(value = "/uss/umt/dpt/selectDeptManageList.do")
	public String selectDeptManageList(@ModelAttribute("deptManageVO") DeptManageVO deptManageVO, ModelMap model) throws Exception {

		/** paging */
		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(deptManageVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(deptManageVO.getPageUnit());
		paginationInfo.setPageSize(deptManageVO.getPageSize());

		deptManageVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		deptManageVO.setLastIndex(paginationInfo.getLastRecordIndex());
		deptManageVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		model.addAttribute("deptManageList", egovDeptManageService.selectDeptManageList(deptManageVO));

		int totCnt = egovDeptManageService.selectDeptManageListTotCnt(deptManageVO);
		paginationInfo.setTotalRecordCount(totCnt);
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("message", egovMessageSource.getMessage("success.common.select"));
		return "egovframework/com/uss/umt/EgovDeptManageList";
	}

	/**
	 * 등록된 부서의 상세정보를 조회한다.
	 * @param bannerVO - 부서 Vo
	 * @return String - 리턴 Url
	 */

	@RequestMapping(value = "/uss/umt/dpt/getDeptManage.do")
	public String selectDeptManage(@RequestParam("orgnztId") String orgnztId, @ModelAttribute("deptManageVO") DeptManageVO deptManageVO, ModelMap model) throws Exception {

		deptManageVO.setOrgnztId(orgnztId);

		model.addAttribute("deptManage", egovDeptManageService.selectDeptManage(deptManageVO));
		model.addAttribute("message", egovMessageSource.getMessage("success.common.select"));
		return "egovframework/com/uss/umt/EgovDeptManageUpdt";
	}

	/**
	 * 부서등록 화면으로 이동한다.
	 * @param banner - 부서 model
	 * @return String - 리턴 Url
	 */
	@RequestMapping(value = "/uss/umt/dpt/addViewDeptManage.do")
	public String insertViewDeptManage(@ModelAttribute("deptManageVO") DeptManageVO deptManageVO, ModelMap model) throws Exception {

		model.addAttribute("deptManage", deptManageVO);
		return "egovframework/com/uss/umt/EgovDeptManageInsert";
	}

	/**
	 * 부서정보를 신규로 등록한다.
	 * @param banner - 부서 model
	 * @return String - 리턴 Url
	 */
	@RequestMapping(value = "/uss/umt/dpt/addDeptManage.do")
	public String insertDeptManage(@ModelAttribute("deptManageVO") DeptManageVO deptManageVO, BindingResult bindingResult,  ModelMap model) throws Exception {

		beanValidator.validate(deptManageVO, bindingResult); //validation 수행

		deptManageVO.setOrgnztId(egovDeptManageIdGnrService.getNextStringId());

		if (bindingResult.hasErrors()) {
			return "egovframework/com/uss/umt/EgovDeptManageInsert";
		} else {
			egovDeptManageService.insertDeptManage(deptManageVO);
			model.addAttribute("message", egovMessageSource.getMessage("success.common.insert"));
			return "forward:/uss/umt/dpt/selectDeptManageList.do";
		}
	}

	/**
	 * 기 등록된 부서정보를 수정한다.
	 * @param banner - 부서 model
	 * @return String - 리턴 Url
	 */
	@RequestMapping(value = "/uss/umt/dpt/updtDeptManage.do")
	public String updateDeptManage(@ModelAttribute("deptManageVO") DeptManageVO deptManageVO, BindingResult bindingResult, ModelMap model) throws Exception {
		beanValidator.validate(deptManageVO, bindingResult); //validation 수행

		if (bindingResult.hasErrors()) {
			return "egovframework/com/uss/umt/EgovDeptManageUpdt";
		} else {
			egovDeptManageService.updateDeptManage(deptManageVO);
			model.addAttribute("message", egovMessageSource.getMessage("success.common.insert"));
			return "forward:/uss/umt/dpt/selectDeptManageList.do";
		}
	}

	/**
	 * 기 등록된 부서정보를 삭제한다.
	 * @param banner Banner
	 * @return String
	 * @exception Exception
	 */
	@RequestMapping(value = "/uss/umt/dpt/removeDeptManage.do")
	public String deleteDeptManage(@ModelAttribute("deptManageVO") DeptManageVO deptManageVO, Model model) throws Exception {

		egovDeptManageService.deleteDeptManage(deptManageVO);
		model.addAttribute("message", egovMessageSource.getMessage("success.common.delete"));
		return "forward:/uss/umt/dpt/selectDeptManageList.do";
	}

	/**
	 * 기 등록된 부서정보목록을 일괄 삭제한다.
	 * @param banners String
	 * @param banner Banner
	 * @return String
	 * @exception Exception
	 */
	@RequestMapping(value = "/uss/umt/dpt/removeDeptManageList.do")
	public String deleteDeptManageList(@RequestParam("deptManages") String deptManages, @ModelAttribute("deptManageVO") DeptManageVO deptManageVO, ModelMap model) throws Exception {

		String[] strDeptManages = deptManages.split(";");
		for (int i = 0; i < strDeptManages.length; i++) {
			deptManageVO.setOrgnztId(strDeptManages[i]);
			egovDeptManageService.deleteDeptManage(deptManageVO);
		}

		model.addAttribute("message", egovMessageSource.getMessage("success.common.delete"));
		return "forward:/uss/umt/dpt/selectDeptManageList.do";
	}

	// ════════════════════════════════════════════════════════════════
	// 트리 전환 (2026-07-27) — 공통코드관리(EgovCcmCodeTree) 골격의 jsTree JSON + Ajax CRUD.
	// 계층=UPPER_ORGNZT_ID 자기참조(단수 제한 없음), 순서=ORDR(형제 내, ▲▼ 재배치).
	// ════════════════════════════════════════════════════════════════

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovDeptManageController.class);

	/**
	 * jsTree 호환 JSON — 평면 노드(id='org_<ID>', parent='#'|'org_<상위>'), 형제 순서는
	 * 조회 정렬(ORDR)에 따라 부모별 등장 순서로 유지된다.
	 */
	@RequestMapping("/uss/umt/dpt/deptTreeJson.do")
	public ModelAndView deptTreeJson() throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			mav.addObject("resultList", new ArrayList<Map<String, Object>>());
			mav.addObject("resultMsg", "UNAUTHORIZED");
			return mav;
		}
		List<Map<String, Object>> nodes = new ArrayList<>();
		for (DeptManageVO d : egovDeptManageService.selectDeptTreeList()) {
			String id = trim(d.getOrgnztId());
			String upper = trim(d.getUpperOrgnztId());
			Map<String, Object> n = new LinkedHashMap<>();
			n.put("id", "org_" + id);
			n.put("parent", (upper == null || upper.isEmpty()) ? "#" : "org_" + upper);
			n.put("text", d.getOrgnztNm());
			Map<String, Object> data = new LinkedHashMap<>();
			data.put("orgnztId", id);
			data.put("orgnztNm", d.getOrgnztNm());
			data.put("orgnztDc", d.getOrgnztDc());
			data.put("upperOrgnztId", upper);
			data.put("ordr", d.getOrdr());
			data.put("childCnt", d.getChildCnt());
			n.put("data", data);
			nodes.add(n);
		}
		mav.addObject("resultList", nodes);
		return mav;
	}

	/** 부서 등록 (최상위=upperOrgnztId 빈값 → 본사·지사급, 그 외=하위부서). ID 는 표준 채번. */
	@ResponseBody
	@RequestMapping("/uss/umt/dpt/insertDeptAjax.do")
	public Map<String, Object> insertDeptAjax(@ModelAttribute("deptManageVO") DeptManageVO vo) {
		Map<String, Object> result = guard();
		if (result != null) {
			return result;
		}
		result = new LinkedHashMap<>();
		try {
			if (vo.getOrgnztNm() == null || vo.getOrgnztNm().trim().isEmpty()) {
				throw new IllegalStateException("부서명을 입력하세요.");
			}
			vo.setOrgnztId(egovDeptManageIdGnrService.getNextStringId());
			egovDeptManageService.insertDeptTree(vo);
			result.put("success", true);
			result.put("resultMsg", "부서가 등록되었습니다.");
			result.put("orgnztId", trim(vo.getOrgnztId()));
			result.put("ordr", vo.getOrdr());
		} catch (Exception e) {
			LOGGER.warn("Dept tree insert failed.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 부서 수정 (부서명·설명·상위부서 변경 — 상위 변경 시 순환 거부·새 부모 마지막 순서) */
	@ResponseBody
	@RequestMapping("/uss/umt/dpt/updateDeptAjax.do")
	public Map<String, Object> updateDeptAjax(@ModelAttribute("deptManageVO") DeptManageVO vo) {
		Map<String, Object> result = guard();
		if (result != null) {
			return result;
		}
		result = new LinkedHashMap<>();
		try {
			if (vo.getOrgnztNm() == null || vo.getOrgnztNm().trim().isEmpty()) {
				throw new IllegalStateException("부서명을 입력하세요.");
			}
			egovDeptManageService.updateDeptTree(vo);
			result.put("success", true);
			result.put("resultMsg", "부서가 수정되었습니다.");
			result.put("ordr", vo.getOrdr());
		} catch (Exception e) {
			LOGGER.warn("Dept tree update failed.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 부서 삭제 — 하위부서가 있으면 거부(서비스 가드) */
	@ResponseBody
	@RequestMapping("/uss/umt/dpt/deleteDeptAjax.do")
	public Map<String, Object> deleteDeptAjax(@RequestParam("orgnztId") String orgnztId) {
		Map<String, Object> result = guard();
		if (result != null) {
			return result;
		}
		result = new LinkedHashMap<>();
		try {
			egovDeptManageService.deleteDeptTree(orgnztId);
			result.put("success", true);
			result.put("resultMsg", "부서가 삭제되었습니다.");
		} catch (Exception e) {
			LOGGER.warn("Dept tree delete failed.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 형제 내 순서 이동 (dir=up|down) — DB 가 순서의 정본, 화면은 성공 시 로컬 반영 */
	@ResponseBody
	@RequestMapping("/uss/umt/dpt/reorderDeptAjax.do")
	public Map<String, Object> reorderDeptAjax(@RequestParam("orgnztId") String orgnztId,
			@RequestParam("dir") String dir) {
		Map<String, Object> result = guard();
		if (result != null) {
			return result;
		}
		result = new LinkedHashMap<>();
		try {
			if (!"up".equals(dir) && !"down".equals(dir)) {
				throw new IllegalStateException("이동 방향이 올바르지 않습니다.");
			}
			egovDeptManageService.reorderDept(orgnztId, dir);
			result.put("success", true);
			result.put("resultMsg", "순서를 변경했습니다.");
		} catch (Exception e) {
			LOGGER.warn("Dept tree reorder failed.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 미인증이면 실패 응답, 인증이면 null (ccm CodeTree Ajax 관례: {success, resultMsg}) */
	private static Map<String, Object> guard() {
		if (Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return null;
		}
		Map<String, Object> result = new LinkedHashMap<>();
		result.put("success", false);
		result.put("resultMsg", "UNAUTHORIZED");
		return result;
	}

	private static String trim(String s) {
		return s == null ? null : s.trim();
	}

}
