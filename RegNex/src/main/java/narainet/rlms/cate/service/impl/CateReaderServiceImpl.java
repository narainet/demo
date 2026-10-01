/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/impl/CateReaderServiceImpl.java
 */
package narainet.rlms.cate.service.impl;

import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.springframework.stereotype.Service;

import narainet.rlms.cate.mapper.CateReaderMapper;
import narainet.rlms.cate.service.CateReaderService;
import narainet.rlms.cate.service.CateReaderVO;

/**
 * 분류별 열람제한 서비스 구현.
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.07   RLMS 전환팀   최초 생성 (TB_CATE_OWNER 패턴 미러 — read 축 신설)
 * </pre>
 */
@Service("cateReaderService")
public class CateReaderServiceImpl extends EgovAbstractServiceImpl implements CateReaderService {

	@Resource(name = "cateReaderMapper")
	private CateReaderMapper cateReaderMapper;

	@Override
	public List<CateReaderVO> selectReaders(Long cateNo) {
		return cateReaderMapper.selectReadersByCate(cateNo);
	}

	@Override
	public void addReader(CateReaderVO vo) {
		if (vo == null || vo.getCateNo() == null
				|| isBlank(vo.getReaderTy()) || isBlank(vo.getReaderId())) {
			throw new IllegalArgumentException("분류/대상유형/열람대상은 필수입니다.");
		}
		String readerTy = vo.getReaderTy().trim().toUpperCase();
		if (!"DEPT".equals(readerTy) && !"USER".equals(readerTy)) {
			throw new IllegalArgumentException("대상유형은 DEPT 또는 USER 만 가능합니다.");
		}
		vo.setReaderTy(readerTy);
		vo.setReaderId(vo.getReaderId().trim());
		if (isBlank(vo.getInheritYn())) {
			vo.setInheritYn("Y");
		}
		// 개인 대상은 ESNTL_ID 실존 검증 — 오타 1건이 "제한 활성 + 매칭 0명" = 분류 전면 차단이 되는
		// fail-dangerous 를 등록 시점에 차단 (작성자(owner) 축은 오타=권한 미부여로 fail-safe 라 미검증)
		if ("USER".equals(readerTy) && cateReaderMapper.countUserExists(vo.getReaderId()) == 0) {
			throw new IllegalArgumentException("존재하지 않는 사용자 고유아이디입니다: " + vo.getReaderId());
		}
		// 중복(PK)이면 조용히 무시 — N명 추가 시 재클릭 안전
		if (cateReaderMapper.countReader(vo.getCateNo(), vo.getReaderTy(), vo.getReaderId()) > 0) {
			return;
		}
		cateReaderMapper.insertReader(vo);
	}

	@Override
	public void removeReader(Long cateNo, String readerTy, String readerId) {
		cateReaderMapper.deleteReader(cateNo, readerTy, readerId);
	}

	@Override
	public boolean canRead(String esntlId, String orgnztId, Long cateNo) {
		if (cateNo == null) {
			// 분류 미지정 규정은 제한을 걸 대상이 없음 — 공개
			return true;
		}
		return cateReaderMapper.countReadBlock(esntlId, orgnztId, cateNo) == 0;
	}

	@Override
	public List<Long> selectBlockedCateNos(String esntlId, String orgnztId) {
		return cateReaderMapper.selectBlockedCateNos(esntlId, orgnztId);
	}

	@Override
	public List<Long> selectBlockedPromNos(String esntlId, String orgnztId) {
		return cateReaderMapper.selectBlockedPromNos(esntlId, orgnztId);
	}

	@Override
	public java.util.List<java.util.Map<String, Object>> searchUsers(String keyword) {
		if (isBlank(keyword)) {
			return new java.util.ArrayList<>();
		}
		return cateReaderMapper.selectUserSearch(keyword.trim());
	}

	// ── 구분(최상위 SGUBUN_ID) 단위 열람제한 ─────────────────────────

	@Override
	public List<CateReaderVO> selectGubunReaders(String gubunId) {
		return cateReaderMapper.selectGubunReaders(gubunId);
	}

	@Override
	public void addGubunReader(CateReaderVO vo) {
		if (vo == null || isBlank(vo.getGubunId())
				|| isBlank(vo.getReaderTy()) || isBlank(vo.getReaderId())) {
			throw new IllegalArgumentException("구분/대상유형/열람대상은 필수입니다.");
		}
		String readerTy = vo.getReaderTy().trim().toUpperCase();
		if (!"DEPT".equals(readerTy) && !"USER".equals(readerTy)) {
			throw new IllegalArgumentException("대상유형은 DEPT 또는 USER 만 가능합니다.");
		}
		vo.setGubunId(vo.getGubunId().trim());
		vo.setReaderTy(readerTy);
		vo.setReaderId(vo.getReaderId().trim());
		// 개인 대상은 ESNTL_ID 실존 검증 — 오타=구분 전면 차단 fail-dangerous 방지 (분류 축과 동일)
		if ("USER".equals(readerTy) && cateReaderMapper.countUserExists(vo.getReaderId()) == 0) {
			throw new IllegalArgumentException("존재하지 않는 사용자 고유아이디입니다: " + vo.getReaderId());
		}
		// 중복(PK)이면 조용히 무시 — N명 추가 시 재클릭 안전
		if (cateReaderMapper.countGubunReader(vo.getGubunId(), vo.getReaderTy(), vo.getReaderId()) > 0) {
			return;
		}
		cateReaderMapper.insertGubunReader(vo);
	}

	@Override
	public void removeGubunReader(String gubunId, String readerTy, String readerId) {
		cateReaderMapper.deleteGubunReader(gubunId, readerTy, readerId);
	}

	private boolean isBlank(String s) {
		return s == null || s.trim().length() == 0;
	}
}
