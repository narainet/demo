/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelVrsnService.java
 *
 * 관련자료 마스터(TB_REL_VRSN) Service — 8 액션이 모두 진입점으로 사용.
 *  - getNewVersion / getNewHseqVersion : 새 마스터 row 발급 (액션별 INSERT 첫 단계)
 *  - getOrCreateMaster                 : LINK / DOMAIN_LINK 의 DELETE-then-INSERT 패턴용
 *  - update / delete                   : 메타 갱신 / 상세행 모두 비운 뒤 마스터 삭제
 *  - get*                              : 단건/목록 조회 (PromEditorController 의 READ 와 공유)
 */
package narainet.rlms.related.service;

import java.util.List;

public interface RelVrsnService {

	// ── 조회 ──────────────────────────────────────────────────────

	RelVrsnVO getByNo(Long relVrsnNo);

	List<RelVrsnVO> getByPromNo(Long promNo);

	List<RelVrsnVO> getByPromAndFullItem(Long promNo, String fullItem);

	/** 같은 도메인 (promNo + stable + flag + fullItem) 의 기존 마스터 — 없으면 null */
	RelVrsnVO getExistingMaster(Long promNo, String stable, String flag, String fullItem);

	// ── WRITE ─────────────────────────────────────────────────────

	/**
	 * 새 마스터 row 발급 (액션별 INSERT 의 첫 단계). FILE 외 7 액션 공통.
	 *  ICTNS_ID 는 매번 새로 발급 (회차간 누적 추적 기준).
	 *  ISEQ 는 호출자가 별도로 결정 후 update 로 채우거나 사용자 입력 반영.
	 *  Returns 새 IRVRSN_NO.
	 */
	Long getNewVersion(Long promNo, String vrsnYn, String stable, String flag,
			String fullItem, String title, Long cateNo, String sysId) throws Exception;

	/**
	 * FILE 액션 전용 — getNewVersion + 카테고리 메타(이름/순서) 포함.
	 *  IRVCATE_NM, IRVCATE_ODR 까지 채워 INSERT.
	 */
	Long getNewHseqVersion(Long promNo, String vrsnYn, String stable, String flag,
			String fullItem, String title, Long cateNo, String sysId,
			String cateName, Integer cateOrder) throws Exception;

	/**
	 * LINK / DOMAIN_LINK 의 DELETE-then-INSERT 패턴용:
	 *  기존 마스터(동일 promNo+stable+flag+fullItem) 가 있으면 그 IRVRSN_NO 반환,
	 *  없으면 getNewVersion 로 새 발급.
	 */
	Long getOrCreateMaster(Long promNo, String vrsnYn, String stable, String flag,
			String fullItem, String title, Long cateNo, String sysId) throws Exception;

	/** 메타 갱신 (제목/순서/카테고리 등) */
	void update(RelVrsnVO vo);

	/** 마스터 삭제 — 호출자가 상세 행 모두 처리 후 호출 */
	void delete(Long relVrsnNo);

	/** 회차 + 카테고리 안의 다음 ISEQ */
	Integer getNextSeq(Long promNo, Long cateNo);
}
