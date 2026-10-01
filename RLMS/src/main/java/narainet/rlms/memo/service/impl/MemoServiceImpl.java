/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/memo/service/impl/MemoServiceImpl.java
 */
package narainet.rlms.memo.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.memo.mapper.MemoMapper;
import narainet.rlms.memo.service.MemoService;
import narainet.rlms.memo.service.MemoVO;

@Service("memoService")
public class MemoServiceImpl extends EgovAbstractServiceImpl implements MemoService {

	@Resource(name = "memoMapper")
	private MemoMapper memoMapper;

	@Resource(name = "egovMemoIdGnrService")
	private EgovIdGnrService memoIdGnrService;

	@Override
	public Map<String, Object> selectMyMemoList(String userId, MemoVO vo) {
		List<MemoVO> list = memoMapper.selectMyMemoList(userId, vo);
		int cnt = memoMapper.selectMyMemoListCnt(userId, vo);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public List<MemoVO> selectMemoListByLaw(String userId, Long lawId, String sysId) {
		return memoMapper.selectMemoListByLaw(userId, lawId, sysId);
	}

	@Override
	public List<MemoVO> selectMemoListByItem(String userId, Long lawId, String item, String sysId) {
		return memoMapper.selectMemoListByItem(userId, lawId, item, sysId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void addMemo(MemoVO vo) throws Exception {
		if (vo.getContents() == null || vo.getContents().trim().isEmpty()) {
			throw processException("memo.empty");
		}
		// SSYS_ID 는 강제 세팅하지 않음(단일 시스템 — 필터 미사용, null 허용). 프론트 미전송 → null 저장.
		vo.setMemoNo(memoIdGnrService.getNextLongId());
		memoMapper.insertMemo(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateMemo(MemoVO vo, String userId) throws Exception {
		MemoVO target = memoMapper.selectMemoByNo(vo.getMemoNo());
		if (target == null) throw processException("memo.notfound");
		if (!target.getUserId().equals(userId)) throw processException("memo.no.permission");
		memoMapper.updateMemo(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteMemo(Long memoNo, String userId) throws Exception {
		MemoVO target = memoMapper.selectMemoByNo(memoNo);
		if (target == null) throw processException("memo.notfound");
		if (!target.getUserId().equals(userId)) throw processException("memo.no.permission");
		memoMapper.deleteMemo(memoNo);
	}
}
