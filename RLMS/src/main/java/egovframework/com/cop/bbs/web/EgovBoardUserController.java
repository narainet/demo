package egovframework.com.cop.bbs.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import egovframework.com.cmm.ComDefaultCodeVO;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.service.CmmnDetailCode;
import egovframework.com.cmm.service.EgovCmmUseService;
import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.cop.bbs.service.BoardMaster;
import egovframework.com.cop.bbs.service.BoardMasterVO;
import egovframework.com.cop.bbs.service.BoardReadGuard;
import egovframework.com.cop.bbs.service.BoardWriteGuard;
import egovframework.com.cop.bbs.service.BoardVO;
import egovframework.com.cop.bbs.service.EgovArticleService;
import egovframework.com.cop.bbs.service.EgovBBSMasterService;
import egovframework.com.cop.bbs.service.EgovBBSSatisfactionService;
import egovframework.com.cop.cmt.service.EgovArticleCommentService;

/**
 * 사용자(front) 게시판 이용 Controller — 열람 전용.
 *
 * <p>게시물 <b>관리</b>는 {@link EgovArticleController}(/cop/bbs/*), 게시판 <b>속성관리</b>는
 * {@link EgovBBSMasterController} 가 맡는다. 이 컨트롤러는 로그인 사용자가 게시판을 "읽기"만 하는
 * 동선(/cop/bbs/user/*)을 담당하며, 서비스·VO·화면(JSP)은 관리 화면과 100% 공유한다.
 * 따라서 게시판 스킨(BBS_SKIN_CODE: 목록형/포토형/FAQ/QnA)과 템플릿 CSS(TMPLAT_COURS) 분기가
 * 관리 화면과 동일하게 적용된다.</p>
 *
 * <p><b>URL 을 /cop/bbs/user/ 하위로 분리한 이유</b> — 메뉴(COMTNMENUCREATDTLS)가 URL 접근권한의
 * 단일 원천이고, 그 파생 규칙은 프로그램 URL 의 슬래시가 3개 이상이면 마지막 슬래시까지를 디렉터리
 * 패턴으로 접는다. 열람 URL 을 /cop/bbs/selectArticleList.do 로 두고 사용자 메뉴에 등록하면
 * {@code \A/cop/bbs/.*\Z} 가 조회 역할에까지 부여되어 글쓰기·삭제·게시판관리가 함께 열린다.
 * /cop/bbs/user/ 로 한 단계 내리면 {@code \A/cop/bbs/user/.*\Z} 만 파생되어 열람 전용으로 봉인된다.
 * SiteMesh 데코레이터도 이 경로에만 사용자 레이아웃을 씌울 수 있다.</p>
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *
 *  수정일        수정자    수정내용
 *  ----------   -------   ---------------------------
 *  2026.07.10   RLMS      최초 생성 (사용자 게시판 열람 전용 진입점)
 * </pre>
 */
