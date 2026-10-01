/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelFileVO.java
 *
 * 관련자료 — FILE 액션 자식 (TB_REL_FILE).
 *
 *  SVIEW_YN: 미리보기 변환 가능 여부 (DOC/DOCX/HWP/XLS/XLSX/PPT/PPTX/PDF → 'Y')
 *  SVIEW_CMPLT_YN: 변환 완료 여부 — 'N' 디폴트 (RLMS 1차 = 변환 인프라 미도입)
 *  IATT_NO: TB_ATTACH FK (실제 파일 디스크 위치는 TB_ATTACH 가 관리)
 *  SCATE: 액션 내 자유 분류 — RLMS 1차 = 빈 문자열 디폴트
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
public class RelFileVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRFILE_NO) */
	private Long relFileNo;

	/** TB_REL_VRSN FK (IRVRSN_NO) */
	private Long relVrsnNo;

	/** TB_ATTACH FK (IATT_NO) */
	private Long attNo;

	/** 액션 내 자유 분류 (SCATE — 레거시 의 "일반/전문/해석/설명") */
	private String cate;

	/** 제목 (STITLE) */
	private String title;

	/** 삭제 플래그 (SDEL_YN — 'N'/'Y' 소프트삭제) */
	private String delYn;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/** 미리보기 가능 여부 (SVIEW_YN — 확장자 기반 'Y'/'N') */
	private String viewYn;

	/** 미리보기 변환 완료 (SVIEW_CMPLT_YN — RLMS 1차는 항상 'N') */
	private String viewCmpltYn;

	// ── 조회 부가 (조인) ──────────────────────────────────────────
	/** TB_ATTACH 의 원본 파일명 — 다운로드 UI 표시용 */
	private String attName;
	/** TB_ATTACH 의 확장자 — 아이콘 표시용 */
	private String attExt;
	/** TB_ATTACH 의 파일 크기 — 메타 표시용 */
	private Long   attSize;
}
