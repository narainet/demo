/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/menu/MenuHelper.java
 *
 * SiteMesh 데코레이터(mgr.jsp / front.jsp) 스크립틀릿에서 호출하는 정적 메뉴 헬퍼.
 *  - getMenuTree: 권한별 메뉴트리. 데이터원은 ★표준프레임워크★ 메뉴서비스
 *    (egovframework.com.sym.mnu.mpm.EgovMenuManageService.selectMainMenuLeft) — 별도 커스텀 쿼리 없음.
 *    selectMainMenuLeft 가 로그인 사용자 권한(COMTNEMPLYRSCRTYESTBS) + MENU_SE 로 필터한 평면 메뉴를 반환 →
 *    여기서 2단(폴더>항목) 트리로 빌드. 60초 캐시.
 *  - resolveAdminLayout: 관리자 레이아웃(GNB + 활성 LNB) 1요청 모델 — mgr.jsp 스크립틀릿 대체.
 *    활성 LNB 판정은 하드코딩 URL 사다리 대신 DB 메뉴트리에서 "공통 접두 최장 매칭"으로 파생.
 *  - 어떤 실패도 메뉴 미표시로 흡수 — 메뉴 때문에 페이지가 깨지지 않도록.
 */
package narainet.rlms.menu;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import javax.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.support.RequestContextUtils;

import egovframework.com.cmm.LoginVO;
import egovframework.com.cmm.util.EgovLayoutResolver;
import egovframework.com.cmm.util.EgovUserDetailsHelper;
import egovframework.com.sym.mnu.mpm.service.EgovMenuManageService;
import egovframework.com.sym.mnu.mpm.service.MenuManageVO;
import narainet.rlms.menu.service.MenuLayoutVO;
import narainet.rlms.menu.service.MenuVO;

public final class MenuHelper {

	private static final Logger LOGGER = LoggerFactory.getLogger(MenuHelper.class);

	// ── 메뉴트리 캐시 (메뉴는 거의 안 바뀜 → 매 요청 DB조회 제거. TTL 후 자동 갱신) ──
	private static final long CACHE_TTL_MS = 60_000L;
	private static final ConcurrentHashMap<String, CacheEntry> MENU_CACHE = new ConcurrentHashMap<>();

	private static final class CacheEntry {
		final long ts;
		final List<MenuVO> list;
		CacheEntry(long ts, List<MenuVO> list) { this.ts = ts; this.list = list; }
	}

	private MenuHelper() {
	}

	/** 캐시 비우기 — 메뉴/권한 변경 즉시 반영이 필요할 때 호출(예: 메뉴관리 저장 후). */
	public static void clearCache() {
		MENU_CACHE.clear();
	}

	/**
	 * 현재 로그인 사용자의 권한으로 노출 가능한 메뉴 트리를 반환 (60초 캐시).
	 * 데이터원 = 표준 EgovMenuManageService.selectMainMenuLeft (MENU_SE + 사용자 권한 필터).
	 *
	 * @param request HTTP 요청 (dispatcher WAC + 인증정보 출처)
	 * @param menuSe  'USER' 또는 'ADMIN'
	 * @return 메뉴 트리(루트 목록). 미인증/실패 시 빈 목록.
	 */
	public static List<MenuVO> getMenuTree(HttpServletRequest request, String menuSe) {
		try {
			String uniqId = currentUniqId();
			if (uniqId == null || uniqId.isEmpty()) {
				// 미인증 사용자 — 표준 인증메뉴(COMTNEMPLYRSCRTYESTBS 기반) 없음.
				return Collections.emptyList();
			}

			String key = menuSe + "|" + uniqId;
			long now = System.currentTimeMillis();
			CacheEntry cached = MENU_CACHE.get(key);
			if (cached != null && now - cached.ts < CACHE_TTL_MS) {
				return cached.list;
			}

			WebApplicationContext ctx = RequestContextUtils.findWebApplicationContext(request);
			if (ctx == null) {
				return Collections.emptyList();
			}
			EgovMenuManageService menuService = ctx.getBean(EgovMenuManageService.class);
			MenuManageVO param = new MenuManageVO();
			param.setMenuSe(menuSe);
			param.setTmpUniqId(uniqId);

			List<?> flat = menuService.selectMainMenuLeft(param);
			List<MenuVO> tree = buildTree(flat);
			MENU_CACHE.put(key, new CacheEntry(now, tree));
			return tree;
		} catch (Exception e) {
			LOGGER.warn("RLMS 메뉴 로드 실패 (메뉴 없이 진행): {}", e.getMessage());
			return Collections.emptyList();
		}
	}

