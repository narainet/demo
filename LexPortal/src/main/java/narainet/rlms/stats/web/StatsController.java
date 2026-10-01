/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/web/StatsController.java
 *
 * 통계/로그 Controller — 레거시 statistic_* 이관.
 *   /rlms/stats/viewStats.do    : 규정별 조회통계 (TB_STATS_FT_VIEW)
 *   /rlms/stats/bbsViewStats.do : 게시판 조회통계 (TB_STATS_BBS_VIEW)
 *   /rlms/stats/keywordStats.do : 기간별 검색어통계 (TB_STATS_KWD)
 *   /rlms/stats/actionLog.do    : 사용자 활동 로그 (TB_ACT_LOG, 페이징)
 *   ※ 접속통계는 표준 웹로그 모듈로 이관(2026-08-06) — /sym/log/wlg/SelectAccessStats.do
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

	/* 규정별 조회통계(viewStats)·규정 도메인 통계는 규정관리 제품 전용 — LexPortal(송무 단독)에서 제거 */

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

	/* 접속통계(accessStats)는 2026-08-06 표준 웹로그 모듈로 이관했다.
	   원천이 COMTNWEBLOG(표준 웹로그)이고 업무와 무관한 공통 기능이라
	   egovframework.com.sym.log.wlg (/sym/log/wlg/SelectAccessStats.do) 에 있다 —
	   접속 세션 현황(2026-07-29 이관)과 같은 자리. 메뉴 위치는 '관리자 > 통계 > 접속통계' 그대로. */

	/* 검색어통계(keywordStats)·부서별 규정통계(deptStats)는 규정관리 제품 전용 — LexPortal 에서 제거 */

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
