/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelDmnLnkMapper.java
 *
 * 관련자료 — DOMAIN_LINK 액션 자식 (TB_REL_DMN_LNK) Mapper.
 *  DELETE-then-INSERT 패턴 — saveLinks 호출 시 마스터 단위 deleteByRelVrsnNo → bulk insert.
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelDmnLnkVO;

@Mapper
public interface RelDmnLnkMapper {

	List<RelDmnLnkVO> selectByRelVrsnNo(@Param("relVrsnNo") String relVrsnNo);

	RelDmnLnkVO selectByNo(@Param("relDmnLnkNo") Long relDmnLnkNo);

	int insert(RelDmnLnkVO vo);

	/** 단건 물리 삭제 */
	int deleteByNo(@Param("relDmnLnkNo") Long relDmnLnkNo);

	/** 마스터 단위 전체 삭제 (저장 = delete then insert 의 delete 단계) */
	int deleteByRelVrsnNo(@Param("relVrsnNo") String relVrsnNo);
}
