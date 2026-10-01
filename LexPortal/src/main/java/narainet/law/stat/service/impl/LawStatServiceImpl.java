/*
 * 물리적 저장 경로: /src/main/java/narainet/law/stat/service/impl/LawStatServiceImpl.java
 *
 * 소송통계 7종 서비스 구현 — LAW_MODULE_DESIGN.md §7.12.
 * 매퍼 원시 집계행을 화면 표시용으로 조립(계 행·승소율·비율 계산은 여기서).
 *
 * ★집계 축 상수(레거시 enum 보존 — 임의 재분류 금지):
 *   구분 4축 = 민사 S001 / 행정 S002 / 국가 S012 / 심판 S009
 *   결과 그룹 = 진행중 {S001} / 승소 {S002,S003,S005,S006,S008,S997} / 패소 {S004,S100,S101,S102,S998}
 *   심급 3축 = 1심 S001 / 2심 S002 / 3심 S004
 */
package narainet.law.stat.service.impl;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import narainet.law.stat.mapper.LawStatMapper;
import narainet.law.stat.service.LawStatService;

@Service("lawStatService")
public class LawStatServiceImpl implements LawStatService {

	// ── 구분 4축 ──
	private static final String CK_MINSA = "S001";
	private static final String CK_HANGJUNG = "S002";
	private static final String CK_KUKGA = "S012";
	private static final String CK_SIMPAN = "S009";

	// ── 결과 그룹 ──
	private static final String RSLT_PROCESSING = "S001";
	private static final List<String> WIN_CDS = Arrays.asList("S002", "S003", "S005", "S006", "S008", "S997");
	private static final List<String> LOSE_CDS = Arrays.asList("S004", "S100", "S101", "S102", "S998");

	// ── 심급 3축 ──
	private static final String INST_1 = "S001";
	private static final String INST_2 = "S002";
	private static final String INST_3 = "S004";

	@Resource(name = "lawStatMapper")
	private LawStatMapper lawStatMapper;

	// ────────────────────────────────────────────── 공통 헬퍼

	private static long lng(Object o) {
		if (o == null) {
			return 0L;
		}
		if (o instanceof Number) {
			return ((Number) o).longValue();
		}
		try {
			return Long.parseLong(o.toString().trim());
		} catch (NumberFormatException e) {
			return 0L;
		}
	}

	private static String str(Object o) {
		return o == null ? "" : o.toString();
	}

	/** 승소율 = 승 / (승+패) * 100, 소수 1자리. 분모 0 = "0.0" (레거시 IFNULL→0) */
	private static String winRate(long win, long lose) {
		long denom = win + lose;
		if (denom <= 0) {
			return "0.0";
		}
		return String.format("%.1f", win * 100.0 / denom);
	}

	private Map<String, Object> baseParam() {
		Map<String, Object> p = new LinkedHashMap<>();
		p.put("minsaCd", CK_MINSA);
		p.put("hangjungCd", CK_HANGJUNG);
		p.put("kukgaCd", CK_KUKGA);
		p.put("simpanCd", CK_SIMPAN);
		p.put("processingCd", RSLT_PROCESSING);
		p.put("winCds", WIN_CDS);
		p.put("loseCds", LOSE_CDS);
		return p;
	}

	// ────────────────────────────────────────────── ① 소송현황

	@Override
	public List<Map<String, Object>> getSummary(String fromDate, String toDate) {
		Map<String, Object> param = baseParam();
		param.put("fromDate", fromDate);
		param.put("toDate", toDate);

		Map<String, Map<String, Object>> byKind = new LinkedHashMap<>();
		for (Map<String, Object> r : lawStatMapper.selectSummary(param)) {
			byKind.put(str(r.get("caseKindCd")), r);
		}

		String[][] rows = { { "TOT", "계" }, { CK_MINSA, "민사" }, { CK_HANGJUNG, "행정" },
				{ CK_KUKGA, "국가" }, { CK_SIMPAN, "심판" } };
		long tOcc = 0, tWin = 0, tLose = 0, tProc = 0;
		List<Map<String, Object>> out = new ArrayList<>();
		// 계는 맨 앞이지만 값은 뒤에서 채우므로 자리표시 후 갱신
		Map<String, Object> totRow = new LinkedHashMap<>();
		totRow.put("name", "계");
		out.add(totRow);
		for (int i = 1; i < rows.length; i++) {
			Map<String, Object> src = byKind.get(rows[i][0]);
			long occ = src == null ? 0 : lng(src.get("occurrenceCnt"));
			long win = src == null ? 0 : lng(src.get("winCnt"));
			long lose = src == null ? 0 : lng(src.get("loseCnt"));
			long proc = src == null ? 0 : lng(src.get("processingCnt"));
			tOcc += occ;
			tWin += win;
			tLose += lose;
			tProc += proc;
			out.add(summaryRow(rows[i][1], occ, win, lose, proc));
		}
		fillSummary(totRow, tOcc, tWin, tLose, tProc);
		return out;
	}

