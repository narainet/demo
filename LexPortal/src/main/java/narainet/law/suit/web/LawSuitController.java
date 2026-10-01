/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/web/LawSuitController.java
 *
 * 소송관리(조회·등록·상세 통합) Controller — LAW_MODULE_DESIGN.md §7.1.
 *   메뉴는 '소송조회' 하나: list → [등록] regist → 저장 → view, 행 클릭 → view → [수정] edit.
 *   서브그리드(당사자/토지/수행자/진행)는 폼 hidden JSON 으로 받아 한 트랜잭션 일괄 저장.
 *   날짜 입력은 native date(yyyy-MM-dd) ↔ DB 'YYYYMMDD' 서버 변환.
 *   사건 검색 모달(searchJson)은 심급연결·일정·선임 공용.
 */
package narainet.law.suit.web;

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

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.assign.service.LawAssignService;
import narainet.law.common.LawTextUtil;
import narainet.law.common.mapper.LawComMapper;
import narainet.law.cost.service.LawCostService;
import narainet.law.doc.service.LawDocService;
import narainet.law.req.service.LawReqService;
import narainet.law.req.service.LawSuitReqVO;
import narainet.law.suit.service.LawSuitLandVO;
import narainet.law.suit.service.LawSuitPartyVO;
import narainet.law.suit.service.LawSuitProgVO;
import narainet.law.suit.service.LawSuitRsltHistVO;
import narainet.law.suit.service.LawSuitService;
import narainet.law.suit.service.LawSuitStaffVO;
import narainet.law.suit.service.LawSuitVO;

