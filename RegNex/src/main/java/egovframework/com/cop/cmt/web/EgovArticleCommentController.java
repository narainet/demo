package egovframework.com.cop.cmt.web;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

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
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import org.springmodules.validation.commons.DefaultBeanValidator;

import egovframework.com.cmm.EgovMessageSource;
import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.cop.cmt.service.Comment;
import egovframework.com.cop.cmt.service.CommentVO;
import egovframework.com.cop.cmt.service.EgovArticleCommentService;
import egovframework.com.utl.fcc.service.EgovStringUtil;

/**
 * 댓글 관리를 위한 컨트롤러 클래스
 * @author 공통서비스개발팀 신용호
 * @since 2016.07.22
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *
 *   수정일      수정자           수정내용
 *  -------       --------    ---------------------------
 *   2016.07.22   신용호              최초 생성
 *   2018.06.27     신용호		    댓글 등록후 처리 예외 수정
 *   2026.07.10   RLMS            사용자 게시판(/cop/cmt/user/*) 동선 + 서버측 작성자 확인
 * </pre>
 *
 * <p><b>URL 이 두 벌인 이유</b> — 게시글과 동일하다. 관리 동선은 /cop/cmt/*(ADMIN, mgr 레이아웃),
 * 사용자 동선은 /cop/cmt/user/*(로그인 사용자, front 레이아웃)로 나눈다. 서비스·화면(JSP)은 공유하고
 * 링크 접두만 {@code cmtUrlBase} 모델값으로 갈아끼운다. 사용자 동선은 쓰기 후 REDIRECT(PRG)로
 * 사용자 상세(/cop/bbs/user/selectArticleDetail.do)에 돌아간다 — SiteMesh 는 REQUEST 만 데코레이트하므로
 * forward 로 돌아가면 원 요청 URI(/cop/cmt/*) 기준의 레이아웃이 씌워진다.</p>
 */

@Controller
public class EgovArticleCommentController {

	/** 사용자(front) 열람·댓글 동선 접두. 이 경로 아래로만 로그인 사용자에게 열려 있다. */
	private static final String CMT_USER_BASE = "/cop/cmt/user";
	private static final String CMT_ADMIN_BASE = "/cop/cmt";
	private static final String BBS_USER_BASE = "/cop/bbs/user";
	private static final String BBS_ADMIN_BASE = "/cop/bbs";

	/** COMTNCOMMENT.ANSWER 컬럼 한도(문자). DDL: VARCHAR2(1000 CHAR). */
	private static final int COMMENT_MAX_LENGTH = 1000;

	@Resource(name = "EgovArticleCommentService")
    protected EgovArticleCommentService egovArticleCommentService;

    @Resource(name="propertiesService")
    protected EgovPropertyService propertyService;

    @Resource(name="egovMessageSource")
    EgovMessageSource egovMessageSource;

    @Autowired
    private DefaultBeanValidator beanValidator;

    //protected Logger log = Logger.getLogger(this.getClass());

