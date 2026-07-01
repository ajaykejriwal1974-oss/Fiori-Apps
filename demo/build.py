#!/usr/bin/env python3
"""Assemble a static, hostable demo Launchpad for the freestyle Fiori apps.

For each custom app this script produces a self-contained folder that runs the
real app code against realistic **mock JSON data** and a **same-origin** OpenUI5
runtime (no external CDN — required for iOS Safari). The output is a flat site:

    <dest>/
      resources/            shared OpenUI5 runtime (one copy for all apps)
      index.html            portal: tile grid linking to every app
      <app>/                copied webapp + demo index.html + mock/data.json
      ...

Three app shapes are handled:
  * "default-model" apps  -> the table binds the default ("") model. We swap that
                             model in manifest.json from the OData dataSource to a
                             JSONModel over mock/data.json.
  * "ui-model" apps       -> the screen builds its data interactively in a named
                             "ui" JSONModel (onInit seeds it empty). We replace
                             that empty seed with realistic rows so the demo shows
                             content on load.
  * "self-contained" apps -> already ship a named JSONModel over a bundled
                             model/data.json (e.g. the Maintenance PM app), so we
                             only copy the webapp + write the demo index.html.

Usage:
    python3 demo/build.py --resources /path/to/openui5/resources --dest dist
    python3 demo/build.py --resources <res> --dest <dest> --link   # symlink runtime (local)
"""

import argparse
import json
import os
import re
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APPS_DIR = os.path.join(ROOT, "apps")
MOCK_DIR = os.path.join(ROOT, "demo", "mock")

# Apps whose data lives entirely in a named "ui" JSONModel seeded in the
# controller onInit (no default-model table). For these we inject the seed.
UI_MODEL_APPS = {
    "contract-batch-update": "controller/Main.controller.js",
    "dyeing-packing":        "controller/Main.controller.js",
    "post-goods-movement-hu": "controller/Main.controller.js",
}

# SAP module groups, in display order. The whole portfolio is arranged by these
# — every app (custom / extended / standard / master / analytics) sits under its
# module, distinguished by tile colour + type badge (see the legend).
MODULES = [
    ("PP", "Production (PP)"),
    ("SD", "Sales &amp; Distribution (SD)"),
    ("MM", "Materials &amp; Inventory (MM)"),
    ("QM", "Quality (QM)"),
    ("FI", "Finance (FI)"),
    ("PM", "Maintenance (PM)"),
    ("WF", "Workflow &amp; Approvals"),
]

# Custom freestyle apps (runnable in the demo). (app folder, module)
APPS = [
    ("batch-status",                  "PP"),
    ("dyeing-packing",                "PP"),
    ("manage-packing-details",        "PP"),
    ("post-packing-gr",               "PP"),
    ("palletization",                 "PP"),
    ("mtos-process",                  "PP"),
    ("contract-batch-update",         "SD"),
    ("dispatch-correction",           "SD"),
    ("hu-unpack",                     "MM"),
    ("inbound-delivery-hus",          "MM"),
    ("post-goods-movement-hu",        "MM"),
    ("record-inspection-results-mass","QM"),
    ("maintenance",                   "PM"),
]

# Self-contained apps that already ship their own JSON data (a named model over a
# bundled model/data.json) — no mock swap/seed needed, just copy + demo index.html.
SELF_CONTAINED = {"maintenance"}

# Adaptation projects (*-ext): these layer custom fields / sections / logic onto
# a STANDARD delivered Fiori app, so they have no standalone webapp that renders
# in this mock demo. They appear as non-clickable info tiles for completeness.
ADAPTATION = [
    # folder                            module title                    fiori  replaces (Z)
    ("manage-sales-orders-ext",         "SD", "Manage Sales Orders",         "F1873",  "ZVA01 / ZVA01N, ZSOCLOSE"),
    ("manage-sales-contracts-ext",      "SD", "Manage Sales Contracts",      "VA42",   "ZCON_CLOSE/1, ZCOREL, ZCON02"),
    ("manage-outbound-deliveries-ext",  "SD", "Manage Outbound Deliveries",  "F0867A", "ZDEL"),
    ("confirm-production-operation-ext","PP", "Confirm Production Operation","F3069",  "ZCO11N / ZCO11A"),
]

