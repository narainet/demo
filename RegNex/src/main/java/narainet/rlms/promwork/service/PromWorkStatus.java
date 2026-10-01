/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/promwork/service/PromWorkStatus.java
 *
 * 작업승인 상태(SSTATUS) ↔ URL 노출용 ASCII 코드 매핑.
 *   · DB/SQL 정본은 한글 SSTATUS(레거시 운영 실데이터와 동일) 를 그대로 유지한다.
 *   · 화면 링크(헤더 배지·규정 IDE)와 목록 필터엔 ASCII 코드(st)만 실어 한글 GET 파라미터를 없앤다.
 *   · 코드→SSTATUS 매핑은 여기 한 곳에서만 정의(단일 원천). 컨트롤러가 코드를 받아 SSTATUS 로 바꿔 SQL 에 넘긴다.
 */
package narainet.rlms.promwork.service;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

public final class PromWorkStatus {

	private PromWorkStatus() {}

	/** 합성 필터 코드 — 단일 SSTATUS 가 아닌 메타 필터. 배지 카운트와 목록 기준 정합(2026-07-09). */
	public static final String CODE_PENDING = "PENDING";   // 처리대기 = 승인요청 (최신행. 수정권한 축 폐지 — 2026-07-20)
	public static final String CODE_MYREJ   = "MYREJ";     // 내 반려 = 승인반려 (최신행+본인 신청분)

	/** 코드 → SSTATUS(한글). 드롭다운 표시 순서 그대로 보존.
	 *  ※ MCHK(수정완료확인)는 진입 전이가 없는 죽은 상태(레거시 TYPE_8 운영 미사용)라 제거(2026-07-09).
	 *  ※ 수정권한 계열(MREQ/MAPR/MREJ/MDONE)은 워크플로 폐지로 제거(2026-07-20, 신규 DB 잔존 데이터 0건 확인). */
	private static final Map<String, String> CODE_TO_STATUS;
	static {
		Map<String, String> m = new LinkedHashMap<>();
		m.put("EDIT",  "편집중");
		m.put("REQ",   "승인요청");
		m.put("APR",   "승인완료");
		m.put("REJ",   "승인반려");
		CODE_TO_STATUS = Collections.unmodifiableMap(m);
	}

	/** 드롭다운 옵션 (합성 필터 + 상태) — 코드 → 라벨. */
	private static final Map<String, String> OPTIONS;
	static {
		Map<String, String> m = new LinkedHashMap<>();
		m.put(CODE_PENDING, "처리대기(전체)");
		m.put(CODE_MYREJ,   "내 반려");
		m.putAll(CODE_TO_STATUS);
		OPTIONS = Collections.unmodifiableMap(m);
	}

	/** 코드 → SSTATUS(한글). 합성 필터·알 수 없는·빈 코드면 null(=단일 상태 필터 없음). */
	public static String toStatus(String code) {
		if (code == null || code.trim().isEmpty()) return null;
		return CODE_TO_STATUS.get(code.trim());
	}

	/** 유효 코드(상태 또는 합성 필터)면 그대로, 아니면 "" — 드롭다운 선택/폼 재현(페이징)용. */
	public static String normalizeCode(String code) {
		if (code == null) return "";
		String c = code.trim();
		return OPTIONS.containsKey(c) ? c : "";
	}

	/** 드롭다운용 코드 → 라벨 순서맵 (합성 필터 포함). */
	public static Map<String, String> options() {
		return OPTIONS;
	}
}
