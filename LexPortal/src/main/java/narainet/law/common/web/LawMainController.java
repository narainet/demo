/*
 * 물리적 저장 경로: /src/main/java/narainet/law/common/web/LawMainController.java
 *
 * LexPortal(송무관리 단독) 진입점 분기 Controller — 단독 제품 전용(통합본 RLMS 에는 없음).
 *
 *   /index.do      — 포탈 공개 메인(변호사 사무실 홈페이지성 화면, 2026-08-04).
 *                     Globals.law.portalMain=Y(기본) 이면 비로그인 열람 허용, N(관리기능만) 이면
 *                     /main.do 로 재위임해 종전대로 로그인이 첫 화면이 된다.
 *
 *   /main.do        — 로그인 성공 후 호출됨 (Spring Security defaultTargetUrl)
 *                     통합본 RlmsHomeController.main() 의 로그인 정책/접속기록 로직을 승계.
 *                     역할별 랜딩: ADMIN/LAW_MGR=대시보드(/law/index.do), 그 외=포탈(포탈 모드) 또는 나의 소송의뢰.
 *
 *   /rlms/home.do, /rlms/mgr/dashboard.do
 *                   — 공통 베이스(데코레이터·표준 JSP)가 참조하는 통합본 URL 호환 별칭.
 *                     공통 베이스 파일을 제품별로 고치지 않기 위해 URL 을 유지하고 /main.do 로 넘긴다.
 *
 *   /rlms/prom/buseoListJson.do
 *                   — 사용자관리 4화면(EgovMber/UserInsert·SelectUpdt)의 부서 선택 모달 데이터원.
 *                     통합본에선 PromEditorController 소관이나 단독 제품엔 prom 이 없어 여기서 제공.
 *                     응답 계약(orgnztId/buseoNm/fullNm/buseoNo)은 통합본과 동일.
 */
package narainet.law.common.web;

import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.sym.log.clg.service.EgovLoginLogService;
import egovframework.com.sym.log.clg.service.LoginLog;
import egovframework.com.uat.uap.service.EgovLoginPolicyService;
import egovframework.com.uat.uap.service.LoginPolicyVO;
import egovframework.com.utl.sim.service.EgovClntInfo;
import egovframework.com.utl.slm.EgovHttpSessionBindingListener;
import narainet.law.common.mapper.LawMainMapper;

@Controller
public class LawMainController {

	private static final Logger LOGGER = LoggerFactory.getLogger(LawMainController.class);

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	/** 로그인 IP 정책(COMTNLOGINPOLICY) — 로그인정책관리/내 로그인 IP설정 공통 */
	@Resource(name = "egovLoginPolicyService")
	private EgovLoginPolicyService loginPolicyService;

	/** 접속로그(COMTNLOGINLOG) — 내 로그인 내역 데이터원 */
	@Resource(name = "EgovLoginLogService")
	private EgovLoginLogService loginLogService;

	@Resource(name = "lawMainMapper")
	private LawMainMapper lawMainMapper;

	@RequestMapping("/")
	public String root() {
		return "redirect:/index.do";
	}

