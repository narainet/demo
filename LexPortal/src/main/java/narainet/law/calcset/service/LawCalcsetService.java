/*
 * 물리적 저장 경로: /src/main/java/narainet/law/calcset/service/LawCalcsetService.java
 */
package narainet.law.calcset.service;

import java.util.List;
import java.util.Map;

public interface LawCalcsetService {

	/** 계산기용 — 기준일 유효 요율(전 타입) */
	List<LawCalcRateVO> getEffectiveRates(String baseDt) throws Exception;

	/** 요율설정 탭(family)의 적용시작일별 세트 목록 (applyDt/cnt, 최신순) */
	List<Map<String, Object>> getSetDates(String tab) throws Exception;

	/** 세트(탭+applyDt)의 행들 */
	List<LawCalcRateVO> getSetRows(String tab, String applyDt) throws Exception;

	/** 최신 세트의 적용시작일(새 적용기준 복사 기준) */
	String getLatestApplyDt(String tab) throws Exception;

	/** 세트 저장(검증 후 family+applyDt 전량 교체). 검증 실패 시 IllegalArgumentException */
	void saveSet(String tab, String applyDt, List<LawCalcRateVO> rows, String userId) throws Exception;

	/** 세트 삭제 — 미래 적용일=물리삭제, 과거·현행=USE_YN 'N'(이력 보존) */
	void deleteSet(String tab, String applyDt, String userId) throws Exception;
}