	private Map<String, Object> summaryRow(String name, long occ, long win, long lose, long proc) {
		Map<String, Object> m = new LinkedHashMap<>();
		m.put("name", name);
		fillSummary(m, occ, win, lose, proc);
		return m;
	}

	private void fillSummary(Map<String, Object> m, long occ, long win, long lose, long proc) {
		m.put("occurrenceCnt", occ);
		m.put("winCnt", win);
		m.put("loseCnt", lose);
		m.put("totalCnt", win + lose);
		m.put("rate", winRate(win, lose));
		m.put("processingCnt", proc);
	}

	// ────────────────────────────────────────────── ② 심급별

	@Override
	public List<Map<String, Object>> getInstance(String fromDate, String toDate) {
		Map<String, Object> param = baseParam();
		param.put("inst1", INST_1);
		param.put("inst2", INST_2);
		param.put("inst3", INST_3);
		param.put("fromDate", fromDate);
		param.put("toDate", toDate);

		Map<String, Map<String, Object>> byInst = new LinkedHashMap<>();
		for (Map<String, Object> r : lawStatMapper.selectInstance(param)) {
			byInst.put(str(r.get("instanceCd")), r);
		}

		String[][] rows = { { INST_1, "1심" }, { INST_2, "2심" }, { INST_3, "3심" } };
		long tM = 0, tH = 0, tK = 0, tS = 0;
		List<Map<String, Object>> body = new ArrayList<>();
		for (String[] row : rows) {
			Map<String, Object> src = byInst.get(row[0]);
			long m = src == null ? 0 : lng(src.get("minsaCnt"));
			long h = src == null ? 0 : lng(src.get("hangjungCnt"));
			long k = src == null ? 0 : lng(src.get("kukgaCnt"));
			long s = src == null ? 0 : lng(src.get("simpanCnt"));
			tM += m; tH += h; tK += k; tS += s;
			body.add(kindRow(row[1], m, h, k, s));
		}
		List<Map<String, Object>> out = new ArrayList<>();
		out.add(kindRow("합계", tM, tH, tK, tS));
		out.addAll(body);
		return out;
	}

	/** 구분4축 카운트 행 (totCnt=계열 합) */
	private Map<String, Object> kindRow(String name, long m, long h, long k, long s) {
		Map<String, Object> row = new LinkedHashMap<>();
		row.put("name", name);
		row.put("totCnt", m + h + k + s);
		row.put("minsaCnt", m);
		row.put("hangjungCnt", h);
		row.put("kukgaCnt", k);
		row.put("simpanCnt", s);
		return row;
	}

	// ────────────────────────────────────────────── ③ 유형별

	@Override
	public List<Map<String, Object>> getCaseType(String fromDate, String toDate) {
		Map<String, Object> param = baseParam();
		param.put("fromDate", fromDate);
		param.put("toDate", toDate);
		List<Map<String, Object>> raw = lawStatMapper.selectCaseType(param);
		long tTot = 0, tM = 0, tH = 0, tK = 0, tS = 0;
		List<Map<String, Object>> body = new ArrayList<>();
		for (Map<String, Object> r : raw) {
			long tot = lng(r.get("totCnt"));
			long m = lng(r.get("minsaCnt"));
			long h = lng(r.get("hangjungCnt"));
			long k = lng(r.get("kukgaCnt"));
			long s = lng(r.get("simpanCnt"));
			tTot += tot; tM += m; tH += h; tK += k; tS += s;
			Map<String, Object> row = new LinkedHashMap<>();
			row.put("name", str(r.get("name")));
			row.put("totCnt", tot);
			row.put("minsaCnt", m);
			row.put("hangjungCnt", h);
			row.put("kukgaCnt", k);
			row.put("simpanCnt", s);
			body.add(row);
		}
		List<Map<String, Object>> out = new ArrayList<>();
		Map<String, Object> tot = new LinkedHashMap<>();
		tot.put("name", "계");
		tot.put("totCnt", tTot);
		tot.put("minsaCnt", tM);
		tot.put("hangjungCnt", tH);
		tot.put("kukgaCnt", tK);
		tot.put("simpanCnt", tS);
		out.add(tot);
		out.addAll(body);
		return out;
	}

	// ────────────────────────────────────────────── ④ 부서별

