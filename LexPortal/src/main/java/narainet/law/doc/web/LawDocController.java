/*
 * 물리적 저장 경로: /src/main/java/narainet/law/doc/web/LawDocController.java
 *
 * 소송문서 조회·승인 Controller (LAW_MODULE_DESIGN.md §7.2).
 *   조회(list) + 엑셀 + ZIP 일괄(표준 FileZipDown 연동) / 등록·수정·삭제(사건 상세 탭에서 호출)
 *   / 승인 화면(approvalList) + 승인·반려 처리(approveJson).
 *   첨부=표준 COMTNFILE(LawFileSupport). 등록=대기, 수정 시 대기 리셋(서비스).
 */
package narainet.law.doc.web;

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
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.common.LawTextUtil;
import narainet.law.common.mapper.LawComMapper;
import narainet.law.doc.service.LawDocService;
import narainet.law.doc.service.LawSuitDocVO;

@Controller
public class LawDocController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawDocController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "lawDocService")
	private LawDocService lawDocService;

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

	private void loadSearchCodes(ModelMap model) {
		model.addAttribute("caseKinds", lawComMapper.selectCmmnCodeList("LAW_CASE_KIND"));
		model.addAttribute("itptKinds", lawComMapper.selectCmmnCodeList("LAW_ITPT_KIND"));
		model.addAttribute("results", lawComMapper.selectCmmnCodeList("LAW_RESULT"));
		model.addAttribute("caseSigns", lawComMapper.selectCmmnCodeList("LAW_CASE_SIGN"));
		model.addAttribute("docKinds", lawComMapper.selectCmmnCodeList("LAW_DOC_KIND"));
	}

	private void applySearchDates(LawSuitDocVO vo) {
		vo.setSearchFrFrom(toDb(vo.getSearchFrFrom()));
		vo.setSearchFrTo(toDb(vo.getSearchFrTo()));
	}

	// ────────────────────────────────────────────────────────────────
	// 조회 화면
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/law/doc/list.do")
	public String list(@ModelAttribute("searchVO") LawSuitDocVO searchVO, ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		applySearchDates(searchVO);
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());
		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = lawDocService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("zipAtchFileIds", lawDocService.getZipAtchFileIds(searchVO));
		loadSearchCodes(model);
		return "law/doc/list";
	}

	@RequestMapping("/law/doc/listExcel.do")
	public void listExcel(@ModelAttribute("searchVO") LawSuitDocVO searchVO, HttpServletResponse response) throws Exception {
		if (!authed()) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		applySearchDates(searchVO);
		searchVO.setFirstIndex(0);
		searchVO.setLastIndex(100000);
		searchVO.setRecordCountPerPage(100000);
		Map<String, Object> result = lawDocService.getList(searchVO);
		@SuppressWarnings("unchecked")
		List<LawSuitDocVO> list = (List<LawSuitDocVO>) result.get("resultList");

		String fname = URLEncoder.encode("소송문서.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
		PrintWriter w = response.getWriter();
		w.write('﻿');
		w.println("<table border='1'><tr><th>번호</th><th>법원명</th><th>사건번호</th><th>사건명</th>"
				+ "<th>문서종류</th><th>문서명</th><th>승인상태</th><th>등록일자</th></tr>");
		int no = list.size();
		for (LawSuitDocVO r : list) {
			w.println("<tr><td>" + (no--) + "</td>" + td(r.getCourtNm()) + tdText(r.getCaseNo()) + td(r.getCaseNm())
					+ td(r.getDocKindNm()) + td(r.getDocTitl()) + td(r.getAppStsNm())
					+ td(dash(r.getRegDt())) + "</tr>");
		}
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
	@RequestMapping(value = "/law/doc/save.do", method = RequestMethod.POST)
	public String save(final MultipartHttpServletRequest multiRequest,
			@ModelAttribute LawSuitDocVO vo, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		String back = "redirect:/law/suit/view.do?suitId=" + vo.getSuitId();
		try {
			if (vo.getSuitId() == null) {
				ra.addFlashAttribute("message", "사건 정보가 없습니다.");
				return "redirect:/law/suit/list.do";
			}
			vo.setDocTitl(LawTextUtil.unescape(vo.getDocTitl()));
			vo.setDocMemo(LawTextUtil.unescape(vo.getDocMemo()));
			List<MultipartFile> files = multiRequest.getFiles("file_1");
			LoginVO user = currentUser();
			lawDocService.save(vo, files, user == null ? null : user.getId());
			ra.addFlashAttribute("message", "문서를 저장했습니다. (승인대기)");
		} catch (Exception e) {
			LOGGER.warn("문서 저장 실패", e);
			ra.addFlashAttribute("message", "저장 중 오류가 발생했습니다.");
		}
		return back;
	}

	@ResponseBody
	@RequestMapping(value = "/law/doc/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("docId") Long docId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			lawDocService.delete(docId);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("문서 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}

	// ────────────────────────────────────────────────────────────────
	// 승인 화면
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/law/doc/approvalList.do")
	public String approvalList(@ModelAttribute("searchVO") LawSuitDocVO searchVO, ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		// 기본 탭 = 대기(S001). 처리 탭은 화면에서 searchAppSts=DONE/S002/S003 로 진입.
		if (searchVO.getSearchAppSts() == null || searchVO.getSearchAppSts().trim().isEmpty()) {
			searchVO.setSearchAppSts("S001");
		}
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());
		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = lawDocService.getApprovalList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("tab", "S001".equals(searchVO.getSearchAppSts()) ? "PENDING" : "DONE");
		return "law/doc/approvalList";
	}

	/** 승인/반려 처리 — 반려는 사유 필수. 자기 등록 문서 승인 허용. (POST) */
	@ResponseBody
	@RequestMapping(value = "/law/doc/approveJson.do", method = RequestMethod.POST)
	public Map<String, Object> approveJson(@RequestParam("docId") Long docId,
			@RequestParam("action") String action,
			@RequestParam(value = "opinion", required = false) String opinion) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			boolean reject = "reject".equals(action);
			String op = LawTextUtil.unescape(opinion);
			if (reject && (op == null || op.trim().isEmpty())) {
				res.put("success", false);
				res.put("message", "반려 사유를 입력하세요.");
				return res;
			}
			LoginVO user = currentUser();
			LawSuitDocVO vo = new LawSuitDocVO();
			vo.setDocId(docId);
			vo.setAppStsCd(reject ? "S003" : "S002");
			vo.setAppUserId(user == null ? null : user.getId());
			vo.setAppUserNm(user == null ? null : user.getName());
			vo.setAppOpinion(op);
			lawDocService.approve(vo);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("문서 승인 처리 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "처리 중 오류가 발생했습니다.");
		}
		return res;
	}
}
