package egovframework.com.cop.bbs.web;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springmodules.validation.commons.DefaultBeanValidator;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.ComDefaultCodeVO;
import egovframework.com.cmm.service.CmmnDetailCode;
import egovframework.com.cmm.service.EgovCmmUseService;
import egovframework.com.cmm.service.EgovFileMngService;
import egovframework.com.cmm.service.FileVO;
import egovframework.com.cmm.service.EgovFileMngUtil;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.cmm.util.EgovXssChecker;
import egovframework.com.cop.bbs.service.Board;
import egovframework.com.cop.bbs.service.BoardMaster;
import egovframework.com.cop.bbs.service.BoardExtraFieldSupport;
import egovframework.com.cop.bbs.service.BoardMasterVO;
import egovframework.com.cop.bbs.service.BoardVO;
import egovframework.com.cop.bbs.service.EgovArticleService;
import egovframework.com.cop.bbs.service.EgovBBSMasterService;
import egovframework.com.cop.bbs.service.EgovBBSSatisfactionService;
import egovframework.com.cop.cmt.service.EgovArticleCommentService;
import egovframework.com.cmm.util.RichTextSanitizer;
import org.springframework.web.util.HtmlUtils;
import egovframework.com.utl.fcc.service.EgovStringUtil;

/**
 * 게시물 관리를 위한 컨트롤러 클래스
 * @author 공통서비스개발팀 이삼섭
 * @since 2009.06.01
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *   
 *  수정일               수정자            수정내용
 *  ----------   -------    ---------------------------
 *  2009.03.19   이삼섭            최초 생성
 *  2009.06.29   한성곤            2단계 기능 추가 (댓글관리, 만족도조사)
 *  2011.07.01   안민정            댓글, 스크랩, 만족도 조사 기능의 종속성 제거
 *  2011.08.26   정진오            IncludedInfo annotation 추가
 *  2011.09.07   서준식            유효 게시판 게시일 지나도 게시물이 조회되던 오류 수정
 *  2016.06.13   김연호            표준프레임워크 3.6 개선
 *  2019.05.17   신용호            KISA 취약점 조치 및 보완
 *  2020.10.27   신용호            파일 업로드 수정 (multiRequest.getFiles)
 *  2022.11.11   김혜준            시큐어코딩 처리
 *  2024.10.29	LeeBaekHaeng	게시판 검색조건 유지
 *  2024.10.29	inganyoyo		Transaction 처리 오류 수정(Article)
 *  
 * </pre>
 */