	/**
	 * 관리자 레이아웃(GNB + 활성 LNB) 모델 반환. mgr.jsp 스크립틀릿 대체.
	 * 활성 판정은 DB 메뉴트리에서 파생 — 하드코딩 URL 분기 없음.
	 */
	public static MenuLayoutVO resolveAdminLayout(HttpServletRequest request) {
		MenuLayoutVO vo = new MenuLayoutVO();
		try {
			Boolean isAuth = EgovUserDetailsHelper.isAuthenticated();
			vo.setAuthenticated(Boolean.TRUE.equals(isAuth));
			if (vo.isAuthenticated()) {
				Object au = EgovUserDetailsHelper.getAuthenticatedUser();
				if (au instanceof LoginVO) {
					vo.setLoginUser((LoginVO) au);
				}
			}
		} catch (Exception e) {
			LOGGER.warn("로그인 정보 조회 실패: {}", e.getMessage());
		}

		List<MenuVO> menuAdmin = getMenuTree(request, "ADMIN");
		vo.setMenuAdmin(menuAdmin);

		String path = resolvePath(request);
		vo.setPath(path);

		// 현재 경로가 속한 최상위 메뉴(lnbRoot)와 활성 2차 항목을, 메뉴트리에서 "공통 접두 최장 매칭"으로 찾음.
		MenuVO lnbRoot = null;
		MenuVO active2 = null;
		int bestScore = -1;
		if (menuAdmin != null && path != null) {
			for (MenuVO root : menuAdmin) {
				if (root == null || root.getChildren() == null) {
					continue;
				}
				for (MenuVO lvl2 : root.getChildren()) {
					int s = subtreeMatchScore(lvl2, path);
					if (s > bestScore) {
						bestScore = s;
						lnbRoot = root;
						active2 = lvl2;
					}
				}
			}
		}

		vo.setLnbRoot(lnbRoot);
		String activePrefix = (active2 != null && active2.getUrl() != null && !active2.getUrl().isEmpty())
				? active2.getUrl() : path;
		vo.setActiveMenuPrefix(activePrefix);
		vo.setShowDbLnb(lnbRoot != null && lnbRoot.getChildren() != null && !lnbRoot.getChildren().isEmpty());
		vo.setActiveSystem(isStandardAdminGroup(lnbRoot));
		return vo;
	}

	// ── 내부 ───────────────────────────────────────────────────────

	/** 현재 로그인 사용자의 고유ID(ESNTL_ID). 미인증/실패 시 "". */
	private static String currentUniqId() {
		try {
			Object au = EgovUserDetailsHelper.getAuthenticatedUser();
			if (au instanceof LoginVO) {
				String id = ((LoginVO) au).getUniqId();
				return id == null ? "" : id;
			}
		} catch (Exception e) {
			LOGGER.warn("로그인 정보 조회 실패: {}", e.getMessage());
		}
		return "";
	}

	/**
	 * 표준 selectMainMenuLeft 의 평면 EgovMap 목록(UPPER_MENU_NO, MENU_ORDR 정렬) → 2단 트리.
	 * EgovMap 키는 mapUnderscoreToCamelCase 로 camelCase(menuNo 등)이나, 안전하게 UPPER 형태도 시도.
	 */
	private static List<MenuVO> buildTree(List<?> flat) {
		if (flat == null || flat.isEmpty()) {
			return Collections.emptyList();
		}
		List<MenuVO> nodes = new ArrayList<>(flat.size());
		for (Object o : flat) {
			if (!(o instanceof Map)) {
				continue;
			}
			Map<?, ?> row = (Map<?, ?>) o;
			MenuVO m = new MenuVO();
			m.setMenuNo(toLong(mapGet(row, "menuNo", "MENU_NO")));
			m.setUpperMenuNo(toLong(mapGet(row, "upperMenuId", "UPPER_MENU_ID")));
			m.setMenuOrdr(toInt(mapGet(row, "menuOrdr", "MENU_ORDR")));
			m.setMenuNm(toStr(mapGet(row, "menuNm", "MENU_NM")));
			m.setProgrmFileNm(toStr(mapGet(row, "progrmFileNm", "PROGRM_FILE_NM")));
			m.setMenuSe(toStr(mapGet(row, "menuSe", "MENU_SE")));
			m.setRelateImagePath(toStr(mapGet(row, "relateImagePath", "RELATE_IMAGE_PATH")));
			m.setRelateImageNm(toStr(mapGet(row, "relateImageNm", "RELATE_IMAGE_NM")));
			m.setUrl(toStr(mapGet(row, "chkUrl", "CHK_URL")));
			nodes.add(m);
		}

		Map<Long, MenuVO> byNo = new LinkedHashMap<>();
		for (MenuVO m : nodes) {
			if (m.getMenuNo() != null) {
				byNo.put(m.getMenuNo(), m);
			}
		}

		List<MenuVO> roots = new ArrayList<>();
		for (MenuVO m : nodes) {
			Long up = m.getUpperMenuNo();
			MenuVO parent = (up == null) ? null : byNo.get(up);
			if (up == null || up.longValue() == 0L || parent == null) {
				roots.add(m);
			} else {
				parent.getChildren().add(m);
			}
		}
		return roots;
	}

	private static Object mapGet(Map<?, ?> row, String camel, String upper) {
		Object v = row.get(camel);
		if (v == null) {
			v = row.get(upper);
		}
		return v;
	}

