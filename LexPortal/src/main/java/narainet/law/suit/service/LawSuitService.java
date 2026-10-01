/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/LawSuitService.java
 */
package narainet.law.suit.service;

import java.util.List;
import java.util.Map;

public interface LawSuitService {

	/** 목록+총건수 (resultList/resultCnt) */
	Map<String, Object> getList(LawSuitVO searchVO) throws Exception;

	/** 본체 (없으면 null) */
	LawSuitVO getSuit(Long suitId) throws Exception;

	/** 상세 묶음 — suit/parties(마스킹)/lands/staffs/progs/rsltHists/instanceSuits */
	Map<String, Object> getDetail(Long suitId) throws Exception;

	/**
	 * 저장 (등록·수정 겸용, 한 트랜잭션 — §7.1).
	 * 본체 + 자식 4종 전량 교체. 당사자 평문 주민번호는 여기서 암호화(미입력+기존행=기존 암호문 보존).
	 * 결과가 바뀌면 결과변경 이력 자동 적재. 신규는 FIRST_SUIT_ID 확정(원심 미선택=자기 ID).
	 * @return 저장된 suitId
	 */
	Long save(LawSuitVO vo, List<LawSuitPartyVO> parties, List<LawSuitLandVO> lands,
			List<LawSuitStaffVO> staffs, List<LawSuitProgVO> progs, String userId) throws Exception;

	/** 소프트삭제 */
	void delete(Long suitId, String userId) throws Exception;

	/** 사건 검색 모달 (심급연결 등 공용) */
	List<LawSuitVO> searchSuits(String keyword) throws Exception;
}
