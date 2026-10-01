--------------------------------------------------------------------------------
-- 21_seed_menu.sql — 프로그램·메뉴·메뉴별권한(=URL 인가 원천)
-- LexPortal(PostgreSQL) 클린 설치 세트 — 통합본(RLMS 스키마, 2026-08-03 라이브)에서 추출·제품 필터링.
-- 실행 계정: lexportal. 클라이언트 인코딩 UTF-8(AL32UTF8) 필수. 재실행 비멱등(단순 INSERT).
--------------------------------------------------------------------------------


-- ── 프로그램 (59행) ──
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovAuthorList',
        '/sec/ram/',
        '권한관리',
        '권한관리',
        '/sec/ram/EgovAuthorList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovBannerList',
        '/uss/ion/bnr/',
        '배너관리',
        '사용자 홈 배너 등록/관리',
        '/uss/ion/bnr/selectBannerList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovBrand',
        '/uss/ion/brd/',
        '브랜드설정',
        '로고와 파비콘 설정',
        '/uss/ion/brd/brandView.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovDeptAuthorList',
        '/sec/drm/',
        '부서권한관리',
        '부서별 권한 할당 관리',
        '/sec/drm/EgovDeptAuthorList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovLoginPolicyList',
        '/uat/uap/',
        '로그인정책관리',
        '사용자별 로그인 정책 관리',
        '/uat/uap/selectLoginPolicyList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovMberManage',
        '/uss/umt/',
        '일반회원관리',
        '일반회원관리',
        '/uss/umt/EgovMberManage.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovMenuCreatManageSelect',
        '/sym/mnu/mcm/',
        '메뉴생성관리',
        '메뉴생성관리',
        '/sym/mnu/mcm/EgovMenuCreatManageSelect.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovMenuListSelect',
        '/sym/mnu/mpm/',
        '메뉴리스트관리',
        '메뉴리스트관리',
        '/sym/mnu/mpm/EgovMenuListSelect.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovMenuManageSelect',
        '/sym/mnu/mpm/',
        '메뉴관리리스트',
        '메뉴관리리스트',
        '/sym/mnu/mpm/EgovMenuManageSelect.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovPopupList',
        '/uss/ion/pwm/',
        '팝업창관리',
        '메인 팝업창 등록/관리',
        '/uss/ion/pwm/listPopup.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovProgramListManageSelect',
        '/sym/prm/',
        '프로그램관리',
        '프로그램관리',
        '/sym/prm/EgovProgramListManageSelect.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovRoleList',
        '/sec/rmt/',
        '역할관리',
        '역할관리',
        '/sec/rmt/EgovRoleList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovSiteMapng',
        '/sym/mnu/stm/',
        '사이트맵',
        '사이트맵',
        '/sym/mnu/stm/EgovSiteMapng.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovUserManage',
        '/uss/umt/',
        '업무사용자관리',
        '업무사용자관리',
        '/uss/umt/EgovUserManage.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_ASSIGN_LIST',
        '/law/assign/',
        '선임관리',
        '변호사 선임·계약서·만족도',
        '/law/assign/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_CALCSET',
        '/law/calcset/',
        '소송비용 요율설정',
        '소송비용 계산기 시점별 요율 관리',
        '/law/calcset/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_COST_LIST',
        '/law/cost/',
        '소송비용조회',
        '소송비용 조회·계산기',
        '/law/cost/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_DOC_APPROVAL',
        '/law/doc/',
        '문서 승인',
        '소송문서 승인 워크플로(대기/승인/반려)',
        '/law/doc/approvalList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_DOC_LIST',
        '/law/doc/',
        '소송문서조회',
        '소송문서 조회·ZIP 일괄',
        '/law/doc/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_HOME',
        '/law/',
        '대시보드',
        '업무 진입 랜딩 현황판 (2026-08-04 송무 홈에서 개명, URL 단축)',
        '/law/index.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_LAWYER_LIST',
        '/law/lawyer/',
        '변호사관리',
        '변호사 명부 관리',
        '/law/lawyer/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_RECEIPT_LIST',
        '/law/receipt/',
        '법원서류접수',
        '법원서류 접수·관련부서 지정',
        '/law/receipt/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_REQ_LIST',
        '/law/req/',
        '소송의뢰관리',
        '소송의뢰 승인·반려·소송등록 연계(법무팀)',
        '/law/req/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_REQ_USER_LIST',
        '/law/reqUser/',
        '나의 소송의뢰',
        '본인 소송의뢰 목록(front — 서버측 본인 필터)',
        '/law/reqUser/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_REQ_USER_REG',
        '/law/reqUser/',
        '소송의뢰 신청',
        '사용자 소송의뢰 신청(front)',
        '/law/reqUser/regist.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_SCHEDULE',
        '/law/schedule/',
        '일정관리',
        '송무 일정(달력·당일/주간)',
        '/law/schedule/main.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_SEIZE_LIST',
        '/law/seize/',
        '압류관리',
        '가압류·가처분 관리',
        '/law/seize/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_STAT_AGENT',
        '/law/stat/',
        '대리인 통계',
        '대리인(변호사선임/직접수행) 통계',
        '/law/stat/agent.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_STAT_CASETYPE',
        '/law/stat/',
        '유형별 통계',
        '사건유형별 통계',
        '/law/stat/caseType.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_STAT_DEPT',
        '/law/stat/',
        '부서별 통계',
        '부서별 통계(COMTNORGNZTINFO 축)',
        '/law/stat/dept.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_STAT_INSTANCE',
        '/law/stat/',
        '심급별 통계',
        '심급별 통계',
        '/law/stat/instance.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_STAT_LANDMAP',
        '/law/stat/',
        '사건지번표시도',
        '사건토지 지도(Kakao — 키 미설정 시 목록 폴백)',
        '/law/stat/landMap.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_STAT_LOSS',
        '/law/stat/',
        '패소원인 통계',
        '패소원인 통계',
        '/law/stat/lossCause.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_STAT_SUMMARY',
        '/law/stat/',
        '소송통계',
        '소송통계(구분 4축)',
        '/law/stat/summary.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('LAW_SUIT_LIST',
        '/law/suit/',
        '소송조회',
        '소송관리 목록(등록·상세는 목록 내 흐름)',
        '/law/suit/list.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_ADM_HELP_FAQ',
        '/uss/olh/faq/',
        'FAQ 관리',
        '도움말 FAQ 관리',
        '/uss/olh/faq/selectFaqList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_ADM_HELP_QNA',
        '/uss/olh/qna/',
        'Q&A 관리',
        '도움말 Q&A 답변관리',
        '/uss/olh/qna/selectQnaAnswerList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_ADM_STATS_ACCESS',
        '/rlms/stats/',
        '접속통계',
        '접속(페이지 요청) 통계 — 시간대/일/월/연/요일/메뉴/기기/브라우저',
        '/rlms/stats/accessStats.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_ADM_STATS_BBSVIEW',
        '/rlms/stats/',
        '게시판 조회통계',
        '게시글별 조회수 통계',
        '/rlms/stats/bbsViewStats.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_ADM_STATS_LOG',
        '/rlms/stats/',
        '사용자 활동 로그',
        '사용자 활동 로그 조회',
        '/rlms/stats/actionLog.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_USR_BBS_NOTICE',
        '/cop/bbs/user/',
        '공지사항',
        '사용자 게시판 열람(공지사항)',
        '/cop/bbs/user/selectArticleList.do?bbsId=BBSMSTR_000000000001BEeMsIjLSK');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_USR_HELP_FAQ',
        '/uss/olh/faq/',
        '도움말 FAQ',
        '도움말 FAQ(사용자 아코디언)',
        '/uss/olh/faq/selectFaqUserList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_USR_HELP_QNA',
        '/uss/olh/qna/',
        '도움말 Q&A',
        '도움말 Q&A(표준)',
        '/uss/olh/qna/selectQnaList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_USR_LOGINHIST',
        '/uss/umt/my/',
        '로그인 내역',
        '본인 로그인 내역 조회',
        '/uss/umt/my/loginHistory.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_USR_LOGINIP',
        '/uss/umt/my/',
        '로그인 IP 설정',
        '본인 로그인 허용 IP 설정',
        '/uss/umt/my/loginIp.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_USR_PASSWORD',
        '/uss/umt/my/',
        '비밀번호 변경',
        '본인 비밀번호 변경(유효기간 정책)',
        '/uss/umt/my/password.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RLMS_USR_PROFILE',
        '/uss/umt/my/',
        '내정보수정',
        '본인 이메일/휴대전화 수정',
        '/uss/umt/my/profile.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('RlmsCodeTree',
        '/sym/ccm/cca/',
        '공통코드관리',
        '공통코드 그룹/상세 트리 통합관리 (ccm cca+cde 대체)',
        '/sym/ccm/cca/selectCodeTree.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('SelectBBSMasterInfs',
        '/cop/bbs/',
        '게시판속성관리',
        '게시판속성관리',
        '/cop/bbs/selectBBSMasterInfs.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('SelectLoginLogList',
        '/sym/log/clg/',
        '접속로그관리',
        '접속로그관리',
        '/sym/log/clg/SelectLoginLogList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('SelectSysLogList',
        '/sym/log/lgm/',
        '로그관리',
        '로그관리',
        '/sym/log/lgm/SelectSysLogList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('SelectTemplateInfs',
        '/cop/tpl/',
        '템플릿관리',
        NULL,
        '/cop/tpl/selectTemplateInfs.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('SelectUserLogList',
        '/sym/log/ulg/',
        '사용로그관리',
        '사용로그관리',
        '/sym/log/ulg/SelectUserLogList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('SelectWebLogList',
        '/sym/log/wlg/',
        '웹로그관리',
        '웹로그관리',
        '/sym/log/wlg/SelectWebLogList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('SelectWebLogSessionList',
        '/sym/log/wlg/',
        '접속 세션 현황',
        '웹로그 세션 단위 접속 현황 — 접속/마지막 활동/체류/화면수/기기/브라우저',
        '/sym/log/wlg/SelectWebLogSessionList.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('egovLoginUsr',
        '/uat/uia/',
        '로그인',
        '로그인',
        '/uat/uia/egovLoginUsr.do');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('externalLink',
        '/',
        '외부링크',
        '외부 URL 링크 메뉴용 placeholder. 실제 링크는 메뉴의 RELATE_IMAGE_PATH.',
        '#');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('folder',
        'folder',
        '폴더',
        '폴더',
        'folder');
INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('selectDeptManageListView',
        '/uss/umt/dpt/',
        '부서관리',
        '부서관리',
        '/uss/umt/dpt/selectDeptManageListView.do');

-- ── 메뉴 (71행) — 2026-08-04 관리자 GNB 재편: 송무관리·도움말관리 폴더 해체, 송무 홈 GNB 미노출(HIDDEN) ──
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('FAQ',
        'RLMS_USR_HELP_FAQ',
        30010000,
        30000000,
        1,
        NULL,
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('FAQ 관리',
        'RLMS_ADM_HELP_FAQ',
        70010000,
        80000000,
        3,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('Q&A',
        'RLMS_USR_HELP_QNA',
        30020000,
        30000000,
        2,
        NULL,
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('Q&A 관리',
        'RLMS_ADM_HELP_QNA',
        70020000,
        80000000,
        4,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('root',
        'folder',
        0,
        0,
        1,
        '최상위 루트',
        '/',
        '/',
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('게시판',
        'folder',
        35000000,
        0,
        2,
        '공지사항 등 사용자 게시판',
        NULL,
        'drop',
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('게시판 조회통계',
        'RLMS_ADM_STATS_BBSVIEW',
        45060000,
        45000000,
        6,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('게시판관리',
        'folder',
        80000000,
        0,
        6,
        '게시판 생성·운영, FAQ·Q&A 관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('게시판속성관리',
        'SelectBBSMasterInfs',
        80010000,
        80000000,
        1,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('공지사항',
        'RLMS_USR_BBS_NOTICE',
        35010000,
        35000000,
        1,
        '공지사항',
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('공통코드관리',
        'RlmsCodeTree',
        90080000,
        90170000,
        1,
        '공통코드 그룹/상세 통합관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('관리자',
        'folder',
        90000000,
        0,
        7,
        '표준 시스템 관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('권한관리',
        'EgovAuthorList',
        90020000,
        90150000,
        1,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('권한관리',
        'folder',
        90150000,
        90000000,
        2,
        '권한관리 그룹',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('나의 소송의뢰',
        'LAW_REQ_USER_LIST',
        15020000,
        15000000,
        2,
        '본인 의뢰 목록',
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('내정보수정',
        'RLMS_USR_PROFILE',
        25040000,
        25000000,
        1,
        '본인 정보 수정ㅇㅇ',
        NULL,
        'undefined',
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('대리인 통계',
        'LAW_STAT_AGENT',
        55080500,
        55080000,
        5,
        '대리인 통계',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('도움말',
        'folder',
        30000000,
        0,
        5,
        '사용자 도움말',
        NULL,
        'drop',
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('로그관리',
        'folder',
        90090000,
        90000000,
        4,
        '시스템·접속·웹·사용 로그',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('로그인 IP 설정',
        'RLMS_USR_LOGINIP',
        25010000,
        25000000,
        2,
        '본인 로그인 허용 IP',
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('로그인 내역',
        'RLMS_USR_LOGINHIST',
        25020000,
        25000000,
        3,
        '본인 로그인 내역',
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('로그인정책관리',
        'EgovLoginPolicyList',
        90120000,
        90140000,
        4,
        '사용자별 로그인 정책',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('마이페이지',
        'folder',
        25000000,
        0,
        6,
        '내 계정 관련(드롭다운)',
        NULL,
        'drop',
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('메뉴관리',
        'EgovMenuListSelect',
        90050000,
        90160000,
        1,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('메뉴관리',
        'folder',
        90160000,
        90000000,
        3,
        '메뉴관리 그룹',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('메뉴생성관리',
        'EgovMenuCreatManageSelect',
        90060000,
        90160000,
        3,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('문서 승인',
        'LAW_DOC_APPROVAL',
        55020300,
        55020000,
        3,
        '소송문서 승인 현황',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('배너관리',
        'EgovBannerList',
        90180000,
        90170000,
        3,
        '사용자 홈 배너 관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('법원서류접수',
        'LAW_RECEIPT_LIST',
        55070000,
        55020000,
        4,
        '법원서류 접수',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('변호사관리',
        'LAW_LAWYER_LIST',
        55040200,
        55040000,
        2,
        '변호사 명부',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('부서관리',
        'selectDeptManageListView',
        60030000,
        90140000,
        3,
        '부서관리(표준)',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('부서권한관리',
        'EgovDeptAuthorList',
        90110000,
        90150000,
        3,
        '부서별 권한 할당',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('부서별 통계',
        'LAW_STAT_DEPT',
        55080400,
        55080000,
        4,
        '부서별 통계',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('브랜드설정',
        'EgovBrand',
        90190000,
        90170000,
        4,
        '로고와 파비콘 등 화면 브랜딩 설정',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('비밀번호 변경',
        'RLMS_USR_PASSWORD',
        25030000,
        25000000,
        4,
        '본인 비밀번호 변경',
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('사건지번표시도',
        'LAW_STAT_LANDMAP',
        55080700,
        55080000,
        7,
        '사건지번표시도',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('사용로그',
        'SelectUserLogList',
        90090400,
        90090000,
        4,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('사용자 활동 로그',
        'RLMS_ADM_STATS_LOG',
        45030000,
        45000000,
        3,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('사용자관리',
        'folder',
        90140000,
        90000000,
        1,
        '사용자관리 그룹',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('사이트맵',
        'EgovSiteMapng',
        90070000,
        90160000,
        4,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('선임관리',
        'LAW_ASSIGN_LIST',
        55040100,
        55040000,
        1,
        '변호사 선임 관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('선임관리',
        'folder',
        55040000,
        0,
        4,
        '선임·변호사',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송관리',
        'folder',
        55020000,
        0,
        1,
        '소송 조회·문서·접수·압류·비용',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송문서조회',
        'LAW_DOC_LIST',
        55020200,
        55020000,
        2,
        '소송문서 조회',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송비용 요율설정',
        'LAW_CALCSET',
        55090000,
        55020000,
        7,
        '계산기 요율 관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송비용조회',
        'LAW_COST_LIST',
        55020400,
        55020000,
        6,
        '소송비용 조회',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송의뢰',
        'folder',
        15000000,
        0,
        3,
        '사용자 소송의뢰',
        NULL,
        'drop',
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송의뢰 신청',
        'LAW_REQ_USER_REG',
        15010000,
        15000000,
        1,
        '소송의뢰 신청',
        NULL,
        NULL,
        'USER');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송의뢰관리',
        'LAW_REQ_LIST',
        55050000,
        0,
        3,
        '소송의뢰 승인·반려',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송조회',
        'LAW_SUIT_LIST',
        55020100,
        55020000,
        1,
        '소송 목록·등록·상세',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송통계',
        'folder',
        55080000,
        0,
        5,
        '송무 통계 7종',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('소송통계',
        'LAW_STAT_SUMMARY',
        55080100,
        55080000,
        1,
        '소송통계',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('대시보드',
        'LAW_HOME',
        55010000,
        0,
        99,
        'GNB 미노출 대시보드(/law/index.do). URL 인가 파생용 행 - 삭제 금지. 모바일 드로어에서 진입',
        NULL,
        NULL,
        'HIDDEN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('시스템로그',
        'SelectSysLogList',
        90090100,
        90090000,
        1,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('심급별 통계',
        'LAW_STAT_INSTANCE',
        55080200,
        55080000,
        2,
        '심급별 통계',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('압류관리',
        'LAW_SEIZE_LIST',
        55060000,
        55020000,
        5,
        '가압류·가처분',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('업무사용자관리',
        'EgovUserManage',
        90010000,
        90140000,
        1,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('역할관리',
        'EgovRoleList',
        90030000,
        90150000,
        2,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('운영관리',
        'folder',
        90170000,
        90000000,
        5,
        '운영관리 그룹',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('웹로그',
        'SelectWebLogList',
        90090300,
        90090000,
        3,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('유형별 통계',
        'LAW_STAT_CASETYPE',
        55080300,
        55080000,
        3,
        '유형별 통계',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('일반사용자관리',
        'EgovMberManage',
        90100000,
        90140000,
        2,
        '일반회원(COMTNGNRLMBER) 관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('일정관리',
        'LAW_SCHEDULE',
        55030000,
        0,
        2,
        '송무 일정',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('접속 세션 현황',
        'SelectWebLogSessionList',
        90090500,
        90090000,
        5,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('접속로그',
        'SelectLoginLogList',
        90090200,
        90090000,
        2,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('접속통계',
        'RLMS_ADM_STATS_ACCESS',
        45070000,
        45000000,
        7,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('템플릿관리',
        'SelectTemplateInfs',
        80020000,
        80000000,
        2,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('통계',
        'folder',
        45000000,
        90000000,
        6,
        NULL,
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('팝업창관리',
        'EgovPopupList',
        90130000,
        90170000,
        2,
        '메인 팝업창 등록/관리',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('패소원인 통계',
        'LAW_STAT_LOSS',
        55080600,
        55080000,
        6,
        '패소원인 통계',
        NULL,
        NULL,
        'ADMIN');
INSERT INTO COMTNMENUINFO (MENU_NM, PROGRM_FILE_NM, MENU_NO, UPPER_MENU_NO, MENU_ORDR, MENU_DC, RELATE_IMAGE_PATH, RELATE_IMAGE_NM, MENU_SE)
VALUES ('프로그램관리',
        'EgovProgramListManageSelect',
        90040000,
        90160000,
        2,
        NULL,
        NULL,
        NULL,
        'ADMIN');

-- ── 메뉴별권한 (134행) — 2026-08-04 재편: 해체 폴더 2건 + 관리자 축 EDITOR/APPROVER 부여 정리 ──
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15000000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15000000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15000000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15000000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15000000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15010000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15010000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15010000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15010000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15020000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15020000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15020000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15020000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (15020000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25000000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25000000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25000000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25000000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25010000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25010000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25010000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25020000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25020000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25020000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25020000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25030000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25030000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25030000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25030000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25040000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25040000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25040000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (25040000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30000000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30000000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30000000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30000000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30010000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30010000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30010000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30020000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30020000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30020000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (30020000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35000000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35000000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35000000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35000000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35010000,
        'ROLE_APPROVER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35010000,
        'ROLE_EDITOR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35010000,
        'ROLE_USER',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (35010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (45000000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (45030000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (45060000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (45070000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55010000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020100,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020100,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020200,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020200,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020300,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020300,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020400,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55020400,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55030000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55030000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55040000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55040000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55040100,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55040100,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55040200,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55040200,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55050000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55050000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55060000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55060000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55070000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55070000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080100,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080100,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080200,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080200,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080300,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080300,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080400,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080400,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080500,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080500,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080600,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080600,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080700,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55080700,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55090000,
        'ROLE_LAW_MGR',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (55090000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (60030000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (70010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (70020000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (80000000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (80010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (80020000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90000000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90010000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90020000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90030000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90040000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90050000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90060000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90070000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90080000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90090000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90090100,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90090200,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90090300,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90090400,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90090500,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90100000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90110000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90120000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90130000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90140000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90150000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90160000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90170000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90180000,
        'ROLE_ADMIN',
        NULL);
INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE, MAPNG_CREAT_ID)
VALUES (90190000,
        'ROLE_ADMIN',
        NULL);

-- ── 2026-08-04 관리자 GNB 재편 — 값은 위 INSERT 에 인라인(재배치 UPDATE 불요) ──
--    GNB: 소송관리 | 일정관리 | 소송의뢰관리 | 선임관리 | 소송통계 | 게시판관리 | 관리자
--    소송관리가 법원서류접수·압류관리·소송비용 요율설정 흡수, 게시판관리가 FAQ·Q&A 관리 흡수.
--    송무 홈(55010000)은 MENU_SE='HIDDEN' — GNB 미노출이지만 /law/home/* URL 인가(L6 파생)의
--    원천이라 행·권한(ADMIN/LAW_MGR)을 유지한다. 홈 진입 = CI 클릭(/main.do → /law/home/main.do).

COMMIT;