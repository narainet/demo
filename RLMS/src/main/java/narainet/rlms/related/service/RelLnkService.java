/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelLnkService.java
 *
 * 관련자료 — LINK 액션 Service. 레거시 RelatedController.urlUpdateDo (1738-1851) 1:1.
 *  DELETE-then-INSERT 패턴 (B4 DOMAIN_LINK 와 동일).
 */
package narainet.rlms.related.service;

import java.util.List;

public interface RelLnkService {

	List<RelLnkVO> getList(Long relVrsnNo);

	/** 회차+fullItem 마스터의 링크 목록 — UI 모달 진입 시 초깃값 */
	List<RelLnkVO> getListByPromAndFullItem(Long promNo, String flag, String fullItem);

	RelLnkVO getByNo(Long relLnkNo);

	/**
	 * URL 링크 배열 저장.
	 *  - 마스터 없으면 getOrCreateMaster
	 *  - 기존 자식 모두 삭제 → 새 items 를 ISEQ=1.. 로 INSERT (레거시 DELETE-then-INSERT)
	 *  - items 빈 배열 = 전체 클리어
	 *  Returns 적용된 IRVRSN_NO.
	 */
	Long saveLinks(Long promNo, String flag, String fullItem, String sysId,
			List<RelLnkVO> items) throws Exception;

	void delete(Long relLnkNo) throws Exception;
}
