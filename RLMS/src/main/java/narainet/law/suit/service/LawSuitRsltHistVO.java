/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/LawSuitRsltHistVO.java
 */
package narainet.law.suit.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/** 결과변경 이력 (LAW_SUIT_RSLT_HIST ← tbetia34 슬림화 — 결과 필드만) */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawSuitRsltHistVO implements Serializable {

	private static final long serialVersionUID = 1L;

	private Long histId;
	private Long suitId;
	private Integer histSeq;
	private String rsltKindCd;
	private String rsltKindNm;
	private String endDt;
	private String histDesc;
	private String regUserId;
	private String regDt;

	// 표시용
	private String rsltDispNm;
}
