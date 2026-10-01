package egovframework.com.cop.cmt.service;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.fdl.cmmn.exception.FdlException;

public interface EgovArticleCommentService {

    public boolean canUseComment(String bbsId) throws Exception;

    Map<String, Object> selectArticleCommentList(CommentVO commentVO);

	/** 페이징 없는 전체 댓글(등록순 ASC) — 사용자 댓글 UI(JSON) 전용. */
	List<CommentVO> selectArticleCommentAllList(CommentVO commentVO);

	void insertArticleComment(Comment comment) throws FdlException;

	void deleteArticleComment(CommentVO commentVO);

	CommentVO selectArticleCommentDetail(CommentVO commentVO);

	void updateArticleComment(Comment comment);

}
