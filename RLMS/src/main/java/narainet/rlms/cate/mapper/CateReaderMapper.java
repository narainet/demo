/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/mapper/CateReaderMapper.java
 */
package narainet.rlms.cate.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.cate.service.CateReaderVO;

/**
 * 분류별 열람제한 매퍼 (TB_CATE_READER)
 */
@Mapper
public interface CateReaderMapper {

	/** 특정 분류의 열람대상 목록 (부서/개인, 표시명 해석 포함) */
	List<CateReaderVO> selectReadersByCate(@Param("cateNo") Long cateNo);

	/** 열람대상 추가 (PK 중복은 호출측에서 countReader 로 사전 차단) */
	int insertReader(CateReaderVO vo);

	/** 열람대상 삭제 (PK 단건) */
	int deleteReader(@Param("cateNo") Long cateNo,
			@Param("readerTy") String readerTy,
			@Param("readerId") String readerId);

	/** PK 존재 여부 (중복 추가 방지) */
	int countReader(@Param("cateNo") Long cateNo,
			@Param("readerTy") String readerTy,
			@Param("readerId") String readerId);

	/** ESNTL_ID 실존 여부 — 개인 열람대상 오타 방어(오타 시 분류 전면 차단되는 fail-dangerous 방지) */
	int countUserExists(@Param("esntlId") String esntlId);

	/** 사용자 검색 — 이름/로그인ID 부분일치 (개인 열람대상 선택 UI) — {esntlId, userId, userNm, orgnztNm} 최대 20 */
	List<java.util.Map<String, Object>> selectUserSearch(@Param("keyword") String keyword);

	// ── 구분(최상위 SGUBUN_ID) 단위 열람제한 (TB_GUBUN_READER) ──────

	/** 특정 구분의 열람대상 목록 (표시명 해석) */
	List<CateReaderVO> selectGubunReaders(@Param("gubunId") String gubunId);

	/** 구분 열람대상 추가 */
	int insertGubunReader(CateReaderVO vo);

	/** 구분 열람대상 삭제 (PK 단건) */
	int deleteGubunReader(@Param("gubunId") String gubunId,
			@Param("readerTy") String readerTy,
			@Param("readerId") String readerId);

	/** 구분 PK 존재 여부 (중복 추가 방지) */
	int countGubunReader(@Param("gubunId") String gubunId,
			@Param("readerTy") String readerTy,
			@Param("readerId") String readerId);

	/**
	 * 열람차단 가드 — 결과>0 이면 차단(열람 불가).
	 * 차단 = "적용 가능한 제한행 존재" AND "그중 본인 매칭 없음".
	 * 면제역할(ADMIN/EDITOR/APPROVER)은 호출측에서 먼저 통과시키고, 그 외에만 사용.
	 *
	 * @param esntlId  현재 사용자 ESNTL_ID (USER 대상 매칭)
	 * @param orgnztId 현재 사용자 ORGNZT_ID (DEPT 대상 매칭)
	 * @param cateNo   규정의 분류번호
	 */
	int countReadBlock(@Param("esntlId") String esntlId,
			@Param("orgnztId") String orgnztId,
			@Param("cateNo") Long cateNo);

	/** 해당 사용자가 열람할 수 없는 분류번호 전체 (트리 필터용, 삭제분류 포함) */
	List<Long> selectBlockedCateNos(@Param("esntlId") String esntlId,
			@Param("orgnztId") String orgnztId);

	/** 해당 사용자가 열람할 수 없는 규정번호 전체 — 법령(ILAW_ID) 단위 전 회차 전개 (기능별분류 트리 필터용) */
	List<Long> selectBlockedPromNos(@Param("esntlId") String esntlId,
			@Param("orgnztId") String orgnztId);
}
