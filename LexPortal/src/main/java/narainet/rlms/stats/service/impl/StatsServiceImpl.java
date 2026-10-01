/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stats/service/impl/StatsServiceImpl.java
 */
package narainet.rlms.stats.service.impl;

import java.util.HashMap;
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

	@Resource(name = "egovStatsBbsViewIdGnrService")
	private EgovIdGnrService statsBbsViewIdGnrService;

	@Resource(name = "egovActLogIdGnrService")
	private EgovIdGnrService actLogIdGnrService;

	@Override
	public void recordBbsView(String bbsId, Long nttId) throws Exception {
		if (nttId == null || bbsId == null || bbsId.trim().isEmpty()) {
			return;   // 두 컬럼 모두 NOT NULL — 결손 데이터는 적재 생략
		}
		// BBS_ID 는 CHAR 고정폭 — RTRIM 저장으로 패딩 무해화(만족도 현황 교훈)
		statsMapper.insertBbsViewStat(statsBbsViewIdGnrService.getNextIntegerId(), bbsId.trim(), nttId);
	}

	@Override
	public List<StatsVO> getBbsViewStats(StatsVO vo) {
		return statsMapper.selectBbsViewStats(vo);
	}

	/* 접속통계(getAccessStats/getAccessTotals + 제로필)는 표준 웹로그 모듈로 이관 — 2026-08-06.
	   egovframework.com.sym.log.wlg.service.impl.EgovWebLogServiceImpl 참조. */

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
