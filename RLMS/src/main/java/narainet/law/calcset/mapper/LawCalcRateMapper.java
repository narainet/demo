/*
 * 물리적 저장 경로: /src/main/java/narainet/law/calcset/mapper/LawCalcRateMapper.java
 *
 * 계산기 요율(LAW_CALC_RATE) 매퍼 — 기준일 유효 세트 조회(계산기) + 세트 편집(요율설정). §7.4·§7.13
 */
package narainet.law.calcset.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.calcset.service.LawCalcRateVO;

@Mapper
public interface LawCalcRateMapper {

	/** 기준일 유효 요율(전 타입) — 타입별 APPLY_DT ≤ 기준일 최신 세트, 없으면 최초 세트 폴백. USE_YN='Y' */
	List<LawCalcRateVO> selectEffectiveRates(@Param("baseDt") String baseDt);

	/** 요율설정 — 한 계산기 종류(family = calcType 목록)의 적용시작일별 세트 목록 (applyDt/cnt, 최신순) */
	List<Map<String, Object>> selectSetDates(@Param("calcTypes") List<String> calcTypes);

	/** 요율설정 — 특정 세트(family + applyDt)의 행들 */
	List<LawCalcRateVO> selectSetRows(@Param("calcTypes") List<String> calcTypes, @Param("applyDt") String applyDt);

	/** 요율설정 — 최신 세트의 적용시작일(복사 기준) */
	String selectLatestApplyDt(@Param("calcTypes") List<String> calcTypes);

	void insertRate(LawCalcRateVO vo);

	/** 세트 물리 삭제(재저장·미래세트 삭제 시 해당 family+applyDt 전량 제거) */
	void deleteSetPhysical(@Param("calcTypes") List<String> calcTypes, @Param("applyDt") String applyDt);

	/** 세트 소프트 삭제(과거 세트 — USE_YN='N' 이력 보존) */
	void softDeleteSet(@Param("calcTypes") List<String> calcTypes, @Param("applyDt") String applyDt);
}