# Standard delivered S/4HANA 2025 Fiori apps adopted as-is (the STD / Table A
# portfolio) — no development, assigned via business role. Reference tiles only;
# they run on the S/4HANA FES, not in this mock demo.
# (module, title, fiori, classic tx, business role, replaces Z)
STANDARD = [
    ("PP", "Manage Batches",                   "F2462",  "MSC3N",        "SAP_BR_WAREHOUSE_CLERK",   "ZBATCH01/02/03(N)"),
    ("MM", "Compare Supplier Quotations",       "F2324",  "ME49",         "SAP_BR_PURCHASER",         "ZME49"),
    ("MM", "Manage Material Master",            "F1602",  "MM60",         "SAP_BR_BUYER",             "ZMM60"),
    ("FI", "Display Line Items in G/L",         "F0706",  "FAGLL03",      "SAP_BR_GL_ACCOUNTANT",     "ZFBL3N / ZZFBL3N"),
    ("FI", "Manage Customer Line Items",        "F0711",  "FBL5N",        "SAP_BR_AR_ACCOUNTANT",     "ZFBL5N / ZZFBL5N"),
    ("FI", "Manage Journal Entries",            "F0717A", "FB03",         "SAP_BR_GL_ACCOUNTANT",     "ZFB03"),
    ("FI", "Manage Credit Memo Requests",       "F0696",  "VA01 (G2/L2)", "SAP_BR_BILLING_CLERK",     "ZCRDRNOTE"),
    ("FI", "Post Asset Acquisition",            "ABZON",  "F-90",         "SAP_BR_AA_ACCOUNTANT",     "ZF90"),
    ("FI", "Reprocess Bank Statement Items",    "F1681",  "FF67",         "SAP_BR_CASH_SPECIALIST",   "ZFF67"),
    # Credit release IS Manage Documented Credit Decisions in S/4HANA FSCM
    # Credit Mgmt (F5587A) — check / release / reject credit-blocked SD docs.
    ("FI", "Manage Documented Credit Decisions","F5587A", "FSCM-CR (DCD)", "SAP_BR_CREDIT_CONTROLLER", "ZCM_RELEASE — check / release / reject credit-blocked SD docs"),
    # Release / approval apps — delivered standard in S/4HANA 2025 (via Flexible
    # Workflow -> approve in My Inbox). F-numbers verified in the Fiori Apps
    # Reference Library. Adopt as-is, assign the role.
    ("MM", "Release Purchase Orders",           "F2872",  "ME29N",          "SAP_BR_PURCHASING_MANAGER", "Flexible Workflow (config F2872) → approve in My Inbox (F0862)"),
    ("SD", "Release Sales Contracts",           "VA42",   "Flexible Workflow", "SAP_BR_INTERNAL_SALES_REP", "contract approval — Flexible Workflow → My Inbox (cf. Manage Sales Contracts ext)"),
    ("WF", "My Inbox (All Items)",              "F0862",  "SBWP",           "SAP_BR_EMPLOYEE",           "central inbox for Flexible Workflow approvals — PO, sales contract, credit"),
    # QM master data — delivered standard, adopt as-is (F-numbers verified in the
    # Fiori Apps Reference Library). Pairs with Record Inspection Results.
    ("QM", "Master Inspection Characteristics", "F2219", "QS21/22/23", "SAP_BR_QUALITY_PLANNER", "MIC master (shade/denier via batch class)"),
    ("QM", "Manage Inspection Plans",           "F3788", "QP01/02/03", "SAP_BR_QUALITY_PLANNER", "inspection plan / task-list master"),
    # Maintenance (PM/EAM) — standard S/4HANA 2025 apps that match the custom
    # Maintenance app's tabs (F-numbers verified in the Fiori Apps Reference
    # Library; Manage Technical Objects anchored on classic tx, confirm F-no).
    ("PM", "Manage Maintenance Plans",              "F5325", "IP01/02/03", "SAP_BR_MAINTENANCE_PLANNER",    "Schedule tab — preventive plans + strategy"),
    ("PM", "Mass Schedule Maintenance Plans",       "F2774", "IP30",       "SAP_BR_MAINTENANCE_PLANNER",    "Schedule tab — 'Schedule Now' / deadline monitoring"),
    ("PM", "Report and Repair Malfunction",         "F2023", "IW21 / IW26","SAP_BR_MAINTENANCE_TECHNICIAN", "Breakdown tab — malfunction report + repair"),
    ("PM", "Manage Maintenance Notifications & Orders","F4604","IW28 / IW38","SAP_BR_MAINTENANCE_PLANNER",  "Breakdown tab — notifications + work orders"),
    ("PM", "Breakdown Analysis (EAM KPI)",          "F2812", "MCI3 / MCI8","SAP_BR_MAINTENANCE_PLANNER",    "Breakdown tab — downtime / MTBF / MTTR KPIs"),
    ("PM", "Manage Technical Objects",              "Technical Objects", "IE01-03 / IL01-03 / CR01-02", "SAP_BR_MD_SPECIALIST_EAM", "Machines tab — equipment / func. location / work center"),
]

