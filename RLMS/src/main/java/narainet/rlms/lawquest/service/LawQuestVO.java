/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/lawquest/service/LawQuestVO.java
 *
 * 법령질의(법률자문 의뢰·회신) VO — TB_LAWQUEST.
 *   레거시 orangeidea.lawquest(모델 Countlaw, 테이블 COUNTLAW) 1:1 이관.
 *   2026-06-17 테이블 COUNTLAW → TB_LAWQUEST 로 개명(데이터 636행 보존).
 *
 *   외부 로펌 법률자문 의뢰 기록: 의뢰부서/자문기관/변호사/금액/의뢰·회신일 +
 *   질의내용/회신내용 + 첨부(TB_ATTACH, SREF_TABLE='TB_LAWQUEST', 최대 3파일).
 *   회신(respoCon)은 답변 권한자(TB_LAWQUEST_ADMIN)가 작성.
 */
package narainet.rlms.lawquest.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawQuestVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** PK (NO, COMTECOPSEQ.LAWQUEST_ID 채번) */
	private Long no;

	/** 작성자 ID (ID — ESNTL_ID, 세션 uniqId) */
	private String id;

	/** 작성자명 (NAME) */
	private String name;

	/** 작성연도 (YEAR — 예: "2020") */
	private String year;

	/** 자문유형 (TYPE — 일반/개발/비축/건설 …) */
	private String type;

	/** 의뢰부서 (SOSOK) */
	private String sosok;

	/** 자문기관/로펌 (GIGWAN) */
	private String gigwan;

	/** 변호사 (LAWER) */
	private String lawer;

	/** 자문 금액 (GUMAEK, 원) */
	private Long gumaek;

	/** 의뢰일자 (ILJA1 — YYYYMMDD) */
	private String ilja1;

	/** 회신일자 (ILJA2 — YYYYMMDD) */
	private String ilja2;

	/** 제목 (SUBJECT) */
	private String subject;

	/** 질의내용 (QUEST_CON, CLOB) */
	private String questCon;

	/** 회신내용 (RESPO_CON, CLOB) — 답변 권한자 작성 */
	private String respoCon;

	/** 작성일 (WRITEDAY — 조회 시 TO_CHAR 포맷 문자열) */
	private String writeday;

	/** 조회수 (READNUM) */
	private Long readnum;

	/** 예산 (BUGET) — 컬럼은 레거시 VARCHAR2 지만 화면 입력은 숫자(원)로 통일 (2026-07-29 고객 지적) */
	private String buget;

	/**
	 * 예산이 숫자만으로 이뤄졌는지 — 상세 화면이 금액 서식(천단위 콤마 + 원) 적용 여부를 판단.
	 * JSTL 에 숫자 판별식이 없어 EL 로 흉내내면 오판하므로 VO 가 판정한다.
	 * 레거시로 들어간 텍스트 값(예: "80000sdsad")은 false 라 원문 그대로 표시된다.
	 */
	public boolean isBugetNumeric() {
		return buget != null && buget.matches("\\d+");
	}

	/** 공개구분 (PUBLIC_YN — 레거시 '1'=공개/'2'=비공개) */
	private String publicYn;

	// ── 조회 부가 ──────────────────────────────────────────
	/** 첨부 건수 (TB_ATTACH SREF_TABLE='TB_LAWQUEST' COUNT) */
	private Integer attachCount;

	// ── 검색/페이징 ────────────────────────────────────────
	/** 검색 조건 (subject/gigwan/sosok) */
	private String searchCnd;
	/** 검색어 */
	private String searchKeyword;
	/** 자문유형 필터 */
	private String searchType;
	/** 작성연도 필터 */
	private String searchYear;
	/** front 공개열람 — true 면 PUBLIC_YN='1'(공개)만 조회 */
	private boolean publicOnly;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;
}
