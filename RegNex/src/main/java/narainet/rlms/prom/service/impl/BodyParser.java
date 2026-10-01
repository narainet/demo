/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/impl/BodyParser.java
 *
 * 조항 HTML 본문(TB_PROV_HTML.SCONTENTS) → 단위 row 목록 분해기.
 *
 * 책임:
 *   1) HTML 을 Jsoup 으로 파싱
 *   2) 블록 요소(p, div, li, h1~h6) 단위로 텍스트 추출
 *   3) 한국 법령 표기 정규식(예: "제3조", "①", "1.") 으로 단위 식별자 추정
 *   4) ProvVrsnVO 리스트 생성 (식별자/계층/순서 부여)
 *
 * ※ 레거시(orangeidea.lims.fulltext.provision.ProvisionVersionUtil) 의 분해 알고리즘이
 *   훨씬 정교함. 본 BodyParser 는 1차 베이스 분해기로, 레거시 로직을 단계적으로 이식하기 위한
 *   골격을 제공한다. 운영 데이터로 검증 후 정밀화.
 *
 * 단위 유형(SUNIT_TYPE) 코드 (잠정):
 *   JO     : 조 ("제N조")
 *   HANG   : 항 ("①", "②"... 또는 "1."  "2.")
 *   HO     : 호 ("가.", "나."... 또는 "1)", "2)")
 *   LINE   : 그 외 일반 문장/줄
 */
package narainet.rlms.prom.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import narainet.rlms.prom.service.ProvVrsnVO;

public class BodyParser {

	private static final Logger LOGGER = LoggerFactory.getLogger(BodyParser.class);

	// 정규식 — 한국 법령 표기
	private static final Pattern JO_PATTERN   = Pattern.compile("^\\s*제\\s*([0-9]+)\\s*조.*");
	private static final Pattern HANG_PATTERN = Pattern.compile("^\\s*([\\u2460-\\u2473\\u3251-\\u325F\\u32B1-\\u32BF]|[0-9]+\\.)\\s.*");
	private static final Pattern HO_PATTERN   = Pattern.compile("^\\s*([가-힣]\\.|[0-9]+\\))\\s.*");

	/**
	 * HTML 본문을 단위 row 리스트로 분해.
	 * @param promNo       법령 PK
	 * @param contents     본문 HTML (CLOB)
	 * @param startDate    적용 시작일
	 * @param sysId        시스템 ID
	 * @param gaejungType  기본 개정 유형
	 * @return ProvVrsnVO 리스트 (promNo, fullItem, item, subItem, unitType, level, index,
	 *         contents, startDate, sysId, gaejungType 채워짐. provVrsnNo 는 호출자가 채번)
	 */
	public List<ProvVrsnVO> decompose(Long promNo, String contents,
			String startDate, String sysId, String gaejungType) {

		List<ProvVrsnVO> result = new ArrayList<>();
		if (contents == null || contents.trim().isEmpty()) {
			return result;
		}

		Document doc = Jsoup.parse(contents);
		Elements blocks = doc.select("p, div, li, h1, h2, h3, h4, h5, h6");

		String currentJo   = null;
		String currentHang = null;
		int jindex = 0;
		int hindex = 0;
		int oindex = 0;
		int globalIndex = 0;

		// 블록이 하나도 없으면 텍스트 전체를 한 LINE row 로
		if (blocks.isEmpty()) {
			String plain = doc.text();
			if (!plain.trim().isEmpty()) {
				result.add(buildVrsn(promNo, "L-1", null, null,
						"LINE", 0, ++globalIndex, plain, startDate, sysId, gaejungType));
			}
			return result;
		}

		for (Element el : blocks) {
			String text = el.text();
			if (text == null || text.trim().isEmpty()) {
				continue;
			}
			globalIndex++;

			Matcher mJo = JO_PATTERN.matcher(text);
			if (mJo.matches()) {
				jindex = Integer.parseInt(mJo.group(1));
				currentJo = "제" + jindex + "조";
				currentHang = null;
				hindex = 0;
				oindex = 0;
				result.add(buildVrsn(promNo, currentJo, currentJo, null,
						"JO", 0, jindex, text, startDate, sysId, gaejungType));
				continue;
			}

			Matcher mHang = HANG_PATTERN.matcher(text);
			if (mHang.matches() && currentJo != null) {
				hindex++;
				currentHang = mHang.group(1);
				String full = currentJo + "-" + currentHang;
				oindex = 0;
				result.add(buildVrsn(promNo, full, currentJo, currentHang,
						"HANG", 1, hindex, text, startDate, sysId, gaejungType));
				continue;
			}

			Matcher mHo = HO_PATTERN.matcher(text);
			if (mHo.matches() && currentJo != null && currentHang != null) {
				oindex++;
				String hoKey = mHo.group(1);
				String full = currentJo + "-" + currentHang + "-" + hoKey;
				result.add(buildVrsn(promNo, full, currentJo,
						currentHang + "-" + hoKey,
						"HO", 2, oindex, text, startDate, sysId, gaejungType));
				continue;
			}

			// 어떤 패턴에도 매칭 안 되는 일반 블록 — LINE 유형
			String fullItem = (currentJo != null ? currentJo + "-" : "")
					+ "L-" + globalIndex;
			result.add(buildVrsn(promNo, fullItem, currentJo, null,
					"LINE", currentJo != null ? 1 : 0, globalIndex,
					text, startDate, sysId, gaejungType));
		}

		LOGGER.debug("BodyParser.decompose: promNo={}, units={}", promNo, result.size());
		return result;
	}

