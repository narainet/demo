/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/common/service/PublicFront.java
 *
 * 공개열람 모드(Globals.rlms.publicFront) 판정 유틸 — LexPortal 의 Globals.law.portalMain 대칭.
 *   Y(기본) = 비로그인(익명)도 사용자(front) 규정 열람 화면을 볼 수 있다 — 첫 화면도 사용자 홈(/rlms/index.do).
 *   N = 로그인이 첫 화면 — 모든 화면이 로그인 후 진입(비공개 구축).
 *
 *   · 스위치 정본 = globals.properties. 구축 형상값이라 최초 1회만 읽어 고정한다 —
 *     값 변경은 서버 재기동 후 반영(2026-08-04 사용자 확정. 매 호출 재독은 게이트 필터가
 *     익명 요청마다 properties 파일 IO 를 반복하게 되어 폐기).
 *   · 익명 열람이어도 분류별 열람제한(TB_CATE_READER/TB_GUBUN_READER)은 그대로 적용된다 —
 *     익명 = 최소권한(면제역할 아님 + READER 매칭 불가)이라 제한 지정 분류는 전부 차단(fail-closed).
 *   · 개인화·쓰기(즐겨찾기/메모/필수열람/만족도/Q&A/게시판/내계정)는 공개 모드에서도 로그인 필요 —
 *     해당 URL 은 인가(context-security.xml)에서 익명 개방하지 않는다.
 */
package narainet.rlms.common.service;

import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.cmm.util.EgovUserDetailsHelper;

public final class PublicFront {

	/** 최초 판정 후 고정(재기동 시 초기화). lazy 1회 — 클래스 로딩 시점의 EgovProperties 준비 여부에 안전 */
	private static volatile Boolean ENABLED;

	private PublicFront() { }

	/** 공개열람 모드 여부 — Globals.rlms.publicFront=Y (기동 후 최초 1회 판정·고정, 변경=재기동 반영) */
	public static boolean enabled() {
		Boolean v = ENABLED;
		if (v == null) {
			String s = EgovProperties.getProperty("Globals.rlms.publicFront");
			v = Boolean.valueOf(s != null && "Y".equalsIgnoreCase(s.trim()));
			ENABLED = v;
		}
		return v.booleanValue();
	}

	/** 열람(front) 화면 진입 허용 — 로그인했거나, 공개열람 모드면 익명도 허용 */
	public static boolean viewAllowed() {
		return Boolean.TRUE.equals(EgovUserDetailsHelper.isAuthenticated()) || enabled();
	}
}
