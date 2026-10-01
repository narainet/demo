# -*- coding: utf-8 -*-
"""Oracle 클린설치 DDL(newdb/) 파싱 — 테이블/컬럼/PK/코멘트/FK/인덱스 메타 추출."""
import io, os, re
from collections import OrderedDict

# 인계 패키지 루트 = 이 스크립트의 …/tools/dbdoc 에서 두 단계 위.
# 다른 위치에서 돌릴 때는 환경변수 RLMS_PACKAGE_ROOT 로 지정한다.
RESULT = os.environ.get(
    "RLMS_PACKAGE_ROOT",
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

DDL_FILES = ["10_tables.sql", "15_law_install.sql"]
CMT_FILES = ["12_comments.sql", "15_law_install.sql"]

SKIP_KW = ("CONSTRAINT", "PRIMARY", "UNIQUE", "CHECK", "FOREIGN", "USING", "ENABLE", "SUPPLEMENTAL")


def read(p):
    if not os.path.exists(p):
        return ""
    with io.open(p, encoding="utf-8-sig", errors="replace") as f:
        return f.read().replace("\r\n", "\n")


def strip_comments(sql):
    """-- 줄주석 제거(문자열 리터럴 밖에서만)."""
    out, i, n = [], 0, len(sql)
    inq = False
    while i < n:
        c = sql[i]
        if inq:
            out.append(c)
            if c == "'":
                inq = False
            i += 1
        elif c == "'":
            inq = True; out.append(c); i += 1
        elif c == "-" and i + 1 < n and sql[i + 1] == "-":
            j = sql.find("\n", i)
            i = n if j < 0 else j
        else:
            out.append(c); i += 1
    return "".join(out)


def split_top(body):
    """최상위 콤마로 분리(괄호 depth 0)."""
    parts, depth, cur = [], 0, []
    for ch in body:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(cur)); cur = []
        else:
            cur.append(ch)
    if "".join(cur).strip():
        parts.append("".join(cur))
    return parts


CT_RE = re.compile(r'CREATE\s+TABLE\s+"?([A-Z][A-Z0-9_$#]*)"?\s*\(', re.I)


def parse_tables(sql):
    sql = strip_comments(sql)
    tables = OrderedDict()
    for m in CT_RE.finditer(sql):
        name = m.group(1).upper()
        i = m.end() - 1          # '(' 위치
        depth, j = 0, i
        while j < len(sql):
            if sql[j] == "(":
                depth += 1
            elif sql[j] == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        body = sql[i + 1:j]
        cols, pk = [], []
        for part in split_top(body):
            t = part.strip()
            if not t:
                continue
            head = t.split()[0].strip('"').upper()
            if head in SKIP_KW:
                pm = re.search(r'PRIMARY\s+KEY\s*\(([^)]*)\)', t, re.I)
                if pm:
                    pk = [c.strip().strip('"').upper() for c in pm.group(1).split(",")]
                continue
            cm = re.match(r'"?([A-Z][A-Z0-9_$#]*)"?\s+(.+)$', t, re.S | re.I)
            if not cm:
                continue
            cname = cm.group(1).upper()
            rest = " ".join(cm.group(2).split())
            tm = re.match(r'([A-Z0-9_]+(?:\s*\([^)]*\))?)', rest, re.I)
            ctype = re.sub(r'\s+', '', tm.group(1)).upper() if tm else "?"
            notnull = bool(re.search(r'\bNOT\s+NULL\b', rest, re.I))
            dm = re.search(r'\bDEFAULT\s+(.+?)(?:\s+NOT\s+NULL|\s+ENABLE|$)', rest, re.I)
            default = dm.group(1).strip() if dm else ""
            if re.search(r'\bPRIMARY\s+KEY\b', rest, re.I):
                pk = [cname]
            cols.append({"name": cname, "type": ctype, "notnull": notnull, "default": default})
        tables[name] = {"cols": cols, "pk": pk}
    return tables


