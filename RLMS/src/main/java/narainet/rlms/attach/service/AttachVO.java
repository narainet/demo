/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/attach/service/AttachVO.java
 *
 * 도메인 첨부(TB_ATTACH) VO.
 * 도메인 모듈(prom/prov_html/rel_*,  cate/act ...) 이 polymorphic 으로 참조:
 *   SREF_TABLE = 'TB_PROV_HTML' / 'TB_PROM' / 'TB_REL_*' / ...
 *   IREF_NO    = 해당 row PK
 *
 * 표준 흡수 모듈(BBS/popup) 은 이 테이블 대신 COMTNFILE/COMTNFILEDETAIL 사용.
 * (memory: feedback_attach_policy.md)
 */
package narainet.rlms.attach.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 도메인 첨부 VO (TB_ATTACH)
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성 (도메인 첨부 정책 반영)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class AttachVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IATT_NO, COMTECOPSEQ.ATTACH_ID 채번) */
	private Long attNo;

	/** 카테고리 ID (SCATE_ID — AjaxRelatedContentsType 등) */
	private String cateId;

	/** 참조 테이블명 (SREF_TABLE — 예: "TB_PROV_HTML") */
	private String refTable;

	/** 참조 row PK (IREF_NO) */
	private Long refNo;

	/** 파일 경로 (SPATH) */
	private String path;

	/** 원본 파일명 (SNAME) */
	private String name;

	/** 저장 매핑 파일명 (SMAPPING — 디스크에 저장된 실제 파일) */
	private String mapping;

	/** 확장자 (SEXT) */
	private String ext;

	/** 메타 (SMETA) */
	private String meta;

	/** 제목 (STITLE) */
	private String title;

	/** 내용 (SCONTENTS, CLOB — 텍스트 추출 결과) */
	private String contents;

	/** 정렬순서 (ISEQ) */
	private Integer seq;

	/** 등록일 (SINS_DT) */
	private String insDt;

	/** 파일 크기 (ISIZE, byte) */
	private Long size;

	/** 시스템 ID (SSYS_ID) */
	private String sysId;

	/**
	 * 다운로드 횟수 (IDOWN_CNT) — attachDownload/downloadZip 성공 시 +1 (2026-07-30).
	 * 상세 이력(누가/언제/IP)은 TB_ACT_LOG(STASK='파일 다운로드'); 이 값은 목록 표시용 집계.
	 */
	private Long downCnt;
}
