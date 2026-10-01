/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/common/web/RlmsHomeController.java
 *
 * RLMS 진입점 분기 Controller.
 *
 *   /main.do        — 로그인 성공 후 호출됨 (Spring Security defaultTargetUrl)
 *                     LoginVO.userSe 로 분기:
 *                       USR (COMTNEMPLYRINFO 업무사용자) → /rlms/mgr/dashboard.do
 *                       GNR (COMTNGNRLMBER  일반회원)   → /rlms/index.do
 *                       비인증                          → /uat/uia/egovLoginUsr.do
 *
 *   /rlms/mgr/dashboard.do  — 업무관리자 대시보드 (mgr decorator)
 *   /rlms/index.do           — 사용자 홈 (front decorator)
 *
 *   ※ admin → mgr 명명 변경 (2026-05-12) — 보안 점검 대응.
 */
package narainet.rlms.common.web;

import java.net.URLEncoder;
import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.sym.log.clg.service.EgovLoginLogService;
import egovframework.com.sym.log.clg.service.LoginLog;
import egovframework.com.uat.uap.service.EgovLoginPolicyService;
import egovframework.com.uat.uap.service.LoginPolicyVO;
import egovframework.com.uat.uia.service.EgovLoginService;
import egovframework.com.uss.ion.bnr.service.BannerVO;
import egovframework.com.uss.ion.bnr.service.EgovBannerService;
import egovframework.com.utl.sim.service.EgovClntInfo;
import egovframework.com.utl.slm.EgovHttpSessionBindingListener;
import narainet.rlms.common.mapper.HomeMapper;
import narainet.rlms.common.service.FtGubunService;
import narainet.rlms.common.service.PublicFront;

@Controller
public class RlmsHomeController {

	private static final Logger LOGGER = LoggerFactory.getLogger(RlmsHomeController.class);

	@Resource(name = "ftGubunService")
	private FtGubunService ftGubunService;

	@Resource(name = "homeMapper")
	private HomeMapper homeMapper;

	/** 분류별 열람제한 가드 (TB_CATE_READER) — 홈 집계/최근개정 카드 게이트 */
	@Resource(name = "promReadGuard")
	private narainet.rlms.prom.service.PromReadGuard promReadGuard;

	/** 필수 열람(TB_READ_DUTY) — 홈 "읽어야 할 규정" 카드 */
	@Resource(name = "readDutyService")
	private narainet.rlms.readduty.service.ReadDutyService readDutyService;

	/** 로그인 IP 정책(COMTNLOGINPOLICY) — 로그인정책관리/내 로그인 IP설정 공통 */
	@Resource(name = "egovLoginPolicyService")
	private EgovLoginPolicyService loginPolicyService;

	/** 접속로그(COMTNLOGINLOG) — 내 로그인 내역 데이터원 */
	@Resource(name = "EgovLoginLogService")
	private EgovLoginLogService loginLogService;

	/** 비밀번호 변경 후 경과일(uat/uia 표준) — 유효기간 만료 배너용 */
	@Resource(name = "loginService")
	private EgovLoginService loginService;

	/** 홈 배너(COMTNBANNER) — 운영관리>배너관리 등록분 노출 */
	@Resource(name = "egovBannerService")
	private EgovBannerService bannerService;

	/** 승인대기/내 반려 카운트(배지와 동일 정의) — 관리자 대시보드 스탯 타일 */
	@Resource(name = "promWorkService")
	private narainet.rlms.promwork.service.PromWorkService promWorkService;

	/** 인기 검색어(TB_STATS_KWD) — 관리자 대시보드 패널 */
	@Resource(name = "unifiedSearchService")
	private narainet.rlms.search.service.UnifiedSearchService unifiedSearchService;

