#!/bin/sh
# ============================================================
#  설정값 암호화 도구 (Linux / UNIX)
#
#   globals.properties 에 넣을 암호문을 만든다. WAS 기동이 필요 없다.
#   설치 직후에는 DB 접속이 안 돼 앱이 뜨지 않아 관리자 화면을 쓸 수 없다 - 그때 이 파일을 쓴다.
#
#   사용법:  ./encrypt.sh "접속URL" "계정ID" "비밀번호"
#            ./encrypt.sh       (인자 없이 실행하면 한 줄에 하나씩 입력, 끝내려면 Ctrl+D)
#   실행권한이 없으면:  sh encrypt.sh ...
#
#   결과를 globals.properties 의 Globals.<DB구분>.Url / .UserName / .Password 값으로 넣고
#   WAS 를 재기동한다. 세 항목 모두 암호문이어야 한다.
# ============================================================

BASE=$(cd "$(dirname "$0")" && pwd)

if [ -n "$JAVA_HOME" ]; then
  JAVA_CMD="$JAVA_HOME/bin/java"
else
  JAVA_CMD=java
fi

if [ ! -f "$BASE/classes/egovframework/com/uss/ion/crypto/EgovCryptoCli.class" ]; then
  echo "[오류] WAR 를 푼 뒤 WEB-INF 폴더 안에서 실행해야 합니다." >&2
  exit 1
fi

# 리눅스/UNIX 는 이 두 줄 그대로면 된다.
# (Git Bash·Cygwin 에서 돌릴 때만 예외 - 그쪽 java 는 윈도우 JVM 이라 경로와 구분자를 바꿔 줘야 한다)
SEP=:
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*)
    SEP=';'
    if command -v cygpath >/dev/null 2>&1; then BASE=$(cygpath -w "$BASE"); fi
    ;;
esac

exec "$JAVA_CMD" -cp "$BASE/classes$SEP$BASE/lib/*" egovframework.com.uss.ion.crypto.EgovCryptoCli "$@"
