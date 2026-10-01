/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/impl/BoardWriteAuthServiceImpl.java
 *
 * 게시판별 작성권한 구현. 게시판 저장과 같은 트랜잭션에서 동작한다
 * (context-transaction.xml 의 execution(* egovframework.com..*Impl.*(..))).
 */
package egovframework.com.cop.bbs.service.impl;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import egovframework.com.cop.bbs.mapper.BoardWriteAuthMapper;
import egovframework.com.cop.bbs.service.BoardMaster;
import egovframework.com.cop.bbs.service.BoardWriteAuthService;

@Service("boardWriteAuthService")
public class BoardWriteAuthServiceImpl extends EgovAbstractServiceImpl implements BoardWriteAuthService {

	private static final Logger LOGGER = LoggerFactory.getLogger(BoardWriteAuthServiceImpl.class);

	private static final String ROLE_ADMIN = "ROLE_ADMIN";

	/** 부여 가능한 역할 — 시큐리티 내부값(IS_AUTHENTICATED_*)은 배제한다.
	 *  ★역할 신설 시 여기에도 추가해야 한다 — 빠지면 화면에서 체크해도 저장 때 조용히 걸러진다
	 *    (2026-07-31 ROLE_LAW_MGR 누락 반영). 짝: BoardMenuLinkServiceImpl.ASSIGNABLE_ROLES,
	 *    EgovBBSMasterController.MENU_ROLE_LABELS. */
	private static final Set<String> ASSIGNABLE_ROLES = Collections.unmodifiableSet(new LinkedHashSet<String>(
			Arrays.asList("ROLE_USER", "ROLE_EDITOR", "ROLE_APPROVER", "ROLE_LAW_MGR", ROLE_ADMIN)));

	@Resource
	private BoardWriteAuthMapper boardWriteAuthMapper;

	@Override
	public List<String> selectWriteAuthorCodes(String bbsId) {
		if (isBlank(bbsId)) {
			return Collections.emptyList();
		}
		List<String> codes = boardWriteAuthMapper.selectWriteAuthorCodes(bbsId.trim());
		return (codes == null) ? Collections.<String>emptyList() : codes;
	}

	@Override
	public void syncWriteAuthors(BoardMaster boardMaster) {
		String bbsId = boardMaster.getBbsId();
		if (isBlank(bbsId)) {
			return;
		}

		// 사용중지된 게시판에는 아무도 글을 쓸 수 없다.
		if ("N".equals(boardMaster.getUseAt())) {
			removeWriteAuthors(bbsId);
			return;
		}

		List<String> codes = resolve(boardMaster.getWriteAuthorCodes());
		boardWriteAuthMapper.deleteWriteAuthors(bbsId);
		for (String code : codes) {
			boardWriteAuthMapper.insertWriteAuthor(bbsId, code);
		}
		LOGGER.info("게시판 {} 작성권한: {}", bbsId, codes);
	}

	@Override
	public void removeWriteAuthors(String bbsId) {
		if (!isBlank(bbsId)) {
			boardWriteAuthMapper.deleteWriteAuthors(bbsId.trim());
		}
	}

	/** 알 수 없는 역할은 조용히 버린다(FK 위반으로 저장 전체가 실패하지 않도록). 관리자는 항상 포함. */
	private List<String> resolve(String[] requested) {
		Set<String> codes = new LinkedHashSet<String>();
		if (requested != null) {
			for (String code : requested) {
				String trimmed = (code == null) ? "" : code.trim();
				if (ASSIGNABLE_ROLES.contains(trimmed)) {
					codes.add(trimmed);
				} else if (!trimmed.isEmpty()) {
					LOGGER.warn("게시판 작성권한에 부여할 수 없는 역할 무시: {}", trimmed);
				}
			}
		}
		codes.add(ROLE_ADMIN);
		return new ArrayList<String>(codes);
	}

	private boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}
}
