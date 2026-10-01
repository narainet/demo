/*
 * 물리적 저장 경로: /src/main/java/narainet/law/stat/web/LawStatController.java
 *
 * 소송통계 7종 Controller — LAW_MODULE_DESIGN.md §7.12 (P7 구현).
 *   화면: summary / instance / caseType / dept / agent / lossCause / landMap
 *   각 화면 [엑셀] = 화면과 동일 집계 전건 HTML-table .xls (RLMS 관행, POI 미사용 — 소송조회와 동일).
 *   지도(landMap): Kakao Maps + Geocoder, appkey=Globals.law.kakaoMapAppKey. 미설정 시 목록 폴백.
 *   기간형(summary·lossCause·landMap)만 일자 입력, 나머지는 계류 스냅샷(무기간).
 */
package narainet.law.stat.web;

import java.io.PrintWriter;
import java.net.URLEncoder;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;

import com.fasterxml.jackson.databind.ObjectMapper;

import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.stat.service.LawStatService;

@Controller
public class LawStatController {

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final ObjectMapper OM = new ObjectMapper();

	@Resource(name = "lawStatService")
	private LawStatService lawStatService;

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	// ── 일자 유틸 (native date yyyy-MM-dd ↔ YYYYMMDD) ──
	private static String digits(String d) {
		if (d == null) {
			return "";
		}
		return d.replaceAll("[^0-9]", "");
	}

	private static String defFrom(String v) {
		if (v == null || v.trim().isEmpty()) {
			return LocalDate.now().minusMonths(1).format(DateTimeFormatter.ISO_LOCAL_DATE);
		}
		return v;
	}

	private static String defTo(String v) {
		if (v == null || v.trim().isEmpty()) {
			return LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
		}
		return v;
	}

	private void putPeriod(ModelMap model, String from, String to) {
		model.addAttribute("fromDate", from);
		model.addAttribute("toDate", to);
	}

	// ════════════════════════════════════════ ① 소송현황

	@RequestMapping("/law/stat/summary.do")
	public String summary(HttpServletRequest req, ModelMap model) {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String from = defFrom(req.getParameter("fromDate"));
		String to = defTo(req.getParameter("toDate"));
		putPeriod(model, from, to);
		model.addAttribute("rows", lawStatService.getSummary(digits(from), digits(to)));
		return "law/stat/summary";
	}

	@RequestMapping("/law/stat/summaryExcel.do")
	public void summaryExcel(HttpServletRequest req, HttpServletResponse res) throws Exception {
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String from = defFrom(req.getParameter("fromDate"));
		String to = defTo(req.getParameter("toDate"));
		List<Map<String, Object>> rows = lawStatService.getSummary(digits(from), digits(to));
		StringBuilder sb = new StringBuilder();
		sb.append("<table border='1'><tr>")
				.append("<th>구분</th><th>발생건수</th><th>확정·종결(계)</th><th>승소</th><th>패소</th><th>승소율(%)</th><th>계류</th></tr>");
		for (Map<String, Object> r : rows) {
			sb.append("<tr>").append(td(r.get("name"))).append(td(r.get("occurrenceCnt"))).append(td(r.get("totalCnt")))
					.append(td(r.get("winCnt"))).append(td(r.get("loseCnt"))).append(td(r.get("rate")))
					.append(td(r.get("processingCnt"))).append("</tr>");
		}
		sb.append("</table>");
		sendXls(res, "소송통계.xls", sb.toString());
	}

	// ════════════════════════════════════════ ② 심급별

	// 기간=소제기일(FR_DT) 필터, 빈값=전체(계류 스냅샷 그대로) — summary 와 달리 기본값 미적용
	@RequestMapping("/law/stat/instance.do")
	public String instance(HttpServletRequest req, ModelMap model) {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String from = req.getParameter("fromDate");
		String to = req.getParameter("toDate");
		putPeriod(model, from == null ? "" : from, to == null ? "" : to);
		model.addAttribute("rows", lawStatService.getInstance(digits(from), digits(to)));
		return "law/stat/instance";
	}

