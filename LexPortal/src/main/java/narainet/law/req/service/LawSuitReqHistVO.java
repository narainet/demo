/*
 * 물리적 저장 경로: /src/main/java/narainet/law/req/service/LawSuitReqHistVO.java
 *
 * 소송의뢰 사건경과 내역 (LAW_SUIT_REQ_HIST ← tbetia41) — 행별 첨부 1건. §4.3
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
public class LawSuitReqHistVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_REQ_HIST_ID) */
	private Long histId;
	/** 의뢰 ID (LAW_SUIT_REQ FK) */
	private Long reqId;
	/** 기간 시작일 (YYYYMMDD, 화면 yyyy-MM-dd) */
	private String staDt;
	/** 기간 종료일 (YYYYMMDD) */
	private String endDt;
	/** 경과 내용 */
	private String histCn;
	/** 행별 첨부파일 ID (표준 COMTNFILE) */
	private String atchFileId;
	/** 표시 순서 */
	private Integer sortOrdr;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;

	/** 첨부 파일 목록 (상세 표시용) */
	private List<FileVO> files;
	/** 폼에서 파일 파트 이름 매칭용 클라이언트 키(histFile_<rowKey>) — 저장 전용, DB 미저장 */
	private String rowKey;
}