	/**
	 * 포탈 공개 메인 — 변호사 사무실 소개(홈페이지성) 화면. 비로그인 열람 허용(보안 L1 ANONYMOUS).
	 * Globals.law.portalMain=N(관리기능만) 이면 /main.do 로 넘겨 종전대로 로그인이 첫 화면이 된다.
	 * 설정은 기동 후 최초 1회 판정·고정 — 값 변경은 서버 재기동 후 반영(2026-08-04 확정, RegNex PublicFront 와 동일 정책).
	 */
	@RequestMapping("/index.do")
	public String portal(ModelMap model) {
		if (!isPortalMain()) {
			return "redirect:/main.do";
		}
		boolean authed = Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated());
		model.addAttribute("portalAuth", Boolean.valueOf(authed));
		if (authed) {
			Object au = EgovUserDetailsHelper.getAuthenticatedUser();
			if (au instanceof LoginVO) {
				model.addAttribute("portalUserName", ((LoginVO) au).getName());
			}
			boolean staff = isLawStaff();
			model.addAttribute("portalWorkUrl", staff ? "/law/index.do" : "/law/reqUser/list.do");
			model.addAttribute("portalWorkLabel", staff ? "대시보드" : "나의 소송의뢰");
		}
		return "law/portal/main";
	}

	/** 최초 판정 후 고정(재기동 시 초기화) — 매호출 properties 재독 폐기(2026-08-04) */
	private static volatile Boolean PORTAL_MAIN;

	/** 포탈 모드 여부 — Globals.law.portalMain. 기본 Y(미설정·공백 포함), 'N' 일 때만 관리기능 전용. */
	private boolean isPortalMain() {
		Boolean pm = PORTAL_MAIN;
		if (pm == null) {
			try {
				String v = EgovProperties.getProperty("Globals.law.portalMain");
				pm = Boolean.valueOf(v == null || v.trim().isEmpty() || !"N".equalsIgnoreCase(v.trim()));
			} catch (Exception e) {
				pm = Boolean.TRUE;
			}
			PORTAL_MAIN = pm;
		}
		return pm.booleanValue();
	}

	/** 송무 실무 역할(ADMIN/LAW_MGR) 여부 — 로그인 후 랜딩 분기용 */
	private boolean isLawStaff() {
		try {
			List<String> authorities = EgovUserDetailsHelper.getAuthorities();
			return authorities != null
					&& (authorities.contains("ROLE_ADMIN") || authorities.contains("ROLE_LAW_MGR"));
		} catch (Exception e) {
			return false;
		}
	}

	/**
	 * 로그인 후 진입점 — 로그인 정책·접속기록 처리 후 역할별 랜딩으로 분기한다.
	 * (송무 단독 제품의 계정은 업무사용자(USR) 중심 — GNR 도 동일 목적지로 보내고
	 *  화면 인가는 메뉴 파생(L6)/폴백(L7)이 판정한다.)
	 */
	@RequestMapping("/main.do")
	public String main(HttpServletRequest request) {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}

		Object au = EgovUserDetailsHelper.getAuthenticatedUser();
		if (!(au instanceof LoginVO)) {
			return LOGIN_REDIRECT;
		}
		LoginVO user = (LoginVO) au;

		// ── 로그인 정책 적용 (Spring Security 모드에선 EgovLoginPolicyFilter 미적용 → 로그인 직후 진입점에서 수행) ──
		//    ① IP 제한(LMTT_AT='Y'): 현재 접속 IP 불일치 → 세션 무효화 후 로그인 화면.
		//    ② 중복로그인 방지(DPLCT_PERM_AT='N'): slm 리스너를 세션에 바인딩 — 같은 ID 가 새로 로그인하면
		//       valueBound 가 기존 세션을 무효화(마지막 로그인 우선). 정책 미설정/오류는 통과(fail-open).
		try {
			String currentIp = EgovClntInfo.getClntIP(request);
			LoginPolicyVO pvo = new LoginPolicyVO();
			pvo.setEmplyrId(user.getId());
			LoginPolicyVO policy = loginPolicyService.selectLoginPolicy(pvo);
			if (policy != null && "Y".equals(policy.getLmttAt())
					&& policy.getIpInfo() != null && !policy.getIpInfo().equals(currentIp)) {
				HttpSession s = request.getSession(false);
				if (s != null) {
					s.invalidate();
				}
				return "redirect:/uat/uia/egovLoginUsr.do?loginMessage="
						+ URLEncoder.encode("허용되지 않은 IP에서의 접속입니다.", "UTF-8");
			}
			if (policy != null && "N".equals(policy.getDplctPermAt())) {
				HttpSession session = request.getSession();
				if (session.getAttribute(user.getId()) == null) {
					session.setAttribute(user.getId(), new EgovHttpSessionBindingListener());
				}
			}
		} catch (Exception e) {
			LOGGER.warn("로그인 정책 확인 실패(통과 처리): {}", e.getMessage());
		}

		// ── 로그인 내역 기록(세션당 1회) — Spring Security 로그인은 actionMain AOP 미경유라 여기서 기록 ──
		try {
			HttpSession session = request.getSession();
			if (session.getAttribute("lawLoginLogged") == null) {
				LoginLog log = new LoginLog();
				log.setLoginId(user.getUniqId()); // CONECT_ID = ESNTL_ID
				log.setLoginIp(EgovClntInfo.getClntIP(request));
				log.setLoginMthd("I");
				log.setErrOccrrAt("N");
				log.setErrorCode("");
				loginLogService.logInsertLoginLog(log);
				session.setAttribute("lawLoginLogged", "Y");
			}
		} catch (Exception e) {
			LOGGER.warn("로그인 내역 기록 실패(무시): {}", e.getMessage());
		}

		// 역할별 랜딩 — 송무 실무(ADMIN/LAW_MGR)=대시보드, 그 외(의뢰인 USER 등)=포탈 또는 나의 소송의뢰.
		// 종전엔 전원 /law/home 수렴이라 USER/APPROVER 가 로그인 직후 403 랜딩이 되는 결함이 있었다(2026-08-04 해소).
		if (isLawStaff()) {
			return "redirect:/law/index.do";
		}
		return isPortalMain() ? "redirect:/index.do" : "redirect:/law/reqUser/list.do";
	}

	/** 통합본 URL 호환 별칭 — 공통 베이스(데코레이터 홈 링크 등)가 참조 */
	@RequestMapping({"/rlms/home.do", "/rlms/mgr/dashboard.do"})
	public String integratedAlias() {
		return "redirect:/main.do";
	}

	/**
	 * 부서 목록 JSON — 통합본 PromEditorController.buseoListJson 과 동일 계약.
	 * 데이터원 = 표준 COMTNORGNZTINFO (rlms 테이블 무접근).
	 */
	@RequestMapping("/rlms/prom/buseoListJson.do")
	@ResponseBody
	public List<Map<String, Object>> buseoListJson(
			@RequestParam(value = "keyword", required = false) String keyword) {

		List<Map<String, Object>> out = new ArrayList<>();
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return out;
		}
		try {
			List<Map<String, Object>> list = lawMainMapper.selectBuseoList(
					(keyword == null || keyword.trim().isEmpty()) ? null : keyword.trim());
			if (list == null) {
				return out;
			}
			int limit = Math.min(list.size(), 500);   // 전체 부서 포괄 — 통합본과 동일 한도
			for (int i = 0; i < limit; i++) {
				out.add(list.get(i));
			}
		} catch (Exception ignore) { /* 빈 리스트 반환 */ }
		return out;
	}
}
