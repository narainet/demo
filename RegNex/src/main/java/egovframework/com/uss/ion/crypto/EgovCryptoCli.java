/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/crypto/EgovCryptoCli.java
 *
 * 설정값 암호화 CLI — WAS 를 띄우지 않고 명령행에서 암호문을 만든다.
 *
 * ★존재 이유(설치 시점의 닭과 달걀):
 *   신규 설치·계정 교체 시에는 globals.properties 에 올바른 암호문이 없어 DB 접속이 안 되고,
 *   그러면 앱이 기동하지 않아 관리자 화면(설정값 암호화)을 쓸 수 없다.
 *   그래서 같은 암호화를 오프라인으로 수행하는 이 도구를 WAR 안에 함께 배포한다.
 *   (기동 이후의 일상적인 교체는 관리자 화면이 더 편하다 — 둘은 완전히 같은 암호문을 만든다.)
 *
 * ★키는 하드코딩하지 않고 context-crypto.xml 에서 읽는다 — 고객사가 키를 바꿔도 도구가 따라간다.
 *
 * 사용법(배포본 기준. WAR 를 푼 디렉터리에서):
 *   java -cp "WEB-INF/classes;WEB-INF/lib/*" egovframework.com.uss.ion.crypto.EgovCryptoCli \
 *        "jdbc:oracle:thin:@127.0.0.1:1521:xe" "RLMS" "비밀번호"
 *   (리눅스는 -cp 구분자를 ':' 로)
 *
 *   · 인자를 주지 않으면 표준입력에서 한 줄에 하나씩 읽는다.
 *   · context-crypto.xml 을 클래스패스에서 못 찾으면 -c <경로> 로 지정한다.
 *   · 각 값은 암호화 직후 복호해 보고 왕복이 맞는지 함께 출력한다.
 */
package egovframework.com.uss.ion.crypto;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PushbackInputStream;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.egovframe.rte.fdl.cryptography.EgovPasswordEncoder;
import org.egovframe.rte.fdl.cryptography.impl.EgovARIACryptoServiceImpl;
import org.egovframe.rte.fdl.cryptography.impl.EgovEnvCryptoServiceImpl;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * globals.properties 용 암호문 생성기(오프라인).
 */
public final class EgovCryptoCli {

	/** 앱과 같은 위치의 설정 — 클래스패스에서 먼저 찾는다. */
	private static final String DEFAULT_CONFIG = "/egovframework/spring/com/context-crypto.xml";

	private EgovCryptoCli() {
		// 유틸리티 클래스
	}

	public static void main(String[] args) throws Exception {
		silenceAppLogging();

		String configPath = null;
		List<String> values = new ArrayList<String>();

		for (int i = 0; i < args.length; i++) {
			if ("-c".equals(args[i]) && i + 1 < args.length) {
				configPath = args[++i];
			} else if ("-h".equals(args[i]) || "--help".equals(args[i])) {
				usage();
				return;
			} else {
				values.add(clean(args[i]));
			}
		}

		if (values.isEmpty()) {
			values = readStdin();
		}
		if (values.isEmpty()) {
			usage();
			return;
		}

		CryptoConfig cfg = loadConfig(configPath);
		System.out.println("# context-crypto.xml : algorithm=" + cfg.algorithm
				+ ", algorithmKey=" + cfg.algorithmKey + ", blockSize=" + cfg.blockSize
				+ (cfg.crypto ? "" : "  (crypto=\"false\" — 앱은 지금 평문을 그대로 씁니다)"));
		System.out.println();

		EgovEnvCryptoServiceImpl env = build(cfg);
		for (String plain : values) {
			String cipher = env.encrypt(plain);
			boolean ok;
			try {
				ok = plain.equals(env.decrypt(cipher));
			} catch (RuntimeException e) {
				ok = false;
			}
			System.out.println(cipher + "    # " + plain + (ok ? "" : "   ★복호 왕복 실패 — 키 설정을 확인하세요"));
		}
	}

