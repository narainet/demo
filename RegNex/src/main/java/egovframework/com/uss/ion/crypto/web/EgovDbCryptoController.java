/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/crypto/web/EgovDbCryptoController.java
 *
 * 설정값 암호화 도구 — globals.properties 에 넣을 암호문을 만들어 준다.
 *
 *  · 고객사 이관·계정 교체 때 관리자가 손으로 암호화할 방법이 없어(별도 자바 도구 필요) 만든 화면.
 *  · 화면은 "암호화만" 한다 — 서버의 globals.properties 를 고쳐 쓰지 않는다.
 *    출력된 암호문을 관리자가 직접 파일에 붙여넣고 WAS 를 재기동하는 절차다.
 *  · 암호화 주체 = context-datasource.xml 이 복호에 쓰는 그 빈(egovEnvCryptoService) 자신이라,
 *    여기서 만든 암호문은 기동 시 반드시 복호된다(키·알고리즘 불일치가 원천 봉쇄된다).
 *  · ★암호화는 DB 종류와 무관하다 — context-crypto.xml 의 algorithmKey 하나로만 암호화하므로
 *    같은 평문이면 oracle/tibero/maria/postgres 어디에 넣든 암호문이 같다. 그래서 DB 구분을 묻지 않는다.
 *  · ⛔평문을 그대로 두면 복호 단계에서 예외가 아니라 "쓰레기 문자열"이 나온다(EgovEnvCryptoServiceImpl
 *    은 IllegalArgumentException 만 잡고 되돌린다). 그래서 항목마다 복호 왕복검증을 함께 보여준다.
 *
 * 화면/인가: /uss/ion/crypto/*  — 인가 규칙을 따로 두지 않아 context-security L7 폴백으로 ADMIN 전용.
 *            메뉴(운영관리 > 설정값 암호화)로도 ROLE_ADMIN 만 부여한다.
 */
package egovframework.com.uss.ion.crypto.web;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cryptography.EgovEnvCryptoService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 설정값(DB 접속 Url·UserName·Password 등) 암호화 도구 컨트롤러.
 */
@Controller
public class EgovDbCryptoController {

	/** 한 번에 받아 줄 최대 줄 수 — 도구 오남용 방지용 상한. */
	private static final int MAX_LINES = 20;

	/** context-datasource.xml 이 복호에 쓰는 바로 그 빈. 같은 빈으로 암호화해야 왕복이 보장된다. */
	@Resource(name = "egovEnvCryptoService")
	private EgovEnvCryptoService egovEnvCryptoService;

	/**
	 * 암호화 도구 화면.
	 */
	@RequestMapping(value = "/uss/ion/crypto/dbCryptoView.do", method = RequestMethod.GET)
	public String dbCryptoView(ModelMap model) throws Exception {
		return "egovframework/com/uss/ion/crypto/EgovDbCrypto";
	}

	/**
	 * 입력한 평문을 한 줄에 하나씩 암호화해 돌려준다.
	 *
	 * 줄 단위라 접속 URL·계정 ID·비밀번호 세 개를 한 번에 처리할 수 있다.
	 */
	@RequestMapping(value = "/uss/ion/crypto/dbCryptoEncrypt.do", method = RequestMethod.POST)
	public String dbCryptoEncrypt(
			@RequestParam(value = "plainText", required = false) String plainText,
			ModelMap model) throws Exception {

		List<CryptoItem> items = new ArrayList<CryptoItem>();
		boolean tooMany = false;

		if (plainText != null) {
			String[] lines = plainText.split("\\r?\\n");
			for (String line : lines) {
				String value = clean(line);
				if (value.isEmpty()) {
					continue;
				}
				if (items.size() >= MAX_LINES) {
					tooMany = true;
					break;
				}
				items.add(encryptOne(value));
			}
		}

		model.addAttribute("items", items);
		model.addAttribute("plainText", plainText);
		if (items.isEmpty()) {
			model.addAttribute("message", "암호화할 값을 입력하세요.");
		} else if (tooMany) {
			model.addAttribute("message", "한 번에 " + MAX_LINES + "줄까지만 처리합니다. 앞의 " + MAX_LINES + "줄만 암호화했습니다.");
		}
		return "egovframework/com/uss/ion/crypto/EgovDbCrypto";
	}

	/**
	 * 앞뒤 공백과 BOM 을 제거한다.
	 *
	 * 메모장·엑셀 등에서 복사해 붙이면 첫 글자에 BOM(U+FEFF)이 딸려 오는 경우가 있다. 눈에 보이지 않는
	 * 글자라 그대로 암호화하면 나중에 접속만 실패하고 원인을 찾기 어렵다.
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

	/**
	 * 평문 1건을 암호화하고 곧바로 복호해 되돌아오는지 확인한다.
	 *
	 * 왕복검증을 하는 이유: 암호문을 잘못 붙여넣거나 평문을 남겨 두면 기동 시 예외가 아니라
	 * 조용히 깨진 문자열로 접속을 시도해 원인 파악이 어렵다. 만들 때 한 번 확인해 두는 편이 싸다.
	 */
	private CryptoItem encryptOne(String value) {
		String cipher = egovEnvCryptoService.encrypt(value);
		boolean verified;
		try {
			verified = value.equals(egovEnvCryptoService.decrypt(cipher));
		} catch (RuntimeException e) {
			verified = false;   // 왕복 실패 자체가 결과이므로 화면에 NG 로만 알린다
		}
		return new CryptoItem(value, cipher, verified);
	}

	/**
	 * 화면 출력용 한 건. (JSP EL 에서 쓰므로 public getter 필요)
	 */
	public static class CryptoItem {

		private final String plain;
		private final String cipher;
		private final boolean verified;

		public CryptoItem(String plain, String cipher, boolean verified) {
			this.plain = plain;
			this.cipher = cipher;
			this.verified = verified;
		}

		public String getPlain() {
			return plain;
		}

		public String getCipher() {
			return cipher;
		}

		public boolean isVerified() {
			return verified;
		}
	}
}
