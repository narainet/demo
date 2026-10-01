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