	private ProvVrsnVO buildVrsn(Long promNo, String fullItem, String item, String subItem,
			String unitType, Integer level, Integer index, String contents,
			String startDate, String sysId, String gaejungType) {
		ProvVrsnVO v = new ProvVrsnVO();
		v.setPromNo(promNo);
		v.setFullItem(fullItem);
		// SITEM 은 TB_PROV_VRSN NOT NULL — 태그/비조문 본문(블록없음 LINE, 또는 선행 "제N조" 없는 LINE)은
		// item(조)이 null 이라 ORA-01400 으로 저장이 통째로 롤백되던 버그. 항상 non-null 인 fullItem 으로 폴백.
		v.setItem(item != null ? item : fullItem);
		// ↓ TB_PROV_VRSN NOT NULL 컬럼 전부 non-null 보장 — insertProvVrsnBatch 가 raw #{} 바인딩이라
		//   하나라도 null 이면 ORA-01400 → @Transactional 전체 롤백 → 조항 저장 실패.
		//   (BodyParser 경로[HTML 조항 단건 저장]는 subItem/nativeType 를 안 채워 원래부터 항상 깨져 있었음.)
		v.setSubItem((subItem != null && !subItem.isEmpty()) ? subItem : "00");
		v.setUnitType(unitType);
		v.setNativeType(nativeTypeOf(unitType));   // SNATIVE_TYPE NOT NULL — buildVrsn 이 아예 세팅 안 하던 누락
		v.setLevel(level);
		v.setIndex(index);
		v.setContents(contents);
		v.setSearchText(contents);
		v.setStartDate((startDate != null && !startDate.isEmpty())
				? startDate : new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()));
		v.setSysId((sysId == null || sysId.isEmpty()) ? "DEFAULT" : sysId);
		v.setGaejungType((gaejungType != null && !gaejungType.isEmpty()) ? gaejungType : "NEW");
		v.setStyleId("NORMAL");   // SSTYLE_ID NOT NULL
		v.setDispYn("Y");
		v.setGaejungHideYn("N");
		v.setUserModifiedYn("N");
		return v;
	}

	/** SUNIT_TYPE → SNATIVE_TYPE 기본 매핑 (TB_PROV_VRSN NOT NULL). 비조문/LINE 은 S_HANG 기본. */
	private String nativeTypeOf(String unitType) {
		if ("JO".equals(unitType))   return "S_JO";
		if ("HANG".equals(unitType)) return "S_HANG";
		if ("HO".equals(unitType))   return "S_HO";
		return "S_HANG";
	}
}
