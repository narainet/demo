/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/common/service/FtGubunService.java
 *
 * 분류구분(SGUBUN) 라벨 제공 — 정본 = eGov 표준 공통코드 ccm
 *   (COMTCCMMNDETAILCODE, CODE_ID='SGUBUN'). 레거시 TB_CODE 는 사용 중단(2026-07-09).
 *
 * 검색폼/홈의 구분 체크박스를 하드코딩 대신 이 리스트로 렌더하면
 * 공통코드 관리화면(/sym/ccm/cca) 편집이 전 화면에 즉시 반영된다.
 *
 *  - 표시(USE_AT='Y') 구분 전체 노출 — 신설 구분(FT_GUBUN_6+)도 자동 포함(2026-07-10 동적화).
 *  - 검색 필터 파라미터 = gubunIds (SGUBUN_ID 코드 그대로, 옛 gubun1~5=TRUE 폐기).
 *  - 각 항목: { code:'FT_GUBUN_5', label:'법령' }  (정렬 = CODE_DC 순)
 */
package narainet.rlms.common.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import narainet.rlms.common.mapper.CmmnCodeMapper;

@Service("ftGubunService")
public class FtGubunService {

	/** ccm 그룹 코드 — 구분(법령/사규/...) 라벨·순서의 단일 정본 */
	private static final String SGUBUN_CODE_ID = "SGUBUN";

	@Resource(name = "cmmnCodeMapper")
	private CmmnCodeMapper cmmnCodeMapper;

	/**
	 * 검색/홈에서 쓸 구분 체크박스 목록 — 표시(USE_AT='Y') 구분 전체.
	 * 각 항목: { code:'FT_GUBUN_N', label } — code = 체크박스 value·counts/label 맵 키.
	 */
	public List<Map<String, Object>> gubunList() {
		List<Map<String, Object>> codes = cmmnCodeMapper.selectCmmnCodeList(SGUBUN_CODE_ID);   // USE_AT='Y', CODE_DC 순
		List<Map<String, Object>> out = new ArrayList<>();
		if (codes == null) {
			return out;
		}
		for (Map<String, Object> c : codes) {
			Object codeObj = c.get("code");
			if (codeObj == null) {
				continue;
			}
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("code", String.valueOf(codeObj));
			m.put("label", c.get("codeNm"));
			out.add(m);
		}
		return out;
	}
}
