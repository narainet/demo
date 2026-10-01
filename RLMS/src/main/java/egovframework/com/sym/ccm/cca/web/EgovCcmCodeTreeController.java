/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/sym/ccm/cca/web/EgovCcmCodeTreeController.java
 *
 * 공통코드 통합 관리 Controller — 표준 ccm 3분할 화면(ccc/cca/cde) 대체.
 *   트리(코드그룹 > 상세코드) + 우측 편집 카드, jsTree JSON + Ajax CRUD.
 * URL 보안: 메뉴(공통코드관리, ADMIN) 파생 L6 — 미파생 시 L7 ADMIN 폴백. 데코=mgr.
 *
 * 보호코드그룹: globals.properties 의 Globals.CodeManage.ProtectedCodeIds (쉼표구분)에
 *   나열된 CODE_ID 는 트리 비노출 + 이 화면 경유 쓰기/삭제 거부. 프로젝트 고유의 근간 코드축을
 *   일반 공통코드 편집으로부터 격리하기 위한 장치(미설정 시 보호 없음).
 */
package egovframework.com.sym.ccm.cca.web;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.sym.ccm.cca.service.CmmnCodeVO;
import egovframework.com.sym.ccm.cca.service.CmmnDetailCodeVO;
import egovframework.com.sym.ccm.cca.service.EgovCcmCodeService;

/**
 * 공통코드 통합 관리 Controller
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.08   RLMS 전환팀   최초 생성 (ccm cca/cde 통합 대체)
 *   2026.07.10   RLMS 전환팀   표준 패키지(sym/ccm/cca) 이관 + 보호코드그룹 프로퍼티 외부화
 * </pre>
 */
