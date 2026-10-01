/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/FullTextSearchServiceImpl.java
 */
package narainet.rlms.prom.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.stereotype.Service;

import narainet.rlms.prom.mapper.ProvVrsnMapper;
import narainet.rlms.prom.service.FullTextSearchService;
import narainet.rlms.prom.service.ProvVrsnVO;

/**
 * Oracle Text 기반 전문검색 Service 구현체.
 * IDX_PROV_VRSN_FT (CTXSYS.CONTEXT, KOREAN_MORPH_LEXER) 활용.
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Service("fullTextSearchService")
public class FullTextSearchServiceImpl extends EgovAbstractServiceImpl
		implements FullTextSearchService {

	@Resource(name = "provVrsnMapper")
	private ProvVrsnMapper provVrsnMapper;

	/** 분류별 열람제한 게이트 (front 전문검색) */
	@Resource(name = "promReadGuard")
	private narainet.rlms.prom.service.PromReadGuard promReadGuard;

	@Override
	public Map<String, Object> searchInProvVrsn(String sysId, String keyword,
			int pageIndex, int pageUnit) {

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(pageIndex);
		pi.setRecordCountPerPage(pageUnit);
		pi.setPageSize(pageUnit);

		int first = pi.getFirstRecordIndex();

		boolean gate = promReadGuard.gateNeeded();
		String rEsntl = promReadGuard.readerEsntlId();
		String rOrgnzt = promReadGuard.readerOrgnztId();
		List<ProvVrsnVO> list = provVrsnMapper.selectFullTextSearch(
				sysId, keyword, first, pageUnit, gate, rEsntl, rOrgnzt);
		int cnt = provVrsnMapper.selectFullTextSearchCnt(sysId, keyword, gate, rEsntl, rOrgnzt);
		pi.setTotalRecordCount(cnt);

		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		map.put("paginationInfo", pi);
		return map;
	}
}
