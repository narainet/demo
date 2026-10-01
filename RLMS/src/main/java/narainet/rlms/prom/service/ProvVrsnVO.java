/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ProvVrsnVO.java
 *
 * 조항 본문의 "단위 row" VO (TB_PROV_VRSN). 21 컬럼.
 *
 * 의미:
 *  - 한 법령(IPROM_NO) 의 본문이 조/항/호/문장/줄 단위 row 로 분해 저장된다.
 *  - 같은 법령의 row 들은 fullItem(예: "1조-1항-1호") 으로 식별.
 *  - 각 row 는 자기 자신의 개정 유형(SGAEJUNG_TYPE) 과 시점(SSTART_DT) 보유.
 *  - 이 모델 덕분에:
 *      * 두 시점의 row 집합을 FULL OUTER JOIN ON SFULL_ITEM 으로 비교 가능
 *      * SCONTENTS 컬럼에 Oracle Text 인덱스 → 단위 정밀 검색
 *
 * 분해 로직: ProvVrsnService.decomposeAndStore() — BodyParser 가 HTML 을 단위로 분해.
 */
package narainet.rlms.prom.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 조항 본문 단위 row VO (TB_PROV_VRSN)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class ProvVrsnVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IPVRSN_NO, COMTECOPSEQ.PROV_VRSN_ID 채번) */
	private Long provVrsnNo;

	/** 법령 번호 (IPROM_NO, TB_PROM FK) */
	private Long promNo;

	// ── 단위 식별자 ───────────────────────────────────────────────
	/** 전체 식별자 (SFULL_ITEM) — 예: "1조-1항-1호" — 비교 join 키 */
	private String fullItem;

	/** 화면 표시용 조항 라벨 — SFULL_ITEM 원문 노출 금지(2026-07-16). JSP EL ${row.itemLabel} */
	public String getItemLabel() { return ProvItemLabel.of(fullItem); }

	/** 상위 단위 (SITEM) — 예: "1조" */
	private String item;

	/** 하위 단위 (SSUB_ITEM) — 예: "1항-1호" */
	private String subItem;

	/** 이동된 경우 새 식별자 (SMOVE_FULL_ITEM) */
	private String moveFullItem;

	// ── 단위 유형 ─────────────────────────────────────────────────
	/** 단위 유형 (SUNIT_TYPE — 조/항/호/문장/줄 등) */
	private String unitType;

	/** 원본 유형 (SNATIVE_TYPE) */
	private String nativeType;

	/** 스타일 코드 (SSTYLE_ID) */
	private String styleId;

	/** 계층 깊이 (ILEVEL) */
	private Integer level;

	/** 같은 레벨 내 순서 (IINDEX) */
	private Integer index;

	// ── 본문 ──────────────────────────────────────────────────────
	/** 단위 제목 (STITLE) */
	private String title;

	/** 단위 본문 (SCONTENTS, CLOB) — Oracle Text 인덱스 대상 */
	private String contents;

	/** 단위 사유 (SREASON, CLOB) */
	private String reason;

	/** 검색 텍스트 (SSEARCH_TEXT, CLOB) */
	private String searchText;

	// ── 개정 추적 ─────────────────────────────────────────────────
	/** 개정 유형 (SGAEJUNG_TYPE — 신규/개정/삭제) */
	private String gaejungType;

	/** 개정 숨김 여부 (SGAEJUNG_HIDE_YN) */
	private String gaejungHideYn = "N";

	/** 사용자 수정 여부 (SUSER_MODIFIED_YN) */
	private String userModifiedYn = "N";

	// ── 메타 ──────────────────────────────────────────────────────
	private String dispYn = "Y";
	private String startDate;
	private String insDt;
	private String sysId;

	// ── 전문검색 결과 부가 (Oracle Text SCORE) ────────────────────
	/** 검색 결과의 SCORE(1) (Oracle Text rank) */
	private Double rank;
}
