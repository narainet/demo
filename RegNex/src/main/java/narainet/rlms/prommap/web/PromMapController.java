/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prommap/web/PromMapController.java
 *
 * 기능별분류(규정맵, TB_PROM_MAP) Controller. 레거시 PromulgationMapController 이관.
 *
 *   - 관리(시스템관리 > 기능별분류관리): 좌측 분류/규정 소스트리(기존 /rlms/prom/treeJson.do 재활용) +
 *     우측 기능별분류 트리 + ↓추가/↑삭제 + 이름변경.
 *   - 사용자(front) 뷰어: 기능별분류 트리 → 폴더 선택 시 현행 규정목록 → 전문뷰어 점프.
 *
 *   URL:
 *     GET  /rlms/prommap/manage.do                       관리 화면
 *     GET  /rlms/prommap/treeJson.do?sysId=              기능별분류 트리(jsTree)
 *     POST /rlms/prommap/importJson.do                   분류/규정 가져오기 (categoryInsert/SubInsert)
 *     POST /rlms/prommap/renameJson.do                   노드명 변경 (updateDo)
 *     POST /rlms/prommap/deleteJson.do                   노드+하위 삭제 (deleteDo)
 *     GET  /rlms/prommap/view.do                         사용자 뷰어 화면
 *     GET  /rlms/prommap/promListJson.do?pmapNo=         폴더 직속 현행 규정목록
 */
package narainet.rlms.prommap.web;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.common.service.PublicFront;
import narainet.rlms.prommap.service.PromMapService;
import narainet.rlms.prommap.service.PromMapVO;