	@Override
	public List<Map<String, Object>> getDept(String fromDate, String toDate) {
		Map<String, Object> param = baseParam();
		param.put("fromDate", fromDate);
		param.put("toDate", toDate);
		List<Map<String, Object>> raw = lawStatMapper.selectDept(param);
		long gTotL = 0, gTotG = 0, gML = 0, gMG = 0, gHL = 0, gHG = 0, gKL = 0, gKG = 0, gSL = 0, gSG = 0;
		List<Map<String, Object>> body = new ArrayList<>();
		for (Map<String, Object> r : raw) {
			long ml = lng(r.get("minsaLawer")), mg = lng(r.get("minsaGong"));
			long hl = lng(r.get("hangjungLawer")), hg = lng(r.get("hangjungGong"));
			long kl = lng(r.get("kukgaLawer")), kg = lng(r.get("kukgaGong"));
			long sl = lng(r.get("simpanLawer")), sg = lng(r.get("simpanGong"));
			long tl = ml + hl + kl + sl, tg = mg + hg + kg + sg;
			gML += ml; gMG += mg; gHL += hl; gHG += hg; gKL += kl; gKG += kg; gSL += sl; gSG += sg;
			gTotL += tl; gTotG += tg;
			body.add(deptRow(str(r.get("name")), tl, tg, ml, mg, hl, hg, kl, kg, sl, sg));
		}
		List<Map<String, Object>> out = new ArrayList<>();
		out.add(deptRow("계", gTotL, gTotG, gML, gMG, gHL, gHG, gKL, gKG, gSL, gSG));
		out.addAll(body);
		return out;
	}

	private Map<String, Object> deptRow(String name, long tl, long tg, long ml, long mg,
			long hl, long hg, long kl, long kg, long sl, long sg) {
		Map<String, Object> row = new LinkedHashMap<>();
		row.put("name", name);
		row.put("totLawer", tl);
		row.put("totGong", tg);
		row.put("minsaLawer", ml);
		row.put("minsaGong", mg);
		row.put("hangjungLawer", hl);
		row.put("hangjungGong", hg);
		row.put("kukgaLawer", kl);
		row.put("kukgaGong", kg);
		row.put("simpanLawer", sl);
		row.put("simpanGong", sg);
		return row;
	}

	// ────────────────────────────────────────────── ⑤ 대리인

	@Override
	public Map<String, Object> getAgent(String fromDate, String toDate) {
		Map<String, Object> param = baseParam();
		param.put("fromDate", fromDate);
		param.put("toDate", toDate);

		// 상단: 변호사선임(L)/공무원수행(G) × 구분
		long[] l = new long[4]; // minsa/hangjung/kukga/simpan
		long[] g = new long[4];
		for (Map<String, Object> r : lawStatMapper.selectAgentTop(param)) {
			String type = str(r.get("agentType"));
			int idx = kindIndex(str(r.get("caseKindCd")));
			if (idx < 0) {
				continue;
			}
			long cnt = lng(r.get("cnt"));
			if ("L".equals(type)) {
				l[idx] += cnt;
			} else if ("G".equals(type)) {
				g[idx] += cnt;
			}
		}
		long lTot = l[0] + l[1] + l[2] + l[3];
		long gTot = g[0] + g[1] + g[2] + g[3];
		long allTot = lTot + gTot;

		List<Map<String, Object>> topList = new ArrayList<>();
		topList.add(agentTopRow("계", l[0] + g[0], l[1] + g[1], l[2] + g[2], l[3] + g[3]));
		topList.add(agentTopRow("변호사 선임", l[0], l[1], l[2], l[3]));
		topList.add(agentTopRow("공무원 수행", g[0], g[1], g[2], g[3]));
		String officialRate = allTot <= 0 ? "0.0" : String.format("%.1f", gTot * 100.0 / allTot);

		// 하단: 대리인별(변호사 + 공무원)
		List<Map<String, Object>> bottomList = new ArrayList<>();
		for (Map<String, Object> r : lawStatMapper.selectAgentByLawyer(param)) {
			bottomList.add(agentBottomRow(r));
		}
		for (Map<String, Object> r : lawStatMapper.selectAgentByOfficial(param)) {
			bottomList.add(agentBottomRow(r));
		}

		Map<String, Object> out = new LinkedHashMap<>();
		out.put("topList", topList);
		out.put("officialRate", officialRate);
		out.put("bottomList", bottomList);
		return out;
	}

	private int kindIndex(String cd) {
		if (CK_MINSA.equals(cd)) return 0;
		if (CK_HANGJUNG.equals(cd)) return 1;
		if (CK_KUKGA.equals(cd)) return 2;
		if (CK_SIMPAN.equals(cd)) return 3;
		return -1;
	}

