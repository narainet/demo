/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/umt/service/EgovMyAccountService.java
 */
package egovframework.com.uss.umt.service;

import java.util.Map;

public interface EgovMyAccountService {

	/**
	 * 본인 로그인(접속) 내역을 페이징 조회한다.
	 * @param uniqId 로그인 사용자 ESNTL_ID
	 * @param vo     페이징/기간검색 조건
	 * @return {resultList: List&lt;LoginHistVO&gt;, resultCnt: String}
	 */
	Map<String, Object> selectMyLoginHistory(String uniqId, LoginHistVO vo);

	/**
	 * 본인 프로필(이름/이메일/휴대전화) 조회 — userSe(GNR/USR)로 원천 테이블 분기.
	 * @return {name, email, mbtlnum} (없으면 null)
	 */
	Map<String, Object> selectMyProfile(String userSe, String uniqId);

	/** 본인 프로필 수정 — 이메일/휴대전화만 (이름·소속은 관리자 관리 영역) */
	void updateMyProfile(String userSe, String uniqId, String email, String mbtlnum);
}
