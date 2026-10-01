package egovframework.com.cop.stf.web;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springmodules.validation.commons.DefaultBeanValidator;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.cop.bbs.service.EgovBBSSatisfactionService;
import egovframework.com.cop.bbs.service.Satisfaction;
import egovframework.com.cop.bbs.service.SatisfactionVO;
import egovframework.com.utl.fcc.service.EgovStringUtil;
import egovframework.com.utl.sim.service.EgovFileScrty;

/**
 * 만족도 서비스 컨트롤러 클래스
 * @author 공통컴포넌트개발팀 한성곤
 * @since 2009.06.29
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *   
 *   수정일      수정자           수정내용
 *  -------    --------    ---------------------------
 *   2009.06.29  한성곤          최초 생성
 *
 * Copyright (C) 2009 by MOPAS  All right reserved.
 * </pre>
 */
@Controller
public class EgovBBSSatisfactionController {
	
	 
	 
	
	
	@Autowired(required=false)
    protected EgovBBSSatisfactionService bbsSatisfactionService;
    
    @Resource(name="propertiesService")
    protected EgovPropertyService propertyService;
    
    @Resource(name="egovMessageSource")
    EgovMessageSource egovMessageSource;
    
    @Autowired
    private DefaultBeanValidator beanValidator;
    
    //Logger log = Logger.getLogger(this.getClass());

    private String redirectArticleDetail(SatisfactionVO satisfactionVO) {
	StringBuilder url = new StringBuilder("redirect:/cop/bbs/selectArticleDetail.do");
	url.append("?bbsId=").append(EgovStringUtil.isNullToString(satisfactionVO.getBbsId()));
	url.append("&nttId=").append(satisfactionVO.getNttId());
	return url.toString();
    }
    
