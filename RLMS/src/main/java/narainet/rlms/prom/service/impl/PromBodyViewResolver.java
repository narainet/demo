/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/PromBodyViewResolver.java
 *
 * 규정형식(SPROV_FG)별 본문 표시 방식 결정 — 레거시 FullTextController frontView 분기 이식.
 *
 *   VERSION : 버전관리조문 — TB_PROV_VRSN 렌더 (레거시는 본문 없는 스켈레톤 → 안내 + 원문파일 링크)
 *   HTML    : HTML형식조문 — SREL_FILE_VIEW_YN='Y' 면 관련파일 인라인 보기 우선(레거시 documentViewer
 *             리다이렉트 대응), 아니면 TB_PROV_HTML 누적 렌더
 *   VIEWER  : PDF파일뷰어 — SPROV_FILE_NO(REL_FILE_3 카테고리 TB_REL_FILE) 의 PDF 인라인(레거시 viewer.htm)
 *
 * 인라인 보기 대표 파일은 "PDF 로 표시 가능한"(원본 pdf 또는 DCMS 변환본 존재) 첫 파일.
 * 레거시 파일 저장소가 마운트되지 않은 환경에서는 대표 파일이 안 잡히고 파일 목록 안내로 폴백.
 */
package narainet.rlms.prom.service.impl;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import lombok.Getter;
import lombok.Setter;
import narainet.rlms.attach.service.AttachService;
import narainet.rlms.attach.service.AttachVO;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.related.mapper.RelFileMapper;
import narainet.rlms.related.service.RelFileVO;

@Service("promBodyViewResolver")
public class PromBodyViewResolver {

	/** 인라인 후보 PDF 판정 시 디스크 확인 상한 (파일 많은 법령의 뷰 지연 방지) */
	private static final int INLINE_PROBE_LIMIT = 20;

	@Resource(name = "relFileMapper")
	private RelFileMapper relFileMapper;

	@Resource(name = "attachService")
	private AttachService attachService;

	/** 본문 표시 방식 결정 결과 */
	@Getter
	@Setter
	public static class BodyView {
		/** VERSION | HTML | VIEWER | LINK (정규화 — FILE_VIEWER 는 VIEWER 로. LINK=본문 없이 외부 원문 SURL) */
		private String mode = "VERSION";
		/** 인라인(PDF) 보기 대표 첨부 — null 이면 인라인 표시 없음 */
		private Long viewAttNo;
		/** 열람가능 파일 목록 (누적, 배너/안내용) */
		private List<RelFileVO> files = new ArrayList<>();
	}

	public BodyView resolve(PromVO prom) {
		BodyView bv = new BodyView();
		if (prom == null) return bv;
		String mode = normalizeFlag(prom.getProvFlag());
		bv.setMode(mode);

		if (prom.getLawId() != null && prom.getLawNo() != null) {
			List<RelFileVO> files =
					relFileMapper.selectViewableListCumulative(prom.getLawId(), prom.getLawNo());
			if (files != null) bv.setFiles(files);
		}

		// 인라인 대표 파일 — 레거시 와 동일하게 VIEWER 와 HTML(관련파일 바로열람=Y) 만
		boolean wantInline = "VIEWER".equals(mode)
				|| ("HTML".equals(mode) && "Y".equals(prom.getRelFileViewYn()));
		if (!wantInline) return bv;

		// 1) VIEWER: SPROV_FILE_NO 가 가리키는 REL_FILE 우선 (레거시 fulltext_view pdfUrl)
		if ("VIEWER".equals(mode)) {
			Long relFileNo = parsePositive(prom.getProvFileNo());
			if (relFileNo != null) {
				RelFileVO rf = relFileMapper.selectByNo(relFileNo);
				if (rf != null && pdfViewable(rf.getAttNo())) {
					bv.setViewAttNo(rf.getAttNo());
					return bv;
				}
			}
		}

		// 2) 누적 후보 중 PDF 표시 가능한 첫 파일 — 레거시 후보 풀 1:1:
		//    HTML(바로열람) = REL_FILE_1(관련파일, CODE_RELATED_FILE_REF)만, 정렬은 쿼리의
		//    분류명(본문>붙임>양식) + ISEQ 순이라 '본문' 파일이 먼저 잡힘.
		//    VIEWER 폴백 = REL_FILE_3(PDF뷰어용)만 (레거시 은 폴백 없음 — 지정파일 유실 대비 보강).
		String wantCate = "VIEWER".equals(mode) ? "REL_FILE_3" : "REL_FILE_1";
		int probed = 0;
		for (RelFileVO f : bv.getFiles()) {
			if (f.getAttNo() == null || !wantCate.equals(f.getCate())) continue;
			if (++probed > INLINE_PROBE_LIMIT) break;
			if (pdfViewable(f.getAttNo())) {
				bv.setViewAttNo(f.getAttNo());
				break;
			}
		}
		return bv;
	}

	private boolean pdfViewable(Long attNo) {
		if (attNo == null) return false;
		AttachVO att = attachService.selectByNo(attNo);
		return att != null && attachService.resolvePdfView(att) != null;
	}

	/**
	 * 본문 형식 코드 정규화 — 이 앱에서 "무엇을 본문으로 보느냐"의 정본이다.
	 * 유효성검사(ValidationServiceImpl)도 형식별 검사 분기에 같은 판정을 써야 하므로 공개한다.
	 */
	public static String normalizeFlag(String flag) {
		if (flag == null) return "VERSION";
		String f = flag.trim().toUpperCase();
		if ("HTML".equals(f)) return "HTML";
		if ("VIEWER".equals(f) || "FILE_VIEWER".equals(f)) return "VIEWER";
		if ("LINK".equals(f)) return "LINK";   // 링크형식 — 본문 없이 외부 원문(SURL) 카드로 연결
		return "VERSION";
	}

	private static Long parsePositive(String s) {
		if (s == null) return null;
		try {
			long v = Long.parseLong(s.trim());
			return v > 0 ? v : null;
		} catch (NumberFormatException e) {
			return null;
		}
	}
}
