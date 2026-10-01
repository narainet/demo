package egovframework.com.cop.bbs.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.fdl.security.intercept.EgovReloadableFilterInvocationSecurityMetadataSource;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springmodules.validation.commons.DefaultBeanValidator;

import egovframework.com.cmm.ComDefaultCodeVO;
import egovframework.com.cmm.EgovComponentChecker;
import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.annotation.IncludedInfo;
import egovframework.com.cmm.service.CmmnDetailCode;
import egovframework.com.cmm.service.EgovCmmUseService;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.cop.bbs.service.BoardMaster;
import egovframework.com.cop.bbs.service.BoardMasterVO;
import egovframework.com.cop.bbs.service.BoardMenuLinkService;
import egovframework.com.cop.bbs.service.BoardMenuVO;
import egovframework.com.cop.bbs.service.EgovBBSMasterService;
import egovframework.com.utl.fcc.service.EgovStringUtil;
import narainet.rlms.menu.MenuHelper;


/**
 * 게시판 속성관리를 위한 컨트롤러  클래스
 * @author 공통서비스개발팀 이삼섭
 * @since 2009.06.01
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *   
 *   수정일      수정자           수정내용
 *  -------       --------    ---------------------------
 *   2009.3.12   이삼섭      최초 생성
 *   2009.06.26	 한성곤		 2단계 기능 추가 (댓글관리, 만족도조사)
 *	 2011.07.21  안민정      커뮤니티 관련 메소드 분리 (->EgovBBSAttributeManageController)
 *	 2011.8.26	 정진오		 IncludedInfo annotation 추가
 *   2011.09.15  서준식      2단계 기능 추가 (댓글관리, 만족도조사) 적용방법 변경
 *   2016.06.13  김연호      표준프레임워크 v3.6 개선
 *   2022.11.11  김혜준      시큐어코딩 처리
 *   2024.10.29	inganyoyo	Controller는 Transaction 처리를 하지 않아 Controller에서 오류 발생 시 데이터 정합성 오류 문제 발생
 * </pre>
 */

@Controller
public class EgovBBSMasterController {

    private static final Logger LOGGER = LoggerFactory.getLogger(EgovBBSMasterController.class);

    @Resource(name = "EgovBBSMasterService")
    private EgovBBSMasterService egovBBSMasterService;

    @Resource(name = "EgovCmmUseService")
    private EgovCmmUseService cmmUseService;

    @Resource(name = "propertiesService")
    protected EgovPropertyService propertyService;
    
    @Resource(name = "egovBBSMstrIdGnrService")
    private EgovIdGnrService idgenServiceBbs;

    /** EgovMessageSource */
	@Resource(name = "egovMessageSource")
	EgovMessageSource egovMessageSource;

    /** 게시판 ↔ 사용자 메뉴 연결 */
    @Resource(name = "boardMenuLinkService")
    private BoardMenuLinkService boardMenuLinkService;

    /** URL 보안 메타데이터 재적용 — 첫 사용자 게시판이 생기면 L6 파생 패턴이 새로 나타난다. */
    @Autowired(required = false)
    private EgovReloadableFilterInvocationSecurityMetadataSource securityMetadataSource;

    /**
     * 게시판 메뉴에 부여할 수 있는 역할과 표시명.
     * 3-tier(+승인자, +송무담당자)로 고정된 프로젝트 역할 체계라 화면 표기는 여기서 관리한다.
     * ★역할을 새로 만들면 여기에도 추가해야 게시판 권한 체크박스에 나타난다
     *   (2026-07-31: 송무 모듈 도입 때 만든 ROLE_LAW_MGR 이 누락돼 있던 것 반영).
     * 순서 = context-security.xml 의 rlmsRoleHierarchy 와 같은 축으로 읽히게:
     *   조회자 &lt; 편집자 &lt; 승인자 (수직 3-tier), 송무담당자는 조회자만 상속하는 별도 가지.
     */
    private static final Map<String, String> MENU_ROLE_LABELS;
    static {
	Map<String, String> labels = new LinkedHashMap<String, String>();
	labels.put("ROLE_USER", "조회자");
	labels.put("ROLE_EDITOR", "편집자");
	labels.put("ROLE_APPROVER", "승인자");
	labels.put("ROLE_LAW_MGR", "송무담당자");
	labels.put("ROLE_ADMIN", "관리자");
	MENU_ROLE_LABELS = java.util.Collections.unmodifiableMap(labels);
    }

