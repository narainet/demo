/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stsfdg/web/StsfdgAdmController.java
 *
 * 만족도 조사 현황 (관리자) — 규정(TB_PROM_STSFDG) + 게시판(COMTNSTSFDG) 참여 현황/집계.
 *   GET  /rlms/stats/stsfdgStats.do?tab=prom|bbs&searchKeyword=&pageIndex=   집계 목록(탭 2개)
 *   GET  /rlms/stats/stsfdgDetailJson.do                                    대상별 참여 상세
 *   POST /rlms/stats/stsfdgDeleteJson.do                                    참여 건별 삭제(운영 정리)
 *
 * - URL 을 기존 통계 폴더(/rlms/stats/)에 얹어 L6 파생(ROLE_ADMIN)·mgr 데코를 그대로 계승(설정 변경 0건).
 *   메뉴 = 통계(45000000) > 만족도 조사 현황(45050000), database/rlms_stsfdg_stats_menu.sql.
 * - 게시판 참여 삭제는 표준 만족도 관례대로 소프트(USE_AT='N'), 규정 참여 삭제는 행 DELETE
 *   (1인 1회 재참여 허용 구조라 소프트 잔재가 유니크 키를 막지 않게).
 */
package narainet.rlms.stsfdg.web;

import java.io.PrintWriter;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import narainet.rlms.stsfdg.mapper.PromStsfdgMapper;

@Controller
public class StsfdgAdmController {

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	@Resource
	private PromStsfdgMapper promStsfdgMapper;

	/** 집계 목록 — tab=prom(규정 회차별) | bbs(게시글별) */
	@RequestMapping("/rlms/stats/stsfdgStats.do")
	public String stsfdgStats(
			@RequestParam(value = "tab", required = false, defaultValue = "prom") String tab,
			@RequestParam(value = "searchKeyword", required = false) String searchKeyword,
			@RequestParam(value = "fromDt", required = false) String fromDt,
			@RequestParam(value = "toDt", required = false) String toDt,
			@RequestParam(value = "pageIndex", required = false, defaultValue = "1") int pageIndex,
			ModelMap model) throws Exception {

		if (!"prom".equals(tab) && !"bbs".equals(tab)) {
			tab = "prom";
		}
		String keyword = searchKeyword == null ? "" : searchKeyword.trim();
		String f = normDate(fromDt);
		String t = normDate(toDt);

		int pageUnit = propertyService.getInt("pageUnit");
		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(pageIndex);
		pi.setRecordCountPerPage(pageUnit);
		pi.setPageSize(propertyService.getInt("pageSize"));

		Map<String, Object> p = new HashMap<>();
		p.put("keyword", keyword.isEmpty() ? null : keyword);
		p.put("fromDt", f);
		p.put("toDt", t);
		p.put("firstIndex", pi.getFirstRecordIndex());
		p.put("recordCountPerPage", pageUnit);

		int totCnt;
		List<Map<String, Object>> list;
		if ("bbs".equals(tab)) {
			totCnt = promStsfdgMapper.countBbsAgg(p);
			list = promStsfdgMapper.selectBbsAggList(p);
		} else {
			totCnt = promStsfdgMapper.countPromAgg(p);
			list = promStsfdgMapper.selectPromAggList(p);
		}
		pi.setTotalRecordCount(totCnt);

		model.addAttribute("tab", tab);
		model.addAttribute("searchKeyword", keyword);
		model.addAttribute("fromDt", f == null ? "" : f);
		model.addAttribute("toDt", t == null ? "" : t);
		model.addAttribute("resultList", list);
		model.addAttribute("resultCnt", totCnt);
		model.addAttribute("paginationInfo", pi);
		return "rlms/stsfdg/stsfdgStats";
	}

	/** 참여 상세 — prom: promNo / bbs: bbsId+nttId. 규정 행에는 wrterId(=SINS_ID, 관리자 삭제 키) 포함. */
	@RequestMapping("/rlms/stats/stsfdgDetailJson.do")
	@ResponseBody
	public Map<String, Object> detailJson(
			@RequestParam(value = "tab", required = false, defaultValue = "prom") String tab,
			@RequestParam(value = "promNo", required = false) Long promNo,
			@RequestParam(value = "bbsId", required = false) String bbsId,
			@RequestParam(value = "nttId", required = false) Long nttId,
			@RequestParam(value = "fromDt", required = false) String fromDt,
			@RequestParam(value = "toDt", required = false) String toDt) {
		Map<String, Object> res = new HashMap<>();
		try {
			String f = normDate(fromDt);
			String t = normDate(toDt);
			List<Map<String, Object>> list;
			if ("bbs".equals(tab)) {
				if (bbsId == null || bbsId.trim().isEmpty() || nttId == null) {
					res.put("ok", false); res.put("message", "대상이 없습니다."); return res;
				}
				list = promStsfdgMapper.selectBbsDetailList(bbsId, nttId, f, t);
			} else {
				if (promNo == null) {
					res.put("ok", false); res.put("message", "대상이 없습니다."); return res;
				}
				list = promStsfdgMapper.selectList(promNo, f, t);
			}
			res.put("ok", true);
			res.put("list", list == null ? new ArrayList<>() : list);
		} catch (Exception e) {
			res.put("ok", false);
			res.put("message", "상세를 불러오지 못했습니다.");
		}
		return res;
	}

