/*
 * 물리적 저장 경로: /src/main/java/narainet/law/schedule/mapper/LawScheduleMapper.java
 *
 * 일정(기일=LAW_SUIT_PROG PROG_KIND_CD='S001') 조회·등록·삭제. 수행자/보조=LAW_SUIT_STAFF 0/1. §7.5
 */
package narainet.law.schedule.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.schedule.service.LawScheduleVO;

@Mapper
public interface LawScheduleMapper {

	/** 기일 목록(유연 검색) — searchFrom/To·targetDt·caseNo·dyprKind·instance 조건 */
	List<LawScheduleVO> selectHearings(LawScheduleVO searchVO);

	LawScheduleVO selectHearing(@Param("progId") Long progId);

	/** 일정(기일) 단건 등록 — PROG_KIND_CD='S001' 고정 */
	void insertHearing(LawScheduleVO vo);

	/** 일정 단건 삭제 */
	void deleteHearing(@Param("progId") Long progId);
}
