/*
 * 물리적 저장 경로: /src/main/java/narainet/law/cost/service/LawCostService.java
 */
package narainet.law.cost.service;

import java.util.List;
import java.util.Map;

public interface LawCostService {

	/** 조회 목록+총건수+합계 (resultList/resultCnt/totalAmt) */
	Map<String, Object> getList(LawSuitCostVO searchVO) throws Exception;

	/** 사건 상세 탭용 — 특정 사건의 비용 목록 */
	List<LawSuitCostVO> getListBySuit(Long suitId) throws Exception;

	LawSuitCostVO getCost(Long costId) throws Exception;

	Long save(LawSuitCostVO vo, String userId) throws Exception;

	void delete(Long costId) throws Exception;
}
