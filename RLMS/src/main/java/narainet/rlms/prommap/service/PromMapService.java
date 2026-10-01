/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prommap/service/PromMapService.java
 */
package narainet.rlms.prommap.service;

import java.util.List;

/**
 * 기능별분류(규정맵) Service. 레거시 PromulgationMapController 의 비즈니스 로직 이관.
 */
public interface PromMapService {

	/** 전체 기능별분류 트리 (CONNECT BY) */
	List<PromMapVO> selectMapTree(String sysId);

	/**
	 * 분류 가져오기 — 선택한 1차 분류(cateNo)와 그 하위(하위분류+규정)를
	 * 기능별분류 트리에 재귀 복사. refPmapNo 가 null/0 이면 루트로, 아니면 그 폴더 밑으로.
	 * (레거시 categoryInsertDo / categorySubInsertDo 의 분류 분기)
	 */
	void importCategory(Long cateNo, Long refPmapNo, String sysId) throws Exception;

	/**
	 * 규정 1건 가져오기 — 선택한 법령(promNo)을 기능별분류 폴더(refPmapNo) 밑 leaf 로 추가.
	 * (레거시 categorySubInsertDo 의 규정 분기)
	 */
	void addPromLeaf(Long promNo, Long refPmapNo, String sysId) throws Exception;

	/** 노드명 변경 (레거시 updateDo) */
	void renameMap(Long pmapNo, String name) throws Exception;

	/** 노드 + 하위 전체 삭제 (레거시 deleteDo, BFS). 삭제된 노드 수 반환. */
	int deleteMapSubtree(Long pmapNo) throws Exception;

	/** front 규정목록 — 폴더(pmapNo) 직속 규정 leaf 의 현행 법령들 */
	List<PromMapVO> selectPromulgationList(Long pmapNo);

	/** 법령 삭제 연동 — 그 법령을 가리키는 규정 leaf 정리(고아 방지). 삭제 수 반환. */
	int cleanupByPromNo(Long promNo);
}
