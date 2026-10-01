/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/PromReadGuard.java
 *
 * 규정 열람제한 가드 (분류별 read 게이팅, TB_CATE_READER — PromEditGuard 미러).
 *   허용 = 면제역할(ROLE_ADMIN/EDITOR/APPROVER)  OR  제한 미지정 분류(전체 공개)
 *          OR  규정의 분류(또는 상속된 조상분류) 열람대상(부서/개인) 매칭.
 *   · 편집계 3역할은 편집/승인/미리보기 업무상 전체 열람 필요 → 면제.
 *   · 제한이 하나도 지정되지 않은 분류는 공개가 기본(미지정 = 전체 공개).
 */
package narainet.rlms.prom.service;

import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.annotation.Resource;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Component;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.cate.service.CateReaderService;
import narainet.rlms.prom.mapper.PromMapper;

@Component("promReadGuard")
public class PromReadGuard {

	@Resource(name = "cateReaderService")
	private CateReaderService cateReaderService;

	@Resource
	private PromMapper promMapper;

	/** 열람제한 면제 여부 — 편집계 3역할(ADMIN/EDITOR/APPROVER)은 전체 열람 */
	public boolean isExempt() {
		List<String> auths = EgovUserDetailsHelper.getAuthorities();
		return auths != null && (auths.contains("ROLE_ADMIN")
				|| auths.contains("ROLE_EDITOR")
				|| auths.contains("ROLE_APPROVER"));
	}

	/** 해당 분류의 규정을 열람할 수 있는가 — 면제역할/미지정 분류는 true */
	public boolean canReadCate(Long cateNo) {
		if (cateNo == null || isExempt()) {
			return true;
		}
		LoginVO u = currentUser();
		return cateReaderService.canRead(u != null ? u.getUniqId() : null,
				u != null ? u.getOrgnztId() : null, cateNo);
	}

	/**
	 * 해당 규정을 열람할 수 있는가 (규정→법령 해석) — 미존재 규정은 true(후속 404 처리에 위임).
	 * ★판정 기준 = 규정(법령)의 '현행(최신 회차)' 분류. 회차 간 분류가 갈라진 이력 데이터에서도
	 *   규정 단위로 일관 판정(과거 회차의 옛 공개분류를 통한 우회·과차단 방지).
	 */
	public boolean canReadProm(Long promNo) {
		if (promNo == null || isExempt()) {
			return true;
		}
		PromVO p = promMapper.selectPromByNo(promNo);
		return p == null || canRead(p);
	}

	/** 이미 로드된 회차 VO 로 판정 — 법령 단위(현행 분류) 기준. 재조회 없이 뷰어/상세 가드용 */
	public boolean canRead(PromVO p) {
		if (p == null || isExempt()) {
			return true;
		}
		if (p.getLawId() != null && p.getLawId() != 0L) {
			return canReadLaw(p.getLawId());
		}
		return canReadCate(p.getCateNo());
	}

	/** 법령(lawId) 단위 열람 가능 여부 — 최신 회차의 분류로 판정 (경량 쿼리, CLOB 미로드) */
	public boolean canReadLaw(Long lawId) {
		if (lawId == null || isExempt()) {
			return true;
		}
		Long cateNo = promMapper.selectLatestCateNoByLawId(lawId);
		return cateNo == null || canReadCate(cateNo);
	}

	/** 규정 열람 강제 — 없으면 AccessDeniedException */
	public void assertCanReadProm(Long promNo) {
		if (!canReadProm(promNo)) {
			throw new AccessDeniedException("이 규정은 열람 권한이 제한되어 있습니다. (지정된 부서/개인만 열람 가능)");
		}
	}

	/**
	 * front 목록 검색조건에 열람제한 SQL 게이트 파라미터 주입.
	 * 면제역할이면 아무것도 하지 않음(게이트 미적용).
	 */
	public void applyReadGate(PromVO searchVO) {
		if (searchVO == null || isExempt()) {
			return;
		}
		LoginVO u = currentUser();
		searchVO.setApplyReadGate(true);
		searchVO.setReaderEsntlId(u != null ? u.getUniqId() : null);
		searchVO.setReaderOrgnztId(u != null ? u.getOrgnztId() : null);
	}

	/** 게이트 적용 필요 여부 (@Param 직접 전달형 매퍼용) — 면제역할이면 false */
	public boolean gateNeeded() {
		return !isExempt();
	}

	/** 현재 사용자 ESNTL_ID (READER_TY='USER' 매칭용) — 비로그인 null */
	public String readerEsntlId() {
		LoginVO u = currentUser();
		return u != null ? u.getUniqId() : null;
	}

	/** 현재 사용자 ORGNZT_ID (READER_TY='DEPT' 매칭용) — 비로그인 null */
	public String readerOrgnztId() {
		LoginVO u = currentUser();
		return u != null ? u.getOrgnztId() : null;
	}

	/** 현재 사용자 기준 차단 분류번호 집합 (front 트리 필터용) — 면제역할은 빈 집합 */
	public Set<Long> blockedCateNos() {
		if (isExempt()) {
			return Collections.emptySet();
		}
		LoginVO u = currentUser();
		List<Long> list = cateReaderService.selectBlockedCateNos(
				u != null ? u.getUniqId() : null,
				u != null ? u.getOrgnztId() : null);
		return (list == null || list.isEmpty()) ? Collections.<Long>emptySet() : new HashSet<>(list);
	}

	/** 현재 사용자 기준 차단 규정번호 집합 (기능별분류 트리 필터용) — 면제역할은 빈 집합 */
	public Set<Long> blockedPromNos() {
		if (isExempt()) {
			return Collections.emptySet();
		}
		LoginVO u = currentUser();
		List<Long> list = cateReaderService.selectBlockedPromNos(
				u != null ? u.getUniqId() : null,
				u != null ? u.getOrgnztId() : null);
		return (list == null || list.isEmpty()) ? Collections.<Long>emptySet() : new HashSet<>(list);
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
