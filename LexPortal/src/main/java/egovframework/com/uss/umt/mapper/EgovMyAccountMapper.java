/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/umt/mapper/EgovMyAccountMapper.java
 */
package egovframework.com.uss.umt.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import egovframework.com.uss.umt.service.LoginHistVO;

@Mapper
public interface EgovMyAccountMapper {

	/** 본인(ESNTL_ID=uniqId) 접속로그 목록 — 최신순 페이징 */
	List<LoginHistVO> selectMyLoginLogList(@Param("uniqId") String uniqId, @Param("vo") LoginHistVO vo);

	/** 본인 접속로그 총건수 */
	int selectMyLoginLogCnt(@Param("uniqId") String uniqId, @Param("vo") LoginHistVO vo);

	/** 본인 프로필 — 일반회원(GNR, COMTNGNRLMBER) */
	Map<String, Object> selectMyProfileGnr(@Param("uniqId") String uniqId);

	/** 본인 프로필 — 업무사용자(USR, COMTNEMPLYRINFO) */
	Map<String, Object> selectMyProfileUsr(@Param("uniqId") String uniqId);

	/** 본인 프로필 수정(이메일/휴대전화) — GNR */
	int updateMyProfileGnr(@Param("uniqId") String uniqId, @Param("email") String email, @Param("mbtlnum") String mbtlnum);

	/** 본인 프로필 수정(이메일/휴대전화) — USR */
	int updateMyProfileUsr(@Param("uniqId") String uniqId, @Param("email") String email, @Param("mbtlnum") String mbtlnum);
}
