package egovframework.com.sym.prm.service.impl;

import java.util.List;

import org.springframework.stereotype.Repository;

import egovframework.com.cmm.ComDefaultVO;
import egovframework.com.cmm.service.impl.EgovComAbstractDAO;
import egovframework.com.sym.prm.service.ProgrmManageVO;
/**
 * 프로그램 목록관리및 프로그램변경관리에 대한 DAO 클래스를 정의한다.
 * @author 개발환경 개발팀 이용
 * @since 2009.06.01
 * @version 1.0
 * @see
 *
 * <pre>
 * << 개정이력(Modification Information) >>
 *
 *   수정일      수정자           수정내용
 *  -------    --------    ---------------------------
 *   2009.03.20  이  용          최초 생성
 *
 * </pre>
 */

@Repository("progrmManageDAO")
public class ProgrmManageDAO extends EgovComAbstractDAO {

	/**
     * 프로그램 목록을 조회
     * 
     * @param vo ComDefaultVO
     * @return List
     * @exception Exception
     */
    public List<ProgrmManageVO> selectProgrmList(ComDefaultVO vo) throws Exception {
        return selectList("progrmManageDAO.selectProgrmList_D", vo);
    }

    /**
	 * 프로그램목록 총건수를 조회한다.
	 * @param vo ComDefaultVO
	 * @return int
	 * @exception Exception
	 */
    public int selectProgrmListTotCnt(ComDefaultVO vo) {
        return (Integer)selectOne("progrmManageDAO.selectProgrmListTotCnt_S", vo);
    }

	/**
	 * 프로그램 기본정보를 조회
	 * @param vo ComDefaultVO
	 * @return ProgrmManageVO
	 * @exception Exception
	 */
	public ProgrmManageVO selectProgrm(ProgrmManageVO vo)throws Exception{
		return (ProgrmManageVO)selectOne("progrmManageDAO.selectProgrm_D", vo);
	}

	/**
	 * 프로그램 기본정보 및 URL을 등록
	 * @param vo ProgrmManageVO
	 * @exception Exception
	 */
	public void insertProgrm(ProgrmManageVO vo){
		insert("progrmManageDAO.insertProgrm_S", vo);
	}

	/**
	 * 프로그램 기본정보 및 URL을 수정
	 * @param vo ProgrmManageVO
	 * @exception Exception
	 */
	public void updateProgrm(ProgrmManageVO vo){
		update("progrmManageDAO.updateProgrm_S", vo);
	}

	/**
	 * 프로그램 기본정보 및 URL을 삭제
	 * @param vo ProgrmManageVO
	 * @exception Exception
	 */
	public void deleteProgrm(ProgrmManageVO vo){
		delete("progrmManageDAO.deleteProgrm_S", vo);
	}

	/**
	 * 프로그램 파일 존재여부를 조회
	 * @param vo ProgrmManageVO
	 * @return int
	 * @exception Exception
	 */
	public int selectProgrmNMTotCnt(ComDefaultVO vo) throws Exception{
		return (Integer)selectOne("progrmManageDAO.selectProgrmNMTotCnt", vo);
	}


	/**
	 * 프로그램목록 전체삭제 초기화
	 * @return boolean
	 * @exception Exception
	 */
	public boolean deleteAllProgrm(){
		ProgrmManageVO vo = new ProgrmManageVO();
		update("progrmManageDAO.deleteAllProgrm", vo);
		return true;
	}

    /**
	 * 프로그램목록 데이타 존재여부 조회한다.
	 * @return int
	 * @exception Exception
	 */
    public int selectProgrmListTotCnt() {
    	ProgrmManageVO vo = new ProgrmManageVO();
        return (Integer)selectOne("progrmManageDAO.selectProgrmListTotCnt", vo);
    }
}