/*
 * 물리적 저장 경로: /src/main/java/narainet/law/suit/service/impl/LawSuitServiceImpl.java
 *
 * 사건 코어 저장 규칙 (LAW_MODULE_DESIGN.md §4.2·§4.4·§4.5·§7.1):
 *  - 본체+자식 4종(당사자/토지/수행자/진행) 한 트랜잭션 전량 교체.
 *  - 주민번호: 평문 입력이 있으면 ARIA 암호화, 없고 기존 행(partyId)이면 기존 암호문 보존.
 *    평문은 저장 직후 VO 에서 지운다(로그·직렬화 유출 방지).
 *  - 결과(RSLT_KIND_CD/RSLT_KIND_NM) 변경 감지 시 결과변경 이력(HIST_SEQ=MAX+1) 자동 적재.
 *  - FIRST_SUIT_ID: 신규 등록 시 원심 미선택이면 자기 ID (원심 선택=폼에서 승계값 전달).
 */
package narainet.law.suit.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.law.common.service.LawJuminCrypto;
import narainet.law.suit.mapper.LawSuitMapper;
import narainet.law.suit.service.LawSuitLandVO;
import narainet.law.suit.service.LawSuitPartyVO;
import narainet.law.suit.service.LawSuitProgVO;
import narainet.law.suit.service.LawSuitRsltHistVO;
import narainet.law.suit.service.LawSuitService;
import narainet.law.suit.service.LawSuitStaffVO;
import narainet.law.suit.service.LawSuitVO;

@Service("lawSuitService")
public class LawSuitServiceImpl implements LawSuitService {

	@Resource(name = "lawSuitMapper")
	private LawSuitMapper lawSuitMapper;

	@Resource(name = "lawJuminCrypto")
	private LawJuminCrypto lawJuminCrypto;

	@Resource(name = "egovLawSuitIdGnrService")
	private EgovIdGnrService suitIdGnrService;

	@Resource(name = "egovLawPartyIdGnrService")
	private EgovIdGnrService partyIdGnrService;

	@Resource(name = "egovLawLandIdGnrService")
	private EgovIdGnrService landIdGnrService;

	@Resource(name = "egovLawStaffIdGnrService")
	private EgovIdGnrService staffIdGnrService;

	@Resource(name = "egovLawProgIdGnrService")
	private EgovIdGnrService progIdGnrService;

	@Resource(name = "egovLawRsltHistIdGnrService")
	private EgovIdGnrService rsltHistIdGnrService;

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	@Override
	public Map<String, Object> getList(LawSuitVO searchVO) throws Exception {
		Map<String, Object> result = new HashMap<String, Object>();
		result.put("resultList", lawSuitMapper.selectSuitList(searchVO));
		result.put("resultCnt", lawSuitMapper.selectSuitCnt(searchVO));
		return result;
	}

	@Override
	public LawSuitVO getSuit(Long suitId) throws Exception {
		return lawSuitMapper.selectSuit(suitId);
	}

	@Override
	public Map<String, Object> getDetail(Long suitId) throws Exception {
		LawSuitVO suit = lawSuitMapper.selectSuit(suitId);
		if (suit == null) {
			return null;
		}
		Map<String, Object> m = new HashMap<String, Object>();
		m.put("suit", suit);
		List<LawSuitPartyVO> parties = lawSuitMapper.selectPartyList(suitId);
		for (LawSuitPartyVO p : parties) {
			boolean has = p.getJuminEnc() != null && !p.getJuminEnc().trim().isEmpty();
			p.setHasJumin(has);
			p.setJuminMask(has ? LawJuminCrypto.mask(p.getBirth()) : null);
			p.setJuminEnc(null); // 암호문도 화면 모델 밖으로 내보내지 않는다
		}
		m.put("parties", parties);
		m.put("lands", lawSuitMapper.selectLandList(suitId));
		m.put("staffs", lawSuitMapper.selectStaffList(suitId));
		m.put("progs", lawSuitMapper.selectProgList(suitId));
		m.put("rsltHists", lawSuitMapper.selectRsltHistList(suitId));
		m.put("instanceSuits", lawSuitMapper.selectInstanceSuits(
				suit.getFirstSuitId() == null ? suitId : suit.getFirstSuitId()));
		return m;
	}

