--------------------------------------------------------------------------------
-- 13_triggers_functions.sql — 트리거 7종(수정 이식) + 함수 1종(재작성 이식)
-- RegNex(규정 단독) 클린 설치 세트. 실행 계정: regnex. sqlplus 등 '/' 실행 지원 클라이언트 필요.
--
-- [트리거 이식 기준 — 2026-07-10 코드 감사 확정]
--  · 이식 7종: 규정 삭제(deleteProm)가 앱 코드 대신 트리거 cascade 에 명시 의존하는 체인
--      TRG_DEL_PROM → TRG_DEL_PROV_HTML / TRG_DEL_PROV_VRSN / TRG_DEL_REL_VRSN
--                   → TRG_DEL_REL_FILE / TRG_DEL_REL_IMG  (+ 별표 삭제 TRG_DEL_DOCU)
--  · 수정 2건: TRG_DEL_REL_FILE/IMG 본문의 'DELETE FROM TB_REL_REF' 라인 제거
--      (TB_REL_REF 는 RLMS 미사용 — 신규 스키마 미생성).
--  · 폐기 13종: TRG_DEL_CATE(⛔TB_PROM 까지 cascade — RLMS 는 분류 소프트삭제만, 이식 금지),
--      TRG_UPD_PROM/PROV_HTML/PROV_VRSN·TRG_INS/DEL_SRC_STORED(무소비 큐 TB_FT_CACHE_QUEUE/
--      TB_QUEUE_TABLE 적재 — 큐 테이블과 함께 제거), TRG_DEL_REL_HTML/LNK/ORGN(TB_REL_REF
--      정리뿐이거나 앱이 직접 정리), TRG_DEL_ACT/ACT_POL/CATE_POL/USER(레거시 모듈 폐기).
--------------------------------------------------------------------------------

-- ★규정 회차 삭제의 핵심 cascade (앱 PromServiceImpl.deleteProm 이 명시 의존)
CREATE OR REPLACE TRIGGER TRG_DEL_PROM
BEFORE DELETE ON TB_PROM
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
    DELETE FROM TB_PROV_VRSN WHERE IPROM_NO = :OLD.IPROM_NO;
    DELETE FROM TB_PROV_HTML WHERE IPROM_NO = :OLD.IPROM_NO;
    DELETE FROM TB_DOCU WHERE IPROM_NO = :OLD.IPROM_NO;
    DELETE FROM TB_SRC_STORED WHERE ILAW_ID = :OLD.ILAW_ID;
    DELETE FROM TB_REL_VRSN WHERE IPROM_NO = :OLD.IPROM_NO;
END;
/

-- 별표/별지서식 삭제 시 개별 첨부 정리 (앱이 명시 의존)
--   관련자료 마스터를 지우면 TRG_DEL_REL_VRSN → TB_REL_FILE → TRG_DEL_REL_FILE → TB_ATTACH 까지 연쇄된다.
--   (2026-07-30) TB_DOCU_FILE 삭제문 제거 — 해당 테이블 폐기, 첨부 축은 관련자료로 단일화.
CREATE OR REPLACE TRIGGER TRG_DEL_DOCU
BEFORE DELETE ON TB_DOCU
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_VRSN
    WHERE IPROM_NO = :OLD.IPROM_NO
    AND SFLAG = 'DOCUMENT'
    AND SFULL_ITEM = :OLD.SITEM;
END;
/

-- 전문HTML 삭제 시 관련자료 앵커 + 첨부 정리 (앱이 명시 의존)
CREATE OR REPLACE TRIGGER TRG_DEL_PROV_HTML
BEFORE DELETE ON TB_PROV_HTML
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_VRSN
    WHERE IPROM_NO = :OLD.IPROM_NO
    AND SFLAG = 'PROVISION'
    AND SFULL_ITEM = :OLD.SITEM;

    DELETE FROM TB_ATTACH
    WHERE IREF_NO = :OLD.IPHTML_NO
    AND SREF_TABLE = 'TB_PROV_HTML';
END;
/

