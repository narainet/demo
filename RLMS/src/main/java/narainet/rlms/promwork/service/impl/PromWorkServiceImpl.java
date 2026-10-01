/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/promwork/service/impl/PromWorkServiceImpl.java
 *
 * 법령 승인 워크플로 Service 구현체.
 *
 * 상태 전이 정책 (레거시 PromulgationType 정본 문자열 — 운영 TB_PROM_WRK 실데이터 호환):
 *   PromServiceImpl.insertProm  → createInitialWork()        : 편집중           row (C_STATUS_TYPE_1)
 *   사용자 신청                 → requestApproval()          : 승인요청          row + ACT_LOG (TYPE_2)
 *   관리자 승인                 → approveRequest()           : 승인완료          row + TB_PROM.SEXISTING_YN='Y' + ACT_LOG (TYPE_4)
 *   관리자 반려                 → rejectRequest()            : 승인반려          row + ACT_LOG (TYPE_3)
 *
 *   ※ 수정권한 계열(TYPE_5~9 — 수정권한요청/승인/반려/수정완료) 폐지 (2026-07-20 사용자 결정):
 *      현행 회차 편집 = 작성권한(분류 작성자/소관부서) 가드만으로 허용. 과거 상태 어휘는 이력 표시 호환.
 *   ※ 상태 전이마다 새 row INSERT (레거시 동작과 동일) — 워크 row 누적 = 이력
 */
package narainet.rlms.promwork.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.gaejung.mapper.GaejungMapper;
import narainet.rlms.gaejung.service.GaejungVO;
import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.promwork.mapper.PromWorkMapper;
import narainet.rlms.promwork.service.PromWorkActLogVO;
import narainet.rlms.promwork.service.PromWorkService;
import narainet.rlms.promwork.service.PromWorkVO;

@Service("promWorkService")
public class PromWorkServiceImpl extends EgovAbstractServiceImpl implements PromWorkService {

	private static final String REF_TABLE = "TB_PROM_WRK";

	@Resource(name = "promWorkMapper")
	private PromWorkMapper promWorkMapper;

	@Resource(name = "promMapper")
	private PromMapper promMapper;

	@Resource(name = "gaejungMapper")
	private GaejungMapper gaejungMapper;

	@Resource(name = "egovPromWorkIdGnrService")
	private EgovIdGnrService promWorkIdGnrService;

	@Resource(name = "egovPromActLogIdGnrService")
	private EgovIdGnrService promActLogIdGnrService;

	// ────────────────────────────────────────────────────────────────
	// 조회
	// ────────────────────────────────────────────────────────────────

