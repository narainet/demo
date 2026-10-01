/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/cop/bbs/service/impl/BoardMenuLinkServiceImpl.java
 *
 * 게시판 ↔ 사용자 메뉴 연결의 구현. 표준 3테이블만 쓰고 별도 저장소를 두지 않는다.
 * 트랜잭션은 context-transaction.xml 의 execution(* egovframework.com..*Impl.*(..)) 어드바이스가 건다 —
 * 게시판 저장과 메뉴 연결이 한 트랜잭션에서 함께 커밋되거나 함께 롤백된다.
 */
package egovframework.com.cop.bbs.service.impl;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.property.EgovPropertyService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import egovframework.com.cop.bbs.mapper.BoardMenuMapper;
import egovframework.com.cop.bbs.service.BoardMaster;
import egovframework.com.cop.bbs.service.BoardMenuLinkService;
import egovframework.com.cop.bbs.service.BoardMenuVO;

@Service("boardMenuLinkService")
public class BoardMenuLinkServiceImpl extends EgovAbstractServiceImpl implements BoardMenuLinkService {

	private static final Logger LOGGER = LoggerFactory.getLogger(BoardMenuLinkServiceImpl.class);

	/** 사용자 게시판 메뉴가 달릴 폴더 메뉴번호 — 프로젝트가 globals.properties 로 지정. */
	private static final String FOLDER_NO_KEY = "Globals.Bbs.UserMenuFolderNo";

	/** 자동 생성 프로그램 파일명 접두 (뒤에 MENU_NO 를 붙여 유일하게 만든다). */
	private static final String PROGRM_PREFIX = "RLMS_USR_BBS_";

	/** AABBCCDD 메뉴번호 컨벤션 — 한 폴더의 자식은 상위 + n*10000 (n = 1..99). */
	private static final long MENU_NO_STEP = 10000L;
	private static final long MENU_NO_MAX_OFFSET = 990000L;

	private static final int MENU_NM_MAX = 60;

	/** 메뉴에 부여할 수 있는 역할. IS_AUTHENTICATED_* 같은 시큐리티 내부값은 배제한다.
	 *  ★역할 신설 시 여기에도 추가해야 한다 — 빠지면 화면에서 체크해도 저장 때 조용히 걸러진다
	 *    (2026-07-31 ROLE_LAW_MGR 누락 반영). 짝: BoardWriteAuthServiceImpl.ASSIGNABLE_ROLES,
	 *    EgovBBSMasterController.MENU_ROLE_LABELS. */
	private static final Set<String> ASSIGNABLE_ROLES = Collections.unmodifiableSet(new LinkedHashSet<String>(
			Arrays.asList("ROLE_USER", "ROLE_EDITOR", "ROLE_APPROVER", "ROLE_LAW_MGR", "ROLE_ADMIN")));

	@Resource
	private BoardMenuMapper boardMenuMapper;

	@Resource(name = "propertiesService")
	private EgovPropertyService propertyService;

	@Override
	public BoardMenuVO selectLink(String bbsId) {
		if (isBlank(bbsId)) {
			return null;
		}
		List<BoardMenuVO> found = boardMenuMapper.selectBoardMenuByUrl(listUrl(bbsId));
		if (found == null || found.isEmpty()) {
			return null;
		}
		BoardMenuVO vo = found.get(0);
		if (found.size() > 1) {
			LOGGER.warn("게시판 {} 에 메뉴가 {}개 연결돼 있습니다. 첫 메뉴({})만 사용합니다.",
					bbsId, found.size(), vo.getMenuNo());
		}
		vo.setBbsId(bbsId);
		vo.setAuthorCodes(boardMenuMapper.selectBoardMenuAuthorCodes(listUrl(bbsId)));
		return vo;
	}

	@Override
	public Map<String, BoardMenuVO> selectLinkMap() {
		Map<String, BoardMenuVO> map = new LinkedHashMap<String, BoardMenuVO>();
		List<BoardMenuVO> all = boardMenuMapper.selectAllBoardMenus(USER_LIST_URL);
		if (all != null) {
			for (BoardMenuVO vo : all) {
				if (!isBlank(vo.getBbsId())) {
					map.put(vo.getBbsId(), vo);
				}
			}
		}
		return map;
	}

	@Override
	public List<String> selectReadableAuthorCodes(String bbsId) {
		if (isBlank(bbsId)) {
			return Collections.emptyList();
		}
		List<String> codes = boardMenuMapper.selectBoardMenuAuthorCodes(listUrl(bbsId));
		return (codes == null) ? Collections.<String>emptyList() : codes;
	}

	@Override
	public void syncLink(BoardMaster boardMaster) {
		String bbsId = boardMaster.getBbsId();
		if (isBlank(bbsId)) {
			return;
		}

		// 사용중지된 게시판은 사용자 메뉴에 남겨두지 않는다.
		boolean expose = "Y".equals(boardMaster.getMenuExposeAt()) && !"N".equals(boardMaster.getUseAt());
		if (!expose) {
			removeLink(bbsId);
			return;
		}

		BoardMenuVO link = selectLink(bbsId);
		String menuNm = resolveMenuNm(boardMaster);
		List<String> authorCodes = resolveAuthorCodes(boardMaster.getMenuAuthorCodes());

		if (link == null) {
			link = createLink(bbsId, menuNm, boardMaster.getMenuOrdr());
		} else {
			link.setMenuNm(menuNm);
			link.setUrl(listUrl(bbsId));
			if (boardMaster.getMenuOrdr() != null && boardMaster.getMenuOrdr().intValue() > 0) {
				link.setMenuOrdr(boardMaster.getMenuOrdr());
			}
			boardMenuMapper.updateProgrm(link);
			boardMenuMapper.updateMenu(link);
			boardMenuMapper.deleteMenuAuthors(link.getMenuNo());
		}

		for (String authorCode : authorCodes) {
			boardMenuMapper.insertMenuAuthor(link.getMenuNo(), authorCode);
		}
		LOGGER.info("게시판 {} 사용자 메뉴 연결: menuNo={} 역할={}", bbsId, link.getMenuNo(), authorCodes);
	}

