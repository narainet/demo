/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/mapper/BoardWriteAuthMapper.java
 *
 * 게시판별 작성권한(COMTNBBSWRITEAUTHOR) 접근.
 */
package egovframework.com.cop.bbs.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface BoardWriteAuthMapper {

	/** 이 게시판에 글을 쓸 수 있는 역할 목록. 없으면 빈 목록. */
	List<String> selectWriteAuthorCodes(@Param("bbsId") String bbsId);

	int deleteWriteAuthors(@Param("bbsId") String bbsId);

	int insertWriteAuthor(@Param("bbsId") String bbsId, @Param("authorCode") String authorCode);
}
