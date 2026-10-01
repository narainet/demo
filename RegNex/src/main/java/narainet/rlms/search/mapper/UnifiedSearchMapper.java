/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/search/mapper/UnifiedSearchMapper.java
 *
 * 통합검색 매퍼 — 4축(규정제목/조문/별표서식/자료) 검색.
 * 파라미터는 Map (keyword, ftKeyword, firstIndex, recordCountPerPage,
 *   cateNo, gubunIds(SGUBUN_ID 코드 목록), applyReadGate, readerEsntlId, readerOrgnztId).
 */
package narainet.rlms.search.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface UnifiedSearchMapper {

	/** ① 규정(현행) 제목 검색 — 공백무시 매칭, 정확>선두>포함 순 정렬 */
	List<Map<String, Object>> searchProms(Map<String, Object> p);

	int countProms(Map<String, Object> p);

	/** ② 조문 검색 — Oracle Text 본문(누적 최신회차) UNION 레거시 조문 제목경로(TB_SRC_STORED.SFULL_TITLE) */
	List<Map<String, Object>> searchProvs(Map<String, Object> p);

	int countProvs(Map<String, Object> p);

	/** ③ 별표/별지서식 검색 — TB_DOCU 누적 최신본 제목/그룹제목 */
	List<Map<String, Object>> searchDocus(Map<String, Object> p);

	int countDocus(Map<String, Object> p);

	/** ④ 자료 검색 — 관련자료 FILE/WORD 제목 + WORD 자체변환 본문(신규 업로드분) */
	List<Map<String, Object>> searchRels(Map<String, Object> p);

	int countRels(Map<String, Object> p);

	/** ⑤ 게시판 글 검색 — 제목·본문. 대상 bbsId 목록(SEARCH_INCLD_AT='Y'+열람가능)은 서비스가 파라미터 'bbsIds'로 주입. */
	List<Map<String, Object>> searchBbs(Map<String, Object> p);

	int countBbs(Map<String, Object> p);

	/** 통합검색 노출(SEARCH_INCLD_AT='Y')·사용중(USE_AT='Y') 게시판 ID 목록 — 서비스가 열람권한으로 재필터. */
	List<String> selectSearchableBbsIds();

	/** ⑥ FAQ 검색 — COMTNFAQINFO 질문제목·질문내용·답변내용(전부 공백무시 매칭). */
	List<Map<String, Object>> searchFaq(Map<String, Object> p);

	int countFaq(Map<String, Object> p);

	/** 검색어 적재 — TB_STATS_KWD 1행(ICNT=1, SINS_DT=오늘) */
	int insertKeywordStat(@Param("id") int id, @Param("kwd") String kwd);

	/** 최근 days 일 인기 검색어 상위 topN */
	List<String> selectPopularKeywords(@Param("days") int days, @Param("topN") int topN);
}
