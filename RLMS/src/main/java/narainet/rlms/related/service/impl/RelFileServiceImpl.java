/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelFileServiceImpl.java
 *
 * 관련자료 — FILE 액션 Service 구현.
 *  saveFile 의 절차 (레거시 RelatedController.fileUpdateDo 패턴):
 *   1) RelFile PK 채번 (IATT_NO 가 가리킬 자식 PK 먼저 발급)
 *   2) AttachService.save("TB_REL_FILE", IRFILE_NO, "FILE", file, sysId) → IATT_NO
 *   3) RelVrsnService.getNewHseqVersion(..., title, cateNo, cateName, cateOrder) → IRVRSN_NO
 *   4) RelFile INSERT { IRFILE_NO, IRVRSN_NO, IATT_NO, ... SVIEW_YN(ext 분기) ... }
 */
package narainet.rlms.related.service.impl;

import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import narainet.rlms.attach.service.AttachService;
import narainet.rlms.attach.service.AttachVO;
import narainet.rlms.related.mapper.RelFileMapper;
import narainet.rlms.related.service.RelFileService;
import narainet.rlms.related.service.RelFileVO;
import narainet.rlms.related.service.RelVrsnService;

@Service("relFileService")
public class RelFileServiceImpl extends EgovAbstractServiceImpl implements RelFileService {

	/** 미리보기 변환 가능 확장자 — 레거시 fileUpdateDo 의 SVIEW_YN 분기와 동일 */
	private static final Set<String> VIEWABLE_EXT = new HashSet<>(Arrays.asList(
			"doc", "docx", "hwp", "xls", "xlsx", "ppt", "pptx", "pdf"));

	@Resource(name = "relFileMapper")
	private RelFileMapper relFileMapper;

	@Resource(name = "egovRelFileIdGnrService")
	private EgovIdGnrService relFileIdGnrService;

	@Resource(name = "relVrsnService")
	private RelVrsnService relVrsnService;

	@Resource(name = "attachService")
	private AttachService attachService;

	@Override
	public List<RelFileVO> getList(Long relVrsnNo) {
		return relFileMapper.selectByRelVrsnNo(relVrsnNo);
	}

	@Override
	public RelFileVO getByNo(Long relFileNo) {
		return relFileMapper.selectByNo(relFileNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long saveFile(Long promNo, String flag, String fullItem,
			Long cateNo, String cateName, Integer cateOrder,
			String title, MultipartFile file, String sysId) throws Exception {

		if (promNo == null || file == null || file.isEmpty()) {
			throw processException("related.file.invalid");
		}

		// 1) 자식 PK 먼저 채번 (TB_ATTACH.IREF_NO 가 가리킬 값)
		Long relFileNo = relFileIdGnrService.getNextLongId();

		// 2) 파일 업로드 + 첨부 row INSERT — categoryId='FILE', refTable='TB_REL_FILE'
		AttachVO att = attachService.save("TB_REL_FILE", relFileNo, "FILE", file, sysId);

		// 3) 마스터 row 발급 — FILE 액션 = getNewHseqVersion (카테고리 메타 포함)
		String effectiveTitle = (title != null && !title.trim().isEmpty())
				? title.trim()
				: ((att.getName() != null) ? att.getName() : "(제목없음)");

		Long relVrsnNo = relVrsnService.getNewHseqVersion(
				promNo,
				"Y",                                    // vrsnYn
				"TB_REL_FILE",                          // stable
				(flag != null && !flag.isEmpty() ? flag : "PROMULGATION"),
				fullItem,
				effectiveTitle,
				cateNo,
				sysId,
				cateName,
				cateOrder);

		// 4) 자식 INSERT
		String ext = (att.getExt() != null) ? att.getExt().toLowerCase() : "";
		String viewYn = VIEWABLE_EXT.contains(ext) ? "Y" : "N";

		RelFileVO vo = new RelFileVO();
		vo.setRelFileNo(relFileNo);
		vo.setRelVrsnNo(relVrsnNo);
		vo.setAttNo(att.getAttNo());
		// SCATE NOT NULL + Oracle ''=NULL → 빈 문자열이면 ORA-01400. 레거시 코드 REL_FILE_1=관련파일(일반 파일등록).
		vo.setCate("REL_FILE_1");
		vo.setTitle(effectiveTitle);
		vo.setDelYn("N");
		vo.setInsDt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
		vo.setSysId(att.getSysId());
		vo.setViewYn(viewYn);
		vo.setViewCmpltYn("N");
		relFileMapper.insert(vo);

		return relFileNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateMeta(Long relFileNo, String title, String cate) {
		RelFileVO target = relFileMapper.selectByNo(relFileNo);
		if (target == null) return;
		if (title != null) target.setTitle(title);
		if (cate  != null) target.setCate(cate);
		relFileMapper.update(target);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void softDelete(Long relFileNo) {
		relFileMapper.softDelete(relFileNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relFileNo) throws Exception {
		RelFileVO target = relFileMapper.selectByNo(relFileNo);
		if (target == null) return;

		// 1) 첨부 디스크/DB 정리 (best-effort)
		if (target.getAttNo() != null) {
			try {
				attachService.deleteByNo(target.getAttNo());
			} catch (Exception ignore) { /* 디스크 미존재 등 */ }
		}
		// 2) 자식 행 물리 삭제
		relFileMapper.deleteByNo(relFileNo);

		// 3) 마스터의 마지막 자식이었다면 마스터 정리
		Long relVrsnNo = target.getRelVrsnNo();
		if (relVrsnNo != null) {
			List<RelFileVO> remaining = relFileMapper.selectByRelVrsnNo(relVrsnNo);
			if (remaining == null || remaining.isEmpty()) {
				relVrsnService.delete(relVrsnNo);
			}
		}
	}
}
