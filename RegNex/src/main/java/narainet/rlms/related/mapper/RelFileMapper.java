/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelFileMapper.java
 *
 * 관련자료 — FILE 액션 자식 (TB_REL_FILE) Mapper.
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelFileVO;

@Mapper
public interface RelFileMapper {

	List<RelFileVO> selectByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);

	RelFileVO selectByNo(@Param("relFileNo") Long relFileNo);

	/** 사용자 뷰어 — 법령 누적 열람가능 파일 (SVIEW_YN='Y', 본문참조 카테고리, ICTNS_ID별 최신) */
	List<RelFileVO> selectViewableListCumulative(@Param("lawId") Long lawId,
			@Param("lawNo") Long lawNo);

	int insert(RelFileVO vo);

	int update(RelFileVO vo);

	/** 소프트 삭제 — SDEL_YN='Y' */
	int softDelete(@Param("relFileNo") Long relFileNo);

	/** 물리 삭제 (마스터 삭제 cascade 또는 강제 정리용) */
	int deleteByNo(@Param("relFileNo") Long relFileNo);

	/** 마스터 삭제 시 자식 모두 물리 삭제 */
	int deleteByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);
}