@Controller
public class PromMapController {

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "promMapService") private PromMapService promMapService;

	/** 분류별 열람제한 가드 (TB_CATE_READER) — 트리 규정 leaf 숨김용 */
	@Resource(name = "promReadGuard")
	private narainet.rlms.prom.service.PromReadGuard promReadGuard;

	// ============================================================
	// 1) 화면
	// ============================================================

	/** 관리 화면 — 기능별분류관리 (3-pane). */
	@RequestMapping("/rlms/prommap/manage.do")
	public String manage(
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId,
			ModelMap model) {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) return LOGIN_REDIRECT;
		model.addAttribute("sysId", sysId);
		return "rlms/prommap/prommapManage";
	}

	/** 사용자 뷰어 화면 — 기능별분류 트리 → 규정목록. */
	@RequestMapping("/rlms/prommap/view.do")
	public String view(
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId,
			ModelMap model) {
		model.addAttribute("sysId", sysId);
		return "rlms/prommap/prommapView";
	}

	// ============================================================
	// 2) 기능별분류 트리 JSON (jsTree)
	// ============================================================

	@ResponseBody
	@RequestMapping("/rlms/prommap/treeJson.do")
	public List<Map<String, Object>> treeJson(
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId) {
		// 공개열람 모드면 익명도 트리 열람 — 차단 규정 leaf 숨김(blockedPromNos)은 익명=비면제로 동일 적용
		if (!PublicFront.viewAllowed()) return new ArrayList<>();
		return buildMapTree(sysId);
	}

	/** CONNECT BY 결과(부모 우선 정렬)를 ref 로 jsTree 계층 구성. */
	private List<Map<String, Object>> buildMapTree(String sysId) {
		List<PromMapVO> rows = promMapService.selectMapTree(sysId);
		Map<Long, Map<String, Object>> nodeMap = new LinkedHashMap<>();
		List<Map<String, Object>> roots = new ArrayList<>();

		// 분류별 열람제한 — 차단 규정(promNo)의 leaf 숨김 (면제역할은 빈 집합).
		// leaf 의 IPROM_NO 는 등록 당시 회차 스냅샷 — 차단집합은 법령(ILAW_ID) 단위 전 회차 전개라
		// 회차 간 분류가 갈라진 이력 데이터에서도 그대로 매칭됨.
		// 폴더는 유지(원래도 빈 폴더 존재) — 규정 제목/본문 누출 없음.
		java.util.Set<Long> blockedPromNos = promReadGuard.blockedPromNos();

		for (PromMapVO r : rows) {
			Map<String, Object> node = new LinkedHashMap<>();
			boolean leaf = "Y".equals(r.getPromYn());
			if (leaf && r.getPromNo() != null && blockedPromNos.contains(r.getPromNo())) {
				continue;   // 차단 규정 leaf — nodeMap 미등록 (아래 부모연결 루프에서 null 스킵)
			}
			node.put("id",   "pmap:" + r.getPmapNo());
			node.put("text", r.getName() != null ? r.getName() : ("(" + r.getPmapNo() + ")"));
			node.put("type", leaf ? "pleaf" : "pfolder");
			Map<String, Object> data = new LinkedHashMap<>();
			data.put("pmapNo", r.getPmapNo());
			data.put("ref",    r.getRef());
			data.put("promYn", r.getPromYn());
			data.put("promNo", r.getPromNo());
			data.put("level",  r.getLevel());
			data.put("pending", leaf && "Y".equals(r.getPendingYn()));   // 현행본 시행예정(A안 뱃지)
			node.put("data", data);
			node.put("children", new ArrayList<Map<String, Object>>());
			Map<String, Object> st = new LinkedHashMap<>();
			st.put("opened", r.getLevel() != null && r.getLevel() <= 0);
			node.put("state", st);
			nodeMap.put(r.getPmapNo(), node);
		}
		// 부모 연결 (CONNECT BY 라 부모가 항상 먼저 등장)
		for (PromMapVO r : rows) {
			Map<String, Object> node = nodeMap.get(r.getPmapNo());
			if (node == null) { continue; }   // 열람제한으로 스킵된 leaf
			Long ref = r.getRef();
			if (ref == null || ref == 0L) { roots.add(node); continue; }
			Map<String, Object> parent = nodeMap.get(ref);
			if (parent != null) {
				@SuppressWarnings("unchecked")
				List<Map<String, Object>> kids = (List<Map<String, Object>>) parent.get("children");
				kids.add(node);
			} else {
				roots.add(node);   // 부모 누락(숨김 등) → 루트로 승격(표시 보장)
			}
		}
		return roots;
	}

	// ============================================================
	// 3) CRUD (Ajax)
	// ============================================================

	/**
	 * 가져오기 — 좌측 소스 노드를 기능별분류로 복사.
	 *   sourceType='cate' → 분류 재귀 미러 / 'prom' → 규정 1건 leaf.
	 *   refPmapNo = 우측에서 선택한 폴더(없으면 0 = 루트, 단 prom 은 폴더 선택 필수).
	 */
	@ResponseBody
	@RequestMapping("/rlms/prommap/importJson.do")
	public Map<String, Object> importJson(
			@RequestParam("sourceType") String sourceType,
			@RequestParam("sourceNo")   Long sourceNo,
			@RequestParam(value = "refPmapNo", required = false, defaultValue = "0") Long refPmapNo,
			@RequestParam(value = "sysId", required = false) String sysId) {   // 단일 시스템 — sysId 미전송, SSYS_ID null 저장
		Map<String, Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			if ("cate".equals(sourceType)) {
				promMapService.importCategory(sourceNo, refPmapNo, sysId);
				res.put("message", "분류를 기능별분류에 추가했습니다.");
			} else if ("prom".equals(sourceType)) {
				promMapService.addPromLeaf(sourceNo, refPmapNo, sysId);
				res.put("message", "규정을 기능별분류에 추가했습니다.");
			} else {
				res.put("success", false); res.put("message", "지원하지 않는 소스 유형입니다: " + sourceType);
				return res;
			}
			res.put("success", true);
			res.put("refPmapNo", refPmapNo);
		} catch (Exception e) {
			res.put("success", false); res.put("message", "추가 실패: " + e.getMessage());
		}
		return res;
	}

	/** 노드명 변경 (레거시 updateDo). */
	@ResponseBody
	@RequestMapping("/rlms/prommap/renameJson.do")
	public Map<String, Object> renameJson(
			@RequestParam("pmapNo") Long pmapNo,
			@RequestParam("name")   String name) {
		Map<String, Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			promMapService.renameMap(pmapNo, name);
			res.put("success", true);
			res.put("pmapNo", pmapNo);
			res.put("name", name.trim());
			res.put("message", "분류명을 변경했습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "변경 실패: " + e.getMessage());
		}
		return res;
	}

	/** 노드 + 하위 전체 삭제 (레거시 deleteDo). */
	@ResponseBody
	@RequestMapping("/rlms/prommap/deleteJson.do")
	public Map<String, Object> deleteJson(@RequestParam("pmapNo") Long pmapNo) {
		Map<String, Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			int n = promMapService.deleteMapSubtree(pmapNo);
			res.put("success", true);
			res.put("deleted", n);
			res.put("message", "삭제했습니다. (" + n + " 노드)");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "삭제 실패: " + e.getMessage());
		}
		return res;
	}

	// ============================================================
	// 4) 사용자 뷰어 — 폴더 직속 규정목록
	// ============================================================

	@ResponseBody
	@RequestMapping("/rlms/prommap/promListJson.do")
	public Map<String, Object> promListJson(@RequestParam("pmapNo") Long pmapNo) {
		Map<String, Object> res = new LinkedHashMap<>();
		List<Map<String, Object>> items = new ArrayList<>();
		res.put("items", items);
		if (!PublicFront.viewAllowed()) {
			res.put("success", false); return res;
		}
		try {
			for (PromMapVO p : promMapService.selectPromulgationList(pmapNo)) {
				Map<String, Object> m = new LinkedHashMap<>();
				m.put("promNo",   p.getPromNo());
				m.put("title",    p.getPromTitle());
				m.put("promDate", p.getPromDate());
				m.put("catePath", p.getCateFullName());
				m.put("pending",  "Y".equals(p.getPendingYn()));   // 시행예정(A안 뱃지)
				items.add(m);
			}
			res.put("success", true);
		} catch (Exception e) {
			res.put("success", false); res.put("message", e.getMessage());
		}
		return res;
	}
}
