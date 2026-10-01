/*
 * 물리적 저장 경로: /src/main/java/narainet/law/seize/mapper/LawSeizeMapper.java
 *
 * 압류관리(LAW_SEIZE) 조회·저장·삭제·조회수. §7.10
 */
package narainet.law.seize.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.seize.service.LawSeizeVO;

@Mapper
public interface LawSeizeMapper {

	List<LawSeizeVO> selectSeizeList(LawSeizeVO searchVO);

	int selectSeizeCnt(LawSeizeVO searchVO);

	LawSeizeVO selectSeize(@Param("seizeId") Long seizeId);

	void insertSeize(LawSeizeVO vo);

	void updateSeize(LawSeizeVO vo);

	void deleteSeize(@Param("seizeId") Long seizeId);

	/** 조회수 +1 */
	void updateReadCnt(@Param("seizeId") Long seizeId);
}
