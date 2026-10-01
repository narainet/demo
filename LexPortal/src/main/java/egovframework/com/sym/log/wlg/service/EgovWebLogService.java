package egovframework.com.sym.log.wlg.service;

import java.util.Map;

/**
 * @Class Name : EgovWebLogService.java
 * @Description : 웹로그 관리를 위한 서비스 인터페이스
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

public interface EgovWebLogService {

	/**
	 * 웹 로그를 기록한다.
	 *
	 * @param WebLog
	 */
	public void logInsertWebLog(WebLog webLog) throws Exception;

	/**
	 * 웹 로그정보를 요약한다.
	 *
	 * @param
	 */
	public void logInsertWebLogSummary() throws Exception;

	/**
	 * 웹로그 상세정보를 조회한다.
	 *
	 * @param webLog
	 * @return webLog
	 * @throws Exception
	 */
	public WebLog selectWebLog(WebLog webLog) throws Exception;

	/**
	 * 웹 로그정보 목록을 조회한다.
	 *
	 * @param WebLog
	 */
	public Map<String, Object> selectWebLogInf(WebLog webLog) throws Exception;

	/**
	 * 접속 세션 목록을 조회한다. 웹로그를 세션(SESN_ID) 단위로 묶어 접속 1회를 1행으로 본다.
	 * 마지막 요청 시각이 곧 떠난 시각이라, 로그아웃 여부와 무관하게 접속~종료·체류가 산출된다.
	 *
	 * @param WebLog
	 */
	public Map<String, Object> selectWebLogSessionInf(WebLog webLog) throws Exception;

	/**
	 * 접속 세션 전체를 조회한다. (엑셀 — 페이징 없음)
	 *
	 * @param WebLog
	 */
	public java.util.List<WebLog> selectWebLogSessionAll(WebLog webLog) throws Exception;

	/**
	 * 접속통계를 조회한다. 웹로그를 차원(시간대/일/월/연/요일/메뉴/기기/브라우저)별로 집계한다.
	 * 접속이 없는 구간도 0 으로 채워(제로필) 차트가 기간 전체를 보여주게 한다.
	 *
	 * @param stats 기간(fromDt~toDt) + 차원(dimension)
	 */
	public java.util.List<WebLogStats> selectAccessStats(WebLogStats stats) throws Exception;

	/**
	 * 접속통계 기간 합계를 조회한다. (총 접속수 + 순 접속자수 — 구간별 합산은 중복이라 별도 집계)
	 *
	 * @param stats 기간(fromDt~toDt)
	 */
	public WebLogStats selectAccessTotals(WebLogStats stats) throws Exception;

}