    /**
     * 댓글관리 목록 조회를 제공한다.
     *
     * @param boardVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/cmt/selectArticleCommentList.do", "/cop/cmt/user/selectArticleCommentList.do"})
    public String selectArticleCommentList(@ModelAttribute("searchVO") CommentVO commentVO, ModelMap model,
    		HttpServletRequest request) throws Exception {

    	CommentVO articleCommentVO = new CommentVO();

		// 수정 처리된 후 댓글 등록 화면으로 처리되기 위한 구현
		if (commentVO.isModified()) {
		    commentVO.setCommentNo("");
		    commentVO.setCommentCn("");
		}

		// 수정을 위한 처리
		if (!commentVO.getCommentNo().equals("")) {
		    return "forward:" + cmtBase(request) + "/updateArticleCommentView.do";
		}

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
   	 	// KISA 보안취약점 조치 (2018-12-10, 신용호)
        Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

        if(!isAuthenticated) {
            return "redirect:/uat/uia/egovLoginUsr.do";
        }

		model.addAttribute("sessionUniqId", user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
		model.addAttribute("myName", user == null ? "" : EgovStringUtil.isNullToString(user.getName())); // 입력창 작성자 표시

		commentVO.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));

//		commentVO.setSubPageUnit(propertyService.getInt("pageUnit"));
//		commentVO.setSubPageSize(propertyService.getInt("pageSize"));

		PaginationInfo paginationInfo = new PaginationInfo();
		paginationInfo.setCurrentPageNo(commentVO.getSubPageIndex());
		paginationInfo.setRecordCountPerPage(commentVO.getSubPageUnit());
		paginationInfo.setPageSize(commentVO.getSubPageSize());

		commentVO.setSubFirstIndex(paginationInfo.getFirstRecordIndex());
		commentVO.setSubLastIndex(paginationInfo.getLastRecordIndex());
		commentVO.setSubRecordCountPerPage(paginationInfo.getRecordCountPerPage());

		Map<String, Object> map = egovArticleCommentService.selectArticleCommentList(commentVO);
		int totCnt = Integer.parseInt((String)map.get("resultCnt"));

		paginationInfo.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", map.get("resultList"));
		model.addAttribute("resultCnt", map.get("resultCnt"));
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("type", "body");	// 댓글 페이지 body import용
		model.addAttribute("cmtUrlBase", cmtBase(request));

		model.addAttribute("articleCommentVO", articleCommentVO);	// validator 용도

		commentVO.setCommentCn("");	// 등록 후 댓글 내용 처리

		return "egovframework/com/cop/cmt/EgovArticleCommentList";
    }


    /**
     * 댓글을 등록한다.
     *
     * @param commentVO
     * @param comment
     * @param bindingResult
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping(value = {"/cop/cmt/insertArticleComment.do", "/cop/cmt/user/insertArticleComment.do"},
    		method = RequestMethod.POST)
    public String insertArticleComment(@ModelAttribute("searchVO") CommentVO commentVO, @ModelAttribute("comment") Comment comment,
	    BindingResult bindingResult, ModelMap model, @RequestParam HashMap<String, String> map,
	    HttpServletRequest request, RedirectAttributes ra) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

		beanValidator.validate(comment, bindingResult);
		String invalid = validateBody(comment.getCommentCn());
		if (bindingResult.hasErrors() || invalid != null) {
		    return back(request, commentVO, model, ra, invalid);
		}
		// 댓글을 끈 보드에 bbsId 를 위조해 주입하는 것을 막는다(사용자 URL 은 인증만 되면 열림).
		if (!egovArticleCommentService.canUseComment(commentVO.getBbsId())) {
		    return back(request, commentVO, model, ra, "댓글을 사용하지 않는 게시판입니다.");
		}

		if (isAuthenticated) {
		    comment.setFrstRegisterId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
		    comment.setWrterId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));
		    comment.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));


		    egovArticleCommentService.insertArticleComment(comment);

		    commentVO.setCommentCn("");
		    commentVO.setCommentNo("");
		}

		return back(request, commentVO, model, ra, null);
    }


    /**
     * 댓글을 삭제한다. (작성자 본인만 — 서버측 확인)
     *
     * @param commentVO
     * @param comment
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping(value = {"/cop/cmt/deleteArticleComment.do", "/cop/cmt/user/deleteArticleComment.do"},
    		method = RequestMethod.POST)
    public String deleteArticleComment(@ModelAttribute("searchVO") CommentVO commentVO, @ModelAttribute("comment") Comment comment,
    		ModelMap model, @RequestParam HashMap<String, String> map, HttpServletRequest request,
    		RedirectAttributes ra) throws Exception {
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

		String msg = null;
		if (isAuthenticated && isOwnComment(commentVO)) {
		    egovArticleCommentService.deleteArticleComment(commentVO);
		} else {
		    msg = "본인이 작성한 댓글만 삭제할 수 있습니다.";
		}

		commentVO.setCommentCn("");
		commentVO.setCommentNo("");

		return back(request, commentVO, model, ra, msg);
    }


    /**
     * 댓글 수정 페이지로 이동한다.
     *
     * @param commentVO
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping({"/cop/cmt/updateArticleCommentView.do", "/cop/cmt/user/updateArticleCommentView.do"})
    public String updateArticleCommentView(@ModelAttribute("searchVO") CommentVO commentVO, ModelMap model,
    		HttpServletRequest request) throws Exception {

	LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
	 //KISA 보안취약점 조치 (2018-12-10, 신용호)
    Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

    if(!isAuthenticated) {
        return "redirect:/uat/uia/egovLoginUsr.do";
    }

	CommentVO articleCommentVO = new CommentVO();

	commentVO.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));

	commentVO.setSubPageUnit(propertyService.getInt("pageUnit"));
	commentVO.setSubPageSize(propertyService.getInt("pageSize"));

	PaginationInfo paginationInfo = new PaginationInfo();
	paginationInfo.setCurrentPageNo(commentVO.getSubPageIndex());
	paginationInfo.setRecordCountPerPage(commentVO.getSubPageUnit());
	paginationInfo.setPageSize(commentVO.getSubPageSize());

	commentVO.setSubFirstIndex(paginationInfo.getFirstRecordIndex());
	commentVO.setSubLastIndex(paginationInfo.getLastRecordIndex());
	commentVO.setSubRecordCountPerPage(paginationInfo.getRecordCountPerPage());

	Map<String, Object> map = egovArticleCommentService.selectArticleCommentList(commentVO);
	int totCnt = Integer.parseInt((String)map.get("resultCnt"));

	paginationInfo.setTotalRecordCount(totCnt);

	model.addAttribute("resultList", map.get("resultList"));
	model.addAttribute("resultCnt", map.get("resultCnt"));
	model.addAttribute("paginationInfo", paginationInfo);
	model.addAttribute("type", "body");	// body import
	model.addAttribute("cmtUrlBase", cmtBase(request));
	model.addAttribute("sessionUniqId", user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));

	// 남의 댓글은 수정폼에 싣지 않는다 — 버튼은 JSP 가 가리지만 URL 직접 호출 방어.
	articleCommentVO = isOwnComment(commentVO) ? egovArticleCommentService.selectArticleCommentDetail(commentVO)
			: new CommentVO();

	model.addAttribute("articleCommentVO", articleCommentVO);


	return "egovframework/com/cop/cmt/EgovArticleCommentList";
    }


    /**
     * 댓글을 수정한다. (작성자 본인만 — 서버측 확인)
     *
     * @param commentVO
     * @param comment
     * @param bindingResult
     * @param model
     * @return
     * @throws Exception
     */
    @RequestMapping(value = {"/cop/cmt/updateArticleComment.do", "/cop/cmt/user/updateArticleComment.do"},
    		method = RequestMethod.POST)
    public String updateArticleComment(@ModelAttribute("searchVO") CommentVO commentVO, @ModelAttribute("comment") Comment comment,
	    BindingResult bindingResult, ModelMap model, HttpServletRequest request, RedirectAttributes ra) throws Exception {

		LoginVO user = (LoginVO)EgovUserDetailsHelper.getAuthenticatedUser();
		Boolean isAuthenticated = EgovUserDetailsHelper.isAuthenticated();

		beanValidator.validate(comment, bindingResult);
		String invalid = validateBody(comment.getCommentCn());
		if (bindingResult.hasErrors() || invalid != null) {
		    return back(request, commentVO, model, ra, invalid);
		}

		String msg = null;
		if (isAuthenticated && isOwnComment(commentVO)) {
		    comment.setLastUpdusrId(user == null ? "" : EgovStringUtil.isNullToString(user.getUniqId()));

		    egovArticleCommentService.updateArticleComment(comment);

		    commentVO.setCommentCn("");
		    commentVO.setCommentNo("");
		} else {
		    msg = "본인이 작성한 댓글만 수정할 수 있습니다.";
		}

		return back(request, commentVO, model, ra, msg);
    }

