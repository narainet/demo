/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/search/service/impl/UnifiedSearchServiceImpl.java
 */
package narainet.rlms.search.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;

import egovframework.com.cop.bbs.service.BoardReadGuard;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.search.mapper.UnifiedSearchMapper;
import narainet.rlms.search.service.UnifiedSearchService;

/**
 * 통합검색 서비스 구현.
 * 검색조건(키워드/구분/분류/열람게이트)은 PromVO 를 받아 매퍼용 Map 파라미터로 평탄화.
 * 분류 체크박스의 축 토글(AXIS_BBS/AXIS_FAQ)은 여기서 해석 — 무체크=전축, 체크=체크된 축만.
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.07   RLMS 전환팀   최초 생성 (지능형 통합검색 v1)
 * </pre>
 */
@Service("unifiedSearchService")
public class UnifiedSearchServiceImpl extends EgovAbstractServiceImpl implements UnifiedSearchService {

	@Resource(name = "unifiedSearchMapper")
	private UnifiedSearchMapper unifiedSearchMapper;

	/** 검색어 통계 채번 — COMTECOPSEQ 'STATS_KWD_NO' (레거시 SQ_STATS_KWD_NO 는 미사용 동결) */
	@Resource(name = "egovStatsKwdIdGnrService")
	private EgovIdGnrService statsKwdIdGnrService;

	/** 게시판 열람권한 — 통합검색 게시판축은 SEARCH_INCLD_AT='Y' 이면서 사용자가 열람 가능한 게시판만 대상. */
	@Resource(name = "boardReadGuard")
	private BoardReadGuard boardReadGuard;

	@Override
	public Map<String, Integer> counts(PromVO vo) {
		Map<String, Object> p = params(vo, 0, 0);
		boolean promAxes = promAxesSelected(vo);
		Map<String, Integer> counts = new LinkedHashMap<>();
		counts.put("promCnt", promAxes ? unifiedSearchMapper.countProms(p) : 0);
		counts.put("provCnt", promAxes ? unifiedSearchMapper.countProvs(p) : 0);
		counts.put("docuCnt", promAxes ? unifiedSearchMapper.countDocus(p) : 0);
		counts.put("relCnt",  promAxes ? unifiedSearchMapper.countRels(p) : 0);
		int bbsCnt = 0;
		if (axisSelected(vo, GUBUN_AXIS_BBS)) {
			List<String> bbsIds = readableSearchableBbsIds();
			bbsCnt = bbsIds.isEmpty() ? 0 : unifiedSearchMapper.countBbs(withBbsIds(p, bbsIds));
		}
		counts.put("bbsCnt", bbsCnt);
		counts.put("faqCnt", axisSelected(vo, GUBUN_AXIS_FAQ) ? unifiedSearchMapper.countFaq(p) : 0);
		return counts;
	}

	@Override
	public List<Map<String, Object>> search(String tab, PromVO vo, int firstIndex, int recordCountPerPage) {
		Map<String, Object> p = params(vo, firstIndex, recordCountPerPage);
		if (TAB_BBS.equals(tab)) {
			if (!axisSelected(vo, GUBUN_AXIS_BBS)) {
				return new ArrayList<>();
			}
			List<String> bbsIds = readableSearchableBbsIds();
			if (bbsIds.isEmpty()) {
				return new ArrayList<>();
			}
			return unifiedSearchMapper.searchBbs(withBbsIds(p, bbsIds));
		}
		if (TAB_FAQ.equals(tab)) {
			return axisSelected(vo, GUBUN_AXIS_FAQ)
					? unifiedSearchMapper.searchFaq(p) : new ArrayList<>();
		}
		// 규정 4축 — 분류 체크가 축 토글(게시판/FAQ)뿐이면 규정 계열은 비검색
		if (!promAxesSelected(vo)) {
			return new ArrayList<>();
		}
		if (TAB_PROV.equals(tab))  return unifiedSearchMapper.searchProvs(p);
		if (TAB_DOCU.equals(tab))  return unifiedSearchMapper.searchDocus(p);
		if (TAB_REL.equals(tab))   return unifiedSearchMapper.searchRels(p);
		return unifiedSearchMapper.searchProms(p);
	}

	/** 분류 체크박스에 체크가 하나라도 있나 — 비면 무필터(전축 검색)가 기존 규약. */
	private boolean hasGubunFilter(PromVO vo) {
		return vo.getGubunIds() != null && !vo.getGubunIds().isEmpty();
	}