	@Override
	@Transactional
	public Long save(LawSuitVO vo, List<LawSuitPartyVO> parties, List<LawSuitLandVO> lands,
			List<LawSuitStaffVO> staffs, List<LawSuitProgVO> progs, String userId) throws Exception {

		String ts = now();
		boolean isNew = vo.getSuitId() == null;
		LawSuitVO before = null;

		if (isNew) {
			vo.setSuitId((long) suitIdGnrService.getNextIntegerId());
			if (vo.getFirstSuitId() == null) {
				vo.setFirstSuitId(vo.getSuitId()); // 최초 심급 = 자기 ID (§4.5)
			}
			vo.setRegUserId(userId);
			vo.setRegDt(ts);
			lawSuitMapper.insertSuit(vo);
		} else {
			before = lawSuitMapper.selectSuit(vo.getSuitId());
			if (before == null) {
				throw new IllegalStateException("존재하지 않는 사건입니다.");
			}
			vo.setFirstSuitId(before.getFirstSuitId()); // 사건군은 수정에서 불변
			vo.setUpdUserId(userId);
			vo.setUpdDt(ts);
			lawSuitMapper.updateSuit(vo);
		}

		// ── 당사자: 기존 암호문 보존 맵 구성 후 전량 교체 ──
		Map<Long, String> keepEnc = new HashMap<Long, String>();
		if (!isNew) {
			for (LawSuitPartyVO old : lawSuitMapper.selectPartyList(vo.getSuitId())) {
				if (old.getJuminEnc() != null && !old.getJuminEnc().trim().isEmpty()) {
					keepEnc.put(old.getPartyId(), old.getJuminEnc());
				}
			}
		}
		lawSuitMapper.deleteParties(vo.getSuitId());
		if (parties != null) {
			int ord = 0;
			for (LawSuitPartyVO p : parties) {
				if (isBlank(p.getPartyNm())) {
					continue;
				}
				String enc = lawJuminCrypto.encrypt(p.getJumin());
				if (enc == null && p.getPartyId() != null) {
					enc = keepEnc.get(p.getPartyId()); // 미입력 기존 행 = 기존 암호문 보존
				}
				p.setJumin(null);
				p.setJuminEnc(enc);
				p.setPartyId((long) partyIdGnrService.getNextIntegerId());
				p.setSuitId(vo.getSuitId());
				p.setSortOrdr(ord++);
				lawSuitMapper.insertParty(p);
			}
		}

		// ── 토지·수행자·진행: 전량 교체 ──
		lawSuitMapper.deleteLands(vo.getSuitId());
		if (lands != null) {
			int ord = 0;
			for (LawSuitLandVO l : lands) {
				if (isBlank(l.getLocation()) && isBlank(l.getJibun())) {
					continue;
				}
				l.setLandId((long) landIdGnrService.getNextIntegerId());
				l.setSuitId(vo.getSuitId());
				l.setSortOrdr(ord++);
				lawSuitMapper.insertLand(l);
			}
		}

		lawSuitMapper.deleteStaffs(vo.getSuitId());
		if (staffs != null) {
			int ord = 0;
			for (LawSuitStaffVO s : staffs) {
				if (isBlank(s.getStaffNm()) && isBlank(s.getOrgnztId())) {
					continue;
				}
				s.setStaffId((long) staffIdGnrService.getNextIntegerId());
				s.setSuitId(vo.getSuitId());
				s.setSortOrdr(ord++);
				lawSuitMapper.insertStaff(s);
			}
		}

		lawSuitMapper.deleteProgs(vo.getSuitId());
		if (progs != null) {
			for (LawSuitProgVO g : progs) {
				if (isBlank(g.getProgDt()) && isBlank(g.getProgDesc())) {
					continue;
				}
				g.setProgId((long) progIdGnrService.getNextIntegerId());
				g.setSuitId(vo.getSuitId());
				lawSuitMapper.insertProg(g);
			}
		}

		// ── 결과변경 이력 (등록=결과 입력 시 1행, 수정=결과 코드·명칭 변경 시 적재) ──
		boolean rsltChanged;
		if (isNew) {
			rsltChanged = !isBlank(vo.getRsltKindCd());
		} else {
			rsltChanged = !eq(before.getRsltKindCd(), vo.getRsltKindCd())
					|| !eq(before.getRsltKindNm(), vo.getRsltKindNm());
		}
		if (rsltChanged) {
			LawSuitRsltHistVO h = new LawSuitRsltHistVO();
			h.setHistId((long) rsltHistIdGnrService.getNextIntegerId());
			h.setSuitId(vo.getSuitId());
			h.setHistSeq(lawSuitMapper.selectMaxHistSeq(vo.getSuitId()) + 1);
			h.setRsltKindCd(vo.getRsltKindCd());
			h.setRsltKindNm(vo.getRsltKindNm());
			h.setEndDt(vo.getDcsnDt());
			h.setHistDesc(isNew ? "등록 시 결과 입력" : "결과 변경");
			h.setRegUserId(userId);
			h.setRegDt(ts);
			lawSuitMapper.insertRsltHist(h);
		}

		return vo.getSuitId();
	}

	@Override
	@Transactional
	public void delete(Long suitId, String userId) throws Exception {
		LawSuitVO vo = new LawSuitVO();
		vo.setSuitId(suitId);
		vo.setUpdUserId(userId);
		vo.setUpdDt(now());
		lawSuitMapper.deleteSuit(vo);
	}

	@Override
	public List<LawSuitVO> searchSuits(String keyword) throws Exception {
		return lawSuitMapper.searchSuits(keyword == null ? "" : keyword.trim());
	}

	private static boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}

	private static boolean eq(String a, String b) {
		String x = a == null ? "" : a.trim();
		String y = b == null ? "" : b.trim();
		return x.equals(y);
	}
}
