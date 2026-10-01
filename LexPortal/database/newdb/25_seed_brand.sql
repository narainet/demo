--------------------------------------------------------------------------------
-- 25_seed_brand.sql — 브랜드설정 기본 행(로고=텍스트, 화면에서 수정)
-- LexPortal 클린 설치 세트 — 통합본(RLMS 스키마, 2026-08-03 라이브)에서 추출·제품 필터링.
-- 실행 계정: lexportal. 클라이언트 인코딩 UTF-8(AL32UTF8) 필수. 재실행 비멱등(단순 INSERT).
--------------------------------------------------------------------------------

SET DEFINE OFF

INSERT INTO COM_BRAND (BRAND_ID, LOGO_TY_CODE, LOGO_TEXT, CNTC_ADRES, CNTC_TELNO, CNTC_FXNUM, CNTC_EMAIL_ADRES)
VALUES ('S', 'TEXT', 'LexPortal 송무관리시스템',
        '(34036) 대전광역시 유성구 테크노10로 33 나라아이넷 사옥', '042-936-8620', '042-000-0000', 'contact@example.com');

COMMIT;
