/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/ProvTextParser.java
 *
 * 레거시 식 한국 법령 본문 파서 — text → 60자 SFULL_ITEM + SNATIVE_TYPE/SUNIT_TYPE/ILEVEL/IINDEX.
 *
 *   - 레거시 orangeidea.lims.fulltext.provision.ProvisionVersionUtil.getPatternResultList +
 *     orangeidea.lims.fulltext.provision.pattern.normal.* (JangPattern/JoPattern/HangPattern/...)
 *     를 Java 단일 클래스로 이식. STYLE_NORMAL 만 지원.
 *
 *   - SFULL_ITEM 구조 (60자 = 5자 × 12단계):
 *       [1-5] 편 / [6-10] 장 / [11-15] 절 / [16-20] 관 / [21-25] 목1 /
 *       [26-30] 조(BASE_TEXT) / [31-35] 항 / [36-40] 호 / [41-45] 목2 / [46-50] 단2 / [51-55] [56-60].
 *     각 5자 = SITEM(3) + SSUB_ITEM(2). 빈 청크는 "00000".
 *
 *   - State machine: 입력 라인을 위에서 아래로 한 번 훑으며 현재 청크 배열을 갱신,
 *     상위 단위 진입 시 모든 하위 단위 청크를 "00000" 으로 리셋.
 *
 *   - 일괄 편집기 (레거시 "버전관리용조문편집") 의 SAVE 단계에서 사용.
 *     "이 회차에 본문 스냅샷" 시멘틱 — 이 회차의 기존 TB_PROV_VRSN 을 통째로 교체.
 *
 *   - 기존 BodyParser (자체 간이 포맷 "제1조-①") 와는 별도. 호환 안 됨.
 *
 * <<개정이력>>
 *   2026.05.13   RLMS 전환팀   레거시 한국법령 파서 포팅 (STYLE_NORMAL)
 */
package narainet.rlms.prom.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import narainet.rlms.prom.service.ProvVrsnVO;

public class ProvTextParser {

	// ── SFULL_ITEM 청크 레이아웃 (STYLE_NORMAL) ────────────────────
	private static final int CHUNK_LEN  = 5;
	private static final int NUM_CHUNKS = 12;
	private static final int LV_PYUN = 1, LV_JANG = 2, LV_JEOL = 3, LV_GWAN = 4, LV_MOK1 = 5,
	                         LV_JO   = 6, LV_HANG = 7, LV_HO   = 8, LV_MOK2 = 9, LV_DAN2 = 10;

	// ── 라인 패턴 ────────────────────────────────────────────────
	// "제N장 [의M] [제목]" (편/장/절/관 공통 골격)
	private static final Pattern P_PYUN = Pattern.compile("^\\s*제\\s*(\\d+)\\s*편(?:\\s*의\\s*(\\d+))?\\s*(.*)$");
	private static final Pattern P_JANG = Pattern.compile("^\\s*제\\s*(\\d+)\\s*장(?:\\s*의\\s*(\\d+))?\\s*(.*)$");
	private static final Pattern P_JEOL = Pattern.compile("^\\s*제\\s*(\\d+)\\s*절(?:\\s*의\\s*(\\d+))?\\s*(.*)$");
	private static final Pattern P_GWAN = Pattern.compile("^\\s*제\\s*(\\d+)\\s*관(?:\\s*의\\s*(\\d+))?\\s*(.*)$");
	// 조: "제N조[의M](제목) 본문" / "제N조[의M]<삭제> 본문" / "제N조[의M] 본문"
	private static final Pattern P_JO_TITLED  = Pattern.compile("^\\s*제\\s*(\\d+)\\s*조(?:\\s*의\\s*(\\d+))?\\s*\\(([^)]*)\\)\\s*(.*)$");
	private static final Pattern P_JO_DELETED = Pattern.compile("^\\s*제\\s*(\\d+)\\s*조(?:\\s*의\\s*(\\d+))?\\s*<([^>]*)>\\s*(.*)$");
	private static final Pattern P_JO_BARE    = Pattern.compile("^\\s*제\\s*(\\d+)\\s*조(?:\\s*의\\s*(\\d+))?\\s*(.*)$");
	// 항: ① ~ ㊿ (원문자 1~50 — ①-⑳ U+2460-2473, ㉑-㉟ U+3251-325F, ㊱-㊿ U+32B1-32BF)
	private static final Pattern P_HANG = Pattern.compile("^\\s*([\\u2460-\\u2473\\u3251-\\u325F\\u32B1-\\u32BF])\\s*(.*)$");
	// 단2: "(N) [본문]" — 본문 없이 단독 "(N)" 만 입력해도 매칭 (\s* 0자 이상)
	private static final Pattern P_DAN2 = Pattern.compile("^\\s*\\(\\s*(\\d+)\\s*\\)\\s*(.*)$");
	// 호 변형: "N) [본문]" — ★#6 2안: "N)" 는 별개 단위로 분해하지 않고 연속 본문 처리(분기 제거됨).
	//   패턴은 참조용으로 보존(향후 1안=정식단위 전환 시 재사용). 현재 parse() 에서 미사용.
	@SuppressWarnings("unused")
	private static final Pattern P_HO2  = Pattern.compile("^\\s*(\\d+)\\)\\s*(.*)$");
	// 호: "N. [본문]" — 본문 없이 단독 "N." 매칭 허용
	private static final Pattern P_HO   = Pattern.compile("^\\s*(\\d+)\\.\\s*(.*)$");
	// 목2: "가. [본문]" — 본문 없이 단독 "가." 매칭 허용
	private static final Pattern P_MOK2 = Pattern.compile("^\\s*([가나다라마바사아자차카타파하])\\.\\s*(.*)$");
	// 부칙: "부칙 <...>" / "부 칙" — 헤더 라인. 이후 본문은 POST_SCRIPT 로 분리해
	//   본문 조(제1조 등)와 같은 SFULL_ITEM 으로 충돌하는 것을 차단. (normalizeLine 이 〈〉→<> 변환)
	private static final Pattern P_BYLAW = Pattern.compile("^\\s*부\\s*칙\\s*(<.*)?$");

