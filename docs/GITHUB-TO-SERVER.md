# From GitHub to the server — how the source actually reaches S/4HANA

`TRANSPORT-PLAN.md` explains how objects move **DEV → KSQ → PROD** *inside* the SAP
landscape. This doc covers the step before that: getting the source **out of this
GitHub repo and into the SAP DEV system** in the first place.

> **Key idea:** GitHub → server is **not** an SAP transport. A transport (STMS) only
> moves objects *within* the SAP landscape. Git → SAP is a separate **import** step,
> done with different tools per layer. There are three stages:

```
GitHub repo ──(import)──▶ SAP DEV ──(STMS transport)──▶ KSQ ──▶ PROD
        abapGit (backend)              TR-01 … TR-FLP
        fiori deploy (UI apps)         (TRANSPORT-PLAN.md)
```

Git stays your source-of-truth and change history; **abapGit / fiori deploy is the
bridge into DEV; STMS is the elevator up the landscape.** The SAP server never
"pulls a transport from GitHub" — a developer or a CI job imports the source, then
the activated objects are transported.

---

## Stage 1 — GitHub → DEV (import the source into SAP)

The repo holds two kinds of content that import by **different** mechanisms.

### A. Backend ABAP (`backend/**/src/`) → via abapGit

The backend is serialized in the ADT/abapGit file format (`.ddls.asddls`,
`.bdef.asbdef`, `.clas.abap`, `.srvd.srvdsrv`, …), so abapGit can recreate it as
real repository objects.

1. In DEV, open **abapGit** (the ADT abapGit plug-in, or report `ZABAPGIT_STANDALONE`).
2. Create the **Z packages first** — `ZKEJRIWAL_BE_*` per `TRANSPORT-PLAN.md` §1.
   Production-bound objects must live in a Z package, **never `$TMP`**.
3. **Clone / link** the repo to the package and **pull**. abapGit reads the source
   files and creates the objects (inactive).
4. **Activate** in dependency order — this is exactly the
   [`ADT-ACTIVATION-CHECKLIST`](ADT-ACTIVATION-CHECKLIST.md) **FU#2** sequence
   (CDS → behavior defs → behavior pools → service defs). As objects activate under
   a Z package, SAP prompts for a **workbench transport request**.

> **Repo layout note:** this repo mixes backend ABAP, UI apps, CI and docs in one
> tree, while abapGit maps **one package ↔ one repo/folder**. Two clean options:
> - **Per-feature online repos** — point an abapGit repo at each `backend/<feature>`
>   folder (its `src/` is the package content), matching the `ZKEJRIWAL_BE_*` split.
> - **Offline ZIP per package** — see the air-gapped note below; import each feature
>   folder as its own package.

### B. UI apps (`apps/**`) → via `fiori deploy` (not abapGit)

The SAPUI5 apps are deployed as **BSP applications** onto the embedded Front-End
Server — they are not abapGit objects.

1. Fill the `REPLACE_WITH_*` placeholders in `ui5.yaml` /
   `manifest.appdescr_variant` (`WIRING-CHECKLIST.md`, `PUBLISHING.md`).
2. `npm install && npm run deploy` — runs `fiori deploy`, which builds the app and
   pushes the BSP to the FES, attaching it to a **workbench TR**. Change
   `"packageName": "$TMP"` to a real `ZKEJRIWAL_UI_*` package first.
3. The four adaptation projects (`*-ext`) deploy the same way, as **app variants**.

---

## Air-gapped DEV (no internet to github.com)

Common for on-prem plants. The SAP server does **not** need to reach GitHub:

- **Backend:** download the repo ZIP from GitHub, then in abapGit use
  **Import → from ZIP** (offline repo) per package. No network from SAP at all.
- **UI:** run `npm run deploy` from a workstation/CI box that can reach **both**
  npm (to build) and the **FES** (to deploy) — the SAP box itself needs no internet.

If DEV **does** reach GitHub over HTTPS, first import the GitHub TLS certificate
chain into **STRUST** (SSL client PSE) and confirm the proxy/firewall allows it,
or the abapGit clone fails on certificate verification.

---

## Stage 2 — service bindings + launchpad (per system)

After import, still in DEV:

- Create + **activate/publish** each **OData V4 service binding**
  ([`ADT-ACTIVATION-CHECKLIST`](ADT-ACTIVATION-CHECKLIST.md) **FU#1**); fill the
  `REPLACE_WITH_*_SERVICE` manifest tokens and controller `SERVICE_NS`. The binding
  object transports, but must be **re-activated in each target system**.
- Build the **launchpad** content — catalogs, target mappings, tiles, spaces/pages,
  PFCG roles (`PUBLISHING.md`) → packaged as `TR-FLP`.

---

## Stage 3 — DEV → KSQ → PROD (the actual transports)

Now it is ordinary STMS. Group objects into the **feature transports** defined in
[`TRANSPORT-PLAN.md`](TRANSPORT-PLAN.md) §3 and release them through STMS in order.
On the **embedded FES**, backend + UI ride the *same* transport route — no separate
UI hub.

```
TR-01 (Shade foundation) → (TR-C1..C3 config) → TR-02..TR-09 (features) → TR-FLP (launchpad) → roles
```

Import the same ordered set into KSQ, validate per `GO-LIVE-CHECKLIST.md`, sign off,
then import to PROD (after the SP stack is applied).

---

## Who does what (RACI in one line)

| Stage | Tool | Who | Reaches GitHub? |
|---|---|---|---|
| 1A backend import | abapGit (online or ZIP) | ABAP dev | only if online clone |
| 1B UI deploy | `fiori deploy` / `npm run deploy` | UI dev / CI | build box only, not SAP |
| 2 bindings + FLP | ADT + `/UI2` + PFCG | ABAP dev / Basis | no |
| 3 transports | STMS | Basis | no |

---

## Recommended first pass on DEV (end to end)

1. Create the `ZKEJRIWAL_*` package tree (`TRANSPORT-PLAN.md` §1).
2. abapGit-import + activate **TR-01 Shade** foundation first; activate its binding.
3. abapGit-import + activate the remaining backend features (FU#2 order); resolve the
   FU#3 `VERIFY` markers as the unmanaged pools activate.
4. Create + activate all OData V4 bindings (FU#1); fill the app placeholders.
5. `npm run deploy` each UI app + adaptation variant to the FES (real package + TR).
6. Build launchpad content; assign roles; smoke-test (`GO-LIVE-CHECKLIST.md`).
7. Collect everything into the feature TRs and release **DEV → KSQ → PROD**
   (`TRANSPORT-PLAN.md` §4).

> See also: [`ACTIVATION.md`](ACTIVATION.md) (Basis activation gate),
> [`ADT-ACTIVATION-CHECKLIST.md`](ADT-ACTIVATION-CHECKLIST.md) (FU#1–FU#4),
> [`PUBLISHING.md`](PUBLISHING.md) (FES deploy + tiles),
> [`TRANSPORT-PLAN.md`](TRANSPORT-PLAN.md) (packages + TR sequence).