# Master-data apps: managed RAP business objects whose service binding generates
# a standard Fiori Elements list/object-page app ("Manage ...") on the FES.
# (module, title, custom table, replaces Z)
MASTER_DATA = [
    ("PP", "Shade Master",             "ZDD_SHADE",          "ZDD_SHADE"),
    ("PP", "Recipe Master",            "ZPP_RECEIPE",        "ZRECP01/02/03"),
    ("PP", "Job Master",               "ZPP_JOBN",           "ZJOB01/02/03(N)"),
    ("MM", "Truck Master",             "ZTB_TRUCK_MSTR",     "ZTRUCK"),
    ("PP", "Schedule Master",          "ZPP_SCHEDULEN",      "ZSCH01/02/03(N)"),
    ("SD", "Transport Code",           "ZTRANS",             "ZTRANS"),
    ("PP", "Merge Details",            "ZPP_MERGE",          "ZMERGE"),
    ("PP", "Checked / Packed By",      "ZPP_PCBY",           "ZPCBY"),
    ("PP", "Packing Material Master",  "ZPACK_MAST",         "ZPACK_MAST"),
    ("SD", "Export Details",           "ZEXP",               "ZMBR2"),
    ("FI", "Digital Signature",        "ZTDIGI_SIGN",        "ZDIGI"),
    ("FI", "C-Form Allocation",        "ZCFORM1",            "ZCFORM1/ZFORM/ZFORMS/ZPCFORM"),
    ("SD", "Gate Pass",                "ZGP_HDR / ZGP_ITEM", "ZGPS01-03, ZGPSI1-3"),
]

# Analytical (BI) CDS queries (ZC_*Query over a cube) — consumed in the Query
# Browser / an Analytical List Page on the FES. (module, title, query, replaces)
BI_QUERIES = [
    ("PP", "Packed Stock",       "ZC_PackedStockQuery",      "8 stock reports (ZBOXSTOCK...)"),
    ("PP", "Packing Register",   "ZC_PackingRegisterQuery",  "17 pack-list reports"),
    ("PP", "WIP Batch",          "ZC_WipBatchQuery",         "ZBATCH_WIP"),
    ("MM", "HU Inventory",       "ZC_HuInventoryQuery",      "ZHUINV_CLS"),
    ("MM", "HU Monitor / Reconciliation", "ZC_HuMonitorQuery", "ZHUMO, ZHUREC"),
    ("SD", "Pending Contract",   "ZC_PendingContractQuery",  "ZPCON, ZPCOND, ZPCONS"),
    ("SD", "Export Register",    "ZC_ExportRegisterQuery",   "ZGCUDB, ZBRC/ZEXP"),
    ("PP", "Merge Analysis",     "ZC_MergeAnalysisQuery",    "merge stock reports"),
    ("PP", "Recipe Analysis",    "ZC_RecipeAnalysisQuery",   "ZRECPM"),
    ("PP", "Job Card",           "ZC_JobCardQuery",          "ZJOBREPTN"),
    ("SD", "Dispatch Register",  "ZC_DispatchRegisterQuery", "ZPWDIS (schedule-wise)"),
    ("SD", "Pending / Security Dispatch", "ZC_PendingDispatchQuery", "ZDISPATCH, ZPDESP"),
    ("FI", "GST Tax",            "ZC_GstTaxQuery",           "ZGST, ZGST1, ZGST2, ZGSTCR"),
]


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


