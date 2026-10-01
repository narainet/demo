/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/lawquest/service/LawQuestService.java
 */
package narainet.rlms.lawquest.service;

import java.util.List;
import java.util.Map;

public interface LawQuestService {

	/** 페이징 목록 ({resultList, resultCnt}) */
	Map<String, Object> getList(LawQuestVO vo);

	/** 엑셀용 전체 목록 (페이징 없음, 동일 검색조건) */
	List<LawQuestVO> getListAll(LawQuestVO vo);

	/** 단건 조회. increaseRead=true 면 조회수 +1 (상세 화면) */
	LawQuestVO getDetail(Long no, boolean increaseRead);

	/** 작성연도 목록 (검색 필터) */
	List<String> getYears();

	/** 등록 — PK 채번 후 INSERT, 생성된 NO 반환 */
	Long insert(LawQuestVO vo) throws Exception;

	/** 전체 메타/회신 수정 */
	void update(LawQuestVO vo) throws Exception;

	/** 삭제 — 본문 + 첨부 전체 정리 */
	void delete(Long no) throws Exception;

	/** 답변 권한자 여부 (TB_LAWQUEST_ADMIN 사번) */
	boolean isAnswerAdmin(String sabun);

	// ── 답변권한자 레지스트리 (TB_LAWQUEST_ADMIN) ──────────────
	/** 답변권한자 전체 목록 */
	List<LawQuestAdminVO> getAdminList();

	/** 답변권한자 추가. 이미 존재하는 사번이면 false(중복), 추가 성공이면 true */
	boolean addAdmin(String sabun, String name) throws Exception;

	/** 답변권한자 삭제 */
	void removeAdmin(String sabun) throws Exception;

	/** 회원 검색 (답변자 추가 picker — 이름/ID) */
	java.util.List<java.util.Map<String, Object>> searchMembers(String kw);
}
