/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/ion/brd/service/BrandInfo.java
 *
 * 브랜드설정 스냅샷 — 데코레이터(JSP)가 매 페이지 렌더마다 참조하는 읽기 전용 캐시.
 *
 * 왜 캐시인가: 로고·파비콘은 헤더/로그인/탭아이콘 등 "모든 화면"에 나온다. 렌더마다 DB 를 치면
 * 페이지당 조회가 1건씩 늘어난다. 그래서 기동 시 1회 적재하고, 설정 저장 시에만 갱신한다.
 * 갱신은 두 경로: 브랜드설정 화면에서 저장할 때(자동), DB 를 직접 고친 경우엔 /rlms/mgr/reloadBrand.do.
 *
 * 적재/갱신은 EgovBrandServiceImpl 이 담당하고, 여기서는 스냅샷을 들고만 있는다.
 */
package egovframework.com.uss.ion.brd.service;

public final class BrandInfo {

	/** 설정이 비어 있을 때 화면에 나갈 기본 문구 — 설치 직후/DB 오류 시에도 빈 헤더가 되지 않게.
	 *  고객사 리브랜딩은 화면(관리자 > 브랜드설정)에서 하며, 이 값은 최후의 폴백일 뿐이다.
	 *  (2026-07-31 이전에는 globals.properties 의 제품명 프로퍼티가 이 역할이었으나,
	 *   설정이 DB 로 옮겨오면서 그 프로퍼티와 전용 캐시 클래스는 삭제했다.) */
	public static final String DEFAULT_TEXT = "LegalNex 법률규정통합관리시스템";

	/** 기동 직후~적재 전, 또는 DB 오류로 못 읽은 경우에 쓰는 빈 설정(화면이 깨지지 않게) */
	private static final Brand EMPTY = new Brand();

	private static volatile Brand snapshot;

	private BrandInfo() {
	}

	/** 스냅샷 교체 — 서비스 계층 전용 */
	public static void set(Brand brand) {
		snapshot = brand;
	}

	/** 현재 설정. 미적재여도 null 을 돌려주지 않는다. */
	public static Brand get() {
		Brand b = snapshot;
		return (b == null) ? EMPTY : b;
	}

	/** 화면에 표시할 브랜드 문구. 미설정이면 기본 문구. (제목·헤더·이미지 alt 공통) */
	public static String getText() {
		String t = get().getLogoText();
		return (t == null || t.trim().isEmpty()) ? DEFAULT_TEXT : t;
	}

	/** 이미지 URL 뒤에 붙일 캐시버스터 — 설정을 바꾸면 값이 달라져 브라우저가 새로 받는다. */
	public static String getVersion() {
		String v = get().getLastUpdtPnttm();
		if (v == null || v.isEmpty()) {
			return "0";
		}
		// 숫자만 남긴다(URL 안전) — 'YYYY-MM-DD HH24:MI:SS' -> '20260731093012'
		StringBuilder sb = new StringBuilder(v.length());
		for (int i = 0; i < v.length(); i++) {
			char c = v.charAt(i);
			if (c >= '0' && c <= '9') {
				sb.append(c);
			}
		}
		return sb.length() == 0 ? "0" : sb.toString();
	}
}
