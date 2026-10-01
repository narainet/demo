/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/promwork/service/PromWorkService.java
 *
 * 법령 승인 워크플로 Service 인터페이스.
 */
package narainet.rlms.promwork.service;

import java.util.List;
import java.util.Map;

public interface PromWorkService {

	// ── 조회 ───────────────────────────────────────────────────────

	/** 작업승인 목록 (검색 + 페이징) */
	Map<String, Object> selectPromWorkList(PromWorkVO vo);

	/** 제·개정내역 관리 — 전역 액션 로그 목록 (검색 + 페이징) */
	Map<String, Object> selectActLogList(PromWorkActLogVO vo);

	/** 단건 상세 */
	PromWorkVO selectPromWorkDetail(Long workNo);

	/** 특정 법령(promNo) 의 최신 워크 상태 */
	PromWorkVO selectLatestByPromNo(Long promNo);

	/** 특정 법령의 워크 + 액션 로그 이력 */
	Map<String, Object> selectHistory(Long promNo);

	// ── 자동 워크플로 (다른 Service 가 호출) ────────────────────────

	/**
	 * 법령 신규 등록 시 자동으로 호출됨 — STATUS_REQ_WAIT(편집중) row 생성.
	 * PromServiceImpl.insertProm 이 본 메서드 호출.
	 * @param gaejungNo 작업종류(SACT_NM) 판정용 — 개정구분이 "제정"이면 제정편집, 그 외 개정편집.
	 */
	void createInitialWork(Long promNo, String sysId, Long gaejungNo) throws Exception;

	// ── 신청 / 승인 / 반려 (사용자 액션) ────────────────────────────

	/** 승인요청 (STATUS_REQ_PEND) */
	void requestApproval(PromWorkVO vo) throws Exception;

	/** 승인완료 (STATUS_REQ_APPR) — TB_PROM.SEXISTING_YN='Y' 연동 */
	void approveRequest(PromWorkVO vo) throws Exception;

	/** 승인반려 (STATUS_REQ_DENY) */
	void rejectRequest(PromWorkVO vo) throws Exception;

	// (수정권한요청/승인/반려/수정완료 전이 폐지 — 2026-07-20 사용자 결정.
	//  현행 회차 편집은 작성권한 가드만으로 허용. 과거 상태 어휘는 이력 표시 호환으로만 남음.)

	/** 특정 promNo 의 모든 워크 row */
	List<PromWorkVO> selectListByPromNo(Long promNo);

	// ── 알림/배지 카운트 (관리자 헤더·대시보드) ─────────────────────

	/** 승인자 배지용 — 전역 미처리 승인요청 건수 (최신 워크 기준) */
	int countPendingApproval();

	/** 작성자 배지용 — 내가 신청했다가 반려된 건수 (최신 워크 기준) */
	int countMyRejected(String userId);

	/**
	 * 조문/본문 편집 등 임의 도메인 액션을 TB_PROM_ACT_LOG 에 기록 (감사 추적).
	 * 레거시 PromulgationActionLog 의 조문편집 로깅 이식. 로깅 실패는 본 작업을 막지 않음(내부 흡수).
	 *
	 * @param refTable 대상 테이블명(예: "TB_PROV_VRSN"/"TB_PROV_HTML"), refNo 대상 식별자(promNo 등)
	 * @param actType  PromWorkActLogVO.ACT_TYPE_* (INSERT/UPDATE/DELETE)
	 */
	void logAction(Long promNo, String sysId, String refTable, String refNo,
			String actType, String actNm, String actDc, String userId, String userNm);
}
