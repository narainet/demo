/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelHtmlVO.java
 *
 * 관련자료 — HTML 액션 자식 (TB_REL_HTML).
 *
 *  직접 작성한 HTML 표/본문. 파일 업로드·첨부 없음.
 *   - SHTML 은 CLOB (표 마크업 그대로 보존).
 *   - 분류(SCATE)·뷰어 컬럼 없음. ZIP 일괄다운로드 제외.
 *  레거시 RelatedController.htmlUpdateDo (RelatedController.java:1344-1480) 대응.
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
public class RelHtmlVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRHTML_NO) */
	private Long relHtmlNo;

	/** TB_REL_VRSN FK (IRVRSN_NO) */
	private Long relVrsnNo;

	/** 제목 (STITLE) */
	private String title;

	/** HTML 본문 (SHTML — CLOB) */
	private String html;

	/** 삭제 플래그 (SDEL_YN — 'N'/'Y' 소프트삭제) */
	private String delYn;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;
}
