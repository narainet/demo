/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/lawquest/service/LawQuestAdminVO.java
 *
 * 법령질의 답변권한자(레지스트리) VO — TB_LAWQUEST_ADMIN.
 *   레거시 orangeidea.lawquest.admin(모델 CountlawAdmin) 1:1 이관.
 *   ADMIN_SABUN(CHAR 7, PK=사번) / ADMIN_NAME(VARCHAR2 30, 성명).
 *   여기 등록된 사번만 법령질의 회신(respoCon) 작성 권한을 가짐(ROLE_ADMIN 은 bypass).
 */
package narainet.rlms.lawquest.service;

import java.io.Serializable;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
public class LawQuestAdminVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 답변권한자 사번 (ADMIN_SABUN, PK) */
	private String sabun;

	/** 답변권한자 성명 (ADMIN_NAME, 등록 시점 회원명) */
	private String name;

	/** 현재 회원명 (COMVNUSERMASTER.USER_NM 조인 — NULL 이면 레거시/미연동 사번) */
	private String userNm;

	/** 소속 부서명 (COMTNORGNZTINFO.ORGNZT_NM 조인) */
	private String orgnztNm;
}
