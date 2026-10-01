/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/DiffLineVO.java
 *
 * 본문 비교 결과 한 줄(또는 한 단위) 표현 VO.
 * BodyDiffService 가 두 법령(promNo)의 TB_PROV_VRSN row 집합을
 * FULL OUTER JOIN ON SFULL_ITEM 한 결과를 이 VO List 로 반환.
 *
 * changeType:
 *   ADDED     — 오른쪽(현재) 에만 존재
 *   REMOVED   — 왼쪽(이전) 에만 존재
 *   MODIFIED  — 양쪽 모두 존재하나 본문이 다름
 *   UNCHANGED — 양쪽 모두 존재하고 본문이 같음
 */
package narainet.rlms.prom.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class DiffLineVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 단위 식별자 (SFULL_ITEM) — 비교 결과 정렬 기준 */
	private String fullItem;

	/** 왼쪽(이전) 본문 */
	private String leftText;

	/** 오른쪽(현재) 본문 */
	private String rightText;

	/** 변경 유형: ADDED / REMOVED / MODIFIED / UNCHANGED (본문 content 비교 기준) */
	private String changeType;

	/** 우측(현재) 회차의 개정유형(SGAEJUNG_TYPE) — 이동/제목개정/본문개정/신설 정밀 라벨. content diff 보강용 */
	private String gaejungType;

	/** 이동된 경우 대상 식별자(SMOVE_FULL_ITEM) */
	private String moveFullItem;

	/** 화면 표시용 조항 라벨 — 내부 식별자(SFULL_ITEM/"line-N") 원문 노출 금지(2026-07-16). JSP EL ${d.itemLabel} */
	public String getItemLabel() { return ProvItemLabel.of(fullItem); }

	/** 이동 대상 조항 라벨 — JSP EL ${d.moveItemLabel} */
	public String getMoveItemLabel() { return ProvItemLabel.of(moveFullItem); }
}
