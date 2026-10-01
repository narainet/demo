/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/CateVO.java
 *
 * 법령 분류(TB_CATE) VO.
 * 자기참조 트리 + 비정규화 경로(IREF_LV_1~10).
 *
 * 트리거 효과 (DB 레벨):
 *   - TRG_DEL_CATE (BEFORE DELETE):
 *       DELETE FROM TB_CATE_POL_ITM WHERE ICATE_NO = :OLD.ICATE_NO;
 *       DELETE FROM TB_PROM         WHERE ICATE_NO = :OLD.ICATE_NO;   ★ 법령까지 cascade!
 *     → 운영 안전을 위해 RLMS Service.deleteCate() 에서 prom/하위카테 존재 시 차단.
 */
package narainet.rlms.cate.service;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 법령 분류 VO (TB_CATE)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성 (레거시 Category → RLMS 이관)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class CateVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── DB 매핑 (TB_CATE) ─────────────────────────────────────────
	/** 분류 번호 (ICATE_NO, PK, COMTECOPSEQ.CATE_ID 채번) */
	private Long cateNo;

	/** 구분 ID (SGUBUN_ID) */
	private String gubunId;

	/** 분류명 (SNAME) */
	private String cateNm;

	/** 전체경로명 (SFULL_NAME) */
	private String fullNm;

	/** 계층 깊이 (ILEVEL) — 루트=0 */
	private Integer level;

	/** 부모 분류 (IREF) — 루트는 0 */
	private Long ref;

	// 비정규화 조상 경로 (IREF_LV_1 ~ IREF_LV_10)
	private Long refLv1;
	private Long refLv2;
	private Long refLv3;
	private Long refLv4;
	private Long refLv5;
	private Long refLv6;
	private Long refLv7;
	private Long refLv8;
	private Long refLv9;
	private Long refLv10;

	/** 표시 여부 (SDISP_YN) */
	private String dispYn = "Y";

	/** 삭제 여부 (SDEL_YN) — 소프트 삭제 */
	private String delYn = "N";

	/** 정렬순서 (ISEQ) */
	private Integer seq;

	/** 등록일 (SINS_DT) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	// ── 조회 부가 ─────────────────────────────────────────────────
	/** 트리 재구성용 자식 목록 */
	private List<CateVO> children = new ArrayList<>();

	/** 이 분류에 속한 법령 건수 (TB_PROM 카운트) — 삭제 차단 판정 */
	private Integer promCnt;

	/** 하위 분류 건수 — 삭제 차단 판정 */
	private Integer childCnt;

	/** 트리 들여쓰기 표시 (LPAD + LEVEL 결과) */
	private String indentPath;

	/** Oracle CONNECT BY 결과의 LEVEL */
	private Integer treeLevel;

	// ── 검색 ─────────────────────────────────────────────────────
	private String searchKeyword;
	private String lastUpdusrId;
}
