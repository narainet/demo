/*
 * 물리적 저장 경로: /src/main/java/narainet/law/lawyer/mapper/LawLawyerMapper.java
 */
package narainet.law.lawyer.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.lawyer.service.LawLawyerVO;

@Mapper
public interface LawLawyerMapper {

	int selectLawyerCnt(LawLawyerVO searchVO);

	/** 목록 — 만족도 평균·건수, 선임 건수 집계 동봉(집합 1회) */
	List<LawLawyerVO> selectLawyerList(LawLawyerVO searchVO);

	LawLawyerVO selectLawyer(@Param("lawyerId") Long lawyerId);

	void insertLawyer(LawLawyerVO vo);

	void updateLawyer(LawLawyerVO vo);

	/** 소프트삭제 (DEL_YN='Y') */
	void deleteLawyer(LawLawyerVO vo);

	/** 선임 참조 건수 — 삭제 차단 판단 */
	int countAssignRef(@Param("lawyerId") Long lawyerId);
}