	/**
	 * 본문 텍스트를 단위 row 리스트로 분해.
	 * 각 row 는 promNo / fullItem(60자) / item / subItem / unitType / nativeType / level / index /
	 * title / contents / dispYn='Y' / startDate / sysId / gaejungType 채워서 반환.
	 * PK(provVrsnNo) 는 호출자가 채번.
	 */
	public List<ProvVrsnVO> parse(Long promNo, String text,
			String startDate, String sysId, String gaejungType) {

		List<ProvVrsnVO> out = new ArrayList<>();
		if (text == null) return out;

		String[] chunks = new String[NUM_CHUNKS];
		for (int i = 0; i < NUM_CHUNKS; i++) chunks[i] = repeat('0', CHUNK_LEN);

		int globalIdx = 0;
		ProvVrsnVO lastRow = null;   // 미인식 라인을 직전 row 의 SCONTENTS 에 잇기 위한 참조

		// 부칙(POST_SCRIPT) 상태 — 부칙 헤더 이후 라인은 본문 조와 분리해 부칙 블록에 누적.
		//   부칙의 "제1조(시행일)" 등이 본문 제1조와 같은 SFULL_ITEM 으로 충돌·중복되는 것을 차단.
		boolean inPostscript = false;
		int bylawSeq = 0;
		ProvVrsnVO curBylaw = null;

		for (String rawLine : text.split("\\r?\\n")) {
			if (rawLine == null) continue;
			String line = rawLine.replace(' ', ' ');
			// 레거시 임포트/재로드 데이터의 숫자 문자참조(&#40;=( &#41;=) 등) 를 실제 문자로 복원.
			// 이게 빠지면 "제N조&#40;제목&#41;" 가 P_JO_TITLED(리터럴 '(' 기대) 매칭에 실패해
			// P_JO_BARE 로 떨어져 STITLE 이 NULL 로 저장됨(조문제목 미표시 버그의 원인).
			line = ProvViewRenderer.decodeNumericEntities(line);
			line = normalizeLine(line);   // 전각 괄호 （）·꺽쇠 〈〉·숫자 → 반각 (패턴 매칭 정상화)
			if (line.trim().isEmpty()) continue;

			// 부칙 헤더 → 이후 라인은 POST_SCRIPT 블록으로 분리 (본문 조와 SFULL_ITEM 충돌 차단)
			if (P_BYLAW.matcher(line).matches()) {
				inPostscript = true;
				curBylaw = buildPostScript(promNo, ++bylawSeq, line.trim(),
						startDate, sysId, ++globalIdx);
				out.add(curBylaw);
				lastRow = curBylaw;
				continue;
			}
			if (inPostscript) {
				if (curBylaw != null) {
					String prev = curBylaw.getContents() == null ? "" : curBylaw.getContents();
					curBylaw.setContents((prev.isEmpty() ? "" : prev + "\n") + line.trim());
				}
				continue;
			}

			Matcher m;
			ProvVrsnVO row = null;

			if ((m = P_JANG.matcher(line)).matches()) {
				applyChunk(chunks, LV_JANG, m.group(1), m.group(2));
				row = buildGroup(promNo, "F_JANG", LV_JANG, chunks, m.group(3),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_JEOL.matcher(line)).matches()) {
				applyChunk(chunks, LV_JEOL, m.group(1), m.group(2));
				row = buildGroup(promNo, "F_JEOL", LV_JEOL, chunks, m.group(3),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_GWAN.matcher(line)).matches()) {
				applyChunk(chunks, LV_GWAN, m.group(1), m.group(2));
				row = buildGroup(promNo, "F_GWAN", LV_GWAN, chunks, m.group(3),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_PYUN.matcher(line)).matches()) {
				applyChunk(chunks, LV_PYUN, m.group(1), m.group(2));
				row = buildGroup(promNo, "F_PYUN", LV_PYUN, chunks, m.group(3),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_JO_TITLED.matcher(line)).matches()) {
				applyChunk(chunks, LV_JO, m.group(1), m.group(2));
				row = buildJo(promNo, chunks, m.group(3), m.group(4),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_JO_DELETED.matcher(line)).matches()) {
				applyChunk(chunks, LV_JO, m.group(1), m.group(2));
				// 삭제 표기 — title 에 마커 그대로, gaejungType 도 NULLIFY 로 표시
				row = buildJo(promNo, chunks, m.group(3), m.group(4),
						startDate, sysId, "NULLIFY", ++globalIdx);
			} else if ((m = P_JO_BARE.matcher(line)).matches()) {
				applyChunk(chunks, LV_JO, m.group(1), m.group(2));
				row = buildJo(promNo, chunks, null, m.group(3),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_HANG.matcher(line)).matches()) {
				int n = circledToInt(m.group(1).charAt(0));
				applyChunk(chunks, LV_HANG, String.valueOf(n), null);
				row = buildSub(promNo, "S_HANG", LV_HANG, chunks, m.group(2),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_DAN2.matcher(line)).matches()) {
				applyChunk(chunks, LV_DAN2, m.group(1), null);
				row = buildSub(promNo, "S_DAN2", LV_DAN2, chunks, m.group(2),
						startDate, sysId, gaejungType, ++globalIdx);
			} else if ((m = P_MOK2.matcher(line)).matches()) {
				int n = korLetterToInt(m.group(1).charAt(0));
				applyChunk(chunks, LV_MOK2, String.valueOf(n), null);
				row = buildSub(promNo, "S_MOK2", LV_MOK2, chunks, m.group(2),
						startDate, sysId, gaejungType, ++globalIdx);
			// "N)" (P_HO2) 는 별개 단위로 분해하지 않는다(#6 2안) — 매칭 안 돼 아래 else(연속 본문)로 떨어져
			//   직전 행 본문에 이어 붙는다. ("가)" 도 패턴이 없어 동일하게 연속 처리.)
			} else if ((m = P_HO.matcher(line)).matches()) {
				applyChunk(chunks, LV_HO, m.group(1), null);
				row = buildSub(promNo, "S_HO", LV_HO, chunks, m.group(2),
						startDate, sysId, gaejungType, ++globalIdx);
			} else {
				// 미인식 라인 — 직전 row 의 본문 뒤에 줄 추가 (레거시 의 연속 단락 처리와 동등)
				if (lastRow != null) {
					String prev = lastRow.getContents() == null ? "" : lastRow.getContents();
					lastRow.setContents((prev.isEmpty() ? "" : prev + "\n") + line.trim());
				}
				continue;
			}

			out.add(row);
			lastRow = row;
		}
		return out;
	}

