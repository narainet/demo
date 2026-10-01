/*
 * 물리적 저장 경로: /src/main/java/narainet/law/req/service/LawReqService.java
 *
 * 소송의뢰 워크플로 서비스 — front 신청/나의 의뢰 + mgr 관리·승인·소송등록 연계. §7.8·§7.9
 */
package narainet.law.req.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartHttpServletRequest;

public interface LawReqService {

	/** 목록(mgr 전체 / front 본인) — searchVO.regUserId 지정 시 본인 필터 */
	Map<String, Object> getList(LawSuitReqVO searchVO) throws Exception;

	/** 상세(본체 + 경과 + 보조자 + 첨부) — null 이면 미존재 */
	LawSuitReqVO getDetail(Long reqId) throws Exception;

	/**
	 * 신청/수정 저장(한 트랜잭션). 경과·보조자는 전량 교체, 첨부는 표준 COMTNFILE.
	 * front 수정은 본인·신청(S001) 상태에서만(컨트롤러 선검증 + 서비스 재확인).
	 */
	Long save(LawSuitReqVO vo, MultipartHttpServletRequest multiRequest, String userId) throws Exception;

	/** 삭제(신청 상태·본인만 — 컨트롤러 선검증) */
	void delete(Long reqId) throws Exception;

	/** 승인/반려 처리 — 반려는 사유 필수(컨트롤러 검증). */
	void approve(LawSuitReqVO vo) throws Exception;

	/** 소송등록 연계 역기입 — 승인 상태에서 사건 생성 후 REQ.SUIT_ID 채움. */
	void linkSuit(Long reqId, Long suitId, String userId) throws Exception;

	/** 본인 필터용 소유자 조회(수정·삭제 권한 검증) */
	LawSuitReqVO getReq(Long reqId) throws Exception;

	/** 승인대기 의뢰 건수(홈 카드 등) */
	int getPendingCnt() throws Exception;

	/** front 나의 의뢰 목록(간이 — 페이징 없이 최신순) */
	List<LawSuitReqVO> getMyList(String userId) throws Exception;
}
