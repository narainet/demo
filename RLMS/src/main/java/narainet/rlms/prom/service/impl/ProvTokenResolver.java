/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/ProvTokenResolver.java
 *
 * 조문 본문(SCONTENTS) 안의 관련자료 토큰 [태그:…] → 링크/이미지/HTML 치환.
 * 레거시 RelatedService.getReplaceTags 이식. promEditor.jsp 의 클립보드 토큰 형식과 1:1.
 *
 *  파일/원본 : [태그:파일:relVrsnNo]제목[/태그]        → 다운로드 <a>
 *  일반이미지: [태그:일반이미지:relVrsnNo]             → <img>
 *  HTML      : [태그:HTML:relVrsnNo]                  → 인라인 HTML
 *  링크      : [태그:링크:URL]제목[/태그]             → 외부 <a target=_blank>
 *  도메인링크: [태그:도메인링크:flag:Y:::fullItem:]제목[/태그] → 규정연계 표시(제목)
 *  워드이미지: [태그:워드이미지:relVrsnNo]            → 마커(변환 미지원)
 *
 * 일반 텍스트 구간은 HTML escape, 토큰만 해석 — 한 번의 토큰 분해로 처리(XSS 안전).
 */
package narainet.rlms.prom.service.impl;

import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import narainet.rlms.related.mapper.RelFileMapper;
import narainet.rlms.related.mapper.RelHtmlMapper;
import narainet.rlms.related.mapper.RelImgMapper;
import narainet.rlms.related.mapper.RelLnkMapper;
import narainet.rlms.related.mapper.RelOrgnMapper;
import narainet.rlms.related.service.RelFileVO;
import narainet.rlms.related.service.RelHtmlVO;
import narainet.rlms.related.service.RelImgVO;
import narainet.rlms.related.service.RelLnkVO;
import narainet.rlms.related.service.RelOrgnVO;

@Service("provTokenResolver")
public class ProvTokenResolver {

	@Resource(name = "relFileMapper") private RelFileMapper relFileMapper;
	@Resource(name = "relOrgnMapper") private RelOrgnMapper relOrgnMapper;
	@Resource(name = "relImgMapper")  private RelImgMapper  relImgMapper;
	@Resource(name = "relHtmlMapper") private RelHtmlMapper relHtmlMapper;
	@Resource(name = "relLnkMapper")  private RelLnkMapper  relLnkMapper;
	@Resource(name = "autoLinkService") private AutoLinkService autoLinkService;

	private static final String DL = "/rlms/related/attachDownload.do?attNo=";

	// 닫는 태그 있는 토큰(파일/링크/도메인링크) + 닫는 태그 없는 토큰(워드이미지/일반이미지/HTML) 통합 — 완결 단위 매칭
	private static final Pattern TOKEN = Pattern.compile(
			"\\[태그:(?:파일|링크|도메인링크):[^\\]]*\\].*?\\[/태그\\]"   // 제목+닫기 류
			+ "|\\[태그:(?:워드이미지|일반이미지|HTML):[0-9]+\\]",        // 단독 류
			Pattern.DOTALL);
	private static final Pattern CLOSING = Pattern.compile(
			"\\[태그:(파일|링크|도메인링크):([^\\]]*)\\](.*?)\\[/태그\\]", Pattern.DOTALL);
	private static final Pattern STANDALONE = Pattern.compile(
			"\\[태그:(워드이미지|일반이미지|HTML):([0-9]+)\\]");

	/** 본문(평문+토큰) → HTML. ctxPath = request.getContextPath() (다운로드 URL 접두) */
	public String render(String contents, String ctxPath) {
		return render(contents, ctxPath, true, null);
	}

	/** 본문(평문+토큰) → HTML + 자동링크(등록 규정명 → 뷰어 <a>). linkCtx=null 이면 자동링크 무동작 */
	public String render(String contents, String ctxPath, AutoLinkService.LinkContext linkCtx) {
		return render(contents, ctxPath, true, linkCtx);
	}

	/**
	 * HTML형식조문(TB_PROV_HTML 등 신뢰 HTML 본문)용 — 일반 구간을 escape 하지 않고
	 * [태그:…] 토큰만 치환. 레거시 ProvisionHtmlUtil + getReplaceTags 경로 대응.
	 */
	public String renderHtml(String contents, String ctxPath) {
		return render(contents, ctxPath, false, null);
	}

	/** HTML형식조문 + 자동링크(태그 밖 텍스트런만 링크화) */
	public String renderHtml(String contents, String ctxPath, AutoLinkService.LinkContext linkCtx) {
		return render(contents, ctxPath, false, linkCtx);
	}

	private String render(String contents, String ctxPath, boolean escapePlain,
			AutoLinkService.LinkContext linkCtx) {
		if (contents == null || contents.isEmpty()) return "";
		String ctx = ctxPath == null ? "" : ctxPath;
		Matcher m = TOKEN.matcher(contents);
		StringBuilder sb = new StringBuilder();
		int last = 0;
		while (m.find()) {
			String plain = contents.substring(last, m.start());      // 일반 구간
			sb.append(plainHtml(plain, escapePlain, linkCtx));
			sb.append(resolve(m.group(), ctx));                      // 토큰
			last = m.end();
		}
		String tail = contents.substring(last);
		sb.append(plainHtml(tail, escapePlain, linkCtx));
		return sb.toString();
	}

