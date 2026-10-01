package egovframework.com.sym.log.wlg.service;

import java.io.Serializable;

/**
 * @Class Name : WebLog.java
 * @Description : 웹 로그 관리를 위한 VO 클래스
 * @Modification Information
 *
 *    수정일         수정자         수정내용
 *    -------        -------     -------------------
 *    2009. 3. 11.   이삼섭         최초생성
 *    2011. 7. 01.   이기하         패키지 분리(sym.log -> sym.log.wlg)
 *    2011.09.14     서준식       화면에 검색일자를 표시하기위한 멤버변수 추가.
 *    2026.07.20     RLMS        접속통계 확장 — 기기구분/브라우저/세션ID 추가.
 * @author 공통 서비스 개발팀 이삼섭
 * @since 2009. 3. 11.
 * @version
 * @see
 *
 */
public class WebLog implements Serializable {

	private static final long serialVersionUID = -7768865822788140496L;

	/**
	 * 요청아이디
	 */
	private String requstId = "";

	/**
	 * 발생일자
	 */
	private String occrrncDe = "";

	/**
	 * URL
	 */
	private String url = "";

	/**
	 * 요청자아이디
	 */
	private String rqesterId = "";

	/**
	 * 요청자 이름
	 */
	private String rqsterNm = "";

	/**
	 * 요청아이피
	 */
	private String rqesterIp = "";

	/**
	 * 접속 기기 구분 (PC/MOBILE/TABLET/BOT/ETC — User-Agent 파싱)
	 */
	private String dviceSe = "";

	/**
	 * 브라우저명 (Chrome/Edge/Whale/… — User-Agent 파싱)
	 */
	private String browserNm = "";

	/**
	 * 세션 ID (방문 단위 집계용, 비로그인 포함)
	 */
	private String sesnId = "";

	/* ── 접속 세션 현황(SESN_ID 로 묶은 접속 1회 = 1행) 결과 필드 ──────────
	   웹로그는 요청마다 쌓이므로 마지막 요청 시각이 곧 떠난 시각이다. 접속로그(COMTNLOGINLOG)는
	   로그아웃 버튼을 눌러야 종료가 남지만 실제로는 대부분 창을 닫고 나가므로, 체류 파악은 이쪽이 정확하다. */

	/** 접속 시작 — 그 세션의 첫 요청 시각 */
	private String bgnDt = "";

	/** 마지막 활동 — 그 세션의 마지막 요청 시각 */
	private String endDt = "";

	/** 체류 시간(분) */
	private int durMin = 0;

	/** 요청 수 */
	private int reqCnt = 0;

	/** 조회 화면 수(중복 URL 제외) */
	private int pageCnt = 0;

	/** 마지막으로 머문 화면 URL */
	private String lastUrl = "";

	/** 검색조건 — 기기 구분(PC/MOBILE/TABLET/BOT/ETC) */
	private String searchDviceSe = "";

	/** 검색조건 — 요청자(이름 또는 ID) */
	private String searchRqster = "";

	/**
	 * 검색시작일
	 */
	private String searchBgnDe = "";

	/**
	 * 검색조건
	 */
	private String searchCnd = "";

	/**
	 * 검색종료일
	 */
	private String searchEndDe = "";

	/**
	 * 검색단어
	 */
	private String searchWrd = "";

	/**
	 * 정렬순서(DESC,ASC)
	 */
	private String sortOrdr = "";

	/** 검색사용여부 */
    private String searchUseYn = "";

    /** 현재페이지 */
    private int pageIndex = 1;

    /** 페이지개수 */
    private int pageUnit = 10;

    /** 페이지사이즈 */
    private int pageSize = 10;

    /** firstIndex */
    private int firstIndex = 1;

    /** lastIndex */
    private int lastIndex = 1;

    /** recordCountPerPage */
    private int recordCountPerPage = 10;

    /** rowNo  */
	private int rowNo = 0;

	/**
	 * 검색시작일_화면용
	 */
	private String searchBgnDeView = "";//2011.09.14

	/**
	 * 검색종료일_화면용
	 */
	private String searchEndDeView = "";//2011.09.14

	public String getSearchEndDeView() {
		return searchEndDeView;
	}
	public void setSearchEndDeView(String searchEndDeView) {
		this.searchEndDeView = searchEndDeView;
	}
	public String getSearchBgnDeView() {
		return searchBgnDeView;
	}
	public void setSearchBgnDeView(String searchBgnDeView) {
		this.searchBgnDeView = searchBgnDeView;
	}

	public String getRequstId() {
		return requstId;
	}

	public void setRequstId(String requstId) {
		this.requstId = requstId;
	}

