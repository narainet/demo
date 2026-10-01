/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/mapper/CateOwnerMapper.java
 */
package narainet.rlms.cate.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.cate.service.CateOwnerVO;

/**
 * 분류별 작성자(소유) 매퍼 (TB_CATE_OWNER)
 */
@Mapper
public interface CateOwnerMapper {

	/** 특정 분류의 작성자 목록 (부서/개인, 표시명 해석 포함) */
	List<CateOwnerVO> selectOwnersByCate(@Param("cateNo") Long cateNo);

	/** 작성자 추가 (PK 중복은 호출측에서 selectOne 으로 사전 차단 또는 MERGE 미사용) */
	int insertOwner(CateOwnerVO vo);

	/** 작성자 삭제 (PK 단건) */
	int deleteOwner(@Param("cateNo") Long cateNo,
			@Param("ownerTy") String ownerTy,
			@Param("ownerId") String ownerId);

	/** PK 존재 여부 (중복 추가 방지) */
	int countOwner(@Param("cateNo") Long cateNo,
			@Param("ownerTy") String ownerTy,
			@Param("ownerId") String ownerId);

	/**
	 * 작성권한 가드 — 결과>0 이면 해당 사용자가 그 분류(또는 상속된 조상분류)의 작성자.
	 * 관리자(ROLE_ADMIN)는 호출측에서 먼저 통과시키고, 그 외에만 사용.
	 *
	 * @param esntlId  현재 사용자 ESNTL_ID (USER 소유 매칭)
	 * @param orgnztId 현재 사용자 ORGNZT_ID (DEPT 소유 매칭)
	 * @param cateNo   규정의 분류번호
	 */
	int countAuthor(@Param("esntlId") String esntlId,
			@Param("orgnztId") String orgnztId,
			@Param("cateNo") Long cateNo);

	/** 이 분류에 적용되는 작성자 규칙 수(사용자 매칭 무관) — 0=미지정 분류(소관부서 폴백) */
	int countApplicableOwnerRules(@Param("cateNo") Long cateNo);

	/** 부서 옵션 목록 (작성자 부서 선택 드롭다운) — ORGNZT_ID, ORGNZT_NM */
	List<Map<String, Object>> selectDeptOptions();
}
