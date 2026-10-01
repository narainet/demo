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
 *  - /index.do               : 2026-08-04 포탈 모드부터 LawMainController 소관(포탈 공개 메인).
 *                              표준 잔여 참조(onepass 등)가 /index.do 로 와도 포탈(로그인 상태 헤더) 또는
 *                              관리기능 전용 모드의 /main.do 재위임으로 자연 수렴되어 별칭이 불필요해짐.
 *  - /egovCSRFAccessDenied.do: context-security.xml csrfAccessDeniedUrl
 */
@Controller
public class EgovComIndexController {

	// context-security.xml 설정
	// csrf="true"인 경우 csrf Token이 없는경우 이동하는 페이지
	// csrfAccessDeniedUrl="/egovCSRFAccessDenied.do"
	@RequestMapping("/egovCSRFAccessDenied.do")
	public String egovCSRFAccessDenied() {
		return "egovframework/com/cmm/error/csrfAccessDenied";
	}
}