@Controller
public class EgovBoardUserController {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovBoardUserController.class);

	/** 사용자 열람 URL 접두 — 공유 JSP 가 링크를 만들 때 사용한다(관리 화면은 이 값이 없어 /cop/bbs 기본). */
	private static final String URL_BASE = "/cop/bbs/user";

	/** 사용자 댓글 URL 접두 — 공유 댓글 조각(EgovArticleCommentList.jsp)이 쓰기 링크를 만들 때 사용한다. */
	private static final String CMT_URL_BASE = "/cop/cmt/user";

	/** 사용자 만족도 URL 접두 — 공유 만족도 조각(EgovSatisfactionList.jsp)이 쓰기 링크를 만들 때 사용한다. */
	private static final String STF_URL_BASE = "/cop/stf/user";

	@Resource(name = "EgovArticleService")
	private EgovArticleService egovArticleService;

	@Resource(name = "EgovBBSMasterService")
	private EgovBBSMasterService egovBBSMasterService;

	@Resource(name = "EgovArticleCommentService")
	private EgovArticleCommentService egovArticleCommentService;

	@org.springframework.beans.factory.annotation.Autowired(required = false)
	private EgovBBSSatisfactionService bbsSatisfactionService;

	@Resource(name = "EgovCmmUseService")
	private EgovCmmUseService cmmUseService;

	/** 첨부 이미지 목록 — 갤러리형 상세가 첨부 이미지를 슬라이드로 렌더할 때 사용한다. */
	@Resource(name = "EgovFileMngService")
	private EgovFileMngService fileMngService;

	@Resource(name = "propertiesService")
	private EgovPropertyService propertyService;

	/** 게시판별 열람 권한 — URL 층(폴더 패턴)이 구분하지 못하는 보드 단위 접근제어. */
	@Resource(name = "boardReadGuard")
	private BoardReadGuard boardReadGuard;

	/** 게시판별 작성 권한 — 목록·상세의 쓰기 버튼 노출 여부를 결정한다. */
	@Resource(name = "boardWriteGuard")
	private BoardWriteGuard boardWriteGuard;

	/** 게시판 뷰 카운트 적재(TB_STATS_BBS_VIEW) — 게시판 조회통계 원천 */
	@Resource(name = "statsService")
	private narainet.rlms.stats.service.StatsService statsService;

	/**
	 * 게시물 목록(열람 전용).
	 *
	 * @param boardVO bbsId 필수. 검색조건·페이지는 관리 목록과 동일 파라미터.
	 */
	@RequestMapping(value = "/cop/bbs/user/selectArticleList.do", method = RequestMethod.GET)
	public String selectArticleList(@ModelAttribute("searchVO") BoardVO boardVO, ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return "redirect:/uat/uia/egovLoginUsr.do";
		}

		boardReadGuard.assertReadable(boardVO.getBbsId());

		BoardMasterVO master = selectBoardMaster(boardVO.getBbsId());
		// 방명록(엔진 GUEST)은 방명록 서브앱으로 — 유형 대신 템플릿 엔진코드가 결정한다.
		if ("GUEST".equals(EgovArticleController.resolveEngine(master))) {
			return "forward:/cop/bbs/selectGuestArticleList.do";
		}

		// 삭제글(USE_AT='N')은 사용자에게 감춘다 — 관리 목록의 '삭제됨' 행과 분리.
		boardVO.setIncludeDeleted("N");
		boardVO.setPageSize(propertyService.getInt("pageSize"));

		// 게시판별 목록 페이지당 건수 옵션(LIST_PAGE_UNIT 쉼표목록): 빈값=전역, 단일=고정, 복수=사용자 select.
		java.util.List<Integer> pageUnitOptions = (master == null) ? new java.util.ArrayList<Integer>()
				: EgovArticleController.parsePageUnitOptions(master.getListPageUnit());
		boardVO.setPageUnit(EgovArticleController.resolvePageUnit(pageUnitOptions, boardVO.getPageUnit(), propertyService.getInt("pageUnit")));

		// 캘린더·연혁형(엔진 전건 조회) 또는 페이징 미사용(PAGING_AT='N') 게시판은 전건을 한 페이지에 싣는다(선택 UI 숨김).
		if (EgovArticleController.needsFullFetch(master) || "N".equals(master.getPagingAt())) {
			boardVO.setPageIndex(1);
			boardVO.setPageUnit(EgovArticleController.FETCH_ALL_LIMIT);
			pageUnitOptions = new java.util.ArrayList<Integer>();
		}
		model.addAttribute("pageUnitOptions", pageUnitOptions);

		// 자료실형(ARCHIVE) 사용자 열람은 게시기간을 벗어난(노출예정·노출만료) 자료를 서버에서 숨긴다 — 페이징 건수 정합.
		if ("ARCHIVE".equals(EgovArticleController.resolveEngine(master))) {
			boardVO.setNtceGateAt("Y");
			boardVO.setTodayYmd(new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()));
		}

		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(boardVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(boardVO.getPageUnit());
		paginationInfo.setPageSize(boardVO.getPageSize());

		boardVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		boardVO.setLastIndex(paginationInfo.getLastRecordIndex());
		boardVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		Map<String, Object> map = egovArticleService.selectArticleList(boardVO);
		paginationInfo.setTotalRecordCount(Integer.parseInt((String) map.get("resultCnt")));

		model.addAttribute("resultList", map.get("resultList"));
		model.addAttribute("resultCnt", map.get("resultCnt"));
		model.addAttribute("noticeList", egovArticleService.selectNoticeArticleList(boardVO));
		model.addAttribute("articleVO", boardVO);
		model.addAttribute("boardMasterVO", master);
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("sessionUniqId", currentUniqId());
		// 탭 분류형·자료실형이 여분필드 코드→라벨 변환·탭 구성에 쓴다(다른 엔진엔 무해).
		addExtraFieldCodeOptions(master, model);
		markUserMode(model, boardVO.getBbsId());

		return EgovArticleController.getArticleListViewName(master);
	}

	/**
	 * 게시물 상세(열람 + 댓글). 삭제글·타인의 비밀글은 목록으로 되돌린다.
	 *
	 * <p>댓글은 사용자 동선 /cop/cmt/user/*(cmtUrlBase)로 붙는다. 만족도(/cop/stf)는 등록·수정 후
	 * 관리 URL(/cop/bbs/selectArticleDetail.do)로 redirect 되어 403 이 나므로 아직 싣지 않는다.</p>
	 *
	 * <p>POST 도 받는다 — 댓글 페이징·수정폼 로드가 이 URL 로 폼 submit(POST) 한다.</p>
	 */
	@RequestMapping(value = "/cop/bbs/user/selectArticleDetail.do",
			method = { RequestMethod.GET, RequestMethod.POST })
	public String selectArticleDetail(@ModelAttribute("searchVO") BoardVO boardVO, ModelMap model,
			HttpServletRequest request) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return "redirect:/uat/uia/egovLoginUsr.do";
		}

		boardReadGuard.assertReadable(boardVO.getBbsId());

		BoardMasterVO master = selectBoardMaster(boardVO.getBbsId());
		String uniqId = currentUniqId();
		boardVO.setLastUpdusrId(uniqId);

		// 표준 서비스 재사용. 조회수는 GET(실제 열람)에서만 올린다 —
		// 댓글 페이징·수정폼 로드는 같은 글을 다시 그리는 POST 라 열람으로 세지 않는다.
		boolean plusCount = RequestMethod.GET.name().equals(request.getMethod());
		BoardVO article = egovArticleService.selectArticleDetail(boardVO, plusCount);
		if (article == null || "N".equals(article.getUseAt())
				|| ("Y".equals(article.getSecretAt()) && !uniqId.equals(article.getFrstRegisterId()))) {
			return "redirect:" + URL_BASE + "/selectArticleList.do?bbsId=" + boardVO.getBbsId();
		}

		// 게시판 조회통계 적재 — 유효글 GET 실열람만. 새로고침/재제출 부풀림 방지 =
		// 세션 직전 글(bbsId|nttId) 대조(규정 조회통계 rlmsLastViewPromNo 선례)
		if (plusCount) {
			String viewKey = (boardVO.getBbsId() == null ? "" : boardVO.getBbsId().trim()) + "|" + boardVO.getNttId();
			if (!viewKey.equals(request.getSession().getAttribute("rlmsLastViewNtt"))) {
				try {
					statsService.recordBbsView(boardVO.getBbsId(), boardVO.getNttId());
				} catch (Exception e) {
					LOGGER.warn("게시판 뷰 카운트 적재 실패(무시): {}", e.getMessage());
				}
				request.getSession().setAttribute("rlmsLastViewNtt", viewKey);
			}
		}

		if (egovArticleCommentService != null && egovArticleCommentService.canUseComment(boardVO.getBbsId())) {
			model.addAttribute("useComment", "true");
		}
		if (bbsSatisfactionService != null && bbsSatisfactionService.canUseSatisfaction(boardVO.getBbsId())) {
			model.addAttribute("useSatisfaction", "true");
			model.addAttribute("stfUrlBase", STF_URL_BASE);
		}
		model.addAttribute("result", article);
		model.addAttribute("boardMasterVO", master);
		model.addAttribute("sessionUniqId", uniqId);
		addExtraFieldCodeOptions(master, model);
		EgovArticleController.addGalleryImages(fileMngService, master, article, model);
		EgovArticleController.addArchiveFiles(fileMngService, master, article, model);
		EgovArticleController.addMagazineNav(egovArticleService, master, boardVO.getBbsId(), boardVO.getNttId(), model);
		markUserMode(model, boardVO.getBbsId());

		return EgovArticleController.getArticleDetailViewName(master);
	}

	// ── 내부 ───────────────────────────────────────────────────────

	/**
	 * 공유 JSP 가 사용자 링크·버튼 상태를 결정하는 플래그.
	 * bbsCanWrite 는 화면 게이팅일 뿐이고, 실제 차단은 BoardReadInterceptor 와 BoardWriteGuard 가 한다.
	 */
	private void markUserMode(ModelMap model, String bbsId) {
		model.addAttribute("bbsUserMode", "Y");
		model.addAttribute("bbsUrlBase", URL_BASE);
		model.addAttribute("cmtUrlBase", CMT_URL_BASE);
		model.addAttribute("bbsCanWrite", Boolean.valueOf(boardWriteGuard.canWrite(bbsId)));
	}

	/** 게시판 마스터(스킨·템플릿·옵션 포함). 없는 bbsId 면 표준과 동일하게 예외로 차단된다. */
	private BoardMasterVO selectBoardMaster(String bbsId) throws Exception {
		BoardMasterVO param = new BoardMasterVO();
		param.setBbsId(bbsId);
		param.setUniqId(currentUniqId());

		BoardMasterVO master = egovBBSMasterService.selectBBSMasterInf(param);
		if (master.getTmplatCours() == null || master.getTmplatCours().equals("")) {
			master.setTmplatCours("/css/egovframework/com/cop/tpl/egovBaseTemplate.css");
		}
		return master;
	}

	/** 확장필드의 radio/select 코드값 → 코드명 변환용 옵션. 관리 상세와 동일. */
	private void addExtraFieldCodeOptions(BoardMaster master, ModelMap model) throws Exception {
		Map<Integer, List<CmmnDetailCode>> options = new LinkedHashMap<Integer, List<CmmnDetailCode>>();
		if (master != null) {
			for (int i = 1; i <= 10; i++) {
				String fieldType = master.getBbsExtraFieldType(i);
				String codeId = master.getBbsExtraFieldCodeId(i);
				if (("radio".equals(fieldType) || "select".equals(fieldType) || "checkbox".equals(fieldType))
						&& codeId != null && !"".equals(codeId.trim())) {
					ComDefaultCodeVO codeVO = new ComDefaultCodeVO();
					codeVO.setCodeId(codeId.trim());
					options.put(Integer.valueOf(i), cmmUseService.selectCmmCodeDetail(codeVO));
				}
			}
		}
		model.addAttribute("bbsExtraCodeOptions", options);
	}

	/** 로그인 사용자 고유ID(ESNTL_ID). 미인증/실패 시 "". */
	private String currentUniqId() {
		try {
			Object au = EgovUserDetailsHelper.getAuthenticatedUser();
			if (au instanceof LoginVO) {
				String id = ((LoginVO) au).getUniqId();
				return id == null ? "" : id;
			}
		} catch (Exception e) {
			LOGGER.warn("로그인 정보 조회 실패: {}", e.getMessage());
		}
		return "";
	}
}
