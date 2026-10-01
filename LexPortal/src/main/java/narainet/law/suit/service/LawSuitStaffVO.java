/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/LawSuitStaffVO.java
 */
package narainet.law.suit.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/** 소송수행자 (LAW_SUIT_STAFF ← tbetia50, 부서=COMTNORGNZTINFO) */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawSuitStaffVO implements Serializable {

	private static final long serialVersionUID = 1L;

	private Long staffId;
	private Long suitId;
	private String orgnztId;
	private String staffNm;
	private String assignDt;
	private Integer sortOrdr;

	/** 표시용 부서명 */
	private String orgnztNm;
}