    // ══════════════════ JSON(AJAX) API — 사용자 댓글 UI 전용 ══════════════════
    // *Json.do 는 decorators.xml 이 데코레이트 제외(SiteMesh) → 순수 JSON 응답.
    // 페이지 리로드 없이 목록/등록/수정/삭제. 소유자 확인·본문 검증은 폼 동선과 동일 로직 재사용.

    /** 댓글 목록(JSON). sort=reg(등록순, 기본) / latest(최신순). 각 항목에 mine(본인 여부) 포함. */
    @ResponseBody
    @RequestMapping({"/cop/cmt/listJson.do", "/cop/cmt/user/listJson.do"})
    public Map<String, Object> listJson(@ModelAttribute("searchVO") CommentVO commentVO,
    		@RequestParam(value = "sort", required = false, defaultValue = "reg") String sort) {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	String uniqId = currentUniqId();
    	List<CommentVO> rows = egovArticleCommentService.selectArticleCommentAllList(commentVO);
    	if ("latest".equals(sort)) {
    		Collections.reverse(rows); // 쿼리는 등록순(ASC) 고정 — 최신순은 뒤집는다.
    	}
    	List<Map<String, Object>> list = new ArrayList<>();
    	for (CommentVO c : rows) {
    		Map<String, Object> m = new LinkedHashMap<>();
    		m.put("commentNo", c.getCommentNo());
    		m.put("wrterNm", c.getWrterNm());
    		m.put("content", c.getCommentCn()); // ★JSON 원문 — 화면에서 textContent 로 넣어 XSS 차단
    		m.put("regDt", c.getFrstRegisterPnttm());
    		m.put("mine", !uniqId.isEmpty() && uniqId.equals(EgovStringUtil.isNullToString(c.getWrterId())));
    		list.add(m);
    	}
    	res.put("ok", true);
    	res.put("count", list.size());
    	res.put("max", COMMENT_MAX_LENGTH);
    	res.put("list", list);
    	return res;
    }

