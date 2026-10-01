/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelVrsnVO.java
 *
 * 관련자료 버전(TB_REL_VRSN) — 우측 패널 "관련자료" 의 허브 행.
 *
 *  한 회차(IPROM_NO) 또는 한 조항(SFLAG='PROVISION', SFULL_ITEM='...') 에 붙은
 *  관련자료 1건 = TB_REL_VRSN 1 row. STABLE 컬럼이 실제 리소스가 저장된 테이블 이름:
 *    TB_REL_FILE    — 파일 일반등록 (Word/PDF 원본 + 변환본)
 *    TB_REL_WORD    — Word 파일 (HWP/DOC → HTML 변환 + 원본)
 *    TB_REL_ORGN    — 원본 첨부 (변환 없이 원본 그대로)
 *    TB_REL_HTML    — HTML 표/본문 (직접 작성)
 *    TB_REL_IMG     — 이미지 첨부
 *    TB_REL_LNK     — 외부 URL 연계
 *    TB_REL_DMN_LNK — 도메인/규정 연계
 *
 *  IRVCATE_NO → TB_REL_VRSN_CATE 의 카테고리 그룹화 (본문/붙임/양식 + 동적).
 *
 * 2026-05-14 — narainet.rlms.relvrsn → narainet.rlms.related 패키지 통합 이동.
 *  마스터(TB_REL_VRSN) + 7 상세 + 카테고리(TB_REL_VRSN_CATE) 가 단일 도메인.
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
public class RelVrsnVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IRVRSN_NO) */
	private Long relVrsnNo;

	/** 회차 번호 (IPROM_NO, TB_PROM FK) */
	private Long promNo;

	/** 콘텐츠 ID (ICTNS_ID) — 회차 간 누적 추적 키 */
	private Long ctnsId;

	/** 버전여부 (SVRSN_YN — 회차별 분기 추적, Y/N) */
	private String vrsnYn;

	/** 실제 리소스 테이블 (STABLE — TB_REL_FILE/TB_REL_HTML/TB_REL_LNK/...) */
	private String stable;

	/** 부착 컨텍스트 (SFLAG — 'PROMULGATION'=법령 전체 / 'PROVISION'=조항 / 'DOCUMENT'=별표) */
	private String flag;

	/** 조항 식별자 (SFULL_ITEM — SFLAG='PROVISION'/'DOCUMENT' 일 때, 60자 코드) */
	private String fullItem;

	/** 제목 (STITLE — 우측 패널 라벨) */
	private String title;

	/** 표시 순서 (ISEQ) */
	private Integer seq;

	/** 외부 URL (SURL — TB_REL_LNK 용. 다른 테이블은 공백) */
	private String url;

	/** 카테고리 FK (IRVCATE_NO → TB_REL_VRSN_CATE) */
	private Long cateNo;

	/** 카테고리 이름 캐시 (IRVCATE_NM — 디폴트 '미선택') */
	private String cateName;

	/** 카테고리 순서 (IRVCATE_ODR — 디폴트 0) */
	private Integer cateOrder;

	/** 등록일 (SINS_DT — YYYYMMDDHHMMSS) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	// ── 조회 부가 (조인 결과) ─────────────────────────────────────
	/** TB_REL_VRSN_CATE.STITLE (조인) — cateName 보다 우선. 카테고리 그룹 헤더용 */
	private String cateTitle;

	/** TB_REL_VRSN_CATE.ISEQ (조인) — 카테고리 그룹 정렬용 */
	private Integer cateSeq;

	/** TB_REL_VRSN_CATE.SORGNDOWN_YN — 원본 다운로드 허용 여부 (Y/N) */
	private String orgnDownYn;
}
