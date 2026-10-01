/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/FrontTreeCache.java
 *
 * 사용자(front) 규정분류 트리 메모리 캐시 — 튜닝(2026-07-24).
 *
 *  · 대상: /rlms/prom/treeJson.do 루트(front) 응답의 원천인 "무차단 전체 트리" 1벌.
 *    요청마다 분류/규정 전건 조회(selectCateTree + selectActivePromsForTree)를 반복하던 것을
 *    메모리 스냅샷으로 대체. 사용자별 열람제한은 컨트롤러가 캐시본에서 차단 분류만
 *    가지치기(사본 생성)하므로 캐시는 사용자 무관 1벌로 충분(권한 누수 없음).
 *  · 파일 캐시가 아닌 메모리 캐시인 이유: 디스크 I/O·파싱·파일 수명주기 관리 없이 동일
 *    효과. MenuHelper/AutoLinkService 사전과 같은 정착 관례(TTL + 변경 시 명시 무효화).
 *  · 무효화: TTL 60초 + 승인 전이(PromWorkServiceImpl)·연혁 삭제(PromServiceImpl.deleteProm)
 *    시 clear() 즉시 호출(자동링크 사전 무효화와 같은 지점). 분류/제목 등 기타 변경은
 *    TTL 이 수렴시킨다(자동링크 사전과 동일한 신선도 수준).
 *  · 관리자 편집기 트리(editorTreeJson)는 비캐시 — draft 포함이라 항상 실시간 조회.
 */
package narainet.rlms.prom.service;

import java.util.List;
import java.util.Map;

public final class FrontTreeCache {

	private static final long TTL_MS = 60_000L;

	private static volatile List<Map<String, Object>> TREE;
	private static volatile long TS;

	private FrontTreeCache() { }

	/** 유효한 스냅샷 반환(만료/없음 = null). 반환 구조는 읽기 전용으로만 사용할 것. */
	public static List<Map<String, Object>> get() {
		List<Map<String, Object>> t = TREE;
		if (t == null || System.currentTimeMillis() - TS >= TTL_MS) return null;
		return t;
	}

	public static void put(List<Map<String, Object>> tree) {
		TREE = tree;
		TS = System.currentTimeMillis();
	}

	/** 규정 승인/삭제 등 트리가 바뀌는 시점에 호출 — 다음 요청에서 재적재 */
	public static void clear() {
		TREE = null;
	}
}
