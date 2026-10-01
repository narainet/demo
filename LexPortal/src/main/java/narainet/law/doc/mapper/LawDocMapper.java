/*
 * 물리적 저장 경로: /src/main/java/narainet/law/doc/mapper/LawDocMapper.java
 *
 * 소송문서(LAW_SUIT_DOC) 매퍼 — 조회 목록·사건별 목록·승인 워크플로. §7.2
 */
package narainet.law.doc.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.doc.service.LawSuitDocVO;

@Mapper
public interface LawDocMapper {

	int selectDocCnt(LawSuitDocVO searchVO);

	/** 조회 목록 (사건 조인·페이징) */
	List<LawSuitDocVO> selectDocList(LawSuitDocVO searchVO);

	/** ZIP 일괄용 — 검색 결과 전체 문서의 첨부 ID(중복·NULL 제외) */
	List<String> selectDocAtchFileIds(LawSuitDocVO searchVO);

	/** 사건 상세 탭용 — 특정 사건의 문서 목록 */
	List<LawSuitDocVO> selectDocListBySuit(@Param("suitId") Long suitId);

	LawSuitDocVO selectDoc(@Param("docId") Long docId);

	void insertDoc(LawSuitDocVO vo);

	/** 내용·파일 수정 — 승인상태 '대기'(S001)로 리셋, 승인정보 초기화 */
	void updateDoc(LawSuitDocVO vo);

	void deleteDoc(@Param("docId") Long docId);

	// ── 승인 워크플로 ──
	int selectApprovalCnt(LawSuitDocVO searchVO);

	/** 승인 목록 — pending(S001) 또는 처리(S002/S003, searchAppSts 필터) */
	List<LawSuitDocVO> selectApprovalList(LawSuitDocVO searchVO);

	/** 승인/반려 처리 — 상태·처리자·일시·의견 기록 */
	void updateApproval(LawSuitDocVO vo);
}
