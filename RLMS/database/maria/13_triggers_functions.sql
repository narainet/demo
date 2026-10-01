--------------------------------------------------------------------------------
-- 13_triggers_functions.sql — 트리거 7종 + 함수 1종 (MariaDB 판)
-- RLMS 통합본(MariaDB) 클린 설치 세트. 실행 계정: rlms.
--
-- Oracle 판(newdb/13_triggers_functions.sql)에서 이식. 변환 요점:
--   · `:OLD.COL` → `OLD.COL`, `REFERENCING NEW AS NEW OLD AS OLD` 절 제거(MariaDB 는 암묵 제공)
--   · `CREATE OR REPLACE TRIGGER` → `DROP TRIGGER IF EXISTS` + `CREATE TRIGGER`
--   · 함수의 `START WITH ... CONNECT BY PRIOR` 계층질의 → `WITH RECURSIVE` 재귀 CTE
--   · `EXCEPTION WHEN NO_DATA_FOUND` → MariaDB 는 스칼라 서브쿼리가 NULL 을 반환하므로
--     IFNULL 로 대체(예외 핸들러 불요)
--   · 종결자 `/` → MariaDB 는 불필요(JDBC 로 문장 단위 전송). sqlplus 전용 표기 제거.
--
-- ※ 실행 방법: mysql CLI 로 넣을 때는 DELIMITER 를 바꿔야 BEGIN~END 안의 ';' 가 보존된다.
--    JDBC(JdbcRun)로 넣을 때는 문장 단위 전송이라 DELIMITER 불요.
--    mysql CLI: `mysql --delimiter=...` 대신 아래 파일을 그대로 source 하면 안 되고,
--               DELIMITER $$ 로 감싼 사본이 필요하다(운영 배포 시 주의).
--
-- [트리거 이식 기준 — Oracle 판과 동일]
--  · 이식 7종: 규정 삭제(deleteProm)가 앱 코드 대신 트리거 cascade 에 명시 의존하는 체인
--      TRG_DEL_PROM → TRG_DEL_PROV_HTML / TRG_DEL_PROV_VRSN / TRG_DEL_REL_VRSN
--                   → TRG_DEL_REL_FILE / TRG_DEL_REL_IMG  (+ 별표 삭제 TRG_DEL_DOCU)
--------------------------------------------------------------------------------

-- ★규정 회차 삭제의 핵심 cascade (앱 PromServiceImpl.deleteProm 이 명시 의존)
DROP TRIGGER IF EXISTS TRG_DEL_PROM;
CREATE TRIGGER TRG_DEL_PROM
BEFORE DELETE ON TB_PROM
FOR EACH ROW
BEGIN
    DELETE FROM TB_PROV_VRSN WHERE IPROM_NO = OLD.IPROM_NO;
    DELETE FROM TB_PROV_HTML WHERE IPROM_NO = OLD.IPROM_NO;
    DELETE FROM TB_DOCU WHERE IPROM_NO = OLD.IPROM_NO;
    DELETE FROM TB_SRC_STORED WHERE ILAW_ID = OLD.ILAW_ID;
    DELETE FROM TB_REL_VRSN WHERE IPROM_NO = OLD.IPROM_NO;
END;

-- 별표/별지서식 삭제 시 개별 첨부 정리 (앱이 명시 의존)
--   관련자료 마스터를 지우면 TRG_DEL_REL_VRSN → TB_REL_FILE → TRG_DEL_REL_FILE → TB_ATTACH 까지 연쇄된다.
DROP TRIGGER IF EXISTS TRG_DEL_DOCU;
CREATE TRIGGER TRG_DEL_DOCU
BEFORE DELETE ON TB_DOCU
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_VRSN
    WHERE IPROM_NO = OLD.IPROM_NO
    AND SFLAG = 'DOCUMENT'
    AND SFULL_ITEM = OLD.SITEM;
END;

-- 전문HTML 삭제 시 관련자료 앵커 + 첨부 정리 (앱이 명시 의존)
DROP TRIGGER IF EXISTS TRG_DEL_PROV_HTML;
CREATE TRIGGER TRG_DEL_PROV_HTML
BEFORE DELETE ON TB_PROV_HTML
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_VRSN
    WHERE IPROM_NO = OLD.IPROM_NO
    AND SFLAG = 'PROVISION'
    AND SFULL_ITEM = OLD.SITEM;

    DELETE FROM TB_ATTACH
    WHERE IREF_NO = OLD.IPHTML_NO
    AND SREF_TABLE = 'TB_PROV_HTML';
END;

-- 조문 삭제(저장 시 delete+reinsert 패턴 포함) 시 관련자료 앵커 정리
DROP TRIGGER IF EXISTS TRG_DEL_PROV_VRSN;
CREATE TRIGGER TRG_DEL_PROV_VRSN
BEFORE DELETE ON TB_PROV_VRSN
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_VRSN
    WHERE IPROM_NO = OLD.IPROM_NO
    AND SFLAG = 'PROVISION'
    AND SFULL_ITEM = OLD.SITEM;
