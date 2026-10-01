/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/web/PromEditorController.java
 *
 * 규정 IDE (3-pane 편집기) Controller.
 *
 *   - 레거시 의 /lims/manage/layout.html?pAct=fulltext 화면 RLMS 이관
 *   - 좌측 트리 (규정분류 / 연혁목차) + 중앙 본문 편집 + 우측 관련자료
 *   - 1단계: 화면 레이아웃 + jsTree mock 데이터               (완료)
 *   - 2단계: Ajax 트리 데이터 API + jsTree lazy load          (완료)
 *   - 3단계: 조항 단위 저장 + CKEditor                        (완료)
 *   - 3.5단계: 조항 트리 계층(회차 > 장 > (절) > 조) 이식      (현재 — 레거시 ProvisionVersion 패턴)
 *   - 4단계: 관련자료 8 액션 모달
 *
 * 트리 계층 (레거시 1:1) :  법령(law) → 회차(prom) → {📁조문(provgrp), 📁별표/별지서식(docgrp)}
 *                          조문(provgrp) → 장(grp,LV2) → (절 grp,LV3) → 조(prov)
 *                          (HTML/FILE_VIEWER 법령은 조문 → TB_PROV_HTML 조 평면)
 *
 * 트리 데이터 API:
 *   GET /rlms/prom/historyJson.do?lawId=...               → 법령 루트 + 회차들 (회차는 children lazy)
 *   GET /rlms/prom/treeJson.do?id=#                       → 분류 트리 + 분류별 법령 (한 방)
 *   GET /rlms/prom/treeJson.do?id=prom:123                → 회차의 콘텐츠 타입 [조문, 별표/별지서식]
 *   GET /rlms/prom/treeJson.do?id=provgrp:123             → "조문" 그룹 → 장 / 조 평면 / HTML 평면
 *   GET /rlms/prom/treeJson.do?id=grp:<lawId>:<lawNo>:<60자코드>  → 장/절 노드의 직속 자식 (절 + 조, 누적)
 *   GET /rlms/prom/treeJson.do?id=docgrp:123              → "별표/별지서식" → TB_DOCU 누적 (레거시 DocumentService.getSelectSql)
 *
 * ※ 조항은 "누적(상속)" 모델: 각 회차는 변경/신규 조항만 저장 → 한 회차의 전체 본문 = 같은 lawId
 *    회차들(ILAW_NO ≤ 이 회차) 중 SFULL_ITEM 별 최신 행. (레거시 ProvisionVersionService.getSelectSql)
 *
 * 조항/별표 본문 Ajax:
 *   GET /rlms/prom/provFragmentJson.do?promNo=&item=         → TB_PROV_HTML 조 (provFlag=HTML 법령)
 *   GET /rlms/prom/provVrsnFragmentJson.do?promNo=&fullItem= → TB_PROV_VRSN 조 (계층 트리의 조 노드)
 *   GET /rlms/prom/docuFragmentJson.do?docuNo=               → TB_DOCU 별표/별지서식 단건
 *
 * 조항 계층 근거 (레거시 AjaxFullTextController.getManageContentsTypeList / getManageProvisionVersionList / getCommonSubProvisionList):
 *   - TB_PROM.SPROV_FG = HTML / FILE_VIEWER → TB_PROV_HTML 평면 목록
 *   - 그 외(VERSION 기본)                    → TB_PROV_VRSN: 장(F_JANG) → (절 F_JEOL) → 조(BASE_TEXT)
 *   - SFULL_ITEM = STYLE_NORMAL 기준 5자 × 12단계 = 60자 고정폭 (사전순 = 트리순).
 *     [1..5]편 [6..10]장 [11..15]절 [16..20]관 [21..25]목 [26..30]조 [31..60]항·호 …
 */
package narainet.rlms.prom.web;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

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
import narainet.rlms.attach.service.AttachVO;
import narainet.rlms.cate.mapper.CateMapper;
import narainet.rlms.cate.service.CateVO;
import narainet.rlms.common.mapper.CmmnCodeMapper;
import narainet.rlms.docu.mapper.DocuMapper;
import narainet.rlms.docu.service.DocuVO;
import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.prom.mapper.ProvTextHstMapper;
import narainet.rlms.prom.mapper.ProvVrsnMapper;
import narainet.rlms.prom.service.PromService;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prom.service.PromEditGuard;
import narainet.rlms.prom.service.PromReadGuard;
import narainet.rlms.prom.service.ProvHtmlService;
import narainet.rlms.prom.service.ProvHtmlVO;
import narainet.rlms.prom.service.ProvTextHstVO;
import narainet.rlms.prom.service.ProvVrsnService;
import narainet.rlms.prom.service.ProvVrsnVO;
import narainet.rlms.prom.service.DocImportService;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import narainet.rlms.related.mapper.RelVrsnMapper;
import narainet.rlms.related.service.RelVrsnVO;
import narainet.rlms.relexcl.service.RelExclLnkService;
import narainet.rlms.relexcl.service.RelExclLnkVO;

@Controller
public class PromEditorController {

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource private CateMapper        cateMapper;
	@Resource private PromMapper        promMapper;
	@Resource private ProvTextHstMapper provTextHstMapper;
	@Resource(name = "egovProvTextHstIdGnrService") private EgovIdGnrService provTextHstIdGnrService;
	@Resource(name = "egovDocuIdGnrService")        private EgovIdGnrService docuIdGnrService;
	@Resource private ProvVrsnMapper  provVrsnMapper;
	@Resource private DocuMapper      docuMapper;
	@Resource private RelVrsnMapper   relVrsnMapper;
	@Resource private narainet.rlms.related.mapper.RelFileMapper relFileMapper;
	@Resource(name = "relLnkService") private narainet.rlms.related.service.RelLnkService relLnkService;
	@Resource private CmmnCodeMapper  cmmnCodeMapper;
	@Resource private ProvHtmlService provHtmlService;
	@Resource private ProvVrsnService provVrsnService;
	@Resource private PromService     promService;
	@Resource private PromEditGuard   promEditGuard;
	@Resource private PromReadGuard   promReadGuard;
	@Resource private narainet.rlms.promwork.service.PromWorkService promWorkService;
	@Resource private AttachService   attachService;
	@Resource(name = "relExclLnkService") private RelExclLnkService relExclLnkService;
	@Resource(name = "docImportService") private DocImportService docImportService;

	// ============================================================
	// 1) 메인 화면
	// ============================================================

	// 접근제어 — AUTH_PGM_* 카탈로그(@PreAuthorize)는 접근제어 재설계에서 폐기(메뉴=단일원천).
	// 실가드 3중: ①메뉴 파생 URL 보안(비편집계 403, 2026-07-16 라이브 실증) ②isAuthenticated ③promEditGuard.
	@RequestMapping("/rlms/prom/editor.do")
	public String editor(
			@RequestParam(value = "sysId",    required = false, defaultValue = "") String sysId,
			@RequestParam(value = "promNo",   required = false) Long promNo,
			@RequestParam(value = "fullItem", required = false) String fullItem,
			ModelMap model) {

		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}

		// 작성권한 가드 — 기존 규정 편집 진입은 관리자 또는 분류 작성자만 (신규는 savePromMeta 에서 분류 기준 가드)
		if (promNo != null) {
			promEditGuard.assertCanEditProm(promNo);
		}

		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		model.addAttribute("loginUser", user);
		model.addAttribute("sysId",     sysId);
		model.addAttribute("promNo",    promNo);
		model.addAttribute("fullItem",  fullItem);

