/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stsfdg/web/PromStsfdgController.java
 *
 * 규정 만족도 조사 (사용자 화면 JSON API) — 전문뷰어(provisionList) 하단 위젯 전용.
 *   GET  /rlms/fulltext/stsfdgListJson.do?promNo=     목록+평균+내 참여
 *   POST /rlms/fulltext/stsfdgSaveJson.do             등록/재참여(갱신 통합 — 1인 1회)
 *   POST /rlms/fulltext/stsfdgDeleteJson.do           본인 참여 취소
 *
 * - /rlms/fulltext/* 네임스페이스 → 기존 L6 폴더패턴(ROLE_USER) 자동 적용, *Json.do = SiteMesh 데코 제외
 *   (UnifiedSearchController 와 동일 관행 — 설정 변경 0건).
 * - 대상 회차 게이트 = 전문뷰어와 동일: SSTSFDG_YN='Y'(연혁 옵션) + SDISP_YN='Y' +
 *   열람제한(PromReadGuard) + 미승인 draft 비편집계 차단. 게시판 만족도의 canUseSatisfaction 재확인 관행 계승.
 * - 게시판(COMTNSTSFDG)과 달리 익명/비밀번호 없음(front 전면 로그인) — 1인 1회, 재참여=본인 행 갱신(MERGE).
 */
package narainet.rlms.stsfdg.web;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.prom.service.PromReadGuard;
import narainet.rlms.prom.service.PromService;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.stsfdg.mapper.PromStsfdgMapper;

@Controller
public class PromStsfdgController {

	/** 의견 최대 길이 — 게시판 만족도(STF_MAX_LENGTH)와 동일 */
	private static final int CN_MAX_LENGTH = 1000;

	@Resource(name = "promService")
	private PromService promService;

	@Resource(name = "promReadGuard")
	private PromReadGuard promReadGuard;

	@Resource
	private PromStsfdgMapper promStsfdgMapper;

	/** 목록 + 집계 + 내 참여 — {ok, count, avg, my, list:[{wrterNm, stsfdg, content, regDt, mine}]} */
	@RequestMapping("/rlms/fulltext/stsfdgListJson.do")
	@ResponseBody
	public Map<String, Object> listJson(@RequestParam("promNo") Long promNo) {
		Map<String, Object> res = new HashMap<>();
		String uniqId = currentUniqId();
		if (uniqId.isEmpty()) {
			res.put("ok", false); res.put("login", true); return res;
		}
		if (gateProm(promNo) == null) {
			res.put("ok", false); res.put("message", "만족도 조사를 사용할 수 없는 규정입니다."); return res;
		}
		Map<String, Object> summary = promStsfdgMapper.selectSummary(promNo);
		// 기간 파라미터는 관리자 현황 전용 — 위젯은 전체(null)
		List<Map<String, Object>> rows = promStsfdgMapper.selectList(promNo, null, null);
		List<Map<String, Object>> list = new ArrayList<>();
		for (Map<String, Object> r : rows) {
			// wrterId(ESNTL_ID)는 응답에 노출하지 않고 본인 여부(mine)만 계산해 전달
			r.put("mine", uniqId.equals(r.remove("wrterId")));
			list.add(r);
		}
		res.put("ok", true);
		res.put("count", summary.get("cnt"));
		res.put("avg", summary.get("avg"));
		res.put("my", promStsfdgMapper.selectMine(promNo, uniqId));
		res.put("list", list);
		return res;
	}

	/** 등록/재참여 통합 — 별점 1~5 필수, 의견 선택(≤1000자). 1인 1회 = 기존 참여는 갱신.
	 *  상태변경 액션이라 POST 전용(전역 csrf 비활성 환경의 GET 드라이브바이 차단 — 2026-07-20 리뷰 반영). */
	@RequestMapping(value = "/rlms/fulltext/stsfdgSaveJson.do", method = RequestMethod.POST)
	@ResponseBody
	public Map<String, Object> saveJson(
			@RequestParam("promNo") Long promNo,
			@RequestParam(value = "stsfdg", required = false) Integer stsfdg,
			@RequestParam(value = "stsfdgCn", required = false) String stsfdgCn) {
		Map<String, Object> res = new HashMap<>();
		String uniqId = currentUniqId();
		if (uniqId.isEmpty()) {
			res.put("ok", false); res.put("login", true); return res;
		}
		if (gateProm(promNo) == null) {
			res.put("ok", false); res.put("message", "만족도 조사를 사용할 수 없는 규정입니다."); return res;
		}
		if (stsfdg == null || stsfdg < 1 || stsfdg > 5) {
			res.put("ok", false); res.put("message", "별점(1~5)을 선택하세요."); return res;
		}
		String cn = stsfdgCn == null ? null : stsfdgCn.trim();
		if (cn != null && cn.isEmpty()) cn = null;
		if (cn != null && cn.length() > CN_MAX_LENGTH) {
			res.put("ok", false); res.put("message", "의견은 " + CN_MAX_LENGTH + "자 이내로 입력하세요."); return res;
		}
		promStsfdgMapper.mergeStsfdg(promNo, uniqId, stsfdg, cn);
		res.put("ok", true);
		return res;
	}

	/** 본인 참여 취소 — 행 삭제 (본인 것만 지워지는 구조: 키 = promNo + 세션 uniqId). POST 전용(위와 동일 사유). */
	@RequestMapping(value = "/rlms/fulltext/stsfdgDeleteJson.do", method = RequestMethod.POST)
	@ResponseBody
	public Map<String, Object> deleteJson(@RequestParam("promNo") Long promNo) {
		Map<String, Object> res = new HashMap<>();
		String uniqId = currentUniqId();
		if (uniqId.isEmpty()) {
			res.put("ok", false); res.put("login", true); return res;
		}
		promStsfdgMapper.deleteMine(promNo, uniqId);
		res.put("ok", true);
		return res;
	}

	/** 대상 회차 게이트 — 전문뷰어(provisionList)와 동일 조건을 API 에도 재확인(직타 방어). */
	private PromVO gateProm(Long promNo) {
		if (promNo == null) return null;
		try {
			PromVO prom = promService.selectPromDetail(promNo);
			if (prom == null) return null;
			if (!"Y".equals(prom.getStsfdgYn()) || !"Y".equals(prom.getDispYn())) return null;
			if (!promReadGuard.canRead(prom)) return null;
			if (!hasEditorRole() && promService.isWorkingDraftProm(promNo)) return null;
			return prom;
		} catch (Exception e) {
			return null;
		}
	}

	/** 편집계 역할 — FullTextController 의 미승인 draft 열람 허용 판정과 동일 */
	private static boolean hasEditorRole() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN")
				|| auths.contains("ROLE_EDITOR") || auths.contains("ROLE_APPROVER"));
	}

	private static String currentUniqId() {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) return "";
		Object user = EgovUserDetailsHelper.getAuthenticatedUser();
		if (!(user instanceof LoginVO)) return "";
		String id = ((LoginVO) user).getUniqId();
		return id == null ? "" : id;
	}
}
