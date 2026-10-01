/*
 * 물리적 저장 경로: /src/main/java/narainet/law/req/web/LawReqController.java
 *
 * 소송의뢰 관리(법무팀 mgr) Controller — LAW_MODULE_DESIGN.md §7.9.
 *   목록(등록일자 기간·상태·사건명) + 상세 view + 승인/반려 처리(approveJson) + 소송등록 연계는 suit 컨트롤러.
 *   URL /law/req/**(LAW_MGR·ADMIN) — /law/reqUser/**(사용자 front)와 URL 분리가 곧 권한 경계(§2.4).
 */
package narainet.law.req.web;

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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.common.LawTextUtil;
import narainet.law.common.mapper.LawComMapper;
import narainet.law.req.service.LawReqService;
import narainet.law.req.service.LawSuitReqVO;

@Controller
public class LawReqController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawReqController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "lawReqService")
	private LawReqService lawReqService;

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

	// ── 목록 (§7.9) ──
	@RequestMapping("/law/req/list.do")
	public String list(@ModelAttribute("searchVO") LawSuitReqVO searchVO, ModelMap model) throws Exception {
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

		Map<String, Object> result = lawReqService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("statuses", lawComMapper.selectCmmnCodeList("LAW_REQ_STATUS"));
		return "law/req/list";
	}

	// ── 상세 (경과·첨부·보조자 + 승인/반려) ──
	@RequestMapping("/law/req/view.do")
	public String view(@RequestParam("reqId") Long reqId, ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LawSuitReqVO req = lawReqService.getDetail(reqId);
		if (req == null) {
			ra.addFlashAttribute("message", "존재하지 않는 의뢰입니다.");
			return "redirect:/law/req/list.do";
		}
		model.addAttribute("req", req);
		return "law/req/view";
	}

	/** 승인/반려 처리 — 반려는 사유 필수. (POST) */
	@ResponseBody
	@RequestMapping(value = "/law/req/approveJson.do", method = RequestMethod.POST)
	public Map<String, Object> approveJson(@RequestParam("reqId") Long reqId,
			@RequestParam("action") String action,
			@RequestParam(value = "opinion", required = false) String opinion) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			boolean reject = "reject".equals(action);
			String op = LawTextUtil.unescape(opinion);
			if (reject && (op == null || op.trim().isEmpty())) {
				res.put("success", false);
				res.put("message", "반려 사유를 입력하세요.");
				return res;
			}
			LawSuitReqVO before = lawReqService.getReq(reqId);
			if (before == null) {
				res.put("success", false);
				res.put("message", "존재하지 않는 의뢰입니다.");
				return res;
			}
			if (!"S001".equals(before.getStatusCd())) {
				res.put("success", false);
				res.put("message", "이미 처리된 의뢰입니다.");
				return res;
			}
			LoginVO user = currentUser();
			LawSuitReqVO vo = new LawSuitReqVO();
			vo.setReqId(reqId);
			vo.setStatusCd(reject ? "S003" : "S002");
			vo.setAprvUserId(user == null ? null : user.getId());
			vo.setAprvUserNm(user == null ? null : user.getName());
			vo.setReturnRsn(reject ? op : null);
			lawReqService.approve(vo);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("의뢰 승인 처리 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "처리 중 오류가 발생했습니다.");
		}
		return res;
	}
}
