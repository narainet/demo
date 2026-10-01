/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelOrgnServiceImpl.java
 *
 * 관련자료 — ORGN 액션 Service 구현.
 *  saveOrgn 의 절차 (레거시 RelatedController.orgnUpdateDo 패턴):
 *   1) RelOrgn PK 채번 (IATT_NO 가 가리킬 자식 PK 먼저 발급)
 *   2) AttachService.save("TB_REL_ORGN", IRORGN_NO, "ORGN", file, sysId) → IATT_NO
 *   3) RelVrsnService.getNewVersion(..., title, null cateNo) → IRVRSN_NO  (카테고리 없음)
 *   4) RelOrgn INSERT { IRORGN_NO, IRVRSN_NO, IATT_NO, STITLE, SDEL_YN='N', ... }
 */
package narainet.rlms.related.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import narainet.rlms.attach.service.AttachService;
import narainet.rlms.attach.service.AttachVO;
import narainet.rlms.related.mapper.RelOrgnMapper;
import narainet.rlms.related.service.RelOrgnService;
import narainet.rlms.related.service.RelOrgnVO;
import narainet.rlms.related.service.RelVrsnService;

@Service("relOrgnService")
public class RelOrgnServiceImpl extends EgovAbstractServiceImpl implements RelOrgnService {

	@Resource(name = "relOrgnMapper")
	private RelOrgnMapper relOrgnMapper;

	@Resource(name = "egovRelOrgnIdGnrService")
	private EgovIdGnrService relOrgnIdGnrService;

	@Resource(name = "relVrsnService")
	private RelVrsnService relVrsnService;

	@Resource(name = "attachService")
	private AttachService attachService;

	@Override
	public List<RelOrgnVO> getList(Long relVrsnNo) {
		return relOrgnMapper.selectByRelVrsnNo(relVrsnNo);
	}

	@Override
	public RelOrgnVO getByNo(Long relOrgnNo) {
		return relOrgnMapper.selectByNo(relOrgnNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long saveOrgn(Long promNo, String flag, String fullItem,
			String title, MultipartFile file, String sysId) throws Exception {

		if (promNo == null || file == null || file.isEmpty()) {
			throw processException("related.orgn.invalid");
		}

		// 1) 자식 PK 먼저 채번 (TB_ATTACH.IREF_NO 가 가리킬 값)
		Long relOrgnNo = relOrgnIdGnrService.getNextLongId();

		// 2) 파일 업로드 + 첨부 row INSERT — categoryId='ORGN', refTable='TB_REL_ORGN'
		AttachVO att = attachService.save("TB_REL_ORGN", relOrgnNo, "ORGN", file, sysId);

		// 3) 마스터 row 발급 — ORGN 액션 = getNewVersion (카테고리 메타 없음)
		String effectiveTitle = (title != null && !title.trim().isEmpty())
				? title.trim()
				: ((att.getName() != null) ? att.getName() : "(제목없음)");

		Long relVrsnNo = relVrsnService.getNewVersion(
				promNo,
				"Y",                                    // vrsnYn
				"TB_REL_ORGN",                          // stable
				(flag != null && !flag.isEmpty() ? flag : "PROMULGATION"),
				fullItem,
				effectiveTitle,
				null,                                   // cateNo — ORGN 은 분류 없음
				sysId);

		// 4) 자식 INSERT
		RelOrgnVO vo = new RelOrgnVO();
		vo.setRelOrgnNo(relOrgnNo);
		vo.setRelVrsnNo(relVrsnNo);
		vo.setAttNo(att.getAttNo());
		vo.setTitle(effectiveTitle);
		vo.setDelYn("N");
		vo.setInsDt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
		vo.setSysId(att.getSysId());
		relOrgnMapper.insert(vo);

		return relOrgnNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateMeta(Long relOrgnNo, String title) {
		RelOrgnVO target = relOrgnMapper.selectByNo(relOrgnNo);
		if (target == null) return;
		if (title != null) target.setTitle(title);
		relOrgnMapper.update(target);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void softDelete(Long relOrgnNo) {
		relOrgnMapper.softDelete(relOrgnNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relOrgnNo) throws Exception {
		RelOrgnVO target = relOrgnMapper.selectByNo(relOrgnNo);
		if (target == null) return;

		// 1) 첨부 디스크/DB 정리 (best-effort)
		if (target.getAttNo() != null) {
			try {
				attachService.deleteByNo(target.getAttNo());
			} catch (Exception ignore) { /* 디스크 미존재 등 */ }
		}
		// 2) 자식 행 물리 삭제
		relOrgnMapper.deleteByNo(relOrgnNo);

		// 3) 마스터의 마지막 자식이었다면 마스터 정리
		Long relVrsnNo = target.getRelVrsnNo();
		if (relVrsnNo != null) {
			List<RelOrgnVO> remaining = relOrgnMapper.selectByRelVrsnNo(relVrsnNo);
			if (remaining == null || remaining.isEmpty()) {
				relVrsnService.delete(relVrsnNo);
			}
		}
	}
}