	@RequestMapping("/law/stat/instanceExcel.do")
	public void instanceExcel(HttpServletRequest req, HttpServletResponse res) throws Exception {
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		StringBuilder sb = new StringBuilder();
		sb.append("<table border='1'><tr>")
				.append("<th>심급</th><th>계</th><th>민사</th><th>행정</th><th>국가</th><th>심판</th></tr>");
		for (Map<String, Object> r : lawStatService.getInstance(digits(req.getParameter("fromDate")),
				digits(req.getParameter("toDate")))) {
			sb.append("<tr>").append(td(r.get("name"))).append(td(r.get("totCnt"))).append(td(r.get("minsaCnt")))
					.append(td(r.get("hangjungCnt"))).append(td(r.get("kukgaCnt"))).append(td(r.get("simpanCnt")))
					.append("</tr>");
		}
		sb.append("</table>");
		sendXls(res, "심급별통계.xls", sb.toString());
	}

	// ════════════════════════════════════════ ③ 유형별

	// 기간=소제기일(FR_DT) 필터, 빈값=전체 — instance 와 동일 규약
	@RequestMapping("/law/stat/caseType.do")
	public String caseType(HttpServletRequest req, ModelMap model) {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String from = req.getParameter("fromDate");
		String to = req.getParameter("toDate");
		putPeriod(model, from == null ? "" : from, to == null ? "" : to);
		model.addAttribute("rows", lawStatService.getCaseType(digits(from), digits(to)));
		return "law/stat/caseType";
	}

	@RequestMapping("/law/stat/caseTypeExcel.do")
	public void caseTypeExcel(HttpServletRequest req, HttpServletResponse res) throws Exception {
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		StringBuilder sb = new StringBuilder();
		sb.append("<table border='1'><tr>")
				.append("<th>사건유형</th><th>계</th><th>민사</th><th>행정</th><th>국가</th><th>심판</th></tr>");
		for (Map<String, Object> r : lawStatService.getCaseType(digits(req.getParameter("fromDate")),
				digits(req.getParameter("toDate")))) {
			sb.append("<tr>").append(td(r.get("name"))).append(td(r.get("totCnt"))).append(td(r.get("minsaCnt")))
					.append(td(r.get("hangjungCnt"))).append(td(r.get("kukgaCnt"))).append(td(r.get("simpanCnt")))
					.append("</tr>");
		}
		sb.append("</table>");
		sendXls(res, "유형별통계.xls", sb.toString());
	}

	// ════════════════════════════════════════ ④ 부서별

	// 기간=소제기일(FR_DT) 필터, 빈값=전체 — instance 와 동일 규약
	@RequestMapping("/law/stat/dept.do")
	public String dept(HttpServletRequest req, ModelMap model) {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String from = req.getParameter("fromDate");
		String to = req.getParameter("toDate");
		putPeriod(model, from == null ? "" : from, to == null ? "" : to);
		model.addAttribute("rows", lawStatService.getDept(digits(from), digits(to)));
		return "law/stat/dept";
	}

	@RequestMapping("/law/stat/deptExcel.do")
	public void deptExcel(HttpServletRequest req, HttpServletResponse res) throws Exception {
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		StringBuilder sb = new StringBuilder();
		sb.append("<table border='1'><tr>")
				.append("<th rowspan='2'>부서</th><th colspan='2'>계</th><th colspan='2'>민사</th>")
				.append("<th colspan='2'>행정</th><th colspan='2'>국가</th><th colspan='2'>심판</th></tr>")
				.append("<tr><th>변호사</th><th>직접</th><th>변호사</th><th>직접</th><th>변호사</th><th>직접</th>")
				.append("<th>변호사</th><th>직접</th><th>변호사</th><th>직접</th></tr>");
		for (Map<String, Object> r : lawStatService.getDept(digits(req.getParameter("fromDate")),
				digits(req.getParameter("toDate")))) {
			sb.append("<tr>").append(td(r.get("name")))
					.append(td(r.get("totLawer"))).append(td(r.get("totGong")))
					.append(td(r.get("minsaLawer"))).append(td(r.get("minsaGong")))
					.append(td(r.get("hangjungLawer"))).append(td(r.get("hangjungGong")))
					.append(td(r.get("kukgaLawer"))).append(td(r.get("kukgaGong")))
					.append(td(r.get("simpanLawer"))).append(td(r.get("simpanGong"))).append("</tr>");
		}
		sb.append("</table>");
		sendXls(res, "부서별통계.xls", sb.toString());
	}

	// ════════════════════════════════════════ ⑤ 대리인

