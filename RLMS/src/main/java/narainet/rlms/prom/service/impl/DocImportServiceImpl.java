/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/DocImportServiceImpl.java
 *
 * DocImportService 구현 — Word/.docx + 한컬오피스/.hwpx 평문 추출.
 *
 *  .docx : ZIP 컨테이너 안 word/document.xml (OOXML WordprocessingML) 를 SAX 로 파싱.
 *           POI(XWPFWordExtractor) 를 쓰지 않는 이유: poi-ooxml 5.2.5 는 xmlbeans 5.x 를 요구하나
 *           프로젝트는 eGov 표준 ems 메일 모듈 때문에 xmlbeans 2.6.0 을 고정해야 함(pom 주석 참고).
 *           둘은 한 클래스패스에서 비호환 → .docx 는 순수 ZIP+SAX(추가 의존성 0) 로 처리.
 *           - <w:p>      문단     → 줄바꿈
 *           - <w:t>...   텍스트   → 본문
 *           - <w:tab/>   탭
 *           - <w:br/> / <w:cr/> 줄바꿈
 *  .hwpx : ZIP 컨테이너 안 Contents/section0.xml,section1.xml... (OWPML) 를 SAX 로 파싱
 *           - <hp:p>      문단     → 줄바꿈
 *           - <hp:t>...   텍스트   → 본문
 *           - <hp:tab/>   탭
 *           - <hp:lineBreak/> 강제 줄바꿈
 *           네임스페이스 prefix 변동 대비 → localName("p","t","tab","lineBreak") 으로 매칭.
 *
 *  추출 후 normalizeForProvision(): 앞뒤 공백 정리 + 3줄 이상 연속 빈줄 → 1줄.
 *  (조문 구조 분해는 저장 시 ProvTextParser 가 담당하므로 여기선 평문만 정돈)
 */
package narainet.rlms.prom.service.impl;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.springframework.stereotype.Service;
import org.xml.sax.Attributes;
import org.xml.sax.helpers.DefaultHandler;

import narainet.rlms.prom.service.DocImportService;

@Service("docImportService")
public class DocImportServiceImpl implements DocImportService {

    @Override
    public String extractPlainText(String fileName, byte[] bytes) throws Exception {
        if (fileName == null) throw new IllegalArgumentException("파일명이 없습니다.");
        String lower = fileName.toLowerCase();
        String raw;
        if (lower.endsWith(".docx")) {
            raw = extractDocx(bytes);
        } else if (lower.endsWith(".hwpx")) {
            raw = extractHwpx(bytes);
        } else if (lower.endsWith(".hwp")) {
            throw new UnsupportedOperationException(".hwp 는 지원하지 않습니다. 한컬오피스에서 .hwpx 로 저장한 뒤 올려주세요.");
        } else {
            throw new UnsupportedOperationException("지원하지 않는 형식: " + fileName + " (.docx 또는 .hwpx 만 지원)");
        }
        return normalizeForProvision(raw);
    }

    @Override
    public String extractRawText(String fileName, byte[] bytes) throws Exception {
        if (fileName == null) return null;
        String lower = fileName.toLowerCase();
        String raw;
        if (lower.endsWith(".docx")) {
            raw = extractDocx(bytes);
        } else if (lower.endsWith(".hwpx")) {
            raw = extractHwpx(bytes);
        } else if (lower.endsWith(".pdf")) {
            raw = extractPdf(bytes);                 // 통합검색 자료 본문 인덱싱 — PDFBox
        } else if (lower.endsWith(".doc")) {
            raw = extractDoc(bytes);                 // 통합검색 자료 본문 인덱싱 — 구 Word(HWPF)
        } else {
            // .hwp(바이너리)·.xls 등 = 자체변환 미지원 → null (호출측이 원본만 보관)
            return null;
        }
        return lightNormalize(raw);
    }

