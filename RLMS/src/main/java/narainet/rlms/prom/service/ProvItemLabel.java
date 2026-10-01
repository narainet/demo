/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ProvItemLabel.java
 *
 * SFULL_ITEM(60자 내부 식별자) → 사람이 읽는 조항 라벨 변환 유틸.
 *
 * 배경(2026-07-16): 본문비교·유효성검사·전문검색 화면이 SFULL_ITEM 원문(예: "00000000100000…")을
 * 그대로 표에 노출 — 사용자가 위치를 읽을 수 없다는 신고. 화면에는 이 라벨만 쓰고
 * 원문 식별자는 화면 밖(정렬키·링크 파라미터)에만 사용한다.
 *
 * SFULL_ITEM 레이아웃(ProvTextParser STYLE_NORMAL): 60자 = 12청크 × 5자, 각 5자 = SITEM(3)+SSUB_ITEM(2).
 *   [1]편 [2]장 [3]절 [4]관 [5]목1 [6]조 [7]항 [8]호 [9]목2 [10]단2 (11·12 예비)
 */
package narainet.rlms.prom.service;

public final class ProvItemLabel {

	private ProvItemLabel() {}

	/** 목(가나다) 순번 → 문자 */
	private static final String[] MOK = {
		"가", "나", "다", "라", "마", "바", "사", "아", "자", "차", "카", "타", "파", "하"
	};

	/**
	 * 조항 라벨 생성.
	 *   "000000001000000000000000000000000040000200003000000000000000" → "제1장 제4조 제2항 3호"
	 *   "line-3" (부칙 diff 행 라벨) → "3행"
	 *   미인식 형식(널/60자 숫자 아님) → 원문 그대로 반환(정보 소실 방지).
	 */
	public static String of(String fullItem) {
		if (fullItem == null) return "";
		String s = fullItem.trim();
		if (s.isEmpty()) return "";
		if (s.startsWith("line-")) {                       // 부칙 라인 diff (BodyDiffService)
			String n = s.substring(5);
			return n.matches("\\d+") ? (n + "행") : s;
		}
		// 60자 전체뿐 아니라 접두(5의 배수 자리, 예: 유효성검사 5-c 의 그룹 접두)도 라벨화
		if (s.length() < 5 || s.length() > 60 || s.length() % 5 != 0 || !s.matches("\\d+")) return s;

		int chunks = s.length() / 5;
		StringBuilder sb = new StringBuilder();
		if (chunks > 0) appendUnit(sb, chunk(s, 0), sub(s, 0), "편");
		if (chunks > 1) appendUnit(sb, chunk(s, 1), sub(s, 1), "장");
		if (chunks > 2) appendUnit(sb, chunk(s, 2), sub(s, 2), "절");
		if (chunks > 3) appendUnit(sb, chunk(s, 3), sub(s, 3), "관");
		if (chunks > 4) appendMok (sb, chunk(s, 4));
		if (chunks > 5) appendUnit(sb, chunk(s, 5), sub(s, 5), "조");
		if (chunks > 6) appendUnit(sb, chunk(s, 6), sub(s, 6), "항");
		if (chunks > 7) appendHo  (sb, chunk(s, 7));
		if (chunks > 8) appendMok (sb, chunk(s, 8));
		if (chunks > 9 && chunk(s, 9) > 0) {
			if (sb.length() > 0) sb.append(' ');
			sb.append("단").append(chunk(s, 9));
		}
		return sb.length() == 0 ? s : sb.toString();
	}

	private static int chunk(String s, int i) {
		try { return Integer.parseInt(s.substring(i * 5, i * 5 + 3)); }
		catch (NumberFormatException e) { return 0; }
	}

	private static int sub(String s, int i) {
		try { return Integer.parseInt(s.substring(i * 5 + 3, i * 5 + 5)); }
		catch (NumberFormatException e) { return 0; }
	}

	/** "제N조" / "제N조의M" 형 단위 */
	private static void appendUnit(StringBuilder sb, int item, int sub, String unit) {
		if (item <= 0 && sub <= 0) return;
		if (sb.length() > 0) sb.append(' ');
		sb.append('제').append(item).append(unit);
		if (sub > 0) sb.append('의').append(sub);
	}

	/** 호: "3호" */
	private static void appendHo(StringBuilder sb, int item) {
		if (item <= 0) return;
		if (sb.length() > 0) sb.append(' ');
		sb.append(item).append('호');
	}

	/** 목: "가목" (범위 밖이면 "제N목") */
	private static void appendMok(StringBuilder sb, int item) {
		if (item <= 0) return;
		if (sb.length() > 0) sb.append(' ');
		if (item <= MOK.length) sb.append(MOK[item - 1]).append('목');
		else sb.append('제').append(item).append('목');
	}
}
