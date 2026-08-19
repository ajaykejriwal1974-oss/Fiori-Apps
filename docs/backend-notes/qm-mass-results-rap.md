# QM Mass Inspection Results · RAP Service (skeleton)

The backend **OData V4 service** for the
[Record Inspection Results (Mass)](../../apps/record-inspection-results-mass) app
(replaces `ZQA32`). It exposes the open inspection characteristics across many
lots and records the entered results through the **standard QM result-recording
API**.

> **Skeleton, not compile-ready.** The QM table/field names, the "open
> characteristic" status filter, and the result-recording BAPI parameters must be
> **verified against your release** in ADT before activation.
>
> **Wired ✅** — the saver now calls `BAPI_INSPCHAR_SETRESULT` + `BAPI_INSPCHAR_CLOSE`
> per buffered row, routes errors into `reported`, and commits once. VERIFY the
> `bapi2045d4` result-structure fields for your release.

## Why unmanaged RAP

Inspection results are **not** a custom table - they live in standard QM and are
written via QM function modules / BAPIs. So this is an **unmanaged** RAP business
object: a read model over QM, with `update` + `save` that calls the QM API. This
matches the app's flow exactly - the UI edits `ResultValue` / `Valuation` inline
and submits the batch; the saver posts them in one commit.

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_qm_inspectionchar.ddls.asddls` | CDS `ZI_QM_InspectionChar` | Read model over QM (qamv/qals/qapo/qamr + work center) |
| `zc_qm_inspectionchar.ddls.asddls` | CDS `ZC_QM_InspectionChar` | Projection (`transactional_query`) |
| `zi_qm_inspectionchar.bdef.asbdef` | Behavior (unmanaged) | `update`; only result + valuation editable |
| `zc_qm_inspectionchar.bdef.asbdef` | Projection behavior | `use update` |
| `zbp_i_qm_inspectionchar.clas.abap` | Behavior pool | `FOR BEHAVIOR OF zi_qm_inspectionchar` |
| `zbp_i_qm_inspectionchar.clas.locals_imp.abap` | `lhc` handler + `lsc` saver | buffer edited rows → record via QM BAPI on save |
| `zui_qm_inspectionchar.srvd.srvdsrv` | Service def `ZUI_QM_INSPECTIONCHAR` | exposes `ZC_QM_InspectionChar` as `InspectionCharacteristic` |

### Create in ADT (no plain-text source)
- **Service binding `ZUI_QM_INSPECTIONCHAR_O4`** - bind `ZUI_QM_INSPECTIONCHAR`
  as **OData V4 – UI**; activate.

## What you must complete (the TODO / VERIFY list)

1. **Read CDS** (`zi_qm_inspectionchar`): confirm the QM source tables/fields and
   the **status filter** for "open" characteristics; confirm the work-center
   derivation (`qapo.arbid → I_WorkCenter`). Prefer released QM CDS interfaces
   where your release offers them.
2. **Saver** (`zbp_i_qm_inspectionchar` locals): replace the commented block with
   the real **`BAPI_INSPCHAR_SETRESULT` / `BAPI_INSPCHAR_CLOSE` + commit**
   sequence; route BAPI `return` messages into `reported` / `failed`.
3. **Authorization**: add `authorization master ( global )` +
   `get_global_authorizations` (QM plant / inspection-type checks).

## Wiring to the app

- Set the app's `REPLACE_WITH_QM_MASS_SERVICE` (in
  `apps/record-inspection-results-mass/webapp/manifest.json`) to the service
  binding name `ZUI_QM_INSPECTIONCHAR`.
- The service entity set is `InspectionCharacteristic` - it matches the app's
  `/InspectionCharacteristic` list binding, so the inline-edit + `onPostResults`
  `submitBatch` flow works without UI changes.
- Property names line up: `InspectionLot`, `Material`, `Plant`, `WorkCenter`,
  `CharacteristicDescription`, `ResultValue`, `Unit`, `Valuation`.

## Activate in order

table sources (standard) → `ZI_QM_InspectionChar` → `ZC_QM_InspectionChar` →
behavior definitions → behavior class → service definition → service binding.

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
