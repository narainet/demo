/*
 * 물리적 저장 경로: /src/main/java/narainet/law/schedule/service/LawScheduleVO.java
 *
 * 일정(기일) — LAW_SUIT_PROG 중 PROG_KIND_CD='S001'(기일) 행. 등록화면 진행상황과 같은 테이블 공유. §7.5
 */
package narainet.law.schedule.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawScheduleVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PROG_ID (채번 LAW_PROG_ID) */
	private Long progId;
	/** 사건 ID (LAW_SUIT FK) */
	private Long suitId;
	/** 기일구분 (LAW_DYPR_KIND) */
	private String dyprKindCd;
	/** 기일 일자 (YYYYMMDD, 화면 yyyy-MM-dd) */
	private String progDt;
	/** 시각 (HHMM) */
	private String progTm;
	private String place;
	/** 내용(등록화면 진행상황 그리드 표기용 — 일정 등록 시 기일구분명으로 채움) */
	private String progDesc;
	/** 결과 */
	private String resultDesc;
	/** 진행상태 (LAW_PROG_STAT — S001 진행/S002 완료) */
	private String statCd;

	// ── 표시용 조인 ──
	private String dyprKindNm;
	private String statNm;
	private String caseNo;
	private String caseNm;
	private String courtNm;
	private String instanceNm;
	/** 소송수행자(LAW_SUIT_STAFF SORT_ORDR 0) */
	private String staffNm;
	/** 보조수행자(SORT_ORDR 1) */
	private String helperNm;

	// ── 검색 ──
	/** 달력 대상 월 (YYYYMM) */
	private String searchYm;
	private String searchFrom;   // 기간 시작 (YYYYMMDD)
	private String searchTo;     // 기간 종료
	private String searchCaseNo; // 사건번호 키워드
	private String searchDyprKind; // 기일구분
	private String searchInstance; // 심급
	/** 특정 일자(당일 그리드/달력 셀) */
	private String targetDt;
}
