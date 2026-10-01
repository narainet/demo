/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prommap/service/impl/PromMapServiceImpl.java
 *
 * 기능별분류(규정맵) Service 구현. 레거시 PromulgationMapController 비즈니스 로직 이관.
 *  - PK 채번: egovPromMapIdGnrService (COMTECOPSEQ.PMAP_ID)
 *  - 재귀 임포트(분류 트리 미러) / BFS 서브트리 삭제 / 노드명 변경 / front 규정목록.
 */
package narainet.rlms.prommap.service.impl;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.cate.mapper.CateMapper;
import narainet.rlms.cate.service.CateVO;
import narainet.rlms.prom.service.PromService;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prommap.mapper.PromMapMapper;
import narainet.rlms.prommap.service.PromMapService;
import narainet.rlms.prommap.service.PromMapVO;

@Service("promMapService")
public class PromMapServiceImpl implements PromMapService {

	/** BFS/재귀 안전 상한 — 무한루프(순환 참조) 방어 */
	private static final int SAFETY_CAP = 100000;

	@Resource private PromMapMapper promMapMapper;
	@Resource private CateMapper    cateMapper;
	@Resource private PromService   promService;
	/** 분류별 열람제한 게이트 (front 규정목록) */
	@Resource private narainet.rlms.prom.service.PromReadGuard promReadGuard;
	@Resource(name = "egovPromMapIdGnrService") private EgovIdGnrService pmapIdGnrService;

	@Override
	public List<PromMapVO> selectMapTree(String sysId) {
		return promMapMapper.selectMapTree(sysId);   // 단일 시스템 — selectMapTree 는 sysId 미사용(전체 트리)
	}

	@Override
	public List<PromMapVO> selectPromulgationList(Long pmapNo) {
		// 분류별 열람제한(TB_CATE_READER) — 면제역할(ADMIN/EDITOR/APPROVER)이면 게이트 미적용
		return promMapMapper.selectPromulgationList(pmapNo,
				promReadGuard.gateNeeded(), promReadGuard.readerEsntlId(), promReadGuard.readerOrgnztId());
	}

	// ── 분류 가져오기 (재귀 미러) ───────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void importCategory(Long cateNo, Long refPmapNo, String sysId) throws Exception {
		// SSYS_ID 강제 안 함(단일 시스템 — 미전송 시 null 저장, 필터 미사용)
		CateVO cate = cateMapper.selectCateByNo(cateNo);
		if (cate == null) throw new IllegalArgumentException("분류를 찾을 수 없습니다: " + cateNo);

