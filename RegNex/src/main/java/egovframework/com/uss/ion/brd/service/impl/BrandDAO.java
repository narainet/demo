/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/brd/service/impl/BrandDAO.java
 *
 * 브랜드설정(로고·파비콘) DAO — COM_BRAND 단일 행.
 */
package egovframework.com.uss.ion.brd.service.impl;

import org.springframework.stereotype.Repository;

import egovframework.com.cmm.service.FileVO;
import egovframework.com.cmm.service.impl.EgovComAbstractDAO;
import egovframework.com.uss.ion.brd.service.Brand;

@Repository("brandDAO")
public class BrandDAO extends EgovComAbstractDAO {

	/**
	 * 브랜드설정을 조회한다. 아직 행이 없으면 null.
	 * @return Brand - 브랜드설정
	 * @exception Exception
	 */
	public Brand selectBrand() throws Exception {
		return (Brand) selectOne("brandDAO.selectBrand");
	}

	/**
	 * 브랜드설정을 수정한다.
	 * @param brand - 브랜드설정
	 * @return int - 수정 건수(0 이면 행이 없다는 뜻)
	 * @exception Exception
	 */
	public int updateBrand(Brand brand) throws Exception {
		return update("brandDAO.updateBrand", brand);
	}

	/**
	 * 브랜드설정을 신규 등록한다(행이 없을 때만).
	 * @param brand - 브랜드설정
	 * @exception Exception
	 */
	public void insertBrand(Brand brand) throws Exception {
		insert("brandDAO.insertBrand", brand);
	}

	/**
	 * 첨부ID 로 파일 1건(저장경로/저장파일명/확장자)을 조회한다 — 로고·파비콘 서빙용.
	 * @param atchFileId - 첨부파일ID
	 * @return FileVO - 파일 정보. 없으면 null
	 * @exception Exception
	 */
	public FileVO selectBrandFile(String atchFileId) throws Exception {
		return (FileVO) selectOne("brandDAO.selectBrandFile", atchFileId);
	}
}
