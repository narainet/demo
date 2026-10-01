package egovframework.com.uss.umt.service;

import egovframework.com.cmm.ComDefaultVO;

public class DeptManageVO extends ComDefaultVO {

	private static final long serialVersionUID = 1L;
	private String orgnztId;
	private String orgnztNm;
	private String orgnztDc;
	/** 상위부서 ID (자기참조, null=최상위: 본사·지사) — 트리 전환(2026-07-27) */
	private String upperOrgnztId;
	/** 형제 내 표시 순서 (오름차순, null=마지막) */
	private Integer ordr;
	/** 하위부서 수 (트리 조회 파생값 — 삭제 가드·표시용) */
	private int childCnt;

	/**
	 * @return the orgnztId
	 */
	public String getOrgnztId() {
		return orgnztId;
	}
	/**
	 * @param orgnztId the orgnztId to set
	 */
	public void setOrgnztId(String orgnztId) {
		this.orgnztId = orgnztId;
	}
	/**
	 * @return the orgnztNm
	 */
	public String getOrgnztNm() {
		return orgnztNm;
	}
	/**
	 * @param orgnztNm the orgnztNm to set
	 */
	public void setOrgnztNm(String orgnztNm) {
		this.orgnztNm = orgnztNm;
	}
	/**
	 * @return the orgnztDc
	 */
	public String getOrgnztDc() {
		return orgnztDc;
	}
	/**
	 * @param orgnztDc the orgnztDc to set
	 */
	public void setOrgnztDc(String orgnztDc) {
		this.orgnztDc = orgnztDc;
	}

	public String getUpperOrgnztId() {
		return upperOrgnztId;
	}

	public void setUpperOrgnztId(String upperOrgnztId) {
		this.upperOrgnztId = upperOrgnztId;
	}

	public Integer getOrdr() {
		return ordr;
	}

	public void setOrdr(Integer ordr) {
		this.ordr = ordr;
	}

	public int getChildCnt() {
		return childCnt;
	}

	public void setChildCnt(int childCnt) {
		this.childCnt = childCnt;
	}

}
