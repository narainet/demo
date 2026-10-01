/*
 * 물리적 저장 경로: /src/main/java/narainet/law/lawyer/service/impl/LawLawyerServiceImpl.java
 */
package narainet.law.lawyer.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.law.lawyer.mapper.LawLawyerMapper;
import narainet.law.lawyer.service.LawLawyerService;
import narainet.law.lawyer.service.LawLawyerVO;

@Service("lawLawyerService")
public class LawLawyerServiceImpl implements LawLawyerService {

	@Resource(name = "lawLawyerMapper")
	private LawLawyerMapper lawLawyerMapper;

	@Resource(name = "egovLawLawyerIdGnrService")
	private EgovIdGnrService lawyerIdGnrService;

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	@Override
	public Map<String, Object> getList(LawLawyerVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		result.put("resultList", lawLawyerMapper.selectLawyerList(searchVO));
		result.put("resultCnt", lawLawyerMapper.selectLawyerCnt(searchVO));
		return result;
	}

	@Override
	public LawLawyerVO getDetail(Long lawyerId) throws Exception {
		return lawLawyerMapper.selectLawyer(lawyerId);
	}

	@Override
	@Transactional
	public Long save(LawLawyerVO vo) throws Exception {
		if (vo.getLawyerId() == null) {
			vo.setLawyerId((long) lawyerIdGnrService.getNextIntegerId());
			vo.setRegDt(now());
			lawLawyerMapper.insertLawyer(vo);
		} else {
			vo.setUpdDt(now());
			lawLawyerMapper.updateLawyer(vo);
		}
		return vo.getLawyerId();
	}

	@Override
	@Transactional
	public void delete(Long lawyerId, String userId) throws Exception {
		int refs = lawLawyerMapper.countAssignRef(lawyerId);
		if (refs > 0) {
			throw new IllegalStateException("선임 이력이 " + refs + "건 있는 변호사는 삭제할 수 없습니다.");
		}
		LawLawyerVO vo = new LawLawyerVO();
		vo.setLawyerId(lawyerId);
		vo.setUpdUserId(userId);
		vo.setUpdDt(now());
		lawLawyerMapper.deleteLawyer(vo);
	}
}