	@Override
	public Map<String, Object> selectPromWorkList(PromWorkVO vo) {
		List<PromWorkVO> list = promWorkMapper.selectPromWorkList(vo);
		int cnt = promWorkMapper.selectPromWorkListCnt(vo);

		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public Map<String, Object> selectActLogList(PromWorkActLogVO vo) {
		List<PromWorkActLogVO> list = promWorkMapper.selectActLogList(vo);
		int cnt = promWorkMapper.selectActLogListCnt(vo);

		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public PromWorkVO selectPromWorkDetail(Long workNo) {
		return promWorkMapper.selectPromWorkByNo(workNo);
	}

	@Override
	public PromWorkVO selectLatestByPromNo(Long promNo) {
		return promWorkMapper.selectLatestByPromNo(promNo);
	}

	@Override
	public List<PromWorkVO> selectListByPromNo(Long promNo) {
		return promWorkMapper.selectListByPromNo(promNo);
	}

	@Override
	public int countPendingApproval() {
		return promWorkMapper.selectPendingApprovalCnt();
	}

	@Override
	public int countMyRejected(String userId) {
		if (userId == null || userId.isEmpty()) {
			return 0;
		}
		return promWorkMapper.selectMyRejectedCnt(userId);
	}

	@Override
	public Map<String, Object> selectHistory(Long promNo) {
		List<PromWorkVO> workList = promWorkMapper.selectListByPromNo(promNo);
		List<PromWorkActLogVO> logList = promWorkMapper.selectActLogListByPromNo(promNo);

		Map<String, Object> map = new HashMap<>();
		map.put("workList", workList);
		map.put("logList", logList);
		return map;
	}

	// ────────────────────────────────────────────────────────────────
	// 자동 워크플로 (PromServiceImpl 가 호출)
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void createInitialWork(Long promNo, String sysId, Long gaejungNo) throws Exception {
		PromWorkVO w = new PromWorkVO();
		w.setPromNo(promNo);
		w.setSysId((sysId == null || sysId.isEmpty()) ? "DEFAULT" : sysId);
		w.setStatus(PromWorkVO.STATUS_REQ_WAIT);
		// 작업종류(SACT_NM) — gaejungNo(커밋된 TB_GAEJUNG)로 제정/개정 판정.
		// ※ insertProm 트랜잭션에 참여(REQUIRED — 2026-07-20 필수화: 실패 시 등록 전체 롤백).
		//   prom 재조회 대신 gaejungNo 판정을 유지(과거 REQUIRES_NEW 시절 설계지만 여전히 단순·안전).
		w.setActNm(enactOrRevise(gaejungNmOf(gaejungNo)));
		// 등록자 = 신청자 (SUSER_ID/SUSER_NM 은 NOT NULL — null 이면 ORA-01400 로 워크행 유실).
		// 항상 웹 요청(등록 화면)에서 호출되므로 로그인 사용자로 채움. 비웹 경로는 매퍼 NVL 안전망.
		egovframework.com.cmm.LoginVO user =
				(egovframework.com.cmm.LoginVO) egovframework.com.cmm.util.EgovUserDetailsHelper.getAuthenticatedUser();
		if (user != null) {
			w.setUserId(user.getId());
			w.setUserNm(user.getName());
		}
		insertWorkRow(w, PromWorkActLogVO.ACT_TYPE_INSERT, "규정 신규 등록 자동 생성");
	}

	// ────────────────────────────────────────────────────────────────
	// 신청 / 승인 / 반려
	// ────────────────────────────────────────────────────────────────

	/**
	 * 전이 직렬화 — 회차 행 잠금(FOR UPDATE) 후 최신 워크 상태 재조회.
	 * 컨트롤러의 사전 가드는 UX 용이고, 동시 요청(두 승인자가 같은 건을 동시에 처리 등)은
	 * check-then-insert 틈에서 둘 다 통과할 수 있어 트랜잭션 안에서 잠금 후 재검사한다 (2026-07-20).
	 * 위반 시 IllegalStateException — 컨트롤러가 잡아 안내 메시지로 변환.
	 */
	private PromWorkVO lockAndLatest(Long promNo) {
		promWorkMapper.lockPromRow(promNo);
		return promWorkMapper.selectLatestByPromNo(promNo);
	}

	private static String statusOf(PromWorkVO w) {
		return w == null ? null : w.getStatus();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void requestApproval(PromWorkVO vo) throws Exception {
		String st = statusOf(lockAndLatest(vo.getPromNo()));
		// 중복 요청 가드 — 승인요청 심사 중 재요청 금지 (잠금 후 재검사라 동시 요청도 직렬화)
		if (PromWorkVO.STATUS_REQ_PEND.equals(st)) {
			throw new IllegalStateException("이미 승인요청이 진행 중입니다. 관리자 승인을 기다려 주세요.");
		}
		vo.setStatus(PromWorkVO.STATUS_REQ_PEND);
		vo.setActNm(approvalWorkType(vo.getPromNo()));
		insertWorkRow(vo, PromWorkActLogVO.ACT_TYPE_UPDATE, "승인요청");
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void approveRequest(PromWorkVO vo) throws Exception {
		String st = statusOf(lockAndLatest(vo.getPromNo()));
		if (!PromWorkVO.STATUS_REQ_PEND.equals(st)) {
			throw new IllegalStateException("이미 처리되었거나 승인요청 상태가 아닙니다. 목록을 새로고침해 주세요.");
		}
		vo.setStatus(PromWorkVO.STATUS_REQ_APPR);
		vo.setActNm(approvalWorkType(vo.getPromNo()));
		insertWorkRow(vo, PromWorkActLogVO.ACT_TYPE_APPROVE, "승인완료");

		// 승격: 같은 lawId 의 모든 회차 'Y' 해제 → 이 회차만 'Y' (레거시 와 동일)
		// 결과: 사용자 화면(front)에서 이 회차가 새 "현행" 으로 노출됨
		if (vo.getPromNo() != null) {
			narainet.rlms.prom.service.PromVO p = promMapper.selectPromByNo(vo.getPromNo());
			if (p != null && p.getLawId() != null) {
				promMapper.resetPromExistingByLawId(p.getLawId(),
						p.getSysId() != null ? p.getSysId() : "DEFAULT");
			}
			promMapper.updatePromExistingYn(vo.getPromNo(), "Y");
			// 폐지일 변경 승인 반영 — SNULL_DT_PEND 가 있으면 본값으로 승격 (2026-07-20 사용자 결정)
			promMapper.applyPendingNullDate(vo.getPromNo());
		}

		// 자동링크 사전 즉시 무효화 — 새 현행 규정명이 다음 렌더부터 전 규정 본문에 링크됨
		narainet.rlms.prom.service.impl.AutoLinkService.clearDictCache();
		// front 트리 캐시 즉시 무효화 — 승인된 규정이 다음 요청부터 사용자 트리에 반영
		narainet.rlms.prom.service.FrontTreeCache.clear();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void rejectRequest(PromWorkVO vo) throws Exception {
		String st = statusOf(lockAndLatest(vo.getPromNo()));
		if (!PromWorkVO.STATUS_REQ_PEND.equals(st)) {
			throw new IllegalStateException("이미 처리되었거나 승인요청 상태가 아닙니다. 목록을 새로고침해 주세요.");
		}
		vo.setStatus(PromWorkVO.STATUS_REQ_DENY);
		vo.setActNm(approvalWorkType(vo.getPromNo()));
		insertWorkRow(vo, PromWorkActLogVO.ACT_TYPE_REJECT, "승인반려");
		// 폐지일 변경 반려 — 대기값(SNULL_DT_PEND) 폐기, 기존 폐지일 유지 (2026-07-20 사용자 결정)
		if (vo.getPromNo() != null) {
			promMapper.clearPendingNullDate(vo.getPromNo());
		}
	}

	// (requestUpdate/approveUpdate/rejectUpdate/completeUpdate 폐지 — 2026-07-20 사용자 결정.
	//  수정권한 계열 전이 제거: 현행 회차 편집은 작성권한 가드만으로 허용.)

	// ────────────────────────────────────────────────────────────────
	// 작업종류(SACT_NM) 판정 — 레거시 C_WORK_NAME (제정편집/개정편집/수정권한)
	// ────────────────────────────────────────────────────────────────

	/** 개정구분 이름 → 작업종류 (레거시 insertDo: "제정"=제정편집, 그 외 개정편집). */
	private String enactOrRevise(String gaejungNm) {
		return "제정".equals(gaejungNm) ? PromWorkVO.WORK_ENACT : PromWorkVO.WORK_REVISE;
	}

	/** 개정구분 번호 → 이름 (커밋된 TB_GAEJUNG 조회 — REQUIRES_NEW 에서도 안전). */
	private String gaejungNmOf(Long gaejungNo) {
		if (gaejungNo == null) return null;
		try {
			GaejungVO g = gaejungMapper.selectGaejungByNo(gaejungNo);
			return g == null ? null : g.getGaejungNm();
		} catch (Exception ignore) { return null; }
	}

	/** prom 의 개정구분으로 작업종류 판정 (신청·승인 흐름 — prom 커밋 후라 selectPromByNo 가시). */
	private String approvalWorkType(Long promNo) {
		try {
			narainet.rlms.prom.service.PromVO p = promMapper.selectPromByNo(promNo);
			if (p != null) return enactOrRevise(p.getGaejungNm());
		} catch (Exception ignore) {}
		return PromWorkVO.WORK_REVISE;
	}

	// ────────────────────────────────────────────────────────────────
	// 공통 — 워크 row + 액션 로그 1쌍 INSERT
	// ────────────────────────────────────────────────────────────────

	private void insertWorkRow(PromWorkVO vo, String actType, String actDc) throws Exception {
		if (vo.getSysId() == null || vo.getSysId().isEmpty()) {
			vo.setSysId("DEFAULT");
		}
		vo.setWorkNo(promWorkIdGnrService.getNextLongId());
		promWorkMapper.insertPromWork(vo);

		// 액션 로그
		PromWorkActLogVO log = new PromWorkActLogVO();
		log.setActLogNo(promActLogIdGnrService.getNextLongId());
		log.setPromNo(vo.getPromNo());
		log.setSysId(vo.getSysId());
		log.setRefTable(REF_TABLE);
		log.setRefNo(String.valueOf(vo.getWorkNo()));
		log.setActType(actType);
		log.setActNm(vo.getActNm());
		log.setActDc(actDc);
		log.setUserId(vo.getUserId());
		log.setUserNm(vo.getUserNm());
		log.setWorkNo(vo.getWorkNo());
		promWorkMapper.insertActLog(log);
	}

	@Override
	public void logAction(Long promNo, String sysId, String refTable, String refNo,
			String actType, String actNm, String actDc, String userId, String userNm) {
		try {
			PromWorkActLogVO log = new PromWorkActLogVO();
			log.setActLogNo(promActLogIdGnrService.getNextLongId());
			log.setPromNo(promNo);
			log.setSysId(sysId == null || sysId.isEmpty() ? "DEFAULT" : sysId);
			log.setRefTable(refTable);
			log.setRefNo(refNo);
			log.setActType(actType);
			log.setActNm(actNm);
			log.setActDc(actDc);
			log.setUserId(userId);
			log.setUserNm(userNm);
			promWorkMapper.insertActLog(log);
		} catch (Exception e) {
			// 감사 로깅 실패는 본 작업(저장)을 막지 않음 — 단, 원인 추적 가능하게 warn 은 남긴다
			// (무기록 흡수 탓에 SSYS_ID NOT NULL 위반으로 로그가 통째로 유실되던 것을 2026-06-11 에야 발견)
			org.slf4j.LoggerFactory.getLogger(PromWorkServiceImpl.class)
					.warn("감사 로그 기록 실패 (promNo={}, refTable={}, actNm={}): {}",
							promNo, refTable, actNm, e.getMessage());
		}
	}
}
