/*
 * Copyright 2008-2009 MOPAS(MINISTRY OF SECURITY AND PUBLIC ADMINISTRATION).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package egovframework.com.cmm.filter;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;

public class HTMLTagFilter implements Filter{

	@SuppressWarnings("unused")
	private FilterConfig config;

	public void doFilter(ServletRequest request, ServletResponse response,
			FilterChain chain) throws IOException, ServletException {

		HttpServletRequest httpRequest = (HttpServletRequest) request;

		// RLMS 도메인(/rlms/*)은 출력 시점 이스케이프(JSP ideEsc/lvEsc/c:out + ProvViewRenderer.esc)가
		// 정석으로 깔려 있어, 이 입력 치환 래퍼와 겹치면 제목/조문/파일명에 &lt; &#40; 같은 엔티티가
		// 영구 저장되는 데이터 오염이 된다(2026-06-11 실DB 약 6,800행 확인 — 복원은
		// database/rlms_entity_decode_cleanup.sql). RLMS 경로는 원문 그대로 통과시키고
		// eGov 표준 화면(*.do 일반)은 기존 동작을 유지한다.
		String uri = httpRequest.getRequestURI();
		if (uri != null && uri.startsWith(httpRequest.getContextPath() + "/rlms/")) {
			chain.doFilter(request, response);
			return;
		}

		chain.doFilter(new HTMLTagFilterRequestWrapper(httpRequest), response);
	}

	public void init(FilterConfig config) throws ServletException {
		this.config = config;
	}

	public void destroy() {

	}
}
