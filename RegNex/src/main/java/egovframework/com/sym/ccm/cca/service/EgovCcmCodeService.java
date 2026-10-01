/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/sym/ccm/cca/service/EgovCcmCodeService.java
 *
 * 공통코드 그룹/상세 통합 관리 Service.
 */
package egovframework.com.sym.ccm.cca.service;

import java.util.List;

/**
 * 공통코드 통합 관리 Service
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.08   RLMS 전환팀   최초 생성 (ccm cca/cde 통합 대체)
 * </pre>
 */
public interface EgovCcmCodeService {

	List<CmmnCodeVO> selectCodeList() throws Exception;

	List<CmmnDetailCodeVO> selectDetailListAll() throws Exception;

	/** 상세코드 단건 — 보호코드그룹 전용 화면 등 외부 모듈의 단건 조회용 */
	CmmnDetailCodeVO selectDetail(String codeId, String code) throws Exception;

	void insertCode(CmmnCodeVO vo) throws Exception;

	void updateCode(CmmnCodeVO vo) throws Exception;

	/** 그룹 삭제 — 하위 상세코드까지 일괄 삭제(트랜잭션) */
	void deleteCode(String codeId) throws Exception;

	void insertDetail(CmmnDetailCodeVO vo) throws Exception;

	void updateDetail(CmmnDetailCodeVO vo) throws Exception;

	void deleteDetail(String codeId, String code) throws Exception;
}
