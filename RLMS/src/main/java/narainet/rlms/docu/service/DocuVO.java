/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/docu/service/DocuVO.java
 *
 * 별표/별지서식 단위 row VO (TB_DOCU).
 *
 *  - 한 회차(IPROM_NO) 의 별표·별지·별첨 항목.  레거시 의 orangeidea.lims.model.Document 이식.
 *  - SITEM 의 첫 2자가 ITEM_TYPE: '01'=별표 / '02'=별지서식 / '03'=별첨.
 *  - 누적(상속) 모델: 회차는 변경/신규 행만 저장 → 한 회차의 전체 별표 = lawId 회차들(ILAW_NO≤) 중
 *    SITEM 별 최신 회차의 행. (TB_PROV_VRSN 과 동일 패턴)
 */
package narainet.rlms.docu.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 별표/별지서식 row VO (TB_DOCU)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.13   RLMS 전환팀   최초 생성 (별표/별지서식 트리·편집 모듈)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class DocuVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IDOCU_NO, COMTECOPSEQ.DOCU_ID 채번) */
	private Long docuNo;

	/** 회차 번호 (IPROM_NO, TB_PROM FK) — 이 별표 행이 실제 저장된 회차 */
	private Long promNo;

	// ── 식별/분류 ────────────────────────────────────────────────
	/** 항목 식별자 (SITEM). 앞 2자 = ITEM_TYPE: '01'별표 / '02'별지서식 / '03'별첨 */
	private String item;

	/** 그룹 제목 (SGRP_TITLE) — "별표", "별지서식" 등 */
	private String grpTitle;

	/** 항목 제목 (STITLE) — 트리 노드 라벨 */
	private String title;

	// ── 본문 ──────────────────────────────────────────────────────
	/** 본문 (SCONTENTS, CLOB) */
	private String contents;

	/** 사유 (SREASON, CLOB) */
	private String reason;

	/** 검색 텍스트 (SSEARCH_TEXT, CLOB) */
	private String searchText;

	// ── 개정 추적 ─────────────────────────────────────────────────
	/** 개정 유형 (SGAEJUNG_TYPE — NEW / MODIFY / NULLIFY / NULLIFY_SEMANTIC / EQUAL) */
	private String gaejungType;

	// ── 메타 ──────────────────────────────────────────────────────
	private String dispYn = "Y";
	private String startDate;
	private String insDt;
	private String sysId;
}
