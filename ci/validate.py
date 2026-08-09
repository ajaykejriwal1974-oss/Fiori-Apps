#!/usr/bin/env python3
"""Repo validator for the KEJRIWAL Fiori package — run in CI and locally.

Validates, with zero external dependencies (Python stdlib only):
  - JSON   : every *.json / *.change / manifest.appdescr_variant parses
  - XML    : every *.xml is well-formed
  - CDS/RAP: balanced braces & parens; no hyphen in object names; every
             service-exposed projection / projection target / behavior class /
             action param entity / composition & redirect target resolves;
             object names are globally unique
  - ABAP   : balanced CLASS/ENDCLASS and METHOD/ENDMETHOD
  - Apps   : manifest id ↔ rootView / i18n / Component / controller namespaces

Exit code 0 = all good, 1 = at least one failure (details printed).
Note: this is *structural* validation. Full semantic ABAP/CDS checks (ATC,
activation) require an S/4HANA backend and are out of scope for CI.
"""
import json, os, re, sys, glob
import xml.dom.minidom as minidom

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
errors = []
def err(msg): errors.append(msg)

def rel(p): return os.path.relpath(p, ROOT)

# ---------------------------------------------------------------- collect files
def files(*exts, under="."):
    out = []
    for ext in exts:
        out += glob.glob(os.path.join(ROOT, under, "**", ext), recursive=True)
    return sorted(out)

backend_cds = files("*.asddls", "*.asbdef", "*.ddlx.asddlxs", "*.srvdsrv", under="backend")
abap        = files("*.clas.abap", under="backend")
json_files  = files("*.json", "*.change", "*.appdescr_variant", under="apps") + files("*.json", under="backend")
xml_files   = files("*.xml", under="apps")

# ------------------------------------------------------------------ 1. JSON
for f in json_files:
    try:
        json.load(open(f))
    except Exception as e:
        err(f"JSON parse error: {rel(f)}: {e}")

# ------------------------------------------------------------------- 2. XML
for f in xml_files:
    try:
        minidom.parse(f)
    except Exception as e:
        err(f"XML not well-formed: {rel(f)}: {e}")

# --------------------------------------------------- 3. CDS/RAP structure + index
defined_views, defined_abstract, defined_behaviors = {}, {}, {}
defined_services, exposed, projections, beh_classes = {}, [], [], []
action_entities, comp_redirect_targets = [], []
name_defs = {}   # object name -> list of files (uniqueness)

def note_name(name, f): name_defs.setdefault(name, []).append(rel(f))

for f in backend_cds:
    txt = open(f).read()
    # balanced braces / parens
    if txt.count("{") != txt.count("}"):
        err(f"Unbalanced braces in {rel(f)} ({txt.count('{')} '{{' vs {txt.count('}')} '}}')")
    if txt.count("(") != txt.count(")"):
        err(f"Unbalanced parens in {rel(f)}")
    for m in re.finditer(r'define (?:root )?view entity (Z[A-Za-z_0-9]+)', txt):
        defined_views[m.group(1)] = f; note_name(m.group(1), f)
    for m in re.finditer(r'define abstract entity (Z[A-Za-z_0-9]+)', txt):
        defined_abstract[m.group(1)] = f; note_name(m.group(1), f)
    for m in re.finditer(r'define behavior for (Z[A-Za-z_0-9]+)', txt):
        defined_behaviors.setdefault(m.group(1), f)
    for m in re.finditer(r'define service (Z[A-Za-z_0-9]+)', txt):
        defined_services[m.group(1)] = f; note_name(m.group(1), f)
    exposed   += [(m.group(1), f) for m in re.finditer(r'expose (Z[A-Za-z_0-9]+)', txt)]
    projections += [(m.group(1), f) for m in re.finditer(r'as projection on (Z[A-Za-z_0-9]+)', txt)]
    beh_classes += [(m.group(1), f) for m in re.finditer(r'implementation in class (z[a-z_0-9]+)', txt)]
    action_entities += [(m.group(1), f) for m in re.finditer(r'(?:parameter|result \[\d+\]) (ZD_[A-Za-z_0-9]+)', txt)]
    comp_redirect_targets += [(m.group(1), f) for m in
        re.finditer(r'(?:composition \[[^\]]*\] of|redirected to (?:parent |composition child )?)(Z[A-Za-z_0-9]+)', txt)]

