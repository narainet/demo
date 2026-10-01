/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ProvHtmlVO.java
 *
 * 조항 HTML 본문(TB_PROV_HTML) VO. 현재 화면 본문 1덩어리.
 * 입력 시 ProvVrsnService.decomposeAndStore() 가 호출되어 단위 row(TB_PROV_VRSN) 도 함께 갱신.
 *
 * 트리거 효과:
 *   - TRG_DEL_PROV_HTML: TB_REL_VRSN(PROVISION 플래그) + TB_ATTACH(SREF_TABLE='TB_PROV_HTML') 자동 삭제
 *   - TRG_UPD_PROV_HTML: TB_FT_CACHE_QUEUE 에 캐시 무효화 row INSERT
 */
package narainet.rlms.prom.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 조항 HTML 본문 VO (TB_PROV_HTML)
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
public class ProvHtmlVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IPHTML_NO, COMTECOPSEQ.PROV_HTML_ID 채번) */
	private Long provHtmlNo;

	/** 법령 번호 (IPROM_NO, TB_PROM FK) */
	private Long promNo;

	/** 조항 식별자 (SITEM, 예: "제3조") */
	private String item;

	/** 조항 제목 (STITLE) */
	private String title;

	/** 본문 HTML (SCONTENTS, CLOB) — 사용자가 보는 메인 본문 */
	private String contents;

	/** 개정 사유 (SREASON, CLOB) */
	private String reason;

	/** 개정 유형 (SGAEJUNG_TYPE — 신규/개정/삭제 등) */
	private String gaejungType;

	/** 표시 여부 (SDISP_YN) */
	private String dispYn = "Y";

	/** 적용 시작일 (SSTART_DT) */
	private String startDate;

	/** 등록일 (SINS_DT) */
	private String insDt;

	/** 검색 텍스트 (SSEARCH_TEXT, CLOB) */
	private String searchText;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	// ── 화면 검색/페이징 ──
	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;

	private String lastUpdusrId;
}
