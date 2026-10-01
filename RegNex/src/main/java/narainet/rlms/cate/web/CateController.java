/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/web/CateController.java
 *
 * 분류 트리 Controller.
 * jsTree JSON 응답은 /rlms/cate/selectCateTreeJson.do 로 노출 — prom 등록 화면에서 호출.
 */
package narainet.rlms.cate.web;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.sym.ccm.cca.service.CmmnDetailCodeVO;
import egovframework.com.sym.ccm.cca.service.EgovCcmCodeService;
import narainet.rlms.cate.service.CateService;
import narainet.rlms.cate.service.CateVO;

/**
 * 분류 트리 Controller
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Controller
public class CateController {

	private static final Logger LOGGER = LoggerFactory.getLogger(CateController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";
	private static final String DEFAULT_SYS_ID = "DEFAULT";

	@Resource(name = "cateService")
	private CateService cateService;

	/** 분류별 열람제한 가드 — 검색 필터트리(selectCateTreeJson)에서 차단 분류명/건수 은닉 */
	@Resource(name = "promReadGuard")
	private narainet.rlms.prom.service.PromReadGuard promReadGuard;

	@Resource(name = "egovMessageSource")
	private EgovMessageSource egovMessageSource;

	/** 구분(ccm 'SGUBUN') CRUD 용 — 구분 관리는 공통코드 화면이 아니라 이 화면 소관(2026-07-09) */
	@Resource(name = "egovCcmCodeService")
	private EgovCcmCodeService codeService;

	/** 구분 채번(FT_GUBUN_N)·참조 카운트 조회용 */
	@Resource
	private narainet.rlms.cate.mapper.CateMapper cateMapper;

	/** 편집계 역할(EDITOR/APPROVER/ADMIN) — 분류관리 트리의 숨김 구분 포함(manage=Y) 허용 판정 */
	private static boolean hasEditorRole() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN")
				|| auths.contains("ROLE_EDITOR") || auths.contains("ROLE_APPROVER"));
	}

	// ────────────────────────────────────────────────────────────────
	// 트리 화면 / 등록·수정·삭제
	// ────────────────────────────────────────────────────────────────

	@RequestMapping("/rlms/cate/selectCateTree.do")
	public String selectCateTree(@RequestParam(value = "sysId", required = false) String sysId,
			ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		String targetSysId = normalizeSysId(sysId);
		Map<String, Object> result = cateService.selectCateTree(targetSysId);
		model.addAttribute("sysId", targetSysId);
		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		return "rlms/cate/cateTree";
	}

	/**
	 * jsTree 호환 JSON — front 검색 필터트리(5종+통합검색)·prom 등록 화면·분류관리가 공용 호출.
	 * 숨김 구분(ccm USE_AT='N')은 기본 제외 — 분류관리 화면만 manage=Y(+편집계 역할)로 포함(복구 입구).
	 */
	@RequestMapping("/rlms/cate/selectCateTreeJson.do")
	public ModelAndView selectCateTreeJson(@RequestParam(value = "sysId", required = false) String sysId,
			@RequestParam(value = "manage", required = false) String manage,
			ModelMap model) throws Exception {
		ModelAndView mav = new ModelAndView("jsonView");
		// 공개열람 모드면 익명도 검색 필터트리 열람 — 차단 분류 은닉(blockedCateNos)은 익명=비면제로 동일 적용
		if (!narainet.rlms.common.service.PublicFront.viewAllowed()) {
			mav.addObject("resultList", Collections.emptyList());
			mav.addObject("resultMsg", "UNAUTHORIZED");
			return mav;
		}
		boolean includeHidden = "Y".equals(manage) && hasEditorRole();   // 파라미터 스푸핑 방어
		List<Map<String, Object>> tree = cateService.selectCateTreeForJsTree(sysId, includeHidden);
		// 분류별 열람제한 — 차단 분류 노드(이름+건수) 은닉. 면제역할은 빈 집합이라 무영향.
		java.util.Set<Long> blocked = promReadGuard.blockedCateNos();
		if (!blocked.isEmpty()) {
			tree = filterBlockedCateNodes(tree, blocked);
		}
		// jsTree 는 배열 그대로 응답을 받음 — 기본 jsonView 가 root key 를 붙이지만,
		// 호출측 처리: data.resultList 로 접근.
		mav.addObject("resultList", tree);
		return mav;
	}

	/**
	 * 차단 분류 노드 제거 + 부모가 제거된 생존 노드는 가장 가까운 생존 조상(없으면 gubun 루트)에 재부착.
	 * (비상속 차단 분류의 공개 하위분류가 jsTree 에서 부모 미존재로 통째로 사라지는 것 방지)
	 */
	private List<Map<String, Object>> filterBlockedCateNodes(
			List<Map<String, Object>> tree, java.util.Set<Long> blocked) {
		Map<String, Map<String, Object>> byId = new java.util.HashMap<>();
		for (Map<String, Object> n : tree) {
			byId.put(String.valueOf(n.get("id")), n);
		}
		List<Map<String, Object>> out = new java.util.ArrayList<>();
		for (Map<String, Object> n : tree) {
			Long cateNo = nodeCateNo(n);
			if (cateNo != null && blocked.contains(cateNo)) {
				continue;
			}
			String parent = String.valueOf(n.get("parent"));
			while (parent.startsWith("cate_")) {
				Map<String, Object> p = byId.get(parent);
				if (p == null) {
					break;
				}
				Long pCateNo = nodeCateNo(p);
				if (pCateNo == null || !blocked.contains(pCateNo)) {
					break;
				}
				parent = String.valueOf(p.get("parent"));
			}
			if (!parent.equals(String.valueOf(n.get("parent")))) {
				n.put("parent", parent);
			}
			out.add(n);
		}
		return out;
	}

	private static Long nodeCateNo(Map<String, Object> node) {
		Object data = node.get("data");
		if (data instanceof Map) {
			Object c = ((Map<?, ?>) data).get("cateNo");
			if (c instanceof Number) {
				return ((Number) c).longValue();
			}
		}
		return null;
	}

	@ResponseBody
	@RequestMapping("/rlms/cate/insertCateAjax.do")
	public Map<String, Object> insertCateAjax(@ModelAttribute("cateVO") CateVO cateVO) throws Exception {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		try {
			cateService.insertCate(cateVO);
			result.put("success", true);
			result.put("cateNo", cateVO.getCateNo());
			result.put("resultMsg", egovMessageSource.getMessage("cate.inserted"));
		} catch (Exception e) {
			LOGGER.warn("Failed to insert category.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	@ResponseBody
	@RequestMapping("/rlms/cate/updateCateAjax.do")
	public Map<String, Object> updateCateAjax(@ModelAttribute("cateVO") CateVO cateVO) throws Exception {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		try {
			cateService.updateCate(cateVO);
			result.put("success", true);
			result.put("cateNo", cateVO.getCateNo());
			result.put("resultMsg", egovMessageSource.getMessage("cate.updated"));
		} catch (Exception e) {
			LOGGER.warn("Failed to update category.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	// ────────────────────────────────────────────────────────────────
	// 구분(최상위) 관리 — 추가/수정(이름·순서)/삭제.
	//   구분(ccm 'SGUBUN')은 일반 공통코드가 아니라 트리의 근간 축(코드값 FT_GUBUN_N 이
	//   규정 데이터 SGUBUN_ID 에 저장)이라 공통코드 화면에서 분리, 이 화면 소관(2026-07-09 사용자 확정).
	//   · 추가 = FT_GUBUN_N 자동 채번(ccm+TB_CATE+TB_PROM 잔재 통합 MAX+1 — 번호 재사용 사고 방지)
	//   · 삭제 = 참조 검사(미삭제 분류/규정이 쓰고 있으면 차단 — 실사용 구분은 자연 보호)
	//   · 순서 = ccm 컨벤션(CODE_DC 'NN_이름' prefix 가 정렬키)
	// ────────────────────────────────────────────────────────────────

	@ResponseBody
	@RequestMapping("/rlms/cate/insertGubunAjax.do")
	public Map<String, Object> insertGubunAjax(@RequestParam("cateNm") String gubunNm,
			@RequestParam(value = "seq", required = false) String seq,
			@RequestParam(value = "dispYn", required = false) String dispYn) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		try {
			if (gubunNm == null || gubunNm.trim().isEmpty()) {
				throw new IllegalArgumentException("구분명을 입력하세요.");
			}
			String nm = gubunNm.trim();
			Long maxNo = cateMapper.selectMaxGubunCodeNo();
			String code = "FT_GUBUN_" + ((maxNo == null ? 0L : maxNo) + 1);
			int order = resolveGubunOrder(seq);
			CmmnDetailCodeVO vo = new CmmnDetailCodeVO();
			vo.setCodeId("SGUBUN");
			vo.setCode(code);
			vo.setCodeNm(nm);
			vo.setCodeDc((order < 10 ? "0" + order : String.valueOf(order)) + "_" + nm);
			// 표시 여부 — 숨김(N)이면 분류관리 화면 외 전 트리/검색/목록에서 비노출 (역할 면제 없음)
			vo.setUseAt("N".equals(dispYn) ? "N" : "Y");
			Object u = EgovUserDetailsHelper.getAuthenticatedUser();
			vo.setUserId((u instanceof LoginVO) ? ((LoginVO) u).getId() : null);
			codeService.insertDetail(vo);
			result.put("success", true);
			result.put("gubunId", code);
			// ※ front 검색 구분 체크박스는 gubunIds 동적화(2026-07-10) — 신규 구분도
			//   트리/분류/편집기/검색 체크박스에 즉시 반영(USE_AT='Y' 전체 노출).
			result.put("resultMsg", "구분이 추가되었습니다: " + nm + " (" + code + ")");
		} catch (Exception e) {
			LOGGER.warn("Failed to insert gubun.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 순서 파라미터 해석 — 미입력이면 기존 ccm 순번(CODE_DC 'NN_' prefix) 최대+1 */
	private int resolveGubunOrder(String seq) throws Exception {
		if (seq != null && !seq.trim().isEmpty()) {
			if (!seq.trim().matches("\\d{1,3}")) {
				throw new IllegalArgumentException("순서는 1~3자리 숫자만 입력하세요.");
			}
			return Integer.parseInt(seq.trim());
		}
		int max = 0;
		for (CmmnDetailCodeVO d : codeService.selectDetailListAll()) {
			if (!"SGUBUN".equals(d.getCodeId()) || d.getCodeDc() == null) continue;
			java.util.regex.Matcher m = java.util.regex.Pattern.compile("^(\\d{1,3})_").matcher(d.getCodeDc());
			if (m.find()) max = Math.max(max, Integer.parseInt(m.group(1)));
		}
		return max + 1;
	}

	@ResponseBody
	@RequestMapping("/rlms/cate/deleteGubunAjax.do")
	public Map<String, Object> deleteGubunAjax(@RequestParam("gubunId") String gubunId) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		try {
			CmmnDetailCodeVO cur = codeService.selectDetail("SGUBUN", gubunId);
			if (cur == null) {
				throw new IllegalArgumentException("구분 코드를 찾을 수 없습니다: " + gubunId);
			}
			// 참조 검사 — 미삭제 분류/규정이 이 구분을 쓰고 있으면 차단 (분류 삭제와 동일 규칙)
			Map<String, Object> ref = cateMapper.selectGubunRefCnts(gubunId);
			long cateCnt = ((Number) ref.get("CATE_CNT")).longValue();
			long promCnt = ((Number) ref.get("PROM_CNT")).longValue();
			if (cateCnt > 0 || promCnt > 0) {
				throw new IllegalStateException("이 구분을 사용 중인 분류 " + cateCnt + "건 / 규정 " + promCnt
						+ "건이 있어 삭제할 수 없습니다. 하위 분류·규정을 먼저 정리하세요.");
			}
			codeService.deleteDetail("SGUBUN", gubunId);
			result.put("success", true);
			result.put("resultMsg", "구분이 삭제되었습니다: " + cur.getCodeNm());
		} catch (Exception e) {
			LOGGER.warn("Failed to delete gubun.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	@ResponseBody
	@RequestMapping("/rlms/cate/updateGubunAjax.do")
	public Map<String, Object> updateGubunAjax(@RequestParam("gubunId") String gubunId,
			@RequestParam("cateNm") String gubunNm,
			@RequestParam(value = "seq", required = false) String seq,
			@RequestParam(value = "dispYn", required = false) String dispYn) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		try {
			if (gubunNm == null || gubunNm.trim().isEmpty()) {
				throw new IllegalArgumentException("구분명을 입력하세요.");
			}
			CmmnDetailCodeVO cur = codeService.selectDetail("SGUBUN", gubunId);
			if (cur == null) {
				throw new IllegalArgumentException("구분 코드를 찾을 수 없습니다: " + gubunId);
			}
			String nm = gubunNm.trim();
			String dc;
			if (seq != null && !seq.trim().isEmpty()) {
				if (!seq.trim().matches("\\d{1,3}")) {
					throw new IllegalArgumentException("순서는 1~3자리 숫자만 입력하세요.");
				}
				int n = Integer.parseInt(seq.trim());
				dc = (n < 10 ? "0" + n : String.valueOf(n)) + "_" + nm;
			} else {
				// 순서 미입력 — 기존 순번 prefix 유지, 이름 부분만 교체
				java.util.regex.Matcher m = java.util.regex.Pattern.compile("^(\\d{1,3})_")
						.matcher(cur.getCodeDc() == null ? "" : cur.getCodeDc());
				dc = m.find() ? (m.group(1) + "_" + nm) : nm;
			}
			cur.setCodeNm(nm);
			cur.setCodeDc(dc);
			// 표시 여부 — 숨김(N)이면 분류관리 화면 외 전 트리/검색/목록에서 비노출 (역할 면제 없음).
			// 파라미터 없으면 기존 값 유지.
			if (dispYn != null) {
				cur.setUseAt("N".equals(dispYn) ? "N" : "Y");
			}
			Object u = EgovUserDetailsHelper.getAuthenticatedUser();
			cur.setUserId((u instanceof LoginVO) ? ((LoginVO) u).getId() : null);
			codeService.updateDetail(cur);
			result.put("success", true);
			result.put("resultMsg", "N".equals(cur.getUseAt())
					? "구분이 수정되었습니다. (숨김 상태 — 분류관리 화면 외 전 화면에서 비노출)"
					: "구분이 수정되었습니다. (홈/검색/편집기 전 화면 공통 반영)");
		} catch (Exception e) {
			LOGGER.warn("Failed to update gubun.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	@ResponseBody
	@RequestMapping("/rlms/cate/deleteCateAjax.do")
	public Map<String, Object> deleteCateAjax(@RequestParam("cateNo") Long cateNo) throws Exception {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		try {
			cateService.deleteCate(cateNo);
			result.put("success", true);
			result.put("resultMsg", egovMessageSource.getMessage("cate.deleted"));
		} catch (Exception e) {
			LOGGER.warn("Failed to delete category.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	private String normalizeSysId(String sysId) {
		return sysId == null || sysId.trim().length() == 0 ? "" : sysId.trim();
	}
}
