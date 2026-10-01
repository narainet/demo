/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/web/PromBodyModelSupport.java
 *
 * 사용자 전문뷰어(provisionList.do) / 관리자 미리보기(preview.do) 공용 —
 * 규정형식(SPROV_FG)별 본문 model attribute 빌더. 레거시 frontView 동선 대응.
 *
 *  model attrs:
 *    bodyMode      : VERSION | HTML | VIEWER
 *    bodyViewAttNo : 인라인(PDF) 보기 대표 첨부 (없으면 null) → attachView.do?attNo=
 *    bodyFiles     : 열람가능 파일 누적 목록 (안내 배너 링크용)
 *    bodySkeleton  : VERSION 인데 조문 본문이 전부 빈 레거시 스켈레톤 여부
 *    provHtml / docuHtml / provList : 기존 뷰어 계약 유지
 */
package narainet.rlms.prom.web;

import java.util.List;

import org.springframework.ui.ModelMap;

import narainet.rlms.docu.mapper.DocuMapper;
import narainet.rlms.prom.mapper.ProvHtmlMapper;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prom.service.ProvHtmlVO;
import narainet.rlms.prom.service.ProvVrsnService;
import narainet.rlms.prom.service.ProvVrsnVO;
import narainet.rlms.prom.service.impl.AutoLinkService;
import narainet.rlms.prom.service.impl.PromBodyViewResolver;
import narainet.rlms.prom.service.impl.ProvTokenResolver;
import narainet.rlms.prom.service.impl.ProvViewRenderer;

final class PromBodyModelSupport {

	private PromBodyModelSupport() {}

	static void addBodyModel(PromVO prom, Long promNo, String ctxPath, ModelMap model,
			PromBodyViewResolver bodyViewResolver,
			ProvVrsnService provVrsnService,
			ProvHtmlMapper provHtmlMapper,
			DocuMapper docuMapper,
			ProvViewRenderer renderer,
			ProvTokenResolver tokenResolver,
			AutoLinkService autoLinkService) throws Exception {
		addBodyModel(prom, promNo, ctxPath, model, bodyViewResolver, provVrsnService,
				provHtmlMapper, docuMapper, renderer, tokenResolver, autoLinkService, null);
	}