	@Override
	public void removeLink(String bbsId) {
		BoardMenuVO link = selectLink(bbsId);
		if (link == null) {
			return;
		}
		// ⛔ 순서 고정 — 프로그램을 먼저 지우면 COMTNMENUINFO 가 CASCADE 로 함께 사라진다.
		//    역할매핑(COMTNMENUCREATDTLS)은 메뉴 삭제에 딸려 CASCADE 로 정리된다.
		boardMenuMapper.deleteMenu(link.getMenuNo());
		if (boardMenuMapper.countMenusByProgrm(link.getProgrmFileNm()) == 0) {
			boardMenuMapper.deleteProgrm(link.getProgrmFileNm());
		} else {
			LOGGER.warn("프로그램 {} 을(를) 다른 메뉴가 참조하고 있어 남겨둡니다.", link.getProgrmFileNm());
		}
		LOGGER.info("게시판 {} 사용자 메뉴 연결 해제: menuNo={}", bbsId, link.getMenuNo());
	}

	// ── 내부 ───────────────────────────────────────────────────────

	private BoardMenuVO createLink(String bbsId, String menuNm, Integer requestedOrdr) {
		long upperMenuNo = folderMenuNo();
		if (boardMenuMapper.countMenu(Long.valueOf(upperMenuNo)) == 0) {
			throw new IllegalStateException("사용자 게시판 폴더 메뉴(" + upperMenuNo + ")가 없습니다. "
					+ FOLDER_NO_KEY + " 설정을 확인하세요.");
		}

		Long menuNo = boardMenuMapper.selectNextMenuNo(Long.valueOf(upperMenuNo));
		if (menuNo == null || menuNo.longValue() > upperMenuNo + MENU_NO_MAX_OFFSET) {
			throw new IllegalStateException("게시판 폴더에 더 이상 메뉴를 만들 수 없습니다"
					+ " (메뉴번호 " + (upperMenuNo + MENU_NO_MAX_OFFSET) + " 초과).");
		}

		int menuOrdr = (requestedOrdr != null && requestedOrdr.intValue() > 0)
				? requestedOrdr.intValue()
				: boardMenuMapper.selectNextMenuOrdr(Long.valueOf(upperMenuNo)).intValue();

		BoardMenuVO link = new BoardMenuVO();
		link.setBbsId(bbsId);
		link.setMenuNo(menuNo);
		link.setUpperMenuNo(Long.valueOf(upperMenuNo));
		link.setMenuNm(menuNm);
		link.setMenuOrdr(Integer.valueOf(menuOrdr));
		link.setProgrmFileNm(PROGRM_PREFIX + menuNo);
		link.setUrl(listUrl(bbsId));

		boardMenuMapper.insertProgrm(link);
		boardMenuMapper.insertMenu(link);
		return link;
	}

	/** 메뉴명은 비어 있으면 게시판명을 쓰고, MENU_NM(60) 길이에 맞춰 자른다. */
	private String resolveMenuNm(BoardMaster boardMaster) {
		String menuNm = boardMaster.getMenuNm();
		if (isBlank(menuNm)) {
			menuNm = boardMaster.getBbsNm();
		}
		menuNm = (menuNm == null) ? "" : menuNm.trim();
		if (menuNm.isEmpty()) {
			throw new IllegalArgumentException("사용자 메뉴에 노출하려면 메뉴명이 필요합니다.");
		}
		return (menuNm.length() > MENU_NM_MAX) ? menuNm.substring(0, MENU_NM_MAX) : menuNm;
	}

	/**
	 * 화면이 보낸 역할을 검증한다. 관리자는 게시판을 관리해야 하므로 항상 포함된다.
	 * 알 수 없는 역할은 조용히 버린다 — COMTNAUTHORINFO FK 위반으로 저장 전체가 실패하지 않도록.
	 */
	private List<String> resolveAuthorCodes(String[] requested) {
		Set<String> codes = new LinkedHashSet<String>();
		if (requested != null) {
			for (String code : requested) {
				String trimmed = (code == null) ? "" : code.trim();
				if (ASSIGNABLE_ROLES.contains(trimmed)) {
					codes.add(trimmed);
				} else if (!trimmed.isEmpty()) {
					LOGGER.warn("게시판 메뉴에 부여할 수 없는 역할 무시: {}", trimmed);
				}
			}
		}
		codes.add("ROLE_ADMIN");
		return new ArrayList<String>(new LinkedHashSet<String>(codes));
	}

	private long folderMenuNo() {
		String raw = propertyService.getString(FOLDER_NO_KEY);
		if (raw == null || raw.trim().isEmpty()) {
			throw new IllegalStateException(FOLDER_NO_KEY + " 가 설정되지 않아 사용자 메뉴 노출을 처리할 수 없습니다.");
		}
		try {
			return Long.parseLong(raw.trim());
		} catch (NumberFormatException e) {
			throw new IllegalStateException(FOLDER_NO_KEY + " 값이 숫자가 아닙니다: " + raw, e);
		}
	}

	private String listUrl(String bbsId) {
		return USER_LIST_URL + bbsId;
	}

	private boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}

	/** 부여 가능한 역할 목록(표시 순서 유지) — 화면이 체크박스를 그릴 때 쓴다. */
	public static List<String> assignableRoles() {
		return new ArrayList<String>(ASSIGNABLE_ROLES);
	}
}
