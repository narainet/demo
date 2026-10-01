package egovframework.com.sym.log.wlg.service;

import java.io.Serializable;

/**
 * @Class Name : WebLogStats.java
 * @Description : 접속통계(웹로그 집계) 조회 조건 + 집계 결과 VO
 *
 *   원천 = COMTNWEBLOG(표준 웹로그). 특정 업무에 매이지 않는 공통 기능이라
 *   표준 웹로그 모듈(sym.log.wlg)에 둔다 — 접속 세션 현황(2026-07-29 이관)과 같은 자리.
 *   조회 조건(기간·차원)과 집계 결과(구간 라벨·접속수·접속자수)를 한 VO 로 공용한다.
 *
 * @Modification Information
 *
 *    수정일         수정자         수정내용
 *    -------        -------     -------------------
 *    2026.08.06     RLMS        최초생성 — narainet.rlms.stats(제품 코드)에서 표준으로 이관
 *
 * @since 2026. 8. 6.
 */
public class WebLogStats implements Serializable {

	private static final long serialVersionUID = 1L;

	/**
	 * 조회 시작일 (YYYY-MM-DD)
	 */
	private String fromDt;

	/**
	 * 조회 종료일 (YYYY-MM-DD)
	 */
	private String toDt;

	/**
	 * 집계 차원 — HOUR(시간대)/DAY(일)/WEEK7(최근 7일)/MONTH(월)/YEAR(연)/DOW(요일)/MENU(메뉴)/DEVICE(기기)/BROWSER(브라우저)
	 */
	private String dimension;

	/**
	 * 구간 라벨 (차원별 집계 키 — '2026-08-06', '09', '월', '대시보드' 등)
	 */
	private String label;

	/**
	 * 접속수 (페이지 요청 건수)
	 */
	private Long cnt;

	/**
	 * 접속자수 (구간 내 DISTINCT 사용자ID, 비로그인은 IP 로 근사)
	 */
	private Long ucnt;

	public String getFromDt() {
		return fromDt;
	}

	public void setFromDt(String fromDt) {
		this.fromDt = fromDt;
	}

	public String getToDt() {
		return toDt;
	}

	public void setToDt(String toDt) {
		this.toDt = toDt;
	}

	public String getDimension() {
		return dimension;
	}

	public void setDimension(String dimension) {
		this.dimension = dimension;
	}

	public String getLabel() {
		return label;
	}

	public void setLabel(String label) {
		this.label = label;
	}

	public Long getCnt() {
		return cnt;
	}

	public void setCnt(Long cnt) {
		this.cnt = cnt;
	}

	public Long getUcnt() {
		return ucnt;
	}

	public void setUcnt(Long ucnt) {
		this.ucnt = ucnt;
	}
}
