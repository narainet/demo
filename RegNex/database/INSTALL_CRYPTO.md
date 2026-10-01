# 설치 시 DB 접속정보 암호화 절차

`globals.properties` 의 DB 접속정보 **세 항목(Url · UserName · Password)은 모두 암호문**이다.
평문을 넣으면 기동 시 오류가 나지 않고 **깨진 문자열로 접속을 시도**해 원인을 찾기 어려우니,
반드시 세 항목을 함께 바꾼다.

```
Globals.<DB구분>.Url       = <암호문>
Globals.<DB구분>.UserName  = <암호문>
Globals.<DB구분>.Password  = <암호문>
```
`<DB구분>` = `oracle` / `tibero` / `maria` / `postgres` (= `Globals.DbType` 값)
`Globals.<DB구분>.DriverClassName` 은 민감정보가 아니라 **평문 그대로** 둔다.

★암호화는 **DB 종류와 무관**하다. `context-crypto.xml` 의 `algorithmKey` 하나로만 암호화하므로,
같은 값이면 어느 DB 항목에 넣든 암호문이 같다.

---

## 방법 ① 설치 시점 — 명령행 도구 (WAS 기동 불필요)

설치 직후에는 아직 DB 접속이 안 돼 앱이 뜨지 않으므로 **관리자 화면을 쓸 수 없다.**
이때는 WAR 안에 함께 배포되는 실행 파일을 쓴다. WAR 를 푼 뒤 **`WEB-INF` 폴더에서** 실행한다.
(`WEB-INF` 안이라 웹으로는 내려받을 수 없다.)

Windows
```
cd <배포경로>\WEB-INF
encrypt.bat "jdbc:oracle:thin:@127.0.0.1:1521:xe" "계정ID" "비밀번호"
```

Linux / UNIX
```
cd <배포경로>/WEB-INF
sh encrypt.sh "jdbc:oracle:thin:@127.0.0.1:1521:xe" "계정ID" "비밀번호"
```
`chmod +x encrypt.sh` 해 두면 `./encrypt.sh ...` 로도 실행된다.
`JAVA_HOME` 이 설정돼 있으면 그 자바를, 없으면 PATH 의 `java` 를 쓴다.

<details><summary>실행 파일 없이 직접 자바로 실행하려면</summary>

```
java -cp "WEB-INF/classes;WEB-INF/lib/*" egovframework.com.uss.ion.crypto.EgovCryptoCli "접속URL" "계정ID" "비밀번호"
```
리눅스는 클래스패스 구분자를 `:` 로 바꾼다.
</details>

출력 예 — 왼쪽이 그대로 프로퍼티 값이 된다.
```
# context-crypto.xml : algorithm=SHA-256, algorithmKey=wwwcodeakr, blockSize=1024

Q0bwy8vXjXViofb7Yt6zz2aDRtZqGZXYXhMryoRSscc9fEg25a-9dOiyBqfLsgLQ    # jdbc:oracle:thin:@127.0.0.1:1521:xe
2VaCzyfsETJfqOfFsrvSxw    # 계정ID
Dj4dlTLIjw1Bqb1XdrtJEA    # 비밀번호
```

- 인자를 생략하면 **표준입력**에서 한 줄에 하나씩 읽는다(비밀번호를 명령 이력에 남기고 싶지 않을 때).
  입력을 끝내려면 Windows 는 `Ctrl+Z` 후 Enter, Linux 는 `Ctrl+D`.
  ```
  encrypt.bat            (Windows)
  sh encrypt.sh          (Linux)
  ```
  파일에서 읽어도 된다: `sh encrypt.sh < 값목록.txt`  (BOM 이 붙어 있어도 알아서 걷어낸다)
- 키 설정 파일을 클래스패스에서 못 찾으면 `-c <context-crypto.xml 경로>` 로 지정한다.
- 도구는 암호화 직후 **복호를 되돌려 확인**한다. `★복호 왕복 실패` 가 찍히면 키 설정이 잘못된 것이다.
- 이 도구는 **암호화만** 한다 — 설정 파일을 고치지 않는다. 값 반영은 사람이 한다.

절차
1. 위 명령으로 세 값의 암호문을 얻는다.
2. `WEB-INF/classes/egovframework/egovProps/globals.properties` 의 해당 세 줄 값을 바꾼다.
   (`Globals.DbType` 도 쓰는 DB 로 맞춘다.)
3. WAS 를 기동한다. **설정은 기동할 때 한 번만 읽으므로 반드시 재기동해야 반영된다.**

## 방법 ② 운영 중 계정 교체 — 관리자 화면

앱이 이미 떠 있으면 화면이 더 편하다.
**관리자 > 운영관리 > 설정값 암호화** (`/uss/ion/crypto/dbCryptoView.do`, ADMIN 전용)
평문을 한 줄에 하나씩 넣으면 줄별 암호문을 준다. CLI 와 **완전히 같은 암호문**을 만든다.
바꾼 뒤에는 마찬가지로 WAS 재기동이 필요하다.

---

## 참고 — 임시로 평문을 쓰려면 (권장하지 않음)

`context-crypto.xml` 의 `crypto="false"` 로 두면 복호를 건너뛰고 값을 **평문 그대로** 쓴다.
개발·검증 편의용이며, 운영에서는 접속정보가 평문으로 남으므로 쓰지 않는다.
되돌릴 때 `crypto="true"` 로 고치는 것을 잊으면 그대로 평문 운영이 되니 주의.

## 문제가 생기면

| 증상 | 원인 |
|---|---|
| 기동은 되는데 DB 접속만 실패 | 세 항목 중 일부가 평문 — 복호가 예외 없이 깨진 값을 돌려준다. 세 항목 모두 다시 암호화 |
| `★복호 왕복 실패` 출력 | `context-crypto.xml` 의 `algorithmKey` / `algorithmKeyHash` 불일치 |
| 값을 바꿨는데 그대로 | WAS 재기동 안 함(설정은 기동 시 1회 로드) |
