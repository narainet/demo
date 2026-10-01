package egovframework.com.cop.bbs.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.service.EgovFileMngUtil;
import egovframework.com.cmm.service.FileVO;
import egovframework.com.cop.bbs.service.Board;
import egovframework.com.cop.bbs.service.BoardVO;
import egovframework.com.cop.bbs.service.EgovArticleService;

/**
 * <pre>
 * << 개정이력(Modification Information) >>
 *   
 *   수정일			수정자		수정내용
 *  -------			--------	---------------------------
 *   2024.10.29		inganyoyo	Transaction 처리 오류 수정(Article)
 * </pre>
 */

@Service("EgovArticleService")
public class EgovArticleServiceImpl extends EgovAbstractServiceImpl implements EgovArticleService {

	@Resource(name = "EgovArticleDAO")
    private EgovArticleDAO egovArticleDao;

    @Resource(name = "EgovFileMngService")
    private EgovFileMngService fileService;

    @Resource(name = "propertiesService")
    protected EgovPropertyService propertyService;

    @Resource(name = "egovNttIdGnrService")
    private EgovIdGnrService nttIdgenService;
  @Resource(name = "EgovFileMngUtil")
  private EgovFileMngUtil fileUtil;
  @Resource(name = "EgovFileMngService")
  private EgovFileMngService fileMngService;

  /**
   * 첨부 저장 루트 프로퍼티 키 — globals.properties 의 Globals.fileStorePath.Bbs (예: D:/upload/bbs/).
   * 실제 저장은 그 아래 게시판(bbsId)별 폴더로 나뉜다 — D:/upload/bbs/&lt;bbsId&gt;/
   */
  private static final String STORE_PATH_KEY = "Globals.fileStorePath.Bbs";

	@Override
	public Map<String, Object> selectArticleList(BoardVO boardVO) {
		List<BoardVO> list = egovArticleDao.selectArticleList(boardVO);


		int cnt = egovArticleDao.selectArticleListCnt(boardVO);

		Map<String, Object> map = new HashMap<String, Object>();

		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));

		return map;
	}

	@Override
	public BoardVO selectArticleDetail(BoardVO boardVO) {
		return selectArticleDetail(boardVO, true);
	}

	@Override
	public BoardVO selectPrevArticle(BoardVO boardVO) {
		return egovArticleDao.selectPrevArticle(boardVO);
	}

	@Override
	public BoardVO selectNextArticle(BoardVO boardVO) {
		return egovArticleDao.selectNextArticle(boardVO);
	}

	@Override
	public BoardVO selectArticleDetail(BoardVO boardVO, boolean plusCount) {
	    if (plusCount) {
		    int iniqireCo = egovArticleDao.selectMaxInqireCo(boardVO);

		    boardVO.setInqireCo(iniqireCo);
		    egovArticleDao.updateInqireCo(boardVO);
	    }

		return egovArticleDao.selectArticleDetail(boardVO);
	}

  @Override
  public void insertArticleAndFiles(Board board, List<MultipartFile> files) throws Exception {
    List<FileVO> result = null;
    String atchFileId = "";

    if (files != null && !files.isEmpty()) {
      result = fileUtil.parseFileInf(files, "BBS_", 0, "", STORE_PATH_KEY, board.getBbsId());
      atchFileId = fileMngService.insertFileInfs(result);
    }
    board.setAtchFileId(atchFileId);

    if ("Y".equals(board.getReplyAt())) {
      // 답글인 경우 1. Parnts를 세팅, 2.Parnts의 sortOrdr을 현재글의 sortOrdr로 가져오도록, 3.nttNo는 현재 게시판의 순서대로
      // replyLc는 부모글의 ReplyLc + 1

		    board.setNttId(nttIdgenService.getNextIntegerId());	// 답글에 대한 nttId 생성
		    egovArticleDao.replyArticle(board);

		} else {
		    // 답글이 아닌경우 Parnts = 0, replyLc는 = 0, sortOrdr = nttNo(Query에서 처리)
		    board.setParnts("0");
		    board.setReplyLc("0");
		    board.setReplyAt("N");
		    board.setNttId(nttIdgenService.getNextIntegerId());//2011.09.22

		    egovArticleDao.insertArticle(board);
		}
	}

	@Override
	public void updateArticle(Board board) {
		egovArticleDao.updateArticle(board);
	}

  @Override
  public void updateArticleAndFiles(Board board, List<MultipartFile> files, String atchFileId)
      throws Exception {
    if (files != null && !files.isEmpty()) {
      if (atchFileId == null || "".equals(atchFileId)) {
        List<FileVO> result = fileUtil.parseFileInf(files, "BBS_", 0, atchFileId, STORE_PATH_KEY, board.getBbsId());
        atchFileId = fileMngService.insertFileInfs(result);
        board.setAtchFileId(atchFileId);
      } else {
        FileVO fvo = new FileVO();
        fvo.setAtchFileId(atchFileId);
        int cnt = fileMngService.getMaxFileSN(fvo);
        List<FileVO> _result = fileUtil.parseFileInf(files, "BBS_", cnt, atchFileId, STORE_PATH_KEY, board.getBbsId());
        fileMngService.updateFileInfs(_result);
      }
    }
		
    this.updateArticle(board);
  }

  @Override
  public void deleteArticle(Board board) throws Exception {
		// 복구 가능한 소프트삭제 — USE_AT='N' 만 바꾼다. 제목(NTT_SJ)·본문·첨부 전부 원본 보존.
		// 첨부그룹 소프트삭제(deleteAllFileInf)도 하지 않는다: selectFileList 가 USE_AT='Y' 필터라
		// 첨부를 숨기면 복구해도 첨부가 0건이 된다. 글이 숨겨지면 첨부는 숨은 글로만 도달하므로 안전.
		egovArticleDao.deleteArticle(board);
	}

  @Override
  public void restoreArticle(Board board) throws Exception {
		// 소프트삭제 되돌리기 — USE_AT='Y'. 과거 톰스톤(첨부 USE_AT='N')도 대비해 첨부그룹까지 복원.
		egovArticleDao.restoreArticle(board);
	}

	@Override
	public List<BoardVO> selectNoticeArticleList(BoardVO boardVO) {
		return egovArticleDao.selectNoticeArticleList(boardVO);
	}

	@Override
	public Map<String, Object> selectGuestArticleList(BoardVO vo) {
		List<BoardVO> list = egovArticleDao.selectGuestArticleList(vo);


		int cnt = egovArticleDao.selectGuestArticleListCnt(vo);

		Map<String, Object> map = new HashMap<String, Object>();

		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));

		return map;
	}

}
