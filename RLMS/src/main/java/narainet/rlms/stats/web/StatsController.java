/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/web/StatsController.java
 *
 * 통계/로그 Controller — 레거시 statistic_* 이관.
 *   /rlms/stats/viewStats.do    : 규정별 조회통계 (TB_STATS_FT_VIEW)
 *   /rlms/stats/bbsViewStats.do : 게시판 조회통계 (TB_STATS_BBS_VIEW)
 *   /rlms/stats/accessStats.do  : 접속통계 (COMTNWEBLOG — 시간대/일/최근7일/월/연/요일/메뉴/기기/브라우저 + 차트)
 *   /rlms/stats/keywordStats.do : 기간별 검색어통계 (TB_STATS_KWD)
 *   /rlms/stats/actionLog.do    : 사용자 활동 로그 (TB_ACT_LOG, 페이징)
 *   읽기전용 집계 리포트. 실DB 이관 데이터(2010~) 기반.
 */
package narainet.rlms.stats.web;

import java.io.PrintWriter;
import java.net.URLEncoder;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.stats.service.StatsService;
import narainet.rlms.stats.service.StatsVO;

@Controller
public class StatsController {

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	/** 기간 미지정 시 전체 데이터 포괄 기본값 (이관 데이터 2010~) */
	private static final String DEFAULT_FROM = "2010-01-01";
	private static final String DEFAULT_TO   = "2035-12-31";

	@Resource(name = "statsService")
	private StatsService statsService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	private void applyDateDefaults(StatsVO vo) {
		if (vo.getFromDt() == null || vo.getFromDt().isEmpty()) vo.setFromDt(DEFAULT_FROM);
		if (vo.getToDt() == null || vo.getToDt().isEmpty())     vo.setToDt(DEFAULT_TO);
	}

	@RequestMapping("/rlms/stats/viewStats.do")
	public String viewStats(@ModelAttribute("searchVO") StatsVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		applyDateDefaults(searchVO);
		List<StatsVO> list = statsService.getViewStats(searchVO);
		long total = 0;
		for (StatsVO r : list) {
			if (r.getCnt() != null) total += r.getCnt();
		}
		model.addAttribute("resultList", list);
		model.addAttribute("totalCnt", total);
		return "rlms/stats/statsView";
	}

	/** 엑셀 내보내기 — 기간 내 규정별 조회수(화면과 동일 집계). lawQuestExcel 선례:
	 *  HTML 테이블 → .xls (POI 미사용 — poi-ooxml/xmlbeans 충돌 회피 관행), UTF-8 BOM, 셀 텍스트 강제. */
	@RequestMapping("/rlms/stats/viewStatsExcel.do")
	public void viewStatsExcel(@ModelAttribute("searchVO") StatsVO searchVO,
			HttpServletResponse response) throws Exception {
		if (!authed()) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		applyDateDefaults(searchVO);
		List<StatsVO> list = statsService.getViewStats(searchVO);

		String fname = URLEncoder.encode("규정별조회통계.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);

		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF); // UTF-8 BOM — Excel 한글 인식
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");
		w.print("<table border=\"1\"><tr><th colspan=\"5\" style=\"background:#DCE6F7\">규정별 조회통계 ("
				+ xesc(searchVO.getFromDt()) + " ~ " + xesc(searchVO.getToDt()) + ")</th></tr><tr>");
		for (String h : new String[] { "순위", "분류", "규정명", "소관부서", "조회수" }) {
			w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		}
		w.print("</tr>");
		int rank = 0;
		for (StatsVO r : list) {
			w.print("<tr>");
			w.print(xcell(++rank));
			w.print(xcell(r.getCateNm()));
			w.print(xcell(r.getLabel()));
			w.print(xcell(r.getDeptNm()));
			w.print(xcell(r.getCnt()));
			w.print("</tr>");
		}
		if (list.isEmpty()) {
			w.print("<tr><td colspan=\"5\">조회 데이터 없음</td></tr>");
		}
		w.print("</table></body></html>");
		w.flush();
	}

	@RequestMapping("/rlms/stats/bbsViewStats.do")
	public String bbsViewStats(@ModelAttribute("searchVO") StatsVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		applyDateDefaults(searchVO);
		List<StatsVO> list = statsService.getBbsViewStats(searchVO);
		long total = 0;
		for (StatsVO r : list) {
			if (r.getCnt() != null) total += r.getCnt();
		}
		model.addAttribute("resultList", list);
		model.addAttribute("totalCnt", total);
		return "rlms/stats/statsBbsView";
	}

