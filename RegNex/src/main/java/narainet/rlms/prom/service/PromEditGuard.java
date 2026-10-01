/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/PromEditGuard.java
 *
 * 규정 작성권한 가드 (데이터 스코핑, 축 B).
 *   허용 = 관리자(ROLE_ADMIN)
 *          OR 분류 작성자 지정 시: 규정의 분류(또는 상속된 조상분류) 작성자(TB_CATE_OWNER 부서/개인)
 *          OR 작성자 미지정 분류: 규정 소관부서 소속원 (2026-07-20 사용자 결정 — 수정권한 워크플로 폐지 대체).
 *   ★승인요청 잠금(2026-07-20): 최신 워크가 '승인요청'(심사 중)이면 관리자 포함 전원 편집 잠금 —
 *     승인자가 본 내용과 승인된 내용이 달라지는 표류 방지. 반려/승인 처리 후 자동 해제.
 */
package narainet.rlms.prom.service;

import java.util.List;

import javax.annotation.Resource;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Component;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.cate.service.CateOwnerService;
import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.promwork.service.PromWorkVO;

@Component("promEditGuard")
public class PromEditGuard {

	@Resource(name = "cateOwnerService")
	private CateOwnerService cateOwnerService;

	@Resource
	private PromMapper promMapper;

	@Resource
	private narainet.rlms.promwork.mapper.PromWorkMapper promWorkMapper;

	/** 전체권한(관리자) 보유 여부 */
	public boolean isAdmin() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && auths.contains("ROLE_ADMIN");
	}

	/** 승인요청 심사 중(최신 워크='승인요청') 편집 잠금 여부 — 관리자 포함 전원 적용 */
	public boolean isApprovalLocked(Long promNo) {
		if (promNo == null) {
			return false;
		}
		try {
			PromWorkVO latest = promWorkMapper.selectLatestByPromNo(promNo);
			return latest != null && PromWorkVO.STATUS_REQ_PEND.equals(latest.getStatus());
		} catch (Exception e) {
			return false;   // 워크 조회 실패는 잠금으로 확대하지 않음(작성권한 축이 본선)
		}
	}

	/** 해당 분류(또는 상속 조상분류)에 작성권한이 있는가 — 관리자는 무조건 true.
	 *  작성자 미지정 분류는 개방(신규 등록 진입) — 등록된 규정의 편집은 canEditProm 이 소관부서로 좁힌다. */
	public boolean canEditCate(Long cateNo) {
		if (isAdmin()) {
			return true;
		}
		LoginVO u = currentUser();
		if (u == null || cateNo == null) {
			return false;
		}
		if (cateOwnerService.hasOwnerRules(cateNo)) {
			return cateOwnerService.canEdit(u.getUniqId(), u.getOrgnztId(), cateNo);
		}
		return true;   // 미지정 분류 — 부서원 누구나 작성 가능 (2026-07-20)
	}

	/** 해당 규정에 작성권한이 있는가 (규정→분류 해석) — 승인요청 심사 중이면 관리자 포함 false */
	public boolean canEditProm(Long promNo) {
		if (promNo == null) {
			return false;
		}
		if (isApprovalLocked(promNo)) {
			return false;
		}
		if (isAdmin()) {
			return true;
		}
		PromVO p = promMapper.selectPromByNo(promNo);
		if (p == null) {
			return false;
		}
		LoginVO u = currentUser();
		if (u == null) {
			return false;
		}
		Long cateNo = p.getCateNo();
		if (cateNo != null && cateOwnerService.hasOwnerRules(cateNo)) {
			return cateOwnerService.canEdit(u.getUniqId(), u.getOrgnztId(), cateNo);
		}
		// 작성자 미지정 분류 — 규정 소관부서 소속원 허용 (2026-07-20 사용자 결정)
		String promOrg = effectiveBuseoOrgnztId(p);
		return promOrg != null && promOrg.equals(u.getOrgnztId());
	}

	/** 규정의 소관부서 ORGNZT_ID — SBUSEO_ORGNZT_ID 우선, 없으면 레거시 IBUSEO_NO 파생. 미지정 센티넬은 null */
	private static String effectiveBuseoOrgnztId(PromVO p) {
		String oid = p.getBuseoOrgnztId() != null ? p.getBuseoOrgnztId().trim() : null;
		if (oid == null || oid.isEmpty()) {
			Long no = p.getBuseoNo();
			if (no != null && no > 0L) {
				oid = String.format("ORG_%016d", no);
			}
		}
		return (oid == null || oid.isEmpty() || "ORG_0000000000000000".equals(oid)) ? null : oid;
	}

	/** 규정 작성권한 강제 — 없으면 AccessDeniedException (승인요청 잠금은 사유를 구분해 안내) */
	public void assertCanEditProm(Long promNo) {
		if (isApprovalLocked(promNo)) {
			throw new AccessDeniedException("승인요청 심사 중이라 편집이 잠겨 있습니다. 승인/반려 처리 후 편집할 수 있습니다.");
		}
		if (!canEditProm(promNo)) {
			throw new AccessDeniedException("이 규정의 작성권한이 없습니다. (관리자·분류 작성자 또는 소관부서 소속원만 수정 가능)");
		}
	}

	/** 분류 작성권한 강제 — 없으면 AccessDeniedException */
	public void assertCanEditCate(Long cateNo) {
		if (!canEditCate(cateNo)) {
			throw new AccessDeniedException("이 분류의 작성권한이 없습니다. (관리자 또는 분류 작성자만)");
		}
	}

	private LoginVO currentUser() {
		try {
			Object u = EgovUserDetailsHelper.getAuthenticatedUser();
			return (u instanceof LoginVO) ? (LoginVO) u : null;
		} catch (Exception e) {
			return null;
		}
	}
}
