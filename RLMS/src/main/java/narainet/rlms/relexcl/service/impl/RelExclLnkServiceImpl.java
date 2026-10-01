/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/relexcl/service/impl/RelExclLnkServiceImpl.java
 */
package narainet.rlms.relexcl.service.impl;

import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.relexcl.mapper.RelExclLnkMapper;
import narainet.rlms.relexcl.service.RelExclLnkService;
import narainet.rlms.relexcl.service.RelExclLnkVO;

@Service("relExclLnkService")
public class RelExclLnkServiceImpl implements RelExclLnkService {

	@Resource(name = "relExclLnkMapper")
	private RelExclLnkMapper relExclLnkMapper;

	@Resource(name = "egovRelExclLnkIdGnrService")
	private EgovIdGnrService relExclLnkIdGnrService;

	@Override
	public List<RelExclLnkVO> selectExclList(Long exclLawId, String sysId) {
		return relExclLnkMapper.selectExclList(exclLawId, sysId);
	}

	@Override
	public RelExclLnkVO selectByNo(Long relnkNo) {
		return relExclLnkMapper.selectByNo(relnkNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long insertExcl(RelExclLnkVO vo) throws Exception {
		if (vo.getSysId() == null || vo.getSysId().isEmpty()) {
			vo.setSysId("DEFAULT");
		}
		if (vo.getFlag() == null || vo.getFlag().isEmpty()) {
			throw new IllegalArgumentException("flag 가 비어있습니다.");
		}
		// 중복 검사
		int dup = relExclLnkMapper.countDuplicate(vo.getSysId(), vo.getExclLawId(),
				vo.getFlag(), vo.getGubunId(), vo.getCateNo(), vo.getLawId());
		if (dup > 0) return 0L;

		vo.setRelnkNo(relExclLnkIdGnrService.getNextLongId());
		relExclLnkMapper.insertExcl(vo);
		return vo.getRelnkNo();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int deleteByNo(Long relnkNo) {
		return relExclLnkMapper.deleteByNo(relnkNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int deleteByExclLawId(Long exclLawId, String sysId) {
		return relExclLnkMapper.deleteByExclLawId(exclLawId, sysId);
	}
}
