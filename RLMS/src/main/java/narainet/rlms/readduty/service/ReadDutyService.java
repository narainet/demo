/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/readduty/service/ReadDutyService.java
 *
 * 필수 열람(의무 숙지) 서비스.
 *  - 지정: 승인 회차에 대상(전사/부서/개인)과 기한을 지정 (회차당 1건 upsert)
 *  - 확인 2단계: 열람(뷰어 본문 열람 시 자동) → 숙지(뷰어 [숙지 확인] 버튼 — 최종 증빙)
 *  - 현황: 지정건 목록/개인 매트릭스/부서 집계 (컴플라이언스 증빙, 엑셀)
 */
package narainet.rlms.readduty.service;

import java.util.List;
import java.util.Map;

public interface ReadDutyService {

	/** 회차의 기존 지정 (대상 행 포함) — 없으면 null. 지정 모달 로드용 */
	ReadDutyVO selectDutyByPromNo(Long promNo);

	/**
	 * 지정 저장 (upsert — 회차당 1건).
	 * tgts = "DEPT:ORGNZT_ID" / "USER:ESNTL_ID" 문자열 목록 (allYn='Y' 면 무시).
	 */
	void saveDuty(ReadDutyVO vo, List<String> tgts) throws Exception;

	/** 지정 삭제 — 대상/확인 기록까지 제거 (지정 취소 = 의무 자체 철회) */
	void deleteDuty(Long dutyNo);

	/** 내가 대상인 미숙지 지정 top N — 사용자 홈 "읽어야 할 규정" 카드 */
	List<Map<String, Object>> selectMyDuties(String esntlId, String orgnztId, String userSe, int n);

	/** 이 회차 지정의 대상인가 — 뷰어 버튼 상태 (dutyNo/dueDt/dday/readDt/confDt). 대상 아니면 null */
	Map<String, Object> selectMyDutyForProm(Long promNo, String esntlId, String orgnztId, String userSe);

	/** 열람 자동 기록 (1단계) — 뷰어 본문 열람 시. 최초 1회만 기록(멱등) */
	void touchRead(Long dutyNo, String esntlId, String userNm, String orgnztId);

	/** 숙지 확인 (2단계, 최종 증빙) — 대상자 본인만. 대상 아니면 IllegalStateException */
	void confirmDuty(Long dutyNo, String esntlId, String userNm, String orgnztId, String userSe);

	/** 지정건 목록 + 대상/열람/숙지 집계 — 열람 현황 화면 */
	List<Map<String, Object>> selectDutyStatList(String keyword);

	/** 지정건 1건의 헤더 요약 (규정명·기한·집계) — 없으면 null */
	Map<String, Object> selectDutySummary(Long dutyNo);

	/** 지정건 1건의 대상자 개인 매트릭스 (부서·이름·열람일·숙지일) */
	List<Map<String, Object>> selectDutyUserMatrix(Long dutyNo);

	/** 지정건 1건의 부서별 집계 (대상수·열람수·숙지수) */
	List<Map<String, Object>> selectDutyDeptSummary(Long dutyNo);

	/** 개인 대상 지정용 사용자 검색 top 20 */
	List<Map<String, Object>> selectUserSearch(String keyword);
}
