/*
 * 물리적 저장 경로: /src/main/java/narainet/law/home/web/LawHomeController.java
 *
 * 송무 홈 Controller — 송무관리 GNB 랜딩 대시보드 (LAW_MODULE_DESIGN.md §7.0).
 *   P1: 요약 카드 4종(진행중 사건/이번 달 신규/미처리 의뢰/승인대기 문서).
 *   P4: 오늘·이번 주 기일 그리드 + 최근 등록 사건 5건 확장.
 */
package narainet.law.home.web;

import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.law.home.service.LawHomeService;

@Controller
public class LawHomeController {

	private static final String LOGIN_REDIRECT = "redirect:/uat/uia/egovLoginUsr.do";

	@Resource(name = "lawHomeService")
	private LawHomeService lawHomeService;

	@RequestMapping("/law/home/main.do")
	public String main(ModelMap model) throws Exception {
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated())) {
			return LOGIN_REDIRECT;
		}
		model.addAllAttributes(lawHomeService.getHomeData());
		return "law/home/main";
	}
}
