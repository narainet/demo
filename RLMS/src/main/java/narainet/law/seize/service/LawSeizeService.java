/*
 * 물리적 저장 경로: /src/main/java/narainet/law/seize/service/LawSeizeService.java
 */
package narainet.law.seize.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

public interface LawSeizeService {

	/** 목록 + 총건수 (검색축·기간) */
	Map<String, Object> getList(LawSeizeVO searchVO) throws Exception;

	/** 상세 — readCntUp=true 면 조회수 증가 후 조회 */
	LawSeizeVO getSeize(Long seizeId, boolean readCntUp) throws Exception;

	/** 신규/수정 저장(첨부 포함) */
	Long save(LawSeizeVO vo, List<MultipartFile> files, String userId) throws Exception;

	void delete(Long seizeId) throws Exception;
}
