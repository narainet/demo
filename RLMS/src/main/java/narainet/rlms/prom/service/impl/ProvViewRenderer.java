/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/ProvViewRenderer.java
 *
 * 조문 누적 목록(List<ProvVrsnVO>) → 사용자 전문 뷰어 HTML 렌더러.
 * 레거시 ProvisionVersionUtil.getProvisionViewList / ProvisionPatternUtil.getHtml 이식.
 *
 *  · 계층 들여쓰기(편/장/절/관 → 조 → 항 → 호 → 목)
 *  · 번호/기호 prefix : 제N조(제목) / 원문자 항 ①②③ / 호 1. / 목 가. / 단 (1)
 *  · 개정유형 인라인 표시 : EQUAL 외 gaejungType 은 <개정/신설/조항이동…> 마크
 *  · 본문 HTML escape + 줄바꿈 <br>
 *  (토큰 [태그:…] 링크 치환은 별도 — 현재는 원문 유지)
 */
package narainet.rlms.prom.service.impl;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import narainet.rlms.docu.service.DocuVO;
import narainet.rlms.prom.service.ProvVrsnVO;

public class ProvViewRenderer {

	/**
	 * 누적 조문 목록 → 전문 뷰어 HTML.
	 * @param viewedPromNo 보는 회차 — 그 회차에서 바뀐 조문만 개정마크 표시(레거시 changedInformation)
	 * @param tokenResolver 본문 [태그:…] 관련자료 토큰 해석기(null 이면 토큰 미해석, 원문 escape)
	 * @param ctxPath request.getContextPath() — 다운로드 URL 접두
	 */
	public String render(List<ProvVrsnVO> rows, Long viewedPromNo,
			ProvTokenResolver tokenResolver, String ctxPath) {
		return render(rows, viewedPromNo, tokenResolver, ctxPath, null);
	}

	/** + 자동링크 컨텍스트(AutoLinkService.context) — null 이면 자동링크 무동작 */
	public String render(List<ProvVrsnVO> rows, Long viewedPromNo,
			ProvTokenResolver tokenResolver, String ctxPath, AutoLinkService.LinkContext linkCtx) {
		return render(rows, viewedPromNo, tokenResolver, ctxPath, linkCtx, null, null);
	}

