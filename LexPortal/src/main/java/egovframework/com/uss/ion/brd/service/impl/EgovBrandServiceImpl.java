/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/brd/service/impl/EgovBrandServiceImpl.java
 *
 * 브랜드설정(로고·파비콘) 서비스 구현.
 *
 * 캐시 정책: 데코레이터가 모든 페이지에서 참조하므로 기동 시 1회 적재해 BrandInfo 에 얹고,
 *            설정을 저장할 때만 다시 읽어 교체한다(즉시 반영).
 *            DB 가 늦게 뜨거나 테이블이 아직 없는 환경에서도 기동은 막지 않는다 — 적재 실패는 경고만.
 */
package egovframework.com.uss.ion.brd.service.impl;

import java.io.File;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Service;

import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.service.FileVO;
import egovframework.com.uss.ion.brd.service.Brand;
import egovframework.com.uss.ion.brd.service.BrandInfo;
import egovframework.com.uss.ion.brd.service.EgovBrandService;

@Service("egovBrandService")
public class EgovBrandServiceImpl extends EgovAbstractServiceImpl implements EgovBrandService, InitializingBean {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovBrandServiceImpl.class);

	@Resource(name = "brandDAO")
	private BrandDAO brandDAO;

	/** 이미지 교체 시 옛 첨부 정리에 사용 */
	@Resource(name = "EgovFileMngService")
	private EgovFileMngService fileMngService;

	/** 기동 시 1회 적재 — 실패해도 컨텍스트를 죽이지 않는다(화면은 기본값으로 뜬다). */
	@Override
	public void afterPropertiesSet() {
		try {
			BrandInfo.set(selectBrand());
		} catch (Exception e) {
			LOGGER.warn("브랜드설정 초기 적재 실패(기본값으로 시작): {}", e.getMessage());
		}
	}

	@Override
	public Brand selectBrand() throws Exception {
		Brand brand = brandDAO.selectBrand();
		return (brand == null) ? new Brand() : brand;   // 행이 없으면 기본값(TEXT)
	}

	@Override
	public void updateBrand(Brand brand) throws Exception {
		// 교체 전 첨부ID 를 먼저 확보 — 갱신 후에는 옛 값을 알 수 없다.
		Brand before = brandDAO.selectBrand();

		int updated = brandDAO.updateBrand(brand);
		if (updated == 0) {
			brandDAO.insertBrand(brand);                // 최초 저장 — 시드 행이 없는 설치본 대응
		}

		// 새 이미지로 교체된 슬롯의 옛 파일 정리. 브랜드 이미지는 슬롯당 1개뿐이라
		// 교체 즉시 옛 파일은 어디서도 참조되지 않는다(게시판 첨부와 달리 이력이 없다).
		// ★ 순서 주의: DB 갱신이 성공한 뒤에 지운다. 먼저 지우면 저장 실패 시 현재 로고까지 잃는다.
		if (before != null) {
			purgeReplaced(before.getLogoAtchFileId(), brand.getLogoAtchFileId());
			purgeReplaced(before.getFaviconAtchFileId(), brand.getFaviconAtchFileId());
		}

		BrandInfo.set(selectBrand());                   // 화면 캐시 즉시 갱신
	}

	/** 새 첨부가 실제로 올라와 교체된 경우에만 옛 첨부를 지운다(새 값이 비었으면 유지된 것이므로 손대지 않는다). */
	private void purgeReplaced(String oldId, String newId) {
		if (oldId == null || oldId.trim().isEmpty()) {
			return;                                     // 원래 없었다
		}
		if (newId == null || newId.trim().isEmpty()) {
			return;                                     // 이번에 안 올렸다 = 기존 유지
		}
		if (oldId.trim().equals(newId.trim())) {
			return;                                     // 같은 파일
		}
		deleteAttach(oldId.trim());
	}

	/** 첨부 1건을 실제 파일과 레코드까지 정리한다. 실패해도 저장 자체는 되돌리지 않는다. */
	private void deleteAttach(String atchFileId) {
		try {
			FileVO fileVO = brandDAO.selectBrandFile(atchFileId);
			if (fileVO == null) {
				return;
			}
			String cours = fileVO.getFileStreCours();
			String streNm = fileVO.getStreFileNm();
			if (cours != null && streNm != null) {
				File file = new File(cours, streNm);
				if (file.delete()) {
					LOGGER.debug("[brand] 옛 이미지 파일 삭제: {}", streNm);
				} else {
					LOGGER.warn("[brand] 옛 이미지 파일 삭제 실패: {}", streNm);
				}
			}
			fileMngService.deleteFileInf(fileVO);       // COMTNFILEDETAIL 행
			fileMngService.deleteAllFileInf(fileVO);    // COMTNFILE 사용여부 'N'
		} catch (Exception e) {
			LOGGER.warn("[brand] 옛 이미지 정리 실패(저장은 정상 완료): {}", e.getMessage());
		}
	}

	@Override
	public FileVO selectBrandFile(String atchFileId) throws Exception {
		if (atchFileId == null || atchFileId.trim().isEmpty()) {
			return null;
		}
		return brandDAO.selectBrandFile(atchFileId.trim());
	}
}
