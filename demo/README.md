# Demo Launchpad — test the custom apps with mock data

A static, hostable sandbox that lets you open and click through **all 12 custom
freestyle Fiori apps** while the S/4HANA 2025 backend is still being prepared.
Every app runs the **real UI5 code** (the same `webapp/` that will be deployed)
against **realistic mock JSON data** and a **same-origin** OpenUI5 runtime — no
backend, no OData connection, no external CDN.

## Open it

Published automatically to GitHub Pages (see the workflow below):

```
https://ajaykejriwal1974-oss.github.io/Fiori-Apps/
```

The landing page is a tile grid grouped by module (PP / SD / MM / QM). Click a
tile to open that app; the in-app banner links back to the launchpad. Two further
**reference** sections complete the portfolio with non-clickable info tiles (they
run on the S/4HANA Front-End Server, not in this mock demo):

- **Adaptation projects** — the 4 `*-ext` apps that extend a standard delivered
  Fiori app (clean-core), with their Fiori ID and the Z they replace.
- **Standard apps (adopt as-is)** — the delivered S/4HANA 2025 apps used as-is
  (the STD / Table A portfolio), each with its Fiori ID, classic transaction,
  business role, and the Z transaction it retires.

Edit the `ADAPTATION` and `STANDARD` tables at the top of `build.py` to add or
adjust these reference tiles.

> **Mock data only.** Buttons and edits work against the in-browser JSON model;
> nothing is posted anywhere. Use it to review layout, fields, columns and flows.

## How it works

```
demo/
  build.py            assembles the static site
  mock/<app>.json     realistic sample rows for each app
<dest>/               (build output — not committed)
  resources/          ONE shared OpenUI5 runtime for all apps (same-origin)
  index.html          portal (tile grid)
  <app>/              copied webapp + demo index.html + mock/data.json
```

`build.py` does, per app:

1. Copies the app's `webapp/` into the output folder.
2. Writes a demo `index.html` that bootstraps UI5 from the **shared
   `../resources/sap-ui-core.js`** (same-origin) and applies the full-height CSS
   chain (`#content → ComponentContainer → UIArea → View → Page`), without which
   the page content collapses to a blank strip on iOS Safari.
3. Feeds it mock data:
   - **default-model apps** — swaps the `""` model in `manifest.json` from the
     OData `dataSource` to a `JSONModel` over `mock/data.json`.
   - **ui-model apps** (`contract-batch-update`, `dyeing-packing`,
     `post-goods-movement-hu`) — these build their data interactively in a named
     `ui` model, so the empty seed in the controller `onInit` is replaced with
     realistic rows.

## Build locally

```bash
# 1) build the shared runtime once (bundles OpenUI5 incl. sap.ui.table)
cd apps/batch-status
npm install
npx ui5 build --all --config ui5-build.yaml --dest /tmp/demo-runtime

# 2) assemble the site (symlink the runtime for fast local iteration)
cd ../..
python3 demo/build.py --resources /tmp/demo-runtime/resources --dest /tmp/demo-dist --link

# 3) serve
cd /tmp/demo-dist && python3 -m http.server 8095   # http://localhost:8095/
```

## Auto-deploy

[`.github/workflows/demo-pages.yml`](../.github/workflows/demo-pages.yml) runs on
every push to `main` that touches `apps/**` or `demo/**`: it builds the shared
runtime, runs `demo/build.py`, and publishes the result to the `gh-pages`
branch. No manual step — change an app, push to `main`, and the live site
rebuilds.

**One-time setup:** the repo must be public (or GitHub Pages enabled on a paid
plan), then Settings → Pages → *Deploy from a branch* → `gh-pages` / `root`.
