/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/brd/service/EgovBrandService.java
 *
 * 브랜드설정(로고·파비콘) 서비스 인터페이스.
 */
package egovframework.com.uss.ion.brd.service;

import egovframework.com.cmm.service.FileVO;

public interface EgovBrandService {

	/**
	 * 브랜드설정을 조회한다. 행이 없으면 기본값(텍스트 모드)을 돌려준다.
	 * @return Brand - 브랜드설정
	 * @exception Exception
	 */
	Brand selectBrand() throws Exception;

	/**
	 * 브랜드설정을 저장하고 화면 캐시(BrandInfo)를 즉시 갱신한다.
	 * @param brand - 브랜드설정
	 * @exception Exception
	 */
	void updateBrand(Brand brand) throws Exception;

	/**
	 * 첨부ID 로 파일 1건을 조회한다 — 로고·파비콘 이미지 서빙용.
	 * @param atchFileId - 첨부파일ID
	 * @return FileVO - 파일 정보. 없으면 null
	 * @exception Exception
	 */
	FileVO selectBrandFile(String atchFileId) throws Exception;
}
