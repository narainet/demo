package egovframework.com.uss.umt.service;

import java.util.List;

public interface EgovDeptManageService {

	/**
	 * 부서를 관리하기 위해 등록된 부서목록을 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return List - 부서 목록
	 * 
	 * @param deptManageVO
	 */
	public List<DeptManageVO> selectDeptManageList(DeptManageVO deptManageVO) throws Exception;

	/**
	 * 부서목록 총 개수를 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return int - 부서 카운트 수
	 * 
	 * @param deptManageVO
	 */
	public int selectDeptManageListTotCnt(DeptManageVO deptManageVO) throws Exception;
	
	/**
	 * 등록된 부서의 상세정보를 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return deptManageVO - 부서 Vo
	 * 
	 * @param deptManageVO
	 */
	public DeptManageVO selectDeptManage(DeptManageVO deptManageVO) throws Exception;

	/**
	 * 부서정보를 신규로 등록한다.
	 * @param deptManageVO - 부서 model
	 * 
	 * @param deptManageVO
	 */
	public void insertDeptManage(DeptManageVO deptManageVO) throws Exception;

	/**
	 * 기 등록된 부서정보를 수정한다.
	 * @param deptManageVO - 부서 model
	 * 
	 * @param deptManageVO
	 */
	public void updateDeptManage(DeptManageVO deptManageVO) throws Exception;

	/**
	 * 기 등록된 부서정보를 삭제한다.
	 * @param deptManageVO - 부서 model
	 *
	 * @param deptManageVO
	 */
	public void deleteDeptManage(DeptManageVO deptManageVO) throws Exception;

	// ══ 트리 전환 (2026-07-27) — 계층(상위부서)·순서 지원. 단수 제한 없음(3단·4단 …) ══

	/** 전 부서 평면 조회 (형제 정렬 포함) — 트리 JSON 조립용 */
	public List<DeptManageVO> selectDeptTreeList() throws Exception;

	/** 트리 신규 등록 — 순서는 같은 부모의 마지막(max+1) 자동 배정 */
	public void insertDeptTree(DeptManageVO deptManageVO) throws Exception;

	/** 트리 수정 — 상위부서 변경 시 순환(자기 후손 아래로 이동) 거부 + 새 부모 마지막 순서 배정 */
	public void updateDeptTree(DeptManageVO deptManageVO) throws Exception;

	/** 트리 삭제 — 하위부서가 있으면 거부 */
	public void deleteDeptTree(String orgnztId) throws Exception;

	/** 형제 내 순서 이동 (dir=up|down) — ORDR 를 1..n 정규화 후 인접 형제와 교환 */
	public void reorderDept(String orgnztId, String dir) throws Exception;
}
