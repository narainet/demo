package egovframework.com.uat.uia.service.impl;

import java.util.Map;

import org.springframework.stereotype.Repository;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.service.impl.EgovComAbstractDAO;

/**
 * 일반 로그인, 인증서 로그인을 처리하는 DAO 클래스
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
@Repository("loginDAO")
public class LoginDAO extends EgovComAbstractDAO {

    /**
     * 2011.08.26
	 * EsntlId를 이용한 로그인을 처리한다
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    public LoginVO actionLoginByEsntlId(LoginVO vo) throws Exception {
    	return (LoginVO)selectOne("LoginUsr.ssoLoginByEsntlId", vo);
    }

	/**
	 * 일반 로그인을 처리한다
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    public LoginVO actionLogin(LoginVO vo) throws Exception {
    	return (LoginVO)selectOne("LoginUsr.actionLogin", vo);
    }

    /**
	 * 로그인 아이디로 USER_SE 를 자동 판별한다. (COMVNUSERMASTER 조회)
	 * @param id 로그인 아이디
	 * @return USER_SE 또는 null
	 */
    public String selectUserSeByUserId(String id) throws Exception {
    	return (String)selectOne("LoginUsr.selectUserSeByUserId", id);
    }


    /**
	 * 아이디를 찾는다.
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    public LoginVO searchId(LoginVO vo) throws Exception {

    	return (LoginVO)selectOne("LoginUsr.searchId", vo);
    }

    /**
	 * 로그인인증제한 내역을 조회한다.
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
	public Map<?,?> selectLoginIncorrect(LoginVO vo) throws Exception {
    	return (Map<?,?>)selectOne("LoginUsr.selectLoginIncorrect", vo);
    }

    /**
	 * 로그인인증제한 내역을 업데이트 한다.
	 * @param vo LoginVO
	 * @return vod
	 * @exception Exception
	 */
    public void updateLoginIncorrect(Map<?,?> map) throws Exception {
    	update("LoginUsr.updateLoginIncorrect"+map.get("USER_SE"), map);
    }
    
    /**
	 * 비밀번호를 수정한후 경과한 날짜를 조회한다.
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    public int selectPassedDayChangePWD(LoginVO vo) throws Exception {
    	return selectOne("LoginUsr.selectPassedDayChangePWD", vo);
    }

	/** 휴면계정 게이트 — 마지막 활동(성공 로그인·비밀번호 변경·가입) 후 경과일 (2026-07-28) */
	public int selectDormantDays(LoginVO vo) throws Exception {
		return selectOne("LoginUsr.selectDormantDays", vo);
	}

	/**
	 * 디지털원패스 인증 회원 조회한다.
	 * @param id
	 * @return LoginVO
	 * @exception Exception
	 */
    public LoginVO onepassLogin(String id) throws Exception {
    	return (LoginVO)selectOne("LoginUsr.onepassLogin", id);
    }

}