    /**
     * 만족도조사 목록 조회를 제공한다.
     * 
     * @param boardVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/stf/selectSatisfactionList.do", "/cop/stf/user/selectSatisfactionList.do"})
    public String selectSatisfactionList(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, ModelMap model,
    		javax.servlet.http.HttpServletRequest request) throws Exception {

	// 수정 처리된 후 만족도조사 등록 화면으로 처리되기 위한 구현
	if (satisfactionVO.isModified()) {
	    satisfactionVO.setStsfdgNo("");
	    satisfactionVO.setStsfdgCn("");
	    satisfactionVO.setStsfdg(0);
	}

	// 수정을 위한 처리
	if (!satisfactionVO.getStsfdgNo().equals("")) {
	    return "forward:/cop/stf/selectSingleSatisfaction.do";
	}

	//------------------------------------------
	// JSP의 <head> 부분 처리 (javascript 생성)
	//------------------------------------------
	model.addAttribute("type", satisfactionVO.getType());	// head or body

	if (satisfactionVO.getType().equals("head")) {
	    return "egovframework/com/cop/stf/EgovSatisfactionList";
	}
	////----------------------------------------

	LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();

	// 조각(JSON UI)이 쓸 링크 접두·작성자명. include 대상 URI 로 사용자/관리 판정.
	model.addAttribute("stfUrlBase", stfBase(request));
	model.addAttribute("myName", user == null ? "" : EgovStringUtil.isNullToString(user.getName()));

	model.addAttribute("sessionUniqId", user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
	
	satisfactionVO.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));
	
	satisfactionVO.setSubPageUnit(propertyService.getInt("pageUnit"));
	satisfactionVO.setSubPageSize(propertyService.getInt("pageSize"));

	PaginationInfo paginationInfo = new PaginationInfo();
	paginationInfo.setCurrentPageNo(satisfactionVO.getSubPageIndex());
	paginationInfo.setRecordCountPerPage(satisfactionVO.getSubPageUnit());
	paginationInfo.setPageSize(satisfactionVO.getSubPageSize());

	satisfactionVO.setSubFirstIndex(paginationInfo.getFirstRecordIndex());
	satisfactionVO.setSubLastIndex(paginationInfo.getLastRecordIndex());
	satisfactionVO.setSubRecordCountPerPage(paginationInfo.getRecordCountPerPage());

	Map<String, Object> map = bbsSatisfactionService.selectSatisfactionList(satisfactionVO);
	int totCnt = Integer.parseInt((String)map.get("resultCnt"));
	
	paginationInfo.setTotalRecordCount(totCnt);

	model.addAttribute("resultList", map.get("resultList"));
	model.addAttribute("resultCnt", map.get("resultCnt"));
	model.addAttribute("summary", map.get("summary"));
	model.addAttribute("paginationInfo", paginationInfo);
	
	satisfactionVO.setStsfdgCn("");	// 등록 후 만족도 내용 처리
	satisfactionVO.setStsfdg(0);	// 등록 후 만족도 처리

	return "egovframework/com/cop/stf/EgovSatisfactionList";
    }
    
    /**
     * 익명용 만족도조사 목록 조회를 제공한다.
     * 
     * @param boardVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/anonymous/selectSatisfactionList.do")
    public String selectAnonymousSatisfactionList(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, ModelMap model) throws Exception {

	// 수정 처리된 후 만족도조사 등록 화면으로 처리되기 위한 구현
	if (satisfactionVO.isModified()) {
	    satisfactionVO.setStsfdgNo("");
	    satisfactionVO.setStsfdgCn("");
	    satisfactionVO.setStsfdg(0);
	    satisfactionVO.setWrterNm("");
	}
	
	// 수정을 위한 처리
	if (!satisfactionVO.getStsfdgNo().equals("")) {
	    return "forward:/cop/stf/anonymous/selectSingleSatisfaction.do";
	}
	
	//------------------------------------------
	// JSP의 <head> 부분 처리 (javascript 생성)
	//------------------------------------------
	model.addAttribute("type", satisfactionVO.getType());	// head or body
	
	if (satisfactionVO.getType().equals("head")) {
	    return "egovframework/com/cop/stf/EgovSatisfactionList";
	}
	////----------------------------------------
	
	model.addAttribute("anonymous", "true");
	
	satisfactionVO.setSubPageUnit(propertyService.getInt("pageUnit"));
	satisfactionVO.setSubPageSize(propertyService.getInt("pageSize"));

	PaginationInfo paginationInfo = new PaginationInfo();
	paginationInfo.setCurrentPageNo(satisfactionVO.getSubPageIndex());
	paginationInfo.setRecordCountPerPage(satisfactionVO.getSubPageUnit());
	paginationInfo.setPageSize(satisfactionVO.getSubPageSize());

	satisfactionVO.setSubFirstIndex(paginationInfo.getFirstRecordIndex());
	satisfactionVO.setSubLastIndex(paginationInfo.getLastRecordIndex());
	satisfactionVO.setSubRecordCountPerPage(paginationInfo.getRecordCountPerPage());

	Map<String, Object> map = bbsSatisfactionService.selectSatisfactionList(satisfactionVO);
	int totCnt = Integer.parseInt((String)map.get("resultCnt"));
	
	paginationInfo.setTotalRecordCount(totCnt);

	model.addAttribute("resultList", map.get("resultList"));
	model.addAttribute("resultCnt", map.get("resultCnt"));
	model.addAttribute("summary", map.get("summary"));
	model.addAttribute("paginationInfo", paginationInfo);
	
	satisfactionVO.setWrterNm("");
	satisfactionVO.setStsfdgCn("");	// 등록 후 만족도 내용 처리
	satisfactionVO.setStsfdg(0);	// 등록 후 만족도 처리

	return "egovframework/com/cop/stf/EgovSatisfactionList";
    }
    
    /**
     * 만족도조사를 등록한다.
     * 
     * @param satisfactionVO
     * @param satisfaction
     * @param bindingResult
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/insertSatisfaction.do")
    public String insertSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, @ModelAttribute("satisfaction") Satisfaction satisfaction, 
	    BindingResult bindingResult, ModelMap model) throws Exception {

	LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

	beanValidator.validate(satisfaction, bindingResult);
	if (bindingResult.hasErrors()) {
	    model.addAttribute("msg", "작성자 및 만족도는 필수 입력값입니다.");
	    
	    return "forward:/cop/bbs/selectBoardArticle.do";
	}

	if (isAuthenticated) {
	    satisfaction.setFrstRegisterId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
	    satisfaction.setWrterId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
	    
	    satisfaction.setStsfdgPassword("");	// dummy
	    
	    bbsSatisfactionService.insertSatisfaction(satisfaction);
	    
	    satisfactionVO.setStsfdgCn("");
	    satisfactionVO.setStsfdgNo("");
	    satisfactionVO.setStsfdg(0);
	}

	return redirectArticleDetail(satisfactionVO);
    }
    
    /**
     * 익명 만족도조사를 등록한다.
     * 
     * @param satisfactionVO
     * @param satisfaction
     * @param bindingResult
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/anonymous/insertSatisfaction.do")
    public String insertAnonymousSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, @ModelAttribute("satisfaction") Satisfaction satisfaction, 
	    BindingResult bindingResult, ModelMap model) throws Exception {

	beanValidator.validate(satisfaction, bindingResult);
	if (bindingResult.hasErrors()) {
	    model.addAttribute("msg", "작성자 및 만족도는 필수 입력값입니다.");
	    
	    return "forward:/cop/stf/anonymous/selectBoardArticle.do";
	}

	satisfaction.setFrstRegisterId("ANONYMOUS");
	satisfaction.setWrterId("");
	satisfaction.setStsfdgPassword(EgovFileScrty.encryptPassword(satisfaction.getStsfdgPassword(), satisfaction.getStsfdgNo()));

	bbsSatisfactionService.insertSatisfaction(satisfaction);

	satisfactionVO.setStsfdgNo("");
	satisfactionVO.setStsfdgCn("");
	satisfactionVO.setStsfdg(0);
	satisfactionVO.setWrterNm("");

	return "forward:/cop/bbs/anonymous/selectArticleDetail.do";
    }
    
    /**
     * 만족도조사를 삭제한다.
     * 
     * @param satisfactionVO
     * @param satisfaction
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/deleteSatisfaction.do")
    public String deleteSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, @ModelAttribute("satisfaction") Satisfaction satisfaction, ModelMap model) throws Exception {
	LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

	if (isAuthenticated) {
	    // 화면은 본인 글에만 버튼을 노출하지만 URL 직접 호출은 막지 못한다 — 본인 또는 ADMIN 만 삭제 허용
	    Satisfaction cur = bbsSatisfactionService.selectSatisfaction(satisfactionVO);
	    boolean owner = cur != null && user != null && user.getUniqId() != null && user.getUniqId().equals(cur.getWrterId());
	    boolean admin = EgovUserDetailsHelper.getAuthorities() != null && EgovUserDetailsHelper.getAuthorities().contains("ROLE_ADMIN");
	    if (owner || admin) {
	        bbsSatisfactionService.deleteSatisfaction(satisfactionVO);
	    }
	}
	
	satisfactionVO.setStsfdgCn("");
	satisfactionVO.setStsfdgNo("");
	satisfactionVO.setStsfdg(0);
	
	return redirectArticleDetail(satisfactionVO);
    }
    
    /**
     * 익명 만족도조사를 삭제한다.
     * 
     * @param satisfactionVO
     * @param satisfaction
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/anonymous/deleteSatisfaction.do")
    public String deleteAnonymousSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, @ModelAttribute("satisfaction") Satisfaction satisfaction, ModelMap model) throws Exception {
	
	//-------------------------------
	// 패스워드 비교
	//-------------------------------
	String dbpassword = bbsSatisfactionService.getSatisfactionPassword(satisfactionVO);
	String enpassword = EgovFileScrty.encryptPassword(satisfactionVO.getConfirmPassword(), satisfaction.getStsfdgNo());
	
	if (!dbpassword.equals(enpassword)) {
	    
	    model.addAttribute("subMsg", egovMessageSource.getMessage("cop.password.not.same.msg"));
	    
	    return "forward:/cop/bbs/anonymous/selectArticleDetail.do";
	}
	////-----------------------------
	
	bbsSatisfactionService.deleteSatisfaction(satisfactionVO);
	
	satisfactionVO.setStsfdgNo("");
	satisfactionVO.setStsfdgCn("");
	satisfactionVO.setStsfdg(0);
	satisfactionVO.setWrterNm("");
	
	return "forward:/cop/bbs/anonymous/selectBoardArticle.do";
    }
    
    /**
     * 만족도조사 수정 페이지로 이동한다.
     * 
     * @param satisfactionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/selectSingleSatisfaction.do")
    public String selectSingleSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, ModelMap model) throws Exception {

	//------------------------------------------
	// JSP의 <head> 부분 처리 (javascript 생성)
	//------------------------------------------
	model.addAttribute("type", satisfactionVO.getType());	// head or body
	
	if (satisfactionVO.getType().equals("head")) {
	    return "egovframework/com/cop/stf/EgovSatisfactionList";
	}
	////----------------------------------------
	
	LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	
	satisfactionVO.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));

	satisfactionVO.setSubPageUnit(propertyService.getInt("pageUnit"));
	satisfactionVO.setSubPageSize(propertyService.getInt("pageSize"));

	PaginationInfo paginationInfo = new PaginationInfo();
	paginationInfo.setCurrentPageNo(satisfactionVO.getSubPageIndex());
	paginationInfo.setRecordCountPerPage(satisfactionVO.getSubPageUnit());
	paginationInfo.setPageSize(satisfactionVO.getSubPageSize());

	satisfactionVO.setSubFirstIndex(paginationInfo.getFirstRecordIndex());
	satisfactionVO.setSubLastIndex(paginationInfo.getLastRecordIndex());
	satisfactionVO.setSubRecordCountPerPage(paginationInfo.getRecordCountPerPage());

	Map<String, Object> map = bbsSatisfactionService.selectSatisfactionList(satisfactionVO);
	int totCnt = Integer.parseInt((String)map.get("resultCnt"));
	
	paginationInfo.setTotalRecordCount(totCnt);

	model.addAttribute("resultList", map.get("resultList"));
	model.addAttribute("resultCnt", map.get("resultCnt"));
	model.addAttribute("summary", map.get("summary"));
	model.addAttribute("paginationInfo", paginationInfo);
	
	Satisfaction data = bbsSatisfactionService.selectSatisfaction(satisfactionVO);
	
	satisfactionVO.setStsfdgNo(data.getStsfdgNo());
	satisfactionVO.setNttId(data.getNttId());
	satisfactionVO.setBbsId(data.getBbsId());
	satisfactionVO.setWrterId(data.getWrterId());
	satisfactionVO.setWrterNm(data.getWrterNm());
	satisfactionVO.setStsfdgPassword(data.getStsfdgPassword());
	satisfactionVO.setStsfdgCn(data.getStsfdgCn());
	satisfactionVO.setStsfdg(data.getStsfdg());
	satisfactionVO.setUseAt(data.getUseAt());
	satisfactionVO.setFrstRegisterPnttm(data.getFrstRegisterPnttm());
	satisfactionVO.setFrstRegisterNm(data.getFrstRegisterNm());
	
	return "egovframework/com/cop/stf/EgovSatisfactionList";
    }
    
    /**
     * 익명 만족도조사 수정 페이지로 이동한다.
     * 
     * @param satisfactionVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/anonymous/selectSingleSatisfaction.do")
    public String selectAnonymousSingleSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, ModelMap model) throws Exception {

	//------------------------------------------
	// JSP의 <head> 부분 처리 (javascript 생성)
	//------------------------------------------
	model.addAttribute("type", satisfactionVO.getType());	// head or body
	
	if (satisfactionVO.getType().equals("head")) {
	    return "egovframework/com/cop/stf/EgovSatisfactionList";
	}
	////----------------------------------------
	
	model.addAttribute("anonymous", "true");

	satisfactionVO.setSubPageUnit(propertyService.getInt("pageUnit"));
	satisfactionVO.setSubPageSize(propertyService.getInt("pageSize"));

	PaginationInfo paginationInfo = new PaginationInfo();
	paginationInfo.setCurrentPageNo(satisfactionVO.getSubPageIndex());
	paginationInfo.setRecordCountPerPage(satisfactionVO.getSubPageUnit());
	paginationInfo.setPageSize(satisfactionVO.getSubPageSize());

	satisfactionVO.setSubFirstIndex(paginationInfo.getFirstRecordIndex());
	satisfactionVO.setSubLastIndex(paginationInfo.getLastRecordIndex());
	satisfactionVO.setSubRecordCountPerPage(paginationInfo.getRecordCountPerPage());

	Map<String, Object> map = bbsSatisfactionService.selectSatisfactionList(satisfactionVO);
	int totCnt = Integer.parseInt((String)map.get("resultCnt"));
	
	paginationInfo.setTotalRecordCount(totCnt);

	model.addAttribute("resultList", map.get("resultList"));
	model.addAttribute("resultCnt", map.get("resultCnt"));
	model.addAttribute("summary", map.get("summary"));
	model.addAttribute("paginationInfo", paginationInfo);
	
	//-------------------------------
	// 패스워드 비교
	//-------------------------------
	String dbpassword = bbsSatisfactionService.getSatisfactionPassword(satisfactionVO);
	String enpassword = EgovFileScrty.encryptPassword(satisfactionVO.getConfirmPassword(), satisfactionVO.getStsfdgNo());

	if (!dbpassword.equals(enpassword)) {

	    model.addAttribute("subMsg", egovMessageSource.getMessage("cop.password.not.same.msg"));
	    
	    satisfactionVO.setStsfdgNo("");
	    satisfactionVO.setStsfdgCn("");
	    satisfactionVO.setStsfdg(0);
	    satisfactionVO.setWrterNm("");
	    
	} else {
	
	    Satisfaction data = bbsSatisfactionService.selectSatisfaction(satisfactionVO);

	    satisfactionVO.setStsfdgNo(data.getStsfdgNo());
	    satisfactionVO.setNttId(data.getNttId());
	    satisfactionVO.setBbsId(data.getBbsId());
	    satisfactionVO.setWrterId(data.getWrterId());
	    satisfactionVO.setWrterNm(data.getWrterNm());
	    satisfactionVO.setStsfdgPassword(data.getStsfdgPassword());
	    satisfactionVO.setStsfdgCn(data.getStsfdgCn());
	    satisfactionVO.setStsfdg(data.getStsfdg());
	    satisfactionVO.setUseAt(data.getUseAt());
	    satisfactionVO.setFrstRegisterPnttm(data.getFrstRegisterPnttm());
	    satisfactionVO.setFrstRegisterNm(data.getFrstRegisterNm());
	}
	////-----------------------------
	
	return "egovframework/com/cop/stf/EgovSatisfactionList";
    }
    
    /**
     * 만족도조사를 수정한다.
     * 
     * @param satisfactionVO
     * @param satisfaction
     * @param bindingResult
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/updateSatisfaction.do")
    public String updateSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, @ModelAttribute("satisfaction") Satisfaction satisfaction, 
	    BindingResult bindingResult, ModelMap model) throws Exception {

	LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

	beanValidator.validate(satisfaction, bindingResult);
	if (bindingResult.hasErrors()) {
	    model.addAttribute("msg", "작성자 및 만족도는 필수 입력값입니다.");
	    
	    return "forward:/cop/bbs/selectArticleDetail.do";
	}

	if (isAuthenticated) {
	    // 화면은 본인 글에만 버튼을 노출하지만 URL 직접 호출은 막지 못한다 — 본인 또는 ADMIN 만 수정 허용
	    SatisfactionVO chk = new SatisfactionVO();
	    chk.setStsfdgNo(satisfaction.getStsfdgNo());
	    Satisfaction cur = bbsSatisfactionService.selectSatisfaction(chk);
	    boolean owner = cur != null && user != null && user.getUniqId() != null && user.getUniqId().equals(cur.getWrterId());
	    boolean admin = EgovUserDetailsHelper.getAuthorities() != null && EgovUserDetailsHelper.getAuthorities().contains("ROLE_ADMIN");
	    if (owner || admin) {
	        satisfaction.setLastUpdusrId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));

	        satisfaction.setStsfdgPassword("");	// dummy

	        bbsSatisfactionService.updateSatisfaction(satisfaction);

	        satisfactionVO.setStsfdgCn("");
	        satisfactionVO.setStsfdgNo("");
	        satisfactionVO.setStsfdg(0);
	    }
	}

	return redirectArticleDetail(satisfactionVO);
    }

    /**
     * 익명 만족도조사를 수정한다.
     * 
     * @param satisfactionVO
     * @param satisfaction
     * @param bindingResult
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping("/cop/stf/anonymous/updateSatisfaction.do")
    public String updateAnonymousSatisfaction(@ModelAttribute("searchVO") SatisfactionVO satisfactionVO, @ModelAttribute("satisfaction") Satisfaction satisfaction, 
	    BindingResult bindingResult, ModelMap model) throws Exception {

	beanValidator.validate(satisfaction, bindingResult);
	if (bindingResult.hasErrors()) {
	    model.addAttribute("msg", "작성자 및 만족도는 필수 입력값입니다.");
	    
	    return "forward:/cop/bbs/anonymous/selectBoardArticle.do";
	}

	satisfaction.setLastUpdusrId("ANONYMOUS");
	satisfaction.setStsfdgPassword(EgovFileScrty.encryptPassword(satisfaction.getStsfdgPassword(), satisfaction.getStsfdgNo()));
	    
	bbsSatisfactionService.updateSatisfaction(satisfaction);

	satisfactionVO.setStsfdgNo("");
	satisfactionVO.setStsfdgCn("");
	satisfactionVO.setStsfdg(0);
	satisfactionVO.setWrterNm("");

	return "forward:/cop/bbs/anonymous/selectBoardArticle.do";
    }

    // ══════════════════ JSON(AJAX) API — 사용자 만족도 UI 전용 ══════════════════
    // 댓글(cop/cmt)과 동일 방식. *Json.do 는 SiteMesh 데코 제외 → 순수 JSON.
    // 페이지 리로드 없이 목록/등록/수정/삭제. 수정·삭제는 서버측 작성자 확인.

    /** STSFDG_CN 컬럼 한도(문자). DDL: VARCHAR2(1000 CHAR). */
    private static final int STF_MAX_LENGTH = 1000;

