/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/PromDocExporter.java
 *
 * 규정 전문 → 문서 내보내기 (본문저장 / 연혁일괄저장).
 *   · PDF  : flying-saucer(core-renderer R8) + iText 2.0.8 — XHTML→PDF, 한글 TTF 임베딩.
 *   · DOCX : POI 미사용(xmlbeans 충돌 회피) — 순수 ZIP + WordprocessingML 직접 생성.
 *
 * 입력은 뷰어와 동일한 렌더 HTML(ProvViewRenderer 결과) + 서문(SPREAMBLE)/부칙(SBYLAW) CLOB.
 * 본문 HTML 은 JSoup 으로 정규화(XHTML)하여 PDF 파서에 안전하게 전달하고,
 * DOCX 는 의미 블록(.prov-* / p / div)을 문단으로 변환한다(이미지/버튼/링크는 텍스트만 유지).
 *
 * 상태가 없는 POJO — 컨트롤러가 직접 new 해서 사용.
 */
package narainet.rlms.prom.service.impl;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.TextNode;
import org.jsoup.select.Elements;

import org.xhtmlrenderer.pdf.ITextRenderer;

import com.lowagie.text.pdf.BaseFont;

public class PromDocExporter {

	/** 내보낼 한 회차(=한 규정 본문) 단위. */
	public static class Section {
		public String title;        // 규정 제목
		public String metaLine;     // [시행 …] [공포 …] · 개정구분
		public String preambleHtml; // 서문 (SPREAMBLE, nullable)
		public String bodyHtml;     // provHtml + docuHtml (ProvViewRenderer 결과)
		public String bylawHtml;    // 부칙 (SBYLAW, nullable)
	}

	// 본문 의미 블록(ProvViewRenderer 산출) — 문단 1:1 매핑 대상
	private static final String BODY_BLOCKS =
			".prov-group, .prov-jo, .prov-sub, .prov-postscript, .prov-docu";

	// ─────────────────────────────────────────────────────────────────
	// PDF
	// ─────────────────────────────────────────────────────────────────

