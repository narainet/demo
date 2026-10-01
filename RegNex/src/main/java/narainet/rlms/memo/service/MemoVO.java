/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/memo/service/MemoVO.java
 *
 * 사용자 인앵커 메모(TB_MEMO) VO.
 *  - favor 와 거의 동일하나 SBUSEO_ID(작성 시점 부서) 추가 보유
 *  - ILAW_ID + SITEM 으로 prom 본문 조항 참조
 *  - 같은 조항(SITEM)에 대해 여러 메모 가능 (즐겨찾기는 1건/조항 제한, 메모는 무제한)
 */
package narainet.rlms.memo.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class MemoVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IMEMO_NO, COMTECOPSEQ.MEMO_ID) */
	private Long memoNo;

	/** 분류 (SGUBUN) */
	private String gubun;

	/** 법령 ID (ILAW_ID) */
	private Long lawId;

	/** 조항 식별자 (SITEM) */
	private String item;

	/** 메모 내용 (SDESC, VARCHAR2 길이 충분) */
	private String contents;

	/** 사용자 ID (SUSER_ID) */
	private String userId;

	/** 사용자명 (SUSER_NAME) */
	private String userName;

	/** 작성 시점 부서 ID (SBUSEO_ID) — favor 와의 차이점. 부서 공유 정책에 따라 활용 가능. */
	private String buseoId;

	/** 등록일 (SINS_DT) */
	private String insDt;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	// 검색/페이징
	private String searchKeyword;
	/** 분류(SGUBUN) 필터 — 빈값/null 이면 전체. 값: USER(사용자)/BUSEO(부서)/PROM(규정) */
	private String searchGubun;
	private int pageIndex = 1;
	private int pageUnit = 20;
	private int pageSize = 20;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 20;
}