@Controller
public class LawSuitController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawSuitController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final ObjectMapper OM = new ObjectMapper();

	@Resource(name = "lawSuitService")
	private LawSuitService lawSuitService;

	@Resource(name = "lawComMapper")
	private LawComMapper lawComMapper;

	@Resource(name = "lawDocService")
	private LawDocService lawDocService;

	@Resource(name = "lawCostService")
	private LawCostService lawCostService;

	@Resource(name = "lawAssignService")
	private LawAssignService lawAssignService;

	@Resource(name = "lawReqService")
	private LawReqService lawReqService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	private LoginVO currentUser() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return u instanceof LoginVO ? (LoginVO) u : null;
	}

	/** yyyy-MM-dd → YYYYMMDD (그 외 형식·빈값은 숫자만 남김) */
	private static String toDb(String d) {
		if (d == null) {
			return null;
		}
		String digits = d.replaceAll("[^0-9]", "");
		return digits.isEmpty() ? null : digits;
	}

	private void applySearchDates(LawSuitVO vo) {
		vo.setSearchFixFrom(toDb(vo.getSearchFixFrom()));
		vo.setSearchFixTo(toDb(vo.getSearchFixTo()));
	}

	private void applyFormDates(LawSuitVO vo) {
		vo.setOfficeReceiptDt(toDb(vo.getOfficeReceiptDt()));
		vo.setFrDt(toDb(vo.getFrDt()));
		vo.setStcDt(toDb(vo.getStcDt()));
		vo.setDcsnDt(toDb(vo.getDcsnDt()));
		vo.setCostFixDt(toDb(vo.getCostFixDt()));
	}

	/** 등록/수정 폼 셀렉트 소스 (ccm·법원·부서) */
	private void loadFormCodes(ModelMap model) {
		model.addAttribute("caseKinds", lawComMapper.selectCmmnCodeList("LAW_CASE_KIND"));
		model.addAttribute("instances", lawComMapper.selectCmmnCodeList("LAW_INSTANCE"));
		model.addAttribute("itptKinds", lawComMapper.selectCmmnCodeList("LAW_ITPT_KIND"));
		model.addAttribute("civilCases", lawComMapper.selectCmmnCodeList("LAW_CIVIL_CASE"));
		model.addAttribute("caseSigns", lawComMapper.selectCmmnCodeList("LAW_CASE_SIGN"));
		model.addAttribute("caseNms", lawComMapper.selectCmmnCodeList("LAW_CASE_NM"));
		model.addAttribute("results", lawComMapper.selectCmmnCodeList("LAW_RESULT"));
		model.addAttribute("lossCauses", lawComMapper.selectCmmnCodeList("LAW_LOSS_CAUSE"));
		model.addAttribute("progKinds", lawComMapper.selectCmmnCodeList("LAW_PROG_KIND"));
		model.addAttribute("progStats", lawComMapper.selectCmmnCodeList("LAW_PROG_STAT"));
		model.addAttribute("dyprKinds", lawComMapper.selectCmmnCodeList("LAW_DYPR_KIND"));
		model.addAttribute("courts", lawComMapper.selectCourtList());
		model.addAttribute("orgnzts", lawComMapper.selectOrgnztList());
	}

	// ────────────────────────────────────────────────────────────────
	// 목록 (14열, §7.1) + 엑셀
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/law/suit/list.do")
	public String list(@ModelAttribute("searchVO") LawSuitVO searchVO, ModelMap model) throws Exception {
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

		Map<String, Object> result = lawSuitService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("caseKinds", lawComMapper.selectCmmnCodeList("LAW_CASE_KIND"));
		model.addAttribute("itptKinds", lawComMapper.selectCmmnCodeList("LAW_ITPT_KIND"));
		model.addAttribute("results", lawComMapper.selectCmmnCodeList("LAW_RESULT"));
		model.addAttribute("caseSigns", lawComMapper.selectCmmnCodeList("LAW_CASE_SIGN"));
		return "law/suit/list";
	}

	/** 엑셀 — 화면과 동일 집계 전건 (HTML 테이블 .xls 관행 — POI 미사용) */
	@RequestMapping("/law/suit/listExcel.do")
	public void listExcel(@ModelAttribute("searchVO") LawSuitVO searchVO, HttpServletResponse response) throws Exception {
		if (!authed()) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		applySearchDates(searchVO);
		searchVO.setFirstIndex(0);
		searchVO.setLastIndex(100000);
		searchVO.setRecordCountPerPage(100000);
		Map<String, Object> result = lawSuitService.getList(searchVO);
		@SuppressWarnings("unchecked")
		List<LawSuitVO> list = (List<LawSuitVO>) result.get("resultList");

		String fname = URLEncoder.encode("소송조회.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
		PrintWriter w = response.getWriter();
		w.write('﻿');
		w.println("<table border='1'><tr>"
				+ "<th>번호</th><th>소송구분</th><th>법원명</th><th>사건번호</th><th>사건명</th><th>심급</th>"
				+ "<th>원고</th><th>피고</th><th>사건토지</th><th>소송진행상황</th>"
				+ "<th>소제기일</th><th>최종선고일</th><th>소가</th><th>승(패)소금액</th></tr>");
		int no = list.size();
		for (LawSuitVO r : list) {
			w.println("<tr><td>" + (no--) + "</td>"
					+ td(r.getCaseKindNm()) + td(r.getCourtNm()) + tdText(r.getCaseNo()) + td(r.getCaseNm()) + td(r.getInstanceNm())
					+ td(party(r.getPlaintiffNm(), r.getPlaintiffCnt())) + td(party(r.getDefendantNm(), r.getDefendantCnt()))
					+ td(land(r.getLandSummary(), r.getLandCnt())) + td(r.getProgSummary())
					+ td(dash(r.getFrDt())) + td(dash(r.getStcDt())) + td(num(r.getSuitAmt())) + td(num(winLose(r))) + "</tr>");
		}
		w.println("</table>");
		w.flush();
	}

	private static Long winLose(LawSuitVO r) {
		return r.getWinAmt() != null ? r.getWinAmt() : r.getLoseAmt();
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

	private static String td(Long n) {
		return "<td>" + (n == null ? "" : n) + "</td>";
	}

	private static String num(Long n) {
		return n == null ? "" : String.valueOf(n);
	}

	private static String td(Object o) {
		return "<td>" + (o == null ? "" : esc(o.toString())) + "</td>";
	}

	private static String dash(String yyyymmdd) {
		if (yyyymmdd == null || yyyymmdd.length() != 8) {
			return "";
		}
		return yyyymmdd.substring(0, 4) + "-" + yyyymmdd.substring(4, 6) + "-" + yyyymmdd.substring(6);
	}

	private static String party(String nm, Integer cnt) {
		if (nm == null) {
			return "";
		}
		int c = cnt == null ? 0 : cnt;
		return c > 1 ? nm + " 외 " + (c - 1) : nm;
	}

	private static String land(String summary, Integer cnt) {
		if (summary == null) {
			return "";
		}
		int c = cnt == null ? 0 : cnt;
		return c > 1 ? summary + " 외 " + (c - 1) : summary;
	}

	// ────────────────────────────────────────────────────────────────
	// 등록 / 수정 폼
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/law/suit/regist.do")
	public String regist(@RequestParam(value = "reqId", required = false) Long reqId,
			ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		loadFormCodes(model);
		model.addAttribute("mode", "regist");
		// 소송의뢰 연계 등록 — 승인분(S002)·미연계만. 사건명·사실관계·보조자 정보 프리필(§7.9).
		if (reqId != null) {
			LawSuitReqVO linkReq = lawReqService.getDetail(reqId);
			if (linkReq == null || !"S002".equals(linkReq.getStatusCd())) {
				ra.addFlashAttribute("message", "승인된 소송의뢰만 소송으로 등록할 수 있습니다.");
				return "redirect:/law/req/list.do";
			}
			if (linkReq.getSuitId() != null) {
				ra.addFlashAttribute("message", "이미 소송으로 등록된 의뢰입니다.");
				return "redirect:/law/suit/view.do?suitId=" + linkReq.getSuitId();
			}
			model.addAttribute("linkReq", linkReq);
			model.addAttribute("linkReqId", reqId);
			model.addAttribute("prefillCaseNm", linkReq.getReqTitl());
			model.addAttribute("prefillDesc", linkReq.getReqCn());
		}
		return "law/suit/form";
	}

	@RequestMapping("/law/suit/edit.do")
	public String edit(@RequestParam("suitId") Long suitId, ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		Map<String, Object> detail = lawSuitService.getDetail(suitId);
		if (detail == null) {
			ra.addFlashAttribute("message", "존재하지 않는 사건입니다.");
			return "redirect:/law/suit/list.do";
		}
		dashDetailDates(detail);
		loadFormCodes(model);
		model.addAllAttributes(detail);
		// 서브그리드 초기 데이터 — hidden textarea 에 담아 JS 가 JSON.parse (HTML 이스케이프 경유라 안전)
		model.addAttribute("partiesJsonStr", OM.writeValueAsString(detail.get("parties")));
		model.addAttribute("landsJsonStr", OM.writeValueAsString(detail.get("lands")));
		model.addAttribute("staffsJsonStr", OM.writeValueAsString(detail.get("staffs")));
		model.addAttribute("progsJsonStr", OM.writeValueAsString(detail.get("progs")));
		model.addAttribute("mode", "edit");
		return "law/suit/form";
	}

	/** 상세 묶음의 날짜 필드들을 표시·date input 겸용 yyyy-MM-dd 로 변환 */
	@SuppressWarnings("unchecked")
	private void dashDetailDates(Map<String, Object> detail) {
		LawSuitVO s = (LawSuitVO) detail.get("suit");
		if (s != null) {
			s.setOfficeReceiptDt(dash(s.getOfficeReceiptDt()));
			s.setFrDt(dash(s.getFrDt()));
			s.setStcDt(dash(s.getStcDt()));
			s.setDcsnDt(dash(s.getDcsnDt()));
			s.setCostFixDt(dash(s.getCostFixDt()));
		}
		List<LawSuitStaffVO> staffs = (List<LawSuitStaffVO>) detail.get("staffs");
		if (staffs != null) {
			for (LawSuitStaffVO t : staffs) {
				t.setAssignDt(dash(t.getAssignDt()));
			}
		}
		List<LawSuitProgVO> progs = (List<LawSuitProgVO>) detail.get("progs");
		if (progs != null) {
			for (LawSuitProgVO g : progs) {
				g.setProgDt(dash(g.getProgDt()));
			}
		}
		List<LawSuitRsltHistVO> hists = (List<LawSuitRsltHistVO>) detail.get("rsltHists");
		if (hists != null) {
			for (LawSuitRsltHistVO h : hists) {
				h.setEndDt(dash(h.getEndDt()));
			}
		}
		List<LawSuitVO> insts = (List<LawSuitVO>) detail.get("instanceSuits");
		if (insts != null) {
			for (LawSuitVO i : insts) {
				i.setFrDt(dash(i.getFrDt()));
				i.setStcDt(dash(i.getStcDt()));
			}
		}
	}

	// ────────────────────────────────────────────────────────────────
	// 저장 (본체 + 서브그리드 JSON 4종 — 한 트랜잭션)
	// ────────────────────────────────────────────────────────────────
	@RequestMapping(value = "/law/suit/save.do", method = RequestMethod.POST)
	public String save(@ModelAttribute LawSuitVO vo,
			@RequestParam(value = "partiesJson", required = false) String partiesJson,
			@RequestParam(value = "landsJson", required = false) String landsJson,
			@RequestParam(value = "staffsJson", required = false) String staffsJson,
			@RequestParam(value = "progsJson", required = false) String progsJson,
			@RequestParam(value = "reqId", required = false) Long reqId,
			RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		try {
			applyFormDates(vo);
			unescapeTexts(vo);
			// 사건번호 표시 결합 (연도+부호명+일련 — 부호명은 화면 확정값 caseNo 우선, 없으면 서버 결합)
			if (vo.getCaseNo() == null || vo.getCaseNo().trim().isEmpty()) {
				String sign = vo.getCaseSignCd() == null ? "" : vo.getCaseSignCd();
				vo.setCaseNo(((vo.getCaseYear() == null ? "" : vo.getCaseYear()) + sign
						+ (vo.getCaseSerial() == null ? "" : vo.getCaseSerial())).trim());
			}

			// HTMLTagFilter 가 JSON 의 따옴표·괄호를 엔티티로 바꿔 놓는다 — 파싱 전 복원(값도 함께 원문 복원)
			List<LawSuitPartyVO> parties = parse(LawTextUtil.unescape(partiesJson), new TypeReference<List<LawSuitPartyVO>>() { });
			List<LawSuitLandVO> lands = parse(LawTextUtil.unescape(landsJson), new TypeReference<List<LawSuitLandVO>>() { });
			List<LawSuitStaffVO> staffs = parse(LawTextUtil.unescape(staffsJson), new TypeReference<List<LawSuitStaffVO>>() { });
			List<LawSuitProgVO> progs = parse(LawTextUtil.unescape(progsJson), new TypeReference<List<LawSuitProgVO>>() { });
			normalizeSubDates(parties, lands, staffs, progs);

			LoginVO user = currentUser();
			boolean wasNew = vo.getSuitId() == null;
			Long suitId = lawSuitService.save(vo, parties, lands, staffs, progs, user == null ? null : user.getId());
			// 소송의뢰 연계 등록이면 REQ.SUIT_ID 역기입(신규·승인분·미연계 한정)
			if (reqId != null && wasNew) {
				LawSuitReqVO linkReq = lawReqService.getReq(reqId);
				if (linkReq != null && "S002".equals(linkReq.getStatusCd()) && linkReq.getSuitId() == null) {
					lawReqService.linkSuit(reqId, suitId, user == null ? null : user.getId());
				}
			}
			ra.addFlashAttribute("message", "저장했습니다.");
			return "redirect:/law/suit/view.do?suitId=" + suitId;
		} catch (Exception e) {
			LOGGER.warn("사건 저장 실패", e);
			ra.addFlashAttribute("message", "저장 중 오류가 발생했습니다.");
			return vo.getSuitId() == null ? "redirect:/law/suit/regist.do"
					: "redirect:/law/suit/edit.do?suitId=" + vo.getSuitId();
		}
	}

	private <T> List<T> parse(String json, TypeReference<List<T>> type) throws Exception {
		if (json == null || json.trim().isEmpty()) {
			return null;
		}
		return OM.readValue(json, type);
	}

	/** 자유 텍스트 필드의 HTMLTagFilter 엔티티 복원 (코드값 select 는 영숫자라 무관) */
	private void unescapeTexts(LawSuitVO vo) {
		vo.setCourtNm(LawTextUtil.unescape(vo.getCourtNm()));
		vo.setCaseSerial(LawTextUtil.unescape(vo.getCaseSerial()));
		vo.setCaseNo(LawTextUtil.unescape(vo.getCaseNo()));
		vo.setCaseNm(LawTextUtil.unescape(vo.getCaseNm()));
		vo.setRsltKindNm(LawTextUtil.unescape(vo.getRsltKindNm()));
		vo.setMergeCase(LawTextUtil.unescape(vo.getMergeCase()));
		vo.setSpecialDesc(LawTextUtil.unescape(vo.getSpecialDesc()));
	}

	private void normalizeSubDates(List<LawSuitPartyVO> parties, List<LawSuitLandVO> lands,
			List<LawSuitStaffVO> staffs, List<LawSuitProgVO> progs) {
		if (parties != null) {
			for (LawSuitPartyVO p : parties) {
				p.setBirth(toDb(p.getBirth()));
			}
		}
		if (staffs != null) {
			for (LawSuitStaffVO s : staffs) {
				s.setAssignDt(toDb(s.getAssignDt()));
			}
		}
		if (progs != null) {
			for (LawSuitProgVO g : progs) {
				g.setProgDt(toDb(g.getProgDt()));
				if (g.getProgTm() != null) {
					g.setProgTm(g.getProgTm().replaceAll("[^0-9]", ""));
				}
			}
		}
	}

	// ────────────────────────────────────────────────────────────────
	// 상세 / 삭제 / 사건 검색 모달
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/law/suit/view.do")
	public String view(@RequestParam("suitId") Long suitId, ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		Map<String, Object> detail = lawSuitService.getDetail(suitId);
		if (detail == null) {
			ra.addFlashAttribute("message", "존재하지 않는 사건입니다.");
			return "redirect:/law/suit/list.do";
		}
		dashDetailDates(detail);
		model.addAllAttributes(detail);
		// 사건 허브 — 문서·비용·선임 목록 + 등록 모달용 코드
		model.addAttribute("docs", lawDocService.getListBySuit(suitId));
		model.addAttribute("costs", lawCostService.getListBySuit(suitId));
		model.addAttribute("assigns", lawAssignService.getListBySuit(suitId));
		model.addAttribute("docKinds", lawComMapper.selectCmmnCodeList("LAW_DOC_KIND"));
		model.addAttribute("costKinds", lawComMapper.selectCmmnCodeList("LAW_COST_KIND"));
		model.addAttribute("lawyerOptions", lawComMapper.selectLawyerOptions());
		return "law/suit/view";
	}

	@ResponseBody
	@RequestMapping(value = "/law/suit/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("suitId") Long suitId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			LoginVO user = currentUser();
			lawSuitService.delete(suitId, user == null ? null : user.getId());
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("사건 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}

	/** 사건 검색 모달 (심급연결·일정·선임 공용 — 상위 20) */
	@ResponseBody
	@RequestMapping("/law/suit/searchJson.do")
	public Map<String, Object> searchJson(@RequestParam(value = "keyword", required = false) String keyword) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			return res;
		}
		try {
			res.put("success", true);
			res.put("list", lawSuitService.searchSuits(keyword));
		} catch (Exception e) {
			LOGGER.warn("사건 검색 실패: {}", e.getMessage());
			res.put("success", false);
		}
		return res;
	}
}