		int rootLevel;
		Long parentRef;
		if (refPmapNo == null || refPmapNo == 0L) {
			rootLevel = 0;
			parentRef = 0L;
		} else {
			PromMapVO parent = promMapMapper.selectByNo(refPmapNo);
			if (parent == null) throw new IllegalArgumentException("대상 폴더를 찾을 수 없습니다: " + refPmapNo);
			rootLevel = (parent.getLevel() == null ? 0 : parent.getLevel()) + 1;
			parentRef = refPmapNo;
		}
		int seq = promMapMapper.selectMaxSeq(parentRef, sysId);
		importCategoryTree(cate, parentRef, rootLevel, seq, sysId, new int[]{0});
	}

	/** 한 분류를 폴더로 만들고, 그 직속 규정(leaf) + 하위분류(재귀)를 미러한다. */
	private void importCategoryTree(CateVO cate, Long parentRef, int level, int seq,
			String sysId, int[] counter) throws Exception {
		if (++counter[0] > SAFETY_CAP) throw new IllegalStateException("분류 깊이/개수 상한 초과(순환 의심)");

		String fullName = (cate.getFullNm() != null && !cate.getFullNm().trim().isEmpty())
				? cate.getFullNm().trim() : cateMapper.selectFullNameByNo(cate.getCateNo());
		if (fullName == null) fullName = cate.getCateNm();

		// 1) 이 분류 폴더 노드
		PromMapVO folder = newNode(sysId, cate.getCateNm(), fullName, "N", level, parentRef, seq, 0L);
		promMapMapper.insertMap(folder);

		// 2) 직속 현행 규정 → leaf (seq 1..N)
		List<Map<String, Object>> proms = promMapMapper.selectExistingPromsByCate(cate.getCateNo());
		int s = 0;
		for (Map<String, Object> p : proms) {
			Long promNo = toLong(p.get("promNo"));
			String title = p.get("title") != null ? p.get("title").toString() : "";
			if (promNo == null) continue;
			s++;
			PromMapVO leaf = newNode(sysId, title, fullName + " > " + title, "Y",
					level + 1, folder.getPmapNo(), s, promNo);
			promMapMapper.insertMap(leaf);
		}

		// 3) 하위 분류 → 재귀 (seq = 규정수 + k)
		List<CateVO> children = cateMapper.selectChildren(cate.getCateNo(), sysId);
		int k = 0;
		for (CateVO child : children) {
			k++;
			importCategoryTree(child, folder.getPmapNo(), level + 1, proms.size() + k, sysId, counter);
		}
	}

	// ── 규정 1건 가져오기 ───────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void addPromLeaf(Long promNo, Long refPmapNo, String sysId) throws Exception {
		// SSYS_ID 강제 안 함(단일 시스템 — 미전송 시 null 저장, 필터 미사용)
		if (refPmapNo == null || refPmapNo == 0L)
			throw new IllegalArgumentException("규정을 추가할 폴더를 먼저 선택하세요.");
		PromMapVO parent = promMapMapper.selectByNo(refPmapNo);
		if (parent == null) throw new IllegalArgumentException("대상 폴더를 찾을 수 없습니다: " + refPmapNo);

		PromVO prom = promService.selectPromDetail(promNo);
		if (prom == null) throw new IllegalArgumentException("규정을 찾을 수 없습니다: " + promNo);

		String cateFull = null;
		if (prom.getCateNo() != null) {
			CateVO cate = cateMapper.selectCateByNo(prom.getCateNo());
			if (cate != null) cateFull = (cate.getFullNm() != null && !cate.getFullNm().trim().isEmpty())
					? cate.getFullNm().trim() : cateMapper.selectFullNameByNo(cate.getCateNo());
		}
		String title = prom.getTitle() != null ? prom.getTitle() : "";
		String fullName = (cateFull != null ? cateFull + " > " : "") + title;
		int seq = promMapMapper.selectMaxSeq(refPmapNo, sysId);
		int level = (parent.getLevel() == null ? 0 : parent.getLevel()) + 1;

		PromMapVO leaf = newNode(sysId, title, fullName, "Y", level, refPmapNo, seq, promNo);
		promMapMapper.insertMap(leaf);
	}

	// ── 이름변경 / 삭제 ─────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void renameMap(Long pmapNo, String name) throws Exception {
		if (name == null || name.trim().isEmpty()) throw new IllegalArgumentException("분류명을 입력하세요.");
		promMapMapper.updateMapName(pmapNo, name.trim());
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int deleteMapSubtree(Long pmapNo) throws Exception {
		PromMapVO node = promMapMapper.selectByNo(pmapNo);
		if (node == null) return 0;
		String sysId = node.getSysId();   // 단일 시스템 — null 허용(필터 미사용)

		// BFS 로 노드 + 모든 하위 수집
		List<Long> toDelete = new ArrayList<>();
		Deque<Long> queue = new ArrayDeque<>();
		queue.add(pmapNo);
		int guard = 0;
		while (!queue.isEmpty()) {
			if (++guard > SAFETY_CAP) throw new IllegalStateException("하위 노드 상한 초과(순환 의심)");
			Long cur = queue.poll();
			toDelete.add(cur);
			for (PromMapVO child : promMapMapper.selectChildrenByRef(cur, sysId)) {
				queue.add(child.getPmapNo());
			}
		}
		int n = 0;
		for (Long id : toDelete) n += promMapMapper.deleteMap(id);
		return n;
	}

	@Override
	public int cleanupByPromNo(Long promNo) {
		if (promNo == null) return 0;
		try {
			return promMapMapper.deleteMapByPromNo(promNo);
		} catch (Exception e) {
			return 0;   // 연동 정리 실패는 본 삭제를 막지 않음
		}
	}

	// ── 헬퍼 ─────────────────────────────────────────────────────────

	private PromMapVO newNode(String sysId, String name, String fullName, String promYn,
			int level, Long ref, int seq, Long promNo) throws Exception {
		PromMapVO vo = new PromMapVO();
		vo.setPmapNo(pmapIdGnrService.getNextLongId());
		vo.setSysId(sysId);
		vo.setName(name);
		vo.setFullName(fullName);
		vo.setPromYn(promYn);
		vo.setLevel(level);
		vo.setRef(ref);
		vo.setDispYn("Y");
		vo.setSeq(seq);
		vo.setPromNo(promNo == null ? 0L : promNo);
		return vo;
	}

	private Long toLong(Object o) {
		if (o == null) return null;
		if (o instanceof Number) return ((Number) o).longValue();
		try { return Long.valueOf(o.toString().trim()); } catch (NumberFormatException e) { return null; }
	}
}
