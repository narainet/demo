/*
 * 물리적 저장 경로: /src/main/java/narainet/law/assign/service/impl/LawAssignServiceImpl.java
 *
 * 선임관리 + 간이 만족도 (LAW_MODULE_DESIGN.md §7.6·§4.3).
 *  - 선임: 계약서 첨부 표준 COMTNFILE(신규 채번·수정 이어붙임), 소프트삭제 아님(물리삭제).
 *  - 만족도: 선임(ASSIGN_ID) 단위 1인 1회 MERGE.
 */
package narainet.law.assign.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import narainet.law.assign.mapper.LawAssignMapper;
import narainet.law.assign.service.LawAssignService;
import narainet.law.assign.service.LawLawyerSatisVO;
import narainet.law.assign.service.LawSuitLawyerVO;
import narainet.law.common.service.LawFileSupport;

@Service("lawAssignService")
public class LawAssignServiceImpl implements LawAssignService {

	@Resource(name = "lawAssignMapper")
	private LawAssignMapper lawAssignMapper;

	@Resource(name = "egovLawAssignIdGnrService")
	private EgovIdGnrService assignIdGnrService;

	@Resource(name = "lawFileSupport")
	private LawFileSupport lawFileSupport;

	/** 첨부 저장 폴더 — D:/upload/law/assign/ (선임 계약서) */
	private static final String FILE_DIR = "assign";

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	@Override
	public Map<String, Object> getList(LawSuitLawyerVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		List<LawSuitLawyerVO> list = lawAssignMapper.selectAssignList(searchVO);
		attachFiles(list);
		result.put("resultList", list);
		result.put("resultCnt", lawAssignMapper.selectAssignCnt(searchVO));
		return result;
	}

	@Override
	public List<LawSuitLawyerVO> getListBySuit(Long suitId) throws Exception {
		List<LawSuitLawyerVO> list = lawAssignMapper.selectAssignListBySuit(suitId);
		attachFiles(list);
		return list;
	}

	private void attachFiles(List<LawSuitLawyerVO> list) throws Exception {
		if (list == null) {
			return;
		}
		for (LawSuitLawyerVO vo : list) {
			vo.setFiles(lawFileSupport.list(vo.getAtchFileId()));
		}
	}

	@Override
	public LawSuitLawyerVO getAssign(Long assignId) throws Exception {
		return lawAssignMapper.selectAssign(assignId);
	}

	@Override
	@Transactional
	public Long save(LawSuitLawyerVO vo, List<MultipartFile> files, String userId) throws Exception {
		String ts = now();
		if (vo.getAssignId() == null) {
			vo.setAtchFileId(lawFileSupport.saveFiles(null, files, "LAW_", FILE_DIR));
			vo.setAssignId((long) assignIdGnrService.getNextIntegerId());
			vo.setRegUserId(userId);
			vo.setRegDt(ts);
			lawAssignMapper.insertAssign(vo);
		} else {
			LawSuitLawyerVO before = lawAssignMapper.selectAssign(vo.getAssignId());
			if (before == null) {
				throw new IllegalStateException("존재하지 않는 선임입니다.");
			}
			vo.setAtchFileId(lawFileSupport.saveFiles(before.getAtchFileId(), files, "LAW_", FILE_DIR));
			vo.setUpdUserId(userId);
			vo.setUpdDt(ts);
			lawAssignMapper.updateAssign(vo);
		}
		return vo.getAssignId();
	}

	@Override
	@Transactional
	public void delete(Long assignId) throws Exception {
		lawAssignMapper.deleteAssign(assignId);
	}

	// ── 만족도 ──
	@Override
	public List<LawLawyerSatisVO> getSatisList(Long assignId) throws Exception {
		return lawAssignMapper.selectSatisList(assignId);
	}

	@Override
	public LawLawyerSatisVO getMySatis(Long assignId, String emplyrId) throws Exception {
		return lawAssignMapper.selectMySatis(assignId, emplyrId);
	}

	@Override
	@Transactional
	public void saveSatis(LawLawyerSatisVO vo) throws Exception {
		lawAssignMapper.mergeSatis(vo);
	}
}
