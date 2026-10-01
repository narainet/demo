/*
 * 물리적 저장 경로: /src/main/java/narainet/law/schedule/web/LawScheduleController.java
 *
 * 일정관리 Controller (LAW_MODULE_DESIGN.md §7.5).
 *   월 달력(monthJson ajax) + 당일/주간 기일 그리드 + 일정등록(사건검색 모달) + 일정검색 + 삭제.
 *   데이터=LAW_SUIT_PROG(기일 PROG_KIND_CD='S001') — 등록화면 진행상황과 공유.
 */
package narainet.law.schedule.web;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
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
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.fasterxml.jackson.databind.ObjectMapper;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.common.LawTextUtil;
import narainet.law.common.mapper.LawComMapper;
import narainet.law.schedule.service.LawScheduleService;
import narainet.law.schedule.service.LawScheduleVO;

@Controller
public class LawScheduleController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawScheduleController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final DateTimeFormatter YMD = DateTimeFormatter.ofPattern("yyyyMMdd");
	private static final DateTimeFormatter YM = DateTimeFormatter.ofPattern("yyyyMM");
	private static final ObjectMapper OM = new ObjectMapper();

	@Resource(name = "lawScheduleService")
	private LawScheduleService lawScheduleService;

	@Resource(name = "lawComMapper")
	private LawComMapper lawComMapper;

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

	@RequestMapping("/law/schedule/main.do")
	public String main(@ModelAttribute("searchVO") LawScheduleVO searchVO, ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LocalDate today = LocalDate.now();
		LocalDate weekStart = today.with(DayOfWeek.MONDAY);
		LocalDate weekEnd = today.with(DayOfWeek.SUNDAY);
		String ym = (searchVO.getSearchYm() == null || searchVO.getSearchYm().replaceAll("[^0-9]", "").length() < 6)
				? today.format(YM) : searchVO.getSearchYm().replaceAll("[^0-9]", "").substring(0, 6);

		model.addAttribute("todayYmd", today.format(YMD));
		model.addAttribute("todayHearings", lawScheduleService.getDay(today.format(YMD)));
		model.addAttribute("weekFrom", weekStart.format(YMD));
		model.addAttribute("weekTo", weekEnd.format(YMD));
		model.addAttribute("weekHearings", lawScheduleService.getWeek(weekStart.format(YMD), weekEnd.format(YMD)));
		model.addAttribute("ym", ym);
		model.addAttribute("monthJsonStr", OM.writeValueAsString(lawScheduleService.getMonth(ym)));

		// 일정검색 (검색어 있을 때만)
		boolean hasSearch = notEmpty(searchVO.getSearchCaseNo()) || notEmpty(searchVO.getSearchDyprKind())
				|| notEmpty(searchVO.getSearchInstance()) || notEmpty(searchVO.getSearchFrom()) || notEmpty(searchVO.getSearchTo());
		if (hasSearch) {
			searchVO.setSearchFrom(toDb(searchVO.getSearchFrom()));
			searchVO.setSearchTo(toDb(searchVO.getSearchTo()));
			searchVO.setTargetDt(null);
			model.addAttribute("searchResults", lawScheduleService.getHearings(searchVO));
			model.addAttribute("searched", true);
		}

		model.addAttribute("dyprKinds", lawComMapper.selectCmmnCodeList("LAW_DYPR_KIND"));
		model.addAttribute("instances", lawComMapper.selectCmmnCodeList("LAW_INSTANCE"));
		return "law/schedule/main";
	}

	private static boolean notEmpty(String s) {
		return s != null && !s.trim().isEmpty();
	}

	/** 달력 월 이동 — 해당 월 기일 JSON */
	@ResponseBody
	@RequestMapping("/law/schedule/monthJson.do")
	public Map<String, Object> monthJson(@RequestParam("ym") String ym) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			return res;
		}
		try {
			res.put("success", true);
			res.put("ym", ym);
			res.put("list", lawScheduleService.getMonth(ym));
		} catch (Exception e) {
			LOGGER.warn("월 일정 조회 실패: {}", e.getMessage());
			res.put("success", false);
		}
		return res;
	}

	/** 일정(기일) 등록 — 사건검색 모달에서 suitId, 폼에서 기일구분/일시/장소/결과 */
	@RequestMapping(value = "/law/schedule/save.do", method = RequestMethod.POST)
	public String save(@ModelAttribute LawScheduleVO vo, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		try {
			if (vo.getSuitId() == null || vo.getProgDt() == null || toDb(vo.getProgDt()) == null) {
				ra.addFlashAttribute("message", "사건과 기일 일자를 입력하세요.");
				return "redirect:/law/schedule/main.do";
			}
			vo.setProgDt(toDb(vo.getProgDt()));
			if (vo.getProgTm() != null) {
				vo.setProgTm(vo.getProgTm().replaceAll("[^0-9]", ""));
			}
			vo.setPlace(LawTextUtil.unescape(vo.getPlace()));
			vo.setResultDesc(LawTextUtil.unescape(vo.getResultDesc()));
			vo.setProgDesc(LawTextUtil.unescape(vo.getProgDesc()));
			LoginVO user = currentUser();
			lawScheduleService.save(vo, user == null ? null : user.getId());
			ra.addFlashAttribute("message", "일정을 등록했습니다.");
		} catch (Exception e) {
			LOGGER.warn("일정 등록 실패", e);
			ra.addFlashAttribute("message", "등록 중 오류가 발생했습니다.");
		}
		return "redirect:/law/schedule/main.do";
	}

	@ResponseBody
	@RequestMapping(value = "/law/schedule/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("progId") Long progId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			lawScheduleService.delete(progId);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("일정 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}
}