	/** 게시판 조회통계 엑셀 — 화면과 동일 집계, viewStatsExcel 과 같은 HTML→.xls 패턴. */
	@RequestMapping("/rlms/stats/bbsViewStatsExcel.do")
	public void bbsViewStatsExcel(@ModelAttribute("searchVO") StatsVO searchVO,
			HttpServletResponse response) throws Exception {
		if (!authed()) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		applyDateDefaults(searchVO);
		List<StatsVO> list = statsService.getBbsViewStats(searchVO);

		String fname = URLEncoder.encode("게시판조회통계.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);

		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF); // UTF-8 BOM — Excel 한글 인식
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");
		w.print("<table border=\"1\"><tr><th colspan=\"4\" style=\"background:#DCE6F7\">게시판 조회통계 ("
				+ xesc(searchVO.getFromDt()) + " ~ " + xesc(searchVO.getToDt()) + ")</th></tr><tr>");
		for (String h : new String[] { "순위", "게시판", "글제목", "조회수" }) {
			w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		}
		w.print("</tr>");
		int rank = 0;
		for (StatsVO r : list) {
			w.print("<tr>");
			w.print(xcell(++rank));
			w.print(xcell(r.getBbsNm()));
			w.print(xcell("N".equals(r.getUseAt()) ? r.getLabel() + " (삭제글)" : r.getLabel()));   // 행 자체가 없으면 label 이 이미 '(삭제글)'
			w.print(xcell(r.getCnt()));
			w.print("</tr>");
		}
		if (list.isEmpty()) {
			w.print("<tr><td colspan=\"4\">조회 데이터 없음</td></tr>");
		}
		w.print("</table></body></html>");
		w.flush();
	}

	/** 엑셀 셀 — HTML 이스케이프 + 텍스트 강제(mso-number-format), LawQuestController.xcell 동일 패턴 */
	private static String xcell(Object v) {
		return "<td style=\"mso-number-format:'\\@'\">" + xesc(v) + "</td>";
	}

	private static String xesc(Object v) {
		return v == null ? "" : String.valueOf(v)
				.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}

	// ── 접속통계 ──────────────────────────────────────────

	private static final List<String> ACCESS_DIMS =
			java.util.Arrays.asList("DAY", "WEEK7", "HOUR", "DOW", "MONTH", "YEAR", "MENU", "DEVICE", "BROWSER");

	/** 요일 라벨 — SQL 의 TRUNC-TRUNC('IW') 0~6 (0=월) 과 정렬 일치 */
	private static final String[] DOW_LABELS = { "월", "화", "수", "목", "금", "토", "일" };

	@RequestMapping("/rlms/stats/accessStats.do")
	public String accessStats(@ModelAttribute("searchVO") StatsVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		prepareAccessParams(searchVO);
		List<StatsVO> list = statsService.getAccessStats(searchVO);
		formatAccessLabels(searchVO.getDimension(), list);
		model.addAttribute("resultList", list);
		model.addAttribute("totals", statsService.getAccessTotals(searchVO));
		return "rlms/stats/statsAccess";
	}

	/** 접속통계 엑셀 — 현재 차원·기간의 표와 동일 데이터. */
	@RequestMapping("/rlms/stats/accessStatsExcel.do")
	public void accessStatsExcel(@ModelAttribute("searchVO") StatsVO searchVO,
			HttpServletResponse response) throws Exception {
		if (!authed()) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		prepareAccessParams(searchVO);
		List<StatsVO> list = statsService.getAccessStats(searchVO);
		formatAccessLabels(searchVO.getDimension(), list);
		StatsVO totals = statsService.getAccessTotals(searchVO);

		String fname = URLEncoder.encode("접속통계.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);

		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF); // UTF-8 BOM — Excel 한글 인식
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");
		w.print("<table border=\"1\"><tr><th colspan=\"3\" style=\"background:#DCE6F7\">접속통계 · "
				+ accessDimName(searchVO.getDimension()) + " (" + xesc(searchVO.getFromDt()) + " ~ " + xesc(searchVO.getToDt())
				+ ") — 총 접속 " + (totals == null || totals.getCnt() == null ? 0 : totals.getCnt())
				+ "회 · 접속자 " + (totals == null || totals.getUcnt() == null ? 0 : totals.getUcnt()) + "명</th></tr><tr>");
		for (String h : new String[] { "구간", "접속수", "접속자수" }) {
			w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		}
		w.print("</tr>");
		for (StatsVO r : list) {
			w.print("<tr>");
			w.print(xcell(r.getLabel()));
			w.print(xcell(r.getCnt()));
			w.print(xcell(r.getUcnt()));
			w.print("</tr>");
		}
		if (list.isEmpty()) {
			w.print("<tr><td colspan=\"3\">접속 데이터 없음</td></tr>");
		}
		w.print("</table></body></html>");
		w.flush();
	}

