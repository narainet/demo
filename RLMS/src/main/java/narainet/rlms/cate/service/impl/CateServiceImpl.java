/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/cate/service/impl/CateServiceImpl.java
 *
 * 법령 분류 Service 구현체.
 *
 * 핵심 동작:
 *   - 신규: 부모(ref) 기준으로 level / refLv1~10 / seq 자동 계산
 *   - 삭제: TRG_DEL_CATE 가 법령(TB_PROM) 까지 cascade 삭제하므로
 *           반드시 법령/하위카테 0건일 때만 허용. 그 외에는 예외.
 *   - 트리: CateMapper.selectCateTree (CONNECT BY) 한 방 결과를 받아
 *           jsTree 호환 형태(부모 id 참조) 로 변환.
 */
package narainet.rlms.cate.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.cate.mapper.CateMapper;
import narainet.rlms.cate.service.CateService;
import narainet.rlms.cate.service.CateVO;
import narainet.rlms.common.mapper.CmmnCodeMapper;

/**
 * 분류 트리 Service 구현체
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Service("cateService")
public class CateServiceImpl extends EgovAbstractServiceImpl implements CateService {

	private static final String DEFAULT_SYS_ID = "DEFAULT";
	private static final String SGUBUN_CODE_ID = "SGUBUN";
	private static final String GUBUN_NODE_PREFIX = "gubun:";

	@Resource(name = "cateMapper")
	private CateMapper cateMapper;

	@Resource
	private CmmnCodeMapper cmmnCodeMapper;

	@Resource(name = "egovCateIdGnrService")
	private EgovIdGnrService cateIdGnrService;

	// ────────────────────────────────────────────────────────────────
	// 조회
	// ────────────────────────────────────────────────────────────────

	@Override
	public Map<String, Object> selectCateTree(String sysId) {
		List<CateVO> list = selectDisplayTreeList(sysId);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(list.size()));
		return map;
	}

	@Override
	public List<Map<String, Object>> selectCateTreeForJsTree(String sysId, boolean includeHidden) {
		// 카운트 게이트: 관리 화면(includeHidden=분류관리)만 원본 카운트(삭제 차단 판정과 동일 기준),
		// 그 외(front 검색 필터트리)는 사용자 목록과 같은 현행 정의(표시+폐지일)로 집계 — 배지=목록 건수
		List<CateVO> list = cateMapper.selectCateTree(trimToNull(sysId), !includeHidden);
		return buildGroupedTreeForJsTree(list, includeHidden);
	}

	private List<Map<String, Object>> buildGroupedTreeForJsTree(List<CateVO> list, boolean includeHidden) {
		Map<String, Map<String, String>> gubunInfos = loadGubunInfos();
		// 숨김 구분(USE_AT='N') — 분류관리(includeHidden)만 표시, 그 외엔 구분·소속 분류 통째 제외(2026-07-09)
		java.util.Set<String> hiddenGubuns = new java.util.HashSet<>();
		for (Map.Entry<String, Map<String, String>> entry : gubunInfos.entrySet()) {
			if ("N".equals(entry.getValue().get("useAt"))) hiddenGubuns.add(entry.getKey());
		}
		Map<String, Map<String, Object>> gubunNodes = new LinkedHashMap<>();
		for (Map.Entry<String, Map<String, String>> entry : gubunInfos.entrySet()) {
			if (!includeHidden && hiddenGubuns.contains(entry.getKey())) continue;
			Map<String, String> info = entry.getValue();
			gubunNodes.put(entry.getKey(),
					newGubunNode(entry.getKey(), info.get("codeNm"), info.get("codeDc"), info.get("useAt")));
		}

		List<Map<String, Object>> cateNodes = new ArrayList<>();
		for (CateVO v : list) {
			if (!includeHidden && v.getGubunId() != null && hiddenGubuns.contains(v.getGubunId())) {
				continue;   // 숨김 구분 소속 분류 — 폴백(ensureGubunNode) 재생성 경로까지 차단
			}
			Map<String, Object> n = new HashMap<>();
			n.put("id", "cate_" + v.getCateNo());
			if (v.getRef() == null || v.getRef() == 0L) {
				String gubunId = normalizeGubunId(v.getGubunId());
				ensureGubunNode(gubunNodes, gubunInfos, gubunId);
				n.put("parent", GUBUN_NODE_PREFIX + gubunId);
			} else {
				n.put("parent", "cate_" + v.getRef());
			}
			n.put("text", v.getCateNm()
					+ (v.getPromCnt() != null && v.getPromCnt() > 0
							? " (" + v.getPromCnt() + ")" : ""));
			Map<String, Object> data = new HashMap<>();
			data.put("cateNo", v.getCateNo());
			data.put("cateNm", v.getCateNm());
			data.put("gubunId", v.getGubunId());
			data.put("fullNm", v.getFullNm());
			data.put("level", v.getLevel());
			data.put("ref", v.getRef());
			data.put("dispYn", v.getDispYn());
			data.put("seq", v.getSeq());
			data.put("sysId", v.getSysId());
			data.put("promCnt", v.getPromCnt());
			data.put("childCnt", v.getChildCnt());
			n.put("data", data);
			cateNodes.add(n);
		}

		List<Map<String, Object>> result = new ArrayList<>();
		for (Map.Entry<String, Map<String, Object>> entry : gubunNodes.entrySet()) {
			result.add(entry.getValue());
		}
		result.addAll(cateNodes);
		return result;
	}

	/** 구분 그룹 라벨/순서 — 정본 = ccm 'SGUBUN' (순서 = CODE_DC '01_/02_/...' prefix). 레거시 TB_CODE 미사용.
	 *  ★분류관리 트리는 숨김(USE_AT='N') 구분도 표시(유일한 복구 입구) — 전체 조회 + useAt 동봉(2026-07-09). */
	private Map<String, Map<String, String>> loadGubunInfos() {
		Map<String, Map<String, String>> infos = new LinkedHashMap<>();
		try {
			List<Map<String, Object>> rows = cmmnCodeMapper.selectCmmnCodeListAll(SGUBUN_CODE_ID);
			for (Map<String, Object> row : rows) {
				String code = (String) row.get("code");
				String codeNm = (String) row.get("codeNm");
				String codeDc = (String) row.get("codeDc");
				String useAt = (String) row.get("useAt");
				if (!isBlank(code)) {
					Map<String, String> info = new HashMap<>();
					info.put("codeNm", isBlank(codeNm) ? code : codeNm);
					info.put("codeDc", codeDc);
					info.put("useAt", "N".equals(useAt) ? "N" : "Y");
					infos.put(code, info);
				}
			}
		} catch (Exception e) {
			infos.clear();
		}
		return infos;
	}

	private void ensureGubunNode(Map<String, Map<String, Object>> gubunNodes,
			Map<String, Map<String, String>> gubunInfos, String gubunId) {
		if (!gubunNodes.containsKey(gubunId)) {
			Map<String, String> info = gubunInfos.get(gubunId);
			String label = info == null ? gubunId : info.get("codeNm");
			String codeDc = info == null ? null : info.get("codeDc");
			String useAt = info == null ? "Y" : info.get("useAt");
			gubunNodes.put(gubunId, newGubunNode(gubunId, label, codeDc, useAt));
		}
	}

	private Map<String, Object> newGubunNode(String gubunId, String label, String codeDc, String useAt) {
		boolean hidden = "N".equals(useAt);
		Map<String, Object> node = new HashMap<>();
		node.put("id", GUBUN_NODE_PREFIX + gubunId);
		node.put("parent", "#");
		node.put("text", hidden ? label + " — 숨김" : label);   // 숨김 구분은 이 화면에서만 보임(복구 입구)
		node.put("type", "gubun");
		Map<String, Object> data = new HashMap<>();
		data.put("nodeType", "gubun");
		data.put("gubunId", gubunId);
		data.put("gubunNm", label);
		data.put("codeDc", codeDc);
		data.put("useAt", hidden ? "N" : "Y");
		node.put("data", data);
		Map<String, Object> state = new HashMap<>();
		state.put("opened", false);
		node.put("state", state);
		return node;
	}

	private String normalizeGubunId(String gubunId) {
		String value = trimToNull(gubunId);
		return value == null ? "_NULL_" : value;
	}

	private List<CateVO> selectDisplayTreeList(String sysId) {
		String targetSysId = trimToNull(sysId);
		List<CateVO> list = cateMapper.selectCateTree(targetSysId, false);
		if (targetSysId != null) {
			return list;
		}
		List<CateVO> roots = new ArrayList<>();
		for (CateVO cate : list) {
			if (cate.getRef() == null || cate.getRef() == 0L) {
				roots.add(cate);
			}
		}
		return roots;
	}

	@Override
	public CateVO selectCateByNo(Long cateNo) {
		return cateMapper.selectCateByNo(cateNo);
	}

	@Override
	public String selectFullNameByNo(Long cateNo) {
		return cateMapper.selectFullNameByNo(cateNo);
	}

	// ────────────────────────────────────────────────────────────────
	// 등록
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void insertCate(CateVO vo) throws Exception {
		normalizeForSave(vo);
		// 1) 부모 정보로부터 level / refLv 자동 계산
		Long parentNo = (vo.getRef() == null) ? 0L : vo.getRef();
		CateVO parent = null;
		if (parentNo == 0L) {
			if (isBlank(vo.getGubunId())) {
				throw processException("cate.gubun.required");
			}
			vo.setLevel(0);
			zeroRefLv(vo);
		} else {
			parent = cateMapper.selectCateByNo(parentNo);
			if (parent == null) {
				throw processException("cate.parent.notfound");
			}
			vo.setSysId(parent.getSysId() == null ? DEFAULT_SYS_ID : parent.getSysId());
			vo.setGubunId(parent.getGubunId());
			vo.setLevel(parent.getLevel() == null ? 1 : parent.getLevel() + 1);
			copyRefLvFromParent(vo, parent, parentNo);
		}

		// 2) 정렬순서
		if (vo.getSeq() == null) {
			vo.setSeq(cateMapper.selectMaxSeq(parentNo, vo.getSysId()));
		}

		// 3) PK 채번
		vo.setCateNo(nextCateNo());

		// 4) fullNm 미입력 시 단순 조립 (정확한 풀네임은 Oracle 함수 호출이 표준)
		if (vo.getFullNm() == null || vo.getFullNm().isEmpty()) {
			if (parentNo == 0L) {
				vo.setFullNm(vo.getCateNm());
			} else {
				String parentFull = parent == null ? null : parent.getFullNm();
				vo.setFullNm((parentFull == null || parentFull.length() == 0)
						? vo.getCateNm() : parentFull + " > " + vo.getCateNm());
			}
		}

		cateMapper.insertCate(vo);
	}

	// ────────────────────────────────────────────────────────────────
	// 수정 / 일괄 수정
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateCate(CateVO vo) throws Exception {
		normalizeForSave(vo);
		CateVO target = cateMapper.selectCateByNo(vo.getCateNo());
		if (target == null) {
			throw processException("cate.notfound");
		}
		// ref 가 변경된 경우 — 부모 재배치는 별도 정책 필요 (refLv1~10 재계산)
		// 본 메서드는 보수적으로 ref/level/refLv 는 기존 값 유지하고, 이름/표시/정렬만 갱신.
		vo.setRef(target.getRef());
		vo.setLevel(target.getLevel());
		vo.setRefLv1(target.getRefLv1());
		vo.setRefLv2(target.getRefLv2());
		vo.setRefLv3(target.getRefLv3());
		vo.setRefLv4(target.getRefLv4());
		vo.setRefLv5(target.getRefLv5());
		vo.setRefLv6(target.getRefLv6());
		vo.setRefLv7(target.getRefLv7());
		vo.setRefLv8(target.getRefLv8());
		vo.setRefLv9(target.getRefLv9());
		vo.setRefLv10(target.getRefLv10());
		vo.setSysId(target.getSysId());
		vo.setGubunId(target.getGubunId());
		if (vo.getSeq() == null) {
			vo.setSeq(target.getSeq());
		}
		vo.setFullNm(buildFullName(vo.getRef(), vo.getCateNm()));
		cateMapper.updateCate(vo);
		refreshDescendantFullNames(vo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateCateList(List<CateVO> list) throws Exception {
		if (list == null || list.isEmpty()) return;
		for (CateVO vo : list) {
			updateCate(vo);
		}
	}

	// ────────────────────────────────────────────────────────────────
	// 삭제 (운영 안전 — TRG_DEL_CATE cascade 위험 회피)
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteCate(Long cateNo) throws Exception {
		CateVO target = cateMapper.selectCateByNo(cateNo);
		if (target == null) {
			throw processException("cate.notfound");
		}
		// 법령 종속 차단
		if (cateMapper.selectPromCntByCate(cateNo) > 0) {
			throw processException("cate.cannot.delete.has.proms");
		}
		// 하위 분류 차단
		if (cateMapper.selectChildCntByCate(cateNo) > 0) {
			throw processException("cate.cannot.delete.has.children");
		}
		// 소프트 삭제만 (실 DELETE 하면 트리거가 cascade)
		cateMapper.updateCateDeleted(cateNo);
	}

	// ────────────────────────────────────────────────────────────────
	// helpers
	// ────────────────────────────────────────────────────────────────

	private static void zeroRefLv(CateVO vo) {
		vo.setRefLv1(0L); vo.setRefLv2(0L); vo.setRefLv3(0L);
		vo.setRefLv4(0L); vo.setRefLv5(0L); vo.setRefLv6(0L);
		vo.setRefLv7(0L); vo.setRefLv8(0L); vo.setRefLv9(0L); vo.setRefLv10(0L);
	}

	private void normalizeForSave(CateVO vo) throws Exception {
		if (vo == null) {
			throw processException("cate.invalid.request");
		}
		vo.setSysId(trimToNull(vo.getSysId()));
		if (vo.getSysId() == null) {
			vo.setSysId(DEFAULT_SYS_ID);
		}
		vo.setCateNm(trimToNull(vo.getCateNm()));
		if (vo.getCateNm() == null) {
			throw processException("cate.name.required");
		}
		vo.setGubunId(trimToNull(vo.getGubunId()));
		vo.setFullNm(trimToNull(vo.getFullNm()));
		if (!"N".equals(vo.getDispYn())) {
			vo.setDispYn("Y");
		}
	}

	private String buildFullName(Long parentNo, String cateNm) {
		if (parentNo == null || parentNo == 0L) {
			return cateNm;
		}
		CateVO parent = cateMapper.selectCateByNo(parentNo);
		String parentFull = parent == null ? null : parent.getFullNm();
		return (parentFull == null || parentFull.length() == 0)
				? cateNm : parentFull + " > " + cateNm;
	}

	private void refreshDescendantFullNames(CateVO root) {
		List<CateVO> descendants = cateMapper.selectDescendants(root.getCateNo(), root.getSysId());
		if (descendants == null || descendants.isEmpty()) {
			return;
		}
		Map<Long, String> fullNameByCateNo = new HashMap<>();
		fullNameByCateNo.put(root.getCateNo(), root.getFullNm());
		for (CateVO child : descendants) {
			String parentFull = fullNameByCateNo.get(child.getRef());
			if (parentFull == null) {
				CateVO parent = cateMapper.selectCateByNo(child.getRef());
				parentFull = parent == null ? null : parent.getFullNm();
			}
			child.setFullNm((parentFull == null || parentFull.length() == 0)
					? child.getCateNm() : parentFull + " > " + child.getCateNm());
			fullNameByCateNo.put(child.getCateNo(), child.getFullNm());
			cateMapper.updateCate(child);
		}
	}

	private Long nextCateNo() throws Exception {
		Long generatedNo = cateIdGnrService.getNextLongId();
		Long maxCateNo = cateMapper.selectMaxCateNo();
		if (maxCateNo == null) {
			return generatedNo;
		}
		return generatedNo != null && generatedNo > maxCateNo ? generatedNo : maxCateNo + 1L;
	}

	private static String trimToNull(String value) {
		if (value == null) {
			return null;
		}
		String trimmed = value.trim();
		return trimmed.length() == 0 ? null : trimmed;
	}

	private static boolean isBlank(String value) {
		return value == null || value.trim().length() == 0;
	}

	/**
	 * 부모의 refLv1~10 을 그대로 받고, 부모의 위치에 부모 cateNo 를 채워 자식 경로를 만든다.
	 * 부모 level 이 N 이면 자식의 refLv(N+1) = parentNo.
	 */
	private static void copyRefLvFromParent(CateVO child, CateVO parent, Long parentNo) {
		Long[] pp = {
				safeLong(parent.getRefLv1()), safeLong(parent.getRefLv2()),
				safeLong(parent.getRefLv3()), safeLong(parent.getRefLv4()),
				safeLong(parent.getRefLv5()), safeLong(parent.getRefLv6()),
				safeLong(parent.getRefLv7()), safeLong(parent.getRefLv8()),
				safeLong(parent.getRefLv9()), safeLong(parent.getRefLv10())
		};
		int parentLevel = parent.getLevel() == null ? 0 : parent.getLevel();
		if (parentLevel < 10) {
			pp[parentLevel] = parentNo;
		}
		child.setRefLv1(pp[0]); child.setRefLv2(pp[1]); child.setRefLv3(pp[2]);
		child.setRefLv4(pp[3]); child.setRefLv5(pp[4]); child.setRefLv6(pp[5]);
		child.setRefLv7(pp[6]); child.setRefLv8(pp[7]); child.setRefLv9(pp[8]);
		child.setRefLv10(pp[9]);
	}

	private static Long safeLong(Long v) { return v == null ? 0L : v; }
}
