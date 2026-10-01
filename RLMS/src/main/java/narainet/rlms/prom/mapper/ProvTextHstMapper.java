/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/mapper/ProvTextHstMapper.java
 *
 * 회차 본문 일괄편집 이력(TB_PROV_TEXT_HST) Mapper.
 * 레거시 "이전개정작업내용" 드롭다운/불러오기/삭제 의 DAO.
 */
package narainet.rlms.prom.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.prom.service.ProvTextHstVO;

@Mapper
public interface ProvTextHstMapper {

	/** 한 회차의 이력 목록 (최신 SINS_DT 순, 최대 30건) — 드롭다운용 */
	List<ProvTextHstVO> selectHistoryByPromNo(@Param("promNo") Long promNo);

	/** 단건 조회 — 불러오기용 (STEXT 포함) */
	ProvTextHstVO selectHistoryByNo(@Param("provTextHstNo") Long provTextHstNo);

	/** 새 이력 INSERT — 저장 직전 본문 백업 */
	int insertHistory(ProvTextHstVO vo);

	/** 단건 삭제 */
	int deleteHistory(@Param("provTextHstNo") Long provTextHstNo);

	/** 회차 삭제 동반 정리 — 그 회차의 백업 이력 전체 삭제 (TB_PROM 트리거 cascade 미대상) */
	int deleteHistoryByPromNo(@Param("promNo") Long promNo);
}
