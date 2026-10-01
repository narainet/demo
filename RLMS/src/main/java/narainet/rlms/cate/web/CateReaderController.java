/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/web/CateReaderController.java
 *
 * 분류별 열람제한 관리 Controller.
 *  - 열람대상 지정/해제는 관리자(ROLE_ADMIN)만. 목록 조회는 인증 사용자.
 *  - 분류 트리 화면(권한 관리 모달 '열람 제한' 탭)에서 분류 선택 후 대상 N명을 부서/개인으로 추가.
 *  - 부서 드롭다운은 기존 /rlms/cate/ownerDeptOptions.do 재사용.
 */
package narainet.rlms.cate.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.cate.service.CateReaderService;
import narainet.rlms.cate.service.CateReaderVO;

/**
 * 분류별 열람제한 Controller
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.07   RLMS 전환팀   최초 생성 (TB_CATE_OWNER 패턴 미러 — read 축 신설)
 * </pre>
 */
@Controller
public class CateReaderController {

	private static final Logger LOGGER = LoggerFactory.getLogger(CateReaderController.class);

	@Resource(name = "cateReaderService")
	private CateReaderService cateReaderService;

	/** 특정 분류의 열람대상 목록 (JSON) */
	@ResponseBody
	@RequestMapping("/rlms/cate/readerListJson.do")
	public Map<String, Object> listJson(@RequestParam("cateNo") Long cateNo) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		List<CateReaderVO> list = cateReaderService.selectReaders(cateNo);
		result.put("success", true);
		result.put("resultList", list);
		return result;
	}

	/** 열람대상 추가 (부서/개인) — 관리자만 */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/cate/readerInsert.do")
	public Map<String, Object> insert(@RequestParam("cateNo") Long cateNo,
			@RequestParam("readerTy") String readerTy,
			@RequestParam("readerId") String readerId,
			@RequestParam(value = "inheritYn", required = false, defaultValue = "Y") String inheritYn) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!isAdmin()) {
			result.put("success", false);
			result.put("resultMsg", "FORBIDDEN");
			return result;
		}
		try {
			CateReaderVO vo = new CateReaderVO();
			vo.setCateNo(cateNo);
			vo.setReaderTy(readerTy);
			vo.setReaderId(readerId);
			vo.setInheritYn(inheritYn);
			vo.setInsId(resolveLoginId());
			cateReaderService.addReader(vo);
			result.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("Failed to add cate reader.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 열람대상 삭제 — 관리자만 */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/cate/readerDelete.do")
	public Map<String, Object> delete(@RequestParam("cateNo") Long cateNo,
			@RequestParam("readerTy") String readerTy,
			@RequestParam("readerId") String readerId) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!isAdmin()) {
			result.put("success", false);
			result.put("resultMsg", "FORBIDDEN");
			return result;
		}
		try {
			cateReaderService.removeReader(cateNo, readerTy, readerId);
			result.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("Failed to delete cate reader.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 사용자 검색 — 이름/로그인ID 부분일치 (개인 열람대상 선택 UI) */
	@ResponseBody
	@RequestMapping("/rlms/cate/readerUserSearch.do")
	public Map<String, Object> userSearch(@RequestParam("keyword") String keyword) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		result.put("success", true);
		result.put("resultList", cateReaderService.searchUsers(keyword));
		return result;
	}

	// ── 구분(최상위 SGUBUN_ID) 단위 열람제한 ─────────────────────────

	/** 특정 구분의 열람대상 목록 (JSON) */
	@ResponseBody
	@RequestMapping("/rlms/cate/readerGubunListJson.do")
	public Map<String, Object> gubunListJson(@RequestParam("gubunId") String gubunId) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		result.put("success", true);
		result.put("resultList", cateReaderService.selectGubunReaders(gubunId));
		return result;
	}

	/** 구분 열람대상 추가 (부서/개인) — 관리자만 */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/cate/readerGubunInsert.do")
	public Map<String, Object> gubunInsert(@RequestParam("gubunId") String gubunId,
			@RequestParam("readerTy") String readerTy,
			@RequestParam("readerId") String readerId) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!isAdmin()) {
			result.put("success", false);
			result.put("resultMsg", "FORBIDDEN");
			return result;
		}
		try {
			CateReaderVO vo = new CateReaderVO();
			vo.setGubunId(gubunId);
			vo.setReaderTy(readerTy);
			vo.setReaderId(readerId);
			vo.setInsId(resolveLoginId());
			cateReaderService.addGubunReader(vo);
			result.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("Failed to add gubun reader.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 구분 열람대상 삭제 — 관리자만 */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/cate/readerGubunDelete.do")
	public Map<String, Object> gubunDelete(@RequestParam("gubunId") String gubunId,
			@RequestParam("readerTy") String readerTy,
			@RequestParam("readerId") String readerId) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!isAdmin()) {
			result.put("success", false);
			result.put("resultMsg", "FORBIDDEN");
			return result;
		}
		try {
			cateReaderService.removeGubunReader(gubunId, readerTy, readerId);
			result.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("Failed to delete gubun reader.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** ROLE_ADMIN 보유 여부 — servlet context 에는 method-security 미선언이라 @PreAuthorize 보조로 본문 명시 검사 */
	private boolean isAdmin() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && auths.contains("ROLE_ADMIN");
	}

	/** 현재 로그인 사용자 ID (등록자 기록용) — 미확인 시 null */
	private String resolveLoginId() {
		try {
			Object user = EgovUserDetailsHelper.getAuthenticatedUser();
			if (user instanceof egovframework.com.cmm.LoginVO) {
				return ((egovframework.com.cmm.LoginVO) user).getId();
			}
		} catch (Exception ignore) {
			// 무시 — 등록자 미기록
		}
		return null;
	}
}
