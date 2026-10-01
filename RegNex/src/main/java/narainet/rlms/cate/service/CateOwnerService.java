/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/CateOwnerService.java
 */
package narainet.rlms.cate.service;

import java.util.List;
import java.util.Map;

/**
 * 분류별 작성자(소유) 서비스.
 *  - 작성자 N명 지정/해제.
 *  - 규정 수정 작성권한 가드(canEdit): 관리자는 호출측에서 선통과, 그 외 분류 작성자만 true.
 */
public interface CateOwnerService {

	/** 특정 분류의 작성자 목록 */
	List<CateOwnerVO> selectOwners(Long cateNo);

	/** 작성자 추가 (중복이면 무시) */
	void addOwner(CateOwnerVO vo);

	/** 작성자 삭제 */
	void removeOwner(Long cateNo, String ownerTy, String ownerId);

	/**
	 * 작성권한 판정. 규정의 분류(또는 상속된 조상분류)의 작성자면 true.
	 * ※ 관리자(ROLE_ADMIN)는 이 메서드 호출 전에 통과시킬 것.
	 *
	 * @param esntlId  현재 사용자 ESNTL_ID
	 * @param orgnztId 현재 사용자 ORGNZT_ID (없으면 null)
	 * @param cateNo   규정의 분류번호
	 */
	boolean canEdit(String esntlId, String orgnztId, Long cateNo);

	/** 이 분류에 적용되는 작성자 규칙(자기분류 직접 OR 조상 상속)이 하나라도 있는가.
	 *  false = 작성자 미지정 분류 → 규정 소관부서 폴백(PromEditGuard, 2026-07-20 사용자 결정) */
	boolean hasOwnerRules(Long cateNo);

	/** 부서 옵션 목록 (작성자 부서 선택 드롭다운) */
	List<Map<String, Object>> selectDeptOptions();
}
