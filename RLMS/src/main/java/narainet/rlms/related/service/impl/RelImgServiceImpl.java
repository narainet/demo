/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelImgServiceImpl.java
 *
 * 관련자료 — IMAGE 액션 Service 구현. ORGN 패턴과 동일 + 확장자만 다름.
 *  1) RelImg PK 채번
 *  2) AttachService.save("TB_REL_IMG", IRIMG_NO, "IMAGE", file, sysId) → IATT_NO
 *  3) RelVrsnService.getNewVersion(...table="TB_REL_IMG"..., cateNo=null) → IRVRSN_NO
 *  4) RelImg INSERT
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
import narainet.rlms.related.mapper.RelImgMapper;
import narainet.rlms.related.service.RelImgService;
import narainet.rlms.related.service.RelImgVO;
import narainet.rlms.related.service.RelVrsnService;

@Service("relImgService")
public class RelImgServiceImpl extends EgovAbstractServiceImpl implements RelImgService {

	@Resource(name = "relImgMapper")
	private RelImgMapper relImgMapper;

	@Resource(name = "egovRelImgIdGnrService")
	private EgovIdGnrService relImgIdGnrService;

	@Resource(name = "relVrsnService")
	private RelVrsnService relVrsnService;

	@Resource(name = "attachService")
	private AttachService attachService;

	@Override
	public List<RelImgVO> getList(Long relVrsnNo) {
		return relImgMapper.selectByRelVrsnNo(relVrsnNo);
	}

	@Override
	public RelImgVO getByNo(Long relImgNo) {
		return relImgMapper.selectByNo(relImgNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long saveImg(Long promNo, String flag, String fullItem,
			String title, MultipartFile file, String sysId) throws Exception {

		if (promNo == null || file == null || file.isEmpty()) {
			throw processException("related.img.invalid");
		}

		Long relImgNo = relImgIdGnrService.getNextLongId();

		AttachVO att = attachService.save("TB_REL_IMG", relImgNo, "IMAGE", file, sysId);

		String effectiveTitle = (title != null && !title.trim().isEmpty())
				? title.trim()
				: ((att.getName() != null) ? att.getName() : "(제목없음)");

		Long relVrsnNo = relVrsnService.getNewVersion(
				promNo,
				"Y",
				"TB_REL_IMG",
				(flag != null && !flag.isEmpty() ? flag : "PROMULGATION"),
				fullItem,
				effectiveTitle,
				null,
				sysId);

		RelImgVO vo = new RelImgVO();
		vo.setRelImgNo(relImgNo);
		vo.setRelVrsnNo(relVrsnNo);
		vo.setAttNo(att.getAttNo());
		vo.setTitle(effectiveTitle);
		vo.setDelYn("N");
		vo.setInsDt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
		vo.setSysId(att.getSysId());
		relImgMapper.insert(vo);

		return relImgNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateMeta(Long relImgNo, String title) {
		RelImgVO target = relImgMapper.selectByNo(relImgNo);
		if (target == null) return;
		if (title != null) target.setTitle(title);
		relImgMapper.update(target);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void softDelete(Long relImgNo) {
		relImgMapper.softDelete(relImgNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relImgNo) throws Exception {
		RelImgVO target = relImgMapper.selectByNo(relImgNo);
		if (target == null) return;

		if (target.getAttNo() != null) {
			try { attachService.deleteByNo(target.getAttNo()); }
			catch (Exception e) {
				org.slf4j.LoggerFactory.getLogger(RelImgServiceImpl.class)
						.warn("관련자료(IMAGE) 첨부 삭제 실패 — 디스크/DB 고아 가능 (attNo={}): {}", target.getAttNo(), e.getMessage());
			}
		}
		relImgMapper.deleteByNo(relImgNo);

		Long relVrsnNo = target.getRelVrsnNo();
		if (relVrsnNo != null) {
			List<RelImgVO> remaining = relImgMapper.selectByRelVrsnNo(relVrsnNo);
			if (remaining == null || remaining.isEmpty()) {
				relVrsnService.delete(relVrsnNo);
			}
		}
	}
}