	private Map<String, Object> agentTopRow(String name, long m, long h, long k, long s) {
		Map<String, Object> row = new LinkedHashMap<>();
		row.put("name", name);
		row.put("totCnt", m + h + k + s);
		row.put("minsaCnt", m);
		row.put("hangjungCnt", h);
		row.put("kukgaCnt", k);
		row.put("simpanCnt", s);
		return row;
	}

	private Map<String, Object> agentBottomRow(Map<String, Object> r) {
		long proc = lng(r.get("processingCnt"));
		long term = lng(r.get("terminatedCnt"));
		long win = lng(r.get("winCnt"));
		long lose = lng(r.get("loseCnt"));
		Map<String, Object> row = new LinkedHashMap<>();
		row.put("name", str(r.get("name")));
		row.put("companyName", str(r.get("companyName")));
		row.put("totCnt", proc + term);
		row.put("processingCnt", proc);
		row.put("terminatedCnt", term);
		row.put("winCnt", win);
		row.put("loseCnt", lose);
		row.put("rate", winRate(win, lose));
		row.put("totAmt", lng(r.get("totAmt")));
		return row;
	}

	// ────────────────────────────────────────────── ⑥ 패소원인

	@Override
	public Map<String, Object> getLossCause(String fromDate, String toDate) {
		Map<String, Object> param = new LinkedHashMap<>();
		param.put("fromDate", fromDate);
		param.put("toDate", toDate);

		List<Map<String, Object>> raw = lawStatMapper.selectLossCause(param);
		long total = 0, max = 0;
		List<Map<String, Object>> body = new ArrayList<>();
		for (Map<String, Object> r : raw) {
			long cnt = lng(r.get("cnt"));
			total += cnt;
			if (cnt > max) {
				max = cnt;
			}
			Map<String, Object> row = new LinkedHashMap<>();
			row.put("codeName", str(r.get("codeName")));
			row.put("cnt", cnt);
			body.add(row);
		}
		// 비율(%) — 전체 대비
		for (Map<String, Object> row : body) {
			long cnt = lng(row.get("cnt"));
			row.put("rate", total <= 0 ? "0.0" : String.format("%.1f", cnt * 100.0 / total));
		}
		List<Map<String, Object>> list = new ArrayList<>();
		Map<String, Object> tot = new LinkedHashMap<>();
		tot.put("codeName", "계");
		tot.put("cnt", total);
		tot.put("rate", total <= 0 ? "0.0" : "100.0");
		list.add(tot);
		list.addAll(body);

		Map<String, Object> out = new LinkedHashMap<>();
		out.put("list", list);
		out.put("maxCnt", max);
		out.put("total", total);
		return out;
	}

	// ────────────────────────────────────────────── ⑦ 사건지번

	@Override
	public List<Map<String, Object>> getLandJibun(String fromDate, String toDate, List<String> rsltCds) {
		Map<String, Object> param = new LinkedHashMap<>();
		param.put("fromDate", fromDate);
		param.put("toDate", toDate);
		if (rsltCds != null && !rsltCds.isEmpty()) {
			param.put("rsltCds", rsltCds);
		}
		List<Map<String, Object>> raw = lawStatMapper.selectLandJibun(param);
		List<Map<String, Object>> out = new ArrayList<>();
		for (Map<String, Object> r : raw) {
			String loc = str(r.get("location")).trim();
			String jibun = str(r.get("jibun")).trim();
			String address = (loc + " " + jibun).trim();
			Map<String, Object> row = new LinkedHashMap<>();
			row.put("suitId", lng(r.get("suitId")));
			row.put("caseNo", str(r.get("caseNo")));
			row.put("caseNm", str(r.get("caseNm")));
			row.put("location", loc);
			row.put("jibun", jibun);
			row.put("address", address);
			out.add(row);
		}
		return out;
	}

	@Override
	public List<String> buildLandResultCodes(boolean processing, boolean terminate, boolean win, boolean lose) {
		// 전체 선택(또는 전무) = 무필터
		if ((processing && terminate && win && lose) || (!processing && !terminate && !win && !lose)) {
			return null;
		}
		List<String> codes = new ArrayList<>();
		if (processing) {
			codes.add(RSLT_PROCESSING);
		}
		// 종결 = 승소 + 패소 그룹 합집합
		if (win || terminate) {
			for (String c : WIN_CDS) {
				if (!codes.contains(c)) {
					codes.add(c);
				}
			}
		}
		if (lose || terminate) {
			for (String c : LOSE_CDS) {
				if (!codes.contains(c)) {
					codes.add(c);
				}
			}
		}
		return codes;
	}
}
