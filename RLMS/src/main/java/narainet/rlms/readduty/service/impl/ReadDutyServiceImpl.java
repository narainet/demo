/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/readduty/service/impl/ReadDutyServiceImpl.java
 */
package narainet.rlms.readduty.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.rlms.readduty.mapper.ReadDutyMapper;
import narainet.rlms.readduty.service.ReadDutyService;
import narainet.rlms.readduty.service.ReadDutyVO;

@Service("readDutyService")
public class ReadDutyServiceImpl extends EgovAbstractServiceImpl implements ReadDutyService {

	@Resource(name = "readDutyMapper")
	private ReadDutyMapper readDutyMapper;

	@Resource(name = "egovReadDutyIdGnrService")
	private EgovIdGnrService readDutyIdGnrService;

	@Override
	public ReadDutyVO selectDutyByPromNo(Long promNo) {
		ReadDutyVO duty = readDutyMapper.selectDutyByPromNo(promNo);
		if (duty != null) {
			duty.setTgtList(readDutyMapper.selectDutyTgts(duty.getDutyNo()));
		}
		return duty;
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void saveDuty(ReadDutyVO vo, List<String> tgts) throws Exception {
		// 대상 파싱/검증 — "DEPT:ORGNZT_ID" / "USER:ESNTL_ID". 전사가 아니면 1건 이상 필수.
		List<String[]> parsed = new ArrayList<>();
		if (!"Y".equals(vo.getAllYn())) {
			vo.setAllYn("N");
			if (tgts != null) {
				for (String t : tgts) {
					int p = t == null ? -1 : t.indexOf(':');
					if (p <= 0 || p >= t.length() - 1) {
						continue;
					}
					String ty = t.substring(0, p);
					String id = t.substring(p + 1);
					if (!"DEPT".equals(ty) && !"USER".equals(ty)) {
						continue;
					}
					parsed.add(new String[] { ty, id });
				}
			}
			if (parsed.isEmpty()) {
				throw new IllegalStateException("열람 대상을 1건 이상 지정해야 합니다. (전사 대상이면 '전사'를 선택)");
			}
		}

		// upsert — 회차당 1건(UNIQUE IPROM_NO). 수정 시 확인 기록(CHK)은 보존(이미 읽은 증빙 유지).
		ReadDutyVO existing = readDutyMapper.selectDutyByPromNo(vo.getPromNo());
		if (existing == null) {
			vo.setDutyNo(readDutyIdGnrService.getNextLongId());
			readDutyMapper.insertDuty(vo);
		} else {
			vo.setDutyNo(existing.getDutyNo());
			readDutyMapper.updateDuty(vo);
			readDutyMapper.deleteDutyTgts(vo.getDutyNo());
		}
		for (String[] t : parsed) {
			readDutyMapper.insertDutyTgt(vo.getDutyNo(), t[0], t[1]);
		}
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void deleteDuty(Long dutyNo) {
		// 지정 취소 = 의무 철회 — 확인 기록까지 제거 (FK CASCADE 있으나 의도를 명시)
		readDutyMapper.deleteDutyChks(dutyNo);
		readDutyMapper.deleteDutyTgts(dutyNo);
		readDutyMapper.deleteDuty(dutyNo);
	}

	@Override
	public List<Map<String, Object>> selectMyDuties(String esntlId, String orgnztId, String userSe, int n) {
		return readDutyMapper.selectMyDuties(esntlId, orgnztId, userSe, n);
	}

	@Override
	public Map<String, Object> selectMyDutyForProm(Long promNo, String esntlId, String orgnztId, String userSe) {
		return readDutyMapper.selectMyDutyForProm(promNo, esntlId, orgnztId, userSe);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void touchRead(Long dutyNo, String esntlId, String userNm, String orgnztId) {
		if (dutyNo == null || esntlId == null || esntlId.isEmpty()) {
			return;
		}
		readDutyMapper.touchRead(dutyNo, esntlId, userNm, orgnztId);
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public void confirmDuty(Long dutyNo, String esntlId, String userNm, String orgnztId, String userSe) {
		// 서버측 대상 재검증 — 화면 가드 우회(직접 POST) 방지. 숙지는 대상자 본인만 남길 수 있다.
		if (readDutyMapper.countDutyTarget(dutyNo, esntlId, orgnztId, userSe) < 1) {
			throw new IllegalStateException("이 규정의 필수 열람 대상이 아닙니다.");
		}
		readDutyMapper.confirmRead(dutyNo, esntlId, userNm, orgnztId);
	}

	@Override
	public List<Map<String, Object>> selectDutyStatList(String keyword) {
		return readDutyMapper.selectDutyStatList(keyword);
	}

	@Override
	public Map<String, Object> selectDutySummary(Long dutyNo) {
		return readDutyMapper.selectDutySummary(dutyNo);
	}

	@Override
	public List<Map<String, Object>> selectDutyUserMatrix(Long dutyNo) {
		return readDutyMapper.selectDutyUserMatrix(dutyNo);
	}

	@Override
	public List<Map<String, Object>> selectDutyDeptSummary(Long dutyNo) {
		return readDutyMapper.selectDutyDeptSummary(dutyNo);
	}

	@Override
	public List<Map<String, Object>> selectUserSearch(String keyword) {
		return readDutyMapper.selectUserSearch(keyword);
	}
}