	/** + 회차 날짜맵(promNo → "YYYY. M. D.")·제정 회차 — 조문 인라인 개정 주석(법제처 스타일, 2026-07-24).
	 *  누적 조문행의 소유 회차(promNo) = 그 조문이 마지막으로 바뀐 회차라는 누적모델 성질을 이용.
	 *  · 보는 회차 변경분 = 기존 강조마크에 날짜 부여(&lt;개정 2026. 7. 1.&gt;)
	 *  · 과거 회차 개정분(조문) = 회색 이력 주석(&lt;개정 날짜&gt; / [본조신설 날짜])
	 *  · 제정 회차(firstRoundNo) 원시 조문 = 무표기. roundDates null 이면 종전 동작 그대로. */
	public String render(List<ProvVrsnVO> rows, Long viewedPromNo,
			ProvTokenResolver tokenResolver, String ctxPath, AutoLinkService.LinkContext linkCtx,
			java.util.Map<Long, String> roundDates, Long firstRoundNo) {
		if (rows == null || rows.isEmpty()) {
			return "<p class=\"prov-empty\">표시할 조문이 없습니다.</p>";
		}
		List<ProvVrsnVO> sorted = new ArrayList<>(rows);
		sorted.sort(Comparator.comparing(v -> safe(v.getFullItem())));

		StringBuilder sb = new StringBuilder("<div class=\"prov-doc\">\n");
		for (ProvVrsnVO v : sorted) {
			String unit = safe(v.getUnitType());
			int indent = indentPx(v);
			String label, body = htmlBody(v.getContents(), tokenResolver, ctxPath, linkCtx);
			// 개정마크는 "이 회차에서 바뀐 조문"(소유 회차 == 보는 회차) 에만 — 레거시 changedInformation
			boolean changedHere = viewedPromNo == null
					|| (v.getPromNo() != null && viewedPromNo.equals(v.getPromNo()));
			String rev = changedHere ? revMark(v.getGaejungType(), dateFor(roundDates, v.getPromNo())) : "";

			if ("BASE_TEXT_GROUP".equals(unit)) {
				// 편/장/절/관/목 — 굵은 제목 행
				label = esc(groupLabel(v));
				sb.append("<div class=\"prov-group\" id=\"").append(grpAnchor(v)).append("\" style=\"margin-left:").append(indent).append("px\">")
				  .append("<b>").append(label).append("</b>").append(rev);
				if (!body.isEmpty()) sb.append("<div class=\"prov-body\">").append(body).append("</div>");
				sb.append("</div>\n");

			} else if ("BASE_TEXT".equals(unit)) {
				// 조 — "제N조(제목)" + 본문. 과거 회차 개정분은 회색 이력 주석(누적 최종개정일)
				String hist = changedHere ? "" : histMark(v.getGaejungType(), v.getPromNo(), roundDates, firstRoundNo);
				label = esc(joLabel(v));
				sb.append("<div class=\"prov-jo\" id=\"").append(joAnchor(v)).append("\" style=\"margin-left:").append(indent).append("px\">")
				  .append("<b class=\"prov-jo-label\">").append(label).append("</b>")
				  .append("<button type=\"button\" class=\"prov-info\" data-fi=\"").append(esc(safe(v.getFullItem())))
				  .append("\" data-jo=\"").append(label).append("\" title=\"조문 정보 관리\">&#9998;</button>");
				if (!body.isEmpty()) sb.append(" ").append(body);
				// 개정마크·이력주석은 본문 끝에 — 법령 표기 관례(<개정 2020. 1. 1.>)이자 항/호(SUB_TEXT) 와 같은 자리.
				// 제목 뒤에 두면 "제2조(소재지) <신설 …> 사무소는 …" 처럼 제목과 본문 사이가 끊긴다 (2026-07-31).
				sb.append(rev).append(hist);
				sb.append("</div>\n");

			} else if ("POST_SCRIPT".equals(unit)) {
				label = esc(safe(v.getTitle()).trim());
				sb.append("<div class=\"prov-postscript\" id=\"").append(grpAnchor(v)).append("\" style=\"margin-left:").append(indent).append("px\">")
				  .append("<b>[부칙] ").append(label).append("</b>").append(rev);
				if (!body.isEmpty()) sb.append("<div class=\"prov-body\">").append(body).append("</div>");
				sb.append("</div>\n");

			} else {
				// 항/호/목/단 (SUB_TEXT) — 기호 prefix + 본문 (한 줄)
				label = esc(subLabel(v));
				sb.append("<div class=\"prov-sub\" style=\"margin-left:").append(indent).append("px\">");
				if (!label.isEmpty()) sb.append("<span class=\"prov-sub-label\">").append(label).append("</span> ");
				sb.append(body).append(rev).append("</div>\n");
			}
		}
		sb.append("</div>");
		return sb.toString();
	}

	/**
	 * 별표/별지서식 누적 목록 → 본문 말미 섹션 HTML (law.go.kr 의 별표 목록 위치와 동일).
	 * 항목 = STITLE("[별표 1] 기구도") + 개정마크(보는 회차에서 바뀐 것만) + 본문(SCONTENTS — [태그:…] 토큰 해석).
	 * SDISP_YN='N'(tombstone — 이전 회차 대비 제거분) 은 숨김. 목록이 비면 빈 문자열.
	 */
	public String renderDocuSection(List<DocuVO> docus, Long viewedPromNo,
			ProvTokenResolver tokenResolver, String ctxPath) {
		return renderDocuSection(docus, viewedPromNo, tokenResolver, ctxPath, null);
	}

	/** + 자동링크 컨텍스트 — null 이면 자동링크 무동작 */
	public String renderDocuSection(List<DocuVO> docus, Long viewedPromNo,
			ProvTokenResolver tokenResolver, String ctxPath, AutoLinkService.LinkContext linkCtx) {
		if (docus == null || docus.isEmpty()) return "";
		StringBuilder sb = new StringBuilder();
		int shown = 0;
		for (DocuVO d : docus) {
			if (d == null || "N".equals(d.getDispYn())) continue;   // tombstone 숨김
			String g = d.getGaejungType() == null ? "" : d.getGaejungType().trim();
			if ("NULLIFY".equals(g)) continue;                       // 레거시 사용자측 — 삭제 별표 완전 숨김
			boolean changedHere = viewedPromNo == null
					|| (d.getPromNo() != null && viewedPromNo.equals(d.getPromNo()));
			String rev = changedHere ? revMark(g) : "";
			String body = htmlBody(d.getContents(), tokenResolver, ctxPath, linkCtx);
			String title = esc(safe(d.getTitle()).trim());
			if ("NULLIFY_SEMANTIC".equals(g)) title = "[폐지] " + title;   // 레거시 — 폐지는 표기 후 노출
			sb.append("<div class=\"prov-docu\" id=\"docu-").append(d.getDocuNo()).append("\">")
			  .append("<b class=\"prov-jo-label\">").append(title).append("</b>")
			  .append(rev);
			if (!body.isEmpty()) sb.append("<div class=\"prov-body\">").append(body).append("</div>");
			sb.append("</div>\n");
			shown++;
		}
		if (shown == 0) return "";
		return "<div class=\"prov-docu-sec\">\n"
				+ "<div class=\"prov-group\"><b>별표 / 별지서식</b></div>\n"
				+ sb + "</div>";
	}

