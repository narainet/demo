package egovframework.com.uss.ion.pwm.web;

import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.egovframe.rte.psl.dataaccess.util.EgovMap;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;
import org.springmodules.validation.commons.DefaultBeanValidator;

import egovframework.com.cmm.ComDefaultCodeVO;
import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.EgovWebUtil;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.annotation.IncludedInfo;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.cmm.util.RichTextSanitizer;
import egovframework.com.uss.ion.pwm.service.EgovPopupManageService;
import egovframework.com.uss.ion.pwm.service.PopupManageVO;
import egovframework.com.utl.fcc.service.EgovStringUtil;

/**
 * 개요
 * - 팝업창에 대한 Controller를 정의한다.
 *
 * 상세내용
 * - 팝업창에 대한 등록, 수정, 삭제, 조회, 반영확인 기능을 제공한다.
 * - 팝업창의 조회기능은 목록조회, 상세조회로, 사용자 화면 보기로 구분된다.
 * @author 이창원
 * @version 1.0
 * @created 05-8-2009 오후 2:19:57
 * <pre>
  * << 개정이력(Modification Information) >>
  *
  *  수정일              수정자           수정내용
  *  ---------   --------   ---------------------------
  *  2009.08.05   이창원           최초 생성
  *  2011.08.26   정진오           IncludedInfo annotation 추가
  *  2019.05.17   신용호           취약점 조치 및 보완
  *
  * </pre>
 */