def app_meta(app):
    """Return (namespace, settings_id, title, subtitle) read from the source."""
    manifest = json.loads(read(os.path.join(APPS_DIR, app, "webapp", "manifest.json")))
    namespace = manifest["sap.app"]["id"]
    # data-settings id from the original index.html, fallback to last ns segment
    idx = read(os.path.join(APPS_DIR, app, "webapp", "index.html"))
    m = re.search(r'data-settings=\'[^\']*"id"\s*:\s*"([^"]+)"', idx)
    settings_id = m.group(1) if m else namespace.split(".")[-1]
    props = read(os.path.join(APPS_DIR, app, "webapp", "i18n", "i18n.properties"))
    title = re.search(r"^appTitle=(.*)$", props, re.M)
    title = title.group(1).strip() if title else app
    return namespace, settings_id, title


def demo_index_html(namespace, settings_id, title):
    """Self-contained demo index.html: same-origin runtime + full-height chain."""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>{title}</title>
    <!-- Full height chain: #content -> ComponentContainer -> UIArea -> View ->
         Page. If any link is auto-height the Page content collapses (~32px) and
         the tables clip to blank (seen on iOS Safari). -->
    <style>
        html, body, #content {{ height: 100%; margin: 0; }}
        #content > .sapUiComponentContainer,
        [id$="-uiarea"],
        [id$="-uiarea"] > .sapUiView,
        [id$="-uiarea"] > .sapUiView > .sapMPage {{ height: 100%; }}
        .sapMPageScroll, .sapMScrollCont, .sapMListUl, .sapMPageEnableScrolling {{
            -webkit-overflow-scrolling: auto !important;
        }}
        #demoBar {{ font:12px/1.4 -apple-system,Segoe UI,Roboto,sans-serif;
            background:#eaf3fb; color:#0a3d62; padding:4px 10px; border-bottom:1px solid #c7ddef; }}
        #demoBar a {{ color:#0a6ed1; text-decoration:none; }}
    </style>
    <script
        id="sap-ui-bootstrap"
        src="../resources/sap-ui-core.js"
        data-sap-ui-theme="sap_horizon"
        data-sap-ui-resourceroots='{{"{namespace}": "./"}}'
        data-sap-ui-oninit="module:sap/ui/core/ComponentSupport"
        data-sap-ui-compatVersion="edge"
        data-sap-ui-async="true">
    </script>
</head>
<body class="sapUiBody" style="display:flex;flex-direction:column">
    <div id="demoBar">&#9432; Demo &mdash; mock data, no backend. <a href="../index.html">&#8592; All apps</a></div>
    <div
        id="content"
        style="flex:1 1 auto;min-height:0"
        data-sap-ui-component
        data-name="{namespace}"
        data-id="container"
        data-settings='{{"id": "{settings_id}", "height": "100%", "width": "100%"}}'></div>
