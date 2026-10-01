package egovframework.com.sym.prm.web;

import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springmodules.validation.commons.DefaultBeanValidator;

import egovframework.com.cmm.ComDefaultVO;
import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.annotation.IncludedInfo;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.sym.prm.service.EgovProgrmManageService;
import egovframework.com.sym.prm.service.ProgrmManageVO;

/**
 * 프로그램목록 관리및 변경을 처리하는 비즈니스 구현 클래스
 * @author 개발환경 개발팀 이용
 * @since 2009.06.01
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *
 *   수정일      수정자           수정내용
 *  -------    --------    ---------------------------
 *   2009.03.20  이용			최초 생성
 *   2011.08.22  서준식			selectProgrmChangRequstProcess() 메서드 처리일자 trim 처리
 *   2011.08.26	 정진오			IncludedInfo annotation 추가
 *   2024.09.04  권태성			등록 화면과 데이터를 처리하는 method 분리, validation 적용
 * </pre>
 */

@Controller
public class EgovProgrmManageController {

	/** Validator */
	@Autowired
	private DefaultBeanValidator beanValidator;

	/** EgovPropertyService */
    @Resource(name = "propertiesService")
    protected EgovPropertyService propertiesService;

    /** EgovProgrmManageService */
	@Resource(name = "progrmManageService")
    private EgovProgrmManageService progrmManageService;

	/** EgovMessageSource */
    @Resource(name="egovMessageSource")
    EgovMessageSource egovMessageSource;

    /**
     * 프로그램목록을 상세화면 호출 및 상세조회한다.
     * @param tmp_progrmNm  String
     * @return 출력페이지정보 "sym/prm/EgovProgramListDetailSelectUpdt"
     * @exception Exception
     */
    @RequestMapping(value="/sym/prm/EgovProgramListDetailSelect.do")
    public String selectProgrm(
    		@RequestParam("tmp_progrmNm") String tmp_progrmNm ,
   		    @ModelAttribute("searchVO") ComDefaultVO searchVO,
    		ModelMap model)
            throws Exception {
        // 0. Spring Security 사용자권한 처리
    	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
    	if(!isAuthenticated) {
    		model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
        	return "redirect:/uat/uia/egovLoginUsr.do";
    	}
    	
    	ProgrmManageVO vo = new ProgrmManageVO();
    	vo.setProgrmFileNm(tmp_progrmNm);
    	ProgrmManageVO progrmManageVO = progrmManageService.selectProgrm(vo);
        model.addAttribute("progrmManageVO", progrmManageVO);
        return "egovframework/com/sym/prm/EgovProgramListDetailSelectUpdt";
    }

