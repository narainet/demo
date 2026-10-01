/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/memo/service/MemoService.java
 */
package narainet.rlms.memo.service;

import java.util.List;
import java.util.Map;

public interface MemoService {

	/** 내 메모 목록 (페이징/키워드) */
	Map<String, Object> selectMyMemoList(String userId, MemoVO vo);

	/** 한 법령의 내 메모 목록 (prom 사이드 위젯용) */
	List<MemoVO> selectMemoListByLaw(String userId, Long lawId, String sysId);

	/** 한 조항의 내 메모 목록 (특정 조항만 펼쳐 보기) */
	List<MemoVO> selectMemoListByItem(String userId, Long lawId, String item, String sysId);

	void addMemo(MemoVO vo) throws Exception;

	void updateMemo(MemoVO vo, String userId) throws Exception;

	void deleteMemo(Long memoNo, String userId) throws Exception;
}
