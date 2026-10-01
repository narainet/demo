/*
 * 물리적 저장 경로: /src/main/java/narainet/law/requser/web/LawReqUserController.java
 *
 * 소송의뢰(사용자 front) Controller — LAW_MODULE_DESIGN.md §7.8.
 *   나의 의뢰(본인 신청분만) + 신청/수정(경과·보조자 서브그리드 + 기타자료/행별 첨부) + 읽기전용 상세.
 *   URL /law/reqUser/**(USER 계열 개방) — 관리(/law/req/**)와 URL 분리가 권한 경계(§2.4).
 *   본인 필터·상태(S001) 게이트는 URL 보안과 별개의 데이터 방어(수정·삭제는 신청 상태·본인만).
 */
package narainet.law.requser.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.common.LawTextUtil;
import narainet.law.req.service.LawReqService;
import narainet.law.req.service.LawSuitReqHelperVO;
import narainet.law.req.service.LawSuitReqHistVO;
import narainet.law.req.service.LawSuitReqVO;

@Controller
public class LawReqUserController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawReqUserController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final ObjectMapper OM = new ObjectMapper();

	@Resource(name = "lawReqService")
	private LawReqService lawReqService;

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

	private static String dash(String ymd) {
		if (ymd == null || ymd.length() != 8) {
			return ymd;
		}
		return ymd.substring(0, 4) + "-" + ymd.substring(4, 6) + "-" + ymd.substring(6);
	}

	/** 본인 소유 여부(수정·삭제 방어) */
	private boolean owns(LawSuitReqVO req, LoginVO user) {
		return req != null && user != null && user.getId() != null && user.getId().equals(req.getRegUserId());
	}

	// ── 나의 의뢰 목록 ──
	@RequestMapping("/law/reqUser/list.do")
	public String list(ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		model.addAttribute("resultList", lawReqService.getMyList(user == null ? null : user.getId()));
		return "law/requser/list";
	}

	// ── 신청(신규) / 수정(본인·S001) 폼 ──
	@RequestMapping("/law/reqUser/regist.do")
	public String regist(@RequestParam(value = "reqId", required = false) Long reqId,
			ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		if (reqId != null) {
			LawSuitReqVO req = lawReqService.getDetail(reqId);
			if (!owns(req, user)) {
				ra.addFlashAttribute("message", "본인 의뢰만 수정할 수 있습니다.");
				return "redirect:/law/reqUser/list.do";
			}
			if (!"S001".equals(req.getStatusCd())) {
				ra.addFlashAttribute("message", "신청 상태에서만 수정할 수 있습니다.");
				return "redirect:/law/reqUser/list.do";
			}
			if (req.getHists() != null) {
				for (LawSuitReqHistVO h : req.getHists()) {
					h.setStaDt(dash(h.getStaDt()));
					h.setEndDt(dash(h.getEndDt()));
				}
			}
			model.addAttribute("req", req);
			model.addAttribute("histsJsonStr", OM.writeValueAsString(req.getHists()));
			model.addAttribute("helpersJsonStr", OM.writeValueAsString(req.getHelpers()));
			model.addAttribute("mode", "edit");
		} else {
			model.addAttribute("mode", "regist");
			model.addAttribute("histsJsonStr", "[]");
			model.addAttribute("helpersJsonStr", "[]");
		}
		return "law/requser/regist";
	}

	// ── 저장(신청/수정) ──
	@RequestMapping(value = "/law/reqUser/save.do", method = RequestMethod.POST)
	public String save(final MultipartHttpServletRequest multiRequest,
			@ModelAttribute LawSuitReqVO vo,
			@RequestParam(value = "histsJson", required = false) String histsJson,
			@RequestParam(value = "helpersJson", required = false) String helpersJson,
			RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		try {
			// 수정이면 본인·신청 상태 방어(서비스에서도 재확인)
			if (vo.getReqId() != null) {
				LawSuitReqVO before = lawReqService.getReq(vo.getReqId());
				if (!owns(before, user)) {
					ra.addFlashAttribute("message", "본인 의뢰만 수정할 수 있습니다.");
					return "redirect:/law/reqUser/list.do";
				}
				if (!"S001".equals(before.getStatusCd())) {
					ra.addFlashAttribute("message", "신청 상태에서만 수정할 수 있습니다.");
					return "redirect:/law/reqUser/list.do";
				}
			}
			if (vo.getReqTitl() == null || LawTextUtil.unescape(vo.getReqTitl()).trim().isEmpty()) {
				ra.addFlashAttribute("message", "사건명을 입력하세요.");
				return vo.getReqId() == null ? "redirect:/law/reqUser/regist.do"
						: "redirect:/law/reqUser/regist.do?reqId=" + vo.getReqId();
			}
			vo.setReqTitl(LawTextUtil.unescape(vo.getReqTitl()));
			vo.setReqCn(LawTextUtil.unescape(vo.getReqCn()));
			// 신청자·부서 자동(세션)
			if (user != null) {
				vo.setReqUserId(user.getId());
				vo.setReqUserNm(user.getName());
				vo.setReqOrgnztId(user.getOrgnztId());
			}

			List<LawSuitReqHistVO> hists = parse(LawTextUtil.unescape(histsJson),
					new TypeReference<List<LawSuitReqHistVO>>() { });
			if (hists != null) {
				for (LawSuitReqHistVO h : hists) {
					h.setStaDt(toDb(h.getStaDt()));
					h.setEndDt(toDb(h.getEndDt()));
					h.setHistCn(LawTextUtil.unescape(h.getHistCn()));
				}
			}
			List<LawSuitReqHelperVO> helpers = parse(LawTextUtil.unescape(helpersJson),
					new TypeReference<List<LawSuitReqHelperVO>>() { });
			if (helpers != null) {
				for (LawSuitReqHelperVO hp : helpers) {
					hp.setDeptNm(LawTextUtil.unescape(hp.getDeptNm()));
					hp.setHelperNm(LawTextUtil.unescape(hp.getHelperNm()));
					hp.setTel(LawTextUtil.unescape(hp.getTel()));
					hp.setMobile(LawTextUtil.unescape(hp.getMobile()));
					hp.setEmail(LawTextUtil.unescape(hp.getEmail()));
				}
			}
			vo.setHists(hists);
			vo.setHelpers(helpers);

			lawReqService.save(vo, multiRequest, user == null ? null : user.getId());
			ra.addFlashAttribute("message", "소송의뢰를 저장했습니다.");
		} catch (Exception e) {
			LOGGER.warn("소송의뢰 저장 실패", e);
			ra.addFlashAttribute("message", "저장 중 오류가 발생했습니다.");
			return vo.getReqId() == null ? "redirect:/law/reqUser/regist.do"
					: "redirect:/law/reqUser/regist.do?reqId=" + vo.getReqId();
		}
		return "redirect:/law/reqUser/list.do";
	}

	private <T> List<T> parse(String json, TypeReference<List<T>> type) throws Exception {
		if (json == null || json.trim().isEmpty()) {
			return null;
		}
		return OM.readValue(json, type);
	}

	// ── 삭제(본인·S001) ──
	@ResponseBody
	@RequestMapping(value = "/law/reqUser/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("reqId") Long reqId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			LoginVO user = currentUser();
			LawSuitReqVO before = lawReqService.getReq(reqId);
			if (!owns(before, user)) {
				res.put("success", false);
				res.put("message", "본인 의뢰만 삭제할 수 있습니다.");
				return res;
			}
			if (!"S001".equals(before.getStatusCd())) {
				res.put("success", false);
				res.put("message", "신청 상태에서만 삭제할 수 있습니다.");
				return res;
			}
			lawReqService.delete(reqId);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("소송의뢰 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}

	// ── 읽기전용 상세(본인) ──
	@RequestMapping("/law/reqUser/view.do")
	public String view(@RequestParam("reqId") Long reqId, ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		LawSuitReqVO req = lawReqService.getDetail(reqId);
		if (!owns(req, user)) {
			ra.addFlashAttribute("message", "본인 의뢰만 조회할 수 있습니다.");
			return "redirect:/law/reqUser/list.do";
		}
		model.addAttribute("req", req);
		return "law/requser/view";
	}
}
