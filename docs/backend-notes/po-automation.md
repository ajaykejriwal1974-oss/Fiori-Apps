# PO Creation Automation (ZAUTOPO* → 1) — ABAP automation class

Clean-core successor to the **nine** `ZAUTOPO*` plant clones
(`ZPRG_PO_CREATE` / `_5000` / `_6000` / `_7000` / `_8000` / `_NEW` / `_NEW1` /
`N`). A single class **`ZCL_PO_AUTOMATION`** with **sales org as a parameter** —
no per-plant copies, no BDC.

## What it does
Back-to-back PO automation:
1. Reads PO-creation config from **`ZSOL_AUPO`** (company code / purch. org /
   sales org → purch. group, PO type, vendor).
2. Selects billing items (standard `VBRK`/`VBRP`) for the sales org **not yet in
   `ZMM_AUTOPO`** (the billing-item → PO log).
3. Creates the PO via the **Purchase Order API** (`BAPI_PO_CREATE1`) — `TODO`.
4. Logs `VBELN`/`POSNR` → `EBELN` in `ZMM_AUTOPO` so nothing is reprocessed.

## Clean-core shape
- **An ABAP class, not a report.** Schedulable through **Application Job
  Scheduling** (`if_apj_dt_exec_object` + `if_apj_rt_exec_object`); runnable in
  ADT (F9) via `if_oo_adt_classrun` for testing.
- Reads **standard** billing tables; the only custom tables are the existing
  driver/log (`ZSOL_AUPO`, `ZMM_AUTOPO`).
- `iv_test = abap_true` simulates (logs only, no PO, no insert).

## Wiring (TODO)
- The `BAPI_PO_CREATE1` call + `BAPI_TRANSACTION_COMMIT` and the `ZMM_AUTOPO`
  insert (see the `run` method).
- The Application Job parameter definition for `VKORG` in
  `if_apj_dt_exec_object~get_parameters` (component names per release).

## Create in ADT
- Activate the class; register it as an **Application Job catalog entry** so it
  can be scheduled in *Application Jobs* (Fiori) with `VKORG` as a parameter.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`. See
[`docs/UPL-MIGRATION.md`](../../docs/UPL-MIGRATION.md) §A.
