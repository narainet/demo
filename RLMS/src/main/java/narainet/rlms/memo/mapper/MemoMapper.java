/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/memo/mapper/MemoMapper.java
 */
package narainet.rlms.memo.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.memo.service.MemoVO;

@Mapper
public interface MemoMapper {

	List<MemoVO> selectMyMemoList(@Param("userId") String userId, @Param("vo") MemoVO vo);

	int selectMyMemoListCnt(@Param("userId") String userId, @Param("vo") MemoVO vo);

	MemoVO selectMemoByNo(@Param("memoNo") Long memoNo);

	List<MemoVO> selectMemoListByLaw(@Param("userId") String userId,
			@Param("lawId") Long lawId,
			@Param("sysId") String sysId);

	List<MemoVO> selectMemoListByItem(@Param("userId") String userId,
			@Param("lawId") Long lawId,
			@Param("item") String item,
			@Param("sysId") String sysId);

	int insertMemo(MemoVO vo);

	int updateMemo(MemoVO vo);

	int deleteMemo(@Param("memoNo") Long memoNo);
}
