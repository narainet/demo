/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelHtmlMapper.java
 *
 * 관련자료 — HTML 액션 자식 (TB_REL_HTML) Mapper.
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelHtmlVO;

@Mapper
public interface RelHtmlMapper {

	List<RelHtmlVO> selectByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);

	RelHtmlVO selectByNo(@Param("relHtmlNo") Long relHtmlNo);

	int insert(RelHtmlVO vo);

	int update(RelHtmlVO vo);

	/** 소프트 삭제 — SDEL_YN='Y' */
	int softDelete(@Param("relHtmlNo") Long relHtmlNo);

	/** 물리 삭제 (마스터 삭제 cascade 또는 강제 정리용) */
	int deleteByNo(@Param("relHtmlNo") Long relHtmlNo);

	/** 마스터 삭제 시 자식 모두 물리 삭제 */
	int deleteByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);
}