	/**
	 * 앱 로그 설정이 WAS 밖에서 터지는 것을 막는다.
	 *
	 * log4j2.xml 의 파일 어펜더가 ${sys:catalina.base}/logs/app.log 를 쓰는데 톰캣 밖에서는 그 값이 없어
	 * "Invalid file path" 스택트레이스가 결과를 뒤덮는다(암호문은 잘 나오지만 설치 담당자가 못 찾는다).
	 * ARIA 구현체의 static 초기화가 로거를 잡기 전에 임시 디렉터리를 채워 넣어 조용히 만든다.
	 */
	private static void silenceAppLogging() {
		if (System.getProperty("catalina.base") == null) {
			System.setProperty("catalina.base", System.getProperty("java.io.tmpdir", "."));
		}
		// log4j 자체 상태 메시지(설정 로드 실패 등)를 끈다
		if (System.getProperty("log4j2.statusLoggerLevel") == null) {
			System.setProperty("log4j2.statusLoggerLevel", "OFF");
		}
		// 앱 log4j2.xml 대신 "없는 파일"을 가리켜 log4j 기본 구성(콘솔·ERROR)으로 떨어뜨린다.
		// 앱 설정을 쓰면 DEBUG 한 줄이 결과에 섞여 설치 담당자가 암호문을 오독할 수 있다.
		// (도구의 출력은 표준출력의 암호문 줄뿐이어야 한다)
		if (System.getProperty("log4j2.configurationFile") == null) {
			System.setProperty("log4j2.configurationFile", "egov-crypto-cli-no-logging.xml");
		}
	}

	private static void usage() {
		System.out.println("사용법: java -cp \"WEB-INF/classes;WEB-INF/lib/*\" "
				+ EgovCryptoCli.class.getName() + " [-c <context-crypto.xml>] <평문> [평문...]");
		System.out.println("       인자를 생략하면 표준입력에서 한 줄에 하나씩 읽습니다.");
		System.out.println("결과를 globals.properties 의 Globals.<DB구분>.Url / .UserName / .Password 값으로 넣고");
		System.out.println("WAS 를 재기동하세요. 세 항목 모두 암호문이어야 합니다.");
	}

	private static List<String> readStdin() throws Exception {
		List<String> out = new ArrayList<String>();
		BufferedReader r = new BufferedReader(new InputStreamReader(skipUtf8Bom(System.in), Charset.defaultCharset()));
		String line;
		while ((line = r.readLine()) != null) {
			String v = clean(line);
			if (!v.isEmpty()) {
				out.add(v);
			}
		}
		return out;
	}

	/**
	 * 입력 앞머리의 UTF-8 BOM(EF BB BF) 세 바이트를 버린다.
	 *
	 * ⛔문자로 걸러서는 안 된다 — 콘솔 기본 인코딩(한국어 윈도우는 cp949)으로 디코딩되면 BOM 바이트가
	 * U+FEFF 가 아니라 엉뚱한 글자가 되어 문자 비교를 빠져나간다(실측). 그래서 바이트 단계에서 처리한다.
	 * 메모장으로 만든 파일이나 PowerShell 파이프가 BOM 을 붙이는데, 그대로 암호화하면 눈에 안 보이는
	 * 글자가 값에 섞여 나중에 접속만 실패한다.
	 */
	private static InputStream skipUtf8Bom(InputStream in) throws Exception {
		PushbackInputStream p = new PushbackInputStream(in, 3);
		byte[] head = new byte[3];
		int n = 0;
		while (n < 3) {
			int r = p.read(head, n, 3 - n);
			if (r < 0) {
				break;
			}
			n += r;
		}
		boolean bom = (n == 3) && (head[0] & 0xFF) == 0xEF && (head[1] & 0xFF) == 0xBB && (head[2] & 0xFF) == 0xBF;
		if (!bom && n > 0) {
			p.unread(head, 0, n);
		}
		return p;
	}

	/**
	 * 앞뒤 공백과 BOM 문자를 제거한다.
	 *
	 * 인자로 넘어온 값이나 이미 문자로 디코딩된 입력에 U+FEFF 가 남아 있을 때를 위한 2차 방어다.
	 */
	private static String clean(String s) {
		if (s == null) {
			return "";
		}
		String v = s.trim();
		while (v.length() > 0 && v.charAt(0) == '﻿') {
			v = v.substring(1).trim();
		}
		return v;
	}

