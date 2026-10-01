/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/search/service/UnifiedSearchService.java
 */
package narainet.rlms.search.service;

import java.util.List;
import java.util.Map;

import narainet.rlms.prom.service.PromVO;

/**
 * 통합검색 서비스 — 6축(규정제목/조문/별표서식/자료/게시판/FAQ).
 *
 * <pre>
 * << 개정이력 >>
 *   2026.07.07   RLMS 전환팀   최초 생성 (지능형 통합검색 v1)
 * </pre>
 */
public interface UnifiedSearchService {

	/** 축 식별자 — prom(규정) / prov(조문) / docu(별표서식) / rel(자료) / bbs(게시판) / faq(FAQ) */
	String TAB_PROM = "prom";
	String TAB_PROV = "prov";
	String TAB_DOCU = "docu";
	String TAB_REL  = "rel";
	String TAB_BBS  = "bbs";
	String TAB_FAQ  = "faq";

	/** 분류 체크박스의 콘텐츠 축 토글 코드 — 규정 구분(FT_GUBUN_N)과 같은 gubunIds 로 넘어오는 가상 분류.
	 *  아무것도 체크 안 하면 전축 검색(무필터), 체크가 있으면 체크된 축만 검색(2026-07-20). */
	String GUBUN_AXIS_BBS = "AXIS_BBS";
	String GUBUN_AXIS_FAQ = "AXIS_FAQ";

	/** 6축 건수 — {promCnt, provCnt, docuCnt, relCnt, bbsCnt, faqCnt} */
	Map<String, Integer> counts(PromVO vo);

	/** 한 축의 검색 결과 (페이징) */
	List<Map<String, Object>> search(String tab, PromVO vo, int firstIndex, int recordCountPerPage);

	/** 검색어 적재(TB_STATS_KWD, 검색 1회=1행 — 레거시 방식 계승). 채번=COMTECOPSEQ 'STATS_KWD_NO' */
	void logKeyword(String keyword) throws Exception;

	/** 최근 days 일 인기 검색어 상위 topN (SUM(ICNT) 내림차순) */
	List<String> popularKeywords(int days, int topN);
}