	// ── 청크 갱신 + 하위 단위 리셋 ─────────────────────────────────
	private static void applyChunk(String[] chunks, int level, String itemStr, String subStr) {
		int item = parseIntSafe(itemStr, 0);
		int sub  = parseIntSafe(subStr,  0);
		chunks[level - 1] = pad3(item) + pad2(sub);
		for (int i = level; i < NUM_CHUNKS; i++) chunks[i] = "00000";
	}

	// ── row 빌더 ─────────────────────────────────────────────────
	private static ProvVrsnVO buildGroup(Long promNo, String nativeType, int level,
			String[] chunks, String title,
			String startDate, String sysId, String gaejungType, int globalIdx) {
		ProvVrsnVO v = baseVO(promNo, chunks, level, "BASE_TEXT_GROUP", nativeType,
				startDate, sysId, gaejungType, globalIdx);
		v.setTitle(safeTrim(title));
		v.setContents(null);
		return v;
	}

	private static ProvVrsnVO buildJo(Long promNo, String[] chunks, String title, String contents,
			String startDate, String sysId, String gaejungType, int globalIdx) {
		ProvVrsnVO v = baseVO(promNo, chunks, LV_JO, "BASE_TEXT", "S_JO",
				startDate, sysId, gaejungType, globalIdx);
		v.setTitle(safeTrim(title));
		v.setContents(emptyToNull(safeTrim(contents)));
		return v;
	}

