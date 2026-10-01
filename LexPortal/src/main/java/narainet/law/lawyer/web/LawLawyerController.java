/*
 * 물리적 저장 경로: /src/main/java/narainet/law/lawyer/web/LawLawyerController.java
 *
 * 변호사관리 Controller (LAW_MODULE_DESIGN.md §7.7).
 *   목록(법무법인·변호사 통합검색, 만족도 집계) + 등록/수정 모달(JSON POST) + 소프트삭제.
 */
package narainet.law.lawyer.web;

import java.util.LinkedHashMap;
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
import org.springframework.web.bind.annotation.ResponseBody;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.common.LawTextUtil;
import narainet.law.lawyer.service.LawLawyerService;
import narainet.law.lawyer.service.LawLawyerVO;

@Controller
public class LawLawyerController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawLawyerController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "lawLawyerService")
	private LawLawyerService lawLawyerService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	private LoginVO currentUser() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return u instanceof LoginVO ? (LoginVO) u : null;
	}

	@RequestMapping("/law/lawyer/list.do")
	public String list(@ModelAttribute("searchVO") LawLawyerVO searchVO, ModelMap model) throws Exception {
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

		Map<String, Object> result = lawLawyerService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		return "law/lawyer/list";
	}

	/** 등록/수정 (모달 폼 JSON POST) */
	@ResponseBody
	@RequestMapping(value = "/law/lawyer/saveJson.do", method = RequestMethod.POST)
	public Map<String, Object> saveJson(@ModelAttribute LawLawyerVO vo) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			// HTMLTagFilter 엔티티 복원 (법인명 괄호 등 — 저장은 원문, 출력은 c:out 이스케이프)
			vo.setLawFirm(LawTextUtil.unescape(vo.getLawFirm()));
			vo.setLawyerNm(LawTextUtil.unescape(vo.getLawyerNm()));
			vo.setEmail(LawTextUtil.unescape(vo.getEmail()));
			vo.setTel(LawTextUtil.unescape(vo.getTel()));
			vo.setMobile(LawTextUtil.unescape(vo.getMobile()));
			if (vo.getLawFirm() == null || vo.getLawFirm().trim().isEmpty()
					|| vo.getLawyerNm() == null || vo.getLawyerNm().trim().isEmpty()) {
				res.put("success", false);
				res.put("message", "법무법인과 변호사 성명은 필수입니다.");
				return res;
			}
			LoginVO user = currentUser();
			String userId = user == null ? null : user.getId();
			vo.setRegUserId(userId);
			vo.setUpdUserId(userId);
			Long id = lawLawyerService.save(vo);
			res.put("success", true);
			res.put("lawyerId", id);
		} catch (Exception e) {
			LOGGER.warn("변호사 저장 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "저장 중 오류가 발생했습니다.");
		}
		return res;
	}

	/** 소프트삭제 (선임 참조 시 차단 안내) */
	@ResponseBody
	@RequestMapping(value = "/law/lawyer/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@ModelAttribute LawLawyerVO vo) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			LoginVO user = currentUser();
			lawLawyerService.delete(vo.getLawyerId(), user == null ? null : user.getId());
			res.put("success", true);
		} catch (IllegalStateException e) {
			res.put("success", false);
			res.put("message", e.getMessage());
		} catch (Exception e) {
			LOGGER.warn("변호사 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}
}
