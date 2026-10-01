/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/lawquest/web/LawQuestController.java
 *
 * 법령질의(법률자문 의뢰·회신) Controller — 레거시 orangeidea.lawquest 이관.
 *   목록(검색/페이징) / 상세(조회수++) / 등록 / 수정·회신 / 삭제 + 첨부(TB_ATTACH 최대 3).
 *   첨부 다운로드는 기존 공용 엔드포인트(/rlms/related/attachDownload.do?attNo=) 재사용.
 */
package narainet.rlms.lawquest.web;

import java.io.PrintWriter;
import java.net.URLEncoder;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.attach.service.AttachService;
import narainet.rlms.lawquest.service.LawQuestService;
import narainet.rlms.lawquest.service.LawQuestVO;

@Controller
public class LawQuestController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawQuestController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final String REF_TABLE = "TB_LAWQUEST";
	private static final String ATTACH_CATE = "FILE";

	@Resource(name = "lawQuestService")
	private LawQuestService lawQuestService;

	@Resource(name = "attachService")
	private AttachService attachService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	private LoginVO currentUser() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return u instanceof LoginVO ? (LoginVO) u : null;
	}

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	/** 전체권한(ROLE_ADMIN) 보유 여부 */
	private boolean isAdmin() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && auths.contains("ROLE_ADMIN");
	}

	/** 회신(답변) 권한 — ROLE_ADMIN 이거나 답변권한자 레지스트리(사번) 등록자 */
	private boolean canAnswer() {
		if (isAdmin()) return true;
		LoginVO u = currentUser();
		return u != null && lawQuestService.isAnswerAdmin(u.getId());
	}

	// ────────────────────────────────────────────────────────────────
	// 목록
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestList.do")
	public String list(@ModelAttribute("searchVO") LawQuestVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		loadListModel(searchVO, model);
		model.addAttribute("admin", isAdmin());
		model.addAttribute("front", false);
		return "rlms/lawquest/lawQuestList";
	}

	/** 목록 페이징 + 공통 모델 적재 (관리/front 공용) */
	private void loadListModel(LawQuestVO searchVO, ModelMap model) {
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = lawQuestService.getList(searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		pi.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("yearList", lawQuestService.getYears());
	}

	// ────────────────────────────────────────────────────────────────
	// 상세 (조회수 +1)
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestView.do")
	public String view(@RequestParam("no") Long no, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		LawQuestVO vo = lawQuestService.getDetail(no, true);
		if (vo == null) return "redirect:/rlms/lawquest/lawQuestList.do";
		model.addAttribute("info", vo);
		model.addAttribute("attachList", attachService.listByRef(REF_TABLE, no));
		model.addAttribute("answerAdmin", canAnswer());
		model.addAttribute("front", false);
		return "rlms/lawquest/lawQuestView";
	}

	// ────────────────────────────────────────────────────────────────
	// 등록 폼
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestRegist.do")
	public String registForm(ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		model.addAttribute("mode", "insert");
		model.addAttribute("answerAdmin", canAnswer());
		return "rlms/lawquest/lawQuestForm";
	}

	@RequestMapping("/rlms/lawquest/lawQuestInsertDo.do")
	public String insertDo(@ModelAttribute("info") LawQuestVO vo,
			@RequestParam(value = "files", required = false) MultipartFile[] files,
			ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		LoginVO user = currentUser();
		vo.setId(user == null || user.getUniqId() == null ? "" : user.getUniqId());
		vo.setName(user == null || user.getName() == null ? "" : user.getName());
		// 회신 권한자가 아니면 신규 등록 시 회신내용은 무시(빈 의뢰만 생성)
		if (!canAnswer()) vo.setRespoCon(null);

		Long no = lawQuestService.insert(vo);
		saveAttachments(no, files);
		return "redirect:/rlms/lawquest/lawQuestView.do?no=" + no;
	}

	// ────────────────────────────────────────────────────────────────
	// 수정 폼 / 수정·회신
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestUpdate.do")
	public String updateForm(@RequestParam("no") Long no, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		LawQuestVO vo = lawQuestService.getDetail(no, false);
		if (vo == null) return "redirect:/rlms/lawquest/lawQuestList.do";
		model.addAttribute("mode", "update");
		model.addAttribute("info", vo);
		model.addAttribute("attachList", attachService.listByRef(REF_TABLE, no));
		model.addAttribute("answerAdmin", canAnswer());
		return "rlms/lawquest/lawQuestForm";
	}

	@RequestMapping("/rlms/lawquest/lawQuestUpdateDo.do")
	public String updateDo(@ModelAttribute("info") LawQuestVO vo,
			@RequestParam(value = "files", required = false) MultipartFile[] files,
			ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		// 회신 권한자가 아니면 회신내용은 기존값 보존(폼 변조 방지)
		if (!canAnswer()) {
			LawQuestVO cur = lawQuestService.getDetail(vo.getNo(), false);
			vo.setRespoCon(cur == null ? null : cur.getRespoCon());
		}
		lawQuestService.update(vo);
		saveAttachments(vo.getNo(), files);
		return "redirect:/rlms/lawquest/lawQuestView.do?no=" + vo.getNo();
	}

	// ────────────────────────────────────────────────────────────────
	// 삭제 / 첨부 단건 삭제
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestDeleteDo.do")
	public String deleteDo(@RequestParam("no") Long no) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		lawQuestService.delete(no);
		return "redirect:/rlms/lawquest/lawQuestList.do";
	}

	@RequestMapping("/rlms/lawquest/lawQuestFileDeleteDo.do")
	public String fileDeleteDo(@RequestParam("no") Long no,
			@RequestParam("attNo") Long attNo) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		attachService.deleteByNo(attNo);
		return "redirect:/rlms/lawquest/lawQuestUpdate.do?no=" + no;
	}

	// ────────────────────────────────────────────────────────────────
	// 엑셀 내보내기 (HTML 테이블 → .xls, 현재 검색조건 전체행, POI 미사용)
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestExcel.do")
	public void excel(@ModelAttribute("searchVO") LawQuestVO searchVO, HttpServletResponse response) throws Exception {
		if (!authed()) return;
		List<LawQuestVO> list = lawQuestService.getListAll(searchVO);

		String fname = URLEncoder.encode("법령질의목록.xls", "UTF-8").replaceAll("\\+", "%20");
		response.setContentType("application/vnd.ms-excel; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"" + fname + "\"; filename*=UTF-8''" + fname);

		PrintWriter w = response.getWriter();
		w.print((char) 0xFEFF); // UTF-8 BOM — Excel 한글 인식
		w.print("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");
		w.print("<table border=\"1\"><tr>");
		String[] head = { "연도", "유형", "제목", "의뢰부서", "자문기관", "변호사", "금액", "의뢰일", "회신일", "예산", "공개" };
		for (String h : head) w.print("<th style=\"background:#F0F4FD\">" + h + "</th>");
		w.print("</tr>");
		if (list != null) {
			for (LawQuestVO r : list) {
				w.print("<tr>");
				w.print(xcell(r.getYear()));
				w.print(xcell(r.getType()));
				w.print(xcell(r.getSubject()));
				w.print(xcell(r.getSosok()));
				w.print(xcell(r.getGigwan()));
				w.print(xcell(r.getLawer()));
				w.print(xcell(r.getGumaek() == null ? "" : String.valueOf(r.getGumaek())));
				w.print(xcell(r.getIlja1()));
				w.print(xcell(r.getIlja2()));
				w.print(xcell(r.getBuget()));
				w.print(xcell("1".equals(r.getPublicYn()) ? "공개" : "비공개"));
				w.print("</tr>");
			}
		}
		w.print("</table></body></html>");
		w.flush();
	}

	/** 엑셀 셀 — HTML 이스케이프 + 텍스트 강제(mso-number-format) */
	private String xcell(String v) {
		String s = v == null ? "" : v.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
		return "<td style=\"mso-number-format:'\\@'\">" + s + "</td>";
	}

	// ────────────────────────────────────────────────────────────────
	// front 공개열람 (USER) — PUBLIC_YN='1' 공개건만 읽기
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestFrontList.do")
	public String frontList(@ModelAttribute("searchVO") LawQuestVO searchVO, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		searchVO.setPublicOnly(true);
		loadListModel(searchVO, model);
		model.addAttribute("admin", false);
		model.addAttribute("front", true);
		return "rlms/lawquest/lawQuestList";
	}

	@RequestMapping("/rlms/lawquest/lawQuestFrontView.do")
	public String frontView(@RequestParam("no") Long no, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		LawQuestVO vo = lawQuestService.getDetail(no, true);
		// 비공개건은 front 직접 URL 접근 차단
		if (vo == null || !"1".equals(vo.getPublicYn())) {
			return "redirect:/rlms/lawquest/lawQuestFrontList.do";
		}
		model.addAttribute("info", vo);
		model.addAttribute("attachList", attachService.listByRef(REF_TABLE, no));
		model.addAttribute("front", true);
		return "rlms/lawquest/lawQuestView";
	}

	// ────────────────────────────────────────────────────────────────
	// 답변권한자 레지스트리 (TB_LAWQUEST_ADMIN) — ROLE_ADMIN 전용
	// ────────────────────────────────────────────────────────────────
	@RequestMapping("/rlms/lawquest/lawQuestAdminList.do")
	public String adminList(ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		if (!isAdmin()) return "redirect:/rlms/lawquest/lawQuestList.do";
		model.addAttribute("adminList", lawQuestService.getAdminList());
		return "rlms/lawquest/lawQuestAdminList";
	}

	@RequestMapping("/rlms/lawquest/lawQuestAdminInsertDo.do")
	public String adminInsertDo(@RequestParam("sabun") String sabun,
			@RequestParam(value = "name", required = false) String name,
			ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		if (!isAdmin()) return "redirect:/rlms/lawquest/lawQuestList.do";
		boolean ok = lawQuestService.addAdmin(sabun, name);
		model.addAttribute("msg", ok ? "답변권한자가 추가되었습니다." : "이미 등록된 사번입니다.");
		return "redirect:/rlms/lawquest/lawQuestAdminList.do";
	}

	@RequestMapping("/rlms/lawquest/lawQuestAdminDeleteDo.do")
	public String adminDeleteDo(@RequestParam("sabun") String sabun, ModelMap model) throws Exception {
		if (!authed()) return LOGIN_REDIRECT;
		if (!isAdmin()) return "redirect:/rlms/lawquest/lawQuestList.do";
		lawQuestService.removeAdmin(sabun);
		return "redirect:/rlms/lawquest/lawQuestAdminList.do";
	}

	/** 답변자 추가용 회원 검색 (이름/ID) — ROLE_ADMIN, JSON */
	@RequestMapping("/rlms/lawquest/lawQuestUserSearch.do")
	@ResponseBody
	public List<Map<String, Object>> userSearch(@RequestParam(value = "kw", required = false) String kw) {
		if (!authed() || !isAdmin()) return java.util.Collections.emptyList();
		if (kw == null || kw.trim().isEmpty()) return java.util.Collections.emptyList();
		return lawQuestService.searchMembers(kw.trim());
	}

	/** 첨부 저장 — 최대 3파일, 빈 파일 skip. 저장 실패는 본문 저장을 막지 않음. */
	private void saveAttachments(Long no, MultipartFile[] files) {
		if (files == null) return;
		int saved = 0;
		for (MultipartFile f : files) {
			if (saved >= 3) break;
			if (f == null || f.isEmpty()) continue;
			try {
				attachService.save(REF_TABLE, no, ATTACH_CATE, f, "DEFAULT");
				saved++;
			} catch (Exception e) {
				LOGGER.warn("법령질의 첨부 저장 실패 (no={}, file={}): {}", no,
						f.getOriginalFilename(), e.getMessage());
			}
		}
	}
}
