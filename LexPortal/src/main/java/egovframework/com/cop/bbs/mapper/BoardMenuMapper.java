/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/mapper/BoardMenuMapper.java
 *
 * 게시판 ↔ 사용자 메뉴 연결의 표준 3테이블 접근.
 *   COMTNPROGRMLIST(프로그램) · COMTNMENUINFO(메뉴) · COMTNMENUCREATDTLS(역할매핑)
 * 게시판을 가리키는 프로그램은 URL 이 유일키 역할을 한다 — '/cop/bbs/user/selectArticleList.do?bbsId=<bbsId>'.
 */
package egovframework.com.cop.bbs.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import egovframework.com.cop.bbs.service.BoardMenuVO;

@Mapper
public interface BoardMenuMapper {

	/** 프로그램 URL 로 연결된 메뉴를 찾는다. 정상 상태에서는 0건 또는 1건. */
	List<BoardMenuVO> selectBoardMenuByUrl(@Param("url") String url);

	/** 해당 게시판 메뉴에 매핑된 역할 목록. 메뉴가 없으면 빈 목록. */
	List<String> selectBoardMenuAuthorCodes(@Param("url") String url);

	/** 사용자 게시판 메뉴 전체 (목록화면에서 게시판별 노출 상태를 한 번에 표시). */
	List<BoardMenuVO> selectAllBoardMenus(@Param("urlPrefix") String urlPrefix);

	/** 폴더 아래 다음 메뉴번호 (AABBCCDD 컨벤션 — 자식은 상위 + n*10000). */
	Long selectNextMenuNo(@Param("upperMenuNo") Long upperMenuNo);

	/** 폴더 아래 다음 정렬순서. */
	Integer selectNextMenuOrdr(@Param("upperMenuNo") Long upperMenuNo);

	/** 상위 폴더 메뉴가 실재하는지. */
	int countMenu(@Param("menuNo") Long menuNo);

	/** 이 프로그램을 참조하는 메뉴 수 — 프로그램 삭제 전 CASCADE 피해 확인용. */
	int countMenusByProgrm(@Param("progrmFileNm") String progrmFileNm);

	int insertProgrm(BoardMenuVO vo);

	int updateProgrm(BoardMenuVO vo);

	/** ⛔ 반드시 참조 메뉴를 먼저 지운 뒤 호출 — COMTNMENUINFO 는 이 행을 CASCADE 로 물고 있다. */
	int deleteProgrm(@Param("progrmFileNm") String progrmFileNm);

	int insertMenu(BoardMenuVO vo);

	int updateMenu(BoardMenuVO vo);

	/** 메뉴 삭제 — COMTNMENUCREATDTLS 는 CASCADE 로 함께 지워진다. */
	int deleteMenu(@Param("menuNo") Long menuNo);

	int insertMenuAuthor(@Param("menuNo") Long menuNo, @Param("authorCode") String authorCode);

	int deleteMenuAuthors(@Param("menuNo") Long menuNo);
}
