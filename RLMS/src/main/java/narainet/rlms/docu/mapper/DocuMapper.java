/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/docu/mapper/DocuMapper.java
 *
 * 별표/별지서식(TB_DOCU) Mapper.
 *  - 누적(상속) 조회: 같은 lawId 회차들 중 SITEM 별 최신 행 (레거시 DocumentService.getSelectSql 이식).
 *  - 단건 조회 / 본문 in-place 갱신.
 */
package narainet.rlms.docu.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.docu.service.DocuVO;

@Mapper
public interface DocuMapper {

	/**
	 * 회차의 별표/별지서식 누적 목록.
	 * = 같은 ILAW_ID 회차들(ILAW_NO ≤ #{lawNo}) 중 SITEM 별 최신 회차의 TB_DOCU 행. ORDER BY SITEM.
	 * (레거시 DocumentService.getSelectSql 의 IDOCU_NO 기반 누적 패턴 이식)
	 */
	List<DocuVO> selectDocuListCumulative(@Param("lawId") Long lawId, @Param("lawNo") Long lawNo);

	/** 단건 조회 (PK) */
	DocuVO selectDocuByNo(@Param("docuNo") Long docuNo);

	/** (promNo, SITEM) 복합키 조회 — 레거시 documentDao.get(promNo, fullItem). 개정분기 upsert 가드 */
	List<DocuVO> selectDocuByPromItem(@Param("promNo") Long promNo, @Param("item") String item);

	/** 본문/제목/사유/개정유형 in-place 갱신 (재이력 분기 없음 — 단건 편집용) */
	int updateDocuContent(DocuVO vo);

	/** 신규 별표/별지서식 등록 — PK(docuNo) 는 호출자가 egovDocuIdGnrService 로 채번 */
	int insertDocu(DocuVO vo);

	/** 단건 별표/별지서식 HARD delete (레거시 documentDao.delete 파리티).
	 *  개별 첨부는 트리거 TRG_DEL_DOCU 가 관련자료(SFLAG='DOCUMENT', SFULL_ITEM=SITEM) → TB_REL_FILE → TB_ATTACH 로 cascade.
	 *  (TB_DOCU_FILE 은 신규·레거시 모두 0행이라 2026-07-30 DROP — 첨부 축은 관련자료로 단일화) */
	int deleteDocu(@Param("docuNo") Long docuNo);
}