	/** 차원 화이트리스트 + 차원별 기간 기본값·클램프(일 92일·월 36개월). 서비스 제로필과 같은 기간을 공유한다. */
	private void prepareAccessParams(StatsVO vo) {
		if (vo.getDimension() == null || !ACCESS_DIMS.contains(vo.getDimension())) {
			vo.setDimension("DAY");
		}
		java.time.LocalDate today = java.time.LocalDate.now();
		java.time.LocalDate from = parseDateOrNull(vo.getFromDt());
		java.time.LocalDate to = parseDateOrNull(vo.getToDt());
		String dim = vo.getDimension();

		if ("WEEK7".equals(dim)) {                       // 최근 7일 — 고정(오늘 포함)
			from = today.minusDays(6);
			to = today;
		} else if ("DAY".equals(dim)) {
			if (to == null) to = today;
			if (from == null) from = to.minusDays(29);   // 기본 최근 30일
			if (from.isAfter(to)) from = to;
			if (from.isBefore(to.minusDays(91))) from = to.minusDays(91);   // 차트 상한 92일
		} else if ("MONTH".equals(dim)) {
			if (to == null) to = today;
			if (from == null) from = to.minusMonths(11).withDayOfMonth(1);  // 기본 최근 12개월
			if (from.isAfter(to)) from = to;
			java.time.YearMonth fm = java.time.YearMonth.from(from);
			java.time.YearMonth tm = java.time.YearMonth.from(to);
			if (fm.isBefore(tm.minusMonths(35))) from = tm.minusMonths(35).atDay(1);   // 차트 상한 36개월
		} else {                                          // HOUR / DOW / YEAR / MENU / DEVICE / BROWSER — 기본 전체 기간
			if (from == null) from = java.time.LocalDate.parse(DEFAULT_FROM);
			if (to == null) to = java.time.LocalDate.parse(DEFAULT_TO);
			if (from.isAfter(to)) from = to;
		}
		vo.setFromDt(from.toString());
		vo.setToDt(to.toString());
	}

	private static java.time.LocalDate parseDateOrNull(String v) {
		if (v == null || !v.matches("\\d{4}-\\d{2}-\\d{2}")) return null;
		try {
			java.time.LocalDate d = java.time.LocalDate.parse(v);
			// java.time 은 연 0000 도 유효지만 Oracle TO_DATE 는 ORA-01841 — 극단 연도는 미지정 취급
			return (d.getYear() < 1900 || d.getYear() > 2999) ? null : d;
		} catch (Exception e) {
			return null;   // 2026-02-31 같은 형식만 맞는 무효 날짜
		}
	}

	/** HOUR('00'→'0시')·DOW('0'→'월')·DEVICE(코드→한글) 구간 키를 표시 라벨로 치환. 날짜형·메뉴·브라우저는 그대로. */
	private static void formatAccessLabels(String dim, List<StatsVO> list) {
		for (StatsVO r : list) {
			if ("HOUR".equals(dim)) {
				r.setLabel(Integer.parseInt(r.getLabel()) + "시");
			} else if ("DOW".equals(dim)) {
				int d = Integer.parseInt(r.getLabel());
				if (d >= 0 && d <= 6) r.setLabel(DOW_LABELS[d]);
			} else if ("DEVICE".equals(dim)) {
				r.setLabel(deviceLabel(r.getLabel()));
			}
		}
	}

	private static String deviceLabel(String code) {
		if ("PC".equals(code)) return "PC";
		if ("MOBILE".equals(code)) return "모바일";
		if ("TABLET".equals(code)) return "태블릿";
		if ("BOT".equals(code)) return "봇";
		if ("ETC".equals(code)) return "기타";
		return code;   // '(수집 전)' 등
	}

	private static String accessDimName(String dim) {
		if ("HOUR".equals(dim)) return "시간대별";
		if ("WEEK7".equals(dim)) return "최근 7일";
		if ("MONTH".equals(dim)) return "월별";
		if ("YEAR".equals(dim)) return "연도별";
		if ("DOW".equals(dim)) return "요일별";
		if ("MENU".equals(dim)) return "메뉴별";
		if ("DEVICE".equals(dim)) return "기기별";
		if ("BROWSER".equals(dim)) return "브라우저별";
		return "일별";
	}

	@RequestMapping("/rlms/stats/keywordStats.do")
	public String keywordStats(@ModelAttribute("searchVO") StatsVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		applyDateDefaults(searchVO);
		model.addAttribute("resultList", statsService.getKeywordStats(searchVO));
		return "rlms/stats/statsKeyword";
	}

	@RequestMapping("/rlms/stats/deptStats.do")
	public String deptStats(@ModelAttribute("searchVO") StatsVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		model.addAttribute("resultList", statsService.getDeptStats(searchVO));
		return "rlms/stats/statsDept";
	}

	@RequestMapping("/rlms/stats/actionLog.do")
	public String actionLog(@ModelAttribute("searchVO") StatsVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		applyDateDefaults(searchVO);
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());
		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = statsService.getActionLog(searchVO);
		pi.setTotalRecordCount(Integer.parseInt((String) result.get("resultCnt")));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("taskKinds", statsService.getTaskKinds());
		return "rlms/stats/statsActionLog";
	}

	// 접속 세션 현황(웹로그 세션 단위 집계)은 2026-07-29 표준 웹로그 모듈로 이관했다.
	// 특정 업무에 매이지 않는 공통 로그 기능이라 다른 시스템에서도 그대로 쓰도록
	// egovframework.com.sym.log.wlg (관리자 > 로그관리 > 접속 세션 현황)에 있다.
}