	/**
	 * HTML형식조문(TB_PROV_HTML 누적 목록) → 전문 뷰어 HTML.
	 * 레거시 FLAG_HTML 모드(ProvisionHtmlUtil.getProvisionViewList) 대응 —
	 * 본문이 관리자가 작성한 신뢰 HTML 이므로 escape 없이 토큰만 치환.
	 * NULLIFY(삭제) 는 완전 숨김, NULLIFY_SEMANTIC(폐지) 는 [폐지] 표기 후 본문 표시.
	 */
	public String renderProvHtmlSection(List<narainet.rlms.prom.service.ProvHtmlVO> rows,
			Long viewedPromNo, ProvTokenResolver tokenResolver, String ctxPath) {
		return renderProvHtmlSection(rows, viewedPromNo, tokenResolver, ctxPath, null);
	}

	/** + 자동링크 컨텍스트 — null 이면 자동링크 무동작 (신뢰 HTML 은 태그 밖 텍스트만 링크화) */
	public String renderProvHtmlSection(List<narainet.rlms.prom.service.ProvHtmlVO> rows,
			Long viewedPromNo, ProvTokenResolver tokenResolver, String ctxPath,
			AutoLinkService.LinkContext linkCtx) {
		if (rows == null || rows.isEmpty()) {
			return "<p class=\"prov-empty\">표시할 조문이 없습니다.</p>";
		}
		StringBuilder sb = new StringBuilder("<div class=\"prov-doc\">\n");
		int shown = 0;
		for (narainet.rlms.prom.service.ProvHtmlVO h : rows) {
			if (h == null || "N".equals(h.getDispYn())) continue;
			String g = h.getGaejungType() == null ? "" : h.getGaejungType().trim();
			if ("NULLIFY".equals(g)) continue;                       // 레거시 GAEJUNG_NOT_BIND — 완전 숨김
			boolean changedHere = viewedPromNo == null
					|| (h.getPromNo() != null && viewedPromNo.equals(h.getPromNo()));
			String rev = changedHere ? revMark(g) : "";
			String title = esc(safe(h.getTitle()).trim());
			if ("NULLIFY_SEMANTIC".equals(g)) title = "[폐지] " + title;
			sb.append("<div class=\"prov-jo\" id=\"phtml-").append(h.getProvHtmlNo()).append("\">")
			  .append("<b class=\"prov-jo-label\">").append(title).append("</b>").append(rev)
			  .append("</div>\n");
			String body = safe(h.getContents()).trim();
			if (!body.isEmpty()) {
				String html = (tokenResolver != null)
						? tokenResolver.renderHtml(body, ctxPath, linkCtx) : body;
				sb.append("<div class=\"prov-body prov-html-body\">").append(html).append("</div>\n");
			}
			shown++;
		}
		sb.append("</div>");
		if (shown == 0) return "<p class=\"prov-empty\">표시할 조문이 없습니다.</p>";
		return sb.toString();
	}

	// ── 개정유형 인라인 마크 (EQUAL/null 은 표시 안 함) ──
	private String revMark(String g) {
		return revMark(g, null);
	}

	/** + 날짜("YYYY. M. D.") — 있으면 법제처 표기처럼 마크에 병기: &lt;개정 2026. 7. 1.&gt; */
	private String revMark(String g, String date) {
		if (g == null) return "";
		String t = g.trim();
		String label;
		switch (t) {
			case "":            case "EQUAL":  return "";
			case "NEW":                    label = "신설";            break;
			case "MODIFY":                 label = "개정";            break;   // 별표/HTML조문 도메인
			case "NULLIFY_SEMANTIC":       label = "폐지";            break;   // 별표/HTML조문 도메인
			case "MODIFY_ALL":             label = "전부개정";        break;
			case "MODIFY_TITLE":           label = "제목개정";        break;
			case "MODIFY_CONTENTS":        label = "본문개정";        break;
			case "MOVE_ALL":               label = "조항이동";        break;
			case "MOVE_TITLE_MODIFY_CONTENTS": label = "조항이동·본문개정"; break;
			case "MOVE_CONTENTS_MODIFY_TITLE": label = "조항이동·제목개정"; break;
			default:                       label = t;                 break;   // NULLIFY 류는 보통 숨겨져 도달 안 함
		}
		String d = (date == null || date.isEmpty()) ? "" : (" " + esc(date));
		return " <span class=\"prov-rev prov-rev-" + esc(t) + "\">&lt;" + esc(label) + d + "&gt;</span>";
	}

