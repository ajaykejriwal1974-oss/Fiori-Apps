# Account Grouping (ZSOL_ACCGRP) — custom Fiori Elements app

**Status: LIVE on KSD (client 500)** — Phase 1, 23 Jul 2026. Backend RAP (11 objects)
active, `ZUI_ACCGRP_04` published, app deployed, renders in FLP with live data
(91 account groups from `ZSOL_ACCGRP`).

Freestyle-free **Fiori Elements** List Report + Object Page master-data app, the
clean-core replacement for transaction **`ZSOL_ACCGRP`** ("Maintain Account
Grouping", program `SAPLZSOL_DASH`). One of the genuine custom masters in Phase 1
(it has real Z-tables), unlike ZMINMAX / ZBOE which route to standard.

Binds to the OData V4 service of
[`backend/account-grouping-rap`](../../backend/account-grouping-rap) (`AccountGroup`
root + `AccountAssignment` child), service binding `ZUI_ACCGRP_04`.

## What you maintain
- **Account groups** — group code (`ZZSOL_GRP`), description, sign-reversal flag.
- **Assigned G/L accounts** — the `RACCT` values mapped to each group (child table),
  edited on the group's Object Page.

## Structure (thin FE app — no custom controllers)
`webapp/manifest.json` (routing + FE templates), `Component.js`, `index.html`,
`i18n/`. All UI comes from the backend `@UI` metadata extension.

## Deploy
```bash
cd apps/account-grouping
FIORI_TOOLS_USER=MD FIORI_TOOLS_PASSWORD='<pw>' npx fiori deploy --yes --config ui5-deploy.yaml
```
(Deploy app name `ZACCGRP_APP`, package `ZKGPL_FIORI`, transport `KSDK906624`.)
Then add the FLP tile — semantic object `AccountGroup`, action `manage`.

Prereq: the backend RAP objects must be activated and `ZUI_ACCGRP_04` published first
(see backend README).
