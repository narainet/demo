/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/brd/service/Brand.java
 *
 * 브랜드설정(로고·파비콘) 모델 — COM_BRAND 단일 행(BRAND_ID='S').
 * 고객사별 리브랜딩 지점이라 특정 제품(RLMS)에 묶지 않고 표준 패키지(egovframework.com)에 둔다
 * — 다른 프로젝트에 그대로 이식할 수 있어야 한다 (2026-07-31).
 */
package egovframework.com.uss.ion.brd.service;

import java.io.Serializable;

@SuppressWarnings("serial")
public class Brand implements Serializable {

	/** 단일 행 고정 키 */
	public static final String ID = "S";

	/** 로고유형 — 텍스트로 표기 */
	public static final String TY_TEXT = "TEXT";

	/** 로고유형 — 업로드 이미지로 표기 */
	public static final String TY_IMAGE = "IMAGE";

	/** 브랜드ID (항상 'S') */
	private String brandId = ID;

	/** 로고유형코드 (TEXT | IMAGE) */
	private String logoTyCode = TY_TEXT;

	/** 로고텍스트 — 헤더/로그인 화면에 그대로 노출되는 한 줄 */
	private String logoText = "";

	/** 로고 이미지 첨부파일ID (COMTNFILE.ATCH_FILE_ID) */
	private String logoAtchFileId = "";

	/** 파비콘 이미지 첨부파일ID */
	private String faviconAtchFileId = "";

	/** 연락처 — 주소 (포탈 공개 메인 '오시는 길' 표시. 비우면 해당 항목 미표시, 2026-08-04) */
	private String cntcAdres = "";

	/** 연락처 — 대표전화 */
	private String cntcTelno = "";

	/** 연락처 — 팩스 */
	private String cntcFxnum = "";

	/** 연락처 — 이메일 */
	private String cntcEmailAdres = "";

	/** 최종수정자ID */
	private String lastUpdusrId = "";

	/** 최종수정시점 — 이미지 URL 캐시버스터로도 쓴다 */
	private String lastUpdtPnttm = "";

	public String getBrandId() {
		return brandId;
	}

	public void setBrandId(String brandId) {
		this.brandId = brandId;
	}

	public String getLogoTyCode() {
		return logoTyCode;
	}

	public void setLogoTyCode(String logoTyCode) {
		this.logoTyCode = logoTyCode;
	}

	public String getLogoText() {
		return logoText;
	}

	public void setLogoText(String logoText) {
		this.logoText = logoText;
	}

	public String getLogoAtchFileId() {
		return logoAtchFileId;
	}

	public void setLogoAtchFileId(String logoAtchFileId) {
		this.logoAtchFileId = logoAtchFileId;
	}

	public String getFaviconAtchFileId() {
		return faviconAtchFileId;
	}

	public void setFaviconAtchFileId(String faviconAtchFileId) {
		this.faviconAtchFileId = faviconAtchFileId;
	}

	public String getCntcAdres() {
		return cntcAdres;
	}

	public void setCntcAdres(String cntcAdres) {
		this.cntcAdres = cntcAdres;
	}

	public String getCntcTelno() {
		return cntcTelno;
	}

	public void setCntcTelno(String cntcTelno) {
		this.cntcTelno = cntcTelno;
	}

	public String getCntcFxnum() {
		return cntcFxnum;
	}

	public void setCntcFxnum(String cntcFxnum) {
		this.cntcFxnum = cntcFxnum;
	}

	public String getCntcEmailAdres() {
		return cntcEmailAdres;
	}

	public void setCntcEmailAdres(String cntcEmailAdres) {
		this.cntcEmailAdres = cntcEmailAdres;
	}

	public String getLastUpdusrId() {
		return lastUpdusrId;
	}

	public void setLastUpdusrId(String lastUpdusrId) {
		this.lastUpdusrId = lastUpdusrId;
	}

	public String getLastUpdtPnttm() {
		return lastUpdtPnttm;
	}

	public void setLastUpdtPnttm(String lastUpdtPnttm) {
		this.lastUpdtPnttm = lastUpdtPnttm;
	}

	/** 로고를 이미지로 표기하는가 — 이미지ID 가 실제로 있어야 참(설정만 IMAGE 이고 파일이 없으면 텍스트로 폴백) */
	public boolean isImageLogo() {
		return TY_IMAGE.equals(logoTyCode) && logoAtchFileId != null && !logoAtchFileId.trim().isEmpty();
	}

	/** 파비콘이 업로드되어 있는가 */
	public boolean hasFavicon() {
		return faviconAtchFileId != null && !faviconAtchFileId.trim().isEmpty();
	}
}
