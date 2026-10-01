# -*- coding: utf-8 -*-
"""newdb 시드 자기완결성 검증.

송무(law)·데모 행을 빼면서 참조가 끊겼는지 확인한다.
시드 파일만 읽고 판단한다(설치 시 DB 에 존재할 집합 = 시드 그 자체이므로).
"""
import io, os, re, sys
import os as _os
# 워크스페이스 루트. 다른 경로에 설치했으면 환경변수 RLMS_WS 로 지정한다.
_WS = _os.environ.get("RLMS_WS", "C:/eGovFrameDev-4.3.1-64bit/workspace")

N = _WS + "/RLMS/database/newdb"

def split_values(s):
    """VALUES(...) 안을 최상위 콤마로 분리. 작은따옴표 문자열('' 이스케이프) 인식."""
    out, cur, i, q, depth = [], [], 0, False, 0
    while i < len(s):
        c = s[i]
        if q:
            if c == "'":
                if i + 1 < len(s) and s[i+1] == "'":
                    cur.append("''"); i += 2; continue
                q = False; cur.append(c)
            else:
                cur.append(c)
        else:
            if c == "'":
                q = True; cur.append(c)
            elif c == "(":
                depth += 1; cur.append(c)
            elif c == ")":
                depth -= 1; cur.append(c)
            elif c == "," and depth == 0:
                out.append("".join(cur).strip()); cur = []
            else:
                cur.append(c)
        i += 1
    out.append("".join(cur).strip())
    return out

def unq(v):
    v = v.strip()
    if v == "NULL": return None
    if v.startswith("'") and v.endswith("'"):
        return v[1:-1].replace("''", "'")
    return v

def load():
    """{TABLE: [ {col: val}, ... ]}"""
    data = {}
    pat = re.compile(r"INSERT INTO (\w+)\s*\(([^)]*)\)\s*VALUES\s*\((.*?)\);", re.S)
    for f in sorted(os.listdir(N)):
        if not re.match(r"\d\d_seed", f): continue
        txt = io.open(os.path.join(N, f), encoding="utf-8").read()
        for m in pat.finditer(txt):
            t = m.group(1).upper()
            cols = [c.strip().upper() for c in m.group(2).split(",")]
            vals = split_values(m.group(3))
            if len(cols) != len(vals):
                print(f"  !! 파싱 불일치 {f} {t}: cols={len(cols)} vals={len(vals)}")
                continue
            data.setdefault(t, []).append(dict(zip(cols, [unq(v) for v in vals])))
    return data

d = load()
print("[로드]", ", ".join(f"{k}={len(v)}" for k, v in sorted(d.items())))
print()

fails = []
def check(name, ok, detail=""):
    print(("  OK  " if ok else "  FAIL") + "  " + name + (("  -> " + detail) if detail and not ok else ""))
    if not ok: fails.append(name)

menus  = {r["MENU_NO"] for r in d.get("COMTNMENUINFO", [])}
progs  = {r["PROGRM_FILE_NM"] for r in d.get("COMTNPROGRMLIST", [])}
auths  = {r["AUTHOR_CODE"] for r in d.get("COMTNAUTHORINFO", [])}
roles  = {r["ROLE_CODE"] for r in d.get("COMTNROLEINFO", [])}
orgs   = {r["ORGNZT_ID"] for r in d.get("COMTNORGNZTINFO", [])}
tmplat = {r["TMPLAT_ID"] for r in d.get("COMTNTMPLATINFO", [])}
bbs    = {r["BBS_ID"] for r in d.get("COMTNBBSMASTER", [])}
esntl  = {r["ESNTL_ID"] for r in d.get("COMTNEMPLYRINFO", [])} | \
         {r["ESNTL_ID"] for r in d.get("COMTNGNRLMBER", [])}

# 1. 메뉴 -> 프로그램
bad = [r["MENU_NO"] for r in d.get("COMTNMENUINFO", [])
       if r["PROGRM_FILE_NM"] not in ("folder", None) and r["PROGRM_FILE_NM"] not in progs]
check("메뉴가 참조하는 프로그램이 시드에 존재", not bad, f"고아 메뉴 {bad}")

# 2. 메뉴 트리(상위 메뉴 존재)
bad = [r["MENU_NO"] for r in d.get("COMTNMENUINFO", [])
       if r["UPPER_MENU_NO"] not in (None,) and r["UPPER_MENU_NO"] not in menus]
check("메뉴 트리 상위 노드가 시드에 존재", not bad, f"부모 없는 메뉴 {bad}")

# 3. 메뉴별권한 -> 메뉴 / 권한코드
bad = [r["MENU_NO"] for r in d.get("COMTNMENUCREATDTLS", []) if r["MENU_NO"] not in menus]
check("메뉴별권한의 MENU_NO 가 시드에 존재", not bad, f"{sorted(set(bad))[:10]}")
bad = [r["AUTHOR_CODE"] for r in d.get("COMTNMENUCREATDTLS", []) if r["AUTHOR_CODE"] not in auths]
check("메뉴별권한의 AUTHOR_CODE 가 시드에 존재", not bad, f"{sorted(set(bad))}")

# 4. 권한-롤 매핑
bad = [r["ROLE_CODE"] for r in d.get("COMTNAUTHORROLERELATE", []) if r["ROLE_CODE"] not in roles]
check("권한-롤 매핑의 ROLE_CODE 가 시드에 존재", not bad, f"{sorted(set(bad))}")
bad = [r["AUTHOR_CODE"] for r in d.get("COMTNAUTHORROLERELATE", []) if r["AUTHOR_CODE"] not in auths]
check("권한-롤 매핑의 AUTHOR_CODE 가 시드에 존재", not bad, f"{sorted(set(bad))}")

