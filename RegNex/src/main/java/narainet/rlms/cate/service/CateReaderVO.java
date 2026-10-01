/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/CateReaderVO.java
 *
 * 분류별 열람제한 VO (TB_CATE_READER).
 *  - 분류당 열람대상 N명(부서 N + 개인 N 혼합). 미지정 분류 = 전체 공개.
 *  - 면제역할(ROLE_ADMIN/EDITOR/APPROVER)은 이 매핑과 무관하게 전체 열람(가드 호출측에서 선통과).
 *  - 상속: 상위분류 제한이 하위로(INHERIT_YN='Y'). 조상 판정은 TB_CATE.IREF CONNECT BY.
 */
package narainet.rlms.cate.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 분류별 열람제한 VO (TB_CATE_READER)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.07   RLMS 전환팀   최초 생성 (TB_CATE_OWNER 패턴 미러 — read 축 신설)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class CateReaderVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── DB 매핑 (TB_CATE_READER / TB_GUBUN_READER) ────────────────
	/** 분류 번호 (ICATE_NO, TB_CATE.ICATE_NO) — 구분 단위 행은 null */
	private Long cateNo;

	/** 구분 (SGUBUN_ID, TB_GUBUN_READER 전용 — 예: FT_GUBUN_1) — 분류 단위 행은 null */
	private String gubunId;

	/** 열람대상 유형 (READER_TY) — 'DEPT'(부서) | 'USER'(개인) */
	private String readerTy;

	/** 열람대상 (READER_ID) — DEPT=ORGNZT_ID / USER=ESNTL_ID */
	private String readerId;

	/** 하위분류 상속 여부 (INHERIT_YN) — Y/N */
	private String inheritYn = "Y";

	/** 등록일시 (SINS_DT) */
	private String insDt;

	/** 등록자 (SINS_ID) */
	private String insId;

	// ── 조회 부가 (이름 해석) ─────────────────────────────────────
	/** 열람대상 표시명 — 부서명 또는 사용자명 (조회 시 조인) */
	private String readerNm;

	/** 분류명 (조회 시 조인) */
	private String cateNm;
}