	/**
	 * 단건 조 편집 폼(saveProvVrsn)이 보내는 본문을 STITLE/SCONTENTS 로 정규화한다.
	 * 폼은 provVrsnFragmentJson 가 조립한 "제N조(제목) 조본문&lt;br/&gt;①항…&lt;br/&gt;…" 형태로 보낸다.
	 *  - 숫자 문자참조(&#40; 등) 디코드
	 *  - 첫 &lt;br/&gt; 이전(= 조 라인)만 취함. 이후 하위항목(항/호/목)은 하위 row 소유이므로 조 본문에서 제외(중복 차단).
	 *  - 조 라인에서 "제N조(제목)" 라벨을 떼어 제목/본문 분리. 라벨이 본문에 박혀 매 편집마다 누적되던 버그 차단.
	 * @return [0]=제목(라벨에 제목 없으면 null), [1]=조 본문(라벨·하위항목 제거)
	 */
	public static String[] normalizeJoFormContent(String raw) {
		if (raw == null) return new String[] { null, null };
		String s = ProvViewRenderer.decodeNumericEntities(raw);
		s = s.replaceAll("(?i)<br\\s*/?>", "\n");          // plain textarea — <br/> 잔재를 개행으로
		int nl = s.indexOf('\n');
		String first = (nl >= 0) ? s.substring(0, nl) : s;
		String rest  = (nl >= 0) ? s.substring(nl + 1) : "";
		first = stripDupJoLabel(normalizeLine(first.trim()));   // 중복 라벨 제거 + 전각→반각
		String title = null, inline = "";
		Matcher m;
		if ((m = P_JO_TITLED.matcher(first)).matches())       { title = safeTrim(m.group(3)); inline = safeTrim(m.group(4)); }
		else if ((m = P_JO_DELETED.matcher(first)).matches()) { title = safeTrim(m.group(3)); inline = safeTrim(m.group(4)); }
		else if ((m = P_JO_BARE.matcher(first)).matches())    { inline = safeTrim(m.group(3)); }
		else                                                   { inline = first; }   // 조 라벨 없음 — 전체 본문
		StringBuilder body = new StringBuilder();
		if (inline != null && !inline.isEmpty()) body.append(inline);
		String restTrim = rest.replaceAll("\\s+$", "");
		if (restTrim.trim().length() > 0) {
			if (body.length() > 0) body.append('\n');
			body.append(restTrim);
		}
		return new String[] {
			(title == null || title.isEmpty()) ? null : title,
			body.length() == 0 ? null : body.toString()
		};
	}

	/** "제N조 제N조 제N조(제목)" 처럼 누적된 선두 조 라벨 중복 제거 → "제N조(제목)" (verbatim 저장 자가복구) */
	static String stripDupJoLabel(String line) {
		if (line == null) return null;
		Pattern lead = Pattern.compile("^\\s*제\\s*\\d+\\s*조(?:\\s*의\\s*\\d+)?\\s+(?=제\\s*\\d+\\s*조)");
		String s = line;
		int guard = 0;
		Matcher lm;
		while ((lm = lead.matcher(s)).find() && guard++ < 20) s = s.substring(lm.end());
		return s.trim();
	}

	private static ProvVrsnVO buildSub(Long promNo, String nativeType, int level,
			String[] chunks, String contents,
			String startDate, String sysId, String gaejungType, int globalIdx) {
		ProvVrsnVO v = baseVO(promNo, chunks, level, "SUB_TEXT", nativeType,
				startDate, sysId, gaejungType, globalIdx);
		v.setTitle(null);
		v.setContents(emptyToNull(safeTrim(contents)));
		return v;
	}

