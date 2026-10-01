--------------------------------------------------------------------------------
-- 00_create_user.sql — 신규 스키마 RLMS 계정 생성 (DBA(SYS/SYSTEM)로 1회 실행)
--
-- 대상: Oracle 21c XE (기존 운영 DB 와 같은 인스턴스 기준)
-- ※ 기존 운영 계정은 CDB$ROOT 에 생성되어 있음(구식 방식). 동일 패턴으로 RLMS 를
--   CDB$ROOT 에 만들면 앱 JDBC URL(jdbc:oracle:thin:@HOST:1521:xe)을 그대로 두고
--   globals.properties 의 UserName/Password 만 바꾸면 된다. (권장)
--   → 별도 서버/PDB(XEPDB1)에 만들 경우 URL 을 서비스명 방식
--     (jdbc:oracle:thin:@//HOST:1521/XEPDB1) 으로 바꿔야 함.
--
-- 비밀번호는 반드시 변경 후 실행할 것.
--------------------------------------------------------------------------------

-- CDB 루트에 일반명(비 C##) 사용자 생성 허용 (기존 운영 계정과 동일 방식)
ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE;

CREATE USER RLMS IDENTIFIED BY "rlms_CHANGE_ME_2026"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

-- 기본 접속/객체 생성 권한
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE, CREATE SYNONYM TO RLMS;

-- Oracle Text (전문검색 인덱스 IDX_PROV_VRSN_FT 생성/운영에 필요)
GRANT CTXAPP TO RLMS;
GRANT EXECUTE ON CTXSYS.CTX_DDL TO RLMS;

--------------------------------------------------------------------------------
-- 이후 절차: RLMS 계정으로 접속해 10_* → 20_* 스크립트를 순서대로 실행
-- (전체 순서는 README.md 참조)
--------------------------------------------------------------------------------