	/**
	 * 공지 보드 동적 해석 — 하드코딩 BBS_ID 제거(2026-07-10).
	 * COMTNBBSMASTER USE_AT='Y' AND BBS_NM='공지사항' 최초등록 1건 우선, 없으면 활성 보드 1건.
	 * 실패/부재 = null (홈/대시보드 공지 패널 생략 fail-soft).
	 */
	private String resolveNoticeBbsId() {
		try {
			return homeMapper.selectNoticeBbsId();
		} catch (Exception e) {
			LOGGER.warn("공지 보드 해석 실패(패널 생략): {}", e.getMessage());
			return null;
		}
	}

	/**
	 * 비밀번호 유효기간 경과 안내(Globals.ExpirePwdDay, 0/미설정=정책 미사용).
	 * 조회 실패가 홈 진입을 막지 않도록 삼킨다 — 배너만 생략된다.
	 */
	private void addPwdExpiryInfo(ModelMap model, LoginVO user) {
		int expire;
		String v = EgovProperties.getProperty("Globals.ExpirePwdDay");
		try {
			expire = (v == null) ? 0 : Integer.parseInt(v.trim());
		} catch (NumberFormatException e) {
			expire = 0;
		}
		if (expire <= 0 || user == null) {
			return;
		}
		try {
			int passed = loginService.selectPassedDayChangePWD(user);
			model.addAttribute("pwdExpireDay", expire);
			model.addAttribute("pwdPassedDay", passed);
			model.addAttribute("pwdDaysLeft", expire - passed);
		} catch (Exception e) {
			LOGGER.warn("비밀번호 경과일 조회 실패: {}", e.getMessage());
		}
	}

	/**
	 * 루트(컨텍스트 `/`) 진입점. DispatcherServlet 이 /* 라 welcome-file 이
	 * 동작하지 않으므로 빈 루트 요청을 진입점(/main.do)으로 넘긴다.
	 */
	@RequestMapping("/")
	public String root() {
		return "redirect:/main.do";
	}

	/**
	 * 로그인 후 진입점. userSe 로 관리자/사용자 분기.
	 * Spring Security defaultTargetUrl=/main.do 로 설정.
	 */
	@RequestMapping("/main.do")
	public String main(HttpServletRequest request) {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			// 공개열람 모드(Globals.rlms.publicFront=Y) — 비로그인 첫 화면 = 사용자 홈.
			// 로그인 정책·접속 기록은 로그인 사용자 전용 절차라 건너뛴다.
			if (PublicFront.enabled()) {
				return "redirect:/rlms/index.do";
			}
			return "redirect:/uat/uia/egovLoginUsr.do";
		}

		Object au = EgovUserDetailsHelper.getAuthenticatedUser();
		if (!(au instanceof LoginVO)) {
			return "redirect:/uat/uia/egovLoginUsr.do";
		}
		LoginVO user = (LoginVO) au;