    /** 만족도 목록(JSON). sort=reg(등록순, 기본)/latest(최신순). summary=평균 별점. 각 항목에 mine 포함. */
    @ResponseBody
    @RequestMapping({"/cop/stf/listJson.do", "/cop/stf/user/listJson.do"})
    public Map<String, Object> listJson(@ModelAttribute("searchVO") SatisfactionVO vo,
    		@RequestParam(value = "sort", required = false, defaultValue = "reg") String sort) throws Exception {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	String uniqId = currentUniqId();
    	vo.setSubFirstIndex(0);            // 페이징 없이 전체
    	vo.setSubRecordCountPerPage(100000);
    	Map<String, Object> data = bbsSatisfactionService.selectSatisfactionList(vo);
    	@SuppressWarnings("unchecked")
    	List<SatisfactionVO> rows = (List<SatisfactionVO>) data.get("resultList");
    	if (rows == null) {
    		rows = new ArrayList<>();
    	}
    	if ("latest".equals(sort)) {
    		Collections.reverse(rows); // 쿼리는 등록순(ASC) 고정
    	}
    	List<Map<String, Object>> list = new ArrayList<>();
    	for (SatisfactionVO s : rows) {
    		Map<String, Object> m = new LinkedHashMap<>();
    		m.put("stsfdgNo", s.getStsfdgNo());
    		m.put("wrterNm", s.getWrterNm());
    		m.put("stsfdg", s.getStsfdg());               // 별점 1~5
    		m.put("content", s.getStsfdgCn());            // ★textContent 로 넣어 XSS 차단
    		m.put("regDt", s.getFrstRegisterPnttm());
    		m.put("mine", !uniqId.isEmpty() && uniqId.equals(EgovStringUtil.isNullToString(s.getWrterId())));
    		list.add(m);
    	}
    	res.put("ok", true);
    	res.put("count", list.size());
    	res.put("summary", data.get("summary")); // 평균(문자열)
    	res.put("max", STF_MAX_LENGTH);
    	res.put("list", list);
    	return res;
    }