	/** 섹션들 → PDF 바이트. fontPath = 한글 TTF(예: C:/Windows/Fonts/malgun.ttf). */
	public byte[] toPdf(List<Section> sections, String docTitle, String fontPath) throws Exception {
		String xhtml = toXhtml(sections, docTitle);
		ITextRenderer renderer = new ITextRenderer();
		try {
			if (fontPath != null && new java.io.File(fontPath).exists()) {
				renderer.getFontResolver().addFont(fontPath, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
			}
		} catch (Exception ignore) {
			// 폰트 등록 실패해도 PDF 자체는 생성(한글이 깨질 수 있음) — 호출측에서 fontPath 점검
		}
		renderer.setDocumentFromString(xhtml);
		renderer.layout();
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		renderer.createPDF(out);
		return out.toByteArray();
	}

	/** 섹션들 → flying-saucer 가 파싱 가능한 완결 XHTML(이미지/버튼 제거, 링크는 텍스트화). */
	private String toXhtml(List<Section> sections, String docTitle) {
		StringBuilder b = new StringBuilder();
		b.append("<html><head><meta charset=\"UTF-8\"/><style>")
		 .append("@page{size:A4;margin:18mm 16mm;}")
		 .append("body{font-family:'Malgun Gothic',sans-serif;font-size:11pt;line-height:1.6;color:#111;}")
		 .append("h1.doc-title{font-size:18pt;text-align:center;margin:0 0 4px;}")
		 .append("p.doc-meta{font-size:9.5pt;text-align:center;color:#555;margin:0 0 14px;border-bottom:1px solid #888;padding-bottom:8px;}")
		 .append("h2.sec{font-size:12pt;border-left:4px solid #345;padding-left:6px;margin:16px 0 6px;}")
		 .append(".prov-group{font-weight:bold;margin:12px 0 4px;}")
		 .append(".prov-jo{margin:8px 0;}.prov-jo-label{font-weight:bold;}")
		 .append(".prov-sub{margin:3px 0;}.prov-postscript{margin:14px 0 6px;font-weight:bold;}")
		 .append(".prov-docu{margin:8px 0;}.prov-body{margin-top:2px;}")
		 .append(".page-break{page-break-before:always;}")
		 .append("</style></head><body>");
		boolean first = true;
		for (Section s : sections) {
			if (s == null) continue;
			b.append("<div class=\"").append(first ? "prom-sec" : "prom-sec page-break").append("\">");
			first = false;
			b.append("<h1 class=\"doc-title\">").append(esc(s.title)).append("</h1>");
			if (notBlank(s.metaLine)) {
				b.append("<p class=\"doc-meta\">").append(esc(s.metaLine)).append("</p>");
			}
			if (notBlank(stripTags(s.preambleHtml))) {
				b.append("<h2 class=\"sec\">서문</h2>").append(s.preambleHtml);
			}
			if (notBlank(s.bodyHtml)) {
				b.append(s.bodyHtml);
			}
			if (notBlank(stripTags(s.bylawHtml))) {
				b.append("<h2 class=\"sec\">부칙</h2>").append(s.bylawHtml);
			}
			b.append("</div>");
		}
		b.append("</body></html>");

		// JSoup 정규화 → XHTML(완결 태그). 이미지/버튼 제거, 링크는 텍스트만 유지.
		Document doc = Jsoup.parse(b.toString());
		doc.select("img, button").remove();
		doc.select("a").unwrap();
		// 인라인 font-family 제거 — 서문/부칙 CLOB(HWP 에디터)은 글자마다 font-family:한양견고딕 등
		// 미임베딩 폰트를 지정해 flying-saucer 가 해당 글리프를 누락시킴. 임베딩한 본문 폰트로 통일.
		for (Element el : doc.select("[style]")) {
			String st = el.attr("style");
			if (st != null && st.toLowerCase().contains("font-family")) {
				el.attr("style", st.replaceAll("(?i)font-family\\s*:[^;]*;?", ""));
			}
		}
		doc.outputSettings()
		   .syntax(Document.OutputSettings.Syntax.xml)
		   .escapeMode(org.jsoup.nodes.Entities.EscapeMode.xhtml)
		   .charset("UTF-8")
		   .prettyPrint(false);
		return doc.html();
	}

	// ─────────────────────────────────────────────────────────────────
	// DOCX (순수 ZIP + WordprocessingML)
	// ─────────────────────────────────────────────────────────────────

	private static final String CONTENT_TYPES =
			"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
			+ "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
			+ "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
			+ "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
			+ "<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>"
			+ "</Types>";

	private static final String DOT_RELS =
			"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
			+ "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
			+ "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>"
			+ "</Relationships>";

	/** 섹션들 → DOCX 바이트. */
	public byte[] toDocx(List<Section> sections, String docTitle) throws Exception {
		StringBuilder body = new StringBuilder();
		boolean first = true;
		for (Section s : sections) {
			if (s == null) continue;
			if (!first) pageBreak(body);
			first = false;
			para(body, runBold(s.title), 0, "title");
			if (notBlank(s.metaLine)) para(body, run(s.metaLine, false), 0, "meta");
			if (notBlank(stripTags(s.preambleHtml))) {
				para(body, runBold("서문"), 0, "head");
				genericHtmlToParas(s.preambleHtml, body);
			}
			if (notBlank(s.bodyHtml)) bodyHtmlToParas(s.bodyHtml, body);
			if (notBlank(stripTags(s.bylawHtml))) {
				para(body, runBold("부칙"), 0, "head");
				genericHtmlToParas(s.bylawHtml, body);
			}
		}
		String documentXml =
				"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
				+ "<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\"><w:body>"
				+ body
				+ "<w:sectPr><w:pgSz w:w=\"11906\" w:h=\"16838\"/>"
				+ "<w:pgMar w:top=\"1134\" w:right=\"1134\" w:bottom=\"1134\" w:left=\"1134\" w:header=\"720\" w:footer=\"720\" w:gutter=\"0\"/></w:sectPr>"
				+ "</w:body></w:document>";

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		ZipOutputStream zos = new ZipOutputStream(baos);
		zos.setLevel(6);
		zipPut(zos, "[Content_Types].xml", CONTENT_TYPES);
		zipPut(zos, "_rels/.rels", DOT_RELS);
		zipPut(zos, "word/document.xml", documentXml);
		zos.finish();
		zos.close();
		return baos.toByteArray();
	}

	// ─────────────────────────────────────────────────────────────────
	// HWPX (한컴오피스 OWPML) — 순수 ZIP + XML. hwpxlib 미사용(오프라인 저장소에 없음).
	//   보일러플레이트(mimetype/version/settings/container/manifest/content.hpf/header.xml)는
	//   실제 .hwpx 패키지에서 추출한 템플릿 리소스(/hwpx/**)를 그대로 재사용하고,
	//   Contents/section0.xml 만 규정 본문으로 생성한다(문자/문단/스타일 ID는 헤더의 기본값 0 참조).
	// ─────────────────────────────────────────────────────────────────

	/** 섹션들 → HWPX 바이트. */
	public byte[] toHwpx(List<Section> sections, String docTitle) throws Exception {
		String secOpen = new String(readResource("/hwpx/frag-section0-open.frag"), "UTF-8");
		String secPr   = new String(readResource("/hwpx/frag-secpr.frag"), "UTF-8");

		StringBuilder sec = new StringBuilder(secOpen);
		boolean[] firstPara = { true };   // 첫 문단의 run 에 secPr(쪽 설정) 삽입
		boolean firstSection = true;
		for (Section s : sections) {
			if (s == null) continue;
			// 제목 — 가운데 정렬(paraPr 29) + 굵게 16pt(charPr 19). 섹션 시작(2번째부터 쪽나눔).
			hpPara(sec, runT(s.title, 19), 29, firstPara, !firstSection, secPr);
			firstSection = false;
			if (notBlank(s.metaLine)) hpPara(sec, runT(s.metaLine, 0), 29, firstPara, false, secPr);
			if (notBlank(stripTags(s.preambleHtml))) {
				hpPara(sec, runT("[서문]", 18), 0, firstPara, false, secPr);
				for (String ln : genericHtmlToLines(s.preambleHtml)) hpPara(sec, runT(ln, 0), 0, firstPara, false, secPr);
			}
			// 본문 — 의미 블록별: 굵게 감지 runs(조 제목 등) + 계층 들여쓰기 paraPr(항/호/목)
			for (Object[] blk : bodyHtmlToBlocks(s.bodyHtml)) {
				hpPara(sec, (String) blk[0], levelPara(((Integer) blk[1]).intValue()), firstPara, false, secPr);
			}
			if (notBlank(stripTags(s.bylawHtml))) {
				hpPara(sec, runT("[부칙]", 18), 0, firstPara, false, secPr);
				for (String ln : genericHtmlToLines(s.bylawHtml)) hpPara(sec, runT(ln, 0), 0, firstPara, false, secPr);
			}
		}
		// 내용이 전혀 없으면 secPr 만 담은 빈 문단이라도 보장
		if (firstPara[0]) hpPara(sec, runT("", 0), 0, firstPara, false, secPr);
		// 문서 끝 빈 문단(한글 관례)
		sec.append("<hp:p id=\"0\" paraPrIDRef=\"0\" styleIDRef=\"0\" pageBreak=\"0\" columnBreak=\"0\" merged=\"0\"/>");
		sec.append("</hs:sec>");
		byte[] section0 = sec.toString().getBytes("UTF-8");

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		ZipOutputStream zos = new ZipOutputStream(baos);
		// mimetype — 반드시 STORED(무압축) 첫 엔트리
		byte[] mime = readResource("/hwpx/mimetype");
		ZipEntry me = new ZipEntry("mimetype");
		me.setMethod(ZipEntry.STORED);
		me.setSize(mime.length);
		me.setCompressedSize(mime.length);
		CRC32 crc = new CRC32(); crc.update(mime); me.setCrc(crc.getValue());
		zos.putNextEntry(me); zos.write(mime); zos.closeEntry();
		// 나머지 — DEFLATED(기본)
		zos.setLevel(6);
		zipPut(zos, "version.xml",            readResource("/hwpx/version.xml"));
		zipPut(zos, "settings.xml",           readResource("/hwpx/settings.xml"));
		zipPut(zos, "META-INF/container.xml", readResource("/hwpx/META-INF/container.xml"));
		zipPut(zos, "META-INF/manifest.xml",  readResource("/hwpx/META-INF/manifest.xml"));
		zipPut(zos, "Contents/header.xml",    readResource("/hwpx/Contents/header.xml"));
		zipPut(zos, "Contents/content.hpf",   readResource("/hwpx/Contents/content.hpf"));
		zipPut(zos, "Contents/section0.xml",  section0);
		zos.finish();
		zos.close();
		return baos.toByteArray();
	}

	/** 구성된 run 들 → OWPML 문단(hp:p, paraPrIDRef 적용). 첫 문단이면 secPr 를 별도 run 으로 선삽입. */
	private void hpPara(StringBuilder out, String runsXml, int paraPrId, boolean[] firstPara, boolean pageBreak, String secPr) {
		out.append("<hp:p id=\"0\" paraPrIDRef=\"").append(paraPrId)
		   .append("\" styleIDRef=\"0\" pageBreak=\"").append(pageBreak ? "1" : "0")
		   .append("\" columnBreak=\"0\" merged=\"0\">");
		if (firstPara[0]) { out.append("<hp:run charPrIDRef=\"0\">").append(secPr).append("</hp:run>"); firstPara[0] = false; }
		out.append(runsXml).append("</hp:p>");
	}

	/** 한 줄 텍스트 → 단일 run (charPrId 글자모양). */
	private String runT(String text, int charPrId) {
		return "<hp:run charPrIDRef=\"" + charPrId + "\"><hp:t>" + escXml(text == null ? "" : text) + "</hp:t></hp:run>";
	}

	/** 계층 레벨 → 문단모양 ID (0=조/장, 1=항, 2=호, 3+=목). */
	private int levelPara(int level) {
		switch (level) { case 0: return 0; case 1: return 30; case 2: return 31; default: return 32; }
	}

	// 본문(ProvViewRenderer 결과) → 의미 블록별 {runsXml(굵게 감지), 들여쓰기 레벨}
	private List<Object[]> bodyHtmlToBlocks(String html) {
		List<Object[]> out = new ArrayList<>();
		Document d = Jsoup.parseBodyFragment(safe(html));
		d.select("button, img").remove();
		Elements blocks = d.select(BODY_BLOCKS);
		if (blocks.isEmpty()) {
			for (String ln : genericHtmlToLines(html)) out.add(new Object[]{ runT(ln, 0), Integer.valueOf(0) });
			return out;
		}
		for (Element blk : blocks) {
			String runs = owpmlRunsOf(blk);
			if (stripXml(runs).trim().isEmpty()) continue;
			int lvl = marginLeftTwips(blk) / (22 * 15);   // px*15=twips, 22px=1단계
			out.add(new Object[]{ runs, Integer.valueOf(lvl) });
		}
		return out;
	}

	/** 한 블록의 자식 노드 → OWPML run 들 (<b>/<strong> 조상 → 굵게 charPr 18, 그 외 0). */
	private String owpmlRunsOf(Element block) {
		StringBuilder sb = new StringBuilder();
		owpmlRuns(block, false, sb);
		return sb.toString();
	}
	private void owpmlRuns(Node node, boolean bold, StringBuilder sb) {
		for (Node c : node.childNodes()) {
			if (c instanceof TextNode) {
				String t = ((TextNode) c).text();
				if (t != null && !t.isEmpty())
					sb.append("<hp:run charPrIDRef=\"").append(bold ? 18 : 0).append("\"><hp:t>")
					  .append(escXml(t)).append("</hp:t></hp:run>");
			} else if (c instanceof Element) {
				Element e = (Element) c;
				String tag = e.tagName().toLowerCase();
				if ("br".equals(tag)) { sb.append("<hp:run charPrIDRef=\"0\"><hp:t> </hp:t></hp:run>"); continue; }
				if ("button".equals(tag) || "img".equals(tag)) continue;
				boolean b2 = bold || "b".equals(tag) || "strong".equals(tag);
				owpmlRuns(e, b2, sb);
			}
		}
	}

	// 임의 HTML(서문/부칙) → 줄 목록 (leaf 블록 우선, 없으면 <br>/텍스트 분해)
	private List<String> genericHtmlToLines(String html) {
		List<String> lines = new ArrayList<>();
		Document d = Jsoup.parseBodyFragment(safe(html));
		d.select("button, img").remove();
		Elements blocks = d.body().select("p, div, li, h1, h2, h3, h4, h5, h6, tr");
		boolean any = false;
		for (Element blk : blocks) {
			if (!blk.select("p, div, li, tr").isEmpty()) continue;
			String t = blk.text().trim();
			if (!t.isEmpty()) { lines.add(t); any = true; }
		}
		if (!any) {
			String marked = safe(html).replaceAll("(?i)<br[^>]*>", "~~~BR~~~");
			String text = Jsoup.parse(marked).text();   // 태그제거+엔티티디코드, 마커는 텍스트라 보존
			for (String ln : text.split("~~~BR~~~")) {
				String t = ln.trim();
				if (!t.isEmpty()) lines.add(t);
			}
		}
		return lines;
	}

	/** 클래스패스 리소스 → 바이트. */
	private byte[] readResource(String path) throws Exception {
		try (InputStream in = PromDocExporter.class.getResourceAsStream(path)) {
			if (in == null) throw new IllegalStateException("hwpx 템플릿 리소스를 찾지 못함: " + path);
			ByteArrayOutputStream b = new ByteArrayOutputStream();
			byte[] buf = new byte[8192]; int n;
			while ((n = in.read(buf)) > 0) b.write(buf, 0, n);
			return b.toByteArray();
		}
	}

	private void zipPut(ZipOutputStream zos, String name, byte[] content) throws Exception {
		zos.putNextEntry(new ZipEntry(name));
		zos.write(content);
		zos.closeEntry();
	}

	// 본문(ProvViewRenderer 결과) → 의미 블록별 문단
	private void bodyHtmlToParas(String html, StringBuilder out) {
		Document d = Jsoup.parseBodyFragment(safe(html));
		d.select("button, img").remove();
		Elements blocks = d.select(BODY_BLOCKS);
		if (blocks.isEmpty()) { genericHtmlToParas(html, out); return; }
		for (Element blk : blocks) {
			int indent = marginLeftTwips(blk);
			String runs = runsOf(blk);
			if (notBlank(stripXml(runs))) para(out, runs, indent, "body");
		}
	}

	// 임의 HTML(서문/부칙) → 문단 (leaf 블록 기준, 없으면 전체를 한 문단)
	private void genericHtmlToParas(String html, StringBuilder out) {
		Document d = Jsoup.parseBodyFragment(safe(html));
		d.select("button, img").remove();
		Elements blocks = d.body().select("p, div, li, h1, h2, h3, h4, h5, h6, tr");
		boolean emitted = false;
		for (Element blk : blocks) {
			if (!blk.select("p, div, li, tr").isEmpty()) continue;   // 컨테이너는 건너뛰고 leaf 만
			String runs = runsOf(blk);
			if (notBlank(stripXml(runs))) { para(out, runs, marginLeftTwips(blk), "body"); emitted = true; }
		}
		if (!emitted) {
			String runs = runsOf(d.body());
			if (notBlank(stripXml(runs))) para(out, runs, 0, "body");
		}
	}

	/** 한 블록의 자식 노드 → WordML run 들(텍스트 노드별, <b>/<strong> 조상 → bold, <br> → 줄바꿈). */
	private String runsOf(Element block) {
		StringBuilder sb = new StringBuilder();
		appendRuns(block, false, sb);
		return sb.toString();
	}
	private void appendRuns(Node node, boolean bold, StringBuilder sb) {
		for (Node c : node.childNodes()) {
			if (c instanceof TextNode) {
				String t = ((TextNode) c).text();
				if (t != null && !t.isEmpty()) sb.append(run(t, bold));
			} else if (c instanceof Element) {
				Element e = (Element) c;
				String tag = e.tagName().toLowerCase();
				if ("br".equals(tag)) { sb.append("<w:r><w:br/></w:r>"); continue; }
				if ("button".equals(tag) || "img".equals(tag)) continue;
				boolean b2 = bold || "b".equals(tag) || "strong".equals(tag);
				appendRuns(e, b2, sb);
			}
		}
	}

	// style="margin-left:NNpx" → twips(px*15). 없으면 0.
	private int marginLeftTwips(Element el) {
		String st = el.attr("style");
		if (st == null) return 0;
		java.util.regex.Matcher m = java.util.regex.Pattern.compile("margin-left\\s*:\\s*(\\d+)\\s*px").matcher(st);
		if (m.find()) { try { return Integer.parseInt(m.group(1)) * 15; } catch (Exception e) { return 0; } }
		return 0;
	}

	// ── WordML 헬퍼 ──
	private void para(StringBuilder out, String runsXml, int indentTwips, String kind) {
		out.append("<w:p><w:pPr>");
		if (indentTwips > 0) out.append("<w:ind w:left=\"").append(indentTwips).append("\"/>");
		if ("title".equals(kind)) out.append("<w:jc w:val=\"center\"/><w:spacing w:before=\"120\" w:after=\"40\"/>");
		else if ("meta".equals(kind)) out.append("<w:jc w:val=\"center\"/><w:spacing w:after=\"160\"/>");
		else if ("head".equals(kind)) out.append("<w:spacing w:before=\"160\" w:after=\"60\"/>");
		out.append("</w:pPr>").append(runsXml).append("</w:p>");
	}
	private void pageBreak(StringBuilder out) {
		out.append("<w:p><w:r><w:br w:type=\"page\"/></w:r></w:p>");
	}
	private String run(String text, boolean bold) {
		return "<w:r><w:rPr>" + (bold ? "<w:b/>" : "") + "</w:rPr>"
				+ "<w:t xml:space=\"preserve\">" + escXml(text) + "</w:t></w:r>";
	}
	private String runBold(String text) { return run(safe(text), true); }

	private void zipPut(ZipOutputStream zos, String name, String content) throws Exception {
		zos.putNextEntry(new ZipEntry(name));
		zos.write(content.getBytes("UTF-8"));
		zos.closeEntry();
	}

	// ── 유틸 ──
	private static boolean notBlank(String s) { return s != null && !s.trim().isEmpty(); }
	private static String safe(String s) { return s == null ? "" : s; }
	private static String stripTags(String s) {
		if (s == null) return "";
		return s.replaceAll("<[^>]*>", "").replace("&nbsp;", "").trim();
	}
	private static String stripXml(String s) {
		if (s == null) return "";
		return s.replaceAll("<[^>]*>", "").replace("&amp;", "").replace("&lt;", "").replace("&gt;", "").trim();
	}
	private static String esc(String s) {
		if (s == null) return "";
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
	}
	private static String escXml(String s) {
		if (s == null) return "";
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}
}
