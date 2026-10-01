/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/mapper/StatsMapper.java
 */
package narainet.rlms.stats.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.stats.service.StatsVO;

@Mapper
public interface StatsMapper {

	

	

	

	/** 게시판 뷰 카운트 적재 — 사용자 게시글 상세 GET 실열람 1회=1행 (ICNT=1, SINS_DT=오늘) */
	void insertBbsViewStat(@Param("id") int id, @Param("bbsId") String bbsId, @Param("nttId") Long nttId);

	/** 게시판 조회통계 (TB_STATS_BBS_VIEW, 게시글별 기간 집계 top N) */
	List<StatsVO> selectBbsViewStats(@Param("vo") StatsVO vo);

	/* 접속통계(selectAccessStats/selectAccessTotals)는 표준 웹로그 매퍼(WebLog.*)로 이관 — 2026-08-06 */

	/** 기간별 검색어통계 (TB_STATS_KWD, top N) */
	List<StatsVO> selectKeywordStats(@Param("vo") StatsVO vo);

	/** 부서별 규정통계 (현행 규정 수를 소관부서별 집계) */
	List<StatsVO> selectDeptStats(@Param("vo") StatsVO vo);

	/** 사용자 활동 로그 적재 — 로그인/규정 열람/파일 다운로드/통합검색 1건=1행 */
	void insertActLog(@Param("id") int id, @Param("task") String task,
			@Param("refTable") String refTable, @Param("refNo") Long refNo, @Param("name") String name,
			@Param("userId") String userId, @Param("userNm") String userNm, @Param("ip") String ip);

	/** 사용자 활동 로그 (TB_ACT_LOG, 기간/작업/사용자 필터 + 페이징) */
	List<StatsVO> selectActionLog(@Param("vo") StatsVO vo);

	int selectActionLogCnt(@Param("vo") StatsVO vo);

	/** 작업(STASK) 구분 목록 (필터 드롭다운) */
	List<String> selectTaskKinds();
}
