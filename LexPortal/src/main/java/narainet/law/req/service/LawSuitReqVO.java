/*
 * 물리적 저장 경로: /src/main/java/narainet/law/req/service/LawSuitReqVO.java
 *
 * 소송의뢰 (LAW_SUIT_REQ ← tbetia40) — 사용자(front) 신청, 법무팀(mgr) 승인/반려, 승인 후 소송등록 연계.
 *   §7.8·§7.9·§4.3. 첨부=표준 COMTNFILE(기타자료, 다중). 상태=LAW_REQ_STATUS(S001 신청/S002 승인/S003 반려).
 */
package narainet.law.req.service;

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
public class LawSuitReqVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_REQ_ID) */
	private Long reqId;
	/** 사건명(의뢰 제목) */
	private String reqTitl;
	/** 사실관계 */
	private String reqCn;
	/** 의뢰부서 ID (COMTNORGNZTINFO — 신청자 소속 자동) */
	private String reqOrgnztId;
	private String reqOrgnztNm;
	/** 의뢰담당자 */
	private String reqUserId;
	private String reqUserNm;
	/** 의뢰일자 (YYYYMMDD) */
	private String reqDt;
	/** 의뢰상태 (LAW_REQ_STATUS — S001 신청/S002 승인/S003 반려) */
	private String statusCd;
	private String statusNm;
	/** 승인(반려)자·일시 */
	private String aprvUserId;
	private String aprvUserNm;
	private String aprvDt;
	/** 반려 사유 */
	private String returnRsn;
	/** 승인 후 연계 등록된 사건 ID (소송등록 시 역기입) */
	private Long suitId;
	/** 연계 사건 표시(조인) */
	private String caseNo;
	/** 기타자료 첨부파일 ID (표준 COMTNFILE, 다중) */
	private String atchFileId;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;

	// ── 상세/저장용 자식 목록 ──
	/** 사건 경과 내역 행 */
	private List<LawSuitReqHistVO> hists;
	/** 소송수행 보조자 행 */
	private List<LawSuitReqHelperVO> helpers;
	/** 기타자료 첨부 파일 목록 (COMTNFILEDETAIL) */
	private List<FileVO> files;

	// ── 검색 ──
	/** 등록일자 기간 시작 (YYYYMMDD) */
	private String searchFrom;
	/** 등록일자 기간 종료 (YYYYMMDD) */
	private String searchTo;
	/** 상태 필터 (S001/S002/S003, 비면 전체) */
	private String searchStatus;
	/** 사건명 키워드 */
	private String searchKeyword;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
