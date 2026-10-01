/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelLnkMapper.java
 *
 * 관련자료 — LINK 액션 자식 (TB_REL_LNK) Mapper. DELETE-then-INSERT 패턴.
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelLnkVO;

@Mapper
public interface RelLnkMapper {

	List<RelLnkVO> selectByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);

	RelLnkVO selectByNo(@Param("relLnkNo") Long relLnkNo);

	int insert(RelLnkVO vo);

	int deleteByNo(@Param("relLnkNo") Long relLnkNo);

	int deleteByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);
}