	/** 과거 회차 개정분 누적 이력 주석 — 제정 회차 원시 조문·날짜 미상은 무표기. */
	private String histMark(String gaejungType, Long ownerNo, java.util.Map<Long, String> roundDates, Long firstRoundNo) {
		if (roundDates == null || ownerNo == null || firstRoundNo == null || ownerNo.equals(firstRoundNo)) {
			return "";
		}
		String d = roundDates.get(ownerNo);
		if (d == null || d.isEmpty()) return "";
		boolean isNew = "NEW".equals(safe(gaejungType).trim());
		return isNew
				? " <span class=\"prov-hist\">[본조신설 " + esc(d) + "]</span>"
				: " <span class=\"prov-hist\">&lt;개정 " + esc(d) + "&gt;</span>";
	}

	private static String dateFor(java.util.Map<Long, String> roundDates, Long promNo) {
		return (roundDates == null || promNo == null) ? null : roundDates.get(promNo);
	}

	// ── 들여쓰기(px) — nativeType 계층 기준 ──
	private int indentPx(ProvVrsnVO v) {
		String nt = safe(v.getNativeType());
		switch (nt) {
			case "F_PYUN": case "F_JANG":              return 0;
			case "F_JEOL": case "F_GWAN": case "F_MOK1": return 18;
			case "S_JO":                               return 0;
			case "S_HANG":                             return 22;
			case "S_HO": case "S_HO2":                 return 44;
			case "S_MOK2": case "S_DAN2":              return 66;
			default:                                   return 0;
		}
	}

	// ── 라벨 빌더 (PromEditorController 와 동일 규칙) ──
	private String groupLabel(ProvVrsnVO g) {
		int item = parseIntSafe(g.getItem(), -1);
		int sub  = parseIntSafe(g.getSubItem(), 0);
		String suffix = groupSuffix(g.getNativeType());
		StringBuilder sb = new StringBuilder();
		if (item >= 0 && suffix != null) {
			sb.append("제").append(item).append(suffix);
			if (sub > 0) sb.append("의").append(sub);
		} else if (notBlank(g.getItem())) {
			sb.append(g.getItem().trim());
		}
		String title = safe(g.getTitle()).trim();
		if (!title.isEmpty() && !"null".equalsIgnoreCase(title)) {
			if (sb.length() > 0) sb.append(" ");
			sb.append(title);
		}
		if (sb.length() == 0) sb.append(safe(g.getFullItem()));
		return sb.toString();
	}

	private String joLabel(ProvVrsnVO j) {
		int item = parseIntSafe(j.getItem(), -1);
		int sub  = parseIntSafe(j.getSubItem(), 0);
		StringBuilder sb = new StringBuilder();
		if (item >= 0) {
			sb.append("제").append(item).append("조");
			if (sub > 0) sb.append("의").append(sub);
		} else if (notBlank(j.getItem())) {
			sb.append(j.getItem().trim());
		}
		String title = decodeNumericEntities(safe(j.getTitle())).trim();
		// 레거시 데이터 정합: 일부 조 제목에 "제N조" 가 포함됨(예: "제1조 (목적)") → 중복 표기 방지로 앞 조번호 제거
		title = title.replaceFirst("^제\\s*\\d+\\s*조(?:의\\s*\\d+)?\\s*", "");
		// 제목이 이미 (…) 로 감싸진 경우 한 겹 제거(아래에서 다시 감쌈 → 이중 괄호 방지)
		if (title.length() >= 2 && title.startsWith("(") && title.endsWith(")")) {
			title = title.substring(1, title.length() - 1).trim();
		}
		if (!title.isEmpty() && !"null".equalsIgnoreCase(title)) {
			if (title.contains("삭제")) sb.append("<").append(title).append(">");
			else                        sb.append("(").append(title).append(")");
		}
		if (sb.length() == 0) sb.append(safe(j.getFullItem()));
		return sb.toString();
	}

