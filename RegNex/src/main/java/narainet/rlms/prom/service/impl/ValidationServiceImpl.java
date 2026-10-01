/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/ValidationServiceImpl.java
 *
 * 법령 본문 무결성 검증 Service 구현체.
 *
 * ★본문 형식(SPROV_FG)별로 검사 항목이 다르다 (2026-07-29). 아래 조문 규칙들은 VERSION 형식 전용이다.
 *   · VERSION      — 조문(TB_PROV_VRSN) 규칙 전부
 *   · HTML         — 본문이 TB_PROV_HTML 평면 → 본문 유무 + 빈 항목만
 *   · VIEWER(PDF뷰어) — 본문이 관련자료의 PDF → 띄울 PDF 가 있는지만
 *   · LINK         — 본문이 외부 원문 → URL 유효성만
 *   날짜 모순 검사는 형식과 무관하게 전 형식 공통.
 *
 * 검증 규칙:
 *   1. TB_PROV_VRSN 의 SFULL_ITEM 중복     → ERROR
 *   2. TB_PROV_VRSN 의 SCONTENTS 비어 있음 → WARN
 *   3. TB_PROM 의 SPROM_DT > SSTART_DT     → ERROR (공포 후 시행 모순)
 *   4. TB_PROM 의 SSTART_DT > SNULL_DT     → ERROR (시행 후 폐지 모순)
 *   5. TB_PROV_VRSN row 0건                → WARN
 *   6. 조항 트리 일관성 (규칙5, 2026-07-16) → INFO — 누적(상속 포함) 뷰 기준:
 *      · SFULL_ITEM 형식 이상(60자 아님)
 *      · 고아 하위단위(항/호/목의 상위 조 없음)
 *      · 고아 조(조의 SFULL_ITEM 이 가리키는 편/장/절/관/목 그룹 행 없음)
 *      · 빈 그룹(하위 조가 하나도 없는 편/장/절/관/목)
 *      ※ 누적 모델에서 회차 직접 저장행만 보면 부모가 이전 회차에 있는 정상 케이스가
 *        오탐되므로 반드시 (lawId, lawNo) 누적 뷰로 검사. tombstone(SDISP_YN='N') 제외.
 */
package narainet.rlms.prom.service.impl;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.prom.mapper.ProvVrsnMapper;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prom.service.ProvHtmlService;
import narainet.rlms.prom.service.ProvHtmlVO;
import narainet.rlms.prom.service.ProvVrsnVO;
import narainet.rlms.prom.service.ValidationIssueVO;
import narainet.rlms.prom.service.ValidationService;

@Service("validationService")
public class ValidationServiceImpl implements ValidationService {

	@Resource(name = "promMapper")
	private PromMapper promMapper;

	@Resource(name = "provVrsnMapper")
	private ProvVrsnMapper provVrsnMapper;

	/** HTML형식 본문(TB_PROV_HTML) 검사용 */
	@Resource(name = "provHtmlService")
	private ProvHtmlService provHtmlService;

	/** PDF파일뷰어 형식의 '띄울 PDF가 있는가' 판정 — 뷰어와 같은 정본 로직을 쓴다 */
	@Resource(name = "promBodyViewResolver")
	private PromBodyViewResolver promBodyViewResolver;

	@Override
	public List<ValidationIssueVO> validateHistory(Long lawId) {
		List<ValidationIssueVO> all = new ArrayList<>();
		// 유효성 검사 — 미승인 draft 포함 전체 회차 대상 (frontOnly=false, 열람제한 미적용=관리자 도구)
		List<PromVO> proms = promMapper.selectComparisonCandidates(lawId, false, false, null, null);
		for (PromVO p : proms) {
			all.addAll(validateProm(p.getPromNo()));
		}
		return all;
	}

	@Override
	public List<ValidationIssueVO> validateExistingAll() {
		List<ValidationIssueVO> all = new ArrayList<>();
		List<PromVO> existings = promMapper.selectAllExisting();
		for (PromVO p : existings) {
			all.addAll(validateProm(p.getPromNo()));
		}
		return all;
	}

