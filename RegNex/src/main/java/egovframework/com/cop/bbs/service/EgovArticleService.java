package egovframework.com.cop.bbs.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

/**
 * <pre>
 * << 개정이력(Modification Information) >>
 *   
 *   수정일			수정자		수정내용
 *  -------			--------	---------------------------
 *   2024.10.29		inganyoyo	Transaction 처리 오류 수정(Article)
 * </pre>
 */

public interface EgovArticleService {

	Map<String, Object> selectArticleList(BoardVO boardVO);

	BoardVO selectArticleDetail(BoardVO boardVO);

	/** 이전 글(더 오래된, 웹진형 상세 네비). 없으면 null. */
	BoardVO selectPrevArticle(BoardVO boardVO);

	/** 다음 글(더 최신, 웹진형 상세 네비). 없으면 null. */
	BoardVO selectNextArticle(BoardVO boardVO);

	/**
	 * 게시물 상세 조회. plusCount=false 면 조회수를 올리지 않는다.
	 * (댓글 페이징·수정폼 로드처럼 같은 글을 다시 그리는 재요청을 열람으로 세지 않기 위함)
	 */
	BoardVO selectArticleDetail(BoardVO boardVO, boolean plusCount);

	void insertArticleAndFiles(Board board, List<MultipartFile> files) throws Exception;

	void updateArticle(Board board);

  void updateArticleAndFiles(Board board, List<MultipartFile> files, String atchFileId)
      throws Exception;

  void deleteArticle(Board board) throws Exception;

  void restoreArticle(Board board) throws Exception;

	List<BoardVO> selectNoticeArticleList(BoardVO boardVO);
	
	Map<String, Object> selectGuestArticleList(BoardVO vo);
}
