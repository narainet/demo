package egovframework.com.cop.bbs.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.apache.commons.lang3.RandomStringUtils;
import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;

import egovframework.com.cmm.EgovComponentChecker;
import egovframework.com.cop.bbs.service.BoardMaster;
import egovframework.com.cop.bbs.service.BoardMasterVO;
import egovframework.com.cop.bbs.service.BoardMenuLinkService;
import egovframework.com.cop.bbs.service.BoardWriteAuthService;
import egovframework.com.cop.bbs.service.EgovBBSMasterService;
import egovframework.com.utl.fcc.service.EgovStringUtil;

/**
 * <pre>
 * << 개정이력(Modification Information) >>
 *   
 *   수정일			수정자		수정내용
 *  -------			--------	---------------------------
 *   2024.10.29		inganyoyo	Controller는 Transaction 처리를 하지 않아 Controller에서 오류 발생 시 데이터 정합성 오류 문제 발생
 * </pre>
 */

@Service("EgovBBSMasterService")
public class EgovBBSMasterServiceImpl extends EgovAbstractServiceImpl implements EgovBBSMasterService {

	@Resource(name = "EgovBBSMasterDAO")
    private EgovBBSMasterDAO egovBBSMasterDao;

    @Resource(name = "egovBBSMstrIdGnrService")
    private EgovIdGnrService idgenService;
	
    //---------------------------------
    // 2009.06.26 : 2단계 기능 추가
    //---------------------------------
    @Resource(name = "BBSAddedOptionsDAO")
    private BBSAddedOptionsDAO addedOptionsDAO;
    ////-------------------------------

    /** 사용자 메뉴 노출(프로그램·메뉴·역할매핑) — 게시판 저장과 같은 트랜잭션에서 처리한다. */
    @Resource(name = "boardMenuLinkService")
    private BoardMenuLinkService boardMenuLinkService;

    /** 게시판별 작성권한 — 열람권한과 직교하는 축(COMTNBBSWRITEAUTHOR). */
    @Resource(name = "boardWriteAuthService")
    private BoardWriteAuthService boardWriteAuthService;

	@Override
	public Map<String, Object> selectNotUsedBdMstrList(BoardMasterVO boardMasterVO) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void deleteBBSMasterInf(BoardMaster boardMaster) {
		// 사라진 게시판이 사용자 GNB 에 남지 않도록 메뉴 연결부터 끊는다.
		boardMenuLinkService.removeLink(boardMaster.getBbsId());
		boardWriteAuthService.removeWriteAuthors(boardMaster.getBbsId());

		egovBBSMasterDao.deleteBBSMasterAtchFiles(boardMaster);
		egovBBSMasterDao.deleteBBSArticles(boardMaster);
		egovBBSMasterDao.deleteBBSMaster(boardMaster);
	}

	@Override
	public void updateBBSMasterInf(BoardMaster boardMaster) throws Exception {
		egovBBSMasterDao.updateBBSMaster(boardMaster);
		
		//---------------------------------
		// 2009.06.26 : 2단계 기능 추가
		//---------------------------------
		// 댓글(ANSWER_AT)·만족도(STSFDG_AT)는 독립 플래그. 옛 코드는 단일선택 option 하나로 둘을 결정해
		// 한쪽을 켜면 다른 쪽이 'N' 으로 꺼졌고, 화면의 option select 가 disabled 여도 제출 직전 재활성화돼
		// 속성을 아무거나 고쳐 저장하기만 해도 옵션이 뒤집혔다(2026-07-10 교정).
		normalizeOptionFlags(boardMaster);

		BoardMasterVO addedOptions = addedOptionsDAO.selectAddedOptionsInf(boardMaster);
		if (addedOptions == null) {
			if ("".equals(EgovStringUtil.isNullToString(boardMaster.getFrstRegisterId()))) {
				boardMaster.setFrstRegisterId(EgovStringUtil.isNullToString(boardMaster.getLastUpdusrId()));
			}
			addedOptionsDAO.insertAddedOptionsInf(boardMaster);
		} else {
			addedOptionsDAO.updateAddedOptionsInf(boardMaster);
		}

		boardMenuLinkService.syncLink(boardMaster);
		boardWriteAuthService.syncWriteAuthors(boardMaster);
	}

