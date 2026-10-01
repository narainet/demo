/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/mapper/PromMapper.java
 *
 * 법령(TB_PROM) MyBatis @Mapper 인터페이스.
 * XML: /src/main/resources/egovframework/mapper/rlms/prom/Prom_SQL_oracle.xml
 */
package narainet.rlms.prom.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.prom.service.PromVO;

@Mapper
public interface PromMapper {

	/** 법령 목록 (페이징 + 검색 + 분류/부서 조인 + 유효한 row 만) */
	List<PromVO> selectPromList(PromVO vo);

	/** 법령 목록 카운트 */
	int selectPromListCnt(PromVO vo);

	/** PK 단건 조회 */
	PromVO selectPromByNo(@Param("promNo") Long promNo);

	/** 같은 법령(lawId) 의 모든 개정본 (최신순) */
	List<PromVO> selectPromListByLawId(@Param("lawId") Long lawId,
			@Param("sysId") String sysId);

	/**
	 * 작업중 draft 회차의 연혁번호들 — 새 연혁(개정) 등록 차단 판정.
	 * draft = SEXISTING_YN='N' + 최신 워크상태 편집중/승인요청/승인반려.
	 * ★SEXISTING_YN='N' 단독 판정 금지 — 과거 승인본도 전부 'N'(2026-07-09 오탐 교정).
	 */
	List<Long> selectWorkingDraftLawNos(@Param("lawId") Long lawId);

	/** 단건 작업중 draft 판정 — front 뷰어/트리의 비편집계 draft 게이트 */
	int countWorkingDraftByPromNo(@Param("promNo") Long promNo);

	/** 법령(lawId)의 최신 회차 분류번호 — 열람제한 가드(PromReadGuard)의 경량 판정용 (CLOB 미로드) */
	Long selectLatestCateNoByLawId(@Param("lawId") Long lawId);

	/**
	 * 누적조회 하한 — lawNo 이하 회차 중 개정구분이 전면개정류(TB_GAEJUNG.SDIFF_YN='N')인
	 * 가장 최근 ILAW_NO (없으면 NULL). 레거시 PromulgationDAO.getLawNoByNotDifference 1:1.
	 */
	Long selectNotDiffLawNo(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo);

	/**
	 * 소관부서 후보 — 표준 조직정보(COMTNORGNZTINFO), keyword 부분일치 + 이름순.
	 * F1-5 전환: TB_BUSEO 폐기. 키 = orgnztId / buseoNm / fullNm / buseoNo(레거시 역파생, NULL 가능).
	 */
	List<java.util.Map<String, Object>> selectOrgnztList(@Param("keyword") String keyword);

	/** 직전 개정본 1건 */
	PromVO selectPreviousProm(@Param("promNo") Long promNo);

	/** 신규 법령 등록 시 사용할 lawId = MAX(ILAW_ID)+1 */
	Long selectMaxLawId();

	/**
	 * 개정본 등록 시 사용할 lawNo = MAX(ILAW_NO)+1 (같은 lawId 안에서).
	 * 신규 법령(이 lawId 의 첫 회차)이면 NULL → Service 에서 1 로 처리.
	 */
	Long selectMaxLawNoByLawId(@Param("lawId") Long lawId);

	/** 분류 내 정렬순서 MAX(ISEQ)+1 */
	int selectMaxSeqByCate(@Param("cateNo") Long cateNo);

	/** 신규 등록 (PK 는 Service 에서 IdGnr 채번) */
	int insertProm(PromVO vo);

	/** 수정 */
	int updateProm(PromVO vo);

	/** 폐지일 변경 대기값 저장 — 현행 회차의 SNULL_DT 변경은 승인 전 PEND 보관 (2026-07-20) */
	void updatePromNullDatePend(@Param("promNo") Long promNo, @Param("pend") String pend);

	/** 폐지일 변경 승인 반영 — SNULL_DT ← SNULL_DT_PEND, PEND 클리어 (approveRequest 에서 호출) */
	int applyPendingNullDate(@Param("promNo") Long promNo);

	/** 폐지일 변경 반려 폐기 — PEND 클리어 (rejectRequest 에서 호출) */
	int clearPendingNullDate(@Param("promNo") Long promNo);

	/** 단일 row 의 유효 플래그(SEXISTING_YN) 갱신 */
	int updatePromExistingYn(@Param("promNo") Long promNo,
			@Param("existingYn") String existingYn);

	/** 같은 lawId 전체의 SEXISTING_YN='N' 으로 일괄 리셋 */
	int resetPromExistingByLawId(@Param("lawId") Long lawId,
			@Param("sysId") String sysId);

