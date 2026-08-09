#!/usr/bin/env python3
"""Assemble a static, hostable demo Launchpad for the custom KGPL Fiori apps,
organised into the **KGPL Fiori Launchpad Spaces** we designed on KSD:
Sales & Billing, Purchasing, Packing & HU, Production & QM, Dispatch & Gate Pass,
Stock, Master Data, Statutory / Compliance.

Each runnable freestyle app runs the real UI5 code against realistic **mock JSON
data** and a **same-origin** OpenUI5 runtime (no external CDN — required for iOS
Safari). Master-data, analytics, adaptation and other-live apps appear as
reference tiles within their Space (they run on the S/4HANA FES, not here).

    <dest>/
      resources/            shared OpenUI5 runtime (one copy for all apps)
      index.html            portal: tiles grouped by FLP Space
      <app>/                copied webapp + demo index.html + mock/data.json
      ...

Usage:
    python3 demo/build.py --resources /path/to/openui5/resources --dest dist
    python3 demo/build.py --resources <res> --dest <dest> --link   # symlink (local)
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
# controller onInit. For these we inject the seed rows.
UI_MODEL_APPS = {
    "contract-batch-update": "controller/Main.controller.js",
    "dyeing-packing":        "controller/Main.controller.js",
    "post-goods-movement-hu": "controller/Main.controller.js",
}

# Apps that already bundle their own JSON data — copy only. (none currently)
SELF_CONTAINED = set()

# ------------------------------------------------------------- FLP Spaces
# The 8 KGPL Launchpad Spaces (code, title), in display order. Every custom app
# below is tagged with the Space it lives in on the real FLP.
SPACES = [
    ("SALES", "Sales &amp; Billing"),
    ("PURCH", "Purchasing"),
    ("PACK",  "Packing &amp; HU"),
    ("PROD",  "Production &amp; QM"),
    ("DISP",  "Dispatch &amp; Gate Pass"),
    ("STOCK", "Stock"),
    ("MAST",  "Master Data"),
    ("STAT",  "Statutory / Compliance"),
]
BADGE = {"SALES": "S&amp;B", "PURCH": "Pur", "PACK": "Pack", "PROD": "P&amp;Q",
         "DISP": "Disp", "STOCK": "Stk", "MAST": "MD", "STAT": "Stat"}

# Runnable freestyle custom apps (blue — live demo on mock data). (folder, space)
APPS = [
    ("batch-status",                  "PROD"),
    ("dyeing-packing",                "PROD"),
    ("manage-packing-details",        "PACK"),
    ("post-packing-gr",               "PACK"),
    ("palletization",                 "PACK"),
    ("mtos-process",                  "PROD"),
    ("contract-batch-update",         "PROD"),
    ("dispatch-correction",           "DISP"),
    ("hu-unpack",                     "PACK"),
    ("inbound-delivery-hus",          "PACK"),
    ("post-goods-movement-hu",        "PACK"),
    ("record-inspection-results-mass","PROD"),
]

# Adaptation projects (*-ext): custom fields / sections / logic on a standard
# app. Reference tiles (run on the FES). (folder, space, title, fiori, replaces)
ADAPTATION = [
    ("manage-sales-orders-ext",         "SALES", "Manage Sales Orders",          "F1873",  "ZVA01 / ZVA01N, ZSOCLOSE"),
    ("manage-sales-contracts-ext",      "SALES", "Manage Sales Contracts",       "VA42",   "ZCON_CLOSE/1, ZCOREL, ZCON02"),
    ("manage-outbound-deliveries-ext",  "DISP",  "Manage Outbound Deliveries",   "F0867A", "ZDEL"),
    ("confirm-production-operation-ext","PROD",  "Confirm Production Operation",  "F3069",  "ZCO11N / ZCO11A"),
]

# Master-data apps (managed RAP -> Fiori Elements). (title, space, table, replaces)
MASTER_DATA = [
    ("Shade Master",             "MAST",  "ZDD_SHADE",          "ZDD_SHADE"),
    ("Recipe Master",            "PROD",  "ZPP_RECEIPE",        "ZRECP01/02/03"),
    ("Job Master",               "PROD",  "ZPP_JOBN",           "ZJOB01/02/03(N)"),
    ("Truck Master",             "MAST",  "ZTB_TRUCK_MSTR",     "ZTRUCK"),
    ("Schedule Master",          "PROD",  "ZPP_SCHEDULEN",      "ZSCH01/02/03(N)"),
    ("Transport Code",           "MAST",  "ZTRANS",             "ZTRANS"),
    ("Merge Details",            "PROD",  "ZPP_MERGE",          "ZMERGE"),
    ("Checked / Packed By",      "MAST",  "ZPP_PCBY",           "ZPCBY"),
    ("Packing Material Master",  "MAST",  "ZPACK_MAST",         "ZPACK_MAST"),
    ("Export Details",           "SALES", "ZEXP",               "ZMBR2"),
    ("Digital Signature",        "MAST",  "ZTDIGI_SIGN",        "ZDIGI"),
    ("C-Form Allocation",        "SALES", "ZCFORM1",            "ZCFORM1/ZFORM/ZFORMS/ZPCFORM"),
    ("Gate Pass",                "DISP",  "ZGP_HDR / ZGP_ITEM", "ZGPS01-03, ZGPSI1-3"),
]

# Analytical (BI) CDS queries (ZC_*Query over a cube). (title, space, query, replaces)
BI_QUERIES = [
    ("Packed Stock",                "STOCK", "ZC_PackedStockQuery",      "8 stock reports (ZBOXSTOCK...)"),
    ("Packing Register",            "PACK",  "ZC_PackingRegisterQuery",  "17 pack-list reports"),
    ("WIP Batch",                   "PROD",  "ZC_WipBatchQuery",         "ZBATCH_WIP"),
    ("HU Inventory",                "STOCK", "ZC_HuInventoryQuery",      "ZHUINV_CLS"),
    ("HU Monitor / Reconciliation", "STOCK", "ZC_HuMonitorQuery",        "ZHUMO, ZHUREC"),
    ("Pending Contract",            "SALES", "ZC_PendingContractQuery",  "ZPCON, ZPCOND, ZPCONS"),
    ("Export Register",             "SALES", "ZC_ExportRegisterQuery",   "ZGCUDB, ZBRC/ZEXP"),
    ("Merge Analysis",              "PROD",  "ZC_MergeAnalysisQuery",    "merge stock reports"),
    ("Recipe Analysis",             "PROD",  "ZC_RecipeAnalysisQuery",   "ZRECPM"),
    ("Job Card",                    "PROD",  "ZC_JobCardQuery",          "ZJOBREPTN"),
    ("Dispatch Register",           "DISP",  "ZC_DispatchRegisterQuery", "ZPWDIS (schedule-wise)"),
    ("Pending / Security Dispatch", "DISP",  "ZC_PendingDispatchQuery",  "ZDISPATCH, ZPDESP"),
    ("GST Tax",                     "SALES", "ZC_GstTaxQuery",           "ZGST, ZGST1, ZGST2, ZGSTCR"),
]

# Live custom apps deployed on KSD with no standalone mock webapp here — shown as
# reference tiles so each Space is complete. (title, space, launch target)
LIVE_REF = [
    ("Sales Register",              "SALES", "AnalyticQuery &middot; XQUERY=2CZC_SALES_REGISTER"),
    ("Customer Register",           "SALES", "AnalyticQuery &middot; XQUERY=2CZC_CUSTOMER_MASTER"),
    ("Credit / Debit Note",         "SALES", "AnalyticQuery &middot; XQUERY=2CZC_CRDR_NOTE"),
    ("Delivery Challan",            "SALES", "Fiori Elements &middot; DeliveryChallan-display"),
    ("Sales Document Status",       "SALES", "Fiori Elements &middot; SalesDocStatus"),
    ("Purchase Register",           "PURCH", "Fiori Elements &middot; PurchaseRegister-display"),
    ("PO Closure Register",         "PURCH", "AnalyticQuery &middot; XQUERY=2CZC_PO_CLOSE"),
    ("Vendor Invoice Allocation",   "PURCH", "Fiori Elements &middot; ZVFORM"),
    ("PO Automation — Job Monitor", "PURCH", "Std &middot; SM37 / job log"),
    ("Packing Units",               "PACK",  "Fiori Elements &middot; PackingUnit-display"),
    ("Packing List",                "PACK",  "Fiori Elements &middot; ZC_PACKING_LIST"),
    ("HU Item",                     "PACK",  "Fiori Elements &middot; HuItem"),
    ("Unassign Return Boxes",       "PACK",  "Fiori Elements &middot; ReturnBox-manage"),
    ("Gate Pass Register",          "DISP",  "AnalyticQuery &middot; XQUERY=2CZC_GATEPASS_REGISTER"),
    ("Job-Work Challan",            "DISP",  "AnalyticQuery &middot; XQUERY=2CZC_JOBWORK_CHALLAN"),
    ("Pallet Stock",                "STOCK", "Fiori Elements &middot; PalletStock-display"),
    ("Account Group",               "MAST",  "Fiori Elements &middot; ZC_ACCGRP"),
    ("eInvoice &amp; eWay (India DRC)","STAT","Std &middot; DRC cockpit (Phase 4)"),
    ("GST Tax Register",            "STAT",  "AnalyticQuery &middot; XQUERY=2CZC_GST_TAX"),
    ("TDS Register",                "STAT",  "AnalyticQuery &middot; XQUERY=2CZC_TDS"),
    ("Audit Log",                   "STAT",  "AnalyticQuery &middot; XQUERY=2CZC_AUDIT_LOG"),
]

# Runnable data-viewer tiles: the generic kgpl-viewer app rendering REAL KSD
# reference / master data (pulled live from KSD, bundled as demo/mock/kgpl-catalog.json).
# Every entry is clickable and shows actual rows with working Company-Code / Plant
# pickers. (title, space, entity_key)
VIEWER = [
    ("Company Codes",             "MAST",  "companyCodes"),
    ("Plants",                    "MAST",  "plants"),
    ("Sales Organizations",       "MAST",  "salesOrgs"),
    ("Divisions (Product)",       "MAST",  "divisions"),
    ("Distribution Channels",     "MAST",  "distChannels"),
    ("Billing Types",             "MAST",  "billingTypes"),
    ("Grades",                    "MAST",  "grades"),
    ("Yarn Material Master",      "MAST",  "materials"),
    ("Customers",                 "SALES", "customers"),
    ("Suppliers (Vendors)",       "PURCH", "suppliers"),
    ("Dyeing Jobs (Job Master)",  "PROD",  "jobs"),
    ("Dyeing Schedules",          "PROD",  "schedules"),
    ("Merge Details",             "PROD",  "merge"),
    ("Packing Boxes",             "PACK",  "packing"),
    ("Sales Register",            "SALES", "salesRegister"),
    ("Purchase Register",         "PURCH", "purchaseRegister"),
    ("Purchase Orders",           "PURCH", "purchaseOrders"),
    ("Delivery Challan",          "DISP",  "deliveryChallan"),
    ("Dyeing Recipes",            "PROD",  "recipes"),
    ("Transport Codes",           "MAST",  "transportCodes"),
    ("Checked / Packed By",       "PACK",  "checkedPackedBy"),
    ("Packing Material Master",   "PACK",  "packingMaterials"),
    ("GST Tax Register",          "STAT",  "gstRegister"),
    ("TDS Register",              "STAT",  "tdsRegister"),
    ("Truck Master",              "MAST",  "truckMaster"),
    ("Export Details",            "SALES", "exportDetails"),
]

# Runnable viewer tiles backed by SAMPLE data (source table is empty on KSD, so
# rows are representative — grounded in real domain values but clearly labelled).
# (title, space, entity_key)
VIEWER_SAMPLE = [
    ("Shade Master",       "MAST",  "shadeMaster"),
    ("C-Form Allocation",  "SALES", "cformAllocation"),
    ("Gate Pass",          "DISP",  "gatePass"),
]

# Reference tiles (MASTER_DATA or LIVE_REF) superseded by a runnable VIEWER tile
# with real data now — so we don't list them twice.
VIEWER_SUPERSEDES = {
    "Job Master", "Schedule Master", "Merge Details",
    "Recipe Master", "Transport Code", "Checked / Packed By",
    "Packing Material Master", "Sales Register", "Purchase Register",
    "Delivery Challan", "GST Tax Register", "TDS Register",
    "Shade Master", "Truck Master", "Export Details",
    "C-Form Allocation", "Gate Pass",
}


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


def app_meta(app):
    """Return (namespace, settings_id, title) read from the source."""
    manifest = json.loads(read(os.path.join(APPS_DIR, app, "webapp", "manifest.json")))
    namespace = manifest["sap.app"]["id"]
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
    mpath = os.path.join(dest_app, "manifest.json")
    manifest = json.loads(read(mpath))
    models = manifest["sap.ui5"].setdefault("models", {})
    models[""] = {"type": "sap.ui.model.json.JSONModel", "uri": "mock/data.json"}
    write(mpath, json.dumps(manifest, indent=2) + "\n")


def inject_ui_seed(dest_app, controller_rel, seed):
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

    for dead in ("sw.js", "manifest.webmanifest"):
        dpath = os.path.join(dest_app, dead)
        if os.path.exists(dpath):
            os.remove(dpath)

    write(os.path.join(dest_app, "index.html"),
          demo_index_html(namespace, settings_id, title))

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


def build_viewer(dest):
    """Copy the generic kgpl-viewer app + bundle the real-KSD catalog beside it."""
    app = "kgpl-viewer"
    src_webapp = os.path.join(APPS_DIR, app, "webapp")
    dest_app = os.path.join(dest, app)
    if os.path.exists(dest_app):
        shutil.rmtree(dest_app)
    shutil.copytree(src_webapp, dest_app)
    # bundle the live-KSD data catalog the controller fetches at runtime
    catalog = read(os.path.join(MOCK_DIR, "kgpl-catalog.json"))
    write(os.path.join(dest_app, "catalog.json"), catalog)
    manifest = json.loads(read(os.path.join(dest_app, "manifest.json")))
    namespace = manifest["sap.app"]["id"]
    write(os.path.join(dest_app, "index.html"),
          demo_index_html(namespace, "viewer", "KGPL Data Viewer"))
    n = len(json.loads(catalog).get("entities", {}))
    print(f"  built {app}  [+{n} live-KSD entities]")


def portal_html(sections_html):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<title>KGPL &mdash; Fiori Launchpad (Demo)</title>
<style>
  body {{ margin:0; font-family:-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
         background:#f5f6f7; color:#32363a; }}
  header {{ background:#0a6ed1; color:#fff; padding:18px 24px; }}
  header h1 {{ margin:0; font-size:20px; font-weight:600; }}
  header p {{ margin:4px 0 0; font-size:13px; opacity:.9; }}
  main {{ padding:16px 24px 48px; max-width:1180px; margin:0 auto; }}
  .note {{ background:#fff7e6; border:1px solid #f0d9a8; border-radius:8px;
          padding:10px 14px; font-size:13px; margin:16px 0; }}
  .grp {{ font-size:15px; font-weight:600; letter-spacing:.02em;
         color:#0a3d62; margin:30px 0 10px; padding-bottom:6px;
         border-bottom:2px solid #d6e4f0; }}
  .grid {{ display:grid; gap:14px; grid-template-columns:repeat(auto-fill,minmax(230px,1fr)); }}
  .tile {{ display:flex; flex-direction:column; justify-content:space-between;
           min-height:112px; background:#fff; border:1px solid #e5e5e5; border-radius:10px;
           padding:14px 16px; text-decoration:none; color:inherit;
           box-shadow:0 1px 2px rgba(0,0,0,.04); transition:box-shadow .15s,transform .15s; }}
  a.tile:hover {{ box-shadow:0 4px 14px rgba(0,0,0,.12); transform:translateY(-1px); }}
  .tile .ico {{ width:40px; height:40px; border-radius:9px; background:#eaf3fb;
               color:#0a6ed1; font-size:12px; font-weight:700; display:flex;
               align-items:center; justify-content:center; }}
  .tile .ttl {{ font-size:15px; font-weight:600; margin-top:10px; }}
  .tile .sub {{ font-size:12px; color:#6a6d70; margin-top:2px; overflow-wrap:anywhere; }}
  .tile .meta {{ font-size:11px; color:#6a6d70; margin-top:6px; line-height:1.5;
               overflow-wrap:anywhere; }}
  .tile .meta b {{ color:#32363a; font-weight:600; }}
  .badge {{ display:inline-block; font-size:10px; font-weight:600; letter-spacing:.03em;
           color:#6a6d70; background:#ececec; border-radius:4px; padding:1px 6px; }}
  .badge.cust {{ color:#0a6ed1; background:#e3f0fb; }}
  .legend {{ display:flex; flex-wrap:wrap; gap:8px 18px; font-size:12px;
            color:#4a4d50; margin:12px 0 4px; }}
  .legend span {{ display:inline-flex; align-items:center; gap:6px; }}
  .legend i {{ width:11px; height:11px; border-radius:3px; display:inline-block;
              border:1px solid rgba(0,0,0,.12); }}
  .sw-cust {{ background:#e3f0fb; }} .sw-ext {{ background:#eee; }}
  .sw-live {{ background:#d9e7f7; }} .sw-mas {{ background:#f1e2c6; }}
  .sw-bi {{ background:#e7dffa; }}
  .tile.info {{ cursor:default; background:#fafafa; border-style:dashed; }}
  .tile.info:hover {{ box-shadow:0 1px 2px rgba(0,0,0,.04); transform:none; }}
  .tile.info .ico {{ background:#eee; color:#6a6d70; }}
  .tile.live {{ background:#f6faff; border-style:dashed; border-color:#cddff2; }}
  .tile.live .ico {{ background:#e0ecfa; color:#0a4f8f; }}
  .tile.live .badge {{ color:#0a4f8f; background:#dcebfb; }}
  .tile.live .badge.std {{ color:#5a5d60; background:#e6e6e6; }}
  .tile.master {{ background:#fdf8f0; border-style:dashed; border-color:#ecdcc0; }}
  .tile.master .ico {{ background:#f6e8cf; color:#8a5a00; }}
  .tile.master .badge {{ color:#8a5a00; background:#f1e2c6; }}
  .tile.bi {{ background:#f8f6fc; border-style:dashed; border-color:#ddd3ee; }}
  .tile.bi .ico {{ background:#eae6f7; color:#5b3a9e; }}
  .tile.bi .badge {{ color:#5b3a9e; background:#e7dffa; }}
  .tile.data {{ background:#f2fbf4; border-color:#c3e6cd; }}
  .tile.data .ico {{ background:#dcf3e3; color:#1a7f37; }}
  .tile.data .badge {{ color:#1a7f37; background:#d6f0de; }}
  .badge.data {{ color:#1a7f37; background:#d6f0de; }}
  .sw-data {{ background:#d6f0de; }}
  .tile.sample {{ background:#fffaf0; border-color:#f0e0b8; }}
  .tile.sample .ico {{ background:#f7eccf; color:#8a6d00; }}
  .tile.sample .badge {{ color:#8a6d00; background:#f5e6bf; }}
  .badge.sample {{ color:#8a6d00; background:#f5e6bf; }}
  .sw-sample {{ background:#f5e6bf; }}
  footer {{ text-align:center; color:#9a9d9f; font-size:12px; padding:24px; }}
</style>
</head>
<body>
<header>
  <h1>KGPL &mdash; Fiori Launchpad</h1>
  <p>S/4HANA 2025 &mdash; custom apps arranged by the KGPL FLP <b>Spaces</b> (KSD)</p>
</header>
<main>
  <div class="note"><b>Arranged by FLP Space.</b> <b>Custom</b> apps (blue) run live
  on <b>mock data</b>, and <b>Live KSD data</b> tiles (green) open a viewer over
  <b>real rows pulled from KSD</b> &mdash; click either to open and test.
  <b>Sample data</b> tiles (amber) run over representative rows where the source
  table is still empty on KSD. <b>Adaptation</b>, <b>Master-data</b>,
  <b>Analytics</b> and other <b>Live</b> tiles are reference cards: they run on
  the S/4HANA FES, not in this mock demo.</div>
  <div class="legend">
    <span><i class="sw-cust"></i>Custom (live demo)</span>
    <span><i class="sw-data"></i>Live KSD data (viewer)</span>
    <span><i class="sw-sample"></i>Sample data (table empty on KSD)</span>
    <span><i class="sw-live"></i>Custom on FES (Fiori Elements / analytical)</span>
    <span><i class="sw-ext"></i>Adaptation (ext)</span>
    <span><i class="sw-mas"></i>Master data</span>
    <span><i class="sw-bi"></i>Analytics (BI)</span>
  </div>
  {sections_html}
</main>
<footer>Generated by <code>demo/build.py</code> &middot; OpenUI5 bundled same-origin &middot; 8 KGPL Spaces</footer>
</body>
</html>
"""


