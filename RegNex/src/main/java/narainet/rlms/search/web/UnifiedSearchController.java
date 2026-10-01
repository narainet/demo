/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/search/web/UnifiedSearchController.java
 *
 * 통합검색 (사용자 화면) Controller.
 *   GET /rlms/fulltext/searchAll.do?searchKeyword=&tab=all|prom|prov|docu|rel|bbs|faq&pageIndex=&cateNo=&gubunIds=FT_GUBUN_N|AXIS_BBS|AXIS_FAQ
 *   - /rlms/fulltext/* 네임스페이스 → 기존 L6 폴더패턴(ROLE_USER)·front 데코레이터 자동 적용(설정 변경 0건).
 *   - 전체(all) 탭 = 축당 상위 5건 + 축별 건수. 개별 탭 = 페이징 목록.
 *   - 열람제한(TB_CATE_READER/TB_GUBUN_READER)·유효기간 게이트 규정 축 적용. 게시판축=BoardReadGuard.
 */
package narainet.rlms.search.web;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.common.service.FtGubunService;
import narainet.rlms.common.service.PublicFront;
import narainet.rlms.prom.service.PromReadGuard;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.search.service.UnifiedSearchService;

@Controller
public class UnifiedSearchController {

	private static final Logger LOGGER = LoggerFactory.getLogger(UnifiedSearchController.class);

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	/** 전체 탭에서 축당 미리보기 건수 */
	private static final int PREVIEW_ROWS = 5;

	/** 인기 검색어 칩 — 집계 기간(일)/노출 수 */
	private static final int POPULAR_KWD_DAYS = 30;
	private static final int POPULAR_KWD_TOP = 10;

	@Resource(name = "unifiedSearchService")
	private UnifiedSearchService unifiedSearchService;

	@Resource(name = "promReadGuard")
	private PromReadGuard promReadGuard;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	@Resource(name = "ftGubunService")
	private FtGubunService ftGubunService;

	/** 사용자 활동 로그(TB_ACT_LOG) — 통합검색 적재 */
	@Resource(name = "statsService")
	private narainet.rlms.stats.service.StatsService statsService;

	/** 구분(SGUBUN) 체크박스 목록 — 검색폼 공용 (FullTextController 와 동일 패턴) */
	@ModelAttribute("gubunList")
	public List<Map<String, Object>> gubunList() {
		return ftGubunService.gubunList();
	}