    /** 동시 생성으로 메뉴번호가 겹쳤을 때 관리자에게 보일 안내 — 롤백됐으니 재시도하면 된다. */
    private static final String MSG_MENU_NO_CONFLICT =
	    "다른 게시판이 동시에 등록되어 메뉴번호가 겹쳤습니다. 저장하신 내용 그대로 다시 저장해 주세요.";

    /**
     * DefaultBeanValidator 는 formset 을 모델 이름이 아니라 <b>대상 객체의 클래스 짧은이름</b>으로 찾는다
     * (Introspector.decapitalize(ClassUtils.getShortName(cls))). 못 찾으면 예외 없이 조용히 통과한다.
     * 따라서 validate() 에 넘기는 객체는 반드시 BoardMasterVO 여야
     * EgovBBSMasterRegist.xml 의 &lt;form name="boardMasterVO"&gt; 규칙이 적용된다.
     */
    @Autowired
    private DefaultBeanValidator beanValidator;

    //Logger log = Logger.getLogger(this.getClass());
    
    /**
     * 신규 게시판 마스터 등록을 위한 등록페이지로 이동한다.
     * 
     * @param boardMasterVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/insertBBSMasterView.do")
    public String insertBBSMasterView(@ModelAttribute("searchVO") BoardMasterVO boardMasterVO, ModelMap model) throws Exception {
		BoardMasterVO boardMaster = new BoardMasterVO();
		// 새 게시판은 만들자마자 조회자에게 보이는 것이 기본 기대치다.
		boardMaster.setMenuExposeAt("Y");
		boardMaster.setMenuAuthorCodes(new String[] { "ROLE_USER", "ROLE_EDITOR", "ROLE_APPROVER", "ROLE_LAW_MGR", "ROLE_ADMIN" });
		// 유형은 폼에서 폐기(표현형태는 템플릿이 결정) — 저장 컬럼(NOT NULL)만 통합유형으로 기본 세팅.
		boardMaster.setBbsTyCode("BBST01");
		// 첨부 1파일 최대 용량 기본 5MB(신규 게시판 폼 기본값).
		boardMaster.setAtchPosblFileSize("5");
		// 비밀글 허용 기본 N — 신규 게시판은 비밀글을 기본 비허용(정책상 명시적 결정, VO 초기값 관성 배제).
		boardMaster.setSecretPosblAt("N");

		//공통코드(게시판유형) — 유형은 폼에서 감췄으나 저장 컬럼(NOT NULL)은 유지되므로 코드는 계속 싣는다.
		ComDefaultCodeVO vo = new ComDefaultCodeVO();
		vo.setCodeId("COM101");
		List<CmmnDetailCode> codeResult = cmmUseService.selectCmmCodeDetail(vo);
		model.addAttribute("bbsTyCode", codeResult);
		model.addAttribute("templateList", egovBBSMasterService.selectTemplateList());	// 표현형태 = 템플릿(정본)
		model.addAttribute("boardMasterVO", boardMaster);
		addMenuRoleModel(model);


		//---------------------------------
		// 2011.09.15 : 2단계 기능 추가 반영 방법 변경
		//---------------------------------


		if(EgovComponentChecker.hasComponent("EgovArticleCommentService")){
			model.addAttribute("useComment", "true");
		}
		if(EgovComponentChecker.hasComponent("EgovBBSSatisfactionService")){
			model.addAttribute("useSatisfaction", "true");
		}

		return "egovframework/com/cop/bbs/EgovBBSMasterRegist";
    }

    /**
     * 신규 게시판 마스터 정보를 등록한다.
     * 
     * @param boardMasterVO
     * @param boardMaster
     * @param status
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/insertBBSMaster.do")
    public String insertBBSMaster(@ModelAttribute("searchVO") BoardMasterVO boardMasterVO, @ModelAttribute("boardMasterVO") BoardMasterVO boardMaster,
	    BindingResult bindingResult, ModelMap model) throws Exception {
    	
		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		
		beanValidator.validate(boardMaster, bindingResult);
		if (bindingResult.hasErrors()) {
		    return backToRegistForm(boardMaster, model);
		}

		if (isAuthenticated) {
		    boardMaster.setFrstRegisterId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
		    boardMaster.setBlogAt("N");
		    normalizeBoardPolicy(boardMaster);
		    try {
			egovBBSMasterService.insertBBSMasterInf(boardMaster);
		    } catch (IllegalArgumentException | IllegalStateException e) {
			// 메뉴 노출 설정이 잘못됐다 — 한 트랜잭션이라 게시판도 만들어지지 않았다.
			LOGGER.warn("게시판 생성 중 사용자 메뉴 연결 실패: {}", e.getMessage());
			model.addAttribute("menuLinkError", e.getMessage());
			return backToRegistForm(boardMaster, model);
		    } catch (DataIntegrityViolationException e) {
			// 메뉴번호는 MAX+10000 을 읽고 넣는 방식이라 동시 생성이 겹칠 수 있다.
			// ORA-00001 이 DuplicateKeyException 으로 번역되지 않는 경우까지 상위 타입으로 받는다.
			// 롤백됐으므로 그대로 다시 저장하면 다음 번호를 받는다.
			LOGGER.warn("게시판 생성 중 메뉴번호 충돌(동시 생성): {}", e.getMessage());
			model.addAttribute("menuLinkError", MSG_MENU_NO_CONFLICT);
			return backToRegistForm(boardMaster, model);
		    }
		    reloadMenuCache("insertBBSMaster");
		}
		return "forward:/cop/bbs/selectBBSMasterInfs.do";
    }

    /** 시스템 멀티파트 업로드 한도(bytes) — context-common.xml multipartResolver maxUploadSize 와 일치. */
    static final long SYSTEM_MAX_UPLOAD_BYTES = 50000000L;
    /** 게시판별 첨부 1파일 최대 용량 상한(MB) = 시스템 한도. */
    static final int MAX_FILE_MB = (int) (SYSTEM_MAX_UPLOAD_BYTES / (1024L * 1024L));

