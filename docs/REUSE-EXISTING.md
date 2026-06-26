# Reuse existing infrastructure (don't rebuild what already ships)

Per the build directive *"reuse our existing infrastructure also while making
apps."* The Build Pack shows the landscape **already contains 61 OData services
and 96 CDS views** plus dozens of value-help (F4) views. Before activating any
new RAP service in this repo, **bind / consume the existing one** where it
exists. The new RAP artifacts here are scaffolds — they should be retargeted to
these, not stood up in parallel.

## 1. Reuse existing OData services / CDS (bind instead of build)

| Need (this repo) | Existing infra to reuse | Action |
|---|---|---|
| HU physical inventory post (`hu-phys-inventory-rap`) | `ZSOL_PHYS_INV_POST_SRV` (`ZSOL_MTOS_PROCESS`) | Bind the Fiori app to the existing service; drop the new post action |
| HU inbound GR (`hu-inbound-rap`) | `ZSOL_INBOUND_HU` | Consume the existing inbound-HU service |
| Packing details read (`packing-detail-rap`) | `ZSOL_PACK_CDS` + `ZPP_PACK_MODULE*` | Read via existing pack CDS; only the *action* is new |
| Batch close/delete (`batch-status-rap`) | `ZSOL_BATCH_CDS`, `ZSOL_WIP_BATCH_CLOSE`, `ZPP_BATCH_DELETE` | Wrap the existing batch programs; reuse their selection logic |
| Contract batch update (`contract-batch-rap`) | `ZSOL_SALE_ORDER_BATCH_UPDATE` | Reuse the existing program as the action implementation |
| HU details (general) | `ZSOL_HU_DETAILS_CDS` | Reuse as the read model for any HU app |
| Sales contract read (`manage-sales-contracts-ext`) | `ZSOL_SALCONT_CDS` | Reuse as the value-list / read CDS |
| Post goods movement (`goods-movement-hu-rap`) | `ZSOL_POST_GOODS_MOVEMENTS` | Reuse the existing movement program |
| Palletization (`palletization-rap`) | `ZSOL_PALLETIZATION`, `ZSOL_UPDATE_PALLET` (`ZSOL_ASRS`) | Reuse the existing pallet programs |
| Value helps (plant, material, shade, batch…) | `ZSOL_F4*` views | Reference as `@Consumption.valueHelpDefinition` — never re-create |

> Rule: a new `*-rap` service here contributes **only** the thin transactional
> action (the BAPI call) and a Fiori-ready projection. The **read model, value
> helps, and selection logic come from the existing CDS/OData** above.

## 2. Reuse existing custom tables (managed RAP over legacy tables)

Every refit master is a managed RAP BO mapped onto the **table that already
exists** — no new persistence is created:

| Master app | Existing table reused |
|---|---|
| Recipe | `ZPP_RECEIPE` |
| Job | `ZPP_JOBN` |
| Schedule | `ZPP_SCHEDULEN` (+ number range `ZPP_SHNUM`) |
| Transport Code | `ZTRANS` |
| Truck | `ZTB_TRUCK_MSTR` |
| Merge | `ZPP_MERGE` (+ `ZTB_MERGE_MST`) |
| Checked/Packed By | `ZPP_PCBY` |
| Packing Material | `ZPACK_MAST` |
| Export Details | `ZEXP` |
| Digital Signature | `ZTDIGI_SIGN` |
| Shade (reference) | `ZMM_SHADE` / `ZPP_SHADE` |

Min/Max needs **no** table — it reuses standard MRP fields on `MARC`
(see `backend/minmax-master-rap`).

## 3. Reuse existing apps in this repo (extend, don't duplicate)

| New requirement | Extend this existing app |
|---|---|
| `ZDELC` / `ZDEL` delivery challan | `apps/manage-outbound-deliveries-ext` (F0867A) — add the challan output |
| `ZCON_CLOSE`, `ZCOREL` contract close/release | `apps/manage-sales-contracts-ext` — add the close/release actions |
| `ZVA01(N)`, `ZSOCLOSE` order create/close | `apps/manage-sales-orders-ext` (F1873) — adaptation extension |
| `ZINSPLOT`, `ZQAR` inspection | `apps/record-inspection-results-mass` / `backend/qm-mass-results-rap` |

## 4. Standard-app reuse (retire the Z program entirely)
The 17 `STD` rows in [CLASSIFICATION.md](CLASSIFICATION.md#std--use-standard-fiori-app--retire-the-z-program-17)
(batch master create/change/display, GL/customer line items, price comparison,
material list…) map 1:1 to standard S/4HANA Fiori apps — assign the standard app
+ role and retire the custom transaction. Nothing to build.

## Net effect
- **Masters:** 10 managed-RAP BOs, each over an **existing** legacy table.
- **Transactional:** new services contribute only the action; **read + F4 reuse
  existing CDS/OData**.
- **Min/Max + 17 STD tcodes:** reuse standard, build nothing.
- **87 BI / 61 PRT / 28 UPL:** analytics / Output Management / migration layers,
  not new tiles.
