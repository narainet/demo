/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/service/impl/StatsServiceImpl.java
 */
package narainet.rlms.stats.service.impl;

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

import narainet.rlms.stats.mapper.StatsMapper;
import narainet.rlms.stats.service.StatsService;
import narainet.rlms.stats.service.StatsVO;

@Service("statsService")
public class StatsServiceImpl extends EgovAbstractServiceImpl implements StatsService {

	@Resource(name = "statsMapper")
	private StatsMapper statsMapper;

	@Resource(name = "egovStatsFtViewIdGnrService")
	private EgovIdGnrService statsFtViewIdGnrService;

	@Resource(name = "egovStatsBbsViewIdGnrService")
	private EgovIdGnrService statsBbsViewIdGnrService;

	@Resource(name = "egovActLogIdGnrService")
	private EgovIdGnrService actLogIdGnrService;

	@Override
	public void recordView(Long lawId, String gubunId) throws Exception {
		if (lawId == null || gubunId == null || gubunId.trim().isEmpty()) {
			return;   // TB_STATS_FT_VIEW 두 컬럼 모두 NOT NULL — 결손 데이터는 적재 생략
		}
		statsMapper.insertViewStat(statsFtViewIdGnrService.getNextIntegerId(), lawId, gubunId);
	}

	@Override
	public void recordBbsView(String bbsId, Long nttId) throws Exception {
		if (nttId == null || bbsId == null || bbsId.trim().isEmpty()) {
			return;   // 두 컬럼 모두 NOT NULL — 결손 데이터는 적재 생략
		}
		// BBS_ID 는 CHAR 고정폭 — RTRIM 저장으로 패딩 무해화(만족도 현황 교훈)
		statsMapper.insertBbsViewStat(statsBbsViewIdGnrService.getNextIntegerId(), bbsId.trim(), nttId);
	}

	@Override
	public List<StatsVO> getViewStats(StatsVO vo) {
		return statsMapper.selectViewStats(vo);
	}

	@Override
	public long getViewCount(Long lawId) {
		return lawId == null ? 0L : statsMapper.selectViewCountByLawId(lawId);
	}

	@Override
	public List<StatsVO> getBbsViewStats(StatsVO vo) {
		return statsMapper.selectBbsViewStats(vo);
	}

	@Override
	public List<StatsVO> getAccessStats(StatsVO vo) {
		List<StatsVO> raw = statsMapper.selectAccessStats(vo);
		List<String> keys = accessBucketKeys(vo, raw);
		if (keys == null) {
			return raw;   // MENU/DEVICE/BROWSER — 데이터 있는 구간만(접속수 내림차순), 제로필 없음
		}
		Map<String, StatsVO> byKey = new LinkedHashMap<>();
		for (StatsVO r : raw) {
			byKey.put(r.getLabel(), r);
		}
		List<StatsVO> out = new ArrayList<>(keys.size());
		for (String k : keys) {
			StatsVO r = byKey.get(k);
			if (r == null) {
				r = new StatsVO();
				r.setLabel(k);
				r.setCnt(0L);
				r.setUcnt(0L);
			}
			out.add(r);
		}
		return out;
	}

	@Override
	public StatsVO getAccessTotals(StatsVO vo) {
		return statsMapper.selectAccessTotals(vo);
	}

	/** 차원별 전체 구간 키 목록 — 접속 없는 구간도 0 으로 그리기 위한 제로필 골격.
	 *  DAY/MONTH 범위 상한은 컨트롤러가 이미 클램프(일 92일·월 36개월)한 fromDt~toDt 기준.
	 *  구간이 고정 집합이 아닌 차원(MENU/DEVICE/BROWSER)은 null — 조회 결과 그대로 쓴다. */
	private static List<String> accessBucketKeys(StatsVO vo, List<StatsVO> raw) {
		List<String> keys = new ArrayList<>();
		String dim = vo.getDimension();
		if ("MENU".equals(dim) || "DEVICE".equals(dim) || "BROWSER".equals(dim)) {
			return null;
		}
		if ("HOUR".equals(dim)) {
			for (int h = 0; h < 24; h++) {
				keys.add(String.format("%02d", h));
			}
		} else if ("DOW".equals(dim)) {
			for (int d = 0; d <= 6; d++) {   // 0=월 (TRUNC-TRUNC('IW'))
				keys.add(String.valueOf(d));
			}
		} else if ("MONTH".equals(dim)) {
			YearMonth from = YearMonth.from(LocalDate.parse(vo.getFromDt()));
			YearMonth to = YearMonth.from(LocalDate.parse(vo.getToDt()));
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
			LocalDate from = LocalDate.parse(vo.getFromDt());
			LocalDate to = LocalDate.parse(vo.getToDt());
			for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
				keys.add(d.toString());   // YYYY-MM-DD
			}
		}
		return keys;
	}

	@Override
	public List<StatsVO> getKeywordStats(StatsVO vo) {
		return statsMapper.selectKeywordStats(vo);
	}

	@Override
	public List<StatsVO> getDeptStats(StatsVO vo) {
		return statsMapper.selectDeptStats(vo);
	}

	@Override
	public void recordAction(String task, String refTable, Long refNo, String name,
			String userId, String userNm, String ip) {
		try {
			// SNAME/SUSER_* 는 VARCHAR2(255 BYTE) — 한글 3바이트 기준 80자 상한으로 ORA-12899 방지
			statsMapper.insertActLog(actLogIdGnrService.getNextIntegerId(), task,
					refTable, refNo, clip(name, 80), clip(userId, 80), clip(userNm, 80), clip(ip, 80));
		} catch (Exception e) {
			org.slf4j.LoggerFactory.getLogger(StatsServiceImpl.class)
					.warn("활동 로그 적재 실패(무시) task={}, name={}: {}", task, name, e.getMessage());
		}
	}

	private static String clip(String s, int max) {
		if (s == null) {
			return null;
		}
		return s.length() > max ? s.substring(0, max) : s;
	}

	@Override
	public Map<String, Object> getActionLog(StatsVO vo) {
		List<StatsVO> list = statsMapper.selectActionLog(vo);
		int cnt = statsMapper.selectActionLogCnt(vo);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public List<String> getTaskKinds() {
		return statsMapper.selectTaskKinds();
	}

}
