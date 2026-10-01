package egovframework.com.uat.uia.service;

import java.util.Map;

import egovframework.com.cmm.LoginVO;

/**
 * EgovLoginService 클래스
 * 
 * <p>
 * 일반 로그인, 인증서 로그인을 처리하는 비즈니스 인터페이스 클래스
 * </p>
 * 
 * @author 공통서비스 개발팀 박지욱
 * @since 2009.03.06
 * @version 1.0
 * @see
 *  
 * <pre>
 * << 개정이력(Modification Information) >>
 * 
 *  수정일               수정자            수정내용
 *  ----------   --------   ---------------------------
 *  2009.03.06   박지욱            최초 생성 
 *  2011.08.26   서준식            EsntlId를 이용한 로그인 추가
 *  2017.07.21   장동한            로그인인증제한 작업
 *  2020.07.08   신용호            비밀번호를 수정한후 경과한 날짜 조회
 *  2021.05.30   정진오            디지털원패스 인증 회원 조회
 *  </pre>
 */
public interface EgovLoginService {
	
	/**
     * 2011.08.26
	 * EsntlId를 이용한 로그인을 처리한다
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    public LoginVO actionLoginByEsntlId(LoginVO vo) throws Exception;
	
	/**
	 * 일반 로그인을 처리한다
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    LoginVO actionLogin(LoginVO vo) throws Exception;

    /**
	 * 로그인 아이디로 USER_SE(회원구분)를 자동 판별한다. (로그인 시 사용자유형 선택 제거용)
	 * COMVNUSERMASTER(전역 유일 뷰) 조회. 미존재 시 null.
	 * @param id 로그인 아이디
	 * @return USER_SE (GNR/USR 등) 또는 null
	 * @exception Exception
	 */
    String selectUserSeByUserId(String id) throws Exception;

    /**
	 * 아이디를 찾는다.
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    LoginVO searchId(LoginVO vo) throws Exception;

    /**
	 * 로그인인증제한을 처리한다.
	 * @param vo LoginVO
	 * @param Map mapLockUserInfo
	 * @return String
	 * @exception Exception
	 */
    String processLoginIncorrect(LoginVO vo, Map<?,?> mapLockUserInfo) throws Exception;
    
    /**
	 * 로그인인증제한을 조회한다.
	 * @param vo LoginVO
	 * @return Map
	 * @exception Exception
	 */
    Map<?,?> selectLoginIncorrect(LoginVO vo) throws Exception;

    /**
	 * 비밀번호를 수정한후 경과한 날짜를 조회한다.
	 * @param vo LoginVO
	 * @return int
	 * @exception Exception
	 */    
    int selectPassedDayChangePWD(LoginVO vo) throws Exception;

	/** 휴면계정 게이트 — 마지막 활동(성공 로그인·비밀번호 변경·가입) 후 경과일 (2026-07-28) */
	int selectDormantDays(LoginVO vo) throws Exception;

	/**
	 * 디지털원패스 인증 회원 조회한다.
	 * @param id
	 * @return LoginVO
	 * @exception Exception
	 */
    LoginVO onepassLogin(String id) throws Exception;
}
