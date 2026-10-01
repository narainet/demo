/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/promwork/mapper/PromWorkMapper.java
 *
 * 법령 승인 워크플로 + 액션 로그 MyBatis Mapper.
 *   XML namespace = 본 인터페이스 FQN.
 *   XML file:  /src/main/resources/egovframework/mapper/rlms/promwork/PromWork_SQL_oracle.xml
 */
package narainet.rlms.promwork.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.promwork.service.PromWorkActLogVO;
import narainet.rlms.promwork.service.PromWorkVO;

@Mapper
public interface PromWorkMapper {

	// ── 조회 ───────────────────────────────────────────────────────

	/** 작업승인 목록 (검색 + 페이징) */
	List<PromWorkVO> selectPromWorkList(PromWorkVO vo);

	/** 작업승인 목록 카운트 */
	int selectPromWorkListCnt(PromWorkVO vo);

	/** PK 단건 조회 (조인 포함) */
	PromWorkVO selectPromWorkByNo(@Param("workNo") Long workNo);

	/** 특정 promNo 의 최신 워크 row */
	PromWorkVO selectLatestByPromNo(@Param("promNo") Long promNo);

	/** 특정 promNo 의 모든 워크 row (이력) */
	List<PromWorkVO> selectListByPromNo(@Param("promNo") Long promNo);

	/** 알림 배지 — 전역 미처리 승인/수정요청(최신 워크 기준) 회차 수 (승인자용) */
	int selectPendingApprovalCnt();

	/** 알림 배지 — 내가 신청했다가 반려된(최신 워크 기준) 회차 수 (작성자용) */
	int selectMyRejectedCnt(@Param("userId") String userId);

	/** 회차 행 잠금(SELECT FOR UPDATE) — 상태 전이의 check-then-insert 경합 직렬화. 미존재 회차는 null */
	Long lockPromRow(@Param("promNo") Long promNo);

	// ── 변경 ───────────────────────────────────────────────────────

	/** 신규 워크 row (상태 전이마다 새 row INSERT — 레거시 동작과 동일) */
	int insertPromWork(PromWorkVO vo);

	/** 규정(회차) 삭제 시 워크행 동반 정리 — 고아 워크행=유령 승인대기 배지 방지 */
	int deleteByPromNo(@Param("promNo") Long promNo);

	// ── 액션 로그 ──────────────────────────────────────────────────

	/** 액션 로그 신규 row */
	int insertActLog(PromWorkActLogVO log);

	/** 특정 promNo 의 액션 로그 목록 (이력 화면용) */
	List<PromWorkActLogVO> selectActLogListByPromNo(@Param("promNo") Long promNo);

	/** 제·개정내역 관리 — 전역 액션 로그 목록 (검색 + 페이징, 규정명 조인) */
	List<PromWorkActLogVO> selectActLogList(PromWorkActLogVO vo);

	/** 제·개정내역 관리 — 전역 액션 로그 카운트 */
	int selectActLogListCnt(PromWorkActLogVO vo);
}
