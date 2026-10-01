/*
 * 물리적 저장 경로: /src/main/java/narainet/law/lawyer/service/LawLawyerService.java
 */
package narainet.law.lawyer.service;

import java.util.Map;

public interface LawLawyerService {

	/** 목록+총건수 (resultList/resultCnt) */
	Map<String, Object> getList(LawLawyerVO searchVO) throws Exception;

	LawLawyerVO getDetail(Long lawyerId) throws Exception;

	/** 등록(lawyerId 채번)·수정(lawyerId 존재) 겸용 — 저장된 ID 반환 */
	Long save(LawLawyerVO vo) throws Exception;

	/** 소프트삭제 — 선임 참조 존재 시 예외(차단 안내) */
	void delete(Long lawyerId, String userId) throws Exception;
}
