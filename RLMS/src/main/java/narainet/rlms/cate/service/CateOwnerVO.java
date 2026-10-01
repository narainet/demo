/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/CateOwnerVO.java
 *
 * 분류별 작성자(소유) VO (TB_CATE_OWNER).
 *  - 분류당 작성자 N명(부서 N + 개인 N 혼합).
 *  - 관리자(ROLE_ADMIN)는 이 매핑과 무관하게 전체 수정(가드 호출측에서 선통과).
 *  - 상속: 상위분류 소유가 하위로(INHERIT_YN='Y'). 조상 판정은 TB_CATE.IREF CONNECT BY.
 */
package narainet.rlms.cate.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 분류별 작성자(소유) VO (TB_CATE_OWNER)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.06.09   RLMS 전환팀   최초 생성 (분류정책 단순화 — POL/ITM/LNK → 단일 매핑)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class CateOwnerVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── DB 매핑 (TB_CATE_OWNER) ───────────────────────────────────
	/** 분류 번호 (ICATE_NO, TB_CATE.ICATE_NO) */
	private Long cateNo;

	/** 소유유형 (OWNER_TY) — 'DEPT'(부서) | 'USER'(개인) */
	private String ownerTy;

	/** 소유대상 (OWNER_ID) — DEPT=ORGNZT_ID / USER=ESNTL_ID */
	private String ownerId;

	/** 하위분류 상속 여부 (INHERIT_YN) — Y/N */
	private String inheritYn = "Y";

	/** 등록일시 (SINS_DT) */
	private String insDt;

	/** 등록자 (SINS_ID) */
	private String insId;

	// ── 조회 부가 (이름 해석) ─────────────────────────────────────
	/** 소유대상 표시명 — 부서명 또는 사용자명 (조회 시 조인) */
	private String ownerNm;

	/** 분류명 (조회 시 조인) */
	private String cateNm;
}
