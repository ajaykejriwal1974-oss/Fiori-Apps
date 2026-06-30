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

Two app shapes are handled:
  * "default-model" apps  -> the table binds the default ("") model. We swap that
                             model in manifest.json from the OData dataSource to a
                             JSONModel over mock/data.json.
  * "ui-model" apps       -> the screen builds its data interactively in a named
                             "ui" JSONModel (onInit seeds it empty). We replace
                             that empty seed with realistic rows so the demo shows
                             content on load.

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

# Display metadata for the portal tiles. order = display order; group = module.
APPS = [
    # app folder                       group                       icon
    ("batch-status",                  "Production (PP)",  "sap-icon://batch-payments"),
    ("dyeing-packing",                "Production (PP)",  "sap-icon://add-product"),
    ("manage-packing-details",        "Production (PP)",  "sap-icon://product"),
    ("post-packing-gr",               "Production (PP)",  "sap-icon://goods-issue"),
    ("palletization",                 "Production (PP)",  "sap-icon://pallets"),
    ("mtos-process",                  "Production (PP)",  "sap-icon://shipping-status"),
    ("contract-batch-update",         "Sales (SD)",       "sap-icon://sales-document"),
    ("dispatch-correction",           "Sales (SD)",       "sap-icon://shipping-status"),
    ("hu-unpack",                     "Inventory (MM)",   "sap-icon://unwired"),
    ("inbound-delivery-hus",          "Inventory (MM)",   "sap-icon://inventory"),
    ("post-goods-movement-hu",        "Inventory (MM)",   "sap-icon://goods-issue"),
    ("record-inspection-results-mass","Quality (QM)",     "sap-icon://quality-issue"),
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

    # demo index.html (same-origin bootstrap + height fix)
    write(os.path.join(dest_app, "index.html"),
          demo_index_html(namespace, settings_id, title))

    seed = json.loads(read(os.path.join(MOCK_DIR, app + ".json")))
    if app in UI_MODEL_APPS:
        inject_ui_seed(dest_app, UI_MODEL_APPS[app], seed)
    else:
        os.makedirs(os.path.join(dest_app, "mock"), exist_ok=True)
        write(os.path.join(dest_app, "mock", "data.json"),
              json.dumps(seed, indent=2) + "\n")
        swap_default_model(dest_app)
    return title


def portal_html(tiles_by_group):
    groups = ""
    for group, tiles in tiles_by_group.items():
        cells = "".join(tiles)
        groups += f'<h2 class="grp">{group}</h2>\n<div class="grid">{cells}</div>\n'
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
  a.tile {{ display:flex; flex-direction:column; justify-content:space-between;
           min-height:110px; background:#fff; border:1px solid #e5e5e5; border-radius:10px;
           padding:14px 16px; text-decoration:none; color:inherit;
           box-shadow:0 1px 2px rgba(0,0,0,.04); transition:box-shadow .15s,transform .15s; }}
  a.tile:hover {{ box-shadow:0 4px 14px rgba(0,0,0,.12); transform:translateY(-1px); }}
  .tile .ico {{ width:38px; height:38px; border-radius:9px; background:#eaf3fb;
               color:#0a6ed1; font-size:16px; font-weight:700; display:flex;
               align-items:center; justify-content:center; }}
  .tile .ttl {{ font-size:15px; font-weight:600; margin-top:10px; }}
  .tile .sub {{ font-size:12px; color:#6a6d70; margin-top:2px; }}
  footer {{ text-align:center; color:#9a9d9f; font-size:12px; padding:24px; }}
</style>
</head>
<body>
<header>
  <h1>Kejriwal &mdash; Custom Fiori Apps</h1>
  <p>S/4HANA 2025 upgrade &mdash; sandbox launchpad for testing the configuration</p>
</header>
<main>
  <div class="note"><b>Demo build.</b> Every app runs the real UI5 code against
  realistic <b>mock data</b> &mdash; no backend / OData connection. Use it to review
  layout, fields and flows while the S/4HANA upgrade is in progress.</div>
  {groups}
</main>
<footer>Generated by <code>demo/build.py</code> &middot; OpenUI5 bundled same-origin</footer>
</body>
</html>
"""


def tile(app, group, title):
    badge = re.search(r"\(([A-Z]{2})\)", group)
    badge = badge.group(1) if badge else group[:2].upper()
    return (
        f'<a class="tile" href="{app}/index.html">'
        f'<div class="ico">{badge}</div>'
        f'<div><div class="ttl">{title}</div>'
        f'<div class="sub">{app}</div></div></a>'
    )


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

    tiles_by_group = {}
    for app, group, icon in APPS:
        title = build_app(app, dest)
        tiles_by_group.setdefault(group, []).append(tile(app, group, title))
        print(f"  built {app}")

    write(os.path.join(dest, "index.html"), portal_html(tiles_by_group))
    write(os.path.join(dest, ".nojekyll"), "")
    print(f"Done -> {dest}")


if __name__ == "__main__":
    main()
