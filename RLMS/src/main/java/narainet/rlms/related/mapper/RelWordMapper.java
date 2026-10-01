/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelWordMapper.java
 *
 * 관련자료 — WORD 액션 자식 (TB_REL_WORD) Mapper.
 */
package narainet.rlms.related.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelWordVO;

@Mapper
public interface RelWordMapper {

	List<RelWordVO> selectByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);

	/** 자체변환 평문(SSEARCH_TEXT) 전문검색 — 규정(promNo)·문서·스니펫 반환. LIKE(인덱스 없음, 소량).
	 *  read-게이트: 비면제 사용자에게 분류/구분 열람제한+현행존재+숨김구분 적용
	 *  (ProvVrsnMapper.selectFullTextSearch 와 동일 @Param 패턴). */
	List<Map<String,Object>> searchByText(@Param("keyword") String keyword,
			@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	RelWordVO selectByNo(@Param("relWordNo") Long relWordNo);

	int insert(RelWordVO vo);

	int update(RelWordVO vo);

	int softDelete(@Param("relWordNo") Long relWordNo);

	int deleteByNo(@Param("relWordNo") Long relWordNo);

	int deleteByRelVrsnNo(@Param("relVrsnNo") Long relVrsnNo);
}
