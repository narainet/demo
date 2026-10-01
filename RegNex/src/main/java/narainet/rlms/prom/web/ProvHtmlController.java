/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/web/ProvHtmlController.java
 *
 * 조항 HTML 본문 + 본문 비교 + 전문 검색 Controller.
 */
package narainet.rlms.prom.web;

import java.io.File;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.ModelAndView;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.prom.service.BodyDiffService;
import narainet.rlms.prom.service.DiffLineVO;
import narainet.rlms.prom.service.FullTextSearchService;
import narainet.rlms.prom.service.PromService;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prom.service.ProvHtmlService;
import narainet.rlms.prom.service.ProvHtmlVO;

/**
 * 조항 본문 / 비교 / 검색 Controller
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Controller
public class ProvHtmlController {

	private static final Logger LOGGER = LoggerFactory.getLogger(ProvHtmlController.class);

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "provHtmlService")
	private ProvHtmlService provHtmlService;

	@Resource(name = "promService")
	private PromService promService;

	/** 분류별 열람제한 가드 (TB_CATE_READER) — 본문비교 단건 가드 (전문검색은 SQL 게이트) */
	@Resource(name = "promReadGuard")
	private narainet.rlms.prom.service.PromReadGuard promReadGuard;

	/** 작성권한 가드 (관리자 OR TB_CATE_OWNER 분류 작성자) — HTML 조항 삭제 방어 */
	@Resource
	private narainet.rlms.prom.service.PromEditGuard promEditGuard;

	@Resource(name = "bodyDiffService")
	private BodyDiffService bodyDiffService;

	@Resource(name = "fullTextSearchService")
	private FullTextSearchService fullTextSearchService;

	/** 관련자료 WORD 자체변환 평문(SSEARCH_TEXT) 보조 검색 */
	@Resource(name = "relWordService")
	private narainet.rlms.related.service.RelWordService relWordService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	// ────────────────────────────────────────────────────────────────
	// 조항 본문 CRUD
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/prom/selectProvHtmlList.do")
	public String selectProvHtmlList(@RequestParam("promNo") Long promNo,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		List<ProvHtmlVO> list = provHtmlService.selectProvHtmlList(promNo);
		PromVO prom = promService.selectPromDetail(promNo);
		model.addAttribute("resultList", list);
		model.addAttribute("prom", prom);
		return "rlms/prom/promDetail";
	}

	// HTML 조항 등록/수정/쓰기 진입은 모두 규정 편집 IDE(editor.do) 로 통합됨 —
	// 옛 standalone 폼(provHtmlEdit.jsp)·리다이렉트 스텁(insert/updateProvHtmlView.do)·
	// 레거시 POST 핸들러(insert/updateProvHtml.do) 폐기(2026-07-09~13). 정본 = IDE saveProvHtml.do.
	// (insert/updateProvHtml.do 는 promEditGuard·상속행 불변 가드 없이 타 분류 조문 변조 가능해 제거)

	@RequestMapping("/rlms/prom/deleteProvHtml.do")
	public String deleteProvHtml(@RequestParam("provHtmlNo") Long provHtmlNo,
			@RequestParam("promNo") Long promNo,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		// 작성권한 가드 + 상속행 불변 가드 — IDE deleteProvHtmlIde 와 동일 기준 (2026-07-09):
		// 이 회차(promNo) 소유 행만 삭제 가능. 이전 회차 상속행은 개정분기(branch) 경유가 정본.
		promEditGuard.assertCanEditProm(promNo);
		ProvHtmlVO row = provHtmlService.selectProvHtmlByNo(provHtmlNo);
		if (row == null || row.getPromNo() == null || !row.getPromNo().equals(promNo)) {
			throw new org.springframework.security.access.AccessDeniedException(
					"이 회차 소유의 조항만 삭제할 수 있습니다. (이전 회차 상속 조항은 개정분기로 처리)");
		}
		provHtmlService.deleteProvHtml(provHtmlNo);
		return "redirect:/rlms/prom/selectProvHtmlList.do?promNo=" + promNo;
	}

	// ────────────────────────────────────────────────────────────────
	// 본문 비교 (현 vs 이전 개정본)
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/prom/compareProvHtml.do")
	public String compareProvHtml(@RequestParam("promNo") Long promNo,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		PromVO current = promService.selectPromDetail(promNo);
		if (current != null && !promReadGuard.canRead(current)) {
			throw new org.springframework.security.access.AccessDeniedException(
					"이 규정은 열람 권한이 제한되어 있습니다. (지정된 부서/개인만 열람 가능)");
		}
		PromVO previous = promService.selectPreviousProm(promNo);

		List<DiffLineVO> mainDiff = null;
		List<DiffLineVO> bylawDiff = null;

		if (previous != null) {
			mainDiff = bodyDiffService.diffByVrsnRows(previous.getPromNo(), promNo);
			bylawDiff = bodyDiffService.diffBylawByLibrary(previous.getBylaw(), current.getBylaw());
		}

		model.addAttribute("current", current);
		model.addAttribute("previous", previous);
		model.addAttribute("mainDiff", mainDiff);
		model.addAttribute("bylawDiff", bylawDiff);
		return "rlms/prom/provHtmlCompare";
	}

	// ────────────────────────────────────────────────────────────────
	// 전문 검색 (Oracle Text)
	// ────────────────────────────────────────────────────────────────

	// 단일 시스템 — sysId 파라미터 폐기(SSYS_ID 는 SQL 필터에 미사용, 검색결과 동일).
	@RequestMapping("/rlms/prom/searchFullText.do")
	public String searchFullText(@RequestParam(value = "keyword", required = false) String keyword,
			@RequestParam(value = "pageIndex", defaultValue = "1") int pageIndex,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		int pageUnit = propertyService.getInt("pageUnit");

		Map<String, Object> result = null;
		if (keyword != null && !keyword.trim().isEmpty()) {
			result = fullTextSearchService.searchInProvVrsn(null, keyword, pageIndex, pageUnit);
			model.addAttribute("resultList", result.get("resultList"));
			model.addAttribute("resultCnt", result.get("resultCnt"));
			model.addAttribute("paginationInfo", result.get("paginationInfo"));
			// 보조: 관련자료 WORD 자체변환 본문(SSEARCH_TEXT) 도 검색 (최대 50, LIKE)
			model.addAttribute("wordResults", relWordService.searchByText(keyword));
		}
		model.addAttribute("keyword", keyword);
		return "rlms/prom/provHtmlSearch";
	}

	// ────────────────────────────────────────────────────────────────
	// CKEditor 본문 이미지 업로드 / 서빙
	// ────────────────────────────────────────────────────────────────

	/** 이미지 저장 폴더 — 운영 시 globals.properties 의 Globals.fileStorePath 로 교체 권장 */
	private File editorImageDir() {
		File dir;
		try {
			String base = propertyService.getString("Globals.fileStorePath");
			dir = (base != null && !base.trim().isEmpty())
					? new File(base, "prov_editor") : null;
		} catch (Exception e) { dir = null; }
		if (dir == null) dir = new File(System.getProperty("java.io.tmpdir"), "rlms_prov_editor");
		if (!dir.exists()) dir.mkdirs();
		return dir;
	}

	private static final Pattern SAFE_FN = Pattern.compile("^[A-Za-z0-9_\\-]+\\.[A-Za-z0-9]{1,8}$");

	/**
	 * CKEditor 4 이미지 업로드 (filebrowserUploadMethod='form').
	 * 응답: { "uploaded":1, "fileName":"...", "url":"...objectFileView.do?fn=..." }
	 * (권한 가드는 메서드 내 isAuthenticated() 로 — 권한 카탈로그 SQL 미적용 환경 대응)
	 */
	@RequestMapping("/rlms/prom/objectFileUpload.do")
	public void objectFileUpload(
			@RequestParam(value = "upload", required = false) MultipartFile upload,
			HttpServletResponse response) throws Exception {

		response.setContentType("application/json; charset=UTF-8");
		PrintWriter out = response.getWriter();
		try {
			if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
				out.write("{\"uploaded\":0,\"error\":{\"message\":\"로그인이 필요합니다.\"}}");
				return;
			}
			if (upload == null || upload.isEmpty()) {
				out.write("{\"uploaded\":0,\"error\":{\"message\":\"파일이 없습니다.\"}}");
				return;
			}
			String origName = upload.getOriginalFilename();
			String ext = "";
			if (origName != null && origName.lastIndexOf('.') >= 0) {
				ext = origName.substring(origName.lastIndexOf('.') + 1).toLowerCase();
			}
			// 이미지 확장자만 허용
			if (!ext.matches("png|jpg|jpeg|gif|bmp|webp|svg")) {
				out.write("{\"uploaded\":0,\"error\":{\"message\":\"이미지 파일만 업로드할 수 있습니다.\"}}");
				return;
			}
			String savedName = UUID.randomUUID().toString().replace("-", "") + "." + ext;
			File dest = new File(editorImageDir(), savedName);
			upload.transferTo(dest);

			String url = "/rlms/prom/objectFileView.do?fn=" + savedName;
			out.write("{\"uploaded\":1,\"fileName\":\"" + savedName + "\",\"url\":\"" + url + "\"}");
			LOGGER.info("editor image uploaded: {} ({} bytes)", savedName, dest.length());
		} catch (Exception e) {
			LOGGER.warn("objectFileUpload error", e);
			out.write("{\"uploaded\":0,\"error\":{\"message\":\"" + escapeJson(e.getMessage()) + "\"}}");
		} finally {
			out.flush();
		}
	}

	/** 업로드된 본문 이미지 서빙 */
	@RequestMapping("/rlms/prom/objectFileView.do")
	public void objectFileView(@RequestParam("fn") String fn,
			HttpServletResponse response) throws Exception {
		if (fn == null || !SAFE_FN.matcher(fn).matches()) {
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		File f = new File(editorImageDir(), fn);
		if (!f.exists() || !f.isFile()) {
			response.setStatus(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		String ext = fn.substring(fn.lastIndexOf('.') + 1).toLowerCase();
		String ct;
		switch (ext) {
			case "png":  ct = "image/png";  break;
			case "gif":  ct = "image/gif";  break;
			case "bmp":  ct = "image/bmp";  break;
			case "webp": ct = "image/webp"; break;
			case "svg":  ct = "image/svg+xml"; break;
			default:     ct = "image/jpeg"; break;
		}
		response.setContentType(ct);
		response.setHeader("Cache-Control", "max-age=86400");
		try (OutputStream os = response.getOutputStream()) {
			Files.copy(f.toPath(), os);
			os.flush();
		}
	}

	private String escapeJson(String s) {
		if (s == null) return "";
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", " ");
	}
}