	/** gubunIds 에서 축 토글 코드(AXIS_*)를 뺀 실제 규정 구분 코드만 — 원본 리스트는 폼 재렌더용이라 불변 유지. */
	private List<String> realGubunIds(PromVO vo) {
		if (vo.getGubunIds() == null) {
			return null;
		}
		List<String> real = new ArrayList<>(vo.getGubunIds());
		real.removeAll(java.util.Arrays.asList(GUBUN_AXIS_BBS, GUBUN_AXIS_FAQ));
		return real;
	}

	/** 규정 계열 4축(규정/조문/별표/자료) 검색 여부 — 무필터이거나 실제 규정 구분이 하나라도 체크됐을 때. */
	private boolean promAxesSelected(PromVO vo) {
		if (!hasGubunFilter(vo)) {
			return true;
		}
		List<String> real = realGubunIds(vo);
		return real != null && !real.isEmpty();
	}

	/** 게시판/FAQ 축 검색 여부 — 무필터이거나 해당 축 토글이 체크됐을 때. */
	private boolean axisSelected(PromVO vo, String axisCode) {
		return !hasGubunFilter(vo) || vo.getGubunIds().contains(axisCode);
	}

	/** 통합검색 노출(SEARCH_INCLD_AT='Y')·사용중인 게시판 중 현재 사용자가 열람 가능한 것만. 비면 게시판축 결과 0. */
	private List<String> readableSearchableBbsIds() {
		List<String> all = unifiedSearchMapper.selectSearchableBbsIds();
		List<String> out = new ArrayList<>();
		for (String bbsId : all) {
			if (boardReadGuard.canRead(bbsId)) {
				out.add(bbsId);
			}
		}
		return out;
	}

	/** 파라미터 맵 복사 + 열람가능 bbsId 목록 주입(게시판축 전용, 다른 축엔 무영향). */
	private Map<String, Object> withBbsIds(Map<String, Object> base, List<String> bbsIds) {
		Map<String, Object> p = new HashMap<>(base);
		p.put("bbsIds", bbsIds);
		return p;
	}

	@Override
	public void logKeyword(String keyword) throws Exception {
		String kwd = keyword == null ? "" : keyword.trim();
		if (kwd.isEmpty()) {
			return;
		}
		if (kwd.length() > 80) {
			kwd = kwd.substring(0, 80);
		}
		unifiedSearchMapper.insertKeywordStat(statsKwdIdGnrService.getNextIntegerId(), kwd);
	}

	@Override
	public List<String> popularKeywords(int days, int topN) {
		return unifiedSearchMapper.selectPopularKeywords(days, topN);
	}

	/** PromVO → 매퍼 Map 파라미터. ftKeyword 는 Oracle Text CONTAINS 안전형(중괄호 래핑, 특수문자 무해화) */
	private Map<String, Object> params(PromVO vo, int firstIndex, int recordCountPerPage) {
		Map<String, Object> p = new HashMap<>();
		String kw = vo.getSearchKeyword() == null ? "" : vo.getSearchKeyword().trim();
		p.put("keyword", kw);
		// CONTAINS 는 키워드가 질의 표현식으로 해석됨 — {} 래핑으로 리터럴화, 내부 중괄호는 제거
		String ft = kw.replace("{", " ").replace("}", " ").trim();
		p.put("ftKeyword", ft.isEmpty() ? null : "{" + ft + "}");
		p.put("firstIndex", firstIndex);
		p.put("recordCountPerPage", recordCountPerPage);
		p.put("cateNo", vo.getCateNo());
		p.put("searchFromDt", vo.getSearchFromDt());
		p.put("searchToDt", vo.getSearchToDt());
		// 축 토글 코드(AXIS_BBS/AXIS_FAQ)는 SQL 의 SGUBUN_ID 필터에 섞이면 안 됨 — 실제 구분 코드만 전달
		p.put("gubunIds", realGubunIds(vo));
		// 열람제한 게이트 — 컨트롤러에서 promReadGuard.applyReadGate(vo) 로 채워진 값 전달
		p.put("applyReadGate", vo.isApplyReadGate());
		p.put("readerEsntlId", vo.getReaderEsntlId());
		p.put("readerOrgnztId", vo.getReaderOrgnztId());
		return p;
	}
}