	private static ProvVrsnVO baseVO(Long promNo, String[] chunks, int level,
			String unitType, String nativeType,
			String startDate, String sysId, String gaejungType, int globalIdx) {
		ProvVrsnVO v = new ProvVrsnVO();
		v.setPromNo(promNo);
		v.setFullItem(concat(chunks));
		v.setItem(chunks[level - 1].substring(0, 3));
		v.setSubItem(chunks[level - 1].substring(3));
		v.setUnitType(unitType);
		v.setNativeType(nativeType);
		v.setLevel(level);
		// IINDEX = 레거시 의 패턴 배열 0-based 인덱스 (level-1) — provisionPatterns[v.getIndex()] 의미.
		// globalIdx 는 파서 디버깅용 — DB 에는 안 들어감.
		v.setIndex(level - 1);
		v.setGaejungType(gaejungType);
		v.setDispYn("Y");
		v.setStartDate(startDate);
		v.setSysId(sysId);
		v.setGaejungHideYn("N");
		v.setUserModifiedYn("N");        // 일괄 자동분해 = 사용자 수정 아님 (실DB 43920건 'N'. 단건 IDE 손편집만 'Y')
		v.setStyleId("NORMAL");          // SSTYLE_ID — 실DB 지배값 'NORMAL'(41839). 이전 'STYLE_NORMAL'(310)은 RLMS 오염분
		return v;
	}

	// 부칙 한 블록 → POST_SCRIPT row. 편(1-5) 청크 = "999"+부칙순번 → SFULL_ITEM 사전순 본문 뒤로 + 고유.
	private static ProvVrsnVO buildPostScript(Long promNo, int bylawSeq, String header,
			String startDate, String sysId, int globalIdx) {
		String[] chunks = new String[NUM_CHUNKS];
		for (int i = 0; i < NUM_CHUNKS; i++) chunks[i] = repeat('0', CHUNK_LEN);
		chunks[0] = "999" + pad2(bylawSeq);
		ProvVrsnVO v = baseVO(promNo, chunks, 1, "POST_SCRIPT", "S_POSTSCRIPT",
				startDate, sysId, null, globalIdx);
		v.setTitle(safeTrim(header));   // "부칙 <...>" 그대로 — 재조회→재저장 시 P_BYLAW 가 다시 인식
		v.setContents(null);
		return v;
	}

	/**
	 * 라인 정규화 — 법령 문서가 쓰는 전각 기호를 반각으로 통일 (전각이면 P_JO_TITLED 등 매칭 실패).
	 *   （）→() , 〈〉＜＞⟨⟩〈〉→<> , 전각숫자 ０-９→0-9 , 전각/비분리 공백→일반 공백.
	 */
	private static String normalizeLine(String s) {
		if (s == null) return "";
		StringBuilder sb = new StringBuilder(s.length());
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if      (c == '（') c = '(';
			else if (c == '）') c = ')';
			else if (c == '〈' || c == '＜' || c == '〈' || c == '⟨') c = '<';
			else if (c == '〉' || c == '＞' || c == '〉' || c == '⟩') c = '>';
			else if (c >= '０' && c <= '９') c = (char) ('0' + (c - '０'));
			else if (c == '　' || c == ' ') c = ' ';
			sb.append(c);
		}
		return sb.toString();
	}

	// ── 유틸 ─────────────────────────────────────────────────────
	private static String concat(String[] chunks) {
		StringBuilder sb = new StringBuilder(60);
		for (String c : chunks) sb.append(c);
		return sb.toString();
	}
	private static String pad3(int n) {
		if (n >= 100) return String.valueOf(n);
		if (n >= 10)  return "0"  + n;
		return                "00" + n;
	}
	private static String pad2(int n) { return n >= 10 ? String.valueOf(n) : "0" + n; }
	private static int parseIntSafe(String s, int def) {
		if (s == null || s.trim().isEmpty()) return def;
		try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return def; }
	}
	private static String safeTrim(String s) { return s == null ? null : s.trim(); }
	private static String emptyToNull(String s) { return (s == null || s.isEmpty()) ? null : s; }
	private static String repeat(char c, int n) {
		char[] a = new char[n]; java.util.Arrays.fill(a, c); return new String(a);
	}
	private static int circledToInt(char c) {
		// 원문자 항 번호 → 정수. 유니코드 원문자 3개 블록(1~50).
		if (c >= 0x2460 && c <= 0x2473) return c - 0x2460 + 1;    // ① ~ ⑳ = 1 ~ 20
		if (c >= 0x3251 && c <= 0x325F) return c - 0x3251 + 21;   // ㉑ ~ ㉟ = 21 ~ 35
		if (c >= 0x32B1 && c <= 0x32BF) return c - 0x32B1 + 36;   // ㊱ ~ ㊿ = 36 ~ 50
		return 0;
	}
	private static int korLetterToInt(char c) {
		String kor = "가나다라마바사아자차카타파하";
		int idx = kor.indexOf(c);
		return idx >= 0 ? idx + 1 : 0;
	}
}
