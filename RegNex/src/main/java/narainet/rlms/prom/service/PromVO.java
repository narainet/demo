/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/PromVO.java
 *
 * 법령(TB_PROM) 관리용 VO. 41 컬럼 매핑 + 조회 부가 + 검색/페이징.
 *
 * 트리거 효과 (DB 레벨, 자동):
 *   - TRG_DEL_PROM (BEFORE DELETE): TB_PROV_VRSN, TB_PROV_HTML, TB_DOCU,
 *                                    TB_SRC_STORED, TB_REL_VRSN cascade 삭제
 *   - TRG_UPD_PROM (BEFORE UPDATE): TB_FT_CACHE_QUEUE 에 캐시 무효화 row INSERT
 */
package narainet.rlms.prom.service;

import java.io.Serializable;
import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * 법령 관리 VO (TB_PROM)
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *
 *   수정일         수정자        수정내용
 *  ----------    ---------    ----------------------------
 *   2026.05.11   RLMS 전환팀   최초 생성 (레거시 Promulgation → RLMS 이관)
 * </pre>
 */
@Getter
@Setter
@ToString
@NoArgsConstructor
public class PromVO implements Serializable {

	private static final long serialVersionUID = 1L;

	// ── 식별 / 분류 (FK) ─────────────────────────────────────────
	/** 법령 번호 (IPROM_NO, PK, COMTECOPSEQ.PROM_ID 채번) */
	private Long promNo;

	/** 법령 구분 (SGUBUN_ID, PromulgationType enum 값) */
	private String gubunId;

	/** 분류 번호 (ICATE_NO, TB_CATE FK) */
	private Long cateNo;

	/** 개정 번호 (IGAEJUNG_NO, TB_GAEJUNG FK) */
	private Long gaejungNo;

	/** 논리 법령 ID (ILAW_ID) — 같은 법령의 개정본을 묶는 키 */
	private Long lawId;

	/** 개정 회차 (ILAW_NO) */
	private Long lawNo;

	/** 담당부서 (IBUSEO_NO, TB_BUSEO FK) */
	private Long buseoNo;

	/** 개정구분 코드 (SGAEJUNG_CODE) — 실DB 파생값 'GJ'+IGAEJUNG_NO 18자리 zero-pad. 서비스가 자동 조립 */
	private String gaejungCode;

	/** 주관부서 조직ID (SBUSEO_ORGNZT_ID, CHAR(20)) — 실DB 파생값 'ORG_'+IBUSEO_NO 16자리 zero-pad. 서비스가 자동 조립 */
	private String buseoOrgnztId;

	/** 시스템 ID (SSYS_ID, 멀티시스템 키) */
	private String sysId;

	// ── 제목 / 일자 ───────────────────────────────────────────────
	/** 법령 제목 (STITLE) */
	private String title;

	/** 부제목 (SSUB_TITLE) */
	private String subTitle;

	/** 법령 번호 표기 (SNUM, 예: "법률 제19999호") */
	private String number;

	/** 당사자 (SPARTY) */
	private String party;

	/** 공포일자 (SPROM_DT, "YYYY-MM-DD") */
	private String promDate;

	/** 시행일자 (SSTART_DT) */
	private String startDate;

	/** 폐지일자 (SNULL_DT) */
	private String nullDate;

	/** 폐지일 변경 승인 대기값 (SNULL_DT_PEND) — NULL=대기 없음, '--'=폐지일 해제 대기.
	 *  현행 회차의 폐지일 변경은 승인요청을 거쳐야 반영 (2026-07-20 사용자 결정) */
	private String nullDatePend;

	/**
	 * 시행예정 여부 — 시행일(SSTART_DT)이 오늘보다 미래(공포~시행 사이).
	 * 백킹 필드 없는 파생 getter(JSP EL ${row.upcoming}) — MenuVO.isFolder() 패턴.
	 * 날짜는 'YYYY-MM-DD' VARCHAR2 라 사전식 비교가 연대순과 일치(미지정 NULL/'--'는 시행예정 아님).
	 */
	public boolean isUpcoming() {
		if (startDate == null) return false;
		String s = startDate.trim();
		if (s.isEmpty() || "--".equals(s)) return false;
		return s.compareTo(java.time.LocalDate.now().toString()) > 0;
	}

	/** 등록일시 (SINS_DT) */
	private String insDt;

	// ── 본문 CLOB 5종 ─────────────────────────────────────────────
	/** 사유 (SREASON, CLOB) */
	private String reason;

	/** 개정내용 (SGAEJUNG, CLOB) */
	private String gaejung;

	/** 부칙 (SBYLAW, CLOB) — java-diff-utils 로 비교 */
	private String bylaw;

	/** 전문 (SPREAMBLE, CLOB) */
	private String preamble;

	/** 검색 텍스트 (SSEARCH_TEXT, CLOB, 분류명+제목 등 조합) */
	private String searchText;

	// ── URL / 본문 파일 메타 ──────────────────────────────────────
	private String url;
	/** 본문 형식 플래그 (SPROV_FG) */
	private String provFlag;
	/** 본문 스타일 코드 (SPROV_STYLE_CD) */
	private String provStyleCd;
	/** 본문 파일 번호 (SPROV_FILE_NO) */
	private String provFileNo;

	// ── 플래그 ────────────────────────────────────────────────────
	private String dispYn = "Y";
	/** 현재 유효 법령 여부 (SEXISTING_YN) — 같은 lawId 중 단 1건만 'Y' */
	private String existingYn = "N";
	private String extDispYn = "N";
	/** 중복 항목 여부 (SDPL_ITEM_YN) */
	private String dplItemYn = "N";
	/** 관련 파일 뷰 표시 여부 (SREL_FILE_VIEW_YN) */
	private String relFileViewYn = "N";
	/** 만족도 조사 사용 여부 (SSTSFDG_YN) — 연혁 등록/수정 옵션, 사용(Y) 회차의 전문뷰어에 위젯 노출 */
	private String stsfdgYn = "N";

