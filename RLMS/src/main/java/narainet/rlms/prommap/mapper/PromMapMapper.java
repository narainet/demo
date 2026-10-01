/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prommap/mapper/PromMapMapper.java
 *
 * 기능별분류(규정맵, TB_PROM_MAP) MyBatis @Mapper.
 * XML: /src/main/resources/egovframework/mapper/rlms/prommap/PromMap_SQL_oracle.xml
 */
package narainet.rlms.prommap.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.prommap.service.PromMapVO;

@Mapper
public interface PromMapMapper {

	/** 전체 기능별분류 트리 (CONNECT BY, 형제 정렬 = 폴더먼저→ISEQ). 표시(SDISP_YN='Y')만. */
	List<PromMapVO> selectMapTree(@Param("sysId") String sysId);

	/** PK 단건 */
	PromMapVO selectByNo(@Param("pmapNo") Long pmapNo);

	/** 직속 자식 (삭제 BFS / 트리 lazy 용) */
	List<PromMapVO> selectChildrenByRef(@Param("ref") Long ref, @Param("sysId") String sysId);

	/** 부모(ref) 안 정렬순서 MAX(ISEQ)+1 (표시 노드만) — 레거시 getMaxSequence 1:1 */
	int selectMaxSeq(@Param("ref") Long ref, @Param("sysId") String sysId);

	/**
	 * front 규정목록 — 한 폴더(ref) 직속 규정 leaf 들이 가리키는 현행 법령.
	 *   레거시 getPromulgationList(reference): 같은 ILAW_ID 의 현행(SEXISTING_YN='Y') 1건.
	 *   반환 = {promNo, promTitle, promDate, cateFullName}.
	 *   applyReadGate=true → 분류별 열람제한(TB_CATE_READER) 게이트 적용(면제역할이면 false 로).
	 */
	List<PromMapVO> selectPromulgationList(@Param("ref") Long ref,
			@Param("applyReadGate") boolean applyReadGate,
			@Param("readerEsntlId") String readerEsntlId,
			@Param("readerOrgnztId") String readerOrgnztId);

	/** 한 분류(cateNo)의 현행 법령 목록 (재귀 임포트용) — {promNo, title}. */
	List<Map<String, Object>> selectExistingPromsByCate(@Param("cateNo") Long cateNo);

	/** 신규 등록 (PK 는 Service 에서 IdGnr 채번) */
	int insertMap(PromMapVO vo);

	/** 노드명 변경 (레거시 updateDo) */
	int updateMapName(@Param("pmapNo") Long pmapNo, @Param("name") String name);

	/** 단건 삭제 */
	int deleteMap(@Param("pmapNo") Long pmapNo);

	/** 특정 법령을 가리키는 규정 leaf 전부 삭제 (deleteProm 연동 — 고아 방지) */
	int deleteMapByPromNo(@Param("promNo") Long promNo);
}
