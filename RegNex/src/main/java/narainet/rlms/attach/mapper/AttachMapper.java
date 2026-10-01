/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/attach/mapper/AttachMapper.java
 *
 * 도메인 첨부(TB_ATTACH) Mapper.
 * polymorphic 참조 (refTable + refNo) 기반.
 */
package narainet.rlms.attach.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.rlms.attach.service.AttachVO;

@Mapper
public interface AttachMapper {

	/** 특정 도메인 row 의 첨부 목록 */
	List<AttachVO> selectAttachByRef(@Param("refTable") String refTable,
			@Param("refNo") Long refNo);

	/** PK 단건 조회 */
	AttachVO selectAttachByNo(@Param("attNo") Long attNo);

	/**
	 * 첨부의 소유 규정 번호 해석 — refTable 이 관련자료 자식(TB_REL_FILE/WORD/ORGN/IMG,
	 * IRVRSN_NO→TB_REL_VRSN.IPROM_NO) 또는 TB_PROM_WRK 일 때 IPROM_NO 반환, 그 외(공지/법령질의 등)는 null.
	 * 분류별 열람제한 가드(attachView/attachDownload)용.
	 */
	Long selectOwnerPromNoByAttach(@Param("attNo") Long attNo);

	int insertAttach(AttachVO vo);

	/** 특정 도메인 row 의 첨부 전체 삭제 (Java 명시 호출 — 트리거 미적용 케이스) */
	int deleteAttachByRef(@Param("refTable") String refTable,
			@Param("refNo") Long refNo);

	int deleteAttachByNo(@Param("attNo") Long attNo);

	/** 다운로드 횟수 +1 — 다운로드 성공 시. 실패해도 다운로드를 막지 않도록 호출부가 예외를 삼킨다. */
	int increaseDownloadCount(@Param("attNo") Long attNo);
}