@Controller
public class EgovPopupManageController {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovPopupManageController.class);

	@Autowired
	private DefaultBeanValidator beanValidator;

	/** EgovMessageSource */
	@Resource(name = "egovMessageSource")
	EgovMessageSource egovMessageSource;

	/** EgovPropertyService */
	@Resource(name = "propertiesService")
	protected EgovPropertyService propertiesService;

	/** EgovPopupManageService */
	@Resource(name = "egovPopupManageService")
	private EgovPopupManageService egovPopupManageService;

	/**
	 * 팝업창관리 목록을 조회한다.
	 * @param popupManageVO
	 * @param model
	 * @return "egovframework/com/uss/ion/pwm/listPopupManage"
	 * @throws Exception
	 */
	@IncludedInfo(name = "팝업창관리", order = 720, gid = 50)
	@RequestMapping(value = "/uss/ion/pwm/listPopup.do")
	public String egovPopupManageList(@RequestParam Map<?, ?> commandMap, PopupManageVO popupManageVO, ModelMap model)
		throws Exception {

		/** EgovPropertyService.sample */
		popupManageVO.setPageUnit(propertiesService.getInt("pageUnit"));
		popupManageVO.setPageSize(propertiesService.getInt("pageSize"));

		/** pageing */
		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(popupManageVO.getPageIndex());
		paginationInfo.setRecordCountPerPage(popupManageVO.getPageUnit());
		paginationInfo.setPageSize(popupManageVO.getPageSize());

		popupManageVO.setFirstIndex(paginationInfo.getFirstRecordIndex());
		popupManageVO.setLastIndex(paginationInfo.getLastRecordIndex());
		popupManageVO.setRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		List<EgovMap> reusltList = egovPopupManageService.selectPopupList(popupManageVO);
		model.addAttribute("resultList", reusltList);

		model.addAttribute("searchKeyword",
			commandMap.get("searchKeyword") == null ? "" : (String)commandMap.get("searchKeyword"));
		model.addAttribute("searchCondition",
			commandMap.get("searchCondition") == null ? "" : (String)commandMap.get("searchCondition"));

		int totCnt = egovPopupManageService.selectPopupListCount(popupManageVO);
		paginationInfo.setTotalRecordCount(totCnt);
		model.addAttribute("paginationInfo", paginationInfo);

		return "egovframework/com/uss/ion/pwm/EgovPopupList";
	}

	/**
	 * 통합링크관리 목록을 상세조회 조회한다.
	 * @param popupManageVO
	 * @param commandMap
	 * @param model
	 * @return
	 *         "/uss/ion/pwm/detailPopupManage"
	 * @throws Exception
	 */
	@RequestMapping(value = "/uss/ion/pwm/detailPopup.do")
	public String egovPopupManageDetail(PopupManageVO popupManageVO, @RequestParam Map<?, ?> commandMap, ModelMap model)
		throws Exception {

		String sLocationUrl = "egovframework/com/uss/ion/pwm/EgovPopupDetail";

		String sCmd = commandMap.get("cmd") == null ? "" : (String)commandMap.get("cmd");

		if (sCmd.equals("del")) {
			egovPopupManageService.deletePopup(popupManageVO);
			sLocationUrl = "forward:/uss/ion/pwm/listPopup.do";
		} else {
			//상세정보 불러오기
			PopupManageVO popupManageVOs = egovPopupManageService.selectPopup(popupManageVO);
			model.addAttribute("popupManageVO", popupManageVOs);
		}

		return sLocationUrl;
	}

	/**
	 * 통합링크관리를 수정한다.
	 * @param searchVO
	 * @param popupManageVO
	 * @param bindingResult
	 * @param model
	 * @return
	 *         "/uss/ion/pwm/updtPopupManage"
	 * @throws Exception
	 */
	@RequestMapping(value = "/uss/ion/pwm/updtPopup.do")
	public String egovPopupManageUpdt(@RequestParam Map<?, ?> commandMap, PopupManageVO popupManageVO,
		BindingResult bindingResult, ModelMap model, HttpServletRequest request) throws Exception {
		// 0. Spring Security 사용자권한 처리
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		if (!isAuthenticated) {
			model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
			return "redirect:/uat/uia/egovLoginUsr.do";
		}

		// 로그인 객체 선언
		LoginVO loginVO = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();

		String sLocationUrl = "egovframework/com/uss/ion/pwm/EgovPopupUpdt";

		String sCmd = commandMap.get("cmd") == null ? "" : (String)commandMap.get("cmd");

		//팝업창시작일자(시)
		model.addAttribute("ntceBgndeHH", getTimeHH());
		//팝업창시작일자(분)
		model.addAttribute("ntceBgndeMM", getTimeMM());
		//팝업창종료일자(시)
		model.addAttribute("ntceEnddeHH", getTimeHH());
		//팝업창정료일자(분)
		model.addAttribute("ntceEnddeMM", getTimeMM());

		if (sCmd.equals("save")) {
			sLocationUrl = "forward:/uss/ion/pwm/listPopup.do";
			//서버  validate 체크
			beanValidator.validate(popupManageVO, bindingResult);
			if (bindingResult.hasErrors()) {
				return sLocationUrl;
			}
			//아이디 설정
			popupManageVO.setFrstRegisterId(loginVO == null ? "" : EgovStringUtil.isNullToString(loginVO.getUniqId()));
			popupManageVO.setLastUpdusrId(loginVO == null ? "" : EgovStringUtil.isNullToString(loginVO.getUniqId()));
			// 직접편집(E) 모드 본문(POPUP_CN)은 CKEditor 리치 HTML → 서버측 새니타이즈.
			// HTMLTagFilter 가 입력 시점에 넣은 엔티티 오염을 되돌리고(깨짐 복원), jsoup allowlist 로
			// on*·javascript:/data: 저장형 XSS 를 차단한다. EgovPopupContent.jsp 가 ${popupCn} 을 raw 로 출력하므로 필수.
			// cnSe='F'(파일URL) 모드는 popupCn 이 렌더되지 않으므로 손대지 않는다.
			if ("E".equals(popupManageVO.getCnSe())) {
				popupManageVO.setPopupCn(RichTextSanitizer.clean(popupManageVO.getPopupCn(), request));
			}
			//저장
			egovPopupManageService.updatePopup(popupManageVO);
		} else {

			PopupManageVO popupManageVOs = egovPopupManageService.selectPopup(popupManageVO);

			String sNtceBgnde = popupManageVOs.getNtceBgnde();
			String sNtceEndde = popupManageVOs.getNtceEndde();

			popupManageVOs.setNtceBgndeHH(sNtceBgnde.substring(8, 10));
			popupManageVOs.setNtceBgndeMM(sNtceBgnde.substring(10, 12));

			popupManageVOs.setNtceEnddeHH(sNtceEndde.substring(8, 10));
			popupManageVOs.setNtceEnddeMM(sNtceEndde.substring(10, 12));

			model.addAttribute("popupManageVO", popupManageVOs);
		}

		return sLocationUrl;
	}

	/**
	 * 통합링크관리를 등록한다.
	 * @param searchVO
	 * @param popupManageVO
	 * @param bindingResult
	 * @param model
	 * @return
	 *         "/uss/ion/pwm/registPopupManage"
	 * @throws Exception
	 */
	@RequestMapping(value = "/uss/ion/pwm/registPopup.do")
	public String egovPopupManageRegist(@RequestParam Map<?, ?> commandMap,
		@ModelAttribute("popupManageVO") PopupManageVO popupManageVO, BindingResult bindingResult,
		ModelMap model, HttpServletRequest request) throws Exception {
		// 0. Spring Security 사용자권한 처리
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();
		if (!isAuthenticated) {
			model.addAttribute("message", egovMessageSource.getMessage("fail.common.login"));
			return "redirect:/uat/uia/egovLoginUsr.do";
		}

		// 로그인 객체 선언
		LoginVO loginVO = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();

		String sLocationUrl = "egovframework/com/uss/ion/pwm/EgovPopupRegist";

		String sCmd = commandMap.get("cmd") == null ? "" : (String)commandMap.get("cmd");
		LOGGER.info("cmd => {}", sCmd);

		if (sCmd.equals("save")) {
			//서버  validate 체크
			beanValidator.validate(popupManageVO, bindingResult);
			if (bindingResult.hasErrors()) {
				return sLocationUrl;
			}
			//아이디 설정
			popupManageVO.setFrstRegisterId(loginVO == null ? "" : EgovStringUtil.isNullToString(loginVO.getUniqId()));
			popupManageVO.setLastUpdusrId(loginVO == null ? "" : EgovStringUtil.isNullToString(loginVO.getUniqId()));
			// 직접편집(E) 모드 본문(POPUP_CN)은 CKEditor 리치 HTML → 서버측 새니타이즈.
			// HTMLTagFilter 가 입력 시점에 넣은 엔티티 오염을 되돌리고(깨짐 복원), jsoup allowlist 로
			// on*·javascript:/data: 저장형 XSS 를 차단한다. EgovPopupContent.jsp 가 ${popupCn} 을 raw 로 출력하므로 필수.
			// cnSe='F'(파일URL) 모드는 popupCn 이 렌더되지 않으므로 손대지 않는다.
			if ("E".equals(popupManageVO.getCnSe())) {
				popupManageVO.setPopupCn(RichTextSanitizer.clean(popupManageVO.getPopupCn(), request));
			}
			//저장
			egovPopupManageService.insertPopup(popupManageVO);

			sLocationUrl = "forward:/uss/ion/pwm/listPopup.do";
		}

		//팝업창시작일자(시)
		model.addAttribute("ntceBgndeHH", getTimeHH());
		//팝업창시작일자(분)
		model.addAttribute("ntceBgndeMM", getTimeMM());
		//팝업창종료일자(시)
		model.addAttribute("ntceEnddeHH", getTimeHH());
		//팝업창정료일자(분)
		model.addAttribute("ntceEnddeMM", getTimeMM());

		return sLocationUrl;
	}

	/**
	 * 팝업창정보를 조회한다.
	 * @param commandMap
	 * @param popupManageVO
	 * @return
	 * @throws Exception
	 */
	@RequestMapping(value = "/uss/ion/pwm/ajaxPopupManageInfo.do")
	public void egovPopupManageInfoAjax(@RequestParam Map<?, ?> commandMap, HttpServletResponse response,
		PopupManageVO popupManageVO) throws Exception {

		// text/html 이면 SiteMesh 가 데코레이터로 감싸 "fileUrl||w||h||…" 평문이 풀페이지 HTML 로 오염된다.
		response.setHeader("Content-Type", "text/plain;charset=utf-8");
		// 브라우저 content-sniffing 차단 — 아래에서 HTML 이스케이프 없이 원문을 내보내는 근거(데이터 채널 고정)
		response.setHeader("X-Content-Type-Options", "nosniff");
		PrintWriter out = new PrintWriter(new OutputStreamWriter(response.getOutputStream(), "UTF-8"));

		LOGGER.debug("commandMap : {}", commandMap);
		LOGGER.debug("popupManageVO : {}", popupManageVO);

		PopupManageVO popupManageVOs = egovPopupManageService.selectPopup(popupManageVO);

		String sPrint = "";
		sPrint = popupManageVOs.getFileUrl();
		sPrint = sPrint + "||" + popupManageVOs.getPopupWSize();
		sPrint = sPrint + "||" + popupManageVOs.getPopupHSize();
		sPrint = sPrint + "||" + popupManageVOs.getPopupHlc();
		sPrint = sPrint + "||" + popupManageVOs.getPopupWlc();
		sPrint = sPrint + "||" + popupManageVOs.getStopVewAt();
		// 2022.01 'Potential XSS in Servlet' 패치의 clearXSSMinimum 은 '.'까지 &#46; 로 치환해
		// fileUrl(URL 데이터)을 파괴한다 — 팝업 오픈 주소가 www&#46;naver&#46;com 꼴이 되어
		// openPopupManage 화이트리스트 정확일치가 항상 실패했음(2026-07-28 원인 확정).
		// 이 응답은 text/plain + nosniff 데이터 채널이라 브라우저가 HTML 로 해석하지 않으므로
		// HTML 이스케이프 대상이 아니다. 방어는 소비처가 담당: JS 는 encodeURIComponent 로만 사용,
		// openPopupManage 는 화이트리스트 정확일치로 검증.
		out.print(sPrint);
		out.flush();
	}

	/**
	 * 팝업창을 오픈 한다.
	 * @param commandMap
	 * @param popupManageVO
	 * @return
	 * @throws Exception
	 */
	@RequestMapping(value = "/uss/ion/pwm/openPopupManage.do")
	public String egovPopupManagePopupOpen(
		@RequestParam(value = "fileUrl", required = false, defaultValue = "") String fileUrl,
		@RequestParam(value = "stopVewAt", required = false, defaultValue = "N") String stopVewAt,
		@RequestParam("popupId") String popupId,
		ModelMap model) throws Exception {

		model.addAttribute("stopVewAt", stopVewAt);
		model.addAttribute("popupId", popupId);

		// 내용구분(CN_SE) 분기: 직접편집(E) 모드이면 DB에 저장된 본문(HTML)을 렌더링한다.
		PopupManageVO searchVO = new PopupManageVO();
		searchVO.setPopupId(popupId);
		PopupManageVO popup = egovPopupManageService.selectPopup(searchVO);
		if (popup != null && "E".equals(popup.getCnSe())) {
			model.addAttribute("popupTitleNm", popup.getPopupTitleNm());
			model.addAttribute("popupCn", popup.getPopupCn());
			return "egovframework/com/uss/ion/pwm/EgovPopupContent";
		}

		// 파일URL(F) 모드: 화이트리스트 검증 후 해당 JSP 뷰를 렌더링한다. (기존 동작)
		fileUrl = EgovWebUtil.filePathBlackList(fileUrl);

		List<EgovMap> popupWhiteList = egovPopupManageService.selectPopupWhiteList();
		LOGGER.debug("Open Popup > WhiteList Count = {}", popupWhiteList.size());
		if (fileUrl == null) {
			fileUrl = "";
		}
		for (Object obj : popupWhiteList) {
			// FILE_URL 이 NULL 인 행(직접편집 E모드 팝업)은 MyBatis 가 행 자체를 null 원소로 돌려준다.
			if (obj == null) {
				continue;
			}
			EgovMap map = (EgovMap)obj;
			LOGGER.debug("Open Popup > whiteList fileUrl = {}", map.get("fileUrl"));
			if (!fileUrl.isEmpty() && fileUrl.equals(map.get("fileUrl"))) {
				// 외부 URL(F모드에 http(s) 또는 스킴 없는 호스트 등록) — 뷰 이름으로 반환하면
				// JSP 리졸브 404 라 리다이렉트로 연다.
				// 화이트리스트 정확일치를 통과한 값만 오므로 오픈 리다이렉트 아님(2026-07-28).
				String external = toExternalUrl(fileUrl);
				if (external != null) {
					return "redirect:" + external;
				}
				return fileUrl;
			}
		}
		//System.out.println("===>>> "+popupWhiteList.size());
		LOGGER.debug("Open Popup > WhiteList mismatch! Please check Admin page!");
		return "egovframework/com/cmm/error/egovError";
	}

	/**
	 * F모드 팝업 URL 이 외부 주소인지 판정하고, 열 수 있는 절대 URL 로 정규화한다.
	 * <p>
	 * 스킴이 있으면 그대로. 스킴이 없어도 {@code www.naver.com} / {@code example.co.kr/path} 처럼
	 * 호스트 꼴이면 https 를 붙여 외부 URL 로 본다 — 스킴 없이 등록하면 뷰 이름으로 해석돼
	 * 팝업 안에 404 가 뜨던 문제(고객 테스트 2026-07-29)를 막는다.
	 * 내부 JSP 뷰 이름({@code egovframework/com/...})은 점 있는 호스트 조각이 없으므로 null 을 돌려준다.
	 * <p>
	 * 호출부는 화이트리스트 정확일치를 통과한 값만 넘기므로 오픈 리다이렉트가 아니다.
	 *
	 * @return 외부 URL 이면 정규화된 절대 URL, 내부 뷰 이름이면 null
	 */
	private static String toExternalUrl(String value) {
		if (value == null) {
			return null;
		}
		String s = value.trim();
		if (s.isEmpty()) {
			return null;
		}
		if (s.startsWith("http://") || s.startsWith("https://")) {
			return s;
		}
		// 다른 스킴(javascript:, data: 등)은 열지 않는다
		if (s.contains(":")) {
			return null;
		}
		// 컨텍스트 상대 경로(/foo/bar.do)는 내부 — 뷰 이름 처리로 넘긴다
		if (s.startsWith("/")) {
			return null;
		}
		int slash = s.indexOf('/');
		String host = (slash < 0) ? s : s.substring(0, slash);
		// 호스트 판정: 점을 품고, 점으로 시작/끝나지 않으며, 공백이 없어야 한다
		if (host.indexOf('.') <= 0 || host.endsWith(".") || host.indexOf(' ') >= 0) {
			return null;
		}
		return "https://" + s;
	}

	/**
	 * 팝업창관리 메인 테스트 목록을 조회한다.
	 * @param popupManageVO
	 * @param model
	 * @return "egovframework/com/uss/ion/pwm/listMainPopup"
	 * @throws Exception
	 * 팝업창리스트를 가져온다.
	 */
	@RequestMapping(value = "/uss/ion/pwm/listMainPopup.do")
	
	public ModelAndView egovPopupManageMainList(PopupManageVO popupManageVO, ModelMap model) throws Exception {
		List<EgovMap> resultList = egovPopupManageService.selectPopupMainList(popupManageVO);
		ModelAndView mav = new ModelAndView("jsonView");
    	mav.addObject("resultList", resultList);
    	return mav;
	}

	/**
	 * 시간을 LIST를 반환한다.
	 * @return  List
	 * @throws
	 */
	@SuppressWarnings("unused")
	private List<ComDefaultCodeVO> getTimeHH() {
		ArrayList<ComDefaultCodeVO> listHH = new ArrayList<ComDefaultCodeVO>();
		HashMap<?, ?> hmHHMM;
		for (int i = 0; i <= 24; i++) {
			String sHH = "";
			String strI = String.valueOf(i);
			if (i < 10) {
				sHH = "0" + strI;
			} else {
				sHH = strI;
			}

			ComDefaultCodeVO codeVO = new ComDefaultCodeVO();
			codeVO.setCode(sHH);
			codeVO.setCodeNm(sHH);

			listHH.add(codeVO);
		}

		return listHH;
	}

	/**
	 * 분을 LIST를 반환한다.
	 * @return  List
	 * @throws
	 */
	@SuppressWarnings("unused")
	private List<ComDefaultCodeVO> getTimeMM() {
		ArrayList<ComDefaultCodeVO> listMM = new ArrayList<ComDefaultCodeVO>();
		HashMap<?, ?> hmHHMM;
		for (int i = 0; i <= 60; i++) {

			String sMM = "";
			String strI = String.valueOf(i);
			if (i < 10) {
				sMM = "0" + strI;
			} else {
				sMM = strI;
			}

			ComDefaultCodeVO codeVO = new ComDefaultCodeVO();
			codeVO.setCode(sMM);
			codeVO.setCodeNm(sMM);

			listMM.add(codeVO);
		}
		return listMM;
	}

	/**
	 * 0을 붙여 반환
	 * @return  String
	 * @throws
	 */
	public String dateTypeIntForString(int iInput) {
		String sOutput = "";
		if (Integer.toString(iInput).length() == 1) {
			sOutput = "0" + Integer.toString(iInput);
		} else {
			sOutput = Integer.toString(iInput);
		}

		return sOutput;
	}
}