    /** 댓글 등록(JSON). */
    @ResponseBody
    @RequestMapping(value = {"/cop/cmt/insertJson.do", "/cop/cmt/user/insertJson.do"}, method = RequestMethod.POST)
    public Map<String, Object> insertJson(@ModelAttribute("comment") Comment comment) throws Exception {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	String invalid = validateBody(comment.getCommentCn());
    	if (invalid != null) {
    		res.put("ok", false);
    		res.put("msg", invalid);
    		return res;
    	}
    	if (!egovArticleCommentService.canUseComment(comment.getBbsId())) {
    		res.put("ok", false);
    		res.put("msg", "댓글을 사용하지 않는 게시판입니다.");
    		return res;
    	}
    	LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
    	String uniqId = currentUniqId();
    	comment.setFrstRegisterId(uniqId);
    	comment.setWrterId(uniqId);
    	comment.setWrterNm(user == null ? "" : EgovStringUtil.isNullToString(user.getName()));
    	egovArticleCommentService.insertArticleComment(comment);
    	res.put("ok", true);
    	return res;
    }

    /** 댓글 수정(JSON) — 작성자 본인만. */
    @ResponseBody
    @RequestMapping(value = {"/cop/cmt/updateJson.do", "/cop/cmt/user/updateJson.do"}, method = RequestMethod.POST)
    public Map<String, Object> updateJson(@ModelAttribute("searchVO") CommentVO commentVO,
    		@ModelAttribute("comment") Comment comment) throws Exception {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	String invalid = validateBody(comment.getCommentCn());
    	if (invalid != null) {
    		res.put("ok", false);
    		res.put("msg", invalid);
    		return res;
    	}
    	if (!isOwnComment(commentVO)) {
    		res.put("ok", false);
    		res.put("msg", "본인이 작성한 댓글만 수정할 수 있습니다.");
    		return res;
    	}
    	comment.setLastUpdusrId(currentUniqId());
    	egovArticleCommentService.updateArticleComment(comment);
    	res.put("ok", true);
    	return res;
    }