-- 조문 삭제(저장 시 delete+reinsert 패턴 포함) 시 관련자료 앵커 정리
CREATE OR REPLACE TRIGGER TRG_DEL_PROV_VRSN
BEFORE DELETE ON TB_PROV_VRSN
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_VRSN
    WHERE IPROM_NO = :OLD.IPROM_NO
    AND SFLAG = 'PROVISION'
    AND SFULL_ITEM = :OLD.SITEM;
END;
/

-- 관련자료 마스터 삭제 시 자식 6종 정리 (규정삭제 cascade 의 중간 고리)
CREATE OR REPLACE TRIGGER TRG_DEL_REL_VRSN
BEFORE DELETE ON TB_REL_VRSN
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_HTML WHERE IRVRSN_NO = :OLD.IRVRSN_NO;
    DELETE FROM TB_REL_FILE WHERE IRVRSN_NO = :OLD.IRVRSN_NO;
    DELETE FROM TB_REL_IMG WHERE IRVRSN_NO = :OLD.IRVRSN_NO;
    DELETE FROM TB_REL_LNK WHERE IRVRSN_NO = :OLD.IRVRSN_NO;
    DELETE FROM TB_REL_DMN_LNK WHERE IRVRSN_NO = :OLD.IRVRSN_NO;
    DELETE FROM TB_REL_WORD WHERE IRVRSN_NO = :OLD.IRVRSN_NO;
END;
/

-- 관련파일 삭제 시 첨부 정리 (원본에서 TB_REL_REF 라인 제거)
CREATE OR REPLACE TRIGGER TRG_DEL_REL_FILE
BEFORE DELETE ON TB_REL_FILE
FOR EACH ROW
BEGIN
    DELETE FROM TB_ATTACH WHERE SREF_TABLE = 'TB_REL_FILE' AND IATT_NO = :OLD.IATT_NO;
END;
/

-- 관련이미지 삭제 시 첨부 정리 (원본에서 TB_REL_REF 라인 제거)
CREATE OR REPLACE TRIGGER TRG_DEL_REL_IMG
BEFORE DELETE ON TB_REL_IMG
FOR EACH ROW
BEGIN
    DELETE FROM TB_ATTACH WHERE SREF_TABLE = 'TB_REL_IMG' AND IATT_NO = :OLD.IATT_NO;
END;
/

--------------------------------------------------------------------------------
-- 함수 GET_FULL_NAME_BY_CATE_NO — 분류 풀네임 "구분명>상위분류>...>자기분류"
--
-- ★재작성 이식: 레거시 본문은 구분명을 TB_CODE(동적 SQL)에서 읽었으나 TB_CODE 는
--   폐기 확정(2026-07-09, 정본=ccm 'SGUBUN') + 신규 스키마 미생성이므로
--   COMTCCMMNDETAILCODE 기반 정적 SQL 로 재작성. V_DB_SUFFIX 파라미터는 호출부
--   시그니처 호환을 위해 유지(전 호출부가 'NONE' 전달 — 분기 자체는 제거).
--   호출부: Prom_SQL_oracle.xml 9곳 / Cate_SQL_oracle.xml / RelExclLnk_SQL_oracle.xml
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION GET_FULL_NAME_BY_CATE_NO (
    V_DB_SUFFIX     VARCHAR2 DEFAULT 'NONE',
    V_CATE_NO       NUMBER)
    RETURN VARCHAR2
IS
    V_NAME          VARCHAR2(255) := '';
BEGIN
    BEGIN
        SELECT D.CODE_NM
          INTO V_NAME
          FROM COMTCCMMNDETAILCODE D
         WHERE D.CODE_ID = 'SGUBUN'
           AND D.CODE = (SELECT SGUBUN_ID FROM TB_CATE WHERE ICATE_NO = V_CATE_NO);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN V_NAME := '';
    END;

    FOR R IN (
        SELECT DISTINCT SNAME, ILEVEL
          FROM TB_CATE
         START WITH ICATE_NO = V_CATE_NO
       CONNECT BY PRIOR IREF = ICATE_NO
         ORDER BY ILEVEL
    ) LOOP
        V_NAME := V_NAME || '>' || R.SNAME;
    END LOOP;

    RETURN V_NAME;
END;
/
