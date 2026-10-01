/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/sym/ccm/cca/mapper/EgovCcmCodeMapper.java
 *
 * 공통코드 그룹/상세 통합 관리 Mapper.
 * SQL: /egovframework/mapper/com/sym/ccm/cca/EgovCcmCode_SQL_oracle.xml
 */
package egovframework.com.sym.ccm.cca.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import egovframework.com.sym.ccm.cca.service.CmmnDetailCodeVO;
import egovframework.com.sym.ccm.cca.service.CmmnCodeVO;

/**
 * 공통코드 통합 관리 Mapper
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.08   RLMS 전환팀   최초 생성 (ccm cca/cde 통합 대체)
 * </pre>
 */
@Mapper
public interface EgovCcmCodeMapper {

	/** 코드그룹 전체 (상세코드 수 포함, CODE_ID 순) */
	List<CmmnCodeVO> selectCodeList();

	/** 코드그룹 단건 */
	CmmnCodeVO selectCode(@Param("codeId") String codeId);

	int insertCode(CmmnCodeVO vo);

	int updateCode(CmmnCodeVO vo);

	int deleteCode(@Param("codeId") String codeId);

	/** 상세코드 전체 (트리 1회 로드용, CODE_ID·CODE 순) */
	List<CmmnDetailCodeVO> selectDetailListAll();

	/** 상세코드 단건 */
	CmmnDetailCodeVO selectDetail(@Param("codeId") String codeId, @Param("code") String code);

	int insertDetail(CmmnDetailCodeVO vo);

	int updateDetail(CmmnDetailCodeVO vo);

	int deleteDetail(@Param("codeId") String codeId, @Param("code") String code);

	/** 그룹 삭제 전 상세 일괄 삭제 (FK COMTCCMMNDETAILCODE_FK1) */
	int deleteDetailsByCodeId(@Param("codeId") String codeId);
}
