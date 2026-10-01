/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/umt/service/LoginHistVO.java
 *
 * 내 로그인 내역(접속로그 COMTNLOGINLOG, CONECT_ID = 본인 ESNTL_ID) 조회용 VO.
 * 페이징 + 선택적 기간검색 + 표시행(일시/IP/구분/결과).
 */
package egovframework.com.uss.umt.service;

import java.io.Serializable;

public class LoginHistVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 로그ID */
	private String logId;
	/** 생성일시(YYYY-MM-DD HH24:MI:SS) */
	private String creatDt;
	/** 접속IP */
	private String conectIp;
	/** 구분(I:로그인, O:로그아웃) */
	private String conectMthd;
	/** 오류발생여부(N:정상) */
	private String errOccrrAt;

	/** 기간검색 시작일(YYYY-MM-DD) */
	private String searchBgnDe = "";
	/** 기간검색 종료일(YYYY-MM-DD) */
	private String searchEndDe = "";

	/** 현재페이지 */
	private int pageIndex = 1;
	/** 페이지당 레코드 수 */
	private int pageUnit = 10;
	/** 페이지 사이즈(네비 블록) */
	private int pageSize = 10;
	/** firstIndex */
	private int firstIndex = 0;
	/** lastIndex */
	private int lastIndex = 1;
	/** recordCountPerPage */
	private int recordCountPerPage = 10;

	public String getLogId() { return logId; }
	public void setLogId(String logId) { this.logId = logId; }

	public String getCreatDt() { return creatDt; }
	public void setCreatDt(String creatDt) { this.creatDt = creatDt; }

	public String getConectIp() { return conectIp; }
	public void setConectIp(String conectIp) { this.conectIp = conectIp; }

	public String getConectMthd() { return conectMthd; }
	public void setConectMthd(String conectMthd) { this.conectMthd = conectMthd; }

	public String getErrOccrrAt() { return errOccrrAt; }
	public void setErrOccrrAt(String errOccrrAt) { this.errOccrrAt = errOccrrAt; }

	public String getSearchBgnDe() { return searchBgnDe; }
	public void setSearchBgnDe(String searchBgnDe) { this.searchBgnDe = searchBgnDe; }

	public String getSearchEndDe() { return searchEndDe; }
	public void setSearchEndDe(String searchEndDe) { this.searchEndDe = searchEndDe; }

	public int getPageIndex() { return pageIndex; }
	public void setPageIndex(int pageIndex) { this.pageIndex = pageIndex; }

	public int getPageUnit() { return pageUnit; }
	public void setPageUnit(int pageUnit) { this.pageUnit = pageUnit; }

	public int getPageSize() { return pageSize; }
	public void setPageSize(int pageSize) { this.pageSize = pageSize; }

	public int getFirstIndex() { return firstIndex; }
	public void setFirstIndex(int firstIndex) { this.firstIndex = firstIndex; }

	public int getLastIndex() { return lastIndex; }
	public void setLastIndex(int lastIndex) { this.lastIndex = lastIndex; }

	public int getRecordCountPerPage() { return recordCountPerPage; }
	public void setRecordCountPerPage(int recordCountPerPage) { this.recordCountPerPage = recordCountPerPage; }
}
