package egovframework.com.uat.uia.web;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import egovframework.com.cmm.EgovComponentChecker;
import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.annotation.IncludedInfo;
import egovframework.com.cmm.config.EgovLoginConfig;
import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.service.Globals;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.uat.uia.service.EgovLoginService;
import egovframework.com.utl.fcc.service.EgovStringUtil;
import egovframework.com.utl.sim.service.EgovClntInfo;

/*
import com.gpki.gpkiapi.cert.X509Certificate;
import com.gpki.servlet.GPKIHttpServletRequest;
import com.gpki.servlet.GPKIHttpServletResponse;
*/

/**
 * 일반 로그인, 인증서 로그인을 처리하는 컨트롤러 클래스
 * @author 공통서비스 개발팀 박지욱
 * @since 2009.03.06
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *
 *  수정일		수정자		수정내용
 *  ----------	--------	---------------------------
 *  2009.03.06	박지욱		최초 생성
 *  2011.08.26	정진오		IncludedInfo annotation 추가
 *  2011.09.07	서준식		스프링 시큐리티 로그인 및 SSO 인증 로직을 필터로 분리
 *  2011.09.25	서준식		사용자 관리 컴포넌트 미포함에 대한 점검 로직 추가
 *  2011.09.27	서준식		인증서 로그인시 스프링 시큐리티 사용에 대한 체크 로직 추가
 *  2011.10.27	서준식		아이디 찾기 기능에서 사용자 리름 공백 제거 기능 추가
 *  2017.07.21	장동한		로그인인증제한 작업
 *  2018.10.26	신용호		로그인 화면에 message 파라미터 전달 수정
 *  2019.10.01	정진오		로그인 인증세션 추가
 *  2020.06.25	신용호		로그인 메시지 처리 수정
 *  2021.01.15	신용호		로그아웃시 권한 초기화 추가 : session 모드 actionLogout()
 *  2021.05.30	정진오		디지털원패스 처리하기 위해 로그인 화면에 인증방식 전달
 *  2022.11.11	김혜준		시큐어코딩 처리
 *  2023.06.09	김신해		NSR 보안조치 (GPKI 인증서 등록 OOB 방지)
 *  2024.10.29	LeeBaekHaeng	불필요 형변환 제거 (request.getParameter("loginMessage"); loginService.selectLoginIncorrect(loginVO);)

 *  
 *  </pre>
 */
@Controller
public class EgovLoginController {

	/** EgovLoginService */
	@Resource(name = "loginService")
	private EgovLoginService loginService;

	/** EgovMessageSource */
	@Resource(name = "egovMessageSource")
	EgovMessageSource egovMessageSource;

	@Resource(name = "egovLoginConfig")
	EgovLoginConfig egovLoginConfig;

	/** log */
	private static final Logger LOGGER = LoggerFactory.getLogger(EgovLoginController.class);

	/**
	 * 로그인 화면으로 들어간다
	 * @param vo - 로그인후 이동할 URL이 담긴 LoginVO
	 * @return 로그인 페이지
	 * @exception Exception
	 */
	@IncludedInfo(name = "로그인", listUrl = "/uat/uia/egovLoginUsr.do", order = 10, gid = 10)
	@RequestMapping(value = "/uat/uia/egovLoginUsr.do")
	public String loginUsrView(@ModelAttribute("loginVO") LoginVO loginVO, HttpServletRequest request, HttpServletResponse response, ModelMap model) throws Exception {
		if (EgovComponentChecker.hasComponent("mberManageService")) {
			model.addAttribute("useMemberManage", "true");
		}
				
		//권한체크시 에러 페이지 이동
		String auth_error =  request.getParameter("auth_error") == null ? "" : (String)request.getParameter("auth_error");
		if(auth_error != null && auth_error.equals("1")){
			return "egovframework/com/cmm/error/accessDenied";
		}

		/*
		GPKIHttpServletResponse gpkiresponse = null;
		GPKIHttpServletRequest gpkirequest = null;

		try{

			gpkiresponse=new GPKIHttpServletResponse(response);
		    gpkirequest= new GPKIHttpServletRequest(request);
		    gpkiresponse.setRequest(gpkirequest);
		    model.addAttribute("challenge", gpkiresponse.getChallenge());
		    return "egovframework/com/uat/uia/EgovLoginUsr";

		}catch(Exception e){
		    return "egovframework/com/cmm/egovError";
		}
		*/

		// 2021.05.30, 정진오, 디지털원패스 처리하기 위해 로그인 화면에 인증방식 전달
		String authType = EgovProperties.getProperty("Globals.Auth").trim();
		model.addAttribute("authType", authType);

		// 로그인 실패 메시지 — 보안필터의 PRG 리다이렉트가 세션에 1회성으로 담아 보냄(URL 노출 방지).
		//   파라미터(레거시 호환)도 함께 지원. 읽은 뒤 세션에서 제거해 새로고침 시 재노출 방지.
		String message = request.getParameter("loginMessage");
		if (message == null) {
			HttpSession session = request.getSession(false);
			if (session != null) {
				Object sm = session.getAttribute("loginMessage");
				if (sm != null) { message = sm.toString(); session.removeAttribute("loginMessage"); }
			}
		}
		if (message!=null) model.addAttribute("loginMessage", message);

		return "egovframework/com/uat/uia/EgovLoginUsr";
	}