END;

-- 관련자료 마스터 삭제 시 자식 6종 정리 (규정삭제 cascade 의 중간 고리)
DROP TRIGGER IF EXISTS TRG_DEL_REL_VRSN;
CREATE TRIGGER TRG_DEL_REL_VRSN
BEFORE DELETE ON TB_REL_VRSN
FOR EACH ROW
BEGIN
    DELETE FROM TB_REL_HTML WHERE IRVRSN_NO = OLD.IRVRSN_NO;
    DELETE FROM TB_REL_FILE WHERE IRVRSN_NO = OLD.IRVRSN_NO;
    DELETE FROM TB_REL_IMG WHERE IRVRSN_NO = OLD.IRVRSN_NO;
    DELETE FROM TB_REL_LNK WHERE IRVRSN_NO = OLD.IRVRSN_NO;
    DELETE FROM TB_REL_DMN_LNK WHERE IRVRSN_NO = OLD.IRVRSN_NO;
    DELETE FROM TB_REL_WORD WHERE IRVRSN_NO = OLD.IRVRSN_NO;
END;

-- 관련파일 삭제 시 첨부 정리 (Oracle 판과 동일 — TB_REL_REF 라인은 원본에서 제거됨)
DROP TRIGGER IF EXISTS TRG_DEL_REL_FILE;
CREATE TRIGGER TRG_DEL_REL_FILE
BEFORE DELETE ON TB_REL_FILE
FOR EACH ROW
BEGIN
    DELETE FROM TB_ATTACH WHERE SREF_TABLE = 'TB_REL_FILE' AND IATT_NO = OLD.IATT_NO;
END;

-- 관련이미지 삭제 시 첨부 정리 (Oracle 판과 동일)
DROP TRIGGER IF EXISTS TRG_DEL_REL_IMG;
CREATE TRIGGER TRG_DEL_REL_IMG
BEFORE DELETE ON TB_REL_IMG
FOR EACH ROW
BEGIN
    DELETE FROM TB_ATTACH WHERE SREF_TABLE = 'TB_REL_IMG' AND IATT_NO = OLD.IATT_NO;
END;

--------------------------------------------------------------------------------
-- 함수 GET_FULL_NAME_BY_CATE_NO — 분류 풀네임 "구분명>상위분류>...>자기분류"
--
-- Oracle 판의 `START WITH ICATE_NO = V_CATE_NO CONNECT BY PRIOR IREF = ICATE_NO`
-- (자기 → 상위로 거슬러 오르는 역방향 계층질의)를 재귀 CTE 로 옮겼다.
-- ILEVEL 오름차순 연결 순서는 Oracle 판과 동일(최상위부터 자기 자신까지).
-- V_DB_SUFFIX 는 호출부 시그니처 호환을 위해 유지(전 호출부가 'NONE' 전달, 분기 없음).
--   호출부: Prom_SQL_maria.xml 9곳 / Cate_SQL_maria.xml / RelExclLnk_SQL_maria.xml
--
-- ※ 재귀 CTE 기본 깊이 제한(@@max_recursive_iterations, 기본 1000)은 분류 깊이 대비 충분.
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS GET_FULL_NAME_BY_CATE_NO;
CREATE FUNCTION GET_FULL_NAME_BY_CATE_NO (
    V_DB_SUFFIX     VARCHAR(50),
    V_CATE_NO       DECIMAL(38,10))
    RETURNS VARCHAR(255)
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE V_NAME VARCHAR(255) DEFAULT '';
    DECLARE V_PATH VARCHAR(255) DEFAULT '';

    -- 구분명(ccm 'SGUBUN') — 없으면 빈 문자열 (Oracle NO_DATA_FOUND 핸들러 대체)
    SET V_NAME = IFNULL((
        SELECT D.CODE_NM
          FROM COMTCCMMNDETAILCODE D
         WHERE D.CODE_ID = 'SGUBUN'
           AND D.CODE = (SELECT SGUBUN_ID FROM TB_CATE WHERE ICATE_NO = V_CATE_NO)
         LIMIT 1), '');

    -- 자기 → 상위로 거슬러 올라간 뒤 ILEVEL 오름차순으로 '>' 연결
    SET V_PATH = (
        WITH RECURSIVE ANC (ICATE_NO, IREF, SNAME, ILEVEL) AS (
            SELECT ICATE_NO, IREF, SNAME, ILEVEL
              FROM TB_CATE
             WHERE ICATE_NO = V_CATE_NO
            UNION ALL
            SELECT C.ICATE_NO, C.IREF, C.SNAME, C.ILEVEL
              FROM TB_CATE C
              JOIN ANC A ON C.ICATE_NO = A.IREF
        )
        SELECT GROUP_CONCAT(DISTINCT CONCAT('>', SNAME) ORDER BY ILEVEL SEPARATOR '')
          FROM ANC);

    RETURN CONCAT(V_NAME, IFNULL(V_PATH, ''));
END;
