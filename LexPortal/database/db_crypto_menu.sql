-- =====================================================================
-- 설정값 암호화 도구 — 프로그램/메뉴/권한 등록 (2026-08-06)
--
--  화면 : /uss/ion/crypto/dbCryptoView.do  (관리자 > 운영관리 > 설정값 암호화)
--  인가 : ROLE_ADMIN 만. context-security 의 L6(메뉴 파생)가 이 행들로 인가를 만든다.
--         별도 인라인 규칙을 두지 않으므로 메뉴가 빠져도 L7 폴백으로 ADMIN 전용이 유지된다.
--
--  ★Oracle/MariaDB/PostgreSQL 3개 라이브 DB 에 모두 적재한다(DUAL·시퀀스 미사용, 표준 INSERT).
--  ★재실행 가능 — 같은 키를 지우고 다시 넣는다. (메뉴 self-FK 는 리프라 CASCADE 무관)
-- =====================================================================

DELETE FROM COMTNMENUCREATDTLS WHERE MENU_NO = 90200000;
DELETE FROM COMTNMENUINFO      WHERE MENU_NO = 90200000;
DELETE FROM COMTNPROGRMLIST    WHERE PROGRM_FILE_NM = 'EgovDbCrypto';

INSERT INTO COMTNPROGRMLIST (PROGRM_FILE_NM, PROGRM_STRE_PATH, PROGRM_KOREAN_NM, PROGRM_DC, URL)
VALUES ('EgovDbCrypto', '/uss/ion/crypto/', '설정값 암호화',
        'globals.properties 에 넣을 암호문 생성(DB Url/UserName/Password 등)', '/uss/ion/crypto/dbCryptoView.do');

INSERT INTO COMTNMENUINFO (MENU_NO, UPPER_MENU_NO, MENU_NM, MENU_ORDR, PROGRM_FILE_NM, MENU_DC, MENU_SE)
VALUES (90200000, 90170000, '설정값 암호화', 5, 'EgovDbCrypto',
        'DB 계정 교체 등 설정값 암호화 — 암호화만 하고 파일은 고치지 않음', 'ADMIN');

INSERT INTO COMTNMENUCREATDTLS (MENU_NO, AUTHOR_CODE) VALUES (90200000, 'ROLE_ADMIN');
