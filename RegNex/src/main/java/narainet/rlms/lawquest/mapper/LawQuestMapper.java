/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/lawquest/mapper/LawQuestMapper.java
 */
package narainet.rlms.lawquest.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.lawquest.service.LawQuestAdminVO;
import narainet.rlms.lawquest.service.LawQuestVO;

@Mapper
public interface LawQuestMapper {

	/** 페이징 목록 (검색: 조건/유형/연도, publicOnly) */
	List<LawQuestVO> selectList(@Param("vo") LawQuestVO vo);

	int selectListCnt(@Param("vo") LawQuestVO vo);

	/** 엑셀용 전체 목록 (페이징 없음, 동일 검색조건) */
	List<LawQuestVO> selectListAll(@Param("vo") LawQuestVO vo);

	/** PK 단건 (첨부건수 포함) */
	LawQuestVO selectByNo(@Param("no") Long no);

	/** 작성연도 목록 (검색 필터 드롭다운용, 내림차순 distinct) */
	List<String> selectYears();

	int insert(LawQuestVO vo);

	/** 전체 메타 수정 */
	int update(LawQuestVO vo);

	/** 조회수 +1 */
	int increaseReadnum(@Param("no") Long no);

	int delete(@Param("no") Long no);

	/** 답변 권한자 여부 (TB_LAWQUEST_ADMIN 사번 존재 = 1) */
	int countAdmin(@Param("sabun") String sabun);

	// ── 답변권한자 레지스트리 (TB_LAWQUEST_ADMIN) ──────────────
	/** 답변권한자 전체 목록 (사번 오름차순) */
	List<LawQuestAdminVO> selectAdminList();

	/** 답변권한자 추가 */
	int insertAdmin(LawQuestAdminVO vo);

	/** 답변권한자 삭제 (사번=USER_ID) */
	int deleteAdmin(@Param("sabun") String sabun);

	/** 회원 검색 (이름/ID LIKE, COMVNUSERMASTER+부서, 최대 50) — 답변자 추가 picker */
	List<Map<String, Object>> searchMembers(@Param("kw") String kw);
}
