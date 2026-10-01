/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/attach/service/AttachService.java
 */
package narainet.rlms.attach.service;

import java.util.List;

import org.springframework.web.multipart.MultipartFile;

/**
 * 도메인 첨부(TB_ATTACH) Service.
 * polymorphic 참조 (refTable + refNo) 기반.
 */
public interface AttachService {

	/** 특정 도메인 row 의 첨부 목록 */
	List<AttachVO> listByRef(String refTable, Long refNo);

	/** PK 단건 */
	AttachVO selectByNo(Long attNo);

	/**
	 * 파일 업로드 + TB_ATTACH row INSERT.
	 * 저장 위치는 RLMS 설정 키 (Globals.rlms.AttachPath) 기준.
	 */
	AttachVO save(String refTable, Long refNo, String cateId,
			MultipartFile file, String sysId) throws Exception;

	/** 특정 도메인 row 의 첨부 전체 삭제 (Java 명시 호출 — 트리거 미적용 케이스) */
	int deleteByRef(String refTable, Long refNo) throws Exception;

	/** 단건 삭제 */
	int deleteByNo(Long attNo) throws Exception;

	/**
	 * 물리 파일 해석.
	 * RLMS 신규 행은 SPATH=파일명 포함 절대경로, 레거시 이관 행은 SPATH='2010_10' 같은
	 * 월별 디렉터리 키 + SMAPPING(디스크 저장명) 분리 구조라 경로 조립이 다르다.
	 * 레거시 루트는 Globals.rlms.LegacyAttachPath (레거시 ATTACH_SAVE_PATH 대응).
	 * @return 존재하고 읽을 수 있는 파일, 못 찾으면 null
	 */
	java.io.File resolvePhysical(AttachVO att);

	/**
	 * 브라우저 인라인 보기용 PDF 해석 (레거시 viewer.htm 의 pdf_yn 판정 대응).
	 * 원본이 PDF 면 원본, 아니면 같은 폴더의 동명 .pdf 변환본(레거시 DCMS 산출물).
	 * @return PDF 파일, 없으면 null
	 */
	java.io.File resolvePdfView(AttachVO att);
}