	// 기간=소제기일(FR_DT) 필터, 빈값=전체 — instance 와 동일 규약
	@RequestMapping("/law/stat/agent.do")
	public String agent(HttpServletRequest req, ModelMap model) {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String from = req.getParameter("fromDate");
		String to = req.getParameter("toDate");
		putPeriod(model, from == null ? "" : from, to == null ? "" : to);
		model.addAllAttributes(lawStatService.getAgent(digits(from), digits(to)));
		return "law/stat/agent";
	}

	@RequestMapping("/law/stat/agentExcel.do")
	public void agentExcel(HttpServletRequest req, HttpServletResponse res) throws Exception {
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		Map<String, Object> data = lawStatService.getAgent(digits(req.getParameter("fromDate")),
				digits(req.getParameter("toDate")));
		@SuppressWarnings("unchecked")
		List<Map<String, Object>> topList = (List<Map<String, Object>>) data.get("topList");
		@SuppressWarnings("unchecked")
		List<Map<String, Object>> bottomList = (List<Map<String, Object>>) data.get("bottomList");

		StringBuilder sb = new StringBuilder();
		sb.append("<table border='1'><tr><th colspan='6'>소송대리인 지정현황(계류사건) — 공무원 수행 비율 ")
				.append(esc(String.valueOf(data.get("officialRate")))).append("%</th></tr>");
		sb.append("<tr><th>구분</th><th>계</th><th>민사</th><th>행정</th><th>국가</th><th>심판</th></tr>");
		for (Map<String, Object> r : topList) {
			sb.append("<tr>").append(td(r.get("name"))).append(td(r.get("totCnt"))).append(td(r.get("minsaCnt")))
					.append(td(r.get("hangjungCnt"))).append(td(r.get("kukgaCnt"))).append(td(r.get("simpanCnt")))
					.append("</tr>");
		}
		sb.append("<tr><td colspan='6'></td></tr>");
		sb.append("<tr><th>대리인</th><th>소속</th><th>합계</th><th>진행중</th><th>종결</th><th>승</th><th>패</th><th>승소율(%)</th><th>비용합계</th></tr>");
		for (Map<String, Object> r : bottomList) {
			sb.append("<tr>").append(td(r.get("name"))).append(td(r.get("companyName"))).append(td(r.get("totCnt")))
					.append(td(r.get("processingCnt"))).append(td(r.get("terminatedCnt"))).append(td(r.get("winCnt")))
					.append(td(r.get("loseCnt"))).append(td(r.get("rate"))).append(td(r.get("totAmt"))).append("</tr>");
		}
		sb.append("</table>");
		sendXls(res, "대리인통계.xls", sb.toString());
	}

	// ════════════════════════════════════════ ⑥ 패소원인

	@RequestMapping("/law/stat/lossCause.do")
	public String lossCause(HttpServletRequest req, ModelMap model) {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String from = defFrom(req.getParameter("fromDate"));
		String to = defTo(req.getParameter("toDate"));
		putPeriod(model, from, to);
		model.addAllAttributes(lawStatService.getLossCause(digits(from), digits(to)));
		return "law/stat/lossCause";
	}

	@RequestMapping("/law/stat/lossCauseExcel.do")
	public void lossCauseExcel(HttpServletRequest req, HttpServletResponse res) throws Exception {
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String from = defFrom(req.getParameter("fromDate"));
		String to = defTo(req.getParameter("toDate"));
		Map<String, Object> data = lawStatService.getLossCause(digits(from), digits(to));
		@SuppressWarnings("unchecked")
		List<Map<String, Object>> list = (List<Map<String, Object>>) data.get("list");
		StringBuilder sb = new StringBuilder();
		sb.append("<table border='1'><tr><th>패소원인</th><th>건수</th><th>비율(%)</th></tr>");
		for (Map<String, Object> r : list) {
			sb.append("<tr>").append(td(r.get("codeName"))).append(td(r.get("cnt"))).append(td(r.get("rate")))
					.append("</tr>");
		}
		sb.append("</table>");
		sendXls(res, "패소원인통계.xls", sb.toString());
	}

	// ════════════════════════════════════════ ⑦ 사건지번표시도