		// ── 로그인 정책 적용 (Spring Security 모드에선 EgovLoginPolicyFilter 미적용 → 로그인 직후 진입점에서 수행) ──
		//    ① IP 제한(LMTT_AT='Y'): 현재 접속 IP 불일치 → 세션 무효화 후 로그인 화면.
		//    ② 중복로그인 방지(DPLCT_PERM_AT='N'): slm 리스너를 세션에 바인딩 — 같은 ID 가 새로 로그인하면
		//       valueBound 가 기존 세션을 무효화(마지막 로그인 우선), 로그아웃/타임아웃 시 valueUnbound 가 등록 해제.
		//       바인딩 attribute 이름 = 로그인ID (리스너 규약). 정책 미설정/오류는 통과(fail-open).
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
			if (session.getAttribute("rlmsLoginLogged") == null) {
				LoginLog log = new LoginLog();
				log.setLoginId(user.getUniqId()); // CONECT_ID = ESNTL_ID
				log.setLoginIp(EgovClntInfo.getClntIP(request));
				log.setLoginMthd("I");
				log.setErrOccrrAt("N");
				log.setErrorCode("");
				loginLogService.logInsertLoginLog(log);
				session.setAttribute("rlmsLoginLogged", "Y");
			}
		} catch (Exception e) {
			LOGGER.warn("로그인 내역 기록 실패(무시): {}", e.getMessage());
		}

		if ("USR".equals(user.getUserSe())) {
			// 업무사용자 → 업무관리자 대시보드
			return "redirect:/rlms/mgr/dashboard.do";
		}
		// GNR / 그 외 → 사용자 홈
		return "redirect:/rlms/index.do";
	}

	/**
	 * 업무관리자 대시보드. mgr decorator 적용.
	 */
	@RequestMapping("/rlms/mgr/dashboard.do")
	public String mgrDashboard(ModelMap model) {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return "redirect:/uat/uia/egovLoginUsr.do";
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();
		// 일반회원(GNR)은 업무관리자 대시보드 대상이 아니다 — /main.do 분기와 동일 기준으로 사용자 홈으로 돌린다.
		// URL 규칙(context-security.xml L1)이 이 주소를 인증 사용자 전체에 열어둔 것은 업무사용자(USR)의
		// 역할 조합(EDITOR/APPROVER/ADMIN/LAW_MGR, 때로 USER 단독)을 URL 층에서 열거하지 않기 위해서다.
		// 그래서 사용자 구분 확인은 여기서 한다 (2026-07-29 — GNR 로그인 후 주소 직접 입력 시 노출되던 결함).
		if (user == null || !"USR".equals(user.getUserSe())) {
			return "redirect:/rlms/index.do";
		}
		model.addAttribute("loginUser", user);
		addPwdExpiryInfo(model, user);

		// ── 운영 현황 위젯 — 소스별 실패는 해당 위젯만 생략(대시보드 진입 불차단) ──
		try {
			model.addAttribute("dash", homeMapper.selectDashCounts());
			model.addAttribute("dashPending", homeMapper.selectDashPendingWorks(5));
			model.addAttribute("dashRecentWorks", homeMapper.selectDashRecentWorks(5));
		} catch (Exception e) {
			LOGGER.warn("대시보드 운영현황 조회 실패(생략): {}", e.getMessage());
		}
		try {
			model.addAttribute("pendingCnt", promWorkService.countPendingApproval());
			model.addAttribute("myRejectedCnt", promWorkService.countMyRejected(user != null ? user.getId() : null));
		} catch (Exception e) {
			LOGGER.warn("대시보드 승인 카운트 조회 실패(생략): {}", e.getMessage());
		}
		// 작성자 관점 — 내 요청 현황(심사중/반려+사유/최근 승인). 요청 이력 없으면 JSP가 패널 숨김.
		try {
			String myId = user != null ? user.getId() : null;
			model.addAttribute("myPendingCnt", homeMapper.selectDashMyPendingCnt(myId));
			model.addAttribute("dashMyWorks", homeMapper.selectDashMyWorks(myId, 5));
		} catch (Exception e) {
			LOGGER.warn("대시보드 내 요청 현황 조회 실패(생략): {}", e.getMessage());
		}
		try {
			model.addAttribute("popularKwds", unifiedSearchService.popularKeywords(30, 10));
		} catch (Exception e) {
			LOGGER.warn("대시보드 인기 검색어 조회 실패(생략): {}", e.getMessage());
		}
		try {
			String noticeBbsId = resolveNoticeBbsId();
			if (noticeBbsId != null) {
				model.addAttribute("notices", homeMapper.selectRecentNotices(noticeBbsId, 5));
				model.addAttribute("noticeBbsId", noticeBbsId);
			}
		} catch (Exception e) {
			LOGGER.warn("대시보드 공지 조회 실패(생략): {}", e.getMessage());
		}
		return "rlms/home/mgrDashboard";
	}

	/**
	 * 사용자 홈. front decorator 적용.
	 */
	@RequestMapping("/rlms/index.do")
	public String userHome(ModelMap model) {
		// 공개열람 모드면 익명도 진입 — user=null 로 흘러 개인화 카드(필수열람/즐겨찾기 소식)만 빠진다
		if (!PublicFront.viewAllowed()) {
			return "redirect:/uat/uia/egovLoginUsr.do";
		}
		LoginVO user = (LoginVO) EgovUserDetailsHelper.getAuthenticatedUser();   // 익명(공개열람) = null
		model.addAttribute("loginUser", user);
		addPwdExpiryInfo(model, user);

		// 구분 라벨(정본 = ccm 'SGUBUN') — 검색 콘솔/집계/카드 공용
		model.addAttribute("gubunList", ftGubunService.gubunList());

		// 분류별 열람제한 — 집계/최근개정 카드에서 차단 규정 제외 (면제역할은 미적용)
		boolean readGate = promReadGuard.gateNeeded();
		String readerEsntlId = promReadGuard.readerEsntlId();
		String readerOrgnztId = promReadGuard.readerOrgnztId();

		// 구분별 현행 보유 건수 — 키 = SGUBUN_ID 코드 그대로(gubunList 의 g.code 와 정합, 번호 파싱 폐기 2026-07-10)
		Map<String, Object> gubunCounts = new HashMap<>();
		for (Map<String, Object> r : homeMapper.selectGubunCounts(readGate, readerEsntlId, readerOrgnztId)) {
			Object sg = r.get("sgubunId");
			if (sg == null) {
				continue;
			}
			gubunCounts.put(String.valueOf(sg), r.get("cnt"));
		}
		model.addAttribute("gubunCounts", gubunCounts);
		model.addAttribute("lastInsDt", homeMapper.selectLastInsDt());
		model.addAttribute("recentProms", homeMapper.selectRecentProms(6, readGate, readerEsntlId, readerOrgnztId));

		// 읽어야 할 규정(필수 열람) — 내가 대상인 미숙지 지정 top 6, 기한 임박순.
		// 숙지 확인([숙지 확인] 버튼) 시 사라진다. 실패해도 홈 진입은 막지 않는다. 익명(공개열람)은 대상 아님.
		if (user != null) {
			try {
				model.addAttribute("readDuties",
						readDutyService.selectMyDuties(user.getUniqId(), user.getOrgnztId(), user.getUserSe(), 6));
			} catch (Exception e) {
				LOGGER.warn("필수 열람 목록 조회 실패(생략): {}", e.getMessage());
			}

			// 즐겨찾기 규정 개정 소식 — 확인(뷰어 열람) 전까지 노출. 실패해도 홈 진입은 막지 않는다.
			try {
				model.addAttribute("favorRevised",
						homeMapper.selectFavorRevisedProms(user.getUniqId(), 6, readGate, readerEsntlId, readerOrgnztId));
			} catch (Exception e) {
				LOGGER.warn("즐겨찾기 개정 소식 조회 실패(생략): {}", e.getMessage());
			}
		}

		// 공지 패널 — 동적 해석 + fail-soft(조회 예외가 홈 진입을 막지 않게, 2026-07-10 500 리스크 해소)
		try {
			String noticeBbsId = resolveNoticeBbsId();
			if (noticeBbsId != null) {
				model.addAttribute("notices", homeMapper.selectRecentNotices(noticeBbsId, 6));
				model.addAttribute("noticeBbsId", noticeBbsId);
			}
		} catch (Exception e) {
			LOGGER.warn("홈 공지 조회 실패(생략): {}", e.getMessage());
		}

		// 홈 배너(REFLCT_AT='Y' 정렬순) — 실패해도 홈 진입은 막지 않는다
		try {
			model.addAttribute("banners", bannerService.selectBannerResult(new BannerVO()));
		} catch (Exception e) {
			LOGGER.warn("홈 배너 조회 실패: {}", e.getMessage());
		}

		return "rlms/home/userHome";
	}
}
