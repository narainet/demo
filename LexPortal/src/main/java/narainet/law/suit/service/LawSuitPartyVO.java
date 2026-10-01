/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/LawSuitPartyVO.java
 */
package narainet.law.suit.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 당사자 (LAW_SUIT_PARTY ← tbetia14).
 * 주민번호: 입력=jumin(평문, 저장 시 암호화 후 폐기 — §4.4), 저장=juminEnc(ARIA Base64),
 * 표시=hasJumin+juminMask(생년월일 기반 마스킹 — 복호화하지 않는다).
 */
@Getter
@Setter
@ToString(exclude = {"jumin", "juminEnc"})
@NoArgsConstructor
public class LawSuitPartyVO implements Serializable {

	private static final long serialVersionUID = 1L;

	private Long partyId;
	private Long suitId;
	/** P=원고 / D=피고 / S=보조참가인 */
	private String partyType;
	private String partyNm;
	/** 생년월일 (YYMMDD 또는 YYYYMMDD) */
	private String birth;
	/** 입력 전용 평문 주민번호 (서버 밖으로 다시 나가지 않는다) */
	private String jumin;
	/** 암호문 (DB 컬럼 JUMIN_ENC) */
	private String juminEnc;
	/** 대리인 */
	private String agentNm;
	private Integer sortOrdr;

	// 표시용
	private boolean hasJumin;
	private String juminMask;
}