# 5. 롤 계층
bad = [f'{r["PARNTS_ROLE"]}>{r["CHLDRN_ROLE"]}' for r in d.get("COMTNROLES_HIERARCHY", [])
       if r["PARNTS_ROLE"] not in auths or r["CHLDRN_ROLE"] not in auths]
check("롤 계층의 양쪽 권한코드가 시드에 존재", not bad, f"{bad}")

# 6. 프로그램 URL 의 bbsId 가 게시판 시드에 존재
bad = []
for r in d.get("COMTNPROGRMLIST", []):
    u = r.get("URL") or ""
    m = re.search(r"bbsId=([A-Za-z0-9_]+)", u)
    if m and m.group(1) not in bbs: bad.append((r["PROGRM_FILE_NM"], m.group(1)))
check("프로그램 URL 이 가리키는 게시판이 시드에 존재", not bad, f"{bad}")

# 7. 게시판 -> 템플릿
bad = [r["BBS_ID"] for r in d.get("COMTNBBSMASTER", []) if r.get("TMPLAT_ID") and r["TMPLAT_ID"] not in tmplat]
check("게시판이 참조하는 템플릿이 시드에 존재", not bad, f"{bad}")

# 8. 사용자 -> 부서
bad = [r["EMPLYR_ID"] for r in d.get("COMTNEMPLYRINFO", []) if r.get("ORGNZT_ID") and r["ORGNZT_ID"] not in orgs]
check("사용자의 소속 부서가 시드에 존재", not bad, f"{bad}")

# 9. 부서 트리
bad = [r["ORGNZT_ID"] for r in d.get("COMTNORGNZTINFO", [])
       if r.get("UPPER_ORGNZT_ID") and r["UPPER_ORGNZT_ID"] not in orgs]
check("부서 트리 상위 노드가 시드에 존재", not bad, f"{bad}")

# 10. 보안설정 -> 계정 ESNTL_ID / 권한코드
bad = [r["SCRTY_DTRMN_TRGET_ID"] for r in d.get("COMTNEMPLYRSCRTYESTBS", [])
       if r["SCRTY_DTRMN_TRGET_ID"] not in esntl]
check("보안설정 대상이 시드 계정의 ESNTL_ID 와 일치", not bad, f"{bad}")
bad = [r["AUTHOR_CODE"] for r in d.get("COMTNEMPLYRSCRTYESTBS", []) if r["AUTHOR_CODE"] not in auths]
check("보안설정의 AUTHOR_CODE 가 시드에 존재", not bad, f"{sorted(set(bad))}")

# 11. 송무(law) 포함 확인 — RLMS 는 통합본이라 송무가 코어다
lawp = [r["PROGRM_FILE_NM"] for r in d.get("COMTNPROGRMLIST", [])
        if r["PROGRM_FILE_NM"].startswith("LAW_") or (r.get("URL") or "").startswith("/law/")]
check("송무 프로그램 포함(21)", len(lawp) == 21, f"{len(lawp)}건")
lawm = [r["MENU_NO"] for r in d.get("COMTNMENUINFO", [])
        if 55000000 <= int(r["MENU_NO"]) <= 55999999 or 15000000 <= int(r["MENU_NO"]) <= 15999999]
check("송무 메뉴 포함(26)", len(lawm) == 26, f"{len(lawm)}건")
check("ROLE_LAW_MGR 포함", "ROLE_LAW_MGR" in auths)
lawseq = [r["TABLE_NAME"] for r in d.get("COMTECOPSEQ", []) if r["TABLE_NAME"].startswith("LAW_")]
check("송무 채번키 포함(17)", len(lawseq) == 17, f"{len(lawseq)}건")
check("송무 기준데이터 포함(법원 22·요율 41)",
      len(d.get("LAW_COURT", [])) == 22 and len(d.get("LAW_CALC_RATE", [])) == 41,
      f'court={len(d.get("LAW_COURT", []))} rate={len(d.get("LAW_CALC_RATE", []))}')

# 11-b. 데모 게시판 잔재 없음(공지사항 1보드만)
check("게시판은 공지사항 1보드만", len(d.get("COMTNBBSMASTER", [])) == 1,
      f'{[r["BBS_ID"] for r in d.get("COMTNBBSMASTER", [])]}')

# 11-c. ⛔시드가 ID 를 선점한 테이블은 채번 시작점이 그 위여야 한다(첫 등록 PK 충돌 방지)
seq = {r["TABLE_NAME"]: int(r["NEXT_ID"]) for r in d.get("COMTECOPSEQ", [])}
for key, table, col in (("LAW_COURT_ID", "LAW_COURT", "COURT_ID"),
                        ("LAW_CALC_RATE_ID", "LAW_CALC_RATE", "RATE_ID")):
    mx = max((int(r[col]) for r in d.get(table, [])), default=0)
    check(f"채번 {key} 가 시드 최대 ID({mx}) 초과", seq.get(key, 0) > mx, f"NEXT_ID={seq.get(key)}")

# 12. 채번 초기값
EXEMPT = {"LAW_COURT_ID", "LAW_CALC_RATE_ID"}   # 시드가 ID 선점 → 위 11-c 가 따로 검증
bad = [r["TABLE_NAME"] for r in d.get("COMTECOPSEQ", []) if r["NEXT_ID"] != "1" and r["TABLE_NAME"] not in EXEMPT]
check("채번 NEXT_ID 가 전부 1(선점 2키 제외)", not bad, f"{bad[:10]}")

print()
print("결과:", "전부 통과" if not fails else f"실패 {len(fails)}건 -> {fails}")
sys.exit(1 if fails else 0)