	private String subLabel(ProvVrsnVO v) {
		String nt = v.getNativeType();
		int item = parseIntSafe(v.getItem(), 0);
		if (nt == null) return safe(v.getTitle()).trim();
		switch (nt) {
			case "S_HANG": return circledNum(item);
			case "S_HO":   return item > 0 ? item + "."   : "";
			case "S_HO2":  return item > 0 ? item + ")"   : "";
			case "S_MOK2": return item > 0 ? korLetter(item) + "." : "";
			case "S_DAN2": return item > 0 ? "(" + item + ")" : "";
			default:       return safe(v.getTitle()).trim();
		}
	}

	private String groupSuffix(String nt) {
		if (nt == null) return null;
		switch (nt) {
			case "F_PYUN": return "편";
			case "F_JANG": return "장";
			case "F_JEOL": return "절";
			case "F_GWAN": return "관";
			case "F_MOK1": return "목";
			default:       return null;
		}
	}

	private String circledNum(int n) {
		// 정수 → 원문자 항 번호. 유니코드 원문자 3개 블록(1~50). 범위 밖은 "n." 폴백.
		if (n >= 1  && n <= 20) return String.valueOf((char) (0x2460 + n - 1));   // ① ~ ⑳
		if (n >= 21 && n <= 35) return String.valueOf((char) (0x3251 + n - 21));  // ㉑ ~ ㉟
		if (n >= 36 && n <= 50) return String.valueOf((char) (0x32B1 + n - 36));  // ㊱ ~ ㊿
		return n > 0 ? n + "." : "";
	}
	private String korLetter(int n) {
		String[] kor = {"가","나","다","라","마","바","사","아","자","차","카","타","파","하"};
		if (n < 1) return "";
		if (n > kor.length) return n + ".";
		return kor[n - 1];
	}

	// ── 본문 → HTML (관련자료 토큰 해석 + 자동링크 + escape + 줄바꿈) ──
	private String htmlBody(String contents, ProvTokenResolver resolver, String ctxPath,
			AutoLinkService.LinkContext linkCtx) {
		if (contents == null) return "";
		String s = contents.trim();
		if (s.isEmpty()) return "";
		s = decodeNumericEntities(s);   // 레거시 임포트 데이터의 &#40; 등 숫자참조 → 실제 문자
		if (resolver != null) return resolver.render(s, ctxPath, linkCtx);   // 토큰 해석(내부에서 escape)+자동링크
		return esc(s).replace("\n", "<br>");
	}

	// ── 조/그룹/부칙 앵커 id (좌측 조문목차 점프 + 본문 내 상호참조 대상) ──
	private String joAnchor(ProvVrsnVO v) {
		int item = parseIntSafe(v.getItem(), -1);
		int sub  = parseIntSafe(v.getSubItem(), 0);
		if (item < 0) return "jo-" + safeId(v.getFullItem());
		return sub > 0 ? ("jo-" + item + "-" + sub) : ("jo-" + item);
	}
	private String grpAnchor(ProvVrsnVO v) { return "grp-" + safeId(v.getFullItem()); }
	private static String safeId(String s) { return s == null ? "x" : s.replaceAll("[^0-9A-Za-z_-]", ""); }

	/** 레거시 임포트 데이터의 숫자 문자참조(&#40; / &#x28; 등) 를 실제 문자로 복원 — 이중 escape 로 리터럴 노출되던 문제 해결 */
	public static String decodeNumericEntities(String s) {
		if (s == null || s.indexOf("&#") < 0) return s;
		java.util.regex.Matcher m = java.util.regex.Pattern.compile("&#(x?)([0-9A-Fa-f]+);").matcher(s);
		StringBuffer sb = new StringBuffer();
		while (m.find()) {
			try {
				int cp = m.group(1).isEmpty() ? Integer.parseInt(m.group(2)) : Integer.parseInt(m.group(2), 16);
				m.appendReplacement(sb, java.util.regex.Matcher.quoteReplacement(new String(Character.toChars(cp))));
			} catch (Exception e) { m.appendReplacement(sb, java.util.regex.Matcher.quoteReplacement(m.group(0))); }
		}
		m.appendTail(sb);
		return sb.toString();
	}

	private static String esc(String s) {
		if (s == null) return "";
		s = decodeNumericEntities(s);
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
	}
	private static String safe(String s) { return s == null ? "" : s; }
	private static boolean notBlank(String s) { return s != null && !s.trim().isEmpty(); }
	private int parseIntSafe(String s, int def) {
		if (s == null) return def;
		try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return def; }
	}
}
