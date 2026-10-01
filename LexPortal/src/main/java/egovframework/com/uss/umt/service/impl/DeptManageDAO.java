package egovframework.com.uss.umt.service.impl;

import java.util.List;

import org.springframework.stereotype.Repository;

import egovframework.com.cmm.service.impl.EgovComAbstractDAO;
import egovframework.com.uss.umt.service.DeptManageVO;

@Repository("deptManageDAO")
public class DeptManageDAO extends EgovComAbstractDAO {

	/**
	 * 부서를 관리하기 위해 등록된 부서목록을 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return List - 부서 목록
	 * @exception Exception
	 */
	public List<DeptManageVO> selectDeptManageList(DeptManageVO deptManageVO) throws Exception {
		return selectList("deptManageDAO.selectDeptManageList", deptManageVO);
	}

    /**
	 * 부서목록 총 개수를 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return int - 부서 카운트 수
	 * @exception Exception
	 */
    public int selectDeptManageListTotCnt(DeptManageVO deptManageVO) throws Exception {
        return (Integer)selectOne("deptManageDAO.selectDeptManageListTotCnt", deptManageVO);
    }

	/**
	 * 등록된 부서의 상세정보를 조회한다.
	 * @param deptManageVO - 부서 Vo
	 * @return deptManageVO - 부서 Vo
	 * 
	 * @param bannerVO
	 */
	public DeptManageVO selectDeptManage(DeptManageVO deptManageVO) throws Exception {
		return (DeptManageVO) selectOne("deptManageDAO.selectDeptManage", deptManageVO);
	}

	/**
	 * 부서정보를 신규로 등록한다.
	 * @param deptManageVO - 부서 model
	 */
	public void insertDeptManage(DeptManageVO deptManageVO) throws Exception {
		insert("deptManageDAO.insertDeptManage", deptManageVO);
	}

	/**
	 * 기 등록된 부서정보를 수정한다.
	 * @param deptManageVO - 부서 model
	 */
	public void updateDeptManage(DeptManageVO deptManageVO) throws Exception {
        update("deptManageDAO.updateDeptManage", deptManageVO);
	}

	/**
	 * 기 등록된 부서정보를 삭제한다.
	 * @param deptManageVO - 부서 model
	 *
	 * @param banner
	 */
	public void deleteDeptManage(DeptManageVO deptManageVO) throws Exception {
		delete("deptManageDAO.deleteDeptManage", deptManageVO);
	}

	// ══ 트리 전환 (2026-07-27) — 계층·순서 지원 ══

	/** 전 부서 평면 조회 (트리 조립용, 형제 정렬 포함) */
	public List<DeptManageVO> selectDeptTreeList() throws Exception {
		return selectList("deptManageDAO.selectDeptTreeList");
	}

	/** 하위부서 수 (삭제 가드) */
	public int selectDeptChildCnt(DeptManageVO deptManageVO) throws Exception {
		return (Integer) selectOne("deptManageDAO.selectDeptChildCnt", deptManageVO);
	}

	/** 같은 부모 아래 최대 순서 */
	public int selectDeptMaxOrdr(DeptManageVO deptManageVO) throws Exception {
		return (Integer) selectOne("deptManageDAO.selectDeptMaxOrdr", deptManageVO);
	}

	/** 형제 목록 (순서 재배치용) */
	public List<DeptManageVO> selectDeptSiblings(DeptManageVO deptManageVO) throws Exception {
		return selectList("deptManageDAO.selectDeptSiblings", deptManageVO);
	}

	/** 부서명·설명·상위·순서 일괄 수정 (트리 화면 전용) */
	public void updateDeptTree(DeptManageVO deptManageVO) throws Exception {
		update("deptManageDAO.updateDeptTree", deptManageVO);
	}

	/** 순서만 수정 (재배치 루프) */
	public void updateDeptOrdr(DeptManageVO deptManageVO) throws Exception {
		update("deptManageDAO.updateDeptOrdr", deptManageVO);
	}

}
