/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelOrgnService.java
 *
 * 관련자료 — ORGN 액션 Service.
 *  saveOrgn: multipart 업로드 1건 → TB_ATTACH + TB_REL_VRSN + TB_REL_ORGN 3-row INSERT.
 *
 *  레거시 RelatedController.orgnUpdateDo (RelatedController.java:632-813) 1:1 이식.
 *  FILE 과 달리 분류 메타 없음 → getNewHseqVersion 이 아니라 getNewVersion 사용.
 *  SVIEW_YN / SVIEW_CMPLT_YN / DocumentConversion 없음 (보존용 원본).
 *  RLMS 1차는 PromulgationActionLog INSERT 생략 (TB_PROM_ACT_LOG 액션 카테고리 확장 후 2차).
 */
package narainet.rlms.related.service;

import java.util.List;

import org.springframework.web.multipart.MultipartFile;

public interface RelOrgnService {

	List<RelOrgnVO> getList(Long relVrsnNo);

	RelOrgnVO getByNo(Long relOrgnNo);

	/**
	 * 원본 1건 신규 등록.
	 *  - 마스터(TB_REL_VRSN) 새 row + 자식(TB_REL_ORGN) 새 row + 첨부(TB_ATTACH) 새 row 한꺼번에.
	 *  - 카테고리 없음 (getNewVersion). SVIEW_YN 없음.
	 *  Returns 신규 IRORGN_NO.
	 */
	Long saveOrgn(Long promNo, String flag, String fullItem,
			String title, MultipartFile file, String sysId) throws Exception;

	/** 제목 변경 */
	void updateMeta(Long relOrgnNo, String title);

	/** 소프트 삭제 — SDEL_YN='Y' (TB_ATTACH 는 보존) */
	void softDelete(Long relOrgnNo);

	/**
	 * 물리 삭제 — 마스터의 마지막 자식이면 마스터도 삭제.
	 *  TB_ATTACH 디스크 파일도 함께 제거 (best-effort).
	 */
	void delete(Long relOrgnNo) throws Exception;
}