	public String getOccrrncDe() {
		return occrrncDe;
	}

	public void setOccrrncDe(String occrrncDe) {
		this.occrrncDe = occrrncDe;
	}

	public String getUrl() {
		return url;
	}

	public void setUrl(String url) {
		this.url = url;
	}

	public String getRqesterId() {
		return rqesterId;
	}

	public void setRqesterId(String rqesterId) {
		this.rqesterId = rqesterId;
	}

	public String getRqsterNm() {
		return rqsterNm;
	}

	public void setRqsterNm(String rqsterNm) {
		this.rqsterNm = rqsterNm;
	}

	public String getRqesterIp() {
		return rqesterIp;
	}

	public void setRqesterIp(String rqesterIp) {
		this.rqesterIp = rqesterIp;
	}

	public String getDviceSe() {
		return dviceSe;
	}

	public void setDviceSe(String dviceSe) {
		this.dviceSe = dviceSe;
	}

	public String getBrowserNm() {
		return browserNm;
	}

	public void setBrowserNm(String browserNm) {
		this.browserNm = browserNm;
	}

	public String getSesnId() {
		return sesnId;
	}

	public void setSesnId(String sesnId) {
		this.sesnId = sesnId;
	}

	public String getSearchBgnDe() {
		return searchBgnDe;
	}

	public void setSearchBgnDe(String searchBgnDe) {
		this.searchBgnDe = searchBgnDe;
	}

	public String getSearchCnd() {
		return searchCnd;
	}

	public void setSearchCnd(String searchCnd) {
		this.searchCnd = searchCnd;
	}

	public String getSearchEndDe() {
		return searchEndDe;
	}

	public void setSearchEndDe(String searchEndDe) {
		this.searchEndDe = searchEndDe;
	}

	public String getSearchWrd() {
		return searchWrd;
	}

	public void setSearchWrd(String searchWrd) {
		this.searchWrd = searchWrd;
	}

	public String getSortOrdr() {
		return sortOrdr;
	}

	public void setSortOrdr(String sortOrdr) {
		this.sortOrdr = sortOrdr;
	}

	public String getSearchUseYn() {
		return searchUseYn;
	}

	public void setSearchUseYn(String searchUseYn) {
		this.searchUseYn = searchUseYn;
	}

	public int getPageIndex() {
		return pageIndex;
	}

	public void setPageIndex(int pageIndex) {
		this.pageIndex = pageIndex;
	}

	public int getPageUnit() {
		return pageUnit;
	}

	public void setPageUnit(int pageUnit) {
		this.pageUnit = pageUnit;
	}

	public int getPageSize() {
		return pageSize;
	}

	public void setPageSize(int pageSize) {
		this.pageSize = pageSize;
	}

	public int getFirstIndex() {
		return firstIndex;
	}

	public void setFirstIndex(int firstIndex) {
		this.firstIndex = firstIndex;
	}

	public int getLastIndex() {
		return lastIndex;
	}

	public void setLastIndex(int lastIndex) {
		this.lastIndex = lastIndex;
	}

	public int getRecordCountPerPage() {
		return recordCountPerPage;
	}

	public void setRecordCountPerPage(int recordCountPerPage) {
		this.recordCountPerPage = recordCountPerPage;
	}

	public int getRowNo() {
		return rowNo;
	}

	public void setRowNo(int rowNo) {
		this.rowNo = rowNo;
	}

	/* ── 접속 세션 현황 ─────────────────────────────────────── */

	public String getBgnDt() {
		return bgnDt;
	}

	public void setBgnDt(String bgnDt) {
		this.bgnDt = bgnDt;
	}

	public String getEndDt() {
		return endDt;
	}

	public void setEndDt(String endDt) {
		this.endDt = endDt;
	}

	public int getDurMin() {
		return durMin;
	}

	public void setDurMin(int durMin) {
		this.durMin = durMin;
	}

	public int getReqCnt() {
		return reqCnt;
	}

	public void setReqCnt(int reqCnt) {
		this.reqCnt = reqCnt;
	}

	public int getPageCnt() {
		return pageCnt;
	}

	public void setPageCnt(int pageCnt) {
		this.pageCnt = pageCnt;
	}

	public String getLastUrl() {
		return lastUrl;
	}

	public void setLastUrl(String lastUrl) {
		this.lastUrl = lastUrl;
	}

	public String getSearchDviceSe() {
		return searchDviceSe;
	}

	public void setSearchDviceSe(String searchDviceSe) {
		this.searchDviceSe = searchDviceSe;
	}

	public String getSearchRqster() {
		return searchRqster;
	}

	public void setSearchRqster(String searchRqster) {
		this.searchRqster = searchRqster;
	}

}