@Controller
public class EgovArticleController {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovArticleController.class);
	
	@Resource(name = "EgovArticleService")
    private EgovArticleService egovArticleService;

    @Resource(name = "EgovBBSMasterService")
    private EgovBBSMasterService egovBBSMasterService;

    @Resource(name = "EgovFileMngService")
    private EgovFileMngService fileMngService;

    @Resource(name = "EgovFileMngUtil")
    private EgovFileMngUtil fileUtil;

    @Resource(name = "propertiesService")
    protected EgovPropertyService propertyService;
    
    @Resource(name="egovMessageSource")
    EgovMessageSource egovMessageSource;
    
    @Resource(name = "EgovArticleCommentService")
    protected EgovArticleCommentService egovArticleCommentService;

    @Resource(name = "EgovBBSSatisfactionService")
    private EgovBBSSatisfactionService bbsSatisfactionService;

	@Resource(name = "EgovCmmUseService")
	private EgovCmmUseService cmmUseService;
    
    @Autowired
    private DefaultBeanValidator beanValidator;

    //protected Logger log = Logger.getLogger(this.getClass());
    
    /**
     * XSS 방지 처리.
     * 
     * @param data
     * @return
     */
    protected String unscript(String data) {
        if (data == null || data.trim().equals("")) {
            return "";
        }
        
        String ret = data;
        
        ret = ret.replaceAll("<(S|s)(C|c)(R|r)(I|i)(P|p)(T|t)", "&lt;script");
        ret = ret.replaceAll("</(S|s)(C|c)(R|r)(I|i)(P|p)(T|t)", "&lt;/script");
        
        ret = ret.replaceAll("<(O|o)(B|b)(J|j)(E|e)(C|c)(T|t)", "&lt;object");
        ret = ret.replaceAll("</(O|o)(B|b)(J|j)(E|e)(C|c)(T|t)", "&lt;/object");
        
        ret = ret.replaceAll("<(A|a)(P|p)(P|p)(L|l)(E|e)(T|t)", "&lt;applet");
        ret = ret.replaceAll("</(A|a)(P|p)(P|p)(L|l)(E|e)(T|t)", "&lt;/applet");
        
        ret = ret.replaceAll("<(E|e)(M|m)(B|b)(E|e)(D|d)", "&lt;embed");
        ret = ret.replaceAll("</(E|e)(M|m)(B|b)(E|e)(D|d)", "&lt;embed");
        
        ret = ret.replaceAll("<(F|f)(O|o)(R|r)(M|m)", "&lt;form");
        ret = ret.replaceAll("</(F|f)(O|o)(R|r)(M|m)", "&lt;form");

        return ret;
    }

    private boolean isAdminUser() {
        List<String> authorities = EgovUserDetailsHelper.getAuthorities();
        return authorities != null && authorities.contains("ROLE_ADMIN");
    }

    /**
     * 게시물에 대한 목록을 조회한다.
     * 
     * @param boardVO
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/selectArticleList.do")
    public String selectArticleList(@ModelAttribute("searchVO") BoardVO boardVO, ModelMap model) throws Exception {
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();	//KISA 보안취약점 조치 (2018-12-10, 이정은)

        if(!isAuthenticated) {
            return "redirect:/uat/uia/egovLoginUsr.do";
        }

        boardVO.setIncludeDeleted(isAdminUser() ? "Y" : "N");
	
		BoardMasterVO vo = new BoardMasterVO();
		
		vo.setBbsId(boardVO.getBbsId());
		vo.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		BoardMasterVO master = egovBBSMasterService.selectBBSMasterInf(vo);
		
		// 방명록(엔진 GUEST)은 방명록 서브앱으로 이동 — 유형(BBST03) 대신 템플릿 엔진코드가 결정한다.
		// resolveEngine 이 템플릿→스킨→유형(BBST03) 순으로 GUEST 를 판정하므로 기존 방명록도 그대로 동작한다.
		if ("GUEST".equals(resolveEngine(master))) {
			return "forward:/cop/bbs/selectGuestArticleList.do";
		}


		boardVO.setPageSize(propertyService.getInt("pageSize"));

		// 게시판별 목록 페이지당 건수 옵션(LIST_PAGE_UNIT 쉼표목록): 빈값=전역, 단일=고정, 복수=사용자 select.
		List<Integer> pageUnitOptions = (master == null) ? new ArrayList<Integer>() : parsePageUnitOptions(master.getListPageUnit());
		boardVO.setPageUnit(resolvePageUnit(pageUnitOptions, boardVO.getPageUnit(), propertyService.getInt("pageUnit")));

		// 캘린더·연혁형(엔진 전건 조회) 또는 페이징 미사용(PAGING_AT='N') 게시판은 전건을 한 페이지에 싣는다(선택 UI 숨김).
		if (needsFullFetch(master) || (master != null && "N".equals(master.getPagingAt()))) {
			boardVO.setPageIndex(1);
			boardVO.setPageUnit(FETCH_ALL_LIMIT);
			pageUnitOptions = new ArrayList<Integer>();
		}
		model.addAttribute("pageUnitOptions", pageUnitOptions);
	
		PaginationInfo paginationInfo = new PaginationInfo();
		
		paginationInfo.setCurrentPageNo(boardVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(boardVO.getPageUnit());
		paginationInfo.setPageSize(boardVO.getPageSize());
	
		boardVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		boardVO.setLastIndex(paginationInfo.getLastRecordIndex());
		boardVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());
	
		Map<String, Object> map = egovArticleService.selectArticleList(boardVO);
		int totCnt = Integer.parseInt((String)map.get("resultCnt"));
		
		//공지사항 추출
		List<BoardVO> noticeList = egovArticleService.selectNoticeArticleList(boardVO);
		
		paginationInfo.setTotalRecordCount(totCnt);
	
		//-------------------------------
		// 기본 BBS template 지정 
		//-------------------------------
		if (master.getTmplatCours() == null || master.getTmplatCours().equals("")) {
		    master.setTmplatCours("/css/egovframework/com/cop/tpl/egovBaseTemplate.css");
		}
		////-----------------------------
	
		if(user != null) {
	    	model.addAttribute("sessionUniqId", user.getUniqId());
	    }
		
		model.addAttribute("resultList", map.get("resultList"));
		model.addAttribute("resultCnt", map.get("resultCnt"));
		model.addAttribute("articleVO", boardVO);
		model.addAttribute("boardMasterVO", master);
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("noticeList", noticeList);
		// 탭 분류형·자료실형이 여분필드 코드→라벨 변환·탭 구성에 쓴다(다른 엔진엔 무해).
		addExtraFieldCodeOptions(master, model);
		return getArticleListViewName(master);
    }
    
    
    
    /**
     * 게시물에 대한 상세 정보를 조회한다.
     * 
     * @param boardVO
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/selectArticleDetail.do")
    public String selectArticleDetail(@ModelAttribute("searchVO") BoardVO boardVO, ModelMap model) throws Exception {
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();	//KISA 보안취약점 조치 (2018-12-10, 이정은)

        if(!isAuthenticated) {
            return "redirect:/uat/uia/egovLoginUsr.do";
        }

	
		boardVO.setLastUpdusrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		boardVO.setIncludeDeleted(isAdminUser() ? "Y" : "N");
		BoardVO vo = egovArticleService.selectArticleDetail(boardVO);
		if (vo == null) {
			return "forward:/cop/bbs/selectArticleList.do";
		}
	
		model.addAttribute("result", vo);
		model.addAttribute("sessionUniqId", (user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		model.addAttribute("isAdmin", isAdminUser());	// 삭제글 배지/복구 동선 게이팅용
		
		//비밀글은 작성자만 볼수 있음 
		if(!EgovStringUtil.isEmpty(vo.getSecretAt()) && vo.getSecretAt().equals("Y") && !((user == null || user.getUniqId() == null) ? "" : user.getUniqId()).equals(vo.getFrstRegisterId()))
			return"forward:/cop/bbs/selectArticleList.do";
		
		//----------------------------
		// template 처리 (기본 BBS template 지정  포함)
		//----------------------------
		BoardMasterVO master = new BoardMasterVO();
		
		master.setBbsId(boardVO.getBbsId());
		master.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		
		BoardMasterVO masterVo = egovBBSMasterService.selectBBSMasterInf(master);
	
		if (masterVo.getTmplatCours() == null || masterVo.getTmplatCours().equals("")) {
		    masterVo.setTmplatCours("/css/egovframework/com/cop/tpl/egovBaseTemplate.css");
		}
	
		////-----------------------------
		
		//----------------------------
		// 2009.06.29 : 2단계 기능 추가
		// 2011.07.01 : 댓글, 만족도 조사 기능의 종속성 제거
		//----------------------------
		if (egovArticleCommentService != null){
			if (egovArticleCommentService.canUseComment(boardVO.getBbsId())) {
			    model.addAttribute("useComment", "true");
			}
		}
		if (bbsSatisfactionService != null) {
			if (bbsSatisfactionService.canUseSatisfaction(boardVO.getBbsId())) {
			    model.addAttribute("useSatisfaction", "true");
			}
		}
		////--------------------------
		
		model.addAttribute("boardMasterVO", masterVo);
		addExtraFieldCodeOptions(masterVo, model);
		addGalleryImages(fileMngService, masterVo, vo, model);
		addArchiveFiles(fileMngService, masterVo, vo, model);
		addMagazineNav(egovArticleService, masterVo, boardVO.getBbsId(), boardVO.getNttId(), model);

		return getArticleDetailViewName(masterVo);
    }

    /**
     * 게시물 등록을 위한 등록페이지로 이동한다.
     * 
     * @param boardVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/bbs/insertArticleView.do", "/cop/bbs/user/insertArticleView.do"})
    public String insertArticleView(HttpServletRequest request, @ModelAttribute("searchVO") BoardVO boardVO, ModelMap model) throws Exception {
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
	
		BoardMasterVO bdMstr = new BoardMasterVO();

		if (isAuthenticated) {
	
		    BoardMasterVO vo = new BoardMasterVO();
		    vo.setBbsId(boardVO.getBbsId());
		    vo.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		    bdMstr = egovBBSMasterService.selectBBSMasterInf(vo);
		}
	
		//----------------------------
		// 기본 BBS template 지정 
		//----------------------------
		if (bdMstr.getTmplatCours() == null || bdMstr.getTmplatCours().equals("")) {
		    bdMstr.setTmplatCours("/css/egovframework/com/cop/tpl/egovBaseTemplate.css");
		}
	
		model.addAttribute("articleVO", boardVO);
		model.addAttribute("boardMasterVO", bdMstr);
		addExtraFieldCodeOptions(bdMstr, model);
		applyUserMode(request, model);
		////-----------------------------
	
		return "egovframework/com/cop/bbs/EgovArticleRegist";
    }

    /**
     * 게시물을 등록한다.
     * 
     * @param boardVO
     * @param board
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/bbs/insertArticle.do", "/cop/bbs/user/insertArticle.do"})
    public String insertArticle(final MultipartHttpServletRequest multiRequest, @ModelAttribute("searchVO") BoardVO boardVO,
	    @ModelAttribute("bdMstr") BoardMaster bdMstr, @ModelAttribute("board") BoardVO board, BindingResult bindingResult, 
	    ModelMap model) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		if(!isAuthenticated) {	//KISA 보안취약점 조치 (2018-12-10, 이정은)
            return "redirect:/uat/uia/egovLoginUsr.do";
        }
	
		beanValidator.validate(board, bindingResult);
		if (bindingResult.hasErrors()) {
	
		    BoardMasterVO master = new BoardMasterVO();
		    
		    master.setBbsId(boardVO.getBbsId());
		    master.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		    master = egovBBSMasterService.selectBBSMasterInf(master);
		    
	
		    //----------------------------
		    // 기본 BBS template 지정 
		    //----------------------------
		    if (master.getTmplatCours() == null || master.getTmplatCours().equals("")) {
			master.setTmplatCours("css/egovframework/com/cop/tpl/egovBaseTemplate.css");
		    }
	
		    model.addAttribute("boardMasterVO", master);
		    addExtraFieldCodeOptions(master, model);
		    applyUserMode(multiRequest, model);
		    ////-----------------------------
	
		    return "egovframework/com/cop/bbs/EgovArticleRegist";
		}

		// 2022.11.11 시큐어코딩 처리
	    
	    //final Map<String, MultipartFile> files = multiRequest.getFileMap();
	    final List<MultipartFile> files = multiRequest.getFiles("file_1");

	    board.setFrstRegisterId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	    board.setBbsId(boardVO.getBbsId());


	    //익명등록 처리 
	    if(board.getAnonymousAt() != null && board.getAnonymousAt().equals("Y")){
	    	board.setNtcrId("anonymous"); //게시물 통계 집계를 위해 등록자 ID 저장
	    	board.setNtcrNm("익명"); //게시물 통계 집계를 위해 등록자 Name 저장
	    	board.setFrstRegisterId("anonymous");
	    	
	    } else {
	    	board.setNtcrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId()); //게시물 통계 집계를 위해 등록자 ID 저장
	    	board.setNtcrNm((user == null || user.getName() == null) ? "" : user.getName()); //게시물 통계 집계를 위해 등록자 Name 저장
	    	
	    }
	    
	    // 게시판 정책(비밀글 허용·첨부 최대용량) 확인용 마스터 로드.
	    BoardMasterVO polMaster = new BoardMasterVO();
	    polMaster.setBbsId(boardVO.getBbsId());
	    polMaster.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	    polMaster = egovBBSMasterService.selectBBSMasterInf(polMaster);
	    // 비밀글 미허용(SECRET_POSBL_AT='N') 게시판은 폼 우회(직접 POST) 방지를 위해 서버측에서 비밀글을 강제 해제.
	    if (polMaster != null && "N".equals(polMaster.getSecretPosblAt())) {
	        board.setSecretAt("N");
	    }
	    // 게시판별 첨부 1파일 최대 용량(MB) 초과 검사 — 초과 시 폼으로 되돌리며 안내(시스템 50MB 한도는 멀티파트가 이미 거른다).
	    if (polMaster != null && files != null) {
	        long maxMb = 0;
	        try {
	            maxMb = Long.parseLong(polMaster.getAtchPosblFileSize() == null ? "" : polMaster.getAtchPosblFileSize().trim());
	        } catch (NumberFormatException ignore) {
	            maxMb = 0;
	        }
	        if (maxMb > 0) {
	            long maxBytes = maxMb * 1024L * 1024L;
	            for (MultipartFile f : files) {
	                if (f != null && !f.isEmpty() && f.getSize() > maxBytes) {
	                    model.addAttribute("articleVO", board);   // 폼 재바인딩(입력내용 유지) — insertArticleView 와 동일 커맨드명.
	                    model.addAttribute("boardMasterVO", polMaster);
	                    addExtraFieldCodeOptions(polMaster, model);
	                    applyUserMode(multiRequest, model);
	                    model.addAttribute("fileSizeError", "첨부파일 '" + f.getOriginalFilename() + "' 이(가) 이 게시판의 최대 허용 용량(" + maxMb + "MB)을 초과합니다.");
	                    return "egovframework/com/cop/bbs/EgovArticleRegist";
	                }
	            }
	        }
	    }
	    // CKEditor 리치텍스트: HTMLTagFilter 가 넣은 엔티티를 복원 후 jsoup allowlist 로 새니타이즈.
	    // (unscript 는 script류 여는 태그만 지워 onerror=/javascript: 를 못 막으므로 대체)
	    board.setNttCn(RichTextSanitizer.clean(board.getNttCn(), multiRequest));
	    // 제목(평문)은 HTMLTagFilter 가 넣은 엔티티를 복원 — 출력단 c:out 이스케이프로 XSS-safe.
	    board.setNttSj(decodeFilteredPlainText(board.getNttSj()));
	    // 체크박스 여분필드는 폼 바인딩 대상이 아니다 — 선택값을 쉼표로 이어 서버가 싣는다.
	    BoardExtraFieldSupport.applyMultiValueFields(multiRequest, board);
    egovArticleService.insertArticleAndFiles(board, files);

		model.addAttribute("bbsId", boardVO.getBbsId());
		model.addAttribute("searchCnd", boardVO.getSearchCnd());
		model.addAttribute("searchWrd", boardVO.getSearchWrd());
		model.addAttribute("pageIndex", boardVO.getPageIndex());
		return "redirect:" + urlBase(multiRequest) + "/selectArticleList.do";
    }

    /**
     * 게시물에 대한 답변 등록을 위한 등록페이지로 이동한다.
     * 
     * @param boardVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/bbs/replyArticleView.do", "/cop/bbs/user/replyArticleView.do"})
    public String addReplyBoardArticle(HttpServletRequest request, @ModelAttribute("searchVO") BoardVO boardVO, ModelMap model) throws Exception {
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();//KISA 보안취약점 조치 (2018-12-10, 이정은)

        if(!isAuthenticated) {
            return "redirect:/uat/uia/egovLoginUsr.do";
        }
        
		BoardMasterVO master = new BoardMasterVO();
		BoardVO articleVO = new BoardVO();
		master.setBbsId(boardVO.getBbsId());
		master.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		master = egovBBSMasterService.selectBBSMasterInf(master);
		boardVO = egovArticleService.selectArticleDetail(boardVO);

		// 삭제(톰스톤)·부재 게시물 — 상세조회가 USE_AT='Y' 필터라 null. 편집 동선은 목록으로.
		if (boardVO == null) {
		    model.addAttribute("bbsId", master.getBbsId());
		    return "redirect:" + urlBase(request) + "/selectArticleList.do";
		}

		//----------------------------
		// 기본 BBS template 지정
		//----------------------------
		if (master.getTmplatCours() == null || master.getTmplatCours().equals("")) {
		    master.setTmplatCours("/css/egovframework/com/cop/tpl/egovBaseTemplate.css");
		}
	
		// 답글을 허용하지 않는 게시판에 사용자가 URL 로 직접 들어오는 것을 막는다(화면은 버튼을 감춘다).
		if (isUserMode(request) && !"Y".equals(master.getReplyPosblAt())) {
		    throw new AccessDeniedException("이 게시판은 답글을 허용하지 않습니다.");
		}

		model.addAttribute("boardMasterVO", master);
		model.addAttribute("result", boardVO);
	
		model.addAttribute("articleVO", articleVO);
		applyUserMode(request, model);

		return "egovframework/com/cop/bbs/EgovArticleReply";
    }

    /**
     * 게시물에 대한 답변을 등록한다.
     * 
     * @param boardVO
     * @param board
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/bbs/replyArticle.do", "/cop/bbs/user/replyArticle.do"})
    public String replyBoardArticle(final MultipartHttpServletRequest multiRequest, @ModelAttribute("searchVO") BoardVO boardVO,
	    @ModelAttribute("bdMstr") BoardMaster bdMstr, @ModelAttribute("board") BoardVO board, BindingResult bindingResult, ModelMap model
	    ) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		if(!isAuthenticated) {	//KISA 보안취약점 조치 (2018-12-10, 이정은)
            return "redirect:/uat/uia/egovLoginUsr.do";
        }

	    BoardMasterVO master = new BoardMasterVO();
	    
	    master.setBbsId(boardVO.getBbsId());
	    master.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());

	    master = egovBBSMasterService.selectBBSMasterInf(master);

	    //----------------------------
	    // 기본 BBS template 지정 
	    //----------------------------
	    if (master.getTmplatCours() == null || master.getTmplatCours().equals("")) {
		master.setTmplatCours("/css/egovframework/com/cop/tpl/egovBaseTemplate.css");
	    }

		if (isUserMode(multiRequest) && !"Y".equals(master.getReplyPosblAt())) {
		    throw new AccessDeniedException("이 게시판은 답글을 허용하지 않습니다.");
		}

		beanValidator.validate(board, bindingResult);
		if (bindingResult.hasErrors()) {
	
		    model.addAttribute("articleVO", boardVO);
		    model.addAttribute("boardMasterVO", master);
		    applyUserMode(multiRequest, model);
		    ////-----------------------------
	
		    return "egovframework/com/cop/bbs/EgovArticleReply";
		}

		//인증된 권한 목록
		List<String> authList = EgovUserDetailsHelper.getAuthorities();
		//관리자 권한 체크
		if(!authList.contains("ROLE_ADMIN")){
			BoardVO vo = egovArticleService.selectArticleDetail(boardVO);
			if (vo == null || "Y".equals(vo.getSecretAt())) {
				
			    model.addAttribute("articleVO", boardVO);
			    model.addAttribute("boardMasterVO", master);

				model.addAttribute("resultMsg", "errors.auth.invalid");
				
				return "egovframework/com/cop/bbs/EgovArticleReply";
			}
		}
		
		// 2022.11.11 시큐어코딩 처리
	    final List<MultipartFile> files = multiRequest.getFiles("file_1");

	    board.setReplyAt("Y");
	    board.setFrstRegisterId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	    board.setBbsId(board.getBbsId());
	    board.setParnts(Long.toString(boardVO.getNttId()));
	    board.setSortOrdr(boardVO.getSortOrdr());
	    board.setReplyLc(Integer.toString(Integer.parseInt(boardVO.getReplyLc()) + 1));
	    
	    //익명등록 처리 
	    if(board.getAnonymousAt() != null && board.getAnonymousAt().equals("Y")){
	    	board.setNtcrId("anonymous"); //게시물 통계 집계를 위해 등록자 ID 저장
	    	board.setNtcrNm("익명"); //게시물 통계 집계를 위해 등록자 Name 저장
	    	board.setFrstRegisterId("anonymous");
	    	
	    } else {
	    	board.setNtcrId((user == null || user.getId() == null) ? "" : user.getId()); //게시물 통계 집계를 위해 등록자 ID 저장
	    	board.setNtcrNm((user == null || user.getName() == null) ? "" : user.getName()); //게시물 통계 집계를 위해 등록자 Name 저장
	    	
	    }
	    // CKEditor 리치텍스트 새니타이즈(RichTextSanitizer). unscript 대체 — 상세=[[RichTextSanitizer]]
	    board.setNttCn(RichTextSanitizer.clean(board.getNttCn(), multiRequest));
	    // 제목(평문) HTMLTagFilter 엔티티 복원 — 출력단 c:out 이스케이프로 XSS-safe.
	    board.setNttSj(decodeFilteredPlainText(board.getNttSj()));

    egovArticleService.insertArticleAndFiles(board, files);

		// 사용자 동선은 forward 로 돌아가면 SiteMesh 가 원 요청 기준으로 관리 셸을 씌우고
		// 관리 목록 핸들러가 쓰기 버튼을 그대로 노출한다 → PRG 로 사용자 목록에 되돌린다.
		if (isUserMode(multiRequest)) {
		    return "redirect:" + USER_URL_BASE + "/selectArticleList.do?bbsId=" + board.getBbsId();
		}
		return "forward:/cop/bbs/selectArticleList.do";
    }

    /**
     * 게시물 수정을 위한 수정페이지로 이동한다.
     * 
     * @param boardVO
     * @param vo
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/bbs/updateArticleView.do", "/cop/bbs/user/updateArticleView.do"})
    public String updateArticleView(HttpServletRequest request, @ModelAttribute("searchVO") BoardVO boardVO, @ModelAttribute("board") BoardVO vo, ModelMap model)
	    throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
	
		boardVO.setFrstRegisterId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		
		BoardMasterVO bmvo = new BoardMasterVO();
		BoardVO bdvo = new BoardVO();
		
		vo.setBbsId(boardVO.getBbsId());
		
		bmvo.setBbsId(boardVO.getBbsId());
		bmvo.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		if (isAuthenticated) {
		    bmvo = egovBBSMasterService.selectBBSMasterInf(bmvo);
		    // 관리자는 삭제(USE_AT='N')글도 수정폼에 열 수 있어야 복구가 가능하다.
		    boardVO.setIncludeDeleted(isAdminUser() ? "Y" : "N");
		    bdvo = egovArticleService.selectArticleDetail(boardVO);
		}

		// 부재 게시물(또는 비관리자의 삭제글) — 편집 동선은 목록으로.
		if (bdvo == null) {
		    model.addAttribute("bbsId", boardVO.getBbsId());
		    return "redirect:" + urlBase(request) + "/selectArticleList.do";
		}
		model.addAttribute("isAdmin", isAdminUser());	// 수정폼 복구버튼 게이팅용

		//----------------------------
		// 기본 BBS template 지정
		//----------------------------
		if (bmvo.getTmplatCours() == null || bmvo.getTmplatCours().equals("")) {
		    bmvo.setTmplatCours("/css/egovframework/com/cop/tpl/egovBaseTemplate.css");
		}
	
		// 수정폼도 본인 글에만 연다 — 저장(updateArticle)에만 본인확인을 두면 남의 글 내용이 폼에 실려 나간다.
		assertOwnerInUserMode(request, bdvo);

		//익명 등록글인 경우 수정 불가
		if(bdvo.getNtcrId().equals("anonymous")){
			model.addAttribute("result", bdvo);
			model.addAttribute("boardMasterVO", bmvo);
			addExtraFieldCodeOptions(bmvo, model);
			applyUserMode(request, model);
			return getArticleDetailViewName(bmvo);
		}
		
		model.addAttribute("articleVO", bdvo);
		model.addAttribute("boardMasterVO", bmvo);
		addExtraFieldCodeOptions(bmvo, model);
		applyUserMode(request, model);

		return "egovframework/com/cop/bbs/EgovArticleUpdt";
    }

    /**
     * 게시물에 대한 내용을 수정한다.
     * 
     * @param boardVO
     * @param board
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/bbs/updateArticle.do", "/cop/bbs/user/updateArticle.do"})
    public String updateBoardArticle(final MultipartHttpServletRequest multiRequest, @ModelAttribute("searchVO") BoardVO boardVO,
	    @ModelAttribute("bdMstr") BoardMaster bdMstr, @ModelAttribute("board") Board board, BindingResult bindingResult, ModelMap model) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		if(!isAuthenticated) {	//KISA 보안취약점 조치 (2018-12-10, 이정은)
            return "redirect:/uat/uia/egovLoginUsr.do";
        }
		
		//--------------------------------------------------------------------------------------------
    	// @ XSS 대응 권한체크 체크  START
    	// param1 : 사용자고유ID(uniqId,esntlId)
    	//--------------------------------------------------------
    	LOGGER.debug("@ XSS 권한체크 START ----------------------------------------------");
    	//step1 DB에서 해당 게시물의 uniqId 조회
    	// 관리자는 삭제글 수정도 저장할 수 있어야 하므로 삭제글 포함 조회.
    	boardVO.setIncludeDeleted(isAdminUser() ? "Y" : "N");
    	BoardVO vo = egovArticleService.selectArticleDetail(boardVO);

    	// 부재 게시물(또는 비관리자의 삭제글) — 편집 동선은 목록으로.
    	if (vo == null) {
    	    model.addAttribute("bbsId", boardVO.getBbsId());
    	    return "redirect:" + urlBase(multiRequest) + "/selectArticleList.do";
    	}

    	//step2 EgovXssChecker 공통모듈을 이용한 권한체크
    	assertOwnerInUserMode(multiRequest, vo);
    	EgovXssChecker.checkerUserXss(multiRequest, vo.getFrstRegisterId());
      	LOGGER.debug("@ XSS 권한체크 END ------------------------------------------------");
    	//--------------------------------------------------------
    	// @ XSS 대응 권한체크 체크 END
    	//--------------------------------------------------------------------------------------------
	
		// 폼 왕복 atchFileId(프래그먼트 히든 암호문 → EgovAtchFileIdPropertyEditor 가 바인딩 시 복호) 대신
		// 소유권 검사용 재조회값(vo)을 정본으로 쓴다 — 복호 실패 sentinel(FILE_ID_DECRIPT_EXCEPTION_01,
		// 27자 > CHAR(20)) 유입 등 왕복 의존을 제거.
		String atchFileId = vo.getAtchFileId() == null ? "" : vo.getAtchFileId();

		beanValidator.validate(board, bindingResult);
		if (bindingResult.hasErrors()) {
	
		    boardVO.setFrstRegisterId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		    
		    BoardMasterVO bmvo = new BoardMasterVO();
		    BoardVO bdvo = new BoardVO();
		    
		    bmvo.setBbsId(boardVO.getBbsId());
		    bmvo.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		    bmvo = egovBBSMasterService.selectBBSMasterInf(bmvo);
		    bdvo = egovArticleService.selectArticleDetail(boardVO);
	
		    model.addAttribute("articleVO", bdvo);
		    model.addAttribute("boardMasterVO", bmvo);
		    addExtraFieldCodeOptions(bmvo, model);
		    applyUserMode(multiRequest, model);
	
		    return "egovframework/com/cop/bbs/EgovArticleUpdt";
		}

	    board.setLastUpdusrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	    
	    board.setNtcrNm("");	// dummy 오류 수정 (익명이 아닌 경우 validator 처리를 위해 dummy로 지정됨)
	    board.setPassword("");	// dummy 오류 수정 (익명이 아닌 경우 validator 처리를 위해 dummy로 지정됨)

	    // CKEditor 리치텍스트 새니타이즈(RichTextSanitizer). unscript 대체 — 상세=[[RichTextSanitizer]]
	    board.setNttCn(RichTextSanitizer.clean(board.getNttCn(), multiRequest));
	    // 제목(평문) HTMLTagFilter 엔티티 복원 — 출력단 c:out 이스케이프로 XSS-safe.
	    board.setNttSj(decodeFilteredPlainText(board.getNttSj()));

	    // 2022.11.11 시큐어코딩 처리
    	final List<MultipartFile> files = multiRequest.getFiles("file_1");

    	// 체크박스 여분필드는 폼 바인딩 대상이 아니다 — 전부 해제하면 마커만 와서 값이 비워진다.
    	BoardExtraFieldSupport.applyMultiValueFields(multiRequest, board);

    	board.setAtchFileId(atchFileId);	// 폼에서 바인딩된 암호문을 DB 정본으로 덮는다
    	egovArticleService.updateArticleAndFiles(board, files, atchFileId);

		model.addAttribute("bbsId", boardVO.getBbsId());
		model.addAttribute("searchCnd", boardVO.getSearchCnd());
		model.addAttribute("searchWrd", boardVO.getSearchWrd());
		model.addAttribute("pageIndex", boardVO.getPageIndex());

		return "redirect:" + urlBase(multiRequest) + "/selectArticleList.do";
	}

    /**
     * 게시물에 대한 내용을 삭제한다.
     * 
     * @param boardVO
     * @param board
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/bbs/deleteArticle.do", "/cop/bbs/user/deleteArticle.do"})
    public String deleteBoardArticle(HttpServletRequest request, @ModelAttribute("searchVO") BoardVO boardVO, @ModelAttribute("board") Board board,
	    @ModelAttribute("bdMstr") BoardMaster bdMstr, ModelMap model) throws Exception {
	
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
	
		//--------------------------------------------------------------------------------------------
    	// @ XSS 대응 권한체크 체크  START
    	// param1 : 사용자고유ID(uniqId,esntlId)
    	//--------------------------------------------------------
    	LOGGER.debug("@ XSS 권한체크 START ----------------------------------------------");
    	//step1 DB에서 해당 게시물의 uniqId 조회
    	BoardVO vo = egovArticleService.selectArticleDetail(boardVO);

    	// 삭제(톰스톤)·부재 게시물 — 이미 삭제된 글의 재삭제 시도 차단, 목록으로.
    	if (vo == null) {
    	    model.addAttribute("bbsId", boardVO.getBbsId());
    	    return "redirect:" + urlBase(request) + "/selectArticleList.do";
    	}

    	//step2 EgovXssChecker 공통모듈을 이용한 권한체크
    	assertOwnerInUserMode(request, vo);
    	EgovXssChecker.checkerUserXss(request, vo.getFrstRegisterId());
      	LOGGER.debug("@ XSS 권한체크 END ------------------------------------------------");
    	//--------------------------------------------------------
    	// @ XSS 대응 권한체크 체크 END
    	//--------------------------------------------------------------------------------------------
		
		BoardVO bdvo = egovArticleService.selectArticleDetail(boardVO);
		//익명 등록글인 경우 수정 불가
		if(bdvo.getNtcrId().equals("anonymous")){
			model.addAttribute("result", bdvo);
			model.addAttribute("boardMasterVO", bdMstr);
			return getArticleDetailViewName(bdMstr);
		}
		
		if (isAuthenticated) {
		    board.setLastUpdusrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());

		    egovArticleService.deleteArticle(board);
		}

		model.addAttribute("bbsId", boardVO.getBbsId());
		model.addAttribute("searchCnd", boardVO.getSearchCnd());
		model.addAttribute("searchWrd", boardVO.getSearchWrd());
		model.addAttribute("pageIndex", boardVO.getPageIndex());
		return "redirect:" + urlBase(request) + "/selectArticleList.do";
    }

    /**
     * 소프트삭제(USE_AT='N')된 게시물을 복구한다. 관리자 전용(사용자 URL 별칭 없음).
     *
     * @param boardVO
     * @param board
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/restoreArticle.do")
    public String restoreArticle(@ModelAttribute("searchVO") BoardVO boardVO, @ModelAttribute("board") Board board,
	    HttpServletRequest request, ModelMap model) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();

		if (!EgovUserDetailsHelper.isAuthenticated()) {
		    return "redirect:/uat/uia/egovLoginUsr.do";
		}
		// 복구는 관리자만.
		if (!isAdminUser()) {
		    throw new AccessDeniedException("삭제된 게시물 복구 권한이 없습니다.");
		}

		board.setLastUpdusrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		egovArticleService.restoreArticle(board);

		model.addAttribute("bbsId", boardVO.getBbsId());
		model.addAttribute("searchCnd", boardVO.getSearchCnd());
		model.addAttribute("searchWrd", boardVO.getSearchWrd());
		model.addAttribute("pageIndex", boardVO.getPageIndex());
		return "redirect:" + urlBase(request) + "/selectArticleList.do";
    }

    /**
     * 방명록에 대한 목록을 조회한다.
     * 
     * @param boardVO
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/selectGuestArticleList.do")
    public String selectGuestArticleList(@ModelAttribute("searchVO") BoardVO boardVO, ModelMap model) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		if(!isAuthenticated) {	//KISA 보안취약점 조치 (2018-12-10, 이정은)
            return "redirect:/uat/uia/egovLoginUsr.do";
        }
		
		// 수정 및 삭제 기능 제어를 위한 처리
		model.addAttribute("sessionUniqId", (user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		
		BoardVO vo = new BoardVO();
	
		vo.setBbsId(boardVO.getBbsId());
		vo.setBbsNm(boardVO.getBbsNm());
		vo.setNtcrNm((user == null || user.getName() == null) ? "" : user.getName());
		vo.setNtcrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		BoardMasterVO masterVo = new BoardMasterVO();
		
		masterVo.setBbsId(vo.getBbsId());
		masterVo.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		
		BoardMasterVO mstrVO = egovBBSMasterService.selectBBSMasterInf(masterVo);
	
		vo.setPageIndex(boardVO.getPageIndex());
		vo.setPageUnit(propertyService.getInt("pageUnit"));
		vo.setPageSize(propertyService.getInt("pageSize"));
	
		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(vo.getPageIndex());
		paginationInfo.setRecordCountPerPage(vo.getPageUnit());
		paginationInfo.setPageSize(vo.getPageSize());
	
		vo.setFirstIndex(paginationInfo.getFirstRecordIndex());
		vo.setLastIndex(paginationInfo.getLastRecordIndex());
		vo.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());
	
		Map<String, Object> map = egovArticleService.selectGuestArticleList(vo);
		int totCnt = Integer.parseInt((String)map.get("resultCnt"));
		
		paginationInfo.setTotalRecordCount(totCnt);
	
		model.addAttribute("user", user);
		model.addAttribute("resultList", map.get("resultList"));
		model.addAttribute("resultCnt", map.get("resultCnt"));
		model.addAttribute("boardMasterVO", mstrVO);
		model.addAttribute("articleVO", vo);
		model.addAttribute("paginationInfo", paginationInfo);
	
		return "egovframework/com/cop/bbs/EgovGuestArticleList";
    }
    
	
    /**
     * 방명록에 대한 내용을 등록한다.
     * 
     * @param boardVO
     * @param board
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/insertGuestArticle.do")
    public String insertGuestList(@ModelAttribute("searchVO") BoardVO boardVO, @ModelAttribute("Board") Board board, BindingResult bindingResult,
	    ModelMap model) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
	
		if(!isAuthenticated) {	//KISA 보안취약점 조치 (2018-12-10, 이정은)
            return "redirect:/uat/uia/egovLoginUsr.do";
        }
		
		beanValidator.validate(board, bindingResult);
		if (bindingResult.hasErrors()) {
	
		    BoardVO vo = new BoardVO();
	
		    vo.setBbsId(boardVO.getBbsId());
		    vo.setBbsNm(boardVO.getBbsNm());
		    vo.setNtcrNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));
		    vo.setNtcrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		    BoardMasterVO masterVo = new BoardMasterVO();
		    
		    masterVo.setBbsId(vo.getBbsId());
		    masterVo.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		    
		    BoardMasterVO mstrVO = egovBBSMasterService.selectBBSMasterInf(masterVo);
	
		    vo.setPageUnit(propertyService.getInt("pageUnit"));
		    vo.setPageSize(propertyService.getInt("pageSize"));
	
		    PaginationInfo paginationInfo = new PaginationInfo();
		    paginationInfo.setCurrentPageNo(vo.getPageIndex());
		    paginationInfo.setRecordCountPerPage(vo.getPageUnit());
		    paginationInfo.setPageSize(vo.getPageSize());
	
		    vo.setFirstIndex(paginationInfo.getFirstRecordIndex());
		    vo.setLastIndex(paginationInfo.getLastRecordIndex());
		    vo.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());
	
		    Map<String, Object> map = egovArticleService.selectGuestArticleList(vo);
		    int totCnt = Integer.parseInt((String)map.get("resultCnt"));
		    
		    paginationInfo.setTotalRecordCount(totCnt);
	
		    model.addAttribute("resultList", map.get("resultList"));
		    model.addAttribute("resultCnt", map.get("resultCnt"));
		    model.addAttribute("boardMasterVO", mstrVO);
		    model.addAttribute("articleVO", vo);	    
		    model.addAttribute("paginationInfo", paginationInfo);
	
		    return "egovframework/com/cop/bbs/EgovGuestArticleList";
	
		}
	
		// 2022.11.11 시큐어코딩 처리
	    board.setFrstRegisterId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	    
    egovArticleService.insertArticleAndFiles(board, null);

	    boardVO.setNttCn("");
	    boardVO.setPassword("");
	    boardVO.setNtcrId("");
	    boardVO.setNttId(0);

		return "forward:/cop/bbs/selectGuestArticleList.do";
    }
    
    /**
     * 방명록에 대한 내용을 삭제한다.
     * 
     * @param boardVO
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/deleteGuestArticle.do")
    public String deleteGuestList(@ModelAttribute("searchVO") BoardVO boardVO, @ModelAttribute("articleVO") Board board, ModelMap model) throws Exception {
		@SuppressWarnings("unused")
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		if (isAuthenticated) {
		    egovArticleService.deleteArticle(boardVO);
		}
		
		return "forward:/cop/bbs/selectGuestArticleList.do";
    }
    
    /**
     * 방명록 수정을 위한 특정 내용을 조회한다.
     * 
     * @param boardVO
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/updateGuestArticleView.do")
    public String updateGuestArticleView(@ModelAttribute("searchVO") BoardVO boardVO, @ModelAttribute("boardMasterVO") BoardMasterVO brdMstrVO,
	    ModelMap model) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		if(!isAuthenticated) {	//KISA 보안취약점 조치 (2018-12-10, 이정은)
            return "redirect:/uat/uia/egovLoginUsr.do";
        }
	
		// 수정 및 삭제 기능 제어를 위한 처리
		model.addAttribute("sessionUniqId", (user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		
		BoardVO vo = egovArticleService.selectArticleDetail(boardVO);
	
		boardVO.setBbsId(boardVO.getBbsId());
		boardVO.setBbsNm(boardVO.getBbsNm());
		boardVO.setNtcrNm((user == null || user.getName() == null) ? "" : user.getName());
	
		boardVO.setPageUnit(propertyService.getInt("pageUnit"));
		boardVO.setPageSize(propertyService.getInt("pageSize"));
	
		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(boardVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(boardVO.getPageUnit());
		paginationInfo.setPageSize(boardVO.getPageSize());
	
		boardVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		boardVO.setLastIndex(paginationInfo.getLastRecordIndex());
		boardVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());
	
		Map<String, Object> map = egovArticleService.selectGuestArticleList(boardVO);
		int totCnt = Integer.parseInt((String)map.get("resultCnt"));
		
		paginationInfo.setTotalRecordCount(totCnt);
	
		model.addAttribute("resultList", map.get("resultList"));
		model.addAttribute("resultCnt", map.get("resultCnt"));
		model.addAttribute("articleVO", vo);
		model.addAttribute("paginationInfo", paginationInfo);
	
		return "egovframework/com/cop/bbs/EgovGuestArticleList";
    }
    
    /**
     * 방명록을 수정하고 게시판 메인페이지를 조회한다.
     * 
     * @param boardVO
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/updateGuestArticle.do")
    public String updateGuestArticle(@ModelAttribute("searchVO") BoardVO boardVO, @ModelAttribute Board board, BindingResult bindingResult,
	    ModelMap model) throws Exception {

		//BBST02, BBST04
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		if(!isAuthenticated) {	//KISA 보안취약점 조치 (2018-12-10, 이정은)
            return "redirect:/uat/uia/egovLoginUsr.do";
        }
	
		beanValidator.validate(board, bindingResult);
		if (bindingResult.hasErrors()) {
	
		    BoardVO vo = new BoardVO();
	
		    vo.setBbsId(boardVO.getBbsId());
		    vo.setBbsNm(boardVO.getBbsNm());
		    vo.setNtcrNm((user == null || user.getName() == null) ? "" : user.getName());
		    vo.setNtcrId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
	
		    BoardMasterVO masterVo = new BoardMasterVO();
		    
		    masterVo.setBbsId(vo.getBbsId());
		    masterVo.setUniqId((user == null || user.getUniqId() == null) ? "" : user.getUniqId());
		    
		    BoardMasterVO mstrVO = egovBBSMasterService.selectBBSMasterInf(masterVo);
	
		    vo.setPageUnit(propertyService.getInt("pageUnit"));
		    vo.setPageSize(propertyService.getInt("pageSize"));
	
		    PaginationInfo paginationInfo = new PaginationInfo();
		    paginationInfo.setCurrentPageNo(vo.getPageIndex());
		    paginationInfo.setRecordCountPerPage(vo.getPageUnit());
		    paginationInfo.setPageSize(vo.getPageSize());
	
		    vo.setFirstIndex(paginationInfo.getFirstRecordIndex());
		    vo.setLastIndex(paginationInfo.getLastRecordIndex());
		    vo.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());
	
		    Map<String, Object> map = egovArticleService.selectGuestArticleList(vo);
		    int totCnt = Integer.parseInt((String)map.get("resultCnt"));
	
		    paginationInfo.setTotalRecordCount(totCnt);
		    
		    model.addAttribute("resultList", map.get("resultList"));
		    model.addAttribute("resultCnt", map.get("resultCnt"));
		    model.addAttribute("boardMasterVO", mstrVO);
		    model.addAttribute("articleVO", vo);
		    model.addAttribute("paginationInfo", paginationInfo);
	
		    return "egovframework/com/cop/bbs/EgovGuestArticleList";
		}
	
		// 2022.11.11 시큐어코딩 처리
	    egovArticleService.updateArticle(board);
	    boardVO.setNttCn("");
	    boardVO.setPassword("");
	    boardVO.setNtcrId("");
	    boardVO.setNttId(0);

		return "forward:/cop/bbs/selectGuestArticleList.do";
    }
    
    /**
     * 템플릿에 대한 미리보기용 게시물 목록을 조회한다.
     * 
     * @param boardVO
     * @param sessionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/previewBoardList.do")
    public String previewBoardArticles(@ModelAttribute("searchVO") BoardVO boardVO, ModelMap model) throws Exception {
		//LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	
		String template = boardVO.getSearchWrd();	// 템플릿 URL
		
		BoardMasterVO master = new BoardMasterVO();
		
		master.setBbsNm("미리보기 게시판");
	
		boardVO.setPageUnit(propertyService.getInt("pageUnit"));
		boardVO.setPageSize(propertyService.getInt("pageSize"));
	
		PaginationInfo paginationInfo = new PaginationInfo();
		
		paginationInfo.setCurrentPageNo(boardVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(boardVO.getPageUnit());
		paginationInfo.setPageSize(boardVO.getPageSize());
	
		boardVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		boardVO.setLastIndex(paginationInfo.getLastRecordIndex());
		boardVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());
		
		BoardVO target = null;
		List<BoardVO> list = new ArrayList<BoardVO>();
		
		target = new BoardVO();
		target.setNttSj("게시판 기능 설명");
		target.setFrstRegisterId("ID");
		target.setFrstRegisterNm("관리자");
		target.setFrstRegisterPnttm("2019-01-01");
		target.setInqireCo(7);
		target.setParnts("0");
		target.setReplyAt("N");
		target.setReplyLc("0");
		target.setUseAt("Y");
		
		list.add(target);
		
		target = new BoardVO();
		target.setNttSj("게시판 부가 기능 설명");
		target.setFrstRegisterId("ID");
		target.setFrstRegisterNm("관리자");
		target.setFrstRegisterPnttm("2019-01-01");
		target.setInqireCo(7);
		target.setParnts("0");
		target.setReplyAt("N");
		target.setReplyLc("0");
		target.setUseAt("Y");
		
		list.add(target);
		
		boardVO.setSearchWrd("");
	
		int totCnt = list.size();
		
		//공지사항 추출
		List<BoardVO> noticeList = egovArticleService.selectNoticeArticleList(boardVO);
	
		paginationInfo.setTotalRecordCount(totCnt);
	
		master.setTmplatCours(template);
		
		model.addAttribute("resultList", list);
		model.addAttribute("resultCnt", Integer.toString(totCnt));
		model.addAttribute("articleVO", boardVO);
		model.addAttribute("boardMasterVO", master);
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("noticeList", noticeList);
		
		model.addAttribute("preview", "true");
	
		return getArticleListViewName(master);
    }

	private void addExtraFieldCodeOptions(BoardMaster master, ModelMap model) throws Exception {
		Map<Integer, List<CmmnDetailCode>> options = new LinkedHashMap<Integer, List<CmmnDetailCode>>();
		if (master != null) {
			for (int i = 1; i <= 10; i++) {
				String fieldType = master.getBbsExtraFieldType(i);
				String codeId = master.getBbsExtraFieldCodeId(i);
				if (("radio".equals(fieldType) || "select".equals(fieldType) || "checkbox".equals(fieldType)) && codeId != null && !"".equals(codeId.trim())) {
					ComDefaultCodeVO codeVO = new ComDefaultCodeVO();
					codeVO.setCodeId(codeId.trim());
					options.put(Integer.valueOf(i), cmmUseService.selectCmmCodeDetail(codeVO));
				}
			}
		}
		model.addAttribute("bbsExtraCodeOptions", options);
	}
        
    /** 게시판 스킨(BBS_SKIN_CODE)별 목록 화면. 사용자 게시판(EgovBoardUserController)도 같은 분기를 탄다. */
    // ── 사용자 동선(/cop/bbs/user/*) 지원 ─────────────────────────────
    //   쓰기 핸들러는 관리 URL 과 사용자 URL 에 이중 매핑된다. 게시판별 작성권한은
    //   BoardReadInterceptor 가 먼저 확인하므로, 여기 도달했다면 쓰기는 허용된 것이다.
    //   남은 일은 (a) 복귀 URL 을 사용자 경로로 돌리고 (b) 수정·삭제의 본인확인을 거는 것.

    private static final String USER_URL_BASE = "/cop/bbs/user";
    private static final String ADMIN_URL_BASE = "/cop/bbs";

    static boolean isUserMode(HttpServletRequest request) {
	String uri = (String) request.getAttribute("javax.servlet.include.request_uri");
	if (uri == null) {
	    uri = request.getRequestURI();
	}
	return uri != null && uri.contains("/cop/bbs/user/");
    }

    private String urlBase(HttpServletRequest request) {
	return isUserMode(request) ? USER_URL_BASE : ADMIN_URL_BASE;
    }

    /** 공유 JSP 가 사용자 레이아웃·링크·버튼 상태를 결정하는 플래그. */
    private void applyUserMode(HttpServletRequest request, ModelMap model) {
	if (!isUserMode(request)) {
	    return;
	}
	model.addAttribute("bbsUserMode", "Y");
	model.addAttribute("bbsUrlBase", USER_URL_BASE);
	model.addAttribute("cmtUrlBase", "/cop/cmt/user");
	// 인터셉터의 작성권한 검사를 통과했으므로 이 화면에서는 쓰기 버튼을 보여도 된다.
	model.addAttribute("bbsCanWrite", Boolean.TRUE);
	model.addAttribute("sessionUniqId", currentUniqId());
    }

    /** 사용자 동선에서는 본인 글만 수정·삭제한다(관리자 우회 없음 — 관리 화면을 쓰면 된다). */
    private void assertOwnerInUserMode(HttpServletRequest request, BoardVO article) {
	if (!isUserMode(request)) {
	    return;
	}
	String uniqId = currentUniqId();
	if (article == null || uniqId.isEmpty() || !uniqId.equals(article.getFrstRegisterId())) {
	    throw new AccessDeniedException("본인이 작성한 글만 수정하거나 삭제할 수 있습니다.");
	}
    }

    /** 로그인 사용자 고유ID(ESNTL_ID). 미인증/실패 시 "". */
    private String currentUniqId() {
	Object au = EgovUserDetailsHelper.getAuthenticatedUser();
	if (au instanceof LoginVO) {
	    String id = ((LoginVO) au).getUniqId();
	    return id == null ? "" : id;
	}
	return "";
    }

    /** 게시판이 사용할 알려진 렌더 엔진코드. 템플릿(COMTNTMPLATINFO.TMPLAT_SE_CODE)의 정본 어휘. */
    private static final java.util.Set<String> KNOWN_ENGINES =
        new java.util.HashSet<>(java.util.Arrays.asList("LIST", "GALLERY", "FAQ", "QNA", "GUEST", "MAGAZINE", "CALENDAR", "TIMELINE", "HISTORY", "NOTICEHL", "TAB", "ARCHIVE"));

    /** 전건 조회 엔진 — 캘린더(월 그리드)·연혁(단일 스크롤)형은 페이지 슬라이스 대신 전 글을 싣는다.
     *  탭분류(TAB)·자료실(ARCHIVE)은 여분필드1 분류 필터(searchCategory)+게시기간 게이팅을 서버에서 걸어 일반 페이징한다. */
    private static final java.util.Set<String> FULL_FETCH_ENGINES =
        new java.util.HashSet<>(java.util.Arrays.asList("CALENDAR", "HISTORY"));

    /** 전건 조회 상한. */
    static final int FETCH_ALL_LIMIT = 10000;

    /** 이 게시판의 렌더엔진이 전건 조회 대상인가(해당 JSP 는 페이저 미표시). */
    static boolean needsFullFetch(BoardMaster master) {
    	return FULL_FETCH_ENGINES.contains(resolveEngine(master));
    }

    /**
     * HTMLTagFilter 가 입력 시점에 엔티티로 치환한 평문 필드(제목 등)를 원문으로 복원한다.
     *
     * <p>{@code /cop/bbs/*} 는 필터 우회 대상이 아니라 요청 파라미터의 {@code < > " ' ( )} 가
     * {@code &lt; &#40;} 등으로 치환돼 들어온다. 본문(nttCn)은 {@link RichTextSanitizer} 가 복원하지만
     * 제목(nttSj)은 복원되지 않아 {@code &#40;} 가 그대로 저장되고, 목록·상세가 c:out(escapeXml=기본)
     * 으로 다시 이스케이프해 화면에 리터럴 {@code &#40;} 가 노출됐다(이중 이스케이프).</p>
     *
     * <p>제목은 모든 목록·상세에서 출력-이스케이프되므로 원문 저장이 XSS-safe 다. (raw 출력
     * escapeXml="false" 필드는 nttCn·bbsIntrcn 뿐이며 이들은 여기서 복원하지 않는다.)</p>
     */
    static String decodeFilteredPlainText(String v) {
    	if (v == null) {
    		return null;
    	}
    	// HtmlUtils.htmlUnescape 는 HTML4 엔티티만 안다 — HTMLTagFilter 가 ' 를 넣는 &apos;(HTML5/XML)
    	// 는 못 되돌린다. 먼저 되돌린 뒤 나머지(&lt; &gt; &quot; &#40; &#41;)를 표준 언이스케이프.
    	return HtmlUtils.htmlUnescape(v.replace("&apos;", "'"));
    }

    /** LIST_PAGE_UNIT 쉼표목록 → 양의 정수 옵션(순서유지·중복제거). 빈 목록이면 전역 기본값 사용 신호. */
    static List<Integer> parsePageUnitOptions(String csv) {
    	List<Integer> out = new ArrayList<Integer>();
    	if (csv == null) {
    		return out;
    	}
    	for (String tok : csv.split(",")) {
    		String t = tok.trim();
    		if (t.isEmpty()) {
    			continue;
    		}
    		try {
    			int v = Integer.parseInt(t);
    			if (v > 0 && !out.contains(Integer.valueOf(v))) {
    				out.add(Integer.valueOf(v));
    			}
    		} catch (NumberFormatException ignore) {
    			// 숫자 아닌 토큰은 무시
    		}
    	}
    	return out;
    }

    /** 옵션·요청값·전역기본으로 실제 페이지당 건수 결정. 빈옵션=전역, 단일=고정, 복수=요청값(옵션내)·아니면 첫옵션. */
    static int resolvePageUnit(List<Integer> options, int requested, int globalDefault) {
    	if (options.isEmpty()) {
    		return globalDefault;
    	}
    	if (options.size() == 1) {
    		return options.get(0);
    	}
    	return options.contains(Integer.valueOf(requested)) ? requested : options.get(0);
    }

    /**
     * 게시판이 사용할 렌더 엔진코드를 정한다 — 템플릿이 표현형태의 단일 정본 축이다.
     *
     * <p>해석 우선순위:
     * <ol>
     *   <li><b>템플릿</b>(정본) — COMTNTMPLATINFO.TMPLAT_SE_CODE. 게시판이 템플릿을 배정했으면 그 엔진코드.</li>
     *   <li><b>스킨</b>(과도기) — BBS_SKIN_CODE 가 엔진 어휘와 동일(GALLERY/FAQ/QNA/MAGAZINE/GUEST/LIST)이면 그대로.
     *       템플릿 미배정 기존 게시판이 마이그레이션(PHASE 4) 전까지 계속 동작하도록.</li>
     *   <li><b>유형</b>(레거시) — 방명록 유형(BBST03)은 GUEST.</li>
     *   <li>그 외 — LIST(기본).</li>
     * </ol>
     * TMPLAT_ID 가 비었으면 LEFT OUTER 조인이 걸리지 않아 tmplatSeCode 는 NULL 이므로 자연히 하위 규칙으로 내려간다.
     */
    static String resolveEngine(BoardMaster master) {
    	if (master == null) {
    		return "LIST";
    	}
    	// 1) 템플릿 = 정본 (BoardMasterVO 만 조인된 엔진코드를 싣는다)
    	if (master instanceof BoardMasterVO) {
    		String engine = normEngine(((BoardMasterVO) master).getTmplatSeCode());
    		if (KNOWN_ENGINES.contains(engine)) {
    			return engine;
    		}
    	}
    	// 2) 스킨 = 과도기 fallback (BASIC/공백/미지값은 통과 → LIST)
    	String skin = normEngine(master.getBbsSkinCode());
    	if (KNOWN_ENGINES.contains(skin)) {
    		return skin;
    	}
    	// 3) 유형 = 레거시 방명록
    	if ("BBST03".equals(master.getBbsTyCode())) {
    		return "GUEST";
    	}
    	return "LIST";
    }

    private static String normEngine(String code) {
    	return code == null ? "" : code.trim().toUpperCase();
    }

    /** 목록 뷰 — 게시판의 렌더 엔진코드(resolveEngine)로 목록 JSP 를 정한다. */
    static String getArticleListViewName(BoardMaster master) {
    	switch (resolveEngine(master)) {
    		case "GALLERY":  return "egovframework/com/cop/bbs/EgovArticleGalleryList";
    		case "CALENDAR": return "egovframework/com/cop/bbs/EgovArticleCalendarList";
    		case "TIMELINE": return "egovframework/com/cop/bbs/EgovArticleTimelineList";
    		case "HISTORY":  return "egovframework/com/cop/bbs/EgovArticleHistoryList";
    		case "NOTICEHL": return "egovframework/com/cop/bbs/EgovArticleNoticeHlList";
    		case "TAB":      return "egovframework/com/cop/bbs/EgovArticleTabList";
    		case "ARCHIVE":  return "egovframework/com/cop/bbs/EgovArticleArchiveList";
    		case "FAQ":      return "egovframework/com/cop/bbs/EgovArticleFaqList";
    		case "QNA":      return "egovframework/com/cop/bbs/EgovArticleQnaList";
    		case "MAGAZINE": return "egovframework/com/cop/bbs/EgovArticleMagazineList";
    		// GUEST 는 실제 진입 시 방명록 서브앱으로 forward 되므로 이 뷰는 직접 렌더되지 않는다(안전판).
    		case "GUEST":    return "egovframework/com/cop/bbs/EgovGuestArticleList";
    		default:         return "egovframework/com/cop/bbs/EgovArticleList";
    	}
    }

    /**
     * 상세 뷰 — 엔진코드로 상세 JSP 를 정한다. 웹진/앨범(MAGAZINE)형만 전용 상세를 갖고,
     * 나머지(LIST/GALLERY/FAQ/QNA)는 공통 상세(EgovArticleDetail)를 공유한다.
     * (방명록 GUEST 는 인라인형이라 상세 페이지가 없다 — 목록에서 forward 로 처리.)
     */
    static String getArticleDetailViewName(BoardMaster master) {
    	String engine = resolveEngine(master);
    	if ("MAGAZINE".equals(engine)) {
    		return "egovframework/com/cop/bbs/EgovArticleMagazineDetail";
    	}
    	if ("GALLERY".equals(engine)) {
    		return "egovframework/com/cop/bbs/EgovArticleGalleryDetail";
    	}
    	if ("ARCHIVE".equals(engine)) {
    		return "egovframework/com/cop/bbs/EgovArticleArchiveDetail";
    	}
    	return "egovframework/com/cop/bbs/EgovArticleDetail";
    }

    /**
     * 갤러리형 상세 — 첨부 이미지(GIF/JPG/PNG/BMP) 목록을 galleryImages 로 싣는다.
     * 갤러리 엔진이 아니거나 첨부가 없으면 아무 것도 하지 않는다(다른 엔진 상세엔 무영향).
     * JSP 는 이 목록의 fileSn 으로 getImage.do 를 호출해 각 이미지를 렌더한다(다중이면 슬라이드).
     */
    static void addGalleryImages(EgovFileMngService fileService, BoardMaster master, BoardVO article, ModelMap model) throws Exception {
    	String engine = resolveEngine(master);
    	// 갤러리형(첨부 이미지 갤러리·슬라이드) + 웹진/앨범형(사진 앨범) 상세가 첨부 이미지 전체를 쓴다.
    	if (article == null || !("GALLERY".equals(engine) || "MAGAZINE".equals(engine))) {
    		return;
    	}
    	String atchFileId = article.getAtchFileId();
    	if (atchFileId == null || atchFileId.trim().isEmpty()) {
    		return;
    	}
    	FileVO fvo = new FileVO();
    	fvo.setAtchFileId(atchFileId.trim());
    	model.addAttribute("galleryImages", fileService.selectImageFileList(fvo));
    }

    /**
     * 웹진/앨범형 상세 — 이전(더 오래된)·다음(더 최신) 글을 네비 카드로 싣는다.
     * 웹진 엔진이 아니면 아무 것도 하지 않는다. 비밀글·삭제글은 쿼리에서 제외된다.
     */
    static void addMagazineNav(EgovArticleService articleService, BoardMaster master, String bbsId, long nttId, ModelMap model) {
    	if (!"MAGAZINE".equals(resolveEngine(master)) || bbsId == null || nttId <= 0) {
    		return;
    	}
    	BoardVO param = new BoardVO();
    	param.setBbsId(bbsId);
    	param.setNttId(nttId);
    	model.addAttribute("prevArticle", articleService.selectPrevArticle(param));
    	model.addAttribute("nextArticle", articleService.selectNextArticle(param));
    }

    /**
     * 자료실형 상세 — 첨부 전체 파일 목록(파일별 다운로드 수 포함)을 archiveFiles 로 싣는다.
     * 자료실 엔진이 아니거나 첨부가 없으면 아무 것도 하지 않는다(다른 엔진 상세엔 무영향).
     */
    static void addArchiveFiles(EgovFileMngService fileService, BoardMaster master, BoardVO article, ModelMap model) throws Exception {
    	if (article == null || !"ARCHIVE".equals(resolveEngine(master))) {
    		return;
    	}
    	String atchFileId = article.getAtchFileId();
    	if (atchFileId == null || atchFileId.trim().isEmpty()) {
    		return;
    	}
    	FileVO fvo = new FileVO();
    	fvo.setAtchFileId(atchFileId.trim());
    	model.addAttribute("archiveFiles", fileService.selectFileInfs(fvo));
    }
}
