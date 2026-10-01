/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/gaejung/service/GaejungVO.java
 *
 * 개정 종류(TB_GAEJUNG) VO.
 * 전 시스템 공용 마스터 (SSYS_ID 없음).
 */
package narainet.rlms.gaejung.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class GaejungVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IGAEJUNG_NO, COMTECOPSEQ.GAEJUNG_ID) */
	private Long gaejungNo;

	/** 개정 종류명 (SNAME) */
	private String gaejungNm;

	/** 정렬순서 (ISEQ) */
	private Integer seq;

	/**
	 * 본문 비교(diff) 여부 (SDIFF_YN, Y/N)
	 * - 'Y': prom 비교 화면이 이전 개정본의 PROV_VRSN row 와 비교
	 * - 'N': '제정' 같은 신규 입력 시점 — 비교할 이전이 없음
	 */
	private String diffYn = "Y";

	/** 삭제 여부 (SDEL_YN) */
	private String delYn = "N";

	/** 등록일 (SINS_DT) */
	private String insDt;

	// 검색/페이징
	private String searchKeyword;
	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;

	private String lastUpdusrId;
}
