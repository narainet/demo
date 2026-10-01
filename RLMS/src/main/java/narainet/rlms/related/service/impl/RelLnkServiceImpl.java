/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelLnkServiceImpl.java
 *
 * 관련자료 — LINK 액션 Service 구현 (레거시 urlUpdateDo 1:1).
 *  saveLinks 절차:
 *   1) getOrCreateMaster(promNo, "TB_REL_LNK", flag, fullItem) → IRVRSN_NO
 *   2) deleteByRelVrsnNo  — 기존 자식 전체 삭제
 *   3) for each item: PK 채번 + ISEQ/INS_DT/SYS_ID/필수 디폴트 채워 INSERT
 *
 *  ※ TB_REL_LNK 모든 컬럼 NOT NULL → SCATE/STITLE/SURL/SREF_TABLE 빈값 디폴트 처리.
 */
package narainet.rlms.related.service.impl;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.related.mapper.RelLnkMapper;
import narainet.rlms.related.service.RelLnkService;
import narainet.rlms.related.service.RelLnkVO;
import narainet.rlms.related.service.RelVrsnService;
import narainet.rlms.related.service.RelVrsnVO;

@Service("relLnkService")
public class RelLnkServiceImpl extends EgovAbstractServiceImpl implements RelLnkService {

	@Resource(name = "relLnkMapper")
	private RelLnkMapper relLnkMapper;

	@Resource(name = "egovRelLnkIdGnrService")
	private EgovIdGnrService relLnkIdGnrService;

	@Resource(name = "relVrsnService")
	private RelVrsnService relVrsnService;

	@Override
	public List<RelLnkVO> getList(Long relVrsnNo) {
		return relLnkMapper.selectByRelVrsnNo(relVrsnNo);
	}

	@Override
	public List<RelLnkVO> getListByPromAndFullItem(Long promNo, String flag, String fullItem) {
		String effFlag = (flag != null && !flag.isEmpty()) ? flag : "PROMULGATION";
		RelVrsnVO master = relVrsnService.getExistingMaster(promNo, "TB_REL_LNK", effFlag, fullItem);
		if (master == null || master.getRelVrsnNo() == null) return new ArrayList<>();
		return relLnkMapper.selectByRelVrsnNo(master.getRelVrsnNo());
	}

	@Override
	public RelLnkVO getByNo(Long relLnkNo) {
		return relLnkMapper.selectByNo(relLnkNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long saveLinks(Long promNo, String flag, String fullItem, String sysId,
			List<RelLnkVO> items) throws Exception {

		if (promNo == null) throw processException("related.lnk.invalid");
		String effFlag     = (flag != null && !flag.isEmpty()) ? flag : "PROMULGATION";
		String effFullItem = (fullItem != null) ? fullItem : "0";
		String effSysId    = (sysId != null && !sysId.isEmpty()) ? sysId : null;   // 단일 시스템 — 미전송 시 null(필터 미사용)

		Long relVrsnNo = relVrsnService.getOrCreateMaster(
				promNo, "Y", "TB_REL_LNK", effFlag, effFullItem,
				"(url links)", null, effSysId);

		// 기존 자식 전체 삭제
		relLnkMapper.deleteByRelVrsnNo(relVrsnNo);

		if (items != null && !items.isEmpty()) {
			String now = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
			int seq = 1;
			for (RelLnkVO it : items) {
				if (it == null) continue;
				String url = (it.getUrl() != null) ? it.getUrl().trim() : "";
				String ttl = (it.getTitle() != null) ? it.getTitle().trim() : "";
				if (url.isEmpty()) continue;                            // URL 없으면 skip
				if (ttl.isEmpty()) ttl = url;                           // 제목 없으면 URL 자체를 제목으로
				it.setRelLnkNo(relLnkIdGnrService.getNextLongId());
				it.setRelVrsnNo(relVrsnNo);
				it.setCate((it.getCate() != null && !it.getCate().trim().isEmpty())
						? it.getCate().trim() : "URL");
				it.setTitle(ttl);
				it.setUrl(url);
				if (it.getRefNo() == null)                it.setRefNo(0L);
				// Oracle: '' == NULL → NOT NULL 위반 회피 위해 공백 한 칸
				if (it.getRefTable() == null || it.getRefTable().isEmpty()) it.setRefTable(" ");
				it.setSeq(seq++);
				it.setInsDt(now);
				it.setSysId(effSysId);
				relLnkMapper.insert(it);
			}
		}

		return relVrsnNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relLnkNo) throws Exception {
		RelLnkVO target = relLnkMapper.selectByNo(relLnkNo);
		if (target == null) return;
		relLnkMapper.deleteByNo(relLnkNo);

		Long relVrsnNo = target.getRelVrsnNo();
		if (relVrsnNo != null) {
			List<RelLnkVO> remaining = relLnkMapper.selectByRelVrsnNo(relVrsnNo);
			if (remaining == null || remaining.isEmpty()) {
				relVrsnService.delete(relVrsnNo);
			}
		}
	}
}