	/**
	 * 일반(세션) 로그인을 처리한다
	 * @param vo - 아이디, 비밀번호가 담긴 LoginVO
	 * @param request - 세션처리를 위한 HttpServletRequest
	 * @return result - 로그인결과(세션정보)
	 * @exception Exception
	 */
	@RequestMapping(value = "/uat/uia/actionLogin.do")
	public String actionLogin(@ModelAttribute("loginVO") LoginVO loginVO, HttpServletRequest request, ModelMap model,
			RedirectAttributes redirectAttributes) throws Exception {

		// 1. 로그인인증제한 활성화시 
		if( egovLoginConfig.isLock()){
		    Map<?,?> mapLockUserInfo = loginService.selectLoginIncorrect(loginVO);
		    if(mapLockUserInfo != null){			
				//2.1 로그인인증제한 처리
				String sLoginIncorrectCode = loginService.processLoginIncorrect(loginVO, mapLockUserInfo);
				if(!sLoginIncorrectCode.equals("E")){
					if(sLoginIncorrectCode.equals("L")){
						model.addAttribute("loginMessage", egovMessageSource.getMessageArgs("fail.common.loginIncorrect", new Object[] {egovLoginConfig.getLockCount(),request.getLocale()}));
					}else if(sLoginIncorrectCode.equals("C")){
						model.addAttribute("loginMessage", egovMessageSource.getMessage("fail.common.login",request.getLocale()));
					}
					return "redirect:/uat/uia/egovLoginUsr.do";
				}
		    }else{
		    	model.addAttribute("loginMessage", egovMessageSource.getMessage("fail.common.login",request.getLocale()));
		    	return "redirect:/uat/uia/egovLoginUsr.do";
		    }
		}
		
		// 2. 로그인 처리
		LoginVO resultVO = loginService.actionLogin(loginVO);
		String userIp = EgovClntInfo.getClntIP(request);
		resultVO.setIp(userIp);
		
		// 3. 일반 로그인 처리
		// 2022.11.11 시큐어코딩 처리
		if (resultVO.getId() != null && !resultVO.getId().equals("")) {

			// 3-0. 휴면계정 게이트(2026-07-28) — Globals.DormantDay(일, 0/미설정=비활성) 초과 미이용 시 차단.
			// 마지막 활동 = 성공 로그인·비밀번호 변경·가입 중 최근. 비밀번호 재설정(변경일 갱신)이 곧 해제라
			// 별도 해제 화면/컬럼 없이 운영 가능. 비밀번호 검증을 통과한 계정에만 판정(계정 존재 노출 없음).
			int dormantDay = 0;
			try {
				String sDormant = EgovProperties.getProperty("Globals.DormantDay");
				dormantDay = (sDormant == null || sDormant.trim().isEmpty()) ? 0 : Integer.parseInt(sDormant.trim());
			} catch (NumberFormatException e) {
				dormantDay = 0;
			}
			if (dormantDay > 0 && loginService.selectDormantDays(resultVO) > dormantDay) {
				redirectAttributes.addFlashAttribute("loginMessage",
						"장기 미이용(" + dormantDay + "일 초과)으로 휴면 상태인 계정입니다. "
						+ "'아이디/비밀번호 찾기'로 비밀번호를 재설정하면 다시 이용할 수 있습니다.");
				return "redirect:/uat/uia/egovLoginUsr.do";
			}

			// 3-1. 로그인 정보를 세션에 저장
			request.getSession().setAttribute("loginVO", resultVO);
			// 2019.10.01 로그인 인증세션 추가
			request.getSession().setAttribute("accessUser", resultVO.getUserSe().concat(resultVO.getId()));

			return "redirect:/uat/uia/actionMain.do";

		} else {
			model.addAttribute("loginMessage", egovMessageSource.getMessage("fail.common.login",request.getLocale()));
			return "redirect:/uat/uia/egovLoginUsr.do";
		}
	}


