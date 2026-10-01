package egovframework.com.cmm.util;

import java.io.File;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * @Class Name : EgovLayoutResolver.java
 * @Description : 요청 URL → 레이아웃(셸) 이름 결정. SiteMesh 2 PageFilter + decorators.xml 을 대체한다.
 *
 * <pre>
 * SiteMesh 는 "응답을 버퍼에 받아 파싱한 뒤 데코레이터로 forward" 하는 구조라
 * Servlet 6.0(Tomcat 10.1+) 에서 응답이 빈 채로 커밋된다(2026-08-06 실측: 전 버전 동일 실패).
 * 그래서 데코레이션을 응답 필터가 아니라 JSP 태그파일(/WEB-INF/tags/layout.tag)로 옮겼고,
 * 이 클래스는 그 태그파일이 "어느 셸로 감쌀지"만 정해 준다. 버퍼링·dispatch 가 없다.
 *
 * 매칭 규칙은 SiteMesh 2 PathMapper 와 동일하게 유지한다(화면별 셸이 바뀌지 않도록).
 *   1) 정확 일치 패턴 우선
 *   2) 없으면 와일드카드 패턴 중 "가장 긴 패턴" 승리 (예: /uss/olh/faq/selectFaqList.do 가 /uss/* 를 이김)
 *   3) 그래도 없으면 default 셸
 * SiteMesh 와 다른 점은 excludes 가 없다는 것 — 이제는 JSP 가 &lt;lay:layout&gt; 을 쓴 화면만
 * 데코레이트되므로, 정적 리소스·JSON 응답은 애초에 이 경로를 타지 않는다.
 *
 * 매칭 대상 경로는 "컨텍스트 경로를 뺀 원 요청 URI" 다. JSP 안에서 호출되는 시점에는 이미
 * DispatcherServlet 이 /WEB-INF/jsp/... 로 forward 한 뒤라 getServletPath() 가 JSP 경로를
 * 가리키므로, forward 전 원본을 담고 있는 FORWARD_REQUEST_URI 를 우선 본다.
 * </pre>
 *
 * @author RLMS
 * @since 2026.08.07
 */
public class EgovLayoutResolver {

	private static final Logger LOG = LoggerFactory.getLogger(EgovLayoutResolver.class);

	/** 레이아웃 정의 파일 (웹앱 상대경로) */
	public static final String CONFIG_PATH = "/WEB-INF/layouts.xml";

	/** 설정 파일을 읽지 못했을 때 쓰는 최후 폴백 셸 */
	private static final String FALLBACK = "plain";

	/** 설정 파일 변경 감지 주기(ms) — 개발 중 layouts.xml 수정이 재기동 없이 반영되게 한다. */
	private static final long RECHECK_INTERVAL = 2000L;

	/** 불변 스냅샷. 설정 리로드는 이 객체를 통째로 교체하는 방식이라 동기화가 필요 없다. */
	private static volatile Config config;

	private static volatile long lastCheckedAt;

	private EgovLayoutResolver() {
	}

	/**
	 * 현재 요청에 적용할 셸 이름을 돌려준다.
	 *
	 * @param request 현재 요청
	 * @return "mgr" / "front" / "plain" / "popup" 등 layouts.xml 에 정의된 이름
	 */
	public static String resolve(HttpServletRequest request) {
		if (request == null) {
			return FALLBACK;
		}
		return resolve(request, requestPath(request));
	}

	/**
	 * 경로를 직접 지정해 셸을 구한다(테스트·강제 지정용).
	 *
	 * @param request 서블릿 컨텍스트 취득용
	 * @param path 컨텍스트 경로를 뺀 요청 경로
	 * @return 셸 이름
	 */
	public static String resolve(HttpServletRequest request, String path) {
		Config cfg = configOf(request);
		if (cfg == null) {
			return FALLBACK;
		}
		return cfg.match(path);
	}

	/**
	 * forward 이전의 원 요청 URI(컨텍스트 경로 포함).
	 *
	 * <pre>
	 * ⛔ JSP 안에서 request.getRequestURI() 를 그냥 부르면 안 되는 이유:
	 *    DispatcherServlet 이 /WEB-INF/jsp/... 로 forward 한 뒤라 JSP 경로가 돌아온다.
	 *    (SiteMesh 시절엔 데코레이터를 include 로 붙여서 원 URI 가 유지됐다 — 그 전제가 깨졌다.)
	 *    forward 시 컨테이너가 넣어 주는 FORWARD_REQUEST_URI 가 원본이고,
	 *    중첩 forward 여도 최초 요청 값이 보존된다(Servlet 스펙 9.4.2).
	 * </pre>
	 *
	 * @param request 현재 요청
	 * @return 예) /RLMS/rlms/prom/preview.do
	 */
	public static String originalRequestUri(HttpServletRequest request) {
		String uri = (String) request.getAttribute(RequestDispatcher.FORWARD_REQUEST_URI);
		if (uri == null || uri.length() == 0) {
			uri = request.getRequestURI();
		}
		return uri == null ? "" : uri;
	}

	/**
	 * forward 이전의 원 쿼리스트링.
	 *
	 * <p>forward 대상 경로에 쿼리가 없을 때 getQueryString() 이 원본을 유지하는지는 컨테이너 구현에
	 * 달려 있어, 스펙이 보장하는 FORWARD_QUERY_STRING 을 우선한다.</p>
	 *
	 * @param request 현재 요청
	 * @return 쿼리스트링. 없으면 null
	 */
	public static String originalQueryString(HttpServletRequest request) {
		String q = (String) request.getAttribute(RequestDispatcher.FORWARD_QUERY_STRING);
		if (q == null) {
			q = request.getQueryString();
		}
		return q;
	}

	/**
	 * forward 이전의 원 요청 경로(컨텍스트 경로 제외).
	 *
	 * @param request 현재 요청
	 * @return 예) /rlms/prom/preview.do
	 */
	public static String requestPath(HttpServletRequest request) {
		String uri = originalRequestUri(request);
		if (uri.length() == 0) {
			return "/";
		}
		String ctx = request.getContextPath();
		if (ctx != null && ctx.length() > 0 && uri.startsWith(ctx)) {
			uri = uri.substring(ctx.length());
		}
		return uri.length() == 0 ? "/" : uri;
	}

	// ----------------------------------------------------------------- 설정 적재

	private static Config configOf(HttpServletRequest request) {
		Config cur = config;
		long now = System.currentTimeMillis();
		if (cur != null && now - lastCheckedAt < RECHECK_INTERVAL) {
			return cur;
		}

		ServletContext sc = request.getServletContext();
		if (sc == null) {
			return cur;
		}
		lastCheckedAt = now;

		long stamp = stampOf(sc);
		if (cur != null && cur.stamp == stamp) {
			return cur;
		}

		Config loaded = load(sc, stamp);
		if (loaded != null) {
			config = loaded;
			return loaded;
		}
		return cur;
	}

	/** 설정 파일의 최종 수정시각. 실경로를 못 얻으면 0 (= 1회 적재 후 고정). */
	private static long stampOf(ServletContext sc) {
		String real = sc.getRealPath(CONFIG_PATH);
		if (real == null) {
			return 0L;
		}
		File f = new File(real);
		return f.exists() ? f.lastModified() : 0L;
	}

	private static Config load(ServletContext sc, long stamp) {
		InputStream in = null;
		try {
			in = sc.getResourceAsStream(CONFIG_PATH);
			if (in == null) {
				// ⛔ 조용히 넘기면 안 된다 — 설정을 못 읽으면 전 화면이 plain 셸로 떨어져
				//    "GNB·LNB 가 통째로 사라진" 상태가 되는데, 예외가 없어 원인 추적이 어렵다.
				//    (2026-08-07 실제로 layouts.xml 이 깨진 XML 이라 전 화면 plain 으로 뜬 사고가 있었다.)
				LOG.error("{} 를 찾을 수 없다 — 전 화면이 '{}' 셸로 폴백한다.", CONFIG_PATH, FALLBACK);
				return null;
			}
			DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
			// XXE 차단 — 설정 파일이 신뢰 대상이어도 파서 기본값에 기대지 않는다.
			dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
			dbf.setExpandEntityReferences(false);
			DocumentBuilder db = dbf.newDocumentBuilder();
			Element root = db.parse(in).getDocumentElement();

			String def = attr(root, "default", FALLBACK);
			// LinkedHashMap — 같은 패턴이 두 번 나오면 SiteMesh 와 동일하게 나중 것이 이긴다.
			Map<String, String> exact = new LinkedHashMap<String, String>();
			List<Wild> wild = new ArrayList<Wild>();

			NodeList layouts = root.getElementsByTagName("layout");
			for (int i = 0; i < layouts.getLength(); i++) {
				Element layout = (Element) layouts.item(i);
				String name = attr(layout, "name", null);
				if (name == null) {
					continue;
				}
				NodeList pats = layout.getElementsByTagName("pattern");
				for (int j = 0; j < pats.getLength(); j++) {
					String p = text(pats.item(j));
					if (p.length() == 0) {
						continue;
					}
					if (p.indexOf('*') < 0 && p.indexOf('?') < 0) {
						exact.put(p, name);
					} else {
						wild.add(new Wild(p, name));
					}
				}
			}
			return new Config(def, exact, wild, stamp);
		} catch (Exception e) {
			// 직전 설정이 있으면 그것을 계속 쓰고, 최초 적재 실패면 전 화면이 FALLBACK 으로 떨어진다.
			// 어느 쪽이든 사람이 알아야 하는 오류다.
			LOG.error("{} 적재 실패 — {}", CONFIG_PATH,
				(config == null ? "전 화면이 '" + FALLBACK + "' 셸로 폴백한다" : "직전 설정을 유지한다"), e);
			return null;
		} finally {
			EgovResourceCloseHelper.close(in);
		}
	}

	private static String attr(Element el, String name, String def) {
		String v = el.getAttribute(name);
		return (v == null || v.trim().length() == 0) ? def : v.trim();
	}

	private static String text(Node n) {
		String v = n.getTextContent();
		return v == null ? "" : v.trim();
	}

	// ----------------------------------------------------------------- 매칭

	private static final class Config {
		private final String defaultLayout;
		private final Map<String, String> exact;
		private final List<Wild> wild;
		private final long stamp;

		Config(String defaultLayout, Map<String, String> exact, List<Wild> wild, long stamp) {
			this.defaultLayout = defaultLayout;
			this.exact = exact;
			this.wild = wild;
			this.stamp = stamp;
		}

		String match(String path) {
			if (path == null) {
				return defaultLayout;
			}
			String hit = exact.get(path);
			if (hit != null) {
				return hit;
			}
			// 와일드카드는 "가장 긴 패턴" 승리 — SiteMesh PathMapper.findComplexKey 와 동일.
			String best = null;
			int bestLen = -1;
			for (int i = 0; i < wild.size(); i++) {
				Wild w = wild.get(i);
				if (w.source.length() > bestLen && w.regex.matcher(path).matches()) {
					best = w.layout;
					bestLen = w.source.length();
				}
			}
			return best != null ? best : defaultLayout;
		}
	}

	private static final class Wild {
		private final String source;
		private final String layout;
		private final Pattern regex;

		Wild(String source, String layout) {
			this.source = source;
			this.layout = layout;
			this.regex = Pattern.compile(toRegex(source));
		}

		/**
		 * SiteMesh 2 글롭 → 정규식. '*' 는 '/' 를 포함한 임의 문자열, '?' 는 임의 1문자.
		 * (Ant 의 경로 인식 '**' 의미는 없다 — SiteMesh 와 동일하게 단순 글롭이다.)
		 */
		private static String toRegex(String glob) {
			StringBuilder sb = new StringBuilder(glob.length() + 16);
			StringBuilder lit = new StringBuilder();
			for (int i = 0; i < glob.length(); i++) {
				char c = glob.charAt(i);
				if (c == '*' || c == '?') {
					if (lit.length() > 0) {
						sb.append(Pattern.quote(lit.toString()));
						lit.setLength(0);
					}
					sb.append(c == '*' ? ".*" : ".");
				} else {
					lit.append(c);
				}
			}
			if (lit.length() > 0) {
				sb.append(Pattern.quote(lit.toString()));
			}
			return sb.toString();
		}
	}
}
