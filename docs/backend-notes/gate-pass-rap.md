# Gate Pass (ZGPS01/02/03 · ZGPSI1/2/3) — managed RAP composition

The gate pass has **no standard SAP equivalent**, so it is a genuine custom
object. Built as a **managed RAP composition** (header → items) over the real
legacy tables **`ZGP_HDR`** and **`ZGP_ITEM`** — the model behind the outward
(`ZGPS01/02/03`) and inward (`ZGPSI1/2/3`) gate-pass entry transactions. The
Fiori Elements *Manage Gate Passes* List Report / Object Page is generated from
the service binding via the metadata extensions.

## Composition tree
```
ZC_GatePass (ZGP_HDR)            header  - keys GpNumber, FiscalYear
  └─ _Item  ZC_GatePassItem (ZGP_ITEM)   item - keys GpNumber, ItemNumber, FiscalYear
       └─ _Part ZC_GatePassPart (ZGP_PART)  inward receipts (ASSOCIATED, read-only)
```

> **Data-model note:** `ZGP_PART` has keys `GPNUM + ZITEM + CNT` but **no `MJAHR`**,
> so it cannot join the item's full key as a composition child. It is exposed as a
> read-only **association** (`_Part`) instead. Add `MJAHR` to `ZGP_PART` (or a
> surrogate) to fold the inward-receipt detail into the editable composition.

## Fields (from the field dictionary)
**Header `ZGP_HDR`** — `GPNUM`/`MJAHR` (key), `DTYPE`, `WERKS`, `DEPT`, `VHNUM`,
`GINDAT`/`GINTME` (in), `GOTDAT`/`GOTTME` (out), `REMKS`, `CRE_USER`, admin
`ERNAM`/`ERDAT`/`ERZET`.
**Item `ZGP_ITEM`** — `GPNUM`/`ZITEM`/`MJAHR` (key), `MATNR`, `MAKTX`, `LIFNR`,
`NAME1`, `GP_QUAN`/`GP_MEINS`.
**Part `ZGP_PART`** — `GPNUM`/`ZITEM`/`CNT` (key), `REC_QUAN`, `VBILL_NO`,
`VBILL_DT`, `MAT_STAT`.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_gatepass.ddls.asddls` | `ZI_GatePass` | Root interface over `ZGP_HDR` + composition `_Item` |
| `zi_gatepass_item.ddls.asddls` | `ZI_GatePassItem` | Item over `ZGP_ITEM`, parent assoc + assoc `_Part` |
| `zi_gatepass_part.ddls.asddls` | `ZI_GatePassPart` | Inward receipt over `ZGP_PART` (associated) |
| `zc_gatepass*.ddls.asddls` | `ZC_GatePass*` | Projections (root `transactional_query` + children) |
| `zi_gatepass.bdef.asbdef` | Behavior (managed) | header + item create/update/delete, mapping |
| `zc_gatepass.bdef.asbdef` | Projection behavior | `use` create/update/delete + `_Item` |
| `zbp_i_gatepass.clas.*` | Behavior pool | `setHeaderDefaults` (admin + number range TODO) + `validateHeader` |
| `zc_gatepass.ddlx` / `zc_gatepass_item.ddlx` | Metadata ext | List Report + Object Page with item table |
| `zui_gatepass.srvd.srvdsrv` | Service def `ZUI_GATEPASS` | exposes header / item / part |

## Wiring (TODO)
- **Number range:** `GpNumber` is assigned from number-range object via `ZGPASS_NUM`
  (keyed by plant + fiscal year) — implement in `setHeaderDefaults`
  (`cl_numberrange_runtime=>number_get`).
- **Print:** the gate-pass form (the `PRT` drivers `ZGPASS` / `ZGATEPASS` /
  `ZREPASS`) becomes an Adobe **form template** printed from this app — see
  [`docs/PRT-OUTPUT-MANAGEMENT.md`](../../docs/PRT-OUTPUT-MANAGEMENT.md) §3.
- **Reports** (`ZGATER*`, `ZGREPT*`) become CDS analytical queries over `ZGP_HDR`/
  `ZGP_ITEM` (BI layer), not part of this transactional BO.

## Create in ADT
- Tables `ZGP_HDR` / `ZGP_ITEM` / `ZGP_PART` **already exist** — the managed BO
  binds to them; no DDIC table to create.
- OData V4 UI service binding `ZUI_GATEPASS_O4` for service definition `ZUI_GATEPASS`.
- Reuse existing `ZSOL_F4*` / supplier / material value helps.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
