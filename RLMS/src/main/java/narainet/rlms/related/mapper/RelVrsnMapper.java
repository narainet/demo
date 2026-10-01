/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/mapper/RelVrsnMapper.java
 *
 * 관련자료 허브(TB_REL_VRSN + TB_REL_VRSN_CATE) Mapper — READ + WRITE.
 *  - READ: 우측 패널 표시용. selectByPromNo / selectByPromAndFullItem / selectByNo.
 *  - WRITE: 8 액션 공통 진입점 (insert/update/delete/maxContentsId 등).
 *
 * 2026-05-14 — narainet.rlms.relvrsn → narainet.rlms.related 패키지 통합 이동.
 */
package narainet.rlms.related.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.related.service.RelVrsnVO;

@Mapper
public interface RelVrsnMapper {

	// ── READ ──────────────────────────────────────────────────────────

	/**
	 * 한 회차에 붙은 관련자료 모두 (PROMULGATION 단위) — 카테고리 정보 조인.
	 *  TB_REL_VRSN_CATE 와 LEFT JOIN — 카테고리가 없는 row 도 살린다(레거시 데이터 보호).
	 *  ORDER BY 카테고리 순서 → 동일 카테고리 안에선 ISEQ.
	 */
	List<RelVrsnVO> selectByPromNo(@Param("promNo") Long promNo);

	/**
	 * 사용자 뷰어 — 회차 자료 누적 (법령 lawId/lawNo, ICTNS_ID 별 최신 + SVRSN_YN 상속).
	 * notDiffLawNo 가 0 보다 크면 그 회차(전면개정류) 이전 자료는 누적 차단 — 레거시 getContentsList 파리티.
	 */
	List<RelVrsnVO> selectByPromCumulative(@Param("lawId") Long lawId,
			@Param("lawNo") Long lawNo,
			@Param("notDiffLawNo") Long notDiffLawNo);

	/**
	 * 한 회차의 한 조항(SFULL_ITEM)에 붙은 관련자료. PROVISION 플래그만.
	 *  fullItem=null/'' 이면 selectByPromNo 가 담당하므로 호출자에서 분기.
	 */
	List<RelVrsnVO> selectByPromAndFullItem(@Param("promNo") Long promNo,
			@Param("fullItem") String fullItem,
			@Param("flag") String flag);

	/**
	 * 별표/별지서식(TB_DOCU) 별 개별 첨부파일 (2026-07-30).
	 *  누적 별표 목록의 IDOCU_NO 를 넘기면 각 별표에 붙은 파일(docuNo/attNo/title/ext/fileSize)을 돌려준다.
	 *  축 = 관련자료 SFLAG='DOCUMENT' + SFULL_ITEM=별표 SITEM (신규 테이블 없음).
	 */
	List<java.util.Map<String, Object>> selectDocuFilesByDocuNos(
			@Param("docuNos") List<Long> docuNos);

	/** 단건 조회 (PK) — 액션 클릭 시 리소스 메타 + 본문 조회 진입점 */
	RelVrsnVO selectByNo(@Param("relVrsnNo") Long relVrsnNo);

	/**
	 * 같은 도메인(promNo + stable + flag + fullItem) 에 이미 마스터 row 가 있는지 조회.
	 *  LINK / DOMAIN_LINK 의 DELETE-then-INSERT 패턴이 재사용할 마스터를 식별할 때 사용.
	 *  여러 건이면 가장 큰 IRVRSN_NO 1건만 반환.
	 */
	RelVrsnVO selectExistingMaster(@Param("promNo")    Long   promNo,
			@Param("stable")   String stable,
			@Param("flag")     String flag,
			@Param("fullItem") String fullItem);

	// ── WRITE ─────────────────────────────────────────────────────────

	/** 마스터 INSERT — 호출자가 relVrsnNo 채번 후 채워서 전달 */
	int insert(RelVrsnVO vo);

	/** 마스터 UPDATE — 카테고리/순서/제목 등 메타 변경 */
	int update(RelVrsnVO vo);

	/** 마스터 DELETE — 상세 행 모두 삭제된 뒤 호출 */
	int deleteByNo(@Param("relVrsnNo") Long relVrsnNo);

	/**
	 * 부착 대상의 식별자만 갈아끼움 — 조 번호(TB_PROV_HTML.SITEM) 변경 시 관련자료 이관용(2026-07-30).
	 *  SFULL_ITEM 이 조항 식별자라 번호가 바뀌면 그대로 두면 첨부가 고아가 된다.
	 */
	int updateFullItemForProm(@Param("promNo")      Long   promNo,
			@Param("flag")        String flag,
			@Param("oldFullItem") String oldFullItem,
			@Param("newFullItem") String newFullItem);

	/**
	 * 새 콘텐츠 ID — 동일 회차/플래그/조항 안에서의 회차간 누적 추적 키.
	 *  MAX(ICTNS_ID) + 1 (디폴트 1).
	 */
	Long getNewContentsId();

	/**
	 * 새 ISEQ — 회차 + 카테고리 안에서 다음 순서.
	 *  MAX(ISEQ) + 1 (디폴트 1).
	 */
	Integer getNextSeq(@Param("promNo") Long promNo,
			@Param("cateNo") Long cateNo);
}
