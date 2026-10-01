/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelImgService.java
 *
 * 관련자료 — IMAGE 액션 Service. 레거시 RelatedController.imageUpdateDo (1514-1697) 1:1.
 *  ORGN 과 동일 구조 (분류·뷰어 없음). RLMS 1차는 PromulgationActionLog INSERT 생략.
 */
package narainet.rlms.related.service;

import java.util.List;

import org.springframework.web.multipart.MultipartFile;

public interface RelImgService {

	List<RelImgVO> getList(Long relVrsnNo);

	RelImgVO getByNo(Long relImgNo);

	/**
	 * 이미지 1건 신규 등록.
	 *  - 마스터(TB_REL_VRSN) + 자식(TB_REL_IMG) + 첨부(TB_ATTACH) 한꺼번에.
	 *  - 카테고리 없음 (getNewVersion, cateNo=null).
	 *  Returns 신규 IRIMG_NO.
	 */
	Long saveImg(Long promNo, String flag, String fullItem,
			String title, MultipartFile file, String sysId) throws Exception;

	void updateMeta(Long relImgNo, String title);

	void softDelete(Long relImgNo);

	void delete(Long relImgNo) throws Exception;
}
