/*
 * 물리적 저장 경로: /src/main/java/narainet/law/cost/service/LawSuitCostVO.java
 *
 * 소송비용 (LAW_SUIT_COST ← tbetia20+21) — 단일행 비용. §7.3·§4.2
 */
package narainet.law.cost.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawSuitCostVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_COST_ID) */
	private Long costId;
	/** 사건 ID (LAW_SUIT FK) */
	private Long suitId;
	/** 비용종류(LAW_COST_KIND) */
	private String costKindCd;
	private String costKindNm;
	/** 금액(원) */
	private Long costAmt;
	/** 내역 */
	private String costDesc;
	/** 지급요청일 (YYYYMMDD, 화면 yyyy-MM-dd) */
	private String payDmndDt;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;

	// ── 목록 표시용 사건 조인 ──
	private String courtNm;
	private String caseNo;
	private String caseNm;

	// ── 검색 (조회 화면 — 문서조회 패턴 + 사건명) ──
	private String searchFrFrom;
	private String searchFrTo;
	private String searchItpt;
	private String searchCaseKind;
	private String searchRslt;
	private String searchCaseYear;
	private String searchCaseSign;
	private String searchCaseSerial;
	private String searchCaseNm;
	/** 비용종류 필터(선택) */
	private String searchCostKind;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;

	/** 목록 하단 합계 (검색 전체 금액 합) */
	private Long totalAmt;
}
