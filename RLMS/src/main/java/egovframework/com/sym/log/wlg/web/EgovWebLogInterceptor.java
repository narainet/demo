package egovframework.com.sym.log.wlg.web;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.sym.log.wlg.service.EgovWebLogService;
import egovframework.com.sym.log.wlg.service.WebLog;

/**
 * @Class Name : EgovWebLogInterceptor.java
 * @Description : 웹로그 생성을 위한 인터셉터 클래스
 * @Modification Information
 *
 *    수정일        수정자         수정내용
 *    -------      -------     -------------------
 *    2009. 3. 9.   이삼섭         최초생성
 *    2011. 7. 1.   이기하         패키지 분리(sym.log -> sym.log.wlg)
 *    2026. 7.20.   RLMS         접속통계 확장 — 폴링/JSON·forward 노이즈 제외,
 *                               기기구분/브라우저(User-Agent 파싱)·세션ID 동반 적재.
 *
 * @author 공통 서비스 개발팀 이삼섭
 * @since 2009. 3. 9.
 * @version
 * @see
 *
 */
public class EgovWebLogInterceptor implements HandlerInterceptor {

	private static final org.slf4j.Logger LOGGER = org.slf4j.LoggerFactory.getLogger(EgovWebLogInterceptor.class);

	@Resource(name="EgovWebLogService")
	private EgovWebLogService webLogService;

	/**
	 * 웹 로그정보를 생성한다.
	 *
	 * @param HttpServletRequest request, HttpServletResponse response, Object handler
	 * @return
	 * @throws Exception
	 */
	@Override
	public void postHandle(HttpServletRequest request,
			HttpServletResponse response, Object handler, ModelAndView modeAndView) throws Exception {

		String reqURL = request.getRequestURI();
		if (reqURL == null) {
			return;
		}
		String ctx = request.getContextPath();
		if (ctx != null && !ctx.isEmpty() && reqURL.startsWith(ctx)) {
			reqURL = reqURL.substring(ctx.length());
		}
		// 페이지뷰가 아닌 요청은 적재하지 않는다 — 배지 폴링 등 *Json.do AJAX 가
		// 전체 로그의 3/4 을 차지해 접속통계를 무의미하게 만들었음(2026-07-20).
		// forward 된 JSP 내부경로·validator.do(검증 JS 로더)도 동일.
		if (reqURL.endsWith("Json.do") || reqURL.startsWith("/WEB-INF/") || reqURL.equals("/validator.do")) {
			return;
		}

		WebLog webLog = new WebLog();
		String uniqId = "";

    	/* Authenticated  */
        Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
    	if(isAuthenticated.booleanValue()) {
			LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
			uniqId = (user == null || user.getUniqId() == null) ? "" : user.getUniqId();
    	}

		webLog.setUrl(reqURL);
		webLog.setRqesterId(uniqId);
		webLog.setRqesterIp(request.getRemoteAddr());

		String ua = request.getHeader("User-Agent");
		webLog.setDviceSe(deviceOf(ua));
		webLog.setBrowserNm(browserOf(ua));
		HttpSession session = request.getSession(false);   // 로깅 목적으로 세션을 새로 만들지는 않음
		// 세션ID 원문(JSESSIONID)은 그 자체가 하이재킹 재료 — 방문 구분 용도라 단방향 해시로 적재
		webLog.setSesnId(session == null ? "" : hashSessionId(session.getId()));

		try {
			webLogService.logInsertWebLog(webLog);
		} catch (Exception e) {
			// 로그 적재 실패가 이미 성공한 화면 렌더를 오류 페이지로 바꿔선 안 됨
			LOGGER.warn("웹로그 적재 실패(무시): {}", e.getMessage());
		}

	}

	/** JSESSIONID → SHA-256 앞 160비트 hex(40자). 실패 시 빈 문자열. */
	private static String hashSessionId(String id) {
		try {
			java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
			byte[] d = md.digest(id.getBytes("UTF-8"));
			StringBuilder sb = new StringBuilder(40);
			for (int i = 0; i < 20; i++) {
				sb.append(String.format("%02x", d[i]));
			}
			return sb.toString();
		} catch (Exception e) {
			return "";
		}
	}

	/** User-Agent → 기기 구분. 판정 불가는 ETC. */
	private static String deviceOf(String ua) {
		if (ua == null || ua.trim().isEmpty()) {
			return "ETC";
		}
		String u = ua.toLowerCase();
		// 'bot' 단독 부분일치는 기기 브랜드(예: CUBOT 폰)를 오판 — 토큰 형태(bot/)와 대표 봇명만
		if (u.contains("bot/") || u.contains("googlebot") || u.contains("bingbot")
				|| u.contains("crawler") || u.contains("spider")) {
			return "BOT";
		}
		// iPad(구형 UA)·안드로이드 태블릿(Mobile 토큰 없음)을 모바일보다 먼저 판정
		if (u.contains("ipad") || u.contains("tablet") || (u.contains("android") && !u.contains("mobile"))) {
			return "TABLET";
		}
		if (u.contains("mobi") || u.contains("iphone") || u.contains("ipod")) {
			return "MOBILE";
		}
		return "PC";
	}

	/** User-Agent → 브라우저명. Whale/Edge/Samsung/Opera 는 UA 에 chrome 토큰도 있어 먼저 판정. */
	private static String browserOf(String ua) {
		if (ua == null || ua.trim().isEmpty()) {
			return "기타";
		}
		String u = ua.toLowerCase();
		if (u.contains("whale")) {
			return "Whale";
		}
		if (u.contains("edg/") || u.contains("edge/") || u.contains("edgios") || u.contains("edga")) {
			return "Edge";
		}
		if (u.contains("samsungbrowser")) {
			return "Samsung";
		}
		if (u.contains("opr/") || u.contains("opera")) {
			return "Opera";
		}
		if (u.contains("chrome/") || u.contains("crios")) {
			return "Chrome";
		}
		if (u.contains("firefox") || u.contains("fxios")) {
			return "Firefox";
		}
		if (u.contains("safari")) {
			return "Safari";
		}
		if (u.contains("trident") || u.contains("msie")) {
			return "IE";
		}
		return "기타";
	}
}
