package egovframework.com.sec.security.filter;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.web.context.support.WebApplicationContextUtils;

import egovframework.com.cmm.LoginVO;
import egovframework.com.sym.log.clg.service.EgovLoginLogService;
import egovframework.com.sym.log.clg.service.LoginLog;
import egovframework.com.utl.sim.service.EgovClntInfo;


/**
 *
 * @author 공통서비스 개발팀 서준식
 * @since 2011. 8. 29.
 * @version 1.0
 * @see
 *
 * <pre>
 * 개정이력(Modification Information)
 *
 *   수정일      수정자          수정내용
 *  -------    --------    ---------------------------
 *  2011. 8. 29.    서준식        최초생성
 *  2017.07.10      장동한       실행환경 v3.7(Spring Security 4.0.3 적용)
 *
 *  </pre>
 */

public class EgovSpringSecurityLogoutFilter implements Filter{

	private FilterConfig config;

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovSpringSecurityLogoutFilter.class);

	public void destroy() {}


	public void doFilter(ServletRequest request, ServletResponse response,
			FilterChain chain) throws IOException, ServletException {

		HttpServletRequest httpRequest = (HttpServletRequest) request;
		LOGGER.debug(httpRequest.getRequestURI());

		HttpSession session = httpRequest.getSession();
		logLogout(httpRequest, session);   // 세션의 loginVO 를 지우기 전에 기록해야 누가 나갔는지 남는다

		session.setAttribute("loginVO", null);
		((HttpServletResponse)response).sendRedirect(httpRequest.getContextPath() + "/egov_security_logout");

	}

	/**
	 * 로그아웃 접속로그(CONECT_MTHD='O') 적재.
	 *
	 * 표준은 EgovLoginLogAspect.logLogout 이 EgovLoginController.actionLogout 실행 시 남기도록 돼 있지만,
	 * security 인증모드에서는 /uat/uia/actionLogout.do 를 이 필터가 가로채 컨트롤러가 아예 실행되지 않는다.
	 * 그래서 로그아웃 로그가 한 건도 쌓이지 않아 접속로그의 접속방식이 늘 'I' 뿐이었다(2026-07-29 발견).
	 * 로그인 쪽이 같은 이유로 RlmsHomeController(/main.do)에서 직접 남기는 것과 같은 보정이다.
	 *
	 * 이 URL 은 context-security.xml 에서 security="none" 이라 SecurityContext 가 비어 있을 수 있어,
	 * 사용자 식별은 EgovUserDetailsHelper 가 아니라 세션의 loginVO 에서 가져온다.
	 * 적재 실패가 로그아웃 자체를 막아선 안 되므로 예외는 삼킨다.
	 */
	private void logLogout(HttpServletRequest request, HttpSession session) {
		try {
			LoginVO user = (LoginVO) session.getAttribute("loginVO");
			if (user == null || user.getUniqId() == null || user.getUniqId().isEmpty()) {
				return;   // 이미 로그아웃됐거나 세션이 만료된 요청 — 남길 주체가 없다
			}
			ApplicationContext act =
					WebApplicationContextUtils.getRequiredWebApplicationContext(config.getServletContext());
			EgovLoginLogService loginLogService = (EgovLoginLogService) act.getBean("EgovLoginLogService");

			LoginLog log = new LoginLog();
			log.setLoginId(user.getUniqId());   // CONECT_ID = ESNTL_ID
			log.setLoginIp(EgovClntInfo.getClntIP(request));
			log.setLoginMthd("O");              // 로그인:I, 로그아웃:O
			log.setErrOccrrAt("N");
			log.setErrorCode("");
			loginLogService.logInsertLoginLog(log);
		} catch (Exception e) {
			LOGGER.warn("로그아웃 접속로그 적재 실패(무시): {}", e.getMessage());
		}
	}

	public void init(FilterConfig filterConfig) throws ServletException {

		this.config = filterConfig;

	}
}
