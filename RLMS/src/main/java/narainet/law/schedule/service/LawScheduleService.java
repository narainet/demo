/*
 * 물리적 저장 경로: /src/main/java/narainet/law/schedule/service/LawScheduleService.java
 */
package narainet.law.schedule.service;

import java.util.List;

public interface LawScheduleService {

	/** 유연 검색(사건번호·기일구분·기간·심급·특정일) */
	List<LawScheduleVO> getHearings(LawScheduleVO vo) throws Exception;

	/** 특정 일자 기일(당일 그리드·달력 셀) */
	List<LawScheduleVO> getDay(String ymd) throws Exception;

	/** 기간 기일(주간 그리드) */
	List<LawScheduleVO> getWeek(String fromYmd, String toYmd) throws Exception;

	/** 월 전체 기일(달력) — ym=YYYYMM */
	List<LawScheduleVO> getMonth(String ym) throws Exception;

	LawScheduleVO getHearing(Long progId) throws Exception;

	/** 일정(기일) 단건 등록 — 채번 후 insert */
	Long save(LawScheduleVO vo, String userId) throws Exception;

	void delete(Long progId) throws Exception;
}
