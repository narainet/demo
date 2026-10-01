/*
 * 물리적 저장 경로: /src/main/java/narainet/law/calcset/service/impl/LawCalcsetServiceImpl.java
 *
 * 계산기 요율설정 (LAW_MODULE_DESIGN.md §7.13) + 계산기용 유효요율 조회(§7.4).
 *  - 탭(family): 인지액=STAMP+STAMP_MULT / 송달료=POST_UNIT+POST_COUNT / 변호사비=LAWYER / 법정이율=LEGAL_INT.
 *  - 세트 저장=검증 후 family+applyDt 전량 교체. 삭제=미래 물리삭제 / 과거·현행 USE_YN 'N'(이력 보존).
 *  - 검증: 구간 하한 중복·역전 금지, 율·금액 음수 금지.
 */
package narainet.law.calcset.service.impl;

import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.law.calcset.mapper.LawCalcRateMapper;
import narainet.law.calcset.service.LawCalcRateVO;
import narainet.law.calcset.service.LawCalcsetService;

@Service("lawCalcsetService")
public class LawCalcsetServiceImpl implements LawCalcsetService {

	@Resource(name = "lawCalcRateMapper")
	private LawCalcRateMapper lawCalcRateMapper;

	@Resource(name = "egovLawCalcRateIdGnrService")
	private EgovIdGnrService calcRateIdGnrService;

	private static String now() {
		return new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
	}

	private static String todayYmd() {
		return new SimpleDateFormat("yyyyMMdd").format(new Date());
	}

	/** 탭 → calcType family */
	private List<String> familyOf(String tab) {
		if ("STAMP".equals(tab)) {
			return Arrays.asList("STAMP", "STAMP_MULT");
		}
		if ("POST".equals(tab)) {
			return Arrays.asList("POST_UNIT", "POST_COUNT");
		}
		if ("LAWYER".equals(tab)) {
			return Arrays.asList("LAWYER");
		}
		if ("LEGAL_INT".equals(tab)) {
			return Arrays.asList("LEGAL_INT");
		}
		throw new IllegalArgumentException("알 수 없는 요율 탭입니다: " + tab);
	}

	@Override
	public List<LawCalcRateVO> getEffectiveRates(String baseDt) throws Exception {
		String d = (baseDt == null || baseDt.replaceAll("[^0-9]", "").length() < 8) ? todayYmd()
				: baseDt.replaceAll("[^0-9]", "").substring(0, 8);
		return lawCalcRateMapper.selectEffectiveRates(d);
	}

	@Override
	public List<Map<String, Object>> getSetDates(String tab) throws Exception {
		return lawCalcRateMapper.selectSetDates(familyOf(tab));
	}

	@Override
	public List<LawCalcRateVO> getSetRows(String tab, String applyDt) throws Exception {
		return lawCalcRateMapper.selectSetRows(familyOf(tab), normalizeDt(applyDt));
	}

	@Override
	public String getLatestApplyDt(String tab) throws Exception {
		return lawCalcRateMapper.selectLatestApplyDt(familyOf(tab));
	}

	@Override
	@Transactional
	public void saveSet(String tab, String applyDt, List<LawCalcRateVO> rows, String userId) throws Exception {
		List<String> family = familyOf(tab);
		String dt = normalizeDt(applyDt);
		if (dt == null) {
			throw new IllegalArgumentException("적용시작일을 올바르게 입력하세요.");
		}
		if (rows == null || rows.isEmpty()) {
			throw new IllegalArgumentException("요율 행이 없습니다.");
		}
		validate(family, rows);

		String ts = now();
		lawCalcRateMapper.deleteSetPhysical(family, dt);
		for (LawCalcRateVO r : rows) {
			r.setRateId((long) calcRateIdGnrService.getNextIntegerId());
			r.setApplyDt(dt);
			r.setUseYn("Y");
			r.setRegUserId(userId);
			r.setRegDt(ts);
			lawCalcRateMapper.insertRate(r);
		}
	}

	@Override
	@Transactional
	public void deleteSet(String tab, String applyDt, String userId) throws Exception {
		List<String> family = familyOf(tab);
		String dt = normalizeDt(applyDt);
		if (dt == null) {
			throw new IllegalArgumentException("적용시작일이 올바르지 않습니다.");
		}
		if (dt.compareTo(todayYmd()) > 0) {
			lawCalcRateMapper.deleteSetPhysical(family, dt); // 미래 세트 = 물리삭제
		} else {
			lawCalcRateMapper.softDeleteSet(family, dt);     // 과거·현행 = 이력 보존
		}
	}

	private static String normalizeDt(String d) {
		if (d == null) {
			return null;
		}
		String s = d.replaceAll("[^0-9]", "");
		return s.length() == 8 ? s : null;
	}

	/** 구간 하한 중복·역전 금지, 율·금액 음수 금지, calcType 소속 검증. */
	private void validate(List<String> family, List<LawCalcRateVO> rows) {
		Long prevSection = null;
		String prevType = null;
		for (LawCalcRateVO r : rows) {
			if (r.getCalcType() == null || !family.contains(r.getCalcType())) {
				throw new IllegalArgumentException("이 탭에 속하지 않는 요율 종류가 있습니다.");
			}
			if (r.getRateVal() != null && r.getRateVal().signum() < 0) {
				throw new IllegalArgumentException("율·값은 음수일 수 없습니다.");
			}
			if (r.getAddAmt() != null && r.getAddAmt() < 0) {
				throw new IllegalArgumentException("가산액·고정액은 음수일 수 없습니다.");
			}
			if (r.getSectionAmt() != null && r.getSectionAmt() < 0) {
				throw new IllegalArgumentException("구간 하한은 음수일 수 없습니다.");
			}
			// 구간표(SECTION_AMT 존재) 타입은 같은 타입 내 하한 오름차순·중복 금지
			boolean isBracket = r.getSectionAmt() != null;
			if (isBracket) {
				if (r.getCalcType().equals(prevType)) {
					if (prevSection != null && r.getSectionAmt().longValue() == prevSection.longValue()) {
						throw new IllegalArgumentException("구간 하한이 중복되었습니다: " + r.getSectionAmt());
					}
					if (prevSection != null && r.getSectionAmt() < prevSection) {
						throw new IllegalArgumentException("구간 하한이 오름차순이 아닙니다.");
					}
				} else {
					prevSection = null;
				}
				prevSection = r.getSectionAmt();
				prevType = r.getCalcType();
			}
		}
		// LAWYER·STAMP 구간표는 최소 1개 구간 필요(율 계산 근거)
		if (family.contains("LAWYER") || family.contains("STAMP")) {
			boolean hasBracket = false;
			for (LawCalcRateVO r : rows) {
				if (("LAWYER".equals(r.getCalcType()) || "STAMP".equals(r.getCalcType())) && r.getSectionAmt() != null) {
					hasBracket = true;
					break;
				}
			}
			if (!hasBracket) {
				throw new IllegalArgumentException("구간표에는 최소 1개의 구간이 필요합니다.");
			}
		}
	}
}
