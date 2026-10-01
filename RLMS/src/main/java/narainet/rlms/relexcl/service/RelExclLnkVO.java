/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/relexcl/service/RelExclLnkVO.java
 *
 * 자동링크 제외범위 (TB_REL_EXCL_LNK) VO.
 *
 * 레거시 모델:
 *   - IEXCL_LAW_ID = "이 법령" (제외범위의 owner — 자동링크 처리 대상 법령)
 *   - SFLAG = 'full_text_gubun'    + SGUBUN_ID = 제외할 SGUBUN 그룹
 *   - SFLAG = 'full_text_category' + ICATE_NO  = 제외할 분류 (하위 분류 포함, CONNECT BY)
 *   - SFLAG = 'full_text_leaf'     + ILAW_ID   = 제외할 특정 법령
 */
package narainet.rlms.relexcl.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class RelExclLnkVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRELNK_NO) */
	private Long relnkNo;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/** 분류 ('full_text_gubun' / 'full_text_category' / 'full_text_leaf') */
	private String flag;

	/** 제외할 SGUBUN (SFLAG='full_text_gubun' 일 때) */
	private String gubunId;

	/** 제외할 분류 (SFLAG='full_text_category' 일 때) */
	private Long cateNo;

	/** 제외할 법령 (SFLAG='full_text_leaf' 일 때) */
	private Long lawId;

	/** "이 법령" — 제외범위의 owner */
	private Long exclLawId;

	/** 등록일시 (SINS_DT) */
	private String insDt;

	// ── 조회 부가 (JOIN) ────────────────────────────────────
	/** 표시용 라벨: gubun 이면 코드명, category 면 분류 풀네임, leaf 면 "분류 > 규정명" */
	private String displayName;
}
