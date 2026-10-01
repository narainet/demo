/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/mapper/LawSuitMapper.java
 */
package narainet.law.suit.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.suit.service.LawSuitLandVO;
import narainet.law.suit.service.LawSuitPartyVO;
import narainet.law.suit.service.LawSuitProgVO;
import narainet.law.suit.service.LawSuitRsltHistVO;
import narainet.law.suit.service.LawSuitStaffVO;
import narainet.law.suit.service.LawSuitVO;

@Mapper
public interface LawSuitMapper {

	// ── 목록 (14열 — 자식 요약 집계 동봉, 집합 1회) ──
	int selectSuitCnt(LawSuitVO searchVO);

	List<LawSuitVO> selectSuitList(LawSuitVO searchVO);

	// ── 본체 ──
	LawSuitVO selectSuit(@Param("suitId") Long suitId);

	void insertSuit(LawSuitVO vo);

	void updateSuit(LawSuitVO vo);

	/** 소프트삭제 (DEL_YN='Y') */
	void deleteSuit(LawSuitVO vo);

	// ── 자식 (저장=전량 교체 delete-insert — §7.1 한 트랜잭션 일괄) ──
	List<LawSuitPartyVO> selectPartyList(@Param("suitId") Long suitId);

	void deleteParties(@Param("suitId") Long suitId);

	void insertParty(LawSuitPartyVO vo);

	List<LawSuitLandVO> selectLandList(@Param("suitId") Long suitId);

	void deleteLands(@Param("suitId") Long suitId);

	void insertLand(LawSuitLandVO vo);

	List<LawSuitStaffVO> selectStaffList(@Param("suitId") Long suitId);

	void deleteStaffs(@Param("suitId") Long suitId);

	void insertStaff(LawSuitStaffVO vo);

	List<LawSuitProgVO> selectProgList(@Param("suitId") Long suitId);

	void deleteProgs(@Param("suitId") Long suitId);

	void insertProg(LawSuitProgVO vo);

	// ── 결과변경 이력 ──
	List<LawSuitRsltHistVO> selectRsltHistList(@Param("suitId") Long suitId);

	int selectMaxHistSeq(@Param("suitId") Long suitId);

	void insertRsltHist(LawSuitRsltHistVO vo);

	// ── 심급(사건군)·검색 모달 ──
	/** 같은 사건군의 심급 목록 (FIRST_SUIT_ID 기준, 삭제 제외) */
	List<LawSuitVO> selectInstanceSuits(@Param("firstSuitId") Long firstSuitId);

	/** 사건 검색 모달 (사건번호·사건명 키워드, 상위 20 — 심급연결·일정·선임 공용) */
	List<LawSuitVO> searchSuits(@Param("keyword") String keyword);
}
