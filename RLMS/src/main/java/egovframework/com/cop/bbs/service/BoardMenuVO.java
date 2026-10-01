/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/BoardMenuVO.java
 *
 * 게시판 ↔ 사용자 메뉴 연결 정보. 표준 3테이블(COMTNPROGRMLIST · COMTNMENUINFO ·
 * COMTNMENUCREATDTLS)에 흩어진 한 게시판의 노출 설정을 한 덩어리로 다룬다.
 * 별도 저장 테이블은 없다 — 메뉴가 접근권한의 단일 원천이라는 원칙을 그대로 따른다.
 */
package egovframework.com.cop.bbs.service;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class BoardMenuVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 연결된 게시판 ID */
	private String bbsId = "";

	/** 메뉴 번호 (COMTNMENUINFO.MENU_NO) */
	private Long menuNo;

	/** 상위 메뉴(게시판 폴더) 번호 */
	private Long upperMenuNo;

	/** 사용자 GNB 에 보일 메뉴명 */
	private String menuNm = "";

	/** 형제 메뉴 사이의 정렬 순서 */
	private Integer menuOrdr;

	/** 프로그램 파일명 (COMTNPROGRMLIST PK) */
	private String progrmFileNm = "";

	/** 프로그램 URL — 코드가 조립하며 사람이 입력하지 않는다. */
	private String url = "";

	/** 이 메뉴를 볼 수 있는 역할들 (COMTNMENUCREATDTLS.AUTHOR_CODE) */
	private List<String> authorCodes = new ArrayList<String>();

	public String getBbsId() {
		return bbsId;
	}

	public void setBbsId(String bbsId) {
		this.bbsId = bbsId;
	}

	public Long getMenuNo() {
		return menuNo;
	}

	public void setMenuNo(Long menuNo) {
		this.menuNo = menuNo;
	}

	public Long getUpperMenuNo() {
		return upperMenuNo;
	}

	public void setUpperMenuNo(Long upperMenuNo) {
		this.upperMenuNo = upperMenuNo;
	}

	public String getMenuNm() {
		return menuNm;
	}

	public void setMenuNm(String menuNm) {
		this.menuNm = menuNm;
	}

	public Integer getMenuOrdr() {
		return menuOrdr;
	}

	public void setMenuOrdr(Integer menuOrdr) {
		this.menuOrdr = menuOrdr;
	}

	public String getProgrmFileNm() {
		return progrmFileNm;
	}

	public void setProgrmFileNm(String progrmFileNm) {
		this.progrmFileNm = progrmFileNm;
	}

	public String getUrl() {
		return url;
	}

	public void setUrl(String url) {
		this.url = url;
	}

	public List<String> getAuthorCodes() {
		return authorCodes;
	}

	public void setAuthorCodes(List<String> authorCodes) {
		this.authorCodes = (authorCodes == null) ? new ArrayList<String>() : authorCodes;
	}
}
