/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/web/RelatedController.java
 *
 * 관련자료 8 액션 + 카테고리 관리 Controller.
 *   - FILE      : /rlms/related/saveFile.do            (단계 B1 — 본 세션 구현)
 *   - ORGN      : /rlms/related/saveOrgn.do            (B2)
 *   - HTML      : /rlms/related/saveHtml.do            (B3)
 *   - DOMAIN    : /rlms/related/saveDmnLnk.do          (B4)
 *   - IMG       : /rlms/related/saveImg.do             (B5)
 *   - WORD      : /rlms/related/saveWord.do            (B6 — .docx/.hwpx 자체변환 → 미리보기·전문검색)
 *   - LINK      : /rlms/related/saveLnk.do             (B7)
 *   - ZIP       : /rlms/related/downloadZip.do         (단계 C)
 *
 * 카테고리 관리 (TB_REL_VRSN_CATE):
 *   - GET  /rlms/related/cateList.do?promNo=&lawId=    — 활성 목록
 *   - POST /rlms/related/cateInsert.do                 — 사용자 추가
 *   - POST /rlms/related/cateRename.do                 — 이름 변경
 *   - POST /rlms/related/cateHide.do                   — 숨김일 설정
 *   - POST /rlms/related/cateOrgnDown.do               — 원본 다운로드 토글
 *   - POST /rlms/related/cateMoveSeq.do                — 순서 변경
 *   - POST /rlms/related/cateDelete.do                 — 삭제
 *
 * 권한 가드: 메뉴 파생 URL 보안(context-security.xml) + authed() + 열람/작성 가드 조합.
 *   (AUTH_PGM_* 카탈로그 @PreAuthorize 는 접근제어 재설계에서 폐기 — 메뉴=단일원천.)
 */
package narainet.rlms.related.web;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.util.HashSet;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.servlet.http.HttpServletResponse;

import narainet.rlms.attach.service.AttachService;
import narainet.rlms.attach.service.AttachVO;
import narainet.rlms.related.service.RelVrsnVO;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.related.service.RelFileService;
import narainet.rlms.related.service.RelFileVO;
import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.related.service.RelDmnLnkService;
import narainet.rlms.related.service.RelDmnLnkVO;
import narainet.rlms.related.service.RelHtmlService;
import narainet.rlms.related.service.RelHtmlVO;
import narainet.rlms.related.service.RelImgService;
import narainet.rlms.related.service.RelImgVO;
import narainet.rlms.related.service.RelLnkService;
import narainet.rlms.related.service.RelLnkVO;
import narainet.rlms.related.service.RelWordService;
import narainet.rlms.related.service.RelWordVO;
import narainet.rlms.related.service.RelOrgnService;
import narainet.rlms.related.service.RelOrgnVO;
import narainet.rlms.related.service.RelVrsnCateService;
import narainet.rlms.related.service.RelVrsnCateVO;
import narainet.rlms.related.service.RelVrsnService;

@Controller
public class RelatedController {

	@Resource(name = "relVrsnService")     private RelVrsnService     relVrsnService;
	@Resource(name = "relVrsnCateService") private RelVrsnCateService relVrsnCateService;
	@Resource(name = "relFileService")     private RelFileService     relFileService;
	@Resource(name = "relOrgnService")     private RelOrgnService     relOrgnService;
	@Resource(name = "relHtmlService")     private RelHtmlService     relHtmlService;
	@Resource(name = "relImgService")      private RelImgService      relImgService;
	@Resource(name = "relLnkService")      private RelLnkService      relLnkService;
	@Resource(name = "relWordService")     private RelWordService     relWordService;
	@Resource(name = "attachService")      private AttachService      attachService;
	@Resource(name = "relDmnLnkService")   private RelDmnLnkService   relDmnLnkService;
	@Resource(name = "promMapper")         private PromMapper         promMapper;
	/** 분류별 열람제한 가드 — 첨부 다운로드/보기/상세/ZIP 은 attNo·relVrsnNo 직접 호출이 가능해 소유 규정 역해석 후 차단 */
	@Resource(name = "promReadGuard")      private narainet.rlms.prom.service.PromReadGuard promReadGuard;
	@Resource private narainet.rlms.attach.mapper.AttachMapper attachMapper;
	/** 사용자 활동 로그(TB_ACT_LOG) — 파일 다운로드 적재 */
	@Resource(name = "statsService")       private narainet.rlms.stats.service.StatsService statsService;

	/** 파일 다운로드 활동 로그 — 현재 로그인 사용자로 적재(감사 실패가 다운로드를 막지 않게 전부 삼킴) */
	/**
	 * 다운로드 1회 기록 — ①집계(TB_ATTACH.IDOWN_CNT +1, 목록에서 O(1) 표시)
	 * ②상세 이력(TB_ACT_LOG STASK='파일 다운로드' — 누가/언제/IP). 2026-07-30 ① 추가.
	 * 둘 다 실패해도 다운로드 자체는 진행한다.
	 */
	private void logDownload(Long refNo, String name, javax.servlet.http.HttpServletRequest request) {
		try {
			attachMapper.increaseDownloadCount(refNo);
		} catch (Exception ignore) { }
		try {
			// 공개열람 익명은 활동 로그 제외(다운로드 수는 위에서 익명 포함 집계) — 뷰어 recordAction 정합
			egovframework.com.cmm.LoginVO u =
					(egovframework.com.cmm.LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
			if (u != null) {
				statsService.recordAction("파일 다운로드", "TB_ATTACH", refNo, name,
						u.getId(), u.getName(),
						egovframework.com.utl.sim.service.EgovClntInfo.getClntIP(request));
			}
		} catch (Exception ignore) { }
	}

	// ============================================================
	// 공통 helper
	// ============================================================

	private boolean authed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
	}