    /** 일반 문서용 경량 정돈 — CR 제거 / 줄끝 공백 trim / 3줄↑ 연속 빈줄 → 1줄. (규정-특화 정규화 없음) */
    private String lightNormalize(String raw) {
        if (raw == null) return "";
        String[] lines = raw.replace("\r", "").split("\n", -1);
        StringBuilder sb = new StringBuilder();
        int blank = 0;
        for (String line : lines) {
            String t = line.replaceAll("[ \t]+$", "");
            if (t.trim().isEmpty()) {
                blank++;
                if (blank <= 1) sb.append('\n');
                continue;
            }
            blank = 0;
            sb.append(t).append('\n');
        }
        return sb.toString().trim();
    }

    /** .docx → ZIP 안 word/document.xml SAX 파싱 (POI 미사용, 추가 의존성 0) */
    private String extractDocx(byte[] bytes) throws Exception {
        byte[] docXml = null;
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(bytes))) {
            ZipEntry e;
            byte[] buf = new byte[8192];
            while ((e = zis.getNextEntry()) != null) {
                if ("word/document.xml".equals(e.getName())) {
                    java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream();
                    int n;
                    while ((n = zis.read(buf)) > 0) bos.write(buf, 0, n);
                    docXml = bos.toByteArray();
                    // word/document.xml 은 1개뿐 — 더 읽을 필요 없음
                }
                zis.closeEntry();
            }
        }
        if (docXml == null) {
            throw new IllegalStateException("docx 안에서 word/document.xml 을 찾지 못했습니다. (올바른 .docx 인가요?)");
        }
        SAXParserFactory spf = SAXParserFactory.newInstance();
        spf.setNamespaceAware(false);   // qName 으로 직접 매칭
        StringBuilder out = new StringBuilder();
        spf.newSAXParser().parse(new ByteArrayInputStream(docXml), new DocxHandler(out));
        return out.toString();
    }

    /** OOXML(WordprocessingML) SAX 핸들러 — <w:p>→줄바꿈, <w:t>본문, tab/br/cr 처리 */
    private static class DocxHandler extends DefaultHandler {
        private final StringBuilder out;
        private final StringBuilder para = new StringBuilder();
        private boolean inText = false;

        DocxHandler(StringBuilder out) { this.out = out; }

        private static boolean is(String qName, String local) {
            return qName.equals(local) || qName.endsWith(":" + local);
        }

        @Override
        public void startElement(String uri, String localName, String qName, Attributes attrs) {
            if (is(qName, "t"))                          inText = true;
            else if (is(qName, "tab"))                   para.append('\t');
            else if (is(qName, "br") || is(qName, "cr")) para.append('\n');
        }
        @Override
        public void characters(char[] ch, int start, int length) {
            if (inText) para.append(ch, start, length);
        }
        @Override
        public void endElement(String uri, String localName, String qName) {
            if (is(qName, "t")) inText = false;
            else if (is(qName, "p")) {
                out.append(para).append('\n');
                para.setLength(0);
            }
        }
    }

    /** .hwpx → ZIP 안 Contents/section*.xml SAX 파싱 */
    private String extractHwpx(byte[] bytes) throws Exception {
        // 1) 섹션 XML 들을 순서대로 수집
        List<String> sectionNames = new ArrayList<>();
        // ZIP을 두 번 읽지 않도록 이름→내용 매핑 캐시
        java.util.Map<String,byte[]> entries = new java.util.HashMap<>();
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(bytes))) {
            ZipEntry e;
            byte[] buf = new byte[8192];
            while ((e = zis.getNextEntry()) != null) {
                String name = e.getName();
                if (name.startsWith("Contents/section") && name.endsWith(".xml")) {
                    java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream();
                    int n;
                    while ((n = zis.read(buf)) > 0) bos.write(buf, 0, n);
                    entries.put(name, bos.toByteArray());
                    sectionNames.add(name);
                }
                zis.closeEntry();
            }
        }
        if (sectionNames.isEmpty()) {
            throw new IllegalStateException("hwpx 안에서 Contents/section*.xml 을 찾지 못했습니다. (올바른 .hwpx 인가요?)");
        }
        Collections.sort(sectionNames); // section0, section1, ...

        StringBuilder all = new StringBuilder();
        SAXParserFactory spf = SAXParserFactory.newInstance();
        spf.setNamespaceAware(false);   // qName 으로 직접 매칭
        SAXParser parser = spf.newSAXParser();

        for (String name : sectionNames) {
            HwpxHandler handler = new HwpxHandler(all);
            parser.parse(new ByteArrayInputStream(entries.get(name)), handler);
        }
        return all.toString();
    }

    /** OWPML SAX 핸들러 — <hp:p>→줄바꿈, <hp:t>본문, tab/lineBreak 처리 */
    private static class HwpxHandler extends DefaultHandler {
        private final StringBuilder out;
        private final StringBuilder para = new StringBuilder();
        private boolean inText = false;

        HwpxHandler(StringBuilder out) { this.out = out; }

        private static boolean is(String qName, String local) {
            return qName.equals(local) || qName.endsWith(":" + local);
        }

        @Override
        public void startElement(String uri, String localName, String qName, Attributes attrs) {
            if (is(qName, "t"))         inText = true;
            else if (is(qName, "tab"))  para.append('\t');
            else if (is(qName, "lineBreak")) para.append('\n');
        }
        @Override
        public void characters(char[] ch, int start, int length) {
            if (inText) para.append(ch, start, length);
        }
        @Override
        public void endElement(String uri, String localName, String qName) {
            if (is(qName, "t")) inText = false;
            else if (is(qName, "p")) {
                out.append(para).append('\n');
                para.setLength(0);
            }
        }
    }

    /**
     * .pdf → PDFBox {@code PDFTextStripper} 로 평문 추출.
     * PDFBox 2.0.x 는 fontbox + commons-logging 만 의존(xmlbeans 무관, JDK 1.8 호환).
     * 비밀번호 잠금 PDF 는 {@code PDDocument.load} 가 예외를 던지고, 호출측이 잡아 원본만 보관한다.
     */
    private String extractPdf(byte[] bytes) throws Exception {
        try (org.apache.pdfbox.pdmodel.PDDocument doc = org.apache.pdfbox.pdmodel.PDDocument.load(bytes)) {
            org.apache.pdfbox.text.PDFTextStripper stripper = new org.apache.pdfbox.text.PDFTextStripper();
            stripper.setSortByPosition(true);   // 읽기 순서대로
            return stripper.getText(doc);
        }
    }

    /**
     * .doc(구 Word 97-2003, HWPF) → POI {@code WordExtractor} 로 평문 추출.
     * poi-scratchpad 는 poi(core) 만 의존하고 xmlbeans 를 쓰지 않아 xmlbeans 2.6.0 핀과 무관.
     * Word 6/95 등 더 오래된 포맷은 {@code OldWordFileFormatException} 을 던지고, 호출측이 잡아 원본만 보관한다.
     */
    private String extractDoc(byte[] bytes) throws Exception {
        try (org.apache.poi.hwpf.HWPFDocument doc = new org.apache.poi.hwpf.HWPFDocument(new ByteArrayInputStream(bytes));
             org.apache.poi.hwpf.extractor.WordExtractor ext = new org.apache.poi.hwpf.extractor.WordExtractor(doc)) {
            return ext.getText();
        }
    }

    // ── 국가법령정보센터(law.go.kr) 다운로드 보일러플레이트 패턴 ──
    //    .hwpx 본문에 페이지 머리말/꼬리말로 끼어드는 노이즈. 조문 분해 전에 제거.
    //    페이지번호 꼬리말: "- 3 / 10 -", "- / -"
    private static final java.util.regex.Pattern P_PAGE_FOOTER =
            java.util.regex.Pattern.compile("^-\\s*\\d*\\s*/\\s*\\d*\\s*-$");
    //    상단 목차(目次) 블록: 들여쓰기된 "제N조" / "제N조의M(제목)" — 본문 없는 제목만
    private static final java.util.regex.Pattern P_TOC_LINE =
            java.util.regex.Pattern.compile("^\\s+제\\d+조(의\\d+)?(\\([^)]*\\))?\\s*$");
    //    본문 시작점: "제N편/장/절/관/조[의M]" — 머리말(제목 중복·시행일·소관부서 연락처) 컷 기준
    private static final java.util.regex.Pattern P_STRUCT_START =
            java.util.regex.Pattern.compile("^제\\s*\\d+\\s*(편|장|절|관|조)(\\s*의\\s*\\d+)?.*$");
    //    조 메타 단독 대괄호 줄: [제목개정 …] [본조신설 …] [전문개정 …] [종전 …에서 이동 …] → 본문 노이즈
    private static final java.util.regex.Pattern P_META_BRACKET =
            java.util.regex.Pattern.compile("^\\[[^\\]]*(개정|신설|이동|삭제|종전)[^\\]]*\\]$");
    //    말미 별표/서식 카탈로그: "[별표 …]" "[별지 …]" "별표 / 서식"
    private static final java.util.regex.Pattern P_BYLPYO_CATALOG =
            java.util.regex.Pattern.compile("^(\\[별표.*|\\[별지.*|별표\\s*/\\s*서식)$");

    /** 한 줄이 보일러플레이트(머리말/꼬리말/목차)인지 — true 면 버림 */
    private boolean isBoilerplate(String trimmed, String original) {
        if (trimmed.equals("법제처") || trimmed.equals("국가법령정보센터")) return true;
        if (P_PAGE_FOOTER.matcher(trimmed).matches()) return true;
        // 목차: 들여쓰기 + 제N조 제목만 (본문 조문은 들여쓰기 없이 컬럼0 에서 시작하므로 안전)
        if (P_TOC_LINE.matcher(original).matches()) return true;
        return false;
    }

    /**
     * 추출 평문 정돈:
     *   - CR 제거, 줄 끝 공백 trim
     *   - 국가법령정보센터 보일러플레이트(법제처/국가법령정보센터/페이지번호/상단 목차) 제거
     *   - 3줄↑ 연속 빈 줄 → 빈 줄 1개
     */
    private String normalizeForProvision(String raw) {
        if (raw == null) return "";
        String[] lines = raw.replace("\r", "").split("\n", -1);
        // 1) 줄 단위 1차 정돈 — 보일러플레이트 / 조 메타 대괄호 / 별표 카탈로그 줄 제거
        List<String> kept = new ArrayList<>();
        for (String line : lines) {
            String t = line.replaceAll("[ \t]+$", "");
            String trimmed = t.trim();
            if (trimmed.isEmpty()) { kept.add(""); continue; }
            if (isBoilerplate(trimmed, t)) continue;                 // 머리말/꼬리말/목차
            if (P_META_BRACKET.matcher(trimmed).matches()) continue; // [제목개정]/[본조신설]/[…이동] 등
            if (P_BYLPYO_CATALOG.matcher(trimmed).matches()) continue; // 말미 [별표]/[별지]/별표 목록
            kept.add(t);
        }
        // 2) 머리말 컷 — 첫 본문 구조 줄(제N조/장/편…) 이전(제목 중복·시행일·소관부서 연락처 등) 제거
        int start = -1;
        for (int i = 0; i < kept.size(); i++) {
            String tr = kept.get(i).trim();
            if (!tr.isEmpty() && P_STRUCT_START.matcher(tr).matches()) { start = i; break; }
        }
        if (start > 0) kept = kept.subList(start, kept.size());
        // 3) 3줄↑ 연속 빈 줄 → 1줄 로 접고 join
        StringBuilder sb = new StringBuilder();
        int blank = 0;
        for (String line : kept) {
            if (line.trim().isEmpty()) {
                blank++;
                if (blank <= 1) sb.append('\n');
                continue;
            }
            blank = 0;
            sb.append(line).append('\n');
        }
        return sb.toString().trim();
    }
}