	// ── 상태 / 정렬 ───────────────────────────────────────────────
	private String status;
	/** 분류 내 정렬순서 (ISEQ) */
	private Integer seq;
	/** 정렬 우선순위 (SORDERIDX, NUMBER(3,0) DEFAULT 50) */
	private Integer orderIdx = 50;

	// (2026-07-30 제거) 저장 파일 메타 7종 — SSTOR_FILE_YN/NM/DT/PATH/DOC_NM/HWP_NM/PDF_NM.
	//   레거시 은 회차별 원본 문서(DOC/HWP/PDF)를 미리 만들어 보관·다운로드시켰으나,
	//   RLMS 는 exportProm.do 실시간 생성으로 대체해 한 번도 채운 적이 없다(신규 DB 전 행 NULL).
	//   컬럼도 함께 DROP — 문서 내보내기는 FullTextController.exportProm 참조.

	// ── 조회 부가 (DB 매핑 없음, 조인 결과) ────────────────────────
	/** 분류명 (TB_CATE 조인) */
	private String cateNm;

	/** 분류 전체 경로 (Oracle 함수 GET_FULL_NAME_BY_CATE_NO 결과) */
	private String cateFullNm;

	/** 담당부서명 (TB_BUSEO 조인) */
	private String buseoNm;

	/** 개정구분 라벨 (TB_GAEJUNG.SNAME — '제정'/'개정'/'전부개정' …) — 회차 노드 라벨용 */
	private String gaejungNm;

	/** 최신 워크상태 (TB_PROM_WRK 최신행 SSTATUS) — selectPromListByLawId 전용, 연혁목차 draft 판정용 */
	private String workStatus;

	// ── 검색 / 페이징 ─────────────────────────────────────────────
	/** 검색 조건 (0=제목, 1=본문, 2=분류, 3=부서) */
	private String searchCnd;

	/** 검색 키워드 */
	private String searchKeyword;

	// ── Front 검색 5종 (레거시 fulltext.html 호환) ────────────────────
	/** 분류구분 필터 — 선택한 SGUBUN_ID 코드 목록('FT_GUBUN_N' 그대로, 라벨 정본 = ccm 'SGUBUN').
	 *  옛 gubun1~5='TRUE' 방식은 폐기(2026-07-10 동적화) — 신설 구분(FT_GUBUN_6+)도 그대로 통과.
	 *  비어 있으면 필터 미적용 = 전체. */
	private List<String> gubunIds;

	/** 최근 N일 (latestList 용 — 기본 30) */
	private Integer searchDays = 30;

	/** 폐지 여부 필터 (Y=폐지만, N=현행만, 빈값=전체) */
	private String nullifyYn;

	/** 검색 시작일 (YYYY-MM-DD) */
	private String searchFromDt;

	/** 검색 종료일 (YYYY-MM-DD) */
	private String searchToDt;

	// ── 상세검색(advanced search, 레거시 상세검색하기 이식) 전용 ──────────────
	/** 검색단위: 제목(STITLE) — 'TRUE'/null */
	private String stTitle;
	/** 검색단위: 본문내용(TB_SRC_STORED SFLAG='조문') — 'TRUE'/null */
	private String stProvision;
	/** 검색단위: 별표·별지서식내용(TB_SRC_STORED SFLAG='서식') — 'TRUE'/null */
	private String stDocument;
	/** 검색단위: 폐지사규 포함(현행 SEXISTING_YN='Y' 외에 폐지 IGAEJUNG_NO=3 도) — 'TRUE'/null */
	private String stPaji;
	/** 검색단위: 계약당사자(SPARTY) — 'TRUE'/null */
	private String stParty;
	/** 자음검색 인덱스 0~13(ㄱ~ㅎ), 미사용 -1. SUBSTR(STITLE,1,1) 앵커범위 */
	private Integer hangulPrefix;
	/** 영문검색 인덱스 0~25(A~Z), 미사용 -1 */
	private Integer englishPrefix;
	/** 검색일자 타입: ''(전체) / 'PROM'(개정일자 SPROM_DT) / 'START'(시행일자 SSTART_DT) */
	private String dateType;

	/** 자음/영문 첫글자 검색 — 컨트롤러가 인덱스→경계문자 계산해 채움. type 'HAN'(자음 범위) / 'ENG'(영문 대소문자) */
	private String prefixType;
	private String prefixFrom;
	private String prefixTo;

	/** 상세검색 모드 — 'Y' 이면 호스트 목록(연혁검색 등)이 상세검색 쿼리로 결과 렌더 */
	private String detailMode;

	// ── 분류별 열람제한 게이트 (TB_CATE_READER) — PromReadGuard.applyReadGate 가 채움 ──
	/** 열람제한 SQL 게이트 적용 여부 — front 목록에서 면제역할(ADMIN/EDITOR/APPROVER) 아닐 때만 true */
	private boolean applyReadGate;
	/** 현재 사용자 ESNTL_ID (READER_TY='USER' 매칭) */
	private String readerEsntlId;
	/** 현재 사용자 ORGNZT_ID (READER_TY='DEPT' 매칭) */
	private String readerOrgnztId;

	private int pageIndex = 1;
	private int pageUnit = 10;
	private int pageSize = 10;
	private int firstIndex = 1;
	private int lastIndex = 1;
	private int recordCountPerPage = 10;

	// ── 로그인 사용자 추적 ────────────────────────────────────────
	private String lastUpdusrId;
}