	private static Long toLong(Object v) {
		if (v == null) {
			return null;
		}
		if (v instanceof Number) {
			return ((Number) v).longValue();
		}
		try {
			return Long.valueOf(v.toString().trim());
		} catch (NumberFormatException e) {
			return null;
		}
	}

	private static Integer toInt(Object v) {
		if (v == null) {
			return null;
		}
		if (v instanceof Number) {
			return ((Number) v).intValue();
		}
		try {
			return Integer.valueOf(v.toString().trim());
		} catch (NumberFormatException e) {
			return null;
		}
	}

	private static String toStr(Object v) {
		return v == null ? null : v.toString();
	}

	/** 컨텍스트 경로 제외한 요청 path. */
	private static String resolvePath(HttpServletRequest request) {
		// ⛔ getRequestURI() 직접 호출 금지 — 이 메서드는 JSP 셸(태그파일)에서도 불리는데,
		//    그 시점엔 이미 /WEB-INF/jsp/... 로 forward 된 뒤라 JSP 경로가 돌아온다(활성 LNB 오판).
		//    SiteMesh 시절엔 셸을 include 로 붙여 원 URI 가 유지됐다 — 그 전제가 깨졌다(2026-08-07).
		String uri = EgovLayoutResolver.originalRequestUri(request);
		if (uri == null || uri.isEmpty()) {
			return "";
		}
		String ctx = request.getContextPath();
		String path;
		if (ctx != null && ctx.length() > 0 && uri.startsWith(ctx)) {
			path = uri.substring(ctx.length());
		} else {
			path = uri;
		}
		String bbsId = request.getParameter("bbsId");
		String bbsMenuPath = normalizeBbsArticlePath(path, bbsId);
		if (bbsMenuPath != null) {
			return bbsMenuPath;
		}
		String query = EgovLayoutResolver.originalQueryString(request);
		if (query != null && !query.isEmpty()) {
			path += "?" + query;
		}
		return path;
	}

	private static String normalizeBbsArticlePath(String path, String bbsId) {
		if (path == null || bbsId == null || bbsId.isEmpty()) {
			return null;
		}
		if ("/cop/bbs/insertArticleView.do".equals(path)
				|| "/cop/bbs/updateArticleView.do".equals(path)
				|| "/cop/bbs/selectArticleDetail.do".equals(path)) {
			return "/cop/bbs/selectArticleList.do?bbsId=" + bbsId;
		}
		return null;
	}

	/**
	 * node(및 모든 하위)의 리프 URL 중, path 와 같은 디렉터리이면서 path 와의 공통 접두 길이가
	 * 가장 긴 점수. 매칭(같은 디렉터리) 없으면 -1.
	 *  - 같은 디렉터리 요구 → 모듈 교차 오매칭 방지(/rlms/cate vs /rlms/gaejung).
	 *  - 공통 접두 최장 → 같은 디렉터리 내 구분(/sec/ram/EgovAuthor vs EgovAuthorRole).
	 */
	private static int subtreeMatchScore(MenuVO node, String path) {
		if (node == null) {
			return -1;
		}
		int best = -1;
		String url = node.getUrl();
		if (url != null && !url.isEmpty() && !node.isFolder()) {
			int slash = url.lastIndexOf('/');
			String dir = slash >= 0 ? url.substring(0, slash + 1) : "";
			if (!dir.isEmpty() && path.startsWith(dir)) {
				best = commonPrefixLen(path, url);
			}
		}
		if (node.getChildren() != null) {
			for (MenuVO c : node.getChildren()) {
				int s = subtreeMatchScore(c, path);
				if (s > best) {
					best = s;
				}
			}
		}
		return best;
	}

	private static int commonPrefixLen(String a, String b) {
		int n = Math.min(a.length(), b.length());
		int i = 0;
		while (i < n && a.charAt(i) == b.charAt(i)) {
			i++;
		}
		return i;
	}

	/**
	 * lnbRoot 그룹이 표준 관리화면(/sec, /sym, /uss/umt/EgovUser)인지.
	 * → 표준 eGov JSP 가 가진 자체 LNB 를 숨기는 CSS 조건에만 사용(최소 규칙).
	 * ★관리자 메뉴는 3단(관리자→그룹→화면)이라 실제 URL 은 손자 노드(leaf)에 있다.
	 *   직속 자식(폴더)의 URL 만 보면 항상 null → 판정 실패 → 자체 LNB 가 DB LNB 와 중복 표시되던 버그.
	 *   하위 트리 전체를 재귀 검사한다.
	 */
	private static boolean isStandardAdminGroup(MenuVO lnbRoot) {
		return subtreeHasAdminUrl(lnbRoot);
	}

	private static boolean subtreeHasAdminUrl(MenuVO node) {
		if (node == null) {
			return false;
		}
		String u = node.getUrl();
		if (u != null && (u.startsWith("/sec/") || u.startsWith("/sym/") || u.startsWith("/uss/umt/EgovUser"))) {
			return true;
		}
		if (node.getChildren() != null) {
			for (MenuVO c : node.getChildren()) {
				if (subtreeHasAdminUrl(c)) {
					return true;
				}
			}
		}
		return false;
	}
}
