/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/BoardReadGuard.java
 *
 * 게시판별 열람 권한 강제.
 *
 * URL 층(L6 메뉴파생)만으로는 게시판을 구분할 수 없다. 사용자 열람 URL 은 슬래시가 3개 이상이라
 * \A/cop/bbs/user/.*\Z 라는 "폴더" 패턴으로 접히고, 역할은 DISTINCT 로 합집합된다.
 * 즉 게시판 A 를 조회자에게 열어두면, 게시판 B 를 편집자 전용 메뉴로 만들어도
 * 조회자가 bbsId 만 바꿔 B 를 열 수 있다(메뉴는 GNB 에서 감출 뿐이다).
 *
 * 그래서 게시판 본문·댓글·만족도의 사용자 동선은 모두 이 가드를 통과해야 한다.
 * 권한 원천은 새 테이블이 아니라 그 게시판이 걸린 메뉴의 역할매핑(COMTNMENUCREATDTLS)이다.
 *
 * ★역할 계층을 적용한다. Authentication 이 들고 있는 권한은 DB 가 직접 부여한 단일 역할뿐이고
 *   (COMTNEMPLYRSCRTYESTBS PK 단독) 계층 확장이 안 돼 있다 — URL 보안만 계층을 본다.
 *   확장 없이 정확일치로 비교하면 조회자용 게시판을 편집자·승인자가 못 여는 회귀가 난다.
 *   rlmsRoleHierarchy(ADMIN > APPROVER > EDITOR > USER, ADMIN > LAW_MGR > USER)로
 *   사용자 역할을 펼친 뒤 대조한다.
 */
package egovframework.com.cop.bbs.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.hierarchicalroles.RoleHierarchy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import egovframework.com.cmm.util.EgovUserDetailsHelper;

@Component("boardReadGuard")
public class BoardReadGuard {

	private static final Logger LOGGER = LoggerFactory.getLogger(BoardReadGuard.class);

	private static final String ROLE_ADMIN = "ROLE_ADMIN";

	@Resource(name = "boardMenuLinkService")
	private BoardMenuLinkService boardMenuLinkService;

	/** 없으면(설정 누락) 계층 없이 정확일치로 동작 — fail-closed 쪽이라 안전하다. */
	@Autowired(required = false)
	@Qualifier("rlmsRoleHierarchy")
	private RoleHierarchy roleHierarchy;

	/** 열람 가능 여부. 관리자는 항상 통과하고, 메뉴에 연결되지 않은 게시판은 관리자만 연다. */
	public boolean canRead(String bbsId) {
		if (bbsId == null || bbsId.trim().isEmpty()) {
			return false;
		}
		Set<String> myRoles = reachableRoles(currentAuthorities());
		if (myRoles.contains(ROLE_ADMIN)) {
			return true;
		}
		List<String> allowed = boardMenuLinkService.selectReadableAuthorCodes(bbsId.trim());
		return !allowed.isEmpty() && !Collections.disjoint(allowed, myRoles);
	}

	/** 열람 권한 강제 — 없으면 AccessDeniedException */
	public void assertReadable(String bbsId) {
		if (!canRead(bbsId)) {
			throw new AccessDeniedException("이 게시판은 열람 권한이 제한되어 있습니다.");
		}
	}

	/**
	 * 로그인 사용자의 역할 + 그 역할이 포함하는 하위 역할 전부.
	 * 작성권한(BoardWriteGuard)도 같은 계층 해석을 써야 하므로 여기서 한 번만 정의한다.
	 */
	public Set<String> currentReachableRoles() {
		return reachableRoles(currentAuthorities());
	}

	// ── 내부 ───────────────────────────────────────────────────────

	/** 사용자 역할 + 그 역할이 포함하는 하위 역할 전부. 계층 빈이 없으면 원래 역할만. */
	private Set<String> reachableRoles(List<String> myRoles) {
		if (myRoles.isEmpty()) {
			return Collections.emptySet();
		}
		if (roleHierarchy == null) {
			return new HashSet<String>(myRoles);
		}
		List<GrantedAuthority> granted = new ArrayList<GrantedAuthority>(myRoles.size());
		for (String role : myRoles) {
			granted.add(new SimpleGrantedAuthority(role));
		}
		Set<String> reachable = new HashSet<String>();
		for (GrantedAuthority ga : roleHierarchy.getReachableGrantedAuthorities(granted)) {
			reachable.add(ga.getAuthority());
		}
		return reachable;
	}

	/** 로그인 사용자의 역할 목록. 실패 시 빈 목록(= 아무 게시판도 열지 못함). */
	private List<String> currentAuthorities() {
		try {
			List<String> roles = EgovUserDetailsHelper.getAuthorities();
			return (roles == null) ? Collections.<String>emptyList() : roles;
		} catch (Exception e) {
			LOGGER.warn("권한 조회 실패: {}", e.getMessage());
			return Collections.emptyList();
		}
	}
}
