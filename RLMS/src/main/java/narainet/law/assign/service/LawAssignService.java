/*
 * 물리적 저장 경로: /src/main/java/narainet/law/assign/service/LawAssignService.java
 */
package narainet.law.assign.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

public interface LawAssignService {

	/** 선임 목록+총건수 (파일 목록 동봉) */
	Map<String, Object> getList(LawSuitLawyerVO searchVO) throws Exception;

	/** 사건 상세 탭용 — 특정 사건의 선임 목록(파일 동봉) */
	List<LawSuitLawyerVO> getListBySuit(Long suitId) throws Exception;

	LawSuitLawyerVO getAssign(Long assignId) throws Exception;

	/** 등록(채번)·수정 겸용 — 계약서 첨부 표준 COMTNFILE 처리 */
	Long save(LawSuitLawyerVO vo, List<MultipartFile> files, String userId) throws Exception;

	void delete(Long assignId) throws Exception;

	// ── 만족도 ──
	List<LawLawyerSatisVO> getSatisList(Long assignId) throws Exception;

	LawLawyerSatisVO getMySatis(Long assignId, String emplyrId) throws Exception;

	/** 1인 1회 MERGE */
	void saveSatis(LawLawyerSatisVO vo) throws Exception;
}
