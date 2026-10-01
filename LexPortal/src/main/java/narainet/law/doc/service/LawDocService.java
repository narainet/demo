/*
 * 물리적 저장 경로: /src/main/java/narainet/law/doc/service/LawDocService.java
 */
package narainet.law.doc.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

public interface LawDocService {

	/** 조회 목록+총건수 (파일 목록 동봉) */
	Map<String, Object> getList(LawSuitDocVO searchVO) throws Exception;

	/** ZIP 일괄용 — 검색 결과 전체 문서의 첨부 ID */
	List<String> getZipAtchFileIds(LawSuitDocVO searchVO) throws Exception;

	/** 사건 상세 탭용 — 특정 사건의 문서 목록(파일 동봉) */
	List<LawSuitDocVO> getListBySuit(Long suitId) throws Exception;

	LawSuitDocVO getDoc(Long docId) throws Exception;

	/** 등록(대기)·수정(대기 리셋) 겸용 — 첨부 표준 COMTNFILE */
	Long save(LawSuitDocVO vo, List<MultipartFile> files, String userId) throws Exception;

	void delete(Long docId) throws Exception;

	// ── 승인 워크플로 ──
	Map<String, Object> getApprovalList(LawSuitDocVO searchVO) throws Exception;

	/** 승인/반려 처리 (S002/S003) */
	void approve(LawSuitDocVO vo) throws Exception;
}