	/** COMTNBBSMASTEROPTN.ANSWER_AT/STSFDG_AT 는 CHAR(1) NOT NULL — 미전송/공백을 'N' 으로 정규화. */
	private void normalizeOptionFlags(BoardMaster boardMaster) {
		boardMaster.setCommentAt("Y".equals(boardMaster.getCommentAt()) ? "Y" : "N");
		boardMaster.setStsfdgAt("Y".equals(boardMaster.getStsfdgAt()) ? "Y" : "N");
	}

	@Override
	public BoardMasterVO selectBBSMasterInf(BoardMasterVO boardMasterVO) throws Exception {
		BoardMasterVO resultVO = egovBBSMasterDao.selectBBSMasterDetail(boardMasterVO);
        if (resultVO == null)
            throw processException("info.nodata.msg");
        
    	if(EgovComponentChecker.hasComponent("EgovBBSCommentService") || EgovComponentChecker.hasComponent("EgovBBSSatisfactionService")){//2011.09.15
    	    BoardMasterVO options = addedOptionsDAO.selectAddedOptionsInf(boardMasterVO);

    	    if (options != null) {
    	    	// ANSWER_AT/STSFDG_AT 는 독립 컬럼 — 화면이 둘을 따로 보여줄 수 있도록 원값을 그대로 싣는다.
    	    	// (option 은 단일선택 레거시라 둘 다 'Y' 면 정보가 소실된다)
    	    	resultVO.setCommentAt(options.getCommentAt());
    	    	resultVO.setStsfdgAt(options.getStsfdgAt());

	    		if (options.getCommentAt().equals("Y")) {
	    			resultVO.setOption("comment");
	    		}

	    		if (options.getStsfdgAt().equals("Y")) {
	    			resultVO.setOption("stsfdg");
	    		}
    	    } else {
    	    	resultVO.setOption("na");	// 미지정 상태로 수정 가능 (이미 지정된 경우는 수정 불가로 처리)
    	    }
    	}

    	// 작성권한을 함께 싣는다 — 수정폼이 현재 상태로 열리고, 상세화면이 그대로 보여줄 수 있다.
    	List<String> writeAuthors = boardWriteAuthService.selectWriteAuthorCodes(resultVO.getBbsId());
    	resultVO.setWriteAuthorCodes(writeAuthors.toArray(new String[0]));

        return resultVO;
	}

	@Override
	public Map<String, Object> selectBBSMasterInfs(BoardMasterVO boardMasterVO) {
		List<BoardMasterVO> result = egovBBSMasterDao.selectBBSMasterInfs(boardMasterVO);
		int cnt = egovBBSMasterDao.selectBBSMasterInfsCnt(boardMasterVO);
		
		Map<String, Object> map = new HashMap<String, Object>();
		
		map.put("resultList", result);
		map.put("resultCnt", Integer.toString(cnt));

		return map;
	}
	
	@Override
	public void insertBBSMasterInf(BoardMaster boardMaster) throws Exception {
		
		//2021 github 반영
		//String bbsId = idgenService.getNextStringId();
		//게시판 ID 채번
		String bbsId = idgenService.getNextStringId() + RandomStringUtils.randomAlphabetic(10);
		boardMaster.setBbsId(bbsId);
		
		egovBBSMasterDao.insertBBSMasterInf(boardMaster);

		//---------------------------------
		// 2009.06.26 : 2단계 기능 추가 — 댓글/만족도 옵션행은 항상 만든다(둘 다 'N' 이어도).
		//---------------------------------
		normalizeOptionFlags(boardMaster);
		addedOptionsDAO.insertAddedOptionsInf(boardMaster);

		boardMenuLinkService.syncLink(boardMaster);
		boardWriteAuthService.syncWriteAuthors(boardMaster);
	}

	@Override
	public List<BoardMasterVO> selectBBSListPortlet(BoardMasterVO boardMasterVO) throws Exception {
		return egovBBSMasterDao.selectBBSListPortlet(boardMasterVO);
	}

	@Override
	public List<BoardMasterVO> selectTemplateList() {
		return egovBBSMasterDao.selectTemplateList();
	}

}
