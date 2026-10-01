# -*- coding: utf-8 -*-
"""MyBatis 매퍼 Oracle → MariaDB 변환기 (2026-08-03)

★설계 근거 — MariaDB 10.8 실측(네이티브 지원이라 변환하지 않는 것):
    NVL / NVL2 / TO_CHAR(날짜, Oracle 포맷토큰) / SUBSTR / INSTR / MOD /
    GREATEST / ADD_MONTHS / LAST_DAY / FROM DUAL
    `||` 문자열연결 → datasource connectionInitSqls 의 sql_mode PIPES_AS_CONCAT 로 해결
    (매퍼를 건드리지 않는다 — Lex 113 + Reg 181 건)

변환 대상:
    SYSDATE(괄호없음) → SYSDATE()      SYSTIMESTAMP → NOW(6)
    TO_DATE(x,fmt)    → STR_TO_DATE    DECODE(...)  → CASE
    REGEXP_LIKE(a,b)  → a REGEXP b     TRUNC(날짜)  → DATE()  / TRUNC(d,'IW') → 주 시작일

수동 대상(자동 변환하지 않고 리포트만):
    ROWNUM 페이징 · CONNECT BY 계층질의 · MERGE INTO · CONTAINS() 전문검색
"""
import io, os, re, sys
import os as _os
# 워크스페이스 루트. 다른 경로에 설치했으면 환경변수 RLMS_WS 로 지정한다.
_WS = _os.environ.get("RLMS_WS", "C:/eGovFrameDev-4.3.1-64bit/workspace")

WS = _WS

def rd(p):
    with io.open(p, encoding="utf-8-sig") as f:
        return f.read().replace("\r\n", "\n")

