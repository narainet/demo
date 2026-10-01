/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/AutoLinkService.java
 *
 * 규정 본문 자동링크 엔진 — RLMS 자체 설계 (2026-07-16, 레거시 미참조).
 *
 * 원칙:
 *   · 사전(registry) 기반 — 링크 후보 = 시스템에 등록된 "현행+유효" 규정의 제목/부제만.
 *     미등록 규정명은 애초에 사전에 없으므로 절대 링크되지 않는다.
 *   · 렌더 시점 계산 — 링크를 저장물에 굽지 않는다. 규정이 나중에 등록/폐지되면
 *     다음 렌더부터 전 규정 본문에 자동 반영(소급 배치 불필요).
 *   · 최장일치 + 참조 연쇄 소비 — "장애인차별금지법 제4장 제4조" 는 규정명을 먼저 잡고
 *     뒤따르는 제N장/제N조 참조를 한 덩어리로 소비해 그 규정(+조 앵커 #jo-N)으로 링크.
 *     규정명 없이 단독으로 나온 "제N조/제N장" 단편은 이 엔진이 링크하지 않는다
 *     (자기문서 상호참조는 뷰어 클라이언트 lvInitBody 가 앵커 실재 확인 후 별도 처리).
 *   · 자동링크 제외범위(TB_REL_EXCL_LNK, IDE F3 화면) 소비 — 보는 규정(viewLawId)의
 *     제외 대상(구분/분류+하위/특정규정)은 사전에서 걸러 링크하지 않는다.
 *   · 동명이규정 = 목록 팝업 — 같은 이름이 여러 규정이면 <a class="prov-autolink-multi">
 *     + data-cands(JSON) 로 내려 뷰어 JS 가 후보 팝업을 띄운다.
 *
 * 삽입 지점: ProvTokenResolver.render() 의 "평문 구간" 처리(escape 직전 원문 기준 매칭)
 *   → 전문뷰어 + 관리자 미리보기 + 별표 + 내보내기(PDF/DOCX/HWPX) 동시 커버.
 *
 * 캐시: MenuHelper 관례(60초 TTL, 불변 스냅샷, 실패는 빈 사전으로 fail-soft).
 *   현행 승격/삭제 시 clearDictCache() 훅으로 즉시 무효화.
 */
package narainet.rlms.prom.service.impl;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import narainet.rlms.cate.mapper.CateMapper;
import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.relexcl.mapper.RelExclLnkMapper;
import narainet.rlms.relexcl.service.RelExclLnkVO;

@Service("autoLinkService")
public class AutoLinkService {

	@Resource(name = "promMapper")       private PromMapper       promMapper;
	@Resource(name = "cateMapper")       private CateMapper       cateMapper;
	@Resource(name = "relExclLnkMapper") private RelExclLnkMapper relExclLnkMapper;

	private static final String VIEWER_URL = "/rlms/fulltext/provisionList.do?promNo=";

	/** 너무 짧은 이름은 오탐(일반명사 충돌) 위험 — 사전 등재 최소 길이 */
	private static final int MIN_NAME_LEN = 2;

	// ── 사전 캐시 (MenuHelper 패턴 — 전역 1스냅샷 + TTL) ──────────────
	private static final long CACHE_TTL_MS = 60_000L;
	private static volatile Dict DICT;

	/** 현행 승격/규정 삭제 등 사전이 바뀌는 시점에 호출 — 다음 렌더에서 재적재 */
	public static void clearDictCache() { DICT = null; }

	private static final class Entry {
		final String name; final Long lawId; final Long promNo;
		final Long cateNo; final String gubunId; final String cateNm;
		Entry(String name, Long lawId, Long promNo, Long cateNo, String gubunId, String cateNm) {
			this.name = name; this.lawId = lawId; this.promNo = promNo;
			this.cateNo = cateNo; this.gubunId = gubunId; this.cateNm = cateNm;
		}
	}

	private static final class Dict {
		final long ts;
		final Map<Character, List<String>> namesByFirst;   // 첫 글자 → 이름들(길이 내림차순 = 최장일치)
		final Map<String, List<Entry>> byName;             // 이름 → 규정들(동명 복수 가능)
		Dict(long ts, Map<Character, List<String>> namesByFirst, Map<String, List<Entry>> byName) {
			this.ts = ts; this.namesByFirst = namesByFirst; this.byName = byName;
		}
		boolean isEmpty() { return byName.isEmpty(); }
	}

	private Dict dict() {
		Dict d = DICT;
		long now = System.currentTimeMillis();
		if (d != null && now - d.ts < CACHE_TTL_MS) return d;
		Dict built;
		try {
			built = buildDict(now);
		} catch (Exception e) {
			// fail-soft — 사전 적재 실패가 뷰어를 깨면 안 됨. 빈 사전(링크 없음)으로 귀결.
			built = new Dict(now, Collections.<Character, List<String>>emptyMap(),
					Collections.<String, List<Entry>>emptyMap());
		}
		DICT = built;
		return built;
	}

	private Dict buildDict(long now) {
		List<PromVO> rows = promMapper.selectAutoLinkDict();
		Map<String, List<Entry>> byName = new HashMap<>();
		if (rows != null) {
			for (PromVO p : rows) {
				if (p == null || p.getLawId() == null || p.getPromNo() == null) continue;
				addName(byName, p.getTitle(), p);
				addName(byName, p.getSubTitle(), p);   // 부제(영문명·약칭)로도 인용됨 — 사전 포함
			}
		}
		Map<Character, List<String>> byFirst = new HashMap<>();
		for (String name : byName.keySet()) {
			char c = name.charAt(0);
			List<String> list = byFirst.get(c);
			if (list == null) { list = new ArrayList<>(); byFirst.put(c, list); }
			list.add(name);
		}
		for (List<String> list : byFirst.values()) {
			list.sort((a, b) -> b.length() - a.length());   // 최장일치 우선
		}
		return new Dict(now, byFirst, byName);
	}

	private void addName(Map<String, List<Entry>> byName, String raw, PromVO p) {
		if (raw == null) return;
		String name = raw.trim();
		if (name.length() < MIN_NAME_LEN) return;
		List<Entry> list = byName.get(name);
		if (list == null) { list = new ArrayList<>(); byName.put(name, list); }
		// 같은 규정(lawId)이 제목=부제 등으로 중복 등재되는 것 방지
		for (Entry e : list) if (e.lawId.equals(p.getLawId())) return;
		list.add(new Entry(name, p.getLawId(), p.getPromNo(), p.getCateNo(), p.getGubunId(), p.getCateNm()));
	}

	// ── 렌더 1회 컨텍스트 (보는 규정 + 제외범위 확장) ──────────────────
	public static final class LinkContext {
		final Long viewLawId;
		final String ctxPath;
		final Set<String> exclGubuns;
		final Set<Long>   exclCates;    // 하위분류까지 확장된 집합
		final Set<Long>   exclLawIds;
		LinkContext(Long viewLawId, String ctxPath,
				Set<String> exclGubuns, Set<Long> exclCates, Set<Long> exclLawIds) {
			this.viewLawId = viewLawId; this.ctxPath = ctxPath == null ? "" : ctxPath;
			this.exclGubuns = exclGubuns; this.exclCates = exclCates; this.exclLawIds = exclLawIds;
		}
	}

	/**
	 * 보는 규정(viewLawId) 기준 컨텍스트 생성 — 렌더(페이지) 1회만 호출.
	 * 제외범위 로드/분류 하위확장(집합 1회 CONNECT BY) 실패는 빈 제외집합으로 fail-soft.
	 */
	public LinkContext context(Long viewLawId, String ctxPath) {
		Set<String> gubuns = new HashSet<>();
		Set<Long> cates = new HashSet<>();
		Set<Long> laws  = new HashSet<>();
		try {
			if (viewLawId != null) {
				List<RelExclLnkVO> excl = relExclLnkMapper.selectExclList(viewLawId, null);
				List<Long> cateRoots = new ArrayList<>();
				if (excl != null) {
					for (RelExclLnkVO r : excl) {
						if (r == null || r.getFlag() == null) continue;
						switch (r.getFlag()) {
							case "full_text_gubun":    if (r.getGubunId() != null) gubuns.add(r.getGubunId()); break;
							case "full_text_category": if (r.getCateNo()  != null) cateRoots.add(r.getCateNo()); break;
							case "full_text_leaf":     if (r.getLawId()   != null) laws.add(r.getLawId()); break;
							default: break;
						}
					}
				}
				if (!cateRoots.isEmpty()) {
					// 하위분류 포함 확장 — 행별 CONNECT BY 금지, 시작점 일괄 집합 1회
					List<Long> expanded = cateMapper.selectDescendantSetIncludingSelf(cateRoots);
					if (expanded != null) cates.addAll(expanded);
				}
			}
		} catch (Exception e) {
			gubuns.clear(); cates.clear(); laws.clear();   // fail-soft
		}
		return new LinkContext(viewLawId, ctxPath, gubuns, cates, laws);
	}

	// ── 매칭 ───────────────────────────────────────────────────────────
	/** 규정명 바로 뒤에 붙는 참조 연쇄 1단위: "제 4장" / "4조" / "제4조의2" / "제3항" … */
	private static final Pattern REF_ONE = Pattern.compile(
			"[ \\t,]*(?:제\\s*)?(\\d{1,4})\\s*(편|장|절|관|조|항|호)(?:\\s*의\\s*(\\d{1,3}))?");

	private static final class Hit {
		int start, end;            // 링크 텍스트 전체 [start, end)
		List<Entry> entries;       // 제외 필터 통과분 (1=단일링크, 2+=목록팝업)
		Integer jo, joSub;         // 첫 "조" 참조 → #jo-N[-M]
	}

	private List<Hit> scan(String text, LinkContext lc) {
		List<Hit> hits = new ArrayList<>();
		Dict d = dict();
		if (text == null || text.isEmpty() || d.isEmpty()) return hits;
		int i = 0, n = text.length();
		while (i < n) {
			List<String> cands = d.namesByFirst.get(text.charAt(i));
			// 단어 시작 검사 — 직전 글자가 문자/숫자면 다른 단어의 꼬리("인사규정" 속 "사규정") 매칭 금지
			if (cands == null || (i > 0 && Character.isLetterOrDigit(text.charAt(i - 1)))) { i++; continue; }
			String matched = null;
			for (String name : cands) {                       // 길이 내림차순 → 최장일치
				if (text.startsWith(name, i)) { matched = name; break; }
			}
			if (matched == null) { i++; continue; }
			List<Entry> es = filter(d.byName.get(matched), lc);
			int nameEnd = i + matched.length();
			if (es.isEmpty()) { i = nameEnd; continue; }      // 전부 제외(자기자신/제외범위) → 링크 없음
			Hit h = new Hit();
			h.start = i; h.entries = es;
			// 참조 연쇄 소비 — "제 4장 4조" 를 한 덩어리로 (단편 오링크의 근원 차단)
			int refEnd = nameEnd;
			Matcher m = REF_ONE.matcher(text);
			while (refEnd < n) {
				m.region(refEnd, n);
				if (!m.lookingAt()) break;
				if (h.jo == null && "조".equals(m.group(2))) {
					h.jo = parseIntSafe(m.group(1));
					h.joSub = m.group(3) != null ? parseIntSafe(m.group(3)) : null;
				}
				refEnd = m.end();
			}
			h.end = refEnd;
			hits.add(h);
			i = refEnd;
		}
		return hits;
	}

	private List<Entry> filter(List<Entry> all, LinkContext lc) {
		if (all == null || all.isEmpty()) return Collections.emptyList();
		List<Entry> out = new ArrayList<>(all.size());
		for (Entry e : all) {
			if (lc.viewLawId != null && lc.viewLawId.equals(e.lawId)) continue;        // 자기 자신
			if (e.gubunId != null && lc.exclGubuns.contains(e.gubunId)) continue;      // 구분 제외
			if (e.cateNo  != null && lc.exclCates.contains(e.cateNo))   continue;      // 분류(하위 포함) 제외
			if (lc.exclLawIds.contains(e.lawId)) continue;                             // 특정 규정 제외
			out.add(e);
		}
		return out;
	}

	// ── 출력 조립 ──────────────────────────────────────────────────────
	/**
	 * VERSION 조문/별표 평문 구간용 — 원문 기준 매칭 후, 비매치 구간은 escBr(escape+줄바꿈),
	 * 매치 구간은 <a> 로 감싼다. lc=null 이면 escBr 와 동일(자동링크 무동작).
	 */
	public String linkifyEscape(String plain, LinkContext lc) {
		if (plain == null || plain.isEmpty()) return "";
		if (lc == null) return escBr(plain);
		List<Hit> hits;
		try { hits = scan(plain, lc); } catch (Exception e) { hits = Collections.emptyList(); }
		if (hits.isEmpty()) return escBr(plain);
		StringBuilder sb = new StringBuilder(plain.length() + 64);
		int last = 0;
		for (Hit h : hits) {
			sb.append(escBr(plain.substring(last, h.start)));
			sb.append(anchorHtml(plain.substring(h.start, h.end), h, lc));
			last = h.end;
		}
		sb.append(escBr(plain.substring(last)));
		return sb.toString();
	}

	/**
	 * HTML형식조문(신뢰 HTML) 구간용 — 태그 밖 텍스트런만 링크화. 기존 <a> 내부·script/style 은 통과.
	 */
	public String linkifyHtml(String html, LinkContext lc) {
		if (html == null || html.isEmpty() || lc == null) return html == null ? "" : html;
		StringBuilder sb = new StringBuilder(html.length() + 64);
		String lower = html.toLowerCase();
		int i = 0, n = html.length(), aDepth = 0;
		while (i < n) {
			if (html.charAt(i) == '<') {
				int gt = html.indexOf('>', i);
				if (gt < 0) { sb.append(html, i, n); break; }
				String tagLower = lower.substring(i, gt + 1);
				if (tagLower.startsWith("<a") && (tagLower.length() > 2 && !Character.isLetterOrDigit(tagLower.charAt(2)))) {
					aDepth++;
				} else if (tagLower.startsWith("</a")) {
					aDepth = Math.max(0, aDepth - 1);
				} else if (tagLower.startsWith("<script") || tagLower.startsWith("<style")) {
					String close = tagLower.startsWith("<script") ? "</script" : "</style";
					int end = lower.indexOf(close, gt + 1);
					if (end < 0) { sb.append(html, i, n); break; }
					int endGt = html.indexOf('>', end);
					if (endGt < 0) { sb.append(html, i, n); break; }
					sb.append(html, i, endGt + 1);
					i = endGt + 1;
					continue;
				}
				sb.append(html, i, gt + 1);
				i = gt + 1;
				continue;
			}
			int lt = html.indexOf('<', i);
			if (lt < 0) lt = n;
			String run = html.substring(i, lt);
			if (aDepth == 0) sb.append(linkifyRaw(run, lc));
			else sb.append(run);
			i = lt;
		}
		return sb.toString();
	}

	/** 이미-HTML 인 텍스트런: 비매치는 그대로, 매치만 <a> 래핑 (추가 escape 없음) */
	private String linkifyRaw(String run, LinkContext lc) {
		List<Hit> hits;
		try { hits = scan(run, lc); } catch (Exception e) { hits = Collections.emptyList(); }
		if (hits.isEmpty()) return run;
		StringBuilder sb = new StringBuilder(run.length() + 64);
		int last = 0;
		for (Hit h : hits) {
			sb.append(run, last, h.start);
			sb.append(anchorHtml(run.substring(h.start, h.end), h, lc));
			last = h.end;
		}
		sb.append(run, last, run.length());
		return sb.toString();
	}

	private String anchorHtml(String text, Hit h, LinkContext lc) {
		String label = esc(text);
		if (h.entries.size() == 1) {
			Entry e = h.entries.get(0);
			StringBuilder href = new StringBuilder(lc.ctxPath).append(VIEWER_URL).append(e.promNo);
			if (h.jo != null) {
				href.append("#jo-").append(h.jo);
				if (h.joSub != null && h.joSub > 0) href.append('-').append(h.joSub);
			}
			return "<a class=\"prov-autolink\" href=\"" + href + "\" title=\"" + esc(e.name)
					+ (e.cateNm != null ? " — " + esc(e.cateNm) : "") + "\">" + label + "</a>";
		}
		// 동명이규정 — 후보 목록 팝업 (뷰어 JS 가 data-cands 소비)
		StringBuilder cands = new StringBuilder("[");
		for (int i = 0; i < h.entries.size(); i++) {
			Entry e = h.entries.get(i);
			if (i > 0) cands.append(',');
			cands.append("{\"p\":").append(e.promNo)
			     .append(",\"t\":\"").append(jsonEsc(e.name)).append('"')
			     .append(",\"c\":\"").append(jsonEsc(e.cateNm == null ? "" : e.cateNm)).append("\"}");
		}
		cands.append(']');
		String jo = h.jo == null ? "" : (h.joSub != null && h.joSub > 0 ? h.jo + "-" + h.joSub : String.valueOf(h.jo));
		return "<a class=\"prov-autolink prov-autolink-multi\" href=\"#\" data-jo=\"" + jo
				+ "\" data-cands=\"" + esc(cands.toString()) + "\" title=\"동명 규정 " + h.entries.size()
				+ "건 — 클릭하여 선택\">" + label + "</a>";
	}

	// ── util ──
	private static String escBr(String s) { return esc(s).replace("\n", "<br>"); }
	private static String esc(String s) {
		if (s == null) return "";
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
	}
	private static String jsonEsc(String s) {
		if (s == null) return "";
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", " ");
	}
	private static Integer parseIntSafe(String s) {
		if (s == null) return null;
		try { return Integer.valueOf(s.trim()); } catch (NumberFormatException e) { return null; }
	}
}
