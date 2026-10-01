/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/readduty/service/ReadDutyTgtVO.java
 *
 * 필수 열람 대상 행(TB_READ_DUTY_TGT) VO — 부서/개인 혼합 지정 (TB_CATE_READER 패턴).
 */
package narainet.rlms.readduty.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class ReadDutyTgtVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 대상 유형 (STGT_TY — 'DEPT' 부서 / 'USER' 개인) */
	private String tgtTy;

	/** 대상 식별자 (STGT_ID — DEPT=ORGNZT_ID / USER=ESNTL_ID) */
	private String tgtId;

	/** 표시명 (조회 전용 — DEPT=부서명 / USER=이름(아이디)) */
	private String tgtNm;
}
