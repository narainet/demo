/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelVrsnServiceImpl.java
 *
 * 관련자료 마스터 서비스 구현.
 *  - 채번: egovRelVrsnIdGnrService (COMTECOPSEQ.TABLE_NAME='REL_VRSN_ID')
 *  - INSERT 시 ICTNS_ID 는 getNewContentsId() 가 자동 발급
 *  - SINS_DT 는 YYYYMMDDHHMMSS, vrsnYn 디폴트 'Y'
 */
package narainet.rlms.related.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.related.mapper.RelVrsnMapper;
import narainet.rlms.related.service.RelVrsnService;
import narainet.rlms.related.service.RelVrsnVO;

@Service("relVrsnService")
public class RelVrsnServiceImpl extends EgovAbstractServiceImpl implements RelVrsnService {

	@Resource(name = "relVrsnMapper")
	private RelVrsnMapper relVrsnMapper;

	@Resource(name = "egovRelVrsnIdGnrService")
	private EgovIdGnrService relVrsnIdGnrService;

	// ── 조회 ──────────────────────────────────────────────────────

	@Override
	public RelVrsnVO getByNo(Long relVrsnNo) {
		return relVrsnMapper.selectByNo(relVrsnNo);
	}

	@Override
	public List<RelVrsnVO> getByPromNo(Long promNo) {
		return relVrsnMapper.selectByPromNo(promNo);
	}

	@Override
	public List<RelVrsnVO> getByPromAndFullItem(Long promNo, String fullItem) {
		return relVrsnMapper.selectByPromAndFullItem(promNo, fullItem, null);   // null = 조항(PROVISION)
	}

	@Override
	public RelVrsnVO getExistingMaster(Long promNo, String stable, String flag, String fullItem) {
		return relVrsnMapper.selectExistingMaster(promNo, stable, flag, fullItem);
	}

	// ── WRITE ─────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long getNewVersion(Long promNo, String vrsnYn, String stable, String flag,
			String fullItem, String title, Long cateNo, String sysId) throws Exception {
		return insertMaster(promNo, vrsnYn, stable, flag, fullItem, title,
				cateNo, sysId, null, null);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long getNewHseqVersion(Long promNo, String vrsnYn, String stable, String flag,
			String fullItem, String title, Long cateNo, String sysId,
			String cateName, Integer cateOrder) throws Exception {
		return insertMaster(promNo, vrsnYn, stable, flag, fullItem, title,
				cateNo, sysId, cateName, cateOrder);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long getOrCreateMaster(Long promNo, String vrsnYn, String stable, String flag,
			String fullItem, String title, Long cateNo, String sysId) throws Exception {
		RelVrsnVO existing = relVrsnMapper.selectExistingMaster(promNo, stable, flag, fullItem);
		if (existing != null && existing.getRelVrsnNo() != null) {
			return existing.getRelVrsnNo();
		}
		return insertMaster(promNo, vrsnYn, stable, flag, fullItem, title,
				cateNo, sysId, null, null);
	}

	/** 공통 INSERT helper. cateName/cateOrder 가 null 이면 디폴트로 채움. */
	private Long insertMaster(Long promNo, String vrsnYn, String stable, String flag,
			String fullItem, String title, Long cateNo, String sysId,
			String cateName, Integer cateOrder) throws Exception {

		Long relVrsnNo = relVrsnIdGnrService.getNextLongId();
		Long ctnsId    = relVrsnMapper.getNewContentsId();
		String now     = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());

		// TB_REL_VRSN NOT NULL 디폴트 처리 (레거시 스키마):
		//  - IRVCATE_NO : 분류 없는 액션 → 0 (= "미선택")
		//  - SFULL_ITEM : 회차(PROMULGATION) 레벨 → "0" (레거시 컨트롤러 디폴트와 동일)
		//  - SFLAG      : 호출자가 안 줬으면 PROMULGATION
		//  - STITLE     : 빈 제목은 placeholder
		Long   effCateNo   = (cateNo != null) ? cateNo : 0L;
		String effFullItem = (fullItem != null && !fullItem.isEmpty()) ? fullItem : "0";
		String effFlag     = (flag != null && !flag.isEmpty()) ? flag : "PROMULGATION";
		String effTitle    = (title != null && !title.isEmpty()) ? title : "(제목없음)";
		String effSysId    = (sysId != null && !sysId.isEmpty()) ? sysId : null;   // 단일 시스템 — 미전송 시 null(필터 미사용)

		RelVrsnVO vo = new RelVrsnVO();
		vo.setRelVrsnNo(relVrsnNo);
		vo.setPromNo(promNo);
		vo.setCtnsId(ctnsId);
		vo.setVrsnYn(vrsnYn != null ? vrsnYn : "Y");
		vo.setStable(stable);
		vo.setFlag(effFlag);
		vo.setFullItem(effFullItem);
		vo.setTitle(effTitle);
		// ISEQ — 사용자 정렬은 별도 update 로. INSERT 시점에는 카테고리 안 다음 값 자동.
		vo.setSeq(relVrsnMapper.getNextSeq(promNo, effCateNo));
		vo.setUrl(" ");
		vo.setCateNo(effCateNo);
		vo.setCateName(cateName != null ? cateName : "미선택");
		vo.setCateOrder(cateOrder != null ? cateOrder : 0);
		vo.setInsDt(now);
		vo.setSysId(effSysId);

		relVrsnMapper.insert(vo);
		return relVrsnNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void update(RelVrsnVO vo) {
		relVrsnMapper.update(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relVrsnNo) {
		relVrsnMapper.deleteByNo(relVrsnNo);
	}

	@Override
	public Integer getNextSeq(Long promNo, Long cateNo) {
		return relVrsnMapper.getNextSeq(promNo, cateNo);
	}
}
