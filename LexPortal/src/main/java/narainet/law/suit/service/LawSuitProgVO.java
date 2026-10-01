/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/LawSuitProgVO.java
 */
package narainet.law.suit.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/** 진행상황·기일 겸용 (LAW_SUIT_PROG ← tbetia19 — 일정관리와 공유 §7.5) */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawSuitProgVO implements Serializable {

	private static final long serialVersionUID = 1L;

	private Long progId;
	private Long suitId;
	/** 진행종류 (LAW_PROG_KIND) */
	private String progKindCd;
	/** 기일구분 (LAW_DYPR_KIND — 종류가 기일일 때) */
	private String dyprKindCd;
	private String progDt;
	/** HHMM */
	private String progTm;
	private String place;
	private String progDesc;
	/** 진행상태 (LAW_PROG_STAT) */
	private String statCd;
	private String resultDesc;

	// 표시용
	private String progKindNm;
	private String dyprKindNm;
	private String statNm;
}
