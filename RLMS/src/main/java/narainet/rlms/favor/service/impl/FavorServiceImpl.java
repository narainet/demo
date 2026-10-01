/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/favor/service/impl/FavorServiceImpl.java
 */
package narainet.rlms.favor.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.favor.mapper.FavorMapper;
import narainet.rlms.favor.service.FavorService;
import narainet.rlms.favor.service.FavorVO;

@Service("favorService")
public class FavorServiceImpl extends EgovAbstractServiceImpl implements FavorService {

	@Resource(name = "favorMapper")
	private FavorMapper favorMapper;

	@Resource(name = "egovFavorIdGnrService")
	private EgovIdGnrService favorIdGnrService;

	@Override
	public Map<String, Object> selectMyFavorList(String userId, FavorVO vo) {
		List<FavorVO> list = favorMapper.selectMyFavorList(userId, vo);
		int cnt = favorMapper.selectMyFavorListCnt(userId, vo);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public FavorVO selectFavorByLawItem(String userId, Long lawId, String item, String sysId) {
		return favorMapper.selectFavorByLawItem(userId, lawId, item, sysId);
	}

	@Override
	public List<FavorVO> selectFavorListByLaw(String userId, Long lawId, String sysId) {
		return favorMapper.selectFavorListByLaw(userId, lawId, sysId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void addFavor(FavorVO vo) throws Exception {
		// SSYS_ID 는 강제 세팅하지 않음(단일 시스템 — 필터 미사용, null 허용). 프론트 미전송 → null 저장.
		FavorVO exist = favorMapper.selectFavorByLawItem(
				vo.getUserId(), vo.getLawId(), vo.getItem(), vo.getSysId());
		if (exist != null) {
			throw processException("favor.duplicate");
		}
		vo.setFavorNo(favorIdGnrService.getNextLongId());
		favorMapper.insertFavor(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void touchSeen(String userId, Long lawId, Long lawNo) {
		if (userId == null || userId.isEmpty() || lawId == null || lawNo == null) {
			return;
		}
		favorMapper.touchFavorSeen(userId, lawId, lawNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateFavor(FavorVO vo, String userId) throws Exception {
		FavorVO target = favorMapper.selectFavorByNo(vo.getFavorNo());
		if (target == null) throw processException("favor.notfound");
		if (!target.getUserId().equals(userId)) throw processException("favor.no.permission");
		favorMapper.updateFavor(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteFavor(Long favorNo, String userId) throws Exception {
		FavorVO target = favorMapper.selectFavorByNo(favorNo);
		if (target == null) throw processException("favor.notfound");
		if (!target.getUserId().equals(userId)) throw processException("favor.no.permission");
		favorMapper.deleteFavor(favorNo);
	}
}