# no hyphen in any defined object name (invalid ABAP identifier)
for name in list(defined_views) + list(defined_abstract) + list(defined_services):
    if "-" in name:
        err(f"Hyphen in object name (invalid ABAP): {name}")

# service-exposed projections exist as views
for ent, f in exposed:
    if ent not in defined_views:
        err(f"Service exposes undefined view {ent} ({rel(f)})")
# projection targets exist
for ent, f in projections:
    if ent not in defined_views:
        err(f"Projection target {ent} not defined ({rel(f)})")
# behavior implementation classes have a source file
for cls, f in beh_classes:
    if not os.path.exists(os.path.join(os.path.dirname(f), f"{cls}.clas.abap")):
        err(f"Behavior class file {cls}.clas.abap missing (for {rel(f)})")
# action param/result entities exist
for ent, f in action_entities:
    if ent not in defined_abstract:
        err(f"Action entity {ent} not defined ({rel(f)})")
# composition / redirect targets exist (view or abstract)
for ent, f in comp_redirect_targets:
    if ent not in defined_views and ent not in defined_abstract:
        err(f"Composition/redirect target {ent} not defined ({rel(f)})")
# global object-name uniqueness
for name, locs in name_defs.items():
    if len(locs) > 1:
        err(f"Duplicate object name {name} defined in: {', '.join(locs)}")

# ------------------------------------------------------------------ 4. ABAP
for f in abap:
    txt = open(f).read()
    nc = len(re.findall(r'(?<!END)\bCLASS\b', txt, re.I)) - len(re.findall(r'\bENDCLASS\b', txt, re.I))
    # CLASS appears twice per class (DEFINITION + IMPLEMENTATION); just check ENDCLASS matches CLASS count
    c_open  = len(re.findall(r'^\s*CLASS\s', txt, re.I | re.M))
    c_close = len(re.findall(r'^\s*ENDCLASS', txt, re.I | re.M))
    if c_open != c_close:
        err(f"ABAP CLASS/ENDCLASS mismatch in {rel(f)} ({c_open} vs {c_close})")
    m_open  = len(re.findall(r'^\s*METHOD\s', txt, re.I | re.M))
    m_close = len(re.findall(r'^\s*ENDMETHOD', txt, re.I | re.M))
    if m_open != m_close:
        err(f"ABAP METHOD/ENDMETHOD mismatch in {rel(f)} ({m_open} vs {m_close})")

# ----------------------------------------------------------- 5. app manifests
for m in glob.glob(os.path.join(ROOT, "apps", "*", "webapp", "manifest.json")):
    app = rel(m).split(os.sep)[1]
    try:
        j = json.load(open(m))
    except Exception:
        continue  # already reported
    appid = j.get("sap.app", {}).get("id", "")
    rv = j.get("sap.ui5", {}).get("rootView", {}).get("viewName", "")
    if rv and not rv.startswith(appid + "."):
        err(f"{app}: rootView '{rv}' not under app id '{appid}'")
    bn = j.get("sap.ui5", {}).get("models", {}).get("i18n", {}).get("settings", {}).get("bundleName", "")
    if bn and not bn.startswith(appid + "."):
        err(f"{app}: i18n bundle '{bn}' not under app id '{appid}'")
    cj = os.path.join(ROOT, "apps", app, "webapp", "Component.js")
    if os.path.exists(cj):
        cm = re.search(r'UIComponent\.extend\("([^"]+)\.Component"', open(cj).read())
        if cm and cm.group(1) != appid:
            err(f"{app}: Component id '{cm.group(1)}' != app id '{appid}'")
    vw = os.path.join(ROOT, "apps", app, "webapp", "view", "Worklist.view.xml")
    if os.path.exists(vw):
        cm = re.search(r'controllerName="([^"]+)"', open(vw).read())
        if cm and not cm.group(1).startswith(appid + "."):
            err(f"{app}: view controller '{cm.group(1)}' not under app id '{appid}'")

# -------------------------------------------------------------------- report
counts = (f"{len(json_files)} JSON, {len(xml_files)} XML, {len(backend_cds)} CDS/RAP, "
          f"{len(abap)} ABAP files")
if errors:
    print(f"❌ Validation FAILED ({len(errors)} issue(s)) — checked {counts}\n")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
print(f"✅ Validation passed — checked {counts}.")
