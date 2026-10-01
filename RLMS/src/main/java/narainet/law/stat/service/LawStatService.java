/*
 * 물리적 저장 경로: /src/main/java/narainet/law/stat/service/LawStatService.java
 *
 * 소송통계 7종 서비스 — LAW_MODULE_DESIGN.md §7.12.
 * 매퍼 원시 집계행을 화면 표시용(계 행·승소율·비율 포함)으로 조립한다.
 * 집계 축 코드는 impl 상수(임의 재분류 금지). 기간형=summary/lossCause/landMap, 나머지=계류 스냅샷.
 */
package narainet.law.stat.service;

import java.util.List;
import java.util.Map;

public interface LawStatService {

	/** ① 소송현황 — 계/민사/행정/국가/심판 × 발생·확정종결(계·승·패·승소율)·계류 */
	List<Map<String, Object>> getSummary(String fromDate, String toDate);

	/** ② 심급별 — 합계/1심/2심/3심 × 구분4축 (계류 스냅샷, 기간 입력 시 소제기일 FR_DT 필터·빈값=전체) */
	List<Map<String, Object>> getInstance(String fromDate, String toDate);

	/** ③ 유형별 — 계 + 사건유형 12종 × 구분4축 (계류 스냅샷, 기간 입력 시 소제기일 FR_DT 필터·빈값=전체) */
	List<Map<String, Object>> getCaseType(String fromDate, String toDate);

	/** ④ 부서별 — 계 + 전 부서 × 구분4축 ×(변호사/직접) (계류 스냅샷, 기간 입력 시 소제기일 FR_DT 필터·빈값=전체) */
	List<Map<String, Object>> getDept(String fromDate, String toDate);

	/** ⑤ 대리인 — top(변호사선임/공무원수행+비율) + bottom(대리인별) 묶음 (기간 입력 시 소제기일 FR_DT 필터·빈값=전체) */
	Map<String, Object> getAgent(String fromDate, String toDate);

	/** ⑥ 패소원인 — 계 + 원인별 건수·비율(+최대치 maxCnt) 묶음 (기간=DCSN_DT) */
	Map<String, Object> getLossCause(String fromDate, String toDate);

	/** ⑦ 사건지번 — 지번/소재지·사건번호·사건명 (기간 + 결과 그룹) */
	List<Map<String, Object>> getLandJibun(String fromDate, String toDate, List<String> rsltCds);

	/**
	 * 사건지번 결과 그룹 체크박스 → RSLT_KIND_CD 목록.
	 * 전체 선택(또는 전무) = null(무필터). 축 코드는 서비스 상수에서 조립.
	 */
	List<String> buildLandResultCodes(boolean processing, boolean terminate, boolean win, boolean lose);
}
