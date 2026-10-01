/*
 * 물리적 저장 경로: /src/main/java/narainet/law/home/service/LawHomeService.java
 */
package narainet.law.home.service;

import java.util.Map;

public interface LawHomeService {

	/** 송무 홈 요약 카드 — activeSuits/newSuitsThisMonth/pendingReqs/pendingDocs */
	Map<String, Object> getHomeSummary() throws Exception;

	/** 송무 홈 대시보드 전체 — summary + todayHearings + weekHearings + recentSuits (§7.0 P4) */
	Map<String, Object> getHomeData() throws Exception;
}
