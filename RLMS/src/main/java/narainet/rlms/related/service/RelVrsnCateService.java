/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/related/service/RelVrsnCateService.java
 *
 * 관련자료 카테고리 서비스 — 우측 패널 카테고리 모달의 진입점.
 */
package narainet.rlms.related.service;

import java.util.List;

public interface RelVrsnCateService {

	/**
	 * 회차+법령 단위 활성 카테고리 목록.
	 *  today = 오늘 YYYYMMDD (호출자가 전달 — 테스트 가능성)
	 */
	List<RelVrsnCateVO> getList(Long promNo, Long lawId, String today);

	/** 단건 조회 */
	RelVrsnCateVO getByNo(Long cateNo);

	/**
	 * 회차 등록 시 디폴트 시드 3종 (본문/붙임/양식) 자동 생성.
	 *  - SORGNDOWN_YN: 본문=Y, 붙임=N, 양식=Y (레거시 운영 분석 패턴)
	 *  - 같은 (promNo, lawId) 쌍에 이미 카테고리가 있으면 시드 생략 (멱등성).
	 *  Returns the number of categories inserted (0 또는 3).
	 */
	int seedDefault(Long promNo, Long lawId) throws Exception;

	/** 사용자 추가 카테고리 등록 */
	Long insert(Long promNo, Long lawId, String title, Integer seq, String orgnDownYn) throws Exception;

	/** 이름 변경 */
	void rename(Long cateNo, String title);

	/** 숨김 처리 ("0"=활성, "YYYYMMDD"=종료일) */
	void hide(Long cateNo, String hideDt);

	/** 원본 다운로드 허용 토글 */
	void toggleOrgnDown(Long cateNo, String orgnDownYn);

	/** 순서 변경 */
	void moveSeq(Long cateNo, Integer seq);

	/** 단건 삭제 (카테고리에 매달린 자료가 있으면 호출자가 사전 검증) */
	void delete(Long cateNo);
}
