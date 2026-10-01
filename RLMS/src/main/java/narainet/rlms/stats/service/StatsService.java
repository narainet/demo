/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/service/StatsService.java
 */
package narainet.rlms.stats.service;

import java.util.List;
import java.util.Map;

public interface StatsService {

	/** 뷰 카운트 적재(TB_STATS_FT_VIEW, 뷰어 진입 1회=1행). 채번=COMTECOPSEQ 'STATS_FT_VIEW_NO' */
	void recordView(Long lawId, String gubunId) throws Exception;

	/** 규정별 조회통계 (상위 200) */
	List<StatsVO> getViewStats(StatsVO vo);

	/** 규정 누적 조회수 (전 기간, lawId=규정 계보 단위) — 전문뷰어 타이틀 노출용 */
	long getViewCount(Long lawId);

	/** 게시판 뷰 카운트 적재(TB_STATS_BBS_VIEW, 사용자 게시글 상세 GET 실열람 1회=1행). 채번=COMTECOPSEQ 'STATS_BBS_VIEW_NO' */
	void recordBbsView(String bbsId, Long nttId) throws Exception;

	/** 게시판 조회통계 (게시글별, 상위 200) */
	List<StatsVO> getBbsViewStats(StatsVO vo);

	/** 접속통계 — 차원별 구간 집계(빈 구간 0 채움, label=구간 키) */
	List<StatsVO> getAccessStats(StatsVO vo);

	/** 접속통계 기간 합계 (cnt=총 접속수, ucnt=순 접속자수) */
	StatsVO getAccessTotals(StatsVO vo);

	/** 기간별 검색어통계 (상위 200) */
	List<StatsVO> getKeywordStats(StatsVO vo);

	/** 부서별 규정통계 (현행 규정 수) */
	List<StatsVO> getDeptStats(StatsVO vo);

	/** 사용자 활동 로그 적재(TB_ACT_LOG) — 감사 실패는 내부에서 삼킴(warn), 본 흐름을 막지 않음.
	 *  task=화면 '작업' 드롭다운에 그대로 노출되는 한국어 라벨, name=화면 '대상' 열 */
	void recordAction(String task, String refTable, Long refNo, String name,
			String userId, String userNm, String ip);

	/** 사용자 활동 로그 (페이징 {resultList, resultCnt}) */
	Map<String, Object> getActionLog(StatsVO vo);

	/** 작업 구분 목록 (필터 드롭다운) */
	List<String> getTaskKinds();
}
