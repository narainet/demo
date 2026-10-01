/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/favor/service/FavorService.java
 */
package narainet.rlms.favor.service;

import java.util.List;
import java.util.Map;

public interface FavorService {

	/** 현재 사용자의 즐겨찾기 목록 (페이징 + 키워드) */
	Map<String, Object> selectMyFavorList(String userId, FavorVO vo);

	/** 특정 법령(lawId) 의 특정 조항(item) 이 즐겨찾기인지 1건 조회 */
	FavorVO selectFavorByLawItem(String userId, Long lawId, String item, String sysId);

	/** 한 법령 안의 즐겨찾기 (prom 본문 사이드 위젯용) */
	List<FavorVO> selectFavorListByLaw(String userId, Long lawId, String sysId);

	void addFavor(FavorVO vo) throws Exception;

	/** 뷰어 본문 열람 시 확인 회차 기록 — 홈 "즐겨찾기 규정 개정 소식" 해소(즐겨찾기 없으면 무동작) */
	void touchSeen(String userId, Long lawId, Long lawNo);

	void updateFavor(FavorVO vo, String userId) throws Exception;

	/** 본인 소유 검증 후 삭제 */
	void deleteFavor(Long favorNo, String userId) throws Exception;
}
