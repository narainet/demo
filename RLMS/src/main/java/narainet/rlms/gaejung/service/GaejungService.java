/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/gaejung/service/GaejungService.java
 */
package narainet.rlms.gaejung.service;

import java.util.List;
import java.util.Map;

public interface GaejungService {

	/** 목록 (페이징/검색) */
	Map<String, Object> selectGaejungList(GaejungVO vo);

	/** 셀렉트박스 / API 용 — 전체 목록 (페이징 없이) */
	List<GaejungVO> selectAllForSelector();

	/** PK 단건 */
	GaejungVO selectGaejungByNo(Long gaejungNo);

	void insertGaejung(GaejungVO vo) throws Exception;

	void updateGaejung(GaejungVO vo) throws Exception;

	void updateGaejungList(List<GaejungVO> list) throws Exception;

	/** 소프트 삭제 (사용 중인 법령 있으면 차단) */
	void deleteGaejung(Long gaejungNo) throws Exception;
}
