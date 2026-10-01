/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/impl/RelHtmlServiceImpl.java
 *
 * 관련자료 — HTML 액션 Service 구현.
 *  saveHtml 의 절차 (레거시 RelatedController.htmlUpdateDo 패턴):
 *   1) RelHtml PK 채번
 *   2) RelVrsnService.getNewVersion(..., title, null cateNo) → IRVRSN_NO  (분류 없음)
 *   3) RelHtml INSERT { IRHTML_NO, IRVRSN_NO, STITLE, SHTML, SDEL_YN='N', ... }
 *
 *  ※ Oracle 은 '' 를 NULL 로 취급 → STITLE/SHTML NOT NULL 위반 방지 위해
 *    빈 제목/본문은 각각 '(제목없음)' / 공백 한 칸으로 치환 (레거시 의 " " 디폴트 패턴).
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

import narainet.rlms.related.mapper.RelHtmlMapper;
import narainet.rlms.related.service.RelHtmlService;
import narainet.rlms.related.service.RelHtmlVO;
import narainet.rlms.related.service.RelVrsnService;

@Service("relHtmlService")
public class RelHtmlServiceImpl extends EgovAbstractServiceImpl implements RelHtmlService {

	@Resource(name = "relHtmlMapper")
	private RelHtmlMapper relHtmlMapper;

	@Resource(name = "egovRelHtmlIdGnrService")
	private EgovIdGnrService relHtmlIdGnrService;

	@Resource(name = "relVrsnService")
	private RelVrsnService relVrsnService;

	@Override
	public List<RelHtmlVO> getList(Long relVrsnNo) {
		return relHtmlMapper.selectByRelVrsnNo(relVrsnNo);
	}

	@Override
	public RelHtmlVO getByNo(Long relHtmlNo) {
		return relHtmlMapper.selectByNo(relHtmlNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long saveHtml(Long promNo, String flag, String fullItem,
			String title, String html, String sysId) throws Exception {

		if (promNo == null) {
			throw processException("related.html.invalid");
		}

		String effectiveTitle = (title != null && !title.trim().isEmpty())
				? title.trim() : "(제목없음)";
		// Oracle: '' == NULL → NOT NULL 회피 (빈 본문은 공백 한 칸)
		String effectiveHtml = (html != null && !html.isEmpty()) ? html : " ";

		// 1) 자식 PK 채번
		Long relHtmlNo = relHtmlIdGnrService.getNextLongId();

		// 2) 마스터 row 발급 — 분류 없음 (getNewVersion, cateNo=null)
		Long relVrsnNo = relVrsnService.getNewVersion(
				promNo,
				"Y",                                    // vrsnYn
				"TB_REL_HTML",                          // stable
				(flag != null && !flag.isEmpty() ? flag : "PROMULGATION"),
				fullItem,
				effectiveTitle,
				null,                                   // cateNo — HTML 은 분류 없음
				sysId);

		// 3) 자식 INSERT
		RelHtmlVO vo = new RelHtmlVO();
		vo.setRelHtmlNo(relHtmlNo);
		vo.setRelVrsnNo(relVrsnNo);
		vo.setTitle(effectiveTitle);
		vo.setHtml(effectiveHtml);
		vo.setDelYn("N");
		vo.setInsDt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
		vo.setSysId((sysId != null && !sysId.isEmpty()) ? sysId : null);   // 단일 시스템 — 미전송 시 null(필터 미사용)
		relHtmlMapper.insert(vo);

		return relHtmlNo;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateContent(Long relHtmlNo, String title, String html) {
		RelHtmlVO target = relHtmlMapper.selectByNo(relHtmlNo);
		if (target == null) return;
		if (title != null) {
			target.setTitle(title.trim().isEmpty() ? "(제목없음)" : title.trim());
		}
		if (html != null) {
			target.setHtml(html.isEmpty() ? " " : html);
		}
		relHtmlMapper.update(target);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void softDelete(Long relHtmlNo) {
		relHtmlMapper.softDelete(relHtmlNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long relHtmlNo) throws Exception {
		RelHtmlVO target = relHtmlMapper.selectByNo(relHtmlNo);
		if (target == null) return;

		relHtmlMapper.deleteByNo(relHtmlNo);

		Long relVrsnNo = target.getRelVrsnNo();
		if (relVrsnNo != null) {
			List<RelHtmlVO> remaining = relHtmlMapper.selectByRelVrsnNo(relVrsnNo);
			if (remaining == null || remaining.isEmpty()) {
				relVrsnService.delete(relVrsnNo);
			}
		}
	}
}
