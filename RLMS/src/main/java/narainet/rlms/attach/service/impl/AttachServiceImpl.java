/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/attach/service/impl/AttachServiceImpl.java
 *
 * 도메인 첨부(TB_ATTACH) Service 구현체.
 *
 * 저장 경로 (egovProps/globals.properties — context-properties.xml 의 extFileName 으로 로드):
 *   1) Globals.rlms.AttachPath (명시 override, 선택)
 *   2) Globals.fileStorePath/rlms_attach (eGov 표준 업로드 루트 재사용 — 기본)
 *   3) java.io.tmpdir/rlms_attach (최후 폴백)
 */
package narainet.rlms.attach.service.impl;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.UUID;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import narainet.rlms.attach.mapper.AttachMapper;
import narainet.rlms.attach.service.AttachService;
import narainet.rlms.attach.service.AttachVO;

/**
 * 도메인 첨부 Service 구현체
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성 (feedback_attach_policy.md 반영)
 * </pre>
 */
@Service("attachService")
public class AttachServiceImpl extends EgovAbstractServiceImpl implements AttachService {

	@Resource(name = "attachMapper")
	private AttachMapper attachMapper;

	@Resource(name = "egovAttachIdGnrService")
	private EgovIdGnrService attachIdGnrService;

	@Resource(name = "propertiesService")
	private EgovPropertyService propertyService;

	@Override
	public List<AttachVO> listByRef(String refTable, Long refNo) {
		return attachMapper.selectAttachByRef(refTable, refNo);
	}

