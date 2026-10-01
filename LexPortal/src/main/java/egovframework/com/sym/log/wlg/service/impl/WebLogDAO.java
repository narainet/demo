package egovframework.com.sym.log.wlg.service.impl;

import java.util.List;

import org.springframework.stereotype.Repository;

import egovframework.com.cmm.service.impl.EgovComAbstractDAO;
import egovframework.com.sym.log.wlg.service.WebLog;
import egovframework.com.sym.log.wlg.service.WebLogStats;

/**
 * @Class Name : WebLogDAO.java
 * @Description : 웹로그 관리를 위한 데이터 접근 클래스
 * @Modification Information
 *
 *    수정일         수정자         수정내용
 *    -------        -------     -------------------
 *    2009. 3. 11.   이삼섭         최초생성
 *    2011. 7. 01.   이기하         패키지 분리(sym.log -> sym.log.wlg)
 *
 * @author 공통 서비스 개발팀 이삼섭
 * @since 2009. 3. 11.
 * @version
 * @see
 *
 */
@Repository("webLogDAO")
public class WebLogDAO extends EgovComAbstractDAO {

	/**
	 * 웹 로그를 기록한다.
	 *
	 * @param WebLog
	 * @return
	 * @throws Exception
	 */
	public void logInsertWebLog(WebLog webLog) throws Exception{
		insert("WebLog.logInsertWebLog", webLog);
	}

	/**
	 * 웹 로그정보를 요약한다.
	 *
	 * @param
	 * @return
	 * @throws Exception
	 */
	public void logInsertWebLogSummary() throws Exception{
		insert("WebLog.logInsertWebLogSummary", null);
		delete("WebLog.logDeleteWebLogSummary", null);
	}

	/**
	 * 웹 로그정보 상세정보를 조회한다.
	 *
	 * @param webLog
	 * @return webLog
	 * @throws Exception
	 */
	public WebLog selectWebLog(WebLog webLog) throws Exception{

		return (WebLog) selectOne("WebLog.selectWebLog", webLog);
	}

	/**
	 * 웹 로그정보 목록을 조회한다.
	 *
	 * @param webLog
	 * @return
	 * @throws Exception
	 */
	public List<WebLog> selectWebLogInf(WebLog webLog) throws Exception{
		return selectList("WebLog.selectWebLogInf", webLog);
	}

	/**
	 * 웹 로그정보 목록의 숫자를 조회한다.
	 * @param webLog
	 * @return
	 * @throws Exception
	 */
	public int selectWebLogInfCnt(WebLog webLog) throws Exception{

		return (Integer)selectOne("WebLog.selectWebLogInfCnt", webLog);
	}

	/**
	 * 접속 세션 목록을 조회한다. (웹로그를 세션 단위로 묶은 접속 1회 = 1행)
	 *
	 * @param webLog
	 * @return
	 * @throws Exception
	 */
	public List<WebLog> selectWebLogSessionInf(WebLog webLog) throws Exception{
		return selectList("WebLog.selectWebLogSessionInf", webLog);
	}

	/**
	 * 접속 세션 목록의 숫자를 조회한다.
	 *
	 * @param webLog
	 * @return
	 * @throws Exception
	 */
	public int selectWebLogSessionInfCnt(WebLog webLog) throws Exception{
		return (Integer)selectOne("WebLog.selectWebLogSessionInfCnt", webLog);
	}

	/**
	 * 접속 세션 전체를 조회한다. (엑셀 — 페이징 없음)
	 *
	 * @param webLog
	 * @return
	 * @throws Exception
	 */
	public List<WebLog> selectWebLogSessionAll(WebLog webLog) throws Exception{
		return selectList("WebLog.selectWebLogSessionAll", webLog);
	}

	/**
	 * 접속통계(차원별 집계)를 조회한다.
	 *
	 * @param stats
	 * @return
	 * @throws Exception
	 */
	public List<WebLogStats> selectAccessStats(WebLogStats stats) throws Exception{
		return selectList("WebLog.selectAccessStats", stats);
	}

	/**
	 * 접속통계 기간 합계를 조회한다.
	 *
	 * @param stats
	 * @return
	 * @throws Exception
	 */
	public WebLogStats selectAccessTotals(WebLogStats stats) throws Exception{
		return (WebLogStats) selectOne("WebLog.selectAccessTotals", stats);
	}

}
