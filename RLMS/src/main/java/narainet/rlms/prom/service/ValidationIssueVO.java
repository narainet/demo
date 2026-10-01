/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ValidationIssueVO.java
 *
 * 유효성 검사 결과 한 건.
 *   - severity: ERROR / WARN / INFO
 *   - category: DUPLICATE_ITEM / EMPTY_CONTENT / DATE_INVALID / TREE_INCONSISTENT 등
 *   - promNo / fullItem / message
 */
package narainet.rlms.prom.service;

import java.io.Serializable;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
@AllArgsConstructor
public class ValidationIssueVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── severity ───────────────────────────────────────────────────
	public static final String SEVERITY_ERROR = "ERROR";
	public static final String SEVERITY_WARN  = "WARN";
	public static final String SEVERITY_INFO  = "INFO";

	// ── category ───────────────────────────────────────────────────
	public static final String CAT_DUPLICATE_ITEM    = "DUPLICATE_ITEM";
	public static final String CAT_EMPTY_CONTENT     = "EMPTY_CONTENT";
	public static final String CAT_DATE_INVALID      = "DATE_INVALID";
	public static final String CAT_TREE_INCONSISTENT = "TREE_INCONSISTENT";
	public static final String CAT_PROV_MISSING      = "PROV_MISSING";

	private String severity;
	private String category;

	/** 검증 대상 법령 (선택) */
	private Long promNo;

	/** 검증 대상 법령 제목 (조회용) */
	private String promTitle;

	/** 조항 식별자 (TB_PROV_VRSN.SFULL_ITEM, 선택) */
	private String fullItem;

	/** 사람이 읽는 메시지 */
	private String message;

	/** 화면 표시용 조항 라벨 — SFULL_ITEM 원문 노출 금지(2026-07-16). JSP EL ${i.itemLabel} */
	public String getItemLabel() { return ProvItemLabel.of(fullItem); }
}