	/** 일반(비토큰) 구간 → HTML. 자동링크 컨텍스트가 있으면 등록 규정명을 <a> 로 치환. */
	private String plainHtml(String plain, boolean escapePlain, AutoLinkService.LinkContext linkCtx) {
		if (plain == null || plain.isEmpty()) return "";
		if (linkCtx == null || autoLinkService == null) {
			return escapePlain ? escBr(plain) : plain;
		}
		return escapePlain
				? autoLinkService.linkifyEscape(plain, linkCtx)   // 원문 매칭 → 비매치 escBr + 매치 <a>
				: autoLinkService.linkifyHtml(plain, linkCtx);    // 태그 밖 텍스트런만 링크화
	}

	private String resolve(String token, String ctx) {
		Matcher c = CLOSING.matcher(token);
		if (c.matches()) {
			String type = c.group(1), arg = c.group(2), title = c.group(3);
			switch (type) {
				case "파일":       return fileLink(arg, title, ctx);
				case "링크":       return urlLink(arg, title);
				case "도메인링크": return dmnLink(title);
				default: break;
			}
		}
		Matcher s = STANDALONE.matcher(token);
		if (s.matches()) {
			String type = s.group(1);
			Long no = parseLong(s.group(2));
			switch (type) {
				case "일반이미지": return imgTag(no, ctx);
				case "HTML":       return htmlBlock(no);
				case "워드이미지": return "<span class=\"rel-word\">[워드문서]</span>";
				default: break;
			}
		}
		return escBr(token);   // 해석 실패 — 원문(escape) 노출
	}

	// 파일/원본 — relVrsnNo 로 첨부 조회 후 다운로드 링크
	private String fileLink(String arg, String title, String ctx) {
		Long relVrsnNo = parseLong(arg);
		String t = (title == null || title.trim().isEmpty()) ? "첨부파일" : title.trim();
		if (relVrsnNo != null) {
			List<RelFileVO> fs = relFileMapper.selectByRelVrsnNo(relVrsnNo);
			if (fs != null && !fs.isEmpty() && fs.get(0).getAttNo() != null) {
				RelFileVO f = fs.get(0);
				String ext = f.getAttExt() != null ? " ("+esc(f.getAttExt())+")" : "";
				return "<a class=\"rel-file\" href=\"" + ctx + DL + f.getAttNo() + "\">" + esc(t) + ext + "</a>";
			}
			List<RelOrgnVO> os = relOrgnMapper.selectByRelVrsnNo(relVrsnNo);
			if (os != null && !os.isEmpty() && os.get(0).getAttNo() != null) {
				return "<a class=\"rel-file\" href=\"" + ctx + DL + os.get(0).getAttNo() + "\">" + esc(t) + "</a>";
			}
		}
		return "<span class=\"rel-file rel-missing\">" + esc(t) + "</span>";
	}

	private String imgTag(Long relVrsnNo, String ctx) {
		if (relVrsnNo != null) {
			List<RelImgVO> imgs = relImgMapper.selectByRelVrsnNo(relVrsnNo);
			if (imgs != null && !imgs.isEmpty() && imgs.get(0).getAttNo() != null) {
				RelImgVO im = imgs.get(0);
				String alt = im.getTitle() != null ? esc(im.getTitle()) : "이미지";
				return "<img class=\"rel-img\" src=\"" + ctx + DL + im.getAttNo() + "\" alt=\"" + alt + "\">";
			}
		}
		return "<span class=\"rel-img rel-missing\">[이미지]</span>";
	}

	private String htmlBlock(Long relVrsnNo) {
		if (relVrsnNo != null) {
			List<RelHtmlVO> hs = relHtmlMapper.selectByRelVrsnNo(relVrsnNo);
			if (hs != null && !hs.isEmpty() && hs.get(0).getHtml() != null) {
				// 편집기에서 저장된 신뢰 HTML — 그대로 인라인
				return "<div class=\"rel-html\">" + hs.get(0).getHtml() + "</div>";
			}
		}
		return "<span class=\"rel-html rel-missing\">[HTML]</span>";
	}

	private String urlLink(String url, String title) {
		String u = url == null ? "" : url.trim();
		String t = (title == null || title.trim().isEmpty()) ? u : title.trim();
		if (u.isEmpty()) return esc(t);
		return "<a class=\"rel-link\" href=\"" + esc(u) + "\" target=\"_blank\" rel=\"noopener\">" + esc(t) + "</a>";
	}

	// 도메인링크 — 토큰 메타(빈 lawId/lawNo)만으로는 대상 확정 어려움 → 규정연계 표시(제목)
	private String dmnLink(String title) {
		String t = (title == null || title.trim().isEmpty()) ? "규정 연계" : title.trim();
		return "<span class=\"rel-dmnlnk\" title=\"규정 연계\">" + esc(t) + "</span>";
	}

	// ── util ──
	private static String escBr(String s) { return esc(s).replace("\n", "<br>"); }
	private static String esc(String s) {
		if (s == null) return "";
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
	}
	private static Long parseLong(String s) {
		if (s == null) return null;
		try { return Long.valueOf(s.trim()); } catch (NumberFormatException e) { return null; }
	}
}
