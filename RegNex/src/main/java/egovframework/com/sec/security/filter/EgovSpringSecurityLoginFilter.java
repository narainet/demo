package egovframework.com.sec.security.filter;

import java.io.IOException;
import java.util.Map;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.egovframe.rte.psl.dataaccess.util.EgovMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;
import org.springframework.web.context.support.WebApplicationContextUtils;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.config.EgovLoginConfig;
import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.uat.uia.service.EgovLoginService;
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
 *  수정일               수정자        	 수정내용
 *  ----------   --------   ---------------------------
 *  2011.08.29   서준식            최초생성
 *  2011.12.12   유지보수          사용자 로그인 정보 간섭 가능성 문제(멤버 변수 EgovUserDetails userDetails를 로컬변수로 변경)
 *  2014.03.07   유지보수          로그인된 상태에서 다시 로그인 시 미처리 되는 문제 수정 (로그인 처리 URL 파라미터화)
 *  2017.03.03   조성원 	       시큐어코딩(ES)-부적절한 예외 처리[CWE-253, CWE-440, CWE-754]
 *  2017.07.10   장동한            실행환경 v3.7(Spring Security 4.0.3 적용)
 *  2017.07.21   장동한 		   로그인인증제한 작업
 *  2020.06.25   신용호 		   로그인 메시지 처리 수정
 *
 *  </pre>
 */

public class EgovSpringSecurityLoginFilter implements Filter {

