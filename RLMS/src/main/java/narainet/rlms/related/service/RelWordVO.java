/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelWordVO.java
 *
 * 관련자료 — WORD 액션 자식 (TB_REL_WORD).
 *
 *  Word/HWP/PDF 등 문서. 레거시 는 별도 DCMS 데몬으로 HTML 변환하여 SHTML/SSEARCH_TEXT/
 *  SHTML_PATH/SSEARCH_TEXT_PATH 를 사후 채움 (status 0→1→2→3).
 *  RLMS 1차 = 변환 인프라 미도입 → 원본만 보관, 변환 컬럼은 NULL/디폴트.
 *  2차에서 Apache POI / hwplib + Tika 자체 변환 도입 검토.
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
public class RelWordVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRWORD_NO) */
	private Long relWordNo;

	/** TB_REL_VRSN FK (IRVRSN_NO) */
	private Long relVrsnNo;

	/** TB_ATTACH FK (IATT_NO) */
	private Long attNo;

	/** 제목 (STITLE) */
	private String title;

	/** 변환 HTML 본문 (SHTML — CLOB). RLMS 1차 = NULL */
	private String html;

	/** 문서 유형 라벨 (STYPE). 1차 = NULL */
	private String type;

	/** 삭제 플래그 (SDEL_YN) */
	private String delYn;

	/** 검색 텍스트 (SSEARCH_TEXT — CLOB). 1차 = NULL */
	private String searchText;

	/** 등록일 (SINS_DT) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/** 변환 HTML 디스크 경로 (SHTML_PATH). 1차 = NULL */
	private String htmlPath;

	/** 검색 텍스트 디스크 경로 (SSEARCH_TEXT_PATH). 1차 = NULL */
	private String searchTextPath;

	/** SHTML 이 디스크 파일인지 (SCLOB_FILE_YN). 1차 = 'N' 디폴트 */
	private String clobFileYn;

	/** 추가 경로 (SPATH). 1차 = NULL */
	private String path;

	// ── 조회 부가 (조인) ──────────────────────────────────────────
	private String attName;
	private String attExt;
	private Long   attSize;
}
