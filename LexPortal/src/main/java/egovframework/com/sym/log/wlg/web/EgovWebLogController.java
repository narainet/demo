package egovframework.com.sym.log.wlg.web;

import java.io.PrintWriter;
import java.net.URLEncoder;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.collections4.MapUtils;
import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import egovframework.com.cmm.annotation.IncludedInfo;
import egovframework.com.sym.log.wlg.service.EgovWebLogService;
import egovframework.com.sym.log.wlg.service.WebLog;
import egovframework.com.sym.log.wlg.service.WebLogStats;

/**
 * @Class Name : EgovWebLogController.java
 * @Description : 시스템 로그정보를 관리하기 위한 컨트롤러 클래스
 * @Modification Information
 *
 *    수정일         수정자         수정내용
 *    -------        -------     -------------------
 *    2009. 3. 11.   이삼섭         최초생성
 *    2011. 7. 01.   이기하         패키지 분리(sym.log -> sym.log.wlg)
 *    2011.8.26	정진오			IncludedInfo annotation 추가
 *
 * @author 공통 서비스 개발팀 이삼섭
 * @since 2009. 3. 11.
 * @version
 * @see
 *
 */

@Controller
public class EgovWebLogController {

	@Resource(name="EgovWebLogService")
	private EgovWebLogService webLogService;

	@Resource(name="propertiesService")
	protected EgovPropertyService propertyService;

	/**
     * 웹 로그 목록 조회
     *
     * @param webLog
     * @return sym/log/wlg/EgovWebLogList
     * @throws Exception
     */
    @IncludedInfo(name = "웹로그관리", listUrl = "/sym/log/wlg/SelectWebLogList.do", order = 1070, gid = 60)
    @RequestMapping(value = "/sym/log/wlg/SelectWebLogList.do")
    public String selectWebLogInf(@ModelAttribute("searchVO") WebLog webLog, ModelMap model) throws Exception {

		webLog.setPageUnit(propertyService.getInt("pageUnit"));
		webLog.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(webLog.getPageIndex());
		paginationInfo.setRecordCountPerPage(webLog.getPageUnit());
		paginationInfo.setPageSize(webLog.getPageSize());

		webLog.setFirstIndex(paginationInfo.getFirstRecordIndex());
		webLog.setLastIndex(paginationInfo.getLastRecordIndex());
		webLog.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		Map<String, Object> map = webLogService.selectWebLogInf(webLog);
        int totCnt = MapUtils.getInteger(map, "resultCnt");

        model.addAttribute("resultList", map.get("resultList"));

		paginationInfo.setTotalRecordCount(totCnt);
		model.addAttribute("paginationInfo", paginationInfo);

		return "egovframework/com/sym/log/wlg/EgovWebLogList";
	}

	/**
	 * 웹 로그 상세 조회
	 *
	 * @param webLog
	 * @param model
	 * @return sym/log/wlg/EgovWebLogInqire
	 * @throws Exception
	 */
	@RequestMapping(value="/sym/log/wlg/SelectWebLogDetail.do")
	public String selectWebLog(@ModelAttribute("searchVO") WebLog webLog,
			@RequestParam("requstId") String requstId,
			ModelMap model) throws Exception{

		webLog.setRequstId(requstId.trim());

		WebLog vo = webLogService.selectWebLog(webLog);
		model.addAttribute("result", vo);
		return "egovframework/com/sym/log/wlg/EgovWebLogDetail";
	}

	// ────────────────────────────────────────────────────────────────
	// 접속 세션 현황 — 웹로그를 세션(SESN_ID) 단위로 묶어 접속 1회를 1행으로 본다.
	//
	// 접속로그(COMTNLOGINLOG)는 로그아웃 버튼을 눌러야 종료가 남는데 실제로는 대부분 창을 닫고
	// 나가므로 체류를 알 수 없다. 웹로그는 요청마다 쌓이므로 마지막 요청 시각이 곧 떠난 시각이다.
	// (2026-07-29 신설. 특정 업무에 매이지 않는 공통 로그 기능이라 표준 웹로그 모듈에 둔다.)
	// ────────────────────────────────────────────────────────────────