	/** 열람 3종(relDetail/attachView/attachDownload) 전용 — 공개열람 모드(Globals.rlms.publicFront=Y)면
	 *  익명도 허용. 편집 CRUD 는 종전대로 authed() 유지. 열람제한(isReadBlockedAttach)은 동일 적용. */
	private boolean viewAllowed() {
		return narainet.rlms.common.service.PublicFront.viewAllowed();
	}

	/** 첨부(attNo)의 소유 규정이 분류별 열람제한으로 차단인가 — 규정 무관 첨부(공지/법령질의 등)는 false */
	private boolean isReadBlockedAttach(Long attNo) {
		if (attNo == null || promReadGuard.isExempt()) {
			return false;
		}
		try {
			Long ownerPromNo = attachMapper.selectOwnerPromNoByAttach(attNo);
			return ownerPromNo != null && !promReadGuard.canReadProm(ownerPromNo);
		} catch (Exception e) {
			return false;   // 해석 실패는 차단하지 않음 (기존 동작 보존)
		}
	}

	private Map<String,Object> ok() {
		Map<String,Object> r = new LinkedHashMap<>();
		r.put("ok", true);
		return r;
	}

	private Map<String,Object> ok(String key, Object value) {
		Map<String,Object> r = ok();
		r.put(key, value);
		return r;
	}

	private Map<String,Object> fail(String message) {
		Map<String,Object> r = new LinkedHashMap<>();
		r.put("ok", false);
		r.put("error", message);
		return r;
	}

	// ============================================================
	// B1) FILE 액션 — 파일 1건 업로드 (multipart)
	// ============================================================

	/**
	 *  POST /rlms/related/saveFile.do  (multipart/form-data)
	 *   - promNo       (필수) 회차 번호
	 *   - flag         (선택) "PROMULGATION" / "PROVISION" / "DOCUMENT" — 디폴트 PROMULGATION
	 *   - fullItem     (선택) flag=PROVISION/DOCUMENT 일 때만 의미 있음 (60자 코드)
	 *   - cateNo       (선택) TB_REL_VRSN_CATE.IRVCATE_NO
	 *   - cateName     (선택) 캐시용 카테고리 명
	 *   - cateOrder    (선택) 카테고리 순서
	 *   - title        (선택) 사용자 입력 제목. 없으면 원본 파일명
	 *   - file         (필수) MultipartFile
	 *   - sysId        (선택) 시스템 ID. 없으면 AttachService 가 DEFAULT 부여
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/saveFile.do")
	public Map<String,Object> saveFile(
			@RequestParam("promNo")                              Long   promNo,
			@RequestParam(value = "flag",      required = false) String flag,
			@RequestParam(value = "fullItem",  required = false) String fullItem,
			@RequestParam(value = "cateNo",    required = false) Long   cateNo,
			@RequestParam(value = "cateName",  required = false) String cateName,
			@RequestParam(value = "cateOrder", required = false) Integer cateOrder,
			@RequestParam(value = "title",     required = false) String title,
			@RequestParam("file")                                MultipartFile file,
			@RequestParam(value = "sysId",     required = false) String sysId) {

		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long relFileNo = relFileService.saveFile(promNo, flag, fullItem,
					cateNo, cateName, cateOrder, title, file, sysId);
			return ok("relFileNo", relFileNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "save.fail");
		}
	}

	/** GET /rlms/related/fileList.do?relVrsnNo=… — 한 마스터의 파일 자식 목록 */
	@ResponseBody
	@RequestMapping("/rlms/related/fileList.do")
	public Map<String,Object> fileList(@RequestParam("relVrsnNo") Long relVrsnNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelFileVO> list = relFileService.getList(relVrsnNo);
		return ok("list", list != null ? list : new ArrayList<>());
	}

	/** POST /rlms/related/deleteFile.do — 파일 1건 삭제 (마스터 cascade) */
	@ResponseBody
	@RequestMapping("/rlms/related/deleteFile.do")
	public Map<String,Object> deleteFile(@RequestParam("relFileNo") Long relFileNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			relFileService.delete(relFileNo);
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}

	// ============================================================
	// 카테고리 관리 (TB_REL_VRSN_CATE)
	// ============================================================

