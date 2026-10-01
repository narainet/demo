/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/BoardWriteGuard.java
 *
 * 게시판별 작성권한 강제.
 *
 * 열람권한(BoardReadGuard)은 그 게시판이 걸린 메뉴의 역할매핑이 원천이지만, 작성권한은 별개의 축이다
 * (COMTNBBSWRITEAUTHOR). 이 표에 역할이 지정되면 조회자(ROLE_USER)도 그 게시판에 글을 쓸 수 있다.
 *
 * 작성은 열람을 전제한다 — 읽지 못하는 게시판에 쓰게 두면 목록·상세가 403 인데 글만 들어가는 모순이 생긴다.
 * 역할 계층(ADMIN > APPROVER > EDITOR > USER)은 열람과 동일하게 적용한다.
 */
package egovframework.com.cop.bbs.service;

import java.util.Collections;
import java.util.List;
import java.util.Set;

import javax.annotation.Resource;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Component;

@Component("boardWriteGuard")
public class BoardWriteGuard {

	private static final String ROLE_ADMIN = "ROLE_ADMIN";

	@Resource(name = "boardReadGuard")
	private BoardReadGuard boardReadGuard;

	@Resource(name = "boardWriteAuthService")
	private BoardWriteAuthService boardWriteAuthService;

	/** 작성 가능 여부. 관리자는 항상 통과. 작성권한이 하나도 없는 게시판은 관리자만 쓸 수 있다. */
	public boolean canWrite(String bbsId) {
		if (bbsId == null || bbsId.trim().isEmpty() || !boardReadGuard.canRead(bbsId)) {
			return false;
		}
		Set<String> myRoles = boardReadGuard.currentReachableRoles();
		if (myRoles.contains(ROLE_ADMIN)) {
			return true;
		}
		List<String> allowed = boardWriteAuthService.selectWriteAuthorCodes(bbsId.trim());
		return !allowed.isEmpty() && !Collections.disjoint(allowed, myRoles);
	}

	/** 작성 권한 강제 — 없으면 AccessDeniedException */
	public void assertWritable(String bbsId) {
		if (!canWrite(bbsId)) {
			throw new AccessDeniedException("이 게시판에 글을 쓸 권한이 없습니다.");
		}
	}
}
