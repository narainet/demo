--------------------------------------------------------------------------------
-- 14_oracle_text.sql — 전문검색(Oracle Text) 한글 lexer + CONTEXT 인덱스
-- RegNex(규정 단독) 클린 설치 세트. 실행 계정: regnex (전제: 00_create_user.sql 의
--   GRANT CTXAPP + EXECUTE ON CTXSYS.CTX_DDL 완료).
--
-- 사용처: 통합검색 조문축(UnifiedSearch provsBody CONTAINS) + 조문/전문 검색
--   (ProvVrsn selectFullTextSearch) — 인덱스 없으면 해당 검색이 DRG-10599 로 실패.
-- 원본: database/rlms_prom_init.sql (레거시 운영 DB_KOR_LEXER → RLMS_KOR_LEXER 개명).
--------------------------------------------------------------------------------

BEGIN
    CTX_DDL.DROP_PREFERENCE('RLMS_KOR_LEXER');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    CTX_DDL.CREATE_PREFERENCE('RLMS_KOR_LEXER', 'KOREAN_MORPH_LEXER');
END;
/

CREATE INDEX IDX_PROV_VRSN_FT ON TB_PROV_VRSN (SCONTENTS)
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS ('LEXER RLMS_KOR_LEXER SYNC (ON COMMIT)');