	/** 참여 건별 삭제(운영 정리) — prom: promNo+sinsId 행 DELETE / bbs: stsfdgNo 소프트삭제(USE_AT='N').
	 *  파괴적 액션이라 POST 전용 — 전역 csrf 비활성 환경에서 GET 드라이브바이(img/프리페치) 삭제 차단. */
	@RequestMapping(value = "/rlms/stats/stsfdgDeleteJson.do", method = RequestMethod.POST)
	@ResponseBody
	public Map<String, Object> deleteJson(
			@RequestParam(value = "tab", required = false, defaultValue = "prom") String tab,
			@RequestParam(value = "promNo", required = false) Long promNo,
			@RequestParam(value = "sinsId", required = false) String sinsId,
			@RequestParam(value = "stsfdgNo", required = false) String stsfdgNo) {
		Map<String, Object> res = new HashMap<>();
		try {
			int n;
			if ("bbs".equals(tab)) {
				if (stsfdgNo == null || !stsfdgNo.trim().matches("\\d+")) {
					res.put("ok", false); res.put("message", "대상이 없습니다."); return res;
				}
				n = promStsfdgMapper.softDeleteBbsStsfdg(stsfdgNo.trim());
			} else {
				if (promNo == null || sinsId == null || sinsId.trim().isEmpty()) {
					res.put("ok", false); res.put("message", "대상이 없습니다."); return res;
				}
				n = promStsfdgMapper.deleteByAdmin(promNo, sinsId.trim());
			}
			res.put("ok", n > 0);
			if (n == 0) {
				res.put("message", "이미 삭제되었거나 없는 참여입니다.");
			}
		} catch (Exception e) {
			res.put("ok", false);
			res.put("message", "삭제에 실패했습니다.");
		}
		return res;
	}

	/** 엑셀 내보내기 — 전체 참여 상세(규정+게시판, 필터 무관). lawQuestExcel 선례:
	 *  HTML 테이블 → .xls (POI 미사용 — poi-ooxml/xmlbeans 충돌 회피 관행), UTF-8 BOM, 셀 텍스트 강제. */
	@RequestMapping("/rlms/stats/stsfdgExcel.do")
	public void excel(
			@RequestParam(value = "fromDt", required = false) String fromDt,
			@RequestParam(value = "toDt", required = false) String toDt,
			HttpServletResponse response) throws Exception {
		String f = normDate(fromDt);
		String t = normDate(toDt);
		List<Map<String, Object>> promRows = promStsfdgMapper.selectPromExportList(f, t);
		List<Map<String, Object>> bbsRows = promStsfdgMapper.selectBbsExportList(f, t);

		String fname = URLEncoder.encode("만족도조사현황.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);

		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF); // UTF-8 BOM — Excel 한글 인식
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");

		w.print("<table border=\"1\"><tr><th colspan=\"9\" style=\"background:#DCE6F7\">규정 만족도 조사</th></tr><tr>");
		for (String h : new String[] { "분류", "규정명", "소관부서", "연혁번호", "현행", "참여자", "별점", "의견", "참여일시" }) {
			w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		}
		w.print("</tr>");
		for (Map<String, Object> r : promRows) {
			w.print("<tr>");
			w.print(xcell(r.get("cateNm")));
			w.print(xcell(r.get("title")));
			w.print(xcell(r.get("buseoNm")));
			w.print(xcell(r.get("lawNo")));
			w.print(xcell("Y".equals(r.get("existingYn")) ? "현행" : ""));
			w.print(xcell(r.get("wrterNm")));
			w.print(xcell(r.get("stsfdg")));
			w.print(xcell(r.get("content")));
			w.print(xcell(r.get("regDt")));
			w.print("</tr>");
		}
		if (promRows.isEmpty()) {
			w.print("<tr><td colspan=\"9\">참여 없음</td></tr>");
		}
		w.print("</table><br/>");

		w.print("<table border=\"1\"><tr><th colspan=\"6\" style=\"background:#DCE6F7\">게시판 만족도 조사</th></tr><tr>");
		for (String h : new String[] { "게시판", "글제목", "참여자", "별점", "의견", "참여일시" }) {
			w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		}
		w.print("</tr>");
		for (Map<String, Object> r : bbsRows) {
			w.print("<tr>");
			w.print(xcell(r.get("bbsNm")));
			Object bt = r.get("title");
			w.print(xcell("N".equals(r.get("articleUseAt"))
					? (bt == null ? "" : bt) + " (삭제글)" : bt));
			w.print(xcell(r.get("wrterNm")));
			w.print(xcell(r.get("stsfdg")));
			w.print(xcell(r.get("content")));
			w.print(xcell(r.get("regDt")));
			w.print("</tr>");
		}
		if (bbsRows.isEmpty()) {
			w.print("<tr><td colspan=\"6\">참여 없음</td></tr>");
		}
		w.print("</table></body></html>");
		w.flush();
	}

	/** 기간 파라미터 정규화 — yyyy-MM-dd 형식만 통과(그 외 null = 무제한) */
	private static String normDate(String v) {
		return (v != null && v.matches("\\d{4}-\\d{2}-\\d{2}")) ? v : null;
	}

	/** 엑셀 셀 — HTML 이스케이프 + 텍스트 강제(mso-number-format), LawQuestController.xcell 동일 패턴 */
	private static String xcell(Object v) {
		String s = v == null ? "" : String.valueOf(v)
				.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
		return "<td style=\"mso-number-format:'\\@'\">" + s + "</td>";
	}
}