    /** 만족도 등록(JSON). 별점(1~5) 필수, 내용 선택. */
    @ResponseBody
    @RequestMapping(value = {"/cop/stf/insertJson.do", "/cop/stf/user/insertJson.do"}, method = RequestMethod.POST)
    public Map<String, Object> insertJson(@ModelAttribute("satisfaction") Satisfaction s) throws Exception {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	String invalid = validateStf(s.getStsfdg(), s.getStsfdgCn());
    	if (invalid != null) {
    		res.put("ok", false);
    		res.put("msg", invalid);
    		return res;
    	}
    	if (!bbsSatisfactionService.canUseSatisfaction(s.getBbsId())) {
    		res.put("ok", false);
    		res.put("msg", "만족도를 사용하지 않는 게시판입니다.");
    		return res;
    	}
    	LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
    	String uniqId = currentUniqId();
    	s.setFrstRegisterId(uniqId);
    	s.setWrterId(uniqId);
    	s.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));
    	s.setStsfdgPassword(""); // 인증 사용자는 미사용(dummy)
    	bbsSatisfactionService.insertSatisfaction(s);
    	res.put("ok", true);
    	return res;
    }

    /** 만족도 수정(JSON) — 작성자 본인만. */
    @ResponseBody
    @RequestMapping(value = {"/cop/stf/updateJson.do", "/cop/stf/user/updateJson.do"}, method = RequestMethod.POST)
    public Map<String, Object> updateJson(@ModelAttribute("searchVO") SatisfactionVO vo,
    		@ModelAttribute("satisfaction") Satisfaction s) throws Exception {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	String invalid = validateStf(s.getStsfdg(), s.getStsfdgCn());
    	if (invalid != null) {
    		res.put("ok", false);
    		res.put("msg", invalid);
    		return res;
    	}
    	if (!isOwnStf(vo)) {
    		res.put("ok", false);
    		res.put("msg", "본인이 작성한 만족도만 수정할 수 있습니다.");
    		return res;
    	}
    	LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
    	// updateSatisfaction 은 WRTER_NM/PASSWORD 도 덮어쓴다 — 본인 이름/더미로 재설정(공란화 방지).
    	s.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));
    	s.setStsfdgPassword("");
    	s.setLastUpdusrId(currentUniqId());
    	bbsSatisfactionService.updateSatisfaction(s);
    	res.put("ok", true);
    	return res;
    }

    /** 만족도 삭제(JSON) — 작성자 본인만. 소프트 삭제(USE_AT='N'). */
    @ResponseBody
    @RequestMapping(value = {"/cop/stf/deleteJson.do", "/cop/stf/user/deleteJson.do"}, method = RequestMethod.POST)
    public Map<String, Object> deleteJson(@ModelAttribute("searchVO") SatisfactionVO vo) throws Exception {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	if (!isOwnStf(vo)) {
    		res.put("ok", false);
    		res.put("msg", "본인이 작성한 만족도만 삭제할 수 있습니다.");
    		return res;
    	}
    	bbsSatisfactionService.deleteSatisfaction(vo);
    	res.put("ok", true);
    	return res;
    }

    // ── 내부 ───────────────────────────────────────────────────────

    /** 조각(만족도 JSON UI)이 쓸 링크 접두 — c:import(INCLUDE) 안에서는 include 대상 URI 로 판정. */
    private static String stfBase(javax.servlet.http.HttpServletRequest request) {
    	String uri = (String) request.getAttribute("javax.servlet.include.request_uri");
    	if (uri == null) {
    		uri = request.getRequestURI();
    	}
    	return (uri != null && uri.contains("/cop/stf/user/")) ? "/cop/stf/user" : "/cop/stf";
    }

    /** 로그인 사용자 고유ID(ESNTL_ID). 미인증/실패 시 "". */
    private String currentUniqId() {
    	Object au = EgovUserDetailsHelper.getAuthenticatedUser();
    	if (au instanceof LoginVO) {
    		return EgovStringUtil.isNullToString(((LoginVO) au).getUniqId());
    	}
    	return "";
    }

    /** 별점 1~5 필수 + 내용 길이. 위반이면 사유, 정상이면 null. */
    private static String validateStf(int stsfdg, String stsfdgCn) {
    	if (stsfdg < 1 || stsfdg > 5) {
    		return "만족도(별점)를 선택해 주세요.";
    	}
    	String cn = (stsfdgCn == null) ? "" : stsfdgCn.trim();
    	if (cn.length() > STF_MAX_LENGTH) {
    		return "내용은 " + STF_MAX_LENGTH + "자까지 입력할 수 있습니다.";
    	}
    	return null;
    }

    /**
     * 대상 만족도가 로그인 사용자의 것이면서 요청한 게시글에 속하는지(IDOR 방어).
     * 관리자 우회 없음 — 댓글 정책과 동일(작성자 본인만).
     */
    private boolean isOwnStf(SatisfactionVO vo) throws Exception {
    	String no = EgovStringUtil.isNullToString(vo.getStsfdgNo());
    	if (!no.matches("\\d+")) {
    		return false;
    	}
    	String uniqId = currentUniqId();
    	if (uniqId.isEmpty()) {
    		return false;
    	}
    	Satisfaction cur = bbsSatisfactionService.selectSatisfaction(vo);
    	if (cur == null || !"Y".equals(cur.getUseAt())) {
    		return false;
    	}
    	return uniqId.equals(EgovStringUtil.isNullToString(cur.getWrterId()))
    			&& cur.getNttId() == vo.getNttId()
    			&& EgovStringUtil.isNullToString(cur.getBbsId()).trim()
    					.equals(EgovStringUtil.isNullToString(vo.getBbsId()).trim());
    }
}
