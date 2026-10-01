/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/web/BoardReadInterceptor.java
 *
 * 사용자 게시판 동선(/cop/bbs/user, /cop/cmt/user, /cop/stf/user)의 게시판별 접근 권한 검사.
 *   · 모든 요청  : 열람권한(BoardReadGuard) — 메뉴 역할매핑이 원천.
 *   · 쓰기 요청  : 작성권한(BoardWriteGuard) — COMTNBBSWRITEAUTHOR 가 원천. 열람을 전제한다.
 *
 * 컨트롤러마다 가드를 부르면 엔드포인트가 늘 때 빠뜨리기 쉽다(댓글·만족도만 해도 JSON 4종씩).
 * 세 접두 전체를 한 곳에서 막아, 새로 추가되는 URL 도 자동으로 보호되게 한다.
 *
 * bbsId 가 없는 요청은 통과시킨다 — 게시판이 특정되지 않아 열람할 대상이 없고, 댓글·만족도의
 * 모든 읽기 쿼리가 BBS_ID 로 스코프되어 nttId 만으로는 남의 게시판 내용을 못 읽는다.
 * (이 접두에 nttId 단독 조회 엔드포인트를 추가하면 이 전제가 깨진다 — 그때는 여기도 함께 고쳐야 한다.)
 *
 * ★거부 응답을 직접 만든다. AccessDeniedException 을 던지면 이제 403 + accessDenied 화면으로 나가지만
 *   (egov-com-servlet.xml 의 excludedExceptions, 2026-07-10), 이 접두에는 그 화면을 쓸 수 없는 두 경우가 있다:
 *   AJAX(JSON 본문이어야 함)와 c:import INCLUDE 조각(forward 하면 IllegalStateException).
 *   그래서 응답 형태를 여기서 직접 고른다.
 */
package egovframework.com.cop.bbs.web;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.util.WebUtils;

import egovframework.com.cop.bbs.service.BoardReadGuard;
import egovframework.com.cop.bbs.service.BoardWriteGuard;

public class BoardReadInterceptor implements HandlerInterceptor {

	private static final Logger LOGGER = LoggerFactory.getLogger(BoardReadInterceptor.class);

	/** 표준 접근권한 오류 화면. 뷰리졸버를 거치지 않고 직접 forward 한다. */
	private static final String ACCESS_DENIED_JSP = "/WEB-INF/jsp/egovframework/com/cmm/error/accessDenied.jsp";

	private static final String READ_DENY_MESSAGE = "이 게시판은 열람 권한이 제한되어 있습니다.";
	private static final String WRITE_DENY_MESSAGE = "이 게시판에 글을 쓸 권한이 없습니다.";

	/** 사용자 쓰기 동선(/cop/bbs/user/*)의 마지막 경로 조각. 여기에 걸리면 작성권한까지 요구한다. */
	private static final Set<String> WRITE_ENDPOINTS = Collections.unmodifiableSet(new HashSet<String>(Arrays.asList(
			"insertArticleView.do", "insertArticle.do",
			"updateArticleView.do", "updateArticle.do",
			"deleteArticle.do",
			"replyArticleView.do", "replyArticle.do")));

	private static final String BBS_USER_PREFIX = "/cop/bbs/user/";

	@Resource(name = "boardReadGuard")
	private BoardReadGuard boardReadGuard;

	@Resource(name = "boardWriteGuard")
	private BoardWriteGuard boardWriteGuard;

	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
			throws Exception {
		String bbsId = request.getParameter("bbsId");
		if (bbsId == null || bbsId.trim().isEmpty()) {
			return true;
		}
		bbsId = bbsId.trim();

		if (!boardReadGuard.canRead(bbsId)) {
			return deny(request, response, bbsId, READ_DENY_MESSAGE, "열람");
		}
		if (isUserWriteEndpoint(request) && !boardWriteGuard.canWrite(bbsId)) {
			return deny(request, response, bbsId, WRITE_DENY_MESSAGE, "작성");
		}
		return true;
	}

	// ── 내부 ───────────────────────────────────────────────────────

	private boolean deny(HttpServletRequest request, HttpServletResponse response, String bbsId, String message,
			String what) throws Exception {
		LOGGER.warn("게시판 {} 거부: bbsId={} uri={}", what, bbsId, request.getRequestURI());
		response.setStatus(HttpServletResponse.SC_FORBIDDEN);

		if (isJsonEndpoint(request)) {
			// 키는 'msg' — 댓글·만족도 조각의 JS 가 d.msg 를 읽고, 컨트롤러 JSON 오류도 같은 키를 쓴다.
			response.setContentType("application/json;charset=UTF-8");
			response.getWriter().write("{\"ok\":false,\"msg\":\"" + message + "\"}");
		} else if (WebUtils.isIncludeRequest(request)) {
			// 댓글·만족도 조각은 상세 JSP 가 c:import(=INCLUDE)로 부른다.
			// INCLUDE 안에서 forward 하면 IllegalStateException 이므로 아무것도 쓰지 않고 멈춘다.
			// (정상 흐름에선 부모 상세가 같은 bbsId 로 이미 통과했으므로 여기 오지 않는다 —
			//  부모 통과 직후 관리자가 역할을 바꾸는 경합에서만 도달한다.)
			LOGGER.warn("INCLUDE 조각 거부 — 본문 없이 종료: {}", request.getRequestURI());
		} else {
			request.getRequestDispatcher(ACCESS_DENIED_JSP).forward(request, response);
		}
		return false;
	}

	/** 사용자 동선의 쓰기 URL 인가. 관리 동선(/cop/bbs/*)은 URL 보안이 ADMIN 전용으로 막는다. */
	private boolean isUserWriteEndpoint(HttpServletRequest request) {
		String uri = request.getRequestURI();
		if (uri == null) {
			return false;
		}
		int at = uri.indexOf(BBS_USER_PREFIX);
		if (at < 0) {
			return false;
		}
		return WRITE_ENDPOINTS.contains(uri.substring(at + BBS_USER_PREFIX.length()));
	}

	/** 댓글·만족도의 AJAX 엔드포인트는 항상 *Json.do 로 끝난다. */
	private boolean isJsonEndpoint(HttpServletRequest request) {
		String uri = request.getRequestURI();
		return uri != null && uri.endsWith("Json.do");
	}
}
