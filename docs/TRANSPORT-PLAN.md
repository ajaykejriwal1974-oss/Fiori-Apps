# Transport & Package Plan

How to organize the KEJRIWAL objects into **packages** and **transport requests**
and move them **DEV → Quality (KSQ/KHQ, client 500) → PROD**. Because the landscape
uses the **embedded Front-End Server**, the UI (BSP) and the ABAP backend live on
the same stack and travel in the **same transport route** — no separate hub/UI
system to coordinate.

> Build in **DEV**, transport up. The runbook activates base apps and validates in
> KSQ; do not import to PROD until KSQ is signed off and the SP stack is applied.

---

## 1. Package hierarchy

Create one structure (super) package and group by layer + domain:

```
ZKEJRIWAL_FIORI                     (structure package; transport layer = your Z layer)
├── ZKEJRIWAL_BE                    (backend - structure)
│   ├── ZKEJRIWAL_BE_SHADE          ZDD_SHADE: table, CDS, behavior, class, service
│   ├── ZKEJRIWAL_BE_QM             QM mass results: CDS, behavior, class, service
│   ├── ZKEJRIWAL_BE_MM_HU          HU goods movement: CDS, abstract entities, class, service
│   ├── ZKEJRIWAL_BE_PP_PACK        Dyeing packing: CDS, abstract entities, class, service
│   ├── ZKEJRIWAL_BE_SD_CONTRACT    Contract batch + contract status/rate (RAP/BAdI)
│   └── ZKEJRIWAL_BE_SD_SO          Sales-order pricing/validation + order-close (RAP/BAdI)
└── ZKEJRIWAL_UI                    (UI - structure)
    ├── ZKEJRIWAL_UI_ADP            adaptation projects (app variants): F1873, F3069, F0867A, contracts
    └── ZKEJRIWAL_UI_APP            custom Fiori apps (BSP): inspection mass, HU move, packing, contract batch
```

Assign every package a **software component / transport layer** so objects collect
into workbench requests routed DEV → KSQ → PROD. Keep `$TMP` only for throwaway
sandbox work — **production-bound objects must be in a Z package**.

---

## 2. Workbench vs customizing requests

| Object type | Request kind | Package |
|---|---|---|
| CDS views, behavior defs, behavior classes, service def/binding, DB table | **Workbench** | `ZKEJRIWAL_BE_*` |
| RAP/BAdI implementations (pricing, status, close, batch) | **Workbench** | `ZKEJRIWAL_BE_*` |
| BSP apps (custom apps + deployed adaptation variants) | **Workbench** (attached by `fiori deploy`) | `ZKEJRIWAL_UI_*` |
| Adaptation project app-variant descriptor (`manifest.appdescr_variant`) | **Workbench** (set `packageName` from `$TMP` → `ZKEJRIWAL_UI_ADP`) | `ZKEJRIWAL_UI_ADP` |
| Output Management (ZCHALLAN type + Adobe form), status profiles, HU config | **Customizing** | (config, not these packages) |
| Key-user Custom Fields & Logic (`YY1_*`), Adapt-UI / RTA changes | **Auto-collected** extensibility transports (see §5) | n/a |

---

## 3. Feature transports (grouping + sequence)

Group by **feature**, each carrying that feature's backend + UI together, with the
shared foundation first. Suggested requests and import order:

| # | Transport (description) | Contents | Depends on |
|---|---|---|---|
| TR-01 | KEJRIWAL Foundation – Shade Master | `ZKEJRIWAL_BE_SHADE` (table, CDS, BO, service) + binding | — |
| TR-02 | KEJRIWAL F1873 Sales Orders | SO ext UI variant + SO BAdI/RAP (pricing, order-close); shade value-help wiring | TR-01 |
| TR-03 | KEJRIWAL F3069 Prod Confirmation | confirmation UI variant + dyeing BAdI/RAP; shade value-help | TR-01 |
| TR-04 | KEJRIWAL F0867A Outbound Delivery | delivery UI variant; (+ TR-C1 Output Mgmt config) | TR-C1 |
| TR-05 | KEJRIWAL Sales Contracts (status/rate) | contract UI variant + status/close/release RAP/BAdI | TR-C2 |
| TR-06 | KEJRIWAL QM Mass Results | `ZKEJRIWAL_BE_QM` + inspection-mass BSP app | — |
| TR-07 | KEJRIWAL HU Goods Movement | `ZKEJRIWAL_BE_MM_HU` + HU-move BSP app | — |
| TR-08 | KEJRIWAL Dyeing Packing | `ZKEJRIWAL_BE_PP_PACK` + packing BSP app | TR-C3 (HU config) |
| TR-09 | KEJRIWAL Contract Batch Update | `ZKEJRIWAL_BE_SD_CONTRACT` (batch) + contract-batch BSP app | — |
| TR-C1 | (Cust.) Output Management ZCHALLAN + Adobe form | output type, determination, form | — |
| TR-C2 | (Cust.) Contract status profile | status management config | — |
| TR-C3 | (Cust.) HU Management + packing instructions | HU type, packing instructions | — |
| TR-FLP | (Cust.) Launchpad content | catalogs, target mappings, tiles, spaces/pages, PFCG roles | the app TRs |

Rule of thumb: **backend object before the UI that binds it**; **customizing
before the code that reads it**; **launchpad content last** (after the apps exist).

---

## 4. Release / import order (one line)

```
TR-01 → (TR-C1..C3 config) → TR-02..TR-09 (per feature) → TR-FLP (launchpad) → roles
```

Import the **same ordered set** into KSQ, validate (runbook §5), then into PROD.

---

## 5. Special cases

- **Key-user extensibility** (`YY1_*` Custom Fields & Logic, Adapt-UI/RTA): these
  are **not** in the Z packages. Each key-user app collects its changes into its
  **own transport** when the client is transport-enabled. Capture them and slot
  them next to the matching feature TR (e.g. the F1873 field TR imports with/just
  before TR-02). Confirm the **target-system mapping** for extensibility transports.
- **Adaptation project `$TMP`**: every `manifest.appdescr_variant` currently has
  `"packageName": "$TMP"`. The BAS/`fiori deploy` wizard prompts for the real
  **package** (`ZKEJRIWAL_UI_ADP`) and a **workbench transport** — set both before
  deploying beyond the sandbox.
- **Service bindings**: the binding object transports, but **activate/publish** it
  in each target system after import.
- **BSP deploy**: `fiori deploy` (custom apps and adaptation variants) attaches the
  BSP to the workbench TR you supply — use the matching feature TR.
- **`/IWFND` activation** of the base apps is **Basis (runbook)**, done per system —
  not transported by us.

---

## 6. Pre-import checklist (per target system)

- [ ] Base apps already activated by Basis (runbook) in the target.
- [ ] Import TR-01 (shade) first; activate its service binding.
- [ ] Import config TRs (Output Mgmt / status / HU) before dependent feature TRs.
- [ ] Import feature TRs; activate each service binding; check `/IWFND/ERROR_LOG`.
- [ ] Import TR-FLP; assign PFCG roles; `/UI2/INVALIDATE_GLOBAL_CACHE`.
- [ ] Smoke-test per `GO-LIVE-CHECKLIST.md`.
- [ ] Sign off in KSQ before importing to PROD (SP stack applied).

> See [`GO-LIVE-CHECKLIST.md`](GO-LIVE-CHECKLIST.md) for per-app placeholder/deploy
> steps and [`ACTIVATION.md`](ACTIVATION.md) for the Basis activation gate.
