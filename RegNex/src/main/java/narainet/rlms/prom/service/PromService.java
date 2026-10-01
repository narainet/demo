/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/PromService.java
 */
package narainet.rlms.prom.service;

import java.util.List;
import java.util.Map;

/**
 * 법령(TB_PROM) 관리 Service 인터페이스
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
public interface PromService {

	/** 목록 (페이징/검색/유효 row) */
	Map<String, Object> selectPromList(PromVO vo);

	/** 상세 (PK) */
	PromVO selectPromDetail(Long promNo);

	/** 같은 법령의 모든 개정본 */
	List<PromVO> selectPromHistory(Long lawId, String sysId);

	/** 직전 개정본 */
	PromVO selectPreviousProm(Long promNo);

	/** 작업중 draft 여부 — SEXISTING_YN='N' + 최신 워크상태 편집중/승인요청/승인반려 (front 비노출 게이트 기준) */
	boolean isWorkingDraftProm(Long promNo);

	/**
	 * 신규 등록 (lawId 가 null/0 이면 신규 법령, 아니면 개정본).
	 * PK 채번 + sequence/lawId 자동 설정.
	 */
	void insertProm(PromVO vo) throws Exception;

	/** 수정 */
	void updateProm(PromVO vo) throws Exception;

	/**
	 * 단건 삭제 + 유효 플래그 재배치.
	 * 트리거가 PROV_*, REL_VRSN, DOCU, SRC_STORED cascade 삭제.
	 * 같은 lawId 의 남은 row 중 가장 최신을 EXISTING='Y' 로 승격.
	 */
	void deleteProm(Long promNo) throws Exception;

	/** 다건 삭제 + 각 lawId 별 유효 플래그 재배치 */
	void deletePromList(List<Long> promNoList) throws Exception;

	/** 분류 내 정렬순서 변경 */
	void updateSequence(Long promNo, Integer seq) throws Exception;

	/** 다른 분류로 이동 */
	void moveCategory(Long promNo, Long newCateNo) throws Exception;

	// ── Front 검색 5종 ─────────────────────────────────────────────

	/** 연혁검색 */
	Map<String, Object> selectFrontHistoryList(PromVO vo);

	/** 연혁검색 현행 목록 — 현행본만 */
	Map<String, Object> selectFrontCurrentList(PromVO vo);

	/** 상세검색 (레거시 상세검색하기) — 현행 규정 + 검색단위/자음·영문/날짜타입/부서/분류 */
	Map<String, Object> selectDetailSearch(PromVO vo);

	/** 상세검색 소관부서 드롭다운 */
	List<Map<String, Object>> selectDetailBuseoList();

	/** 상세검색 규정분류 드롭다운 */
	List<Map<String, Object>> selectDetailCateList();

	/** 폐지 목록 */
	Map<String, Object> selectFrontNullifyList(PromVO vo);

	/** 최근 개정내용 */
	Map<String, Object> selectFrontLatestList(PromVO vo);

	/** 신구대조 후보 (좌/우 선택용) */
	List<PromVO> selectComparisonCandidates(Long lawId);

	/**
	 * 연혁번호(ILAW_NO) 자동 제안 — 레거시 체계 "제정=10, 개정마다 +10". 연혁등록 폼 prefill 용.
	 */
	Long suggestNextLawNo(Long lawId);
}
