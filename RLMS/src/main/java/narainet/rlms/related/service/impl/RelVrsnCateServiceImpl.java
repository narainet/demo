/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelVrsnCateServiceImpl.java
 *
 * 관련자료 카테고리 서비스 구현.
 *  - 디폴트 시드 3종 정책: 본문(1, Y) / 붙임(2, N) / 양식(3, Y)
 *    레거시 운영 DB (2026-05-14 분석) 의 다수파 정책. seedDefault 가 멱등성 보장.
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

import narainet.rlms.related.mapper.RelVrsnCateMapper;
import narainet.rlms.related.service.RelVrsnCateService;
import narainet.rlms.related.service.RelVrsnCateVO;

@Service("relVrsnCateService")
public class RelVrsnCateServiceImpl extends EgovAbstractServiceImpl implements RelVrsnCateService {

	@Resource(name = "relVrsnCateMapper")
	private RelVrsnCateMapper relVrsnCateMapper;

	@Resource(name = "egovRelVrsnCateIdGnrService")
	private EgovIdGnrService relVrsnCateIdGnrService;

	// ── 조회 ──────────────────────────────────────────────────────

	@Override
	public List<RelVrsnCateVO> getList(Long promNo, Long lawId, String today) {
		if (today == null || today.isEmpty()) {
			today = new SimpleDateFormat("yyyyMMdd").format(new Date());
		}
		return relVrsnCateMapper.selectActiveList(promNo, lawId, today);
	}

	@Override
	public RelVrsnCateVO getByNo(Long cateNo) {
		return relVrsnCateMapper.selectByNo(cateNo);
	}

	// ── 시드 ──────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int seedDefault(Long promNo, Long lawId) throws Exception {
		if (promNo == null || lawId == null) return 0;
		String today = new SimpleDateFormat("yyyyMMdd").format(new Date());
		// 멱등성: 이미 있으면 생략
		List<RelVrsnCateVO> exist = relVrsnCateMapper.selectActiveList(promNo, lawId, today);
		if (exist != null && !exist.isEmpty()) return 0;

		String now = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
		String tempPromNo = String.valueOf(promNo);

		insertOne(lawId, tempPromNo, "본문", 1, "Y", now);
		insertOne(lawId, tempPromNo, "붙임", 2, "N", now);
		insertOne(lawId, tempPromNo, "양식", 3, "Y", now);
		return 3;
	}

	private void insertOne(Long lawId, String tempPromNo, String title,
			Integer seq, String orgnDownYn, String now) throws Exception {
		RelVrsnCateVO vo = new RelVrsnCateVO();
		vo.setCateNo(relVrsnCateIdGnrService.getNextLongId());
		vo.setTitle(title);
		vo.setSeq(seq);
		vo.setHideDt("0");
		vo.setInsDt(now);
		vo.setLawId(lawId);
		vo.setTempPromNo(tempPromNo);
		vo.setOrgnDownYn(orgnDownYn);
		relVrsnCateMapper.insert(vo);
	}

	// ── 사용자 작업 ────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long insert(Long promNo, Long lawId, String title, Integer seq, String orgnDownYn) throws Exception {
		RelVrsnCateVO vo = new RelVrsnCateVO();
		vo.setCateNo(relVrsnCateIdGnrService.getNextLongId());
		vo.setTitle(title);
		vo.setSeq(seq != null ? seq : 99);
		vo.setHideDt("0");
		vo.setInsDt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
		vo.setLawId(lawId);
		vo.setTempPromNo(promNo != null ? String.valueOf(promNo) : null);
		vo.setOrgnDownYn(orgnDownYn != null ? orgnDownYn : "N");
		relVrsnCateMapper.insert(vo);
		return vo.getCateNo();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void rename(Long cateNo, String title) {
		relVrsnCateMapper.updateTitle(cateNo, title);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void hide(Long cateNo, String hideDt) {
		relVrsnCateMapper.updateHide(cateNo, hideDt);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void toggleOrgnDown(Long cateNo, String orgnDownYn) {
		relVrsnCateMapper.updateOrgnDown(cateNo, orgnDownYn);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void moveSeq(Long cateNo, Integer seq) {
		relVrsnCateMapper.updateSeq(cateNo, seq);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long cateNo) {
		relVrsnCateMapper.deleteByNo(cateNo);
	}
}