	/**
	 * 로그인 후 메인화면으로 들어간다
	 * @param
	 * @return 로그인 페이지
	 * @exception Exception
	 */
	@RequestMapping(value = "/uat/uia/actionMain.do")
	public String actionMain(HttpServletRequest request,ModelMap model) throws Exception {

		// 1. Spring Security 사용자권한 처리
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		if (!isAuthenticated) {
			model.addAttribute("loginMessage", egovMessageSource.getMessage("fail.common.login"));
			return "redirect:/uat/uia/egovLoginUsr.do";
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		
		if (user.getIp().equals(""))
			user.setIp(EgovClntInfo.getClntIP(request));
		
		// 221116	김혜준	2022 시큐어코딩 조치
		LOGGER.debug("User Id : {}", EgovStringUtil.isNullToString(user.getId()));

		/*
		// 2. 메뉴조회
		MenuManageVO menuManageVO = new MenuManageVO();
		menuManageVO.setTmp_Id(user.getId());
		menuManageVO.setTmp_UserSe(user.getUserSe());
		menuManageVO.setTmp_Name(user.getName());
		menuManageVO.setTmp_Email(user.getEmail());
		menuManageVO.setTmp_OrgnztId(user.getOrgnztId());
		menuManageVO.setTmp_UniqId(user.getUniqId());
		List list_headmenu = menuManageService.selectMainMenuHead(menuManageVO);
		model.addAttribute("list_headmenu", list_headmenu);
		*/

		// 3. 메인 페이지 이동
		String main_page = Globals.MAIN_PAGE;

		LOGGER.debug("Globals.MAIN_PAGE > " + Globals.MAIN_PAGE);
		LOGGER.debug("main_page > {}", main_page);

		if (main_page.startsWith("/")) {
			return "forward:" + main_page;
		} else {
			return main_page;
		}

		/*
		if (main_page != null && !main_page.equals("")) {

			// 3-1. 설정된 메인화면이 있는 경우
			return main_page;

		} else {

			// 3-2. 설정된 메인화면이 없는 경우
			if (user.getUserSe().equals("USR")) {
				return "egovframework/com/EgovMainView";
			} else {
				return "egovframework/com/EgovMainViewG";
			}
		}
		*/
	}

	/**
	 * 로그아웃한다.
	 * @return String
	 * @exception Exception
	 */
	@RequestMapping(value = "/uat/uia/actionLogout.do")
	public String actionLogout(HttpServletRequest request, HttpServletResponse response) throws Exception {

		// Spring Security 인증을 실제로 해제한다.
		//   - 화면 인증 판정(rlmsAuthenticated)은 EgovUserDetailsHelper.isAuthenticated() =
		//     SecurityContext 를 보므로, 세션의 loginVO 만 비우면 로그아웃이 안 됨.
		//   - SecurityContextLogoutHandler 가 SecurityContext clear + 세션 무효화(동시접속 슬롯 반환 포함) 수행.
		Authentication auth = SecurityContextHolder.getContext().getAuthentication();
		if (auth != null) {
			new SecurityContextLogoutHandler().logout(request, response, auth);
		}
		SecurityContextHolder.clearContext();
		request.getSession().setAttribute("loginVO", null);
		request.getSession().setAttribute("accessUser", null);

		// 로그아웃 성공 후 로그인 화면으로 (context-security.xml logoutSuccessUrl 과 동일).
		//   기존 redirect:/EgovContent.do 는 RLMS 에 매핑이 없어 404 발생하던 것을 교정.
		return "redirect:/uat/uia/egovLoginUsr.do";
	}

	/**
	 * 아이디/비밀번호 찾기 화면으로 들어간다
	 * @param
	 * @return 아이디/비밀번호 찾기 페이지
	 * @exception Exception
	 */
	@RequestMapping(value = "/uat/uia/egovIdPasswordSearch.do")
	public String idPasswordSearchView(ModelMap model) throws Exception {

		return "egovframework/com/uat/uia/EgovIdPasswordSearch";
	}


	/**
	 * 아이디를 찾는다.
	 * @param vo - 이름, 이메일주소, 사용자구분이 담긴 LoginVO
	 * @return result - 아이디
	 * @exception Exception
	 */
	@RequestMapping(value = "/uat/uia/searchId.do")
	public String searchId(@ModelAttribute("loginVO") LoginVO loginVO, ModelMap model) throws Exception {

		// USER_SE 선택 제거: 이름+이메일만 필수 (회원유형 무관, COMVNUSERMASTER 통합검색)
		if (loginVO == null || loginVO.getName() == null || "".equals(loginVO.getName())
				|| loginVO.getEmail() == null || "".equals(loginVO.getEmail())) {
			return "egovframework/com/cmm/egovError";
		}

		// 1. 아이디 찾기
		loginVO.setName(loginVO.getName().replaceAll(" ", ""));
		LoginVO resultVO = loginService.searchId(loginVO);

		if (resultVO != null && resultVO.getId() != null && !resultVO.getId().equals("")) {

			model.addAttribute("resultInfo", "아이디는 " + resultVO.getId() + " 입니다.");
			return "egovframework/com/uat/uia/EgovIdPasswordResult";
		} else {
			model.addAttribute("resultInfo", egovMessageSource.getMessage("fail.common.idsearch"));
			return "egovframework/com/uat/uia/EgovIdPasswordResult";
		}
	}




	/**
	 * 세션타임아웃 시간을 연장한다.
	 * Cookie에 egovLatestServerTime, egovExpireSessionTime 기록하도록 한다.
	 * @return result - String
	 * @exception Exception
	 */
	@RequestMapping(value="/uat/uia/refreshSessionTimeout.do")
	public ModelAndView refreshSessionTimeout(@RequestParam Map<String, Object> commandMap) throws Exception {
		ModelAndView modelAndView = new ModelAndView();
		modelAndView.setViewName("jsonView");

		modelAndView.addObject("result", "ok");

		return modelAndView;
	}
	
	/**
	 * 비밀번호 유효기간 팝업을 출력한다.
	 * Cookie에 egovLatestServerTime, egovExpireSessionTime 기록하도록 한다.
	 * @return result - String
	 * @exception Exception
	 */
	@RequestMapping(value="/uat/uia/noticeExpirePwd.do")
	public String noticeExpirePwd(@RequestParam Map<String, Object> commandMap, ModelMap model) throws Exception {
		
		// 설정된 비밀번호 유효기간을 가져온다. ex) 180이면 비밀번호 변경후 만료일이 앞으로 180일 
		String propertyExpirePwdDay = EgovProperties.getProperty("Globals.ExpirePwdDay");
		int expirePwdDay = 0 ;
		try {
			expirePwdDay =  Integer.parseInt(propertyExpirePwdDay);
		} catch (NumberFormatException e) {
			LOGGER.debug("convert expirePwdDay Err : "+e.getMessage());
		}
		
		model.addAttribute("expirePwdDay", expirePwdDay);

		// 비밀번호 설정일로부터 몇일이 지났는지 확인한다. ex) 3이면 비빌번호 설정후 3일 경과
		LoginVO loginVO = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		model.addAttribute("loginVO", loginVO);
		int passedDayChangePWD = 0;
		if ( loginVO != null ) {
			LOGGER.debug("===>>> loginVO.getId() = "+loginVO.getId());
			LOGGER.debug("===>>> loginVO.getUniqId() = "+loginVO.getUniqId());
			LOGGER.debug("===>>> loginVO.getUserSe() = "+loginVO.getUserSe());
			// 비밀번호 변경후 경과한 일수
			passedDayChangePWD = loginService.selectPassedDayChangePWD(loginVO);
			LOGGER.debug("===>>> passedDayChangePWD = "+passedDayChangePWD);
			model.addAttribute("passedDay", passedDayChangePWD);
		}
		
		// 만료일자로부터 경과한 일수 => ex)1이면 만료일에서 1일 경과
		model.addAttribute("elapsedTimeExpiration", passedDayChangePWD - expirePwdDay);
		
		return "egovframework/com/uat/uia/EgovExpirePwd";
	}

}