	@Override
	public AttachVO selectByNo(Long attNo) {
		return attachMapper.selectAttachByNo(attNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public AttachVO save(String refTable, Long refNo, String cateId,
			MultipartFile file, String sysId) throws Exception {

		if (file == null || file.isEmpty()) {
			throw processException("attach.upload.fail");
		}

		String baseDir = getAttachBaseDir();
		File saveDir = new File(baseDir, refTable);
		if (!saveDir.exists() && !saveDir.mkdirs()) {
			throw new IOException("Cannot create directory: " + saveDir.getAbsolutePath());
		}

		String originalName = file.getOriginalFilename();
		String ext = extOf(originalName);
		String mapping = UUID.randomUUID().toString().replace("-", "") + (ext.isEmpty() ? "" : "." + ext);
		File dest = new File(saveDir, mapping);
		file.transferTo(dest);

		AttachVO vo = new AttachVO();
		vo.setAttNo(attachIdGnrService.getNextLongId());
		vo.setCateId(cateId);
		vo.setRefTable(refTable);
		vo.setRefNo(refNo);
		vo.setPath(dest.getAbsolutePath());
		vo.setName(originalName);
		vo.setMapping(mapping);
		vo.setExt(ext);
		vo.setTitle(originalName);
		vo.setSize(file.getSize());
		vo.setSysId((sysId == null || sysId.isEmpty()) ? null : sysId);   // 단일 시스템 — 미전송 시 null(필터 미사용)
		// TB_ATTACH 스키마: SMETA/ISEQ NOT NULL, SCONTENTS 도 레거시 관행상 공백 디폴트
		vo.setMeta(" ");
		vo.setContents(" ");
		vo.setSeq(1);

		attachMapper.insertAttach(vo);
		return vo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int deleteByRef(String refTable, Long refNo) throws Exception {
		List<AttachVO> list = attachMapper.selectAttachByRef(refTable, refNo);
		for (AttachVO v : list) {
			deletePhysical(v);
		}
		return attachMapper.deleteAttachByRef(refTable, refNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int deleteByNo(Long attNo) throws Exception {
		AttachVO target = attachMapper.selectAttachByNo(attNo);
		if (target == null) {
			throw processException("attach.notfound");
		}
		deletePhysical(target);
		return attachMapper.deleteAttachByNo(attNo);
	}

	@Override
	public File resolvePhysical(AttachVO att) {
		if (att == null) return null;
		// 1) RLMS 신규 행 — SPATH 가 파일명 포함 절대경로
		if (att.getPath() != null && !att.getPath().isEmpty()) {
			File f = new File(att.getPath());
			if (f.isAbsolute() && f.isFile() && f.canRead()) return f;
		}
		// 2) 레거시 이관 행 — 레거시루트/SPATH(월키)/SMAPPING
		if (att.getMapping() != null && !att.getMapping().isEmpty()) {
			String root = getLegacyAttachRoot();
			if (root != null) {
				File dir = (att.getPath() != null && !att.getPath().isEmpty())
						? new File(root, att.getPath()) : new File(root);
				File f = new File(dir, att.getMapping());
				if (f.isFile() && f.canRead()) return f;
			}
		}
		return null;
	}

	@Override
	public File resolvePdfView(AttachVO att) {
		File f = resolvePhysical(att);
		if (f == null) return null;
		if ("pdf".equalsIgnoreCase(extOf(f.getName()))) return f;
		// 레거시 DCMS 변환본 — 같은 폴더, 저장명의 확장자만 .pdf
		String name = f.getName();
		int dot = name.lastIndexOf('.');
		String pdfName = (dot > 0 ? name.substring(0, dot) : name) + ".pdf";
		File pdf = new File(f.getParentFile(), pdfName);
		return (pdf.isFile() && pdf.canRead()) ? pdf : null;
	}

	// ────────────────────────────────────────────────────────────────
	// helpers
	// ────────────────────────────────────────────────────────────────

	/** 미설정 경고는 1회만 — 레거시 첨부가 왜 404 인지 로그로 추적 가능하게 */
	private static volatile boolean legacyRootWarned = false;

	private String getLegacyAttachRoot() {
		try {
			String v = propertyService.getString("Globals.rlms.LegacyAttachPath");
			if (v != null && !v.isEmpty()) {
				return v;
			}
		} catch (Exception ignored) {
			// 설정 미존재 — 레거시 파일 미탑재 환경
		}
		if (!legacyRootWarned) {
			legacyRootWarned = true;
			LoggerHolder.LOG.warn("Globals.rlms.LegacyAttachPath 미설정 (context-properties.xml) — "
					+ "레거시 이관 첨부 해석 비활성 (다운로드/인라인 404, 뷰어는 파일목록 안내로 폴백)");
		}
		return null;
	}

	private String getAttachBaseDir() {
		// 1) 명시 override (선택)
		String v = getPropSafe("Globals.rlms.AttachPath");
		if (v != null) return v;
		// 2) eGov 표준 업로드 루트 재사용 (globals.properties Globals.fileStorePath, 예: D:/upload/)
		//    — 표준 모듈 파일과 섞이지 않게 하위 rlms_attach 로 격리
		String std = getPropSafe("Globals.fileStorePath");
		if (std != null) return new File(std, "rlms_attach").getPath();
		// 3) 최후 폴백
		return System.getProperty("java.io.tmpdir") + File.separator + "rlms_attach";
	}

	private String getPropSafe(String key) {
		try {
			String v = propertyService.getString(key);
			return (v == null || v.trim().isEmpty()) ? null : v.trim();
		} catch (Exception e) {
			return null;   // 키 미정의
		}
	}

	private static void deletePhysical(AttachVO v) {
		if (v.getPath() == null) return;
		File f = new File(v.getPath());
		if (f.exists() && !f.delete()) {
			// 삭제 실패는 로깅만 (정합성 깨지 않도록 SQL 진행)
			LoggerHolder.LOG.warn("Could not delete attach file: {}", v.getPath());
		}
	}

	private static String extOf(String name) {
		if (name == null) return "";
		int dot = name.lastIndexOf('.');
		if (dot < 0 || dot == name.length() - 1) return "";
		return name.substring(dot + 1).toLowerCase();
	}

	private static final class LoggerHolder {
		static final org.slf4j.Logger LOG = org.slf4j.LoggerFactory.getLogger(AttachServiceImpl.class);
	}
}
