/*
 * 물리적 저장 경로: /src/main/java/narainet/law/lawyer/service/LawLawyerVO.java
 */
package narainet.law.lawyer.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/** 변호사 명부 (LAW_LAWYER ← tbetia51) — §7.7 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawLawyerVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (채번 LAW_LAWYER_ID) */
	private Long lawyerId;
	/** 법무법인명(텍스트) */
	private String lawFirm;
	/** 변호사 성명 */
	private String lawyerNm;
	private String email;
	/** 전화(사무실) */
	private String tel;
	/** 휴대폰 */
	private String mobile;
	private String delYn;

	private String regUserId;
	private String regDt;
	private String updUserId;
	private String updDt;

	/** 만족도 집계 (선임 단위 평가의 변호사 합산 — LAW_LAWYER_SATIS) */
	private Double satisAvg;
	private Integer satisCnt;
	/** 선임 참조 건수 (소프트삭제 차단 판단·표시) */
	private Integer assignCnt;

	/** 검색 — 법무법인·변호사 통합 키워드 */
	private String searchKeyword;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
