/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/ProvHtmlServiceImpl.java
 */
package narainet.rlms.prom.service.impl;

import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.prom.mapper.ProvHtmlMapper;
import narainet.rlms.prom.service.ProvHtmlService;
import narainet.rlms.prom.service.ProvHtmlVO;
import narainet.rlms.prom.service.ProvVrsnService;

/**
 * 조항 HTML 본문 Service 구현체.
 *
 * insert/update 시 동기로 ProvVrsnService.decomposeAndStore() 호출 → 단위 row 즉시 갱신.
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Service("provHtmlService")
public class ProvHtmlServiceImpl extends EgovAbstractServiceImpl implements ProvHtmlService {

	@Resource(name = "provHtmlMapper")
	private ProvHtmlMapper provHtmlMapper;

	@Resource(name = "provVrsnService")
	private ProvVrsnService provVrsnService;

	/** 조 번호 변경 시 조항 단위 관련자료(SFLAG='PROVISION') 이관용 */
	@Resource(name = "relVrsnMapper")
	private narainet.rlms.related.mapper.RelVrsnMapper relVrsnMapper;

	/** 조 번호 변경 시 사용자 즐겨찾기(TB_FAVOR.SITEM) 이관용 */
	@Resource(name = "favorMapper")
	private narainet.rlms.favor.mapper.FavorMapper favorMapper;

	@Resource(name = "egovProvHtmlIdGnrService")
	private EgovIdGnrService provHtmlIdGnrService;

	@Override
	public List<ProvHtmlVO> selectProvHtmlList(Long promNo) {
		return provHtmlMapper.selectProvHtmlList(promNo);
	}

	@Override
	public List<ProvHtmlVO> selectProvHtmlListCumulativeAdmin(Long lawId, Long lawNo) {
		if (lawId == null || lawNo == null) return new java.util.ArrayList<>();
		return provHtmlMapper.selectProvHtmlListCumulativeAdmin(lawId, lawNo);
	}

	@Override
	public ProvHtmlVO selectProvHtmlByNo(Long provHtmlNo) {
		return provHtmlMapper.selectProvHtmlByNo(provHtmlNo);
	}

	@Override
	public ProvHtmlVO selectProvHtmlByPromItem(Long promNo, String item) {
		return provHtmlMapper.selectProvHtmlByPromItem(promNo, item);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void insertProvHtml(ProvHtmlVO vo) throws Exception {
		if (vo.getSysId() == null || vo.getSysId().isEmpty()) {
			vo.setSysId("DEFAULT");
		}
		ProvHtmlVO exist = provHtmlMapper.selectProvHtmlByPromItem(vo.getPromNo(), vo.getItem());
		if (exist != null) {
			throw processException("provhtml.duplicate.item");
		}
		vo.setProvHtmlNo(provHtmlIdGnrService.getNextLongId());
		provHtmlMapper.insertProvHtml(vo);

		// 단위 분해 동기 — ★회차 전체 합본으로 (단건 contents 만 분해하면 다른 조항의 단위행이 소실됨)
		resyncProvVrsnAll(vo.getPromNo(), vo.getStartDate(), vo.getSysId(), vo.getGaejungType());
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateProvHtml(ProvHtmlVO vo) throws Exception {
		ProvHtmlVO target = provHtmlMapper.selectProvHtmlByNo(vo.getProvHtmlNo());
		if (target == null) {
			throw processException("provhtml.notfound");
		}
		if (vo.getPromNo() == null) vo.setPromNo(target.getPromNo());

		// ── 조 번호(SITEM) 변경 — 목록 정렬이 ORDER BY SITEM 이라 이게 곧 "순서 이동"이다 (2026-07-30).
		//    SITEM 은 회차간 누적의 계보 키이자 부속 데이터(관련자료·즐겨찾기)의 조항 식별자라
		//    ①계보 충돌 검사 ②부속 데이터 이관 을 같은 트랜잭션에서 처리한다.
		String oldItem = target.getItem() == null ? "" : target.getItem().trim();
		String newItem = vo.getItem()    == null ? "" : vo.getItem().trim();
		boolean itemChanged = !oldItem.isEmpty() && !newItem.isEmpty() && !oldItem.equals(newItem);
		if (itemChanged) {
			if (!newItem.matches("[0-9]{6}")) {
				throw processException("provhtml.item.format");
			}
			// 바꿀 번호가 이 규정 계보에 이미 있으면 = 그 조항의 개정판으로 오인된다
			if (provHtmlMapper.countProvHtmlItemInLaw(vo.getPromNo(), newItem, vo.getProvHtmlNo()) > 0) {
				throw processException("provhtml.item.conflict");
			}
			// 지금 번호를 다른 회차도 쓰고 있으면 = 계보가 끊겨 조항이 둘로 보인다 (개정 승계 파손)
			if (provHtmlMapper.countProvHtmlItemInLaw(vo.getPromNo(), oldItem, vo.getProvHtmlNo()) > 0) {
				throw processException("provhtml.item.locked");
			}
		}

		provHtmlMapper.updateProvHtml(vo);

		if (itemChanged) {
			// 관련자료(조항 단위 첨부) — SFLAG='PROVISION' + SFULL_ITEM = 조항 식별자
			relVrsnMapper.updateFullItemForProm(vo.getPromNo(), "PROVISION", oldItem, newItem);
			// 사용자 즐겨찾기 — TB_FAVOR.SITEM 이 같은 식별자를 쓴다
			favorMapper.updateSitemByLawOfProm(vo.getPromNo(), oldItem, newItem);
		}

		// 단위 분해 재실행 — ★회차 전체 합본으로
		resyncProvVrsnAll(vo.getPromNo(), vo.getStartDate(), vo.getSysId(), vo.getGaejungType());
	}

	/**
	 * TB_PROV_VRSN 단위행 재동기 — 이 회차의 TB_PROV_HTML 전 조항 본문을 SITEM 순으로 합본해
	 * 한 번에 분해한다. (decomposeAndStore 는 promNo 전체 delete 후 재삽입이라,
	 * 단건 contents 만 넘기면 나머지 조항의 단위행이 통째로 사라지는 잠복버그가 있었음 — 2026-06-11)
	 */
	private void resyncProvVrsnAll(Long promNo, String startDate, String sysId, String gaejungType)
			throws Exception {
		List<ProvHtmlVO> rows = provHtmlMapper.selectProvHtmlList(promNo);   // ORDER BY SITEM
		StringBuilder merged = new StringBuilder();
		if (rows != null) {
			for (ProvHtmlVO r : rows) {
				if (r.getContents() == null || r.getContents().trim().isEmpty()) continue;
				if (merged.length() > 0) merged.append("\n");
				merged.append(r.getContents());
			}
		}
		provVrsnService.decomposeAndStore(promNo, merged.toString(), startDate, sysId, gaejungType);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteProvHtml(Long provHtmlNo) throws Exception {
		ProvHtmlVO target = provHtmlMapper.selectProvHtmlByNo(provHtmlNo);
		if (target == null) {
			throw processException("provhtml.notfound");
		}
		// 단위 row 정리 (트리거는 PROV_VRSN 까지는 안 잡음 — 명시 처리)
		// TRG_DEL_PROV_HTML 가 REL_VRSN/ATTACH 만 정리.
		// PROV_VRSN 은 promNo 단위라 다른 PROV_HTML 행과 공유될 수도 있어 신중.
		// 본 모듈 정책: 같은 promNo 의 PROV_VRSN row 들은 전체 재분해가 안전 → 마지막 PROV_HTML 삭제 후 빈 분해 호출.
		provHtmlMapper.deleteProvHtml(provHtmlNo);

		// 남은 PROV_HTML 합본으로 재분해 (insert/update 와 동일 경로)
		resyncProvVrsnAll(target.getPromNo(), target.getStartDate(),
				target.getSysId(), target.getGaejungType());
	}
}