def tile(app, space, title):
    """Clickable tile for a runnable custom app (blue, live demo)."""
    return (
        f'<a class="tile" href="{app}/index.html">'
        f'<div class="ico">{BADGE[space]}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{app}</div>'
        f'<div class="meta"><span class="badge cust">CUSTOM &middot; LIVE DEMO</span></div>'
        f'</div></a>'
    )


def tile_viewer(space, title, entity_key):
    """Runnable tile: opens the kgpl-viewer on a real-KSD entity."""
    return (
        f'<a class="tile data" href="kgpl-viewer/index.html?e={entity_key}" '
        f'title="Live KSD data — real rows pulled from the S/4HANA database">'
        f'<div class="ico">{BADGE[space]}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">kgpl-viewer &middot; {entity_key}</div>'
        f'<div class="meta"><span class="badge data">LIVE KSD DATA</span></div>'
        f'</div></a>'
    )


def tile_sample(space, title, entity_key):
    """Runnable tile backed by representative SAMPLE data (source table empty on KSD)."""
    return (
        f'<a class="tile sample" href="kgpl-viewer/index.html?e={entity_key}" '
        f'title="Sample data — the source table is empty on KSD; rows are representative">'
        f'<div class="ico">{BADGE[space]}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">kgpl-viewer &middot; {entity_key}</div>'
        f'<div class="meta"><span class="badge sample">SAMPLE DATA</span></div>'
        f'</div></a>'
    )


