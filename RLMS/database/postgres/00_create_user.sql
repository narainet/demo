--------------------------------------------------------------------------------
-- 00_create_user.sql — PostgreSQL 롤/데이터베이스 생성
-- RLMS 통합본(PostgreSQL) 설치 세트.
-- 실행 계정: postgres(관리자). psql 등에서 실행(CREATE DATABASE 는 트랜잭션 밖).
--
-- ★콜레이션은 DB 생성 시 고정(변경=재생성뿐). 'C' 선택 이유:
--   Oracle BINARY 정렬과 일치·인덱스 안정·한글(완성형)은 유니코드 코드포인트가
--   가나다순이라 정렬 자연스러움(실측 확인 2026-08-03).
--------------------------------------------------------------------------------

CREATE ROLE rlms LOGIN PASSWORD 'www_codea_kr_12';

CREATE DATABASE rlms
    OWNER rlms
    ENCODING 'UTF8'
    LC_COLLATE 'C'
    LC_CTYPE 'C'
    TEMPLATE template0;

-- 이후 10_tables.sql 부터는 rlms 계정으로 rlms DB 에 접속해 실행한다.
