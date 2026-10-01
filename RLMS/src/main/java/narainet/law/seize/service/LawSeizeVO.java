/*
 * 물리적 저장 경로: /src/main/java/narainet/law/seize/service/LawSeizeVO.java
 *
 * 압류관리(가압류·가처분) — LAW_SEIZE ← tc_seize. 게시판형, 첨부 5개·10MB 제한(§7.10).
 */
package narainet.law.seize.service;

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
public class LawSeizeVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_SEIZE_ID) */
	private Long seizeId;
	/** 채권자 */
	private String creditor;
	/** 채무자 */
	private String debtor;
	/** 제3채무자 */
	private String thirdDebtor;
	/** 담당부서 ID (COMTNORGNZTINFO) */
	private String orgnztId;
	private String orgnztNm;
	/** 관할법원명 */
	private String courtNm;
	/** 사건번호 */
	private String caseNo;
	/** 메모 (CLOB) */
	private String memo;
	/** 조회수 (상세 열람 시 증가) */
	private Integer readCnt;
	/** 첨부파일 ID (표준 COMTNFILE) */
	private String atchFileId;

	private String regUserId;
	private String regUserNm;
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
	/** 검색축 (ORGNZT/CREDITOR/DEBTOR/THIRD_DEBTOR/COURT/CASE_NO) */
	private String searchAxis;
	/** 검색 키워드 */
	private String searchKeyword;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