def info_tile(folder, space, title, fiori, replaces):
    return (
        f'<div class="tile info" title="Adaptation project — runs on S/4HANA, not in this mock demo">'
        f'<div class="ico">{BADGE[space]}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{folder}</div>'
        f'<div class="meta"><span class="badge">STANDARD&nbsp;+&nbsp;EXT</span><br>'
        f'<b>Fiori:</b> {fiori} &middot; <b>replaces</b> {replaces}</div></div></div>'
    )


def master_tile(space, title, table, replaces):
    return (
        f'<div class="tile master" title="Managed RAP master — Fiori Elements app generated from the service binding">'
        f'<div class="ico">{BADGE[space]}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{table}</div>'
        f'<div class="meta"><span class="badge">MASTER DATA</span><br>'
        f'<b>Fiori Elements</b> &middot; replaces {replaces}</div></div></div>'
    )


def bi_tile(space, title, query, replaces):
    return (
        f'<div class="tile bi" title="CDS analytical query — open in the Query Browser / Analytical List Page">'
        f'<div class="ico">{BADGE[space]}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{query}</div>'
        f'<div class="meta"><span class="badge">ANALYTICS</span><br>'
        f'<b>Query Browser / ALP</b> &middot; replaces {replaces}</div></div></div>'
    )


