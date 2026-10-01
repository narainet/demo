/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/umt/web/EgovMyAccountController.java
 *
 * 내 계정(프론트 셀프서비스):
 *   - 내 로그인 IP 설정 : 본인 COMTNLOGINPOLICY 행을 직접 조회/저장(IP + 제한 사용여부).
 *                         제한 ON 시 "현재 접속 IP" 와 일치해야만 저장(본인 잠금 방지 가드).
 *   - 내 로그인 내역   : 본인 접속로그(COMTNLOGINLOG, CONECT_ID=본인 ESNTL_ID) 페이징 조회.
 *   - 비밀번호 변경    : 본인 비밀번호 변경(umt 표준 selectPassword/updatePassword 재사용,
 *                         CHG_PWD_LAST_PNTTM=sysdate 갱신 → 유효기간(Globals.ExpirePwdDay) 기산 리셋).
 *
 *   ※ 정책 저장소는 관리자 '로그인정책관리'(/uat/uap)와 동일한 COMTNLOGINPOLICY → 일관 적용.
 *      실제 차단은 로그인 직후 진입점(홈 컨트롤러)에서 수행한다.
 *
 *   URL 네임스페이스 = /uss/umt/my/* (4단). 관리자 사용자관리(/uss/umt/*.do, 3단)가 접히는
 *   폴더 패턴 '\A/uss/umt/.*\Z' 보다 한 단계 깊어, 메뉴 L6 파생이 이 셀프서비스 메뉴에
 *   ROLE_USER 를 부여해도 사용자관리 화면이 열리지 않는다(더 깊은 패턴이 먼저 매칭).
 *   ⛔ /uss/umt/ 직하로 옮기지 말 것 — 사용자에게 EgovUserDelete.do 까지 열린다.
 */
package egovframework.com.uss.umt.web;

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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.uat.uap.service.EgovLoginPolicyService;
import egovframework.com.uat.uap.service.LoginPolicy;
import egovframework.com.uat.uap.service.LoginPolicyVO;
import egovframework.com.uat.uia.service.EgovLoginService;
import egovframework.com.uss.umt.service.EgovMberManageService;
import egovframework.com.uss.umt.service.EgovUserManageService;
import egovframework.com.uss.umt.service.MberManageVO;
import egovframework.com.uss.umt.service.UserManageVO;
import egovframework.com.utl.sim.service.EgovClntInfo;
import egovframework.com.utl.sim.service.EgovFileScrty;
import egovframework.com.uss.umt.service.LoginHistVO;
import egovframework.com.uss.umt.service.EgovMyAccountService;

