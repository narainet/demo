/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/menu/service/MenuVO.java
 *
 * 표준 메뉴(COMTNMENUINFO) + 프로그램(COMTNPROGRMLIST) 조인 VO.
 *  - 데이터기반 GNB 렌더링용. children 으로 2단(폴더>항목) 트리 구성.
 *  - url 은 COMTNPROGRMLIST.URL (폴더는 NULL → isFolder()=true)
 */
package narainet.rlms.menu.service;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class MenuVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 메뉴번호 (MENU_NO, PK) */
	private Long menuNo;

	/** 메뉴명 (MENU_NM) */
	private String menuNm;

	/** 연결 프로그램 파일명 (PROGRM_FILE_NM, 폴더면 NULL) */
	private String progrmFileNm;

	/** 상위메뉴번호 (UPPER_MENU_NO, 최상위=0) */
	private Long upperMenuNo;

	/** 메뉴순서 (MENU_ORDR) */
	private Integer menuOrdr;

	/** 메뉴구분 (MENU_SE: USER/ADMIN) */
	private String menuSe;

	/** 링크 URL (COMTNPROGRMLIST.URL) */
	private String url;

	/** 관련이미지경로 (RELATE_IMAGE_PATH) — 외부링크 메뉴는 여기에 외부 URL 저장(레거시 관례) */
	private String relateImagePath;

	/** 관련이미지명 (RELATE_IMAGE_NM) — 폴더 메뉴의 GNB 렌더 힌트. 'drop'=드롭다운(레거시 관례: 미사용 컬럼 전용) */
	private String relateImageNm;

	/** 하위 메뉴 (트리 빌드 결과) */
	private List<MenuVO> children = new ArrayList<>();

	/**
	 * 폴더(링크 없는 그룹) 여부 — JSP EL ${menu.folder}.
	 * eGov 표준 폴더 규칙: PROGRM_FILE_NM='folder' (또는 미연결 NULL).
	 */
	public boolean isFolder() {
		return progrmFileNm == null || progrmFileNm.isEmpty()
				|| "folder".equalsIgnoreCase(progrmFileNm);
	}

	/**
	 * 외부링크 메뉴 여부 — JSP EL ${menu.external}.
	 * 폴더가 아니면서 RELATE_IMAGE_PATH(외부 URL)가 채워진 경우.
	 * (레거시 관례: 외부링크는 PROGRM_FILE_NM='externalLink' placeholder + RELATE_IMAGE_PATH=실제 URL)
	 */
	public boolean isExternal() {
		return !isFolder() && relateImagePath != null && !relateImagePath.trim().isEmpty();
	}

	/**
	 * GNB 를 드롭다운으로 펼칠 폴더인지 — JSP EL ${menu.dropdown}.
	 * 나머지 폴더는 하위 리프를 평면으로 펼친다(현행 단일바 룩).
	 * 메뉴명 문자열 매칭 대신 DB 값(RELATE_IMAGE_NM='drop')으로 판정 — 메뉴 개명에도 안 깨진다.
	 */
	public boolean isDropdown() {
		return isFolder() && relateImageNm != null && "drop".equalsIgnoreCase(relateImageNm.trim());
	}

	/**
	 * 렌더링용 최종 href — JSP EL ${menu.href}.
	 *  - 외부링크: 외부 URL(relateImagePath) 그대로
	 *  - 폴더: '#'
	 *  - 내부프로그램: 프로그램 URL
	 */
	public String getHref() {
		if (isExternal()) {
			return relateImagePath;
		}
		if (isFolder()) {
			return "#";
		}
		return url;
	}
}
