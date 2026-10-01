/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/BodyDiffServiceImpl.java
 */
package narainet.rlms.prom.service.impl;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.springframework.stereotype.Service;

import com.github.difflib.DiffUtils;
import com.github.difflib.patch.AbstractDelta;
import com.github.difflib.patch.DeltaType;
import com.github.difflib.patch.Patch;

import narainet.rlms.prom.service.BodyDiffService;
import narainet.rlms.prom.service.DiffLineVO;
import narainet.rlms.prom.service.ProvVrsnService;

/**
 * 본문 비교 Service 구현체
 *
 *  - diffByVrsnRows  : 메인 비교 (SQL FULL OUTER JOIN, ProvVrsnService 위임)
 *  - diffBylawByLibrary : 부칙(CLOB 한 덩어리) 라인 diff, java-diff-utils 사용
 *
 * <pre>
 * << 개정이력 >>
 *   2026.05.11   RLMS 전환팀   최초 생성
 * </pre>
 */
@Service("bodyDiffService")
public class BodyDiffServiceImpl extends EgovAbstractServiceImpl implements BodyDiffService {

	@Resource(name = "provVrsnService")
	private ProvVrsnService provVrsnService;

	@Override
	public List<DiffLineVO> diffByVrsnRows(Long leftPromNo, Long rightPromNo) {
		return provVrsnService.diffByPromNo(leftPromNo, rightPromNo);
	}

	@Override
	public List<DiffLineVO> diffBylawByLibrary(String leftBylaw, String rightBylaw) {
		List<DiffLineVO> result = new ArrayList<>();

		List<String> leftLines  = toLines(leftBylaw);
		List<String> rightLines = toLines(rightBylaw);

		Patch<String> patch = DiffUtils.diff(leftLines, rightLines);

		// 변화 없는 라인부터 시작 — 동일 라인은 모두 UNCHANGED 로 미리 채워둔다.
		int leftIdx = 0;
		int rightIdx = 0;
		int seq = 0;

		for (AbstractDelta<String> delta : patch.getDeltas()) {
			int srcPos = delta.getSource().getPosition();
			// delta 이전의 동일 라인들
			while (leftIdx < srcPos) {
				result.add(line("line-" + (++seq),
						leftLines.get(leftIdx),
						rightLines.get(rightIdx),
						"UNCHANGED"));
				leftIdx++;
				rightIdx++;
			}

			// delta 자체
			DeltaType type = delta.getType();
			List<String> srcLines = delta.getSource().getLines();
			List<String> tgtLines = delta.getTarget().getLines();
			switch (type) {
				case INSERT:
					for (String l : tgtLines) {
						result.add(line("line-" + (++seq), null, l, "ADDED"));
						rightIdx++;
					}
					break;
				case DELETE:
					for (String l : srcLines) {
						result.add(line("line-" + (++seq), l, null, "REMOVED"));
						leftIdx++;
					}
					break;
				case CHANGE:
					int max = Math.max(srcLines.size(), tgtLines.size());
					for (int i = 0; i < max; i++) {
						String l = i < srcLines.size() ? srcLines.get(i) : null;
						String r = i < tgtLines.size() ? tgtLines.get(i) : null;
						String ct = l == null ? "ADDED" : (r == null ? "REMOVED" : "MODIFIED");
						result.add(line("line-" + (++seq), l, r, ct));
					}
					leftIdx += srcLines.size();
					rightIdx += tgtLines.size();
					break;
				default:
					break;
			}
		}

		// delta 뒤의 남은 동일 라인
		while (leftIdx < leftLines.size() && rightIdx < rightLines.size()) {
			result.add(line("line-" + (++seq),
					leftLines.get(leftIdx),
					rightLines.get(rightIdx),
					"UNCHANGED"));
			leftIdx++;
			rightIdx++;
		}

		return result;
	}

	private static List<String> toLines(String s) {
		if (s == null || s.isEmpty()) {
			return new ArrayList<>();
		}
		return new ArrayList<>(Arrays.asList(s.split("\\r?\\n", -1)));
	}

	private static DiffLineVO line(String fullItem, String left, String right, String changeType) {
		DiffLineVO d = new DiffLineVO();
		d.setFullItem(fullItem);
		d.setLeftText(left);
		d.setRightText(right);
		d.setChangeType(changeType);
		return d;
	}
}