	@RequestMapping("/law/stat/landMap.do")
	public String landMap(HttpServletRequest req, ModelMap model) {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String from = defFrom(req.getParameter("fromDate"));
		String to = defTo(req.getParameter("toDate"));
		putPeriod(model, from, to);
		// 결과 체크박스 (기본 전체 체크)
		boolean[] flags = resultFlags(req, true);
		model.addAttribute("chkProcessing", flags[0]);
		model.addAttribute("chkTerminate", flags[1]);
		model.addAttribute("chkWin", flags[2]);
		model.addAttribute("chkLose", flags[3]);

		String kakaoKey = EgovProperties.getProperty("Globals.law.kakaoMapAppKey");
		model.addAttribute("kakaoKey", kakaoKey == null ? "" : kakaoKey.trim());
		model.addAttribute("mapCenterLat", trimOr(EgovProperties.getProperty("Globals.law.mapCenterLat"), "35.228"));
		model.addAttribute("mapCenterLng", trimOr(EgovProperties.getProperty("Globals.law.mapCenterLng"), "128.889"));

		// 폴백 목록(및 초기 데이터)
		List<String> rsltCds = lawStatService.buildLandResultCodes(flags[0], flags[1], flags[2], flags[3]);
		model.addAttribute("landList", lawStatService.getLandJibun(digits(from), digits(to), rsltCds));
		return "law/stat/landMap";
	}

	@RequestMapping("/law/stat/landMapExcel.do")
	public void landMapExcel(HttpServletRequest req, HttpServletResponse res) throws Exception {
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String from = defFrom(req.getParameter("fromDate"));
		String to = defTo(req.getParameter("toDate"));
		boolean[] flags = resultFlags(req, true);
		List<String> rsltCds = lawStatService.buildLandResultCodes(flags[0], flags[1], flags[2], flags[3]);
		List<Map<String, Object>> list = lawStatService.getLandJibun(digits(from), digits(to), rsltCds);
		StringBuilder sb = new StringBuilder();
		sb.append("<table border='1'><tr><th>번호</th><th>사건번호</th><th>사건명</th><th>소재지·지번</th></tr>");
		int no = list.size();
		for (Map<String, Object> r : list) {
			sb.append("<tr><td>").append(no--).append("</td>").append(td(r.get("caseNo"))).append(td(r.get("caseNm")))
					.append(td(r.get("address"))).append("</tr>");
		}
		sb.append("</table>");
		sendXls(res, "사건지번목록.xls", sb.toString());
	}

	/** 지번 JSON — 지도 마커 원천 (사건번호·사건명·주소) */
	@RequestMapping("/law/stat/landMapJson.do")
	public void landMapJson(HttpServletRequest req, HttpServletResponse res) throws Exception {
		res.setContentType("application/json; charset=UTF-8");
		if (!authed()) {
			res.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		String from = defFrom(req.getParameter("fromDate"));
		String to = defTo(req.getParameter("toDate"));
		boolean[] flags = resultFlags(req, false);
		List<String> rsltCds = lawStatService.buildLandResultCodes(flags[0], flags[1], flags[2], flags[3]);
		List<Map<String, Object>> list = lawStatService.getLandJibun(digits(from), digits(to), rsltCds);
		PrintWriter w = res.getWriter();
		w.write(OM.writeValueAsString(list));
		w.flush();
	}

	/** processing/terminate/win/lose 파라미터 → boolean[4]. 파라미터 자체가 없으면(초기 진입) defAll 적용 */
	private boolean[] resultFlags(HttpServletRequest req, boolean initialDefaultAll) {
		boolean hasAny = req.getParameter("processing") != null || req.getParameter("terminate") != null
				|| req.getParameter("win") != null || req.getParameter("lose") != null
				|| req.getParameter("searched") != null;
		if (!hasAny && initialDefaultAll) {
			return new boolean[] { true, true, true, true };
		}
		return new boolean[] { "Y".equals(req.getParameter("processing")), "Y".equals(req.getParameter("terminate")),
				"Y".equals(req.getParameter("win")), "Y".equals(req.getParameter("lose")) };
	}

	private static String trimOr(String v, String def) {
		return (v == null || v.trim().isEmpty()) ? def : v.trim();
	}

	// ════════════════════════════════════════ 엑셀 공통 (HTML-table .xls)

	private void sendXls(HttpServletResponse res, String fileName, String tableHtml) throws Exception {
		String fname = URLEncoder.encode(fileName, "UTF-8").replaceAll("\\+", "%20");
		res.setContentType("application/vnd.ms-excel; charset=UTF-8");
		res.setHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
		PrintWriter w = res.getWriter();
		w.write('﻿');
		w.print(tableHtml);
		w.flush();
	}

	private static String esc(String s) {
		return s == null ? "" : s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}

	private static String td(Object o) {
		return "<td>" + (o == null ? "" : esc(o.toString())) + "</td>";
	}
}
