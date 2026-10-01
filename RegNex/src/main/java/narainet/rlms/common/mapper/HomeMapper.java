/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/common/mapper/HomeMapper.java
 *
 * 사용자 홈 대시보드 조회 매퍼.
 *  - 구분별 현행 보유 규정 수 / 최종 등록일 / 최근 개정 규정 / 공지사항 최신글
 */
package narainet.rlms.common.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface HomeMapper {

	/** 구분(SGUBUN_ID)별 현행 보유 규정 수 — { sgubunId, cnt }. 열람제한 게이트 적용 가능. */
	List<Map<String, Object>> selectGubunCounts(@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	/** 규정 최종 등록일시 (TB_PROM.SINS_DT MAX) */
	String selectLastInsDt();

	/** 최근 등록(개정) 규정 top N — { promNo, title, promDate, cateNm }. 열람제한 게이트 적용 가능. */
	List<Map<String, Object>> selectRecentProms(@Param("n") int n,
			@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	/** 즐겨찾기 규정 개정 소식 top N — 마지막 확인 회차 이후 새 현행 회차가 공포된 즐겨찾기 법령.
	 *  { promNo, title, promDate, cateNm, pendingYn }. userId = ESNTL_ID(TB_FAVOR.SUSER_ID 규약). */
	List<Map<String, Object>> selectFavorRevisedProms(@Param("userId") String userId, @Param("n") int n,
			@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	/** 공지사항 BBS 최신글 top N — { nttId, nttSj, regDt } */
	List<Map<String, Object>> selectRecentNotices(@Param("bbsId") String bbsId, @Param("n") int n);

	/** 공지 보드 동적 해석 — USE_AT='Y' AND BBS_NM='공지사항' 최초등록 1건, 없으면 활성 보드 1건, 전무=null */
	String selectNoticeBbsId();

	/** 관리자 대시보드 — 운영 카운트 묶음 { curProms, totalLaws, qnaNoAnswer, todayLogins } */
	Map<String, Object> selectDashCounts();

	/** 관리자 대시보드 — 승인대기(최신 워크행=승인요청, 배지와 동일 기준) 최근 n건 */
	List<Map<String, Object>> selectDashPendingWorks(@Param("n") int n);

	/** 관리자 대시보드 — 최근 워크플로 처리 n건(상태 무관, IPWRK_NO 역순) */
	List<Map<String, Object>> selectDashRecentWorks(@Param("n") int n);

	/** 작성자 대시보드 — 내가 신청한 심사중(최신 워크=승인요청 & 요청자=나) 회차 수. userId=로그인 ID(SUSER_ID 규약) */
	int selectDashMyPendingCnt(@Param("userId") String userId);

	/** 작성자 대시보드 — 내 요청 현황 top N { promNo, title, status, actorNm, insDt, reason } */
	List<Map<String, Object>> selectDashMyWorks(@Param("userId") String userId, @Param("n") int n);
}
