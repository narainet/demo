/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/impl/CateOwnerServiceImpl.java
 */
package narainet.rlms.cate.service.impl;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.springframework.stereotype.Service;

import narainet.rlms.cate.mapper.CateOwnerMapper;
import narainet.rlms.cate.service.CateOwnerService;
import narainet.rlms.cate.service.CateOwnerVO;

/**
 * 분류별 작성자(소유) 서비스 구현.
 *
 * <pre>
 * << 개정이력 >>
 *   2026.06.09   RLMS 전환팀   최초 생성 (분류정책 단순화)
 * </pre>
 */
@Service("cateOwnerService")
public class CateOwnerServiceImpl extends EgovAbstractServiceImpl implements CateOwnerService {

	@Resource(name = "cateOwnerMapper")
	private CateOwnerMapper cateOwnerMapper;

	@Override
	public List<CateOwnerVO> selectOwners(Long cateNo) {
		return cateOwnerMapper.selectOwnersByCate(cateNo);
	}

	@Override
	public void addOwner(CateOwnerVO vo) {
		if (vo == null || vo.getCateNo() == null
				|| isBlank(vo.getOwnerTy()) || isBlank(vo.getOwnerId())) {
			throw new IllegalArgumentException("분류/소유유형/소유대상은 필수입니다.");
		}
		String ownerTy = vo.getOwnerTy().trim().toUpperCase();
		if (!"DEPT".equals(ownerTy) && !"USER".equals(ownerTy)) {
			throw new IllegalArgumentException("소유유형은 DEPT 또는 USER 만 가능합니다.");
		}
		vo.setOwnerTy(ownerTy);
		vo.setOwnerId(vo.getOwnerId().trim());
		if (isBlank(vo.getInheritYn())) {
			vo.setInheritYn("Y");
		}
		// 중복(PK)이면 조용히 무시 — N명 추가 시 재클릭 안전
		if (cateOwnerMapper.countOwner(vo.getCateNo(), vo.getOwnerTy(), vo.getOwnerId()) > 0) {
			return;
		}
		cateOwnerMapper.insertOwner(vo);
	}

	@Override
	public void removeOwner(Long cateNo, String ownerTy, String ownerId) {
		cateOwnerMapper.deleteOwner(cateNo, ownerTy, ownerId);
	}

	@Override
	public boolean canEdit(String esntlId, String orgnztId, Long cateNo) {
		if (cateNo == null) {
			return false;
		}
		return cateOwnerMapper.countAuthor(esntlId, orgnztId, cateNo) > 0;
	}

	@Override
	public boolean hasOwnerRules(Long cateNo) {
		return cateNo != null && cateOwnerMapper.countApplicableOwnerRules(cateNo) > 0;
	}

	@Override
	public List<Map<String, Object>> selectDeptOptions() {
		return cateOwnerMapper.selectDeptOptions();
	}

	private boolean isBlank(String s) {
		return s == null || s.trim().length() == 0;
	}
}