def wr(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with io.open(p, "w", encoding="utf-8", newline="") as f:
        f.write(s)

_FMT = [('YYYY', '%Y'), ('RRRR', '%Y'), ('HH24', '%H'), ('HH12', '%h'),
        ('MON', '%b'), ('DAY', '%W'),
        ('MM', '%m'), ('DD', '%d'), ('HH', '%h'), ('MI', '%i'), ('SS', '%s'), ('YY', '%y')]

def ora_fmt(f):
    out, i, F = '', 0, f.upper()
    while i < len(F):
        for k, v in _FMT:
            if F.startswith(k, i):
                out += v
                i += len(k)
                break
        else:
            out += f[i]
            i += 1
    return out

def split_args(s):
    """괄호/따옴표 깊이를 지키며 최상위 콤마로 인자 분리"""
    args, cur, depth, inq = [], '', 0, False
    for ch in s:
        if ch == "'":
            inq = not inq
            cur += ch
        elif not inq and ch == '(':
            depth += 1
            cur += ch
        elif not inq and ch == ')':
            depth -= 1
            cur += ch
        elif not inq and ch == ',' and depth == 0:
            args.append(cur.strip())
            cur = ''
        else:
            cur += ch
    if cur.strip():
        args.append(cur.strip())
    return args

def find_call(s, name, start=0):
    """name( ... ) 호출의 (시작, 인자문자열시작, 끝) — 괄호 균형 기준"""
    pat = re.compile(r'\b' + name + r'\s*\(', re.I)
    m = pat.search(s, start)
    if not m:
        return None
    i = m.end()          # '(' 다음
    depth, inq = 1, False
    while i < len(s):
        ch = s[i]
        if ch == "'":
            inq = not inq
        elif not inq and ch == '(':
            depth += 1
        elif not inq and ch == ')':
            depth -= 1
            if depth == 0:
                return (m.start(), m.end(), i)
        i += 1
    return None

def conv_decode(s):
    """DECODE(e, s1,r1, s2,r2, ..., default) → CASE WHEN e = s1 THEN r1 ... ELSE default END"""
    while True:
        f = find_call(s, 'DECODE')
        if not f:
            return s
        a, b, c = f
        args = split_args(s[b:c])
        if len(args) < 3:
            return s
        expr, rest = args[0], args[1:]
        parts = ['CASE']
        i = 0
        while i + 1 < len(rest):
            parts.append("WHEN %s = %s THEN %s" % (expr, rest[i], rest[i + 1]))
            i += 2
        if i < len(rest):
            parts.append("ELSE %s" % rest[i])
        parts.append('END')
        s = s[:a] + ' '.join(parts) + s[c + 1:]

def conv_to_date(s):
    """TO_DATE(x, 'fmt') → STR_TO_DATE(x, '%...'),  TO_DATE(x) → STR_TO_DATE(x,'%Y%m%d')"""
    while True:
        f = find_call(s, 'TO_DATE')
        if not f:
            return s
        a, b, c = f
        args = split_args(s[b:c])
        if len(args) >= 2 and args[1].startswith("'"):
            new = "STR_TO_DATE(%s, '%s')" % (args[0], ora_fmt(args[1].strip("'")))
        elif len(args) == 1:
            new = "STR_TO_DATE(%s, '%%Y%%m%%d')" % args[0]
        else:
            new = "STR_TO_DATE(%s)" % ', '.join(args)
        s = s[:a] + new + s[c + 1:]

def conv_regexp_like(s):
    """REGEXP_LIKE(a, b) → (a REGEXP b)"""
    while True:
        f = find_call(s, 'REGEXP_LIKE')
        if not f:
            return s
        a, b, c = f
        args = split_args(s[b:c])
        new = "(%s REGEXP %s)" % (args[0], args[1]) if len(args) >= 2 else s[a:c + 1]
        s = s[:a] + new + s[c + 1:]

def conv_trunc(s):
    """TRUNC(d)        → DATE(d)                  (날짜 절삭)
       TRUNC(d,'IW')   → 해당 주 월요일           (ISO 주 시작)
       TRUNC(d,'MM')   → 해당 월 1일"""
    while True:
        f = find_call(s, 'TRUNC')
        if not f:
            return s
        a, b, c = f
        args = split_args(s[b:c])
        if len(args) == 1:
            new = "DATE(%s)" % args[0]
        elif len(args) >= 2:
            unit = args[1].strip("'").upper()
            d = args[0]
            if unit in ('IW', 'W', 'DY', 'DAY'):
                new = "DATE(DATE_SUB(%s, INTERVAL WEEKDAY(%s) DAY))" % (d, d)
            elif unit in ('MM', 'MONTH', 'MON'):
                new = "DATE_FORMAT(%s, '%%Y-%%m-01')" % d
            elif unit in ('YYYY', 'YEAR', 'YY'):
                new = "DATE_FORMAT(%s, '%%Y-01-01')" % d
            elif unit in ('DD', 'DDD', 'J'):
                new = "DATE(%s)" % d
            else:
                new = "DATE(%s)" % d
        else:
            new = s[a:c + 1]
        s = s[:a] + new + s[c + 1:]

def conv_dbms_lob(s):
    """Oracle DBMS_LOB → MariaDB 문자열 함수 (LONGTEXT 는 일반 문자열로 다룬다)
       ⚠️인자 순서 주의: DBMS_LOB.SUBSTR(lob, 길이, 시작) ↔ SUBSTRING(str, 시작, 길이)"""
    while True:
        f = find_call(s, r'DBMS_LOB\.SUBSTR')
        if not f:
            break
        a, b, c = f
        args = split_args(s[b:c])
        if len(args) >= 3:
            new = "SUBSTRING(%s, %s, %s)" % (args[0], args[2], args[1])
        elif len(args) == 2:
            new = "SUBSTRING(%s, 1, %s)" % (args[0], args[1])
        else:
            new = "SUBSTRING(%s, 1, 4000)" % args[0]
        s = s[:a] + new + s[c + 1:]
    s = re.sub(r'\bDBMS_LOB\.GETLENGTH\s*\(', 'CHAR_LENGTH(', s, flags=re.I)
    s = re.sub(r'\bDBMS_LOB\.INSTR\s*\(', 'INSTR(', s, flags=re.I)
    s = re.sub(r'\bDBMS_LOB\.COMPARE\s*\(', 'STRCMP(', s, flags=re.I)
    return s

def conv_date_arith(s):
    """★Oracle 날짜 산술은 '일(day)' 단위 — MariaDB 는 숫자 뺄셈이 되어 조용히 깨진다.
       SYSDATE() - 1 → (SYSDATE() - INTERVAL 1 DAY)"""
    s = re.sub(r'\bSYSDATE\(\)\s*-\s*(\d+)\b', r'(SYSDATE() - INTERVAL \1 DAY)', s, flags=re.I)
    s = re.sub(r'\bSYSDATE\(\)\s*\+\s*(\d+)\b', r'(SYSDATE() + INTERVAL \1 DAY)', s, flags=re.I)
    s = re.sub(r'\bNOW\(\)\s*-\s*(\d+)\b', r'(NOW() - INTERVAL \1 DAY)', s, flags=re.I)
    s = re.sub(r'\bNOW\(\)\s*\+\s*(\d+)\b', r'(NOW() + INTERVAL \1 DAY)', s, flags=re.I)
    return s

def conv_fmt_tokens(s):
    """MariaDB TO_CHAR 가 모르는 Oracle 밀리초 토큰(FF/FF3) 제거.
       ⚠️반드시 TO_CHAR/TO_DATE 의 '두 번째 인자' 안에서만 손댄다 —
         SQL 전체를 따옴표로 훑으면 컬럼명(OFFICE_RECEIPT_DT, LAW_SUIT_STAFF)이 훼손된다.
         (2026-08-03 실사고: 따옴표 밖까지 매칭해 FF 를 지워 4개 매퍼 손상)"""
    def fix(m):
        head, fmt = m.group(1), m.group(2)
        if not re.search(r'FF\d?', fmt, re.I):
            return m.group(0)
        return "%s'%s'" % (head, re.sub(r'FF\d?', '', fmt, flags=re.I))
    return re.sub(r"(TO_CHAR\s*\([^()']*(?:\([^()]*\))?[^()']*,\s*)'([A-Za-z0-9:\-/ .]*)'",
                  fix, s, flags=re.I)

def convert_sql(s):
    """SQL 본문 변환 — XML 주석/CDATA 구분 없이 안전한 치환만 수행"""
    s = re.sub(r'\bSYSTIMESTAMP\b', 'NOW(6)', s, flags=re.I)
    s = re.sub(r'\bSYSDATE\b(?!\s*\()', 'SYSDATE()', s, flags=re.I)
    s = conv_date_arith(s)
    s = conv_to_date(s)
    s = conv_decode(s)
    s = conv_regexp_like(s)
    s = conv_trunc(s)
    s = conv_dbms_lob(s)
    s = conv_fmt_tokens(s)
    return s

MANUAL = [('ROWNUM', r'\bROWNUM\b'),
          ('CONNECT BY', r'\bCONNECT\s+BY\b'),
          ('START WITH', r'\bSTART\s+WITH\b'),
          ('MERGE INTO', r'\bMERGE\s+INTO\b'),
          ('CONTAINS', r'\bCONTAINS\s*\('),
          ('LISTAGG', r'\bLISTAGG\s*\('),
          ('LEVEL', r'\bLEVEL\b')]

def convert_file(src, dst):
    s = rd(src)
    # 헤더 경로 주석 갱신
    s = s.replace('_SQL_oracle.xml', '_SQL_maria.xml')
    s = convert_sql(s)
    # 수동 대상 탐지
    hits = {}
    for name, pat in MANUAL:
        n = len(re.findall(pat, s, re.I))
        if n:
            hits[name] = n
    if hits:
        note = ("<!-- ⚠️ MariaDB 수동 확인 필요: "
                + ', '.join('%s %d건' % (k, v) for k, v in sorted(hits.items()))
                + " — Oracle 전용 구문이라 자동 변환하지 않았다. -->\n")
        # DOCTYPE 뒤/mapper 태그 앞에 삽입
        m = re.search(r'(<mapper\b)', s)
        if m:
            s = s[:m.start()] + note + s[m.start():]
    wr(dst, s)
    return hits

if __name__ == '__main__':
    product = sys.argv[1]
    base = os.path.join(WS, product, 'src/main/resources/egovframework/mapper')
    if len(sys.argv) > 2:            # 선택: mapper 하위 경로만 변환 (예: rlms, com/uss/ion/brd)
        base = os.path.join(base, sys.argv[2])
    made, manual_files, totals = 0, [], {}
    for root, _, files in os.walk(base):
        for fn in sorted(files):
            if not fn.endswith('_oracle.xml'):
                continue
            src = os.path.join(root, fn)
            dst = os.path.join(root, fn.replace('_oracle.xml', '_maria.xml'))
            hits = convert_file(src, dst)
            made += 1
            if hits:
                manual_files.append((os.path.relpath(dst, base).replace('\\', '/'), hits))
                for k, v in hits.items():
                    totals[k] = totals.get(k, 0) + v
    print('%s: %d개 매퍼 생성(oracle → maria 전량 덮어쓰기)' % (product, made))
    print('  수동 확인 대상 %d개 파일:' % len(manual_files))
    for f, h in manual_files:
        print('    %-52s %s' % (f, ', '.join('%s=%d' % kv for kv in sorted(h.items()))))
    print('  합계:', ', '.join('%s=%d' % kv for kv in sorted(totals.items())))
