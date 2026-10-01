/*
 * 물리적 저장 경로: /src/main/java/narainet/law/receipt/service/impl/LawReceiptServiceImpl.java
 *
 * 법원서류접수 (LAW_MODULE_DESIGN.md §7.11) — 접수 CRUD + 관련부서 지정 + 첨부(표준 COMTNFILE).
 *  등록부서=등록자 소속(컨트롤러 세션 세팅). 관련부서 알림 발송은 비범위(지정·표시까지).
 */
package narainet.law.receipt.service.impl;

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
import narainet.law.receipt.mapper.LawReceiptMapper;
import narainet.law.receipt.service.LawReceiptService;
import narainet.law.receipt.service.LawReceiptVO;

@Service("lawReceiptService")
public class LawReceiptServiceImpl implements LawReceiptService {

	@Resource(name = "lawReceiptMapper")
	private LawReceiptMapper lawReceiptMapper;

	@Resource(name = "egovLawReceiptIdGnrService")
	private EgovIdGnrService receiptIdGnrService;

	@Resource(name = "lawFileSupport")
	private LawFileSupport lawFileSupport;

	/** 첨부 저장 폴더 — D:/upload/law/receipt/ (법원 영수증) */
	private static final String FILE_DIR = "receipt";

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	@Override
	public Map<String, Object> getList(LawReceiptVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		List<LawReceiptVO> list = lawReceiptMapper.selectReceiptList(searchVO);
		for (LawReceiptVO vo : list) {
			vo.setFiles(lawFileSupport.list(vo.getAtchFileId()));
		}
		result.put("resultList", list);
		result.put("resultCnt", lawReceiptMapper.selectReceiptCnt(searchVO));
		return result;
	}

	@Override
	public LawReceiptVO getReceipt(Long receiptId) throws Exception {
		LawReceiptVO vo = lawReceiptMapper.selectReceipt(receiptId);
		if (vo != null) {
			vo.setFiles(lawFileSupport.list(vo.getAtchFileId()));
		}
		return vo;
	}

	@Override
	@Transactional
	public Long save(LawReceiptVO vo, List<MultipartFile> files, String userId) throws Exception {
		String ts = now();
		if (vo.getReceiptId() == null) {
			vo.setAtchFileId(lawFileSupport.saveFiles(null, files, "LAW_", FILE_DIR));
			vo.setReceiptId((long) receiptIdGnrService.getNextIntegerId());
			vo.setRegUserId(userId);
			vo.setRegDt(ts);
			lawReceiptMapper.insertReceipt(vo);
		} else {
			LawReceiptVO before = lawReceiptMapper.selectReceipt(vo.getReceiptId());
			if (before == null) {
				throw new IllegalStateException("존재하지 않는 접수 정보입니다.");
			}
			vo.setAtchFileId(lawFileSupport.saveFiles(before.getAtchFileId(), files, "LAW_", FILE_DIR));
			vo.setUpdUserId(userId);
			vo.setUpdDt(ts);
			lawReceiptMapper.updateReceipt(vo);
		}
		return vo.getReceiptId();
	}

	@Override
	@Transactional
	public void delete(Long receiptId) throws Exception {
		lawReceiptMapper.deleteReceipt(receiptId);
	}
}
