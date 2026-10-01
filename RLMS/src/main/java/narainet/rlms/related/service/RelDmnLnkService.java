/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelDmnLnkService.java
 *
 * 관련자료 — DOMAIN_LINK 액션 Service.
 *  saveLinks: 회차 단위 마스터 1건 아래 여러 링크 row 를 DELETE-then-INSERT.
 *  레거시 RelatedController.domainLinkUpdateDo (RelatedController.java:1885-1973) 1:1.
 */
package narainet.rlms.related.service;

import java.util.List;

public interface RelDmnLnkService {

	/** 마스터의 자식 링크 목록 (대상 규정 라벨링 포함) */
	List<RelDmnLnkVO> getList(String relVrsnNo);

	/** 회차+fullItem 마스터의 링크 목록 — UI 가 처음 모달 열 때 호출 */
	List<RelDmnLnkVO> getListByPromAndFullItem(Long promNo, String flag, String fullItem);

	RelDmnLnkVO getByNo(Long relDmnLnkNo);

	/**
	 * 링크 배열 저장 (DELETE-then-INSERT).
	 *  - 마스터 없으면 getOrCreateMaster 로 발급
	 *  - 기존 자식 모두 삭제
	 *  - 새 items 를 ISEQ=1.. 로 차례 INSERT (items 빈 배열이면 전체 클리어 효과)
	 *  Returns 적용된 IRVRSN_NO (String — 스키마 VARCHAR2).
	 */
	String saveLinks(Long promNo, String flag, String fullItem, String sysId,
			List<RelDmnLnkVO> items) throws Exception;

	/** 단건 물리 삭제 (마스터 비면 정리) */
	void delete(Long relDmnLnkNo) throws Exception;
}
