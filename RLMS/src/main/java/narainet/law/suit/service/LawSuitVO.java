/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/LawSuitVO.java
 */
package narainet.law.suit.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/** 사건 마스터 (LAW_SUIT ← tbetia11, 심급 단위 1행 — §4.2) + 목록 표시·검색 조건 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawSuitVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_SUIT_ID) */
	private Long suitId;
	/** 사건군 최초 심급 사건 ID (§4.5 — 최초심=자기 ID) */
	private Long firstSuitId;
	/** 소송구분 (LAW_CASE_KIND) */
	private String caseKindCd;
	/** 심급 (LAW_INSTANCE) */
	private String instanceCd;
	/** 법원 (LAW_COURT FK, 직접입력 시 NULL) */
	private Long courtId;
	private String courtNm;
	/** 사건번호 3분해 + 표시 결합 */
	private String caseYear;
	private String caseSignCd;
	private String caseSerial;
	private String caseNo;
	/** 사건명 (코드 S999=직접입력) */
	private String caseNmCd;
	private String caseNm;
	/** 사건유형 (LAW_CIVIL_CASE) */
	private String civilCaseCd;
	/** 제·피소 (LAW_ITPT_KIND) */
	private String itptKindCd;
	/** 소가 */
	private Long suitAmt;
	private String officeReceiptDt;
	/** 소제기일 */
	private String frDt;
	/** 최종 선고일 */
	private String stcDt;
	/** 확정일 */
	private String dcsnDt;
	/** 소송결과 (LAW_RESULT) + 직접입력 명칭 */
	private String rsltKindCd;
	private String rsltKindNm;
	private Long winAmt;
	private Long loseAmt;
	/** 패소원인 (LAW_LOSS_CAUSE) */
	private String lossCauseCd;
	/** 병합사건 텍스트 */
	private String mergeCase;
	private String costFixDt;
	private Long costFixAmt;
	private Long costRcvAmt;
	private Long retainerAmt;
	private Long successAmt;
	private String specialDesc;
	private String delYn;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;

	// ── 목록·상세 표시 (코드명·자식 요약 — 집합 1회 조인 산출) ──
	private String caseKindNm;
	private String instanceNm;
	private String itptKindNm;
	private String civilCaseNm;
	private String lossCauseNm;
	/** 결과 표시 라벨 (코드명, 직접입력 시 RSLT_KIND_NM) */
	private String rsltDispNm;
	/** 원고 대표 + 인원수 */
	private String plaintiffNm;
	private Integer plaintiffCnt;
	/** 피고 대표 + 인원수 */
	private String defendantNm;
	private Integer defendantCnt;
	/** 사건토지 첫 행 요약 (소재지 지번, 외 N) */
	private String landSummary;
	private Integer landCnt;
	/** 최신 진행상황 내용 */
	private String progSummary;

	// ── 검색 조건 (§7.1 목록: 확정일 기간/제·피소/소송구분/소송결과/사건번호) ──
	/** 확정일 기간 (yyyy-MM-dd — 서버에서 YYYYMMDD 변환) */
	private String searchFixFrom;
	private String searchFixTo;
	private String searchItpt;
	private String searchCaseKind;
	private String searchRslt;
	private String searchCaseYear;
	private String searchCaseSign;
	private String searchCaseSerial;
	/** 사건 검색 모달 키워드 (사건번호·사건명) */
	private String searchKeyword;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
