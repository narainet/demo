/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/favor/mapper/FavorMapper.java
 */
package narainet.rlms.favor.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.favor.service.FavorVO;

@Mapper
public interface FavorMapper {

	/** 사용자별 페이징 목록 */
	List<FavorVO> selectMyFavorList(@Param("userId") String userId, @Param("vo") FavorVO vo);

	int selectMyFavorListCnt(@Param("userId") String userId, @Param("vo") FavorVO vo);

	/** PK + 사용자 검증 */
	FavorVO selectFavorByNo(@Param("favorNo") Long favorNo);

	/** (사용자 + 법령 + 조항) 단건 — 중복 판정 */
	FavorVO selectFavorByLawItem(@Param("userId") String userId,
			@Param("lawId") Long lawId,
			@Param("item") String item,
			@Param("sysId") String sysId);

	/** 한 법령(lawId) 안의 사용자 즐겨찾기 — 본문 위젯용 */
	List<FavorVO> selectFavorListByLaw(@Param("userId") String userId,
			@Param("lawId") Long lawId,
			@Param("sysId") String sysId);

	int insertFavor(FavorVO vo);

	/** 뷰어 본문 열람 시 확인 회차 기록 — 홈 개정 소식 해소(GREATEST, 과거 회차 열람 무영향) */
	int touchFavorSeen(@Param("userId") String userId,
			@Param("lawId") Long lawId,
			@Param("lawNo") Long lawNo);

	int updateFavor(FavorVO vo);

	/**
	 * 조항 식별자 일괄 교체 — 조 번호(TB_PROV_HTML.SITEM) 변경 시 즐겨찾기 이관(2026-07-30).
	 *  TB_FAVOR.SITEM 이 조항 식별자라 안 옮기면 사용자 즐겨찾기가 "삭제된 조항"으로 표시된다.
	 *  regPromNo = 변경된 조항이 속한 회차(그 회차의 ILAW_ID 로 범위를 잡는다).
	 */
	int updateSitemByLawOfProm(@Param("regPromNo") Long regPromNo,
			@Param("oldItem") String oldItem,
			@Param("newItem") String newItem);

	int deleteFavor(@Param("favorNo") Long favorNo);
}
