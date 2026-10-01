package egovframework.com.cop.bbs.service.impl;

import java.util.List;

import org.springframework.stereotype.Repository;

import egovframework.com.cmm.service.impl.EgovComAbstractDAO;
import egovframework.com.cop.bbs.service.Board;
import egovframework.com.cop.bbs.service.BoardVO;

@Repository("EgovArticleDAO")
public class EgovArticleDAO extends EgovComAbstractDAO {

	public List<BoardVO> selectArticleList(BoardVO boardVO) {
		return selectList("BBSArticle.selectArticleList", boardVO);
	}

	public int selectArticleListCnt(BoardVO boardVO) {
		return (Integer)selectOne("BBSArticle.selectArticleListCnt", boardVO);
	}

	public int selectMaxInqireCo(BoardVO boardVO) {
		return (Integer)selectOne("BBSArticle.selectMaxInqireCo", boardVO);
	}

	public void updateInqireCo(BoardVO boardVO) {
		update("BBSArticle.updateInqireCo", boardVO);
	}

	public BoardVO selectArticleDetail(BoardVO boardVO) {
		return (BoardVO) selectOne("BBSArticle.selectArticleDetail", boardVO);
	}

	/** 이전 글(더 오래된, 웹진형 상세 네비). 없으면 null. */
	public BoardVO selectPrevArticle(BoardVO boardVO) {
		return (BoardVO) selectOne("BBSArticle.selectPrevArticle", boardVO);
	}

	/** 다음 글(더 최신, 웹진형 상세 네비). 없으면 null. */
	public BoardVO selectNextArticle(BoardVO boardVO) {
		return (BoardVO) selectOne("BBSArticle.selectNextArticle", boardVO);
	}
	
	public void replyArticle(Board board) {
		insert("BBSArticle.replyArticle", board);
	}

	public void insertArticle(Board board) {
		insert("BBSArticle.insertArticle", board);
	}

	public void updateArticle(Board board) {
		update("BBSArticle.updateArticle", board);
	}

	public void deleteArticle(Board board) {
		update("BBSArticle.deleteArticle", board);

	}

	public void restoreArticle(Board board) {
		update("BBSArticle.restoreArticle", board);
	}

	public List<BoardVO> selectNoticeArticleList(BoardVO boardVO) {
		return selectList("BBSArticle.selectNoticeArticleList", boardVO);
	}
	
	public List<BoardVO> selectGuestArticleList(BoardVO vo) {
		return selectList("BBSArticle.selectGuestArticleList", vo);
	}

	public int selectGuestArticleListCnt(BoardVO vo) {
		return (Integer)selectOne("BBSArticle.selectGuestArticleListCnt", vo);
	}

}