</body>
</html>
"""


def swap_default_model(dest_app):
    """Point the default ("") model at mock/data.json instead of the OData service."""
    mpath = os.path.join(dest_app, "manifest.json")
    manifest = json.loads(read(mpath))
    models = manifest["sap.ui5"].setdefault("models", {})
    models[""] = {"type": "sap.ui.model.json.JSONModel", "uri": "mock/data.json"}
    write(mpath, json.dumps(manifest, indent=2) + "\n")


def inject_ui_seed(dest_app, controller_rel, seed):
    """Replace the empty `new JSONModel({...}), "ui"` seed in onInit with rows."""
    cpath = os.path.join(dest_app, controller_rel)
    src = read(cpath)
    anchor = src.index("new JSONModel(")
    i = src.index("{", anchor)
    depth = 0
    j = i
    while j < len(src):
        c = src[j]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                break
        j += 1
    seed_js = json.dumps(seed, indent=4)
    seed_js = "\n".join(
        ("            " + ln) if k else ln for k, ln in enumerate(seed_js.splitlines())
    )
    new_src = src[:i] + seed_js + src[j + 1:]
    write(cpath, new_src)


def build_app(app, dest):
    namespace, settings_id, title = app_meta(app)
    src_webapp = os.path.join(APPS_DIR, app, "webapp")
    dest_app = os.path.join(dest, app)
    if os.path.exists(dest_app):
        shutil.rmtree(dest_app)
    shutil.copytree(src_webapp, dest_app)

    # drop per-app PWA artifacts the demo index.html doesn't use (a stray
    # service worker / web manifest would just be dead files on the site)
    for dead in ("sw.js", "manifest.webmanifest"):
        dpath = os.path.join(dest_app, dead)
        if os.path.exists(dpath):
            os.remove(dpath)

    # demo index.html (same-origin bootstrap + height fix)
    write(os.path.join(dest_app, "index.html"),
          demo_index_html(namespace, settings_id, title))

    # self-contained apps already bundle their own JSON data — nothing to inject
    if app in SELF_CONTAINED:
        return title

    seed = json.loads(read(os.path.join(MOCK_DIR, app + ".json")))
    if app in UI_MODEL_APPS:
        inject_ui_seed(dest_app, UI_MODEL_APPS[app], seed)
    else:
        os.makedirs(os.path.join(dest_app, "mock"), exist_ok=True)
        write(os.path.join(dest_app, "mock", "data.json"),
              json.dumps(seed, indent=2) + "\n")
        swap_default_model(dest_app)
    return title


def portal_html(sections_html):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<title>Kejriwal &mdash; Fiori Apps (Demo)</title>
<style>
  body {{ margin:0; font-family:-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
         background:#f5f6f7; color:#32363a; }}
  header {{ background:#0a6ed1; color:#fff; padding:18px 24px; }}
  header h1 {{ margin:0; font-size:20px; font-weight:600; }}
  header p {{ margin:4px 0 0; font-size:13px; opacity:.9; }}
  main {{ padding:16px 24px 48px; max-width:1100px; margin:0 auto; }}
  .note {{ background:#fff7e6; border:1px solid #f0d9a8; border-radius:8px;
          padding:10px 14px; font-size:13px; margin:16px 0; }}
  .grp {{ font-size:14px; text-transform:uppercase; letter-spacing:.05em;
         color:#6a6d70; margin:28px 0 10px; }}
  .grid {{ display:grid; gap:14px; grid-template-columns:repeat(auto-fill,minmax(220px,1fr)); }}
  .tile {{ display:flex; flex-direction:column; justify-content:space-between;
           min-height:110px; background:#fff; border:1px solid #e5e5e5; border-radius:10px;
           padding:14px 16px; text-decoration:none; color:inherit;
           box-shadow:0 1px 2px rgba(0,0,0,.04); transition:box-shadow .15s,transform .15s; }}
  a.tile:hover {{ box-shadow:0 4px 14px rgba(0,0,0,.12); transform:translateY(-1px); }}
  .tile .ico {{ width:38px; height:38px; border-radius:9px; background:#eaf3fb;
               color:#0a6ed1; font-size:16px; font-weight:700; display:flex;
               align-items:center; justify-content:center; }}
  .tile .ttl {{ font-size:15px; font-weight:600; margin-top:10px; }}
  .tile .sub {{ font-size:12px; color:#6a6d70; margin-top:2px; }}
  .tile .badge.cust {{ color:#0a6ed1; background:#e3f0fb; }}
  .legend {{ display:flex; flex-wrap:wrap; gap:8px 18px; font-size:12px;
            color:#4a4d50; margin:12px 0 4px; }}
  .legend span {{ display:inline-flex; align-items:center; gap:6px; }}
  .legend i {{ width:11px; height:11px; border-radius:3px; display:inline-block;
              border:1px solid rgba(0,0,0,.12); }}
  .sw-cust {{ background:#e3f0fb; }} .sw-ext {{ background:#eee; }}
  .sw-std {{ background:#dcefe1; }} .sw-mas {{ background:#f1e2c6; }}
  .sw-bi {{ background:#e7dffa; }}
  /* info tiles (adaptation projects — not runnable in the mock demo) */
  .tile.info {{ cursor:default; background:#fafafa; border-style:dashed; }}
  .tile.info:hover {{ box-shadow:0 1px 2px rgba(0,0,0,.04); transform:none; }}
  .tile.info .ico {{ background:#eee; color:#6a6d70; }}
  .tile .meta {{ font-size:11px; color:#6a6d70; margin-top:6px; line-height:1.5;
               overflow-wrap:anywhere; }}
  .tile .meta b {{ color:#32363a; font-weight:600; }}
  .badge {{ display:inline-block; font-size:10px; font-weight:600; letter-spacing:.03em;
           color:#6a6d70; background:#ececec; border-radius:4px; padding:1px 6px; }}
  /* standard-app tiles (adopt as-is) — green accent */
  .tile.std {{ background:#f5faf6; border-style:dashed; border-color:#cfe6d4; }}
  .tile.std .ico {{ background:#e3f1e6; color:#256029; }}
  .tile.std .badge {{ color:#256029; background:#dcefe1; }}
  /* master-data tiles — amber accent */
  .tile.master {{ background:#fdf8f0; border-style:dashed; border-color:#ecdcc0; }}
  .tile.master .ico {{ background:#f6e8cf; color:#8a5a00; }}
  .tile.master .badge {{ color:#8a5a00; background:#f1e2c6; }}
  /* analytical (BI) tiles — purple accent */
  .tile.bi {{ background:#f8f6fc; border-style:dashed; border-color:#ddd3ee; }}
  .tile.bi .ico {{ background:#eae6f7; color:#5b3a9e; }}
  .tile.bi .badge {{ color:#5b3a9e; background:#e7dffa; }}
  footer {{ text-align:center; color:#9a9d9f; font-size:12px; padding:24px; }}
</style>
</head>
<body>
<header>
  <h1>Kejriwal &mdash; Fiori App Portfolio</h1>
  <p>S/4HANA 2025 upgrade &mdash; the whole portfolio arranged by SAP module</p>
</header>
<main>
  <div class="note"><b>Arranged by module.</b> Every app sits under its SAP module
  below. <b>Custom</b> apps (blue) run live on <b>mock data</b> &mdash; click to open.
  <b>Extended</b>, <b>Standard</b>, <b>Master-data</b> and <b>Analytics</b> tiles are
  reference cards: they run on the S/4HANA FES, not in this mock demo.</div>
  <div class="legend">
    <span><i class="sw-cust"></i>Custom (live demo)</span>
    <span><i class="sw-ext"></i>Extended (adaptation)</span>
    <span><i class="sw-std"></i>Standard (as-is)</span>
    <span><i class="sw-mas"></i>Master data</span>
    <span><i class="sw-bi"></i>Analytics (BI)</span>
  </div>
  {sections_html}
</main>
<footer>Generated by <code>demo/build.py</code> &middot; OpenUI5 bundled same-origin</footer>
</body>
</html>
"""


