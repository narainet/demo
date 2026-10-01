/*
 * 물리적 저장 경로: /src/main/java/narainet/law/assign/service/LawSuitLawyerVO.java
 *
 * 선임 (LAW_SUIT_LAWYER ← tbetia52) — 사건×변호사, 계약서 첨부(표준 COMTNFILE), 만족도 평가 대상 단위. §7.6
 */
package narainet.law.assign.service;

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
public class LawSuitLawyerVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_ASSIGN_ID) */
	private Long assignId;
	/** 사건 ID (LAW_SUIT FK) */
	private Long suitId;
	/** 변호사 ID (LAW_LAWYER FK) */
	private Long lawyerId;
	/** 선임일 (YYYYMMDD, 화면은 yyyy-MM-dd) */
	private String assignDt;
	/** 계약서 첨부파일 ID (표준 COMTNFILE) */
	private String atchFileId;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;

	// ── 목록 표시용 조인 컬럼 ──
	private String lawFirm;
	private String lawyerNm;
	private String caseNo;
	private String caseNm;
	/** 소송결과 표시명 (코드명 or 직접입력) */
	private String rsltDispNm;
	/** 만족도 집계 (이 선임 단위) */
	private Double satisAvg;
	private Integer satisCnt;
	/** 계약서 파일 목록 (COMTNFILEDETAIL) */
	private List<FileVO> files;

	// ── 검색 ──
	private String searchKeyword;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
