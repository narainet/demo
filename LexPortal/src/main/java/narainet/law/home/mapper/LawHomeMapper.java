/*
 * 물리적 저장 경로: /src/main/java/narainet/law/home/mapper/LawHomeMapper.java
 */
package narainet.law.home.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface LawHomeMapper {

	/** 진행중 사건 수 — DEL_YN='N' 이고 결과가 미입력 또는 진행중(S001) */
	int countActiveSuits();

	/** 이번 달 신규 등록 사건 수 (REG_DT 기준) */
	int countNewSuitsThisMonth();

	/** 미처리 소송의뢰 건수 (STATUS_CD='S001' 신청) */
	int countPendingReqs();

	/** 승인대기 소송문서 건수 (APP_STS_CD='S001' 대기) */
	int countPendingDocs();

	/** 최근 등록 사건 5건 (SUIT_ID 역순) */
	List<Map<String, Object>> selectRecentSuits();
}
