/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/gaejung/mapper/GaejungMapper.java
 */
package narainet.rlms.gaejung.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.gaejung.service.GaejungVO;

@Mapper
public interface GaejungMapper {

	List<GaejungVO> selectGaejungList(GaejungVO vo);

	int selectGaejungListCnt(GaejungVO vo);

	/** 전체 활성 목록 (셀렉트박스용) */
	List<GaejungVO> selectAllActive();

	GaejungVO selectGaejungByNo(@Param("gaejungNo") Long gaejungNo);

	GaejungVO selectGaejungByName(@Param("gaejungNm") String gaejungNm);

	int selectMaxSeq();

	/** 이 개정 종류를 사용하는 유효 법령 수 (삭제 차단 판정) */
	int selectPromCntByGaejung(@Param("gaejungNo") Long gaejungNo);

	int insertGaejung(GaejungVO vo);

	int updateGaejung(GaejungVO vo);

	int updateGaejungDeleted(@Param("gaejungNo") Long gaejungNo);
}
