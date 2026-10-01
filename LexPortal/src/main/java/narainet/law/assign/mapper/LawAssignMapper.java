/*
 * 물리적 저장 경로: /src/main/java/narainet/law/assign/mapper/LawAssignMapper.java
 *
 * 선임(LAW_SUIT_LAWYER) + 만족도(LAW_LAWYER_SATIS) 매퍼. §7.6
 */
package narainet.law.assign.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.assign.service.LawLawyerSatisVO;
import narainet.law.assign.service.LawSuitLawyerVO;

@Mapper
public interface LawAssignMapper {

	int selectAssignCnt(LawSuitLawyerVO searchVO);

	/** 선임 목록 — 변호사·사건·소송결과·만족도 집계 동봉(집합 1회) */
	List<LawSuitLawyerVO> selectAssignList(LawSuitLawyerVO searchVO);

	/** 사건 상세 탭용 — 특정 사건의 선임 목록(페이징 없음) */
	List<LawSuitLawyerVO> selectAssignListBySuit(@Param("suitId") Long suitId);

	LawSuitLawyerVO selectAssign(@Param("assignId") Long assignId);

	void insertAssign(LawSuitLawyerVO vo);

	void updateAssign(LawSuitLawyerVO vo);

	void deleteAssign(@Param("assignId") Long assignId);

	// ── 만족도 ──
	/** 이 선임의 의견 목록 (평가자명 조인) */
	List<LawLawyerSatisVO> selectSatisList(@Param("assignId") Long assignId);

	/** 현재 사용자의 이 선임 평가(있으면) */
	LawLawyerSatisVO selectMySatis(@Param("assignId") Long assignId, @Param("emplyrId") String emplyrId);

	/** 1인 1회 MERGE (재평가=갱신) */
	void mergeSatis(LawLawyerSatisVO vo);
}
