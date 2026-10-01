/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/relexcl/service/RelExclLnkService.java
 */
package narainet.rlms.relexcl.service;

import java.util.List;

public interface RelExclLnkService {

	List<RelExclLnkVO> selectExclList(Long exclLawId, String sysId);

	RelExclLnkVO selectByNo(Long relnkNo);

	/**
	 * 제외범위 추가.
	 *  · vo.flag = 'full_text_gubun' / 'full_text_category' / 'full_text_leaf' 중 하나
	 *  · flag 별 채워야 할 필드: gubunId / cateNo / lawId
	 * @return 생성된 relnkNo. 중복이면 0.
	 */
	Long insertExcl(RelExclLnkVO vo) throws Exception;

	int deleteByNo(Long relnkNo);

	int deleteByExclLawId(Long exclLawId, String sysId);
}
