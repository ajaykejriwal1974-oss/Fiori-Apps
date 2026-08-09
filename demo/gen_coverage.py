#!/usr/bin/env python3
"""Generate the Fiori launchpad coverage/mapping report from build.py's data.

Single source of truth = the tile tables in build.py. Produces:
  docs/FIORI-COVERAGE.md   — grouped, shareable Markdown
  docs/FIORI-COVERAGE.csv  — flat, for Excel
Run: python3 demo/gen_coverage.py
"""
import csv
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import build as B  # noqa: E402  (main() is guarded, so importing is safe)

# Custom freestyle apps carry their "replaces" in the top-level README, not in
# build.py — keep the Z-mapping here so the report is complete.
CUSTOM_REPLACES = {
    "batch-status": "ZBATCHD, ZBATCH_CLS",
    "dyeing-packing": "ZPACK01D/02D/03D, ZREPACKD",
    "manage-packing-details": "ZPACK01/01N/02/02N/03, ZREPACK",
    "post-packing-gr": "ZPOST01",
    "palletization": "ZPALLET/1, ZPAL_BOX, ZSOL_ASRS",
    "mtos-process": "ZMTOS, ZHUINV",
    "contract-batch-update": "ZBATCH_CHANGE",
    "dispatch-correction": "ZDSP_CORR",
    "hu-unpack": "ZHUPK",
    "inbound-delivery-hus": "ZHUINB",
    "post-goods-movement-hu": "ZBOX_MOVE",
    "record-inspection-results-mass": "ZQA32",
}
RANK = {"Custom": 0, "Extended": 1, "Standard": 2, "Master data": 3, "Analytics": 4}


def collect():
    rows = []  # (module, type, title, app_id, classic_or_table, role, replaces)
    for folder, module in B.APPS:
        title = B.app_meta(folder)[2]
        rows.append((module, "Custom", title, "freestyle (custom RAP)", "—",
                     "custom business role", CUSTOM_REPLACES.get(folder, "—")))
    for folder, module, title, fiori, replaces in B.ADAPTATION:
        rows.append((module, "Extended", title, fiori, "—",
                     "(base-app role)", replaces))
    for module, title, fiori, classic, role, replaces in B.STANDARD:
        rows.append((module, "Standard", title, fiori, classic, role, replaces))
    for module, title, table, replaces in B.MASTER_DATA:
        rows.append((module, "Master data", title, "Fiori Elements", table,
                     "master-data role", replaces))
    for module, title, query, replaces in B.BI_QUERIES:
        rows.append((module, "Analytics", title, query, "—",
                     "reporting role", replaces))
    return rows


def clean(s):
    return s.replace("&amp;", "&")


def write_md(rows):
    labels = {code: clean(lbl) for code, lbl in B.MODULES}
    order = [code for code, _ in B.MODULES]
    by_mod = {code: [] for code in order}
    for r in rows:
        by_mod[r[0]].append(r)

    total = len(rows)
    from collections import Counter
    tc = Counter(r[1] for r in rows)
    out = []
    out.append("# Kejriwal — Fiori App Portfolio: coverage & mapping\n")
    out.append("S/4HANA 2025 upgrade — every launchpad tile mapped to its SAP "
               "module, type, Fiori/app ID, business role and the Z transaction "
               "it replaces. Generated from `demo/build.py` "
               "(`python3 demo/gen_coverage.py`).\n")
    out.append("**Live launchpad:** <https://ajaykejriwal1974-oss.github.io/Fiori-Apps/>\n")
    out.append(f"**Totals:** {total} tiles — "
               + ", ".join(f"{n} {t.lower()}" for t, n in tc.most_common()) + ".\n")
    # per-module counts
    out.append("| Module | Tiles |\n|---|--:|")
    for code in order:
        if by_mod[code]:
            out.append(f"| {labels[code]} | {len(by_mod[code])} |")
    out.append("")
    out.append("> **Type key** — **Custom** = freestyle app, runs live in the demo; "
               "**Extended** = adaptation of a standard app; **Standard** = delivered "
               "app adopted as-is; **Master data** = managed-RAP → Fiori Elements; "
               "**Analytics** = CDS analytical query. "
               "App IDs shown as `F####`/`W####` are library-verified; plain "
               "transaction codes (e.g. `VK11`, `MI01`) are the reliable anchor "
               "where the Fiori F-number varies by release — confirm in your FES.\n")

    for code in order:
        items = by_mod[code]
        if not items:
            continue
        items.sort(key=lambda r: RANK[r[1]])
        out.append(f"## {labels[code]}\n")
        out.append("| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |")
        out.append("|---|---|---|---|---|---|")
        for _, typ, title, app_id, classic, role, replaces in items:
            out.append(f"| {title} | {typ} | {app_id} | {classic} | {role} | {replaces} |")
        out.append("")
    path = os.path.join(ROOT, "docs", "FIORI-COVERAGE.md")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out) + "\n")
    return path


def write_csv(rows):
    labels = {code: clean(lbl) for code, lbl in B.MODULES}
    order = {code: i for i, (code, _) in enumerate(B.MODULES)}
    rows = sorted(rows, key=lambda r: (order[r[0]], RANK[r[1]]))
    path = os.path.join(ROOT, "docs", "FIORI-COVERAGE.csv")
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["Module", "Type", "App / Tile", "App ID",
                    "Classic tx / table", "Business role", "Replaces / notes"])
        for module, typ, title, app_id, classic, role, replaces in rows:
            w.writerow([labels[module], typ, title, app_id, classic, role, replaces])
    return path


def main():
    rows = collect()
    md = write_md(rows)
    cv = write_csv(rows)
    print(f"{len(rows)} tiles -> {md}")
    print(f"{len(rows)} tiles -> {cv}")


if __name__ == "__main__":
    main()