	/** + lawRounds(같은 법령의 전 회차, 최신순) — 조문 인라인 개정 주석용 날짜맵 재료(2026-07-24).
	 *  null 이면 주석 없이 종전 렌더 그대로. */
	static void addBodyModel(PromVO prom, Long promNo, String ctxPath, ModelMap model,
			PromBodyViewResolver bodyViewResolver,
			ProvVrsnService provVrsnService,
			ProvHtmlMapper provHtmlMapper,
			DocuMapper docuMapper,
			ProvViewRenderer renderer,
			ProvTokenResolver tokenResolver,
			AutoLinkService autoLinkService,
			List<PromVO> lawRounds) throws Exception {

		if (prom == null) {
			// 방어 — 호출자는 prom null 시 목록 분기로 가야 하지만, 직접 호출 대비 빈 본문으로 안전 귀결
			model.addAttribute("bodyMode", "VERSION");
			model.addAttribute("bodySkeleton", Boolean.FALSE);
			model.addAttribute("provHtml", "");
			model.addAttribute("docuHtml", "");
			return;
		}
		PromBodyViewResolver.BodyView bv = bodyViewResolver.resolve(prom);
		model.addAttribute("bodyMode", bv.getMode());
		model.addAttribute("bodyViewAttNo", bv.getViewAttNo());
		model.addAttribute("bodyFiles", bv.getFiles());
		model.addAttribute("bodySkeleton", Boolean.FALSE);

		boolean inline = bv.getViewAttNo() != null;

		if ("LINK".equals(bv.getMode())) {
			// 링크형식 — 본문 없음. 뷰어/미리보기의 외부 원문 참조 카드(.lv-extref, prom.url)가 본문을 대신.
			model.addAttribute("provHtml", "");
			model.addAttribute("docuHtml", "");
			return;
		}

		if ("VIEWER".equals(bv.getMode()) || inline) {
			// PDF 인라인(또는 파일 안내) — 조문/별표 섹션 없음 (레거시 documentViewer/viewer.htm 동선)
			model.addAttribute("provHtml", "");
			model.addAttribute("docuHtml", "");
			return;
		}

		// 자동링크 컨텍스트 — 보는 규정(lawId) 기준 제외범위 확장. 페이지 렌더당 1회. fail-soft.
		AutoLinkService.LinkContext linkCtx =
				(autoLinkService != null) ? autoLinkService.context(prom.getLawId(), ctxPath) : null;

		if ("HTML".equals(bv.getMode())) {
			// HTML형식조문 — TB_PROV_HTML 누적 렌더 (본문이 신뢰 HTML, 토큰만 치환 + 태그 밖 자동링크)
			List<ProvHtmlVO> htmlRows =
					provHtmlMapper.selectProvHtmlListCumulative(prom.getLawId(), prom.getLawNo());
			model.addAttribute("provHtml",
					renderer.renderProvHtmlSection(htmlRows, promNo, tokenResolver, ctxPath, linkCtx));
			model.addAttribute("docuHtml",
					renderer.renderDocuSection(
							docuMapper.selectDocuListCumulative(prom.getLawId(), prom.getLawNo()),
							promNo, tokenResolver, ctxPath, linkCtx));
			// "원문 파일로 제공" 배너 여부 — 표시 행 중 본문(SCONTENTS)이 실제로 있는 행이 하나라도
			// 있을 때만 억제. 제목만 있는 스켈레톤(실DB TB_PROV_HTML 418행 전부 본문 NULL)은
			// 제목 목차 + 배너를 같이 보여준다 (VERSION bodySkeleton 안내와 대칭).
			boolean htmlEmpty = true;
			if (htmlRows != null) {
				for (ProvHtmlVO h : htmlRows) {
					if (h == null || "N".equals(h.getDispYn())) continue;
					String g = h.getGaejungType() == null ? "" : h.getGaejungType().trim();
					if ("NULLIFY".equals(g)) continue;
					if (h.getContents() == null || h.getContents().trim().isEmpty()) continue;
					htmlEmpty = false;
					break;
				}
			}
			model.addAttribute("bodyHtmlEmpty", htmlEmpty);
			return;
		}

		// VERSION — 누적(상속 포함, tombstone 제외) 조문 → 계층 HTML 전문 렌더
		List<ProvVrsnVO> provList = provVrsnService.selectCumulative(prom.getLawId(), prom.getLawNo());
		model.addAttribute("provList", provList);
		// 회차 날짜맵(promNo → "YYYY. M. D.") + 제정 회차 — 조문 인라인 개정 주석(공포일 우선, 없으면 시행일)
		java.util.Map<Long, String> roundDates = null;
		Long firstRoundNo = null;
		if (lawRounds != null && !lawRounds.isEmpty()) {
			roundDates = new java.util.HashMap<>();
			String firstKey = null;
			for (PromVO p : lawRounds) {
				if (p == null || p.getPromNo() == null) continue;
				String raw = (p.getPromDate() != null && !p.getPromDate().trim().isEmpty())
						? p.getPromDate().trim() : (p.getStartDate() == null ? null : p.getStartDate().trim());
				String d = korDate(raw);
				if (d != null) roundDates.put(p.getPromNo(), d);
				// 제정 회차 = (공포/시행일, 회차번호) 최소 — 소급 등록으로 번호가 연대순이 아닐 수 있어 날짜 우선
				String key = (raw == null || raw.isEmpty() ? "9999-99-99" : raw)
						+ "|" + String.format("%019d", p.getPromNo());
				if (firstKey == null || key.compareTo(firstKey) < 0) {
					firstKey = key;
					firstRoundNo = p.getPromNo();
				}
			}
		}
		model.addAttribute("provHtml",
				renderer.render(provList, promNo, tokenResolver, ctxPath, linkCtx, roundDates, firstRoundNo));
		model.addAttribute("docuHtml",
				renderer.renderDocuSection(
						docuMapper.selectDocuListCumulative(prom.getLawId(), prom.getLawNo()),
						promNo, tokenResolver, ctxPath, linkCtx));
		// 레거시 스켈레톤(조문은 있으나 본문이 전부 빈) 판정 → "본문 미등록" 안내 배너
		boolean skeleton = false;
		if (provList != null && !provList.isEmpty()) {
			skeleton = true;
			for (ProvVrsnVO v : provList) {
				if (v.getContents() != null && !v.getContents().trim().isEmpty()) {
					skeleton = false;
					break;
				}
			}
		}
		model.addAttribute("bodySkeleton", skeleton);
	}

	/** "YYYY-MM-DD" → "YYYY. M. D." (법제처 표기). 형식 불일치·미지정('--' 등)은 null. */
	private static String korDate(String ymd) {
		if (ymd == null) return null;
		String s = ymd.trim();
		if (!s.matches("\\d{4}-\\d{2}-\\d{2}")) return null;
		int y = Integer.parseInt(s.substring(0, 4));
		int m = Integer.parseInt(s.substring(5, 7));
		int d = Integer.parseInt(s.substring(8, 10));
		if (m < 1 || d < 1) return null;
		return y + ". " + m + ". " + d + ".";
	}
}