TC_RE = re.compile(r"COMMENT\s+ON\s+TABLE\s+\"?([A-Z0-9_$#]+)\"?\s+IS\s+'((?:[^']|'')*)'", re.I)
CC_RE = re.compile(r"COMMENT\s+ON\s+COLUMN\s+\"?([A-Z0-9_$#]+)\"?\.\"?([A-Z0-9_$#]+)\"?\s+IS\s+'((?:[^']|'')*)'", re.I)


def parse_comments(sql):
    tcm, ccm = {}, {}
    for m in TC_RE.finditer(sql):
        tcm[m.group(1).upper()] = m.group(2).replace("''", "'").strip()
    for m in CC_RE.finditer(sql):
        ccm[(m.group(1).upper(), m.group(2).upper())] = m.group(3).replace("''", "'").strip()
    return tcm, ccm


FK_RE = re.compile(
    r'ALTER\s+TABLE\s+"?([A-Z0-9_$#]+)"?\s+ADD\s+CONSTRAINT\s+"?([A-Z0-9_$#]+)"?\s+'
    r'FOREIGN\s+KEY\s*\(([^)]*)\)\s*REFERENCES\s+"?([A-Z0-9_$#]+)"?\s*\(([^)]*)\)([^;]*)', re.I)


def parse_fks(sql):
    out = []
    for m in FK_RE.finditer(strip_comments(sql)):
        out.append({
            "table": m.group(1).upper(), "name": m.group(2).upper(),
            "cols": [c.strip().strip('"').upper() for c in m.group(3).split(",")],
            "ref": m.group(4).upper(),
            "refcols": [c.strip().strip('"').upper() for c in m.group(5).split(",")],
            "cascade": "CASCADE" in m.group(6).upper(),
        })
    return out


IX_RE = re.compile(r'CREATE\s+(UNIQUE\s+)?INDEX\s+"?([A-Z0-9_$#]+)"?\s+ON\s+"?([A-Z0-9_$#]+)"?\s*\(([^)]*)\)', re.I)


def parse_indexes(sql):
    out = []
    for m in IX_RE.finditer(strip_comments(sql)):
        out.append({"uniq": bool(m.group(1)), "name": m.group(2).upper(),
                    "table": m.group(3).upper(),
                    "cols": [c.strip().strip('"').upper() for c in m.group(4).split(",")]})
    return out


def load(product):
    d = os.path.join(RESULT, product, "database", "newdb")
    tables = OrderedDict()
    for f in DDL_FILES:
        tables.update(parse_tables(read(os.path.join(d, f))))
    tcm, ccm = {}, {}
    for f in CMT_FILES:
        a, b = parse_comments(read(os.path.join(d, f)))
        tcm.update(a); ccm.update(b)
    fks = []
    for f in ["30_fks.sql"]:
        fks += parse_fks(read(os.path.join(d, f)))
    idx = []
    for f in ["11_indexes.sql", "15_law_install.sql"]:
        idx += parse_indexes(read(os.path.join(d, f)))
    return {"tables": tables, "tcm": tcm, "ccm": ccm, "fks": fks, "idx": idx}


if __name__ == "__main__":
    for p in ("RLMS", "RegNex", "LexPortal"):
        M = load(p)
        nocol = [t for t, v in M["tables"].items() if not v["cols"]]
        nopk = [t for t, v in M["tables"].items() if not v["pk"]]
        nocmt = [t for t in M["tables"] if t not in M["tcm"]]
        print("%-10s tables=%-3d cols=%-5d fks=%-3d idx=%-3d | 컬럼0=%s PK없음=%s 코멘트없음=%s"
              % (p, len(M["tables"]), sum(len(v["cols"]) for v in M["tables"].values()),
                 len(M["fks"]), len(M["idx"]), nocol or "-", nopk or "-", nocmt or "-"))
