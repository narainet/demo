/*
 * 물리적 저장 경로: /src/main/java/narainet/law/common/mapper/LawComMapper.java
 *
 * 송무 공용 조회 — 공통코드(ccm)·부서(COMTNORGNZTINFO)·법원(LAW_COURT) select 소스.
 * ※ 표준 베이스 원칙(§1.3-3): narainet.rlms 코드 참조 금지 — rlms CmmnCodeMapper 의 law 축 복제본.
 */
package narainet.law.common.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface LawComMapper {

	/** ccm 상세 코드 목록 (USE_AT='Y', CODE_DC 순 — code/codeNm/codeDc) */
	List<Map<String, Object>> selectCmmnCodeList(@Param("codeId") String codeId);

	/** 부서 목록 (orgnztId/orgnztNm) */
	List<Map<String, Object>> selectOrgnztList();

	/** 법원 목록 (courtId/courtNm — 루트 제외, 서열 순) */
	List<Map<String, Object>> selectCourtList();

	/** 변호사 select 소스 (lawyerId/label='법무법인 / 변호사' — 미삭제, §7.6 선임등록 모달) */
	List<Map<String, Object>> selectLawyerOptions();
}