@Controller
public class EgovMyAccountController {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovMyAccountController.class);
	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "egovLoginPolicyService")
	private EgovLoginPolicyService loginPolicyService;

	@Resource(name = "egovMyAccountService")
	private EgovMyAccountService myAccountService;

	@Resource(name = "propertiesService")
	protected EgovPropertyService propertyService;

	/** 비밀번호 변경 후 경과일 조회(uat/uia 표준) — 유효기간 상태 표시용 */
	@Resource(name = "loginService")
	private EgovLoginService loginService;

	/** 일반회원(GNR, COMTNGNRLMBER) 비밀번호 조회/변경 — umt 표준 재사용 */
	@Resource(name = "mberManageService")
	private EgovMberManageService mberManageService;

	/** 업무사용자(USR, COMTNEMPLYRINFO) 비밀번호 조회/변경 — umt 표준 재사용 */
	@Resource(name = "userManageService")
	private EgovUserManageService userManageService;

	private LoginVO currentUser() {
		Object u = EgovUserDetailsHelper.getAuthenticatedUser();
		return u instanceof LoginVO ? (LoginVO) u : null;
	}

	/** 정책 키 = 로그인ID(COMVNUSERMASTER.USER_ID) */
	private String currentLoginId() {
		LoginVO u = currentUser();
		return (u == null || u.getId() == null) ? "" : u.getId();
	}

	/** 로그/식별 키 = ESNTL_ID */
	private String currentUniqId() {
		LoginVO u = currentUser();
		return (u == null || u.getUniqId() == null) ? "" : u.getUniqId();
	}

	// ── 내 로그인 IP 설정 ───────────────────────────────────────────────

	@RequestMapping("/uss/umt/my/loginIp.do")
	public String loginIpForm(HttpServletRequest request, ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		LoginPolicyVO vo = new LoginPolicyVO();
		vo.setEmplyrId(currentLoginId());
		LoginPolicyVO policy = loginPolicyService.selectLoginPolicy(vo);

		model.addAttribute("policy", policy);
		model.addAttribute("currentIp", EgovClntInfo.getClntIP(request));
		return "egovframework/com/uss/umt/my/EgovMyLoginIp";
	}

	@RequestMapping("/uss/umt/my/saveLoginIp.do")
	public String saveLoginIp(@RequestParam(value = "ipInfo", required = false) String ipInfo,
			@RequestParam(value = "lmttAt", required = false) String lmttAt,
			HttpServletRequest request) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}

		String loginId = currentLoginId();
		String currentIp = EgovClntInfo.getClntIP(request);
		String ip = (ipInfo == null) ? "" : ipInfo.trim();
		String lmtt = "Y".equals(lmttAt) ? "Y" : "N";

		// 본인 잠금 방지: 제한 ON 이면 등록 IP 는 현재 접속 IP 와 일치해야 한다(필터는 단일 IP 정확매칭).
		if ("Y".equals(lmtt) && (ip.isEmpty() || !ip.equals(currentIp))) {
			return "redirect:/uss/umt/my/loginIp.do?err=lockout";
		}

		LoginPolicyVO existVO = new LoginPolicyVO();
		existVO.setEmplyrId(loginId);
		LoginPolicyVO exist = loginPolicyService.selectLoginPolicy(existVO);

		LoginPolicy lp = new LoginPolicy();
		lp.setEmplyrId(loginId);
		lp.setIpInfo(ip);
		lp.setLmttAt(lmtt);
		lp.setDplctPermAt((exist != null && "N".equals(exist.getDplctPermAt())) ? "N" : "Y");
		lp.setUserId(loginId);

		try {
			if (exist != null && "Y".equals(exist.getRegYn())) {
				loginPolicyService.updateLoginPolicy(lp);
			} else {
				loginPolicyService.insertLoginPolicy(lp);
			}
		} catch (Exception e) {
			LOGGER.error("내 로그인 IP 저장 실패: {}", e.getMessage());
			return "redirect:/uss/umt/my/loginIp.do?err=save";
		}
		return "redirect:/uss/umt/my/loginIp.do?saved=Y";
	}

	// ── 내 로그인 내역 ─────────────────────────────────────────────────

	@RequestMapping("/uss/umt/my/loginHistory.do")
	public String loginHistory(@ModelAttribute("searchVO") LoginHistVO searchVO, ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		searchVO.setPageUnit(propertyService.getInt("pageUnit"));
		searchVO.setPageSize(propertyService.getInt("pageSize"));

		PaginationInfo pi = new PaginationInfo();
		pi.setCurrentPageNo(searchVO.getPageIndex());
		pi.setRecordCountPerPage(searchVO.getPageUnit());
		pi.setPageSize(searchVO.getPageSize());

		searchVO.setFirstIndex(pi.getFirstRecordIndex());
		searchVO.setLastIndex(pi.getLastRecordIndex());
		searchVO.setRecordCountPerPage(pi.getRecordCountPerPage());

		Map<String, Object> result = myAccountService.selectMyLoginHistory(currentUniqId(), searchVO);
		int totCnt = Integer.parseInt((String) result.get("resultCnt"));
		pi.setTotalRecordCount(totCnt);

		model.addAttribute("resultList", result.get("resultList"));
		model.addAttribute("resultCnt", result.get("resultCnt"));
		model.addAttribute("paginationInfo", pi);
		return "egovframework/com/uss/umt/my/EgovMyLoginHistory";
	}

	// ── 내정보수정 ────────────────────────────────────────────────────

	@RequestMapping("/uss/umt/my/profile.do")
	public String profileForm(ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		if (user == null) {
			return LOGIN_REDIRECT;
		}
		model.addAttribute("loginUser", user);
		model.addAttribute("profile", myAccountService.selectMyProfile(user.getUserSe(), user.getUniqId()));
		return "egovframework/com/uss/umt/my/EgovMyProfile";
	}

	@RequestMapping("/uss/umt/my/saveProfile.do")
	public String saveProfile(@RequestParam(value = "email", required = false) String email,
			@RequestParam(value = "mbtlnum", required = false) String mbtlnum,
			RedirectAttributes ra) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		if (user == null || user.getUniqId() == null) {
			return LOGIN_REDIRECT;
		}
		String back = "redirect:/uss/umt/my/profile.do";

		String em = (email == null) ? "" : email.trim();
		String tel = (mbtlnum == null) ? "" : mbtlnum.trim();

		String err = null;
		if (!em.isEmpty() && !em.matches("[^@\\s]+@[^@\\s]+\\.[^@\\s]{2,}")) {
			err = "이메일 형식이 올바르지 않습니다.";
		} else if (em.length() > 50) {
			err = "이메일은 50자 이내로 입력해 주세요.";
		} else if (!tel.isEmpty() && !tel.matches("[0-9\\-]{9,20}")) {
			err = "휴대전화는 숫자와 - 만으로 9~20자로 입력해 주세요.";
		}
		if (err != null) {
			ra.addFlashAttribute("pfMsg", err);
			ra.addFlashAttribute("pfMsgType", "err");
			return back;
		}

		myAccountService.updateMyProfile(user.getUserSe(), user.getUniqId(), em, tel);
		LOGGER.info("내정보수정: uniqId={}", user.getUniqId());
		ra.addFlashAttribute("pfMsg", "내 정보가 저장되었습니다.");
		ra.addFlashAttribute("pfMsgType", "ok");
		return back;
	}

	// ── 비밀번호 변경 ──────────────────────────────────────────────────

	/** 비밀번호 유효기간(일). Globals.ExpirePwdDay 미설정/0 = 정책 미사용 */
	private int expirePwdDay() {
		String v = EgovProperties.getProperty("Globals.ExpirePwdDay");
		try {
			return (v == null) ? 0 : Integer.parseInt(v.trim());
		} catch (NumberFormatException e) {
			return 0;
		}
	}

	@RequestMapping("/uss/umt/my/password.do")
	public String passwordForm(ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		int expire = expirePwdDay();
		if (user != null && expire > 0) {
			int passed = loginService.selectPassedDayChangePWD(user);
			model.addAttribute("pwdExpireDay", expire);
			model.addAttribute("pwdPassedDay", passed);
			model.addAttribute("pwdDaysLeft", expire - passed);
		}
		return "egovframework/com/uss/umt/my/EgovMyPassword";
	}

	/**
	 * 비밀번호 변경. 본인확인은 세션 기준(솔트=로그인ID, 조회키=ESNTL_ID) —
	 * 표준(umt)의 uniqId request 파라미터 방식은 타인 계정 지정이 가능해 채택하지 않음.
	 * 저장은 umt 표준 updatePassword 재사용 → CHG_PWD_LAST_PNTTM=sysdate 로 기산 리셋.
	 */
	@RequestMapping("/uss/umt/my/savePassword.do")
	public String savePassword(@RequestParam(value = "oldPassword", required = false) String oldPassword,
			@RequestParam(value = "newPassword", required = false) String newPassword,
			@RequestParam(value = "newPassword2", required = false) String newPassword2,
			RedirectAttributes ra) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = currentUser();
		if (user == null || user.getId() == null || user.getUniqId() == null) {
			return LOGIN_REDIRECT;
		}
		String back = "redirect:/uss/umt/my/password.do";

		String oldPw = (oldPassword == null) ? "" : oldPassword;
		String newPw = (newPassword == null) ? "" : newPassword;
		String newPw2 = (newPassword2 == null) ? "" : newPassword2;

		String err = null;
		if (oldPw.isEmpty() || newPw.isEmpty() || newPw2.isEmpty()) {
			err = "모든 항목을 입력해 주세요.";
		} else if (!newPw.equals(newPw2)) {
			err = "새 비밀번호가 서로 일치하지 않습니다.";
		} else if (!newPw.matches("(?=.*[A-Za-z])(?=.*[0-9]).{8,20}")) {
			err = "새 비밀번호는 영문과 숫자를 포함해 8~20자로 입력해 주세요.";
		} else if (newPw.equals(oldPw)) {
			err = "현재 비밀번호와 다른 비밀번호를 입력해 주세요.";
		}

		if (err == null) {
			String stored;
			if ("USR".equals(user.getUserSe())) {
				UserManageVO q = new UserManageVO();
				q.setUniqId(user.getUniqId());
				UserManageVO r = userManageService.selectPassword(q);
				stored = (r == null) ? null : r.getPassword();
			} else {
				MberManageVO q = new MberManageVO();
				q.setUniqId(user.getUniqId());
				MberManageVO r = mberManageService.selectPassword(q);
				stored = (r == null) ? null : r.getPassword();
			}
			if (stored == null || !stored.equals(EgovFileScrty.encryptPassword(oldPw, user.getId()))) {
				err = "현재 비밀번호가 일치하지 않습니다.";
			}
		}

		if (err != null) {
			ra.addFlashAttribute("pwdMsg", err);
			ra.addFlashAttribute("pwdMsgType", "err");
			return back;
		}

		String encNew = EgovFileScrty.encryptPassword(newPw, user.getId());
		if ("USR".equals(user.getUserSe())) {
			UserManageVO u = new UserManageVO();
			u.setUniqId(user.getUniqId());
			u.setPassword(encNew);
			userManageService.updatePassword(u);
		} else {
			MberManageVO m = new MberManageVO();
			m.setUniqId(user.getUniqId());
			m.setPassword(encNew);
			mberManageService.updatePassword(m);
		}
		LOGGER.info("비밀번호 변경: uniqId={}", user.getUniqId());
		ra.addFlashAttribute("pwdMsg", "비밀번호가 변경되었습니다.");
		ra.addFlashAttribute("pwdMsgType", "ok");
		return back;
	}
}
