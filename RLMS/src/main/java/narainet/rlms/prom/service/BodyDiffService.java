/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/BodyDiffService.java
 */
package narainet.rlms.prom.service;

import java.util.List;

/**
 * 본문 비교 Service.
 *
 * - diffByVrsnRows: 단위 row 기반 비교 (ProvVrsnService.diffByPromNo 위임 + 부가 가공)
 * - diffBylawByLibrary: TB_PROM.SBYLAW 처럼 CLOB 한 덩어리인 텍스트의 라인 diff
 *                       (java-diff-utils 4.x Myers diff 알고리즘)
 */
public interface BodyDiffService {

	/** 단위 row 기반 비교 결과 */
	List<DiffLineVO> diffByVrsnRows(Long leftPromNo, Long rightPromNo);

	/**
	 * CLOB 한 덩어리 텍스트(예: 부칙)를 라인 단위로 diff.
	 * 반환: 라인별 변경 유형 표시된 DiffLineVO 리스트.
	 * fullItem 컬럼에는 "line-NN" 라벨, leftText/rightText 는 해당 라인.
	 */
	List<DiffLineVO> diffBylawByLibrary(String leftBylaw, String rightBylaw);
}
