/*
 * 물리적 저장 경로: /src/main/java/narainet/law/calcset/service/LawCalcRateVO.java
 *
 * 계산기 요율 (LAW_CALC_RATE) — 타입×항목×적용시작일 시점별 세트. §4.3·§7.4·§7.13
 *   계산기(cost)는 기준일 유효 세트를 읽기만, 요율설정(calcset)은 세트 편집.
 */
package narainet.law.calcset.service;

import java.io.Serializable;
import java.math.BigDecimal;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawCalcRateVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_CALC_RATE_ID) */
	private Long rateId;
	/** 계산기 타입 — STAMP/STAMP_MULT/POST_UNIT/POST_COUNT/LAWYER/LEGAL_INT */
	private String calcType;
	/** 항목 식별 (배율=C1~C8·MIN_AMT, 회수=T01~T17, 이율=CIVIL/COMM/SOCHOK). 구간표·단가는 NULL */
	private String itemCd;
	/** 적용시작일 (YYYYMMDD — 개정 시행일) */
	private String applyDt;
	/** 구간 하한(소가) — 구간표 행만 */
	private Long sectionAmt;
	/** 값 — 율/단가/배율/회수/이율 (NUMBER(12,6)) */
	private BigDecimal rateVal;
	/** 구간 가산액 또는 고정액 */
	private Long addAmt;
	/** 근거 */
	private String rmk;
	/** 사용여부 (Y/N — 과거 세트 소프트삭제) */
	private String useYn;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;
}
