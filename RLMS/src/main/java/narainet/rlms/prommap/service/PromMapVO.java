/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prommap/service/PromMapVO.java
 *
 * 기능별분류(규정맵, TB_PROM_MAP) VO. 레거시 PromulgationMap 이관.
 *
 *  1차 분류(TB_CATE)와 별개로, 규정을 임의의 "기능별 분류 트리"에 매핑한다.
 *   - 폴더 노드 : SPROM_YN='N', IPROM_NO=0  (기능별 분류 카테고리)
 *   - 규정 leaf : SPROM_YN='Y', IPROM_NO=대상 법령  (전문뷰어로 점프)
 *  트리 구조 = IREF(부모 IPMAP_NO) 자기참조. 루트는 IREF=0.
 */
package narainet.rlms.prommap.service;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 기능별분류(규정맵) VO (TB_PROM_MAP)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.06.15   RLMS 전환팀   최초 생성 (레거시 PromulgationMap → RLMS 이관)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class PromMapVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── DB 매핑 (TB_PROM_MAP, 11 컬럼) ─────────────────────────────
	/** 규정맵 번호 (IPMAP_NO, PK, COMTECOPSEQ.PMAP_ID 채번) */
	private Long pmapNo;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/** 노드명 (SNAME) — 폴더명 또는 규정 제목 */
	private String name;

	/** 전체경로명 (SFULL_NAME) */
	private String fullName;

	/** 규정 여부 (SPROM_YN) — 'Y'=규정 leaf, 'N'=폴더 */
	private String promYn = "N";

	/** 계층 깊이 (ILEVEL) — 루트=0 */
	private Integer level = 0;

	/** 부모 노드 (IREF, 부모 IPMAP_NO) — 루트=0 */
	private Long ref = 0L;

	/** 표시 여부 (SDISP_YN) */
	private String dispYn = "Y";

	/** 정렬순서 (ISEQ) */
	private Integer seq = 0;

	/** 등록일시 (SINS_DT) */
	private String insDt;

	/** 참조 법령 (IPROM_NO) — SPROM_YN='Y' 일 때만 의미. 폴더는 0 */
	private Long promNo = 0L;

	// ── 조회 부가 (front 규정목록 조인 결과 — getPromulgationList) ──
	/** 규정 제목 (TB_PROM.STITLE) */
	private String promTitle;

	/** 공포일자 (TB_PROM.SPROM_DT) */
	private String promDate;

	/** 시행예정 여부 'Y'/'N' — 현행본 시행일(SSTART_DT)이 미래(A안 뱃지). 트리·front 목록 조회 전용 */
	private String pendingYn;

	/** 분류 풀패스 (TB_CATE.SFULL_NAME) */
	private String cateFullName;

	/** 트리 재구성용 자식 목록 */
	private List<PromMapVO> children = new ArrayList<>();
}