    /**
     * 저장 전 정규화.
     *  - 첨부파일가능여부(fileAtchPosblAt)는 폼에서 숨김 → 첨부 가능 파일 수가 0보다 크면 'Y', 아니면 'N'.
     *  - 첨부 1파일 최대 용량(atchPosblFileSize, 단위 MB)은 시스템 업로드 한도(MAX_FILE_MB) 이하로 상한. 숫자 아니면 비움.
     */
    private void normalizeBoardPolicy(BoardMaster boardMaster) {
    	boardMaster.setFileAtchPosblAt(boardMaster.getAtchPosblFileNumber() > 0 ? "Y" : "N");
    	String mb = boardMaster.getAtchPosblFileSize();
    	if (mb != null && !mb.trim().isEmpty()) {
    		try {
    			int v = Integer.parseInt(mb.trim());
    			if (v < 0) {
    				v = 0;
    			}
    			if (v > MAX_FILE_MB) {
    				v = MAX_FILE_MB;
    			}
    			boardMaster.setAtchPosblFileSize(String.valueOf(v));
    		} catch (NumberFormatException e) {
    			boardMaster.setAtchPosblFileSize("");
    		}
    	}
    }

    /** 등록폼 재표시 — 폼 객체(boardMasterVO)와 게시판유형 코드·노출 설정 모델을 다시 실어준다. */
    private String backToRegistForm(BoardMaster boardMaster, ModelMap model) throws Exception {
	ComDefaultCodeVO vo = new ComDefaultCodeVO();
	vo.setCodeId("COM101");
	model.addAttribute("bbsTyCode", cmmUseService.selectCmmCodeDetail(vo));
	model.addAttribute("templateList", egovBBSMasterService.selectTemplateList());
	addMenuRoleModel(model);
	if (EgovComponentChecker.hasComponent("EgovArticleCommentService")) {
	    model.addAttribute("useComment", "true");
	}
	if (EgovComponentChecker.hasComponent("EgovBBSSatisfactionService")) {
	    model.addAttribute("useSatisfaction", "true");
	}
	return "egovframework/com/cop/bbs/EgovBBSMasterRegist";
    }

    /**
     * 게시판 마스터 목록을 조회한다.
     * 
     * @param boardMasterVO
     * @param model
     * @return
     * @throws Exception
     */
    @IncludedInfo(name="게시판관리",order = 180 ,gid = 40)
    @RequestMapping("/cop/bbs/selectBBSMasterInfs.do")
    public String selectBBSMasterInfs(@ModelAttribute("searchVO") BoardMasterVO boardMasterVO, ModelMap model) throws Exception {
		boardMasterVO.setPageUnit(propertyService.getInt("pageUnit"));
		boardMasterVO.setPageSize(propertyService.getInt("pageSize"));
	
		PaginationInfo paginationInfo = new PaginationInfo();
		
		paginationInfo.setCurrentPageNo(boardMasterVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(boardMasterVO.getPageUnit());
		paginationInfo.setPageSize(boardMasterVO.getPageSize());
	
		boardMasterVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		boardMasterVO.setLastIndex(paginationInfo.getLastRecordIndex());
		boardMasterVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());
	
		Map<String, Object> map = egovBBSMasterService.selectBBSMasterInfs(boardMasterVO);
		int totCnt = Integer.parseInt((String)map.get("resultCnt"));
		
		paginationInfo.setTotalRecordCount(totCnt);
	
		model.addAttribute("resultList", map.get("resultList"));
		model.addAttribute("resultCnt", map.get("resultCnt"));
		model.addAttribute("paginationInfo", paginationInfo);
		// 게시판별 사용자 메뉴 노출 상태 — bbsId 를 눈으로 캐내던 마찰을 없앤다.
		model.addAttribute("boardMenuMap", boardMenuLinkService.selectLinkMap());

		return "egovframework/com/cop/bbs/EgovBBSMasterList";
    }
    
