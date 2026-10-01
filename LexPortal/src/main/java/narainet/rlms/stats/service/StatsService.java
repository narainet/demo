/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/service/StatsService.java
 */
package narainet.rlms.stats.service;

import java.util.List;
import java.util.Map;

public interface StatsService {

	

	

	

	/** 게시판 뷰 카운트 적재(TB_STATS_BBS_VIEW, 사용자 게시글 상세 GET 실열람 1회=1행). 채번=COMTECOPSEQ 'STATS_BBS_VIEW_NO' */
	void recordBbsView(String bbsId, Long nttId) throws Exception;

	/** 게시판 조회통계 (게시글별, 상위 200) */
	List<StatsVO> getBbsViewStats(StatsVO vo);

	/* 접속통계는 표준 웹로그 모듈(EgovWebLogService.selectAccessStats)로 이관 — 2026-08-06 */



	

	/** 사용자 활동 로그 적재(TB_ACT_LOG) — 감사 실패는 내부에서 삼킴(warn), 본 흐름을 막지 않음.
	 *  task=화면 '작업' 드롭다운에 그대로 노출되는 한국어 라벨, name=화면 '대상' 열 */
	void recordAction(String task, String refTable, Long refNo, String name,
			String userId, String userNm, String ip);

	/** 사용자 활동 로그 (페이징 {resultList, resultCnt}) */
	Map<String, Object> getActionLog(StatsVO vo);

	/** 작업 구분 목록 (필터 드롭다운) */
	List<String> getTaskKinds();
}
