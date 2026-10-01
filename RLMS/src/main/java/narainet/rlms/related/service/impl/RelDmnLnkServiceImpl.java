/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelDmnLnkServiceImpl.java
 *
 * 관련자료 — DOMAIN_LINK 액션 Service 구현.
 *  saveLinks 의 절차 (레거시 RelatedController.domainLinkUpdateDo 패턴):
 *   1) (promNo, "TB_REL_DMN_LNK", flag, fullItem) 마스터 getOrCreateMaster → IRVRSN_NO (Long)
 *   2) deleteByRelVrsnNo(String 변환)  — 기존 자식 전체 삭제
 *   3) for each item: PK 채번 + relVrsnNo/seq/insDt/sysId/디폴트 채워 INSERT
 *
 *  ※ TB_REL_DMN_LNK.IRVRSN_NO 는 VARCHAR2(255) — 다른 TB_REL_* 와 달리 문자열.
 *    마스터 Long → String 변환은 이 Service 안에서 처리.
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

import narainet.rlms.related.mapper.RelDmnLnkMapper;
import narainet.rlms.related.service.RelDmnLnkService;
import narainet.rlms.related.service.RelDmnLnkVO;
import narainet.rlms.related.service.RelVrsnService;
import narainet.rlms.related.service.RelVrsnVO;

@Service("relDmnLnkService")
public class RelDmnLnkServiceImpl extends EgovAbstractServiceImpl implements RelDmnLnkService {

	@Resource(name = "relDmnLnkMapper")
	private RelDmnLnkMapper relDmnLnkMapper;

	@Resource(name = "egovRelDmnLnkIdGnrService")
	private EgovIdGnrService relDmnLnkIdGnrService;

	@Resource(name = "relVrsnService")
	private RelVrsnService relVrsnService;

	@Override
	public List<RelDmnLnkVO> getList(String relVrsnNo) {
		return relDmnLnkMapper.selectByRelVrsnNo(relVrsnNo);
	}

	@Override
	public List<RelDmnLnkVO> getListByPromAndFullItem(Long promNo, String flag, String fullItem) {
		String effFlag = (flag != null && !flag.isEmpty()) ? flag : "PROMULGATION";
		RelVrsnVO master = relVrsnService.getExistingMaster(promNo, "TB_REL_DMN_LNK", effFlag, fullItem);
		if (master == null || master.getRelVrsnNo() == null) return new ArrayList<>();
		return relDmnLnkMapper.selectByRelVrsnNo(String.valueOf(master.getRelVrsnNo()));
	}

	@Override
	public RelDmnLnkVO getByNo(Long relDmnLnkNo) {
		return relDmnLnkMapper.selectByNo(relDmnLnkNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public String saveLinks(Long promNo, String flag, String fullItem, String sysId,
			List<RelDmnLnkVO> items) throws Exception {

		if (promNo == null) throw processException("related.dmnlnk.invalid");
		String effFlag     = (flag != null && !flag.isEmpty()) ? flag : "PROMULGATION";
		String effFullItem = (fullItem != null) ? fullItem : "0";
		String effSysId    = (sysId != null && !sysId.isEmpty()) ? sysId : null;   // 단일 시스템 — 미전송 시 null(필터 미사용)

		// 1) 마스터 확보 (있으면 재사용 / 없으면 신규)
		Long irvrsnNoLong = relVrsnService.getOrCreateMaster(
				promNo, "Y", "TB_REL_DMN_LNK", effFlag, effFullItem,
				"(domain link)", null, effSysId);
		String relVrsnNo = String.valueOf(irvrsnNoLong);

		// 2) 기존 자식 전체 삭제
		relDmnLnkMapper.deleteByRelVrsnNo(relVrsnNo);

		// 3) 새 items INSERT
		if (items != null && !items.isEmpty()) {
			String now = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
			int seq = 1;
			for (RelDmnLnkVO it : items) {
				if (it == null || it.getLawId() == null) continue;     // 필수 누락 skip
				it.setRelDmnLnkNo(relDmnLnkIdGnrService.getNextLongId());
				it.setRelVrsnNo(relVrsnNo);
				it.setFlag((it.getFlag() != null && !it.getFlag().isEmpty())
						? it.getFlag() : "PROMULGATION");
				if (it.getLawNo() == null)   it.setLawNo(0L);
				if (it.getFullItem() == null) it.setFullItem("0");
				if (it.getTitle() == null || it.getTitle().trim().isEmpty()) it.setTitle("(제목없음)");
				it.setSeq(seq++);
				it.setInsDt(now);
				it.setSysId(effSysId);
				if (it.getAlwaysLatestYn() == null || it.getAlwaysLatestYn().isEmpty())
					it.setAlwaysLatestYn("N");
				if (it.getFileItem() == null) it.setFileItem(0L);
				relDmnLnkMapper.insert(it);
			}
		}

		return relVrsnNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relDmnLnkNo) throws Exception {
		RelDmnLnkVO target = relDmnLnkMapper.selectByNo(relDmnLnkNo);
		if (target == null) return;
		relDmnLnkMapper.deleteByNo(relDmnLnkNo);

		// 마스터의 마지막 자식이면 마스터도 정리
		String relVrsnNo = target.getRelVrsnNo();
		if (relVrsnNo != null) {
			List<RelDmnLnkVO> remaining = relDmnLnkMapper.selectByRelVrsnNo(relVrsnNo);
			if (remaining == null || remaining.isEmpty()) {
				try { relVrsnService.delete(Long.parseLong(relVrsnNo)); }
				catch (NumberFormatException e) {
					org.slf4j.LoggerFactory.getLogger(RelDmnLnkServiceImpl.class)
							.warn("관련자료(DMN_LNK) 마스터 정리 건너뜀 — relVrsnNo 파싱 실패 (값='{}')", relVrsnNo);
				}
			}
		}
	}
}
