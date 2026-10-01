--------------------------------------------------------------------------------
-- 25_seed_domain.sql — 도메인 기본 시드
-- RegNex(규정 단독, MariaDB) 클린 설치 세트 — 레거시 운영 DB(2026-07-09 기준)에서 추출/정리.
-- 실행 계정: regnex. 클라이언트 인코딩 UTF-8(AL32UTF8) 필수.
-- 개정구분(TB_GAEJUNG) 표준 8종(영문 테스트 2행 제외). 분류(TB_CATE)는 의도적으로 빈 상태 —
--   트리 최상위(구분)는 ccm SGUBUN(법령/사규)이 렌더하며 하위분류는 사용자가 분류관리에서 생성.
--------------------------------------------------------------------------------


INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (1,
        '제정',
        1,
        'Y',
        '2009-11-18 11:04:37',
        'N');
INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (2,
        '개정',
        2,
        'Y',
        '2009-11-18 11:04:37',
        'N');
INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (3,
        '폐지',
        3,
        'Y',
        '2009-11-18 11:04:37',
        'N');
INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (4,
        '전문개정',
        4,
        'N',
        '2009-11-18 11:04:37',
        'N');
INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (5,
        '타사규개정',
        5,
        'Y',
        '2010-09-24',
        'N');
INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (6,
        '타사규폐지',
        6,
        'Y',
        '2010-09-24',
        'N');
INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (7,
        '타법령개정',
        7,
        'Y',
        '2010-09-24',
        'N');
INSERT INTO TB_GAEJUNG (IGAEJUNG_NO, SNAME, ISEQ, SDIFF_YN, SINS_DT, SDEL_YN)
VALUES (8,
        '타법령폐지',
        8,
        'Y',
        '2010-09-24',
        'N');
-- 8 rows

-- 법령질의 답변 관리자 지정 (예시: admin)
INSERT INTO TB_LAWQUEST_ADMIN (ADMIN_SABUN, ADMIN_NAME) VALUES ('admin', '관리자');
COMMIT;

-- 브랜드설정 기본 행 (로고=텍스트) — 화면에서 수정 (2026-07-31)
INSERT INTO COM_BRAND (BRAND_ID, LOGO_TY_CODE, LOGO_TEXT) VALUES ('S', 'TEXT', 'RegNex 규정관리시스템');