@Controller
public class EgovCcmCodeTreeController {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovCcmCodeTreeController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "egovCcmCodeService")
	private EgovCcmCodeService codeService;

	private static final String PROTECTED_CODE_IDS_KEY = "Globals.CodeManage.ProtectedCodeIds";

	/** 보호코드그룹 — 이 화면에서 다루지 않는 CODE_ID 집합(트리 비노출 + 쓰기/삭제 거부).
	 *  값은 globals.properties 에서 프로젝트가 지정한다. 서비스층은 막지 않으므로
	 *  전용 관리 화면은 서비스를 직접 호출해 정상 편집할 수 있다.
	 *
	 *  최초 요청 시 1회만 읽는다 — EgovProperties 는 호출마다 파일을 다시 읽으므로
	 *  트리 노드 루프에서 직접 부르면 안 되고, static 초기화에서 부르면 파일 부재 시
	 *  ExceptionInInitializerError 로 컨텍스트가 죽는다. */
	private static volatile Set<String> protectedCodeIds;

	private static Set<String> protectedCodeIds() {
		Set<String> ids = protectedCodeIds;
		if (ids == null) {
			synchronized (EgovCcmCodeTreeController.class) {
				ids = protectedCodeIds;
				if (ids == null) {
					ids = loadProtectedCodeIds();
					protectedCodeIds = ids;
				}
			}
		}
		return ids;
	}

	private static Set<String> loadProtectedCodeIds() {
		Set<String> ids = new HashSet<>();
		String raw = EgovProperties.getProperty(PROTECTED_CODE_IDS_KEY);
		if (raw != null) {
			for (String id : raw.split(",")) {
				if (!id.trim().isEmpty()) {
					ids.add(id.trim());
				}
			}
		}
		LOGGER.info("보호코드그룹({}) = {}", PROTECTED_CODE_IDS_KEY, ids);
		return Collections.unmodifiableSet(ids);
	}

	private static boolean isProtected(String codeId) {
		return codeId != null && protectedCodeIds().contains(codeId.trim());
	}

	private static void assertNotProtected(String codeId) {
		if (isProtected(codeId)) {
			throw new IllegalStateException(
					"보호된 코드그룹입니다 — 이 화면에서는 편집할 수 없습니다: " + codeId.trim());
		}
	}

	// ────────────────────────────────────────────────────────────────
	// 화면 / 트리 JSON
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/sym/ccm/cca/selectCodeTree.do")
	public String selectCodeTree(ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		return "egovframework/com/sym/ccm/cca/EgovCcmCodeTree";
	}

	/**
	 * jsTree 호환 JSON — 코드그룹(부모 '#') + 상세코드(부모 'code_<ID>') 평면 노드.
	 * 미사용(USE_AT='N')은 라벨 마커 + a_attr 클래스로 흐리게 표시.
	 */
	@RequestMapping("/sym/ccm/cca/codeTreeJson.do")
	public ModelAndView codeTreeJson() throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			mav.addObject("resultList", new ArrayList<Map<String, Object>>());
			mav.addObject("resultMsg", "UNAUTHORIZED");
			return mav;
		}
		List<Map<String, Object>> nodes = new ArrayList<>();
		for (CmmnCodeVO c : codeService.selectCodeList()) {
			if (isProtected(c.getCodeId())) continue;   // 보호코드그룹 = 전용 화면 소관, 여기 비노출
			Map<String, Object> n = new LinkedHashMap<>();
			n.put("id", "code_" + c.getCodeId());
			n.put("parent", "#");
			n.put("text", label(c.getCodeIdNm(), c.getCodeId(), c.getUseAt()) + " [" + c.getDetailCnt() + "]");
			if ("N".equals(c.getUseAt())) {
				n.put("a_attr", attrOff());
			}
			Map<String, Object> data = new LinkedHashMap<>();
			data.put("nodeType", "code");
			data.put("codeId",   c.getCodeId());
			data.put("codeIdNm", c.getCodeIdNm());
			data.put("codeIdDc", c.getCodeIdDc());
			data.put("useAt",    c.getUseAt());
			data.put("detailCnt", c.getDetailCnt());
			n.put("data", data);
			nodes.add(n);
		}
		for (CmmnDetailCodeVO d : codeService.selectDetailListAll()) {
			if (isProtected(d.getCodeId())) continue;   // 보호코드그룹 상세도 비노출
			Map<String, Object> n = new LinkedHashMap<>();
			n.put("id", "det_" + d.getCodeId() + "__" + d.getCode());
			n.put("parent", "code_" + d.getCodeId());
			n.put("text", label(d.getCodeNm(), d.getCode(), d.getUseAt()));
			n.put("icon", "jstree-file");
			if ("N".equals(d.getUseAt())) {
				n.put("a_attr", attrOff());
			}
			Map<String, Object> data = new LinkedHashMap<>();
			data.put("nodeType", "detail");
			data.put("codeId", d.getCodeId());
			data.put("code",   d.getCode());
			data.put("codeNm", d.getCodeNm());
			data.put("codeDc", d.getCodeDc());
			data.put("useAt",  d.getUseAt());
			n.put("data", data);
			nodes.add(n);
		}
		mav.addObject("resultList", nodes);
		return mav;
	}

	private static String label(String nm, String id, String useAt) {
		String base = (nm == null || nm.trim().isEmpty() ? "(이름없음)" : nm.trim()) + " (" + id + ")";
		return "N".equals(useAt) ? base + " — 미사용" : base;
	}

	private static Map<String, Object> attrOff() {
		Map<String, Object> a = new LinkedHashMap<>();
		a.put("class", "code-node-off");
		return a;
	}

	// ────────────────────────────────────────────────────────────────
	// 코드그룹 CRUD (Ajax)
	// ────────────────────────────────────────────────────────────────

	@ResponseBody
	@RequestMapping("/sym/ccm/cca/insertCodeAjax.do")
	public Map<String, Object> insertCodeAjax(@ModelAttribute("codeVO") CmmnCodeVO vo) {
		return run(() -> { assertNotProtected(vo.getCodeId()); stampUser(vo); codeService.insertCode(vo); return "코드그룹이 등록되었습니다."; });
	}

	@ResponseBody
	@RequestMapping("/sym/ccm/cca/updateCodeAjax.do")
	public Map<String, Object> updateCodeAjax(@ModelAttribute("codeVO") CmmnCodeVO vo) {
		return run(() -> { assertNotProtected(vo.getCodeId()); stampUser(vo); codeService.updateCode(vo); return "코드그룹이 수정되었습니다."; });
	}

	@ResponseBody
	@RequestMapping("/sym/ccm/cca/deleteCodeAjax.do")
	public Map<String, Object> deleteCodeAjax(@RequestParam("codeId") String codeId) {
		return run(() -> { assertNotProtected(codeId); codeService.deleteCode(codeId); return "코드그룹과 하위 상세코드가 삭제되었습니다."; });
	}

	// ────────────────────────────────────────────────────────────────
	// 상세코드 CRUD (Ajax)
	// ────────────────────────────────────────────────────────────────

	@ResponseBody
	@RequestMapping("/sym/ccm/cca/insertDetailAjax.do")
	public Map<String, Object> insertDetailAjax(@ModelAttribute("codeDetailVO") CmmnDetailCodeVO vo) {
		return run(() -> { assertNotProtected(vo.getCodeId()); stampUser(vo); codeService.insertDetail(vo); return "상세코드가 등록되었습니다."; });
	}

	@ResponseBody
	@RequestMapping("/sym/ccm/cca/updateDetailAjax.do")
	public Map<String, Object> updateDetailAjax(@ModelAttribute("codeDetailVO") CmmnDetailCodeVO vo) {
		return run(() -> { assertNotProtected(vo.getCodeId()); stampUser(vo); codeService.updateDetail(vo); return "상세코드가 수정되었습니다."; });
	}

	@ResponseBody
	@RequestMapping("/sym/ccm/cca/deleteDetailAjax.do")
	public Map<String, Object> deleteDetailAjax(@RequestParam("codeId") String codeId,
			@RequestParam("code") String code) {
		return run(() -> { assertNotProtected(codeId); codeService.deleteDetail(codeId, code); return "상세코드가 삭제되었습니다."; });
	}

	// ── 공통 응답 골격 (CateController Ajax 관례: {success, resultMsg}) ──

	private interface Action { String apply() throws Exception; }

	private Map<String, Object> run(Action action) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		try {
			result.put("success", true);
			result.put("resultMsg", action.apply());
		} catch (Exception e) {
			LOGGER.warn("Common code manage action failed.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	private void stampUser(CmmnCodeVO vo) {
		vo.setUserId(loginId());
	}

	private void stampUser(CmmnDetailCodeVO vo) {
		vo.setUserId(loginId());
	}

	private String loginId() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return (u instanceof LoginVO) ? ((LoginVO) u).getId() : null;
	}
}
