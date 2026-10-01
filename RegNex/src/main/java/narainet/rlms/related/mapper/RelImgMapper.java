/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelImgMapper.java
 *
 * 관련자료 — IMAGE 액션 자식 (TB_REL_IMG) Mapper.
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelImgVO;

@Mapper
public interface RelImgMapper {

	List<RelImgVO> selectByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);

	RelImgVO selectByNo(@Param("relImgNo") Long relImgNo);

	int insert(RelImgVO vo);

	int update(RelImgVO vo);

	int softDelete(@Param("relImgNo") Long relImgNo);

	int deleteByNo(@Param("relImgNo") Long relImgNo);

	int deleteByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);
}
