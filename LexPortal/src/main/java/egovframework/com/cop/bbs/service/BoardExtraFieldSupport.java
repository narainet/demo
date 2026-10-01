/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/BoardExtraFieldSupport.java
 *
 * 여분필드(NTT_EXTRA_FIELD_1..10)의 다중값 처리.
 *
 * 게시판 여분필드는 값 한 칸(VARCHAR2(200))에 한 필드를 담는다. checkbox 타입은 여러 코드를 고를 수 있으므로
 * 쉼표로 이어 한 칸에 넣는다. 상세화면은 쉼표로 다시 쪼개 코드명으로 바꿔 보여준다.
 *
 * ★폼 파라미터 이름을 nttExtraFieldChk{i} 로 분리한 이유 — 체크박스를 nttExtraField{i} 로 두면
 *   같은 이름의 값이 여러 개 와서 스프링이 String 속성에 String[] 을 넣으려다 바인딩 예외를 낸다
 *   (이 프로젝트의 WebDataBinder 에는 ConversionService 가 없다). 그래서 바인딩 대상에서 빼고
 *   서버가 직접 조립한다.
 *
 * ★마커(nttExtraFieldChkMark{i})가 필요한 이유 — 체크박스는 하나도 안 고르면 파라미터 자체가 오지 않는다.
 *   마커가 없으면 "전부 해제"와 "이 필드는 체크박스가 아님"을 구별할 수 없어, 수정 시 옛 값이 남는다.
 */
package egovframework.com.cop.bbs.service;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import javax.servlet.http.HttpServletRequest;

public final class BoardExtraFieldSupport {

	/** 체크박스 선택값 파라미터 접두 — 바인딩 대상인 nttExtraField{i} 와 일부러 다르다. */
	public static final String CHECKBOX_PARAM_PREFIX = "nttExtraFieldChk";

	/** 체크박스 필드가 화면에 있었음을 알리는 숨김 마커 접두. */
	public static final String CHECKBOX_MARK_PREFIX = "nttExtraFieldChkMark";

	/** NTT_EXTRA_FIELD_n 컬럼 폭. */
	private static final int MAX_LEN = 200;

	private static final int FIELD_COUNT = 10;

	private BoardExtraFieldSupport() {
	}

	/**
	 * 체크박스 타입 여분필드의 선택값들을 쉼표로 이어 게시물에 싣는다.
	 * 마커가 온 필드만 건드리므로, 체크박스가 아닌 필드의 폼 바인딩 결과는 그대로 남는다.
	 */
	public static void applyMultiValueFields(HttpServletRequest request, Board board) {
		if (request == null || board == null) {
			return;
		}
		for (int i = 1; i <= FIELD_COUNT; i++) {
			if (request.getParameter(CHECKBOX_MARK_PREFIX + i) == null) {
				continue;
			}
			board.setNttExtraField(i, join(request.getParameterValues(CHECKBOX_PARAM_PREFIX + i)));
		}
	}

	/** 빈값·중복·쉼표 포함 값(구분자를 깨뜨린다)을 걸러 이어붙이고, 컬럼 폭을 넘지 않게 자른다. */
	private static String join(String[] values) {
		if (values == null || values.length == 0) {
			return "";
		}
		Set<String> codes = new LinkedHashSet<String>();
		for (String value : values) {
			String code = (value == null) ? "" : value.trim();
			if (!code.isEmpty() && code.indexOf(',') < 0) {
				codes.add(code);
			}
		}

		List<String> kept = new ArrayList<String>();
		int len = 0;
		for (String code : codes) {
			int added = kept.isEmpty() ? code.length() : code.length() + 1;
			if (len + added > MAX_LEN) {
				break;
			}
			kept.add(code);
			len += added;
		}

		StringBuilder sb = new StringBuilder(len);
		for (String code : kept) {
			if (sb.length() > 0) {
				sb.append(',');
			}
			sb.append(code);
		}
		return sb.toString();
	}
}