	/** 단건 삭제 (트리거가 PROV_*, REL_VRSN, DOCU, SRC_STORED cascade) */
	int deleteProm(@Param("promNo") Long promNo);

	/**
	 * 빈 회차 안전 삭제용 — 의존행(본문/문서/관련자료/첨부) 총 개수.
	 * 0 일 때만 deleteProm 허용. 0 이 아니면 운영 데이터가 있는 회차이므로 삭제 금지.
	 * (DB 트리거가 cascade 하지만 응용 단계에서 명시적 가드.)
	 */
	int countDependentRowsByPromNo(@Param("promNo") Long promNo);

	/** 다건 일괄 삭제 */
	int deletePromList(@Param("list") List<Long> promNoList);

	/** 정렬순서 갱신 */
	int updatePromSequence(@Param("promNo") Long promNo,
			@Param("seq") Integer seq);

	/** 분류 이동 */
	int updatePromCategoryMove(@Param("promNo") Long promNo,
			@Param("cateNo") Long cateNo);

	// ── Front 검색 5종 (레거시 fulltext.html 호환) ────────────────────

	/** 연혁검색 — 같은 lawId 의 모든 row (front) */
	List<PromVO> selectFrontHistoryList(PromVO vo);

	int selectFrontHistoryListCnt(PromVO vo);

	/** 연혁검색 현행 목록 — 현행본(SEXISTING_YN='Y') 1행/규정 */
	List<PromVO> selectFrontCurrentList(PromVO vo);

	int selectFrontCurrentListCnt(PromVO vo);

	/** 상세검색(detailSearch) — 현행본 1행/규정, 검색단위·자음/영문·날짜타입·부서·분류 */
	List<PromVO> selectDetailSearchList(PromVO vo);

	int selectDetailSearchListCnt(PromVO vo);

	/** 상세검색 소관부서 드롭다운 — 규정에 실제 쓰인 부서 distinct */
	List<java.util.Map<String, Object>> selectDetailBuseoList();

	/** 상세검색 규정분류 드롭다운 — 구분>분류 평면(들여쓰기) */
	List<java.util.Map<String, Object>> selectDetailCateList();

	/** 폐지 목록 — SEXISTING_YN='N' (또는 SNULL_DT IS NOT NULL) */
	List<PromVO> selectFrontNullifyList(PromVO vo);

	int selectFrontNullifyListCnt(PromVO vo);

	/** 최근 개정 — SINS_DT >= SYSDATE - searchDays */
	List<PromVO> selectFrontLatestList(PromVO vo);

	int selectFrontLatestListCnt(PromVO vo);

	/** 신구대조 후보 — 같은 lawId 의 promNo (선택 UI 용).
	 *  frontOnly=true → 미승인 draft 제외(사용자 신구대조), false → 전체(관리자 유효성검사).
	 *  applyReadGate=true → 분류별 열람제한 게이트 적용(면제역할이면 false 로). */
	List<PromVO> selectComparisonCandidates(@Param("lawId") Long lawId,
			@Param("frontOnly") boolean frontOnly,
			@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	/** 운영 중인 모든 법령 (SEXISTING_YN='Y' AND SDEL_YN='N' 가정 — 유효성 검사용) */
	List<PromVO> selectAllExisting();

	/** 자동링크 사전 — 현행+표시+유효 규정의 (제목/부제/lawId/promNo/분류/구분) 경량 조회 */
	List<PromVO> selectAutoLinkDict();

	/** 트리용: 시스템 내 운영 법령 (분류별 그룹화 위해 ICATE_NO + ISEQ 정렬) */
	List<PromVO> selectActivePromsForTree(@Param("sysId") String sysId);

	/** front 부서별 트리 — 현행 규정+소관부서명(삭제분류·숨김구분 게이트 적용, 2026-07-24) */
	List<PromVO> selectActivePromsForDeptTree();

	/** IDE 좌측 '작업중(draft)' 패널: 미승인 draft 회차 목록. */
	List<Map<String, Object>> selectDraftPromsForPanel();

	/** 편집계 트리(editorTreeJson) 전용: draft-only 법령(현행 회차가 아예 없는 법령)의 최신 draft 회차.
	 *  신규 등록한 연혁이 승인 전이라 분류 트리에서 안 보이는 갭 해소(마커 없이 일반 노드로 합류).
	 *  현행이 있는 법령의 개정 draft 는 제외(트리엔 현행 노드가 이미 있고 연혁목차로 도달). */
	List<PromVO> selectDraftOnlyPromsForTree();

	/** 규정 일괄수정: 선택 분류의 현행 규정(법령별 현행 1건), 정렬순서(SORDERIDX) 순. */
	List<PromVO> selectCurrentPromsByCate(@Param("cateNo") Long cateNo);
}