	@RequestMapping("/rlms/fulltext/searchAll.do")
	public String searchAll(@ModelAttribute("searchVO") PromVO searchVO,
			@RequestParam(value = "tab", required = false, defaultValue = "all") String tab,
			HttpServletRequest request, ModelMap model) throws Exception {

		if (!PublicFront.viewAllowed()) {
			return LOGIN_REDIRECT;
		}
		if (!isValidTab(tab)) {
			tab = "all";
		}
		model.addAttribute("tab", tab);

		// 인기 검색어 칩 — 실패해도 검색 화면은 정상 렌더
		try {
			model.addAttribute("popularKwds", unifiedSearchService.popularKeywords(POPULAR_KWD_DAYS, POPULAR_KWD_TOP));
		} catch (Exception e) {
			LOGGER.warn("인기 검색어 조회 실패(칩 생략): {}", e.getMessage());
		}

		String keyword = searchVO.getSearchKeyword() == null ? "" : searchVO.getSearchKeyword().trim();
		if (keyword.isEmpty()) {
			// 키워드 없이 진입 — 빈 검색폼만 렌더 (제로 상태)
			model.addAttribute("hasQuery", false);
			return "rlms/fulltext/searchAll";
		}
		model.addAttribute("hasQuery", true);

		// 검색어 통계 적재 — 탭 전환/페이징 재제출로 부풀지 않게 세션 직전 검색어와 다를 때만
		HttpSession session = request.getSession();
		if (!keyword.equals(session.getAttribute("rlmsLastSearchKwd"))) {
			try {
				unifiedSearchService.logKeyword(keyword);
			} catch (Exception e) {
				LOGGER.warn("검색어 통계 적재 실패(무시): {}", e.getMessage());
			}
			// 사용자 활동 로그 — 검색어 통계와 같은 세션 dedup.
			// 공개열람 익명은 제외(검색어 통계 logKeyword 만 집계) — 활동 로그는 로그인 사용자 감사 용도.
			egovframework.com.cmm.LoginVO actUser =
					(egovframework.com.cmm.LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
			if (actUser != null) {
				statsService.recordAction("통합검색", null, null, keyword,
						actUser.getId(), actUser.getName(),
						egovframework.com.utl.sim.service.EgovClntInfo.getClntIP(request));
			}
			session.setAttribute("rlmsLastSearchKwd", keyword);
		}

		promReadGuard.applyReadGate(searchVO);   // 분류/구분 열람제한(면제역할 제외)

		// 축 제외 플래그 — 분류 체크(또는 좌측 트리 클릭의 gubunIds 자동 주입)로 검색에서 빠진 축을
		// JSP 가 '0건'과 구분해 '–'/안내문으로 표기(오독 방지). 판정 규칙은 UnifiedSearchServiceImpl 과 동일.
		List<String> gsel = searchVO.getGubunIds();
		boolean hasGubunFilter = gsel != null && !gsel.isEmpty();
		boolean promAxesOff = false;
		if (hasGubunFilter) {
			List<String> realG = new ArrayList<>(gsel);
			realG.removeAll(Arrays.asList(UnifiedSearchService.GUBUN_AXIS_BBS, UnifiedSearchService.GUBUN_AXIS_FAQ));
			promAxesOff = realG.isEmpty();
		}
		model.addAttribute("promAxesOff", promAxesOff);
		model.addAttribute("bbsAxisOff", hasGubunFilter && !gsel.contains(UnifiedSearchService.GUBUN_AXIS_BBS));
		model.addAttribute("faqAxisOff", hasGubunFilter && !gsel.contains(UnifiedSearchService.GUBUN_AXIS_FAQ));

		// 축별 건수 — 탭 배지 공용
		Map<String, Integer> counts = unifiedSearchService.counts(searchVO);
		model.addAttribute("counts", counts);
		int totalCnt = counts.get("promCnt") + counts.get("provCnt")
				+ counts.get("docuCnt") + counts.get("relCnt")
				+ counts.get("bbsCnt") + counts.get("faqCnt");
		model.addAttribute("totalCnt", totalCnt);

		if ("all".equals(tab)) {
			// 전체 탭 — 축당 상위 N건 미리보기
			model.addAttribute("promList", unifiedSearchService.search(UnifiedSearchService.TAB_PROM, searchVO, 0, PREVIEW_ROWS));
			model.addAttribute("provList", unifiedSearchService.search(UnifiedSearchService.TAB_PROV, searchVO, 0, PREVIEW_ROWS));
			model.addAttribute("docuList", unifiedSearchService.search(UnifiedSearchService.TAB_DOCU, searchVO, 0, PREVIEW_ROWS));
			model.addAttribute("relList",  unifiedSearchService.search(UnifiedSearchService.TAB_REL,  searchVO, 0, PREVIEW_ROWS));
			model.addAttribute("bbsList",  unifiedSearchService.search(UnifiedSearchService.TAB_BBS,  searchVO, 0, PREVIEW_ROWS));
			model.addAttribute("faqList",  unifiedSearchService.search(UnifiedSearchService.TAB_FAQ,  searchVO, 0, PREVIEW_ROWS));
			model.addAttribute("previewRows", PREVIEW_ROWS);
			return "rlms/fulltext/searchAll";
		}

		// 개별 탭 — 페이징 목록
		int pageUnit = propertyService.getInt("pageUnit");
		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(pageUnit);
		pi.setPageSize(propertyService.getInt("pageSize"));
		pi.setTotalRecordCount(tabCount(counts, tab));

		List<Map<String, Object>> list = unifiedSearchService.search(
				tab, searchVO, pi.getFirstRecordIndex(), pageUnit);
		model.addAttribute("resultList", list);
		model.addAttribute("paginationInfo", pi);
		return "rlms/fulltext/searchAll";
	}

	private boolean isValidTab(String tab) {
		return "all".equals(tab) || UnifiedSearchService.TAB_PROM.equals(tab)
				|| UnifiedSearchService.TAB_PROV.equals(tab)
				|| UnifiedSearchService.TAB_DOCU.equals(tab)
				|| UnifiedSearchService.TAB_REL.equals(tab)
				|| UnifiedSearchService.TAB_BBS.equals(tab)
				|| UnifiedSearchService.TAB_FAQ.equals(tab);
	}

	private int tabCount(Map<String, Integer> counts, String tab) {
		if (UnifiedSearchService.TAB_PROV.equals(tab)) return counts.get("provCnt");
		if (UnifiedSearchService.TAB_DOCU.equals(tab)) return counts.get("docuCnt");
		if (UnifiedSearchService.TAB_REL.equals(tab))  return counts.get("relCnt");
		if (UnifiedSearchService.TAB_BBS.equals(tab))  return counts.get("bbsCnt");
		if (UnifiedSearchService.TAB_FAQ.equals(tab))  return counts.get("faqCnt");
		return counts.get("promCnt");
	}
}
