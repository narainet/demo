/*
 * 물리적 저장 경로: /src/main/java/narainet/law/common/mapper/LawMainMapper.java
 *
 * LexPortal(송무관리 단독) 전용 진입점 보조 조회 — LawMainController 소관.
 * ※ 통합본 RLMS 에는 없는 파일. 공통 베이스 화면(사용자관리 부서 모달)이 쓰는
 *   부서 목록 JSON 의 데이터원으로, 통합본 Prom_SQL selectOrgnztList 와 동일 계약을 유지한다.
 */
package narainet.law.common.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface LawMainMapper {

	/** 부서 목록 (orgnztId/buseoNm/fullNm/buseoNo — 통합본 buseoListJson 응답 계약) */
	List<Map<String, Object>> selectBuseoList(@Param("keyword") String keyword);
}
