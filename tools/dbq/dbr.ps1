# 신규 DB 설치 스크립트 러너. 사용: .\tools\dbq\dbr.ps1 <user> <password> <script.sql | exec "SQL">
param([Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)][string[]]$Args_)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# JDK 21 필요(ojdbc11 이 Java 11+ 클래스파일). 다른 경로면 환경변수 RLMS_JDK 로 지정.
$jdk = if ($env:RLMS_JDK) { $env:RLMS_JDK } else { "C:\java\jdk-21.0.10" }
# 접속 URL. 환경변수 RLMS_DB_URL 로 지정(미지정 시 로컬 Oracle 가정).
$dbUrl = if ($env:RLMS_DB_URL) { $env:RLMS_DB_URL } else { "jdbc:oracle:thin:@127.0.0.1:1521:xe" }
$m2 = "$env:USERPROFILE\.m2\repository"
$cp = "$here;$m2\com\oracle\database\jdbc\ojdbc11\21.11.0.0\ojdbc11-21.11.0.0.jar"

$src = "$here\DbRun.java"
$cls = "$here\DbRun.class"
if (-not (Test-Path $cls) -or ((Get-Item $src).LastWriteTime -gt (Get-Item $cls).LastWriteTime)) {
    & "$jdk\bin\javac.exe" -encoding UTF-8 -cp $cp -d $here $src
    if ($LASTEXITCODE -ne 0) { throw "DbRun compile failed" }
}

[Console]::OutputEncoding = [Text.Encoding]::UTF8
& "$jdk\bin\java.exe" "-Dfile.encoding=UTF-8" "-Ddb.url=$dbUrl" -cp $cp DbRun @Args_
exit $LASTEXITCODE