def tile(app, module, title):
    """Clickable tile for a runnable custom app (blue, live demo)."""
    return (
        f'<a class="tile" href="{app}/index.html">'
        f'<div class="ico">{module}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{app}</div>'
        f'<div class="meta"><span class="badge cust">CUSTOM &middot; LIVE DEMO</span></div>'
        f'</div></a>'
    )


def info_tile(folder, module, title, fiori, replaces):
    """Non-clickable tile for an adaptation project (extends a standard app)."""
    return (
        f'<div class="tile info" title="Adaptation project — runs on S/4HANA, not in this mock demo">'
        f'<div class="ico">{module}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{folder}</div>'
        f'<div class="meta"><span class="badge">STANDARD&nbsp;+&nbsp;EXT</span><br>'
        f'<b>Fiori:</b> {fiori} &middot; <b>replaces</b> {replaces}</div></div></div>'
    )


def standard_tile(module, title, fiori, classic, role, replaces):
    """Non-clickable reference tile for a standard app adopted as-is."""
    return (
        f'<div class="tile std" title="Standard S/4HANA app — assign via business role, runs on the FES">'
        f'<div class="ico">{module}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{fiori} &middot; {classic}</div>'
        f'<div class="meta"><span class="badge">STANDARD</span><br>'
        f'<b>Role:</b> {role}<br><b>replaces</b> {replaces}</div></div></div>'
    )


