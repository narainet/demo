/*
 * 물리적 저장 경로: /src/main/java/narainet/law/cost/service/LawInterestCalc.java
 *
 * 지연이자 일할 계산 — 레거시 레거시 송무시스템 ComputeInterest 1:1 이식 (§7.4).
 *   · 이자 = (종료 연중일 − 시작 연중일 + 1) × 이율 ÷ (365|366) × 원금, long 절사(내림).
 *   · 일수는 포함(+1). 다년도는 시작연 잔여일 + 중간연 만액(rate×money) + 종료연 경과일 합산.
 *   · 윤년(366) 반영. 이율은 분수(퍼센트/100). 시작>종료면 스왑.
 *   레거시의 'YYYYMMDD'/'YYYY.MM.DD' 월 오프바이원 버그는 재현하지 않음 — 팝업 실경로(점표기)의
 *   올바른 해석(월-1)만 이식(LocalDate 사용).
 */
package narainet.law.cost.service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

public final class LawInterestCalc {

	private static final DateTimeFormatter YMD = DateTimeFormatter.ofPattern("yyyyMMdd");

	private LawInterestCalc() {
	}

	/** YYYYMMDD 파싱 (그 외 형식 숫자만 남겨 8자리로 절단) */
	private static LocalDate parse(String ymd) {
		if (ymd == null) {
			return null;
		}
		String d = ymd.replaceAll("[^0-9]", "");
		if (d.length() < 8) {
			return null;
		}
		return LocalDate.parse(d.substring(0, 8), YMD);
	}

	/**
	 * 한 기간의 지연이자.
	 *
	 * @param sYmd        시작일 (YYYYMMDD 또는 yyyy-MM-dd)
	 * @param eYmd        종료일
	 * @param money       원금
	 * @param ratePercent 이율(연 %, 예: 12)
	 * @return 이자(원, 절사). 입력 불충분 시 0.
	 */
	public static long compute(String sYmd, String eYmd, long money, double ratePercent) {
		LocalDate s = parse(sYmd);
		LocalDate e = parse(eYmd);
		if (s == null || e == null || money <= 0 || ratePercent <= 0) {
			return 0L;
		}
		if (s.isAfter(e)) {
			LocalDate t = s;
			s = e;
			e = t;
		}
		double rate = ratePercent / 100.0;
		int sy = s.getYear();
		int ey = e.getYear();

		if (sy == ey) {
			int denom = s.isLeapYear() ? 366 : 365;
			return (long) ((e.getDayOfYear() - s.getDayOfYear() + 1) * rate / denom * money);
		}

		long sum = 0L;
		int sDenom = s.isLeapYear() ? 366 : 365;
		int dayS = sDenom - s.getDayOfYear() + 1; // 시작연 잔여일(포함)
		sum += (long) (dayS * rate / sDenom * money);
		for (int y = sy + 1; y < ey; y++) {
			sum += (long) (rate * money); // 중간연 만액
		}
		int eDenom = e.isLeapYear() ? 366 : 365;
		int dayE = e.getDayOfYear(); // 종료연 경과일
		sum += (long) (dayE * rate / eDenom * money);
		return sum;
	}
}
