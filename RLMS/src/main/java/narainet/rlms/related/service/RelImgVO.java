/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelImgVO.java
 *
 * 관련자료 — IMAGE 액션 자식 (TB_REL_IMG).
 *
 *  이미지 파일 업로드. ORGN 과 거의 동일 구조 (분류·뷰어 없음). 우측 패널·상세에서 썸네일 미리보기.
 *  IATT_NO: TB_ATTACH FK.
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
public class RelImgVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRIMG_NO) */
	private Long relImgNo;

	/** TB_REL_VRSN FK (IRVRSN_NO) */
	private Long relVrsnNo;

	/** TB_ATTACH FK (IATT_NO) */
	private Long attNo;

	/** 제목 (STITLE) */
	private String title;

	/** 삭제 플래그 (SDEL_YN — 'N'/'Y') */
	private String delYn;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	// ── 조회 부가 (조인) ──────────────────────────────────────────
	private String attName;
	private String attExt;
	private Long   attSize;
}
