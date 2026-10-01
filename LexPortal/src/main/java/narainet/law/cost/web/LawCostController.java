/*
 * 물리적 저장 경로: /src/main/java/narainet/law/cost/web/LawCostController.java
 *
 * 소송비용조회 + 계산기 서버 Controller (LAW_MODULE_DESIGN.md §7.3·§7.4).
 *   조회(list·합계)·엑셀 / 등록·수정·삭제(사건 상세 탭에서 호출)
 *   / 계산기 요율(calcRateJson — 기준일 유효 세트) / 지연이자(calcInterestJson — 서버 일할 계산).
 */
package narainet.law.cost.web;

import java.io.PrintWriter;
import java.net.URLEncoder;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

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
import narainet.law.calcset.service.LawCalcsetService;
import narainet.law.common.LawTextUtil;
import narainet.law.common.mapper.LawComMapper;
import narainet.law.cost.service.LawCostService;
import narainet.law.cost.service.LawInterestCalc;
import narainet.law.cost.service.LawSuitCostVO;

@Controller
public class LawCostController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawCostController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "lawCostService")
	private LawCostService lawCostService;

	@Resource(name = "lawCalcsetService")
	private LawCalcsetService lawCalcsetService;

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

	private static Long toAmt(String s) {
		if (s == null) {
			return null;
		}
		String digits = s.replaceAll("[^0-9]", "");
		return digits.isEmpty() ? null : Long.valueOf(digits);
	}

	private void loadSearchCodes(ModelMap model) {
		model.addAttribute("caseKinds", lawComMapper.selectCmmnCodeList("LAW_CASE_KIND"));
		model.addAttribute("itptKinds", lawComMapper.selectCmmnCodeList("LAW_ITPT_KIND"));
		model.addAttribute("results", lawComMapper.selectCmmnCodeList("LAW_RESULT"));
		model.addAttribute("caseSigns", lawComMapper.selectCmmnCodeList("LAW_CASE_SIGN"));
		model.addAttribute("costKinds", lawComMapper.selectCmmnCodeList("LAW_COST_KIND"));
	}

	// ────────────────────────────────────────────────────────────────
	// 조회
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/law/cost/list.do")
	public String list(@ModelAttribute("searchVO") LawSuitCostVO searchVO, ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		searchVO.setSearchFrFrom(toDb(searchVO.getSearchFrFrom()));
		searchVO.setSearchFrTo(toDb(searchVO.getSearchFrTo()));
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());
		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = lawCostService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("totalAmt", result.get("totalAmt"));
		model.addAttribute("paginationInfo", pi);
		loadSearchCodes(model);
		return "law/cost/list";
	}

	@RequestMapping("/law/cost/listExcel.do")
	public void listExcel(@ModelAttribute("searchVO") LawSuitCostVO searchVO, HttpServletResponse response) throws Exception {
		if (!authed()) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		searchVO.setSearchFrFrom(toDb(searchVO.getSearchFrFrom()));
		searchVO.setSearchFrTo(toDb(searchVO.getSearchFrTo()));
		searchVO.setFirstIndex(0);
		searchVO.setLastIndex(100000);
		searchVO.setRecordCountPerPage(100000);
		Map<String, Object> result = lawCostService.getList(searchVO);
		@SuppressWarnings("unchecked")
		List<LawSuitCostVO> list = (List<LawSuitCostVO>) result.get("resultList");
		Long total = (Long) result.get("totalAmt");

		String fname = URLEncoder.encode("소송비용.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
		PrintWriter w = response.getWriter();
		w.write('﻿');
		w.println("<table border='1'><tr><th>번호</th><th>법원명</th><th>사건번호</th><th>사건명</th>"
				+ "<th>비용종류</th><th>내역</th><th>금액</th><th>등록일자</th></tr>");
		int no = list.size();
		for (LawSuitCostVO r : list) {
			w.println("<tr><td>" + (no--) + "</td>" + td(r.getCourtNm()) + tdText(r.getCaseNo()) + td(r.getCaseNm())
					+ td(r.getCostKindNm()) + td(r.getCostDesc()) + td(r.getCostAmt() == null ? "" : String.valueOf(r.getCostAmt()))
					+ td(dash(r.getRegDt())) + "</tr>");
		}
		w.println("<tr><td colspan='6' style='text-align:right;'><b>합계</b></td><td><b>"
				+ (total == null ? 0 : total) + "</b></td><td></td></tr>");
		w.println("</table>");
		w.flush();
	}

	private static String esc(String s) {
		return s == null ? "" : s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}

	private static String td(String s) {
		return "<td>" + esc(s) + "</td>";
	}

	private static String tdText(String s) {
		return "<td style='mso-number-format:\"\\@\";'>" + esc(s) + "</td>";
	}

	private static String dash(String ts) {
		if (ts == null || ts.length() < 8) {
			return "";
		}
		return ts.substring(0, 4) + "-" + ts.substring(4, 6) + "-" + ts.substring(6, 8);
	}

	// ────────────────────────────────────────────────────────────────
	// 등록/수정/삭제 (사건 상세 탭에서 호출)
	// ────────────────────────────────────────────────────────────────
	@RequestMapping(value = "/law/cost/save.do", method = RequestMethod.POST)
	public String save(@ModelAttribute LawSuitCostVO vo,
			@RequestParam(value = "costAmtStr", required = false) String costAmtStr,
			RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String back = "redirect:/law/suit/view.do?suitId=" + vo.getSuitId();
		try {
			if (vo.getSuitId() == null) {
				ra.addFlashAttribute("message", "사건 정보가 없습니다.");
				return "redirect:/law/suit/list.do";
			}
			vo.setCostAmt(toAmt(costAmtStr));
			vo.setPayDmndDt(toDb(vo.getPayDmndDt()));
			vo.setCostDesc(LawTextUtil.unescape(vo.getCostDesc()));
			LoginVO user = currentUser();
			lawCostService.save(vo, user == null ? null : user.getId());
			ra.addFlashAttribute("message", "비용을 저장했습니다.");
		} catch (Exception e) {
			LOGGER.warn("비용 저장 실패", e);
			ra.addFlashAttribute("message", "저장 중 오류가 발생했습니다.");
		}
		return back;
	}

	@ResponseBody
	@RequestMapping(value = "/law/cost/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("costId") Long costId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			lawCostService.delete(costId);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("비용 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}

	// ────────────────────────────────────────────────────────────────
	// 계산기 (§7.4)
	// ────────────────────────────────────────────────────────────────
	/** 기준일 유효 요율 세트 — 계산기 JS 가 인지액·송달료·변호사비·법정이율 계산에 사용 */
	@ResponseBody
	@RequestMapping("/law/cost/calcRateJson.do")
	public Map<String, Object> calcRateJson(@RequestParam(value = "baseDt", required = false) String baseDt) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			return res;
		}
		try {
			res.put("success", true);
			res.put("rates", lawCalcsetService.getEffectiveRates(baseDt));
		} catch (Exception e) {
			LOGGER.warn("요율 조회 실패: {}", e.getMessage());
			res.put("success", false);
		}
		return res;
	}

	/** 지연이자 서버 일할 계산 (레거시 ComputeInterest 이식) — 1·2차 이율구간 합산 */
	@ResponseBody
	@RequestMapping(value = "/law/cost/calcInterestJson.do", method = RequestMethod.POST)
	public Map<String, Object> calcInterestJson(
			@RequestParam("amount") String amount,
			@RequestParam(value = "day1From", required = false) String day1From,
			@RequestParam(value = "day1To", required = false) String day1To,
			@RequestParam(value = "rate1", required = false) String rate1,
			@RequestParam(value = "day2From", required = false) String day2From,
			@RequestParam(value = "day2To", required = false) String day2To,
			@RequestParam(value = "rate2", required = false) String rate2) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			return res;
		}
		try {
			long money = toAmt(amount) == null ? 0L : toAmt(amount);
			long i1 = periodInterest(day1From, day1To, money, rate1);
			long i2 = periodInterest(day2From, day2To, money, rate2);
			long interest = i1 + i2;
			res.put("success", true);
			res.put("money", money);
			res.put("interest", interest);
			res.put("result", money + interest);
		} catch (Exception e) {
			LOGGER.warn("지연이자 계산 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "계산 중 오류가 발생했습니다.");
		}
		return res;
	}

	private long periodInterest(String from, String to, long money, String rate) {
		if (from == null || to == null || rate == null
				|| from.trim().isEmpty() || to.trim().isEmpty() || rate.trim().isEmpty()) {
			return 0L;
		}
		double r;
		try {
			r = Double.parseDouble(rate.trim());
		} catch (NumberFormatException nfe) {
			return 0L;
		}
		return LawInterestCalc.compute(from, to, money, r);
	}
}
