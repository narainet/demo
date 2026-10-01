/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/gaejung/service/impl/GaejungServiceImpl.java
 */
package narainet.rlms.gaejung.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.gaejung.mapper.GaejungMapper;
import narainet.rlms.gaejung.service.GaejungService;
import narainet.rlms.gaejung.service.GaejungVO;

/**
 * 개정 종류 Service 구현체
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Service("gaejungService")
public class GaejungServiceImpl extends EgovAbstractServiceImpl implements GaejungService {

	@Resource(name = "gaejungMapper")
	private GaejungMapper gaejungMapper;

	@Resource(name = "egovGaejungIdGnrService")
	private EgovIdGnrService gaejungIdGnrService;

	@Override
	public Map<String, Object> selectGaejungList(GaejungVO vo) {
		List<GaejungVO> list = gaejungMapper.selectGaejungList(vo);
		int cnt = gaejungMapper.selectGaejungListCnt(vo);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public List<GaejungVO> selectAllForSelector() {
		return gaejungMapper.selectAllActive();
	}

	@Override
	public GaejungVO selectGaejungByNo(Long gaejungNo) {
		return gaejungMapper.selectGaejungByNo(gaejungNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void insertGaejung(GaejungVO vo) throws Exception {
		GaejungVO exist = gaejungMapper.selectGaejungByName(vo.getGaejungNm());
		if (exist != null && "N".equals(exist.getDelYn())) {
			throw processException("gaejung.duplicate");
		}
		if (vo.getSeq() == null) vo.setSeq(gaejungMapper.selectMaxSeq());
		vo.setGaejungNo(gaejungIdGnrService.getNextLongId());
		gaejungMapper.insertGaejung(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateGaejung(GaejungVO vo) throws Exception {
		GaejungVO target = gaejungMapper.selectGaejungByNo(vo.getGaejungNo());
		if (target == null) throw processException("gaejung.notfound");
		gaejungMapper.updateGaejung(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateGaejungList(List<GaejungVO> list) throws Exception {
		if (list == null || list.isEmpty()) return;
		for (GaejungVO vo : list) updateGaejung(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteGaejung(Long gaejungNo) throws Exception {
		GaejungVO target = gaejungMapper.selectGaejungByNo(gaejungNo);
		if (target == null) throw processException("gaejung.notfound");
		if (gaejungMapper.selectPromCntByGaejung(gaejungNo) > 0)
			throw processException("gaejung.hasproms");
		gaejungMapper.updateGaejungDeleted(gaejungNo);
	}
}
