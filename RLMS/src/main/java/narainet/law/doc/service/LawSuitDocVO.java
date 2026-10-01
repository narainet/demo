/*
 * 물리적 저장 경로: /src/main/java/narainet/law/doc/service/LawSuitDocVO.java
 *
 * 소송문서 (LAW_SUIT_DOC ← tbetia17) — 첨부=표준 COMTNFILE, 등록=승인대기·수정 시 대기 리셋. §7.2·§4.2
 */
package narainet.law.doc.service;

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
public class LawSuitDocVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_DOC_ID) */
	private Long docId;
	/** 사건 ID (LAW_SUIT FK) */
	private Long suitId;
	/** 문서종류(LAW_DOC_KIND) */
	private String docKindCd;
	private String docKindNm;
	/** 문서 제목 */
	private String docTitl;
	/** 메모 */
	private String docMemo;
	/** 첨부파일 ID (표준 COMTNFILE) */
	private String atchFileId;

	/** 승인상태(LAW_DOC_APP_STATUS — S001 대기/S002 승인/S003 반려) */
	private String appStsCd;
	private String appStsNm;
	/** 승인(반려)자 */
	private String appUserId;
	private String appUserNm;
	/** 승인(반려)일시 (YYYYMMDDHH24MISS) */
	private String appDt;
	/** 승인의견·반려사유 */
	private String appOpinion;

	private String regUserId;
	private String regUserNm;
	private String regDt;
	private String updUserId;
	private String updDt;

	// ── 목록 표시용 사건 조인 ──
	private String courtNm;
	private String caseNo;
	private String caseNm;

	/** 첨부 파일 목록 (COMTNFILEDETAIL) */
	private List<FileVO> files;

	// ── 검색 (조회 화면) ──
	private String searchFrFrom;   // 소제기일 기간 시작 (YYYYMMDD)
	private String searchFrTo;     // 소제기일 기간 종료
	private String searchItpt;     // 제·피소구분
	private String searchCaseKind; // 소송구분
	private String searchRslt;     // 소송결과
	private String searchCaseYear; // 사건번호-연도
	private String searchCaseSign; // 사건번호-부호
	private String searchCaseSerial; // 사건번호-일련
	/** 문서종류 다중 선택(체크박스) — 비면 전체 */
	private List<String> searchDocKinds;
	/** 승인 처리 탭 상태 필터 (S002/S003, 비면 전체 처리분) */
	private String searchAppSts;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
