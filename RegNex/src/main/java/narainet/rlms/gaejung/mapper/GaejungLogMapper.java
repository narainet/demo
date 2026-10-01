/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/gaejung/mapper/GaejungLogMapper.java
 *
 * 개정 작업 로그(TB_GAEJUNG_LOG) Mapper.
 * 단순 4 컬럼(PROM/BUSEO/USER/INS_DT) 의 누가/언제/어느부서가 어느 법령을 등록·수정했는지 기록.
 * 화면 없이 prom insert/update 시점에 자동 1건 INSERT 만 수행.
 */
package narainet.rlms.gaejung.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface GaejungLogMapper {

	/** prom 작업 1건 로그 (null 허용) */
	int insertGaejungLog(@Param("promNo") Long promNo,
			@Param("buseoNo") Long buseoNo,
			@Param("userNo") Long userNo);
}
