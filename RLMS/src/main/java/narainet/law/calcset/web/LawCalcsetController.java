/*
 * 물리적 저장 경로: /src/main/java/narainet/law/calcset/web/LawCalcsetController.java
 *
 * 계산기 요율설정 Controller (LAW_MODULE_DESIGN.md §7.13).
 *   4탭(인지액/송달료/변호사비/법정이율) × 적용시작일별 세트 CRUD.
 *   화면 셸(list) + JSON 엔드포인트(세트목록·세트행·최신일·저장·삭제). 저장은 POST JSON(HTMLTagFilter unescape).
 */
package narainet.law.calcset.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.calcset.service.LawCalcRateVO;
import narainet.law.calcset.service.LawCalcsetService;
import narainet.law.common.LawTextUtil;

@Controller
public class LawCalcsetController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawCalcsetController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final ObjectMapper OM = new ObjectMapper();

	@Resource(name = "lawCalcsetService")
	private LawCalcsetService lawCalcsetService;

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	private LoginVO currentUser() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return u instanceof LoginVO ? (LoginVO) u : null;
	}

	@RequestMapping("/law/calcset/list.do")
	public String list() {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		return "law/calcset/list";
	}

	/** 탭(family)의 세트 목록 + 최신 적용일(현행 판단·복사 기준) */
	@ResponseBody
	@RequestMapping("/law/calcset/setDatesJson.do")
	public Map<String, Object> setDatesJson(@RequestParam("tab") String tab) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			return res;
		}
		try {
			res.put("success", true);
			res.put("sets", lawCalcsetService.getSetDates(tab));
			res.put("latest", lawCalcsetService.getLatestApplyDt(tab));
		} catch (Exception e) {
			LOGGER.warn("세트 목록 조회 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", e.getMessage());
		}
		return res;
	}

	/** 특정 세트(탭+적용일)의 요율 행들 */
	@ResponseBody
	@RequestMapping("/law/calcset/setRowsJson.do")
	public Map<String, Object> setRowsJson(@RequestParam("tab") String tab, @RequestParam("applyDt") String applyDt) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			return res;
		}
		try {
			res.put("success", true);
			res.put("rows", lawCalcsetService.getSetRows(tab, applyDt));
		} catch (Exception e) {
			LOGGER.warn("세트 행 조회 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", e.getMessage());
		}
		return res;
	}

	/** 세트 저장 (검증 후 family+applyDt 전량 교체) */
	@ResponseBody
	@RequestMapping(value = "/law/calcset/saveSetJson.do", method = RequestMethod.POST)
	public Map<String, Object> saveSetJson(@RequestParam("tab") String tab,
			@RequestParam("applyDt") String applyDt,
			@RequestParam("rowsJson") String rowsJson) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			List<LawCalcRateVO> rows = OM.readValue(LawTextUtil.unescape(rowsJson),
					new TypeReference<List<LawCalcRateVO>>() { });
			// 자유 텍스트(근거) 엔티티 복원
			if (rows != null) {
				for (LawCalcRateVO r : rows) {
					r.setRmk(LawTextUtil.unescape(r.getRmk()));
				}
			}
			LoginVO user = currentUser();
			lawCalcsetService.saveSet(tab, LawTextUtil.unescape(applyDt), rows, user == null ? null : user.getId());
			res.put("success", true);
		} catch (IllegalArgumentException e) {
			res.put("success", false);
			res.put("message", e.getMessage());
		} catch (Exception e) {
			LOGGER.warn("세트 저장 실패", e);
			res.put("success", false);
			res.put("message", "저장 중 오류가 발생했습니다.");
		}
		return res;
	}

	/** 세트 삭제 (미래=물리삭제 / 과거·현행=USE_YN 'N') */
	@ResponseBody
	@RequestMapping(value = "/law/calcset/deleteSetJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteSetJson(@RequestParam("tab") String tab, @RequestParam("applyDt") String applyDt) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			LoginVO user = currentUser();
			lawCalcsetService.deleteSet(tab, applyDt, user == null ? null : user.getId());
			res.put("success", true);
		} catch (IllegalArgumentException e) {
			res.put("success", false);
			res.put("message", e.getMessage());
		} catch (Exception e) {
			LOGGER.warn("세트 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}
}
