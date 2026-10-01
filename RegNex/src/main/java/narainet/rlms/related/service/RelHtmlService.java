/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelHtmlService.java
 *
 * 관련자료 — HTML 액션 Service.
 *  saveHtml: 직접 작성한 HTML 표/본문 1건 → TB_REL_VRSN + TB_REL_HTML 2-row INSERT.
 *  파일 업로드 없음 (TB_ATTACH 미사용).
 *
 *  레거시 RelatedController.htmlUpdateDo (RelatedController.java:1344-1480) 1:1 이식.
 *  getNewVersion 사용 (FILE 의 getNewHseqVersion 아님). 분류 없음.
 *  RLMS 1차는 PromulgationActionLog INSERT 생략 (B1/B2 와 동일 정책).
 */
package narainet.rlms.related.service;

import java.util.List;

public interface RelHtmlService {

	List<RelHtmlVO> getList(Long relVrsnNo);

	RelHtmlVO getByNo(Long relHtmlNo);

	/**
	 * HTML 1건 신규 등록.
	 *  - 마스터(TB_REL_VRSN) 새 row + 자식(TB_REL_HTML) 새 row.
	 *  - SHTML 은 CLOB. 분류 없음 (getNewVersion, cateNo=null).
	 *  Returns 신규 IRHTML_NO.
	 */
	Long saveHtml(Long promNo, String flag, String fullItem,
			String title, String html, String sysId) throws Exception;

	/** 제목/본문 변경 */
	void updateContent(Long relHtmlNo, String title, String html);

	/** 소프트 삭제 — SDEL_YN='Y' */
	void softDelete(Long relHtmlNo);

	/** 물리 삭제 — 마스터의 마지막 자식이면 마스터도 삭제. */
	void delete(Long relHtmlNo) throws Exception;
}