	private FilterConfig config;

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovSpringSecurityLoginFilter.class);

	public void destroy() {
	}

	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {

		LOGGER.info("EgovSpringSecurityLoginFilter called...");

		// 로그인 URL
		String loginURL = config.getInitParameter("loginURL");
		loginURL = loginURL.replaceAll("\r", "").replaceAll("\n", "");

		String loginProcessURL = config.getInitParameter("loginProcessURL");
		loginProcessURL = loginProcessURL.replaceAll("\r", "").replaceAll("\n", "");

		ApplicationContext act = WebApplicationContextUtils.getRequiredWebApplicationContext(config.getServletContext());
		EgovLoginService loginService = (EgovLoginService) act.getBean("loginService");
		EgovLoginConfig egovLoginConfig = (EgovLoginConfig) act.getBean("egovLoginConfig");
		
		EgovMessageSource egovMessageSource = (EgovMessageSource) act.getBean("egovMessageSource");

		HttpServletRequest httpRequest = (HttpServletRequest) request;
		HttpServletResponse httpResponse = (HttpServletResponse) response;
		HttpSession session = httpRequest.getSession();
		//String isLocallyAuthenticated = (String)session.getAttribute("isLocallyAuthenticated");
		String isRemotelyAuthenticated = (String) session.getAttribute("isRemotelyAuthenticated");

		String requestURL = ((HttpServletRequest) request).getRequestURI();

		//스프링 시큐리티 인증이 처리 되었는지 EgovUserDetailsHelper.getAuthenticatedUser() 메서드를 통해 확인한다.
		//context-common.xml 빈 설정에 egovUserDetailsSecurityService를 등록 해서 사용해야 정상적으로 동작한다.
		if (EgovUserDetailsHelper.getAuthenticatedUser() == null || requestURL.contains(loginProcessURL)) {

			if (isRemotelyAuthenticated != null && isRemotelyAuthenticated.equals("true")) {
				try {
					//세션 토큰 정보를 가지고 DB로부터 사용자 정보를 가져옴
					LoginVO loginVO = (LoginVO) session.getAttribute("loginVOForDBAuthentication");
					loginVO = loginService.actionLoginByEsntlId(loginVO);

					if (loginVO != null && loginVO.getId() != null && !loginVO.getId().equals("")) {
						
						String userIp = EgovClntInfo.getClntIP(httpRequest);
                        loginVO.setIp(userIp);
                        
						//세션 로그인
						session.setAttribute("loginVO", loginVO);

						//로컬 인증결과 세션에 저장
						session.setAttribute("isLocallyAuthenticated", "true");

						//스프링 시큐리티 로그인
						//httpResponse.sendRedirect(httpRequest.getContextPath() + "/j_spring_security_check?j_username=" + loginVO.getUserSe() + loginVO.getId() + "&j_password=" + loginVO.getUniqId());
						
						UsernamePasswordAuthenticationFilter springSecurity = null;

						Map<String, UsernamePasswordAuthenticationFilter> beans = act.getBeansOfType(UsernamePasswordAuthenticationFilter.class);
						if (beans.size() > 0) {
							springSecurity = (UsernamePasswordAuthenticationFilter) beans.values().toArray()[0];
							springSecurity.setUsernameParameter("egov_security_username");
							springSecurity.setPasswordParameter("egov_security_password");
							springSecurity.setRequiresAuthenticationRequestMatcher(new AntPathRequestMatcher(request.getServletContext().getContextPath() +"/egov_security_login", "POST"));
						} else {
							LOGGER.error("No AuthenticationProcessingFilter");
							throw new IllegalStateException("No AuthenticationProcessingFilter");
						}
						//springSecurity.setContinueChainBeforeSuccessfulAuthentication(false);	// false 이면 chain 처리 되지 않음.. (filter가 아닌 경우 false로...)

						LOGGER.debug("before security filter call....");
						springSecurity.doFilter(new RequestWrapperForSecurity(httpRequest, loginVO.getUserSe() + loginVO.getId(), loginVO.getUniqId()), httpResponse, chain);
						LOGGER.debug("after security filter call....");

					}
				//2017.03.03 	조성원 	시큐어코딩(ES)-부적절한 예외 처리[CWE-253, CWE-440, CWE-754]
				} catch(IllegalArgumentException e) {
					LOGGER.error("[IllegalArgumentException] Try/Catch...usingParameters Runing : "+ e.getMessage());
				} catch(Exception e) {
					LOGGER.error("["+e.getClass()+"] Try/Catch...Exception : " + e.getMessage());
				}

			} else if (isRemotelyAuthenticated == null) {
				if (requestURL.contains(loginProcessURL)) {

					String password = httpRequest.getParameter("password");
					// 아이디의 공백 제거 — 붙여넣기/자동완성으로 앞뒤 공백이 섞여 들어오면 계정 조회가
					// 실패해 "로그인 정보가 올바르지 않습니다" 만 뜬다(고객 테스트 2026-07-29).
					// 화면에서도 막지만, 실제 인증 경로가 이 필터라 서버측을 정본으로 둔다.
					// (비밀번호는 공백이 유효 문자일 수 있으므로 손대지 않는다.)
					String id = stripSpaces(httpRequest.getParameter("id"));

					// 보안점검 후속 조치(Password 검증)
					if ((id == null || "".equals(id)) && (password == null || "".equals(password))) {
						// 포워드 대신 PRG 리다이렉트 — SiteMesh(REQUEST 전용) 데코 적용 + 주소창 정상화 (#1)
						redirectToLoginForm(httpRequest, httpResponse, loginURL, "");
						return;
					}
					else if (password == null || password.equals("") || password.length() < 8 || password.length() > 20) {
						redirectToLoginForm(httpRequest, httpResponse, loginURL,
								egovMessageSource.getMessage("fail.common.login.password", request.getLocale()));
						return;
					}

					LoginVO loginVO = new LoginVO();

					loginVO.setId(id);   // 공백 제거본 (위 stripSpaces)
					loginVO.setPassword(password);
					// USER_SE 선택 제거: 입력 아이디로 COMVNUSERMASTER 에서 회원구분 자동 판별.
					// (이후 잠금/인증 분기는 이 값으로 내부 처리. 미존재 아이디면 null → 로그인 실패로 귀결)
					String resolvedUserSe = null;
					try {
						resolvedUserSe = loginService.selectUserSeByUserId(loginVO.getId());
					} catch (Exception e) {
						LOGGER.error("USER_SE 자동판별 실패: {}", e.getMessage());
					}
					loginVO.setUserSe(resolvedUserSe);

					//------------------------------------------------------------------
				    // 로그인시 로그인인증제한 활성화 처리
				    //------------------------------------------------------------------
				    if(egovLoginConfig.isLock()){
				        try{
				             Map<?,?> mapLockUserInfo = (EgovMap)loginService.selectLoginIncorrect(loginVO);
				             if(mapLockUserInfo != null){		
				                //로그인인증제한 처리
				                String sLoginIncorrectCode = loginService.processLoginIncorrect(loginVO, mapLockUserInfo);
				                if(!sLoginIncorrectCode.equals("E")){
				                    String lockMsg = "";
				                    if(sLoginIncorrectCode.equals("L")){
				                        lockMsg = egovMessageSource.getMessageArgs("fail.common.loginIncorrect", new Object[] {egovLoginConfig.getLockCount(),request.getLocale()});
				                    }else if(sLoginIncorrectCode.equals("C")){
				                        lockMsg = egovMessageSource.getMessage("fail.common.login",request.getLocale());
				                    }
				                    redirectToLoginForm(httpRequest, httpResponse, loginURL, lockMsg);
				                    return;
				                }
				            }else{
				                redirectToLoginForm(httpRequest, httpResponse, loginURL,
				                        egovMessageSource.getMessage("fail.common.login",request.getLocale()));
				                return;
				            }
				        } catch(IllegalArgumentException e) {
				            LOGGER.error("[IllegalArgumentException] : "+ e.getMessage());
				        } catch(Exception ex) {
							LOGGER.error("Login Exception : {}", ex.getCause(), ex);
							redirectToLoginForm(httpRequest, httpResponse, loginURL,
									egovMessageSource.getMessage("fail.common.login",request.getLocale()));
							return;
				        }
				    }

					//------------------------------------------------------------------
				    // 사용자 로그인 처리
				    //------------------------------------------------------------------
					try {
						//사용자 입력 id, password로 DB 인증을 실행함
						loginVO = loginService.actionLogin(loginVO);
						//사용자 IP 기록
						String userIp = EgovClntInfo.getClntIP(httpRequest);
                        loginVO.setIp(userIp);
						if (loginVO != null && loginVO.getId() != null && !loginVO.getId().equals("")) {

							// 휴면계정 게이트(2026-07-28) — Globals.DormantDay(일, 0/미설정=비활성) 초과 미이용 시 차단.
							// security 인증모드의 유일한 로그인 성공 지점이 여기라 필터에 둔다(컨트롤러 actionLogin 은 비보안 모드 폴백).
							// 마지막 활동 = 성공 로그인·비밀번호 변경·가입 중 최근. 비밀번호 재설정(변경일 갱신)이 곧 해제.
							// 비밀번호 검증을 통과한 계정에만 판정(계정 존재 노출 없음). 판정 실패(예외)는 게이트 미적용으로 완화.
							int dormantDay = 0;
							try {
								String sDormant = EgovProperties.getProperty("Globals.DormantDay");
								dormantDay = (sDormant == null || sDormant.trim().isEmpty()) ? 0 : Integer.parseInt(sDormant.trim());
							} catch (Exception e) {
								dormantDay = 0;
							}
							if (dormantDay > 0) {
								boolean dormant = false;
								try {
									dormant = loginService.selectDormantDays(loginVO) > dormantDay;
								} catch (Exception e) {
									LOGGER.error("휴면계정 판정 실패(게이트 미적용): {}", e.getMessage());
								}
								if (dormant) {
									redirectToLoginForm(httpRequest, httpResponse, loginURL,
											"장기 미이용(" + dormantDay + "일 초과)으로 휴면 상태인 계정입니다. "
											+ "'아이디/비밀번호 찾기'로 비밀번호를 재설정하면 다시 이용할 수 있습니다.");
									return;
								}
							}

							//세션 로그인
							session.setAttribute("loginVO", loginVO);

							//로컬 인증결과 세션에 저장
							session.setAttribute("isLocallyAuthenticated", "true");

							// 사용자 활동 로그 — 로그인 성공 적재. security 인증모드는 이 필터가 actionLogin.do 를
							// 완전 대체(컨트롤러 미실행)하므로 여기가 유일한 성공 지점. 실패는 서비스가 삼킴.
							try {
								((narainet.rlms.stats.service.StatsService) act.getBean("statsService"))
										.recordAction("로그인", null, null, null, loginVO.getId(), loginVO.getName(), userIp);
							} catch (Exception ignore) { }

							//스프링 시큐리티 로그인
							//httpResponse.sendRedirect(httpRequest.getContextPath() + "/j_spring_security_check?j_username=" + loginVO.getUserSe() + loginVO.getId() + "&j_password=" + loginVO.getUniqId());

							UsernamePasswordAuthenticationFilter springSecurity = null;

							Map<String, UsernamePasswordAuthenticationFilter> beans = act.getBeansOfType(UsernamePasswordAuthenticationFilter.class);
							if (beans.size() > 0) {
								springSecurity = (UsernamePasswordAuthenticationFilter) beans.values().toArray()[0];
								springSecurity.setUsernameParameter("egov_security_username");
								springSecurity.setPasswordParameter("egov_security_password");
								springSecurity.setRequiresAuthenticationRequestMatcher(new AntPathRequestMatcher(request.getServletContext().getContextPath() +"/egov_security_login", "POST"));
							} else {
								LOGGER.error("No AuthenticationProcessingFilter");
								throw new IllegalStateException("No AuthenticationProcessingFilter");
							}
							//springSecurity.setContinueChainBeforeSuccessfulAuthentication(false);	// false 이면 chain 처리 되지 않음.. (filter가 아닌 경우 false로...)

							LOGGER.debug("before security filter call....");
							springSecurity.doFilter(new RequestWrapperForSecurity(httpRequest, loginVO.getUserSe() + loginVO.getId(), loginVO.getUniqId()), httpResponse, chain);
							LOGGER.debug("after security filter call....");

						} else {
							//사용자 정보가 없는 경우 로그인 화면으로 redirect 시킴
							redirectToLoginForm(httpRequest, httpResponse, loginURL,
									egovMessageSource.getMessage("fail.common.login",request.getLocale()));
							return;

						}
			        } catch(IllegalArgumentException e) {
			            LOGGER.error("[IllegalArgumentException] : "+ e.getMessage());
					} catch (Exception ex) {
						//DB인증 예외가 발생할 경우 로그인 화면으로 redirect 시킴
						LOGGER.error("Login Exception : {}", ex.getCause(), ex);
						redirectToLoginForm(httpRequest, httpResponse, loginURL,
								egovMessageSource.getMessage("fail.common.login",request.getLocale()));
						return;

					}
					return;
				}

			}
		}

		chain.doFilter(request, response);
	}

	public void init(FilterConfig filterConfig) throws ServletException {
		this.config = filterConfig;
	}

	/**
	 * 로그인 실패/검증 실패 시 — RequestDispatcher.forward 대신 PRG 리다이렉트(302)로 로그인 폼으로 보낸다. (#1)
	 *
	 * forward 는 SiteMesh 데코레이터 필터가 web.xml 에서 REQUEST 디스패처만 매핑되어 데코하지 않는다.
	 * 그 결과 (1)주소창이 actionLogin.do 에 머물고 (2)plain 데코(KRDS 스타일)가 빠진 맨몸 화면이 떠
	 * "화면은 다르지만 로그인은 됨" 증상이 난다. 리다이렉트면 브라우저가 egovLoginUsr.do 를 새 REQUEST 로
	 * 다시 받아 데코·주소창이 정상화된다. 실패 메시지는 세션에 1회성으로 담아 보낸다
	 * (쿼리파라미터로 붙이면 주소창에 한글 메시지가 그대로 노출되므로). 컨트롤러 loginUsrView 가
	 * 세션에서 읽어 모델에 담고 제거한다.
	 */
	private void redirectToLoginForm(HttpServletRequest req, HttpServletResponse res,
			String loginURL, String msg) throws IOException {
		if (msg != null && !msg.isEmpty()) {
			req.getSession().setAttribute("loginMessage", msg);
		}
		res.sendRedirect(req.getContextPath() + loginURL);
	}

	/** 아이디에서 모든 공백류(스페이스·탭·개행·NBSP)를 제거. null 은 null 그대로. */
	private static String stripSpaces(String v) {
		if (v == null) {
			return null;
		}
		return v.replaceAll("[\\s\\u00A0]", "");
	}
}

class RequestWrapperForSecurity extends HttpServletRequestWrapper {
	private String username = null;
	private String password = null;

	public RequestWrapperForSecurity(HttpServletRequest request, String username, String password) {
		super(request);

		this.username = username;
		this.password = password;
	}
	
	@Override
	public String getServletPath() {
		return ((HttpServletRequest) super.getRequest()).getContextPath() + "/egov_security_login";
	}

	@Override
	public String getRequestURI() {
		return ((HttpServletRequest) super.getRequest()).getContextPath() + "/egov_security_login";
	}

	@Override
	public String getParameter(String name) {
		if (name.equals("egov_security_username")) {
			return username;
		}

		if (name.equals("egov_security_password")) {
			return password;
		}

		return super.getParameter(name);
	}
}
