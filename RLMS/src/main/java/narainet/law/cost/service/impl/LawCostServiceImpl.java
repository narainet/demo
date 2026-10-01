/*
 * 물리적 저장 경로: /src/main/java/narainet/law/cost/service/impl/LawCostServiceImpl.java
 *
 * 소송비용 조회·등록 (LAW_MODULE_DESIGN.md §7.3). 등록·수정은 사건 상세 탭에서.
 */
package narainet.law.cost.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.law.cost.mapper.LawCostMapper;
import narainet.law.cost.service.LawCostService;
import narainet.law.cost.service.LawSuitCostVO;

@Service("lawCostService")
public class LawCostServiceImpl implements LawCostService {

	@Resource(name = "lawCostMapper")
	private LawCostMapper lawCostMapper;

	@Resource(name = "egovLawCostIdGnrService")
	private EgovIdGnrService costIdGnrService;

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	@Override
	public Map<String, Object> getList(LawSuitCostVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		result.put("resultList", lawCostMapper.selectCostList(searchVO));
		result.put("resultCnt", lawCostMapper.selectCostCnt(searchVO));
		result.put("totalAmt", lawCostMapper.selectCostSum(searchVO));
		return result;
	}

	@Override
	public List<LawSuitCostVO> getListBySuit(Long suitId) throws Exception {
		return lawCostMapper.selectCostListBySuit(suitId);
	}

	@Override
	public LawSuitCostVO getCost(Long costId) throws Exception {
		return lawCostMapper.selectCost(costId);
	}

	@Override
	@Transactional
	public Long save(LawSuitCostVO vo, String userId) throws Exception {
		String ts = now();
		if (vo.getCostId() == null) {
			vo.setCostId((long) costIdGnrService.getNextIntegerId());
			vo.setRegUserId(userId);
			vo.setRegDt(ts);
			lawCostMapper.insertCost(vo);
		} else {
			vo.setUpdUserId(userId);
			vo.setUpdDt(ts);
			lawCostMapper.updateCost(vo);
		}
		return vo.getCostId();
	}

	@Override
	@Transactional
	public void delete(Long costId) throws Exception {
		lawCostMapper.deleteCost(costId);
	}
}
