/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ValidationService.java
 *
 * 법령 본문 무결성 검증 Service.
 *
 *   - validateHistory     : 특정 lawId 의 모든 개정본 검증
 *   - validateExistingAll : 모든 SEXISTING_YN='Y' 법령 검증 (운영 데이터 전체 헬스 체크)
 *
 * 검증 규칙 (레거시 ValidationContents 의 핵심 규칙을 RLMS 가능 범위로 추림):
 *   1. 조항 식별자(SFULL_ITEM) 중복     → ERROR  (CAT_DUPLICATE_ITEM)
 *   2. 본문(SCONTENTS) 비어 있음        → WARN   (CAT_EMPTY_CONTENT)
 *   3. 시행일/공포일/폐지일 모순        → ERROR  (CAT_DATE_INVALID)
 *      - 공포일 > 시행일
 *      - 시행일 > 폐지일
 *   4. TB_PROV_VRSN row 0건             → WARN   (CAT_PROV_MISSING)
 *   5. 조항 트리 일관성                 → INFO   (CAT_TREE_INCONSISTENT, 2026-07-16 구현)
 *      - SFULL_ITEM 형식 이상 / 고아 하위단위 / 고아 조(그룹 행 없음) / 빈 그룹
 *      - 누적(상속 포함) 뷰 기준 — tombstone 제외, 회차당 30건 상한
 */
package narainet.rlms.prom.service;

import java.util.List;

public interface ValidationService {

	/**
	 * 특정 lawId 의 모든 개정본을 검증.
	 * @param lawId   같은 lawId 의 모든 promNo 가 검증 대상
	 * @return 모든 결과 (이슈 없음이면 빈 List)
	 */
	List<ValidationIssueVO> validateHistory(Long lawId);

	/**
	 * 운영 중인 모든 법령(SEXISTING_YN='Y') 일괄 검증.
	 * @return 모든 결과
	 */
	List<ValidationIssueVO> validateExistingAll();

	/**
	 * 단일 법령 검증.
	 * @param promNo 대상 법령
	 * @return 결과 리스트
	 */
	List<ValidationIssueVO> validateProm(Long promNo);
}
