@echo off
rem ============================================================
rem  설정값 암호화 도구 (Windows)
rem
rem   globals.properties 에 넣을 암호문을 만든다. WAS 기동이 필요 없다.
rem   설치 직후에는 DB 접속이 안 돼 앱이 뜨지 않아 관리자 화면을 쓸 수 없다 - 그때 이 파일을 쓴다.
rem
rem   사용법:  encrypt.bat "접속URL" "계정ID" "비밀번호"
rem            encrypt.bat        (인자 없이 실행하면 한 줄에 하나씩 입력, 끝내려면 Ctrl+Z 후 Enter)
rem
rem   결과를 globals.properties 의 Globals.<DB구분>.Url / .UserName / .Password 값으로 넣고
rem   WAS 를 재기동한다. 세 항목 모두 암호문이어야 한다.
rem ============================================================
setlocal

set "BASE=%~dp0"

if defined JAVA_HOME (
  set "JAVA_CMD=%JAVA_HOME%\bin\java.exe"
) else (
  set "JAVA_CMD=java"
)

if not exist "%BASE%classes\egovframework\com\uss\ion\crypto\EgovCryptoCli.class" (
  echo [오류] WAR 를 푼 뒤 WEB-INF 폴더 안에서 실행해야 합니다.
  exit /b 1
)

"%JAVA_CMD%" -cp "%BASE%classes;%BASE%lib\*" egovframework.com.uss.ion.crypto.EgovCryptoCli %*
set "RC=%ERRORLEVEL%"

endlocal & exit /b %RC%
