/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/FullTextSearchService.java
 */
package narainet.rlms.prom.service;

import java.util.Map;

/**
 * 본문 전문 검색 Service.
 * - Oracle Text 인덱스(IDX_PROV_VRSN_FT) 활용
 * - 결과는 TB_PROV_VRSN row 목록 + SCORE(1) rank
 */
public interface FullTextSearchService {

	/**
	 * 키워드로 본문 단위 row 검색.
	 * @param sysId 시스템 ID
	 * @param keyword Oracle Text CONTAINS 표현식 (단순 키워드 또는 'A AND B', '"구문 검색"' 등)
	 * @param pageIndex 페이지
	 * @param pageUnit 페이지당 건수
	 * @return resultList(List&lt;ProvVrsnVO&gt;), resultCnt(String), paginationInfo
	 */
	Map<String, Object> searchInProvVrsn(String sysId, String keyword,
			int pageIndex, int pageUnit);
}
