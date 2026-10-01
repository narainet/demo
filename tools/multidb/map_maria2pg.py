# -*- coding: utf-8 -*-
"""MyBatis 매퍼 MariaDB → PostgreSQL 변환기 (2026-08-05)

★원본을 oracle 이 아니라 maria 로 삼는 이유:
    ROWNUM 페이징 해체(LIMIT/OFFSET)·CONNECT BY→WITH RECURSIVE·KEEP→ROW_NUMBER·
    INSERT ALL→다중 VALUES·FULL OUTER→LEFT JOIN∪안티조인·파생테이블 별칭·
    CONTAINS→부분일치 등 구조 변환(8/3+8/5 두 세션의 수작업, 실기동 73/73 검증)이
    이미 반영돼 있고, 이 구조들은 PG 와 문법이 같다. 남는 것은 함수 어휘 치환뿐.

PG 로 갈 때 바꾸는 것:
    NVL/IFNULL→COALESCE, NVL2→CASE, SYSDATE()→LOCALTIMESTAMP, NOW(n)→CURRENT_TIMESTAMP,
    STR_TO_DATE→TO_TIMESTAMP/TO_DATE(토큰 역매핑), DATE_FORMAT→TO_CHAR(역매핑),
    INSTR→STRPOS, REGEXP→~, DATE(x)→CAST(x AS date), DATEDIFF→날짜뺄셈,
    TIMESTAMPDIFF(SECOND)→EXTRACT(EPOCH), WEEKDAY→ISODOW-1, ADD_MONTHS/INTERVAL→make_interval,
    LAST_DAY→date_trunc 식, CAST AS UNSIGNED→BIGINT, CAST AS CHAR→VARCHAR(PG CHAR=char(1) 함정),
    FROM DUAL 제거, FF3 밀리초 관용구(NOW(3)+%f)→TO_CHAR(...,'...MS') 네이티브.

PG 네이티브라 그대로 두는 것:
    TO_CHAR(날짜)·SUBSTR·MOD·GREATEST·LPAD·CONCAT·||·LIMIT/OFFSET·WITH RECURSIVE·
    ROW_NUMBER()·CASE·EXISTS(WITH…)·`col IS NULL, col` 정렬 관용구.

수동 대상(자동 변환하지 않고 리포트만):
    ON DUPLICATE KEY(→ON CONFLICT, 테이블 PK 필요)·GROUP_CONCAT(→STRING_AGG)·STRCMP·
    ORDER BY … DESC 의 NULLS LAST 복원(oracle 쌍둥이에 NULLS 절이 있는 파일)
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

# MySQL % 토큰 → Oracle/PG 포맷 토큰 (긴 것 우선 불필요 — %x 는 2글자 고정)
_FMT_REV = {'%Y': 'YYYY', '%y': 'YY', '%m': 'MM', '%d': 'DD', '%H': 'HH24',
            '%h': 'HH12', '%i': 'MI', '%s': 'SS', '%b': 'MON', '%W': 'DAY',
            '%f': 'US'}

def mysql_fmt_to_pg(f):
    out, i = '', 0
    while i < len(f):
        if f[i] == '%' and i + 1 < len(f):
            tok = f[i:i+2]
            out += _FMT_REV.get(tok, tok)
            i += 2
        else:
            out += f[i]
            i += 1
    return out

def split_args(s):
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
    pat = re.compile(r'\b' + name + r'\s*\(', re.I)
    m = pat.search(s, start)
    if not m:
        return None
    i = m.end()
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

def map_calls(s, name, fn):
    """name(...) 호출 전부를 fn(args, 원문)->치환문자열 로 교체(중첩 안전, 좌→우 재스캔)"""
    pos = 0
    while True:
        f = find_call(s, name, pos)
        if not f:
            return s
        a, b, c = f
        args = split_args(s[b:c])
        new = fn(args, s[a:c + 1])
        if new is None:            # 변환 불가 — 원문 유지하고 다음 위치로
            pos = c + 1
            continue
        s = s[:a] + new + s[c + 1:]
        pos = a + len(new)

# ── 개별 규칙 ───────────────────────────────────────────────
def conv_ff3_idiom(s):
    """maria FF3 관용구 → PG 네이티브 밀리초.
       CONCAT(DATE_FORMAT(NOW(3),'%Y%m%d%H%i%s'), SUBSTR(DATE_FORMAT(NOW(3),'%f'),1,3))
       → TO_CHAR(CURRENT_TIMESTAMP,'YYYYMMDDHH24MISSMS')  (MS=3자리 밀리초)"""
    pat = re.compile(
        r"CONCAT\(\s*DATE_FORMAT\(NOW\(3\),\s*'%Y%m%d%H%i%s'\)\s*,\s*"
        r"SUBSTR\(DATE_FORMAT\(NOW\(3\),\s*'%f'\)\s*,\s*1\s*,\s*3\s*\)\s*\)", re.I)
    return pat.sub("TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISSMS')", s)

def conv_trunc_iw(s):
    """maria 주시작 관용구 DATE(DATE_SUB(x, INTERVAL WEEKDAY(x) DAY)) → date_trunc('week', x)"""
    def f(m):
        return "CAST(date_trunc('week', %s) AS date)" % m.group(1)
    return re.sub(r"DATE\(DATE_SUB\(([^,()]+(?:\([^()]*\))?[^,()]*),\s*INTERVAL\s+WEEKDAY\(\s*\1\s*\)\s+DAY\)\)",
                  f, s, flags=re.I)

def conv_str_to_date(s):
    def f(args, orig):
        if len(args) < 2 or not args[1].startswith("'"):
            return None
        fmt = mysql_fmt_to_pg(args[1].strip("'"))
        fn = 'TO_TIMESTAMP' if re.search(r'HH24|HH12|MI|SS', fmt) else 'TO_DATE'
        return "%s(%s, '%s')" % (fn, args[0], fmt)
    return map_calls(s, 'STR_TO_DATE', f)

def conv_date_format(s):
    def f(args, orig):
        if len(args) < 2 or not args[1].startswith("'"):
            return None
        return "TO_CHAR(%s, '%s')" % (args[0], mysql_fmt_to_pg(args[1].strip("'")))
    return map_calls(s, 'DATE_FORMAT', f)

def conv_nvl2(s):
    def f(args, orig):
        if len(args) != 3:
            return None
        return "CASE WHEN %s IS NOT NULL THEN %s ELSE %s END" % (args[0], args[1], args[2])
    return map_calls(s, 'NVL2', f)

def conv_datediff(s):
    def f(args, orig):
        if len(args) != 2:
            return None
        return "(CAST(%s AS date) - CAST(%s AS date))" % (args[0], args[1])
    return map_calls(s, 'DATEDIFF', f)

def conv_timestampdiff(s):
    def f(args, orig):
        if len(args) != 3:
            return None
        unit = args[0].upper()
        div = {'SECOND': 1, 'MINUTE': 60, 'HOUR': 3600, 'DAY': 86400}.get(unit)
        if div is None:
            return None
        core = "EXTRACT(EPOCH FROM (CAST(%s AS timestamp) - CAST(%s AS timestamp)))" % (args[2], args[1])
        if div == 1:
            return "CAST(%s AS int)" % core
        return "CAST(%s / %d AS int)" % (core, div)
    return map_calls(s, 'TIMESTAMPDIFF', f)

def conv_weekday(s):
    def f(args, orig):
        if len(args) != 1:
            return None
        return "(CAST(EXTRACT(ISODOW FROM %s) AS int) - 1)" % args[0]
    return map_calls(s, 'WEEKDAY', f)

def conv_add_months(s):
    def f(args, orig):
        if len(args) != 2:
            return None
        return "(%s + make_interval(months => CAST(%s AS int)))" % (args[0], args[1])
    return map_calls(s, 'ADD_MONTHS', f)

def conv_last_day(s):
    def f(args, orig):
        if len(args) != 1:
            return None
        return "CAST(date_trunc('month', %s) + INTERVAL '1 month - 1 day' AS date)" % args[0]
    return map_calls(s, 'LAST_DAY', f)

def conv_date_cast(s):
    """단독 DATE(x) → CAST(x AS date)  (DATE_FORMAT/DATE_SUB 는 \b+( 로 제외됨)"""
    def f(args, orig):
        if len(args) != 1:
            return None
        return "CAST(%s AS date)" % args[0]
    return map_calls(s, 'DATE', f)

def conv_interval(s):
    """INTERVAL 1 DAY → INTERVAL '1 day' / INTERVAL #{p} DAY → make_interval(days=>…)
       (앞의 +,- 연산자는 그대로 두면 된다)"""
    s = re.sub(r'\bINTERVAL\s+(\d+)\s+(DAY|MONTH|YEAR|HOUR|MINUTE|SECOND)S?\b',
               lambda m: "INTERVAL '%s %s'" % (m.group(1), m.group(2).lower()), s, flags=re.I)
    s = re.sub(r'\bINTERVAL\s+(#\{[^}]+\})\s+DAY\b',
               r'make_interval(days => CAST(\1 AS int))', s, flags=re.I)
    return s

def convert_sql(s):
    s = conv_ff3_idiom(s)
    s = conv_trunc_iw(s)
    s = re.sub(r'\bSYSDATE\(\)', 'LOCALTIMESTAMP', s, flags=re.I)
    s = re.sub(r'\bNOW\(\s*\d+\s*\)', 'CURRENT_TIMESTAMP', s, flags=re.I)
    s = re.sub(r'\bNVL\s*\(', 'COALESCE(', s, flags=re.I)
    s = re.sub(r'\bIFNULL\s*\(', 'COALESCE(', s, flags=re.I)
    s = conv_nvl2(s)
    s = conv_str_to_date(s)
    s = conv_date_format(s)
    s = re.sub(r'\bINSTR\s*\(', 'STRPOS(', s, flags=re.I)
    s = re.sub(r'(\S)\s+REGEXP\s+', r'\1 ~ ', s)
    s = conv_datediff(s)
    s = conv_timestampdiff(s)
    s = conv_weekday(s)
    s = conv_add_months(s)
    s = conv_last_day(s)
    s = conv_date_cast(s)
    s = conv_interval(s)
    s = re.sub(r'\bAS\s+UNSIGNED\s*\)', 'AS BIGINT)', s, flags=re.I)
    s = re.sub(r'\bAS\s+CHAR\s*\)', 'AS VARCHAR)', s, flags=re.I)   # PG CHAR=char(1) 함정
    s = re.sub(r'\s+FROM\s+DUAL\b', '', s, flags=re.I)
    return s

MANUAL = [('ON DUPLICATE KEY', r'\bON\s+DUPLICATE\s+KEY\b'),
          ('GROUP_CONCAT', r'\bGROUP_CONCAT\s*\('),
          ('STRCMP', r'\bSTRCMP\s*\('),
          ('SEPARATOR', r'\bSEPARATOR\b'),
          ('DESC(NULLS 복원 검토)', r'\bDESC\b(?!\w)')]

def convert_file(src, dst, ora_twin):
    s = rd(src)
    s = s.replace('_SQL_maria.xml', '_SQL_postgres.xml')
    s = convert_sql(s)
    hits = {}
    for name, pat in MANUAL[:4]:
        n = len(re.findall(pat, s, re.I))
        if n:
            hits[name] = n
    # oracle 쌍둥이에 NULLS 절이 있으면 DESC NULLS LAST 복원 검토 대상
    if ora_twin and os.path.exists(ora_twin):
        if re.search(r'NULLS\s+(LAST|FIRST)', rd(ora_twin), re.I):
            hits['NULLS(oracle쌍둥이 보유)'] = 1
    wr(dst, s)
    return hits

if __name__ == '__main__':
    product = sys.argv[1]
    base = os.path.join(WS, product, 'src/main/resources/egovframework/mapper')
    if len(sys.argv) > 2:
        base = os.path.join(base, sys.argv[2])
    made, manual_files, totals = 0, [], {}
    for root, _, files in os.walk(base):
        for fn in sorted(files):
            if not fn.endswith('_maria.xml'):
                continue
            src = os.path.join(root, fn)
            dst = os.path.join(root, fn.replace('_maria.xml', '_postgres.xml'))
            ora = os.path.join(root, fn.replace('_maria.xml', '_oracle.xml'))
            hits = convert_file(src, dst, ora)
            made += 1
            if hits:
                manual_files.append((os.path.relpath(dst, base).replace('\\', '/'), hits))
                for k, v in hits.items():
                    totals[k] = totals.get(k, 0) + v
    print('%s: %d개 매퍼 생성(maria → postgres)' % (product, made))
    print('  수동 확인 대상 %d개 파일:' % len(manual_files))
    for f, h in manual_files:
        print('    %-56s %s' % (f, ', '.join('%s=%d' % kv for kv in sorted(h.items()))))
    print('  합계:', ', '.join('%s=%d' % kv for kv in sorted(totals.items())))
