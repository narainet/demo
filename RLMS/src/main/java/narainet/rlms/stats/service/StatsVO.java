/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/service/StatsVO.java
 *
 * 통계/로그 조회 VO — 레거시 statistic_* 이관.
 *   원천(실DB 이관 데이터):
 *     · 규정별 조회통계  = TB_STATS_FT_VIEW (ILAW_ID/ICNT/SINS_DT)
 *     · 검색어 통계      = TB_STATS_KWD     (SKWD/ICNT/SINS_DT)
 *     · 사용자 활동 로그 = TB_ACT_LOG       (STASK, SUSER_ID, SUSER_NAME, SINS_DT, SINS_IP)
 *   읽기전용 집계 리포트(필터: 기간/작업/사용자). 단일 VO로 필터+결과 공용.
 */
package narainet.rlms.stats.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class StatsVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── 필터 ──────────────────────────────────────────────
	/** 시작일 (YYYY-MM-DD) */
	private String fromDt;
	/** 종료일 (YYYY-MM-DD) */
	private String toDt;
	/** 작업 필터 (TB_ACT_LOG.STASK — 열람/로그인/파일다운/…) */
	private String searchTask;
	/** 사용자 필터 (SUSER_NAME LIKE) */
	private String searchUser;
	/** 접속통계 차원 (HOUR/DAY/WEEK7/MONTH/YEAR/DOW) */
	private String dimension;

	// ── 집계 결과 (규정별조회/검색어 공용) ────────────────
	/** 라벨 (규정명 또는 검색어) */
	private String label;
	/** 집계 수치 (조회수/검색횟수) */
	private Long cnt;
	/** 법령 ID (규정별조회 — 뷰어 링크용) */
	private Long lawId;
	/** 분류명 (규정별조회 — 동명 규정 구분) */
	private String cateNm;
	/** 소관부서명 (규정별조회 — 동명 규정 구분) */
	private String deptNm;

	// ── 게시판 조회통계 결과 ─────────────────────────────
	/** 게시판 ID (RTRIM 저장 — 글 링크용) */
	private String bbsId;
	/** 게시글 ID (글 링크용) */
	private Long nttId;
	/** 게시판명 */
	private String bbsNm;
	/** 게시글 사용여부 (N=삭제글 표시) */
	private String useAt;

	// ── 접속통계 결과 ────────────────────────────────────
	/** 순 접속자수 (구간 내 DISTINCT CONECT_ID) */
	private Long ucnt;

	// ── 사용자 활동 로그 결과 ─────────────────────────────
	private String task;
	private String userId;
	private String userName;
	private String refTable;
	private String refName;
	private String insDt;
	private String insIp;

	// ── 페이징 (사용자 활동 로그) ─────────────────────────
	private int pageIndex = 1;
	private int pageUnit = 20;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 20;
}
