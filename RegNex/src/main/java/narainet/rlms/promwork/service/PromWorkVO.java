/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/promwork/service/PromWorkVO.java
 *
 * 법령 승인 워크플로(TB_PROM_WRK) VO.
 *
 * 레거시(레거시) 와 다른 점
 *  - PK 채번: SQ_PROM_WRK_NO.NEXTVAL 직접 호출 폐기 → COMTECOPSEQ + EgovIdGnrService
 *  - 상태값(SSTATUS) 한글 문자열 그대로 유지 — 운영 DB 호환 (PromWorkStatus 상수 참조)
 *  - HQL/StringBuffer SQL 폐기 → MyBatis @Mapper + XML
 */
package narainet.rlms.promwork.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 법령 승인 워크플로 VO
 *
 * <pre>
 * &lt;&lt; 개정이력 &gt;&gt;
 *   2026.05.12   RLMS 전환팀   최초 생성 (레거시 PromulgationWork 이관)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class PromWorkVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── 상태 상수 (SSTATUS) — 레거시 PromulgationType 정본 문자열 그대로 (운영 6만행 호환) ──
	//   ※ 운영 TB_PROM_WRK 실데이터가 쓰는 값과 1:1 일치해야 목록 상태필터/액션버튼이
	//     기존 행에 정상 동작함. (이전 값 "신청대기/수정승인요청" 등은 운영과 불일치하여
	//     레거시 행에서 승인/반려 버튼이 안 떠 처리 불능이던 잠복결함 — 2026-06-15 정합화)
	public static final String STATUS_REQ_WAIT  = "편집중";            // 레거시 C_STATUS_TYPE_1 (신규 초기상태)
	public static final String STATUS_REQ_PEND  = "승인요청";          // 레거시 C_STATUS_TYPE_2
	public static final String STATUS_REQ_DENY  = "승인반려";          // 레거시 C_STATUS_TYPE_3
	public static final String STATUS_REQ_APPR  = "승인완료";          // 레거시 C_STATUS_TYPE_4
	// (수정권한 계열 TYPE_5~9 상수 제거 — 워크플로 폐지, 2026-07-20. DB 이력 문자열은 그대로 표시됨)

	// ── 작업종류 상수 (SACT_NM) — 레거시 PromulgationType C_WORK_NAME 정본 (운영 TB_PROM_WRK 호환) ──
	//   제정편집/개정편집 = 신청·승인 흐름(prom 의 개정구분이 "제정"이면 제정편집, 그 외 개정편집 — 레거시 insertDo).
	public static final String WORK_ENACT  = "제정편집";   // 레거시 C_WORK_NAME_1
	public static final String WORK_REVISE = "개정편집";   // 레거시 C_WORK_NAME_2

	// ── DB 매핑 (TB_PROM_WRK) ──────────────────────────────────────
	/** 워크 번호 (IPWRK_NO, PK, COMTECOPSEQ.PROMWORK_ID 채번) */
	private Long workNo;

	/** 법령 번호 (IPROM_NO, FK → TB_PROM) */
	private Long promNo;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/** 상태 (SSTATUS, PromWorkVO.STATUS_* 상수 사용) */
	private String status;

	/** 신청자/처리자 ID (SUSER_ID) */
	private String userId;

	/** 신청자/처리자 이름 (SUSER_NM) */
	private String userNm;

	/** 등록일시 (SINS_DT, VARCHAR2 문자열) */
	private String insDt;

	/** 사유 / 의견 (SREASON, CLOB) */
	private String reason;

	/** 작업종류 (SACT_NM, WORK_* 상수 — 제정편집/개정편집) */
	private String actNm;

	// ── 조회 부가 (TB_PROM 조인 결과) ───────────────────────────────
	/** 법령 제목 (TB_PROM.STITLE) */
	private String promTitle;

	/** 법령 종류 (TB_PROM.SGUBUN_ID) */
	private String promGubunId;

	/** 분류명 (TB_CATE.SNAME) */
	private String cateNm;

	/** 부서명 (TB_BUSEO.SNAME) */
	private String buseoNm;

	/** 이 행이 해당 회차(IPROM_NO)의 최신 워크 row 인지 ('Y'/'N' — 목록 액션버튼 노출 판단) */
	private String latestYn;

	/** 이 회차의 필수 열람 지정번호 (TB_READ_DUTY.IDUTY_NO) — null 이면 미지정.
	 *  지정 여부 판단과 [현황] 딥링크(dutyStatus.do?dutyNo=)에 함께 쓴다. */
	private Long dutyNo;

	// ── 검색 ───────────────────────────────────────────────────────
	/** 신청자명 검색 */
	private String searchUserNm;

	/** 상태 필터 */
	private String searchStatus;

	/** 합성 필터: 처리대기(승인요청 최신행 — 수정권한 축 폐지 2026-07-20) — 배지 링크 st=PENDING */
	private boolean searchPending;

	/** 합성 필터: 내 반려(최신행이 승인반려 + 마지막 요청 신청자=이 값) — 배지 링크 st=MYREJ (2026-07-09) */
	private String searchMyRejectedUserId;

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