    /**
     * 프로그램목록 리스트조회한다.
     * 
     * @param searchVO ComDefaultVO
     * @return 출력페이지정보 "sym/prm/EgovProgramListManage"
     * @exception Exception
     */
    @IncludedInfo(name = "프로그램관리", order = 1111, gid = 60)
    @RequestMapping(value = "/sym/prm/EgovProgramListManageSelect.do")
    public String selectProgrmList(@ModelAttribute("searchVO") ComDefaultVO searchVO, ModelMap model) throws Exception {
        // 0. Spring Security 사용자권한 처리
    	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
    	if (!isAuthenticated) {
    		model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
        	return "redirect:/uat/uia/egovLoginUsr.do";
    	}
    	// 내역 조회
    	/** EgovPropertyService.sample */
    	searchVO.setPageUnit(propertiesService.getInt("pageUnit"));
    	searchVO.setPageSize(propertiesService.getInt("pageSize"));

    	/** pageing */
    	PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(searchVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(searchVO.getPageUnit());
		paginationInfo.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		searchVO.setLastIndex(paginationInfo.getLastRecordIndex());
		searchVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		List<ProgrmManageVO> resultList = progrmManageService.selectProgrmList(searchVO);
        model.addAttribute("resultList", resultList);

        int totCnt = progrmManageService.selectProgrmListTotCnt(searchVO);
		paginationInfo.setTotalRecordCount(totCnt);
        model.addAttribute("paginationInfo", paginationInfo);

      	return "egovframework/com/sym/prm/EgovProgramListManage";
    }

    /**
     * 프로그램목록 멀티 삭제한다.
     * @param checkedProgrmFileNmForDel String
     * @return 출력페이지정보 "forward:/sym/prm/EgovProgramListManageSelect.do"
     * @exception Exception
     */
    @RequestMapping("/sym/prm/EgovProgrmManageListDelete.do")
    public String deleteProgrmManageList(
            @RequestParam("checkedProgrmFileNmForDel") String checkedProgrmFileNmForDel ,
            @ModelAttribute("progrmManageVO") ProgrmManageVO progrmManageVO,
            ModelMap model)
            throws Exception {
		String sLocationUrl = null;
    	String resultMsg    = "";
        // 0. Spring Security 사용자권한 처리
    	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
    	if(!isAuthenticated) {
    		model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
        	return "redirect:/uat/uia/egovLoginUsr.do";
    	}
    	String [] delProgrmFileNm = checkedProgrmFileNmForDel.split(",");
		if (delProgrmFileNm == null || (delProgrmFileNm.length ==0)){
    		resultMsg = egovMessageSource.getMessage("fail.common.delete");
    		sLocationUrl = "forward:/sym/prm/EgovProgramListManageSelect.do";
		}else{
    	   progrmManageService.deleteProgrmManageList(checkedProgrmFileNmForDel);
    	   resultMsg = egovMessageSource.getMessage("success.common.delete");
    	   sLocationUrl ="forward:/sym/prm/EgovProgramListManageSelect.do";
		}
		model.addAttribute("resultMsg", resultMsg);
        //status.setComplete();
        return sLocationUrl ;
    }

	/**
	 * 프로그램목록 등록화면
	 * 
	 * @param progrmManageVO ProgrmManageVO
	 * @return 출력페이지정보 등록화면 호출시 "sym/prm/EgovProgramListRegist", 출력페이지정보 등록처리시
	 *         "forward:/sym/prm/EgovProgramListManageSelect.do"
	 * @exception Exception
	 */
	@RequestMapping(value = "/sym/prm/EgovProgramListRegistView.do")
	public String insertProgrmListView(@ModelAttribute("progrmManageVO") ProgrmManageVO progrmManageVO, ModelMap model)
			throws Exception {
		// 0. Spring Security 사용자권한 처리
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		if (!isAuthenticated) {
			model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
			return "redirect:/uat/uia/egovLoginUsr.do";
		}
		return "egovframework/com/sym/prm/EgovProgramListRegist";
	}

	/**
	 * 프로그램목록을 등록한다.
	 * 
	 * @param progrmManageVO
	 * @param bindingResult
	 * @param model
	 * @return
	 * @throws Exception
	 */
	@RequestMapping(value = "/sym/prm/EgovProgramListRegist.do")
	public String insertProgrmList(@ModelAttribute("progrmManageVO") ProgrmManageVO progrmManageVO, BindingResult bindingResult,
			ModelMap model) throws Exception {
		String resultMsg = "";
		// 0. Spring Security 사용자권한 처리
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		if (!isAuthenticated) {
			model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
			return "redirect:/uat/uia/egovLoginUsr.do";
		}

		beanValidator.validate(progrmManageVO, bindingResult);
		if (bindingResult.hasErrors()) {
			return "egovframework/com/sym/prm/EgovProgramListRegist";
		}
		if (progrmManageVO.getProgrmDc() == null || progrmManageVO.getProgrmDc().equals("")) {
			progrmManageVO.setProgrmDc(" ");
		}
		progrmManageService.insertProgrm(progrmManageVO);
		resultMsg = egovMessageSource.getMessage("success.common.insert");
		model.addAttribute("resultMsg", resultMsg);
		return "redirect:/sym/prm/EgovProgramListManageSelect.do";
	}


	/**
	 * 프로그램목록을 수정 한다.
	 * 
	 * @param progrmManageVO ProgrmManageVO
	 * @return 출력페이지정보 "forward:/sym/prm/EgovProgramListManageSelect.do"
	 * @exception Exception
	 */
	/* 프로그램목록수정 */
	@RequestMapping(value = "/sym/prm/EgovProgramListDetailSelectUpdt.do")
	public String updateProgrmList(@ModelAttribute("progrmManageVO") ProgrmManageVO progrmManageVO,
			BindingResult bindingResult, ModelMap model) throws Exception {
		String resultMsg = "";
		String sLocationUrl = null;
		// 0. Spring Security 사용자권한 처리
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		if (!isAuthenticated) {
			model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
			return "redirect:/uat/uia/egovLoginUsr.do";
		}

		beanValidator.validate(progrmManageVO, bindingResult);
		if (bindingResult.hasErrors()) {
			sLocationUrl = "forward:/sym/prm/EgovProgramListDetailSelect.do";
			return sLocationUrl;
		}
		if (progrmManageVO.getProgrmDc() == null || progrmManageVO.getProgrmDc().equals("")) {
			progrmManageVO.setProgrmDc(" ");
		}
		progrmManageService.updateProgrm(progrmManageVO);
		resultMsg = egovMessageSource.getMessage("success.common.update");
		sLocationUrl = "forward:/sym/prm/EgovProgramListManageSelect.do";
		model.addAttribute("resultMsg", resultMsg);
		return sLocationUrl;
	}

    /**
     * 프로그램목록을 삭제 한다.
     * @param progrmManageVO ProgrmManageVO
     * @return 출력페이지정보 "forward:/sym/prm/EgovProgramListManageSelect.do"
     * @exception Exception
     */
    @RequestMapping(value="/sym/prm/EgovProgramListManageDelete.do")
    public String deleteProgrmList(
    		@ModelAttribute("progrmManageVO")
    		ProgrmManageVO progrmManageVO,
    		ModelMap model)
            throws Exception {
    	String resultMsg = "";
        // 0. Spring Security 사용자권한 처리
    	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
    	if(!isAuthenticated) {
    		model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
        	return "redirect:/uat/uia/egovLoginUsr.do";
    	}
        progrmManageService.deleteProgrm(progrmManageVO);
        resultMsg = egovMessageSource.getMessage("success.common.delete");
    	model.addAttribute("resultMsg", resultMsg);
        return "forward:/sym/prm/EgovProgramListManageSelect.do";
    }

    /**
     * 프로그램파일명을 조회한다.
     * 
     * @param searchVO ComDefaultVO
     * @return 출력페이지정보 "sym/prm/EgovFileNmSearch"
     * @exception Exception
     */
    @RequestMapping(value = "/sym/prm/EgovProgramListSearch.do")
    public String selectProgrmListSearch(@ModelAttribute("searchVO") ComDefaultVO searchVO, ModelMap model)
            throws Exception {
        // 0. Spring Security 사용자권한 처리
    	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
    	if (!isAuthenticated) {
    		model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
        	return "redirect:/uat/uia/egovLoginUsr.do";
    	}
    	// 내역 조회
    	searchVO.setPageUnit(propertiesService.getInt("pageUnit"));
    	searchVO.setPageSize(propertiesService.getInt("pageSize"));

    	/** pageing */
    	PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(searchVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(searchVO.getPageUnit());
		paginationInfo.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		searchVO.setLastIndex(paginationInfo.getLastRecordIndex());
		searchVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		List<ProgrmManageVO> resultList = progrmManageService.selectProgrmList(searchVO);
        model.addAttribute("resultList", resultList);

        int totCnt = progrmManageService.selectProgrmListTotCnt(searchVO);
		paginationInfo.setTotalRecordCount(totCnt);
        model.addAttribute("paginationInfo", paginationInfo);

      	return "egovframework/com/sym/prm/EgovFileNmSearch";
    }

    /**
     * 프로그램파일명을 조회한다. (New)
     * 
     * @param searchVO ComDefaultVO
     * @return 출력페이지정보 "sym/prm/EgovFileNmSearch"
     * @exception Exception
     */
    @RequestMapping(value = "/sym/prm/EgovProgramListSearchNew.do")
    public String selectProgrmListSearchNew(@ModelAttribute("searchVO") ComDefaultVO searchVO, ModelMap model)
            throws Exception {
        // 0. Spring Security 사용자권한 처리
    	Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
    	if (!isAuthenticated) {
    		model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
        	return "redirect:/uat/uia/egovLoginUsr.do";
    	}
    	// 내역 조회
    	searchVO.setPageUnit(propertiesService.getInt("pageUnit"));
    	searchVO.setPageSize(propertiesService.getInt("pageSize"));

    	/** pageing */
    	PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(searchVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(searchVO.getPageUnit());
		paginationInfo.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		searchVO.setLastIndex(paginationInfo.getLastRecordIndex());
		searchVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		List<ProgrmManageVO> resultList = progrmManageService.selectProgrmList(searchVO);
        model.addAttribute("resultList", resultList);

        int totCnt = progrmManageService.selectProgrmListTotCnt(searchVO);
		paginationInfo.setTotalRecordCount(totCnt);
        model.addAttribute("paginationInfo", paginationInfo);

      	return "egovframework/com/sym/prm/EgovFileNmSearchNew";
    }
}