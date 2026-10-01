package egovframework.com.cop.bbs.service.impl;

import java.util.List;

import org.springframework.stereotype.Repository;

import egovframework.com.cmm.service.impl.EgovComAbstractDAO;
import egovframework.com.cop.bbs.service.BoardMaster;
import egovframework.com.cop.bbs.service.BoardMasterVO;

@Repository("EgovBBSMasterDAO")
public class EgovBBSMasterDAO extends EgovComAbstractDAO {

	public List<BoardMasterVO> selectBBSMasterInfs(BoardMasterVO boardMasterVO) {
		return selectList("BBSMaster.selectBBSMasterList", boardMasterVO);
	}

	public int selectBBSMasterInfsCnt(BoardMasterVO boardMasterVO) {
		return (Integer)selectOne("BBSMaster.selectBBSMasterListTotCnt", boardMasterVO);
	}
	
	public BoardMasterVO selectBBSMasterDetail(BoardMasterVO boardMasterVO) {
		return (BoardMasterVO) selectOne("BBSMaster.selectBBSMasterDetail", boardMasterVO);
	}

	public void insertBBSMasterInf(BoardMaster boardMaster) {
		insert("BBSMaster.insertBBSMaster", boardMaster);
	}

	public void updateBBSMaster(BoardMaster boardMaster) {
		update("BBSMaster.updateBBSMaster", boardMaster);
	}

	public void deleteBBSMaster(BoardMaster boardMaster) {
		update("BBSMaster.deleteBBSMaster", boardMaster);
	}

	public void deleteBBSArticles(BoardMaster boardMaster) {
		update("BBSMaster.deleteBBSArticles", boardMaster);
	}

	public void deleteBBSMasterAtchFiles(BoardMaster boardMaster) {
		update("BBSMaster.deleteBBSMasterAtchFiles", boardMaster);
	}

	public List<BoardMasterVO> selectBBSListPortlet(BoardMasterVO boardMasterVO) {
		return selectList("BBSMaster.selectBBSListPortlet", boardMasterVO);
	}

	/** 속성폼 템플릿 select 용 — 사용중(USE_AT='Y')인 템플릿 목록(tmplatId/tmplatNm/tmplatSeCode). */
	public List<BoardMasterVO> selectTemplateList() {
		return selectList("BBSMaster.selectTemplateList");
	}
}
