package egovframework.com.sym.log.wlg.service.impl;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;

import egovframework.com.sym.log.wlg.service.EgovWebLogService;
import egovframework.com.sym.log.wlg.service.WebLog;
import egovframework.com.sym.log.wlg.service.WebLogStats;

/**
 * @Class Name : EgovWebLogServiceImpl.java
 * @Description : 웹로그 관리를 위한 서비스 구현 클래스
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
@Service("EgovWebLogService")
public class EgovWebLogServiceImpl extends EgovAbstractServiceImpl implements
	EgovWebLogService {

	@Resource(name="webLogDAO")
	private WebLogDAO webLogDAO;

    /** ID Generation */
	@Resource(name="egovWebLogIdGnrService")
	private EgovIdGnrService egovWebLogIdGnrService;

	/**
	 * 웹 로그를 기록한다.
	 *
	 * @param WebLog
	 */
	@Override
	public void logInsertWebLog(WebLog webLog) throws Exception {
		String requstId = egovWebLogIdGnrService.getNextStringId();
		webLog.setRequstId(requstId);

		webLogDAO.logInsertWebLog(webLog);
	}

	/**
	 * 웹 로그정보를 요약한다.
	 *
	 * @param
	 */
	@Override
	public void logInsertWebLogSummary() throws Exception {

		webLogDAO.logInsertWebLogSummary();
	}

	/**
	 * 웹 로그정보 상제정보를 조회한다.
	 *
	 * @param webLog
	 * @return webLog
	 * @throws Exception
	 */
	@Override
	public WebLog selectWebLog(WebLog webLog) throws Exception{

		return webLogDAO.selectWebLog(webLog);
	}

	/**
	 * 웹 로그정보 목록을 조회한다.
	 *
	 * @param WebLog
	 */
	@Override
	public Map<String, Object> selectWebLogInf(WebLog webLog) throws Exception {
		List<WebLog> resultList = webLogDAO.selectWebLogInf(webLog);
		int totCnt = webLogDAO.selectWebLogInfCnt(webLog);

		Map<String, Object> map = new HashMap<>();
        map.put("resultList", resultList);
        map.put("resultCnt", totCnt);

        return map;
	}

	/**
	 * 접속 세션 목록을 조회한다. (웹로그를 세션 단위로 묶은 접속 1회 = 1행)
	 *
	 * @param WebLog
	 */
	@Override
	public Map<String, Object> selectWebLogSessionInf(WebLog webLog) throws Exception {
		List<WebLog> resultList = webLogDAO.selectWebLogSessionInf(webLog);
		int totCnt = webLogDAO.selectWebLogSessionInfCnt(webLog);

		Map<String, Object> map = new HashMap<>();
		map.put("resultList", resultList);
		map.put("resultCnt", totCnt);

		return map;
	}

	/**
	 * 접속 세션 전체를 조회한다. (엑셀 — 페이징 없음)
	 *
	 * @param WebLog
	 */
	@Override
	public List<WebLog> selectWebLogSessionAll(WebLog webLog) throws Exception {
		return webLogDAO.selectWebLogSessionAll(webLog);
	}

	/**
	 * 접속통계를 조회한다. 조회 결과에 없는 구간은 0 으로 채운다(제로필).
	 *
	 * @param WebLogStats
	 */
	@Override
	public List<WebLogStats> selectAccessStats(WebLogStats stats) throws Exception {
		List<WebLogStats> raw = webLogDAO.selectAccessStats(stats);
		List<String> keys = accessBucketKeys(stats, raw);
		if (keys == null) {
			return raw;   // MENU/DEVICE/BROWSER — 구간이 고정 집합이 아니다(접속수 내림차순 그대로)
		}
		Map<String, WebLogStats> byKey = new LinkedHashMap<>();
		for (WebLogStats r : raw) {
			byKey.put(r.getLabel(), r);
		}
		List<WebLogStats> out = new ArrayList<>(keys.size());
		for (String k : keys) {
			WebLogStats r = byKey.get(k);
			if (r == null) {
				r = new WebLogStats();
				r.setLabel(k);
				r.setCnt(Long.valueOf(0));
				r.setUcnt(Long.valueOf(0));
			}
			out.add(r);
		}
		return out;
	}

	/**
	 * 접속통계 기간 합계를 조회한다.
	 *
	 * @param WebLogStats
	 */
	@Override
	public WebLogStats selectAccessTotals(WebLogStats stats) throws Exception {
		return webLogDAO.selectAccessTotals(stats);
	}

	/**
	 * 차원별 전체 구간 키 목록 — 접속 없는 구간도 0 으로 그리기 위한 제로필 골격.
	 * DAY/MONTH 범위 상한은 컨트롤러가 이미 클램프(일 92일·월 36개월)한 fromDt~toDt 기준.
	 * 구간이 고정 집합이 아닌 차원(MENU/DEVICE/BROWSER)은 null — 조회 결과를 그대로 쓴다.
	 */
	private static List<String> accessBucketKeys(WebLogStats stats, List<WebLogStats> raw) {
		List<String> keys = new ArrayList<>();
		String dim = stats.getDimension();
		if ("MENU".equals(dim) || "DEVICE".equals(dim) || "BROWSER".equals(dim)) {
			return null;
		}
		if ("HOUR".equals(dim)) {
			for (int h = 0; h < 24; h++) {
				keys.add(String.format("%02d", Integer.valueOf(h)));
			}
		} else if ("DOW".equals(dim)) {
			for (int d = 0; d <= 6; d++) {   // 0=월 (ISO 주 시작 기준)
				keys.add(String.valueOf(d));
			}
		} else if ("MONTH".equals(dim)) {
			YearMonth from = YearMonth.from(LocalDate.parse(stats.getFromDt()));
			YearMonth to = YearMonth.from(LocalDate.parse(stats.getToDt()));
			for (YearMonth m = from; !m.isAfter(to); m = m.plusMonths(1)) {
				keys.add(m.toString());   // YYYY-MM
			}
		} else if ("YEAR".equals(dim)) {
			// 기본 기간(2010~2035)을 그대로 채우면 빈 연도 투성이 — 데이터 있는 연도 범위만
			if (raw.isEmpty()) {
				return keys;
			}
			int min = Integer.parseInt(raw.get(0).getLabel());
			int max = Integer.parseInt(raw.get(raw.size() - 1).getLabel());
			for (int y = min; y <= max; y++) {
				keys.add(String.valueOf(y));
			}
		} else {   // DAY / WEEK7
			LocalDate from = LocalDate.parse(stats.getFromDt());
			LocalDate to = LocalDate.parse(stats.getToDt());
			for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
				keys.add(d.toString());   // YYYY-MM-DD
			}
		}
		return keys;
	}

}
