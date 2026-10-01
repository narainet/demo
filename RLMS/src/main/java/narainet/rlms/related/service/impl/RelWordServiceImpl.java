/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelWordServiceImpl.java
 *
 * 관련자료 — WORD 액션 Service 구현 (레거시 wordUpdateDo, RLMS 1차 = 변환 X).
 *  1) RelWord PK 채번
 *  2) AttachService.save("TB_REL_WORD", IRWORD_NO, "WORD", file, sysId) → IATT_NO
 *  3) RelVrsnService.getNewVersion(...table="TB_REL_WORD"..., cateNo=null) → IRVRSN_NO
 *  4) RelWord INSERT { ..., SCLOB_FILE_YN='N', 변환 컬럼 NULL }
 *
 *  ※ 레거시 의 DocumentConversion 큐 등록 단계는 생략. DCMS 데몬이 RLMS 환경에 없음.
 *    추후 Apache POI / hwplib + Tika 자체 변환 도입 시 이 메서드에 큐 등록 추가.
 */
package narainet.rlms.related.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import narainet.rlms.attach.service.AttachService;
import narainet.rlms.attach.service.AttachVO;
import narainet.rlms.prom.service.DocImportService;
import narainet.rlms.related.mapper.RelWordMapper;
import narainet.rlms.related.service.RelVrsnService;
import narainet.rlms.related.service.RelWordService;
import narainet.rlms.related.service.RelWordVO;

@Service("relWordService")
public class RelWordServiceImpl extends EgovAbstractServiceImpl implements RelWordService {

	@Resource(name = "relWordMapper")
	private RelWordMapper relWordMapper;

	@Resource(name = "egovRelWordIdGnrService")
	private EgovIdGnrService relWordIdGnrService;

	@Resource(name = "relVrsnService")
	private RelVrsnService relVrsnService;

	@Resource(name = "attachService")
	private AttachService attachService;

	/** WORD 자체변환 — .docx/.hwpx 평문 추출 재사용 (규정 IDE 문서가져오기와 동일 엔진, 순수 ZIP+SAX) */
	@Resource(name = "docImportService")
	private DocImportService docImportService;

	/** 분류/구분별 열람제한 게이트 (searchByText read-게이트) — FullTextSearchServiceImpl 미러.
	 *  면제 3역할(ADMIN/EDITOR/APPROVER)은 gateNeeded()=false 로 자동 우회. */
	@Resource(name = "promReadGuard")
	private narainet.rlms.prom.service.PromReadGuard promReadGuard;

	private static final org.slf4j.Logger LOG = org.slf4j.LoggerFactory.getLogger(RelWordServiceImpl.class);

	@Override
	public List<RelWordVO> getList(Long relVrsnNo) {
		return relWordMapper.selectByRelVrsnNo(relVrsnNo);
	}

	@Override
	public RelWordVO getByNo(Long relWordNo) {
		return relWordMapper.selectByNo(relWordNo);
	}

