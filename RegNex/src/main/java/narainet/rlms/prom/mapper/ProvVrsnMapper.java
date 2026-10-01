/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/mapper/ProvVrsnMapper.java
 *
 * 본문 단위 row(TB_PROV_VRSN) Mapper.
 * - 단위 분해 결과 배치 INSERT
 * - 두 promNo 의 row 집합을 FULL OUTER JOIN 으로 비교 (DiffLineVO)
 * - Oracle Text CONTAINS() 로 전문 검색
 */
package narainet.rlms.prom.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.prom.service.DiffLineVO;
import narainet.rlms.prom.service.ProvVrsnVO;

@Mapper
public interface ProvVrsnMapper {

	/** 한 법령의 모든 단위 row (fullItem 순) */
	List<ProvVrsnVO> selectProvVrsnList(@Param("promNo") Long promNo);

	/** 특정 단위 (promNo + fullItem) 조회 */
	ProvVrsnVO selectProvVrsnByFullItem(@Param("promNo") Long promNo,
			@Param("fullItem") String fullItem);

	/**
	 * 조 row + 그 자식 항/호/목 모두 조회 — 단건 조 화면 본문 조립용 (누적 모델).
	 * 레거시 와 동일: 같은 lawId 의 lawNo ≤ 현재 회차 중 SFULL_ITEM 별 최신 회차 row.
	 * SFULL_ITEM 30자 prefix 일치 = 그 조 아래 모든 sub_text.
	 */
	List<ProvVrsnVO> selectProvVrsnAndSubItemsCumulative(@Param("lawId") Long lawId,
			@Param("lawNo") Long lawNo,
			@Param("fullItem") String fullItem);

	// ── 규정 편집 IDE 조항 트리(회차 > 장 > (절) > 조) — 누적(상속) 조회 ───
	// 레거시 ProvisionVersionService.getSelectSql 이식: 한 회차의 전체 본문 = 같은 lawId
	// 회차들(ILAW_NO ≤ 이 회차) 중 SFULL_ITEM 별 최신 회차의 행. (각 회차는 변경/신규만 저장)
	// → 식별은 (lawId, lawNo) 로 한다 (promNo 만으로는 누락됨).
	// SFULL_ITEM = 60자(STYLE_NORMAL: 5자 × 12단계, 사전순 = 트리순) 고정폭 계층 코드.

	/** 회차의 최상위 그룹(장 — F_JANG) 누적 목록. 장이 없으면 빈 리스트 */
	List<ProvVrsnVO> selectTopGroupNodes(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo);

	/** 회차의 조(BASE_TEXT) 누적 평면 목록 — 장 구조가 없는 법령(예: 영문 정관)용 */
	List<ProvVrsnVO> selectBaseTextNodes(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo);

	/**
	 * 회차의 **모든** 누적 행 (장/절/관/목/조/항/호/...) — SFULL_ITEM 사전순.
	 * "버전관리용조문편집" 일괄 편집기 본문 조립용.
	 */
	List<ProvVrsnVO> selectAllCumulative(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo);

	/**
	 * 같은 법령(lawId)에서 현재 회차(lawNo) 직전 회차의 ILAW_NO. 없으면 null(=제정 회차).
	 * 개정유형 분류·삭제 tombstone 의 비교 기준선(이전 회차 누적)을 잡는 데 사용. 레거시 previousPromulgation.
	 */
	Long selectPrevLawNo(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo);

	/**
	 * 회차 행을 FOR UPDATE 로 잡아 같은 회차의 동시 저장을 직렬화한다(2026-07-30).
	 * 저장이 delete+insert 라 겹치면 조문이 2중으로 남는다 — 저장 트랜잭션 진입점에서 호출.
	 */
	Long lockPromForUpdate(@Param("promNo") Long promNo);

	/**
	 * 한 그룹(장/절) 노드의 직속 자식 — 직속 조(BASE_TEXT) + (장이면) 직속 절(F_JEOL). 누적.
	 * parentFullItem = 그룹 행의 SFULL_ITEM. 60자 고정폭 prefix 매칭으로 계층 판정.
	 */
	List<ProvVrsnVO> selectGroupChildren(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo,
			@Param("parentFullItem") String parentFullItem);

	/** 조항(TB_PROV_VRSN) 단위 row 의 본문/제목/사유/개정유형 in-place 갱신 (재분해 없음) */
	int updateProvVrsnContent(ProvVrsnVO vo);

	/** 분해 결과 일괄 INSERT (foreach) */
	int insertProvVrsnBatch(@Param("list") List<ProvVrsnVO> list);

	/** 재분해 시 기존 row 전부 삭제 */
	int deleteProvVrsnByPromNo(@Param("promNo") Long promNo);

	/**
	 * 단건 "조문별 수정" — 이 회차가 소유한 한 조의 subtree(조 + 그 항/호/목) 만 삭제.
	 * prefix30 = 조 SFULL_ITEM 앞 30자(편/장/절/관/목1/조 청크). 같은 조 아래 행만 매칭.
	 */
	int deleteProvVrsnBySubtreePrefix(@Param("promNo") Long promNo,
			@Param("prefix30") String prefix30);

	/**
	 * 두 법령의 단위 row 를 SFULL_ITEM 으로 FULL OUTER JOIN 비교.
	 * 메인 비교 알고리즘 — java-diff-utils 불필요.
	 */
	List<DiffLineVO> selectDiffByPromNo(@Param("leftPromNo") Long leftPromNo,
			@Param("rightPromNo") Long rightPromNo);

	/**
	 * 전문 검색 — Oracle Text CONTAINS(SCONTENTS, keyword)
	 * SCORE(1) 로 정렬, rank 컬럼 매핑.
	 */
	List<ProvVrsnVO> selectFullTextSearch(@Param("sysId") String sysId,
			@Param("keyword") String keyword,
			@Param("firstIndex") int firstIndex,
			@Param("recordCountPerPage") int recordCountPerPage,
			@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	int selectFullTextSearchCnt(@Param("sysId") String sysId,
			@Param("keyword") String keyword,
			@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	// ── 유효성 검사 보조 메서드 ─────────────────────────────────────

	/** 한 법령의 row 개수 (0이면 PROV_VRSN 미생성) */
	int countByPromNo(@Param("promNo") Long promNo);

	/** 누적(승계 포함) 표시 조문 수 — SFULL_ITEM 별 최신 행 중 SDISP_YN='Y' (유효성검사 승계 안내용) */
	int countCumulativeByLaw(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo);

	/**
	 * 뷰어 좌측 빠른검색 보조 — 전 규정(현행 회차 기준 누적)의 조문/별표 제목 검색.
	 * VERSION 조문(BASE_TEXT) + HTML 조문(TB_PROV_HTML) + 별표/별지서식(TB_DOCU) 3원 UNION.
	 * 공백 제거 LIKE("국제자본" ↔ "국제 자본 …"). 열람제한은 호출측이 canReadLaw 로 후필터.
	 */
	java.util.List<java.util.Map<String, Object>> selectQuickTitleSearch(@Param("q") String q);

	/** 중복된 SFULL_ITEM 목록 — GROUP BY HAVING COUNT(*) > 1 */
	List<String> selectDuplicateFullItems(@Param("promNo") Long promNo);

	/** 본문(SCONTENTS) 비어 있는 SFULL_ITEM 목록 */
	List<String> selectEmptyContentItems(@Param("promNo") Long promNo);
}
