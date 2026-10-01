/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/favor/service/FavorVO.java
 *
 * 사용자 즐겨찾기(TB_FAVOR) VO.
 *  - ILAW_ID + SITEM 으로 prom(법령) 의 조항 단위를 참조
 *  - SUSER_ID 로 개인 격리 (다른 사용자 즐겨찾기 보이지 않음)
 */
package narainet.rlms.favor.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class FavorVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IFAVOR_NO, COMTECOPSEQ.FAVOR_ID) */
	private Long favorNo;

	/** 분류 (SGUBUN) */
	private String gubun;

	/** 법령 ID (ILAW_ID, TB_PROM 의 논리 lawId) */
	private Long lawId;

	/** 조항 식별자 (SITEM, 예: "제3조 제1항") — 본문 단위 jump 키 */
	private String item;

	/** 메모/설명 (SDESC, 짧은 텍스트) */
	private String description;

	/** 사용자 ID (SUSER_ID, EgovUserDetailsHelper.uniqId) */
	private String userId;

	/** 사용자명 (SUSER_NAME) */
	private String userName;

	/** 등록일 (SINS_DT) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	// ── 조회 부가 (현행 prom 조인 — 식별/삭제표시용, 레거시 FavoriteView 파리티) ──
	/** 현행 회차 번호 (TB_PROM.IPROM_NO, SEXISTING_YN='Y') — null 이면 현행 법령 없음 */
	private Long promNo;
	/** 현행 법령 제목 (TB_PROM.STITLE) — 목록 식별용 */
	private String promTitle;
	/** 현행본 시행예정 여부 'Y'/'N' — 시행일(SSTART_DT) 미래(A안 뱃지). 목록 조회 전용 */
	private String pendingYn;
	/**
	 * 참조 조항 삭제 여부 ('Y'/'N'). 'Y' = 즐겨찾기한 조항이 현행 회차에 더 이상 없음
	 * (개정으로 삭제/폐지). 레거시 FavoriteService.search 의 provisionDeleted 이식.
	 */
	private String provDeleted;

	// ── 열람제한 게이트 (PromReadGuard 주입) — 즐겨찾기 목록에서 열람제한 규정 은닉 ──
	/** 게이트 적용 여부 — 면제역할(ADMIN/EDITOR/APPROVER)이면 false(미적용). */
	private boolean applyReadGate;
	/** 게이트 매칭용 현재 사용자 ESNTL_ID (TB_CATE_READER/TB_GUBUN_READER READER_TY='USER'). */
	private String readerEsntlId;
	/** 게이트 매칭용 현재 사용자 ORGNZT_ID (READER_TY='DEPT'). */
	private String readerOrgnztId;

	// 검색/페이징
	private String searchKeyword;
	/** 분류(SGUBUN) 필터 — 빈값/null 이면 전체. 값: PROVISION(조문)/FULLTEXT(전문)/PROM(규정) */
	private String searchGubun;
	private int pageIndex = 1;
	private int pageUnit = 20;
	private int pageSize = 20;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 20;
}
