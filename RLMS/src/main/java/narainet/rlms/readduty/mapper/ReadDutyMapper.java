/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/readduty/mapper/ReadDutyMapper.java
 */
package narainet.rlms.readduty.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.readduty.service.ReadDutyTgtVO;
import narainet.rlms.readduty.service.ReadDutyVO;

@Mapper
public interface ReadDutyMapper {

	/** 회차의 지정 헤더 (회차당 1건 — UNIQUE IPROM_NO) */
	ReadDutyVO selectDutyByPromNo(@Param("promNo") Long promNo);

	/** 지정의 대상 행 (표시명 조인 포함) */
	List<ReadDutyTgtVO> selectDutyTgts(@Param("dutyNo") Long dutyNo);

	int insertDuty(ReadDutyVO vo);

	/** 헤더 갱신 — SALL_YN/SDUE_DT + 지정자 스냅샷 갱신 */
	int updateDuty(ReadDutyVO vo);

	int deleteDuty(@Param("dutyNo") Long dutyNo);

	int deleteDutyTgts(@Param("dutyNo") Long dutyNo);

	int deleteDutyChks(@Param("dutyNo") Long dutyNo);

	int insertDutyTgt(@Param("dutyNo") Long dutyNo,
			@Param("tgtTy") String tgtTy,
			@Param("tgtId") String tgtId);

	/** 대상 판정 — 1=대상 (전사=USR 전 직원 / 부서=ORGNZT_ID / 개인=ESNTL_ID) */
	int countDutyTarget(@Param("dutyNo") Long dutyNo,
			@Param("esntlId") String esntlId,
			@Param("orgnztId") String orgnztId,
			@Param("userSe") String userSe);

	/** 내가 대상인 미숙지 지정 top N — 홈 카드 (dday 포함) */
	List<Map<String, Object>> selectMyDuties(@Param("esntlId") String esntlId,
			@Param("orgnztId") String orgnztId,
			@Param("userSe") String userSe,
			@Param("n") int n);

	/** 이 회차 지정의 내 상태 — 대상 아니면 0행 */
	Map<String, Object> selectMyDutyForProm(@Param("promNo") Long promNo,
			@Param("esntlId") String esntlId,
			@Param("orgnztId") String orgnztId,
			@Param("userSe") String userSe);

	/** 열람 자동 기록 — MERGE, SREAD_DT 최초 1회만 (스냅샷은 최초 확인 시점) */
	int touchRead(@Param("dutyNo") Long dutyNo,
			@Param("esntlId") String esntlId,
			@Param("userNm") String userNm,
			@Param("orgnztId") String orgnztId);

	/** 숙지 확인 — MERGE, SCONF_DT 최초 1회만 (SREAD_DT 도 방어적 보정) */
	int confirmRead(@Param("dutyNo") Long dutyNo,
			@Param("esntlId") String esntlId,
			@Param("userNm") String userNm,
			@Param("orgnztId") String orgnztId);

	/** 지정건 목록 + 집계 (대상수/열람수/숙지수) — 현황 화면 */
	List<Map<String, Object>> selectDutyStatList(@Param("keyword") String keyword);

	/** 지정건 헤더 요약 (규정명·기한·집계) */
	Map<String, Object> selectDutySummary(@Param("dutyNo") Long dutyNo);

	/** 대상자 개인 매트릭스 — 대상 전개 LEFT JOIN 확인 */
	List<Map<String, Object>> selectDutyUserMatrix(@Param("dutyNo") Long dutyNo);

	/** 부서별 집계 */
	List<Map<String, Object>> selectDutyDeptSummary(@Param("dutyNo") Long dutyNo);

	/** 개인 대상 지정용 사용자 검색 top 20 (CateReader selectUserSearch 패턴) */
	List<Map<String, Object>> selectUserSearch(@Param("keyword") String keyword);
}
