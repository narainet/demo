package egovframework.com.uat.uia.service.impl;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.springframework.stereotype.Service;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.config.EgovLoginConfig;
import egovframework.com.uat.uia.service.EgovLoginService;
import egovframework.com.utl.fcc.service.EgovStringUtil;
import egovframework.com.utl.sim.service.EgovFileScrty;

/**
 * 일반 로그인, 인증서 로그인을 처리하는 비즈니스 구현 클래스
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
 *  2014.12.08   이기하            암호화방식 변경(EgovFileScrty.encryptPassword)
 *  2017.07.21   장동한            로그인인증제한 작업
 *  2020.07.08   신용호            비밀번호를 수정한후 경과한 날짜 조회
 *  2021.05.30   정진오            디지털원패스 인증 회원 조회
 *  2024.10.29   LeeBaekHaeng		불필요 형변환 제거 (mapLockUserInfo.get("lockAt") ), @Override 표기
 *  </pre>
 */
@Service("loginService")
public class EgovLoginServiceImpl extends EgovAbstractServiceImpl implements EgovLoginService {

    @Resource(name="loginDAO")
    private LoginDAO loginDAO;

	@Resource(name = "egovLoginConfig")
	EgovLoginConfig egovLoginConfig;

	/**
     * 2011.08.26
	 * EsntlId를 이용한 로그인을 처리한다
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    @Override
	public LoginVO actionLoginByEsntlId(LoginVO vo) throws Exception {

    	LoginVO loginVO = loginDAO.actionLoginByEsntlId(vo);

    	// 3. 결과를 리턴한다.
    	if (loginVO != null && !loginVO.getId().equals("") && !loginVO.getPassword().equals("")) {
    		return loginVO;
    	} else {
    		loginVO = new LoginVO();
    	}

    	return loginVO;
    }


    /**
	 * 일반 로그인을 처리한다
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    @Override
	public LoginVO actionLogin(LoginVO vo) throws Exception {

    	// 1. 입력한 비밀번호를 암호화한다.
		String enpassword = EgovFileScrty.encryptPassword(vo.getPassword(), vo.getId());
    	vo.setPassword(enpassword);

    	// 2. 아이디와 암호화된 비밀번호가 DB와 일치하는지 확인한다.
    	LoginVO loginVO = loginDAO.actionLogin(vo);

    	// 3. 결과를 리턴한다.
    	if (loginVO != null && !loginVO.getId().equals("") && !loginVO.getPassword().equals("")) {
    		return loginVO;
    	} else {
    		loginVO = new LoginVO();
    	}

    	return loginVO;
    }

    /**
	 * 로그인 아이디로 USER_SE 를 자동 판별한다. (로그인 시 사용자유형 선택 제거용)
	 */
	@Override
	public String selectUserSeByUserId(String id) throws Exception {
		if (id == null || id.trim().isEmpty()) {
			return null;
		}
		return loginDAO.selectUserSeByUserId(id);
	}


    /**
	 * 아이디를 찾는다.
	 * @param vo LoginVO
	 * @return LoginVO
	 * @exception Exception
	 */
    @Override
	public LoginVO searchId(LoginVO vo) throws Exception {

    	// 1. 이름, 이메일주소가 DB와 일치하는 사용자 ID를 조회한다.
    	LoginVO loginVO = loginDAO.searchId(vo);

    	// 2. 결과를 리턴한다.
    	if (loginVO != null && !loginVO.getId().equals("")) {
    		return loginVO;
    	} else {
    		loginVO = new LoginVO();
    	}

    	return loginVO;
    }

    /**
	 * 로그인인증제한을 조회한다.
	 * @param vo LoginVO
	 * @return Map
	 * @exception Exception
	 */
	@Override
    public Map<?,?> selectLoginIncorrect(LoginVO vo) throws Exception{
		String enpassword = EgovFileScrty.encryptPassword(vo.getPassword(), EgovStringUtil.isNullToString(vo.getId()));
		System.out.println("=====================================>" + enpassword);
    	return loginDAO.selectLoginIncorrect(vo);
    }
    
    /**
	 * 로그인인증제한을 처리한다.
	 * @param vo LoginVO
	 * @param vo mapLockUserInfo
	 * @return String
	 * @exception Exception
	 */
	@Override
    public String processLoginIncorrect(LoginVO vo, Map<?,?> mapLockUserInfo) throws Exception{    	
    	String sRtnCode = "C";
    	//KISA 보안약점 조치 (2018-10-29, 윤창원)
    	String enpassword = EgovFileScrty.encryptPassword(vo.getPassword(), EgovStringUtil.isNullToString(vo.getId()));
    	Map<String,String> mapParam = new HashMap<String,String>();
    	mapParam.put("USER_SE", vo.getUserSe());
		mapParam.put("id", EgovStringUtil.isNullToString(vo.getId()));//KISA 보안약점 조치 (2018-10-29, 윤창원)
    	//잠김시 
		if ("Y".equals((mapLockUserInfo.get("lockAt")))) {
			sRtnCode = "L";
		//패드워드 인증시 
		}else if( ((String)mapLockUserInfo.get("userPw")).equals(enpassword) ){
    		//LOCK 해제
    		mapParam.put("updateAt", "E");
    		loginDAO.updateLoginIncorrect(mapParam);
    		sRtnCode = "E";
        //패드워드 비인증시 
		} else if (!"Y".equals((mapLockUserInfo.get("lockAt")))) {
    		//LOCK 설정
    		if( Integer.parseInt(String.valueOf(mapLockUserInfo.get("lockCnt")))+1 >= egovLoginConfig.getLockCount() ){    			
	    		mapParam.put("updateAt", "L");
	    		loginDAO.updateLoginIncorrect(mapParam);
	    		sRtnCode = "L";
	    	//LOCK 증가
    		}else{
	    		mapParam.put("updateAt", "C");
	    		loginDAO.updateLoginIncorrect(mapParam);
	    		sRtnCode = "C";
    		}
    	}
    	return sRtnCode;
    }

    /**
	 * 비밀번호를 수정한후 경과한 날짜를 조회한다.
	 * @param vo LoginVO
	 * @return int
	 * @exception Exception
	 */
	@Override
	public int selectPassedDayChangePWD(LoginVO vo) throws Exception {
		return loginDAO.selectPassedDayChangePWD(vo);
	}

	/** 휴면계정 게이트 — 마지막 활동(성공 로그인·비밀번호 변경·가입) 후 경과일 (2026-07-28) */
	@Override
	public int selectDormantDays(LoginVO vo) throws Exception {
		return loginDAO.selectDormantDays(vo);
	}

    /**
	 * 디지털원패스 인증 회원 조회한다.
	 * @param id
	 * @return LoginVO
	 * @exception Exception
	 */
    @Override
	public LoginVO onepassLogin(String id) throws Exception {
    	LoginVO loginVO = loginDAO.onepassLogin(id);
    	return loginVO;
    }

}
