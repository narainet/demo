/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/ProvVrsnServiceImpl.java
 */
package narainet.rlms.prom.service.impl;

import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.prom.mapper.ProvVrsnMapper;
import narainet.rlms.prom.service.DiffLineVO;
import narainet.rlms.prom.service.ProvVrsnService;
import narainet.rlms.prom.service.ProvVrsnVO;

/**
 * 조항 본문 단위 row Service 구현체
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Service("provVrsnService")
public class ProvVrsnServiceImpl extends EgovAbstractServiceImpl implements ProvVrsnService {

	@Resource(name = "provVrsnMapper")
	private ProvVrsnMapper provVrsnMapper;

	@Resource(name = "egovProvVrsnIdGnrService")
	private EgovIdGnrService provVrsnIdGnrService;

	/** BodyParser 는 stateless POJO — 직접 생성하여 사용 (TB_PROV_HTML 단건 편집용 자체 간이 파서) */
	private final BodyParser bodyParser = new BodyParser();

	/** 레거시 식 한국법령 파서 — "버전관리용조문편집" 일괄 저장에서 사용 */
	private final ProvTextParser provTextParser = new ProvTextParser();

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void decomposeAndStore(Long promNo, String contents,
			String startDate, String sysId, String gaejungType) throws Exception {

		// 1) 기존 단위 row 정리
		provVrsnMapper.deleteProvVrsnByPromNo(promNo);

		// 2) HTML 분해
		List<ProvVrsnVO> units = bodyParser.decompose(promNo, contents, startDate, sysId, gaejungType);
		if (units == null || units.isEmpty()) {
			return;
		}

		// 3) PK 채번 (각 row 마다)
		for (ProvVrsnVO v : units) {
			v.setProvVrsnNo(provVrsnIdGnrService.getNextLongId());
		}

		// 4) 일괄 INSERT (청크 분할 — Oracle INSERT ALL 바인드 한계 회피)
		insertProvVrsnInChunks(units);
	}

	@Override
	public List<ProvVrsnVO> selectListByPromNo(Long promNo) {
		return provVrsnMapper.selectProvVrsnList(promNo);
	}

	@Override
	public List<ProvVrsnVO> selectCumulative(Long lawId, Long lawNo) {
		if (lawId == null || lawNo == null) return java.util.Collections.emptyList();
		return provVrsnMapper.selectAllCumulative(lawId, lawNo);
	}

	@Override
	public List<DiffLineVO> diffByPromNo(Long leftPromNo, Long rightPromNo) {
		return provVrsnMapper.selectDiffByPromNo(leftPromNo, rightPromNo);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int snapshotBulkBody(Long promNo, Long lawId, Long lawNo, String text,
			String startDate, String sysId, String gaejungType) throws Exception {

		// 0) 회차 직렬화 락 — 저장이 "소유행 전량 DELETE 후 재INSERT" 라 같은 회차의 저장이 겹치면
		//    뒤 트랜잭션의 DELETE 가 앞 트랜잭션의 미커밋 INSERT 를 못 봐 두 벌이 모두 남는다
		//    (조문 2중 저장 — 고객 테스트 2026-07-22 지적). 화면 이중클릭 가드만으로는 탭 2개·재요청을 못 막는다.
		provVrsnMapper.lockPromForUpdate(promNo);

		// 1) 파싱 — 레거시 STYLE_NORMAL 패턴 → 60자 SFULL_ITEM row
		List<ProvVrsnVO> rows = provTextParser.parse(promNo, text, startDate, sysId, gaejungType);
		if (rows == null) rows = new java.util.ArrayList<>();

		// 2) 비교 기준선 = 직전 회차의 누적 본문 (레거시 previousPromulgation).
		//    개정유형은 "이전 법령 대비 이번 개정에서 무엇이 바뀌었나" 이므로 직전 회차와 비교.
		List<ProvVrsnVO> prevBaseline = java.util.Collections.<ProvVrsnVO>emptyList();
		if (lawId != null && lawNo != null) {
			Long prevLawNo = provVrsnMapper.selectPrevLawNo(lawId, lawNo);
			if (prevLawNo != null) {
				prevBaseline = provVrsnMapper.selectAllCumulative(lawId, prevLawNo);
			}
		}

		// 3) 레거시 compare() 이식 — 조문별 개정유형 분류(rows 가공) + 삭제/이동 tombstone 생성
		List<ProvVrsnVO> tombstones = classifyAndBuildTombstones(prevBaseline, rows, promNo, startDate, sysId);

		// 3-a) 미개정(EQUAL) 행은 이 회차에 저장하지 않는다 — 직전 연혁과 동일한 조문은 행을 만들지
		//      않고 이전 연혁 행을 그대로 승계. "개정으로 1차 처리했다가 되돌린" 조문의 1차 데이터가
		//      재저장(delete+미삽입)으로 제거되어 신구대조/뷰어 개정마크에 남지 않으며,
		//      회차는 변경/신규/삭제(tombstone) 행만 소유(누적 조회 설계 원형과 일치).
		List<ProvVrsnVO> stored = new java.util.ArrayList<>(rows.size());
		for (ProvVrsnVO r : rows) {
			if (!"EQUAL".equals(r.getGaejungType())) stored.add(r);
		}

		// 3-b) 레거시 compareByModifiedYN 이식 — 기존 저장본(누적) 중 손편집(SUSER_MODIFIED_YN='Y') 행과
		//      제목+본문이 동일한 새 행에는 기존 개정유형과 'Y' 를 승계 (일괄 재저장이 손편집 분류를 덮지 않게).
		//      승계 대상은 저장되는(비EQUAL) 행만 — EQUAL 로 승계 처리된 행에 옛 유형을 되살리면
		//      "내용은 직전 연혁과 같은데 개정으로 남는" 문제가 재발하므로 내용 판정이 우선.
		carryUserModifiedTypes(promNo, lawId, lawNo, stored);

		// 4) 이 회차가 직접 소유한 기존 TB_PROV_VRSN 통째 삭제 (이전 회차 상속분은 tombstone 으로 가림)
		provVrsnMapper.deleteProvVrsnByPromNo(promNo);

		// 5) 변경/신규 행 + tombstone 합쳐 PK 채번 후 일괄 INSERT (전량 미개정이면 삽입 없음 = 전부 승계)
		List<ProvVrsnVO> all = new java.util.ArrayList<>(stored.size() + tombstones.size());
		all.addAll(stored);
		all.addAll(tombstones);
		if (all.isEmpty()) return rows.size();
		for (ProvVrsnVO v : all) {
			v.setProvVrsnNo(provVrsnIdGnrService.getNextLongId());
		}
		insertProvVrsnInChunks(all);
		return rows.size();   // 표시 행 수(tombstone 제외)
	}

	/**
	 * 일괄 INSERT 를 청크로 나눠 실행.
	 *
	 * insertProvVrsnBatch 는 Oracle 의 {@code INSERT ALL ... INTO ... INTO ...} 패턴이라
	 * 행이 많으면 한 SQL 문에 펼쳐지는 바인드 변수/표현식 수가 한계를 넘어
	 * {@code ORA-00913: 값의 수가 너무 많습니다} 로 저장이 통째로 실패한다
	 * (예: 조세특례제한법 시행령 — 수백 조항. "90조까지 잘라야 저장됨"의 원인).
	 *
	 * 컬럼 20개 × {@value #INSERT_CHUNK} 행 = 약 2000 바인드로 한계 대비 충분히 여유.
	 * 같은 {@code @Transactional} 안에서 여러 번 호출하므로 원자성(전부 커밋/전부 롤백)은 유지.
	 */
	private static final int INSERT_CHUNK = 100;

	private void insertProvVrsnInChunks(List<ProvVrsnVO> all) {
		if (all == null || all.isEmpty()) return;
		for (int i = 0; i < all.size(); i += INSERT_CHUNK) {
			int end = Math.min(i + INSERT_CHUNK, all.size());
			provVrsnMapper.insertProvVrsnBatch(all.subList(i, end));
		}
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int replaceJoSubtree(Long promNo, Long lawId, Long lawNo, String joFullItem, String blockText,
			String startDate, String sysId, String reason) throws Exception {

		if (promNo == null || joFullItem == null || joFullItem.trim().isEmpty()) {
			throw new IllegalArgumentException("promNo/joFullItem 이 없습니다.");
		}
		// 회차 직렬화 락 — 단건 조 편집도 subtree delete+insert 라 일괄저장과 겹치면 같은 2중 저장이 난다.
		provVrsnMapper.lockPromForUpdate(promNo);
		String joFull = rpad60(joFullItem.trim());

		// 1) 블록 재분해 — 조 + 하위 항/호/목. (개정유형은 아래 분류가 정본이므로 파싱은 null)
		List<ProvVrsnVO> rows = provTextParser.parse(promNo, blockText, startDate, sysId, null);
		if (rows == null) rows = new java.util.ArrayList<>();

		// 2) 조 라인이 본문에 있어야 함 (제N조 누락 시 트리 구조가 깨지므로 거부).
		//    조 삭제의 정본 동선 = 일괄편집기에서 조 블록을 지우고 저장 → snapshotBulkBody 가 tombstone 처리.
		boolean hasJo = false;
		for (ProvVrsnVO r : rows) {
			if ("BASE_TEXT".equals(r.getUnitType())) { hasJo = true; break; }
		}
		if (!hasJo) {
			throw new IllegalStateException("본문 첫 줄에 조 라인(\"제N조(제목)\")이 있어야 합니다.");
		}

		// 3) 원래 조의 상위(편/장/절/관/목1) prefix[0,25) 를 각 행에 이식 — 블록 단독 파싱 시 비는 상위 청크 보정.
		String upperPrefix = joFull.substring(0, 25);
		for (ProvVrsnVO r : rows) {
			String fi = rpad60(r.getFullItem());
			r.setFullItem(upperPrefix + fi.substring(25));
		}

		// 4) 직전 연혁의 이 조 subtree 를 기준선으로 개정유형 분류 + 블록에서 빠진 항/호/목 tombstone.
		//    (일괄편집기 snapshotBulkBody 와 동일 기준 — 화면이 들고 온 stale 개정유형은 쓰지 않는다.
		//     기준선이 없으면(제정 회차/이 회차 신설 조) 전부 NEW 로 분류돼 아래 전량저장과 동일.)
		List<ProvVrsnVO> baseline = java.util.Collections.<ProvVrsnVO>emptyList();
		if (lawId != null && lawNo != null) {
			Long prevLawNo = provVrsnMapper.selectPrevLawNo(lawId, lawNo);
			if (prevLawNo != null) {
				baseline = provVrsnMapper.selectProvVrsnAndSubItemsCumulative(lawId, prevLawNo, joFull);
			}
		}
		List<ProvVrsnVO> tombstones = classifyAndBuildTombstones(baseline, rows, promNo, startDate, sysId);

		String joPrefix30 = joFull.substring(0, 30);

		// 4-b) 전량 EQUAL + tombstone 없음 = 직전 연혁과 동일(미개정 재처리) —
		//      이 회차가 소유한 subtree 행을 삭제만 하고 재삽입하지 않는다(이전 연혁 행 승계 복원).
		//      "개정으로 1차 처리했다가 되돌린" 조문이 신구대조/개정마크에 남지 않게 하는 핵심.
		boolean allEqual = tombstones.isEmpty();
		if (allEqual) {
			for (ProvVrsnVO r : rows) {
				if (!"EQUAL".equals(r.getGaejungType())) { allEqual = false; break; }
			}
		}
		if (allEqual) {
			provVrsnMapper.deleteProvVrsnBySubtreePrefix(promNo, joPrefix30);
			return -1;   // 호출측 안내용 — 미개정 복원(이 회차 소유 행 제거, 이전 연혁 승계)
		}

		// 5) 조 행(첫 BASE_TEXT)에 개정사유/시행일 반영 (개정유형은 4의 분류 결과 유지)
		for (ProvVrsnVO r : rows) {
			if ("BASE_TEXT".equals(r.getUnitType())) {
				if (reason != null)      r.setReason(reason);
				if (startDate != null)   r.setStartDate(startDate);
				r.setUserModifiedYn("Y");   // 단건 손편집 — 일괄 재저장이 분류를 덮지 않게 (carryUserModifiedTypes 연동)
				break;
			}
		}

		// 6) 이 회차가 소유한 그 조 subtree 행 삭제 (SFULL_ITEM 앞 30자 = 조 prefix = 조 + 그 항/호/목)
		//    후 새 subtree + tombstone 삽입
		provVrsnMapper.deleteProvVrsnBySubtreePrefix(promNo, joPrefix30);

		// 7) 채번 + 청크 INSERT
		List<ProvVrsnVO> all = new java.util.ArrayList<>(rows.size() + tombstones.size());
		all.addAll(rows);
		all.addAll(tombstones);
		if (all.isEmpty()) return 0;
		for (ProvVrsnVO v : all) {
			v.setProvVrsnNo(provVrsnIdGnrService.getNextLongId());
		}
		insertProvVrsnInChunks(all);
		return rows.size();
	}

	/** SFULL_ITEM 을 60자로 우측 '0' 패딩 (짧은 입력 방어) */
	private static String rpad60(String s) {
		if (s == null) s = "";
		if (s.length() >= 60) return s.substring(0, 60);
		StringBuilder sb = new StringBuilder(s);
		while (sb.length() < 60) sb.append('0');
		return sb.toString();
	}

	/**
	 * 레거시 ProvisionVersionUtil.compareByModifiedYN 이식 —
	 * 일괄 재저장(delete+insert) 직전, 기존 저장본(누적 — 이전 회차 상속분 포함) 중 사용자가
	 * 손편집한(SUSER_MODIFIED_YN='Y') 행과 같은 fullItem 이고 제목+본문이 동일(공백 무시)한
	 * 새 행에 기존 SGAEJUNG_TYPE/'Y' 를 승계. 텍스트만 같은 타 위치 행으로의 승계는 안 함
	 * (레거시 동일 — 모호 매칭에 의한 과승계 방지).
	 */
	private void carryUserModifiedTypes(Long promNo, Long lawId, Long lawNo, List<ProvVrsnVO> newRows) {
		if (promNo == null || newRows == null || newRows.isEmpty()) return;
		List<ProvVrsnVO> baseline;
		try {
			baseline = (lawId != null && lawNo != null)
					? provVrsnMapper.selectAllCumulative(lawId, lawNo)
					: provVrsnMapper.selectProvVrsnList(promNo);
		} catch (Exception e) {
			return;   // 승계는 보강 기능 — 조회 실패가 저장을 막지 않게
		}
		if (baseline == null || baseline.isEmpty()) return;

		java.util.Map<String, ProvVrsnVO> byFull = new java.util.HashMap<>();
		for (ProvVrsnVO o : baseline) {
			if (!"Y".equals(o.getUserModifiedYn())) continue;
			if (o.getFullItem() != null) byFull.putIfAbsent(o.getFullItem(), o);
		}
		if (byFull.isEmpty()) return;

		for (ProvVrsnVO n : newRows) {
			ProvVrsnVO m = byFull.get(n.getFullItem());
			if (m == null || !modKey(m).equals(modKey(n))) continue;
			n.setGaejungType(m.getGaejungType());
			n.setMoveFullItem(m.getMoveFullItem());
			n.setUserModifiedYn("Y");
		}
	}

	/** 손편집 승계 매칭 키 - 공백 전부 제거(레거시 replaceSpace 등가), 제목/본문 경계 구분자 보존 */
	private String modKey(ProvVrsnVO v) {
		return stripSpace(v.getTitle()) + "\u0001" + stripSpace(v.getContents());
	}
	private static String stripSpace(String s) {
		return s == null ? "" : s.replaceAll("\\s+", "");
	}


	/**
	 * 레거시 ProvisionVersionUtil.compare() 완전 이식 — 직전 회차(prev) 대비:
	 *
	 *  (1) 현재 본문(newRows) 각 조문의 개정유형(SGAEJUNG_TYPE) + 이동대상(SMOVE_FULL_ITEM) 분류 (newRows 가공)
	 *      - prev 에 같은 fullItem: EQUAL / MODIFY_TITLE / MODIFY_CONTENTS / MODIFY_ALL
	 *      - fullItem 없음 + prev 제목/본문 유일매칭: MOVE_ALL / MOVE_TITLE_MODIFY_CONTENTS / MOVE_CONTENTS_MODIFY_TITLE
	 *      - 매칭 없음: NEW. (gaejungType 값은 운영 TB_PROV_VRSN 과 동일 문자열)
	 *  (2) prev 에는 있으나 newRows 에 없는 조문: SDISP_YN='N' tombstone (NULLIFY / NULLIFY_MOVE_*).
	 *      누적 조회(MAX(ILAW_NO)+SDISP_YN='Y')가 tombstone 을 숨겨 조문이 사라짐.
	 *
	 * 이동/중복 판정은 (nativeType, 정규화텍스트) 키가 상대 목록에 유일(count==1)할 때만 인정(모호하면 NEW/NULLIFY).
	 */
	private List<ProvVrsnVO> classifyAndBuildTombstones(List<ProvVrsnVO> prev,
			List<ProvVrsnVO> newRows, Long promNo, String startDate, String sysId) {

		// 인덱스 빌드 (양방향)
		java.util.Map<String, ProvVrsnVO> prevByFull = new java.util.HashMap<>();
		Index prevTitle = new Index(), prevContents = new Index();
		for (ProvVrsnVO p : prev) {
			prevByFull.putIfAbsent(p.getFullItem(), p);
			prevTitle.add(safe(p.getNativeType()) + norm(p.getTitle()), norm(p.getTitle()), p);
			prevContents.add(safe(p.getNativeType()) + norm(p.getContents()), norm(p.getContents()), p);
		}
		java.util.Set<String> newFull = new java.util.HashSet<>();
		Index newTitle = new Index(), newContents = new Index();
		for (ProvVrsnVO n : newRows) {
			newFull.add(n.getFullItem());
			newTitle.add(safe(n.getNativeType()) + norm(n.getTitle()), norm(n.getTitle()), n);
			newContents.add(safe(n.getNativeType()) + norm(n.getContents()), norm(n.getContents()), n);
		}

		// (1) 현재 본문 각 조문 개정유형 분류 (레거시 compare 현재측)
		for (ProvVrsnVO cur : newRows) {
			ProvVrsnVO same = prevByFull.get(cur.getFullItem());
			if (same != null) {
				boolean tSame = norm(cur.getTitle()).equals(norm(same.getTitle()));
				boolean cSame = norm(cur.getContents()).equals(norm(same.getContents()));
				cur.setGaejungType(tSame && cSame ? "EQUAL"
						: (!tSame && !cSame) ? "MODIFY_ALL"
						: (!tSame) ? "MODIFY_TITLE" : "MODIFY_CONTENTS");
				continue;
			}
			ProvVrsnVO mvT = prevTitle.unique(safe(cur.getNativeType()) + norm(cur.getTitle()));
			ProvVrsnVO mvC = prevContents.unique(safe(cur.getNativeType()) + norm(cur.getContents()));
			if (mvT != null) {
				boolean cSame = norm(cur.getContents()).equals(norm(mvT.getContents()));
				cur.setGaejungType(cSame ? "MOVE_ALL" : "MOVE_TITLE_MODIFY_CONTENTS");
				cur.setMoveFullItem(mvT.getFullItem());
			} else if (mvC != null) {
				boolean tSame = norm(cur.getTitle()).equals(norm(mvC.getTitle()));
				cur.setGaejungType(tSame ? "MOVE_TITLE_MODIFY_CONTENTS" : "MOVE_CONTENTS_MODIFY_TITLE");
				cur.setMoveFullItem(mvC.getFullItem());
			} else {
				cur.setGaejungType("NEW");
			}
		}

		// (2) prev 에는 있으나 new 에 없는 조문 -> SDISP_YN='N' tombstone (레거시 compare 이전측)
		List<ProvVrsnVO> tombstones = new java.util.ArrayList<>();
		for (ProvVrsnVO p : prev) {
			if (newFull.contains(p.getFullItem())) continue;
			ProvVrsnVO mvT = newTitle.unique(safe(p.getNativeType()) + norm(p.getTitle()));
			ProvVrsnVO mvC = newContents.unique(safe(p.getNativeType()) + norm(p.getContents()));
			String gaejung; String moveTo = null;
			if (mvT != null) {
				gaejung = (mvC == null) ? "NULLIFY_MOVE_TITLE" : "NULLIFY_MOVE_CONTENTS";
				moveTo  = mvT.getFullItem();
			} else if (mvC != null) {
				gaejung = "NULLIFY_MOVE_CONTENTS";
				moveTo  = mvC.getFullItem();
			} else {
				gaejung = "NULLIFY";
			}
			tombstones.add(makeTombstone(p, promNo, gaejung, moveTo, startDate, sysId));
		}
		return tombstones;
	}

	/** (nativeType+정규화텍스트) 키 -> 대표 VO + 빈도. unique() 는 빈 텍스트/중복 시 null(모호) 반환. */
	private static final class Index {
		private final java.util.Map<String, ProvVrsnVO> first = new java.util.HashMap<>();
		private final java.util.Map<String, Integer> count = new java.util.HashMap<>();
		void add(String key, String text, ProvVrsnVO vo) {
			if (text == null || text.isEmpty()) return;
			count.merge(key, 1, Integer::sum);
			first.putIfAbsent(key, vo);
		}
		ProvVrsnVO unique(String key) {
			return count.getOrDefault(key, 0) == 1 ? first.get(key) : null;
		}
	}

	/** baseline 행을 복제해 현재 회차의 SDISP_YN='N' tombstone 으로 변환 */
	private ProvVrsnVO makeTombstone(ProvVrsnVO src, Long promNo, String gaejungType,
			String moveFullItem, String startDate, String sysId) {
		ProvVrsnVO t = new ProvVrsnVO();
		t.setPromNo(promNo);
		t.setFullItem(src.getFullItem());
		t.setItem(src.getItem());
		t.setSubItem(src.getSubItem());
		t.setMoveFullItem(moveFullItem);
		t.setUnitType(src.getUnitType());
		t.setNativeType(src.getNativeType());
		t.setStyleId(src.getStyleId());
		t.setLevel(src.getLevel());
		t.setIndex(src.getIndex());
		t.setTitle(src.getTitle());
		t.setContents(src.getContents());
		t.setReason(src.getReason());
		t.setSearchText(src.getSearchText());
		t.setGaejungType(gaejungType);
		t.setGaejungHideYn("N");
		t.setUserModifiedYn("N");         // 자동 생성 tombstone = 사용자 수정 아님 (실DB tombstone 도 'N')
		t.setDispYn("N");                 // ★ tombstone — 누적 조회에서 숨김
		t.setStartDate(startDate != null ? startDate : src.getStartDate());
		t.setSysId(sysId != null ? sysId : src.getSysId());
		return t;
	}

	/** 공백 정규화(레거시 TextUtil.replaceSpace 등가) — null/연속공백 → 단일, 양끝 trim */
	private static String norm(String s) {
		if (s == null) return "";
		return s.replaceAll("\\s+", " ").trim();
	}

	private static String safe(String s) { return s == null ? "" : s; }
}
