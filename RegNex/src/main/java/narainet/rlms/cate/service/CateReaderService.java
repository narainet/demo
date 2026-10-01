/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/CateReaderService.java
 */
package narainet.rlms.cate.service;

import java.util.List;

/**
 * 분류별 열람제한 서비스 (TB_CATE_READER)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.07   RLMS 전환팀   최초 생성 (TB_CATE_OWNER 패턴 미러 — read 축 신설)
 * </pre>
 */
public interface CateReaderService {

	/** 특정 분류의 열람대상 목록 */
	List<CateReaderVO> selectReaders(Long cateNo);

	/** 열람대상 추가 (부서/개인) */
	void addReader(CateReaderVO vo);

	/** 열람대상 삭제 (PK 단건) */
	void removeReader(Long cateNo, String readerTy, String readerId);

	/**
	 * 열람 가능 여부 — 제한 미지정 분류는 true(전체 공개).
	 * 면제역할(ADMIN/EDITOR/APPROVER)은 호출측(PromReadGuard)에서 먼저 통과.
	 */
	boolean canRead(String esntlId, String orgnztId, Long cateNo);

	/** 해당 사용자가 열람할 수 없는 분류번호 전체 (트리 필터용, 삭제분류 포함) */
	List<Long> selectBlockedCateNos(String esntlId, String orgnztId);

	/** 해당 사용자가 열람할 수 없는 규정번호 전체 — 법령(ILAW_ID) 단위 전 회차 전개 (기능별분류 트리 필터용) */
	List<Long> selectBlockedPromNos(String esntlId, String orgnztId);

	/** 사용자 검색 — 이름/로그인ID 부분일치 (개인 열람대상 선택 UI) */
	List<java.util.Map<String, Object>> searchUsers(String keyword);

	// ── 구분(최상위 SGUBUN_ID) 단위 열람제한 ─────────────────────────

	/** 특정 구분의 열람대상 목록 */
	List<CateReaderVO> selectGubunReaders(String gubunId);

	/** 구분 열람대상 추가 (부서/개인) */
	void addGubunReader(CateReaderVO vo);

	/** 구분 열람대상 삭제 (PK 단건) */
	void removeGubunReader(String gubunId, String readerTy, String readerId);
}