def live_tile(space, title, launch):
    """Reference tile for a live KSD app with no standalone mock webapp here.

    The badge distinguishes CUSTOM apps (custom CDS/RAP services rendered by the
    Fiori Elements framework, or custom analytical queries) from genuinely
    STANDARD SAP apps. 'Fiori Elements' / 'AnalyticQuery' here name the UI
    technology — these apps are custom-built, not standard SAP.
    """
    if launch.startswith("Fiori Elements"):
        badge = '<span class="badge cust">CUSTOM &middot; FIORI ELEMENTS</span>'
    elif launch.startswith("AnalyticQuery"):
        badge = '<span class="badge cust">CUSTOM &middot; ANALYTICAL QUERY</span>'
    elif launch.startswith("Std"):
        badge = '<span class="badge std">STANDARD SAP</span>'
    else:
        badge = '<span class="badge">LIVE &middot; FES</span>'
    return (
        f'<div class="tile live" title="Deployed on KSD — runs on the S/4HANA FES, not in this mock demo">'
        f'<div class="ico">{BADGE[space]}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">on KSD (FES)</div>'
        f'<div class="meta">{badge}<br>{launch}</div></div></div>'
    )


def spaces_html(by_space):
    """Render every Space section; within each, tiles ordered by type rank."""
    out = ""
    for code, label in SPACES:
        items = by_space.get(code)
        if not items:
            continue
        items.sort(key=lambda t: (t[0], t[1]))   # rank then title
        cells = "".join(html for _, _, html in items)
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

    # Bucket every custom item under its FLP Space, tagged with a type rank so
    # each Space lists runnable (0) -> live-on-FES (1) -> adaptation (2) ->
    # master (3) -> analytics (4).
    by_space = {code: [] for code, _ in SPACES}
    for app, space in APPS:
        title = build_app(app, dest)
        by_space[space].append((0, title, tile(app, space, title)))
        print(f"  built {app}  [{space}]")
    build_viewer(dest)
    for title, space, entity_key in VIEWER:
        by_space[space].append((0, title, tile_viewer(space, title, entity_key)))
    for title, space, entity_key in VIEWER_SAMPLE:
        by_space[space].append((0, title, tile_sample(space, title, entity_key)))
    for title, space, launch in LIVE_REF:
        if title in VIEWER_SUPERSEDES:
            continue  # now runnable via a VIEWER tile with real data
        by_space[space].append((1, title, live_tile(space, title, launch)))
    for folder, space, title, fiori, replaces in ADAPTATION:
        by_space[space].append((2, title, info_tile(folder, space, title, fiori, replaces)))
    for title, space, table, replaces in MASTER_DATA:
        if title in VIEWER_SUPERSEDES:
            continue  # now runnable via a VIEWER tile with real data
        by_space[space].append((3, title, master_tile(space, title, table, replaces)))
    for title, space, query, replaces in BI_QUERIES:
        by_space[space].append((4, title, bi_tile(space, title, query, replaces)))

    write(os.path.join(dest, "index.html"), portal_html(spaces_html(by_space)))
    write(os.path.join(dest, ".nojekyll"), "")
    print(f"Done -> {dest}")


if __name__ == "__main__":
    main()
