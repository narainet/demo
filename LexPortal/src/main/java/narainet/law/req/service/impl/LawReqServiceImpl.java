/*
 * 물리적 저장 경로: /src/main/java/narainet/law/req/service/impl/LawReqServiceImpl.java
 *
 * 소송의뢰 워크플로 (LAW_MODULE_DESIGN.md §7.8·§7.9·§4.3).
 *  - 신청/수정: 본체 + 경과(행별 첨부) + 보조자 한 트랜잭션. 경과·보조자는 전량 교체.
 *    수정 시 경과 행의 기존 첨부(atchFileId)는 폼 JSON 으로 이어받아 보존/증분.
 *  - 승인/반려: 상태 전이 + 처리자·일시. 반려는 사유 필수(컨트롤러 검증).
 *  - 소송등록 연계: 승인 후 사건 생성 시 REQ.SUIT_ID 역기입(linkSuit).
 *  - 첨부는 표준 COMTNFILE(LawFileSupport). front 수정·삭제는 본인·신청(S001) 상태만(컨트롤러 선검증).
 */
package narainet.law.req.service.impl;

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
import org.springframework.web.multipart.MultipartHttpServletRequest;

import narainet.law.common.service.LawFileSupport;
import narainet.law.req.mapper.LawReqMapper;
import narainet.law.req.service.LawReqService;
import narainet.law.req.service.LawSuitReqHelperVO;
import narainet.law.req.service.LawSuitReqHistVO;
import narainet.law.req.service.LawSuitReqVO;

@Service("lawReqService")
public class LawReqServiceImpl implements LawReqService {

	@Resource(name = "lawReqMapper")
	private LawReqMapper lawReqMapper;

	@Resource(name = "egovLawReqIdGnrService")
	private EgovIdGnrService reqIdGnrService;

	@Resource(name = "egovLawReqHistIdGnrService")
	private EgovIdGnrService histIdGnrService;

	@Resource(name = "egovLawReqHelperIdGnrService")
	private EgovIdGnrService helperIdGnrService;

	@Resource(name = "lawFileSupport")
	private LawFileSupport lawFileSupport;

	/** 첨부 저장 폴더 — D:/upload/law/req/ (소송의뢰 본문·경과내역) */
	private static final String FILE_DIR = "req";

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	private static String today() {
		return new SimpleDateFormat("yyyyMMdd").format(new Date());
	}