def master_tile(module, title, table, replaces):
    return (
        f'<div class="tile master" title="Managed RAP master — Fiori Elements app generated from the service binding">'
        f'<div class="ico">{module}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{table}</div>'
        f'<div class="meta"><span class="badge">MASTER DATA</span><br>'
        f'<b>Fiori Elements</b> &middot; replaces {replaces}</div></div></div>'
    )


def bi_tile(module, title, query, replaces):
    return (
        f'<div class="tile bi" title="CDS analytical query — open in the Query Browser / Analytical List Page">'
        f'<div class="ico">{module}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{query}</div>'
        f'<div class="meta"><span class="badge">ANALYTICS</span><br>'
        f'<b>Query Browser / ALP</b> &middot; replaces {replaces}</div></div></div>'
    )


def modules_html(by_module):
    """Render every module section; within each, tiles ordered by type rank."""
    out = ""
    for code, label in MODULES:
        items = by_module.get(code)
        if not items:
            continue
        items.sort(key=lambda t: t[0])          # stable: custom→ext→std→master→bi
        cells = "".join(html for _, html in items)
        out += f'<h2 class="grp">{label}</h2>\n<div class="grid">{cells}</div>\n'
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--resources", required=True, help="path to OpenUI5 'resources' dir")
    ap.add_argument("--dest", required=True, help="output directory")
    ap.add_argument("--link", action="store_true", help="symlink runtime instead of copy (local)")
    args = ap.parse_args()

    dest = os.path.abspath(args.dest)
    os.makedirs(dest, exist_ok=True)

    # shared runtime
    res_dest = os.path.join(dest, "resources")
    if os.path.islink(res_dest) or os.path.exists(res_dest):
        if os.path.islink(res_dest):
            os.unlink(res_dest)
        else:
            shutil.rmtree(res_dest)
    if args.link:
        os.symlink(os.path.abspath(args.resources), res_dest)
    else:
        shutil.copytree(args.resources, res_dest)

    # Bucket every portfolio item under its module, tagged with a type rank so
    # each module lists custom (0) → extended (1) → standard (2) → master (3)
    # → analytics (4).
    by_module = {code: [] for code, _ in MODULES}
    for app, module in APPS:
        title = build_app(app, dest)
        by_module[module].append((0, tile(app, module, title)))
        print(f"  built {app}")
    for folder, module, title, fiori, replaces in ADAPTATION:
        by_module[module].append((1, info_tile(folder, module, title, fiori, replaces)))
    for module, title, fiori, classic, role, replaces in STANDARD:
        by_module[module].append((2, standard_tile(module, title, fiori, classic, role, replaces)))
    for module, title, table, replaces in MASTER_DATA:
        by_module[module].append((3, master_tile(module, title, table, replaces)))
    for module, title, query, replaces in BI_QUERIES:
        by_module[module].append((4, bi_tile(module, title, query, replaces)))

    write(os.path.join(dest, "index.html"), portal_html(modules_html(by_module)))
    write(os.path.join(dest, ".nojekyll"), "")
    print(f"Done -> {dest}")


if __name__ == "__main__":
    main()