	@ResponseBody
	@RequestMapping("/rlms/related/cateList.do")
	public Map<String,Object> cateList(
			@RequestParam("promNo") Long promNo,
			@RequestParam("lawId")  Long lawId) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelVrsnCateVO> list = relVrsnCateService.getList(promNo, lawId, null);
		return ok("list", list != null ? list : new ArrayList<>());
	}

	@ResponseBody
	@RequestMapping("/rlms/related/cateInsert.do")
	public Map<String,Object> cateInsert(
			@RequestParam("promNo")                            Long   promNo,
			@RequestParam("lawId")                             Long   lawId,
			@RequestParam("title")                             String title,
			@RequestParam(value = "seq",        required = false) Integer seq,
			@RequestParam(value = "orgnDownYn", required = false) String orgnDownYn) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long cateNo = relVrsnCateService.insert(promNo, lawId, title, seq, orgnDownYn);
			return ok("cateNo", cateNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "insert.fail");
		}
	}

	@ResponseBody
	@RequestMapping("/rlms/related/cateRename.do")
	public Map<String,Object> cateRename(
			@RequestParam("cateNo") Long   cateNo,
			@RequestParam("title")  String title) {
		if (!authed()) return fail("UNAUTHORIZED");
		relVrsnCateService.rename(cateNo, title);
		return ok();
	}

	@ResponseBody
	@RequestMapping("/rlms/related/cateHide.do")
	public Map<String,Object> cateHide(
			@RequestParam("cateNo") Long   cateNo,
			@RequestParam("hideDt") String hideDt) {
		if (!authed()) return fail("UNAUTHORIZED");
		relVrsnCateService.hide(cateNo, hideDt);
		return ok();
	}

	@ResponseBody
	@RequestMapping("/rlms/related/cateOrgnDown.do")
	public Map<String,Object> cateOrgnDown(
			@RequestParam("cateNo")     Long   cateNo,
			@RequestParam("orgnDownYn") String orgnDownYn) {
		if (!authed()) return fail("UNAUTHORIZED");
		relVrsnCateService.toggleOrgnDown(cateNo, orgnDownYn);
		return ok();
	}

	@ResponseBody
	@RequestMapping("/rlms/related/cateMoveSeq.do")
	public Map<String,Object> cateMoveSeq(
			@RequestParam("cateNo") Long    cateNo,
			@RequestParam("seq")    Integer seq) {
		if (!authed()) return fail("UNAUTHORIZED");
		relVrsnCateService.moveSeq(cateNo, seq);
		return ok();
	}

	@ResponseBody
	@RequestMapping("/rlms/related/cateDelete.do")
	public Map<String,Object> cateDelete(@RequestParam("cateNo") Long cateNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		relVrsnCateService.delete(cateNo);
		return ok();
	}

	// ============================================================
	// B2) ORGN 액션 — 원본 1건 업로드 (multipart, 분류 없음)
	// ============================================================

	/**
	 *  POST /rlms/related/saveOrgn.do  (multipart/form-data)
	 *   - promNo    (필수) 회차 번호
	 *   - flag      (선택) "PROMULGATION" / "PROVISION" / "DOCUMENT" — 디폴트 PROMULGATION
	 *   - fullItem  (선택) flag=PROVISION/DOCUMENT 일 때만 의미 있음 (60자 코드)
	 *   - title     (선택) 사용자 입력 제목. 없으면 원본 파일명
	 *   - file      (필수) MultipartFile
	 *   - sysId     (선택) 시스템 ID. 없으면 AttachService 가 DEFAULT 부여
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/saveOrgn.do")
	public Map<String,Object> saveOrgn(
			@RequestParam("promNo")                             Long   promNo,
			@RequestParam(value = "flag",     required = false) String flag,
			@RequestParam(value = "fullItem", required = false) String fullItem,
			@RequestParam(value = "title",    required = false) String title,
			@RequestParam("file")                               MultipartFile file,
			@RequestParam(value = "sysId",    required = false) String sysId) {

		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long relOrgnNo = relOrgnService.saveOrgn(promNo, flag, fullItem,
					title, file, sysId);
			return ok("relOrgnNo", relOrgnNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "save.fail");
		}
	}

	/** GET /rlms/related/orgnList.do?relVrsnNo=… — 한 마스터의 원본 자식 목록 */
	@ResponseBody
	@RequestMapping("/rlms/related/orgnList.do")
	public Map<String,Object> orgnList(@RequestParam("relVrsnNo") Long relVrsnNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelOrgnVO> list = relOrgnService.getList(relVrsnNo);
		return ok("list", list != null ? list : new ArrayList<>());
	}

	/** POST /rlms/related/deleteOrgn.do — 원본 1건 삭제 (마스터 cascade) */
	@ResponseBody
	@RequestMapping("/rlms/related/deleteOrgn.do")
	public Map<String,Object> deleteOrgn(@RequestParam("relOrgnNo") Long relOrgnNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			relOrgnService.delete(relOrgnNo);
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}

	// ============================================================
	// B3) HTML 액션 — 직접 작성한 HTML 표/본문 (파일 업로드 없음)
	// ============================================================

	/**
	 *  POST /rlms/related/saveHtml.do
	 *   - promNo    (필수) 회차 번호
	 *   - flag      (선택) "PROMULGATION" / "PROVISION" / "DOCUMENT" — 디폴트 PROMULGATION
	 *   - fullItem  (선택) flag=PROVISION/DOCUMENT 일 때만 의미 있음 (60자 코드)
	 *   - title     (선택) 제목. 없으면 '(제목없음)'
	 *   - html      (필수에 준함) CKEditor 가 만든 HTML 본문
	 *   - sysId     (선택) 시스템 ID
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/saveHtml.do")
	public Map<String,Object> saveHtml(
			@RequestParam("promNo")                             Long   promNo,
			@RequestParam(value = "flag",     required = false) String flag,
			@RequestParam(value = "fullItem", required = false) String fullItem,
			@RequestParam(value = "title",    required = false) String title,
			@RequestParam(value = "html",     required = false) String html,
			@RequestParam(value = "sysId",    required = false) String sysId) {

		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long relHtmlNo = relHtmlService.saveHtml(promNo, flag, fullItem,
					title, html, sysId);
			return ok("relHtmlNo", relHtmlNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "save.fail");
		}
	}

	/** GET /rlms/related/htmlList.do?relVrsnNo=… — 한 마스터의 HTML 자식 목록 */
	@ResponseBody
	@RequestMapping("/rlms/related/htmlList.do")
	public Map<String,Object> htmlList(@RequestParam("relVrsnNo") Long relVrsnNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelHtmlVO> list = relHtmlService.getList(relVrsnNo);
		return ok("list", list != null ? list : new ArrayList<>());
	}

	/** POST /rlms/related/deleteHtml.do — HTML 1건 삭제 (마스터 cascade) */
	@ResponseBody
	@RequestMapping("/rlms/related/deleteHtml.do")
	public Map<String,Object> deleteHtml(@RequestParam("relHtmlNo") Long relHtmlNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			relHtmlService.delete(relHtmlNo);
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}

	// ============================================================
	// B4) DOMAIN_LINK 액션 — 규정 연계 (다건, DELETE-then-INSERT)
	// ============================================================

	/**
	 *  GET /rlms/related/dmnLnkList.do?promNo=&flag=&fullItem=
	 *  현재 마스터에 매달린 링크 목록 — 모달 진입 시 staging 초깃값.
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/dmnLnkList.do")
	public Map<String,Object> dmnLnkList(
			@RequestParam("promNo")                            Long   promNo,
			@RequestParam(value = "flag",     required = false) String flag,
			@RequestParam(value = "fullItem", required = false) String fullItem) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelDmnLnkVO> list = relDmnLnkService.getListByPromAndFullItem(
				promNo, flag, (fullItem != null ? fullItem : "0"));
		return ok("list", list != null ? list : new ArrayList<>());
	}

	/**
	 *  POST /rlms/related/saveDmnLnk.do  (application/json)
	 *  body = { promNo, flag, fullItem, sysId, items:[
	 *            {flag, lawId, lawNo, fullItem, title, alwaysLatestYn, fileItem}, ...
	 *          ] }
	 *  - items 빈 배열이면 전체 클리어
	 *  - DELETE-then-INSERT, ISEQ 는 서버가 1.. 자동 부여
	 */
	@ResponseBody
	@RequestMapping(value = "/rlms/related/saveDmnLnk.do", method = RequestMethod.POST,
			consumes = "application/json")
	@SuppressWarnings("unchecked")
	public Map<String,Object> saveDmnLnk(@RequestBody Map<String,Object> body) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long   promNo   = toLong(body.get("promNo"));
			String flag     = (String) body.get("flag");
			String fullItem = (String) body.get("fullItem");
			String sysId    = (String) body.get("sysId");

			List<RelDmnLnkVO> items = new ArrayList<>();
			Object rawItems = body.get("items");
			if (rawItems instanceof List) {
				for (Object o : (List<Object>) rawItems) {
					if (!(o instanceof Map)) continue;
					Map<String,Object> m = (Map<String,Object>) o;
					RelDmnLnkVO it = new RelDmnLnkVO();
					it.setFlag((String) m.get("flag"));
					it.setLawId(toLong(m.get("lawId")));
					it.setLawNo(toLong(m.get("lawNo")));
					it.setFullItem((String) m.get("fullItem"));
					it.setTitle((String) m.get("title"));
					it.setAlwaysLatestYn((String) m.get("alwaysLatestYn"));
					it.setFileItem(toLong(m.get("fileItem")));
					// 클라이언트가 promNo 만 알고 lawId/lawNo 를 비웠으면 서버에서 해석
					Long targetPromNo = toLong(m.get("promNo"));
					if ((it.getLawId() == null || it.getLawNo() == null) && targetPromNo != null) {
						PromVO p = promMapper.selectPromByNo(targetPromNo);
						if (p != null) {
							if (it.getLawId() == null) it.setLawId(p.getLawId());
							if (it.getLawNo() == null) it.setLawNo(p.getLawNo());
							if ((it.getTitle() == null || it.getTitle().trim().isEmpty()) && p.getTitle() != null) {
								it.setTitle(p.getTitle());
							}
						}
					}
					items.add(it);
				}
			}
			String relVrsnNo = relDmnLnkService.saveLinks(promNo, flag, fullItem, sysId, items);
			return ok("relVrsnNo", relVrsnNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "save.fail");
		}
	}

	/** POST /rlms/related/deleteDmnLnk.do?relDmnLnkNo= */
	@ResponseBody
	@RequestMapping("/rlms/related/deleteDmnLnk.do")
	public Map<String,Object> deleteDmnLnk(@RequestParam("relDmnLnkNo") Long relDmnLnkNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			relDmnLnkService.delete(relDmnLnkNo);
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}

	/** body Map 의 숫자값을 안전 변환 — Integer/Long/String 모두 수용 */
	private static Long toLong(Object v) {
		if (v == null) return null;
		if (v instanceof Number) return ((Number) v).longValue();
		String s = String.valueOf(v).trim();
		if (s.isEmpty()) return null;
		try { return Long.parseLong(s); } catch (NumberFormatException e) { return null; }
	}

	// ============================================================
	// B5) IMAGE 액션 — 이미지 업로드 (multipart, 분류 없음)
	// ============================================================

	/**
	 *  POST /rlms/related/saveImg.do  (multipart/form-data)
	 *   - promNo (필수), flag, fullItem, title, file, sysId
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/saveImg.do")
	public Map<String,Object> saveImg(
			@RequestParam("promNo")                             Long   promNo,
			@RequestParam(value = "flag",     required = false) String flag,
			@RequestParam(value = "fullItem", required = false) String fullItem,
			@RequestParam(value = "title",    required = false) String title,
			@RequestParam("file")                               MultipartFile file,
			@RequestParam(value = "sysId",    required = false) String sysId) {

		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long relImgNo = relImgService.saveImg(promNo, flag, fullItem, title, file, sysId);
			return ok("relImgNo", relImgNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "save.fail");
		}
	}

	@ResponseBody
	@RequestMapping("/rlms/related/imgList.do")
	public Map<String,Object> imgList(@RequestParam("relVrsnNo") Long relVrsnNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelImgVO> list = relImgService.getList(relVrsnNo);
		return ok("list", list != null ? list : new ArrayList<>());
	}

	@ResponseBody
	@RequestMapping("/rlms/related/deleteImg.do")
	public Map<String,Object> deleteImg(@RequestParam("relImgNo") Long relImgNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			relImgService.delete(relImgNo);
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}

	// ============================================================
	// B7) LINK 액션 — 외부 URL 연계 (다건, DELETE-then-INSERT)
	// ============================================================

	/**
	 *  GET /rlms/related/lnkList.do?promNo=&flag=&fullItem=
	 *  현재 마스터의 링크 목록 — 모달 진입 시 staging 초깃값.
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/lnkList.do")
	public Map<String,Object> lnkList(
			@RequestParam("promNo")                             Long   promNo,
			@RequestParam(value = "flag",     required = false) String flag,
			@RequestParam(value = "fullItem", required = false) String fullItem) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelLnkVO> list = relLnkService.getListByPromAndFullItem(
				promNo, flag, (fullItem != null ? fullItem : "0"));
		return ok("list", list != null ? list : new ArrayList<>());
	}

	/**
	 *  POST /rlms/related/saveLnk.do  (application/json)
	 *  body = { promNo, flag, fullItem, sysId, items:[{cate, title, url}, ...] }
	 *  - URL 빈 행은 자동 skip, 제목 비우면 URL 자체가 제목
	 *  - DELETE-then-INSERT, ISEQ 자동 부여
	 */
	@ResponseBody
	@RequestMapping(value = "/rlms/related/saveLnk.do", method = RequestMethod.POST,
			consumes = "application/json")
	@SuppressWarnings("unchecked")
	public Map<String,Object> saveLnk(@RequestBody Map<String,Object> body) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long   promNo   = toLong(body.get("promNo"));
			String flag     = (String) body.get("flag");
			String fullItem = (String) body.get("fullItem");
			String sysId    = (String) body.get("sysId");

			List<RelLnkVO> items = new ArrayList<>();
			Object rawItems = body.get("items");
			if (rawItems instanceof List) {
				for (Object o : (List<Object>) rawItems) {
					if (!(o instanceof Map)) continue;
					Map<String,Object> m = (Map<String,Object>) o;
					RelLnkVO it = new RelLnkVO();
					it.setCate((String) m.get("cate"));
					it.setTitle((String) m.get("title"));
					it.setUrl((String) m.get("url"));
					items.add(it);
				}
			}
			Long relVrsnNo = relLnkService.saveLinks(promNo, flag, fullItem, sysId, items);
			return ok("relVrsnNo", relVrsnNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "save.fail");
		}
	}

	/** POST /rlms/related/deleteLnk.do?relLnkNo= */
	@ResponseBody
	@RequestMapping("/rlms/related/deleteLnk.do")
	public Map<String,Object> deleteLnk(@RequestParam("relLnkNo") Long relLnkNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			relLnkService.delete(relLnkNo);
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}

	// ============================================================
	// B6) WORD 액션 — Word/HWP/PDF 문서 (1차: 변환 없이 원본만 보관)
	// ============================================================

	/**
	 *  POST /rlms/related/saveWord.do  (multipart/form-data)
	 *   - promNo (필수), flag, fullItem, title, file, sysId
	 *  .docx/.hwpx/.pdf/.doc 은 업로드 시 본문 자체변환(DocImportService.extractRawText)
	 *  → SHTML(인라인 미리보기)/SSEARCH_TEXT(전문검색) 채움. 그 외 확장자는 원본만 보관.
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/saveWord.do")
	public Map<String,Object> saveWord(
			@RequestParam("promNo")                             Long   promNo,
			@RequestParam(value = "flag",     required = false) String flag,
			@RequestParam(value = "fullItem", required = false) String fullItem,
			@RequestParam(value = "title",    required = false) String title,
			@RequestParam("file")                               MultipartFile file,
			@RequestParam(value = "sysId",    required = false) String sysId) {

		if (!authed()) return fail("UNAUTHORIZED");
		try {
			Long relWordNo = relWordService.saveWord(promNo, flag, fullItem, title, file, sysId);
			return ok("relWordNo", relWordNo);
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "save.fail");
		}
	}

	@ResponseBody
	@RequestMapping("/rlms/related/wordList.do")
	public Map<String,Object> wordList(@RequestParam("relVrsnNo") Long relVrsnNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		List<RelWordVO> list = relWordService.getList(relVrsnNo);
		return ok("list", list != null ? list : new ArrayList<>());
	}

	@ResponseBody
	@RequestMapping("/rlms/related/deleteWord.do")
	public Map<String,Object> deleteWord(@RequestParam("relWordNo") Long relWordNo) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			relWordService.delete(relWordNo);
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}

	// ============================================================
	// 단계 C — 단일 첨부 다운로드 / ZIP 일괄다운로드 / 항목 상세
	// ============================================================

	/**
	 *  GET /rlms/related/attachDownload.do?attNo=
	 *   - TB_ATTACH 한 건 다운로드. AttachVO.path 는 디스크 절대경로(AttachServiceImpl.save 기준).
	 *   - 한글 파일명: filename*=UTF-8 + filename(ISO-8859-1) 동시 헤더로 브라우저 호환.
	 */
	@RequestMapping("/rlms/related/attachDownload.do")
	public void attachDownload(@RequestParam("attNo") Long attNo,
			javax.servlet.http.HttpServletRequest request,
			HttpServletResponse response) throws IOException {
		if (!viewAllowed()) { response.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
		if (isReadBlockedAttach(attNo)) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		AttachVO att = attachService.selectByNo(attNo);
		// 레거시(레거시 이관) 행은 SPATH 가 월별 키라 경로 조립이 필요 — resolvePhysical 위임
		File f = (att == null) ? null : attachService.resolvePhysical(att);
		if (f == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		String name = (att.getName() != null && !att.getName().isEmpty())
				? att.getName() : ("attach_" + attNo);
		logDownload(attNo, name, request);
		response.setContentType("application/octet-stream");
		response.setHeader("Content-Disposition",
				buildContentDisposition(name, true));
		response.setContentLengthLong(f.length());
		streamFile(f, response);
	}

	/**
	 *  GET /rlms/related/attachView.do?attNo=
	 *   - 브라우저 인라인 보기 (레거시 viewer.htm + attach.html?pAct=pdf 대응).
	 *   - PDF(원본 또는 DCMS 변환본 — 같은 폴더 동명 .pdf) / 이미지 → inline 스트림.
	 *   - 인라인 표현이 없으면 다운로드로 폴백.
	 */
	@RequestMapping("/rlms/related/attachView.do")
	public void attachView(@RequestParam("attNo") Long attNo,
			HttpServletResponse response) throws IOException {
		if (!viewAllowed()) { response.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
		if (isReadBlockedAttach(attNo)) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		AttachVO att = attachService.selectByNo(attNo);
		if (att == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		String name = (att.getName() != null && !att.getName().isEmpty())
				? att.getName() : ("attach_" + attNo);

		// 1) PDF 인라인 (원본 pdf 또는 변환본)
		File pdf = attachService.resolvePdfView(att);
		if (pdf != null) {
			String pdfName = name.toLowerCase().endsWith(".pdf")
					? name : (stripExt(name) + ".pdf");
			response.setContentType("application/pdf");
			response.setHeader("Content-Disposition", buildContentDisposition(pdfName, false));
			response.setContentLengthLong(pdf.length());
			streamFile(pdf, response);
			return;
		}

		File f = attachService.resolvePhysical(att);
		if (f == null) {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;
		}
		// 2) 이미지 인라인
		String mime = imageMime(att.getExt() != null ? att.getExt() : extOf(f.getName()));
		if (mime != null) {
			response.setContentType(mime);
			response.setHeader("Content-Disposition", buildContentDisposition(name, false));
			response.setContentLengthLong(f.length());
			streamFile(f, response);
			return;
		}
		// 3) 인라인 표현 없음 — 다운로드 폴백
		response.setContentType("application/octet-stream");
		response.setHeader("Content-Disposition", buildContentDisposition(name, true));
		response.setContentLengthLong(f.length());
		streamFile(f, response);
	}

	private static void streamFile(File f, HttpServletResponse response) throws IOException {
		try (InputStream in = new BufferedInputStream(new FileInputStream(f));
		     OutputStream out = response.getOutputStream()) {
			byte[] buf = new byte[8192];
			int n;
			while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
			out.flush();
		}
	}

	private static String imageMime(String ext) {
		if (ext == null) return null;
		switch (ext.toLowerCase()) {
			case "png":            return "image/png";
			case "jpg": case "jpeg": return "image/jpeg";
			case "gif":            return "image/gif";
			case "bmp":            return "image/bmp";
			case "webp":           return "image/webp";
			default:               return null;
		}
	}

	private static String extOf(String name) {
		if (name == null) return "";
		int dot = name.lastIndexOf('.');
		return (dot < 0 || dot == name.length() - 1) ? "" : name.substring(dot + 1);
	}

	private static String stripExt(String name) {
		int dot = name.lastIndexOf('.');
		return dot > 0 ? name.substring(0, dot) : name;
	}

	/**
	 *  GET /rlms/related/downloadZip.do?promNo=&fullItem=&flag=
	 *   - 회차(+조항) 의 FILE/IMAGE/WORD 자식 첨부를 ZIP 으로 묶어 스트림.
	 *   - 레거시 downloadDo 와 동일: ORGN/HTML/LINK/DMN_LNK 는 제외.
	 *   - 동명 파일은 " (2)" 식 suffix 로 dedup (레거시 는 처리 없음, RLMS 보강).
	 */
	@RequestMapping("/rlms/related/downloadZip.do")
	public void downloadZip(
			@RequestParam("promNo")                             Long   promNo,
			@RequestParam(value = "flag",     required = false) String flag,
			@RequestParam(value = "fullItem", required = false) String fullItem,
			javax.servlet.http.HttpServletRequest request,
			HttpServletResponse response) throws IOException {
		if (!authed()) { response.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
		if (!promReadGuard.canReadProm(promNo)) { response.sendError(HttpServletResponse.SC_FORBIDDEN); return; }
		logDownload(null, "regulation_" + promNo + ".zip (일괄)", request);

		String effFlag = (flag != null && !flag.isEmpty()) ? flag : null;
		String effFI   = (fullItem != null && !fullItem.isEmpty()) ? fullItem : null;

		// 마스터 목록 — relVrsnService 가 promNo 기준으로 전체 dispatch 행을 줌
		List<RelVrsnVO> masters = (effFI != null)
				? relVrsnService.getByPromAndFullItem(promNo, effFI)
				: relVrsnService.getByPromNo(promNo);

		// flag 필터 (있으면)
		List<RelVrsnVO> filtered = new ArrayList<>();
		if (masters != null) for (RelVrsnVO m : masters) {
			if (effFlag == null || effFlag.equalsIgnoreCase(m.getFlag())) filtered.add(m);
		}

		String zipBaseName = "regulation_" + promNo;     // 클라이언트가 더 정확한 이름으로 덮어쓰지 않으므로 보수적 디폴트
		response.setContentType("application/zip");
		response.setHeader("Content-Disposition",
				buildContentDisposition(zipBaseName + ".zip", true));

		Set<String> usedNames = new HashSet<>();
		try (ZipOutputStream zos = new ZipOutputStream(response.getOutputStream())) {
			for (RelVrsnVO m : filtered) {
				String stable = m.getStable();
				if (stable == null) continue;
				// ZIP 대상: FILE/IMAGE/WORD 만 (ORGN/HTML/LINK/DMN_LNK 제외 — 레거시 동일)
				Long attNo = null;
				if ("TB_REL_FILE".equals(stable)) {
					List<RelFileVO> ch = relFileService.getList(m.getRelVrsnNo());
					for (RelFileVO c : ch) addAttachToZip(zos, c.getAttNo(), usedNames);
				} else if ("TB_REL_IMG".equals(stable)) {
					List<RelImgVO> ch = relImgService.getList(m.getRelVrsnNo());
					for (RelImgVO c : ch) addAttachToZip(zos, c.getAttNo(), usedNames);
				} else if ("TB_REL_WORD".equals(stable)) {
					List<RelWordVO> ch = relWordService.getList(m.getRelVrsnNo());
					for (RelWordVO c : ch) addAttachToZip(zos, c.getAttNo(), usedNames);
				}
			}
			zos.finish();
		}
	}

	private void addAttachToZip(ZipOutputStream zos, Long attNo, Set<String> usedNames) {
		if (attNo == null) return;
		try {
			AttachVO att = attachService.selectByNo(attNo);
			File f = (att == null) ? null : attachService.resolvePhysical(att);
			if (f == null) return;
			String base = (att.getName() != null && !att.getName().isEmpty())
					? att.getName() : ("attach_" + attNo);
			String entryName = dedupName(base, usedNames);
			usedNames.add(entryName);
			zos.putNextEntry(new ZipEntry(entryName));
			try (InputStream in = new BufferedInputStream(new FileInputStream(f))) {
				byte[] buf = new byte[8192];
				int n;
				while ((n = in.read(buf)) > 0) zos.write(buf, 0, n);
			}
			zos.closeEntry();
			// ZIP 에 실제로 담긴 파일도 1회 다운로드로 집계 (2026-07-30)
			try { attachMapper.increaseDownloadCount(attNo); } catch (Exception ignore) { }
		} catch (IOException ignore) {
			// 한 항목 실패가 전체 ZIP 을 막지 않게 — skip
		}
	}

	/** "name.ext" 가 이미 있으면 "name (2).ext", "name (3).ext" 로 회피 */
	private String dedupName(String name, Set<String> used) {
		if (!used.contains(name)) return name;
		int dot = name.lastIndexOf('.');
		String stem = (dot > 0) ? name.substring(0, dot) : name;
		String ext  = (dot > 0) ? name.substring(dot) : "";
		for (int i = 2; i < 9999; i++) {
			String cand = stem + " (" + i + ")" + ext;
			if (!used.contains(cand)) return cand;
		}
		return name + "-" + System.nanoTime();
	}

	/** RFC 5987 + ISO-8859-1 두 필드를 함께 — 브라우저 호환 */
	private String buildContentDisposition(String filename, boolean attachment) {
		String prefix = attachment ? "attachment" : "inline";
		String enc;
		try {
			enc = URLEncoder.encode(filename, "UTF-8").replace("+", "%20");
		} catch (Exception e) {
			enc = filename;
		}
		String iso;
		try {
			iso = new String(filename.getBytes("UTF-8"), "ISO-8859-1");
		} catch (Exception e) {
			iso = filename;
		}
		return prefix + "; filename=\"" + iso + "\"; filename*=UTF-8''" + enc;
	}

	/**
	 *  GET /rlms/related/relDetail.do?relVrsnNo=&kind=
	 *   - 5c 항목 클릭 상세 모달용 kind별 정보 반환.
	 *   - kind: file/word/orgn/image/html/url/dmn
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/relDetail.do")
	public Map<String,Object> relDetail(
			@RequestParam("relVrsnNo") Long relVrsnNo,
			@RequestParam("kind")      String kind) {
		if (!viewAllowed()) return fail("UNAUTHORIZED");
		// 분류별 열람제한 — relVrsnNo 로 소유 규정 해석 후 차단 (직접 호출/enum 방어)
		RelVrsnVO master = relVrsnService.getByNo(relVrsnNo);
		if (master != null && master.getPromNo() != null
				&& !promReadGuard.canReadProm(master.getPromNo())) {
			return fail("FORBIDDEN");
		}
		Map<String,Object> r = ok();
		r.put("kind", kind);
		r.put("relVrsnNo", relVrsnNo);
		if ("file".equals(kind)) {
			r.put("items", relFileService.getList(relVrsnNo));
		} else if ("orgn".equals(kind)) {
			r.put("items", relOrgnService.getList(relVrsnNo));
		} else if ("image".equals(kind)) {
			r.put("items", relImgService.getList(relVrsnNo));
		} else if ("word".equals(kind)) {
			r.put("items", relWordService.getList(relVrsnNo));
		} else if ("html".equals(kind)) {
			r.put("items", relHtmlService.getList(relVrsnNo));
		} else if ("url".equals(kind)) {
			r.put("items", relLnkService.getList(relVrsnNo));
		} else if ("dmn".equals(kind)) {
			// dmn 마스터의 IRVRSN_NO 는 VARCHAR2 라 String 변환
			r.put("items", relDmnLnkService.getList(String.valueOf(relVrsnNo)));
		} else {
			r.put("items", new ArrayList<>());
		}
		return r;
	}

	/**
	 *  POST /rlms/related/deleteMaster.do?relVrsnNo=&kind=
	 *   - 우측 목록의 한 항목(마스터) 통째 삭제.
	 *   - kind 별로 자식 서비스 dispatch → 각 자식 .delete() 가 attach 정리 + 마지막 자식이면 마스터까지 정리.
	 */
	@ResponseBody
	@RequestMapping("/rlms/related/deleteMaster.do")
	public Map<String,Object> deleteMaster(
			@RequestParam("relVrsnNo") Long relVrsnNo,
			@RequestParam("kind")      String kind) {
		if (!authed()) return fail("UNAUTHORIZED");
		try {
			// 1) 자식 행 정리 — 각 자식 .delete() 가 attach 정리까지 처리
			if ("file".equals(kind)) {
				for (RelFileVO c : relFileService.getList(relVrsnNo))   relFileService.delete(c.getRelFileNo());
			} else if ("orgn".equals(kind)) {
				for (RelOrgnVO c : relOrgnService.getList(relVrsnNo))   relOrgnService.delete(c.getRelOrgnNo());
			} else if ("image".equals(kind)) {
				for (RelImgVO  c : relImgService.getList(relVrsnNo))    relImgService.delete(c.getRelImgNo());
			} else if ("word".equals(kind)) {
				for (RelWordVO c : relWordService.getList(relVrsnNo))   relWordService.delete(c.getRelWordNo());
			} else if ("html".equals(kind)) {
				for (RelHtmlVO c : relHtmlService.getList(relVrsnNo))   relHtmlService.delete(c.getRelHtmlNo());
			} else if ("url".equals(kind)) {
				for (RelLnkVO  c : relLnkService.getList(relVrsnNo))    relLnkService.delete(c.getRelLnkNo());
			} else if ("dmn".equals(kind)) {
				// DMN_LNK.IRVRSN_NO 는 VARCHAR2 — String 변환
				for (RelDmnLnkVO c : relDmnLnkService.getList(String.valueOf(relVrsnNo)))
					relDmnLnkService.delete(c.getRelDmnLnkNo());
			} else {
				return fail("delete.kind.unsupported");
			}
			// 2) 마스터(TB_REL_VRSN) 강제 정리 — orphan/STABLE 불일치 케이스 대비.
			//    자식 .delete() 가 이미 마지막 자식이면 마스터를 지웠더라도
			//    여기 호출은 멱등(이미 없는 행은 0건 영향) 이라 안전.
			try { relVrsnService.delete(relVrsnNo); } catch (Exception ignore) { /* 이미 삭제됨 */ }
			return ok();
		} catch (Exception e) {
			return fail(e.getMessage() != null ? e.getMessage() : "delete.fail");
		}
	}
}
