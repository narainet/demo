/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelVrsnCateMapper.java
 *
 * 관련자료 카테고리(TB_REL_VRSN_CATE) Mapper.
 *  CRUD + 활성 목록 조회(누적: 같은 ILAW_ID 의 ILAW_NO ≤ 현재 모두).
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelVrsnCateVO;

@Mapper
public interface RelVrsnCateMapper {

	/**
	 * 활성 카테고리 목록 (레거시 DAO getList 패턴).
	 *  - 누적: STEMP 가 promNo 와 같거나, STEMP IN (같은 ILAW_ID 의 ILAW_NO ≤ 현재)
	 *  - 숨김 미경과: SHIDE_DT >= today 또는 SHIDE_DT='0'
	 *  - itemCount: 카테고리에 매달린 TB_REL_FILE row 수 (레거시 기준 카운트)
	 */
	List<RelVrsnCateVO> selectActiveList(@Param("promNo") Long promNo,
			@Param("lawId") Long lawId,
			@Param("today") String today);

	/** 단건 조회 */
	RelVrsnCateVO selectByNo(@Param("cateNo") Long cateNo);

	/** INSERT — 호출자가 cateNo 채번 후 전달 */
	int insert(RelVrsnCateVO vo);

	/** UPDATE — 이름/순서/숨김/원본다운로드 모두 */
	int update(RelVrsnCateVO vo);

	/** 이름만 변경 */
	int updateTitle(@Param("cateNo") Long cateNo, @Param("title") String title);

	/** 숨김일 설정 ("0" = 활성 / "YYYYMMDD") */
	int updateHide(@Param("cateNo") Long cateNo, @Param("hideDt") String hideDt);

	/** 원본 다운로드 허용 토글 */
	int updateOrgnDown(@Param("cateNo") Long cateNo, @Param("orgnDownYn") String orgnDownYn);

	/** 순서 변경 */
	int updateSeq(@Param("cateNo") Long cateNo, @Param("seq") Integer seq);

	/** 단건 DELETE */
	int deleteByNo(@Param("cateNo") Long cateNo);

	/** 회차 삭제 동반 정리 — STEMP(소유 promNo) 기준. 트리거는 TB_REL_VRSN 만 cascade 한다 */
	int deleteByPromNo(@Param("promNo") Long promNo);
}
