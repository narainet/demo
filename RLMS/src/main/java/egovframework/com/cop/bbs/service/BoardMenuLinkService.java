/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/BoardMenuLinkService.java
 *
 * 게시판을 사용자 메뉴에 노출시키는 연결(프로그램 · 메뉴 · 역할매핑)을 게시판 저장과 함께 관리한다.
 * 이 서비스가 없으면 관리자가 화면 다섯 개를 돌며 bbsId 를 손으로 URL 에 박아야 하고,
 * 접두를 /cop/bbs/user/ 로 쓰지 않으면 조회 역할에 글쓰기·게시판관리까지 열리는 권한상승이 난다.
 */
package egovframework.com.cop.bbs.service;

import java.util.List;
import java.util.Map;

public interface BoardMenuLinkService {

	/** 게시판 열람 URL 접두 — 이 접두여야 L6 파생이 열람 전용 패턴을 만든다. */
	String USER_LIST_URL = "/cop/bbs/user/selectArticleList.do?bbsId=";

	/** 게시판에 연결된 사용자 메뉴. 노출 설정이 없으면 null. */
	BoardMenuVO selectLink(String bbsId);

	/** bbsId → 연결 메뉴. 게시판 목록화면이 노출 상태를 한 번에 그릴 때 쓴다. */
	Map<String, BoardMenuVO> selectLinkMap();

	/** 이 게시판을 열람할 수 있는 역할들. 연결이 없으면 빈 목록(= 관리자 외 접근 불가). */
	List<String> selectReadableAuthorCodes(String bbsId);

	/**
	 * 게시판의 노출 설정(menuExposeAt · menuNm · menuOrdr · menuAuthorCodes)을 메뉴에 반영한다.
	 * 노출이 'Y' 면 프로그램·메뉴·역할매핑을 만들거나 갱신하고, 'N' 이면 연결을 제거한다.
	 */
	void syncLink(BoardMaster boardMaster);

	/** 게시판의 사용자 메뉴 연결을 제거한다(게시판 삭제·사용중지 시). */
	void removeLink(String bbsId);
}
