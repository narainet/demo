/**
 * 개요
 * - 배너에 대한 ServiceImpl 클래스를 정의한다.
 * 
 * 상세내용
 * - 배너에 대한 등록, 수정, 삭제, 조회, 반영확인 기능을 제공한다.
 * - 배너의 조회기능은 목록조회, 상세조회로 구분된다.
 * @author 이문준
 * @version 1.0
 * @created 03-8-2009 오후 2:07:12
 */

package egovframework.com.uss.ion.bnr.service.impl;

import java.io.File;
import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.service.FileVO;
import egovframework.com.uss.ion.bnr.service.Banner;
import egovframework.com.uss.ion.bnr.service.BannerVO;
import egovframework.com.uss.ion.bnr.service.EgovBannerService;

@Service("egovBannerService")
public class EgovBannerServiceImpl extends EgovAbstractServiceImpl implements EgovBannerService {
	
	/** logger */
	private static final Logger LOGGER = LoggerFactory.getLogger(EgovBannerServiceImpl.class);

	@Resource(name="bannerDAO")
    private BannerDAO bannerDAO;

	/** 배너 삭제 시 첨부 레코드 정리에 사용 */
	@Resource(name="EgovFileMngService")
    private EgovFileMngService fileMngService;

	/**
	 * 배너를 관리하기 위해 등록된 배너목록을 조회한다.
	 * @param bannerVO - 배너 VO
	 * @return List - 배너 목록
	 */
	public List<BannerVO> selectBannerList(BannerVO bannerVO) throws Exception{
		return bannerDAO.selectBannerList(bannerVO);
	}

	/**
	 * 배너목록 총 개수를 조회한다.
	 * @param bannerVO - 배너 VO
	 * @return int - 배너 카운트 수
	 */
	public int selectBannerListTotCnt(BannerVO bannerVO) throws Exception {
		return bannerDAO.selectBannerListTotCnt(bannerVO);
	}
	
	/**
	 * 등록된 배너의 상세정보를 조회한다.
	 * @param bannerVO - 배너 VO
	 * @return BannerVO - 배너 VO
	 */
	public BannerVO selectBanner(BannerVO bannerVO) throws Exception{
		return bannerDAO.selectBanner(bannerVO);
	}

	/**
	 * 배너정보를 신규로 등록한다.
	 * @param banner - 배너 model
	 */
	public BannerVO insertBanner(Banner banner, BannerVO bannerVO) throws Exception{
        bannerDAO.insertBanner(banner);
        bannerVO.setBannerId(banner.getBannerId());
        return selectBanner(bannerVO);
	}

	/**
	 * 기 등록된 배너정보를 수정한다.
	 * @param banner - 배너 model
	 */
	public void updateBanner(Banner banner) throws Exception{
        bannerDAO.updateBanner(banner);
	}

	/**
	 * 기 등록된 배너정보를 삭제한다.
	 * @param banner - 배너 model
	 */
	public void deleteBanner(Banner banner) throws Exception {
		deleteBannerFile(banner);
        bannerDAO.deleteBanner(banner);
	}

	/**
	 * 기 등록된 배너정보의 이미지파일을 삭제한다.
	 * @param banner - 배너 model
	 */
	public void deleteBannerFile(Banner banner) throws Exception{
		FileVO fileVO = (FileVO)bannerDAO.selectBannerFile(banner);
		// 이미지가 없는 배너(또는 첨부 레코드가 이미 사라진 배너)는 정리할 것이 없다.
		// 예전에는 여기서 바로 fileVO.getFileStreCours() 를 불러 NPE 로 삭제 자체가 실패했다 (2026-07-31).
		if (fileVO == null) {
			LOGGER.debug("[banner] 첨부 없음 — 파일 정리 생략: {}", banner.getBannerId());
			return;
		}

		// ① 실제 파일
		String cours = fileVO.getFileStreCours();
		String streNm = fileVO.getStreFileNm();
		if (cours != null && streNm != null) {
			File file = new File(cours + streNm);
			//2017.02.08 	이정은 	시큐어코딩(ES)-부적절한 예외 처리[CWE-253, CWE-440, CWE-754]
			if(file.delete()){
				LOGGER.debug("[file.delete] file : File Deletion Success");
			}else{
				LOGGER.error("[file.delete] file : File Deletion Fail");
			}
		}

		// ② 첨부 레코드 — 배너 행은 곧 완전 삭제(DELETE)되어 참조가 사라지므로 고아 행을 남기지 않는다.
		//    이미지 '교체' 때는 정리하지 않는다(잘못 올린 뒤 되돌릴 여지를 남긴다) — 삭제 시에만 정리.
		String atchFileId = fileVO.getAtchFileId();
		if (atchFileId != null && !atchFileId.isEmpty()) {
			try {
				fileMngService.deleteFileInf(fileVO);      // COMTNFILEDETAIL 해당 행 삭제
				fileMngService.deleteAllFileInf(fileVO);   // COMTNFILE 사용여부 'N'
			} catch (Exception e) {
				// 첨부 레코드 정리 실패가 배너 삭제 자체를 막지는 않는다.
				LOGGER.warn("[banner] 첨부 레코드 정리 실패(배너 삭제는 진행): {}", e.getMessage());
			}
		}
	}

	/**
	 * 배너가 특정화면에 반영된 결과를 조회한다.
	 * @param bannerVO - 배너 VO
	 * @return BannerVO - 배너 VO
	 */
	public List<BannerVO> selectBannerResult(BannerVO bannerVO) throws Exception{
		return bannerDAO.selectBannerResult(bannerVO);
	}

	/**
	 * 다음 정렬순서(현재 최대값 + 1)를 조회한다 — 등록 화면 기본값.
	 * @return String - 다음 정렬순서
	 */
	public String selectNextSortOrdr() throws Exception{
		return bannerDAO.selectNextSortOrdr();
	}

}