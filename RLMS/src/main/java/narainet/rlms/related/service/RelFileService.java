/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelFileService.java
 *
 * 관련자료 — FILE 액션 Service.
 *  saveFile: multipart 업로드 1건 → TB_ATTACH + TB_REL_VRSN + TB_REL_FILE 3-row INSERT.
 *
 *  레거시 RelatedController.fileUpdateDo (RelatedController.java:331-625) 1:1 이식.
 *  단 RLMS 1차는 PromulgationActionLog INSERT 생략 (TB_PROM_ACT_LOG 액션 카테고리 확장 후 2차).
 */
package narainet.rlms.related.service;

import java.util.List;

import org.springframework.web.multipart.MultipartFile;

public interface RelFileService {

	List<RelFileVO> getList(Long relVrsnNo);

	RelFileVO getByNo(Long relFileNo);

	/**
	 * 파일 1건 신규 등록.
	 *  - 마스터(TB_REL_VRSN) 새 row + 자식(TB_REL_FILE) 새 row + 첨부(TB_ATTACH) 새 row 한꺼번에.
	 *  - SVIEW_YN: ext ∈ {DOC,DOCX,HWP,XLS,XLSX,PPT,PPTX,PDF} → 'Y', 아니면 'N'.
	 *  - SVIEW_CMPLT_YN 항상 'N' (RLMS 1차 변환 인프라 미도입).
	 *  Returns 신규 IRFILE_NO.
	 */
	Long saveFile(Long promNo, String flag, String fullItem,
			Long cateNo, String cateName, Integer cateOrder,
			String title, MultipartFile file, String sysId) throws Exception;

	/** 제목/액션내분류 변경 */
	void updateMeta(Long relFileNo, String title, String cate);

	/** 소프트 삭제 — SDEL_YN='Y' (TB_ATTACH 는 보존) */
	void softDelete(Long relFileNo);

	/**
	 * 물리 삭제 — 마스터의 마지막 자식이면 마스터도 삭제.
	 *  TB_ATTACH 디스크 파일도 함께 제거 (best-effort).
	 */
	void delete(Long relFileNo) throws Exception;
}
