/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/sym/ccm/cca/service/CmmnDetailCodeVO.java
 *
 * 공통상세코드(COMTCCMMNDETAILCODE) VO. 복합 PK = (CODE_ID, CODE).
 */
package egovframework.com.sym.ccm.cca.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 공통상세코드 VO (COMTCCMMNDETAILCODE)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.08   RLMS 전환팀   최초 생성 (ccm cca/cde 통합 대체)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class CmmnDetailCodeVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 코드그룹 ID (CODE_ID, PK1) */
	private String codeId;

	/** 상세코드 (CODE, PK2) — 예: FT_GUBUN_1 */
	private String code;

	/** 상세코드명 (CODE_NM) */
	private String codeNm;

	/** 설명 (CODE_DC) */
	private String codeDc;

	/** 사용 여부 (USE_AT) — Y/N */
	private String useAt;

	// ── 감사 ─────────────────────────────────────────────────
	/** 등록/수정자 로그인 ID */
	private String userId;
}
