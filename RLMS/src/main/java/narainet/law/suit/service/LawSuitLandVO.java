/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/LawSuitLandVO.java
 */
package narainet.law.suit.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/** 사건토지 (LAW_SUIT_LAND ← tbetia53) */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawSuitLandVO implements Serializable {

	private static final long serialVersionUID = 1L;

	private Long landId;
	private Long suitId;
	private String location;
	private String jibun;
	private Integer sortOrdr;
}
