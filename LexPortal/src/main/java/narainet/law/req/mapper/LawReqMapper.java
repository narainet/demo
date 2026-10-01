/*
 * 물리적 저장 경로: /src/main/java/narainet/law/req/mapper/LawReqMapper.java
 *
 * 소송의뢰(LAW_SUIT_REQ / _HIST / _HELPER) 조회·저장·승인·연계. §7.8·§7.9
 */
package narainet.law.req.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.req.service.LawSuitReqHelperVO;
import narainet.law.req.service.LawSuitReqHistVO;
import narainet.law.req.service.LawSuitReqVO;

@Mapper
public interface LawReqMapper {

	// ── 의뢰 본체 ──
	List<LawSuitReqVO> selectReqList(LawSuitReqVO searchVO);

	int selectReqCnt(LawSuitReqVO searchVO);

	LawSuitReqVO selectReq(@Param("reqId") Long reqId);

	void insertReq(LawSuitReqVO vo);

	void updateReq(LawSuitReqVO vo);

	void deleteReq(@Param("reqId") Long reqId);

	/** 승인/반려 — 상태·처리자·일시·사유(반려)·승인 시 사유 초기화 */
	void updateApproval(LawSuitReqVO vo);

	/** 소송등록 연계 역기입 — SUIT_ID 채움 */
	void updateSuitLink(LawSuitReqVO vo);

	int selectPendingCnt();

	// ── 경과 내역 ──
	List<LawSuitReqHistVO> selectHistList(@Param("reqId") Long reqId);

	void insertHist(LawSuitReqHistVO vo);

	void deleteHists(@Param("reqId") Long reqId);

	// ── 보조자 ──
	List<LawSuitReqHelperVO> selectHelperList(@Param("reqId") Long reqId);

	void insertHelper(LawSuitReqHelperVO vo);

	void deleteHelpers(@Param("reqId") Long reqId);
}
