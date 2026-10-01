/*
 * 물리적 저장 경로: /src/main/java/narainet/law/schedule/service/impl/LawScheduleServiceImpl.java
 *
 * 일정관리 (LAW_MODULE_DESIGN.md §7.5) — 기일(LAW_SUIT_PROG PROG_KIND_CD='S001') 조회·단건 등록·삭제.
 *   등록화면 진행상황과 같은 테이블 공유(단건 insert/delete — 사건 저장의 전량교체와 별개).
 */
package narainet.law.schedule.service.impl;

import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import narainet.law.schedule.mapper.LawScheduleMapper;
import narainet.law.schedule.service.LawScheduleService;
import narainet.law.schedule.service.LawScheduleVO;

@Service("lawScheduleService")
public class LawScheduleServiceImpl implements LawScheduleService {

	private static final DateTimeFormatter YM = DateTimeFormatter.ofPattern("yyyyMM");
	private static final DateTimeFormatter YMD = DateTimeFormatter.ofPattern("yyyyMMdd");

	@Resource(name = "lawScheduleMapper")
	private LawScheduleMapper lawScheduleMapper;

	@Resource(name = "egovLawProgIdGnrService")
	private EgovIdGnrService progIdGnrService;

	@Override
	public List<LawScheduleVO> getHearings(LawScheduleVO vo) throws Exception {
		return lawScheduleMapper.selectHearings(vo);
	}

	@Override
	public List<LawScheduleVO> getDay(String ymd) throws Exception {
		LawScheduleVO vo = new LawScheduleVO();
		vo.setTargetDt(ymd);
		return lawScheduleMapper.selectHearings(vo);
	}

	@Override
	public List<LawScheduleVO> getWeek(String fromYmd, String toYmd) throws Exception {
		LawScheduleVO vo = new LawScheduleVO();
		vo.setSearchFrom(fromYmd);
		vo.setSearchTo(toYmd);
		return lawScheduleMapper.selectHearings(vo);
	}

	@Override
	public List<LawScheduleVO> getMonth(String ym) throws Exception {
		String m = (ym == null || ym.replaceAll("[^0-9]", "").length() < 6) ? YearMonth.now().format(YM)
				: ym.replaceAll("[^0-9]", "").substring(0, 6);
		YearMonth yearMonth = YearMonth.parse(m, YM);
		LawScheduleVO vo = new LawScheduleVO();
		vo.setSearchFrom(yearMonth.atDay(1).format(YMD));
		vo.setSearchTo(yearMonth.atEndOfMonth().format(YMD));
		return lawScheduleMapper.selectHearings(vo);
	}

	@Override
	public LawScheduleVO getHearing(Long progId) throws Exception {
		return lawScheduleMapper.selectHearing(progId);
	}

	@Override
	@Transactional
	public Long save(LawScheduleVO vo, String userId) throws Exception {
		vo.setProgId((long) progIdGnrService.getNextIntegerId());
		lawScheduleMapper.insertHearing(vo);
		return vo.getProgId();
	}

	@Override
	@Transactional
	public void delete(Long progId) throws Exception {
		lawScheduleMapper.deleteHearing(progId);
	}

	/** 오늘(YYYYMMDD) */
	public static String today() {
		return LocalDate.now().format(YMD);
	}
}
