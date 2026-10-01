/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelDmnLnkVO.java
 *
 * 관련자료 — DOMAIN_LINK 액션 자식 (TB_REL_DMN_LNK).
 *
 *  규정 ↔ 다른 규정/조문 연계. 회차 단위로 묶인 마스터(TB_REL_VRSN) 한 row 아래
 *  여러 링크 row 가 매달리는 다건 구조 (DELETE-then-INSERT 패턴).
 *
 *  스키마 주의:
 *   - IRVRSN_NO 가 VARCHAR2(255) — 레거시 의 특이 설계(다른 TB_REL_* 는 NUMBER). 문자열로 바인딩.
 *   - SFILE_ITEM NUMBER NOT NULL — 기본값 0 (레거시 도 "0" 디폴트).
 *   - SAWS_LST_YN NOT NULL — "Y" 면 표시 시 항상 ILAW_ID 의 현행 회차로 자동 점프.
 *
 *  레거시 RelatedController.domainLinkUpdateDo (RelatedController.java:1885-1973) 1:1 이식.
 */
package narainet.rlms.related.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class RelDmnLnkVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRDLNK_NO) */
	private Long relDmnLnkNo;

	/** TB_REL_VRSN FK (IRVRSN_NO) — 스키마 VARCHAR2 라 String */
	private String relVrsnNo;

	/** 연계 대상 SFLAG — "PROMULGATION"/"PROVISION"/"DOCUMENT" */
	private String flag;

	/** 연계 대상 ILAW_ID (규정 ID) */
	private Long lawId;

	/** 연계 대상 ILAW_NO (회차 번호) */
	private Long lawNo;

	/** 조문 단위 연계일 때 60자 코드 (없으면 "0") */
	private String fullItem;

	/** 표시 제목 — 비우면 대상 규정명/조문명 자동 유추 */
	private String title;

	/** 표시 순서 (1부터) */
	private Integer seq;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/** 항상 최신 자동 적용 ('Y'/'N') — Y 면 ILAW_NO 무시하고 현행 회차로 점프 */
	private String alwaysLatestYn;

	/** 파일 아이템 (SFILE_ITEM) — 별표 연계 시 식별, 기본 0 */
	private Long fileItem;

	// ── 조회 부가 (조인) ──────────────────────────────────────────
	/** 대상 규정명 (TB_PROM 의 현행 또는 lawNo 회차) — 표시용 */
	private String targetPromTitle;
	/**
	 * 대상 회차 IPROM_NO — dmn 점프용 (SAWS_LST_YN='Y' 면 현행, 아니면 ILAW_NO 회차.
	 * 현행 부재 폐지 규정은 저장된 ILAW_NO 회차로 폴백). 해석 불가면 NULL.
	 */
	private Long targetPromNo;
	/** 대상 분류 경로 — 표시용 */
	private String targetCatePath;
}
