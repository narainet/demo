/*
 * 물리적 저장 경로: /src/main/java/narainet/law/receipt/service/LawReceiptVO.java
 *
 * 법원서류접수 — LAW_COURT_RECEIPT ← tbetia44. 접수+관련부서 지정·표시(알림 발송 비범위). §7.11
 */
package narainet.law.receipt.service;

import java.io.Serializable;
import java.util.List;

import egovframework.com.cmm.service.FileVO;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawReceiptVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_RECEIPT_ID) */
	private Long receiptId;
	/** 제목 */
	private String receiptTitl;
	/** 등록부서 ID (등록자 소속 자동) */
	private String orgnztId;
	private String orgnztNm;
	/** 관련부서 1·2 */
	private String relOrgnztId1;
	private String relOrgnztNm1;
	private String relOrgnztId2;
	private String relOrgnztNm2;
	/** 관련자료 첨부파일 ID (표준 COMTNFILE) */
	private String atchFileId;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;

	/** 첨부 파일 목록 (COMTNFILEDETAIL) */
	private List<FileVO> files;

	// ── 검색 ──
	/** 등록일자 기간 시작 (YYYYMMDD) */
	private String searchFrom;
	/** 등록일자 기간 종료 (YYYYMMDD) */
	private String searchTo;
	/** 제목 키워드 */
	private String searchKeyword;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