	private static boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}

	@Override
	public Map<String, Object> getList(LawSuitReqVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		result.put("resultList", lawReqMapper.selectReqList(searchVO));
		result.put("resultCnt", lawReqMapper.selectReqCnt(searchVO));
		return result;
	}

	@Override
	public List<LawSuitReqVO> getMyList(String userId) throws Exception {
		LawSuitReqVO vo = new LawSuitReqVO();
		vo.setRegUserId(userId);
		vo.setFirstIndex(0);
		vo.setLastIndex(100000);
		return lawReqMapper.selectReqList(vo);
	}

	@Override
	public LawSuitReqVO getReq(Long reqId) throws Exception {
		return lawReqMapper.selectReq(reqId);
	}

	@Override
	public LawSuitReqVO getDetail(Long reqId) throws Exception {
		LawSuitReqVO req = lawReqMapper.selectReq(reqId);
		if (req == null) {
			return null;
		}
		req.setFiles(lawFileSupport.list(req.getAtchFileId()));
		List<LawSuitReqHistVO> hists = lawReqMapper.selectHistList(reqId);
		for (LawSuitReqHistVO h : hists) {
			h.setFiles(lawFileSupport.list(h.getAtchFileId()));
		}
		req.setHists(hists);
		req.setHelpers(lawReqMapper.selectHelperList(reqId));
		return req;
	}

	@Override
	@Transactional
	public Long save(LawSuitReqVO vo, MultipartHttpServletRequest multiRequest, String userId) throws Exception {
		String ts = now();
		boolean isNew = vo.getReqId() == null;

		// ── 기타자료 첨부(req 레벨, 다중) ──
		List<MultipartFile> reqFiles = multiRequest == null ? null : multiRequest.getFiles("file_1");

		if (isNew) {
			vo.setReqId((long) reqIdGnrService.getNextIntegerId());
			vo.setStatusCd("S001");
			if (isBlank(vo.getReqDt())) {
				vo.setReqDt(today());
			}
			vo.setAtchFileId(lawFileSupport.saveFiles(null, reqFiles, "LAW_", FILE_DIR));
			vo.setRegUserId(userId);
			vo.setRegDt(ts);
			lawReqMapper.insertReq(vo);
		} else {
			LawSuitReqVO before = lawReqMapper.selectReq(vo.getReqId());
			if (before == null) {
				throw new IllegalStateException("존재하지 않는 의뢰입니다.");
			}
			if (!"S001".equals(before.getStatusCd())) {
				throw new IllegalStateException("신청 상태에서만 수정할 수 있습니다.");
			}
			vo.setStatusCd("S001");
			if (isBlank(vo.getReqDt())) {
				vo.setReqDt(before.getReqDt());
			}
			vo.setAtchFileId(lawFileSupport.saveFiles(before.getAtchFileId(), reqFiles, "LAW_", FILE_DIR));
			vo.setUpdUserId(userId);
			vo.setUpdDt(ts);
			lawReqMapper.updateReq(vo);
		}

		Long reqId = vo.getReqId();

		// ── 경과 내역: 전량 교체(행별 첨부는 폼 JSON 의 기존 atchFileId 이어받아 보존/증분) ──
		lawReqMapper.deleteHists(reqId);
		if (vo.getHists() != null) {
			int ord = 0;
			for (LawSuitReqHistVO h : vo.getHists()) {
				if (isBlank(h.getHistCn()) && isBlank(h.getStaDt()) && isBlank(h.getEndDt())) {
					continue;
				}
				List<MultipartFile> rowFiles = (multiRequest == null || isBlank(h.getRowKey())) ? null
						: multiRequest.getFiles("histFile_" + h.getRowKey());
				h.setAtchFileId(lawFileSupport.saveFiles(h.getAtchFileId(), rowFiles, "LAW_", FILE_DIR));
				h.setHistId((long) histIdGnrService.getNextIntegerId());
				h.setReqId(reqId);
				h.setSortOrdr(ord++);
				h.setRegUserId(userId);
				h.setRegDt(ts);
				lawReqMapper.insertHist(h);
			}
		}

		// ── 보조자: 전량 교체 ──
		lawReqMapper.deleteHelpers(reqId);
		if (vo.getHelpers() != null) {
			int ord = 0;
			for (LawSuitReqHelperVO hp : vo.getHelpers()) {
				if (isBlank(hp.getHelperNm()) && isBlank(hp.getDeptNm()) && isBlank(hp.getTel())
						&& isBlank(hp.getMobile()) && isBlank(hp.getEmail())) {
					continue;
				}
				hp.setHelperId((long) helperIdGnrService.getNextIntegerId());
				hp.setReqId(reqId);
				hp.setSortOrdr(ord++);
				hp.setRegUserId(userId);
				hp.setRegDt(ts);
				lawReqMapper.insertHelper(hp);
			}
		}

		return reqId;
	}

	@Override
	@Transactional
	public void delete(Long reqId) throws Exception {
		lawReqMapper.deleteHists(reqId);
		lawReqMapper.deleteHelpers(reqId);
		lawReqMapper.deleteReq(reqId);
	}

	@Override
	@Transactional
	public void approve(LawSuitReqVO vo) throws Exception {
		lawReqMapper.updateApproval(vo);
	}

	@Override
	@Transactional
	public void linkSuit(Long reqId, Long suitId, String userId) throws Exception {
		LawSuitReqVO vo = new LawSuitReqVO();
		vo.setReqId(reqId);
		vo.setSuitId(suitId);
		vo.setUpdUserId(userId);
		vo.setUpdDt(now());
		lawReqMapper.updateSuitLink(vo);
	}

	@Override
	public int getPendingCnt() throws Exception {
		return lawReqMapper.selectPendingCnt();
	}
}
