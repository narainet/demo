package egovframework.com.cmm.util;

import javax.servlet.http.HttpServletRequest;

import org.jsoup.Jsoup;
import org.jsoup.safety.Safelist;
import org.springframework.web.util.HtmlUtils;

/**
 * CKEditor 리치텍스트 본문 서버측 새니타이저.
 *
 * <p>배경: {@code HTMLTagFilter} 가 모든 {@code *.do} 요청 파라미터의
 * {@code < > " ( )} 를 입력 시점에 엔티티로 치환한다(/rlms/* 만 우회). 그래서 게시판·팝업
 * 등 {@code /cop/*}·{@code /uss/*} 경로로 들어온 CKEditor HTML 은 {@code &lt;img&gt;} 처럼
 * 깨져 저장되고, 상세화면(escapeXml="false")에서 태그가 문자열로 노출됐다.</p>
 *
 * <p>단순히 필터를 우회시켜 HTML 을 살리면 저장형 XSS 가 열린다 — 기존 게시판 가드
 * {@code unscript()} 는 script/object/applet/embed/form 여는 태그만 지우고
 * {@code onerror=}·{@code javascript:} 같은 속성/URL 벡터는 통과시키기 때문이다.
 * 따라서 필터가 남긴 엔티티를 되돌린 뒤, jsoup allowlist 로 태그·속성·URL 스킴을 강제한다.</p>
 *
 * <p>안전성은 전적으로 jsoup {@link Safelist#relaxed()} 에 의존한다:
 * 허용 태그(a,b,strong,em,img,table,ul,ol,li,p,br,h1~h6 …)만 남기고 그 외 속성을
 * 전부 제거(→ on* 이벤트 핸들러 삭제)하며, a[href]·img[src] 에 http/https/mailto 프로토콜을
 * 강제한다(→ javascript:/data:/vbscript: 차단). 디코드가 어긋나도 jsoup 출력은 항상 XSS-safe 다.</p>
 *
 * <p>이미지 URL 은 컨텍스트 상대경로({@code /utl/web/imageSrc.do?...})라, base URI 없이
 * clean 하면 상대 src 가 통째로 제거된다. 요청 스킴+호스트를 base 로 넘겨 절대화하면
 * 우리 이미지는 살고 javascript:/data: 는 여전히 걸러진다.</p>
 */
public final class RichTextSanitizer {

	private RichTextSanitizer() {
	}

	/**
	 * 요청 컨텍스트를 base URI 로 사용해 리치텍스트를 새니타이즈한다.
	 *
	 * @param raw     HTMLTagFilter 를 거쳐 엔티티 치환된 CKEditor 본문
	 * @param request 현재 요청(스킴+호스트+포트를 상대 src 절대화 base 로 사용)
	 * @return XSS-safe HTML (null 입력 시 빈 문자열)
	 */
	public static String clean(String raw, HttpServletRequest request) {
		return clean(raw, baseUri(request));
	}

	/**
	 * base URI 를 직접 지정하는 변형.
	 *
	 * @param raw     엔티티 치환된 CKEditor 본문
	 * @param baseUri 상대 링크/이미지 절대화 기준(예: "http://host:port"). 비면 상대 src 는 제거된다.
	 * @return XSS-safe HTML (null 입력 시 빈 문자열)
	 */
	public static String clean(String raw, String baseUri) {
		if (raw == null || raw.trim().isEmpty()) {
			return "";
		}
		// 1) HTMLTagFilter 가 넣은 &lt; &gt; &quot; &#40; &#41; 등을 실제 문자로 복원.
		String decoded = HtmlUtils.htmlUnescape(raw);
		// 2) allowlist 새니타이즈 — 여기서 XSS 안전성이 확정된다.
		Safelist safelist = Safelist.relaxed().addAttributes("img", "alt", "title", "width", "height");
		return Jsoup.clean(decoded, baseUri == null ? "" : baseUri, safelist);
	}

	/** 요청에서 스킴+호스트(+비표준 포트)를 조립. 상대 이미지 src 절대화 base 로 쓴다. */
	private static String baseUri(HttpServletRequest request) {
		if (request == null) {
			return "";
		}
		String scheme = request.getScheme();
		String host = request.getServerName();
		int port = request.getServerPort();
		StringBuilder sb = new StringBuilder();
		sb.append(scheme).append("://").append(host);
		boolean defaultPort = ("http".equals(scheme) && port == 80) || ("https".equals(scheme) && port == 443);
		if (port > 0 && !defaultPort) {
			sb.append(':').append(port);
		}
		return sb.toString();
	}
}
