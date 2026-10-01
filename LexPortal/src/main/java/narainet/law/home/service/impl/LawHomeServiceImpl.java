/*
 * 물리적 저장 경로: /src/main/java/narainet/law/home/service/impl/LawHomeServiceImpl.java
 *
 * 송무 홈 대시보드 (LAW_MODULE_DESIGN.md §7.0). P4: 오늘·이번 주 기일 그리드(일정 서비스 재사용)+최근 사건 5건.
 */
package narainet.law.home.service.impl;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import narainet.law.home.mapper.LawHomeMapper;
import narainet.law.schedule.service.LawScheduleService;
import narainet.law.schedule.service.LawScheduleVO;

@Service("lawHomeService")
public class LawHomeServiceImpl implements narainet.law.home.service.LawHomeService {

	private static final DateTimeFormatter YMD = DateTimeFormatter.ofPattern("yyyyMMdd");

	@Resource(name = "lawHomeMapper")
	private LawHomeMapper lawHomeMapper;

	@Resource(name = "lawScheduleService")
	private LawScheduleService lawScheduleService;

	@Override
	public Map<String, Object> getHomeSummary() throws Exception {
		Map<String, Object> m = new HashMap<String, Object>();
		m.put("activeSuits", lawHomeMapper.countActiveSuits());
		m.put("newSuitsThisMonth", lawHomeMapper.countNewSuitsThisMonth());
		m.put("pendingReqs", lawHomeMapper.countPendingReqs());
		m.put("pendingDocs", lawHomeMapper.countPendingDocs());
		return m;
	}

	@Override
	public Map<String, Object> getHomeData() throws Exception {
		LocalDate today = LocalDate.now();
		String todayYmd = today.format(YMD);
		String weekFrom = today.with(DayOfWeek.MONDAY).format(YMD);
		String weekTo = today.with(DayOfWeek.SUNDAY).format(YMD);

		Map<String, Object> m = new HashMap<String, Object>();
		m.put("summary", getHomeSummary());
		m.put("todayHearings", lawScheduleService.getDay(todayYmd));
		// 이번 주 목록에서 오늘치는 뺀다 — 바로 위 '오늘 기일' 카드에 이미 나와 같은 항목이 두 번 보였다(2026-08-06 사용자 지시).
		// 일정관리 화면(LawScheduleController)의 주간 목록은 종전대로 오늘 포함 — 대시보드만의 표시 규칙이다.
		List<LawScheduleVO> week = lawScheduleService.getWeek(weekFrom, weekTo);
		List<LawScheduleVO> weekExceptToday = new ArrayList<LawScheduleVO>();
		for (LawScheduleVO h : week) {
			if (!todayYmd.equals(h.getProgDt())) {
				weekExceptToday.add(h);
			}
		}
		m.put("weekHearings", weekExceptToday);
		m.put("recentSuits", lawHomeMapper.selectRecentSuits());
		return m;
	}
}
