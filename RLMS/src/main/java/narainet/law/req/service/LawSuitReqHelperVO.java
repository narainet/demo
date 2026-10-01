/*
 * 물리적 저장 경로: /src/main/java/narainet/law/req/service/LawSuitReqHelperVO.java
 *
 * 소송의뢰 소송수행 보조자 (LAW_SUIT_REQ_HELPER ← tbetia13 재사용분) — 부서명은 자유 텍스트(외부 인원 허용). §4.3
 */
package narainet.law.req.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawSuitReqHelperVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_REQ_HELPER_ID) */
	private Long helperId;
	/** 의뢰 ID (LAW_SUIT_REQ FK) */
	private Long reqId;
	/** 부서명 (자유 텍스트) */
	private String deptNm;
	/** 담당자 성명 */
	private String helperNm;
	/** 전화 */
	private String tel;
	/** 휴대폰 */
	private String mobile;
	/** 이메일 */
	private String email;
	/** 표시 순서 */
	private Integer sortOrdr;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;
}
