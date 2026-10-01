/*
 * 물리적 저장 경로: /src/main/java/narainet/law/assign/service/LawLawyerSatisVO.java
 *
 * 법무법인 만족도(간이) (LAW_LAWYER_SATIS ← tbetia45 대체) — 평가 대상=선임(ASSIGN_ID) 단위.
 * PK(ASSIGN_ID, EMPLYR_ID) 복합 — 1인 1회 MERGE 갱신. §4.3·§7.6
 */
package narainet.law.assign.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawLawyerSatisVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 선임 ID (LAW_SUIT_LAWYER FK — 복합 PK) */
	private Long assignId;
	/** 평가자 ID (COMTNEMPLYRINFO.EMPLYR_ID — 복합 PK, 1인 1회) */
	private String emplyrId;
	/** 별점 (1~5) */
	private Integer score;
	/** 의견 (선택) */
	private String opinion;
	private String regDt;
	private String updDt;

	/** 표시용 — 평가자 성명 (COMTNEMPLYRINFO.USER_NM) */
	private String evaluatorNm;
}
