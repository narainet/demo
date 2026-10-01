/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/PromServiceImpl.java
 *
 * 법령(TB_PROM) Service 구현체.
 *
 * 핵심 동작:
 *   - insert: lawId 가 0/null 이면 신규 법령(getMaxLawId), 아니면 개정본
 *   - update: 기본 갱신만 (existingYn 자동 변경 정책은 운영 정책에 따름 — 일단 vo 값 그대로)
 *   - delete: 트리거가 PROV_*, REL_*, DOCU, SRC_STORED cascade.
 *             단, 같은 lawId 의 다른 row 가 남았으면 가장 최신을 EXISTING='Y' 로 승격.
 */
package narainet.rlms.prom.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.gaejung.mapper.GaejungLogMapper;
import narainet.rlms.prom.mapper.PromMapper;
import narainet.rlms.prom.service.PromReadGuard;
import narainet.rlms.prom.service.PromService;
import narainet.rlms.prom.service.PromVO;
import narainet.rlms.prommap.mapper.PromMapMapper;
import narainet.rlms.promwork.service.PromWorkService;
import narainet.rlms.promwork.service.PromWorkVO;
import narainet.rlms.related.service.RelVrsnCateService;

/**
 * 법령 관리 Service 구현체
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Service("promService")
public class PromServiceImpl extends EgovAbstractServiceImpl implements PromService {

	@Resource(name = "promMapper")
	private PromMapper promMapper;

	/** 기능별분류(규정맵) 연동 — 법령 삭제 시 그 법령을 가리키는 leaf 정리 */
	@Resource
	private PromMapMapper promMapMapper;

	@Resource(name = "egovPromIdGnrService")
	private EgovIdGnrService promIdGnrService;

	/** prom 작업 로그(TB_GAEJUNG_LOG) 자동 기록용 */
	@Resource(name = "gaejungLogMapper")
	private GaejungLogMapper gaejungLogMapper;

	/** 승인 워크플로 자동 row 생성용 */
	@Resource(name = "promWorkService")
	private PromWorkService promWorkService;

	/** 회차 삭제 시 워크행 동반 정리용 — 고아 워크행=유령 승인대기 배지 방지 */
	@Resource
	private narainet.rlms.promwork.mapper.PromWorkMapper promWorkMapper;

	/** 회차 삭제 시 일괄편집 본문 백업(TB_PROV_TEXT_HST) 동반 정리 — 트리거 cascade 미대상 */
	@Resource
	private narainet.rlms.prom.mapper.ProvTextHstMapper provTextHstMapper;

	/** 회차 삭제 시 회차 직접 첨부(TB_ATTACH SREF_TABLE='TB_PROM') 동반 정리 — 트리거 cascade 미대상 */
	@Resource
	private narainet.rlms.attach.mapper.AttachMapper attachMapper;

	/** 관련자료 카테고리 디폴트 시드용 (본문/붙임/양식 3종 자동 INSERT) */
	@Resource(name = "relVrsnCateService")
	private RelVrsnCateService relVrsnCateService;

	/** 회차 삭제 시 관련자료 카테고리(TB_REL_VRSN_CATE) 동반 정리 — 트리거 cascade 미대상 */
	@Resource
	private narainet.rlms.related.mapper.RelVrsnCateMapper relVrsnCateMapper;

	/** 분류별 열람제한 게이트 (front 신구대조 후보) */
	@Resource(name = "promReadGuard")
	private PromReadGuard promReadGuard;

	// ────────────────────────────────────────────────────────────────
	// 조회
	// ────────────────────────────────────────────────────────────────

	@Override
	public Map<String, Object> selectPromList(PromVO vo) {
		List<PromVO> list = promMapper.selectPromList(vo);
		int cnt = promMapper.selectPromListCnt(vo);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public PromVO selectPromDetail(Long promNo) {
		return promMapper.selectPromByNo(promNo);
	}

	@Override
	public List<PromVO> selectPromHistory(Long lawId, String sysId) {
		return promMapper.selectPromListByLawId(lawId, sysId);
	}

	@Override
	public PromVO selectPreviousProm(Long promNo) {
		return promMapper.selectPreviousProm(promNo);
	}

	@Override
	public boolean isWorkingDraftProm(Long promNo) {
		return promNo != null && promMapper.countWorkingDraftByPromNo(promNo) > 0;
	}

	// ────────────────────────────────────────────────────────────────
	// 등록
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void insertProm(PromVO vo) throws Exception {
		// SSYS_ID 는 저장하지 않음(단일 시스템 — SSYS_ID 는 어떤 SQL 필터에도 미사용, null 허용).
		//   insert SQL 에 SSYS_ID 컬럼 없음. 강제 시스템ID 세팅은 죽은코드라 제거(2026-07-16).
		// 1) lawId 결정 — 레거시 워크플로 통합:
		//    · 신규 lawId(첫 회차) → SEXISTING_YN='N'  (★승인 전 비공개 — 2026-06-30 변경)
		//    · 개정본(기존 lawId)  → SEXISTING_YN='N'  (승인 전 비공개, 기존 'Y' 회차가 사용자 화면 유지)
		//    ★ 2026-06-30: 신규 제정도 'N' 으로 통일. 이전엔 'Y' 즉시노출이라 미승인 draft 가 사용자
		//       규정검색/분류트리에 새던 문제. 이제 SEXISTING_YN='Y' = '승인된 현행' 을 정확히 의미.
		//    승인 시점은 PromWorkServiceImpl.approveRequest 에서 resetPromExistingByLawId
		//    + updatePromExistingYn(promNo,'Y') 로 승격(제정·개정 동일).
		//    연혁번호(ILAW_NO) 채번 — 레거시 체계: 제정=10, 개정마다 +10 (10→20→30).
		//    화면에서 사용자가 직접 입력(수정)한 값이 있으면 그대로 존중, 없으면 자동.
		boolean userLawNo = (vo.getLawNo() != null && vo.getLawNo() != 0L);
		if (vo.getLawId() == null || vo.getLawId() == 0L) {
			vo.setLawId(promMapper.selectMaxLawId());
			if (!userLawNo) vo.setLawNo(10L);          // 제정 연혁번호 = 10 (레거시 동일)
			vo.setSeq(promMapper.selectMaxSeqByCate(vo.getCateNo()));
			vo.setExistingYn("N");   // ★ 신규 제정도 'N' — 승인(approveRequest) 시에만 'Y' 로 승격
		} else {
			// 개정본 — 기존 'Y' 회차 유지. resetPromExistingByLawId 호출 안 함.
			if (!userLawNo) {
				Long max = promMapper.selectMaxLawNoByLawId(vo.getLawId());
				vo.setLawNo((max == null ? 0L : max) + 10L);   // 직전 회차 +10 (레거시 동일)
			}
			vo.setExistingYn("N");
			if (vo.getSeq() == null) {
				vo.setSeq(promMapper.selectMaxSeqByCate(vo.getCateNo()));
			}
		}

		// 2) PK 채번
		vo.setPromNo(promIdGnrService.getNextLongId());

		// 3) searchText 자동 조립 (분류 전체경로는 Mapper 의 GET_FULL_NAME_BY_CATE_NO 가 표시용 — 저장은 단순 조합)
		if (vo.getSearchText() == null || vo.getSearchText().isEmpty()) {
			vo.setSearchText(safe(vo.getTitle()) + " " + safe(vo.getSubTitle()));
		}

		// 3') NOT NULL 컬럼 기본값 가드 (insert/update 공용)
		applyNotNullDefaults(vo);

		promMapper.insertProm(vo);

		// 4) 개정 작업 로그(TB_GAEJUNG_LOG) 1건 자동 INSERT — userNo 통합 전까지 null 허용
		try {
			gaejungLogMapper.insertGaejungLog(vo.getPromNo(), vo.getBuseoNo(), null);
		} catch (Exception ignored) {
			// 로그 INSERT 실패는 prom 등록 자체를 막지 않음 (best-effort)
		}

		// 5) 승인 워크플로 초기 row (편집중) 자동 생성 — ★필수(2026-07-20 best-effort 폐지).
		//    워크행 없는 회차는 draft 판정(excludeUnapprovedDraft — 최신 워크 기준)에 안 걸려
		//    미승인 상태로 front 게이트를 통과할 수 있다. 실패 시 등록 전체 롤백이 안전.
		promWorkService.createInitialWork(vo.getPromNo(), vo.getSysId(), vo.getGaejungNo());

		// 6) 관련자료 디폴트 카테고리 시드 (본문/붙임/양식 3종) — best-effort
		//    레거시 운영 분석(2026-05-14): 회차마다 동일 3종 반복이 다수파.
		//    seedDefault 는 멱등성 보장 (이미 있으면 SKIP).
		try {
			relVrsnCateService.seedDefault(vo.getPromNo(), vo.getLawId());
		} catch (Exception ignored) {
			// 카테고리 시드 실패는 prom 등록 자체를 막지 않음
		}
	}

	/**
	 * 연혁번호(ILAW_NO) 자동 제안 — 레거시 체계 "제정=10, 개정마다 +10".
	 *   · lawId 가 없거나 0 → 제정(첫 회차) → 10
	 *   · lawId 가 있으면 그 규정의 직전 최대 회차 +10
	 * 화면(연혁등록 폼)에서 미리 채워 보이고 사용자가 수정 가능 — prefill 용.
	 */
	@Override
	public Long suggestNextLawNo(Long lawId) {
		if (lawId == null || lawId == 0L) return 10L;            // 제정
		Long max = promMapper.selectMaxLawNoByLawId(lawId);
		return (max == null ? 0L : max) + 10L;                   // 직전 +10
	}

	// ────────────────────────────────────────────────────────────────
	// 수정
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateProm(PromVO vo) throws Exception {
		PromVO target = promMapper.selectPromByNo(vo.getPromNo());
		if (target == null) {
			throw processException("prom.notfound");
		}
		// searchText 미입력 시 자동 조립
		if (vo.getSearchText() == null || vo.getSearchText().isEmpty()) {
			vo.setSearchText(safe(vo.getTitle()) + " " + safe(vo.getSubTitle()));
		}
		// NOT NULL 컬럼 기본값 가드 (insert 와 동일) — 화면에서 SNUM/SNULL_DT/SURL 등을 비우면
		// emptyToNull 로 null 이 되어 ORA-01407 이 났던 문제 방지.
		applyNotNullDefaults(vo);

		// ── 폐지일 변경 승인 게이트 (2026-07-20 사용자 결정) ──
		// 현행(SEXISTING_YN='Y') 회차의 SNULL_DT 변경은 즉시 반영하지 않는다:
		// 기존값을 유지하고 새 값을 SNULL_DT_PEND 에 보관 + 승인요청 자동 생성.
		// 승인 시 PromWorkServiceImpl.approveRequest 가 반영, 반려 시 폐기.
		// draft(미승인) 회차는 회차 승인 자체가 게이트라 즉시 저장 유지.
		if ("Y".equals(target.getExistingYn())) {
			String oldNd = normNullDate(target.getNullDate());
			String newNd = normNullDate(vo.getNullDate());
			if (!oldNd.equals(newNd)) {
				vo.setNullDate(target.getNullDate());
				promMapper.updatePromNullDatePend(vo.getPromNo(), newNd);
				fileNullDateApproval(vo.getPromNo(), oldNd, newNd);
			}
		}

		promMapper.updateProm(vo);
		// 트리거 TRG_UPD_PROM 가 TB_FT_CACHE_QUEUE 캐시 무효화 자동 수행.
	}

	/** 폐지일 비교 정규화 — null/공백/'-' 는 미폐지 센티넬 '--' 로 통일 */
	private static String normNullDate(String d) {
		if (d == null) return "--";
		String t = d.trim();
		return (t.isEmpty() || "-".equals(t) || "--".equals(t)) ? "--" : t;
	}

	/** 폐지일 변경 승인요청 자동 생성 — 사유에 변경 내용 기록(승인 목록 사유 열에 노출).
	 *  이미 승인요청 심사 중이면 requestApproval 이 IllegalStateException → 저장 전체 롤백(선행 잠금과 정합). */
	private void fileNullDateApproval(Long promNo, String oldNd, String newNd) throws Exception {
		narainet.rlms.promwork.service.PromWorkVO w = new narainet.rlms.promwork.service.PromWorkVO();
		w.setPromNo(promNo);
		w.setReason("폐지일 변경 승인요청: "
				+ ("--".equals(oldNd) ? "(없음)" : oldNd) + " → "
				+ ("--".equals(newNd) ? "(해제)" : newNd));
		egovframework.com.cmm.LoginVO user =
				(egovframework.com.cmm.LoginVO) egovframework.com.cmm.util.EgovUserDetailsHelper.getAuthenticatedUser();
		if (user != null) {
			w.setUserId(user.getId());
			w.setUserNm(user.getName());
		}
		promWorkService.requestApproval(w);
	}

	/**
	 * TB_PROM 의 NOT NULL 컬럼 기본값 가드 (insertProm/updateProm 공용).
	 * 화면 미입력분을 레거시 PromulgationController 기본값으로 채워 ORA-01400/01407(NULL) 을 회피한다.
	 * Oracle 은 ''=NULL 이므로 빈 문자열도 막아야 한다. 레거시 운영 DB 기본값과 일치.
	 * (SSTOR_ 계열, SPARTY, SSUB_TITLE, SREL_FILE_VIEW_YN, SORDERIDX 등 nullable 컬럼은 제외)
	 */
	private void applyNotNullDefaults(PromVO vo) {
		if (isBlank(vo.getTitle()))       vo.setTitle(" ");            // STITLE   (화면 필수 — NULL 방지 안전망)
		if (isBlank(vo.getPromDate()))    vo.setPromDate(" ");         // SPROM_DT (화면 필수 — 안전망)
		if (isBlank(vo.getStartDate()))   vo.setStartDate(" ");        // SSTART_DT(화면 필수 — 안전망)
		if (isBlank(vo.getNumber()))      vo.setNumber(" ");           // SNUM (제·개정번호 — 선택항목)
		if (isBlank(vo.getNullDate()))    vo.setNullDate("--");        // SNULL_DT (종료일자 미정 = 레거시 "Y-M-D" 빈값)
		if (isBlank(vo.getUrl()))         vo.setUrl(" ");              // SURL
		if (isBlank(vo.getReason()))      vo.setReason(" ");           // SREASON  (CLOB)
		if (isBlank(vo.getGaejung()))     vo.setGaejung(" ");          // SGAEJUNG (CLOB)
		if (isBlank(vo.getBylaw()))       vo.setBylaw(" ");            // SBYLAW   (CLOB)
		if (isBlank(vo.getPreamble()))    vo.setPreamble(" ");         // SPREAMBLE(CLOB)
		if (isBlank(vo.getProvFlag()))    vo.setProvFlag("VERSION");   // SPROV_FG
		if (isBlank(vo.getProvStyleCd())) vo.setProvStyleCd("NORMAL"); // SPROV_STYLE_CD
		if (isBlank(vo.getProvFileNo()))  vo.setProvFileNo("-1");      // SPROV_FILE_NO (실DB 기본 -1 = 미지정)
		if (isBlank(vo.getDispYn()))      vo.setDispYn("Y");           // SDISP_YN
		if (isBlank(vo.getExtDispYn()))   vo.setExtDispYn("N");        // SEXT_DISP_YN
		if (isBlank(vo.getDplItemYn()))   vo.setDplItemYn("N");        // SDPL_ITEM_YN
		if (isBlank(vo.getStatus()))      vo.setStatus("편집중");      // SSTATUS (레거시 C_STATUS_TYPE_1 = 신규 초기상태)
		if (vo.getGaejungNo() == null)    vo.setGaejungNo(0L);         // IGAEJUNG_NO
		if (vo.getOrderIdx()  == null)    vo.setOrderIdx(50);          // SORDERIDX (실DB 기본 50 — 명시 NULL 이면 DEFAULT 우회)

		// 파생 코드 (실DB 호환) — SGAEJUNG_CODE = 'GJ' + IGAEJUNG_NO 18자리 zero-pad (VARCHAR2(20)).
		// gaejungNo 변경 시 코드도 따라가도록 항상 재조립(insert/update 공용).
		vo.setGaejungCode(String.format("GJ%018d", vo.getGaejungNo()));

		// 소관부서 — 정본 = 표준 조직ID(SBUSEO_ORGNZT_ID, COMTNORGNZTINFO. F1-5 전환 2026-06-11).
		//  · 폼이 orgnztId 를 주면 그대로 쓰고, IBUSEO_NO 는 이관분(ORG_+16자리)에서만 역파생
		//    (표준 화면 자체 생성 부서는 레거시 번호가 없어 0 — 표시 조인은 SBUSEO_ORGNZT_ID 우선이라 무관).
		//  · 구경로(buseoNo 만 온 경우)는 종전대로 ORG_ 16자리 zero-pad 파생.
		if (vo.getBuseoOrgnztId() != null && !vo.getBuseoOrgnztId().trim().isEmpty()) {
			String oid = vo.getBuseoOrgnztId().trim();
			vo.setBuseoOrgnztId(oid);
			if (vo.getBuseoNo() == null) {
				vo.setBuseoNo(oid.matches("ORG_[0-9]{16}") ? Long.valueOf(oid.substring(4)) : 0L);
			}
		} else {
			if (vo.getBuseoNo() == null) vo.setBuseoNo(0L);            // IBUSEO_NO
			// buseoNo=0(미지정)이면 'ORG_0000000000000000' 센티넬 대신 NULL — 센티넬은
			// 필수검증(orgnztId != null)을 우회시키는 가짜 값이 된다. 표시 조인은 NVL 폴백이라 동일.
			vo.setBuseoOrgnztId(vo.getBuseoNo() > 0L
					? String.format("ORG_%016d", vo.getBuseoNo()) : null);
		}
	}

	// ────────────────────────────────────────────────────────────────
	// 삭제 + 유효 플래그 재배치
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteProm(Long promNo) throws Exception {
		PromVO target = promMapper.selectPromByNo(promNo);
		if (target == null) {
			throw processException("prom.notfound");
		}

		// 기능별분류(규정맵) 정리 — 이 회차를 가리키는 leaf 삭제(레거시 singleDeleteDo/multipleDeleteDo
		// 의 promulgationMapDao 정리 파리티. 트리거는 TB_PROM_MAP 을 cascade 하지 않음).
		try { promMapMapper.deleteMapByPromNo(promNo); } catch (Exception ignore) { }

		// 조문 있는 연혁 삭제 허용(2026-07-23)에 따른 잔재 정리 — 트리거 cascade 미대상 3종.
		//   ① 일괄편집 본문 백업(TB_PROV_TEXT_HST)  ② 회차 직접 첨부(TB_ATTACH SREF_TABLE='TB_PROM')
		//   ③ 관련자료 카테고리(TB_REL_VRSN_CATE) — 트리거는 자료 본체(TB_REL_VRSN)만 지우고
		//      카테고리 껍데기(본문/붙임/양식 시드 포함)를 남긴다 (2026-07-30).
		try { provTextHstMapper.deleteHistoryByPromNo(promNo); } catch (Exception ignore) { }
		try { attachMapper.deleteAttachByRef("TB_PROM", promNo); } catch (Exception ignore) { }
		try { relVrsnCateMapper.deleteByPromNo(promNo); } catch (Exception ignore) { }

		// 트리거가 PROV_*, REL_VRSN, DOCU, SRC_STORED cascade 처리.
		// 이 회차에서 개정된 조문(TB_PROV_VRSN/HTML)·별표·관련자료가 함께 삭제되며,
		// 삭제된 조문은 누적 조회(SFULL_ITEM 별 MAX(ILAW_NO))가 이전 연혁들 중 최종 행을
		// 자동 승계 — "이전 연혁의 최종 조문이 현행이 되는" 재배치는 별도 갱신 없이 성립.
		promMapper.deleteProm(promNo);

		// 워크행 동반 정리 — 트리거가 TB_PROM_WRK 를 cascade 하지 않아 고아 워크행이 남으면
		// '승인요청' 최신행이 유령 승인대기 배지를 만든다. 액션 로그(TB_PROM_ACT_LOG)는 감사 이력이라 보존.
		promWorkMapper.deleteByPromNo(promNo);

		// 유효 플래그 재배치 — 현행 = 표시(SDISP_YN='Y') 회차 중 최신(ILAW_NO DESC).
		// 숨김회차(SDISP_YN='N')가 더 높은 ILAW_NO 라도 현행으로 승격하지 않음(실DB 53건 예외 대응).
		// ★승인 전 회차(최신워크 편집중/승인요청/승인반려)도 승격 제외 — 현행 삭제 시 미승인 draft 가
		//   무가드로 현행 승격돼 front 에 노출되던 승인 게이트 우회 차단 (2026-07-09,
		//   recomputeExistingAfterBulk 의 isPendingApproval 가드와 동일 기준).
		promMapper.resetPromExistingByLawId(target.getLawId(), target.getSysId());
		List<PromVO> remained = promMapper.selectPromListByLawId(target.getLawId(), target.getSysId());
		PromVO latest = null;
		for (PromVO p : remained) {            // selectPromListByLawId 는 ILAW_NO DESC 정렬 (workStatus 포함)
			if ("N".equals(p.getDispYn())) continue;
			String ws = p.getWorkStatus();
			if (PromWorkVO.STATUS_REQ_WAIT.equals(ws) || PromWorkVO.STATUS_REQ_PEND.equals(ws)
					|| PromWorkVO.STATUS_REQ_DENY.equals(ws)) continue;
			latest = p;
			break;
		}
		if (latest != null) {
			promMapper.updatePromExistingYn(latest.getPromNo(), "Y");
		}

		// 자동링크 사전 즉시 무효화 — 삭제/현행 재배치가 다음 렌더부터 링크에 반영
		AutoLinkService.clearDictCache();
		// front 트리 캐시 즉시 무효화 — 삭제된 연혁/규정이 다음 요청부터 사용자 트리에서 제거
		narainet.rlms.prom.service.FrontTreeCache.clear();
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deletePromList(List<Long> promNoList) throws Exception {
		if (promNoList == null || promNoList.isEmpty()) {
			return;
		}
		for (Long no : promNoList) {
			deleteProm(no);
		}
	}

	// ────────────────────────────────────────────────────────────────
	// 정렬 / 분류 이동
	// ────────────────────────────────────────────────────────────────

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateSequence(Long promNo, Integer seq) throws Exception {
		PromVO target = promMapper.selectPromByNo(promNo);
		if (target == null) {
			throw processException("prom.notfound");
		}
		promMapper.updatePromSequence(promNo, seq);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void moveCategory(Long promNo, Long newCateNo) throws Exception {
		PromVO target = promMapper.selectPromByNo(promNo);
		if (target == null) {
			throw processException("prom.notfound");
		}
		promMapper.updatePromCategoryMove(promNo, newCateNo);
	}

	// ────────────────────────────────────────────────────────────────
	// Front 검색 5종
	// ────────────────────────────────────────────────────────────────

	@Override
	public Map<String, Object> selectFrontHistoryList(PromVO vo) {
		List<PromVO> list = promMapper.selectFrontHistoryList(vo);
		int cnt = promMapper.selectFrontHistoryListCnt(vo);
		return wrapResult(list, cnt);
	}

	@Override
	public Map<String, Object> selectFrontCurrentList(PromVO vo) {
		List<PromVO> list = promMapper.selectFrontCurrentList(vo);
		int cnt = promMapper.selectFrontCurrentListCnt(vo);
		return wrapResult(list, cnt);
	}

	@Override
	public Map<String, Object> selectDetailSearch(PromVO vo) {
		List<PromVO> list = promMapper.selectDetailSearchList(vo);
		int cnt = promMapper.selectDetailSearchListCnt(vo);
		return wrapResult(list, cnt);
	}

	@Override
	public List<Map<String, Object>> selectDetailBuseoList() {
		return promMapper.selectDetailBuseoList();
	}

	@Override
	public List<Map<String, Object>> selectDetailCateList() {
		return promMapper.selectDetailCateList();
	}

	@Override
	public Map<String, Object> selectFrontNullifyList(PromVO vo) {
		List<PromVO> list = promMapper.selectFrontNullifyList(vo);
		int cnt = promMapper.selectFrontNullifyListCnt(vo);
		return wrapResult(list, cnt);
	}

	@Override
	public Map<String, Object> selectFrontLatestList(PromVO vo) {
		if (vo.getSearchDays() == null || vo.getSearchDays() <= 0) {
			vo.setSearchDays(30);
		}
		List<PromVO> list = promMapper.selectFrontLatestList(vo);
		int cnt = promMapper.selectFrontLatestListCnt(vo);
		return wrapResult(list, cnt);
	}

	@Override
	public List<PromVO> selectComparisonCandidates(Long lawId) {
		// 사용자 신구대조 후보 — 미승인 draft·삭제분류 제외 (frontOnly) + 분류별 열람제한 게이트.
		// 편집계 3역할은 frontOnly 미적용(2026-07-08): IDE 대비표 버튼이 comparisonList.do 로 진입하므로
		// 삭제분류에 매달린 규정(excludeDeletedCate 대상)도 회차 비교 후 재분류할 수 있어야 함.
		return promMapper.selectComparisonCandidates(lawId, !promReadGuard.isExempt(),
				promReadGuard.gateNeeded(), promReadGuard.readerEsntlId(), promReadGuard.readerOrgnztId());
	}

	private Map<String, Object> wrapResult(List<PromVO> list, int cnt) {
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	private String safe(String s) {
		return s == null ? "" : s;
	}

	/** null 또는 공백만이면 true (NOT NULL 컬럼 기본값 가드용) */
	private static boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}
}
