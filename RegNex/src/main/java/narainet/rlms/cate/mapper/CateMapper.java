/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/mapper/CateMapper.java
 */
package narainet.rlms.cate.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.cate.service.CateVO;

@Mapper
public interface CateMapper {

	/** CONNECT BY 한 방 트리 조회 (들여쓰기 + 법령 카운트).
	 *  frontGate=true 면 법령 카운트에 사용자 화면 현행 게이트(SDISP_YN·폐지일)를 적용해
	 *  front 검색 목록 건수와 일치시킨다. 관리(분류관리/편집기) 트리는 false = 원본 카운트
	 *  (삭제 차단 판정 selectPromCntByCate 와 동일 기준). */
	List<CateVO> selectCateTree(@Param("sysId") String sysId, @Param("frontGate") boolean frontGate);

	/** 직속 자식 */
	List<CateVO> selectChildren(@Param("parentNo") Long parentNo,
			@Param("sysId") String sysId);

	/** PK 단건 */
	CateVO selectCateByNo(@Param("cateNo") Long cateNo);

	/** 지정 분류의 모든 하위 분류 */
	List<CateVO> selectDescendants(@Param("cateNo") Long cateNo,
			@Param("sysId") String sysId);

	/** 여러 시작 분류의 자손-또는-자신 ICATE_NO 집합 — 집합 1회 CONNECT BY (자동링크 제외범위 확장) */
	List<Long> selectDescendantSetIncludingSelf(@Param("cateNos") List<Long> cateNos);

	/** Oracle 함수로 풀네임 */
	String selectFullNameByNo(@Param("cateNo") Long cateNo);

	/** 같은 부모 내 정렬순서 MAX(ISEQ)+1 */
	int selectMaxSeq(@Param("parentNo") Long parentNo,
			@Param("sysId") String sysId);

	/** 이 분류의 법령 수 (삭제 차단 판정 — SEXISTING_YN='Y' 만 카운트) */
	int selectPromCntByCate(@Param("cateNo") Long cateNo);

	/** 이 분류의 자식 분류 수 (삭제 차단 판정 — SDEL_YN='N' 만) */
	int selectChildCntByCate(@Param("cateNo") Long cateNo);

	/** 현재 TB_CATE 최대 PK */
	Long selectMaxCateNo();

	/** 구분(FT_GUBUN_N) 최대 번호 — 신규 구분 채번용. ccm + TB_CATE + TB_PROM 잔재까지 통합
	 *  (과거 삭제된 구분의 분류/규정 행이 남아 있으면 그 번호 재사용 시 엉뚱하게 붙는 사고 방지) */
	Long selectMaxGubunCodeNo();

	/** 구분 참조 카운트 — 삭제 차단 판정 {CATE_CNT: 미삭제 분류 수, PROM_CNT: 규정 수} */
	java.util.Map<String, Object> selectGubunRefCnts(@Param("gubunId") String gubunId);

	int insertCate(CateVO vo);

	int updateCate(CateVO vo);

	int updateCateDeleted(@Param("cateNo") Long cateNo);
}
