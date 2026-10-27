# ZScript is case-insensitive: a field and a method that differ only in capitals collide.
# Run: python check_names.py   (from CorpoWars_tools)
import re, glob, os
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CorpoWars", "zscript")
names = {}
for f in glob.glob(os.path.join(root, "**", "*.zs"), recursive=True):
    if os.sep + "archive" + os.sep in f: continue
    cls = None
    for ln in open(f, encoding="latin1"):
        m = re.match(r'(?:extend |mixin )?class (\w+)', ln)
        if m: cls = m.group(1); continue
        if not cls: continue
        m = re.match(r'\t(?:clearscope |static |ui |virtual |override |action |play )*[\w<>]+\s+(\w+)\s*\(', ln)
        if m: names.setdefault((cls, m.group(1).lower()), set()).add(("method", m.group(1)))
        m = re.match(r'\t(?:ui |const )?(?:bool|int|double|String|Actor|Vector3|Vector2|Color|SpotLight|CW_\w+|Array<\w+>)\s+([\w, \[\]]+?)\s*(?:=.*)?;', ln)
        if m:
            for n in m.group(1).split(','):
                n = re.sub(r'\[.*', '', n).strip()
                if n: names.setdefault((cls, n.lower()), set()).add(("field", n))
# constants vs local variables / parameters in the same class (e.g. const C vs Vector2 c)
for f in glob.glob(os.path.join(root, "**", "*.zs"), recursive=True):
    if os.sep + "archive" + os.sep in f: continue
    cls = None
    for ln in open(f, encoding="latin1"):
        m = re.match(r'(?:extend |mixin )?class (\w+)', ln)
        if m: cls = m.group(1); continue
        if not cls: continue
        m = re.match(r'\tconst (\w+)\s*=', ln)
        if m: names.setdefault((cls, m.group(1).lower()), set()).add(("const", m.group(1)))
        for m in re.finditer(r'\b(?:int|double|bool|Vector2|Vector3|String|let)\s+(\w+)\s*(?:=|;|,|\))', ln):
            if ln.startswith("\t\t") or "(" in ln.split(m.group(0))[0]:
                names.setdefault((cls, m.group(1).lower()), set()).add(("local", m.group(1)))
bad = [(k, sorted(v)) for k, v in names.items() if len({t for t, _ in v}) > 1 and not {t for t, _ in v} <= {"local", "field"} or ({"field", "method"} <= {t for t, _ in v})]
bad = [(k, v) for k, v in bad if len({t for t, _ in v}) > 1]
for (cls, _), v in bad: print(f"CLASH in {cls}: " + ", ".join(f"{t} {n}" for t, n in v))
print("OK - no field/method name clashes" if not bad else f"{len(bad)} clash(es)")

# locals in the same function that differ only by case (e.g. int T and loop var t)
fn_bad = 0
for f in glob.glob(os.path.join(root, "**", "*.zs"), recursive=True):
    if os.sep + "archive" + os.sep in f: continue
    text = open(f, encoding="latin1").read()
    for fm in re.finditer(r'\n\t(?:[\w<>]+ )+(\w+)\s*\([^)]*\)\s*\n\t\{(.*?)\n\t\}', text, re.S):
        seen = {}
        for m in re.finditer(r'\b(?:int|double|bool|Vector2|Vector3|String|let)\s+(\w+)', fm.group(2)):
            n = m.group(1); seen.setdefault(n.lower(), set()).add(n)
        for low, forms in seen.items():
            if len(forms) > 1:
                fn_bad += 1
                print(f"CLASH in {os.path.basename(f)} {fm.group(1)}(): locals " + ", ".join(sorted(forms)))
print("OK - no local-variable case clashes" if not fn_bad else f"{fn_bad} local clash(es)")
