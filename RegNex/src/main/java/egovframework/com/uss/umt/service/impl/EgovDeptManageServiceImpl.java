package egovframework.com.uss.umt.service.impl;

import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.springframework.stereotype.Service;

import egovframework.com.uss.umt.service.DeptManageVO;
import egovframework.com.uss.umt.service.EgovDeptManageService;

@Service("egovDeptManageService")
public class EgovDeptManageServiceImpl extends EgovAbstractServiceImpl implements EgovDeptManageService {
	
	@Resource(name="deptManageDAO")
    private DeptManageDAO deptManageDAO;

	/**
	 * 부서를 관리하기 위해 등록된 부서목록을 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return List - 부서 목록
	 * 
	 * @param deptManageVO
	 */
	public List<DeptManageVO> selectDeptManageList(DeptManageVO deptManageVO) throws Exception {
		return deptManageDAO.selectDeptManageList(deptManageVO);
	}

	/**
	 * 부서목록 총 개수를 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return int - 부서 카운트 수
	 * 
	 * @param deptManageVO
	 */
	public int selectDeptManageListTotCnt(DeptManageVO deptManageVO) throws Exception {
		return deptManageDAO.selectDeptManageListTotCnt(deptManageVO);
	}

	/**
	 * 등록된 부서의 상세정보를 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return deptManageVO - 부서 Vo
	 * 
	 * @param deptManageVO
	 */
	public DeptManageVO selectDeptManage(DeptManageVO deptManageVO) throws Exception {
		return deptManageDAO.selectDeptManage(deptManageVO);
	}

	/**
	 * 부서정보를 신규로 등록한다.
	 * @param deptManageVO - 부서 model
	 * 
	 * @param deptManageVO
	 */
	public void insertDeptManage(DeptManageVO deptManageVO) throws Exception {
		deptManageDAO.insertDeptManage(deptManageVO);
	}

	/**
	 * 기 등록된 부서정보를 수정한다.
	 * @param deptManageVO - 부서 model
	 * 
	 * @param deptManageVO
	 */
	public void updateDeptManage(DeptManageVO deptManageVO) throws Exception {
		deptManageDAO.updateDeptManage(deptManageVO);
	}

	/**
	 * 기 등록된 부서정보를 삭제한다.
	 * @param deptManageVO - 부서 model
	 *
	 * @param deptManageVO
	 */
	public void deleteDeptManage(DeptManageVO deptManageVO) throws Exception {
		deptManageDAO.deleteDeptManage(deptManageVO);
	}

	// ══ 트리 전환 (2026-07-27) — 계층(상위부서)·순서 지원. 단수 제한 없음 ══

	public List<DeptManageVO> selectDeptTreeList() throws Exception {
		return deptManageDAO.selectDeptTreeList();
	}

	public void insertDeptTree(DeptManageVO vo) throws Exception {
		normalizeUpper(vo);
		vo.setOrdr(Integer.valueOf(deptManageDAO.selectDeptMaxOrdr(vo) + 1));
		deptManageDAO.insertDeptManage(vo);
	}

	public void updateDeptTree(DeptManageVO vo) throws Exception {
		normalizeUpper(vo);
		DeptManageVO cur = deptManageDAO.selectDeptManage(vo);
		if (cur == null) {
			throw new IllegalStateException("부서를 찾을 수 없습니다: " + vo.getOrgnztId());
		}
		boolean parentChanged = !eq(trim(cur.getUpperOrgnztId()), trim(vo.getUpperOrgnztId()));
		if (parentChanged) {
			assertNoCycle(vo.getOrgnztId(), vo.getUpperOrgnztId());
			vo.setOrdr(Integer.valueOf(deptManageDAO.selectDeptMaxOrdr(vo) + 1));   // 새 부모의 마지막
		} else {
			vo.setOrdr(cur.getOrdr());   // 순서는 ▲▼(reorderDept) 전용 — 여기선 보존
		}
		deptManageDAO.updateDeptTree(vo);
	}