	/**
	 * 접속 세션 현황 목록 조회
	 *
	 * @param webLog
	 * @return sym/log/wlg/EgovWebLogSessionList
	 * @throws Exception
	 */
	@IncludedInfo(name = "접속 세션 현황", listUrl = "/sym/log/wlg/SelectWebLogSessionList.do", order = 1071, gid = 60)
	@RequestMapping(value = "/sym/log/wlg/SelectWebLogSessionList.do")
	public String selectWebLogSessionInf(@ModelAttribute("searchVO") WebLog webLog, ModelMap model) throws Exception {

		webLog.setPageUnit(propertyService.getInt("pageUnit"));
		webLog.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(webLog.getPageIndex());
		paginationInfo.setRecordCountPerPage(webLog.getPageUnit());
		paginationInfo.setPageSize(webLog.getPageSize());

		webLog.setFirstIndex(paginationInfo.getFirstRecordIndex());
		webLog.setLastIndex(paginationInfo.getLastRecordIndex());
		webLog.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		Map<String, Object> map = webLogService.selectWebLogSessionInf(webLog);
		int totCnt = MapUtils.getInteger(map, "resultCnt");

		model.addAttribute("resultList", map.get("resultList"));
		model.addAttribute("resultCnt", totCnt);

		paginationInfo.setTotalRecordCount(totCnt);
		model.addAttribute("paginationInfo", paginationInfo);

		return "egovframework/com/sym/log/wlg/EgovWebLogSessionList";
	}

	/**
	 * 접속 세션 현황 엑셀 — 현재 검색조건의 전체 세션(페이징 없음).
	 * HTML 테이블을 .xls 로 내보내는 방식(POI 미사용) — 다른 현황 화면과 동일.
	 *
	 * @param webLog
	 * @param response
	 * @throws Exception
	 */
	@RequestMapping(value = "/sym/log/wlg/SelectWebLogSessionExcel.do")
	public void selectWebLogSessionExcel(@ModelAttribute("searchVO") WebLog webLog,
			HttpServletResponse response) throws Exception {

		List<WebLog> list = webLogService.selectWebLogSessionAll(webLog);

		String fname = URLEncoder.encode("접속세션현황.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);

		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF); // UTF-8 BOM — Excel 한글 인식
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");
		w.print("<table border=\"1\"><tr><th colspan=\"9\" style=\"background:#DCE6F7\">접속 세션 현황 ("
				+ xesc(webLog.getSearchBgnDe()) + " ~ " + xesc(webLog.getSearchEndDe()) + ") — "
				+ (list == null ? 0 : list.size()) + "건</th></tr><tr>");
		for (String h : new String[] { "사용자", "접속 시작", "마지막 활동", "체류(분)", "요청", "화면", "기기", "브라우저", "마지막 화면" }) {
			w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		}
		w.print("</tr>");
		if (list != null) {
			for (WebLog r : list) {
				w.print("<tr>");
				w.print(xcell(r.getRqsterNm() == null || r.getRqsterNm().isEmpty() ? "(비로그인)" : r.getRqsterNm()));
				w.print(xcell(r.getBgnDt()));
				w.print(xcell(r.getEndDt()));
				w.print(xcell(String.valueOf(r.getDurMin())));
				w.print(xcell(String.valueOf(r.getReqCnt())));
				w.print(xcell(String.valueOf(r.getPageCnt())));
				w.print(xcell(deviceLabel(r.getDviceSe())));
				w.print(xcell(r.getBrowserNm()));
				w.print(xcell(r.getLastUrl()));
				w.print("</tr>");
			}
		}
		if (list == null || list.isEmpty()) {
			w.print("<tr><td colspan=\"9\">접속 세션 없음</td></tr>");
		}
		w.print("</table></body></html>");
		w.flush();
	}

	// ── 접속통계 (웹로그 집계) ────────────────────────────────────────────
	// 2026-08-06 이관: 특정 업무에 매이지 않는 공통 기능이라 제품 코드(narainet.rlms.stats)에서
	// 표준 웹로그 모듈로 옮겼다. 원천이 COMTNWEBLOG 이므로 접속 세션 현황과 같은 자리가 맞다.
	// 메뉴 위치는 그대로 '관리자 > 통계 > 접속통계'(메뉴는 DB, 소스는 표준 — 서로 독립).

	/** 지원 차원 화이트리스트 — 그 외 값이 들어오면 DAY 로 강제한다(SQL 분기 키라 검증 필수). */
	private static final List<String> ACCESS_DIMS =
			java.util.Arrays.asList("DAY", "WEEK7", "HOUR", "DOW", "MONTH", "YEAR", "MENU", "DEVICE", "BROWSER");

	/** 요일 라벨 — SQL 의 ISO 주 시작(월) 기준 0~6 과 정렬 일치 */
	private static final String[] DOW_LABELS = { "월", "화", "수", "목", "금", "토", "일" };

	/** 기간 미지정 시 전체 데이터 포괄 기본값 */
	private static final String ACCESS_DEFAULT_FROM = "2010-01-01";
	private static final String ACCESS_DEFAULT_TO = "2035-12-31";

