/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/sym/ccm/cca/service/impl/EgovCcmCodeServiceImpl.java
 *
 * 공통코드 그룹/상세 통합 관리 ServiceImpl.
 * PK 는 자연키(CODE_ID / CODE_ID+CODE) — 채번 없음. 서버측 필수/중복/PK 불변 검증 포함.
 */
package egovframework.com.sym.ccm.cca.service.impl;

import java.util.List;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import egovframework.com.sym.ccm.cca.mapper.EgovCcmCodeMapper;
import egovframework.com.sym.ccm.cca.service.CmmnDetailCodeVO;
import egovframework.com.sym.ccm.cca.service.EgovCcmCodeService;
import egovframework.com.sym.ccm.cca.service.CmmnCodeVO;

/**
 * 공통코드 통합 관리 ServiceImpl
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.08   RLMS 전환팀   최초 생성 (ccm cca/cde 통합 대체)
 * </pre>
 */
@Service("egovCcmCodeService")
public class EgovCcmCodeServiceImpl implements EgovCcmCodeService {

	@Resource
	private EgovCcmCodeMapper codeMapper;

	@Override
	public List<CmmnCodeVO> selectCodeList() throws Exception {
		return codeMapper.selectCodeList();
	}

	@Override
	public List<CmmnDetailCodeVO> selectDetailListAll() throws Exception {
		return codeMapper.selectDetailListAll();
	}

	@Override
	public CmmnDetailCodeVO selectDetail(String codeId, String code) throws Exception {
		return codeMapper.selectDetail(codeId, code);
	}

	@Override
	public void insertCode(CmmnCodeVO vo) throws Exception {
		normalizeCode(vo);
		requireText(vo.getCodeId(), "코드그룹 ID를 입력하세요.");
		requireText(vo.getCodeIdNm(), "코드그룹명을 입력하세요.");
		if (codeMapper.selectCode(vo.getCodeId()) != null) {
			throw new IllegalArgumentException("이미 존재하는 코드그룹 ID 입니다: " + vo.getCodeId());
		}
		codeMapper.insertCode(vo);
	}

	@Override
	public void updateCode(CmmnCodeVO vo) throws Exception {
		normalizeCode(vo);
		requireText(vo.getCodeId(), "코드그룹 ID가 없습니다.");
		requireText(vo.getCodeIdNm(), "코드그룹명을 입력하세요.");
		if (codeMapper.updateCode(vo) == 0) {
			throw new IllegalArgumentException("존재하지 않는 코드그룹입니다: " + vo.getCodeId());
		}
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteCode(String codeId) throws Exception {
		requireText(codeId, "코드그룹 ID가 없습니다.");
		// FK(COMTCCMMNDETAILCODE_FK1) — 상세 먼저 일괄 삭제 후 그룹 삭제
		codeMapper.deleteDetailsByCodeId(codeId.trim());
		if (codeMapper.deleteCode(codeId.trim()) == 0) {
			throw new IllegalArgumentException("존재하지 않는 코드그룹입니다: " + codeId);
		}
	}

	@Override
	public void insertDetail(CmmnDetailCodeVO vo) throws Exception {
		normalizeDetail(vo);
		requireText(vo.getCodeId(), "코드그룹 ID가 없습니다.");
		requireText(vo.getCode(), "상세코드를 입력하세요.");
		requireText(vo.getCodeNm(), "상세코드명을 입력하세요.");
		if (codeMapper.selectCode(vo.getCodeId()) == null) {
			throw new IllegalArgumentException("존재하지 않는 코드그룹입니다: " + vo.getCodeId());
		}
		if (codeMapper.selectDetail(vo.getCodeId(), vo.getCode()) != null) {
			throw new IllegalArgumentException("이미 존재하는 상세코드입니다: " + vo.getCode());
		}
		codeMapper.insertDetail(vo);
	}

	@Override
	public void updateDetail(CmmnDetailCodeVO vo) throws Exception {
		normalizeDetail(vo);
		requireText(vo.getCodeId(), "코드그룹 ID가 없습니다.");
		requireText(vo.getCode(), "상세코드가 없습니다.");
		requireText(vo.getCodeNm(), "상세코드명을 입력하세요.");
		if (codeMapper.updateDetail(vo) == 0) {
			throw new IllegalArgumentException("존재하지 않는 상세코드입니다: " + vo.getCode());
		}
	}

	@Override
	public void deleteDetail(String codeId, String code) throws Exception {
		requireText(codeId, "코드그룹 ID가 없습니다.");
		requireText(code, "상세코드가 없습니다.");
		if (codeMapper.deleteDetail(codeId.trim(), code.trim()) == 0) {
			throw new IllegalArgumentException("존재하지 않는 상세코드입니다: " + code);
		}
	}

	// ── 정규화/검증 ─────────────────────────────────────────────

	private void normalizeCode(CmmnCodeVO vo) {
		if (vo.getCodeId() != null)   vo.setCodeId(vo.getCodeId().trim());
		if (vo.getCodeIdNm() != null) vo.setCodeIdNm(vo.getCodeIdNm().trim());
		vo.setUseAt("N".equals(vo.getUseAt()) ? "N" : "Y");
	}

	private void normalizeDetail(CmmnDetailCodeVO vo) {
		if (vo.getCodeId() != null) vo.setCodeId(vo.getCodeId().trim());
		if (vo.getCode() != null)   vo.setCode(vo.getCode().trim());
		if (vo.getCodeNm() != null) vo.setCodeNm(vo.getCodeNm().trim());
		vo.setUseAt("N".equals(vo.getUseAt()) ? "N" : "Y");
	}

	private void requireText(String s, String msg) {
		if (s == null || s.trim().isEmpty()) {
			throw new IllegalArgumentException(msg);
		}
	}
}
