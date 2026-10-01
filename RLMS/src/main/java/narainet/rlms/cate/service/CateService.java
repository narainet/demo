/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/CateService.java
 */
package narainet.rlms.cate.service;

import java.util.List;
import java.util.Map;

/**
 * 법령 분류(TB_CATE) 트리 관리 Service
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
public interface CateService {

	/** 시스템별 전체 트리 (CONNECT BY 정렬 + 법령 카운트) */
	Map<String, Object> selectCateTree(String sysId);

	/**
	 * 시스템별 트리를 jsTree 호환 트리 (부모-자식 중첩) 로 재구성.
	 * 각 노드: {id, parent('#' 또는 부모 id), text, ...}
	 * @param includeHidden 숨김 구분(ccm USE_AT='N') 포함 여부 — 분류관리 화면만 true(복구 입구),
	 *                      front 검색 필터트리 등 그 외 소비자는 false(구분·소속 분류 통째 비노출)
	 */
	List<Map<String, Object>> selectCateTreeForJsTree(String sysId, boolean includeHidden);

	/** 단건 (PK) */
	CateVO selectCateByNo(Long cateNo);

	/** Oracle 함수로 풀네임 */
	String selectFullNameByNo(Long cateNo);

	/** 신규 등록 (ref/sysId 필수, level/refLv*  seq 자동 계산) */
	void insertCate(CateVO vo) throws Exception;

	/** 수정 */
	void updateCate(CateVO vo) throws Exception;

	/** 일괄 수정 (이름/표시/정렬만) */
	void updateCateList(List<CateVO> list) throws Exception;

	/**
	 * 소프트 삭제.
	 *  - 법령 종속(TB_PROM) 0건 + 하위 분류 0건일 때만 허용.
	 *  - 트리거 cascade 의 위험(법령까지 동반 삭제)을 회피.
	 */
	void deleteCate(Long cateNo) throws Exception;
}
