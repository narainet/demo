/*
 * 물리적 저장 경로: /src/main/java/narainet/law/common/LawTextUtil.java
 */
package narainet.law.common;

import org.springframework.web.util.HtmlUtils;

/**
 * HTMLTagFilter(전역 *.do — XSS 방지)가 파라미터에 넣는 엔티티를 저장 직전에 복원하는 유틸.
 * 게시판(EgovArticleController)의 htmlUnescape 선례와 동일 규칙 —
 * HtmlUtils.htmlUnescape 는 HTML4 만 알아서 &apos;(필터가 ' 에 사용)는 선치환.
 * 출력은 항상 c:out 이스케이프이므로 저장은 원문이 정본(이중 이스케이프 방지).
 */
public final class LawTextUtil {

	private LawTextUtil() {
	}

	public static String unescape(String v) {
		if (v == null) {
			return null;
		}
		return HtmlUtils.htmlUnescape(v.replace("&apos;", "'"));
	}
}