		return "rlms/prom/promEditor";
	}

	// ============================================================
	// 1-b) 조항 본문 Ajax 조회 / 저장 (IDE 중앙 편집 폼용)
	// ============================================================

	/** 조항 본문 조회 — (promNo, item) 으로 TB_PROV_HTML 단건. 없으면 found=false */
	@ResponseBody
	@RequestMapping("/rlms/prom/provFragmentJson.do")
	public Map<String,Object> provFragmentJson(
			@RequestParam("promNo") Long promNo,
			@RequestParam("item")   String item) {

		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("found", false);
			res.put("error", "unauthenticated");
			return res;
		}
		try {
			ProvHtmlVO vo = provHtmlService.selectProvHtmlByPromItem(promNo, item);
			if (vo != null) {
				res.put("found",       true);
				res.put("provHtmlNo",  vo.getProvHtmlNo());
				res.put("promNo",      vo.getPromNo());
				res.put("item",        vo.getItem());
				res.put("title",       vo.getTitle());
				res.put("contents",    vo.getContents());
				res.put("reason",      vo.getReason());
				res.put("gaejungType", vo.getGaejungType());
				res.put("dispYn",      vo.getDispYn());
			} else {
				res.put("found",  false);
				res.put("promNo", promNo);
				res.put("item",   item);
			}
		} catch (Exception e) {
			res.put("found", false);
			res.put("error", e.getMessage());
		}
		return res;
	}

	/** 조항 본문 저장 — provHtmlNo 있으면 update, 없으면 insert. 단위 분해는 Service 가 처리 */
	@ResponseBody
	@RequestMapping("/rlms/prom/saveProvHtml.do")
	public Map<String,Object> saveProvHtml(@ModelAttribute("provHtmlVO") ProvHtmlVO vo,
			@RequestParam(value = "viewPromNo", required = false) Long viewPromNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			promEditGuard.assertCanEditProm(vo.getPromNo());   // 작성권한 가드(관리자/분류작성자)
			boolean isNew = vo.getProvHtmlNo() == null;
			// 상속 행 in-place 수정 차단 — 다른 회차 컨텍스트에서 연 행은 개정분기(branchProvHtml)로
			if (!isNew && viewPromNo != null) {
				ProvHtmlVO cur = provHtmlService.selectProvHtmlByNo(vo.getProvHtmlNo());
				if (cur != null && cur.getPromNo() != null && !viewPromNo.equals(cur.getPromNo())) {
					res.put("success", false);
					res.put("message", "이전 회차에 등록된 조항입니다. \"이 회차로 개정 등록\"(개정분기)을 사용하세요.");
					return res;
				}
			}
			if (!isNew) {
				provHtmlService.updateProvHtml(vo);
			} else {
				provHtmlService.insertProvHtml(vo);
			}
			promWorkService.logAction(vo.getPromNo(), vo.getSysId(), "TB_PROV_HTML", String.valueOf(vo.getPromNo()),
					isNew ? narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_INSERT
					      : narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_UPDATE,
					"별표/HTML조문편집", "HTML 조문 " + (isNew ? "등록" : "수정"), currentUserId(), currentUserNm());
			res.put("success",    true);
			res.put("provHtmlNo", vo.getProvHtmlNo());
			res.put("item",       vo.getItem());
			res.put("message",    "저장되었습니다.");
		} catch (Exception e) {
			res.put("success", false);
			res.put("message", "저장 실패: " + e.getMessage());
		}
		return res;
	}

	// ============================================================
	// 1-b') TB_PROV_VRSN 조항 단위 Ajax 조회 / 저장 (계층 트리의 조 노드용)
	//   - 레거시 "HTML형식조문수정" 의 단건 조 편집 흐름.
	//   - 트리의 조 노드는 (promNo, fullItem=60자 코드) 로 식별.
	// ============================================================

	/**
	 * 조항(TB_PROV_VRSN) 단위 본문 조회 — 누적 모델.
	 * 같은 lawId 의 lawNo ≤ 현재 회차 중 SFULL_ITEM 별 최신 row 를 조립.
	 * lawId/lawNo 누락 시 promNo 로 보조 조회.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/provVrsnFragmentJson.do")
	public Map<String,Object> provVrsnFragmentJson(
			@RequestParam("promNo")                       Long promNo,
			@RequestParam("fullItem")                     String fullItem,
			@RequestParam(value = "lawId", required = false) Long lawId,
			@RequestParam(value = "lawNo", required = false) Long lawNo) {

		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("found", false); res.put("error", "unauthenticated"); return res;
		}
		try {
			// lawId/lawNo 누락 시 promNo 로 보강 (구버전 클라이언트 호환)
			if (lawId == null || lawNo == null) {
				PromVO p = promService.selectPromDetail(promNo);
				if (p != null) {
					if (lawId == null) lawId = p.getLawId();
					if (lawNo == null) lawNo = p.getLawNo();
				}
			}
			if (lawId == null || lawNo == null) {
				res.put("found", false); res.put("error", "lawId/lawNo 추출 실패"); return res;
			}
			// 누적: 같은 lawId 의 lawNo ≤ 현재 회차 중 SFULL_ITEM 별 최신 회차 row
			List<ProvVrsnVO> rows = provVrsnMapper.selectProvVrsnAndSubItemsCumulative(lawId, lawNo, fullItem);
			if (rows != null && !rows.isEmpty()) {
				ProvVrsnVO v = rows.get(0);   // 조 BASE_TEXT row
				res.put("found",       true);
				res.put("promNo",      v.getPromNo());
				res.put("fullItem",    v.getFullItem());
				res.put("item",        v.getItem());
				res.put("subItem",     v.getSubItem());
				res.put("unitType",    v.getUnitType());
				res.put("nativeType",  v.getNativeType());
				res.put("level",       v.getLevel());
				// 과거 verbatim 저장으로 SCONTENTS 에 라벨/제목이 박혀 있을 수 있어 정규화로 제목·본문 분리(자가복구).
				String[] norm = narainet.rlms.prom.service.impl.ProvTextParser.normalizeJoFormContent(v.getContents());
				String stitle = v.getTitle();
				boolean validTitle = stitle != null && !stitle.trim().isEmpty() && !"null".equalsIgnoreCase(stitle.trim());
				String joTitle = validTitle ? stitle.trim() : norm[0];   // STITLE 우선, 없으면 본문에서 추출
				v.setTitle(joTitle);                                     // buildProvVrsnJoLabel 가 제목 반영하도록
				res.put("title",       joTitle);
				res.put("startDate",   v.getStartDate());
				res.put("reason",      v.getReason());
				res.put("gaejungType", v.getGaejungType());

				// 단건 "조문별 수정" = 이 조 전체(조 + 항/호/목)를 일괄편집기와 같은 포맷으로 조립해 표시.
				//   (옛 동작은 조 행만 표시 → 조 본문에 인라인인 ①항만 보이고 ②항 이후가 안 보이던 #5 버그)
				//   저장 시 saveProvVrsn 이 이 블록을 재분해해 그 조 subtree 만 교체하므로 중복 누적 없음.
				StringBuilder sb = new StringBuilder();
				for (ProvVrsnVO r : rows) {
					String line = formatBulkLine(r);
					if (line == null || line.isEmpty()) continue;
					if (sb.length() > 0) sb.append('\n');
					sb.append(line);
				}
				res.put("contents", sb.toString());
			} else {
				res.put("found", false); res.put("promNo", promNo); res.put("fullItem", fullItem);
			}
		} catch (Exception e) {
			res.put("found", false); res.put("error", e.getMessage());
		}
		return res;
	}

	/**
	 * 조항(TB_PROV_VRSN) 단위 본문 in-place 저장 — 트리의 조 노드 편집용.
	 * 단위 재분해는 하지 않는다(단건 조 row 의 STITLE/SCONTENTS/SREASON/SGAEJUNG_TYPE 만 갱신).
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/saveProvVrsn.do")
	public Map<String,Object> saveProvVrsn(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long promNo = parseLongSafe(params.get("promNo"));
			String fullItem = params.get("fullItem");
			if (promNo == null || fullItem == null || fullItem.trim().isEmpty()) {
				res.put("success", false); res.put("message", "조항 식별자(promNo/fullItem)가 없습니다."); return res;
			}
			promEditGuard.assertCanEditProm(promNo);   // 작성권한 가드(관리자/분류작성자)
			ProvVrsnVO v = provVrsnMapper.selectProvVrsnByFullItem(promNo, fullItem.trim());
			if (v == null) {
				res.put("success", false); res.put("message", "조항 단위 행을 찾을 수 없습니다."); return res;
			}
			if (params.containsKey("contents")) {
				// 전체 편집(#5): "제N조(제목) ①… ②… ③…" 블록 → 그 조 subtree 재분해 교체.
				//   조 본문 + 모든 항/호/목을 한 화면에서 편집. 저장은 대상 회차 소유 행 범위로 한정.
				// ★저장 대상 = 보는 회차(폼 lawId/lawNo 로 식별) — 이전 연혁 상속 조를 새 연혁
				//   컨텍스트에서 편집하면 상속 원본(owner 회차) 행을 소급 수정하지 않고 보는 회차의
				//   개정으로 저장한다. lawId/lawNo 미전송(구 클라이언트)이면 owner 회차 = 기존 동작.
				Long lawId = parseLongSafe(params.get("lawId"));
				Long lawNo = parseLongSafe(params.get("lawNo"));
				Long targetPromNo = promNo;
				if (lawId != null && lawNo != null) {
					for (PromVO pr : promMapper.selectPromListByLawId(lawId, v.getSysId())) {
						if (lawNo.equals(pr.getLawNo())) { targetPromNo = pr.getPromNo(); break; }
					}
				}
				if (!targetPromNo.equals(promNo)) {
					promEditGuard.assertCanEditProm(targetPromNo);
				}
				int n = provVrsnService.replaceJoSubtree(targetPromNo, lawId, lawNo, fullItem.trim(),
						params.get("contents"),
						emptyToNull(params.get("startDate")),
						v.getSysId(),
						params.containsKey("reason") ? params.get("reason") : null);
				boolean reverted = (n < 0);
				promWorkService.logAction(targetPromNo, v.getSysId(), "TB_PROV_VRSN", String.valueOf(targetPromNo),
						narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_UPDATE,
						"조문편집", reverted
								? "조문별 수정 — 이전 연혁과 동일, 이 연혁의 개정 데이터 제거(승계 복원) (" + fullItem.trim() + ")"
								: "조문별 수정 (" + fullItem.trim() + ", " + n + "개 단위)",
						currentUserId(), currentUserNm());
				res.put("success",  true);
				res.put("fullItem", fullItem.trim());
				res.put("reverted", reverted);
				res.put("message",  reverted
						? "이전 연혁과 내용이 동일합니다 — 이 연혁의 개정 데이터를 제거하고 이전 연혁 조문을 승계합니다."
						: "저장되었습니다. (" + n + "개 단위)");
			} else {
				// 본문 없이 제목/사유/유형/시행일만 변경 — 조 행 in-place 갱신
				if (params.containsKey("title")) v.setTitle(emptyToNull(params.get("title")));
				if (params.containsKey("reason"))      v.setReason(params.get("reason"));
				if (params.containsKey("gaejungType")) v.setGaejungType(emptyToNull(params.get("gaejungType")));
				if (params.containsKey("startDate"))   v.setStartDate(emptyToNull(params.get("startDate")));
				provVrsnMapper.updateProvVrsnContent(v);
				promWorkService.logAction(promNo, v.getSysId(), "TB_PROV_VRSN", String.valueOf(promNo),
						narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_UPDATE,
						"조문편집", "단건 조항 수정 (" + v.getFullItem() + ")", currentUserId(), currentUserNm());
				res.put("success",  true);
				res.put("fullItem", v.getFullItem());
				res.put("message",  "저장되었습니다.");
			}
		} catch (Exception e) {
			res.put("success", false); res.put("message", "저장 실패: " + e.getMessage());
		}
		return res;
	}

	// ============================================================
	// 1-b''') 회차 전체 본문 일괄 편집기 (레거시 "버전관리용조문편집")
	//   - "조문" 그룹(provgrp) 노드 클릭 시 진입.
	//   - 누적 본문(장/절/조/항/호 …) 을 SFULL_ITEM 순으로 한 줄씩 조립해 텍스트로 반환.
	//   - 저장(text → 60자 SFULL_ITEM 재파싱) 은 후속 작업.
	// ============================================================

	/** 회차의 누적 본문을 일괄 편집기용 텍스트로 조립해 반환 */
	@ResponseBody
	@RequestMapping("/rlms/prom/provBulkBodyJson.do")
	public Map<String,Object> provBulkBodyJson(@RequestParam("promNo") Long promNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("found", false); res.put("error", "unauthenticated"); return res;
		}
		try {
			PromVO p = promService.selectPromDetail(promNo);
			if (p == null) { res.put("found", false); res.put("error", "규정 없음"); return res; }
			Long lawId = p.getLawId();
			Long lawNo = p.getLawNo();
			if (lawId == null || lawNo == null) {
				res.put("found", false); res.put("error", "회차의 lawId/lawNo 미상"); return res;
			}
			List<ProvVrsnVO> rows = provVrsnMapper.selectAllCumulative(lawId, lawNo);
			StringBuilder sb = new StringBuilder();
			int count = 0;
			for (ProvVrsnVO v : rows) {
				String line = formatBulkLine(v);
				if (line == null) continue;
				if (sb.length() > 0) sb.append('\n');
				sb.append(line);
				count++;
			}
			res.put("found",   true);
			res.put("promNo",  promNo);
			res.put("lawId",   lawId);
			res.put("lawNo",   lawNo);
			res.put("rowCnt",  count);
			// 본문 내 숫자 문자참조(&#40; 등) 디코드 — 일괄편집기에 깨끗한 텍스트로 로드, 재저장 시 파서가 제목 정상 추출.
			res.put("body",    narainet.rlms.prom.service.impl.ProvViewRenderer.decodeNumericEntities(sb.toString()));
			res.put("title",   p.getTitle());
		} catch (Exception e) {
			res.put("found", false); res.put("error", e.getMessage());
		}
		return res;
	}

	/** 한 단위 row 를 일괄 편집기 한 줄로 — 단위 타입에 맞는 prefix + 제목/본문 */
	private String formatBulkLine(ProvVrsnVO v) {
		if (v == null) return null;
		String unit       = v.getUnitType();
		String nativeType = v.getNativeType();
		String label;
		String body = (v.getContents() != null) ? v.getContents().trim() : "";
		if ("BASE_TEXT_GROUP".equals(unit)) {
			label = buildProvVrsnGroupLabel(v);              // "제N장 제목"
		} else if ("BASE_TEXT".equals(unit)) {
			// 조 — 과거 verbatim 저장으로 SCONTENTS 에 라벨/제목이 박혀 "제7조의2 제7조의2 …" 식 중복되던
			// 것을 정규화로 분리(자가복구). 일괄 재저장 한 번이면 전체 조가 깨끗해진다.
			String[] norm = narainet.rlms.prom.service.impl.ProvTextParser.normalizeJoFormContent(v.getContents());
			String st = v.getTitle();
			boolean ok = st != null && !st.trim().isEmpty() && !"null".equalsIgnoreCase(st.trim());
			String t = ok ? st.trim() : norm[0];
			String saved = v.getTitle();
			v.setTitle(t);
			label = buildProvVrsnJoLabel(v);                 // "제N조(제목)"
			v.setTitle(saved);                               // 부작용 방지 원복
			body = (norm[1] != null) ? norm[1] : "";
		} else if ("SUB_TEXT".equals(unit)) {
			label = buildProvVrsnSubLabel(v);                // "①" / "1." / "가." 등
		} else if ("POST_SCRIPT".equals(unit)) {
			// 부칙 — 헤더("부칙 <...>") 그대로 출력해야 재저장 시 ProvTextParser 가 다시 부칙으로 인식
			label = safe(v.getTitle());
		} else {
			label = (v.getTitle() != null) ? v.getTitle().trim() : "";
			if (label.isEmpty() && nativeType != null) label = "[" + nativeType + "]";
		}
		// 레거시 원본 본문은 SmartEditor HTML — ProvTextParser 가 plain text 만 처리하므로
		// <p>/<br/>/<...> 태그 제거 + 줄바꿈 평문화. label 도 동일.
		label = stripHtmlToPlain(label);
		body  = stripHtmlToPlain(body);
		if (label == null) label = "";
		if (body.isEmpty()) return label;
		if (label.isEmpty()) return body;
		// 부칙 블록은 헤더와 본문을 줄바꿈으로 — 부칙 내부 "제1조(시행일)" 등이 별 줄로 보존돼
		// 재저장 시 부칙 모드에 그대로 남는다. 그 외 단위는 레거시 JangPattern.getText 형식(공백 1칸).
		String sep = "POST_SCRIPT".equals(unit) ? "\n" : " ";
		return label + sep + body;
	}

	/**
	 * HTML 태그 → plain text 변환 — 일괄편집기는 plain text 만 다룸.
	 * <p>/<br/>/<...> 제거 + entity 디코드 + 연속 빈 줄 정리.
	 */
	private static String stripHtmlToPlain(String html) {
		if (html == null || html.isEmpty()) return html;
		String s = html;
		// 줄바꿈으로 변환할 태그
		s = s.replaceAll("(?i)<br\\s*/?>", "\n");
		s = s.replaceAll("(?i)</p>",       "\n");
		s = s.replaceAll("(?i)<p[^>]*>",   "");
		s = s.replaceAll("(?i)</div>",     "\n");
		s = s.replaceAll("(?i)<div[^>]*>", "");
		// 잔여 HTML 태그 제거 (img/span/strong/em 등) — ASCII 태그명 형태(</?영문…>)만.
		// 법령 꺾쇠 표기 <개정 2026. 6. 12.> / 부칙 <제999호, …> 는 한글·숫자 시작이라 보존.
		s = s.replaceAll("(?s)<!--.*?-->", "");
		s = s.replaceAll("</?[A-Za-z][^>]*>", "");
		// HTML entity 디코드
		s = s.replace("&nbsp;",  " ")
		     .replace("&lt;",    "<")
		     .replace("&gt;",    ">")
		     .replace("&quot;",  "\"")
		     .replace("&apos;",  "'")
		     .replace("&#39;",   "'")
		     .replace("&#40;",   "(")
		     .replace("&#41;",   ")")
		     .replace("&middot;", "·")
		     .replace("&hellip;", "…")
		     .replace("&amp;",   "&");
		// 연속 빈 줄 정리 + 좌우 공백 trim
		s = s.replaceAll("\n{3,}", "\n\n").trim();
		return s;
	}

	/**
	 * 일괄 편집기 저장 — 레거시 "버전관리용조문편집" 의 [저장하기].
	 *  text → ProvTextParser → 60자 SFULL_ITEM 행으로 분해 → 이 회차의 TB_PROV_VRSN 통째 교체.
	 *  스냅샷 시멘틱(이 회차가 모든 행을 직접 소유) — 레거시 동일.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/saveProvBulkBody.do")
	public Map<String,Object> saveProvBulkBody(@RequestParam Map<String,String> params, HttpServletRequest request) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long promNo = parseLongSafe(params.get("promNo"));
			// 본문은 폼 파라미터(소형) 또는 원시 요청 본문(대형)에서 — 한국법령 전문은 form-urlencoded 시
			//   한글이 %XX%XX%XX 로 ~4배 팽창해 Tomcat maxPostSize(기본 2MB)를 넘어 연결이 끊긴다.
			//   클라이언트가 text/plain 원시 본문으로 보내면 팽창 없이(promNo 는 쿼리스트링) 대용량도 통과. (조특법 시행령 등)
			String body = params.get("body");
			if (body == null || body.isEmpty()) {
				body = readRawRequestBody(request);
			}
			if (promNo == null) {
				res.put("success", false); res.put("message", "회차 식별자(promNo) 가 없습니다."); return res;
			}
			promEditGuard.assertCanEditProm(promNo);   // 작성권한 가드(관리자/분류작성자)
			PromVO p = promService.selectPromDetail(promNo);
			if (p == null) {
				res.put("success", false); res.put("message", "회차를 찾을 수 없습니다."); return res;
			}
			String startDate   = p.getStartDate() != null ? p.getStartDate() : p.getPromDate();
			String sysId       = p.getSysId();
			String gaejungType = "MODIFY_ALL";   // 기본 — 라인별 NULLIFY 는 파서가 덮어씀

			// 1) 스냅샷 직전에 본문을 이력 테이블에 백업 (레거시 "이전개정작업내용")
			try {
				ProvTextHstVO hst = new ProvTextHstVO();
				hst.setProvTextHstNo(provTextHstIdGnrService.getNextLongId());
				hst.setPromNo(promNo);
				hst.setUserId(currentUserId());
				hst.setText(body);
				provTextHstMapper.insertHistory(hst);
			} catch (Exception histEx) {
				// 이력 저장 실패는 본 저장을 막지 않음 (로그만)
			}

			// 2) 본 스냅샷 적용 (lawId/lawNo = 삭제·이동 tombstone 비교 기준선)
			int saved = provVrsnService.snapshotBulkBody(promNo, p.getLawId(), p.getLawNo(),
					body, startDate, sysId, gaejungType);
			// 3) 감사 로그 (레거시 PromulgationActionLog 조문편집)
			promWorkService.logAction(promNo, sysId, "TB_PROV_VRSN", String.valueOf(promNo),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_UPDATE,
					"조문편집", "버전관리용조문편집 일괄저장 (" + saved + " 행)",
					currentUserId(), currentUserNm());
			res.put("success",  true);
			res.put("promNo",   promNo);
			res.put("savedRow", saved);
			res.put("message",  "저장되었습니다. (" + saved + " 행)");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "저장 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 임시저장 — 본문을 TB_PROV_TEXT_HST 에만 저장. TB_PROV_VRSN(정식 본문) 은 건드리지 않음.
	 * 사용자 화면(front) 에는 영향 없음 (이전 본문이 그대로 노출).
	 * 작성자가 중간 저장 용도로 사용 + "이전개정작업내용" 드롭다운에서 다시 불러옴.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/saveProvBulkBodyTempJson.do")
	public Map<String,Object> saveProvBulkBodyTempJson(
			@RequestParam("promNo") Long promNo,
			@RequestParam("body")   String body) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			promEditGuard.assertCanEditProm(promNo);   // 작성권한 가드(관리자/분류작성자)
			if (body == null) body = "";
			ProvTextHstVO hst = new ProvTextHstVO();
			hst.setProvTextHstNo(provTextHstIdGnrService.getNextLongId());
			hst.setPromNo(promNo);
			hst.setUserId(currentUserId());
			hst.setText(body);
			provTextHstMapper.insertHistory(hst);
			res.put("success", true);
			res.put("provTextHstNo", hst.getProvTextHstNo());
			res.put("message", "임시저장 되었습니다. (이전개정작업내용 드롭다운에서 다시 불러올 수 있습니다)");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "임시저장 실패: " + e.getMessage());
		}
		return res;
	}

	// ============================================================
	// 1-b'''') 이전개정작업내용 (TB_PROV_TEXT_HST) — 레거시 동일 드롭다운/불러오기/삭제
	// ============================================================

	/** 연혁번호(ILAW_NO) 자동채번 제안 — 연혁등록 폼 prefill (제정=10, 개정=직전+10) */
	@ResponseBody
	@RequestMapping("/rlms/prom/nextLawNo.do")
	public Map<String,Object> nextLawNo(
			@RequestParam(value = "lawId", required = false) Long lawId) {
		Map<String,Object> res = new LinkedHashMap<>();
		try {
			res.put("lawNo", promService.suggestNextLawNo(lawId));
		} catch (Exception e) {
			res.put("lawNo", 10L);
		}
		return res;
	}

	/** 회차의 이전개정작업내용 목록 (최신 30건, 본문 제외) */
	@ResponseBody
	@RequestMapping("/rlms/prom/provTextHstListJson.do")
	public List<Map<String,Object>> provTextHstListJson(@RequestParam("promNo") Long promNo) {
		List<Map<String,Object>> out = new ArrayList<>();
		// 사용자 뷰어(변경 내역 목록)도 호출 — 공개열람 모드면 익명 허용. 본문(provTextHstBodyJson)은 편집기 전용 유지.
		if (!narainet.rlms.common.service.PublicFront.viewAllowed() || promNo == null) return out;
		if (!promReadGuard.canReadProm(promNo)) return out;   // 분류별 열람제한
		try {
			List<ProvTextHstVO> list = provTextHstMapper.selectHistoryByPromNo(promNo);
			if (list != null) for (ProvTextHstVO h : list) {
				Map<String,Object> m = new LinkedHashMap<>();
				m.put("provTextHstNo", h.getProvTextHstNo());
				m.put("insDt",         h.getInsDt());
				m.put("userId",        h.getUserId());
				out.add(m);
			}
		} catch (Exception ignore) { }
		return out;
	}

	/** 이전개정작업내용 단건 본문 — "불러오기" 진입점 */
	@ResponseBody
	@RequestMapping("/rlms/prom/provTextHstBodyJson.do")
	public Map<String,Object> provTextHstBodyJson(@RequestParam("provTextHstNo") Long provTextHstNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("found", false); return res;
		}
		try {
			ProvTextHstVO h = provTextHstMapper.selectHistoryByNo(provTextHstNo);
			if (h == null) { res.put("found", false); return res; }
			// 분류별 열람제한 — 목록(provTextHstListJson)과 동일 가드 (번호 추측 우회 차단, 2026-07-09)
			if (!promReadGuard.canReadProm(h.getPromNo())) { res.put("found", false); return res; }
			res.put("found",         true);
			res.put("provTextHstNo", h.getProvTextHstNo());
			res.put("promNo",        h.getPromNo());
			res.put("insDt",         h.getInsDt());
			res.put("userId",        h.getUserId());
			res.put("body",          h.getText());
		} catch (Exception e) {
			res.put("found", false); res.put("error", e.getMessage());
		}
		return res;
	}

	/** 이전개정작업내용 단건 삭제 */
	@ResponseBody
	@RequestMapping("/rlms/prom/deleteProvTextHst.do")
	public Map<String,Object> deleteProvTextHst(@RequestParam("provTextHstNo") Long provTextHstNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message","로그인이 필요합니다."); return res;
		}
		try {
			ProvTextHstVO h = provTextHstMapper.selectHistoryByNo(provTextHstNo);
			if (h == null) { res.put("success", false); res.put("message", "대상이 없습니다."); return res; }
			// 작성권한 가드 — 대상 회차의 관리자/분류작성자만 임시저장 삭제 (타인 임시저장 무단삭제 차단, 2026-07-09)
			promEditGuard.assertCanEditProm(h.getPromNo());
			int n = provTextHstMapper.deleteHistory(provTextHstNo);
			res.put("success", n > 0);
			res.put("message", n > 0 ? "삭제되었습니다." : "대상이 없습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "삭제 실패: " + e.getMessage());
		}
		return res;
	}

	/** SUB_TEXT(항/호/목/단) 행의 prefix — 레거시 HangPattern/HoPattern/Mok2Pattern.getPrefix 약식 */
	private String buildProvVrsnSubLabel(ProvVrsnVO v) {
		String nt = v.getNativeType();
		int item = parseIntSafe(v.getItem(), 0);
		// 레거시 의 native_type: S_HANG(①) / S_HO(1.) / S_MOK2(가.) / S_DAN2((1)) / surround hangul 등
		if (nt == null) return v.getTitle() != null ? v.getTitle().trim() : "";
		switch (nt) {
			case "S_HANG":  return circledNum(item);                          // ① ② ③ …
			case "S_HO":    return item > 0 ? item + "."   : "";              // 1. 2. 3.
			case "S_HO2":   return item > 0 ? item + ")"   : "";              // 1) 2) 3)
			case "S_MOK2":  return item > 0 ? korLetter(item) + "."  : "";    // 가. 나. 다.
			case "S_DAN2":  return item > 0 ? "(" + item + ")" : "";          // (1) (2)
			default:        return safe(v.getTitle()).trim();
		}
	}

	private String circledNum(int n) {
		// 정수 → 원문자 항 번호. 유니코드 원문자 3개 블록(1~50). 범위 밖은 "n." 폴백.
		if (n >= 1  && n <= 20) return String.valueOf((char) (0x2460 + n - 1));   // ① ~ ⑳
		if (n >= 21 && n <= 35) return String.valueOf((char) (0x3251 + n - 21));  // ㉑ ~ ㉟
		if (n >= 36 && n <= 50) return String.valueOf((char) (0x32B1 + n - 36));  // ㊱ ~ ㊿
		return n > 0 ? n + "." : "";
	}
	private String korLetter(int n) {
		// 가=0xAC00, 나=0xB098 — 한글 자모 N째 음절. 간단 매핑(가/나/다/라/마/바/사/아/자/차/카/타/파/하).
		String[] kor = {"가","나","다","라","마","바","사","아","자","차","카","타","파","하"};
		if (n < 1) return "";
		if (n > kor.length) return n + ".";
		return kor[n - 1];
	}

	// ============================================================
	// 1-b'') 별표/별지서식(TB_DOCU) 단건 Ajax 조회 / 저장 — 트리의 docu 노드용
	// ============================================================

	/** 별표/별지서식 단건 조회 — PK(docuNo) */
	@ResponseBody
	@RequestMapping("/rlms/prom/docuFragmentJson.do")
	public Map<String,Object> docuFragmentJson(@RequestParam("docuNo") Long docuNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("found", false); res.put("error", "unauthenticated"); return res;
		}
		try {
			DocuVO d = docuMapper.selectDocuByNo(docuNo);
			if (d != null) {
				res.put("found",       true);
				res.put("docuNo",      d.getDocuNo());
				res.put("promNo",      d.getPromNo());
				res.put("item",        d.getItem());
				res.put("grpTitle",    d.getGrpTitle());
				res.put("title",       d.getTitle());
				res.put("contents",    d.getContents());
				res.put("reason",      d.getReason());
				res.put("gaejungType", d.getGaejungType());
				res.put("dispYn",      d.getDispYn());
			} else {
				res.put("found", false); res.put("docuNo", docuNo);
			}
		} catch (Exception e) {
			res.put("found", false); res.put("error", e.getMessage());
		}
		return res;
	}

	/**
	 * 별표/별지서식 단건 in-place 저장 — 트리의 docu 노드 편집용.
	 * 단건 TB_DOCU row 의 STITLE/SCONTENTS/SREASON/SGAEJUNG_TYPE/SDISP_YN 만 갱신.
	 * 새 회차에 변경분을 분기 등록하는 워크플로(레거시 DocumentController.updateDo)는 별도.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/saveDocu.do")
	public Map<String,Object> saveDocu(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long docuNo = parseLongSafe(params.get("docuNo"));
			if (docuNo == null) {
				res.put("success", false); res.put("message", "별표 식별자(docuNo)가 없습니다."); return res;
			}
			DocuVO d = docuMapper.selectDocuByNo(docuNo);
			if (d == null) {
				res.put("success", false); res.put("message", "별표 행을 찾을 수 없습니다."); return res;
			}
			promEditGuard.assertCanEditProm(d.getPromNo());   // 작성권한 가드(관리자/분류작성자)
			// 상속 행 in-place 수정 차단 — 다른 회차 컨텍스트에서 연 행은 개정분기(branchDocu)로 (레거시 원본 불변)
			Long viewPromNo = parseLongSafe(params.get("viewPromNo"));
			if (viewPromNo != null && !viewPromNo.equals(d.getPromNo())) {
				res.put("success", false);
				res.put("message", "이전 회차에 등록된 별표입니다. \"이 회차로 개정 등록\"(개정분기)을 사용하세요.");
				return res;
			}
			// 개정유형 도메인 가드 (빈값=유지)
			String gj = emptyToNull(params.get("gaejungType"));
			if (gj != null && !"NEW".equals(gj) && !"MODIFY".equals(gj) && !"EQUAL".equals(gj)
					&& !"NULLIFY".equals(gj) && !"NULLIFY_SEMANTIC".equals(gj)) {
				res.put("success", false); res.put("message", "개정유형 값이 올바르지 않습니다: " + gj); return res;
			}
			if (params.containsKey("title"))       d.setTitle(emptyToNull(params.get("title")));
			if (params.containsKey("contents"))    d.setContents(params.get("contents"));
			if (params.containsKey("reason"))      d.setReason(params.get("reason"));
			if (gj != null)                        d.setGaejungType(gj);
			if (params.containsKey("dispYn"))      d.setDispYn(emptyToNull(params.get("dispYn")));
			docuMapper.updateDocuContent(d);
			res.put("success", true);
			res.put("docuNo",  d.getDocuNo());
			res.put("message", "저장되었습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "저장 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 별표/별지서식 단건 물리 삭제 — 트리의 docu 노드 편집화면 [삭제] 버튼용 (레거시 DocumentController.deleteDo 파리티).
	 *  - 자기회차(own) 행만 삭제 가능. 상속(이전회차) 행은 viewPromNo 가드로 차단하고
	 *    "이 회차로 개정 등록(개정분기) → 삭제(숨김)" 경로로 안내 (레거시 원본 불변 정책).
	 *  - TB_DOCU 는 SDEL_YN 이 없는 HARD delete. 개별 첨부는 트리거 TRG_DEL_DOCU 가
	 *    관련자료(SFLAG='DOCUMENT', SFULL_ITEM=SITEM) → TB_REL_FILE → TB_ATTACH 로 cascade (2026-07-30).
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/deleteDocu.do")
	public Map<String,Object> deleteDocu(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long docuNo = parseLongSafe(params.get("docuNo"));
			if (docuNo == null) {
				res.put("success", false); res.put("message", "별표 식별자(docuNo)가 없습니다."); return res;
			}
			DocuVO d = docuMapper.selectDocuByNo(docuNo);
			if (d == null) {
				res.put("success", false); res.put("message", "별표 행을 찾을 수 없습니다."); return res;
			}
			promEditGuard.assertCanEditProm(d.getPromNo());   // 작성권한 가드(관리자/분류작성자)
			// 상속(이전회차) 행 삭제 차단 — own-회차 행만 HARD delete (레거시 원본 불변)
			Long viewPromNo = parseLongSafe(params.get("viewPromNo"));
			if (viewPromNo != null && !viewPromNo.equals(d.getPromNo())) {
				res.put("success", false);
				res.put("message", "이전 회차에 등록된 별표입니다. \"이 회차로 개정 등록\"(개정분기) 후 \"삭제(숨김)\" 유형으로 폐지하세요.");
				return res;
			}
			docuMapper.deleteDocu(docuNo);
			promWorkService.logAction(d.getPromNo(), d.getSysId(), "TB_DOCU", String.valueOf(docuNo),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_DELETE,
					"별표삭제", "별표/별지서식 단건 삭제 (" + (d.getTitle() != null ? d.getTitle() : "#"+docuNo) + ")",
					currentUserId(), currentUserNm());
			res.put("success", true);
			res.put("docuNo",  docuNo);
			res.put("message", "삭제되었습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "삭제 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * HTML형식조문(TB_PROV_HTML) 단건 삭제 — IDE 조항 편집화면 [삭제] 버튼용 (별표 삭제와 parity).
	 *  - own-회차 행만 삭제. 상속 행은 viewPromNo 가드 차단 → 개정분기 후 폐지 안내.
	 *  - 서비스 deleteProvHtml 이 트리거 cascade(REL_VRSN/ATTACH) + TB_PROV_VRSN 재분해까지 처리.
	 *  - 기존 ProvHtmlController.deleteProvHtml.do(redirect, 가드없음)는 비-IDE용으로 그대로 둠.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/deleteProvHtmlIde.do")
	public Map<String,Object> deleteProvHtmlIde(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long provHtmlNo = parseLongSafe(params.get("provHtmlNo"));
			if (provHtmlNo == null) {
				res.put("success", false); res.put("message", "조항 식별자(provHtmlNo)가 없습니다."); return res;
			}
			ProvHtmlVO cur = provHtmlService.selectProvHtmlByNo(provHtmlNo);
			if (cur == null) {
				res.put("success", false); res.put("message", "조항 행을 찾을 수 없습니다."); return res;
			}
			promEditGuard.assertCanEditProm(cur.getPromNo());   // 작성권한 가드
			Long viewPromNo = parseLongSafe(params.get("viewPromNo"));
			if (viewPromNo != null && cur.getPromNo() != null && !viewPromNo.equals(cur.getPromNo())) {
				res.put("success", false);
				res.put("message", "이전 회차에 등록된 조항입니다. \"이 회차로 개정 등록\"(개정분기) 후 \"삭제(숨김)\" 유형으로 폐지하세요.");
				return res;
			}
			provHtmlService.deleteProvHtml(provHtmlNo);
			promWorkService.logAction(cur.getPromNo(), cur.getSysId(), "TB_PROV_HTML", String.valueOf(provHtmlNo),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_DELETE,
					"HTML조문삭제", "HTML 조문 단건 삭제 (" + (cur.getItem() != null ? cur.getItem() : "#"+provHtmlNo) + ")",
					currentUserId(), currentUserNm());
			res.put("success",    true);
			res.put("provHtmlNo", provHtmlNo);
			res.put("message",    "삭제되었습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "삭제 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 별표/별지서식 다음 번호 제안 — 신규등록 모달 prefill.
	 * 회차 누적 목록에서 해당 유형(01별표/02별지서식/03별첨) 의 MAX(번호)+1.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/docuNextItemJson.do")
	public Map<String,Object> docuNextItemJson(
			@RequestParam("promNo")   Long promNo,
			@RequestParam("itemType") String itemType) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			PromVO p = promService.selectPromDetail(promNo);
			if (p == null) { res.put("success", false); res.put("message", "회차 없음"); return res; }
			int max = 0;
			List<DocuVO> rows = docuMapper.selectDocuListCumulative(p.getLawId(), p.getLawNo());
			for (DocuVO r : rows) {
				String it = r.getItem();
				if (it != null && it.length() >= 6 && it.startsWith(itemType)) {
					try { max = Math.max(max, Integer.parseInt(it.substring(2, 6))); } catch (NumberFormatException ignore) {}
				}
			}
			res.put("success", true);
			res.put("nextNo",  max + 1);
		} catch (Exception e) {
			res.put("success", false); res.put("message", e.getMessage());
		}
		return res;
	}

	/**
	 * 별표/별지서식 신규 등록 — 레거시 DocumentController.insertDo 이식.
	 *  SITEM = 유형(2) + 번호(4 zero-pad) + 가지번호(2 zero-pad). 실DB 전수 8자리.
	 *  본문(SCONTENTS)은 운영상 미사용(메타 항목) — 실제 내용물은 관련자료/첨부로 유통.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/insertDocu.do")
	public Map<String,Object> insertDocu(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long promNo = parseLongSafe(params.get("promNo"));
			if (promNo == null) {
				res.put("success", false); res.put("message", "회차 식별자(promNo)가 없습니다."); return res;
			}
			promEditGuard.assertCanEditProm(promNo);   // 작성권한 가드(관리자/분류작성자)
			PromVO p = promService.selectPromDetail(promNo);
			if (p == null) {
				res.put("success", false); res.put("message", "회차를 찾을 수 없습니다."); return res;
			}
			String itemType = params.get("itemType");
			if (!"01".equals(itemType) && !"02".equals(itemType) && !"03".equals(itemType)) {
				res.put("success", false); res.put("message", "유형은 01(별표)/02(별지서식)/03(별첨) 중 하나여야 합니다."); return res;
			}
			String title = emptyToNull(params.get("title"));
			if (title == null) {
				res.put("success", false); res.put("message", "제목을 입력하세요."); return res;
			}
			int itemNo, subNo;
			try {
				itemNo = Integer.parseInt(params.getOrDefault("itemNo", "").trim());
			} catch (NumberFormatException e) {
				res.put("success", false); res.put("message", "번호는 숫자여야 합니다."); return res;
			}
			try {
				String s = params.getOrDefault("subNo", "").trim();
				subNo = s.isEmpty() ? 0 : Integer.parseInt(s);
			} catch (NumberFormatException e) {
				res.put("success", false); res.put("message", "가지번호는 숫자여야 합니다."); return res;
			}
			if (itemNo < 1 || itemNo > 9999 || subNo < 0 || subNo > 99) {
				res.put("success", false); res.put("message", "번호는 1~9999, 가지번호는 0~99 범위입니다."); return res;
			}
			String sitem = itemType + String.format("%04d", itemNo) + String.format("%02d", subNo);

			// 중복 차단 — 회차 누적(이전 회차 상속분 포함)에 같은 SITEM 이 있으면 신규 불가(해당 노드에서 수정)
			for (DocuVO r : docuMapper.selectDocuListCumulative(p.getLawId(), p.getLawNo())) {
				if (sitem.equals(r.getItem())) {
					res.put("success", false);
					res.put("message", "이미 존재하는 번호입니다 (" + r.getTitle() + "). 트리에서 해당 항목을 선택해 수정하세요.");
					return res;
				}
			}

			// STITLE — 실DB 표기: "[별표 1] 기구도" / "[별지 제1호서식] 신고서". 사용자가 [ 로 시작하면 그대로.
			String label;
			if (title.startsWith("[")) {
				label = title;
			} else {
				String noTxt = itemNo + (subNo > 0 ? "의" + subNo : "");
				if ("02".equals(itemType))      label = "[별지 제" + noTxt + "호서식] " + title;
				else if ("03".equals(itemType)) label = "[별첨 " + noTxt + "] " + title;
				else                            label = "[별표 " + noTxt + "] " + title;
			}

			DocuVO d = new DocuVO();
			d.setDocuNo(docuIdGnrService.getNextLongId());
			d.setPromNo(promNo);
			d.setItem(sitem);
			d.setGrpTitle(" ");
			d.setTitle(label);
			d.setReason(emptyToNull(params.get("reason")));
			d.setGaejungType("NEW");
			d.setDispYn("Y");
			docuMapper.insertDocu(d);

			promWorkService.logAction(promNo, p.getSysId(), "TB_DOCU", String.valueOf(d.getDocuNo()),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_INSERT,
					"별표등록", "별표/별지서식 신규 등록 (" + label + ")", currentUserId(), currentUserNm());
			res.put("success", true);
			res.put("docuNo",  d.getDocuNo());
			res.put("title",   label);
			res.put("message", "등록되었습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "등록 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 별표/별지서식 "새 회차 개정분기" — 레거시 DocumentController 의
	 * update 화면(GAEJUNG_YN='Y') → gaejung() → pAct=insertDo 제출 경로 이식.
	 *
	 *  이전 회차에 저장된(상속) 별표 행을, 지금 보는 회차(promNo)에 새 행으로 INSERT.
	 *  원본 행은 절대 건드리지 않는다(회차별 스냅샷 누적). SITEM 은 동일 유지(논리 계보 키).
	 *  같은 회차에 같은 SITEM 이 이미 있으면 그 행을 갱신(레거시 insertDo upsert 동작 보존).
	 *  개정유형 도메인 = MODIFY(개정) / NULLIFY_SEMANTIC(폐지 표기) / NULLIFY(완전 숨김) / NEW.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/branchDocu.do")
	public Map<String,Object> branchDocu(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long docuNo = parseLongSafe(params.get("docuNo"));
			Long promNo = parseLongSafe(params.get("promNo"));   // 분기 대상(지금 보는) 회차
			if (docuNo == null || promNo == null) {
				res.put("success", false); res.put("message", "docuNo/promNo 가 필요합니다."); return res;
			}
			promEditGuard.assertCanEditProm(promNo);   // 작성권한 가드(관리자/분류작성자)

			DocuVO src = docuMapper.selectDocuByNo(docuNo);
			if (src == null) {
				res.put("success", false); res.put("message", "원본 별표 행을 찾을 수 없습니다."); return res;
			}
			if (promNo.equals(src.getPromNo())) {
				res.put("success", false);
				res.put("message", "이 별표는 현재 회차에 등록된 행입니다. 분기 없이 바로 수정(저장)하세요.");
				return res;
			}
			PromVO target = promService.selectPromDetail(promNo);
			PromVO owner  = promService.selectPromDetail(src.getPromNo());
			if (target == null) {
				res.put("success", false); res.put("message", "분기 대상 회차를 찾을 수 없습니다."); return res;
			}
			if (owner != null && (target.getLawId() == null || !target.getLawId().equals(owner.getLawId()))) {
				res.put("success", false); res.put("message", "다른 규정의 별표는 분기할 수 없습니다."); return res;
			}
			if (owner != null && target.getLawNo() != null && owner.getLawNo() != null
					&& target.getLawNo() < owner.getLawNo()) {
				res.put("success", false);
				res.put("message", "원본보다 이전 회차로는 분기할 수 없습니다 (원본 회차 " + owner.getLawNo() + ").");
				return res;
			}

			String gaejungType = emptyToNull(params.get("gaejungType"));
			if (gaejungType == null) gaejungType = "MODIFY";   // 분기 기본 = 개정
			if (!"MODIFY".equals(gaejungType) && !"NEW".equals(gaejungType)
					&& !"NULLIFY".equals(gaejungType) && !"NULLIFY_SEMANTIC".equals(gaejungType)) {
				res.put("success", false); res.put("message", "개정유형은 MODIFY/NEW/NULLIFY/NULLIFY_SEMANTIC 중 하나여야 합니다."); return res;
			}
			String title    = params.containsKey("title")    ? emptyToNull(params.get("title"))  : null;
			String contents = params.containsKey("contents") ? params.get("contents")            : null;
			String reason   = params.containsKey("reason")   ? emptyToNull(params.get("reason")) : null;
			String dispYn   = "N".equals(params.get("dispYn")) ? "N" : "Y";

			// 같은 회차에 같은 SITEM 이 이미 있으면 — 그 행을 갱신 (레거시 insertDo 의 upsert)
			List<DocuVO> dup = docuMapper.selectDocuByPromItem(promNo, src.getItem());
			if (dup != null && !dup.isEmpty()) {
				DocuVO d = dup.get(0);
				d.setTitle(title != null ? title : src.getTitle());
				d.setContents(contents != null ? contents : src.getContents());
				d.setReason(reason != null ? reason : src.getReason());
				d.setGaejungType(gaejungType);
				d.setDispYn(dispYn);
				docuMapper.updateDocuContent(d);
				res.put("success", true);
				res.put("docuNo",  d.getDocuNo());
				res.put("updated", true);
				res.put("message", "이 회차에 이미 분기된 행이 있어 갱신했습니다.");
				return res;
			}

			DocuVO d = new DocuVO();
			d.setDocuNo(docuIdGnrService.getNextLongId());
			d.setPromNo(promNo);
			d.setItem(src.getItem());                      // 계보 키 — 동일 유지
			d.setGrpTitle(src.getGrpTitle() != null ? src.getGrpTitle() : " ");
			d.setTitle(title != null ? title : src.getTitle());
			d.setContents(contents != null ? contents : src.getContents());
			d.setReason(reason != null ? reason : src.getReason());
			d.setSearchText(contents != null ? null : src.getSearchText());
			d.setGaejungType(gaejungType);
			d.setDispYn(dispYn);
			docuMapper.insertDocu(d);

			promWorkService.logAction(promNo, target.getSysId(), "TB_DOCU", String.valueOf(d.getDocuNo()),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_INSERT,
					"별표개정분기", "별표/별지서식 회차 분기 등록 (" + d.getTitle() + ", 원본 docuNo=" + docuNo
							+ ", 유형=" + gaejungType + ")", currentUserId(), currentUserNm());
			res.put("success", true);
			res.put("docuNo",  d.getDocuNo());
			res.put("title",   d.getTitle());
			res.put("message", "이 회차로 개정 분기 등록되었습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "분기 등록 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * PDF파일뷰어 참조파일 후보 — 레거시 fillFileListForViewer(CODE_RELATED_FILE_VIEWER) 이식 + RLMS 보강.
	 *  법령 누적 관련파일(TB_REL_FILE) 중 '파일 등록'(REL_FILE_1)·레거시 PDF뷰어용(REL_FILE_3)에서
	 *  실제 PDF 로 렌더 가능한 파일만. value = TB_REL_FILE.IRFILE_NO (= SPROV_FILE_NO).
	 *  ※ RLMS '파일 등록'은 항상 REL_FILE_1 로 저장돼 레거시 처럼 REL_FILE_3 만 받으면 후보가 늘 비었음.
	 *  promNo 없이 lawId 만 오면(신규 연혁 폼) 법령 전체 회차에서 후보를 모은다.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/viewerFileListJson.do")
	public Map<String,Object> viewerFileListJson(
			@RequestParam(value = "promNo", required = false) Long promNo,
			@RequestParam(value = "lawId",  required = false) Long lawId) {
		Map<String,Object> res = new LinkedHashMap<>();
		List<Map<String,Object>> files = new ArrayList<>();
		res.put("files", files);
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) return res;
		if (!promReadGuard.canReadProm(promNo) || !promReadGuard.canReadLaw(lawId)) return res;   // 분류별 열람제한
		try {
			Long effLawId = lawId, effLawNo = null;
			if (promNo != null) {
				PromVO p = promService.selectPromDetail(promNo);
				if (p != null) { effLawId = p.getLawId(); effLawNo = p.getLawNo(); }
			}
			if (effLawId == null) return res;
			if (effLawNo == null) effLawNo = 999999L;   // 신규 회차 — 법령 전체에서 후보
			for (narainet.rlms.related.service.RelFileVO f
					: relFileMapper.selectViewableListCumulative(effLawId, effLawNo)) {
				// 뷰어 후보 = '파일 등록'(REL_FILE_1) + 레거시 PDF뷰어용(REL_FILE_3). 개정문(REL_FILE_2) 제외.
				//   ※ '파일 등록'은 항상 REL_FILE_1 로 저장됨 — REL_FILE_3 만 받던 옛 코드는 후보가 늘 비어
				//      드롭다운 빈칸 → VIEWER 저장이 막히던 버그(첨부는 REL_FILE_1, 뷰어는 REL_FILE_3 만 봄).
				String cate = f.getCate();
				if (!"REL_FILE_1".equals(cate) && !"REL_FILE_3".equals(cate)) continue;
				// 실제 PDF 로 인라인 렌더되는 파일만 후보로 — SVIEW_YN='Y' 는 워드/한글/엑셀도 포함하므로
				//   PromBodyViewResolver 의 VIEWER 렌더 판정과 동일 기준(resolvePdfView)으로 한 번 더 거른다
				//   → 드롭다운에 보이는 파일 = 실제 뷰어에서 보이는 파일(비PDF·미변환본 선택 후 빈 화면 방지).
				if (f.getAttNo() == null) continue;
				AttachVO att = attachService.selectByNo(f.getAttNo());
				if (att == null || attachService.resolvePdfView(att) == null) continue;
				Map<String,Object> m = new LinkedHashMap<>();
				m.put("relFileNo", f.getRelFileNo());
				m.put("name", (f.getAttName() != null && !f.getAttName().isEmpty())
						? f.getAttName() : f.getTitle());
				files.add(m);
			}
		} catch (Exception e) {
			res.put("error", e.getMessage());
		}
		return res;
	}

	/**
	 * HTML형식조문 "새 회차 개정분기" — branchDocu 와 동일 메커니즘 (레거시 원본 불변).
	 *  이전 회차에 저장된(상속) TB_PROV_HTML 행을 지금 보는 회차(promNo)에 새 행으로 INSERT.
	 *  SITEM 은 동일 유지(계보 키). 같은 회차에 같은 SITEM 이 이미 있으면 그 행을 갱신.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/branchProvHtml.do")
	public Map<String,Object> branchProvHtml(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			Long provHtmlNo = parseLongSafe(params.get("provHtmlNo"));
			Long promNo     = parseLongSafe(params.get("promNo"));   // 분기 대상(지금 보는) 회차
			if (provHtmlNo == null || promNo == null) {
				res.put("success", false); res.put("message", "provHtmlNo/promNo 가 필요합니다."); return res;
			}
			promEditGuard.assertCanEditProm(promNo);

			ProvHtmlVO src = provHtmlService.selectProvHtmlByNo(provHtmlNo);
			if (src == null) {
				res.put("success", false); res.put("message", "원본 조항 행을 찾을 수 없습니다."); return res;
			}
			if (promNo.equals(src.getPromNo())) {
				res.put("success", false);
				res.put("message", "이 조항은 현재 회차에 등록된 행입니다. 분기 없이 바로 수정(저장)하세요.");
				return res;
			}
			PromVO target = promService.selectPromDetail(promNo);
			PromVO owner  = promService.selectPromDetail(src.getPromNo());
			if (target == null) {
				res.put("success", false); res.put("message", "분기 대상 회차를 찾을 수 없습니다."); return res;
			}
			if (owner != null && (target.getLawId() == null || !target.getLawId().equals(owner.getLawId()))) {
				res.put("success", false); res.put("message", "다른 규정의 조항은 분기할 수 없습니다."); return res;
			}
			if (owner != null && target.getLawNo() != null && owner.getLawNo() != null
					&& target.getLawNo() < owner.getLawNo()) {
				res.put("success", false);
				res.put("message", "원본보다 이전 회차로는 분기할 수 없습니다 (원본 회차 " + owner.getLawNo() + ").");
				return res;
			}

			String gaejungType = emptyToNull(params.get("gaejungType"));
			if (gaejungType == null) gaejungType = "MODIFY";   // 분기 기본 = 개정
			if (!"MODIFY".equals(gaejungType) && !"NEW".equals(gaejungType)
					&& !"NULLIFY".equals(gaejungType) && !"NULLIFY_SEMANTIC".equals(gaejungType)) {
				res.put("success", false); res.put("message", "개정유형은 MODIFY/NEW/NULLIFY/NULLIFY_SEMANTIC 중 하나여야 합니다."); return res;
			}
			String title    = params.containsKey("title")    ? emptyToNull(params.get("title"))  : null;
			String contents = params.containsKey("contents") ? params.get("contents")            : null;
			String reason   = params.containsKey("reason")   ? emptyToNull(params.get("reason")) : null;
			String dispYn   = "N".equals(params.get("dispYn")) ? "N" : "Y";

			// 같은 회차에 같은 SITEM 이 이미 있으면 — 그 행을 갱신 (분기 중복 방지)
			ProvHtmlVO dup = provHtmlService.selectProvHtmlByPromItem(promNo, src.getItem());
			ProvHtmlVO d;
			boolean updated = (dup != null);
			if (updated) {
				d = dup;
				d.setPromNo(promNo);
				d.setTitle(title != null ? title : src.getTitle());
				d.setContents(contents != null ? contents : src.getContents());
				d.setReason(reason != null ? reason : src.getReason());
				d.setGaejungType(gaejungType);
				d.setDispYn(dispYn);
				provHtmlService.updateProvHtml(d);
			} else {
				d = new ProvHtmlVO();
				d.setPromNo(promNo);
				d.setItem(src.getItem());                      // 계보 키 — 동일 유지
				d.setTitle(title != null ? title : src.getTitle());
				d.setContents(contents != null ? contents : src.getContents());
				d.setReason(reason != null ? reason : src.getReason());
				d.setSearchText(contents != null ? null : src.getSearchText());
				d.setGaejungType(gaejungType);
				d.setDispYn(dispYn);
				d.setSysId(target.getSysId());
				provHtmlService.insertProvHtml(d);             // 채번 + 중복가드 + 단위 분해 재동기
			}

			promWorkService.logAction(promNo, target.getSysId(), "TB_PROV_HTML", String.valueOf(d.getProvHtmlNo()),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_INSERT,
					"HTML조문분기", "HTML 조항 회차 분기 등록 (" + d.getTitle() + ", 원본 provHtmlNo=" + provHtmlNo
							+ ", 유형=" + gaejungType + ")", currentUserId(), currentUserNm());
			res.put("success",    true);
			res.put("provHtmlNo", d.getProvHtmlNo());
			res.put("title",      d.getTitle());
			res.put("updated",    updated);
			res.put("message",    updated ? "이 회차에 이미 분기된 행이 있어 갱신했습니다."
			                              : "이 회차로 개정 분기 등록되었습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "분기 등록 실패: " + e.getMessage());
		}
		return res;
	}

	// ============================================================
	// 1-c) 법령 메타 Ajax 조회 / 저장 (IDE 중앙 편집 폼용)
	// ============================================================

	/** 법령 메타 조회 — TB_PROM 단건의 편집 가능한 메타 필드만 (CLOB 본문 제외) */
	@ResponseBody
	@RequestMapping("/rlms/prom/promFragmentJson.do")
	public Map<String,Object> promFragmentJson(@RequestParam("promNo") Long promNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("found", false);
			res.put("error", "unauthenticated");
			return res;
		}
		try {
			PromVO p = promService.selectPromDetail(promNo);
			if (p == null) { res.put("found", false); return res; }
			res.put("found",      true);
			res.put("promNo",     p.getPromNo());
			res.put("lawId",      p.getLawId());
			res.put("lawNo",      p.getLawNo());
			res.put("sysId",      p.getSysId());
			res.put("title",      p.getTitle());
			res.put("subTitle",   p.getSubTitle());
			res.put("number",     p.getNumber());
			res.put("party",      p.getParty());
			res.put("promDate",   p.getPromDate());
			res.put("startDate",  p.getStartDate());
			res.put("nullDate",   p.getNullDate());
			// 폐지일 변경 승인 대기(SNULL_DT_PEND) — 표시 라벨: 날짜 또는 '(해제)' (2026-07-20)
			String _ndp = p.getNullDatePend() == null ? "" : p.getNullDatePend().trim();
			res.put("nullDatePendLabel", _ndp.isEmpty() ? null : ("--".equals(_ndp) ? "(해제)" : _ndp));
			res.put("url",        p.getUrl());
			res.put("orderIdx",   p.getOrderIdx());
			res.put("cateNo",     p.getCateNo());
			res.put("cateNm",     p.getCateNm());
			res.put("cateFullNm", p.getCateFullNm());
			res.put("gaejungNo",  p.getGaejungNo());
			res.put("gaejungNm",  p.getGaejungNm());
			res.put("buseoNo",    p.getBuseoNo());
			String metaOid = p.getBuseoOrgnztId() == null ? null : p.getBuseoOrgnztId().trim();
			// 레거시 미지정 센티넬(buseoNo=0 파생)은 화면에 빈값으로 — 필수검증이 살아있도록
			if ("ORG_0000000000000000".equals(metaOid)) metaOid = null;
			res.put("orgnztId",   metaOid);
			res.put("buseoNm",    p.getBuseoNm());
			res.put("existingYn", p.getExistingYn());
			// 최신 워크 상태 — 에디터 상태라벨(편집중/승인요청/승인반려) 표시용
			try {
				narainet.rlms.promwork.service.PromWorkVO _lw = promWorkService.selectLatestByPromNo(promNo);
				res.put("workStatus", _lw == null ? null : _lw.getStatus());
				// 반려 사유(SREASON) — 승인반려 시 편집기에 사유 카드 표시용
				res.put("workReason", _lw == null ? null : _lw.getReason());
			} catch (Exception ignore) { res.put("workStatus", null); }
			// #8 B: 실제 편집권한(ADMIN/분류소유자 = assertCanEditProm 과 동일 로직)을 UI 에 내려보내,
			//   편집 못 하는 사용자에게 워크플로/편집/저장 버튼이 보이다 저장 시 '권한없음' 팝업 맞는 불일치를 제거.
			try {
				res.put("canEdit", promEditGuard.canEditProm(promNo));
			} catch (Exception ignore) { res.put("canEdit", false); }
			res.put("dispYn",     p.getDispYn());
			res.put("stsfdgYn",   p.getStsfdgYn());       // 만족도 조사 사용 여부 (SSTSFDG_YN)
			res.put("extDispYn",  p.getExtDispYn());      // 외부 열람 요청 공개 여부 (SEXT_DISP_YN)
			res.put("provFlag",   p.getProvFlag());       // 규정형식 (SPROV_FG)
			res.put("provStyleCd",p.getProvStyleCd());    // 규정형식 스타일 (SPROV_STYLE_CD)
			res.put("provFileNo",    p.getProvFileNo());      // PDF뷰어 참조파일 (SPROV_FILE_NO)
			res.put("relFileViewYn", p.getRelFileViewYn());   // HTML 관련파일 바로열람 (SREL_FILE_VIEW_YN)
			// 본문 CLOB 4종 — 레거시 의 "개정이유 / 주요내용 / 부칙 / 서문" 탭 (CK HTML 원문 그대로)
			res.put("reason",     p.getReason());     // 개정이유 (SREASON)
			res.put("gaejung",    p.getGaejung());    // 주요내용 (SGAEJUNG)
			res.put("bylaw",      p.getBylaw());      // 부칙     (SBYLAW)
			res.put("preamble",   p.getPreamble());   // 서문     (SPREAMBLE)
		} catch (Exception e) {
			res.put("found", false);
			res.put("error", e.getMessage());
		}
		return res;
	}

	/**
	 * 법령 메타 저장 — selectPromDetail 로 기존 vo 를 읽어 메타 필드만 머지 후 updateProm.
	 * CLOB 본문(reason/gaejung/bylaw/preamble/searchText)은 건드리지 않음.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/savePromMeta.do")
	public Map<String,Object> savePromMeta(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false);
			res.put("message", "로그인이 필요합니다.");
			return res;
		}
		try {
			String promNoStr = params.get("promNo");
			boolean isNew = (promNoStr == null || promNoStr.trim().isEmpty());

			PromVO vo;
			if (isNew) {
				// ── 신규 법령 등록 ──
				String cateNoStr = params.get("cateNo");
				if (cateNoStr == null || cateNoStr.trim().isEmpty()) {
					res.put("success", false);
					res.put("message", "분류를 먼저 선택하세요.");
					return res;
				}
				Long cateNo = Long.valueOf(cateNoStr.trim());
				CateVO cate = cateMapper.selectCateByNo(cateNo);
				if (cate == null) {
					res.put("success", false);
					res.put("message", "분류를 찾을 수 없습니다.");
					return res;
				}
				vo = new PromVO();
				vo.setCateNo(cateNo);
				vo.setGubunId(cate.getGubunId());
				// SSYS_ID 는 저장하지 않음(단일 시스템 — 필터 미사용, null 허용)
				vo.setLawId(null);            // 신규 법령 — insertProm 이 lawId/lawNo/seq 채번
				// 개정 회차 등록 (레거시 insertDo 의 pLawId 파리티) — lawId 가 오면 이 법령의 새 회차.
				// 작업중 draft(SEXISTING_YN='N' + 최신워크 편집중/승인요청/승인반려)가 있으면 차단.
				// ★SEXISTING_YN='N' 단독 판정 금지 — 과거 승인본도 전부 'N'이라 다회차 법령의
				//   개정 등록이 영구 차단됐음 (2026-07-09 오탐 교정, selectWorkingDraftLawNos 기준).
				String lawIdStr = params.get("lawId");
				if (lawIdStr != null && !lawIdStr.trim().isEmpty()) {
					Long revLawId = Long.valueOf(lawIdStr.trim());
					List<Long> workingDrafts = promMapper.selectWorkingDraftLawNos(revLawId);
					if (workingDrafts != null && !workingDrafts.isEmpty()) {
						res.put("success", false);
						res.put("message", "작업중(승인 대기) 회차가 이미 있습니다: " + workingDrafts.get(0)
								+ "차. 해당 회차를 승인(또는 삭제)한 뒤 새 연혁을 등록하세요.");
						return res;
					}
					vo.setLawId(revLawId);    // insertProm 이 개정본 분기 처리 (연혁번호 +10, 승인 전 비공개 'N')
				}
				vo.setDispYn("Y");
				vo.setExistingYn("Y");        // 신규는 현행 (개정본이면 insertProm 이 'N' 으로 덮어씀)
			} else {
				// ── 기존 법령 수정 ──
				Long promNo = Long.valueOf(promNoStr.trim());
				vo = promService.selectPromDetail(promNo);
				if (vo == null) {
					res.put("success", false);
					res.put("message", "규정을 찾을 수 없습니다.");
					return res;
				}
			}
			// 작성권한 가드 — 신규=분류 단위 / 기존=규정 단위(승인요청 잠금·소관부서 폴백 포함, 2026-07-20)
			if (vo.getPromNo() == null) {
				promEditGuard.assertCanEditCate(vo.getCateNo());
			} else {
				promEditGuard.assertCanEditProm(vo.getPromNo());
			}
			if (params.containsKey("title"))      vo.setTitle(emptyToNull(params.get("title")));
			if (params.containsKey("subTitle"))   vo.setSubTitle(emptyToNull(params.get("subTitle")));
			// 연혁번호(ILAW_NO) — 사용자가 직접 입력/수정한 값 존중 (비면 insertProm 이 제정10/개정+10 자동)
			if (params.containsKey("lawNo")) {
				String ln = params.get("lawNo");
				if (ln != null && !ln.trim().isEmpty()) {
					try { vo.setLawNo(Long.valueOf(ln.trim())); } catch (NumberFormatException ignore) {}
				}
			}
			// SNUM/SNULL_DT/SURL 등 NOT NULL 컬럼의 빈값 보정은 service(insertProm/updateProm 공용
			// applyNotNullDefaults)에서 일괄 처리 — 여기서는 emptyToNull 로 두고 service 가 기본값을 채운다.
			if (params.containsKey("number"))     vo.setNumber(emptyToNull(params.get("number")));
			if (params.containsKey("party"))      vo.setParty(emptyToNull(params.get("party")));
			if (params.containsKey("promDate"))   vo.setPromDate(emptyToNull(params.get("promDate")));
			if (params.containsKey("startDate"))  vo.setStartDate(emptyToNull(params.get("startDate")));
			if (params.containsKey("nullDate"))   vo.setNullDate(emptyToNull(params.get("nullDate")));
			if (params.containsKey("url"))        vo.setUrl(emptyToNull(params.get("url")));
			if (params.containsKey("orderIdx")) {
				String oi = params.get("orderIdx");
				if (oi != null && !oi.trim().isEmpty()) {
					try { vo.setOrderIdx(Integer.valueOf(oi.trim())); } catch (NumberFormatException ignore) {}
				}
			}
			if (params.containsKey("gaejungNo")) {
				String g = params.get("gaejungNo");
				vo.setGaejungNo((g == null || g.trim().isEmpty()) ? null : Long.valueOf(g.trim()));
			}
			if (params.containsKey("buseoNo")) {
				String b = params.get("buseoNo");
				vo.setBuseoNo((b == null || b.trim().isEmpty()) ? null : Long.valueOf(b.trim()));
			}
			// 소관부서 정본 키 — 표준 조직ID (F1-5 전환. buseoNo 는 레거시 컬럼 호환 파생)
			if (params.containsKey("orgnztId")) {
				String oid = emptyToNull(params.get("orgnztId"));
				// buseoNo=0 파생 센티넬은 미지정과 동치 — 필수검증 우회 차단
				if ("ORG_0000000000000000".equals(oid)) oid = null;
				vo.setBuseoOrgnztId(oid);
			}
			// 필수입력 강제 — 개정구분/소관부서. 폼이 해당 필드를 제출한 경우(또는 신규) 빈값 거부.
			// (applyNotNullDefaults 의 0 디폴트는 비폼 경로용 최후 안전망으로만 남김)
			if ((isNew || params.containsKey("gaejungNo"))
					&& (vo.getGaejungNo() == null || vo.getGaejungNo() <= 0L)) {
				res.put("success", false);
				res.put("message", "개정구분을 선택하세요. (필수)");
				return res;
			}
			if ((isNew || params.containsKey("buseoNo") || params.containsKey("orgnztId"))
					&& (vo.getBuseoNo() == null || vo.getBuseoNo() <= 0L)
					&& vo.getBuseoOrgnztId() == null) {
				res.put("success", false);
				res.put("message", "소관부서를 선택하세요. (필수)");
				return res;
			}
			// 규정형식 (SPROV_FG + SPROV_STYLE_CD) — 신규 등록 시 기본 VERSION/NORMAL
			if (params.containsKey("provFlag"))    vo.setProvFlag(emptyToNull(params.get("provFlag")));
			if (params.containsKey("provStyleCd")) vo.setProvStyleCd(emptyToNull(params.get("provStyleCd")));
			if (params.containsKey("provFileNo"))  vo.setProvFileNo(emptyToNull(params.get("provFileNo")));   // VIEWER 참조파일
			// 링크형식(LINK) — 본문 없이 외부 원문(SURL)으로 연결. URL http(s) 필수.
			if ("LINK".equals(vo.getProvFlag())) {
				String linkUrl = (vo.getUrl() == null) ? "" : vo.getUrl().trim().toLowerCase();
				if (!(linkUrl.startsWith("http://") || linkUrl.startsWith("https://"))) {
					res.put("success", false);
					res.put("message", "링크형식 규정은 URL(http:// 또는 https://)이 필수입니다.");
					return res;
				}
			}
			// 관련파일 바로열람(HTML 형식 체크박스) — 미체크 시 param 자체가 없음 → 'N'. 폼 제출(provFlag 존재) 시에만 갱신.
			if (params.containsKey("provFlag"))    vo.setRelFileViewYn("Y".equals(params.get("relFileViewYn")) ? "Y" : "N");
			if (isNew) {
				if (vo.getProvFlag()    == null) vo.setProvFlag("VERSION");
				if (vo.getProvStyleCd() == null) vo.setProvStyleCd("NORMAL");
			}
			// "이 연혁을 감춥니다" — 체크박스. 체크 = SDISP_YN='N', 미체크 = 'Y'
			vo.setDispYn("N".equals(params.get("dispYn")) ? "N" : "Y");
			// "만족도 조사 사용" — 체크박스. 체크 = SSTSFDG_YN='Y', 미체크 = 'N'
			vo.setStsfdgYn("Y".equals(params.get("stsfdgYn")) ? "Y" : "N");
			// "외부 열람 요청 공개 여부" — 라디오(Y=공개/N=비공개). 작성자가 명시 선택해야 갱신.
			// 미선택 시 기존 값 유지 (신규는 null 그대로).
			String extDispYn = params.get("extDispYn");
			if ("Y".equals(extDispYn) || "N".equals(extDispYn)) {
				vo.setExtDispYn(extDispYn);
			}
			// 본문 CLOB 4종 (개정이유/주요내용/부칙/서문) — 전달된 경우만 갱신
			if (params.containsKey("reason"))   vo.setReason(params.get("reason"));
			if (params.containsKey("gaejung"))  vo.setGaejung(params.get("gaejung"));
			if (params.containsKey("bylaw"))    vo.setBylaw(params.get("bylaw"));
			if (params.containsKey("preamble")) vo.setPreamble(params.get("preamble"));

			if (isNew) {
				promService.insertProm(vo);
			} else {
				promService.updateProm(vo);
			}
			res.put("success", true);
			res.put("promNo",  vo.getPromNo());
			res.put("lawId",   vo.getLawId());   // 저장 후 좌측 연혁목차 트리 갱신용 (신규 등록 시 채번된 lawId)
			res.put("lawNo",   vo.getLawNo());
			res.put("message", isNew ? "등록되었습니다." : "저장되었습니다.");
		} catch (Exception e) {
			res.put("success", false);
			res.put("message", "저장 실패: " + e.getMessage());
		}
		return res;
	}

	private String emptyToNull(String s) {
		return (s == null || s.trim().isEmpty()) ? null : s;
	}


	// ============================================================
	// 1-c-1) 분류이동 — 레거시 "분류이동" 모달 (F2)
	//   · cateOnlyTreeJson : 분류 전용 트리 (법령/회차 노드 제외)
	//   · moveCategoryJson : promNo 의 분류를 newCateNo 로 이동 + JSON 응답
	// ============================================================

	/** 분류 전용 트리 — SGUBUN 그룹 + 분류 노드만 (법령 노드 제외). 분류이동 모달용. */
	@ResponseBody
	@RequestMapping("/rlms/prom/cateOnlyTreeJson.do")
	public List<Map<String,Object>> cateOnlyTreeJson(
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId) {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return new ArrayList<>();
		}
		return buildCateOnlyTree(sysId);
	}

	/**
	 * B4 규정연계 모달용 — 회차(promNo)의 조 leaves 평면 리스트.
	 *  - HTML/FILE_VIEWER 모드: TB_PROV_HTML 행 그대로
	 *  - VERSION 모드: TB_PROV_VRSN 의 BASE_TEXT(조 단위) 누적 평면
	 *  반환 = { ok, promNo, lawId, lawNo, title (규정명), items:[{fullItem, title}] }
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/dmnLnkProvList.do")
	public Map<String,Object> dmnLnkProvList(@RequestParam("promNo") Long promNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("ok", false); res.put("error", "UNAUTHORIZED"); return res;
		}
		PromVO p;
		try { p = promService.selectPromDetail(promNo); }
		catch (Exception e) { res.put("ok", false); res.put("error", "prom.not.found"); return res; }
		if (p == null) { res.put("ok", false); res.put("error", "prom.not.found"); return res; }

		List<Map<String,Object>> items = new ArrayList<>();
		String flag = p.getProvFlag();
		if ("HTML".equalsIgnoreCase(flag) || "VIEWER".equalsIgnoreCase(flag) || "FILE_VIEWER".equalsIgnoreCase(flag)) {
			for (ProvHtmlVO r : provHtmlService.selectProvHtmlList(promNo)) {
				Map<String,Object> it = new LinkedHashMap<>();
				it.put("fullItem", safe(r.getItem()));
				it.put("title",    buildProvHtmlLabel(r));
				items.add(it);
			}
		} else if (p.getLawId() != null && p.getLawNo() != null) {
			List<ProvVrsnVO> jos = provVrsnMapper.selectBaseTextNodes(p.getLawId(), p.getLawNo());
			if (jos != null) for (ProvVrsnVO j : jos) {
				Map<String,Object> it = new LinkedHashMap<>();
				it.put("fullItem", safe(j.getFullItem()));
				it.put("title",    buildProvVrsnJoLabel(j));
				items.add(it);
			}
		}
		res.put("ok",     true);
		res.put("promNo", promNo);
		res.put("lawId",  p.getLawId());
		res.put("lawNo",  p.getLawNo());
		res.put("title",  p.getTitle());
		res.put("items",  items);
		return res;
	}

	/** 회차의 분류 이동 (JSON 응답) — 모달의 [이동하기] 처리. */
	@ResponseBody
	@RequestMapping("/rlms/prom/moveCategoryJson.do")
	public Map<String,Object> moveCategoryJson(
			@RequestParam("promNo") Long promNo,
			@RequestParam("cateNo") Long newCateNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			PromVO p = promService.selectPromDetail(promNo);
			if (p == null) {
				res.put("success", false); res.put("message", "회차를 찾을 수 없습니다."); return res;
			}
			CateVO cate = cateMapper.selectCateByNo(newCateNo);
			if (cate == null) {
				res.put("success", false); res.put("message", "이동할 분류를 찾을 수 없습니다."); return res;
			}
			// 작성권한 가드 — 원본 규정 + 대상 분류 둘 다 (관리자/분류작성자)
			promEditGuard.assertCanEditProm(promNo);
			promEditGuard.assertCanEditCate(newCateNo);
			if (p.getCateNo() != null && p.getCateNo().equals(newCateNo)) {
				res.put("success", false); res.put("message", "이미 같은 분류에 있습니다."); return res;
			}
			promService.moveCategory(promNo, newCateNo);
			res.put("success",   true);
			res.put("promNo",    promNo);
			res.put("oldCateNo", p.getCateNo());
			res.put("oldCateNm", p.getCateNm());
			res.put("newCateNo", newCateNo);
			res.put("newCateNm", cate.getCateNm());
			res.put("message",   "분류를 이동했습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "이동 실패: " + e.getMessage());
		}
		return res;
	}

	// ============================================================
	// 1-c-3) 자동링크 제외범위 (TB_REL_EXCL_LNK) — F3
	//   레거시 "인용링크제외범위수정" 모달. 한 법령(lawId) 의 자동링크 처리 시 제외할
	//   SGUBUN 그룹 / 분류 / 특정 법령 목록을 관리.
	// ============================================================

	/** 한 법령의 제외범위 목록 (gubun + category + leaf 통합). */
	@ResponseBody
	@RequestMapping("/rlms/prom/relExclLnkListJson.do")
	public Map<String,Object> relExclLnkListJson(
			@RequestParam("lawId") Long lawId,
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			List<RelExclLnkVO> list = relExclLnkService.selectExclList(lawId, sysId);
			res.put("success", true);
			res.put("list", list);
		} catch (Exception e) {
			res.put("success", false); res.put("message", "조회 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 제외범위 추가.
	 *  · flag = 'full_text_gubun'    → gubunId 필수
	 *  · flag = 'full_text_category' → cateNo  필수
	 *  · flag = 'full_text_leaf'     → lawId   필수 (제외할 대상 법령 ID)
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/relExclLnkInsertJson.do")
	public Map<String,Object> relExclLnkInsertJson(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		if (!hasEditorRole()) {   // 제외범위 관리 = 편집계 전용 (관련자료 CRUD L5 와 동일 기준, 2026-07-09)
			res.put("success", false); res.put("message", "편집 권한이 필요합니다."); return res;
		}
		try {
			RelExclLnkVO vo = new RelExclLnkVO();
			// SSYS_ID 는 저장하지 않음(단일 시스템 — 필터 미사용, null 허용)
			vo.setExclLawId(parseLongSafe(params.get("exclLawId")));
			vo.setFlag(emptyToNull(params.get("flag")));
			if (vo.getExclLawId() == null || vo.getFlag() == null) {
				res.put("success", false); res.put("message", "exclLawId / flag 가 누락되었습니다."); return res;
			}
			if ("full_text_gubun".equals(vo.getFlag())) {
				vo.setGubunId(emptyToNull(params.get("gubunId")));
				if (vo.getGubunId() == null) {
					res.put("success", false); res.put("message", "gubunId 가 필요합니다."); return res;
				}
			} else if ("full_text_category".equals(vo.getFlag())) {
				vo.setCateNo(parseLongSafe(params.get("cateNo")));
				if (vo.getCateNo() == null) {
					res.put("success", false); res.put("message", "cateNo 가 필요합니다."); return res;
				}
			} else if ("full_text_leaf".equals(vo.getFlag())) {
				vo.setLawId(parseLongSafe(params.get("lawId")));
				if (vo.getLawId() == null) {
					res.put("success", false); res.put("message", "lawId 가 필요합니다."); return res;
				}
			} else {
				res.put("success", false); res.put("message", "지원하지 않는 flag: " + vo.getFlag()); return res;
			}
			Long no = relExclLnkService.insertExcl(vo);
			if (no == null || no == 0L) {
				res.put("success", false); res.put("message", "이미 등록된 제외 항목입니다.");
			} else {
				res.put("success", true);
				res.put("relnkNo", no);
				res.put("message", "추가되었습니다.");
			}
		} catch (Exception e) {
			res.put("success", false); res.put("message", "추가 실패: " + e.getMessage());
		}
		return res;
	}

	/** 제외범위 단건 삭제. */
	@ResponseBody
	@RequestMapping("/rlms/prom/relExclLnkDeleteJson.do")
	public Map<String,Object> relExclLnkDeleteJson(@RequestParam("relnkNo") Long relnkNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		if (!hasEditorRole()) {   // 제외범위 관리 = 편집계 전용 (2026-07-09)
			res.put("success", false); res.put("message", "편집 권한이 필요합니다."); return res;
		}
		try {
			int n = relExclLnkService.deleteByNo(relnkNo);
			res.put("success", n > 0);
			res.put("message", n > 0 ? "삭제되었습니다." : "삭제할 항목이 없습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "삭제 실패: " + e.getMessage());
		}
		return res;
	}

	// ============================================================
	// 1-c-2) (폐지 2026-07-23) 빈 회차 전용 삭제(deletePromIfEmpty) —
	//        "연혁에 조문이 붙어 있어도 삭제" 정책 전환으로 deletePromRevision(2단계 확인)에 통합.
	// ============================================================

	// ============================================================
	// 1-c-4) 연혁 일괄 수정 — 레거시 PromulgationController.multipleUpdate /
	//        multipleUpdateDo / singleDeleteDo / multipleDeleteDo 파리티.
	//   한 규정(lawId)의 전 회차를 표 하나에서 일괄편집:
	//     회차별 개정구분(gaejungNo) / 제명(title) / 감추기(dispYn) /
	//     제·개정번호(number) / 공포일·시행일·폐지일(promDate/startDate/nullDate).
	//   + 행별 단건 삭제(singleDelete) + 규정 전체 삭제(multipleDelete).
	//   저장 경로는 savePromMeta 와 동일(load vo → 메타 머지 → updateProm) 재활용.
	// ============================================================

	/**
	 * 일괄수정 표 데이터 — 한 lawId 의 전 회차 목록(ILAW_NO DESC) + 편집 메타.
	 * 개정구분 옵션은 JSP 가 /rlms/gaejung/selectGaejungJson.do 로 별도 로드.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/promMultiUpdateListJson.do")
	public Map<String,Object> promMultiUpdateListJson(
			@RequestParam(value = "lawId",  required = false) Long lawId,
			@RequestParam(value = "promNo", required = false) Long promNo,
			@RequestParam(value = "sysId",  required = false, defaultValue = "") String sysId) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			// promNo 만 온 경우(법령/회차 노드 진입) lawId 보강
			String effSysId = sysId;
			if (lawId == null && promNo != null) {
				PromVO p = promService.selectPromDetail(promNo);
				if (p != null) { lawId = p.getLawId(); if (p.getSysId() != null) effSysId = p.getSysId(); }
			}
			if (lawId == null) {
				res.put("success", false); res.put("message", "규정을 먼저 선택하세요."); return res;
			}
			List<PromVO> list = promMapper.selectPromListByLawId(lawId, effSysId);
			if (list == null || list.isEmpty()) {
				res.put("success", false); res.put("message", "회차가 없습니다."); return res;
			}
			String lawTitle = null;
			List<Map<String,Object>> rows = new ArrayList<>();
			for (PromVO p : list) {
				if (p.getTitle() != null && !p.getTitle().trim().isEmpty()
						&& (lawTitle == null || "Y".equals(p.getExistingYn()))) {
					lawTitle = p.getTitle().trim();   // 규정명 = 현행(없으면 첫) 회차 제목
				}
				Map<String,Object> m = new LinkedHashMap<>();
				m.put("promNo",     p.getPromNo());
				m.put("lawNo",      p.getLawNo());
				m.put("gaejungNo",  p.getGaejungNo());
				m.put("title",      p.getTitle());
				m.put("number",     p.getNumber() != null ? p.getNumber().trim() : "");
				m.put("dispYn",     p.getDispYn());
				m.put("existingYn", p.getExistingYn());
				m.put("promDate",   normDate(p.getPromDate()));
				m.put("startDate",  normDate(p.getStartDate()));
				m.put("nullDate",   normDate(p.getNullDate()));
				rows.add(m);
			}
			res.put("success",  true);
			res.put("lawId",    lawId);
			res.put("lawTitle", lawTitle != null ? lawTitle : ("규정 " + lawId));
			res.put("rows",     rows);
		} catch (Exception e) {
			res.put("success", false); res.put("message", "조회 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 연혁 정보 일괄수정 — 레거시 multipleUpdateDo 파리티.
	 *  파라미터: promNos="11,12,13" + 회차별 {title_,lawNo_,gaejungNo_,number_,dispYn_,
	 *           promDate_,startDate_,nullDate_}<promNo>.
	 *  각 행은 savePromMeta(기존) 와 동일하게 load vo → 메타 머지 → updateProm.
	 *  전 회차 갱신 후 현행(SEXISTING_YN) 재계산(recomputeExistingAfterBulk).
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/promMultiUpdateDo.do")
	public Map<String,Object> promMultiUpdateDo(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			String csv = params.get("promNos");
			if (csv == null || csv.trim().isEmpty()) {
				res.put("success", false); res.put("message", "수정할 회차가 없습니다."); return res;
			}
			Long lawId = null;
			Long repPromNo = null;   // 감사로그용 대표 회차 (IPROM_NO NOT NULL)
			String sysId = null;   // 단일 시스템 — 강제값 없음(logAction 이 null 처리)

			// 1) 전 행 검증 + 준비 — 제명 누락 등 검증 실패 시 아무것도 쓰지 않고 반환(부분 저장 방지).
			List<PromVO> prepared = new ArrayList<>();
			for (String tok : csv.split(",")) {
				Long pno = parseLongSafe(tok);
				if (pno == null) continue;
				PromVO vo = promService.selectPromDetail(pno);
				if (vo == null) continue;                       // 이미 삭제된 회차 — 건너뜀
				promEditGuard.assertCanEditProm(pno);           // 작성권한 가드(관리자/분류작성자)
				if (lawId == null) lawId = vo.getLawId();
				if (repPromNo == null) repPromNo = pno;
				if (vo.getSysId() != null) sysId = vo.getSysId();

				// 제명(필수) — 레거시 "제명을 입력하세요"
				String title = emptyToNull(params.get("title_" + pno));
				if (title == null) {
					res.put("success", false);
					res.put("message", "제명을 입력하세요. (연혁번호 " + (vo.getLawNo() != null ? vo.getLawNo() : pno) + ")");
					return res;
				}
				boolean titleChanged = !title.equals(vo.getTitle());
				vo.setTitle(title);

				// 연혁번호(ILAW_NO) — 숫자만 반영
				String ln = params.get("lawNo_" + pno);
				if (ln != null && !ln.trim().isEmpty()) {
					try { vo.setLawNo(Long.valueOf(ln.trim())); } catch (NumberFormatException ignore) {}
				}
				// 개정구분
				if (params.containsKey("gaejungNo_" + pno)) {
					String g = params.get("gaejungNo_" + pno);
					vo.setGaejungNo((g == null || g.trim().isEmpty()) ? null : parseLongSafe(g));
				}
				// 제·개정번호(선택)
				if (params.containsKey("number_" + pno)) vo.setNumber(emptyToNull(params.get("number_" + pno)));
				// 감추기 체크박스 — 'N'=숨김, 그 외=표시
				if (params.containsKey("dispYn_" + pno)) {
					vo.setDispYn("N".equals(params.get("dispYn_" + pno)) ? "N" : "Y");
				}
				// 일자 3종 — 빈값은 service applyNotNullDefaults 가 ' '/'--' 센티넬로 보정
				if (params.containsKey("promDate_"  + pno)) vo.setPromDate(emptyToNull(params.get("promDate_"  + pno)));
				if (params.containsKey("startDate_" + pno)) vo.setStartDate(emptyToNull(params.get("startDate_" + pno)));
				if (params.containsKey("nullDate_"  + pno)) vo.setNullDate(emptyToNull(params.get("nullDate_"  + pno)));

				// 제명이 바뀌면 검색텍스트(SSEARCH_TEXT) 재조립 — updateProm 이 비었을 때만 재조립하므로 비운다(레거시 동일)
				if (titleChanged) vo.setSearchText(null);

				prepared.add(vo);
			}
			if (lawId == null || prepared.isEmpty()) {
				res.put("success", false); res.put("message", "유효한 회차가 없습니다."); return res;
			}

			// 2) 적용 — 각 행은 updateProm(@Transactional) 로 개별 원자 저장
			int updated = 0;
			for (PromVO vo : prepared) {
				promService.updateProm(vo);
				updated++;
			}
			// 현행(SEXISTING_YN) 재계산 — 감추기 변경 반영(승인대기 회차는 승격 제외)
			recomputeExistingAfterBulk(lawId, sysId);

			promWorkService.logAction(repPromNo, sysId, "TB_PROM", String.valueOf(lawId),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_UPDATE,
					"연혁일괄수정", "연혁 정보 일괄수정 (" + updated + " 회차, lawId=" + lawId + ")",
					currentUserId(), currentUserNm());

			res.put("success", true);
			res.put("lawId",   lawId);
			res.put("updated", updated);
			res.put("message", "연혁정보가 일괄수정되었습니다. (" + updated + " 회차)");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "일괄수정 실패: " + e.getMessage());
		}
		return res;
	}

	// ────────────────────────────────────────────────────────────────
	// 1-c-5) 규정 일괄 수정 (분류 단위) — 선택 분류의 현행 규정들을 한 표에서 메타 일괄수정 + 정렬순서(드래그).
	//   연혁일괄수정(한 법령의 회차들)과 별개 기능: 한 분류 안 여러 법령의 현행본 대상.
	// ────────────────────────────────────────────────────────────────
	@ResponseBody
	@RequestMapping("/rlms/prom/promCateBulkListJson.do")
	public Map<String,Object> promCateBulkListJson(
			@RequestParam(value = "cateNo", required = false) Long cateNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		if (cateNo == null) {
			res.put("success", false);
			res.put("message", "분류를 먼저 선택하세요.\n좌측 트리에서 분류를 클릭한 뒤 다시 시도하세요.");
			return res;
		}
		try {
			List<PromVO> list = promMapper.selectCurrentPromsByCate(cateNo);
			String cateNm = null;
			List<Map<String,Object>> rows = new ArrayList<>();
			for (PromVO p : list) {
				if (cateNm == null) cateNm = (p.getCateFullNm() != null && !p.getCateFullNm().trim().isEmpty())
						? p.getCateFullNm() : p.getCateNm();
				Map<String,Object> m = new LinkedHashMap<>();
				m.put("promNo",    p.getPromNo());
				m.put("lawId",     p.getLawId());
				m.put("title",     p.getTitle());
				m.put("gaejungNo", p.getGaejungNo());
				m.put("orgnztId",  p.getBuseoOrgnztId());
				m.put("buseoNm",   p.getBuseoNm());
				m.put("dispYn",    p.getDispYn());
				rows.add(m);
			}
			res.put("success",   true);
			res.put("cateNo",    cateNo);
			res.put("cateTitle", cateNm != null ? cateNm : ("분류 " + cateNo));
			res.put("rows",      rows);
		} catch (Exception e) {
			res.put("success", false); res.put("message", "조회 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 규정 일괄수정 저장 — 분류 내 현행 규정들의 메타(제명/개정구분/소관부서/표시) + 정렬순서 일괄 반영.
	 *  파라미터: promNos="11,12,13"(드래그 순서) + 규정별 {title_,gaejungNo_,orgnztId_,dispYn_}&lt;promNo&gt;.
	 *  정렬순서(SORDERIDX) = promNos 순번(1..N). 전 행 검증 후 적용(부분저장 방지). savePromMeta 와 동일 load→merge→updateProm.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/promCateBulkUpdateDo.do")
	public Map<String,Object> promCateBulkUpdateDo(@RequestParam Map<String,String> params) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			String csv = params.get("promNos");
			if (csv == null || csv.trim().isEmpty()) {
				res.put("success", false); res.put("message", "수정할 규정이 없습니다."); return res;
			}
			Long cateNo = null;
			Long repPromNo = null;
			String sysId = null;   // 단일 시스템 — 강제값 없음(logAction 이 null 처리)

			// 1) 전 행 검증 + 준비 (제명/개정구분/소관부서 누락 시 아무것도 쓰지 않고 반환)
			List<PromVO> prepared = new ArrayList<>();
			int order = 1;
			for (String tok : csv.split(",")) {
				Long pno = parseLongSafe(tok);
				if (pno == null) continue;
				PromVO vo = promService.selectPromDetail(pno);
				if (vo == null) continue;                       // 이미 삭제됨
				promEditGuard.assertCanEditProm(pno);           // 작성권한 가드(관리자/분류작성자)
				if (cateNo == null) cateNo = vo.getCateNo();
				if (repPromNo == null) repPromNo = pno;
				if (vo.getSysId() != null) sysId = vo.getSysId();

				String title = emptyToNull(params.get("title_" + pno));
				if (title == null) {
					res.put("success", false);
					res.put("message", "제명을 입력하세요. (규정 " + (vo.getTitle() != null ? vo.getTitle() : pno) + ")");
					return res;
				}
				boolean titleChanged = !title.equals(vo.getTitle());
				vo.setTitle(title);

				if (params.containsKey("gaejungNo_" + pno)) {
					String g = params.get("gaejungNo_" + pno);
					vo.setGaejungNo((g == null || g.trim().isEmpty()) ? null : parseLongSafe(g));
				}
				if (vo.getGaejungNo() == null || vo.getGaejungNo() <= 0L) {
					res.put("success", false);
					res.put("message", "개정구분을 선택하세요. (규정 " + title + ")");
					return res;
				}
				if (params.containsKey("orgnztId_" + pno)) {
					String oid = emptyToNull(params.get("orgnztId_" + pno));
					if ("ORG_0000000000000000".equals(oid)) oid = null;
					vo.setBuseoOrgnztId(oid);
				}
				if (vo.getBuseoOrgnztId() == null && (vo.getBuseoNo() == null || vo.getBuseoNo() <= 0L)) {
					res.put("success", false);
					res.put("message", "소관부서를 선택하세요. (규정 " + title + ")");
					return res;
				}
				if (params.containsKey("dispYn_" + pno)) {
					vo.setDispYn("N".equals(params.get("dispYn_" + pno)) ? "N" : "Y");
				}
				// 정렬순서 = 드래그 순번. 트리(selectActivePromsForTree)·목록은 ISEQ 우선 정렬이므로
				// ISEQ 를 갱신해야 화면 순서가 바뀜. SORDERIDX 도 동일값으로 일관 유지.
				vo.setSeq(order);
				vo.setOrderIdx(order);
				if (titleChanged) vo.setSearchText(null);
				prepared.add(vo);
				order++;
			}
			if (cateNo == null || prepared.isEmpty()) {
				res.put("success", false); res.put("message", "유효한 규정이 없습니다."); return res;
			}

			// 2) 적용 — 각 규정 updateProm(@Transactional) 개별 원자 저장
			int updated = 0;
			for (PromVO vo : prepared) { promService.updateProm(vo); updated++; }

			promWorkService.logAction(repPromNo, sysId, "TB_PROM", String.valueOf(cateNo),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_UPDATE,
					"규정일괄수정", "분류 규정 일괄수정 (" + updated + " 건, cateNo=" + cateNo + ")",
					currentUserId(), currentUserNm());

			res.put("success", true);
			res.put("cateNo",  cateNo);
			res.put("updated", updated);
			res.put("message", "규정정보가 일괄수정되었습니다. (" + updated + " 건)");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "일괄수정 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 연혁 단건 삭제 — 레거시 singleDeleteDo 파리티. 삭제 후 현행 재배치(promService.deleteProm).
	 *  본문/문서/관련자료가 있으면(force!='Y') NOT_EMPTY 로 거부 → 클라이언트가 경고 후 force 재호출.
	 *  (레거시 은 무조건 삭제 + 경고만. RLMS 는 2단계 확인으로 안전망 추가하되 강제 삭제 허용.)
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/deletePromRevision.do")
	public Map<String,Object> deletePromRevision(
			@RequestParam("promNo") Long promNo,
			@RequestParam(value = "force", required = false) String force) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			PromVO p = promService.selectPromDetail(promNo);
			if (p == null) {
				res.put("success", false); res.put("reason", "NOT_FOUND");
				res.put("message", "회차를 찾을 수 없습니다."); return res;
			}
			promEditGuard.assertCanEditProm(promNo);
			if (!"Y".equals(force)) {
				int cnt = promMapper.countDependentRowsByPromNo(promNo);
				if (cnt > 0) {
					res.put("success", false); res.put("reason", "NOT_EMPTY");
					res.put("dependentRows", cnt);
					res.put("message", "이 연혁에는 조문/별표/관련자료 " + cnt + " 건이 있습니다. "
							+ "삭제하면 이 연혁에서 개정된 데이터가 함께 삭제되고, "
							+ "삭제된 조문은 이전 연혁의 최종 조문이 현행으로 승계됩니다.");
					return res;
				}
			}
			String sysId = p.getSysId();
			promService.deleteProm(promNo);   // 트리거 cascade + 현행 재배치
			// IPROM_NO NOT NULL — 삭제된 promNo 로 기록(FK 없음, 감사 이력으로 보존)
			promWorkService.logAction(promNo, sysId, "TB_PROM", String.valueOf(promNo),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_DELETE,
					"연혁삭제", "연혁(회차) 단건 삭제 (" + (p.getLawNo() != null ? p.getLawNo() + "차" : "promNo=" + promNo)
							+ (("Y".equals(force)) ? ", 강제" : "") + ")",
					currentUserId(), currentUserNm());
			res.put("success", true);
			res.put("lawId", p.getLawId());
			res.put("deletedPromNo", promNo);
			res.put("message", "연혁이 삭제되었습니다.");
		} catch (Exception e) {
			res.put("success", false); res.put("reason", "ERROR");
			res.put("message", "삭제 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 규정 전체 삭제 — 레거시 multipleDeleteDo 파리티. 한 lawId 의 모든 회차를 삭제.
	 *  (전체 연혁이 사라지는 비가역 작업 — 클라이언트가 강한 확인을 받은 뒤 호출.)
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/deletePromAll.do")
	public Map<String,Object> deletePromAll(
			@RequestParam("lawId") Long lawId,
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("success", false); res.put("message", "로그인이 필요합니다."); return res;
		}
		try {
			List<PromVO> list = promMapper.selectPromListByLawId(lawId, sysId);
			if (list == null || list.isEmpty()) {
				res.put("success", false); res.put("message", "삭제할 회차가 없습니다."); return res;
			}
			// 작성권한 가드 — 같은 lawId 의 회차는 분류를 공유하므로 대표 1건으로 검사
			promEditGuard.assertCanEditProm(list.get(0).getPromNo());
			String effSysId = list.get(0).getSysId() != null ? list.get(0).getSysId() : sysId;
			String lawTitle = list.get(0).getTitle();
			List<Long> ids = new ArrayList<>();
			for (PromVO p : list) ids.add(p.getPromNo());
			Long repPromNo = ids.get(0);   // IPROM_NO NOT NULL — 대표(삭제됨) 회차로 기록
			promService.deletePromList(ids);   // 각 회차 deleteProm(트리거 cascade)
			promWorkService.logAction(repPromNo, effSysId, "TB_PROM", String.valueOf(lawId),
					narainet.rlms.promwork.service.PromWorkActLogVO.ACT_TYPE_DELETE,
					"규정전체삭제", "규정 전체(전 회차) 삭제 (" + (lawTitle != null ? lawTitle : "") + ", "
							+ ids.size() + " 회차, lawId=" + lawId + ")", currentUserId(), currentUserNm());
			res.put("success", true);
			res.put("lawId", lawId);
			res.put("deletedCount", ids.size());
			res.put("message", "규정 전체가 삭제되었습니다. (" + ids.size() + " 회차)");
		} catch (Exception e) {
			res.put("success", false); res.put("message", "삭제 실패: " + e.getMessage());
		}
		return res;
	}

	/**
	 * 일괄수정 후 현행(SEXISTING_YN) 재계산 — 승인 워크플로 보존형.
	 *  · 현재 현행 회차가 여전히 표시(SDISP_YN≠'N') 상태면 그대로 유지(아무것도 안 함).
	 *  · 현행이 없거나 숨김 처리되었으면: 전체 reset 후 표시 회차 중 최신(ILAW_NO DESC) 1건을 승격.
	 *    단, 최신 워크 상태가 '편집중/승인요청/승인반려'(승인 전)인 회차는 건너뜀(승인 전 비공개 보존).
	 *  레거시 multipleUpdateDo 의 "reset 후 최신 승격" 을 RLMS 승인 워크플로와 양립하도록 보강한 형태.
	 */
	private void recomputeExistingAfterBulk(Long lawId, String sysId) {
		List<PromVO> list = promMapper.selectPromListByLawId(lawId, sysId);   // ILAW_NO DESC
		if (list == null || list.isEmpty()) return;
		PromVO currentExisting = null;
		for (PromVO p : list) {
			if ("Y".equals(p.getExistingYn())) { currentExisting = p; break; }
		}
		// 현행이 살아있고 표시상태면 유지 (대부분의 일괄수정 — 제목/일자만 고침)
		if (currentExisting != null && !"N".equals(currentExisting.getDispYn())) return;
		// 현행 부재/숨김 → 재배치
		promMapper.resetPromExistingByLawId(lawId, sysId);
		for (PromVO p : list) {                  // ILAW_NO DESC = 최신부터
			if ("N".equals(p.getDispYn())) continue;        // 숨김 제외
			if (isPendingApproval(p.getPromNo())) continue; // 승인 전 회차 제외
			promMapper.updatePromExistingYn(p.getPromNo(), "Y");
			return;
		}
	}

	/** 회차의 최신 워크 상태가 '승인 전'(편집중/승인요청/승인반려)이면 true — 현행 승격 제외용. */
	private boolean isPendingApproval(Long promNo) {
		try {
			narainet.rlms.promwork.service.PromWorkVO w = promWorkService.selectLatestByPromNo(promNo);
			if (w == null) return false;
			String s = w.getStatus();
			return narainet.rlms.promwork.service.PromWorkVO.STATUS_REQ_WAIT.equals(s)
				|| narainet.rlms.promwork.service.PromWorkVO.STATUS_REQ_PEND.equals(s)
				|| narainet.rlms.promwork.service.PromWorkVO.STATUS_REQ_DENY.equals(s);
		} catch (Exception e) {
			return false;
		}
	}

	/** 일자 표시 정규화 — 센티넬(' ','--','-')·null 은 빈 문자열로(date input 비움). 그 외 trim. */
	private String normDate(String d) {
		if (d == null) return "";
		String t = d.trim();
		if (t.isEmpty() || "--".equals(t) || "-".equals(t)) return "";
		return t;
	}

	// ============================================================
	// 1-d) 소관부서 선택 모달 — 표준 조직정보(COMTNORGNZTINFO) 검색 (F1-5: TB_BUSEO 폐기)
	// ============================================================

	/**
	 * 부서 검색 JSON — keyword 부분일치, 이름순. limit 500 (전체 부서 포괄).
	 * 정본 키 = orgnztId. buseoNo 는 레거시 컬럼(IBUSEO_NO) 호환용 역파생 — 표준 화면에서
	 * 자체 생성한 부서는 NULL 일 수 있다.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/buseoListJson.do")
	public List<Map<String,Object>> buseoListJson(
			@RequestParam(value = "keyword", required = false) String keyword,
			@RequestParam(value = "sysId",   required = false, defaultValue = "") String sysId) {

		List<Map<String,Object>> out = new ArrayList<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) return out;
		try {
			List<Map<String,Object>> list = promMapper.selectOrgnztList(
					(keyword == null || keyword.trim().isEmpty()) ? null : keyword.trim());
			if (list == null) return out;
			int limit = Math.min(list.size(), 500);   // 전체 부서(현재 271) 포괄 — 규정일괄수정 드롭다운이 누락없이
			for (int i = 0; i < limit; i++) {
				out.add(list.get(i));
			}
		} catch (Exception ignore) { /* 빈 리스트 반환 */ }
		return out;
	}

	// ============================================================
	// 1-d) 관련자료 Ajax 목록 — 우측 패널
	// ============================================================
	//  (레거시 attachListJson.do(TB_ATTACH 직접 조회)는 2026-07-16 폐기 —
	//   SREF_TABLE='TB_PROM'/'TB_PROV_HTML' 행을 쓰는 코드가 없어 구조적 0건.
	//   회차/조항 단위 자료는 모두 TB_REL_VRSN + 8 상세 테이블 경유 = relatedListJson.do 단일 진입점.)

	/**
	 * 우측 패널 "관련자료" 그룹화 목록 — 레거시 식 8 액션 자료의 READ 진입점.
	 *   GET ?promNo=N           → 회차 전체 (SFLAG='PROMULGATION' 또는 NULL)
	 *   GET ?promNo=N&fullItem=… → 한 조항 단위 (SFLAG='PROVISION')
	 * 반환: 카테고리 그룹 배열 [{cateNo, cateTitle, cateSeq, items: [...] }, ...]
	 *   item 안에 stable(TB_REL_FILE/HTML/LNK/...) 와 title/seq/url/relVrsnNo 등 → JSP 가 클릭 라우팅.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/relatedListJson.do")
	public Map<String,Object> relatedListJson(
			@RequestParam("promNo")              Long   promNo,
			@RequestParam(value = "fullItem",   required = false) String fullItem,
			@RequestParam(value = "flag",       required = false) String flag,
			@RequestParam(value = "cumulative", required = false) String cumulative) {

		Map<String,Object> res = new LinkedHashMap<>();
		res.put("promNo",   promNo);
		res.put("fullItem", fullItem);
		res.put("groups",   new ArrayList<Map<String,Object>>());
		// 사용자 뷰어(관련자료 목록)도 호출 — 공개열람 모드면 익명 허용(canReadProm 게이트는 아래 유지)
		if (!narainet.rlms.common.service.PublicFront.viewAllowed() || promNo == null) {
			return res;
		}
		if (!promReadGuard.canReadProm(promNo)) {
			return res;   // 분류별 열람제한
		}
		try {
			List<RelVrsnVO> rows;
			if (fullItem != null && !fullItem.trim().isEmpty()) {
				// flag='DOCUMENT' = 별표/별지서식 단위 (미지정이면 조항 PROVISION)
				rows = relVrsnMapper.selectByPromAndFullItem(promNo, fullItem.trim(),
						"DOCUMENT".equals(flag) ? "DOCUMENT" : null);
			} else if ("Y".equals(cumulative)) {
				// 사용자 뷰어 — 레거시 getContentsList 와 동일한 누적(상속 포함) 목록
				PromVO p = promService.selectPromDetail(promNo);
				if (p != null && p.getLawId() != null && p.getLawNo() != null) {
					// 전면개정류(SDIFF_YN='N') 회차가 있으면 그 이전 자료는 누적 차단 (레거시 파리티)
					Long notDiff = promMapper.selectNotDiffLawNo(p.getLawId(), p.getLawNo());
					rows = relVrsnMapper.selectByPromCumulative(p.getLawId(), p.getLawNo(),
							notDiff == null ? 0L : notDiff);
				} else {
					rows = relVrsnMapper.selectByPromNo(promNo);
				}
			} else {
				rows = relVrsnMapper.selectByPromNo(promNo);
			}

			// 카테고리별 그룹화 — LinkedHashMap 이라 SQL 의 ORDER BY 순서 유지
			LinkedHashMap<String, Map<String,Object>> byCate = new LinkedHashMap<>();
			for (RelVrsnVO r : rows) {
				String cateKey   = r.getCateNo() != null ? String.valueOf(r.getCateNo()) : "_NULL_";
				String cateLabel = pickCateLabel(r);
				Map<String,Object> grp = byCate.get(cateKey);
				if (grp == null) {
					grp = new LinkedHashMap<>();
					grp.put("cateNo",        r.getCateNo());
					grp.put("cateTitle",     cateLabel);
					grp.put("cateSeq",       r.getCateSeq());
					grp.put("isDefault",     isDefaultCateLabel(r));   // JSP 가 회색 표시로 구분
					grp.put("items",         new ArrayList<Map<String,Object>>());
					byCate.put(cateKey, grp);
				}
				@SuppressWarnings("unchecked")
				List<Map<String,Object>> items = (List<Map<String,Object>>) grp.get("items");
				items.add(buildRelItem(r));
			}
			res.put("groups", new ArrayList<>(byCate.values()));
		} catch (Exception e) {
			res.put("error", e.getMessage());
		}
		return res;
	}

	/**
	 * "문서에서 가져오기" — .docx / .hwpx 평문 추출 (DB 미저장, 텍스트만 반환).
	 *   중앙 "버전관리용조문편집" textarea 에 주입 → 사용자가 조문 검토 후 저장.
	 */
	@ResponseBody
	@RequestMapping("/rlms/prom/importDocText.do")
	public Map<String,Object> importDocText(@RequestParam("file") MultipartFile file) {
		Map<String,Object> res = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			res.put("ok", false); res.put("error", "로그인이 필요합니다."); return res;
		}
		if (file == null || file.isEmpty()) {
			res.put("ok", false); res.put("error", "파일이 없습니다."); return res;
		}
		try {
			String name = file.getOriginalFilename();
			String text = docImportService.extractPlainText(name, file.getBytes());
			int lineCnt = text.isEmpty() ? 0 : text.split("\n", -1).length;
			res.put("ok",       true);
			res.put("fileName", name);
			res.put("text",     text);
			res.put("lineCnt",  lineCnt);
		} catch (UnsupportedOperationException ue) {
			res.put("ok", false); res.put("error", ue.getMessage());
		} catch (Exception e) {
			res.put("ok", false); res.put("error", "추출 실패: " + e.getMessage());
		}
		return res;
	}

	private String pickCateLabel(RelVrsnVO r) {
		String title = r.getCateTitle() != null ? r.getCateTitle().trim() : "";
		String name  = r.getCateName()  != null ? r.getCateName().trim()  : "";
		String raw   = !title.isEmpty() ? title : name;
		if (raw.isEmpty())                        return "(분류 미지정)";
		// 디폴트성 라벨은 의미를 명확히 (레거시 임포트 데이터의 IRVCATE_NM DEFAULT 가 의미 불명)
		if ("미선택".equals(raw) || "미설정".equals(raw)) return "(분류 미지정)";
		return raw;
	}

	private boolean isDefaultCateLabel(RelVrsnVO r) {
		if (r.getCateNo() == null) return true;
		String title = r.getCateTitle() != null ? r.getCateTitle().trim() : "";
		String name  = r.getCateName()  != null ? r.getCateName().trim()  : "";
		String raw   = !title.isEmpty() ? title : name;
		return raw.isEmpty() || "미선택".equals(raw) || "미설정".equals(raw);
	}

	private Map<String,Object> buildRelItem(RelVrsnVO r) {
		Map<String,Object> m = new LinkedHashMap<>();
		m.put("relVrsnNo", r.getRelVrsnNo());
		String kind  = stableToKind(r.getStable());
		String title = r.getTitle() != null ? r.getTitle() : "(제목 없음)";
		String url   = r.getUrl();

		// URL 링크(TB_REL_LNK): 마스터 제목은 "(url links)" 그룹라벨이고 실제 제목/URL 은 자식에 있다.
		//   → 패널/뷰어가 '제목'으로 표시하고 클릭되도록 자식 링크로 채운다.
		//   자식 1건이면 그 제목/URL 직접 노출(바로 클릭), 여러 건이면 "제목 외 N건"(클릭 시 상세목록).
		if ("url".equals(kind) && r.getRelVrsnNo() != null) {
			try {
				List<narainet.rlms.related.service.RelLnkVO> lnks = relLnkService.getList(r.getRelVrsnNo());
				if (lnks != null && !lnks.isEmpty()) {
					narainet.rlms.related.service.RelLnkVO first = lnks.get(0);
					String firstTtl = (first.getTitle() != null && !first.getTitle().trim().isEmpty())
							? first.getTitle().trim() : first.getUrl();
					if (lnks.size() == 1) {
						title = firstTtl;
						url   = first.getUrl();
					} else {
						title = firstTtl + " 외 " + (lnks.size() - 1) + "건";
						url   = null;   // 여러 건 — 직접 링크 대신 상세 모달(목록)로 열기
					}
				}
			} catch (Exception ignore) {
				// 자식 조회 실패 시 마스터 제목 유지 (graceful)
			}
		}

		m.put("title",     title);
		m.put("stable",    r.getStable());       // TB_REL_FILE / TB_REL_LNK / TB_REL_HTML / ...
		m.put("kind",      kind);                 // file/url/html/image/orgn/word/dmn — JSP 가 아이콘/액션 분기
		m.put("flag",      r.getFlag());
		m.put("fullItem",  r.getFullItem());
		m.put("url",       url);
		m.put("seq",       r.getSeq());
		m.put("insDt",     r.getInsDt());
		return m;
	}

	/** STABLE → 단순 kind 식별자 (JSP 가 아이콘/클릭 액션을 분기) */
	private String stableToKind(String stable) {
		if (stable == null) return "unknown";
		switch (stable) {
			case "TB_REL_FILE":    return "file";
			case "TB_REL_WORD":    return "word";
			case "TB_REL_ORGN":    return "orgn";
			case "TB_REL_HTML":    return "html";
			case "TB_REL_IMG":     return "image";
			case "TB_REL_LNK":     return "url";
			case "TB_REL_DMN_LNK": return "dmn";
			case "TB_REL_HB_TML":  return "hbtml";
			default:               return "unknown";
		}
	}

	// ============================================================
	// 2) 규정분류 / 연혁목차 트리 JSON (jsTree 호환) — 레거시 트리 계층 1:1
	//    - id=# 또는 빈값        : 분류 전체 트리 + 분류별 법령 (한 방)
	//    - id=prom:N             : 회차 N 의 콘텐츠 타입 = [📁조문, 📁별표/별지서식]
	//    - id=provgrp:N          : "조문" 그룹 → 장 노드 (또는 조 평면 / TB_PROV_HTML 평면)
	//    - id=grp:N:FULLITEM:LV  : 장/절 노드의 직속 자식 (절 + 조)
	//    - id=docgrp:N           : "별표/별지서식" 그룹 → TB_DOCU 누적 (buildDocumentGroup, 레거시 DocumentService.getSelectSql)
	//    (레거시 AjaxFullTextController.getManageContentsTypeList / getManageProvisionVersionList)
	// ============================================================

	@ResponseBody
	@RequestMapping("/rlms/prom/treeJson.do")
	public List<Map<String,Object>> treeJson(
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId,
			@RequestParam(value = "id",    required = false, defaultValue = "#")   String id) {

		// (a) 회차 노드 클릭 → 콘텐츠 타입 [조문, 별표/별지서식] — 열람제한 차단 회차는 빈 응답.
		//     미승인 draft 는 비편집계에 빈 응답 (front 비노출 정합, 2026-07-09)
		if (id != null && id.startsWith("prom:")) {
			Long pn = parseLongAfterColon(id);
			if (!promReadGuard.canReadProm(pn)) return new ArrayList<>();
			if (!hasEditorRole() && promService.isWorkingDraftProm(pn)) return new ArrayList<>();
			return buildContentTypeNodes(pn);
		}

		// (b) "조문" 그룹 → 조항 트리 1단계 (장 / 조 평면 / HTML 평면)
		if (id != null && id.startsWith("provgrp:")) {
			Long pn = parseLongAfterColon(id);
			if (!promReadGuard.canReadProm(pn)) return new ArrayList<>();
			if (!hasEditorRole() && promService.isWorkingDraftProm(pn)) return new ArrayList<>();
			return buildProvisionGroup(pn);
		}

		// (c) 장/절 노드 클릭 → 직속 자식 (절 + 조)
		if (id != null && id.startsWith("grp:")) {
			String[] parts = id.split(":", 4);   // grp : lawId : lawNo : fullItem
			Long lawId      = parseLongSafe(parts.length > 1 ? parts[1] : null);
			Long lawNo      = parseLongSafe(parts.length > 2 ? parts[2] : null);
			String fullItem = parts.length > 3 ? parts[3] : null;
			if (!promReadGuard.canReadLaw(lawId)) return new ArrayList<>();
			return buildGroupChildren(lawId, lawNo, fullItem);
		}

		// (d) "별표/별지서식" 그룹 → TB_DOCU 누적 (buildDocumentGroup. 편집=docuFragment/save/insert/branch, 뷰어=renderDocuSection)
		if (id != null && id.startsWith("docgrp:")) {
			Long pn = parseLongAfterColon(id);
			if (!promReadGuard.canReadProm(pn)) return new ArrayList<>();
			if (!hasEditorRole() && promService.isWorkingDraftProm(pn)) return new ArrayList<>();
			return buildDocumentGroup(pn);
		}

		// (e) 루트 → 분류 트리 + 법령 한 방 (승인된 현행만 — front 드로어 공용).
		//     분류별 열람제한(TB_CATE_READER) 차단 분류/규정은 숨김 (면제역할=빈 집합이라 무영향).
		//     삭제분류 규정('(미분류)' 폴백)은 편집계 트리 전용 — front 는 목록/검색의
		//     excludeDeletedCate 게이트와 정합되게 비노출(2026-07-08 사용자 확정).
		//     ★튜닝(2026-07-24): 무차단 전체 트리를 메모리 캐시(FrontTreeCache, TTL 60s+승인/삭제 무효화)
		//       하고, 사용자별 열람제한은 캐시본에서 차단 분류 서브트리만 가지치기한 사본으로 응답.
		return frontTreeCached(sysId);
	}

	/** front 루트 트리 — 캐시 적재/재사용 + 사용자별 차단 분류 가지치기 */
	private List<Map<String,Object>> frontTreeCached(String sysId) {
		// 단일 시스템(sysId 상시 공백)이 캐시 전제 — 비공백 sysId 우회 호출은 캐시 미적용(정확성 우선)
		if (sysId != null && !sysId.isEmpty()) {
			return buildCateTree(sysId, false, false, promReadGuard.blockedCateNos());
		}
		List<Map<String,Object>> full = narainet.rlms.prom.service.FrontTreeCache.get();
		if (full == null) {
			full = buildCateTree("", false, false, java.util.Collections.<Long>emptySet());
			narainet.rlms.prom.service.FrontTreeCache.put(full);
		}
		Set<Long> blocked = promReadGuard.blockedCateNos();
		if (blocked == null || blocked.isEmpty()) {
			return full;   // 무차단(면제역할·제한 미설정) — 캐시본 그대로 직렬화(읽기 전용)
		}
		return pruneBlockedCates(full, blocked);
	}

	/**
	 * 캐시본은 불변 유지 — 차단 분류(cate:N ∈ blocked) 서브트리를 제외한 사본을 만들어 반환.
	 * 규정(prom) 잎은 소속 분류 노드 아래에만 있으므로 분류 가지치기로 함께 숨겨진다.
	 * 가지치기로 자식이 빈 구분(gubun) 그룹은 빌더와 동일하게 제거.
	 */
	@SuppressWarnings("unchecked")
	private List<Map<String,Object>> pruneBlockedCates(List<Map<String,Object>> nodes, Set<Long> blocked) {
		List<Map<String,Object>> out = new ArrayList<>(nodes.size());
		for (Map<String,Object> n : nodes) {
			Object id = n.get("id");
			if (id instanceof String && ((String) id).startsWith("cate:")) {
				Long no = parseLongSafe(((String) id).substring(5));
				if (no != null && blocked.contains(no)) continue;   // 차단 분류 — 서브트리째 제외
			}
			Object kids = n.get("children");
			if (kids instanceof List) {
				List<Map<String,Object>> pruned = pruneBlockedCates((List<Map<String,Object>>) kids, blocked);
				if ("gubun".equals(n.get("type")) && pruned.isEmpty()) continue;   // 빈 그룹 — 빌더 동작 보존
				Map<String,Object> copy = new LinkedHashMap<>(n);
				copy.put("children", pruned);
				out.add(copy);
			} else {
				out.add(n);   // 잎(prom 등) — 캐시 원소 공유(읽기 전용)
			}
		}
		return out;
	}

	/** front 부서별 트리(2026-07-24) — 현행 규정을 소관부서로 그룹. 잎 노드 형식은 전문분류
	 *  트리와 동일(lvBuildNodes 계약: data.promNo/pending). 열람제한은 규정 단위 집합
	 *  (blockedPromNos — 기능별분류 트리와 동일 방식)으로 가지치기. 부서 미지정은 말미 그룹.
	 *  URL 은 treeJson 접두 유지 — context-security 의 '/rlms/prom/(treeJson|…).*' 허용 패턴에 편승. */
	@ResponseBody
	@RequestMapping("/rlms/prom/treeJsonDept.do")
	public List<Map<String,Object>> deptTreeJson() {
		Set<Long> blocked = promReadGuard.blockedPromNos();
		List<PromVO> proms = promMapper.selectActivePromsForDeptTree();
		Map<String, List<Map<String,Object>>> groups = new LinkedHashMap<>();
		if (proms != null) {
			for (PromVO p : proms) {
				if (p == null || p.getPromNo() == null) continue;
				if (blocked.contains(p.getPromNo())) continue;
				String dept = (p.getBuseoNm() == null || p.getBuseoNm().trim().isEmpty())
						? "부서 미지정" : p.getBuseoNm().trim();
				Map<String,Object> leaf = new LinkedHashMap<>();
				leaf.put("id", "prom:" + p.getPromNo());
				leaf.put("text", p.getTitle());
				leaf.put("data", buildPromData(p));
				List<Map<String,Object>> bucket = groups.get(dept);
				if (bucket == null) { bucket = new ArrayList<>(); groups.put(dept, bucket); }
				bucket.add(leaf);
			}
		}
		List<Map<String,Object>> out = new ArrayList<>(groups.size());
		for (Map.Entry<String, List<Map<String,Object>>> e : groups.entrySet()) {
			Map<String,Object> folder = new LinkedHashMap<>();
			folder.put("id", "dept:" + out.size());
			folder.put("text", e.getKey() + " (" + e.getValue().size() + ")");
			folder.put("children", e.getValue());
			out.add(folder);
		}
		return out;
	}

	/** 편집계 화면(IDE/미리보기) 전용 트리 — front(treeJson, 현행만)와 URL 로 화면을 구분.
	 *  루트에 draft-only 법령(승인 전 신규 연혁 등)도 일반 노드로 포함(마커 없음).
	 *  서버측 역할 게이트(편집계 아님 → 현행만 폴백)가 실제 방어선. */
	@ResponseBody
	@RequestMapping("/rlms/prom/editorTreeJson.do")
	public List<Map<String,Object>> editorTreeJson(
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId,
			@RequestParam(value = "id",    required = false, defaultValue = "#")   String id) {
		if (id != null && !"#".equals(id)) {
			return treeJson(sysId, id);   // 하위 노드(prom:/provgrp:/grp:/docgrp:)는 공용 로직
		}
		// 편집계 역할이면 blockedCateNos()가 빈 집합(면제) — 비편집계가 우회 호출해도 열람제한 유지.
		// '(미분류)' 폴백(삭제분류 규정의 발견·재분류 입구)도 편집계 역할에만 노출.
		boolean editor = hasEditorRole();
		return buildCateTree(sysId, editor, editor, promReadGuard.blockedCateNos());
	}

	/** 편집계 역할(EDITOR/APPROVER/ADMIN) 보유 여부 — 트리 draft 노출 게이트. */
	private boolean hasEditorRole() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN")
				|| auths.contains("ROLE_EDITOR") || auths.contains("ROLE_APPROVER"));
	}

	/** IDE 좌측 '작업중(draft)' 패널 — 미승인 draft 회차 목록.
	 *  분류 트리는 현행(SEXISTING_YN='Y')만 실어 편집중 draft 재발견이 안 되는 갭의 IDE 내 진입점.
	 *  항목 클릭 → loadPromForm(promNo) (딥링크와 동일 경로, SEXISTING 검사 없음). */
	@ResponseBody
	@RequestMapping("/rlms/prom/draftListJson.do")
	public List<Map<String, Object>> draftListJson() {
		// 인증 + 편집계 역할 — 전 draft 목록은 편집계 전용 (URL층 단독 의존 해소, 2026-07-09)
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated()) || !hasEditorRole()) {
			return new ArrayList<>();
		}
		return promMapper.selectDraftPromsForPanel();
	}

	// ============================================================
	// 3) 연혁목차 트리 JSON — 법령(정관) 루트 → 회차들 → [조문, 별표] (레거시 1:1)
	// ============================================================

	@ResponseBody
	@RequestMapping("/rlms/prom/historyJson.do")
	public List<Map<String,Object>> historyJson(
			@RequestParam(value = "sysId", required = false, defaultValue = "") String sysId,
			@RequestParam(value = "lawId", required = false) Long lawId) {

		List<Map<String,Object>> roots = new ArrayList<>();
		if (lawId == null) return roots;

		List<PromVO> versions = promMapper.selectPromListByLawId(lawId, sysId);
		if (versions == null || versions.isEmpty()) return roots;
		// 분류별 열람제한 — 규정(법령) 단위 판정 (차단이면 연혁목차 미제공)
		if (!promReadGuard.canRead(versions.get(0))) return roots;

		// 회차 노드들 (펼치면 [📁조문, 📁별표/별지서식] lazy)
		// 비편집계(USER)는 작업중 draft 회차 비노출 — 목록/검색의 excludeUnapprovedDraft 와 정합 (2026-07-09)
		boolean editorRole = hasEditorRole();
		String lawTitle = null;
		List<Map<String,Object>> versNodes = new ArrayList<>();
		for (PromVO v : versions) {
			if (!editorRole && isWorkingDraft(v)) continue;
			if (v.getTitle() != null && !v.getTitle().isEmpty()
					&& (lawTitle == null || "Y".equals(v.getExistingYn()))) {
				lawTitle = v.getTitle();   // 법령 제목 = 현행(없으면 첫) 회차의 제목
			}
			Map<String,Object> node = new LinkedHashMap<>();
			node.put("id",   "prom:" + v.getPromNo());
			node.put("text", buildPromVersionLabel(v));
			node.put("type", "prom");
			// 회차 노드 data — 공통 buildPromData + 개정문(개정이유/주요내용/시행일).
			//   ★buildPromData 공통 헬퍼 본체는 건드리지 않는다(분류트리 selectActivePromsForTree 가
			//     같은 헬퍼를 써서 전체 규정 CLOB 가 실리면 트리 JSON 이 비대해짐). 회차 노드(소량)에만 추가. (#14)
			Map<String,Object> data = buildPromData(v);
			data.put("reason",    v.getReason());
			data.put("gaejung",   v.getGaejung());
			data.put("startDate", v.getStartDate());
			data.put("workStatus",   v.getWorkStatus());
			data.put("workingDraft", isWorkingDraft(v));   // 개정등록 차단(클라) 판정용
			node.put("data", data);
			node.put("children", true);
			versNodes.add(node);
		}
		if (versNodes.isEmpty()) return roots;   // draft-only 법령 — 비편집계엔 루트도 미노출
		if (lawTitle == null) lawTitle = "규정 " + lawId;

		// 법령(정관) 루트 노드 — 레거시 트리의 최상위
		Map<String,Object> lawNode = new LinkedHashMap<>();
		lawNode.put("id",   "law:" + lawId);
		lawNode.put("text", lawTitle);
		lawNode.put("type", "law");
		Map<String,Object> st = new LinkedHashMap<>(); st.put("opened", true);
		lawNode.put("state", st);
		lawNode.put("children", versNodes);   // 회차들 인라인 (개수 적음)
		roots.add(lawNode);
		return roots;
	}

	/** 작업중 draft 판정 — SEXISTING_YN='N' + 최신 워크상태 편집중/승인요청/승인반려 (selectWorkingDraftLawNos 와 동일 기준) */
	private static boolean isWorkingDraft(PromVO v) {
		if (!"N".equals(v.getExistingYn())) return false;
		String s = v.getWorkStatus();
		return "편집중".equals(s) || "승인요청".equals(s) || "승인반려".equals(s);
	}

	/**
	 * 개정문 패널(사용자 전문뷰어) — 한 회차의 개정구분/개정일자/시행일자 + 개정이유·주요내용·부칙·서문.
	 * 레거시 frontGaejungView 이식. CLOB(부칙·서문 포함)은 단건만 로드 → 연혁목록(historyJson)을 경량 유지.
	 * reason/gaejung/bylaw/preamble 은 관리자 작성 HTML CLOB — 뷰어가 그대로 렌더(빈 값은 클라 폴백).
	 */
	@RequestMapping("/rlms/prom/gaejungJson.do")
	@ResponseBody
	public Map<String,Object> gaejungJson(@RequestParam(value = "promNo", required = false) Long promNo) {
		Map<String,Object> res = new LinkedHashMap<>();
		PromVO p = (promNo != null) ? promService.selectPromDetail(promNo) : null;
		if (p == null || !promReadGuard.canRead(p)) { res.put("ok", false); return res; }
		res.put("ok",        true);
		res.put("promNo",    p.getPromNo());
		res.put("title",     p.getTitle());
		res.put("gaejungNm", p.getGaejungNm());
		res.put("promDate",  p.getPromDate());
		res.put("startDate", p.getStartDate());
		res.put("reason",    p.getReason());     // 개정이유 (SREASON)
		res.put("gaejung",   p.getGaejung());    // 주요내용 (SGAEJUNG)
		res.put("bylaw",     p.getBylaw());      // 부칙     (SBYLAW)
		res.put("preamble",  p.getPreamble());   // 서문/전문(SPREAMBLE)
		return res;
	}

	// ============================================================
	// 트리 빌더
	// ============================================================

	private static final String SGUBUN_CODE_ID = "SGUBUN";

	/**
	 * SGUBUN_ID → 표시 라벨/정렬 동적 조회 (ccm 패러다임).
	 * COMTCCMMNDETAILCODE WHERE CODE_ID='SGUBUN' ORDER BY CODE_DC.
	 * 운영팀이 CODE_DC prefix '01_/02_/...' 로 순서 관리.
	 * 결과 LinkedHashMap 의 entry 순서가 그룹 표시 순서가 됨.
	 */
	private Map<String,String> loadGubunLabels() {
		Map<String,String> labels = new LinkedHashMap<>();
		try {
			List<Map<String,Object>> rows = cmmnCodeMapper.selectCmmnCodeList(SGUBUN_CODE_ID);
			for (Map<String,Object> r : rows) {
				String code   = (String) r.get("code");     // 'FT_GUBUN_1' 등
				String codeNm = (String) r.get("codeNm");   // '사규' 등
				if (code != null) labels.put(code, codeNm != null ? codeNm : code);
			}
		} catch (Exception e) {
			labels.clear();
		}
		return labels;
	}

	/** 숨김 구분(ccm SGUBUN USE_AT='N') 집합 — 분류관리 화면 외 전 트리에서 그 구분·소속
	 *  분류/규정을 통째 비노출(역할 면제 없음 — 열람제한과 다른 전역 스위치, 2026-07-09 사용자 확정).
	 *  ccm 미등록 SGUBUN_ID(레거시 잔재)는 숨김 아님 — 기존 폴백 그룹 노출 유지. */
	private Set<String> loadHiddenGubuns() {
		Set<String> hidden = new java.util.HashSet<>();
		try {
			for (Map<String,Object> r : cmmnCodeMapper.selectCmmnCodeListAll(SGUBUN_CODE_ID)) {
				if ("N".equals(r.get("useAt")) && r.get("code") != null) {
					hidden.add(String.valueOf(r.get("code")));
				}
			}
		} catch (Exception ignore) { }
		return hidden;
	}

	/**
	 * 분류 트리(CONNECT BY 결과) + 분류별 법령 → SGUBUN_ID 가상 그룹 → jsTree 노드.
	 * 라벨/순서는 ccm(COMTCCMMNDETAILCODE, CODE_ID='SGUBUN') 에서 동적 조회.
	 */
	/**
	 * 분류 전용 트리 빌더 — buildCateTree 의 변형. SGUBUN 그룹 + 분류 노드만, 법령(prom) 노드 제외.
	 * 분류이동 모달 등 분류 선택 전용 UI 용.
	 */
	private List<Map<String,Object>> buildCateOnlyTree(String sysId) {
		List<CateVO> cates = cateMapper.selectCateTree(sysId, false);
		Map<String,String> gubunLabels = loadGubunLabels();
		Set<String> hiddenGubuns = loadHiddenGubuns();

		Map<String, Map<String,Object>> gubunMap = new LinkedHashMap<>();
		for (Map.Entry<String,String> e : gubunLabels.entrySet()) {
			gubunMap.put(e.getKey(), newGubunNode(e.getKey(), e.getValue()));
		}

		Map<Long, Map<String,Object>> nodeMap = new LinkedHashMap<>();
		for (CateVO c : cates) {
			if (c.getGubunId() != null && hiddenGubuns.contains(c.getGubunId())) {
				continue;   // 숨김 구분 — 분류이동 대상에서도 제외
			}
			Map<String,Object> node = new LinkedHashMap<>();
			node.put("id",   "cate:" + c.getCateNo());
			node.put("text", c.getCateNm());
			node.put("type", "cate");
			node.put("children", new ArrayList<Map<String,Object>>());
			Map<String,Object> state = new LinkedHashMap<>();
			state.put("opened", c.getLevel() != null && c.getLevel() <= 1);
			node.put("state", state);
			nodeMap.put(c.getCateNo(), node);

			Long parent = c.getRef();
			if (parent == null || parent == 0L) {
				String gubun = c.getGubunId() != null ? c.getGubunId() : "_NULL_";
				attachToGubun(gubunMap, gubun, gubunLabels, node);
			} else {
				Map<String,Object> parentNode = nodeMap.get(parent);
				if (parentNode != null) {
					@SuppressWarnings("unchecked")
					List<Map<String,Object>> kids = (List<Map<String,Object>>) parentNode.get("children");
					kids.add(node);
				} else {
					String gubun = c.getGubunId() != null ? c.getGubunId() : "_NULL_";
					attachToGubun(gubunMap, gubun, gubunLabels, node);
				}
			}
		}

		List<Map<String,Object>> roots = new ArrayList<>();
		for (Map<String,Object> g : gubunMap.values()) {
			@SuppressWarnings("unchecked")
			List<Map<String,Object>> kids = (List<Map<String,Object>>) g.get("children");
			if (kids != null && !kids.isEmpty()) roots.add(g);
		}
		return roots;
	}

	/** blockedCates = 분류별 열람제한(TB_CATE_READER)으로 현재 사용자가 볼 수 없는 분류 집합.
	 *  차단 분류는 폴더 노드 자체를 생성하지 않고, 그 분류의 규정 leaf 도 싣지 않는다
	 *  (leaf 스킵을 빠뜨리면 '(미분류)' 폴백으로 새어나가므로 반드시 쌍으로 처리).
	 *  상속(INHERIT_YN='Y') 차단은 SQL 이 자손 분류까지 집합에 넣어주므로 여기선 개별 판정만.
	 *  비상속 차단 분류의 공개 하위분류는 부모 노드 부재 → 기존 gubun 루트 승격 경로로 계속 노출(의도).
	 *  includeOrphans: 삭제/누락 분류 규정의 '(미분류)' 폴백 노출 여부 — 편집계 트리만 true(2026-07-08). */
	private List<Map<String,Object>> buildCateTree(String sysId, boolean includeDrafts, boolean includeOrphans, Set<Long> blockedCates) {

		List<CateVO> cates  = cateMapper.selectCateTree(sysId, false);
		List<PromVO> proms  = promMapper.selectActivePromsForTree(sysId);
		if (includeDrafts) {
			// 편집계 트리 전용 — 현행 회차가 없어 트리에서 사라지던 draft-only 법령(승인 전 신규 연혁 등)을
			// 일반 노드로 합류(마커 없음 — 상태는 작업중 탭/승인목록에서 관리). front 는 현행만 유지.
			proms = new ArrayList<>(proms);
			proms.addAll(promMapper.selectDraftOnlyPromsForTree());
		}
		Map<String,String> gubunLabels = loadGubunLabels();
		Set<String> hiddenGubuns = loadHiddenGubuns();

		// 분류별 법령 그룹화 — 숨김 구분의 규정은 여기서 제외('(미분류)' 폴백 유출 방지 포함)
		Map<Long, List<PromVO>> promsByCate = new HashMap<>();
		for (PromVO p : proms) {
			if (p.getCateNo() == null) continue;
			if (p.getGubunId() != null && hiddenGubuns.contains(p.getGubunId())) continue;
			promsByCate.computeIfAbsent(p.getCateNo(), k -> new ArrayList<>()).add(p);
		}

		// 그룹 순서 보존을 위해 라벨 순서대로 그룹 노드 미리 생성
		Map<String, Map<String,Object>> gubunMap = new LinkedHashMap<>();
		for (Map.Entry<String,String> e : gubunLabels.entrySet()) {
			gubunMap.put(e.getKey(), newGubunNode(e.getKey(), e.getValue()));
		}

		// 분류 노드 생성 + 트리 연결
		Map<Long, Map<String,Object>> nodeMap = new LinkedHashMap<>();
		for (CateVO c : cates) {
			if (blockedCates.contains(c.getCateNo())) {
				continue;   // 열람제한 차단 분류 — 폴더 미생성 (상속 차단은 자손도 집합에 포함됨)
			}
			if (c.getGubunId() != null && hiddenGubuns.contains(c.getGubunId())) {
				continue;   // 숨김 구분 — 편집계 포함 전 트리 비노출(분류관리 화면만 예외)
			}
			Map<String,Object> node = new LinkedHashMap<>();
			node.put("id",   "cate:" + c.getCateNo());
			node.put("text", c.getCateNm());
			node.put("type", "cate");
			node.put("children", new ArrayList<Map<String,Object>>());
			Map<String,Object> state = new LinkedHashMap<>();
			state.put("opened", c.getLevel() != null && c.getLevel() <= 1);
			node.put("state", state);
			nodeMap.put(c.getCateNo(), node);

			Long parent = c.getRef();
			if (parent == null || parent == 0L) {
				// 최상위 분류 → SGUBUN_ID 가상 그룹 아래로
				String gubun = c.getGubunId() != null ? c.getGubunId() : "_NULL_";
				attachToGubun(gubunMap, gubun, gubunLabels, node);
			} else {
				Map<String,Object> parentNode = nodeMap.get(parent);
				if (parentNode != null) {
					@SuppressWarnings("unchecked")
					List<Map<String,Object>> kids = (List<Map<String,Object>>) parentNode.get("children");
					kids.add(node);
				} else {
					String gubun = c.getGubunId() != null ? c.getGubunId() : "_NULL_";
					attachToGubun(gubunMap, gubun, gubunLabels, node);
				}
			}
		}

		// 분류 노드 아래에 법령 노드 추가 — 규정분류 탭은 "메타까지만" leaf 처리.
		// 본문 구조(조문/별표 → 장 → 조) 는 연혁목차 탭(historyJson)에서만 표시.
		// 정관(prom) 클릭 시 ideOnSelectNode 가 연혁목차 탭으로 자동 전환하므로,
		// 분류 탭 prom 노드는 children:false 로 더 이상 lazy load 시도하지 않음.
		// 분류 노드가 없는(=삭제/누락 분류) 규정은 '(미분류)' 폴백으로 수집 — 편집계 트리(includeOrphans) 전용.
		//   front 트리는 비노출: 삭제분류 규정은 목록/검색(excludeDeletedCate 게이트)과 정합되게 숨김(2026-07-08 사용자 확정).
		List<Map<String,Object>> orphanProms = new ArrayList<>();
		for (Map.Entry<Long, List<PromVO>> e : promsByCate.entrySet()) {
			if (blockedCates.contains(e.getKey())) {
				continue;   // 열람제한 차단 분류의 규정 — '(미분류)' 폴백 유출 방지 포함
			}
			Map<String,Object> parentNode = nodeMap.get(e.getKey());
			if (parentNode == null && !includeOrphans) {
				continue;   // front: 삭제/누락 분류 규정 비노출
			}
			@SuppressWarnings("unchecked")
			List<Map<String,Object>> kids = (parentNode != null)
					? (List<Map<String,Object>>) parentNode.get("children")
					: orphanProms;   // 분류 노드 없음 → 미분류 폴백(편집계)
			for (PromVO p : e.getValue()) {
				Map<String,Object> pn = new LinkedHashMap<>();
				pn.put("id",       "prom:" + p.getPromNo());
				pn.put("text",     buildPromTitleLabel(p));
				pn.put("type",     "prom");
				pn.put("data",     buildPromData(p));
				pn.put("children", false);   // leaf — 분류 탭은 메타까지
				kids.add(pn);
			}
		}

		// 자식 없는 그룹은 트리에서 제외 (운영중 분류가 0개인 그룹)
		List<Map<String,Object>> roots = new ArrayList<>();
		for (Map<String,Object> g : gubunMap.values()) {
			@SuppressWarnings("unchecked")
			List<Map<String,Object>> kids = (List<Map<String,Object>>) g.get("children");
			if (kids != null && !kids.isEmpty()) roots.add(g);
		}

		// '(미분류)' 폴백 그룹 — 삭제/누락 분류에 매달린 현행 규정을 편집계 트리에서 찾을 수 있게 맨 끝에(발견·재분류 입구).
		if (!orphanProms.isEmpty()) {
			orphanProms.sort((a, b) -> String.valueOf(a.get("text")).compareTo(String.valueOf(b.get("text"))));
			Map<String,Object> orphanGrp = newGubunNode("_ORPHAN_", "(미분류)");
			orphanGrp.put("children", orphanProms);
			@SuppressWarnings("unchecked")
			Map<String,Object> gst = (Map<String,Object>) orphanGrp.get("state");
			gst.put("opened", false);   // 규정이 많을 수 있어 기본 접힘 (검색으로 도달)
			roots.add(orphanGrp);
		}
		return roots;
	}

	private void attachToGubun(Map<String, Map<String,Object>> gubunMap,
			String gubun, Map<String,String> labels, Map<String,Object> node) {
		Map<String,Object> gnode = gubunMap.get(gubun);
		if (gnode == null) {
			// 공통코드에 미등록된 SGUBUN_ID → 폴백 그룹 노드 (코드 그대로 라벨)
			gnode = newGubunNode(gubun, labels.getOrDefault(gubun, gubun));
			gubunMap.put(gubun, gnode);
		}
		@SuppressWarnings("unchecked")
		List<Map<String,Object>> gkids = (List<Map<String,Object>>) gnode.get("children");
		gkids.add(node);
	}

	private Map<String,Object> newGubunNode(String gubun, String label) {
		Map<String,Object> g = new LinkedHashMap<>();
		g.put("id",   "gubun:" + gubun);
		g.put("text", label);
		g.put("type", "gubun");
		g.put("children", new ArrayList<Map<String,Object>>());
		Map<String,Object> gstate = new LinkedHashMap<>();
		gstate.put("opened", true);  // 그룹은 기본 펼침
		g.put("state", gstate);
		return g;
	}

	// SFULL_ITEM(STYLE_NORMAL): 5자 × 12단계 = 60자. ILEVEL: 1편 2장 3절 4관 5목 6조(BASE_TEXT).

	/**
	 * 회차 노드의 콘텐츠 타입 = [📁조문, 📁별표/별지서식] — 레거시 getManageContentsTypeList 이식.
	 * (레거시 트리: 법령 → 회차 → {조문, 별표/별지서식} → 장 → (절) → 조)
	 * "조문" 은 기본 펼침 — 레거시 화면도 펼쳐진 상태.
	 */
	private List<Map<String,Object>> buildContentTypeNodes(Long promNo) {
		List<Map<String,Object>> nodes = new ArrayList<>();
		if (promNo == null) return nodes;

		// 규정형식 — provgrp 클릭 시 JSP 가 일괄편집기(VERSION) / HTML 조항 목록을 분기하는 근거
		String provFlag = "VERSION";
		try {
			PromVO p = promService.selectPromDetail(promNo);
			if (p != null && p.getProvFlag() != null && !p.getProvFlag().isEmpty()) {
				provFlag = "FILE_VIEWER".equalsIgnoreCase(p.getProvFlag()) ? "VIEWER" : p.getProvFlag();
			}
		} catch (Exception ignore) { }

		Map<String,Object> provData = new LinkedHashMap<>();
		provData.put("promNo",   promNo);
		provData.put("provFlag", provFlag);

		Map<String,Object> prov = new LinkedHashMap<>();
		prov.put("id",       "provgrp:" + promNo);
		prov.put("text",     "조문");
		prov.put("type",     "provgrp");
		prov.put("data",     provData);
		prov.put("children", true);
		Map<String,Object> ps = new LinkedHashMap<>(); ps.put("opened", true);
		prov.put("state",    ps);
		nodes.add(prov);

		Map<String,Object> doc = new LinkedHashMap<>();
		doc.put("id",       "docgrp:" + promNo);
		doc.put("text",     "별표/별지서식");
		doc.put("type",     "docgrp");
		doc.put("data",     singleData("promNo", promNo));
		doc.put("children", true);
		nodes.add(doc);
		return nodes;
	}

	/**
	 * "조문" 그룹의 자식 (조항 트리 1단계) — 레거시 getManageProvisionVersionList 이식.
	 *   · provFlag = HTML / FILE_VIEWER → TB_PROV_HTML 평면 목록 (조 단위, 본문은 HTML 편집)
	 *   · 그 외(VERSION 기본)            → TB_PROV_VRSN 누적 계층:
	 *        - 장(F_JANG) 행이 있으면  → 장 노드(자식 lazy)
	 *        - 장이 없으면               → 조(BASE_TEXT) 평면 목록 (예: 영문 정관)
	 *   누적 = 같은 lawId 의 회차들(ILAW_NO ≤ 이 회차) 중 SFULL_ITEM 별 최신 행 (레거시 와 동일).
	 */
	private List<Map<String,Object>> buildProvisionGroup(Long promNo) {
		List<Map<String,Object>> nodes = new ArrayList<>();
		if (promNo == null) return nodes;

		PromVO p = null;
		try { p = promService.selectPromDetail(promNo); } catch (Exception ignore) { }
		String flag = (p != null) ? p.getProvFlag() : null;

		if ("HTML".equalsIgnoreCase(flag) || "VIEWER".equalsIgnoreCase(flag) || "FILE_VIEWER".equalsIgnoreCase(flag)) {
			// 누적(상속 포함) — 이전 회차 상속 행은 회색(tree_document_provius) + 클릭 시 개정분기 모드
			Long hLawId = (p != null) ? p.getLawId() : null;
			Long hLawNo = (p != null) ? p.getLawNo() : null;
			List<ProvHtmlVO> rows = (hLawId != null && hLawNo != null)
					? provHtmlService.selectProvHtmlListCumulativeAdmin(hLawId, hLawNo)
					: provHtmlService.selectProvHtmlList(promNo);
			for (ProvHtmlVO r : rows) {
				Map<String,Object> n = new LinkedHashMap<>();
				n.put("id",   "prov:" + (r.getPromNo() != null ? r.getPromNo() : promNo) + ":" + safe(r.getItem()));
				n.put("text", buildProvHtmlLabel(r));
				n.put("type", "prov");
				n.put("data", buildProvHtmlData(promNo, r));
				n.put("children", false);
				if (r.getPromNo() != null && !r.getPromNo().equals(promNo)) {
					n.put("a_attr", singleData("class", "tree_document_provius"));
				}
				nodes.add(n);
			}
			return nodes;
		}

		// VERSION 모드 — TB_PROV_VRSN 누적 계층 (lawId/lawNo 필요)
		Long lawId = (p != null) ? p.getLawId() : null;
		Long lawNo = (p != null) ? p.getLawNo() : null;
		if (lawId == null || lawNo == null) return nodes;   // 식별 불가 — 빈 트리

		List<ProvVrsnVO> jangs = provVrsnMapper.selectTopGroupNodes(lawId, lawNo);
		if (jangs != null && !jangs.isEmpty()) {
			for (ProvVrsnVO g : jangs) nodes.add(provGroupNode(lawId, lawNo, g));
			return nodes;
		}
		List<ProvVrsnVO> jos = provVrsnMapper.selectBaseTextNodes(lawId, lawNo);
		if (jos != null) for (ProvVrsnVO j : jos) nodes.add(provVrsnLeafNode(lawId, lawNo, j));
		return nodes;
	}

	/**
	 * "별표/별지서식" 그룹의 자식 — 레거시 getManageDocumentList(TB_DOCU) 누적 조회 이식.
	 *   · 같은 lawId 회차들 중 SITEM 별 최신 회차의 TB_DOCU 행. 표시 항목 먼저, SITEM 순.
	 *   · 라벨 = STITLE. 현재 회차가 직접 만든 행과 이전 회차에서 상속된 행을 CSS 클래스로 구분
	 *     (레거시 tree_document_provius / tree_document_display 와 동일).
	 */
	private List<Map<String,Object>> buildDocumentGroup(Long promNo) {
		List<Map<String,Object>> nodes = new ArrayList<>();
		if (promNo == null) return nodes;

		PromVO p = null;
		try { p = promService.selectPromDetail(promNo); } catch (Exception ignore) { }
		Long lawId = (p != null) ? p.getLawId() : null;
		Long lawNo = (p != null) ? p.getLawNo() : null;
		if (lawId == null || lawNo == null) return nodes;

		List<DocuVO> rows = docuMapper.selectDocuListCumulative(lawId, lawNo);
		if (rows == null) return nodes;
		for (DocuVO d : rows) {
			Map<String,Object> n = new LinkedHashMap<>();
			n.put("id",       "docu:" + d.getDocuNo());
			n.put("text",     buildDocuLabel(d));
			n.put("type",     "docu");
			n.put("data",     buildDocuData(promNo, lawId, lawNo, d));
			n.put("children", false);
			// 레거시 와 동일하게 표시여부/상속 구분을 CSS 클래스로
			String cls = docuRowClass(promNo, d);
			if (!cls.isEmpty()) n.put("a_attr", singleData("class", cls));
			nodes.add(n);
		}
		return nodes;
	}

	private String buildDocuLabel(DocuVO d) {
		String title = d.getTitle() != null ? d.getTitle().trim() : "";
		if (!title.isEmpty()) return title;
		String item = d.getItem() != null ? d.getItem().trim() : "";
		String grp  = d.getGrpTitle() != null ? d.getGrpTitle().trim() : "";
		if (!grp.isEmpty() && !item.isEmpty()) return grp + " " + item;
		if (!item.isEmpty()) return item;
		return "(별표 " + (d.getDocuNo() != null ? d.getDocuNo() : "") + ")";
	}

	/** 레거시 tree_document_* 클래스 동일 의미로: 숨김행 / 이전 회차 상속행 구분. */
	private String docuRowClass(Long currentPromNo, DocuVO d) {
		if ("N".equals(d.getDispYn())) return "tree_document_display";
		if (d.getPromNo() != null && !d.getPromNo().equals(currentPromNo)) return "tree_document_provius";
		return "";
	}

	private Map<String,Object> buildDocuData(Long currentPromNo, Long lawId, Long lawNo, DocuVO d) {
		Map<String,Object> m = new LinkedHashMap<>();
		m.put("docuNo",      d.getDocuNo());
		m.put("promNo",      d.getPromNo());        // owner (이 행이 실제 저장된 회차)
		m.put("currentPromNo", currentPromNo);      // 트리에서 보고 있는 회차
		m.put("lawId",       lawId);
		m.put("lawNo",       lawNo);
		m.put("item",        d.getItem());
		m.put("grpTitle",    d.getGrpTitle());
		m.put("title",       d.getTitle());
		m.put("gaejungType", d.getGaejungType());
		m.put("dispYn",      d.getDispYn());
		m.put("docu",        Boolean.TRUE);
		return m;
	}

	private Map<String,Object> singleData(String key, Object val) {
		Map<String,Object> d = new LinkedHashMap<>();
		d.put(key, val);
		return d;
	}

	/**
	 * 그룹(장/절) 노드의 직속 자식 — 레거시 getCommonSubProvisionList 이식 (누적).
	 * 직속 절(F_JEOL) 은 다시 그룹 노드(자식 lazy), 직속 조(BASE_TEXT) 는 leaf.
	 */
	private List<Map<String,Object>> buildGroupChildren(Long lawId, Long lawNo, String parentFullItem) {
		List<Map<String,Object>> nodes = new ArrayList<>();
		if (lawId == null || lawNo == null || parentFullItem == null) return nodes;
		List<ProvVrsnVO> kids = provVrsnMapper.selectGroupChildren(lawId, lawNo, parentFullItem);
		if (kids == null) return nodes;
		for (ProvVrsnVO k : kids) {
			if ("BASE_TEXT".equals(k.getUnitType())) nodes.add(provVrsnLeafNode(lawId, lawNo, k));
			else                                     nodes.add(provGroupNode(lawId, lawNo, k));
		}
		return nodes;
	}

	/** 장/절 노드 — id=grp:lawId:lawNo:<60자코드> (lawId/lawNo 로 누적 자식 조회) */
	private Map<String,Object> provGroupNode(Long lawId, Long lawNo, ProvVrsnVO g) {
		Map<String,Object> n = new LinkedHashMap<>();
		n.put("id",   "grp:" + lawId + ":" + lawNo + ":" + safe(g.getFullItem()));
		n.put("text", buildProvVrsnGroupLabel(g));
		n.put("type", "grp");
		n.put("data", buildProvVrsnData(lawId, lawNo, g));
		n.put("children", true);
		return n;
	}

	/** 조 노드 — id=prov:<ownerPromNo>:<60자코드> (ownerPromNo = 이 조항 행이 실제 저장된 회차) */
	private Map<String,Object> provVrsnLeafNode(Long lawId, Long lawNo, ProvVrsnVO j) {
		Map<String,Object> n = new LinkedHashMap<>();
		n.put("id",   "prov:" + j.getPromNo() + ":" + safe(j.getFullItem()));
		n.put("text", buildProvVrsnJoLabel(j));
		n.put("type", "prov");
		n.put("data", buildProvVrsnData(lawId, lawNo, j));
		n.put("children", false);
		return n;
	}

	private Map<String,Object> buildProvVrsnData(Long lawId, Long lawNo, ProvVrsnVO v) {
		Map<String,Object> d = new LinkedHashMap<>();
		d.put("lawId",      lawId);
		d.put("lawNo",      lawNo);
		d.put("promNo",     v.getPromNo());        // 이 조항 행이 실제 저장된 회차 (owner) — 본문 조회/저장 키
		d.put("fullItem",   v.getFullItem());      // TB_PROV_VRSN 식별키 — 60자 코드
		d.put("item",       v.getItem());
		d.put("subItem",    v.getSubItem());
		d.put("unitType",   v.getUnitType());
		d.put("nativeType", v.getNativeType());
		d.put("level",      v.getLevel());
		d.put("vrsn",       Boolean.TRUE);         // JSP 가 TB_PROV_HTML 노드와 구분
		return d;
	}

	/** 장/절 그룹 라벨 — 레거시 JangPattern/JeolPattern.getTitle 이식 ("제N장 제목") */
	private String buildProvVrsnGroupLabel(ProvVrsnVO g) {
		int item = parseIntSafe(g.getItem(), -1);
		int sub  = parseIntSafe(g.getSubItem(), 0);
		String suffix = groupSuffix(g.getNativeType());
		StringBuilder sb = new StringBuilder();
		if (item >= 0 && suffix != null) {
			sb.append("제").append(item).append(suffix);
			if (sub > 0) sb.append("의").append(sub);
		} else if (g.getItem() != null && !g.getItem().trim().isEmpty()) {
			sb.append(g.getItem().trim());
		}
		String title = g.getTitle() != null ? g.getTitle().trim() : "";
		if (!title.isEmpty() && !"null".equalsIgnoreCase(title)) {
			if (sb.length() > 0) sb.append(" ");
			sb.append(title);
		}
		if (sb.length() == 0) sb.append(safe(g.getFullItem()));
		return sb.toString();
	}

	/** 조 라벨 — 레거시 JoPattern.getTitle 이식 ("제N조(제목)" / 제목에 "삭제" 포함 시 "제N조<…>") */
	private String buildProvVrsnJoLabel(ProvVrsnVO j) {
		int item = parseIntSafe(j.getItem(), -1);
		int sub  = parseIntSafe(j.getSubItem(), 0);
		StringBuilder sb = new StringBuilder();
		if (item >= 0) {
			sb.append("제").append(item).append("조");
			if (sub > 0) sb.append("의").append(sub);
		} else if (j.getItem() != null && !j.getItem().trim().isEmpty()) {
			sb.append(j.getItem().trim());
		}
		String title = j.getTitle() != null ? j.getTitle().trim() : "";
		if (!title.isEmpty() && !"null".equalsIgnoreCase(title)) {
			if (title.contains("삭제")) sb.append("<").append(title).append(">");
			else                        sb.append("(").append(title).append(")");
		}
		if (sb.length() == 0) sb.append(safe(j.getFullItem()));
		return sb.toString();
	}

	private String groupSuffix(String nativeType) {
		if (nativeType == null) return null;
		switch (nativeType) {
			case "F_PYUN": return "편";
			case "F_JANG": return "장";
			case "F_JEOL": return "절";
			case "F_GWAN": return "관";
			case "F_MOK1": return "목";
			default:       return null;
		}
	}

	private int parseIntSafe(String s, int def) {
		if (s == null) return def;
		try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return def; }
	}

	private String buildProvHtmlLabel(ProvHtmlVO r) {
		// SITEM 은 '002000' 같은 정렬 코드라 라벨에 부적합 — STITLE 만 사용
		String title = r.getTitle() != null ? r.getTitle().trim() : "";
		if (!title.isEmpty()) return title;
		String item = r.getItem() != null ? r.getItem().trim() : "";
		if (!item.isEmpty()) return item;
		return "(조항 " + (r.getProvHtmlNo() != null ? r.getProvHtmlNo() : "") + ")";
	}

	private Map<String,Object> buildProvHtmlData(Long currentPromNo, ProvHtmlVO r) {
		Map<String,Object> d = new LinkedHashMap<>();
		d.put("promNo",        r.getPromNo() != null ? r.getPromNo() : currentPromNo);   // owner(행 저장 회차)
		d.put("ownerPromNo",   r.getPromNo());
		d.put("currentPromNo", currentPromNo);       // 트리에서 보고 있는 회차 — 분기 판정용
		d.put("item",       r.getItem());            // TB_PROV_HTML 식별키 ("002000")
		d.put("provHtmlNo", r.getProvHtmlNo());      // 우측 첨부(TB_ATTACH refNo) 조회용
		d.put("title",      r.getTitle());
		return d;
	}

	// ============================================================
	// 헬퍼
	// ============================================================

	/** 분류 트리용 라벨 — 제목만 (운영중 회차이므로 회차번호 생략) */
	private String buildPromTitleLabel(PromVO p) {
		String t = p.getTitle();
		return (t != null && !t.isEmpty()) ? t : ("(규정 " + p.getPromNo() + ")");
	}

	/**
	 * 연혁목차용 라벨 — 레거시 식 "{lawNo}. {gaejungNm} ({promDate})" + 현행 표시.
	 * 예: "200. 개정 (2020-06-02) [현행]" / "10. 제정 (1979-02-13)".
	 * gaejungNm 이 없으면 "차" 로 폴백 ("200차 (2020-06-02)").
	 */
	private String buildPromVersionLabel(PromVO p) {
		StringBuilder sb = new StringBuilder();
		String gaejungNm = (p.getGaejungNm() != null) ? p.getGaejungNm().trim() : "";
		if (p.getLawNo() != null) {
			sb.append(p.getLawNo());
			sb.append(gaejungNm.isEmpty() ? "차" : ". " + gaejungNm);
		}
		if (p.getPromDate() != null && !p.getPromDate().isEmpty()) {
			if (sb.length() > 0) sb.append(" ");
			sb.append("(").append(p.getPromDate()).append(")");
		}
		if ("Y".equals(p.getExistingYn())) sb.append(" [현행]");
		if (sb.length() == 0) sb.append(p.getTitle() != null ? p.getTitle() : ("규정 " + p.getPromNo()));
		return sb.toString().trim();
	}

	private Map<String,Object> buildPromData(PromVO p) {
		Map<String,Object> d = new LinkedHashMap<>();
		d.put("promNo",     p.getPromNo());
		d.put("lawId",      p.getLawId());
		d.put("lawNo",      p.getLawNo());
		d.put("title",      p.getTitle());
		d.put("gaejungNm",  p.getGaejungNm());
		d.put("promDate",   p.getPromDate());
		d.put("existingYn", p.getExistingYn());
		d.put("pending",    p.isUpcoming());   // 시행예정(공포~시행 사이, A안) — 트리·연혁 뱃지 공용
		return d;
	}

	/** "prom:123" → 123. (id 첫 ':' 뒤 전체를 long 으로 — 단일 토큰 id 전용) */
	private Long parseLongAfterColon(String id) {
		try {
			int colon = id.indexOf(':');
			if (colon < 0) return null;
			return Long.valueOf(id.substring(colon + 1));
		} catch (NumberFormatException e) {
			return null;
		}
	}

	private Long parseLongSafe(String s) {
		if (s == null) return null;
		try { return Long.valueOf(s.trim()); } catch (NumberFormatException e) { return null; }
	}

	/** 원시 요청 본문 전체를 문자열로 읽음 (text/plain 대용량 본문용 — form-urlencoded 팽창·maxPostSize 회피).
	 *  CharacterEncodingFilter(UTF-8, forceEncoding) 가 적용돼 getReader 가 UTF-8 로 디코딩한다. */
	private String readRawRequestBody(HttpServletRequest request) {
		StringBuilder sb = new StringBuilder();
		try (java.io.BufferedReader r = request.getReader()) {
			char[] buf = new char[8192];
			int n;
			while ((n = r.read(buf)) != -1) sb.append(buf, 0, n);
		} catch (Exception e) {
			return null;
		}
		return sb.length() == 0 ? null : sb.toString();
	}

	private String safe(String s) { return s == null ? "" : s; }

	/** 현재 로그인 사용자 ID — 없으면 null */
	private String currentUserId() {
		try {
			LoginVO u = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
			return u != null ? u.getId() : null;
		} catch (Exception e) {
			return null;
		}
	}

	private String currentUserNm() {
		try {
			LoginVO u = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
			return u != null ? u.getName() : null;
		} catch (Exception e) {
			return null;
		}
	}
}
