/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/promwork/service/PromWorkActLogVO.java
 *
 * 법령 승인 액션 로그(TB_PROM_ACT_LOG) VO.
 *
 *   - polymorphic 로그 — SREF_TABLE/IREF_NO 로 어떤 도메인 row 액션인지 식별
 *     (예: SREF_TABLE='TB_PROM_WRK', IREF_NO=IPWRK_NO)
 *   - PK 채번: COMTECOPSEQ + EgovIdGnrService (egovPromActLogIdGnrService)
 *   - SFIELD_LOG CLOB 에 변경 필드 before/after 직렬화 저장 (선택)
 */
package narainet.rlms.promwork.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 법령 액션 로그 VO
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class PromWorkActLogVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── 액션 타입 상수 ─────────────────────────────────────────────
	public static final String ACT_TYPE_INSERT  = "INSERT";
	public static final String ACT_TYPE_UPDATE  = "UPDATE";
	public static final String ACT_TYPE_DELETE  = "DELETE";
	public static final String ACT_TYPE_APPROVE = "APPROVE";
	public static final String ACT_TYPE_REJECT  = "REJECT";

	// ── DB 매핑 (TB_PROM_ACT_LOG) ──────────────────────────────────
	/** 로그 번호 (IPALOG_NO, PK) */
	private Long actLogNo;

	/** 법령 번호 (IPROM_NO) */
	private Long promNo;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/** 참조 테이블명 (SREF_TABLE — polymorphic) */
	private String refTable;

	/** 참조 row PK (IREF_NO, VARCHAR2) */
	private String refNo;

	/** 액션 타입 (SACT_TYPE, INSERT/UPDATE/DELETE/APPROVE/REJECT) */
	private String actType;

	/** 액션명 (SACT_NM) */
	private String actNm;

	/** 액션 설명 (SACT_DC, VARCHAR2 4000) */
	private String actDc;

	/** 사용자 ID (SUSER_ID) */
	private String userId;

	/** 사용자명 (SUSER_NM) */
	private String userNm;

	/** 등록일시 (SINS_DT, VARCHAR2 문자열) */
	private String insDt;

	/** 워크 번호 (IPWRK_NO, FK → TB_PROM_WRK) */
	private Long workNo;

	/** 필드 변경 로그 (SFIELD_LOG, CLOB — 선택, 필드 before/after) */
	private String fieldLog;

	// ── 조회 부가 (TB_PROM 조인 결과) ───────────────────────────────
	/** 규정명 (TB_PROM.STITLE) — 제·개정내역 목록 표시용 */
	private String promTitle;

	// ── 검색 (제·개정내역 관리 목록) ────────────────────────────────
	/** 검색어 — 규정명/액션명/작업자 LIKE */
	private String searchKeyword;

	/** 액션 타입 필터 (INSERT/UPDATE/DELETE/APPROVE/REJECT, 빈값=전체) */
	private String searchActType;

	/** 기간 시작 (YYYY-MM-DD) */
	private String searchFromDt;

	/** 기간 종료 (YYYY-MM-DD) */
	private String searchToDt;

	// ── 페이징 ─────────────────────────────────────────────────────
	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