	@Override
	public List<ValidationIssueVO> validateProm(Long promNo) {
		List<ValidationIssueVO> issues = new ArrayList<>();
		PromVO p = promMapper.selectPromByNo(promNo);
		if (p == null) {
			issues.add(new ValidationIssueVO(
					ValidationIssueVO.SEVERITY_ERROR,
					ValidationIssueVO.CAT_TREE_INCONSISTENT,
					promNo, null, null, "규정 row 가 존재하지 않습니다."));
			return issues;
		}

		// 1) 날짜 모순 검사
		if (isAfter(p.getPromDate(), p.getStartDate())) {
			issues.add(new ValidationIssueVO(
					ValidationIssueVO.SEVERITY_ERROR,
					ValidationIssueVO.CAT_DATE_INVALID,
					promNo, p.getTitle(), null,
					"공포일(" + p.getPromDate() + ")이 시행일(" + p.getStartDate() + ")보다 늦습니다."));
		}
		if (notEmpty(p.getNullDate()) && isAfter(p.getStartDate(), p.getNullDate())) {
			issues.add(new ValidationIssueVO(
					ValidationIssueVO.SEVERITY_ERROR,
					ValidationIssueVO.CAT_DATE_INVALID,
					promNo, p.getTitle(), null,
					"시행일(" + p.getStartDate() + ")이 폐지일(" + p.getNullDate() + ")보다 늦습니다."));
		}

		// ── 본문 형식별 분기 (2026-07-29) ────────────────────────────
		// 아래 조문 검사(2~5)는 전부 TB_PROV_VRSN 을 보는데, 그건 VERSION 형식 전용 모델이다.
		// 다른 형식에 그대로 돌리면 그 형식에서는 할 수도 없는 일을 요구하는 오안내가 된다
		// (예: PDF파일뷰어 규정에 "본문 분해가 필요합니다"). 형식마다 맞는 검사로 갈라 끝낸다.
		// 날짜 모순 검사(1)는 형식과 무관하므로 이 분기 앞에서 이미 전 형식 공통으로 수행했다.
		String bodyFlag = PromBodyViewResolver.normalizeFlag(p.getProvFlag());

		// 링크형식(LINK) — 본문 없이 외부 원문(SURL)으로 연결. 검사할 것은 URL 유효성뿐.
		if ("LINK".equals(bodyFlag)) {
			String u = (p.getUrl() == null) ? "" : p.getUrl().trim().toLowerCase();
			if (!(u.startsWith("http://") || u.startsWith("https://"))) {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_ERROR,
						ValidationIssueVO.CAT_PROV_MISSING,
						promNo, p.getTitle(), null,
						"링크형식 규정인데 외부 원문 URL(http/https)이 없습니다."));
			}
			return issues;
		}

		// PDF파일뷰어(VIEWER) — 본문이 조문이 아니라 관련자료(PDF뷰어용)의 PDF 파일 자체다.
		// 조문 row 가 0건인 게 정상이므로, 대신 "화면에 띄울 PDF 가 실제로 있는가"를 본다.
		if ("VIEWER".equals(bodyFlag)) {
			boolean pdfReady = false;
			try {
				pdfReady = promBodyViewResolver.resolve(p).getViewAttNo() != null;
			} catch (Exception e) {
				// 첨부 조회 실패는 검증 실패로 보지 않는다 — 다른 규정 검사를 막지 않도록 흡수
				return issues;
			}
			if (!pdfReady) {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_ERROR,
						ValidationIssueVO.CAT_PROV_MISSING,
						promNo, p.getTitle(), null,
						"PDF파일뷰어 형식인데 화면에 띄울 원문 PDF가 없습니다. (관련자료의 'PDF뷰어용' 첨부를 확인하세요)"));
			}
			return issues;
		}

		// HTML형식 — 본문이 TB_PROV_HTML 평면 모델이라 조문(TB_PROV_VRSN) 트리 검사는 비대상.
		if ("HTML".equals(bodyFlag)) {
			issues.addAll(validateHtmlBody(p));
			return issues;
		}

		// 2) TB_PROV_VRSN row 0건 검사
		//    개정처리 재검토(2026-07-23) — 미개정(EQUAL) 조문은 회차에 저장되지 않으므로,
		//    소유 행이 0건이어도 이전 연혁 승계 조문이 있으면 "변경 없는 회차"로 정상 안내(INFO).
		int provCnt = provVrsnMapper.countByPromNo(promNo);
		if (provCnt == 0) {
			int cumCnt = 0;
			if (p.getLawId() != null && p.getLawNo() != null) {
				try { cumCnt = provVrsnMapper.countCumulativeByLaw(p.getLawId(), p.getLawNo()); }
				catch (Exception ignore) { }
			}
			if (cumCnt > 0) {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_INFO,
						ValidationIssueVO.CAT_PROV_MISSING,
						promNo, p.getTitle(), null,
						"이 연혁에서 변경된 조문이 없습니다. (이전 연혁 조문 " + cumCnt + "건 승계)"));
			} else {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_WARN,
						ValidationIssueVO.CAT_PROV_MISSING,
						promNo, p.getTitle(), null,
						"조항 단위 row 가 없습니다. 본문 분해가 필요합니다."));
				return issues;
			}
		}

		// 3) SFULL_ITEM 중복
		List<String> dupItems = provVrsnMapper.selectDuplicateFullItems(promNo);
		for (String item : dupItems) {
			issues.add(new ValidationIssueVO(
					ValidationIssueVO.SEVERITY_ERROR,
					ValidationIssueVO.CAT_DUPLICATE_ITEM,
					promNo, p.getTitle(), item,
					"같은 조항이 두 번 이상 등록되어 있습니다."));
		}

		// 4) 본문 빈 항목
		List<String> emptyItems = provVrsnMapper.selectEmptyContentItems(promNo);
		for (String item : emptyItems) {
			issues.add(new ValidationIssueVO(
					ValidationIssueVO.SEVERITY_WARN,
					ValidationIssueVO.CAT_EMPTY_CONTENT,
					promNo, p.getTitle(), item,
					"본문이 비어 있습니다."));
		}

		// 5) 조항 트리 일관성 (INFO) — 누적 뷰 기준
		if (p.getLawId() != null && p.getLawNo() != null) {
			issues.addAll(validateTree(p));
		}

		return issues;
	}

	/**
	 * HTML형식 본문 검사 — 원천이 TB_PROV_HTML 이다.
	 * 조문(TB_PROV_VRSN) 기반 검사 2~5 를 대신하며, 보는 것은 두 가지뿐이다:
	 *   · 본문이 아예 없는가 (단, 이 회차에 변경분이 없고 이전 연혁 승계분이 있으면 정상 안내)
	 *   · 등록된 항목 중 내용이 빈 것이 있는가
	 */
	private List<ValidationIssueVO> validateHtmlBody(PromVO p) {
		List<ValidationIssueVO> issues = new ArrayList<>();
		List<ProvHtmlVO> rows;
		try {
			rows = provHtmlService.selectProvHtmlList(p.getPromNo());
		} catch (Exception e) {
			return issues;   // 조회 실패가 전체 검증을 막지 않도록
		}

		if (rows == null || rows.isEmpty()) {
			// VERSION 형식의 누적 규칙과 같은 철학 — 이 회차에 변경이 없을 뿐 승계 본문이 있으면 정상
			int cum = 0;
			if (p.getLawId() != null && p.getLawNo() != null) {
				try {
					List<ProvHtmlVO> c = provHtmlService.selectProvHtmlListCumulativeAdmin(p.getLawId(), p.getLawNo());
					cum = (c == null) ? 0 : c.size();
				} catch (Exception ignore) { }
			}
			if (cum > 0) {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_INFO,
						ValidationIssueVO.CAT_PROV_MISSING,
						p.getPromNo(), p.getTitle(), null,
						"이 연혁에서 변경된 본문이 없습니다. (이전 연혁 본문 " + cum + "건 승계)"));
			} else {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_WARN,
						ValidationIssueVO.CAT_PROV_MISSING,
						p.getPromNo(), p.getTitle(), null,
						"HTML형식 규정인데 본문이 등록되지 않았습니다."));
			}
			return issues;
		}

		for (ProvHtmlVO r : rows) {
			if (r == null || "N".equals(r.getDispYn())) continue;
			String c = r.getContents();
			// 리치 본문이라 태그만 남은 경우(<p></p> 등)도 빈 본문으로 본다
			if (c == null || c.replaceAll("<[^>]*>", "").replace("&nbsp;", " ").trim().isEmpty()) {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_WARN,
						ValidationIssueVO.CAT_EMPTY_CONTENT,
						p.getPromNo(), p.getTitle(), r.getItem(),
						"본문이 비어 있습니다."));
			}
		}
		return issues;
	}

	// ── 규칙 5: 조항 트리 일관성 (INFO) ────────────────────────────
	/** 회차당 트리 이슈 보고 상한 — 손상 임포트 데이터가 목록을 잠식하지 않도록 */
	private static final int MAX_TREE_ISSUES = 30;

	/** SFULL_ITEM 60자 = 5자 × 12청크. 그룹 단위의 유효 접두 길이 */
	private static final int LEN_FULL = 60;
	private static final int LEN_JO_PREFIX = 30;   // 편5+장5+절5+관5+목5+조5

	private List<ValidationIssueVO> validateTree(PromVO p) {
		List<ValidationIssueVO> issues = new ArrayList<>();
		List<ProvVrsnVO> rows;
		try {
			rows = provVrsnMapper.selectAllCumulative(p.getLawId(), p.getLawNo());
		} catch (Exception e) {
			return issues;   // 트리 검사는 선택 규칙 — 조회 실패가 전체 검증을 막지 않음
		}
		if (rows == null || rows.isEmpty()) return issues;

		// 수집 — tombstone 제외, 단위별 분류
		java.util.Set<String> joPrefixes   = new java.util.HashSet<>();   // BASE_TEXT 의 앞 30자
		java.util.Set<String> grpPrefixes  = new java.util.HashSet<>();   // 그룹 행의 유효 접두(편5/장10/절15/관20/목25)
		List<ProvVrsnVO> joRows  = new ArrayList<>();
		List<ProvVrsnVO> subRows = new ArrayList<>();
		List<ProvVrsnVO> grpRows = new ArrayList<>();
		for (ProvVrsnVO v : rows) {
			if (v == null || "N".equals(v.getDispYn())) continue;
			String fi = v.getFullItem() == null ? "" : v.getFullItem();
			String unit = v.getUnitType() == null ? "" : v.getUnitType();
			if ("POST_SCRIPT".equals(unit)) continue;   // 부칙 — 트리 검사 비대상
			// 5-a) 형식 이상 — 60자 고정폭이 아니면 이하 접두 검사가 무의미하므로 보고만 하고 제외
			if (fi.length() != LEN_FULL) {
				if (issues.size() < MAX_TREE_ISSUES) {
					issues.add(new ValidationIssueVO(
							ValidationIssueVO.SEVERITY_INFO,
							ValidationIssueVO.CAT_TREE_INCONSISTENT,
							p.getPromNo(), p.getTitle(), fi,
							"조항 위치 정보가 손상되어 위치를 식별할 수 없습니다."));
				}
				continue;
			}
			if ("BASE_TEXT".equals(unit)) {
				joRows.add(v); joPrefixes.add(fi.substring(0, LEN_JO_PREFIX));
			} else if ("BASE_TEXT_GROUP".equals(unit)) {
				grpRows.add(v);
				int sig = groupSigLen(v.getNativeType(), fi);
				if (sig > 0) grpPrefixes.add(fi.substring(0, sig));
			} else {
				subRows.add(v);   // SUB_TEXT (항/호/목/단)
			}
		}

		// 5-b) 고아 하위단위 — 항/호의 앞 30자(소속 조)가 조 집합에 없음
		for (ProvVrsnVO v : subRows) {
			if (issues.size() >= MAX_TREE_ISSUES) break;
			String pre = v.getFullItem().substring(0, LEN_JO_PREFIX);
			if (!joPrefixes.contains(pre)) {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_INFO,
						ValidationIssueVO.CAT_TREE_INCONSISTENT,
						p.getPromNo(), p.getTitle(), v.getFullItem(),
						"상위 조가 없는 하위단위(항/호)입니다."));
			}
		}

		// 5-c) 고아 조 — 조의 편/장/절/관/목 청크가 가리키는 그룹 행 없음 (distinct 접두당 1건)
		java.util.Set<String> missingGrp = new java.util.LinkedHashSet<>();
		for (ProvVrsnVO v : joRows) {
			String fi = v.getFullItem();
			for (int off = 0; off <= 20; off += 5) {                 // 편0/장5/절10/관15/목20
				String chunk = fi.substring(off, off + 5);
				if (isZero(chunk)) continue;
				String pre = fi.substring(0, off + 5);
				if (!grpPrefixes.contains(pre)) missingGrp.add(pre);
			}
		}
		for (String pre : missingGrp) {
			if (issues.size() >= MAX_TREE_ISSUES) break;
			issues.add(new ValidationIssueVO(
					ValidationIssueVO.SEVERITY_INFO,
					ValidationIssueVO.CAT_TREE_INCONSISTENT,
					p.getPromNo(), p.getTitle(), pre,
					"조가 속한 상위 그룹(편·장·절·관·목) 행이 없습니다."));
		}

		// 5-d) 빈 그룹 — 하위 조가 하나도 없는 편/장/절/관/목
		for (ProvVrsnVO g : grpRows) {
			if (issues.size() >= MAX_TREE_ISSUES) break;
			int sig = groupSigLen(g.getNativeType(), g.getFullItem());
			if (sig <= 0) continue;
			String pre = g.getFullItem().substring(0, sig);
			boolean hasChild = false;
			for (String jp : joPrefixes) {
				if (jp.startsWith(pre)) { hasChild = true; break; }
			}
			if (!hasChild) {
				issues.add(new ValidationIssueVO(
						ValidationIssueVO.SEVERITY_INFO,
						ValidationIssueVO.CAT_TREE_INCONSISTENT,
						p.getPromNo(), p.getTitle(), g.getFullItem(),
						"하위 조가 없는 빈 그룹(편/장/절/관/목)입니다."));
			}
		}

		if (issues.size() >= MAX_TREE_ISSUES) {
			issues.add(new ValidationIssueVO(
					ValidationIssueVO.SEVERITY_INFO,
					ValidationIssueVO.CAT_TREE_INCONSISTENT,
					p.getPromNo(), p.getTitle(), null,
					"트리 이슈가 " + MAX_TREE_ISSUES + "건을 넘어 이하 생략 — 본문 일괄편집기에서 구조 재저장을 권장합니다."));
		}
		return issues;
	}

	/** 그룹 단위(nativeType)별 유효 접두 길이 — 편5/장10/절15/관20/목25. 미상은 뒤 0 청크 제거로 추정 */
	private int groupSigLen(String nativeType, String fullItem) {
		if (nativeType != null) {
			switch (nativeType) {
				case "F_PYUN": return 5;
				case "F_JANG": return 10;
				case "F_JEOL": return 15;
				case "F_GWAN": return 20;
				case "F_MOK1": return 25;
				default: break;
			}
		}
		// 폴백 — 마지막 비영(非0) 청크까지
		if (fullItem == null || fullItem.length() != LEN_FULL) return -1;
		for (int off = 20; off >= 0; off -= 5) {
			if (!isZero(fullItem.substring(off, off + 5))) return off + 5;
		}
		return -1;
	}

	private static boolean isZero(String chunk) {
		for (int i = 0; i < chunk.length(); i++) {
			if (chunk.charAt(i) != '0') return false;
		}
		return true;
	}

	// ── helpers ────────────────────────────────────────────────────

	private boolean notEmpty(String s) {
		return s != null && !s.trim().isEmpty();
	}

	/**
	 * a > b 인지 — 문자열 'YYYY-MM-DD' 또는 'YYYY-MM-DD HH:MI:SS' 형식 가정.
	 * 둘 중 하나라도 비어 있거나 미지정 센티넬('--')이면 false (검사 스킵).
	 * ('--' 를 날짜로 비교하면 사전식으로 모든 날짜보다 작아 "시행일이 폐지일(--)보다 늦다"
	 *  오탐이 났음 — 2026-07-16 교정.)
	 * 단순 lexicographic 비교로 충분 (ISO 형식).
	 */
	private boolean isAfter(String a, String b) {
		if (!dateGiven(a) || !dateGiven(b)) {
			return false;
		}
		return a.compareTo(b) > 0;
	}

	/** 실제 날짜가 입력된 값인지 — NULL/공백/'--'(미지정 센티넬) 는 false */
	private boolean dateGiven(String s) {
		if (!notEmpty(s)) return false;
		return !"--".equals(s.trim());
	}
}
