/*
 * 물리적 저장 경로: /src/main/java/narainet/law/common/service/LawJuminCrypto.java
 *
 * 송무 주민등록번호 양방향 암호화 헬퍼 (LAW_MODULE_DESIGN.md §4.4).
 *  - 저장: ARIA(lawCryptoService, 키=Globals.law.cryptoKey) 암호문 Base64 — LAW_SUIT_PARTY.JUMIN_ENC.
 *  - 표시: 항상 마스킹(생년월일 앞6자리 기반) — 조회 경로에서 복호화하지 않는다.
 *    복호화 메서드는 향후 연계·증빙 대비로만 존재(화면 노출 금지).
 *  - 암복호화는 서비스 레이어 전용(매퍼는 암호문만).
 */
package narainet.law.common.service;

import java.util.Base64;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cryptography.EgovARIACryptoService;
import org.springframework.stereotype.Service;

import egovframework.com.cmm.service.EgovProperties;

@Service("lawJuminCrypto")
public class LawJuminCrypto {

	@Resource(name = "lawCryptoService")
	private EgovARIACryptoService cryptoService;

	private String key() {
		return EgovProperties.getProperty("Globals.law.cryptoKey");
	}

	/**
	 * 주민번호 평문(하이픈 허용) → ARIA 암호문 Base64.
	 * 숫자 13자리가 아니면 저장하지 않는다(null 반환 — 선택 입력 필드).
	 */
	public String encrypt(String plainJumin) {
		if (plainJumin == null) {
			return null;
		}
		String digits = plainJumin.replaceAll("[^0-9]", "");
		if (digits.length() != 13) {
			return null;
		}
		try {
			byte[] enc = cryptoService.encrypt(digits.getBytes("UTF-8"), key());
			return Base64.getEncoder().encodeToString(enc);
		} catch (Exception e) {
			throw new RuntimeException("주민번호 암호화 실패", e);
		}
	}

	/** 복호화 — 향후 연계·증빙 전용. 화면 표시 경로에서 호출 금지(§4.4). */
	public String decrypt(String encBase64) {
		if (encBase64 == null || encBase64.trim().isEmpty()) {
			return null;
		}
		try {
			byte[] dec = cryptoService.decrypt(Base64.getDecoder().decode(encBase64), key());
			return new String(dec, "UTF-8");
		} catch (Exception e) {
			throw new RuntimeException("주민번호 복호화 실패", e);
		}
	}

	/**
	 * 마스킹 표시 — 생년월일 앞6자리 + "-*******".
	 * 주민번호가 저장된 행(hasJumin)에만 쓰며, 생년월일이 6자리가 안 되면 전체 마스킹.
	 */
	public static String mask(String birth) {
		String digits = birth == null ? "" : birth.replaceAll("[^0-9]", "");
		String head;
		if (digits.length() >= 8) {
			head = digits.substring(2, 8);
		} else if (digits.length() >= 6) {
			head = digits.substring(0, 6);
		} else {
			head = "******";
		}
		return head + "-*******";
	}
}
