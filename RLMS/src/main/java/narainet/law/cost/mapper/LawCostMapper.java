/*
 * 물리적 저장 경로: /src/main/java/narainet/law/cost/mapper/LawCostMapper.java
 *
 * 소송비용(LAW_SUIT_COST) 매퍼 — 조회 목록(합계 포함)·사건별 목록·CRUD. §7.3
 */
package narainet.law.cost.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.cost.service.LawSuitCostVO;

@Mapper
public interface LawCostMapper {

	int selectCostCnt(LawSuitCostVO searchVO);

	/** 조회 목록 (사건 조인·페이징) */
	List<LawSuitCostVO> selectCostList(LawSuitCostVO searchVO);

	/** 검색 전체 금액 합계 (합계 행) */
	Long selectCostSum(LawSuitCostVO searchVO);

	/** 사건 상세 탭용 — 특정 사건의 비용 목록 */
	List<LawSuitCostVO> selectCostListBySuit(@Param("suitId") Long suitId);

	LawSuitCostVO selectCost(@Param("costId") Long costId);

	void insertCost(LawSuitCostVO vo);

	void updateCost(LawSuitCostVO vo);

	void deleteCost(@Param("costId") Long costId);
}
