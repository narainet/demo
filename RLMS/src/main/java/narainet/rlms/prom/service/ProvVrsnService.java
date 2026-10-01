/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ProvVrsnService.java
 */
package narainet.rlms.prom.service;

import java.util.List;

/**
 * 조항 본문 단위 row(TB_PROV_VRSN) Service.
 *
 * - decomposeAndStore : HTML CLOB → 단위 row 분해 + 일괄 INSERT
 * - listByPromNo      : 한 법령의 단위 row 목록
 * - diffByPromNo      : 두 법령 비교 (SQL FULL OUTER JOIN)
 */
public interface ProvVrsnService {

	/**
	 * 본문 HTML 을 단위(조/항/호/문장/줄)로 분해해 TB_PROV_VRSN row 일괄 저장.
	 * 기존 row 가 있으면 먼저 삭제(deleteProvVrsnByPromNo)하고 재생성.
	 * 분해 알고리즘은 BodyParser 가 담당.
	 */
	void decomposeAndStore(Long promNo, String contents,
			String startDate, String sysId, String gaejungType) throws Exception;

	/** 한 법령의 단위 row 목록 */
	List<ProvVrsnVO> selectListByPromNo(Long promNo);

	/**
	 * 한 회차의 **누적(상속 포함)** 조문 목록 — 같은 lawId 회차들(ILAW_NO ≤ lawNo) 중 SFULL_ITEM 별 최신,
	 * SDISP_YN='N' tombstone 제외. 사용자 전문 뷰어/렌더링용.
	 */
	List<ProvVrsnVO> selectCumulative(Long lawId, Long lawNo);

	/** 두 법령의 단위 비교 결과 (변경 유형 라벨링) */
	List<DiffLineVO> diffByPromNo(Long leftPromNo, Long rightPromNo);

	/**
	 * "버전관리용조문편집" 일괄 편집기 저장.
	 * 평문 본문(text) 을 레거시 식 한국법령 파서(ProvTextParser)로 분해해 60자 SFULL_ITEM 행으로 만들고,
	 * 이 회차(promNo)의 기존 TB_PROV_VRSN 을 통째로 교체("스냅샷" 시멘틱 — 레거시 동일).
	 *
	 * 삭제 처리(레거시 재현): 저장 직전 누적(상속 포함) 본문과 비교해, 이전 회차에서 상속됐으나
	 * 새 본문에 없는 조문은 SDISP_YN='N' tombstone(개정유형 NULLIFY / 이동 시 NULLIFY_MOVE_*) 으로
	 * 이 회차에 INSERT 한다. 누적 조회(MAX(ILAW_NO) + SDISP_YN='Y' 필터)가 이를 숨겨 조문이 사라진다.
	 * (lawId/lawNo 가 null 이면 비교 기준선이 없어 tombstone 생성을 건너뜀)
	 *
	 * 반환: 표시(저장)된 row 수(tombstone 제외).
	 */
	int snapshotBulkBody(Long promNo, Long lawId, Long lawNo, String text,
			String startDate, String sysId, String gaejungType) throws Exception;

	/**
	 * 단건 "조문별 수정" 저장 — 한 조(joFullItem)의 본문 블록(조 + 항/호/목 전체)을 재분해해
	 * 이 회차(promNo)가 소유한 그 조의 subtree 행만 교체한다.
	 *
	 * 일괄편집기(snapshotBulkBody)가 회차 전체를 다루는 데 반해, 이 메서드는 한 조의 하위 트리
	 * (SFULL_ITEM 앞 30자 = 조 prefix 가 같은 행 = 조 + 그 조의 항/호/목)만 범위로 한다.
	 * 블록만 단독 파싱하면 상위(편/장/절/관/목1) 청크가 비어 트리 위치가 어긋나므로,
	 * 원래 조 SFULL_ITEM 의 앞 25자(상위 prefix)를 재분해 결과 각 행에 이식해 위치를 보존한다.
	 *
	 * 개정유형은 일괄편집기와 동일하게 직전 연혁(lawId/lawNo 기준 selectPrevLawNo)의 이 조
	 * subtree 를 기준선으로 분류하며, 블록에서 빠진 항/호/목은 tombstone 으로 처리한다.
	 * 블록 전체가 직전 연혁과 동일(전량 EQUAL, tombstone 없음)이면 미개정 재처리로 보고
	 * 이 회차 소유 subtree 행을 삭제만 하고 재삽입하지 않는다(이전 연혁 행 승계 복원) — 반환 -1.
	 *
	 * @param promNo      저장 대상 회차 PK (이 회차가 소유한 행만 교체)
	 * @param lawId       법령 ID (개정유형 분류 기준선 — null 이면 분류 없이 전량 NEW)
	 * @param lawNo       저장 대상 회차의 연혁번호 (직전 연혁 산출용)
	 * @param joFullItem  편집 대상 조의 60자 SFULL_ITEM
	 * @param blockText   조 라인 + 항/호/목 라인을 개행으로 이어붙인 평문
	 * @param startDate   시행일(조 행에 반영)
	 * @param sysId       시스템 ID
	 * @param reason      개정사유(조 행에 반영)
	 * @return 저장된 row 수(tombstone 제외). -1 = 직전 연혁과 동일하여 이 회차 데이터 제거(승계 복원)
	 */
	int replaceJoSubtree(Long promNo, Long lawId, Long lawNo, String joFullItem, String blockText,
			String startDate, String sysId, String reason) throws Exception;
}
