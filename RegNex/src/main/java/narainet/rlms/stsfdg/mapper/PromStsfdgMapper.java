/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/stsfdg/mapper/PromStsfdgMapper.java
 *
 * 규정 만족도 조사 매퍼 — TB_PROM_STSFDG (회차별, 1인 1회 = PK(IPROM_NO, SINS_ID)).
 * 게시판 만족도(COMTNSTSFDG)를 참고하되 로그인 전용·재참여=갱신(MERGE) 규약(2026-07-20).
 */
package narainet.rlms.stsfdg.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface PromStsfdgMapper {

	/** 회차의 참여 목록 — 최신 참여/수정 순. {wrterId, wrterNm, stsfdg, content, regDt}.
	 *  fromDt/toDt(yyyy-MM-dd, null=무제한)는 관리자 현황의 기간 검색용 — 사용자 위젯은 null 전달. */
	List<Map<String, Object>> selectList(@Param("promNo") Long promNo,
			@Param("fromDt") String fromDt, @Param("toDt") String toDt);

	/** 회차 집계 — {cnt, avg} */
	Map<String, Object> selectSummary(@Param("promNo") Long promNo);

	/** 본인 참여 1건 — {stsfdg, content} 또는 null */
	Map<String, Object> selectMine(@Param("promNo") Long promNo, @Param("userId") String userId);

	/** 등록/재참여 통합 — MERGE (있으면 갱신 + SUPD_DT, 없으면 삽입) */
	int mergeStsfdg(@Param("promNo") Long promNo, @Param("userId") String userId,
			@Param("stsfdg") int stsfdg, @Param("stsfdgCn") String stsfdgCn);

	/** 본인 참여 취소 — 행 삭제 */
	int deleteMine(@Param("promNo") Long promNo, @Param("userId") String userId);

	// ═══ 관리자 현황/집계 (stsfdgStats — /rlms/stats/ 폴더, ROLE_ADMIN L6 파생) ═══

	/** 규정 회차별 집계 — 옵션(SSTSFDG_YN='Y')이거나 참여가 있는 회차. p:{keyword, firstIndex, recordCountPerPage} */
	List<Map<String, Object>> selectPromAggList(Map<String, Object> p);

	int countPromAgg(Map<String, Object> p);

	/** 게시글별 집계 — COMTNSTSFDG(USE_AT='Y') GROUP BY 게시글. p:{keyword, firstIndex, recordCountPerPage} */
	List<Map<String, Object>> selectBbsAggList(Map<String, Object> p);

	int countBbsAgg(Map<String, Object> p);

	/** 게시판 만족도 참여 상세(관리자) — 소프트삭제 제외(USE_AT='Y'). fromDt/toDt = 기간 검색(null=무제한). */
	List<Map<String, Object>> selectBbsDetailList(@Param("bbsId") String bbsId, @Param("nttId") Long nttId,
			@Param("fromDt") String fromDt, @Param("toDt") String toDt);

	/** 관리자 삭제 — 규정 참여 행(참여자 지정) */
	int deleteByAdmin(@Param("promNo") Long promNo, @Param("sinsId") String sinsId);

	/** 관리자 삭제 — 게시판 참여 행(표준 관례 소프트삭제 USE_AT='N') */
	int softDeleteBbsStsfdg(@Param("stsfdgNo") String stsfdgNo);

	/** 엑셀 — 규정 만족도 전체 참여 상세(규정명·분류·부서·연혁·참여자·별점·의견·일시). 기간 검색 적용. */
	List<Map<String, Object>> selectPromExportList(@Param("fromDt") String fromDt, @Param("toDt") String toDt);

	/** 엑셀 — 게시판 만족도 전체 참여 상세(게시판·글제목·참여자·별점·의견·일시). 기간 검색 적용. */
	List<Map<String, Object>> selectBbsExportList(@Param("fromDt") String fromDt, @Param("toDt") String toDt);
}
