/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/web/CateOwnerController.java
 *
 * 분류별 작성자(소유) 관리 Controller.
 *  - 작성자 지정/해제는 관리자(ROLE_ADMIN)만. 목록 조회는 인증 사용자.
 *  - 분류 트리 화면에서 분류 선택 후 작성자 N명을 부서/개인으로 추가.
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
import narainet.rlms.cate.service.CateOwnerService;
import narainet.rlms.cate.service.CateOwnerVO;

/**
 * 분류별 작성자 Controller
 *
 * <pre>
 * << 개정이력 >>
 *   2026.06.09   RLMS 전환팀   최초 생성 (분류정책 단순화)
 * </pre>
 */
@Controller
public class CateOwnerController {

	private static final Logger LOGGER = LoggerFactory.getLogger(CateOwnerController.class);

	@Resource(name = "cateOwnerService")
	private CateOwnerService cateOwnerService;

	/** 부서 옵션 (작성자 부서 선택 드롭다운) */
	@ResponseBody
	@RequestMapping("/rlms/cate/ownerDeptOptions.do")
	public Map<String, Object> deptOptions() {
		Map<String, Object> result = new LinkedHashMap<>();
		result.put("success", true);
		result.put("resultList", cateOwnerService.selectDeptOptions());
		return result;
	}

	/** 특정 분류의 작성자 목록 (JSON) */
	@ResponseBody
	@RequestMapping("/rlms/cate/ownerListJson.do")
	public Map<String, Object> listJson(@RequestParam("cateNo") Long cateNo) {
		Map<String, Object> result = new LinkedHashMap<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			result.put("success", false);
			result.put("resultMsg", "UNAUTHORIZED");
			return result;
		}
		List<CateOwnerVO> list = cateOwnerService.selectOwners(cateNo);
		result.put("success", true);
		result.put("resultList", list);
		return result;
	}

	/** 작성자 추가 (부서/개인) — 관리자만 */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/cate/ownerInsert.do")
	public Map<String, Object> insert(@RequestParam("cateNo") Long cateNo,
			@RequestParam("ownerTy") String ownerTy,
			@RequestParam("ownerId") String ownerId,
			@RequestParam(value = "inheritYn", required = false, defaultValue = "Y") String inheritYn) {
		Map<String, Object> result = new LinkedHashMap<>();
		try {
			CateOwnerVO vo = new CateOwnerVO();
			vo.setCateNo(cateNo);
			vo.setOwnerTy(ownerTy);
			vo.setOwnerId(ownerId);
			vo.setInheritYn(inheritYn);
			vo.setInsId(resolveLoginId());
			cateOwnerService.addOwner(vo);
			result.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("Failed to add cate owner.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
	}

	/** 작성자 삭제 — 관리자만 */
	@PreAuthorize("hasRole('ADMIN')")
	@ResponseBody
	@RequestMapping("/rlms/cate/ownerDelete.do")
	public Map<String, Object> delete(@RequestParam("cateNo") Long cateNo,
			@RequestParam("ownerTy") String ownerTy,
			@RequestParam("ownerId") String ownerId) {
		Map<String, Object> result = new LinkedHashMap<>();
		try {
			cateOwnerService.removeOwner(cateNo, ownerTy, ownerId);
			result.put("success", true);
		} catch (Exception e) {
			LOGGER.warn("Failed to delete cate owner.", e);
			result.put("success", false);
			result.put("resultMsg", e.getMessage());
		}
		return result;
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
