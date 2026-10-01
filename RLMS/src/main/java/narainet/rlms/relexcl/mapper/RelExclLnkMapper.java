/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/relexcl/mapper/RelExclLnkMapper.java
 *
 * 자동링크 제외범위 (TB_REL_EXCL_LNK) MyBatis @Mapper.
 * XML: /src/main/resources/egovframework/mapper/rlms/relexcl/RelExclLnk_SQL_oracle.xml
 */
package narainet.rlms.relexcl.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.relexcl.service.RelExclLnkVO;

@Mapper
public interface RelExclLnkMapper {

	/** 한 법령(exclLawId) 의 제외범위 전체 — gubun + category + leaf 모두 (displayName 조인) */
	List<RelExclLnkVO> selectExclList(@Param("exclLawId") Long exclLawId,
			@Param("sysId") String sysId);

	/** PK 단건 조회 */
	RelExclLnkVO selectByNo(@Param("relnkNo") Long relnkNo);

	/** 중복 확인 — 같은 (sysId, exclLawId, flag, key) 조합이 이미 있는지 */
	int countDuplicate(@Param("sysId") String sysId,
			@Param("exclLawId") Long exclLawId,
			@Param("flag") String flag,
			@Param("gubunId") String gubunId,
			@Param("cateNo") Long cateNo,
			@Param("lawId") Long lawId);

	int insertExcl(RelExclLnkVO vo);

	int deleteByNo(@Param("relnkNo") Long relnkNo);

	/** 한 법령의 제외범위 전체 삭제 (회차 삭제 시 등) */
	int deleteByExclLawId(@Param("exclLawId") Long exclLawId,
			@Param("sysId") String sysId);
}
