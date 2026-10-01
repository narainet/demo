/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/readduty/service/ReadDutyVO.java
 *
 * 필수 열람 지정(TB_READ_DUTY) VO.
 *  - 승인된 개정 회차(IPROM_NO)에 열람 의무 대상을 지정 (회차당 1건 — UNIQUE)
 *  - 대상 = 전사(SALL_YN='Y') 또는 TB_READ_DUTY_TGT 행(부서/개인 혼합)
 *  - 확인은 TB_READ_DUTY_CHK 2단계: 열람(SREAD_DT, 뷰어 자동) / 숙지(SCONF_DT, 버튼)
 */
package narainet.rlms.readduty.service;

import java.io.Serializable;
import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class ReadDutyVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IDUTY_NO, COMTECOPSEQ.READ_DUTY_ID) */
	private Long dutyNo;

	/** 대상 법령 논리 ID (ILAW_ID — TB_PROM 에서 파생) */
	private Long lawId;

	/** 대상 회차 (IPROM_NO — 승인된 개정 회차, 회차당 지정 1건) */
	private Long promNo;

	/** 전사 대상 여부 (SALL_YN 'Y'/'N' — Y 면 대상 행 무시) */
	private String allYn;

	/** 열람 기한 (SDUE_DT YYYYMMDD — null=무기한) */
	private String dueDt;

	/** 지정자 로그인 ID (SINS_ID) */
	private String insId;

	/** 지정자명 (SINS_NM — 표시 스냅샷) */
	private String insNm;

	/** 지정 일시 (SINS_DT YYYYMMDDHH24MISS) */
	private String insDt;

	/** 대상 행 목록 (TB_READ_DUTY_TGT — SALL_YN='N' 일 때만 의미) */
	private List<ReadDutyTgtVO> tgtList;
}
