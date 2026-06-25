# Fiori Apps – KEJRIWAL extensions

Clean-core SAP Fiori extensions for the S/4HANA 2025 migration, derived from
`KEJRIWAL_Z_to_Fiori_Mapping.pdf`. Each standard app that needs customization
(Table B of the mapping) gets its own **SAPUI5 Adaptation Project** under
`apps/`, layering custom fields / sections / controller logic on top of the
delivered app **without modifying SAP source**.

## Principle

- **Table A** apps (12) → adopt the standard Fiori app as-is, no development
  (activate OData service + assign business catalog/role + retrain). Nothing to
  build here.
- **Table B** apps (10) → adopt the standard app, then re-add the customization
  the clean-core way: key-user / in-app extensibility, custom CDS, or a released
  BAdI / RAP extension — never a modification.

## Apps in this repo

| App | Fiori ID | Replaces (Z) | Status |
|---|---|---|---|
| [Manage Sales Orders](apps/manage-sales-orders-ext) | F1873 | ZVA01 / ZVA01N, ZSOCLOSE | Scaffolded (UI layer; placeholders to complete on live system) |
| [Confirm Production Operation](apps/confirm-production-operation-ext) | F3069 | ZCO11N / ZCO11A | Scaffolded (UI layer; placeholders to complete on live system) |
| [Manage Outbound Deliveries](apps/manage-outbound-deliveries-ext) | F0867A | ZDEL | Scaffolded (UI layer; challan print via Output Management) |
| [Manage Sales Contracts](apps/manage-sales-contracts-ext) | VA42 / verify | ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02 | Scaffolded (UI layer; status actions call backend) |

> All Table B items are now scaffolded (4 adaptation projects + 4 custom apps +
> 1 RAP business object). Each still needs its live-system placeholders filled
> and its documented backend (CDS / RAP / BAdI / HU config / Output Management).

## Custom Fiori apps (not adaptation projects)

Some Table B items need a *different interaction model* than the standard app
offers, so they're built as standalone custom Fiori apps over a (custom) RAP/OData
service rather than as adaptation projects.

| App | Replaces (Z) | Why custom | Status |
|---|---|---|---|
| [Record Inspection Results (Mass)](apps/record-inspection-results-mass) | ZQA32 (vs F2655) | F2655 records one inspection lot at a time; this does mass / multi-lot entry | UI authored; QM RAP service skeleton in backend/qm-mass-results-rap |
| [Post Goods Movement (HU / Box)](apps/post-goods-movement-hu) | ZBOX_MOVE (vs MIGO) | MIGO is a GUI tx; box/HU-wise movement is a scan-driven flow | UI authored; needs custom RAP goods-movement + HU service |
| [Dyeing Packing](apps/dyeing-packing) | ZPACK01D/02D/03D, ZREPACKD | Textile cone/carton/pallet structure not in standard HU UI | UI authored; needs custom RAP packing service / HU config |
| [Contract Batch Update](apps/contract-batch-update) | ZBATCH_CHANGE | Mass batch assignment across contract items | UI authored; needs custom RAP mass-update service |

## Backend (non-UI) artifacts

| Artifact | Type | Replaces (Z) | Status |
|---|---|---|---|
| [Shade Master](backend/shade-master-rap) | RAP Custom Business Object | ZDD_SHADE | Source authored (table + service binding to create in ADT) |
| [QM Mass Results](backend/qm-mass-results-rap) | Unmanaged RAP service | ZQA32 (backend for the mass app) | Skeleton authored (QM BAPI calls + status filter to complete in ADT) |

The shade master has no standard SAP equivalent, so it's a RAP business object
(not an adaptation project). It also provides the value-help source for the shade
fields in F1873 and F3069.

## Layout

```
apps/
  manage-sales-orders-ext/      # F1873 adaptation project
    webapp/
      manifest.appdescr_variant # app-variant descriptor
      changes/
        fragments/              # custom XML UI sections
        coding/                 # controller extensions
        manifest/               # page-configuration / column changes
        annotations/            # (optional) annotation changes
      i18n/
    ui5.yaml
    package.json
```

Each project's own README lists the `REPLACE_WITH_*` placeholders that must be
filled from the live system and the backend (CDS / RAP / BAdI) prerequisites.

## Docs

- [`docs/EXTENSIBILITY.md`](docs/EXTENSIBILITY.md) — SAP clean-core extensibility
  tiers; per-app guidance on what to build as tier-1 key-user vs. tier-2
  adaptation project vs. backend.
- [`docs/PUBLISHING.md`](docs/PUBLISHING.md) — deploy to the Front-End Server and
  publish/launch each app as its own Fiori Launchpad tile (on-premise).
- [`docs/ACTIVATION.md`](docs/ACTIVATION.md) — how the Basis Fiori activation
  runbook (KSQ/KHQ, client 500) and this repo fit together: base-app activation
  → extension deploy order, and the base app → business role → repo artifact map.
- [`docs/GO-LIVE-CHECKLIST.md`](docs/GO-LIVE-CHECKLIST.md) — per-app checklist:
  placeholder values to collect, backend prerequisites, deploy / publish / verify
  steps, and a suggested execution sequence.
