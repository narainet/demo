/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/common/mapper/CmmnCodeMapper.java
 *
 * eGov 표준 공통코드(ccm) 조회용 단순 매퍼.
 *  - 라벨/설명 조회만 (관리 화면은 /sym/ccm/cca 공통코드 통합 관리)
 *  - 결과: List<Map<String,Object>> — { code, codeNm, codeDc }
 */
package narainet.rlms.common.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CmmnCodeMapper {

	/**
	 * 그룹 코드(CODE_ID)에 속한 상세 코드 목록.
	 * @param codeId  COMTCCMMNDETAILCODE.CODE_ID (예: 'SGUBUN', 'COM101')
	 */
	List<Map<String,Object>> selectCmmnCodeList(@Param("codeId") String codeId);

	/** 그룹의 전체 상세(USE_AT 무관, useAt 포함) — 숨김 구분 판정/분류관리 트리 표시용 */
	List<Map<String,Object>> selectCmmnCodeListAll(@Param("codeId") String codeId);
}
