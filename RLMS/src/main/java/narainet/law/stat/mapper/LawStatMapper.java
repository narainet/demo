/*
 * 물리적 저장 경로: /src/main/java/narainet/law/stat/mapper/LawStatMapper.java
 *
 * 소송통계 7종 조회 매퍼 — LAW_MODULE_DESIGN.md §7.12.
 * 각 메서드는 param Map(fromDate/toDate + 축 코드 상수)을 받아 집계 행(Map)을 돌려준다.
 * 축 코드값은 서비스 상수에서 주입(SQL 하드코딩 금지). 레거시 BEFORE_FLAG 폐지, DEL_YN='N'만.
 */
package narainet.law.stat.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface LawStatMapper {

	/** ① 소송현황 — CASE_KIND_CD별 발생/승/패/계류 (기간=FR_DT·DCSN_DT) */
	List<Map<String, Object>> selectSummary(Map<String, Object> param);

	/** ② 심급별 — INSTANCE_CD별 구분 카운트 (계류 스냅샷) */
	List<Map<String, Object>> selectInstance(Map<String, Object> param);

	/** ③ 유형별 — LAW_CIVIL_CASE 전 코드 × 구분 (계류 스냅샷) */
	List<Map<String, Object>> selectCaseType(Map<String, Object> param);

	/** ④ 부서별 — 전 부서 × 구분 × (변호사/직접) (계류 스냅샷) */
	List<Map<String, Object>> selectDept(Map<String, Object> param);

	/** ⑤-상단 대리인 지정현황 — 변호사(L)/공무원(G) × 구분 (계류 스냅샷) */
	List<Map<String, Object>> selectAgentTop(Map<String, Object> param);

	/** ⑤-하단 대리인별(변호사) — 법무법인/성명별 집계 */
	List<Map<String, Object>> selectAgentByLawyer(Map<String, Object> param);

	/** ⑤-하단 대리인별(공무원) — 부서/성명별 집계 */
	List<Map<String, Object>> selectAgentByOfficial(Map<String, Object> param);

	/** ⑥ 패소원인 — LAW_LOSS_CAUSE 전 코드 건수 (기간=DCSN_DT) */
	List<Map<String, Object>> selectLossCause(Map<String, Object> param);

	/** ⑦ 사건지번 — 지번/소재지·사건번호·사건명 (기간=FR_DT/DCSN_DT + 결과 그룹) */
	List<Map<String, Object>> selectLandJibun(Map<String, Object> param);
}
