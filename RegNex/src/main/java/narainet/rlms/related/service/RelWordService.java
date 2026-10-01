/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelWordService.java
 *
 * 관련자료 — WORD 액션 Service.
 *  레거시 RelatedController.wordUpdateDo (847-1037) 1:1.
 *  ★2026-06-16 자체변환 도입: .docx/.hwpx 업로드 시 SSEARCH_TEXT/SHTML 채움(DocImportService 재사용).
 *    .doc/.hwp/.pdf 등은 여전히 원본만 보관(변환 컬럼 NULL).
 */
package narainet.rlms.related.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

public interface RelWordService {

	List<RelWordVO> getList(Long relVrsnNo);

	RelWordVO getByNo(Long relWordNo);

	/** 자체변환 평문(SSEARCH_TEXT) 전문검색 — 매칭 규정/문서/스니펫 목록(최대 50). */
	List<Map<String,Object>> searchByText(String keyword);

	/**
	 * 문서 1건 신규 등록 (변환 X, 원본만 보관).
	 *  - 마스터(TB_REL_VRSN) + 자식(TB_REL_WORD) + 첨부(TB_ATTACH).
	 *  - 변환 관련 컬럼은 NULL/디폴트.
	 *  Returns 신규 IRWORD_NO.
	 */
	Long saveWord(Long promNo, String flag, String fullItem,
			String title, MultipartFile file, String sysId) throws Exception;

	void updateMeta(Long relWordNo, String title);

	void softDelete(Long relWordNo);

	void delete(Long relWordNo) throws Exception;
}
