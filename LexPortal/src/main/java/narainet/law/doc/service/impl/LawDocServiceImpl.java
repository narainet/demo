/*
 * 물리적 저장 경로: /src/main/java/narainet/law/doc/service/impl/LawDocServiceImpl.java
 *
 * 소송문서 조회·승인 (LAW_MODULE_DESIGN.md §7.2).
 *  - 등록=승인상태 '대기'(S001). 내용·파일 수정 시 '대기'로 자동 리셋(재승인 대상).
 *  - 승인/반려: 자기 등록 문서 승인 허용(직무분리 강제 없음), 반려는 사유 필수(컨트롤러 검증).
 *  - 첨부는 표준 COMTNFILE(LawFileSupport). 다운로드=표준 FileDown.do / ZIP=표준 FileZipDown.do.
 */
package narainet.law.doc.service.impl;

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
import narainet.law.doc.mapper.LawDocMapper;
import narainet.law.doc.service.LawDocService;
import narainet.law.doc.service.LawSuitDocVO;

@Service("lawDocService")
public class LawDocServiceImpl implements LawDocService {

	@Resource(name = "lawDocMapper")
	private LawDocMapper lawDocMapper;

	@Resource(name = "egovLawDocIdGnrService")
	private EgovIdGnrService docIdGnrService;

	@Resource(name = "lawFileSupport")
	private LawFileSupport lawFileSupport;

	/** 첨부 저장 폴더 — D:/upload/law/doc/ (소송문서) */
	private static final String FILE_DIR = "doc";

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	@Override
	public Map<String, Object> getList(LawSuitDocVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		List<LawSuitDocVO> list = lawDocMapper.selectDocList(searchVO);
		attachFiles(list);
		result.put("resultList", list);
		result.put("resultCnt", lawDocMapper.selectDocCnt(searchVO));
		return result;
	}

	@Override
	public List<String> getZipAtchFileIds(LawSuitDocVO searchVO) throws Exception {
		return lawDocMapper.selectDocAtchFileIds(searchVO);
	}

	@Override
	public List<LawSuitDocVO> getListBySuit(Long suitId) throws Exception {
		List<LawSuitDocVO> list = lawDocMapper.selectDocListBySuit(suitId);
		attachFiles(list);
		return list;
	}

	private void attachFiles(List<LawSuitDocVO> list) throws Exception {
		if (list == null) {
			return;
		}
		for (LawSuitDocVO vo : list) {
			vo.setFiles(lawFileSupport.list(vo.getAtchFileId()));
		}
	}

	@Override
	public LawSuitDocVO getDoc(Long docId) throws Exception {
		return lawDocMapper.selectDoc(docId);
	}

	@Override
	@Transactional
	public Long save(LawSuitDocVO vo, List<MultipartFile> files, String userId) throws Exception {
		String ts = now();
		if (vo.getDocId() == null) {
			vo.setAtchFileId(lawFileSupport.saveFiles(null, files, "LAW_", FILE_DIR));
			vo.setDocId((long) docIdGnrService.getNextIntegerId());
			vo.setRegUserId(userId);
			vo.setRegDt(ts);
			lawDocMapper.insertDoc(vo);
		} else {
			LawSuitDocVO before = lawDocMapper.selectDoc(vo.getDocId());
			if (before == null) {
				throw new IllegalStateException("존재하지 않는 문서입니다.");
			}
			vo.setAtchFileId(lawFileSupport.saveFiles(before.getAtchFileId(), files, "LAW_", FILE_DIR));
			vo.setUpdUserId(userId);
			vo.setUpdDt(ts);
			lawDocMapper.updateDoc(vo); // 승인상태 '대기' 리셋은 매퍼 SQL 이 수행
		}
		return vo.getDocId();
	}

	@Override
	@Transactional
	public void delete(Long docId) throws Exception {
		lawDocMapper.deleteDoc(docId);
	}

	// ── 승인 워크플로 ──
	@Override
	public Map<String, Object> getApprovalList(LawSuitDocVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		List<LawSuitDocVO> list = lawDocMapper.selectApprovalList(searchVO);
		attachFiles(list);
		result.put("resultList", list);
		result.put("resultCnt", lawDocMapper.selectApprovalCnt(searchVO));
		return result;
	}

	@Override
	@Transactional
	public void approve(LawSuitDocVO vo) throws Exception {
		lawDocMapper.updateApproval(vo);
	}
}