	public void deleteDeptTree(String orgnztId) throws Exception {
		DeptManageVO vo = new DeptManageVO();
		vo.setOrgnztId(orgnztId);
		if (deptManageDAO.selectDeptChildCnt(vo) > 0) {
			throw new IllegalStateException("하위 부서가 있어 삭제할 수 없습니다. 하위 부서를 먼저 이동/삭제하세요.");
		}
		deptManageDAO.deleteDeptManage(vo);
	}

	/** 형제 내 순서 이동 — ORDR 를 1..n 으로 정규화(NULL 잔재 흡수)한 뒤 인접 형제와 교환 */
	public void reorderDept(String orgnztId, String dir) throws Exception {
		DeptManageVO key = new DeptManageVO();
		key.setOrgnztId(orgnztId);
		DeptManageVO cur = deptManageDAO.selectDeptManage(key);
		if (cur == null) {
			throw new IllegalStateException("부서를 찾을 수 없습니다: " + orgnztId);
		}
		DeptManageVO parentKey = new DeptManageVO();
		parentKey.setUpperOrgnztId(trim(cur.getUpperOrgnztId()));
		List<DeptManageVO> siblings = deptManageDAO.selectDeptSiblings(parentKey);

		int idx = -1;
		for (int i = 0; i < siblings.size(); i++) {
			if (eq(trim(siblings.get(i).getOrgnztId()), trim(orgnztId))) {
				idx = i;
				break;
			}
		}
		if (idx < 0) {
			throw new IllegalStateException("형제 목록에서 부서를 찾지 못했습니다: " + orgnztId);
		}
		int swap = "up".equals(dir) ? idx - 1 : idx + 1;
		if (swap < 0 || swap >= siblings.size()) {
			return;   // 이미 처음/마지막 — 변경 없음
		}
		java.util.Collections.swap(siblings, idx, swap);
		for (int i = 0; i < siblings.size(); i++) {   // 1..n 재부여 (NULL ORDR 정규화 겸)
			DeptManageVO s = siblings.get(i);
			Integer want = Integer.valueOf(i + 1);
			if (!want.equals(s.getOrdr())) {
				DeptManageVO u = new DeptManageVO();
				u.setOrgnztId(s.getOrgnztId());
				u.setOrdr(want);
				deptManageDAO.updateDeptOrdr(u);
			}
		}
	}

	/** 상위부서 순환 방지 — 새 부모에서 최상위까지 거슬러 오르며 자기 자신을 만나면 거부 */
	private void assertNoCycle(String orgnztId, String newUpperId) throws Exception {
		String self = trim(orgnztId);
		String cursor = trim(newUpperId);
		int hop = 0;
		while (cursor != null && !cursor.isEmpty()) {
			if (cursor.equals(self)) {
				throw new IllegalStateException("자기 자신 또는 하위 부서 아래로는 이동할 수 없습니다.");
			}
			if (++hop > 100) {   // 데이터 이상(기존 순환) 방어
				throw new IllegalStateException("부서 계층이 순환하고 있습니다. 데이터를 확인하세요.");
			}
			DeptManageVO k = new DeptManageVO();
			k.setOrgnztId(cursor);
			DeptManageVO p = deptManageDAO.selectDeptManage(k);
			cursor = (p == null) ? null : trim(p.getUpperOrgnztId());
		}
	}

	/** 빈 문자열 상위 ID → null (최상위) */
	private static void normalizeUpper(DeptManageVO vo) {
		String u = trim(vo.getUpperOrgnztId());
		vo.setUpperOrgnztId((u == null || u.isEmpty()) ? null : u);
	}

	private static String trim(String s) {
		return s == null ? null : s.trim();
	}

	private static boolean eq(String a, String b) {
		String x = (a == null || a.isEmpty()) ? null : a;
		String y = (b == null || b.isEmpty()) ? null : b;
		return x == null ? y == null : x.equals(y);
	}
}