	/**
	 * 접속통계 조회 — 시간대/일/최근7일/월/연/요일/메뉴/기기/브라우저 차원별 집계 + 차트.
	 *
	 * @param stats
	 * @return sym/log/wlg/EgovAccessStats
	 * @throws Exception
	 */
	@IncludedInfo(name = "접속통계", listUrl = "/sym/log/wlg/SelectAccessStats.do", order = 1072, gid = 60)
	@RequestMapping(value = "/sym/log/wlg/SelectAccessStats.do")
	public String selectAccessStats(@ModelAttribute("searchVO") WebLogStats stats, ModelMap model) throws Exception {

		prepareAccessParams(stats);
		List<WebLogStats> list = webLogService.selectAccessStats(stats);
		formatAccessLabels(stats.getDimension(), list);

		model.addAttribute("resultList", list);
		model.addAttribute("totals", webLogService.selectAccessTotals(stats));

		return "egovframework/com/sym/log/wlg/EgovAccessStats";
	}

	/**
	 * 접속통계 엑셀 — 현재 차원·기간의 표와 동일 데이터.
	 *
	 * @param stats
	 * @param response
	 * @throws Exception
	 */
	@RequestMapping(value = "/sym/log/wlg/SelectAccessStatsExcel.do")
	public void selectAccessStatsExcel(@ModelAttribute("searchVO") WebLogStats stats,
			HttpServletResponse response) throws Exception {

		prepareAccessParams(stats);
		List<WebLogStats> list = webLogService.selectAccessStats(stats);
		formatAccessLabels(stats.getDimension(), list);
		WebLogStats totals = webLogService.selectAccessTotals(stats);

		String fname = URLEncoder.encode("접속통계.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);

		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF); // UTF-8 BOM — Excel 한글 인식
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");
		w.print("<table border=\"1\"><tr><th colspan=\"3\" style=\"background:#DCE6F7\">접속통계 · "
				+ accessDimName(stats.getDimension()) + " (" + xesc(stats.getFromDt()) + " ~ " + xesc(stats.getToDt())
				+ ") — 총 접속 " + (totals == null || totals.getCnt() == null ? 0 : totals.getCnt())
				+ "회 · 접속자 " + (totals == null || totals.getUcnt() == null ? 0 : totals.getUcnt()) + "명</th></tr><tr>");
		for (String h : new String[] { "구간", "접속수", "접속자수" }) {
			w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		}
		w.print("</tr>");
		for (WebLogStats r : list) {
			w.print("<tr>");
			w.print(xcell(r.getLabel()));
			w.print(xcell(r.getCnt() == null ? "0" : String.valueOf(r.getCnt())));
			w.print(xcell(r.getUcnt() == null ? "0" : String.valueOf(r.getUcnt())));
			w.print("</tr>");
		}
		if (list.isEmpty()) {
			w.print("<tr><td colspan=\"3\">접속 데이터 없음</td></tr>");
		}
		w.print("</table></body></html>");
		w.flush();
	}

	/** 차원 화이트리스트 + 차원별 기간 기본값·클램프(일 92일·월 36개월). 서비스 제로필과 같은 기간을 공유한다. */
	private void prepareAccessParams(WebLogStats vo) {
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
			if (from == null) from = java.time.LocalDate.parse(ACCESS_DEFAULT_FROM);
			if (to == null) to = java.time.LocalDate.parse(ACCESS_DEFAULT_TO);
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
	private static void formatAccessLabels(String dim, List<WebLogStats> list) {
		for (WebLogStats r : list) {
			if ("HOUR".equals(dim)) {
				r.setLabel(Integer.parseInt(r.getLabel()) + "시");
			} else if ("DOW".equals(dim)) {
				int d = Integer.parseInt(r.getLabel());
				if (d >= 0 && d <= 6) r.setLabel(DOW_LABELS[d]);
			} else if ("DEVICE".equals(dim)) {
				r.setLabel(accessDeviceLabel(r.getLabel()));
			}
		}
	}

	/** 접속통계 기기 라벨 — 세션 현황(deviceLabel)과 달리 '(수집 전)' 같은 집계 키를 그대로 흘린다. */
	private static String accessDeviceLabel(String code) {
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

	/** 기기 구분 코드 → 표시 라벨. 수집 전(빈값)은 '-'. */
	private static String deviceLabel(String code) {
		if (code == null || code.isEmpty()) return "-";
		if ("PC".equals(code)) return "PC";
		if ("MOBILE".equals(code)) return "모바일";
		if ("TABLET".equals(code)) return "태블릿";
		if ("BOT".equals(code)) return "봇";
		if ("ETC".equals(code)) return "기타";
		return code;
	}

	/** 엑셀 셀 — HTML 이스케이프 + 텍스트 강제(mso-number-format) */
	private static String xcell(String v) {
		return "<td style=\"mso-number-format:'\\@'\">" + xesc(v) + "</td>";
	}

	private static String xesc(String v) {
		return v == null ? "" : v.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}

}
