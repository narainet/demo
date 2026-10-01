/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelLnkVO.java
 *
 * 관련자료 — LINK 액션 자식 (TB_REL_LNK).
 *
 *  외부 URL 연계. 회차 단위 마스터(TB_REL_VRSN) 1건 아래 여러 링크 row.
 *  레거시 의 다중 입력 DELETE-then-INSERT 패턴 (urlUpdateDo).
 *
 *  스키마: 모든 컬럼 NOT NULL → 빈값 처리 디폴트 필요.
 *   - SCATE: 자유 분류 라벨 (레거시 도 폼에 분류 입력 칸 있음) — 비우면 "URL" 디폴트
 *   - IREF_NO/SREF_TABLE: 통합단말검색 보조 모달용 외부 시스템 참조 — RLMS 1차는 0/공백 디폴트
 */
package narainet.rlms.related.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class RelLnkVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRLINK_NO) */
	private Long relLnkNo;

	/** TB_REL_VRSN FK (IRVRSN_NO) */
	private Long relVrsnNo;

	/** 자유 분류 라벨 (SCATE) — 비우면 "URL" */
	private String cate;

	/** 제목 (STITLE) */
	private String title;

	/** URL (SURL) */
	private String url;

	/** 외부 시스템 참조 PK (IREF_NO) — RLMS 1차 디폴트 0 */
	private Long refNo;

	/** 외부 시스템 참조 테이블명 (SREF_TABLE) — RLMS 1차 디폴트 "" */
	private String refTable;

	/** 표시 순서 (ISEQ — 1부터) */
	private Integer seq;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;
}
