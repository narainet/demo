/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelOrgnMapper.java
 *
 * 관련자료 — ORGN 액션 자식 (TB_REL_ORGN) Mapper.
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelOrgnVO;

@Mapper
public interface RelOrgnMapper {

	List<RelOrgnVO> selectByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);

	RelOrgnVO selectByNo(@Param("relOrgnNo") Long relOrgnNo);

	int insert(RelOrgnVO vo);

	int update(RelOrgnVO vo);

	/** 소프트 삭제 — SDEL_YN='Y' */
	int softDelete(@Param("relOrgnNo") Long relOrgnNo);

	/** 물리 삭제 (마스터 삭제 cascade 또는 강제 정리용) */
	int deleteByNo(@Param("relOrgnNo") Long relOrgnNo);

	/** 마스터 삭제 시 자식 모두 물리 삭제 */
	int deleteByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);
}
