/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/menu/service/MenuLayoutVO.java
 *
 * 관리자 레이아웃(mgr.jsp 데코레이터) 1요청 모델.
 *  - mgr.jsp 스크립틀릿 100여 줄을 대체: 헬퍼가 이 VO 하나로 반환.
 *  - active(LNB) 판정은 하드코딩 URL 사다리 대신 DB 메뉴트리에서 파생.
 */
package narainet.rlms.menu.service;

import java.io.Serializable;
import java.util.List;

import egovframework.com.cmm.LoginVO;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MenuLayoutVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 인증 여부 */
	private boolean authenticated;

	/** 로그인 사용자 */
	private LoginVO loginUser;

	/** 관리자 GNB 메뉴트리 (COMTNMENUINFO MENU_SE='ADMIN' + 권한필터) */
	private List<MenuVO> menuAdmin;

	/** 컨텍스트 제외 현재 경로 (예 /sec/rmt/EgovRoleList.do) */
	private String path;

	/** 현재 페이지가 속한 최상위 메뉴(LNB 루트). 없으면 null */
	private MenuVO lnbRoot;

	/** LNB 활성 항목 강조용 — 활성 메뉴의 URL (없으면 path) */
	private String activeMenuPrefix;

	/** LNB(좌측 메뉴) 노출 여부 — lnbRoot 에 자식이 있을 때 */
	private boolean showDbLnb;

	/** 표준 관리화면(/sec,/sym,/uss/umt/EgovUser) 여부 — 표준 JSP 자체 LNB 숨김 CSS 용 */
	private boolean activeSystem;
}