    /**
     * 게시판 마스터 상세내용을 조회한다.
     * 
     * @param boardMasterVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/selectBBSMasterDetail.do")
    public String selectBBSMasterDetail(@ModelAttribute("searchVO") BoardMasterVO searchVO, ModelMap model) throws Exception {
		BoardMasterVO vo = egovBBSMasterService.selectBBSMasterInf(searchVO);
		model.addAttribute("result", vo);
		model.addAttribute("boardMenu", boardMenuLinkService.selectLink(vo.getBbsId()));
		addMenuRoleModel(model);

		//---------------------------------
		// 2011.09.15 : 2단계 기능 추가 반영 방법 변경
		//---------------------------------

		if(EgovComponentChecker.hasComponent("EgovArticleCommentService")){
			model.addAttribute("useComment", "true");
		}
		if(EgovComponentChecker.hasComponent("EgovBBSSatisfactionService")){
			model.addAttribute("useSatisfaction", "true");
		}

		return "egovframework/com/cop/bbs/EgovBBSMasterDetail";
    }
    
    /**
     * 게시판 마스터정보를 수정하기 위한 전 처리
     * @param bbsId
     * @param searchVO
     * @param model
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/updateBBSMasterView.do")
    public String updateBBSMasterView(@RequestParam("bbsId") String bbsId ,
            @ModelAttribute("searchVO") BoardMaster searchVO, ModelMap model)
            throws Exception {


        BoardMasterVO boardMasterVO = new BoardMasterVO();

        
        //게시판유형코드
        ComDefaultCodeVO vo = new ComDefaultCodeVO();
        vo.setCodeId("COM101");
        List<CmmnDetailCode> codeResult = cmmUseService.selectCmmCodeDetail(vo);
        model.addAttribute("bbsTyCode", codeResult);
        model.addAttribute("templateList", egovBBSMasterService.selectTemplateList());

        // Primary Key 값 세팅
        boardMasterVO.setBbsId(bbsId);

        BoardMasterVO result = egovBBSMasterService.selectBBSMasterInf(boardMasterVO);
        applyMenuLink(result);
        model.addAttribute("boardMasterVO", result);
        addMenuRoleModel(model);

		//---------------------------------
		// 2011.09.15 : 2단계 기능 추가 반영 방법 변경
		//---------------------------------

		if(EgovComponentChecker.hasComponent("EgovArticleCommentService")){
			model.addAttribute("useComment", "true");
		}
		if(EgovComponentChecker.hasComponent("EgovBBSSatisfactionService")){
			model.addAttribute("useSatisfaction", "true");
		}

        return "egovframework/com/cop/bbs/EgovBBSMasterUpdt";
    }
    

    /**
     * 게시판 마스터 정보를 수정한다.
     * 
     * @param boardMasterVO
     * @param boardMaster
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/updateBBSMaster.do")
    public String updateBBSMaster(@ModelAttribute("searchVO") BoardMasterVO boardMasterVO, @ModelAttribute("boardMasterVO") BoardMasterVO boardMaster,
	    BindingResult bindingResult, ModelMap model) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
	
		beanValidator.validate(boardMaster, bindingResult);
		if (bindingResult.hasErrors()) {
		    return backToUpdtForm(boardMaster, model);
		}

		if (isAuthenticated) {
		    String uniqId = user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId());
		    boardMaster.setLastUpdusrId(uniqId);
		    boardMaster.setFrstRegisterId(uniqId);
		    normalizeBoardPolicy(boardMaster);
		    try {
			egovBBSMasterService.updateBBSMasterInf(boardMaster);
		    } catch (IllegalArgumentException | IllegalStateException e) {
			LOGGER.warn("게시판 수정 중 사용자 메뉴 연결 실패: {}", e.getMessage());
			model.addAttribute("menuLinkError", e.getMessage());
			return backToUpdtForm(boardMaster, model);
		    } catch (DataIntegrityViolationException e) {
			LOGGER.warn("게시판 수정 중 메뉴번호 충돌(동시 생성): {}", e.getMessage());
			model.addAttribute("menuLinkError", MSG_MENU_NO_CONFLICT);
			return backToUpdtForm(boardMaster, model);
		    }
		    reloadMenuCache("updateBBSMaster");
		}

		return "forward:/cop/bbs/selectBBSMasterInfs.do";
    }

    /** 수정폼 재표시 — 사용자가 방금 입력한 값을 그대로 되돌려 준다(DB 재조회로 덮어쓰지 않는다). */
    private String backToUpdtForm(BoardMaster boardMaster, ModelMap model) throws Exception {
	ComDefaultCodeVO comVo = new ComDefaultCodeVO();
	comVo.setCodeId("COM101");
	model.addAttribute("bbsTyCode", cmmUseService.selectCmmCodeDetail(comVo));
	model.addAttribute("templateList", egovBBSMasterService.selectTemplateList());
	addMenuRoleModel(model);
	if (EgovComponentChecker.hasComponent("EgovArticleCommentService")) {
	    model.addAttribute("useComment", "true");
	}
	if (EgovComponentChecker.hasComponent("EgovBBSSatisfactionService")) {
	    model.addAttribute("useSatisfaction", "true");
	}
	return "egovframework/com/cop/bbs/EgovBBSMasterUpdt";
    }

