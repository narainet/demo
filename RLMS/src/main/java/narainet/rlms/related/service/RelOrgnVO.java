/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelOrgnVO.java
 *
 * 관련자료 — ORGN 액션 자식 (TB_REL_ORGN).
 *
 *  보존용 정본(원본) 버킷. FILE 과 달리:
 *   - 분류(SCATE) 없음, 온라인 뷰어 플래그(SVIEW_YN) 없음, 변환 없음.
 *   - ZIP 일괄다운로드에서 제외 (downloadZip 은 FILE/WORD/IMG 만 수집).
 *   - 노출은 카테고리의 SORGNDOWN_YN(원본 다운로드 허용) 정책으로 별도 통제.
 *  IATT_NO: TB_ATTACH FK (실제 파일 디스크 위치는 TB_ATTACH 가 관리).
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
public class RelOrgnVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRORGN_NO) */
	private Long relOrgnNo;

	/** TB_REL_VRSN FK (IRVRSN_NO) */
	private Long relVrsnNo;

	/** TB_ATTACH FK (IATT_NO) */
	private Long attNo;

	/** 제목 (STITLE) */
	private String title;

	/** 삭제 플래그 (SDEL_YN — 'N'/'Y' 소프트삭제) */
	private String delYn;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	// ── 조회 부가 (조인) ──────────────────────────────────────────
	/** TB_ATTACH 의 원본 파일명 — 다운로드 UI 표시용 */
	private String attName;
	/** TB_ATTACH 의 확장자 — 아이콘 표시용 */
	private String attExt;
	/** TB_ATTACH 의 파일 크기 — 메타 표시용 */
	private Long   attSize;
}
