/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ProvHtmlService.java
 */
package narainet.rlms.prom.service;

import java.util.List;

/**
 * 조항 HTML 본문(TB_PROV_HTML) 관리 Service.
 * insert/update 시 ProvVrsnService.decomposeAndStore() 를 동기 호출하여
 * TB_PROV_VRSN 의 단위 row 도 함께 갱신한다.
 */
public interface ProvHtmlService {

	List<ProvHtmlVO> selectProvHtmlList(Long promNo);

	/** 관리자(IDE 트리) 누적 조회 — 이전 회차 상속분 포함, 숨김행은 자기 회차에서만 */
	List<ProvHtmlVO> selectProvHtmlListCumulativeAdmin(Long lawId, Long lawNo);

	ProvHtmlVO selectProvHtmlByNo(Long provHtmlNo);

	ProvHtmlVO selectProvHtmlByPromItem(Long promNo, String item);

	/**
	 * 등록.
	 * 동일 (promNo, item) 존재 시 중복 에러.
	 * 저장 후 단위 분해(decomposeAndStore) 자동 호출.
	 */
	void insertProvHtml(ProvHtmlVO vo) throws Exception;

	/** 수정 + 단위 분해 재실행 */
	void updateProvHtml(ProvHtmlVO vo) throws Exception;

	/** 삭제 — 트리거가 REL_VRSN/ATTACH cascade. PROV_VRSN 은 본 메서드에서 명시 정리 */
	void deleteProvHtml(Long provHtmlNo) throws Exception;
}
