package egovframework.com.cmm.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * eGov 템플릿 진입/오류 URL 잔여 매핑.
 *
 * 원본(공통컴포넌트 개발용 3분할 index — EgovTop/EgovLeft/EgovContent/EgovBottom +
 * IncludedInfo 스캐너)은 원 주석부터 "실 운영 시 삭제" 대상이라 RLMS 에서 제거함(2026-07-08).
 * RLMS 진입점 정본 = RlmsHomeController(/main.do → userSe 분기).
 *
 *  - /index.do               : 표준 잔여 참조(onepass, 로그인세션체크 JSP)와
 *                              표준 컨트롤러들의 미인증 fallback 뷰("index" → index.jsp)용 별칭 → /main.do
 *  - /egovCSRFAccessDenied.do: context-security.xml csrfAccessDeniedUrl
 */
@Controller
public class EgovComIndexController {

	@RequestMapping("/index.do")
	public String index() {
		return "redirect:/main.do";
	}

	// context-security.xml 설정
	// csrf="true"인 경우 csrf Token이 없는경우 이동하는 페이지
	// csrfAccessDeniedUrl="/egovCSRFAccessDenied.do"
	@RequestMapping("/egovCSRFAccessDenied.do")
	public String egovCSRFAccessDenied() {
		return "egovframework/com/cmm/error/csrfAccessDenied";
	}
}
