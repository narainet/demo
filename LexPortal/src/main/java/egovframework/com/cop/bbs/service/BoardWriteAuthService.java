/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/BoardWriteAuthService.java
 *
 * 게시판별 작성권한. 열람권한(메뉴 역할매핑)과 직교하는 별개의 축이다 —
 * "메뉴가 보인다"와 "글을 쓸 수 있다"는 다른 문제라 메뉴로는 표현할 수 없다.
 * 여기에 역할이 지정되면 조회자(ROLE_USER)도 그 게시판에 글을 쓸 수 있다.
 */
package egovframework.com.cop.bbs.service;

import java.util.List;

public interface BoardWriteAuthService {

	/** 이 게시판에 글을 쓸 수 있는 역할들. 관리자는 서버가 항상 포함한다. */
	List<String> selectWriteAuthorCodes(String bbsId);

	/** 게시판 저장 시 작성권한(BoardMaster.writeAuthorCodes)을 반영한다. */
	void syncWriteAuthors(BoardMaster boardMaster);

	/** 게시판 삭제·사용중지 시 작성권한을 지운다. */
	void removeWriteAuthors(String bbsId);
}