	/** context-crypto.xml 의 egov-crypto:config 속성을 읽는다. */
	private static CryptoConfig loadConfig(String path) throws Exception {
		DocumentBuilderFactory f = DocumentBuilderFactory.newInstance();
		f.setNamespaceAware(true);
		// 외부 엔티티 차단(설정 파일이라도 파서 기본값에 기대지 않는다)
		f.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
		DocumentBuilder b = f.newDocumentBuilder();

		Document doc;
		if (path != null) {
			File file = new File(path);
			if (!file.isFile()) {
				throw new IllegalArgumentException("context-crypto.xml 을 찾을 수 없습니다: " + path);
			}
			doc = b.parse(file);
		} else {
			InputStream in = EgovCryptoCli.class.getResourceAsStream(DEFAULT_CONFIG);
			if (in == null) {
				throw new IllegalArgumentException(
						"클래스패스에서 " + DEFAULT_CONFIG + " 를 찾지 못했습니다. -c <경로> 로 지정하세요.");
			}
			try {
				doc = b.parse(in);
			} finally {
				in.close();
			}
		}

		Element cfgEl = findConfigElement(doc);
		if (cfgEl == null) {
			throw new IllegalArgumentException("context-crypto.xml 에서 egov-crypto:config 를 찾지 못했습니다.");
		}

		CryptoConfig c = new CryptoConfig();
		c.algorithm = attr(cfgEl, "algorithm", "SHA-256");
		c.algorithmKey = attr(cfgEl, "algorithmKey", "");
		c.algorithmKeyHash = attr(cfgEl, "algorithmKeyHash", "");
		c.blockSize = Integer.parseInt(attr(cfgEl, "cryptoBlockSize", "1024"));
		c.crypto = !"false".equalsIgnoreCase(attr(cfgEl, "crypto", "true"));
		if (c.algorithmKey.isEmpty() || c.algorithmKeyHash.isEmpty()) {
			throw new IllegalArgumentException("algorithmKey / algorithmKeyHash 가 비어 있습니다.");
		}
		return c;
	}

	/** 네임스페이스 접두사가 무엇이든 localName 이 config 인 요소를 찾는다. */
	private static Element findConfigElement(Document doc) {
		NodeList all = doc.getElementsByTagName("*");
		for (int i = 0; i < all.getLength(); i++) {
			Node n = all.item(i);
			if (n.getNodeType() == Node.ELEMENT_NODE && "config".equals(n.getLocalName())
					&& ((Element) n).hasAttribute("algorithmKey")) {
				return (Element) n;
			}
		}
		return null;
	}

	private static String attr(Element el, String name, String defaultValue) {
		String v = el.getAttribute(name);
		return (v == null || v.isEmpty()) ? defaultValue : v.trim();
	}

	/** 런타임(context-datasource.xml)이 복호에 쓰는 것과 같은 구성으로 조립한다. */
	private static EgovEnvCryptoServiceImpl build(CryptoConfig c) {
		EgovPasswordEncoder encoder = new EgovPasswordEncoder();
		encoder.setAlgorithm(c.algorithm);
		encoder.setHashedPassword(c.algorithmKeyHash);

		EgovARIACryptoServiceImpl aria = new EgovARIACryptoServiceImpl();
		aria.setPasswordEncoder(encoder);
		aria.setBlockSize(c.blockSize);

		EgovEnvCryptoServiceImpl env = new EgovEnvCryptoServiceImpl();
		env.setPasswordEncoder(encoder);
		env.setCryptoService(aria);
		env.setCryptoAlgorithm(c.algorithm);
		env.setCyptoAlgorithmKey(c.algorithmKey);
		env.setCyptoAlgorithmKeyHash(c.algorithmKeyHash);
		env.setCryptoBlockSize(c.blockSize);
		env.setCrypto(true);   // 도구는 항상 암호화한다(앱의 crypto 값과 무관)
		return env;
	}

	/** context-crypto.xml 에서 읽은 값. */
	private static final class CryptoConfig {
		private String algorithm;
		private String algorithmKey;
		private String algorithmKeyHash;
		private int blockSize;
		private boolean crypto;
	}
}
