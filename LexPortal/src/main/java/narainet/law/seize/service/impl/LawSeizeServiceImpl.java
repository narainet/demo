/*
 * 물리적 저장 경로: /src/main/java/narainet/law/seize/service/impl/LawSeizeServiceImpl.java
 *
 * 압류관리 (LAW_MODULE_DESIGN.md §7.10) — 게시판형 CRUD + 첨부(표준 COMTNFILE) + 상세 조회수 증가.
 *  첨부 개수·용량(5개·10MB) 검증은 컨트롤러에서 LawFileSupport.validateFiles 로 선검증.
 */
package narainet.law.seize.service.impl;

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

import narainet.law.common.service.LawFileSupport;
import narainet.law.seize.mapper.LawSeizeMapper;
import narainet.law.seize.service.LawSeizeService;
import narainet.law.seize.service.LawSeizeVO;

@Service("lawSeizeService")
public class LawSeizeServiceImpl implements LawSeizeService {

	@Resource(name = "lawSeizeMapper")
	private LawSeizeMapper lawSeizeMapper;

	@Resource(name = "egovLawSeizeIdGnrService")
	private EgovIdGnrService seizeIdGnrService;

	@Resource(name = "lawFileSupport")
	private LawFileSupport lawFileSupport;

	/** 첨부 저장 폴더 — D:/upload/law/seize/ (압류) */
	private static final String FILE_DIR = "seize";

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	@Override
	public Map<String, Object> getList(LawSeizeVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		result.put("resultList", lawSeizeMapper.selectSeizeList(searchVO));
		result.put("resultCnt", lawSeizeMapper.selectSeizeCnt(searchVO));
		return result;
	}

	@Override
	@Transactional
	public LawSeizeVO getSeize(Long seizeId, boolean readCntUp) throws Exception {
		if (readCntUp) {
			lawSeizeMapper.updateReadCnt(seizeId);
		}
		LawSeizeVO vo = lawSeizeMapper.selectSeize(seizeId);
		if (vo != null) {
			vo.setFiles(lawFileSupport.list(vo.getAtchFileId()));
		}
		return vo;
	}

	@Override
	@Transactional
	public Long save(LawSeizeVO vo, List<MultipartFile> files, String userId) throws Exception {
		String ts = now();
		if (vo.getSeizeId() == null) {
			vo.setAtchFileId(lawFileSupport.saveFiles(null, files, "LAW_", FILE_DIR));
			vo.setSeizeId((long) seizeIdGnrService.getNextIntegerId());
			vo.setRegUserId(userId);
			vo.setRegDt(ts);
			lawSeizeMapper.insertSeize(vo);
		} else {
			LawSeizeVO before = lawSeizeMapper.selectSeize(vo.getSeizeId());
			if (before == null) {
				throw new IllegalStateException("존재하지 않는 압류 정보입니다.");
			}
			vo.setAtchFileId(lawFileSupport.saveFiles(before.getAtchFileId(), files, "LAW_", FILE_DIR));
			vo.setUpdUserId(userId);
			vo.setUpdDt(ts);
			lawSeizeMapper.updateSeize(vo);
		}
		return vo.getSeizeId();
	}

	@Override
	@Transactional
	public void delete(Long seizeId) throws Exception {
		lawSeizeMapper.deleteSeize(seizeId);
	}
}
