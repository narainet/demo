/*
 * 물리적 저장 경로: /src/main/java/narainet/law/receipt/web/LawReceiptController.java
 *
 * 법원서류접수 Controller — LAW_MODULE_DESIGN.md §7.11.
 *   목록(등록일자 기간+제목 검색) + 인라인 등록(제목·관련자료 첨부·관련부서1·2) + 상세 + 삭제.
 *   등록부서=등록자 소속 자동(세션). 관련부서 알림 발송은 비범위(지정·표시까지).
 */
package narainet.law.receipt.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

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
import narainet.law.receipt.service.LawReceiptService;
import narainet.law.receipt.service.LawReceiptVO;

@Controller
public class LawReceiptController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawReceiptController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "lawReceiptService")
	private LawReceiptService lawReceiptService;

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

	// ── 목록 + 인라인 등록 폼 ──
	@RequestMapping("/law/receipt/list.do")
	public String list(@ModelAttribute("searchVO") LawReceiptVO searchVO, ModelMap model) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		searchVO.setSearchFrom(toDb(searchVO.getSearchFrom()));
		searchVO.setSearchTo(toDb(searchVO.getSearchTo()));
		searchVO.setSearchKeyword(LawTextUtil.unescape(searchVO.getSearchKeyword()));
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());
		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = lawReceiptService.getList(searchVO);
		pi.setTotalRecordCount((Integer) result.get("resultCnt"));

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		model.addAttribute("orgnzts", lawComMapper.selectOrgnztList());
		return "law/receipt/list";
	}

	// ── 상세 ──
	@RequestMapping("/law/receipt/view.do")
	public String view(@RequestParam("receiptId") Long receiptId, ModelMap model, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		LawReceiptVO vo = lawReceiptService.getReceipt(receiptId);
		if (vo == null) {
			ra.addFlashAttribute("message", "존재하지 않는 접수 정보입니다.");
			return "redirect:/law/receipt/list.do";
		}
		model.addAttribute("receipt", vo);
		return "law/receipt/view";
	}

	// ── 저장(등록/수정) ──
	@RequestMapping(value = "/law/receipt/save.do", method = RequestMethod.POST)
	public String save(final MultipartHttpServletRequest multiRequest,
			@ModelAttribute LawReceiptVO vo, RedirectAttributes ra) throws Exception {
		if (!authed()) {
			return LOGIN_REDIRECT;
		}
		try {
			if (vo.getReceiptTitl() == null || LawTextUtil.unescape(vo.getReceiptTitl()).trim().isEmpty()) {
				ra.addFlashAttribute("message", "제목을 입력하세요.");
				return "redirect:/law/receipt/list.do";
			}
			vo.setReceiptTitl(LawTextUtil.unescape(vo.getReceiptTitl()));
			// 등록부서 = 등록자 소속(세션) — 신규 등록 시 세팅
			LoginVO user = currentUser();
			if (vo.getReceiptId() == null && user != null) {
				vo.setOrgnztId(user.getOrgnztId());
			}
			List<MultipartFile> files = multiRequest.getFiles("file_1");
			lawReceiptService.save(vo, files, user == null ? null : user.getId());
			ra.addFlashAttribute("message", "접수를 등록했습니다.");
		} catch (Exception e) {
			LOGGER.warn("법원서류접수 저장 실패", e);
			ra.addFlashAttribute("message", "저장 중 오류가 발생했습니다.");
		}
		return "redirect:/law/receipt/list.do";
	}

	@ResponseBody
	@RequestMapping(value = "/law/receipt/deleteJson.do", method = RequestMethod.POST)
	public Map<String, Object> deleteJson(@RequestParam("receiptId") Long receiptId) {
		Map<String, Object> res = new LinkedHashMap<String, Object>();
		if (!authed()) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			lawReceiptService.delete(receiptId);
			res.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("법원서류접수 삭제 실패: {}", e.getMessage());
			res.put("success", false);
			res.put("message", "삭제 중 오류가 발생했습니다.");
		}
		return res;
	}
}
