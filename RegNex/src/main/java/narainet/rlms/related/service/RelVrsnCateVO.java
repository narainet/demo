/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelVrsnCateVO.java
 *
 * 관련자료 카테고리 (TB_REL_VRSN_CATE) — 우측 패널 자료 그룹 헤더.
 *
 *  회차(STEMP=IPROM_NO) + 법령(ILAW_ID) 페어 단위로 정의.
 *  운영 패턴(레거시, 2026-05-14 분석): 새 회차 등록 시 시드 3종 (본문/붙임/양식) 자동 생성.
 *  운영팀은 추가 카테고리(별표별지서식, 첨부, 부록 등) 를 위 모달에서 직접 등록.
 *
 *  SHIDE_DT="0" = 활성 / 날짜(YYYYMMDD) = 그날부터 숨김.
 *  SORGNDOWN_YN — 사용자 화면 원본 다운로드 허용 (기본값: 본문=Y, 붙임=N, 양식=Y).
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
public class RelVrsnCateVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRVCATE_NO) */
	private Long cateNo;

	/** 카테고리 이름 (STITLE) */
	private String title;

	/** 표시 순서 (ISEQ) */
	private Integer seq;

	/** 숨김 종료일 (SHIDE_DT) — "0" = 활성 / "YYYYMMDD" = 해당일부터 숨김 */
	private String hideDt;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 법령 FK (ILAW_ID) */
	private Long lawId;

	/** 회차 매핑 (STEMP) — 정식 promNo 값. 임시 시 별도 임시 키 */
	private String tempPromNo;

	/** 원본 다운로드 허용 (SORGNDOWN_YN — Y/N) */
	private String orgnDownYn;

	// ── 조회 부가 ─────────────────────────────────────────────────
	/** 이 카테고리에 매달린 자료 건수 (집계용) */
	private Integer itemCount;
}
