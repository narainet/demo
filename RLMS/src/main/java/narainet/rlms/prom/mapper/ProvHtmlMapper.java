/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/mapper/ProvHtmlMapper.java
 */
package narainet.rlms.prom.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.prom.service.ProvHtmlVO;

@Mapper
public interface ProvHtmlMapper {

	/** 한 법령의 모든 조항 본문 (item 순) */
	List<ProvHtmlVO> selectProvHtmlList(@Param("promNo") Long promNo);

	/** 누적(상속) 조회 — 같은 법령 회차들 중 SITEM 별 최신 행 (사용자 뷰어, SDISP_YN='Y') */
	List<ProvHtmlVO> selectProvHtmlListCumulative(@Param("lawId") Long lawId,
			@Param("lawNo") Long lawNo);

	/** 관리자(IDE 트리) 누적 조회 — 숨김행은 자기 회차에서만 노출 (TB_DOCU 관리자 변형과 동일) */
	List<ProvHtmlVO> selectProvHtmlListCumulativeAdmin(@Param("lawId") Long lawId,
			@Param("lawNo") Long lawNo);

	/** PK 단건 조회 */
	ProvHtmlVO selectProvHtmlByNo(@Param("provHtmlNo") Long provHtmlNo);

	/** (promNo, item) 복합키 조회 — 중복/부활 판정 */
	ProvHtmlVO selectProvHtmlByPromItem(@Param("promNo") Long promNo,
			@Param("item") String item);

	/**
	 * promNo 가 속한 규정(ILAW_ID) 계보 전체에서 이 SITEM 을 쓰는 행 수 (자기 행 제외).
	 *  조 번호 변경(2026-07-30) 검사용 — SITEM 은 회차간 누적의 계보 키라
	 *  ①바꿀 번호가 다른 회차에 있으면 그 조항의 개정판으로 오인되고
	 *  ②지금 번호가 다른 회차에도 있으면 계보가 끊겨 조항이 둘로 보인다.
	 */
	int countProvHtmlItemInLaw(@Param("promNo") Long promNo,
			@Param("item") String item,
			@Param("exceptProvHtmlNo") Long exceptProvHtmlNo);

	int insertProvHtml(ProvHtmlVO vo);

	int updateProvHtml(ProvHtmlVO vo);

	/** 단건 삭제 (트리거: TB_REL_VRSN(PROVISION) + TB_ATTACH(SREF_TABLE='TB_PROV_HTML') cascade) */
	int deleteProvHtml(@Param("provHtmlNo") Long provHtmlNo);
}