	@Override
	public List<Map<String,Object>> searchByText(String keyword) {
		if (keyword == null || keyword.trim().isEmpty()) {
			return java.util.Collections.emptyList();
		}
		return relWordMapper.searchByText(keyword.trim(),
				promReadGuard.gateNeeded(),
				promReadGuard.readerEsntlId(),
				promReadGuard.readerOrgnztId());
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long saveWord(Long promNo, String flag, String fullItem,
			String title, MultipartFile file, String sysId) throws Exception {

		if (promNo == null || file == null || file.isEmpty()) {
			throw processException("related.word.invalid");
		}

		Long relWordNo = relWordIdGnrService.getNextLongId();

		// ★ 변환용 바이트/파일명은 attachService.save 전에 확보 — save 가 file.transferTo() 로
		//   temp 파일을 옮겨 이후 file.getBytes() 가 실패하기 때문. (변환 실패가 업로드를 막진 않음)
		String origName = file.getOriginalFilename();
		byte[] convBytes = null;
		try { convBytes = file.getBytes(); }
		catch (Exception ignore) { /* 바이트 확보 실패 — 원본 저장은 계속, 변환만 생략 */ }

		AttachVO att = attachService.save("TB_REL_WORD", relWordNo, "WORD", file, sysId);

		String effectiveTitle = (title != null && !title.trim().isEmpty())
				? title.trim()
				: ((att.getName() != null) ? att.getName() : "(제목없음)");

		Long relVrsnNo = relVrsnService.getNewVersion(
				promNo,
				"Y",
				"TB_REL_WORD",
				(flag != null && !flag.isEmpty() ? flag : "PROMULGATION"),
				fullItem,
				effectiveTitle,
				null,
				sysId);

		RelWordVO vo = new RelWordVO();
		vo.setRelWordNo(relWordNo);
		vo.setRelVrsnNo(relVrsnNo);
		vo.setAttNo(att.getAttNo());
		vo.setTitle(effectiveTitle);
		vo.setDelYn("N");
		vo.setInsDt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
		vo.setSysId(att.getSysId());
		// 변환 컬럼 — .docx/.hwpx/.pdf/.doc 는 자체변환(평문 SSEARCH_TEXT + 인라인 SHTML), 그 외는 NULL(원본만 보관)
		vo.setHtmlPath(null);
		vo.setSearchTextPath(null);
		vo.setClobFileYn("N");           // SHTML 은 CLOB 직접 저장(디스크 파일 아님) — DDL default 와 일치
		vo.setPath(null);
		try {
			String text = (convBytes != null) ? docImportService.extractRawText(origName, convBytes) : null;
			if (text != null && !text.trim().isEmpty()) {
				vo.setSearchText(text);                 // 전문검색용 평문
				vo.setHtml(buildBasicHtml(text));       // 상세 모달 인라인 표시용 HTML
				vo.setType(docType(origName));          // "DOCX" / "HWPX" / "PDF" / "DOC"
			} else {
				// 지원하지 않는 포맷(.hwp 바이너리·.xls 등) 또는 빈 문서(이미지 PDF 등) → 변환 없이 원본만
				vo.setHtml(null); vo.setType(null); vo.setSearchText(null);
			}
		} catch (Exception convEx) {
			// ★ 변환 실패가 업로드를 막아선 안 됨 — 원본 첨부는 이미 저장됨, 변환 컬럼만 비움
			vo.setHtml(null); vo.setType(null); vo.setSearchText(null);
			LOG.warn("관련자료(WORD) 자체변환 실패 — 원본만 보관 (relWordNo={}, file={}): {}",
					relWordNo, file.getOriginalFilename(), convEx.getMessage());
		}
		relWordMapper.insert(vo);

		return relWordNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateMeta(Long relWordNo, String title) {
		RelWordVO target = relWordMapper.selectByNo(relWordNo);
		if (target == null) return;
		if (title != null) target.setTitle(title);
		relWordMapper.update(target);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void softDelete(Long relWordNo) {
		relWordMapper.softDelete(relWordNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relWordNo) throws Exception {
		RelWordVO target = relWordMapper.selectByNo(relWordNo);
		if (target == null) return;

		if (target.getAttNo() != null) {
			try { attachService.deleteByNo(target.getAttNo()); }
			catch (Exception e) {
				org.slf4j.LoggerFactory.getLogger(RelWordServiceImpl.class)
						.warn("관련자료(WORD) 첨부 삭제 실패 — 디스크/DB 고아 가능 (attNo={}): {}", target.getAttNo(), e.getMessage());
			}
		}
		relWordMapper.deleteByNo(relWordNo);

		Long relVrsnNo = target.getRelVrsnNo();
		if (relVrsnNo != null) {
			List<RelWordVO> remaining = relWordMapper.selectByRelVrsnNo(relVrsnNo);
			if (remaining == null || remaining.isEmpty()) {
				relVrsnService.delete(relVrsnNo);
			}
		}
	}

	// ────────────────────────────────────────────────────────────────
	// 자체변환 헬퍼
	// ────────────────────────────────────────────────────────────────

	/** 추출 평문 → 안전한 인라인 HTML (이스케이프 + 빈줄 단락 분리, 단락 내 줄바꿈은 &lt;br&gt;). */
	private static String buildBasicHtml(String text) {
		String[] paras = text.split("\\n\\s*\\n");   // 빈 줄 = 단락 경계
		StringBuilder sb = new StringBuilder("<div class=\"rel-word-doc\">");
		for (String para : paras) {
			String p = para.trim();
			if (p.isEmpty()) continue;
			sb.append("<p>").append(escapeHtml(p).replace("\n", "<br/>")).append("</p>");
		}
		sb.append("</div>");
		return sb.toString();
	}

	/** XSS 방지 — 추출 평문을 HTML 에 넣기 전 이스케이프. */
	private static String escapeHtml(String s) {
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
				.replace("\"", "&quot;").replace("'", "&#39;");
	}

	/** 파일 확장자 → 문서유형 라벨(STYPE). */
	private static String docType(String fileName) {
		if (fileName == null) return null;
		String l = fileName.toLowerCase();
		if (l.endsWith(".docx")) return "DOCX";
		if (l.endsWith(".hwpx")) return "HWPX";
		if (l.endsWith(".pdf")) return "PDF";
		if (l.endsWith(".doc")) return "DOC";
		return null;
	}
}
