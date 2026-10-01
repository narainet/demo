/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/common/filter/PublicFrontGateFilter.java
 *
 * 공개열람 모드 게이트 필터 — 설정 N(비공개)일 때 익명 접근을 로그인으로 되돌리는 안전망.
 *
 *   · URL 인가(context-security.xml)는 front 열람 축을 ROLE_ANONYMOUS 로 "상시 개방"해 둔다.
 *     Y/N 전환은 프로퍼티 수정 후 서버 재기동으로 반영(PublicFront 가 기동 후 1회 판정·고정).
 *   · 공개열람 N: 익명 요청은 원래부터 익명이던 URL(로그인/브랜드 이미지)만 남기고 전부
 *     로그인 화면으로 리다이렉트 → 종전(비공개) 동작과 동일해진다.
 *   · 공개열람 Y: 필터 무동작 — 개별 컨트롤러 가드(PublicFront.viewAllowed)와 인가 SQL 이 방어.
 *   · 자체 로그인 가드가 없는 열람 JSON(treeJson/treeJsonDept/historyJson/gaejungJson)도
 *     이 필터가 N 모드에서 확실히 닫는다(인가 개방과의 이중 방어).
 *   · springSecurityFilterChain 뒤에 등록(EgovWebApplicationInitializer) — 인가에서 막힌 요청
 *     (개인화·관리 URL 의 익명 접근)은 시큐리티 entry point 가 먼저 처리하므로 여기 오지 않는다.
 */
package narainet.rlms.common.filter;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import egovframework.com.cmm.util.EgovUserDetailsHelper;
import narainet.rlms.common.service.PublicFront;

public class PublicFrontGateFilter implements Filter {

	/** 공개열람 모드와 무관하게 익명에 열려 있는 경로(로그인·브랜드 이미지) — 컨텍스트 제외 경로 기준 */
	private static boolean alwaysAnonymous(String path) {
		return path.startsWith("/uat/uia/")
				|| path.equals("/cmm/brand/logo.do")
				|| path.equals("/cmm/brand/favicon.do");
	}

	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
			throws IOException, ServletException {
		HttpServletRequest req = (HttpServletRequest) request;
		if (!Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated()) && !PublicFront.enabled()) {
			String path = req.getRequestURI().substring(req.getContextPath().length());
			if (!alwaysAnonymous(path)) {
				((HttpServletResponse) response).sendRedirect(req.getContextPath() + "/uat/uia/egovLoginUsr.do");
				return;
			}
		}
		chain.doFilter(request, response);
	}

	@Override
	public void init(FilterConfig filterConfig) {
	}

	@Override
	public void destroy() {
	}
}
