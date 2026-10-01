/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/ProvTextHstVO.java
 *
 * 회차 본문 일괄편집 작업 이력(TB_PROV_TEXT_HST).
 * 레거시 의 "이전개정작업내용" 드롭다운 + 불러오기/삭제 의 데이터 모델.
 * 일괄저장(snapshotBulkBody) 직전의 본문 텍스트를 한 row 로 보존.
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
public class ProvTextHstVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (IPTHST_NO) */
	private Long provTextHstNo;

	/** 회차 (IPROM_NO) */
	private Long promNo;

	/** 저장 사용자 ID (SUSER_ID) */
	private String userId;

	/** 본문 텍스트 (STEXT, CLOB) */
	private String text;

	/** 등록일 (SINS_DT) */
	private String insDt;
}