    /** 댓글 삭제(JSON) — 작성자 본인만. 소프트 삭제(USE_AT='N'). */
    @ResponseBody
    @RequestMapping(value = {"/cop/cmt/deleteJson.do", "/cop/cmt/user/deleteJson.do"}, method = RequestMethod.POST)
    public Map<String, Object> deleteJson(@ModelAttribute("searchVO") CommentVO commentVO) throws Exception {
    	Map<String, Object> res = new LinkedHashMap<>();
    	if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
    		res.put("ok", false);
    		res.put("login", true);
    		return res;
    	}
    	if (!isOwnComment(commentVO)) {
    		res.put("ok", false);
    		res.put("msg", "본인이 작성한 댓글만 삭제할 수 있습니다.");
    		return res;
    	}
    	egovArticleCommentService.deleteArticleComment(commentVO);
    	res.put("ok", true);
    	return res;
    }

	// ── 내부 ───────────────────────────────────────────────────────

	/** 로그인 사용자 고유ID(ESNTL_ID). 미인증/실패 시 "". */
	private String currentUniqId() {
		Object au = EgovUserDetailsHelper.getAuthenticatedUser();
		if (au instanceof LoginVO) {
			return EgovStringUtil.isNullToString(((LoginVO) au).getUniqId());
		}
		return "";
	}

	/** 요청이 사용자(front) 동선인지 — c:import(INCLUDE) 안에서는 include 대상 URI 로 판정한다. */
	private static boolean isUserMode(HttpServletRequest request) {
		String uri = (String) request.getAttribute("javax.servlet.include.request_uri");
		if (uri == null) {
			uri = request.getRequestURI();
		}
		return uri != null && uri.contains(CMT_USER_BASE + "/");
	}

	/** 공유 JSP 가 댓글 등록/수정/삭제 링크를 만들 때 쓰는 접두. */
	private static String cmtBase(HttpServletRequest request) {
		return isUserMode(request) ? CMT_USER_BASE : CMT_ADMIN_BASE;
	}

	/**
	 * 쓰기 후 게시글 상세로 복귀. msg 가 있으면 화면(댓글 조각)에 안내한다.
	 *  - 사용자 동선: REDIRECT(PRG). SiteMesh 가 REQUEST 만 데코레이트하므로 forward 로는 front 레이아웃이 안 씌워진다.
	 *    한글 메시지는 쿼리스트링에 실으면 깨지므로 flash 로 넘긴다.
	 *  - 관리 동선: 기존 forward 유지.
	 */
	private static String back(HttpServletRequest request, CommentVO commentVO, ModelMap model,
			RedirectAttributes ra, String msg) {
		if (!isUserMode(request)) {
			if (msg != null) {
				model.addAttribute("msg", msg);
			}
			return "forward:" + BBS_ADMIN_BASE + "/selectArticleDetail.do";
		}
		if (msg != null) {
			ra.addFlashAttribute("cmtMsg", msg);
		}
		StringBuilder url = new StringBuilder("redirect:").append(BBS_USER_BASE).append("/selectArticleDetail.do");
		url.append("?bbsId=").append(enc(commentVO.getBbsId()));
		url.append("&nttId=").append(commentVO.getNttId());
		url.append("&subPageIndex=").append(commentVO.getSubPageIndex());
		// 목록 버튼이 검색어·페이지를 잃지 않도록 상세의 검색맥락을 되돌려준다.
		// ※ 직접 UTF-8 인코딩 — redirect 문자열에 한글을 그냥 붙이면 모지바케.
		appendParam(url, request, "searchCnd");
		appendParam(url, request, "searchWrd");
		appendParam(url, request, "pageIndex");
		return url.toString();
	}

	/** 요청 파라미터가 있으면 UTF-8 로 인코딩해 쿼리에 덧붙인다. */
	private static void appendParam(StringBuilder url, HttpServletRequest request, String name) {
		String value = request.getParameter(name);
		if (value != null && !value.isEmpty()) {
			url.append('&').append(name).append('=').append(enc(value));
		}
	}

	private static String enc(String value) {
		try {
			return URLEncoder.encode(EgovStringUtil.isNullToString(value), "UTF-8");
		} catch (UnsupportedEncodingException e) {
			return EgovStringUtil.isNullToString(value);
		}
	}

	/**
	 * 대상 댓글이 로그인 사용자의 것이면서 요청한 게시글에 속하는지.
	 * 컨트롤러에 서버측 확인이 전무해 commentNo 만 바꾸면 남의 댓글을 지울 수 있었다(IDOR).
	 * 관리자 우회는 두지 않는다 — 게시글 수정/삭제(EgovXssChecker 작성자 확인)와 동일 정책.
	 */
	private boolean isOwnComment(CommentVO commentVO) {
		String commentNo = EgovStringUtil.isNullToString(commentVO.getCommentNo());
		// ANSWER_NO 는 NUMBER — 숫자가 아니면 조회 시 ORA-01722. 여기서 먼저 걸러낸다.
		if (!commentNo.matches("\\d+")) {
			return false;
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		String uniqId = (user == null) ? "" : EgovStringUtil.isNullToString(user.getUniqId());
		if (uniqId.isEmpty()) {
			return false;
		}
		CommentVO current = egovArticleCommentService.selectArticleCommentDetail(commentVO);
		if (current == null || !"Y".equals(current.getUseAt())) {
			return false;
		}
		return uniqId.equals(current.getWrterId())
				&& current.getNttId() == commentVO.getNttId()
				&& EgovStringUtil.isNullToString(current.getBbsId()).trim()
						.equals(EgovStringUtil.isNullToString(commentVO.getBbsId()).trim());
	}

	/**
	 * 본문 필수 + 컬럼 한도. 위반이면 사유 문자열, 정상이면 null.
	 * beanValidator 는 'comment' formset 이 없어 서버측에서 사실상 no-op 이므로 여기서 직접 막는다.
	 */
	private static String validateBody(String commentCn) {
		String body = (commentCn == null) ? "" : commentCn.trim();
		if (body.isEmpty()) {
			return "댓글내용은 필수 입력값입니다.";
		}
		if (body.length() > COMMENT_MAX_LENGTH) {
			return "댓글은 " + COMMENT_MAX_LENGTH + "자까지 입력할 수 있습니다.";
		}
		return null;
	}
}