    /**
     * 게시판 마스터 정보를 삭제한다.
     * 
     * @param boardMasterVO
     * @param boardMaster
     * @param status
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/deleteBBSMaster.do")
    public String deleteBBSMaster(@ModelAttribute("searchVO") BoardMasterVO boardMasterVO, @ModelAttribute("boardMaster") BoardMaster boardMaster
	    ) throws Exception {

	LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

	if (isAuthenticated) {
	    boardMaster.setLastUpdusrId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
	    egovBBSMasterService.deleteBBSMasterInf(boardMaster);
	    reloadMenuCache("deleteBBSMaster");
	}
	// status.setComplete();
	return "forward:/cop/bbs/selectBBSMasterInfs.do";
    }

    /**
     * 메뉴 캐시와 URL 보안 메타데이터를 재적용한다 — 재기동 없이 GNB·접근권한이 즉시 바뀐다.
     * 게시판 노출 설정이 메뉴(COMTNMENUCREATDTLS)를 건드리고, 그 메뉴가 L6 URL 보안의 입력이기 때문이다.
     */
    private void reloadMenuCache(String source) {
    	try {
    	    MenuHelper.clearCache();
    	    LOGGER.info("Menu cache cleared after {}.", source);
    	} catch (Exception e) {
    	    LOGGER.warn("Menu cache clear failed after {}.", source, e);
    	}
    	try {
    	    if (securityMetadataSource != null) {
    		securityMetadataSource.reload();
    		LOGGER.info("Security URL metadata reloaded after {}.", source);
    	    }
    	} catch (Exception e) {
    	    LOGGER.warn("Security reload failed after {}.", source, e);
    	}
    }

    /** 노출 설정 화면이 필요로 하는 모델(역할 체크박스). */
    private void addMenuRoleModel(ModelMap model) {
	model.addAttribute("menuRoleLabels", MENU_ROLE_LABELS);
    }

    /** 저장된 노출 설정을 폼 객체에 실어 수정화면이 현재 상태로 열리게 한다. */
    private void applyMenuLink(BoardMasterVO boardMasterVO) {
	BoardMenuVO link = boardMenuLinkService.selectLink(boardMasterVO.getBbsId());
	if (link == null) {
	    boardMasterVO.setMenuExposeAt("N");
	    boardMasterVO.setMenuNm(boardMasterVO.getBbsNm());
	    return;
	}
	boardMasterVO.setMenuExposeAt("Y");
	boardMasterVO.setMenuNm(link.getMenuNm());
	boardMasterVO.setMenuOrdr(link.getMenuOrdr());
	boardMasterVO.setMenuAuthorCodes(link.getAuthorCodes().toArray(new String[0]));
    }
    
    /**
     * 포트릿을 위한 게시판 목록 정보를 조회한다.
     *
     * @param boardMasterVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/bbs/selectBBSListPortlet.do")
    public String selectBBSListPortlet(@ModelAttribute("searchVO") BoardMasterVO boardMasterVO, ModelMap model) throws Exception {
    	List<BoardMasterVO> result = egovBBSMasterService.selectBBSListPortlet(boardMasterVO);
    	
    	model.addAttribute("resultList", result);
    	
    	return "egovframework/com/cop/bbs/EgovBBSListPortlet";
    }

    
}
