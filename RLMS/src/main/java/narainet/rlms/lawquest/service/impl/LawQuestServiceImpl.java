/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/lawquest/service/impl/LawQuestServiceImpl.java
 */
package narainet.rlms.lawquest.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.attach.service.AttachService;
import narainet.rlms.attach.service.AttachVO;
import narainet.rlms.lawquest.mapper.LawQuestMapper;
import narainet.rlms.lawquest.service.LawQuestAdminVO;
import narainet.rlms.lawquest.service.LawQuestService;
import narainet.rlms.lawquest.service.LawQuestVO;

@Service("lawQuestService")
public class LawQuestServiceImpl extends EgovAbstractServiceImpl implements LawQuestService {

	private static final String REF_TABLE = "TB_LAWQUEST";

	@Resource(name = "lawQuestMapper")
	private LawQuestMapper lawQuestMapper;

	@Resource(name = "egovLawQuestIdGnrService")
	private EgovIdGnrService lawQuestIdGnrService;

	@Resource(name = "attachService")
	private AttachService attachService;

	@Override
	public Map<String, Object> getList(LawQuestVO vo) {
		List<LawQuestVO> list = lawQuestMapper.selectList(vo);
		int cnt = lawQuestMapper.selectListCnt(vo);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public List<LawQuestVO> getListAll(LawQuestVO vo) {
		return lawQuestMapper.selectListAll(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public LawQuestVO getDetail(Long no, boolean increaseRead) {
		if (increaseRead) {
			lawQuestMapper.increaseReadnum(no);
		}
		return lawQuestMapper.selectByNo(no);
	}

	@Override
	public List<String> getYears() {
		return lawQuestMapper.selectYears();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public Long insert(LawQuestVO vo) throws Exception {
		vo.setNo(lawQuestIdGnrService.getNextLongId());
		if (vo.getGumaek() == null) vo.setGumaek(0L);
		lawQuestMapper.insert(vo);
		return vo.getNo();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void update(LawQuestVO vo) throws Exception {
		if (vo.getGumaek() == null) vo.setGumaek(0L);
		lawQuestMapper.update(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void delete(Long no) throws Exception {
		// 첨부 먼저 정리 (TB_ATTACH + 물리파일)
		List<AttachVO> atts = attachService.listByRef(REF_TABLE, no);
		if (atts != null) {
			for (AttachVO a : atts) {
				attachService.deleteByNo(a.getAttNo());
			}
		}
		lawQuestMapper.delete(no);
	}

	@Override
	public boolean isAnswerAdmin(String sabun) {
		if (sabun == null || sabun.isEmpty()) return false;
		return lawQuestMapper.countAdmin(sabun) > 0;
	}

	// ── 답변권한자 레지스트리 ──────────────────────────────────
	@Override
	public List<LawQuestAdminVO> getAdminList() {
		return lawQuestMapper.selectAdminList();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public boolean addAdmin(String sabun, String name) throws Exception {
		if (sabun == null || sabun.trim().isEmpty()) return false;
		String s = sabun.trim();
		if (lawQuestMapper.countAdmin(s) > 0) return false; // 중복
		LawQuestAdminVO vo = new LawQuestAdminVO();
		vo.setSabun(s);
		vo.setName(name == null ? "" : name.trim());
		lawQuestMapper.insertAdmin(vo);
		return true;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void removeAdmin(String sabun) throws Exception {
		if (sabun == null || sabun.trim().isEmpty()) return;
		lawQuestMapper.deleteAdmin(sabun.trim());
	}

	@Override
	public List<Map<String, Object>> searchMembers(String kw) {
		return lawQuestMapper.searchMembers(kw == null ? "" : kw.trim());
	}
}
