/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/sym/ccm/cca/service/CmmnCodeVO.java
 *
 * 공통코드 그룹(COMTCCMMNCODE) VO.
 * 표준 ccm 3분할 화면(분류/공통/상세, ccc·cca·cde)을 트리형 통합 관리 화면
 * (/sym/ccm/cca/selectCodeTree.do)으로 대체한 구성에서 사용한다.
 * 분류코드(CL_CODE)는 다루지 않는다 — 신규 행은 NULL.
 */
package egovframework.com.sym.ccm.cca.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 공통코드 그룹 VO (COMTCCMMNCODE)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.08   RLMS 전환팀   최초 생성 (ccm cca/cde 통합 대체)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class CmmnCodeVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 코드그룹 ID (CODE_ID, PK) */
	private String codeId;

	/** 코드그룹명 (CODE_ID_NM) */
	private String codeIdNm;

	/** 설명 (CODE_ID_DC) */
	private String codeIdDc;

	/** 사용 여부 (USE_AT) — Y/N */
	private String useAt;

	// ── 조회 부가 ─────────────────────────────────────────────
	/** 하위 상세코드 수 (트리 라벨/삭제 안내용) */
	private int detailCnt;

	// ── 감사 ─────────────────────────────────────────────────
	/** 등록/수정자 로그인 ID (FRST_REGISTER_ID / LAST_UPDUSR_ID) */
	private String userId;
}
